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
        // Cumulez les champs comme `amount`, `totalValue`, `dailyIncome`, `monthlyIncome` et `yearlyIncome`
        groupedPortfolio[shortName]!['amount'] =
            (groupedPortfolio[shortName]!['amount'] as double) + tokenAmount;
        groupedPortfolio[shortName]!['totalValue'] =
            (groupedPortfolio[shortName]!['totalValue'] as double) + tokenValue;
        groupedPortfolio[shortName]!['dailyIncome'] =
            (groupedPortfolio[shortName]!['dailyIncome'] as double) +
                dailyIncome;
        groupedPortfolio[shortName]!['monthlyIncome'] =
            (groupedPortfolio[shortName]!['monthlyIncome'] as double) +
                monthlyIncome;
        groupedPortfolio[shortName]!['yearlyIncome'] =
            (groupedPortfolio[shortName]!['yearlyIncome'] as double) +
                yearlyIncome;

        // Mettre à jour les indicateurs de présence dans le wallet et le RMM
        groupedPortfolio[shortName]!['inWallet'] |= isInWallet;
        groupedPortfolio[shortName]!['inRMM'] |= isInRMM;
      } else {
        // Si c'est un nouveau token, ajoutez-le au groupe et initialisez les valeurs
        groupedPortfolio[shortName] = Map<String, dynamic>.from(token);
        groupedPortfolio[shortName]!['amount'] = tokenAmount;
        groupedPortfolio[shortName]!['totalValue'] = tokenValue;
        groupedPortfolio[shortName]!['dailyIncome'] = dailyIncome;
        groupedPortfolio[shortName]!['monthlyIncome'] = monthlyIncome;
        groupedPortfolio[shortName]!['yearlyIncome'] = yearlyIncome;
        groupedPortfolio[shortName]!['inWallet'] = isInWallet;
        groupedPortfolio[shortName]!['inRMM'] = isInRMM;
      }
    }

    return groupedPortfolio.values.toList();
  }

  // Modifier la méthode pour appliquer le filtre sur le statut de location
  List<Map<String, dynamic>> _filterAndSortPortfolio(
    List<Map<String, dynamic>> portfolio) {
  // Regroupez et cumulez les tokens similaires
  List<Map<String, dynamic>> groupedPortfolio = _groupAndSumPortfolio(portfolio);

  // Filtrez sur fullName, ville et statut de location
  List<Map<String, dynamic>> filteredPortfolio = groupedPortfolio
      .where((token) =>
          token['fullName']
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) &&
          (_selectedCity == null ||
              token['fullName'].contains(_selectedCity!)) &&
          (_rentalStatusFilter == S.of(context).rentalStatusAll ||
              _filterByRentalStatus(token)))
      .toList();

  // Ajoutez le filtre par wallet (si au moins un wallet est sélectionné)
  if (_selectedWallets.isNotEmpty) {
    filteredPortfolio = filteredPortfolio.where((token) {
      // On suppose que token['wallets'] est une liste des adresses associées au token
      List<dynamic> tokenWallets = token['wallets'] ?? [];
      // On garde le token s'il contient au moins un wallet sélectionné
      return tokenWallets.any((wallet) => _selectedWallets.contains(wallet));
    }).toList();
  }

// Filtre par type si l'utilisateur n'a pas sélectionné tous les types
if (!(_selectedTokenTypes.contains("wallet") && _selectedTokenTypes.contains("RMM"))) {
  filteredPortfolio = filteredPortfolio.where((token) {
    // Les tokens regroupés possèdent des indicateurs "inWallet" et "inRMM"
    bool inWallet = token['inWallet'] ?? false;
    bool inRMM = token['inRMM'] ?? false;
    // On conserve le token s'il appartient à un des types sélectionnés
    return (_selectedTokenTypes.contains("wallet") && inWallet) ||
           (_selectedTokenTypes.contains("RMM") && inRMM);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<DataManager>(
        builder: (context, dataManager, child) {
          final sortedFilteredPortfolio =
              _filterAndSortPortfolio(dataManager.portfolio);
          final uniqueCities = _getUniqueCities(dataManager.portfolio);

          return Padding(
            padding: const EdgeInsets.only(top: 0),
            child: NestedScrollView(
              headerSliverBuilder:
                  (BuildContext context, bool innerBoxIsScrolled) {
                return <Widget>[
                  SliverAppBar(
                    floating: true,
                    snap: true,
                    automaticallyImplyLeading: false,
                    expandedHeight: UIUtils.getSliverAppBarHeight(
                        context), // Hauteur étendue
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment
                              .end, // Aligne les éléments vers le bas
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(
                                  2.0), // Ajustez les marges si nécessaire
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: TextField(
                                      onChanged: (value) {
                                        _updateSearchQuery(value);
                                      },
                                      decoration: InputDecoration(
                                        hintText: S
                                            .of(context)
                                            .searchHint, // "Search..."
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
                                  IconButton(
                                    icon: Icon(_isDisplay1
                                        ? Icons.view_module
                                        : Icons.view_list),
                                    onPressed: _toggleDisplay,
                                  ),
                                  const SizedBox(width: 8.0),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.location_city),
                                    onSelected: (String value) {
                                      _updateCityFilter(
                                          value == S.of(context).allCities
                                              ? null
                                              : value);
                                    },
                                    itemBuilder: (BuildContext context) {
                                      return [
                                        PopupMenuItem(
                                          value: S.of(context).allCities,
                                          child: Text(S.of(context).allCities),
                                        ),
                                        ...uniqueCities
                                            .map((city) => PopupMenuItem(
                                                  value: city,
                                                  child: Text(city),
                                                )),
                                      ];
                                    },
                                  ),
                                  const SizedBox(width: 8.0),
                                 PopupMenuButton<String>(
  icon: const Icon(Icons.filter_alt),
  onSelected: (String value) {
    // Gestion des filtres de location (les valeurs commençant par "rental_" déclenchent onSelected)
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
    // Pour les wallets, la gestion se fait via l'InkWell dans l'item (voir ci-dessous)
  },
  itemBuilder: (BuildContext context) {
    final dataManager = Provider.of<DataManager>(context, listen: false);
    // Exemple : récupération des wallets depuis dataManager.evmAddresses
    final List<String> uniqueWallets = dataManager.evmAddresses.toSet().toList();

    return [
      // --- Section filtres par statut de location ---
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
      const PopupMenuDivider(),
      // --- Titre de la section wallets ---
      PopupMenuItem(
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
      // --- Section de sélection des wallets ---
      ...uniqueWallets.map((wallet) => PopupMenuItem(
      enabled: false, // Empêche la fermeture automatique du menu
      child: StatefulBuilder(
        builder: (BuildContext context, StateSetter setStateLocal) {
          return InkWell(
            onTap: () {
              setState(() {
                if (_selectedWallets.contains(wallet)) {
                  _selectedWallets.remove(wallet);
                } else {
                  _selectedWallets.add(wallet);
                }
              });
              setStateLocal(() {}); // Forcer la reconstruction locale
            },
            child: Row(
              children: [
                // Affiche la coche à gauche si le wallet est sélectionné, sinon réserve l'espace
                _selectedWallets.contains(wallet)
                    ? const Icon(Icons.check, size: 20)
                    : const SizedBox(width: 20),
                const SizedBox(width: 8.0),
                const Icon(Icons.account_balance_wallet, size: 20),
                const SizedBox(width: 8.0),
                Flexible(child: Text(wallet)),
              ],
            ),
          );
        },
      ),
    )),

    ];
  },
),
const SizedBox(width: 8.0),
PopupMenuButton<String>(
  icon: const Icon(Icons.category),
  onSelected: (String value) {
    // Cette fonction ne sera pas appelée directement puisque nous gérons
    // la sélection via l'InkWell dans les items (comme pour les wallets).
  },
  itemBuilder: (BuildContext context) {
    return [
      // Titre de la section
      PopupMenuItem(
        enabled: false,
        child: Row(
          children: const [
            Icon(Icons.category, size: 20),
            SizedBox(width: 8.0),
            Text(
              "Type",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      const PopupMenuDivider(),
      // Item pour "Wallet"
      PopupMenuItem(
        enabled: false,
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
                  // Ne jamais laisser le set vide
                  if (_selectedTokenTypes.isEmpty) {
                    _selectedTokenTypes = {"wallet", "RMM"};
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
      // Item pour "RMM"
      PopupMenuItem(
        enabled: false,
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
                  if (_selectedTokenTypes.isEmpty) {
                    _selectedTokenTypes = {"wallet", "RMM"};
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
                  // Vous pouvez choisir une icône différente pour RMM
                  const Icon(Icons.business, size: 20),
                  const SizedBox(width: 8.0),
                  const Text("RMM"),
                ],
              ),
            );
          },
        ),
      ),
    ];
  },
),

                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.sort),
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
                                    itemBuilder: (BuildContext context) {
                                      return [
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
                                          child:
                                              Text(S.of(context).sortByValue),
                                        ),
                                        CheckedPopupMenuItem(
                                          value: S.of(context).sortByAPY,
                                          checked: _sortOption ==
                                              S.of(context).sortByAPY,
                                          child: Text(S.of(context).sortByAPY),
                                        ),
                                        CheckedPopupMenuItem(
                                          value: S
                                              .of(context)
                                              .sortByInitialLaunchDate,
                                          checked: _sortOption ==
                                              S
                                                  .of(context)
                                                  .sortByInitialLaunchDate,
                                          child: Text(S
                                              .of(context)
                                              .sortByInitialLaunchDate),
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
                                      ];
                                    },
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
    );
  }
}
