import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:meprop_asset_tracker/generated/l10n.dart';
import 'package:meprop_asset_tracker/utils/currency_utils.dart';
import 'package:meprop_asset_tracker/services/local_portfolio_service.dart';
import 'package:provider/provider.dart';
import 'package:show_network_image/show_network_image.dart';
import 'package:meprop_asset_tracker/components/shimmer_widget.dart';
import 'package:meprop_asset_tracker/utils/validation_utils.dart';

class PropertyPurchasePage extends StatefulWidget {
  final Map<String, dynamic> property;

  const PropertyPurchasePage({super.key, required this.property});

  @override
  _PropertyPurchasePageState createState() => _PropertyPurchasePageState();
}

class _PropertyPurchasePageState extends State<PropertyPurchasePage> {
  final TextEditingController _amountController = TextEditingController(text: '1.0');
  double _tokenAmount = 1.0;
  bool _isPurchasing = false;
  String? _validationError;
  String? _walletValidationError;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
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
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);

    _validationError = PurchaseValidation.validateTokenAmount(
      _amountController.text,
      stock,
      userAvailableTokens,
      currencyUtils.currencySymbol,
    );

    if (_validationError == null && _tokenAmount > 0) {
      _walletValidationError = PurchaseValidation.validateWalletBalance(
        _tokenAmount,
        tokenPrice,
        userAvailableTokens,
        currencyUtils.currencySymbol,
      );

      // Debug: Print wallet validation info
      final totalCost = _tokenAmount * tokenPrice;
      print(
          '💰 Wallet Validation: TokenAmount=$_tokenAmount, TokenPrice=$tokenPrice, TotalCost=$totalCost, Available=$userAvailableTokens');
      if (_walletValidationError != null) {
        print('❌ Wallet Error: $_walletValidationError');
      } else {
        print('✅ Wallet OK');
      }
    } else {
      _walletValidationError = null;
    }
  }

  bool _canPurchase() {
    return _validationError == null && _walletValidationError == null && _tokenAmount > 0;
  }

  String get imageUrl {
    if (widget.property['imageLink'] != null &&
        widget.property['imageLink'] is List &&
        widget.property['imageLink'].isNotEmpty) {
      final url = widget.property['imageLink'][0];
      print('🖼️ PropertyPurchase: imageUrl = $url');
      return url;
    }
    print('🖼️ PropertyPurchase: No imageUrl found');
    return '';
  }

  String get title => widget.property['shortName'] ?? widget.property['title'] ?? S.of(context).nameUnavailable;
  double get stock => (widget.property['stock'] as num?)?.toDouble() ?? 0.0;
  double get tokenPrice => (widget.property['tokenPrice'] as num?)?.toDouble() ?? 0.0;
  String get country => widget.property['country'] ?? S.of(context).unavailable;
  String get city => widget.property['city'] ?? S.of(context).unavailable;
  double get annualYield => (widget.property['annualPercentageYield'] as num?)?.toDouble() ?? 0.0;
  // User's available wallet balance in USD (Russell's wallet)
  double get userAvailableTokens => 2000.0;

  String _getPropertyId() {
    return widget.property['uuid'] ??
        widget.property['contractAddress'] ??
        widget.property['shortName'] ??
        widget.property['title'] ??
        'unknown_${widget.property.hashCode}';
  }

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
          title: Text(S.of(context).purchaseSuccessful),
          content: Column(
            children: [
              const SizedBox(height: 20),
              const Icon(CupertinoIcons.check_mark_circled, color: CupertinoColors.activeGreen, size: 60),
              const SizedBox(height: 15),
              Text(
                S.of(context).purchaseConfirmation(
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
                Navigator.of(context).pop(); // Go back from purchase page
              },
            ),
          ],
        );
      },
    );
  }

  void _initiatePurchase() async {
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);
    final amount = double.tryParse(_amountController.text) ?? 0.0;

    // Comprehensive validation
    final tokenValidation = PurchaseValidation.validateTokenAmount(
      _amountController.text,
      stock,
      userAvailableTokens,
      currencyUtils.currencySymbol,
    );

    if (tokenValidation != null) {
      _showErrorDialog('Invalid Amount', tokenValidation);
      return;
    }

    final walletValidation = PurchaseValidation.validateWalletBalance(
      amount,
      tokenPrice,
      userAvailableTokens,
      currencyUtils.currencySymbol,
    );

    if (walletValidation != null) {
      _showErrorDialog('Insufficient Balance', walletValidation);
      return;
    }

    setState(() {
      _isPurchasing = true;
    });

    // Simulate a network request
    await Future.delayed(const Duration(seconds: 2));

    // ذخیره خرید در حافظه محلی
    try {
      print('💾 Saving purchase with imageUrl: $imageUrl');
      await LocalPortfolioService.addPurchase(
        propertyId: _getPropertyId(),
        shortName: widget.property['shortName'] ?? '',
        title: title,
        tokenAmount: amount,
        tokenPrice: tokenPrice,
        imageUrl: imageUrl,
        country: country,
        city: city,
        annualYield: annualYield,
        purchaseDate: DateTime.now(),
      );
    } catch (e) {
      print('Error saving purchase: $e');
      setState(() {
        _isPurchasing = false;
      });
      _showErrorDialog('Purchase Error', 'Failed to save purchase. Please try again.');
      return;
    }

    setState(() {
      _isPurchasing = false;
    });

    _showSuccessDialog();
  }

  @override
  Widget build(BuildContext context) {
    final currencyUtils = Provider.of<CurrencyProvider>(context);
    final totalCost = _tokenAmount * tokenPrice;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (imageUrl.isNotEmpty)
              Hero(
                tag: 'property_image_${widget.property['uuid']}',
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: imageUrl.isNotEmpty
                      ? (kIsWeb
                          ? ShowNetworkImage(
                              imageSrc: imageUrl,
                              mobileBoxFit: BoxFit.cover,
                            )
                          : CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => ImageShimmer(
                                borderRadius: BorderRadius.zero,
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  CupertinoIcons.photo,
                                  color: CupertinoColors.systemGrey,
                                  size: 50,
                                ),
                              ),
                            ))
                      : Container(
                          color: Colors.grey[300],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                title.toLowerCase().contains('factoring')
                                    ? CupertinoIcons.chart_bar
                                    : CupertinoIcons.building_2_fill,
                                color: CupertinoColors.systemGrey,
                                size: 50,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                title.toLowerCase().contains('factoring')
                                    ? S.of(context).propertiesFactoring
                                    : S.of(context).propertiesProperty,
                                style: TextStyle(
                                  color: CupertinoColors.systemGrey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.of(context).purchaseDetails,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  _buildInfoCard(context, currencyUtils),
                  const SizedBox(height: 30),
                  Text(
                    S.of(context).enterAmount,
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
                  _buildSummaryCard(context, currencyUtils, totalCost),
                  // Purchase limit info
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: CupertinoColors.systemBlue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.info_circle, color: CupertinoColors.systemBlue, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Purchase limit: \$200 per transaction',
                            style: TextStyle(
                              color: CupertinoColors.systemBlue,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                  if (_walletValidationError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: CupertinoColors.systemOrange.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(CupertinoIcons.money_dollar_circle, color: CupertinoColors.systemOrange, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _walletValidationError!,
                              style: const TextStyle(
                                color: CupertinoColors.systemOrange,
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
                      onPressed: _isPurchasing || !_canPurchase() ? null : _initiatePurchase,
                      alignment: Alignment.center,
                      child: _isPurchasing
                          ? const CupertinoActivityIndicator(color: Colors.white)
                          : Text(S.of(context).confirmPurchase),
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
          _buildInfoRow(S.of(context).availableTokens, stock.toStringAsFixed(2)),
          _buildDivider(),
          _buildInfoRow(S.of(context).annualYield, '${annualYield.toStringAsFixed(2)}%'),
          _buildDivider(),
          _buildInfoRow(S.of(context).country, country),
          _buildDivider(),
          _buildInfoRow(S.of(context).city, city),
          _buildDivider(),
          _buildInfoRow(S.of(context).yourAvailableTokens,
              currencyUtils.formatCurrency(userAvailableTokens, currencyUtils.currencySymbol),
              isHighlighted: true),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, CurrencyProvider currencyUtils, double totalCost) {
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
          _buildInfoRow(S.of(context).quantity, _tokenAmount.toStringAsFixed(2)),
          _buildDivider(),
          _buildInfoRow(
            S.of(context).totalCost,
            currencyUtils.formatCurrency(totalCost, currencyUtils.currencySymbol),
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
