import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:realtoken_asset_tracker/utils/url_utils.dart';
import 'package:flutter/services.dart';

class DonationCardWidget extends StatelessWidget {
  final String? montantWallet;
  final bool isLoading;
  const DonationCardWidget({Key? key, this.montantWallet, this.isLoading = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            S.of(context).supportProject + " ❤️",
            style: TextStyle(
              fontSize: 24 + appState.getTextSizeOffset(),
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4 + appState.getTextSizeOffset()),
          // Loader ou montant total
          if (isLoading)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16 + appState.getTextSizeOffset()),
              child: SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                ),
              ),
            )
          else if (montantWallet != null && montantWallet!.isNotEmpty)
            Column(
              children: [
                Text(
                  S.of(context).donationTotal,
                  style: TextStyle(fontSize: 15 + appState.getTextSizeOffset(), color: Colors.grey[700]),
                ),
                SizedBox(height: 4 + appState.getTextSizeOffset()),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      montantWallet!,
                      style: TextStyle(
                        fontSize: 28 + appState.getTextSizeOffset(),
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 6 + appState.getTextSizeOffset()),
                    Padding(
                      padding: EdgeInsets.only(bottom: 2 + appState.getTextSizeOffset()),
                      child: Text(
                        'USD',
                        style: TextStyle(
                          fontSize: 15 + appState.getTextSizeOffset(),
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4 + appState.getTextSizeOffset()),
              ],
            ),
          SizedBox(height: 8 + appState.getTextSizeOffset()),
          // Message d'intro
          Text(
            S.of(context).donationMessage,
            style: TextStyle(fontSize: 14 + appState.getTextSizeOffset(), color: Colors.black87),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8 + appState.getTextSizeOffset()),
          Divider(
            color: Colors.grey[300],
            thickness: 1,
          ),
          SizedBox(height: 8 + appState.getTextSizeOffset()),

          // Bouton BuyMeACoffee
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: Text("☕", style: TextStyle(fontSize: 16 + appState.getTextSizeOffset())),
              label: Text(
                "Buy Me a Coffee",
                style: TextStyle(fontSize: 15 + appState.getTextSizeOffset(), color: Colors.black),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFDD00),
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(vertical: 10 + appState.getTextSizeOffset()),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              onPressed: () => UrlUtils.launchURL('https://buymeacoffee.com/byackee'),
            ),
          ),
          SizedBox(height: 10 + appState.getTextSizeOffset()),
          // Bouton PayPal
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: Text("💳", style: TextStyle(fontSize: 16 + appState.getTextSizeOffset())),
              label: Text(
                S.of(context).paypal,
                style: TextStyle(fontSize: 15 + appState.getTextSizeOffset(), color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0070ba),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 10 + appState.getTextSizeOffset()),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              onPressed: () => UrlUtils.launchURL('https://paypal.me/byackee?country.x=FR&locale.x=fr_FR'),
            ),
          ),
          SizedBox(height: 10 + appState.getTextSizeOffset()),
          // Section crypto
          Column(
            children: [
              Text(
                S.of(context).cryptoDonation,
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              SizedBox(height: 4 + appState.getTextSizeOffset()),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F4),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: SelectableText(
                        '0x2cb49d04890a98eb89f4f43af96ad01b98b64165',
                        style: TextStyle(
                          fontSize: 12 + appState.getTextSizeOffset(),
                          fontFamily: 'Menlo',
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 20, color: Colors.grey),
                      tooltip: S.of(context).copy,
                      onPressed: () async {
                        await Clipboard.setData(const ClipboardData(text: '0x2cb49d04890a98eb89f4f43af96ad01b98b64165'));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(S.of(context).addressCopied),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8 + appState.getTextSizeOffset()),
          // Message de remerciement
          Text(
            S.of(context).everyContributionCounts,
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
} 