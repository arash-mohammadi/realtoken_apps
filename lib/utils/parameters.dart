import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:realtokens/generated/l10n.dart';

class Parameters {
  // ✅ Clé API chargée dynamiquement
  static late final String theGraphApiKey;

  // ✅ URLs mises à jour avec clé API dynamique
  static late final String gnosisUrl;
  static late final String etherumUrl;
  static late final String rmmUrl;
  static late final String yamUrl;

  static const String realTokensUrl = 'https://api.pitsbi.io/api';
  static const String rentTrackerUrl = 'https://ehpst.duckdns.org/realt_rent_tracker/api';

  // ✅ Méthode d'initialisation
  static void initialize() {
    theGraphApiKey = (dotenv.env['THE_GRAPH_API_KEY'] ?? dotenv.env['THE_GRAPH_API_KEY2'])!;

    gnosisUrl = 'https://gateway-arbitrum.network.thegraph.com/api/$theGraphApiKey/subgraphs/id/FPPoFB7S2dcCNrRyjM5QbaMwKqRZPdbTg8ysBrwXd4SP';
    etherumUrl = 'https://gateway-arbitrum.network.thegraph.com/api/$theGraphApiKey/subgraphs/id/EVjGN4mMd9h9JfGR7yLC6T2xrJf9syhjQNboFb7GzxVW';
    rmmUrl = 'https://gateway-arbitrum.network.thegraph.com/api/$theGraphApiKey/subgraphs/id/2dMMk7DbQYPX6Gi5siJm6EZ2gDQBF8nJcgKtpiPnPBsK';
    yamUrl = 'https://gateway-arbitrum.network.thegraph.com/api/$theGraphApiKey/subgraphs/id/4eJa4rKCR5f8fq48BKbYBPvf7DWHppGZRvfiVUSFXBGR';
  }

  // 📌 Autres paramètres inchangés
  static const Duration apiCacheDuration = Duration(hours: 1);
  static bool convertToSquareMeters = false;
  static String selectedCurrency = 'usd';
  static List<String> languages = ['en', 'fr', 'es', "zh", "it", "pt"];
  static List<String> textSizeOptions = ['verySmall', 'small', 'normal', 'big', 'veryBig'];

  static String getPropertyTypeName(int? propertyType, BuildContext context) {
    switch (propertyType) {
      case 1: return S.of(context).singleFamily;
      case 2: return S.of(context).multiFamily;
      case 3: return S.of(context).duplex;
      case 4: return S.of(context).condominium;
      case 6: return S.of(context).mixedUse;
      case 8: return S.of(context).multiFamily;
      case 9: return S.of(context).commercial;
      case 10: return S.of(context).sfrPortfolio;
      case 11: return S.of(context).mfrPortfolio;
      case 12: return S.of(context).resortBungalow;
      default: return S.of(context).unknown;
    }
  }

  static final Map<String, String> usStateAbbreviations = {
    'AL': 'Alabama', 'AK': 'Alaska', 'AZ': 'Arizona', 'AR': 'Arkansas',
    'CA': 'California', 'CO': 'Colorado', 'CT': 'Connecticut', 'DE': 'Delaware',
    'FL': 'Florida', 'GA': 'Georgia', 'HI': 'Hawaii', 'ID': 'Idaho', 'IL': 'Illinois',
    'IN': 'Indiana', 'IA': 'Iowa', 'KS': 'Kansas', 'KY': 'Kentucky', 'LA': 'Louisiana',
    'ME': 'Maine', 'MD': 'Maryland', 'MA': 'Massachusetts', 'MI': 'Michigan',
    'MN': 'Minnesota', 'MS': 'Mississippi', 'MO': 'Missouri', 'MT': 'Montana',
    'NE': 'Nebraska', 'NV': 'Nevada', 'NH': 'New Hampshire', 'NJ': 'New Jersey',
    'NM': 'New Mexico', 'NY': 'New York', 'NC': 'North Carolina', 'ND': 'North Dakota',
    'OH': 'Ohio', 'OK': 'Oklahoma', 'OR': 'Oregon', 'PA': 'Pennsylvania',
    'RI': 'Rhode Island', 'SC': 'South Carolina', 'SD': 'South Dakota',
    'TN': 'Tennessee', 'TX': 'Texas', 'UT': 'Utah', 'VT': 'Vermont',
    'VA': 'Virginia', 'WA': 'Washington', 'WV': 'West Virginia',
    'WI': 'Wisconsin', 'WY': 'Wyoming'
  };

  static final Map<String, String> currencySymbols = {
    'usd': '\$', 'eur': '€', 'gbp': '£', 'jpy': '¥', 'inr': '₹', 'btc': '₿', 'eth': 'Ξ'
  };
}
