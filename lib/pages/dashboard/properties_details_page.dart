import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:realtokens/app_state.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class PropertiesDetailsPage extends StatelessWidget {
  const PropertiesDetailsPage({super.key});

  Widget _buildInfoCards(BuildContext context, DataManager dataManager, AppState appState) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(child: _buildCard(context, '${dataManager.totalTokenCount}', S.of(context).properties, appState)),
              Expanded(child: _buildCard(context, '${dataManager.walletTokenCount}', S.of(context).wallet, appState)),
              Expanded(child: _buildCard(context, '${dataManager.rmmTokenCount.toInt()}', S.of(context).rmm, appState)),
            ],
          ),
          SizedBox(height: 10),
          _buildFullWidthCard(context, '${dataManager.totalRealtTokens}', S.of(context).tokens, appState),
          SizedBox(height: 10),
          _buildFullWidthCard(context, '${dataManager.rentedUnits} / ${dataManager.totalUnits}', S.of(context).rentedUnits, appState),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, String value, String label, AppState appState) {
    return Card(
      elevation: 0.5,
            color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18 + appState.getTextSizeOffset(),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14 + appState.getTextSizeOffset(),
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullWidthCard(BuildContext context, String value, String label, AppState appState) {
    return SizedBox(
      width: double.infinity,
      child: _buildCard(context, value, label, appState),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).properties),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: dataManager.portfolio.isEmpty
            ? Center(
                child: Text(
                  'No data available.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRentedUnitsGauge(context, dataManager, appState),
                  _buildInfoCards(context, dataManager, appState), // Ajout des cartes
                  SizedBox(height: 20),
                  _buildTokenDistributionCard(context, dataManager, appState),
                ],
              ),
      ),
    );
  }

 Widget _buildRentedUnitsGauge(BuildContext context, DataManager dataManager, AppState appState) {
    final double rentedPercentage = (dataManager.rentedUnits / dataManager.totalUnits) * 100;
    Color gaugeColor = _getGaugeColor(rentedPercentage);

    return Center(
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade400, width: 2),
          color: Theme.of(context).cardColor,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            SfRadialGauge(
              axes: <RadialAxis>[
                RadialAxis(
                  minimum: 0,
                  maximum: 100,
                  showLabels: false,
                  showTicks: false,
                  startAngle: 270,
                  endAngle: 270,
                  axisLineStyle: AxisLineStyle(
                    thickness: 0.25,
                    cornerStyle: CornerStyle.bothCurve,
                    color: Colors.grey.shade300,
                    thicknessUnit: GaugeSizeUnit.factor,
                  ),
                  pointers: <GaugePointer>[
                    RangePointer(
                      value: rentedPercentage,
                      width: 0.25,
                      enableAnimation: true,
                      cornerStyle: CornerStyle.bothCurve,
                      color: gaugeColor,
                      sizeUnit: GaugeSizeUnit.factor,
                    ),
                  ],
                ),
              ],
            ),
            Container(
              width: 125,
              height: 125,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${rentedPercentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 20 + appState.getTextSizeOffset(),
                      fontWeight: FontWeight.bold,
                      color: gaugeColor,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Rented Units',
                    style: TextStyle(
                      fontSize: 16 + appState.getTextSizeOffset(),
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
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

  Color _getGaugeColor(double percentage) {
    if (percentage < 50) {
      return Colors.red;
    } else if (percentage < 80) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
  Widget _buildTokenDistributionCard(BuildContext context, DataManager dataManager, AppState appState) {
    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.of(context).tokenDistribution,
              style: TextStyle(fontSize: 20 + appState.getTextSizeOffset(), fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _buildDonutChartData(dataManager),
                  centerSpaceRadius: 70,
                  sectionsSpace: 2,
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildDonutChartData(DataManager dataManager) {
    final sortedData = List<Map<String, dynamic>>.from(dataManager.propertyData)
      ..sort((a, b) => b['count'].compareTo(a['count']));

    return sortedData.asMap().entries.map((entry) {
      final data = entry.value;
      final double percentage = (data['count'] / dataManager.propertyData.fold(0.0, (double sum, item) => sum + item['count'])) * 100;

      return PieChartSectionData(
        value: data['count'].toDouble(),
        title: '${percentage.toStringAsFixed(1)}%',
        color: _getPropertyColor(data['propertyType']),
        radius: 40,
        titleStyle: const TextStyle(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();
  }

  Color _getPropertyColor(int propertyType) {
    switch (propertyType) {
      case 1:
        return Colors.blue;
      case 2:
        return Colors.green;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.red;
      case 5:
        return Colors.purple;
      case 6:
        return Colors.yellow;
      case 7:
        return Colors.teal;
      case 8:
        return Colors.brown;
      case 9:
        return Colors.pink;
      case 10:
        return Colors.cyan;
      case 11:
        return Colors.lime;
      case 12:
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }
}
