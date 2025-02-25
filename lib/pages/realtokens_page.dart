import 'package:flutter/foundation.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/modals/token_details/showTokenDetails.dart';
import 'package:realtokens/utils/currency_utils.dart';
import 'package:realtokens/utils/ui_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:show_network_image/show_network_image.dart';

class RealTokensPage extends StatefulWidget {
  const RealTokensPage({super.key});

  @override
  RealTokensPageState createState() => RealTokensPageState();
}

class RealTokensPageState extends State<RealTokensPage> {
  String _searchQuery = '';
  String _sortOption = 'recentlyAdded';
  bool _isAscending = true;
  String? _selectedCity;
  // Afficher ou non les tokens non whitelistés
  bool _showNonWhitelisted = true;
  // Filtrer les tokens non présents dans le wallet
  bool _filterNotInWallet = false;

  @override
  void initState() {
    super.initState();
    _loadSortPreferences();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DataManager>(context, listen: false).fetchAndStoreAllTokens();
    });
  }

  Future<void> _loadSortPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _sortOption = prefs.getString('sortOption') ?? 'recentlyAdded';
      _isAscending = prefs.getBool('isAscending') ?? true;
      _showNonWhitelisted = prefs.getBool('showNonWhitelisted') ?? true;
      _filterNotInWallet = prefs.getBool('filterNotInWallet') ?? false;
    });
  }

  Future<void> _saveSortPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('sortOption', _sortOption);
    prefs.setBool('isAscending', _isAscending);
    prefs.setBool('showNonWhitelisted', _showNonWhitelisted);
    prefs.setBool('filterNotInWallet', _filterNotInWallet);
  }

  List<Map<String, dynamic>> _filterAndSortTokens(DataManager dataManager) {
    List<Map<String, dynamic>> filteredTokens = dataManager.allTokens.where((token) {
      final matchesSearchQuery = token['fullName']
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
      final matchesCity = _selectedCity == null ||
          token['fullName'].contains(_selectedCity!);
      return matchesSearchQuery && matchesCity;
    }).toList();

    if (_filterNotInWallet) {
      filteredTokens = filteredTokens.where((token) => !dataManager.portfolio.any(
          (p) => p['uuid'].toLowerCase() == token['uuid'].toLowerCase())).toList();
    }

    if (!_showNonWhitelisted) {
      filteredTokens = filteredTokens.where((token) => dataManager.whitelistTokens.any(
          (whitelisted) =>
              whitelisted['token'].toLowerCase() == token['uuid'].toLowerCase())).toList();
    }

    if (_sortOption == S.of(context).sortByName) {
      filteredTokens.sort((a, b) => _isAscending
          ? a['shortName'].compareTo(b['shortName'])
          : b['shortName'].compareTo(a['shortName']));
    } else if (_sortOption == S.of(context).sortByValue) {
      filteredTokens.sort((a, b) => _isAscending
          ? a['totalValue'].compareTo(b['totalValue'])
          : b['totalValue'].compareTo(a['totalValue']));
    } else if (_sortOption == S.of(context).sortByAPY) {
      filteredTokens.sort((a, b) => _isAscending
          ? a['annualPercentageYield']
              .compareTo(b['annualPercentageYield'])
          : b['annualPercentageYield']
              .compareTo(a['annualPercentageYield']));
    } else if (_sortOption == S.of(context).sortByInitialLaunchDate) {
      filteredTokens.sort((a, b) => _isAscending
          ? a['initialLaunchDate'].compareTo(b['initialLaunchDate'])
          : b['initialLaunchDate'].compareTo(a['initialLaunchDate']));
    }

    return filteredTokens;
  }

  List<String> _getUniqueCities(List<Map<String, dynamic>> tokens) {
    final cities = tokens
        .map((token) {
          List<String> parts = token['fullName'].split(',');
          return parts.length >= 2 ? parts[1].trim() : S.of(context).unknownCity;
        })
        .toSet()
        .toList();
    cities.sort();
    return cities;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(S.of(context).appTitle),
      ),
      body: Consumer<DataManager>(
        builder: (context, dataManager, child) {
          final filteredAndSortedTokens = _filterAndSortTokens(dataManager);
          final uniqueCities = _getUniqueCities(dataManager.allTokens);
          final currencyUtils =
              Provider.of<CurrencyProvider>(context, listen: false);

          return NestedScrollView(
            headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
              return <Widget>[
                SliverAppBar(
                  floating: true,
                  snap: true,
                  automaticallyImplyLeading: false,
                  expandedHeight: UIUtils.getSliverAppBarHeight(context),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      color: Theme.of(context).cardColor,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            // Champ de recherche
                            Expanded(
                              flex: 3,
                              child: TextField(
                                onChanged: (value) {
                                  setState(() {
                                    _searchQuery = value;
                                  });
                                },
                                decoration: InputDecoration(
                                  hintText: S.of(context).searchHint,
                                  prefixIcon: const Icon(Icons.search),
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(30.0),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            // Sélection de la ville
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.location_city),
                              onSelected: (String value) {
                                setState(() {
                                  _selectedCity = value ==
                                          S.of(context).allCities
                                      ? null
                                      : value;
                                });
                              },
                              itemBuilder: (BuildContext context) {
                                return [
                                  PopupMenuItem(
                                    value: S.of(context).allCities,
                                    child: Text(S.of(context).allCities),
                                  ),
                                  ...uniqueCities.map((city) => PopupMenuItem(
                                        value: city,
                                        child: Text(city),
                                      )),
                                ];
                              },
                            ),
                            const SizedBox(width: 8.0),
                            // Menu regroupant les filtres
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.filter_alt),
                              onSelected: (value) {
                                setState(() {
                                  if (value == 'filterNotInWallet') {
                                    _filterNotInWallet = !_filterNotInWallet;
                                  } else if (value ==
                                      'showNonWhitelisted') {
                                    _showNonWhitelisted = !_showNonWhitelisted;
                                  }
                                  _saveSortPreferences();
                                });
                              },
                              itemBuilder: (context) => [
                                CheckedPopupMenuItem(
                                  value: 'filterNotInWallet',
                                  checked: _filterNotInWallet,
                                  child: Text(
                                      S.of(context).filterNotInWallet),
                                ),
                                CheckedPopupMenuItem(
                                  value: 'showNonWhitelisted',
                                  checked: _showNonWhitelisted,
                                  child: Text(
                                      S.of(context).showOnlyWhitelisted),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8.0),
                            // Menu de tri
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.sort),
                              onSelected: (value) {
                                setState(() {
                                  if (value == 'asc' || value == 'desc') {
                                    _isAscending = value == 'asc';
                                  } else {
                                    _sortOption = value;
                                  }
                                  _saveSortPreferences();
                                });
                              },
                              itemBuilder: (context) => [
                                CheckedPopupMenuItem(
                                  value: S.of(context).sortByName,
                                  checked: _sortOption ==
                                      S.of(context).sortByName,
                                  child: Text(S.of(context).sortByName),
                                ),
                                CheckedPopupMenuItem(
                                  value: S.of(context).sortByValue,
                                  checked: _sortOption ==
                                      S.of(context).sortByValue,
                                  child: Text(S.of(context).sortByValue),
                                ),
                                CheckedPopupMenuItem(
                                  value: S.of(context).sortByAPY,
                                  checked: _sortOption ==
                                      S.of(context).sortByAPY,
                                  child: Text(S.of(context).sortByAPY),
                                ),
                                CheckedPopupMenuItem(
                                  value: S.of(context).sortByInitialLaunchDate,
                                  checked: _sortOption ==
                                      S.of(context).sortByInitialLaunchDate,
                                  child: Text(
                                      S.of(context).sortByInitialLaunchDate),
                                ),
                                const PopupMenuDivider(),
                                CheckedPopupMenuItem(
                                  value: 'asc',
                                  checked: _isAscending,
                                  child: Text(S.of(context).ascending),
                                ),
                                CheckedPopupMenuItem(
                                  value: 'desc',
                                  checked: !_isAscending,
                                  child: Text(S.of(context).descending),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              ];
            },
            body: filteredAndSortedTokens.isEmpty
                ? Center(child: Text(S.of(context).noTokensFound))
                : GridView.builder(
                    padding: const EdgeInsets.all(8.0),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:
                          MediaQuery.of(context).size.width > 700 ? 2 : 1,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      mainAxisExtent: 160,
                    ),
                    itemCount: filteredAndSortedTokens.length,
                    itemBuilder: (context, index) {
                      final token = filteredAndSortedTokens[index];
                      return GestureDetector(
                        onTap: () => showTokenDetails(context, token),
                        child: Card(
                          elevation: 0.5,
                          margin: EdgeInsets.zero,
                          color: Theme.of(context).cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              // Image avec overlay indiquant la présence dans le wallet
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      bottomLeft: Radius.circular(12),
                                    ),
                                    child: SizedBox(
                                      width: 150,
                                      height: double.infinity,
                                      child: kIsWeb
                                          ? ShowNetworkImage(
                                              imageSrc:
                                                  token['imageLink'][0],
                                              mobileBoxFit: BoxFit.cover,
                                              mobileWidth: 150,
                                            )
                                          : CachedNetworkImage(
                                              imageUrl:
                                                  token['imageLink'][0],
                                              width: 150,
                                              height: double.infinity,
                                              fit: BoxFit.cover,
                                              errorWidget: (context, url, error) =>
                                                  const Icon(Icons.error),
                                            ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    left: 0,
                                    child: Builder(
                                      builder: (context) {
                                        final bool isInPortfolio = dataManager.portfolio.any(
                                            (portfolioItem) =>
                                                portfolioItem['uuid']
                                                    .toLowerCase() ==
                                                token['uuid']
                                                    .toLowerCase());
                                        if (isInPortfolio) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.black54,
                                              borderRadius:
                                                  const BorderRadius.only(
                                                bottomRight:
                                                    Radius.circular(8),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize:
                                                  MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.account_balance_wallet,
                                                  color: Theme.of(context)
                                                      .primaryColor,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  S.of(context)
                                                      .presentInWallet,
                                                  style:
                                                      const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        } else {
                                          return const SizedBox();
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              // Informations sur le token
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                if (token['country'] != null)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            right: 8.0),
                                                    child: Image.asset(
                                                      'assets/country/${token['country'].toLowerCase()}.png',
                                                      width: 24,
                                                      height: 24,
                                                      errorBuilder:
                                                          (context, error,
                                                              stackTrace) {
                                                        return const Icon(
                                                            Icons.flag,
                                                            size: 18);
                                                      },
                                                    ),
                                                  ),
                                                Text(
                                                  token['shortName'] ??
                                                      S.of(context)
                                                          .nameUnavailable,
                                                  style:
                                                      const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${S.of(context).assetPrice}: ${currencyUtils.formatCurrency(token['totalInvestment'], currencyUtils.currencySymbol)}',
                                            ),
                                            Text(
                                              '${S.of(context).tokenPrice}: ${currencyUtils.formatCurrency(token['tokenPrice'], currencyUtils.currencySymbol)}',
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              '${S.of(context).expectedYield}: ${token['annualPercentageYield'].toStringAsFixed(2)} %',
                                            ),
                                          ],
                                        ),
                                      ),
                                      Builder(
                                        builder: (context) {
                                          final bool isWhitelisted = dataManager
                                              .whitelistTokens
                                              .any((whitelisted) =>
                                                  whitelisted['token']
                                                      .toLowerCase() ==
                                                  token['uuid']
                                                      .toLowerCase());
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                                top: 2.0, bottom: 1.0),
                                            child: Row(
                                              mainAxisSize:
                                                  MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  isWhitelisted
                                                      ? Icons.check_circle
                                                      : Icons.cancel,
                                                  color: isWhitelisted
                                                      ? Colors.green
                                                      : Colors.red,
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  isWhitelisted
                                                      ? S.of(context)
                                                          .tokenWhitelisted
                                                      : S.of(context)
                                                          .tokenNotWhitelisted,
                                                  style: TextStyle(
                                                    color: isWhitelisted
                                                        ? Colors.green
                                                        : Colors.red,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                      Icons.help_outline,
                                                      size: 18),
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(),
                                                  onPressed: () {
                                                    showDialog(
                                                      context: context,
                                                      builder: (context) =>
                                                          AlertDialog(
                                                        title: Text(S.of(context)
                                                            .whitelistInfoTitle),
                                                        content: Text(S.of(context)
                                                            .whitelistInfoContent),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                    context),
                                                            child: Text(
                                                                S.of(context)
                                                                    .ok),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}
