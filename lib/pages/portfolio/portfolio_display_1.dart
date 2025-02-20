import 'package:flutter/foundation.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/modals/token_details/showTokenDetails.dart';
import 'package:realtokens/utils/currency_utils.dart';
import 'package:realtokens/utils/location_utils.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/settings/manage_evm_addresses_page.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/utils/ui_utils.dart';
import 'package:show_network_image/show_network_image.dart';

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
                    color: const Color.fromARGB(255, 78, 78, 78).withOpacity(0.3), // Couleur du fond grisé
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                Container(
                  height: 10,
                  width: rentValue.clamp(0, 100) / 100 * maxWidth,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
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
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: portfolio.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
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
                        backgroundColor: Theme.of(context).primaryColor,
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
          : GridView.builder(
              padding: const EdgeInsets.only(top: 20, bottom: 80, right: 4, left: 4),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 700 ? 2 : 1,

                mainAxisExtent: 195 * (1 + (appState.getTextSizeOffset() / 35)), // Ajustez ici pour plus de hauteur
              ),
              itemCount: portfolio.length,
              itemBuilder: (context, index) {
                final token = portfolio[index];
                final isWallet = token['inWallet'] ?? false;
                final isRMM = token['inRMM'] ?? false;
                final city = LocationUtils.extractCity(token['fullName'] ?? '');

                // Vérifier si la date de 'rent_start' est dans le futur
                final rentStartDate = DateTime.parse(token['rentStartDate'] ?? DateTime.now().toString());
                final bool isFutureRentStart = rentStartDate.isAfter(DateTime.now());

                final rentPercentage = (token['totalRentReceived'] != null && token['initialTotalValue'] != null && token['initialTotalValue'] != 0)
                    ? (token['totalRentReceived'] / token['initialTotalValue']) * 100
                    : 0.5;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                  child: GestureDetector(
                    onTap: () => showTokenDetails(context, token),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        // Image avec la ville et le statut de location
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                          child: Stack(
                            children: [
                              ColorFiltered(
                                colorFilter:
                                    isFutureRentStart ? const ColorFilter.mode(Colors.black45, BlendMode.darken) : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                                child: SizedBox(
                                  width: kIsWeb ? 150 : 120,
                                  height: double.infinity,
                                  child: kIsWeb
                                      ? ShowNetworkImage(
                                          imageSrc: token['imageLink'][0],
                                          mobileBoxFit: BoxFit.cover,
                                        )
                                      : CachedNetworkImage(
                                          imageUrl: token['imageLink'][0],
                                          fit: BoxFit.cover,
                                          errorWidget: (context, url, error) => const Icon(Icons.error),
                                        ),
                                ),
                              ),

                              // ✅ Superposition d'un GestureDetector transparent uniquement sur Web
                              if (kIsWeb)
                                Positioned.fill(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.translucent, // Capture le clic même sur les parties transparentes
                                    onTap: () {
                                      print("✅ Image cliquée sur Web !");
                                      showTokenDetails(context, token);
                                    },
                                  ),
                                ),

                              // ✅ Superposition du texte si 'rent_start' est dans le futur
                              if (isFutureRentStart)
                                Positioned.fill(
                                  child: Center(
                                    child: Container(
                                      color: Colors.black54,
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        S.of(context).rentStartFuture,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12 + appState.getTextSizeOffset(),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Card(
                            elevation: 0.5,
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
                                      Expanded(
                                        child: Row(
                                          children: [
                                            if (token['country'] != null) // Vérifie si le pays est disponible
                                              Padding(
                                                padding: const EdgeInsets.only(right: 8.0), // Espacement entre l'image et le texte
                                                child: Image.asset(
                                                  'assets/country/${token['country'].toLowerCase()}.png',
                                                  width: 18,
                                                  height: 18,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return const Icon(Icons.flag, size: 24); // Icône par défaut si l'image est introuvable
                                                  },
                                                ),
                                              ),
                                            Text(
                                              token['shortName'] ?? S.of(context).nameUnavailable,
                                              style: TextStyle(
                                                fontSize: 15 + appState.getTextSizeOffset(),
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context).textTheme.bodyLarge?.color,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Transform.translate(
                                        offset: const Offset(30.0, 0), // Décalage de 30 pixels vers la droite
                                        child: SizedBox(
                                          width: 100,
                                          child: rentPercentage != null ? _buildGaugeForRent(rentPercentage, context) : const SizedBox.shrink(),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${S.of(context).totalValue}: ${currencyUtils.formatCurrency(currencyUtils.convert((token['totalValue'])), currencyUtils.currencySymbol)}',
                                    style: TextStyle(
                                      fontSize: 13 + appState.getTextSizeOffset(),
                                    ),
                                  ),
                                  Text(
                                    'YAM: ${currencyUtils.formatCurrency(currencyUtils.convert((token['yamAverageValue'] * token['amount'])), currencyUtils.currencySymbol)} (${((token['yamAverageValue'] / token['tokenPrice'] - 1) * 100).toStringAsFixed(0)}%)',
                                    style: TextStyle(
                                      fontSize: 13 + appState.getTextSizeOffset(),
                                      color: (token['yamAverageValue'] * token['amount']) >= token['totalValue']
                                          ? Colors.green // Texte vert si la condition est vraie
                                          : Colors.red, // Texte rouge si la condition est fausse
                                    ),
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
                                            Text(S.of(context).week, style: TextStyle(fontSize: 13 + appState.getTextSizeOffset())),
                                            Text(currencyUtils.formatCurrency(currencyUtils.convert(token['dailyIncome']) * 7, currencyUtils.currencySymbol),
                                                style: TextStyle(fontSize: 13 + appState.getTextSizeOffset())),
                                          ],
                                        ),
                                        Column(
                                          children: [
                                            Text(S.of(context).month, style: TextStyle(fontSize: 13 + appState.getTextSizeOffset())),
                                            Text(currencyUtils.formatCurrency(currencyUtils.convert(token['monthlyIncome']), currencyUtils.currencySymbol),
                                                style: TextStyle(fontSize: 13 + appState.getTextSizeOffset())),
                                          ],
                                        ),
                                        Column(
                                          children: [
                                            Text(S.of(context).year, style: TextStyle(fontSize: 13 + appState.getTextSizeOffset())),
                                            Text(currencyUtils.formatCurrency(currencyUtils.convert(token['yearlyIncome']), currencyUtils.currencySymbol),
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
                );
              },
            ),
    );
  }
}
