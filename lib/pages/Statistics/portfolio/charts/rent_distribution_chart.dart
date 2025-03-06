import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/utils/ui_utils.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/utils/parameters.dart';
import 'package:realtokens/utils/currency_utils.dart';

class RentDistributionCard extends StatefulWidget {
  final DataManager dataManager;

  const RentDistributionCard({super.key, required this.dataManager});

  @override
  _RentDistributionCardState createState() => _RentDistributionCardState();
}

class _RentDistributionCardState extends State<RentDistributionCard> {
  late String _selectedFilter;
  int? _selectedIndex;
  final ValueNotifier<int?> _selectedIndexNotifier = ValueNotifier<int?>(null);

  @override
  void initState() {
    super.initState();
    _selectedFilter = 'Region';
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Card(
      elevation: 0.5,
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  S.of(context).rentDistribution,
                  style: TextStyle(
                    fontSize: 20 + appState.getTextSizeOffset(),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                DropdownButton<String>(
                  value: _selectedFilter,
                  items: [
                    DropdownMenuItem(value: 'Country', child: Text(S.of(context).country)),
                    DropdownMenuItem(value: 'Region', child: Text(S.of(context).region)),
                    DropdownMenuItem(value: 'City', child: Text(S.of(context).city)),
                  ],
                  onChanged: (String? value) {
                    setState(() {
                      _selectedFilter = value!;
                      _selectedIndexNotifier.value = null;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: ValueListenableBuilder<int?>(
                valueListenable: _selectedIndexNotifier,
                builder: (context, selectedIndex, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sections: _buildRentDonutChartData(widget.dataManager, selectedIndex),
                          centerSpaceRadius: 65,
                          sectionsSpace: 2,
                          borderData: FlBorderData(show: false),
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, PieTouchResponse? response) {
                              if (response != null && response.touchedSection != null) {
                                final touchedIndex = response.touchedSection!.touchedSectionIndex;
                                _selectedIndexNotifier.value = touchedIndex >= 0 ? touchedIndex : null;
                              } else {
                                _selectedIndexNotifier.value = null;
                              }
                            },
                          ),
                        ),
                      ),
                      _buildCenterText(widget.dataManager, selectedIndex),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Flexible(
              child: SingleChildScrollView(
                child: _buildRentLegend(widget.dataManager),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildRentDonutChartData(DataManager dataManager, int? selectedIndex) {
    final Map<String, double> groupedData = _groupRentDataBySelectedFilter(dataManager);
    final totalRent = groupedData.values.fold(0.0, (sum, value) => sum + value);

    final sortedEntries = groupedData.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final percentage = (data.value / totalRent) * 100;

      final bool isSelected = selectedIndex == index;
      final opacity = selectedIndex != null && !isSelected ? 0.5 : 1.0;

      return PieChartSectionData(
        value: data.value,
        title: '${percentage.toStringAsFixed(1)}%',
        color: generateColor(index).withOpacity(opacity),
        radius: isSelected ? 50 : 40,
        titleStyle: TextStyle(
          fontSize: isSelected ? 14 + Provider.of<AppState>(context).getTextSizeOffset() : 10 + Provider.of<AppState>(context).getTextSizeOffset(),
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();
  }

  Widget _buildCenterText(DataManager dataManager, int? selectedIndex) {
    final Map<String, double> groupedData = _groupRentDataBySelectedFilter(dataManager);
    final totalRent = groupedData.values.fold(0.0, (sum, value) => sum + value);
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);

    if (selectedIndex == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'total',
            style: TextStyle(
              fontSize: 16 + Provider.of<AppState>(context).getTextSizeOffset(),
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            currencyUtils.getFormattedAmount(currencyUtils.convert(totalRent), currencyUtils.currencySymbol, true),
            style: TextStyle(
              fontSize: 14 + Provider.of<AppState>(context).getTextSizeOffset(),
              color: Colors.grey,
            ),
          ),
        ],
      );
    }

    final sortedEntries = groupedData.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final selectedEntry = sortedEntries[selectedIndex];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          Parameters.usStateAbbreviations[selectedEntry.key] ?? selectedEntry.key,
          style: TextStyle(
            fontSize: 16 + Provider.of<AppState>(context).getTextSizeOffset(),
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          currencyUtils.getFormattedAmount(currencyUtils.convert(selectedEntry.value), currencyUtils.currencySymbol, true),
          style: TextStyle(
            fontSize: 14 + Provider.of<AppState>(context).getTextSizeOffset(),
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Map<String, double> _groupRentDataBySelectedFilter(DataManager dataManager) {
    Map<String, double> groupedData = {};

    for (var token in dataManager.portfolio) {
      String key;
      switch (_selectedFilter) {
        case 'Country':
          key = token['country'] ?? 'Unknown Country';
          break;
        case 'Region':
          key = token['regionCode'] ?? 'Unknown Region';
          break;
        case 'City':
          key = token['city'] ?? 'Unknown City';
          break;
        default:
          key = 'Unknown';
      }

      groupedData[key] = (groupedData[key] ?? 0) + (token['monthlyIncome'] ?? 0.0);
    }

    return groupedData;
  }

  Widget _buildRentLegend(DataManager dataManager) {
    final Map<String, double> groupedData = _groupRentDataBySelectedFilter(dataManager);
    final appState = Provider.of<AppState>(context);

    final sortedEntries = groupedData.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      alignment: WrapAlignment.start,
      children: sortedEntries.map((entry) {
        final index = sortedEntries.indexOf(entry);
        final color = generateColor(index);

        String displayKey = Parameters.usStateAbbreviations[entry.key] ?? entry.key;

        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 200),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 2,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  displayKey,
                  style: TextStyle(fontSize: 11 + appState.getTextSizeOffset()),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color generateColor(int index) {
    final hue = ((index * 57) + 193 * (index % 3)) % 360;
    final saturation = (0.7 + (index % 5) * 0.06).clamp(0.4, 0.7);
    final brightness = (0.8 + (index % 3) * 0.2).clamp(0.6, 0.9);
    return HSVColor.fromAHSV(1.0, hue.toDouble(), saturation, brightness).toColor();
  }
}
