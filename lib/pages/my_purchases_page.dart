import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:meprop_asset_tracker/generated/l10n.dart';
import 'package:meprop_asset_tracker/utils/currency_utils.dart';
import 'package:meprop_asset_tracker/services/local_portfolio_service.dart';
import 'package:meprop_asset_tracker/utils/parameters.dart';
import 'package:meprop_asset_tracker/pages/propertiesForSale/property_sell_page.dart';
import 'package:provider/provider.dart';
import 'package:meprop_asset_tracker/app_state.dart';
import 'package:meprop_asset_tracker/components/shimmer_widget.dart';
import 'package:show_network_image/show_network_image.dart';

class MyPurchasesPage extends StatefulWidget {
  const MyPurchasesPage({super.key});

  @override
  _MyPurchasesPageState createState() => _MyPurchasesPageState();
}

class _MyPurchasesPageState extends State<MyPurchasesPage> {
  List<Map<String, dynamic>> _purchases = [];
  bool _isLoading = true;
  double _totalInvested = 0.0;

  @override
  void initState() {
    super.initState();
    _loadPurchases();
  }

  Future<void> _loadPurchases() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final purchases = await LocalPortfolioService.getPortfolio();

      // Debug: Print the first purchase to see the data structure
      if (purchases.isNotEmpty) {
        print('🔍 MyPurchases: Loaded ${purchases.length} properties');
        print('🔍 First purchase data: ${purchases.first}');

        // Debug each purchase's image URL
        for (int i = 0; i < purchases.length; i++) {
          final purchase = purchases[i];
          final title = purchase['title'] ?? purchase['shortName'] ?? 'Unknown';
          final imageUrl = purchase['imageUrl'] ?? '';
          print('🖼️ Purchase $i ($title): imageUrl = "$imageUrl"');
        }
      } else {
        print('⚠️ No purchases found in portfolio');
      }

      double totalInvested = 0.0;
      for (final purchase in purchases) {
        totalInvested += (purchase['totalValue'] as double? ?? 0.0);
      }

      setState(() {
        _purchases = purchases;
        _totalInvested = totalInvested;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading purchases: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading purchases: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyUtils = Provider.of<CurrencyProvider>(context);
    final textSizeOffset = Provider.of<AppState>(context).getTextSizeOffset();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'My Purchases',
          style: TextStyle(fontSize: 20 + textSizeOffset),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.refresh),
            onPressed: _loadPurchases,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : RefreshIndicator(
              onRefresh: _loadPurchases,
              child: Column(
                children: [
                  // Summary Card
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.black.withOpacity(0.3)
                              : Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Portfolio Summary',
                          style: TextStyle(
                            fontSize: 18 + textSizeOffset,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.titleLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSummaryItem(
                              'Total Properties',
                              _purchases.length.toString(),
                              CupertinoIcons.house_alt,
                              Colors.blue,
                              textSizeOffset,
                            ),
                            _buildSummaryItem(
                              'Total Invested',
                              currencyUtils.formatCurrency(_totalInvested, currencyUtils.currencySymbol),
                              CupertinoIcons.money_dollar,
                              Colors.green,
                              textSizeOffset,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Properties List
                  Expanded(
                    child: _purchases.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.house,
                                  size: 80,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No properties purchased yet',
                                  style: TextStyle(
                                    fontSize: 16 + textSizeOffset,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Purchase properties to see them here',
                                  style: TextStyle(
                                    fontSize: 14 + textSizeOffset,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _purchases.length,
                            itemBuilder: (context, index) {
                              final purchase = _purchases[index];
                              return _buildPropertyCard(purchase, currencyUtils, textSizeOffset);
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryItem(String title, String value, IconData icon, Color color, double textSizeOffset) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12 + textSizeOffset,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 16 + textSizeOffset,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatPurchaseDate(String purchaseDate) {
    try {
      if (purchaseDate.isEmpty) return 'Unknown';
      final dateTimeString = DateTime.parse(purchaseDate).toLocal().toString();
      final parts = dateTimeString.split(' ');
      if (parts.isNotEmpty) {
        return parts[0];
      }
      return 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  Widget _buildPropertyCard(Map<String, dynamic> purchase, CurrencyProvider currencyUtils, double textSizeOffset) {
    final title = purchase['title'] ?? purchase['shortName'] ?? 'Unknown Property';
    final tokenAmount = (purchase['tokenAmount'] as num?)?.toDouble() ?? 0.0;
    final tokenPrice = (purchase['tokenPrice'] as num?)?.toDouble() ?? 0.0;
    final totalValue = (purchase['totalValue'] as num?)?.toDouble() ?? 0.0;

    // Handle imageUrl properly - it's stored as a string in local storage
    String imageUrl = '';
    if (purchase['imageUrl'] != null && purchase['imageUrl'].toString().isNotEmpty) {
      imageUrl = purchase['imageUrl'].toString();
    }

    // Debug: Print image URL and full purchase data to help troubleshoot
    print('🖼️ Image URL for ${title}: $imageUrl');
    print('🔍 Full purchase data: $purchase');

    final country = purchase['country'] ?? 'Unknown';
    final city = purchase['city'] ?? 'Unknown';
    final annualYield = (purchase['annualYield'] as num?)?.toDouble() ?? 0.0;
    final purchaseDate = purchase['purchaseDate'] ?? '';
    final propertyId = purchase['propertyId'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image and basic info
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
            )
          else
            // Show default placeholder when no image URL is available
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      CupertinoIcons.house_alt,
                      color: CupertinoColors.systemGrey,
                      size: 60,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'No Image Available',
                      style: TextStyle(
                        color: CupertinoColors.systemGrey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ImageURL: "${imageUrl.isEmpty ? 'empty' : imageUrl}"',
                      style: const TextStyle(
                        color: CupertinoColors.systemGrey,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and country flag
                Row(
                  children: [
                    if (country != 'Unknown')
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.black.withOpacity(0.2)
                                    : Colors.black.withOpacity(0.05),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.asset(
                              'assets/country/${Parameters.getCountryFileName(country)}.png',
                              width: 24,
                              height: 24,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(CupertinoIcons.flag,
                                    size: 24, color: Theme.of(context).textTheme.bodyMedium?.color);
                              },
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 18 + textSizeOffset,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => PropertySellPage(
                              property: {
                                'uuid': propertyId,
                                'shortName': purchase['shortName'] ?? '',
                                'fullName': title,
                                'tokenPrice': tokenPrice,
                                'imageUrl': imageUrl.isNotEmpty ? [imageUrl] : [],
                                'coordinate': {
                                  'country': country,
                                  'city': city,
                                },
                                'totalTokens': purchase['totalTokens'] ?? 1000000,
                                'netRentYear': purchase['netRentYear'] ?? 0,
                                'annualPercentageYield': annualYield,
                              },
                            ),
                          ),
                        );

                        // Refresh the list only if sell was successful
                        if (result == true) {
                          _loadPurchases();
                        }
                      },
                      icon: const Icon(
                        CupertinoIcons.money_dollar_circle,
                        size: 18,
                      ),
                      label: const Text('Sell'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minimumSize: const Size(80, 36),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Location
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.location_solid,
                      size: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      city,
                      style: TextStyle(
                        fontSize: 14 + textSizeOffset,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem('Tokens', tokenAmount.toStringAsFixed(2), textSizeOffset),
                    _buildStatItem('Price/Token',
                        currencyUtils.formatCurrency(tokenPrice, currencyUtils.currencySymbol), textSizeOffset),
                    _buildStatItem('Total Value',
                        currencyUtils.formatCurrency(totalValue, currencyUtils.currencySymbol), textSizeOffset),
                  ],
                ),
                if (annualYield > 0) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatItem('Annual Yield', '${annualYield.toStringAsFixed(2)}%', textSizeOffset),
                      if (purchaseDate.isNotEmpty)
                        _buildStatItem('Purchase Date', _formatPurchaseDate(purchaseDate), textSizeOffset),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, double textSizeOffset) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12 + textSizeOffset,
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14 + textSizeOffset,
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
