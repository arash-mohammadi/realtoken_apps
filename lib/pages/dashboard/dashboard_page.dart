import 'package:realtokens/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import pour SharedPreferences
import 'package:realtokens/api/data_manager.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:shimmer/shimmer.dart';
import '/settings/manage_evm_addresses_page.dart'; // Import de la page pour gérer les adresses EVM
import 'dashboard_details_page.dart';
import 'package:realtokens/app_state.dart'; // Import AppState

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  DashboardPageState createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage> {
  bool _showAmounts = true; // Variable pour contrôler la visibilité des montants
  bool _isPageLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrivacyMode();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Utils.loadData(context);
      setState(() {
        _isPageLoading = false; // Indique que la page a fini de charger
      });
    });
  }

  // Méthode pour basculer l'état de visibilité des montants
  void _toggleAmountsVisibility() async {
    setState(() {
      _showAmounts = !_showAmounts;
    });
    // Sauvegarder l'état du mode "confidentialité" dans SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showAmounts', _showAmounts);
  }

  // Charger l'état du mode "confidentialité" depuis SharedPreferences
  Future<void> _loadPrivacyMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _showAmounts = prefs.getBool('showAmounts') ?? true; // Par défaut, les montants sont visibles
    });
  }

  // Récupère la dernière valeur de loyer
  String _getLastRentReceived(DataManager dataManager) {
    final rentData = dataManager.rentData;

    if (rentData.isEmpty) {
      return S.of(context).noRentReceived;
    }

    rentData.sort((a, b) => DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));
    final lastRent = rentData.first['rent'];

    // Utiliser _getFormattedAmount pour masquer ou afficher la valeur
    return Utils.getFormattedAmount(dataManager.convert(lastRent), dataManager.currencySymbol, _showAmounts);
  }

  // Groupement mensuel sur les 12 derniers mois glissants pour la carte Rendement
  List<double> _getLast12MonthsRent(DataManager dataManager) {
    final currentDate = DateTime.now();
    final rentData = dataManager.rentData;

    Map<String, double> monthlyRent = {};

    for (var rentEntry in rentData) {
      DateTime date = DateTime.parse(rentEntry['date']);
      // Exclure le mois en cours et ne garder que les données des 12 mois précédents
      if (date.isBefore(DateTime(currentDate.year, currentDate.month)) && date.isAfter(DateTime(currentDate.year, currentDate.month - 12, 1))) {
        String monthKey = DateFormat('yyyy-MM').format(date);
        monthlyRent[monthKey] = (monthlyRent[monthKey] ?? 0) + rentEntry['rent'];
      }
    }

    // Assurer que nous avons les 12 derniers mois dans l'ordre (sans le mois en cours)
    List<String> sortedMonths = List.generate(12, (index) {
      DateTime date = DateTime(currentDate.year, currentDate.month - 1 - index, 1); // Commence à partir du mois précédent
      return DateFormat('yyyy-MM').format(date);
    }).reversed.toList();

    return sortedMonths.map((month) => monthlyRent[month] ?? 0).toList();
  }

  double _getPortfolioBarGraphData(DataManager dataManager) {
    // Calcul du pourcentage de rentabilité (ROI)
    return (dataManager.roiGlobalValue); // ROI en %
  }

  Widget _buildPieChart(double rentedPercentage, BuildContext context) {
    return SizedBox(
      width: 120, // Largeur du camembert
      height: 70, // Hauteur du camembert
      child: PieChart(
        PieChartData(
          startDegreeOffset: -90, // Pour placer la petite section en haut
          sections: [
            PieChartSectionData(
              value: rentedPercentage,
              color: Colors.green, // Couleur pour les unités louées
              title: '',
              radius: 23, // Taille de la section louée
              titleStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              gradient: LinearGradient(
                colors: [Colors.green.shade300, Colors.green.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            PieChartSectionData(
              value: 100 - rentedPercentage,
              color: Colors.blue, // Couleur pour les unités non louées
              title: '',
              radius: 17, // Taille de la section non louée
              gradient: LinearGradient(
                colors: [Colors.blue.shade300, Colors.blue.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ],
          borderData: FlBorderData(show: false),
          sectionsSpace: 2, // Un léger espace entre les sections pour les démarquer
          centerSpaceRadius: 23, // Taille de l'espace central
        ),
        swapAnimationDuration: const Duration(milliseconds: 800), // Durée de l'animation
        swapAnimationCurve: Curves.easeInOut, // Courbe pour rendre l'animation fluide
      ),
    );
  }

  Widget _buildVerticalGauges(double factor, BuildContext context, DataManager dataManager) {
    double progress1 = (factor / 10).clamp(0.0, 1.0); // Jauge 1
    double progress2 =
        ((dataManager.totalUsdcBorrowBalance + dataManager.totalXdaiBorrowBalance) / dataManager.rmmValue * 100).clamp(0.0, 100.0) / 100; // Jauge 2 (en %)

    // Couleur dynamique pour la première jauge
    Color progress1Color = Color.lerp(Colors.red, Colors.green, progress1)!;

    // Couleur dynamique pour la deuxième jauge (0% = vert, 100% = rouge)
    Color progress2Color = Color.lerp(Colors.green.shade300, Colors.red, progress2)!;

    return SizedBox(
      width: 100, // Largeur totale pour la disposition
      height: 180, // Hauteur totale
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Jauge 1 (HF)
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Titre de la jauge
              Text(
                'HF',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 8), // Espacement entre le titre et la jauge
              Stack(
                alignment: Alignment.bottomCenter, // Alignement pour jauge verticale
                children: [
                  // Fond de la jauge
                  Container(
                    width: 20, // Largeur fixe pour jauge verticale
                    height: 100, // Hauteur totale de la jauge
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 78, 78, 78).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  // Progression de la jauge
                  Container(
                    width: 20, // Largeur fixe pour jauge verticale
                    height: progress1 * 100, // Hauteur dynamique
                    decoration: BoxDecoration(
                      color: progress1Color, // Couleur dynamique
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5), // Espacement entre la jauge et le texte
              Text(
                '${(progress1 * 10).toStringAsFixed(1)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          // Jauge 2 (LTV)
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Titre de la jauge
              Text(
                'LTV',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 8), // Espacement entre le titre et la jauge
              Stack(
                alignment: Alignment.bottomCenter, // Alignement pour jauge verticale
                children: [
                  // Fond de la jauge
                  Container(
                    width: 20, // Largeur fixe pour jauge verticale
                    height: 100, // Hauteur totale de la jauge
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 78, 78, 78).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  // Progression de la jauge
                  Container(
                    width: 20, // Largeur fixe pour jauge verticale
                    height: progress2 * 100, // Hauteur dynamique
                    decoration: BoxDecoration(
                      color: progress2Color, // Couleur dynamique
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5), // Espacement entre la jauge et le texte
              Text(
                '${(progress2 * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Méthode pour créer un graphique en barres en tant que jauge
  Widget _buildVerticalGauge(double value, BuildContext context) {
    // Utiliser une valeur par défaut si 'value' est NaN ou négatif
    double displayValue = value.isNaN || value < 0 ? 0 : value;

    return Padding(
      padding: const EdgeInsets.only(right: 1.0),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Ajuster la taille de la colonne au contenu
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "ROI", // Titre de la jauge
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
              const SizedBox(width: 8), // Espacement entre le texte et l'icône
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(S.of(context).roiPerProperties), // Titre du popup
                        content: Text(S.of(context).roiAlertInfo), // Texte du popup
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(); // Fermer le popup
                            },
                            child: Text('OK'),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Icon(
                  Icons.info_outline, // Icône à afficher
                  size: 15, // Taille de l'icône
                  color: Colors.grey, // Couleur de l'icône
                ),
              ),
            ],
          ),
          const SizedBox(height: 8), // Espacement entre le titre et la jauge
          SizedBox(
            height: 100, // Hauteur totale de la jauge
            width: 90, // Largeur de la jauge
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.center,
                maxY: 100, // Échelle sur 100%
                barTouchData: BarTouchData(
                  enabled: true, // Activer l'interaction pour l'animation au toucher
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toStringAsFixed(1)}%',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value % 25 == 0) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(fontSize: 10, color: Colors.black54), // Définir la taille et couleur du texte
                          );
                        }
                        return Container();
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: false), // Désactiver la grille
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: displayValue, // Utiliser la valeur corrigée
                        width: 20, // Largeur de la barre
                        borderRadius: BorderRadius.circular(4), // Bordures arrondies
                        color: Colors.transparent, // Couleur transparente pour appliquer le dégradé
                        gradient: LinearGradient(
                          colors: [Colors.blueAccent, Colors.lightBlueAccent],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: 100, // Fond de la jauge
                          color: const Color.fromARGB(255, 78, 78, 78).withOpacity(0.3), // Couleur du fond grisé
                        ),
                        rodStackItems: [
                          BarChartRodStackItem(0, displayValue, Colors.blueAccent.withOpacity(0.6)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8), // Espacement entre le titre et la jauge
          Text(
            "${displayValue.toStringAsFixed(1)}%", // Valeur de la barre affichée en dessous
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.blue, // Même couleur que la barre
            ),
          ),
        ],
      ),
    );
  }

  // Méthode pour créer un mini graphique pour la carte Rendement
  Widget _buildMiniGraphForRendement(List<double> data, BuildContext context, DataManager dataManager) {
    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        height: 70,
        width: 120,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            minX: 0,
            maxX: data.length.toDouble() - 1,
            minY: data.reduce((a, b) => a < b ? a : b),
            maxY: data.reduce((a, b) => a > b ? a : b),
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(data.length, (index) {
                  double roundedValue = double.parse(dataManager.convert(data[index]).toStringAsFixed(2));
                  return FlSpot(index.toDouble(), roundedValue);
                }),
                isCurved: true,
                barWidth: 2,
                color: Colors.blue,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                    radius: 2,
                    color: Colors.blue,
                    strokeWidth: 0,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.withOpacity(0.4), // Couleur plus opaque en haut
                      Colors.blue.withOpacity(0), // Couleur plus transparente en bas
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
            // Ajout de LineTouchData pour le tooltip
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (List<LineBarSpot> touchedSpots) {
                  return touchedSpots.map((touchedSpot) {
                    final flSpot = touchedSpot;
                    return LineTooltipItem(
                      '${flSpot.y.toStringAsFixed(2)} ${dataManager.currencySymbol}', // Utiliser currencySymbol de dataManager
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }).toList();
                },
              ),
              handleBuiltInTouches: true,
            ),
          ),
        ),
      ),
    );
  }

  // Construction des cartes du Dashboard
  Widget _buildCard(
    String title,
    IconData icon,
    Widget firstChild,
    List<Widget> otherChildren,
    DataManager dataManager,
    BuildContext context, {
    bool hasGraph = false,
    Widget? rightWidget, // Ajout du widget pour le graphique
  }) {
    final appState = Provider.of<AppState>(context);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0,
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      icon,
                      size: 24 + appState.getTextSizeOffset(),
                      color: _getIconColor(title, context), // Appelle une fonction pour déterminer la couleur
                    ),
                    const SizedBox(width: 8), // Espacement entre l'icône et le texte
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 19 + appState.getTextSizeOffset(),
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(width: 12), // Espacement entre le texte et l'icône
                    if (title == S.of(context).rents)
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const DashboardRentsDetailsPage(),
                            ),
                          );
                        },
                        child: Icon(
                          Icons.arrow_forward,
                          size: 24, // Taille de l'icône
                          color: Colors.grey, // Couleur de l'icône
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                firstChild,
                const SizedBox(height: 3),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: otherChildren,
                ),
              ],
            ),
            const Spacer(),
            if (hasGraph && rightWidget != null) rightWidget, // Affiche le graphique
          ],
        ),
      ),
    );
  }

  Widget _buildTextWithShimmer(String? value, String label, bool isLoading, BuildContext context) {
    final theme = Theme.of(context);

    // Couleurs pour le shimmer adaptées au thème
    final baseColor = theme.textTheme.bodyMedium?.color?.withOpacity(0.2) ?? Colors.grey[300]!;
    final highlightColor = theme.textTheme.bodyMedium?.color?.withOpacity(0.4) ?? Colors.grey[100]!;

    return Row(
      children: [
        // Partie label statique
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            color: theme.textTheme.bodyMedium?.color,
          ),
        ),
        // Partie valeur dynamique avec ou sans shimmer
        isLoading
            ? Shimmer.fromColors(
                baseColor: baseColor,
                highlightColor: highlightColor,
                child: Container(
                  width: 100, // Largeur du shimmer
                  height: 16, // Hauteur du shimmer
                  color: baseColor,
                ),
              )
            : Text(
                value ?? '',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
      ],
    );
  }

  // Construction d'une ligne pour afficher la valeur avant le texte
  Widget _buildValueBeforeText(String? value, String text, bool isLoading, {bool highlightPercentage = false}) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context); // Accéder au thème actuel

    // Définir les couleurs en fonction du thème
    final baseColor = theme.textTheme.bodyMedium?.color?.withOpacity(0.2) ?? Colors.grey[300]!;
    final highlightColor = theme.textTheme.bodyMedium?.color?.withOpacity(0.6) ?? Colors.grey[100]!;

    String percentageText = '';
    Color percentageColor = theme.textTheme.bodyLarge?.color ?? Colors.black;

    if (highlightPercentage) {
      final regex = RegExp(r'\(([-+]?\d+)%\)'); // Extraction de la valeur entre parenthèses
      final match = regex.firstMatch(text);
      if (match != null) {
        percentageText = match.group(1)!;
        final percentageValue = double.tryParse(percentageText) ?? 0;
        percentageColor = percentageValue >= 0 ? Colors.green : Colors.red;
      }
    }

    return Row(
      children: [
        isLoading
            ? Shimmer.fromColors(
                baseColor: baseColor, // Couleur de fond du shimmer
                highlightColor: highlightColor, // Couleur d'éclaircissement du shimmer
                child: Container(
                  width: 50, // Largeur placeholder pour la valeur
                  height: 16, // Hauteur placeholder pour la valeur
                  color: baseColor, // Couleur de fond
                ),
              )
            : Text(
                value ?? '',
                style: TextStyle(
                  fontSize: 16 + appState.getTextSizeOffset(),
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color, // Couleur par défaut
                ),
              ),
        const SizedBox(width: 6),
        highlightPercentage && percentageText.isNotEmpty
            ? RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: text.split('(').first, // Texte avant les parenthèses
                      style: TextStyle(
                        fontSize: 13 + appState.getTextSizeOffset(),
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    TextSpan(
                      text: '($percentageText%)', // Texte entre parenthèses
                      style: TextStyle(
                        fontSize: 13 + appState.getTextSizeOffset(),
                        color: percentageColor, // Vert si positif, rouge si négatif
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            : Text(
                text,
                style: TextStyle(
                  fontSize: 13 + appState.getTextSizeOffset(),
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
      ],
    );
  }

  Widget _buildNoWalletCard(BuildContext context) {
    return Center(
      // Centrer la carte horizontalement
      child: Card(
        color: Colors.orange[200], // Couleur d'alerte
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Ajuster la taille de la colonne au contenu
            crossAxisAlignment: CrossAxisAlignment.center, // Centrer le contenu horizontalement
            children: [
              Text(
                S.of(context).noDataAvailable, // Utilisation de la traduction pour "Aucun wallet trouvé"
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center, // Centrer le texte
              ),
              const SizedBox(height: 10),
              Center(
                // Centrer le bouton dans la colonne
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ManageEvmAddressesPage(), // Ouvre la page de gestion des adresses
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue, // Texte blanc et fond bleu
                  ),
                  child: Text(S.of(context).manageAddresses), // Texte du bouton
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);
    final appState = Provider.of<AppState>(context);

    IconButton visibilityButton = IconButton(
      icon: Icon(_showAmounts ? Icons.visibility : Icons.visibility_off),
      onPressed: _toggleAmountsVisibility,
    );

    final lastRentReceived = _getLastRentReceived(dataManager);
    final totalRentReceived = Utils.getFormattedAmount(dataManager.convert(dataManager.getTotalRentReceived()), dataManager.currencySymbol, _showAmounts);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => Utils.refreshData(context),
            displacement: 100,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.only(top: Utils.getAppBarHeight(context), left: 8.0, right: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          S.of(context).hello,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
                        ),
                        visibilityButton,
                      ],
                    ),
                    if (!_isPageLoading && (dataManager.rentData.isEmpty || dataManager.walletValue == 0)) _buildNoWalletCard(context),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        children: [
                          // Partie statique pour "Last Rent Received"
                          TextSpan(
                            text: S.of(context).lastRentReceived,
                            style: TextStyle(
                              fontSize: 15 + appState.getTextSizeOffset(),
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                          // Partie dynamique avec ou sans shimmer pour "lastRentReceived"
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: dataManager.isLoading
                                ? Shimmer.fromColors(
                                    baseColor: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6) ?? Colors.grey[300]!,
                                    highlightColor: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.9) ?? Colors.grey[100]!,
                                    child: Container(
                                      width: 100, // Largeur placeholder
                                      height: 20, // Hauteur placeholder
                                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.2),
                                    ),
                                  )
                                : Text(
                                    lastRentReceived,
                                    style: TextStyle(
                                      fontSize: 18 + appState.getTextSizeOffset(),
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                          ),
                          // Partie statique pour "Total Rent Received"
                          TextSpan(
                            text: '\n${S.of(context).totalRentReceived}: ',
                            style: TextStyle(
                              fontSize: 16 + appState.getTextSizeOffset(),
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                          // Partie dynamique avec ou sans shimmer pour "totalRentReceived"
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: dataManager.isLoading
                                ? Shimmer.fromColors(
                                    baseColor: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.2) ?? Colors.grey[300]!,
                                    highlightColor: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.4) ?? Colors.grey[100]!,
                                    child: Container(
                                      width: 100, // Largeur placeholder
                                      height: 16, // Hauteur placeholder
                                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.2),
                                    ),
                                  )
                                : Text(
                                    totalRentReceived,
                                    style: TextStyle(
                                      fontSize: 18 + appState.getTextSizeOffset(),
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildCard(
                      S.of(context).portfolio,
                      Icons.dashboard,
                      _buildValueBeforeText(
                        Utils.getFormattedAmount(
                            dataManager.convert(dataManager.yamTotalValue +
                                dataManager.rwaHoldingsValue +
                                dataManager.totalUsdcDepositBalance +
                                dataManager.totalXdaiDepositBalance -
                                dataManager.totalUsdcBorrowBalance -
                                dataManager.totalXdaiBorrowBalance),
                            dataManager.currencySymbol,
                            _showAmounts),
                        'projection YAM (${(((dataManager.yamTotalValue + dataManager.rwaHoldingsValue + dataManager.totalUsdcDepositBalance + dataManager.totalXdaiDepositBalance - dataManager.totalUsdcBorrowBalance - dataManager.totalXdaiBorrowBalance) / dataManager.totalWalletValue - 1) * 100).toStringAsFixed(0)}%)',
                        dataManager.isLoading,
                        highlightPercentage: true, // Activer la coloration conditionnelle
                      ),
                      [
                        _buildValueBeforeText(
                            Utils.getFormattedAmount(dataManager.convert(dataManager.totalWalletValue), dataManager.currencySymbol, _showAmounts),
                            S.of(context).totalPortfolio,
                            dataManager.isLoading),
                        _buildIndentedBalance(S.of(context).wallet, dataManager.convert(dataManager.walletValue), dataManager.currencySymbol, true, context,
                            dataManager.isLoading),
                        _buildIndentedBalance(
                            S.of(context).rmm, dataManager.convert(dataManager.rmmValue), dataManager.currencySymbol, true, context, dataManager.isLoading),
                        _buildIndentedBalance(S.of(context).rwaHoldings, dataManager.convert(dataManager.rwaHoldingsValue), dataManager.currencySymbol, true,
                            context, dataManager.isLoading),
                        const SizedBox(height: 10),
                        _buildIndentedBalance(
                            S.of(context).depositBalance,
                            dataManager.convert(dataManager.totalUsdcDepositBalance + dataManager.totalXdaiDepositBalance),
                            dataManager.currencySymbol,
                            true,
                            context,
                            dataManager.isLoading),
                        _buildIndentedBalance(
                            S.of(context).borrowBalance,
                            dataManager.convert(dataManager.totalUsdcBorrowBalance + dataManager.totalXdaiBorrowBalance),
                            dataManager.currencySymbol,
                            false,
                            context,
                            dataManager.isLoading),
                      ],
                      dataManager,
                      context,
                      hasGraph: true,
                      rightWidget: _buildVerticalGauge(_getPortfolioBarGraphData(dataManager), context),
                    ),
                    const SizedBox(height: 8),
                    if (!dataManager.isLoading &&
                        (dataManager.rmmValue != 0 ||
                            dataManager.totalUsdcBorrowBalance != 0 ||
                            dataManager.totalXdaiBorrowBalance != 0 ||
                            dataManager.totalXdaiDepositBalance != 0 ||
                            dataManager.totalUsdcDepositBalance != 0))
                      _buildCard(
                        S.of(context).rmm,
                        Icons.currency_exchange,
                        _buildValueBeforeText(
                            ((dataManager.rmmValue * 0.7) / (dataManager.totalUsdcBorrowBalance + dataManager.totalXdaiBorrowBalance)).toStringAsFixed(1),
                            'Health factor',
                            dataManager.isLoading),
                        [
                          _buildValueBeforeText(
                              ((dataManager.totalUsdcBorrowBalance + dataManager.totalXdaiBorrowBalance) / dataManager.rmmValue * 100).toStringAsFixed(1),
                              'Current LTV',
                              dataManager.isLoading),
                          const SizedBox(height: 10),
                          Text(
                            '${S.of(context).timeBeforeLiquidation}: ${_calculateTimeBeforeLiquidationFormatted(
                              dataManager.rmmValue,
                              dataManager.totalUsdcBorrowBalance,
                              dataManager.totalXdaiBorrowBalance,
                              dataManager.usdcDepositApy,
                            )}',
                            style: TextStyle(
                              fontSize: 13 + appState.getTextSizeOffset(),
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          _buildTextWithShimmer(
                            Utils.getFormattedAmount(dataManager.convert(dataManager.totalXdaiDepositBalance), dataManager.currencySymbol, _showAmounts),
                            'Xdai ${S.of(context).depositBalance}',
                            dataManager.isLoading,
                            context,
                          ),
                          _buildTextWithShimmer(
                            Utils.getFormattedAmount(dataManager.convert(dataManager.totalUsdcDepositBalance), dataManager.currencySymbol, _showAmounts),
                            'USDC ${S.of(context).depositBalance}',
                            dataManager.isLoading,
                            context,
                          ),
                          _buildTextWithShimmer(
                            Utils.getFormattedAmount(dataManager.convert(dataManager.totalUsdcBorrowBalance), dataManager.currencySymbol, _showAmounts),
                            'USDC ${S.of(context).borrowBalance}',
                            dataManager.isLoading,
                            context,
                          ),
                          _buildTextWithShimmer(
                            Utils.getFormattedAmount(dataManager.convert(dataManager.totalXdaiBorrowBalance), dataManager.currencySymbol, _showAmounts),
                            'Xdai ${S.of(context).borrowBalance}',
                            dataManager.isLoading,
                            context,
                          ),
                        ],
                        dataManager,
                        context,
                        hasGraph: true,
                        rightWidget: Builder(
                          builder: (context) {
                            double factor = (dataManager.rmmValue * 0.7) / (dataManager.totalUsdcBorrowBalance + dataManager.totalXdaiBorrowBalance);
                            factor = factor.isNaN || factor < 0 ? 0 : factor.clamp(0.0, 10.0);

                            return _buildVerticalGauges(factor, context, dataManager);
                          },
                        ),
                      ),
                    const SizedBox(height: 8),
                    _buildCard(
                      S.of(context).properties,
                      Icons.home,
                      _buildValueBeforeText(
                          '${(dataManager.rentedUnits / dataManager.totalUnits * 100).toStringAsFixed(2)}%', S.of(context).rented, dataManager.isLoading),
                      [
                        _buildTextWithShimmer(
                          '${dataManager.totalTokenCount}',
                          S.of(context).properties,
                          dataManager.isLoading,
                          context,
                        ),
                        _buildTextWithShimmer(
                          '${dataManager.walletTokenCount}',
                          S.of(context).wallet,
                          dataManager.isLoading,
                          context,
                        ),
                        Row(
                          children: [
                            _buildTextWithShimmer(
                              '${dataManager.rmmTokenCount.toInt()}',
                              S.of(context).rmm,
                              dataManager.isLoading,
                              context,
                            ),
                            SizedBox(width: 6),
                            GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text(S.of(context).duplicate_title), // Titre de la popup
                                      content: Text(
                                        '${dataManager.duplicateTokenCount.toInt()} ${S.of(context).duplicate}', // Contenu de la popup
                                        style: TextStyle(fontSize: 13 + appState.getTextSizeOffset()),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop(); // Fermer la popup
                                          },
                                          child: Text(S.of(context).close), // Bouton de fermeture
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              child: Icon(Icons.info_outline, size: 15), // Icône sans padding implicite
                            ),
                          ],
                        ),
                        _buildTextWithShimmer(
                          '${dataManager.rentedUnits} / ${dataManager.totalUnits}',
                          S.of(context).rentedUnits,
                          dataManager.isLoading,
                          context,
                        ),
                      ],
                      dataManager,
                      context,
                      hasGraph: true,
                      rightWidget: Builder(
                        builder: (context) {
                          double rentedPercentage = dataManager.rentedUnits / dataManager.totalUnits * 100;
                          if (rentedPercentage.isNaN || rentedPercentage < 0) {
                            rentedPercentage = 0; // Remplacer NaN par une valeur par défaut comme 0
                          }
                          return _buildPieChart(rentedPercentage, context); // Ajout du camembert avec la vérification
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildCard(
                      S.of(context).tokens,
                      Icons.account_balance_wallet,
                      _buildValueBeforeText(dataManager.totalTokens.toStringAsFixed(2), S.of(context).totalTokens, dataManager.isLoading),
                      [
                        _buildTextWithShimmer(
                          dataManager.walletTokensSums.toStringAsFixed(2),
                          S.of(context).wallet,
                          dataManager.isLoading,
                          context,
                        ),
                        _buildTextWithShimmer(
                          dataManager.rmmTokensSums.toStringAsFixed(2),
                          S.of(context).rmm,
                          dataManager.isLoading,
                          context,
                        ),
                      ],
                      dataManager,
                      context,
                      hasGraph: true,
                      rightWidget: Builder(
                        builder: (context) {
                          double rentedPercentage = dataManager.walletTokensSums / dataManager.totalTokens * 100;
                          if (rentedPercentage.isNaN || rentedPercentage < 0) {
                            rentedPercentage = 0; // Remplacer NaN par une valeur par défaut comme 0
                          }
                          return _buildPieChart(rentedPercentage, context); // Ajout du camembert avec la vérification
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildCard(
                      S.of(context).rents,
                      Icons.attach_money,
                      Row(
                        children: [
                          _buildValueBeforeText('${dataManager.netGlobalApy.toStringAsFixed(2)}%', S.of(context).annualYield, dataManager.isLoading),
                          SizedBox(width: 6),
                          GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text(S.of(context).apy), // Titre de la popup
                                    content: Text(
                                      S.of(context).netApyHelp, // Contenu de la popup
                                      style: TextStyle(fontSize: 13 + appState.getTextSizeOffset()),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop(); // Fermer la popup
                                        },
                                        child: Text(S.of(context).close), // Bouton de fermeture
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            child: Icon(Icons.info_outline, size: 15), // Icône sans padding implicite
                          ),
                        ],
                      ),
                      [
                        _buildTextWithShimmer(
                          '${dataManager.averageAnnualYield.toStringAsFixed(2)}%',
                          'APY brut: ',
                          dataManager.isLoading,
                          context,
                        ),
                        const SizedBox(height: 10),
                        _buildTextWithShimmer(
                          Utils.getFormattedAmount(dataManager.convert(dataManager.dailyRent), dataManager.currencySymbol, _showAmounts),
                          S.of(context).daily,
                          dataManager.isLoading,
                          context,
                        ),
                        _buildTextWithShimmer(
                          Utils.getFormattedAmount(dataManager.convert(dataManager.weeklyRent), dataManager.currencySymbol, _showAmounts),
                          S.of(context).weekly,
                          dataManager.isLoading,
                          context,
                        ),
                        _buildTextWithShimmer(
                          Utils.getFormattedAmount(
                            dataManager.convert(dataManager.monthlyRent),
                            dataManager.currencySymbol,
                            _showAmounts,
                          ),
                          S.of(context).monthly,
                          dataManager.isLoading,
                          context,
                        ),
                        _buildTextWithShimmer(
                          Utils.getFormattedAmount(dataManager.convert(dataManager.yearlyRent), dataManager.currencySymbol, _showAmounts),
                          S.of(context).annually,
                          dataManager.isLoading,
                          context,
                        ),
                      ],
                      dataManager,
                      context,
                      hasGraph: true,
                      rightWidget: _buildMiniGraphForRendement(_getLast12MonthsRent(dataManager), context, dataManager),
                    ),
                    const SizedBox(height: 8),
                    _buildCard(
                      S.of(context).nextRondays,
                      Icons.trending_up,
                      _buildCumulativeRentList(dataManager),
                      [], // Pas d'autres enfants pour cette carte
                      dataManager,
                      context,
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _calculateTimeBeforeLiquidationFormatted(double rmmValue, double usdcBorrow, double xdaiBorrow, double apy) {
    double totalBorrow = usdcBorrow + xdaiBorrow;

    if (totalBorrow == 0 || apy == 0) {
      return '∞'; // Pas de liquidation possible
    }

    double liquidationThreshold = rmmValue * 0.7;

    if (liquidationThreshold <= totalBorrow) {
      return 'Liquidation imminente'; // Déjà liquidé
    }

    // APY en taux journalier
    double dailyRate = apy / 365 / 100;

    // Temps avant liquidation en jours
    double timeInDays = (liquidationThreshold - totalBorrow) / (totalBorrow * dailyRate);

    // Conversion en mois ou années si nécessaire
    if (timeInDays > 100 * 30) {
      // Plus de 100 mois
      double years = timeInDays / 365;
      return '${years.toStringAsFixed(1)} ans';
    } else if (timeInDays > 100) {
      // Plus de 100 jours
      double months = timeInDays / 30;
      return '${months.toStringAsFixed(1)} mois';
    } else {
      return '${timeInDays.toStringAsFixed(1)} jours';
    }
  }

  Widget _buildCumulativeRentList(DataManager dataManager) {
    final cumulativeRentEvolution = dataManager.getCumulativeRentEvolution();
    DateTime today = DateTime.now();
    final appState = Provider.of<AppState>(context);

    // Filtrer pour n'afficher que les dates futures
    final futureRentEvolution = cumulativeRentEvolution.where((entry) {
      DateTime rentStartDate = entry['rentStartDate'];
      return rentStartDate.isAfter(today);
    }).toList();

    // Utiliser un Set pour ne garder que des dates uniques
    Set<DateTime> displayedDates = <DateTime>{};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: futureRentEvolution.map((entry) {
        DateTime rentStartDate = entry['rentStartDate'];

        // Vérifier si la date est déjà dans le Set
        if (displayedDates.contains(rentStartDate)) {
          return SizedBox.shrink(); // Ne rien afficher si la date est déjà affichée
        } else {
          // Ajouter la date au Set
          displayedDates.add(rentStartDate);

          // Vérifier si la date est "3000-01-01" et afficher 'date non connu'
          String displayDate = rentStartDate == DateTime(3000, 1, 1) ? 'Date non communiquée' : DateFormat('yyyy-MM-dd').format(rentStartDate);

          // Afficher la date et le loyer cumulé
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 0),
            child: Text(
              '$displayDate: ${Utils.getFormattedAmount(dataManager.convert(entry['cumulativeRent']), dataManager.currencySymbol, _showAmounts)}',
              style: TextStyle(fontSize: 13 + appState.getTextSizeOffset(), color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
          );
        }
      }).toList(),
    );
  }

  // Fonction utilitaire pour ajouter un "+" ou "-" et afficher entre parenthèses

  Widget _buildIndentedBalance(String label, double value, String symbol, bool isPositive, BuildContext context, bool isLoading) {
    // Utiliser la fonction _getFormattedAmount pour gérer la visibilité des montants
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context); // Accéder au thème actuel

    // Définir les couleurs pour le shimmer en fonction du thème
    final baseColor = theme.textTheme.bodyMedium?.color?.withOpacity(0.2) ?? Colors.grey[300]!;
    final highlightColor = theme.textTheme.bodyMedium?.color?.withOpacity(0.6) ?? Colors.grey[100]!;

    // Formatage du montant
    String formattedAmount = _showAmounts
        ? (isPositive ? "+ ${Utils.formatCurrency(value, symbol)}" : "- ${Utils.formatCurrency(value, symbol)}")
        : (isPositive ? "+ " : "- ") + ('*' * 10); // Affiche une série d'astérisques si masqué

    return Padding(
      padding: const EdgeInsets.only(left: 10.0), // Ajoute une indentation pour décaler à droite
      child: Row(
        children: [
          isLoading
              ? Shimmer.fromColors(
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                  child: Container(
                    width: 60, // Largeur placeholder pour le montant
                    height: 14, // Hauteur placeholder
                    color: baseColor,
                  ),
                )
              : Text(
                  formattedAmount, // Affiche le montant ou des astérisques
                  style: TextStyle(
                    fontSize: 13, // Taille du texte ajustée
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyMedium?.color, // Couleur en fonction du thème
                  ),
                ),
          const SizedBox(width: 8), // Espace entre le montant et le label
          Text(
            label, // Affiche le label après le montant
            style: TextStyle(
              fontSize: 11 + appState.getTextSizeOffset(), // Texte légèrement plus petit
              color: theme.textTheme.bodyMedium?.color, // Couleur en fonction du thème
            ),
          ),
        ],
      ),
    );
  }

  // Fonction pour obtenir la couleur en fonction du titre traduit
  Color _getIconColor(String title, BuildContext context) {
    final String translatedTitle = title.trim(); // Supprime les espaces éventuels

    if (translatedTitle == S.of(context).rents) {
      return Colors.green;
    } else if (translatedTitle == S.of(context).tokens) {
      return Colors.orange;
    } else if (translatedTitle == S.of(context).rmm) {
      return Colors.teal;
    } else if (translatedTitle == S.of(context).properties) {
      return Colors.blue;
    } else if (translatedTitle == S.of(context).portfolio) {
      return Colors.blueGrey;
    } else {
      return Colors.blue; // Couleur par défaut
    }
  }
}
