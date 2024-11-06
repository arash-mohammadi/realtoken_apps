import 'package:realtokens_apps/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:realtokens_apps/pages/token_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:realtokens_apps/generated/l10n.dart';
import 'package:realtokens_apps/settings/manage_evm_addresses_page.dart';
import 'package:realtokens_apps/app_state.dart';

class PortfolioDisplay1 extends StatelessWidget {
  final List<Map<String, dynamic>> portfolio;
  const PortfolioDisplay1({super.key, required this.portfolio});

  // Méthode pour construire la jauge de rentabilité
  Widget _buildGaugeForRent(double rentValue, BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 5),
        LayoutBuilder(
          builder: (context, constraints) {
            double maxWidth = constraints.maxWidth * 0.4;
            return Stack(
              children: [
                Container(
                  height: 10,
                  width: maxWidth,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                Container(
                  height: 10,
                  width: rentValue.clamp(0, 100) / 100 * maxWidth,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ],
            );
          },
        ),
        Text(
          "${rentValue.toStringAsFixed(1)} %",
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: portfolio.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      S.of(context).noDataAvailable,
                      style: TextStyle(
                        fontSize: 18 + appState.getTextSizeOffset(),
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ManageEvmAddressesPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.blue,
                      ),
                      child: Text(
                        S.of(context).manageAddresses,
                        style: TextStyle(
                          fontSize: 16 + appState.getTextSizeOffset(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 20, bottom: 80),
              itemCount: portfolio.length,
              itemBuilder: (context, index) {
                final token = portfolio[index];
                final isWallet = token['inWallet'] ?? false;
                final isRMM = token['inRMM'] ?? false;
                final city = Utils.extractCity(token['fullName'] ?? '');

                final rentPercentage = (token['totalRentReceived'] != null &&
                        token['initialTotalValue'] != null &&
                        token['initialTotalValue'] != 0)
                    ? (token['totalRentReceived'] / token['initialTotalValue']) * 100
                    : 0.5;

                return Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
                  child: GestureDetector(
                    onTap: () => showTokenDetails(context, token),
                    child: SizedBox(
                      height: 170, // Définir une hauteur fixe pour le Row
                      
                      child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Image avec la ville et le statut de location
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                          child: Stack(
                            children: [
                              ColorFiltered(
                                colorFilter: token['rentStartDate'] != null &&
                                        DateTime.tryParse(token['rentStartDate']) != null &&
                                        DateTime.parse(token['rentStartDate']).isAfter(DateTime.now())
                                    ? const ColorFilter.mode(Colors.black45, BlendMode.darken)
                                    : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                                child: SizedBox(
                                  width: 120,
                                  height: double.infinity,
                                  child: CachedNetworkImage(
                                    imageUrl: (token['imageLink'] != null && token['imageLink'].isNotEmpty)
                                        ? token['imageLink'][0]
                                        : '',
                                    fit: BoxFit.cover,
                                    errorWidget: (context, url, error) => const Icon(Icons.error),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  color: Colors.black54,
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        left: 0,
                                        top: 0,
                                        bottom: 0,
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Utils.getRentalStatusColor(
                                              token['rentedUnits'] ?? 0,
                                              token['totalUnits'] ?? 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Center(
                                        child: Text(
                                          city,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14 + appState.getTextSizeOffset(),
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Card(
                            elevation: 0,
                            margin: EdgeInsets.zero,
                            color: Theme.of(context).cardColor,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Tronquer le shortName si trop long
                                      Expanded(
                                        child: Text(
                                          token['shortName'] ?? S.of(context).nameUnavailable,
                                          style: TextStyle(
                                            fontSize: 15 + appState.getTextSizeOffset(),
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).textTheme.bodyLarge?.color,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      // Jauge alignée à droite sans marges
                                      Transform.translate(
                                            offset: const Offset(16.0, 0), // Décalage de 8 pixels vers la droite
                                            child: SizedBox(
                                              width: 100,
                                              child: rentPercentage != null
                                                  ? _buildGaugeForRent(rentPercentage, context)
                                                  : const SizedBox.shrink(),
                                            ),
                                          ),
                                    ],
                                  ),
                                  Text(
                                    '${S.of(context).totalValue}: ${formatCurrency(context, token['totalValue'] ?? 0)}',
                                    style: TextStyle(fontSize: 13 + appState.getTextSizeOffset()),
                                  ),
                                  Text(
                                    '${S.of(context).amount}: ${token['amount']?.toStringAsFixed(2) ?? '0.00'} / ${token['totalTokens'] ?? 'N/A'}',
                                    style: TextStyle(fontSize: 13 + appState.getTextSizeOffset()),
                                  ),
                                  Text(
                                    '${S.of(context).apy}: ${token['annualPercentageYield']?.toStringAsFixed(2) ?? 'N/A'}%',
                                    style: TextStyle(fontSize: 13 + appState.getTextSizeOffset()),
                                  ),
                                  const SizedBox(height: 8),
                                          Text(
                                            '${S.of(context).revenue}:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13 + appState.getTextSizeOffset(),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4.0),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                              children: [
                                                Column(
                                                  children: [
                                                    Text(S.of(context).week,
                                                        style: TextStyle(fontSize: 13 + appState.getTextSizeOffset())),
                                                    Text(
                                                        formatCurrency(context, token['dailyIncome'] * 7 ?? 0),
                                                        style: TextStyle(fontSize: 13 + appState.getTextSizeOffset())),
                                                  ],
                                                ),
                                                Column(
                                                  children: [
                                                    Text(S.of(context).month,
                                                        style: TextStyle(fontSize: 13 + appState.getTextSizeOffset())),
                                                    Text(
                                                        formatCurrency(context, token['monthlyIncome'] ?? 0),
                                                        style: TextStyle(fontSize: 13 + appState.getTextSizeOffset())),
                                                  ],
                                                ),
                                                Column(
                                                  children: [
                                                    Text(S.of(context).year,
                                                        style: TextStyle(fontSize: 13 + appState.getTextSizeOffset())),
                                                    Text(
                                                        formatCurrency(context, token['yearlyIncome'] ?? 0),
                                                        style: TextStyle(fontSize: 13 + appState.getTextSizeOffset())),
                                                  ],
                                                ),
                                              ],
                                            ),
                                    
                                          ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      ],
                    ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
