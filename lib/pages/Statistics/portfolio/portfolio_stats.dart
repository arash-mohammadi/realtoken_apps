import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/pages/Statistics/portfolio/charts/rent_distribution_chart.dart';
import 'package:realtokens/pages/Statistics/portfolio/charts/rented_graph.dart';
import 'package:realtokens/pages/Statistics/portfolio/charts/token_distribution_by_city_card.dart';
import 'package:realtokens/pages/Statistics/portfolio/charts/token_distribution_by_country_card.dart';
import 'package:realtokens/pages/Statistics/portfolio/charts/token_distribution_by_region_card.dart';
import 'package:realtokens/pages/Statistics/portfolio/charts/token_distribution_by_wallet_card.dart';
import 'package:realtokens/pages/Statistics/portfolio/charts/token_distribution_chart.dart';
import 'package:realtokens/utils/data_fetch_utils.dart';
import 'package:realtokens/generated/l10n.dart';

class PortfolioStats extends StatefulWidget {
  const PortfolioStats({super.key});

  @override
  _PortfolioStats createState() => _PortfolioStats();
}

class _PortfolioStats extends State<PortfolioStats> {
  late String _selectedPeriod;
  late String _selectedFilter;
  bool _rentedIsBarChart = true; // Ajoutez cette variable pour gérer le type de graphique

  @override
  void initState() {
    super.initState();
    _selectedFilter = 'Region';
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      try {
        // Vérifier si les données sont déjà disponibles
        final dataManager = Provider.of<DataManager>(context, listen: false);
        
        if (!dataManager.isLoadingMain && dataManager.evmAddresses.isNotEmpty && 
            dataManager.portfolio.isNotEmpty && dataManager.rentHistory.isNotEmpty) {
          debugPrint("📊 Stats: données déjà chargées, skip chargement");
        } else {
          debugPrint("📊 Stats: chargement des données nécessaire");
          await DataFetchUtils.loadDataWithCache(context);
        }
      } catch (e, stacktrace) {
        debugPrint("Error during initState: $e");
        debugPrint("Stacktrace: $stacktrace");
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedPeriod = S.of(context).month;
  }

  @override
  Widget build(BuildContext context) {
    DataManager? dataManager;
    try {
      dataManager = Provider.of<DataManager>(context);
    } catch (e, stacktrace) {
      debugPrint("Error accessing DataManager: $e");
      debugPrint("Stacktrace: $stacktrace");
      return Center(child: Text("Error loading data"));
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 700;
    final double fixedCardHeight = 380;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
            ],
          ),
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Grille pour tous les graphiques
            SliverPadding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 80.0, left: 8.0, right: 8.0),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isWideScreen ? 2 : 1,
                  mainAxisSpacing: 8.0,
                  crossAxisSpacing: 8.0,
                  mainAxisExtent: fixedCardHeight,
                ),
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    switch (index) {
                      case 0:
                        return RentedHistoryGraph(
                          selectedPeriod: _selectedPeriod,
                          onPeriodChanged: (period) {
                            setState(() {
                              _selectedPeriod = period;
                            });
                          },
                          rentedIsBarChart: _rentedIsBarChart,
                          onChartTypeChanged: (isBarChart) {
                            setState(() {
                              _rentedIsBarChart = isBarChart;
                            });
                          },
                        );
                      case 1:
                        return RentDistributionChart(dataManager: dataManager!);
                      case 2:
                        return TokenDistributionCard(dataManager: dataManager!);
                      case 3:
                        return TokenDistributionByCountryCard(dataManager: dataManager!);
                      case 4:
                        return TokenDistributionByRegionCard(dataManager: dataManager!);
                      case 5:
                        return TokenDistributionByCityCard(dataManager: dataManager!);
                      case 6:
                        return TokenDistributionByWalletCard(dataManager: dataManager!);
                      default:
                        return Container();
                    }
                  },
                  childCount: 7,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
