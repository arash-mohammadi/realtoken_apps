import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/models/balance_record.dart';
import 'package:realtokens/components/charts/generic_chart_widget.dart';
import 'package:realtokens/app_state.dart';
import 'package:intl/intl.dart';

class WalletBalanceGraph extends StatelessWidget {
  final String selectedPeriod;
  final Function(String) onPeriodChanged;
  final bool balanceIsBarChart;
  final Function(bool) onChartTypeChanged;
  final String selectedTimeRange;
  final Function(String) onTimeRangeChanged;
  final int timeOffset;
  final Function(int) onTimeOffsetChanged;

  const WalletBalanceGraph({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.balanceIsBarChart,
    required this.onChartTypeChanged,
    this.selectedTimeRange = 'all',
    required this.onTimeRangeChanged,
    this.timeOffset = 0,
    required this.onTimeOffsetChanged,
  });

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
          padding: const EdgeInsets.all(8.0),
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
              const SizedBox(height: 8),
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
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: DataTable(
                            columnSpacing: 8,
                            horizontalMargin: 8,
                            columns: [
                              DataColumn(
                                label: SizedBox(
                                  width: 150,
                                  child: Text(
                                    S.of(context).date,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14 + appState.getTextSizeOffset(),
                                    ),
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: SizedBox(
                                  width: 100,
                                  child: Text(
                                    S.of(context).balance,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14 + appState.getTextSizeOffset(),
                                    ),
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: SizedBox(
                                  width: 60,
                                  child: Text(
                                    "Actions",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14 + appState.getTextSizeOffset(),
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ),
                            ],
                            rows: (() {
                              final sortedEntries = dataManager.walletBalanceHistory
                                  .asMap()
                                  .entries
                                  .toList()
                                ..sort((a, b) => b.value.timestamp.compareTo(a.value.timestamp));
                              
                              return sortedEntries.map((entry) {
                                final index = entry.key;
                                final record = entry.value;
                                TextEditingController valueController = TextEditingController(
                                  text: record.balance.toStringAsFixed(2),
                                );
                                TextEditingController dateController = TextEditingController(
                                  text: DateFormat('yyyy-MM-dd HH:mm').format(record.timestamp),
                                );

                                return DataRow(
                                  cells: [
                                    DataCell(
                                      SizedBox(
                                        width: 150,
                                        child: TextField(
                                          controller: dateController,
                                          keyboardType: TextInputType.datetime,
                                          textInputAction: TextInputAction.done,
                                          style: TextStyle(
                                            fontSize: 14 + appState.getTextSizeOffset(),
                                          ),
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: Colors.white,
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                color: Colors.grey.shade300,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                color: Colors.grey.shade300,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                color: Theme.of(context).primaryColor,
                                              ),
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
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
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 100,
                                        child: TextField(
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
                                            filled: true,
                                            fillColor: Colors.white,
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                color: Colors.grey.shade300,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                color: Colors.grey.shade300,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                color: Theme.of(context).primaryColor,
                                              ),
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
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
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 60,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            IconButton(
                                              icon: Icon(
                                                Icons.delete_outline,
                                                color: Colors.red.shade700,
                                                size: 20 + appState.getTextSizeOffset(),
                                              ),
                                              onPressed: () {
                                                dataManager.walletBalanceHistory.removeAt(index);
                                                dataManager.saveWalletBalanceHistory();
                                                Navigator.pop(context);
                                                _showEditModal(context, dataManager);
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList();
                            })(),
                          ),
                        ),
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

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);

    return GenericChartWidget<BalanceRecord>(
      title: S.of(context).walletBalanceHistory,
      chartColor: const Color(0xFF007AFF), // Bleu iOS
      dataList: dataManager.walletBalanceHistory,
      selectedPeriod: selectedPeriod,
      onPeriodChanged: onPeriodChanged,
      isBarChart: balanceIsBarChart,
      onChartTypeChanged: onChartTypeChanged,
      selectedTimeRange: selectedTimeRange,
      onTimeRangeChanged: onTimeRangeChanged,
      timeOffset: timeOffset,
      onTimeOffsetChanged: onTimeOffsetChanged,
      getYValue: (record) => record.balance,
      getTimestamp: (record) => record.timestamp,
      valuePrefix: '',
      valueSuffix: ' €',
      onEditPressed: (context) => _showEditModal(context, dataManager),
    );
  }
}
