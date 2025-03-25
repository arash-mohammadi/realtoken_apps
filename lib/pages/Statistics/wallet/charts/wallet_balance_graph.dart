import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/models/balance_record.dart';
import 'package:realtokens/utils/chart_utils.dart';
import 'package:realtokens/utils/currency_utils.dart';
import 'package:realtokens/utils/date_utils.dart';

class WalletBalanceGraph extends StatelessWidget {
  final DataManager dataManager;
  final String selectedPeriod;
  final Function(String) onPeriodChanged;
  final bool isBarChart;
  final Function(bool) onChartTypeChanged;

  const WalletBalanceGraph({
    super.key,
    required this.dataManager,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.isBarChart,
    required this.onChartTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Theme.of(context).cardColor,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).cardColor,
              Theme.of(context).cardColor.withOpacity(0.8),
            ],
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  S.of(context).walletBalanceHistory,
                  style: TextStyle(
                    fontSize: 20 + appState.getTextSizeOffset(),
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.tune_rounded,
                    size: 20.0,
                    color: Theme.of(context).primaryColor,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 24.0,
                            horizontal: 16.0,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16.0, left: 8.0),
                                child: Text(
                                  'S.of(context).options',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18 + appState.getTextSizeOffset(),
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                              ListTile(
                                leading: Icon(
                                  Icons.bar_chart_rounded,
                                  color: const Color(0xFF5856D6),
                                  size: 28,
                                ),
                                title: Text(
                                  S.of(context).barChart,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16 + appState.getTextSizeOffset(),
                                  ),
                                ),
                                trailing: isBarChart
                                    ? Icon(
                                        Icons.check_circle,
                                        color: const Color(0xFF5856D6),
                                      )
                                    : null,
                                onTap: () {
                                  onChartTypeChanged(true);
                                  Navigator.of(context).pop();
                                },
                              ),
                              ListTile(
                                leading: Icon(
                                  Icons.show_chart_rounded,
                                  color: const Color(0xFFAF52DE),
                                  size: 28,
                                ),
                                title: Text(
                                  S.of(context).lineChart,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16 + appState.getTextSizeOffset(),
                                  ),
                                ),
                                trailing: !isBarChart
                                    ? Icon(
                                        Icons.check_circle,
                                        color: const Color(0xFFAF52DE),
                                      )
                                    : null,
                                onTap: () {
                                  onChartTypeChanged(false);
                                  Navigator.of(context).pop();
                                },
                              ),
                              const Divider(
                                height: 32,
                                thickness: 0.5,
                              ),
                              ListTile(
                                leading: Icon(
                                  CupertinoIcons.pencil_circle_fill,
                                  color: const Color(0xFF007AFF),
                                  size: 28,
                                ),
                                title: Text(
                                  S.of(context).edit,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16 + appState.getTextSizeOffset(),
                                  ),
                                ),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  _showEditModal(context, dataManager);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            ChartUtils.buildPeriodSelector(
              context,
              selectedPeriod: selectedPeriod,
              onPeriodChanged: onPeriodChanged,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: isBarChart
                  ? BarChart(
                      BarChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey.withOpacity(0.15),
                              strokeWidth: 1,
                            );
                          },
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                List<String> labels = _buildDateLabelsForWallet(
                                    context, dataManager, selectedPeriod);
                                if (value.toInt() >= 0 &&
                                    value.toInt() < labels.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 10.0),
                                    child: Transform.rotate(
                                      angle: -0.5,
                                      child: Text(
                                        labels[value.toInt()],
                                        style: TextStyle(
                                          fontSize: 10 + appState.getTextSizeOffset(),
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                  );
                                } else {
                                  return const SizedBox.shrink();
                                }
                              },
                            ),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                final formattedValue = currencyUtils.formatCompactCurrency(
                                  value,
                                  currencyUtils.currencySymbol,
                                );

                                return Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Text(
                                    formattedValue,
                                    style: TextStyle(
                                      fontSize: 10 + appState.getTextSizeOffset(),
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        maxY: _calculateMaxY(context, dataManager, selectedPeriod),
                        barGroups: _buildWalletBalanceBarChartData(
                            context, dataManager, selectedPeriod).map((group) {
                          return BarChartGroupData(
                            x: group.x,
                            barRods: [
                              BarChartRodData(
                                toY: group.barRods.first.toY,
                                color: const Color(0xFF5856D6),
                                width: 12,
                                borderRadius: const BorderRadius.all(Radius.circular(6)),
                                backDrawRodData: BackgroundBarChartRodData(
                                  show: true,
                                  toY: _calculateMaxY(context, dataManager, selectedPeriod),
                                  color: Colors.grey.withOpacity(0.1),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final List<String> labels = _buildDateLabelsForWallet(
                                  context, dataManager, selectedPeriod);
                              
                              if (groupIndex >= 0 && groupIndex < labels.length) {
                                final formattedValue = currencyUtils.formatCompactCurrency(
                                  rod.toY,
                                  currencyUtils.currencySymbol,
                                );
                                
                                return BarTooltipItem(
                                  '${labels[groupIndex]}\n$formattedValue',
                                  const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                );
                              }
                              return null;
                            },
                            fitInsideHorizontally: true,
                            fitInsideVertically: true,
                            tooltipRoundedRadius: 12,
                            tooltipPadding: const EdgeInsets.all(12),
                          ),
                        ),
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey.withOpacity(0.15),
                              strokeWidth: 1,
                            );
                          },
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                List<String> labels = _buildDateLabelsForWallet(
                                    context, dataManager, selectedPeriod);
                                if (value.toInt() >= 0 &&
                                    value.toInt() < labels.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 10.0),
                                    child: Transform.rotate(
                                      angle: -0.5,
                                      child: Text(
                                        labels[value.toInt()],
                                        style: TextStyle(
                                          fontSize: 10 + appState.getTextSizeOffset(),
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                  );
                                } else {
                                  return const SizedBox.shrink();
                                }
                              },
                            ),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                final formattedValue = currencyUtils.formatCompactCurrency(
                                  value,
                                  currencyUtils.currencySymbol,
                                );

                                return Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Text(
                                    formattedValue,
                                    style: TextStyle(
                                      fontSize: 10 + appState.getTextSizeOffset(),
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _buildWalletBalanceChartData(
                                context, dataManager, selectedPeriod),
                            isCurved: true,
                            curveSmoothness: 0.3,
                            barWidth: 3,
                            color: const Color(0xFFAF52DE),
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) {
                                return FlDotCirclePainter(
                                  radius: 3,
                                  color: Colors.white,
                                  strokeWidth: 2,
                                  strokeColor: const Color(0xFFAF52DE),
                                );
                              },
                              checkToShowDot: (spot, barData) {
                                // Montrer points aux extrémités et points intermédiaires
                                final isFirst = spot.x == 0;
                                final isLast = spot.x == barData.spots.length - 1;
                                final isInteresting = spot.x % (barData.spots.length > 10 ? 5 : 2) == 0;
                                return isFirst || isLast || isInteresting;
                              },
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFAF52DE).withOpacity(0.3),
                                  const Color(0xFFAF52DE).withOpacity(0.05),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (List<LineBarSpot> touchedSpots) {
                              return touchedSpots.map((touchedSpot) {
                                final index = touchedSpot.x.toInt();
                                final averageBalance = touchedSpot.y;
                                final periodLabel = _buildDateLabelsForWallet(
                                    context,
                                    dataManager,
                                    selectedPeriod)[index];

                                final formattedValue = currencyUtils.formatCompactCurrency(
                                  touchedSpot.y, 
                                  currencyUtils.currencySymbol,
                                );

                                return LineTooltipItem(
                                  '$periodLabel\n$formattedValue',
                                  const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                );
                              }).toList();
                            },
                            fitInsideHorizontally: true,
                            fitInsideVertically: true,
                            tooltipMargin: 8,
                            tooltipHorizontalOffset: 0,
                            tooltipRoundedRadius: 12,
                            tooltipPadding: const EdgeInsets.all(12),
                          ),
                          handleBuiltInTouches: true,
                          touchSpotThreshold: 20,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateMaxY(BuildContext context, DataManager dataManager, String selectedPeriod) {
    final data = _buildWalletBalanceChartData(context, dataManager, selectedPeriod);
    if (data.isEmpty) return 100;
    
    final maxY = data.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    // Augmenter de 10% pour laisser de l'espace
    return maxY * 1.1; 
  }

  List<BarChartGroupData> _buildWalletBalanceBarChartData(
      BuildContext context, DataManager dataManager, String selectedPeriod) {
    List<FlSpot> walletBalanceData =
        _buildWalletBalanceChartData(context, dataManager, selectedPeriod);
    return walletBalanceData
        .asMap()
        .entries
        .map(
          (entry) => BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.y,
                color: const Color(0xFF5856D6),
                width: 8,
              ),
            ],
          ),
        )
        .toList();
  }

  List<FlSpot> _buildWalletBalanceChartData(
      BuildContext context, DataManager dataManager, String selectedPeriod) {
    return ChartUtils.buildHistoryChartData<BalanceRecord>(
      context,
      dataManager.walletBalanceHistory,
      selectedPeriod,
      (record) => record.balance,
      (record) => record.timestamp,
    );
  }

  List<String> _buildDateLabelsForWallet(
      BuildContext context, DataManager dataManager, String selectedPeriod) {
    List<BalanceRecord> walletHistory = dataManager.walletBalanceHistory;

    Map<String, List<double>> groupedData = {};
    for (var record in walletHistory) {
      DateTime date = record.timestamp;
      String periodKey;

      if (selectedPeriod == S.of(context).day) {
        periodKey = DateFormat('yyyy/MM/dd').format(date);
      } else if (selectedPeriod == S.of(context).week) {
        periodKey =
            "${date.year}-S${CustomDateUtils.weekNumber(date).toString().padLeft(2, '0')}";
      } else if (selectedPeriod == S.of(context).month) {
        periodKey = DateFormat('yyyy/MM').format(date);
      } else {
        periodKey = date.year.toString();
      }

      groupedData.putIfAbsent(periodKey, () => []).add(record.balance);
    }

    List<String> sortedKeys = groupedData.keys.toList()..sort();
    return sortedKeys;
  }

  void _showEditModal(BuildContext context, DataManager dataManager) {
    final appState = Provider.of<AppState>(context, listen: false);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final screenHeight = MediaQuery.of(context).size.height;
        return Container(
          height: screenHeight * 0.7,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    S.of(context).editWalletBalance,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: dataManager.walletBalanceHistory.isEmpty
                    ? Center(
                        child: Text(
                          "Aucun historique disponible",
                          style: TextStyle(
                            fontSize: 16 + appState.getTextSizeOffset(),
                            color: Colors.grey.shade600,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: dataManager.walletBalanceHistory.length,
                        itemBuilder: (context, index) {
                          BalanceRecord record = dataManager.walletBalanceHistory[index];
                          TextEditingController valueController = TextEditingController(
                            text: record.balance.toString(),
                          );
                          TextEditingController dateController = TextEditingController(
                            text: DateFormat('yyyy-MM-dd HH:mm:ss').format(record.timestamp),
                          );

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12.0),
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 5,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "Entrée #${index + 1}",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14 + appState.getTextSizeOffset(),
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        _deleteBalanceRecord(dataManager, index);
                                        Navigator.pop(context);
                                        _showEditModal(context, dataManager);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(6.0),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.delete_outline,
                                          color: Colors.red.shade700,
                                          size: 18 + appState.getTextSizeOffset(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: dateController,
                                  keyboardType: TextInputType.datetime,
                                  textInputAction: TextInputAction.done,
                                  style: TextStyle(
                                    fontSize: 14 + appState.getTextSizeOffset(),
                                  ),
                                  decoration: InputDecoration(
                                    labelText: S.of(context).date,
                                    labelStyle: TextStyle(
                                      fontSize: 14 + appState.getTextSizeOffset(),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  onSubmitted: (value) {
                                    try {
                                      DateTime newDate = DateFormat('yyyy-MM-dd HH:mm:ss').parse(value);
                                      record.timestamp = newDate;
                                      dataManager.saveWalletBalanceHistory();
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Format de date invalide')),
                                      );
                                    }
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: valueController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  textInputAction: TextInputAction.done,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                  ],
                                  style: TextStyle(
                                    fontSize: 14 + appState.getTextSizeOffset(),
                                  ),
                                  decoration: InputDecoration(
                                    labelText: S.of(context).balance,
                                    labelStyle: TextStyle(
                                      fontSize: 14 + appState.getTextSizeOffset(),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  onSubmitted: (value) {
                                    double? newValue = double.tryParse(value);
                                    if (newValue != null) {
                                      record.balance = newValue;
                                      dataManager.saveWalletBalanceHistory();
                                      FocusScope.of(context).unfocus();
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      dataManager.saveWalletBalanceHistory();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      S.of(context).save,
                      style: TextStyle(
                        fontSize: 16 + appState.getTextSizeOffset(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _deleteBalanceRecord(DataManager dataManager, int index) {
    dataManager.walletBalanceHistory.removeAt(index);
    dataManager.saveWalletBalanceHistory();
  }
}
