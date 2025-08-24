import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:meprop_asset_tracker/generated/l10n.dart';
import 'package:meprop_asset_tracker/utils/currency_utils.dart';
import 'package:meprop_asset_tracker/services/local_portfolio_service.dart';
import 'package:provider/provider.dart';
import 'package:meprop_asset_tracker/utils/validation_utils.dart';

class PropertySellPage extends StatefulWidget {
  final Map<String, dynamic> property;

  const PropertySellPage({super.key, required this.property});

  @override
  _PropertySellPageState createState() => _PropertySellPageState();
}

class _PropertySellPageState extends State<PropertySellPage> {
  final TextEditingController _amountController = TextEditingController(text: '1.0');
  double _tokenAmount = 1.0;
  bool _isSelling = false;
  double _ownedTokens = 0.0;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
    _loadOwnedTokens();
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    setState(() {
      _tokenAmount = double.tryParse(_amountController.text) ?? 0.0;
      _validateInput();
    });
  }

  void _validateInput() {
    _validationError = SellValidation.validateSellAmount(
      _amountController.text,
      _ownedTokens,
    );
  }

  bool _canSell() {
    return _validationError == null && _tokenAmount > 0 && _ownedTokens > 0;
  }

  String _getPropertyId() {
    return widget.property['uuid'] ??
        widget.property['contractAddress'] ??
        widget.property['shortName'] ??
        widget.property['title'] ??
        'unknown_${widget.property.hashCode}';
  }

  Future<void> _loadOwnedTokens() async {
    final portfolio = await LocalPortfolioService.getPortfolio();
    final propertyId = _getPropertyId();

    final ownedProperty = portfolio.firstWhere(
      (item) => item['propertyId'] == propertyId,
      orElse: () => {'tokenAmount': 0.0},
    );

    setState(() {
      _ownedTokens = (ownedProperty['tokenAmount'] as num?)?.toDouble() ?? 0.0;
      _validateInput(); // Validate after loading owned tokens
    });
  }

  String get imageUrl {
    if (widget.property['imageUrl'] != null &&
        widget.property['imageUrl'] is List &&
        widget.property['imageUrl'].isNotEmpty) {
      return widget.property['imageUrl'][0];
    }
    // Fallback to imageLink for backward compatibility
    if (widget.property['imageLink'] != null &&
        widget.property['imageLink'] is List &&
        widget.property['imageLink'].isNotEmpty) {
      return widget.property['imageLink'][0];
    }
    return '';
  }

  String get title => widget.property['shortName'] ?? widget.property['title'] ?? S.of(context).nameUnavailable;
  double get tokenPrice => (widget.property['tokenPrice'] as num?)?.toDouble() ?? 0.0;
  String get country => widget.property['country'] ?? S.of(context).unavailable;
  String get city => widget.property['city'] ?? S.of(context).unavailable;
  double get annualYield => (widget.property['annualPercentageYield'] as num?)?.toDouble() ?? 0.0;

  void _showErrorDialog(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            CupertinoDialogAction(
              child: Text(S.of(context).ok),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog() {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text(S.of(context).sellSuccessful),
          content: Column(
            children: [
              const SizedBox(height: 20),
              const Icon(CupertinoIcons.check_mark_circled, color: CupertinoColors.activeGreen, size: 60),
              const SizedBox(height: 15),
              Text(
                S.of(context).sellConfirmation(
                    _tokenAmount.toStringAsFixed(2),
                    title,
                    Provider.of<CurrencyProvider>(context, listen: false).formatCurrency(_tokenAmount * tokenPrice,
                        Provider.of<CurrencyProvider>(context, listen: false).currencySymbol)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              child: Text(S.of(context).ok),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(true); // Go back from sell page with success result
              },
            ),
          ],
        );
      },
    );
  }

  void _initiateSell() async {
    final amount = double.tryParse(_amountController.text) ?? 0.0;

    // Comprehensive validation
    final sellValidation = SellValidation.validateSellAmount(
      _amountController.text,
      _ownedTokens,
    );

    if (sellValidation != null) {
      _showErrorDialog('Invalid Amount', sellValidation);
      return;
    }

    setState(() {
      _isSelling = true;
    });

    // Simulate a network request
    await Future.delayed(const Duration(seconds: 2));

    // فروش توکن‌ها از حافظه محلی
    try {
      final propertyId = _getPropertyId();

      await LocalPortfolioService.sellTokens(
        propertyId: propertyId,
        sellAmount: amount,
      );

      await _loadOwnedTokens(); // به‌روزرسانی توکن‌های مالکیت
    } catch (e) {
      print('Error during sell: $e');
      setState(() {
        _isSelling = false;
      });
      _showErrorDialog('Sale Error', 'Failed to save sale. Please try again.');
      return;
    }

    setState(() {
      _isSelling = false;
    });

    _showSuccessDialog();
  }

  @override
  Widget build(BuildContext context) {
    final currencyUtils = Provider.of<CurrencyProvider>(context);
    final totalRevenue = _tokenAmount * tokenPrice;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('${S.of(context).sell} $title'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (imageUrl.isNotEmpty)
              Hero(
                tag: 'property_sell_image_${widget.property['uuid']}',
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  height: 250,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 250,
                    color: CupertinoColors.systemGrey5,
                    child: const Center(child: CupertinoActivityIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 250,
                    color: CupertinoColors.systemGrey5,
                    child: const Icon(CupertinoIcons.photo, color: CupertinoColors.systemGrey, size: 50),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.of(context).sellDetails,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  _buildInfoCard(context, currencyUtils),
                  const SizedBox(height: 30),
                  Text(
                    S.of(context).sellAmount,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  CupertinoTextField(
                    controller: _amountController,
                    placeholder: S.of(context).numberOfTokens,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    prefix: Padding(
                      padding: const EdgeInsets.only(left: 12.0),
                      child: Icon(CupertinoIcons.number, color: CupertinoColors.systemGrey),
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: CupertinoColors.systemGrey3,
                        width: 1,
                      ),
                    ),
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  ),
                  const SizedBox(height: 30),
                  _buildSummaryCard(context, currencyUtils, totalRevenue),
                  const SizedBox(height: 40),
                  // Validation error messages
                  if (_validationError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: CupertinoColors.systemRed.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(CupertinoIcons.exclamationmark_triangle,
                              color: CupertinoColors.systemRed, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _validationError!,
                              style: const TextStyle(
                                color: CupertinoColors.systemRed,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  Center(
                    child: CupertinoButton.filled(
                      onPressed: _isSelling || !_canSell() ? null : _initiateSell,
                      alignment: Alignment.center,
                      child: _isSelling
                          ? const CupertinoActivityIndicator(color: Colors.white)
                          : Text(S.of(context).confirmSell),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, CurrencyProvider currencyUtils) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(
              S.of(context).propertyPrice, currencyUtils.formatCurrency(tokenPrice, currencyUtils.currencySymbol)),
          _buildDivider(),
          _buildInfoRow(S.of(context).ownedTokens, _ownedTokens.toStringAsFixed(2), isHighlighted: true),
          _buildDivider(),
          _buildInfoRow(S.of(context).propertiesYield, '${annualYield.toStringAsFixed(2)}%'),
          _buildDivider(),
          _buildInfoRow(S.of(context).country, country),
          _buildDivider(),
          _buildInfoRow(S.of(context).city, city),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, CurrencyProvider currencyUtils, double totalRevenue) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(S.of(context).sellAmount, _tokenAmount.toStringAsFixed(2)),
          _buildDivider(),
          _buildInfoRow(
            S.of(context).totalRevenue,
            currencyUtils.formatCurrency(totalRevenue, currencyUtils.currencySymbol),
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String title, String value, {bool isTotal = false, bool isHighlighted = false}) {
    final textStyle = Theme.of(context).textTheme.bodyLarge;
    final valueStyle = isHighlighted
        ? textStyle?.copyWith(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)
        : textStyle;
    final totalStyle = Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: isTotal ? totalStyle : textStyle),
          Text(value, style: isTotal ? totalStyle : valueStyle),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: Theme.of(context).dividerColor.withOpacity(0.5),
    );
  }
}
