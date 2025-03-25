import 'package:googleapis/meet/v2.dart';
import 'package:realtokens/utils/data_fetch_utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/utils/text_utils.dart';
import 'package:realtokens/utils/ui_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'portfolio_display_1.dart';
import 'portfolio_display_2.dart';
import 'package:realtokens/generated/l10n.dart'; // Import pour les traductions
import 'package:realtokens/utils/parameters.dart';

class PortfolioPage extends StatefulWidget {
  const PortfolioPage({super.key});

  @override
  PortfolioPageState createState() => PortfolioPageState();
}

class PortfolioPageState extends State<PortfolioPage> {
  bool _isDisplay1 = true;
  String _searchQuery = '';
  String _sortOption = 'sort by recently added';
  bool _isAscending = true;
  String? _selectedCity;
  String? _selectedRegion;
  String? _selectedCountry;
  String _rentalStatusFilter = 'All'; // Nouveau filtre pour le statut de location
  Set<String> _selectedWallets = {};
  Set<String> _selectedTokenTypes = {"wallet", "RMM"};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      DataFetchUtils.loadData(context);
      _loadDisplayPreference();
      _loadFilterPreferences();
    });
  }

  // Charger les préférences d'affichage
  Future<void> _loadDisplayPreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Assurez-vous d'utiliser addPostFrameCallback même ici
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Vérifie que le widget est toujours monté
        setState(() {
          _isDisplay1 = prefs.getBool('isDisplay1') ?? true;
        });
      }
    });
  }

  // Sauvegarder l'affichage
  Future<void> _saveDisplayPreference(bool isDisplay1) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDisplay1', isDisplay1);
  }

  void _toggleDisplay() {
    setState(() {
      _isDisplay1 = !_isDisplay1;
    });
    _saveDisplayPreference(_isDisplay1);
  }

  // Charger les filtres et tri depuis SharedPreferences
  Future<void> _loadFilterPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Assurez-vous d'utiliser addPostFrameCallback même ici
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Vérifie que le widget est toujours monté
        setState(() {
          _sortOption = prefs.getString('sortOption') ??
              S.of(context).sortByInitialLaunchDate;
          _isAscending =
              prefs.getBool('isAscending') ?? false; // Charger l'état de tri
          _selectedCity = prefs.getString('selectedCity')?.isEmpty ?? true
              ? null
              : prefs.getString('selectedCity');
          _selectedRegion = prefs.getString('selectedRegion')?.isEmpty ?? true
              ? null
              : prefs.getString('selectedRegion');
          _selectedCountry = prefs.getString('selectedCountry')?.isEmpty ?? true
              ? null
              : prefs.getString('selectedCountry');
          _rentalStatusFilter = prefs.getString('rentalStatusFilter') ?? 'All';
        });
      }
    });
  }

  // Sauvegarder les filtres et tri dans SharedPreferences
  Future<void> _saveFilterPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('sortOption', _sortOption);
    await prefs.setBool('isAscending', _isAscending);
    await prefs.setString('selectedCity',
        _selectedCity ?? ''); // Sauvegarder la ville sélectionnée
    await prefs.setString('selectedRegion',
        _selectedRegion ?? ''); // Sauvegarder la région sélectionnée
    await prefs.setString('selectedCountry',
        _selectedCountry ?? ''); // Sauvegarder le pays sélectionné
    await prefs.setString('rentalStatusFilter', _rentalStatusFilter);
  }

  // Méthodes de gestion des filtres et tri
  void _updateSearchQuery(String value) {
    setState(() {
      _searchQuery = value;
    });
  }

  void _updateSortOption(String value) {
    setState(() {
      _sortOption = value;
    });
    _saveFilterPreferences(); // Sauvegarde
  }

  void _updateCityFilter(String? value) {
    setState(() {
      _selectedCity = value;
    });
    _saveFilterPreferences(); // Sauvegarde
  }
  
  void _updateRegionFilter(String? value) {
    setState(() {
      _selectedRegion = value;
    });
    _saveFilterPreferences(); // Sauvegarde
  }
  
  void _updateCountryFilter(String? value) {
    setState(() {
      _selectedCountry = value;
    });
    _saveFilterPreferences(); // Sauvegarde
  }

  void _updateRentalStatusFilter(String value) {
    setState(() {
      _rentalStatusFilter = value;
    });
    _saveFilterPreferences(); // Sauvegarde
  }

  List<Map<String, dynamic>> _groupAndSumPortfolio(
      List<Map<String, dynamic>> portfolio) {
    Map<String, Map<String, dynamic>> groupedPortfolio = {};

    for (var token in portfolio) {
      String shortName = token['shortName']; // Utilisez l'identifiant unique
      double tokenAmount = double.tryParse(token['amount'].toString()) ?? 0.0;
      double tokenValue =
          double.tryParse(token['totalValue'].toString()) ?? 0.0;
      double dailyIncome =
          double.tryParse(token['dailyIncome'].toString()) ?? 0.0;
      double monthlyIncome =
          double.tryParse(token['monthlyIncome'].toString()) ?? 0.0;
      double yearlyIncome =
          double.tryParse(token['yearlyIncome'].toString()) ?? 0.0;

      bool isInWallet = token['source'] ==
          'wallet'; // Ajout de la vérification pour le wallet
      bool isInRMM =
          token['source'] == 'RMM'; // Ajout de la vérification pour le RMM

      if (groupedPortfolio.containsKey(shortName)) {
        groupedPortfolio[shortName]!['amount'] =
            (groupedPortfolio[shortName]!['amount'] as double) + tokenAmount;
        groupedPortfolio[shortName]!['totalValue'] =
            (groupedPortfolio[shortName]!['totalValue'] as double) + tokenValue;
        groupedPortfolio[shortName]!['dailyIncome'] =
            (groupedPortfolio[shortName]!['dailyIncome'] as double) + dailyIncome;
        groupedPortfolio[shortName]!['monthlyIncome'] =
            (groupedPortfolio[shortName]!['monthlyIncome'] as double) + monthlyIncome;
        groupedPortfolio[shortName]!['yearlyIncome'] =
            (groupedPortfolio[shortName]!['yearlyIncome'] as double) + yearlyIncome;

        groupedPortfolio[shortName]!['inWallet'] |= isInWallet;
        groupedPortfolio[shortName]!['inRMM'] |= isInRMM;
        // Agrégation des adresses wallet
        if (token['evmAddress'] != null && token['evmAddress'].toString().isNotEmpty) {
          if (groupedPortfolio[shortName]!['evmAddresses'] == null) {
            groupedPortfolio[shortName]!['evmAddresses'] = { token['evmAddress'] };
          } else {
            (groupedPortfolio[shortName]!['evmAddresses'] as Set<String>).add(token['evmAddress']);
          }
        }
      } else {
        groupedPortfolio[shortName] = Map<String, dynamic>.from(token);
        groupedPortfolio[shortName]!['amount'] = tokenAmount;
        groupedPortfolio[shortName]!['totalValue'] = tokenValue;
        groupedPortfolio[shortName]!['dailyIncome'] = dailyIncome;
        groupedPortfolio[shortName]!['monthlyIncome'] = monthlyIncome;
        groupedPortfolio[shortName]!['yearlyIncome'] = yearlyIncome;
        groupedPortfolio[shortName]!['inWallet'] = isInWallet;
        groupedPortfolio[shortName]!['inRMM'] = isInRMM;
        // Initialisation du set d'adresses wallet
        groupedPortfolio[shortName]!['evmAddresses'] = (token['evmAddress'] != null && token['evmAddress'].toString().isNotEmpty) ? { token['evmAddress'] } : <String>{};
      }
    }

    return groupedPortfolio.values.toList();
  }

  // Modifier la méthode pour appliquer le filtre sur le statut de location
  List<Map<String, dynamic>> _filterAndSortPortfolio(
    List<Map<String, dynamic>> portfolio) {
  // Regroupez et cumulez les tokens similaires
  List<Map<String, dynamic>> groupedPortfolio = _groupAndSumPortfolio(portfolio);

  // Filtrez sur différents critères
  List<Map<String, dynamic>> filteredPortfolio = groupedPortfolio
      .where((token) =>
          // Filtre par recherche
          token['fullName']
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) &&
          // Filtre par ville (conservé pour compatibilité)
          (_selectedCity == null ||
              token['fullName'].contains(_selectedCity!)) &&
          // Filtre par région
          (_selectedRegion == null || 
              (token['regionCode'] != null && token['regionCode'] == _selectedRegion)) &&
          // Filtre par pays
          (_selectedCountry == null || 
              (token['country'] != null && token['country'] == _selectedCountry)) &&
          // Filtre par statut de location
          (_rentalStatusFilter == S.of(context).rentalStatusAll ||
              _filterByRentalStatus(token)))
      .toList();

  // Filtre par wallet (si au moins un wallet est sélectionné)
  if (_selectedWallets.isNotEmpty) {
    filteredPortfolio = filteredPortfolio.where((token) {
      // Utiliser la clé 'wallets' qui contient la liste des wallets
      if (token['wallets'] != null) {
        try {
          // Si c'est une liste, la convertir en Set
          if (token['wallets'] is List) {
            var walletsList = token['wallets'] as List;
            Set<String> tokenWallets = walletsList.map((w) => w.toString()).toSet();
            // Vérifier s'il y a une intersection avec les wallets sélectionnés
            return tokenWallets.intersection(_selectedWallets).isNotEmpty;
          } 
          // Si c'est une chaîne unique
          else if (token['wallets'] is String) {
            String wallet = token['wallets'].toString();
            return _selectedWallets.contains(wallet);
          }
        } catch (e) {
          // En cas d'erreur
          print("Erreur lors du filtrage des wallets: $e");
        }
      }
      return false; // Aucun wallet trouvé ou ne correspond
    }).toList();
  }

  // Filtre par type si l'utilisateur n'a pas sélectionné tous les types
  if (_selectedTokenTypes.isEmpty) {
    // Aucun type sélectionné : ne retourner aucun token
    filteredPortfolio = [];
  } else if (!(_selectedTokenTypes.contains("wallet") && _selectedTokenTypes.contains("RMM"))) {
    // Si la sélection n'inclut pas tous les types, appliquer le filtre par token["source"]
    filteredPortfolio = filteredPortfolio.where((token) {
      String tokenType = token['source'] ?? '';
      return _selectedTokenTypes.contains(tokenType);
    }).toList();
  }

  // Tri en fonction des options sélectionnées
  if (_sortOption == S.of(context).sortByName) {
    filteredPortfolio.sort((a, b) => _isAscending
        ? a['shortName'].compareTo(b['shortName'])
        : b['shortName'].compareTo(a['shortName']));
  } else if (_sortOption == S.of(context).sortByValue) {
    filteredPortfolio.sort((a, b) => _isAscending
        ? a['totalValue'].compareTo(b['totalValue'])
        : b['totalValue'].compareTo(a['totalValue']));
  } else if (_sortOption == S.of(context).sortByAPY) {
    filteredPortfolio.sort((a, b) => _isAscending
        ? a['annualPercentageYield'].compareTo(b['annualPercentageYield'])
        : b['annualPercentageYield'].compareTo(a['annualPercentageYield']));
  } else if (_sortOption == S.of(context).sortByInitialLaunchDate) {
    filteredPortfolio.sort((a, b) {
      final dateA = a['initialLaunchDate'] != null
          ? DateTime.tryParse(a['initialLaunchDate'])
          : DateTime(1970);
      final dateB = b['initialLaunchDate'] != null
          ? DateTime.tryParse(b['initialLaunchDate'])
          : DateTime(1970);
      return _isAscending
          ? dateA!.compareTo(dateB!)
          : dateB!.compareTo(dateA!);
    });
  }

  return filteredPortfolio;
}

  // Nouvelle méthode pour filtrer par statut de location
  bool _filterByRentalStatus(Map<String, dynamic> token) {
    int rentedUnits = token['rentedUnits'] ?? 0;
    int totalUnits = token['totalUnits'] ?? 1;

    if (_rentalStatusFilter == S.of(context).rentalStatusRented) {
      return rentedUnits == totalUnits;
    } else if (_rentalStatusFilter ==
        S.of(context).rentalStatusPartiallyRented) {
      return rentedUnits > 0 && rentedUnits < totalUnits;
    } else if (_rentalStatusFilter == S.of(context).rentalStatusNotRented) {
      return rentedUnits == 0;
    }
    return true;
  }

  // Méthode pour obtenir la liste unique des villes à partir des noms complets (fullName)
  List<String> _getUniqueCities(List<Map<String, dynamic>> portfolio) {
    final cities = portfolio
        .map((token) {
          List<String> parts = token['fullName'].split(',');
          return parts.length >= 2
              ? parts[1].trim()
              : S.of(context).unknownCity;
        })
        .toSet()
        .toList();
    cities.sort();
    return cities;
  }
  
  // Méthode pour obtenir la liste unique des régions
  List<String> _getUniqueRegions(List<Map<String, dynamic>> portfolio) {
    final regions = portfolio
        .map((token) => token['regionCode'] ?? "Unknown Region")
        .where((region) => region != null)
        .toSet()
        .cast<String>()
        .toList();
    regions.sort();
    return regions;
  }
  
  // Méthode pour obtenir la liste unique des pays
  List<String> _getUniqueCountries(List<Map<String, dynamic>> portfolio) {
    final countries = portfolio
        .map((token) => token['country'] ?? "Unknown Country")
        .where((country) => country != null)
        .toSet()
        .cast<String>()
        .toList();
    countries.sort();
    return countries;
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery.removeViewPadding(
      context: context,
      removeTop: true,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        extendBodyBehindAppBar: false,
        body: Consumer<DataManager>(
          builder: (context, dataManager, child) {
            final sortedFilteredPortfolio = _filterAndSortPortfolio(dataManager.portfolio);
            final uniqueCities = _getUniqueCities(dataManager.portfolio);
            final uniqueRegions = _getUniqueRegions(dataManager.portfolio);
            final uniqueCountries = _getUniqueCountries(dataManager.portfolio);

            return Padding(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + kToolbarHeight),
              child: NestedScrollView(
                headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                  return <Widget>[
                    SliverAppBar(
                      floating: true,
                      snap: true,
                      automaticallyImplyLeading: false,
                      expandedHeight: UIUtils.getSliverAppBarHeight(context) + 65,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Container(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
                                child: Column(
                                  children: [
                                    // Barre avec recherche et bouton d'affichage
                                    Row(
                                      children: [
                                        // Conteneur de recherche avec bords arrondis
                                        Expanded(
                                          child: Container(
                                            margin: const EdgeInsets.only(bottom: 8, right: 8),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).cardColor,
                                              borderRadius: BorderRadius.circular(24),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.03),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              children: [
                                                // Icône de recherche
                                                Padding(
                                                  padding: const EdgeInsets.only(left: 12.0),
                                                  child: Icon(
                                                    Icons.search,
                                                    color: Theme.of(context).primaryColor,
                                                    size: 18,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                // Champ de recherche
                                                Expanded(
                                                  child: TextField(
                                                    onChanged: (value) {
                                                      _updateSearchQuery(value);
                                                    },
                                                    style: const TextStyle(fontSize: 14),
                                                    decoration: InputDecoration(
                                                      isDense: true,
                                                      hintText: S.of(context).searchHint,
                                                      hintStyle: TextStyle(
                                                        fontSize: 14,
                                                        color: Theme.of(context).textTheme.bodySmall?.color,
                                                      ),
                                                      border: InputBorder.none,
                                                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        
                                        // Bouton d'affichage séparé
                                        Container(
                                          margin: const EdgeInsets.only(bottom: 8),
                                          padding: EdgeInsets.zero,
                                          child: _buildFilterButton(
                                            icon: _isDisplay1 ? Icons.view_module : Icons.view_list,
                                            label: _isDisplay1 ? "Grid" : "List",
                                            onTap: _toggleDisplay,
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    // Ligne des contrôles principaux
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        children: [
                                          // Filtre par Région
                                          _buildFilterPopupMenu(
                                            context: context,
                                            icon: Icons.map,
                                            label: _selectedRegion != null 
                                              ? (Parameters.usStateAbbreviations[_selectedRegion!] ?? _selectedRegion!)
                                              : "Region",
                                            items: [
                                              PopupMenuItem(
                                                value: "all_regions",
                                                child: Text("All Regions"),
                                              ),
                                              ...(_getUniqueRegions(Provider.of<DataManager>(context, listen: false).portfolio)
                                                .map((region) => PopupMenuItem(
                                                  value: region,
                                                  child: Text(Parameters.usStateAbbreviations[region] ?? region),
                                                ))),
                                            ],
                                            onSelected: (String value) {
                                              _updateRegionFilter(
                                                value == "all_regions" ? null : value);
                                            },
                                          ),
                                          
                                          // Filtre par Pays
                                          _buildFilterPopupMenu(
                                            context: context,
                                            icon: Icons.flag,
                                            label: _selectedCountry ?? "Country",
                                            items: [
                                              PopupMenuItem(
                                                value: "all_countries",
                                                child: Text("All Countries"),
                                              ),
                                              ...(_getUniqueCountries(Provider.of<DataManager>(context, listen: false).portfolio)
                                                .map((country) => PopupMenuItem(
                                                  value: country,
                                                  child: Row(
                                                    children: [
                                                      if (country != "Unknown Country") 
                                                        Padding(
                                                          padding: const EdgeInsets.only(right: 8.0),
                                                          child: Image.asset(
                                                            'assets/country/${country.toLowerCase()}.png',
                                                            width: 24,
                                                            height: 16,
                                                            errorBuilder: (context, _, __) => const Icon(Icons.flag, size: 20),
                                                          ),
                                                        ),
                                                      Text(country),
                                                    ],
                                                  ),
                                                ))),
                                            ],
                                            onSelected: (String value) {
                                              _updateCountryFilter(
                                                value == "all_countries" ? null : value);
                                            },
                                          ),
                                          
                                          // Filtres combinés: Statut de location et Type de token
                                          _buildFilterPopupMenu(
                                            context: context,
                                            icon: Icons.filter_alt,
                                            label: _getCombinedFilterLabel(),
                                            items: [
                                              // Section Statut de location
                                              PopupMenuItem(
                                                value: "rental_header",
                                                enabled: false,
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.home_work, size: 20),
                                                    const SizedBox(width: 8.0),
                                                    Text(
                                                      "Statut de location",
                                                      style: TextStyle(fontWeight: FontWeight.bold),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              PopupMenuItem(
                                                value: "rental_all",
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.home_work_outlined, size: 20),
                                                    const SizedBox(width: 8.0),
                                                    Text(S.of(context).rentalStatusAll),
                                                  ],
                                                ),
                                              ),
                                              PopupMenuItem(
                                                value: "rental_rented",
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.check_circle, size: 20, color: Colors.green),
                                                    const SizedBox(width: 8.0),
                                                    Text(S.of(context).rentalStatusRented),
                                                  ],
                                                ),
                                              ),
                                              PopupMenuItem(
                                                value: "rental_partially",
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.adjust, size: 20, color: Colors.orange),
                                                    const SizedBox(width: 8.0),
                                                    Text(S.of(context).rentalStatusPartiallyRented),
                                                  ],
                                                ),
                                              ),
                                              PopupMenuItem(
                                                value: "rental_not",
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.cancel, size: 20, color: Colors.red),
                                                    const SizedBox(width: 8.0),
                                                    Text(S.of(context).rentalStatusNotRented),
                                                  ],
                                                ),
                                              ),
                                              
                                              // Séparateur
                                              const PopupMenuDivider(),
                                              
                                              // Section Type de token
                                              PopupMenuItem(
                                                value: "type_header",
                                                enabled: false,
                                                child: Row(
                                                  children: const [
                                                    Icon(Icons.category, size: 20),
                                                    SizedBox(width: 8.0),
                                                    Text(
                                                      "Type de token",
                                                      style: TextStyle(fontWeight: FontWeight.bold),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              PopupMenuItem(
                                                value: "type_wallet_toggle",
                                                child: StatefulBuilder(
                                                  builder: (context, setStateLocal) {
                                                    return InkWell(
                                                      onTap: () {
                                                        setState(() {
                                                          if (_selectedTokenTypes.contains("wallet")) {
                                                            _selectedTokenTypes.remove("wallet");
                                                          } else {
                                                            _selectedTokenTypes.add("wallet");
                                                          }
                                                        });
                                                        setStateLocal(() {});
                                                      },
                                                      child: Row(
                                                        children: [
                                                          _selectedTokenTypes.contains("wallet")
                                                              ? const Icon(Icons.check, size: 20)
                                                              : const SizedBox(width: 20),
                                                          const SizedBox(width: 8.0),
                                                          const Icon(Icons.account_balance_wallet, size: 20),
                                                          const SizedBox(width: 8.0),
                                                          const Text("Wallet"),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                              PopupMenuItem(
                                                value: "type_rmm_toggle",
                                                child: StatefulBuilder(
                                                  builder: (context, setStateLocal) {
                                                    return InkWell(
                                                      onTap: () {
                                                        setState(() {
                                                          if (_selectedTokenTypes.contains("RMM")) {
                                                            _selectedTokenTypes.remove("RMM");
                                                          } else {
                                                            _selectedTokenTypes.add("RMM");
                                                          }
                                                        });
                                                        setStateLocal(() {});
                                                      },
                                                      child: Row(
                                                        children: [
                                                          _selectedTokenTypes.contains("RMM")
                                                              ? const Icon(Icons.check, size: 20)
                                                              : const SizedBox(width: 20),
                                                          const SizedBox(width: 8.0),
                                                          const Icon(Icons.business, size: 20),
                                                          const SizedBox(width: 8.0),
                                                          const Text("RMM"),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ],
                                            onSelected: (String value) {
                                              if (value.startsWith("rental_")) {
                                                switch (value) {
                                                  case "rental_all":
                                                    _updateRentalStatusFilter(S.of(context).rentalStatusAll);
                                                    break;
                                                  case "rental_rented":
                                                    _updateRentalStatusFilter(S.of(context).rentalStatusRented);
                                                    break;
                                                  case "rental_partially":
                                                    _updateRentalStatusFilter(S.of(context).rentalStatusPartiallyRented);
                                                    break;
                                                  case "rental_not":
                                                    _updateRentalStatusFilter(S.of(context).rentalStatusNotRented);
                                                    break;
                                                }
                                                _saveFilterPreferences();
                                              }
                                            },
                                          ),
                                          
                                          // Filtres Wallet
                                          _buildWalletFilterMenu(
                                            context: context,
                                            icon: Icons.account_balance_wallet,
                                            selectedWallets: _selectedWallets,
                                            onWalletsChanged: (newSelectedWallets) {
                                              setState(() {
                                                _selectedWallets = newSelectedWallets;
                                              });
                                            },
                                          ),
                                          
                                          // Espace flexible pour pousser le tri à droite
                                          const Spacer(),
                                          
                                          // Tri
                                          Container(
                                            margin: EdgeInsets.zero, // Sans marge
                                            child: PopupMenuButton<String>(
                                              tooltip: _getSortLabel(context),
                                              onSelected: (String value) {
                                                if (value == 'asc' || value == 'desc') {
                                                  setState(() {
                                                    _isAscending = (value == 'asc');
                                                  });
                                                  _saveFilterPreferences(); // Sauvegarder après la modification
                                                } else {
                                                  _updateSortOption(value);
                                                }
                                              },
                                              offset: const Offset(0, 40),
                                              elevation: 8,
                                              color: Theme.of(context).cardColor.withOpacity(0.97),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              child: Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.sort,
                                                      size: 20,
                                                      color: Theme.of(context).primaryColor,
                                                    ),
                                                    Icon(
                                                      Icons.arrow_drop_down,
                                                      size: 20,
                                                      color: Theme.of(context).primaryColor,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              itemBuilder: (context) => [
                                                CheckedPopupMenuItem(
                                                  value: S.of(context).sortByName,
                                                  checked: _sortOption == S.of(context).sortByName,
                                                  child: Text(S.of(context).sortByName),
                                                ),
                                                CheckedPopupMenuItem(
                                                  value: S.of(context).sortByValue,
                                                  checked: _sortOption == S.of(context).sortByValue,
                                                  child: Text(S.of(context).sortByValue),
                                                ),
                                                CheckedPopupMenuItem(
                                                  value: S.of(context).sortByAPY,
                                                  checked: _sortOption == S.of(context).sortByAPY,
                                                  child: Text(S.of(context).sortByAPY),
                                                ),
                                                CheckedPopupMenuItem(
                                                  value: S.of(context).sortByInitialLaunchDate,
                                                  checked: _sortOption == S.of(context).sortByInitialLaunchDate,
                                                  child: Text(S.of(context).sortByInitialLaunchDate),
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
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  ];
                },
                body: _isDisplay1
                    ? PortfolioDisplay1(portfolio: sortedFilteredPortfolio)
                    : PortfolioDisplay2(portfolio: sortedFilteredPortfolio),
              ),
            );
          },
        ),
      ),
    );
  }
  
  // Helper pour construire un bouton de filtre simple
  Widget _buildFilterButton({
    required IconData icon,
    required String label, // Conservé pour tooltip
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: Tooltip(
          message: label,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 20,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // Helper pour les boutons popup de filtre
  Widget _buildFilterPopupMenu({
    required BuildContext context,
    required IconData icon,
    required String label, // Conservé pour tooltip
    required List<PopupMenuEntry<String>> items,
    required Function(String) onSelected,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: PopupMenuButton<String>(
        tooltip: label,
        onSelected: onSelected,
        offset: const Offset(0, 40),
        elevation: 8,
        color: Theme.of(context).cardColor.withOpacity(0.97),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: Theme.of(context).primaryColor,
              ),
              Icon(
                Icons.arrow_drop_down,
                size: 20,
                color: Theme.of(context).primaryColor,
              ),
            ],
          ),
        ),
        itemBuilder: (context) => items,
      ),
    );
  }
  
  // Helper pour obtenir le label du tri actuel
  String _getSortLabel(BuildContext context) {
    if (_sortOption == S.of(context).sortByName) {
      return "Name";
    } else if (_sortOption == S.of(context).sortByValue) {
      return "Value";
    } else if (_sortOption == S.of(context).sortByAPY) {
      return "APY";
    } else {
      return "Date";
    }
  }
  
  // Helper pour obtenir le label du statut de location
  String _getRentalStatusLabel(BuildContext context) {
    if (_rentalStatusFilter == S.of(context).rentalStatusAll) {
      return "Status";
    } else if (_rentalStatusFilter == S.of(context).rentalStatusRented) {
      return "Rented";
    } else if (_rentalStatusFilter == S.of(context).rentalStatusPartiallyRented) {
      return "Partially";
    } else {
      return "Not Rented";
    }
  }

  // Helper pour obtenir le label des filtres combinés
  String _getCombinedFilterLabel() {
    // Par défaut, afficher "Filtres"
    String baseLabel = "Filtres";
    
    // Ajouter des indications si des filtres sont actifs
    List<String> activeFilters = [];
    
    // Vérifier le statut de location
    if (_rentalStatusFilter != S.of(context).rentalStatusAll) {
      if (_rentalStatusFilter == S.of(context).rentalStatusRented) {
        activeFilters.add("R");
      } else if (_rentalStatusFilter == S.of(context).rentalStatusPartiallyRented) {
        activeFilters.add("P");
      } else {
        activeFilters.add("NR");
      }
    }
    
    // Vérifier les types de token
    if (!(_selectedTokenTypes.contains("wallet") && _selectedTokenTypes.contains("RMM"))) {
      if (_selectedTokenTypes.contains("wallet") && !_selectedTokenTypes.contains("RMM")) {
        activeFilters.add("W");
      } else if (!_selectedTokenTypes.contains("wallet") && _selectedTokenTypes.contains("RMM")) {
        activeFilters.add("RMM");
      }
    }
    
    // Si des filtres sont actifs, les ajouter au label
    if (activeFilters.isNotEmpty) {
      return "${activeFilters.join('+')}";
    }
    
    return baseLabel;
  }

  // Filtres Wallet
  Widget _buildWalletFilterMenu({
    required BuildContext context,
    required IconData icon,
    required Set<String> selectedWallets,
    required Function(Set<String>) onWalletsChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: PopupMenuButton<String>(
        tooltip: "Wallets",
        onSelected: (String value) {
          if (value == "apply_wallets") {
            // Gérer la sélection directe (au cas où StatefulBuilder ne fonctionne pas comme prévu)
            onWalletsChanged(selectedWallets);
          }
        },
        offset: const Offset(0, 40),
        elevation: 8,
        color: Theme.of(context).cardColor.withOpacity(0.97),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: Theme.of(context).primaryColor,
              ),
              Icon(
                Icons.arrow_drop_down,
                size: 20,
                color: Theme.of(context).primaryColor,
              ),
            ],
          ),
        ),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: "wallet_header",
            enabled: false,
            child: Row(
              children: const [
                Icon(Icons.account_balance_wallet, size: 20),
                SizedBox(width: 8.0),
                Text(
                  "Wallets",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const PopupMenuDivider(),
          ...Provider.of<DataManager>(context, listen: false).evmAddresses
            .toSet()
            .toList()
            .map((wallet) => PopupMenuItem(
            value: wallet,
            child: StatefulBuilder(
              builder: (context, setStateLocal) {
                return InkWell(
                  onTap: () {
                    setState(() {
                      if (selectedWallets.contains(wallet)) {
                        selectedWallets.remove(wallet);
                      } else {
                        selectedWallets.add(wallet);
                      }
                    });
                    setStateLocal(() {});
                  },
                  child: Row(
                    children: [
                      selectedWallets.contains(wallet)
                          ? const Icon(Icons.check, size: 20)
                          : const SizedBox(width: 20),
                      const SizedBox(width: 8.0),
                      const Icon(Icons.account_balance_wallet, size: 20),
                      const SizedBox(width: 8.0),
                      Flexible(child: Text(wallet.length > 15 
                          ? '${wallet.substring(0, 6)}...${wallet.substring(wallet.length - 4)}'
                          : wallet)),
                    ],
                  ),
                );
              },
            ),
          )),
          // Bouton pour fermer/appliquer
          const PopupMenuDivider(),
          PopupMenuItem(
            value: "apply_wallets",
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text("Appliquer"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
