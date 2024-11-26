import 'package:flutter/material.dart';
import 'package:realtokens_apps/generated/l10n.dart';

class Parameters {
//Parameters apiService
  static const Duration apiCacheDuration = Duration(hours: 1);
  static const theGraphApiKey = 'c57eb2612e998502f4418378a4cb9f35';
  static const String gnosisUrl = 'https://gateway-arbitrum.network.thegraph.com/api/$theGraphApiKey/subgraphs/id/FPPoFB7S2dcCNrRyjM5QbaMwKqRZPdbTg8ysBrwXd4SP';
  static const String etherumUrl =
      'https://gateway-arbitrum.network.thegraph.com/api/$theGraphApiKey/subgraphs/id/EVjGN4mMd9h9JfGR7yLC6T2xrJf9syhjQNboFb7GzxVW';
  static const String rmmUrl = 'https://gateway-arbitrum.network.thegraph.com/api/$theGraphApiKey/subgraphs/id/2dMMk7DbQYPX6Gi5siJm6EZ2gDQBF8nJcgKtpiPnPBsK';
  static const String yamUrl = 'https://gateway-arbitrum.network.thegraph.com/api/$theGraphApiKey/subgraphs/id/4eJa4rKCR5f8fq48BKbYBPvf7DWHppGZRvfiVUSFXBGR';
  static const String realTokensUrl = 'https://pitswap-api.herokuapp.com/api';
  static const String rentTrackerUrl = 'https://ehpst.duckdns.org/realt_rent_tracker/api';

// Parameters Settings
  static bool convertToSquareMeters = false; // Variable pour la conversion des pieds carrés
  static String selectedCurrency = 'usd'; // Déclarez la devise sélectionnée
  static List<String> languages = ['en', 'fr', 'es', "zh", "it", "pt"]; // Langues disponibles
  static List<String> textSizeOptions = ['verySmall', 'small', 'normal', 'big', 'veryBig']; // Options de taille de texte

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

  // Carte des abréviations d'États des États-Unis à leurs noms complets
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
}
