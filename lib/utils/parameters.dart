import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:realtokens/generated/l10n.dart';

class Parameters {
  static late final String theGraphApiKey;
  static late final String theGraphApiKey2;

  static const String theGraphBaseUrl = 'https://gateway-arbitrum.network.thegraph.com/api';

  static const String gnosisSubgraphId = 'FPPoFB7S2dcCNrRyjM5QbaMwKqRZPdbTg8ysBrwXd4SP';
  static const String etherumSubgraphId = 'EVjGN4mMd9h9JfGR7yLC6T2xrJf9syhjQNboFb7GzxVW';
  static const String rmmSubgraphId = '2dMMk7DbQYPX6Gi5siJm6EZ2gDQBF8nJcgKtpiPnPBsK';
  static const String yamSubgraphId = '4eJa4rKCR5f8fq48BKbYBPvf7DWHppGZRvfiVUSFXBGR';

  static const String realTokensUrl = 'https://api.pitsbi.io/api';
  static const String rentTrackerUrl = 'https://ehpst.duckdns.org/realt_rent_tracker/api';
  static const String coingeckoUrl = 'https://api.coingecko.com/api/v3/coins/xdai';

  static void initialize() {
    theGraphApiKey = dotenv.env['THE_GRAPH_API_KEY']!;
    theGraphApiKey2 = dotenv.env['THE_GRAPH_API_KEY2']!;
  }

  static String getGraphUrl(String subgraphId, {bool useAlternativeKey = false}) {
    final apiKey = useAlternativeKey ? theGraphApiKey2 : theGraphApiKey;
    return '$theGraphBaseUrl/$apiKey/subgraphs/id/$subgraphId';
  }

  static const List<String> stables = ["0xe91d153e0b41518a2ce8dd3d7944fa863463a97d", "0xddafbb505ad214d7b80b1f830fccc89b60fb7a83", "0x7349c9eaa538e118725a6130e0f8341509b9f8a0"];

  // 📌 Autres paramètres inchangés
  static const Duration apiCacheDuration = Duration(hours: 1);
  static bool convertToSquareMeters = false;
  static String selectedCurrency = 'usd';
  static List<String> languages = ['en', 'fr', 'es', "zh", "it", "pt"];
  static List<String> textSizeOptions = ['verySmall', 'small', 'normal', 'big', 'veryBig'];

  static String getPropertyTypeName(int? propertyType, BuildContext context) {
    switch (propertyType) {
      case 1:
        return S.of(context).singleFamily;
      case 2:
        return S.of(context).multiFamily;
      case 3:
        return S.of(context).duplex;
      case 4:
        return S.of(context).condominium;
      case 6:
        return S.of(context).mixedUse;
      case 8:
        return S.of(context).multiFamily;
      case 9:
        return S.of(context).commercial;
      case 10:
        return S.of(context).sfrPortfolio;
      case 11:
        return S.of(context).mfrPortfolio;
      case 12:
        return S.of(context).resortBungalow;
      default:
        return S.of(context).unknown;
    }
  }

  static final Map<String, String> usStateAbbreviations = {
    'AL': 'Alabama',
    'AK': 'Alaska',
    'AZ': 'Arizona',
    'AR': 'Arkansas',
    'CA': 'California',
    'CO': 'Colorado',
    'CT': 'Connecticut',
    'DE': 'Delaware',
    'FL': 'Florida',
    'GA': 'Georgia',
    'HI': 'Hawaii',
    'ID': 'Idaho',
    'IL': 'Illinois',
    'IN': 'Indiana',
    'IA': 'Iowa',
    'KS': 'Kansas',
    'KY': 'Kentucky',
    'LA': 'Louisiana',
    'ME': 'Maine',
    'MD': 'Maryland',
    'MA': 'Massachusetts',
    'MI': 'Michigan',
    'MN': 'Minnesota',
    'MS': 'Mississippi',
    'MO': 'Missouri',
    'MT': 'Montana',
    'NE': 'Nebraska',
    'NV': 'Nevada',
    'NH': 'New Hampshire',
    'NJ': 'New Jersey',
    'NM': 'New Mexico',
    'NY': 'New York',
    'NC': 'North Carolina',
    'ND': 'North Dakota',
    'OH': 'Ohio',
    'OK': 'Oklahoma',
    'OR': 'Oregon',
    'PA': 'Pennsylvania',
    'RI': 'Rhode Island',
    'SC': 'South Carolina',
    'SD': 'South Dakota',
    'TN': 'Tennessee',
    'TX': 'Texas',
    'UT': 'Utah',
    'VT': 'Vermont',
    'VA': 'Virginia',
    'WA': 'Washington',
    'WV': 'West Virginia',
    'WI': 'Wisconsin',
    'WY': 'Wyoming'
  };

  static final Map<String, String> currencySymbols = {'usd': '\$', 'eur': '€', 'gbp': '£', 'jpy': '¥', 'inr': '₹', 'btc': '₿', 'eth': 'Ξ'};
}
