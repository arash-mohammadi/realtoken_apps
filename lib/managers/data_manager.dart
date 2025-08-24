import '../app_state.dart';
// Reference to AppState for user context (should be set by the app at startup)
// Reference to AppState for user context (should be set by the app at startup)
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
// import 'package:meprop_asset_tracker/generated/l10n.dart';
import 'package:meprop_asset_tracker/models/healthandltv_record.dart';
import 'package:meprop_asset_tracker/models/rented_record.dart';
import 'package:meprop_asset_tracker/services/local_portfolio_service.dart';
import 'package:meprop_asset_tracker/utils/parameters.dart';
import 'package:meprop_asset_tracker/utils/location_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import '../models/balance_record.dart';
import '../models/roi_record.dart';
import '../models/apy_record.dart';
import 'archive_manager.dart';
import 'package:meprop_asset_tracker/managers/apy_manager.dart';
import 'package:flutter/foundation.dart';

class DataManager extends ChangeNotifier {
  static AppState? appStateRef;

  /// Sets mock analytics data for Russell (portfolio, rentHistory, etc.)
  /// Only sets data if Russell doesn't have saved data already
  void setMockAnalyticsDataForRussell() async {
    // بررسی کنیم که آیا داده‌های Russell قبلاً ذخیره شده است یا نه
    final prefs = await SharedPreferences.getInstance();
    final russellDataExists = prefs.containsKey('russell_portfolio_data');

    if (russellDataExists) {
      // اگر داده‌های Russell موجود است، آن‌ها را بارگذاری کنیم
      await _loadRussellDataFromPrefs();
      return;
    }

    // اگر داده‌ای موجود نیست، داده‌های تستی تنظیم کنیم
    // داده تستی غنی‌تر برای Russell با انواع مختلف productType
    _portfolio = [
      {
        'uuid': '0xMOCKTOKEN1',
        'shortName': 'Detroit House A',
        'fullName': 'Detroit Residential Property A',
        'country': 'USA',
        'regionCode': 'MI',
        'city': 'Detroit',
        'imageLink': '',
        'lat': 42.3314,
        'lng': -83.0458,
        'totalTokens': 100,
        'tokenPrice': 55.0,
        'totalValue': 5500.0,
        'amount': 100.0,
        'annualPercentageYield': 0.085,
        'dailyIncome': 1.28,
        'monthlyIncome': 38.5,
        'yearlyIncome': 467.5,
        'initialLaunchDate': '2022-01-01',
        'totalInvestment': 5500.0,
        'underlyingAssetPrice': 5500.0,
        'initialMaintenanceReserve': 120.0,
        'rentalType': 'residential',
        'rentStartDate': '2022-01-01',
        'rentedUnits': 1,
        'totalUnits': 1,
        'grossRentMonth': 42.0,
        'netRentMonth': 38.5,
        'constructionYear': 2008,
        'propertyStories': 2,
        'lotSize': 2200,
        'squareFeet': 1350,
        'marketplaceLink': '',
        'propertyType': 'single_family',
        'productType': 'real_estate_rental',
        'totalRentReceived': 462.0,
        'historic': {},
        'ethereumContract': '0xMOCKTOKEN1',
        'transactions': [],
        'source': 'wallet'
      },
      {
        'uuid': '0xMOCKTOKEN2',
        'shortName': 'Detroit Duplex B',
        'fullName': 'Detroit Duplex Property B',
        'country': 'USA',
        'regionCode': 'MI',
        'city': 'Detroit',
        'imageLink': '',
        'lat': 42.3314,
        'lng': -83.0458,
        'totalTokens': 75,
        'tokenPrice': 73.33,
        'totalValue': 5500.0,
        'amount': 75.0,
        'annualPercentageYield': 0.077,
        'dailyIncome': 1.16,
        'monthlyIncome': 35.3,
        'yearlyIncome': 423.5,
        'initialLaunchDate': '2022-06-01',
        'totalInvestment': 5500.0,
        'underlyingAssetPrice': 5500.0,
        'initialMaintenanceReserve': 110.0,
        'rentalType': 'residential',
        'rentStartDate': '2022-06-01',
        'rentedUnits': 2,
        'totalUnits': 2,
        'grossRentMonth': 38.0,
        'netRentMonth': 35.3,
        'constructionYear': 2010,
        'propertyStories': 2,
        'lotSize': 1800,
        'squareFeet': 2200,
        'marketplaceLink': '',
        'propertyType': 'duplex',
        'productType': 'real_estate_rental',
        'totalRentReceived': 423.6,
        'historic': {},
        'ethereumContract': '0xMOCKTOKEN2',
        'transactions': [],
        'source': 'wallet'
      },
      {
        'uuid': '0xMOCKTOKEN3',
        'shortName': 'Miami Condo',
        'fullName': 'Miami Waterfront Condominium',
        'country': 'USA',
        'regionCode': 'FL',
        'city': 'Miami',
        'imageLink': '',
        'lat': 25.7617,
        'lng': -80.1918,
        'totalTokens': 80,
        'tokenPrice': 137.5,
        'totalValue': 0.0,
        'amount': 80.0,
        'annualPercentageYield': 0.065,
        'dailyIncome': 1.95,
        'monthlyIncome': 59.6,
        'yearlyIncome': 715.0,
        'initialLaunchDate': '2023-01-15',
        'totalInvestment': 0.0,
        'underlyingAssetPrice': 0.0,
        'initialMaintenanceReserve': 200.0,
        'rentalType': 'residential',
        'rentStartDate': '2023-01-15',
        'rentedUnits': 1,
        'totalUnits': 1,
        'grossRentMonth': 65.0,
        'netRentMonth': 59.6,
        'constructionYear': 2018,
        'propertyStories': 1,
        'lotSize': 0,
        'squareFeet': 850,
        'marketplaceLink': '',
        'propertyType': 'condo',
        'productType': 'real_estate_rental',
        'totalRentReceived': 715.0,
        'historic': {},
        'ethereumContract': '0xMOCKTOKEN3',
        'transactions': [],
        'source': 'wallet'
      },
      {
        'uuid': '0xMOCKTOKEN4',
        'shortName': 'Dallas Office',
        'fullName': 'Dallas Commercial Office Complex',
        'country': 'USA',
        'regionCode': 'TX',
        'city': 'Dallas',
        'imageLink': '',
        'lat': 32.7767,
        'lng': -96.7970,
        'totalTokens': 60,
        'tokenPrice': 125.0,
        'totalValue': 7500.0,
        'amount': 60.0,
        'annualPercentageYield': 0.092,
        'dailyIncome': 1.89,
        'monthlyIncome': 57.5,
        'yearlyIncome': 690.0,
        'initialLaunchDate': '2023-08-01',
        'totalInvestment': 7500.0,
        'underlyingAssetPrice': 7500.0,
        'initialMaintenanceReserve': 150.0,
        'rentalType': 'commercial',
        'rentStartDate': '2023-08-01',
        'rentedUnits': 1,
        'totalUnits': 1,
        'grossRentMonth': 62.0,
        'netRentMonth': 57.5,
        'constructionYear': 2015,
        'propertyStories': 3,
        'lotSize': 5000,
        'squareFeet': 3200,
        'marketplaceLink': '',
        'propertyType': 'office',
        'productType': 'loan_income',
        'totalRentReceived': 460.0,
        'historic': {},
        'ethereumContract': '0xMOCKTOKEN4',
        'transactions': [],
        'source': 'wallet'
      },
      {
        'uuid': '0xMOCKTOKEN5',
        'shortName': 'Austin Retail',
        'fullName': 'Austin Retail Shopping Center',
        'country': 'USA',
        'regionCode': 'TX',
        'city': 'Austin',
        'imageLink': '',
        'lat': 30.2672,
        'lng': -97.7431,
        'totalTokens': 45,
        'tokenPrice': 111.11,
        'totalValue': 5000.0,
        'amount': 45.0,
        'annualPercentageYield': 0.088,
        'dailyIncome': 1.21,
        'monthlyIncome': 36.7,
        'yearlyIncome': 440.0,
        'initialLaunchDate': '2024-02-01',
        'totalInvestment': 5000.0,
        'underlyingAssetPrice': 5000.0,
        'initialMaintenanceReserve': 100.0,
        'rentalType': 'commercial',
        'rentStartDate': '2024-02-01',
        'rentedUnits': 1,
        'totalUnits': 1,
        'grossRentMonth': 40.0,
        'netRentMonth': 36.7,
        'constructionYear': 2012,
        'propertyStories': 1,
        'lotSize': 8000,
        'squareFeet': 4500,
        'marketplaceLink': '',
        'propertyType': 'retail',
        'productType': 'factoring_profitshare',
        'totalRentReceived': 220.2,
        'historic': {},
        'ethereumContract': '0xMOCKTOKEN5',
        'transactions': [],
        'source': 'RMM'
      },
      {
        'uuid': '0xMOCKTOKEN6',
        'shortName': 'Chicago Loft',
        'fullName': 'Chicago Industrial Loft',
        'country': 'USA',
        'regionCode': 'IL',
        'city': 'Chicago',
        'imageLink': '',
        'lat': 41.8781,
        'lng': -87.6298,
        'totalTokens': 35,
        'tokenPrice': 171.43,
        'totalValue': 6000.0,
        'amount': 35.0,
        'annualPercentageYield': 0.072,
        'dailyIncome': 1.18,
        'monthlyIncome': 36.0,
        'yearlyIncome': 432.0,
        'initialLaunchDate': '2024-05-01',
        'totalInvestment': 6000.0,
        'underlyingAssetPrice': 6000.0,
        'initialMaintenanceReserve': 120.0,
        'rentalType': 'residential',
        'rentStartDate': '2024-05-01',
        'rentedUnits': 1,
        'totalUnits': 1,
        'grossRentMonth': 39.0,
        'netRentMonth': 36.0,
        'constructionYear': 1995,
        'propertyStories': 1,
        'lotSize': 0,
        'squareFeet': 1800,
        'marketplaceLink': '',
        'propertyType': 'loft',
        'productType': 'real_estate_rental',
        'totalRentReceived': 144.0,
        'historic': {},
        'ethereumContract': '0xMOCKTOKEN6',
        'transactions': [],
        'source': 'wallet'
      },
      {
        'uuid': '0xMOCKTOKEN7',
        'shortName': 'NYC Studio',
        'fullName': 'New York Studio Apartment',
        'country': 'USA',
        'regionCode': 'NY',
        'city': 'New York',
        'imageLink': '',
        'lat': 40.7128,
        'lng': -74.0060,
        'totalTokens': 25,
        'tokenPrice': 200.0,
        'totalValue': 5000.0,
        'amount': 25.0,
        'annualPercentageYield': 0.058,
        'dailyIncome': 0.79,
        'monthlyIncome': 24.2,
        'yearlyIncome': 290.0,
        'initialLaunchDate': '2024-07-01',
        'totalInvestment': 5000.0,
        'underlyingAssetPrice': 5000.0,
        'initialMaintenanceReserve': 100.0,
        'rentalType': 'residential',
        'rentStartDate': '2024-07-01',
        'rentedUnits': 1,
        'totalUnits': 1,
        'grossRentMonth': 26.5,
        'netRentMonth': 24.2,
        'constructionYear': 2005,
        'propertyStories': 1,
        'lotSize': 0,
        'squareFeet': 450,
        'marketplaceLink': '',
        'propertyType': 'studio',
        'productType': 'real_estate_rental',
        'totalRentReceived': 48.4,
        'historic': {},
        'ethereumContract': '0xMOCKTOKEN7',
        'transactions': [],
        'source': 'wallet'
      },
      {
        'uuid': '0xMOCKTOKEN8',
        'shortName': 'Phoenix Warehouse',
        'fullName': 'Phoenix Industrial Warehouse',
        'country': 'USA',
        'regionCode': 'AZ',
        'city': 'Phoenix',
        'imageLink': '',
        'lat': 33.4484,
        'lng': -112.0740,
        'totalTokens': 50,
        'tokenPrice': 100.0,
        'totalValue': 5000.0,
        'amount': 50.0,
        'annualPercentageYield': 0.095,
        'dailyIncome': 1.30,
        'monthlyIncome': 39.6,
        'yearlyIncome': 475.0,
        'initialLaunchDate': '2024-09-01',
        'totalInvestment': 5000.0,
        'underlyingAssetPrice': 5000.0,
        'initialMaintenanceReserve': 100.0,
        'rentalType': 'industrial',
        'rentStartDate': '2024-09-01',
        'rentedUnits': 1,
        'totalUnits': 1,
        'grossRentMonth': 42.5,
        'netRentMonth': 39.6,
        'constructionYear': 2020,
        'propertyStories': 1,
        'lotSize': 15000,
        'squareFeet': 12000,
        'marketplaceLink': '',
        'propertyType': 'warehouse',
        'productType': 'loan_income',
        'totalRentReceived': 39.6,
        'historic': {},
        'ethereumContract': '0xMOCKTOKEN8',
        'transactions': [],
        'source': 'wallet'
      }
    ];
    rentHistory = [
      {
        'date': '2025-08-01',
        'wallet': '0xd7a6A4b95E29CE5f8f45404d1251178DAFE75AF3',
        'rents': [
          {'token': '0xMOCKTOKEN1', 'rent': 38.5},
          {'token': '0xMOCKTOKEN2', 'rent': 35.3},
          {'token': '0xMOCKTOKEN3', 'rent': 59.6}
        ]
      },
      {
        'date': '2025-08-01',
        'wallet': '0xOTHERWALLET000000000000000000000001',
        'rents': [
          {'token': '0xMOCKTOKEN4', 'rent': 57.5},
          {'token': '0xMOCKTOKEN5', 'rent': 36.7}
        ]
      },
      {
        'date': '2025-08-01',
        'wallet': '0xOTHERWALLET000000000000000000000002',
        'rents': [
          {'token': '0xMOCKTOKEN6', 'rent': 36.0},
          {'token': '0xMOCKTOKEN7', 'rent': 24.2},
          {'token': '0xMOCKTOKEN8', 'rent': 39.6}
        ]
      },
      {
        'date': '2025-07-01',
        'wallet': '0xd7a6A4b95E29CE5f8f45404d1251178DAFE75AF3',
        'rents': [
          {'token': '0xMOCKTOKEN1', 'rent': 37.8},
          {'token': '0xMOCKTOKEN2', 'rent': 34.9},
          {'token': '0xMOCKTOKEN3', 'rent': 58.2}
        ]
      },
      {
        'date': '2025-07-01',
        'wallet': '0xOTHERWALLET000000000000000000000001',
        'rents': [
          {'token': '0xMOCKTOKEN4', 'rent': 56.8},
          {'token': '0xMOCKTOKEN5', 'rent': 36.1}
        ]
      },
      {
        'date': '2025-07-01',
        'wallet': '0xOTHERWALLET000000000000000000000002',
        'rents': [
          {'token': '0xMOCKTOKEN6', 'rent': 35.5},
          {'token': '0xMOCKTOKEN7', 'rent': 23.8},
          {'token': '0xMOCKTOKEN8', 'rent': 39.0}
        ]
      },
      {
        'date': '2025-06-01',
        'wallet': '0xd7a6A4b95E29CE5f8f45404d1251178DAFE75AF3',
        'rents': [
          {'token': '0xMOCKTOKEN1', 'rent': 37.2},
          {'token': '0xMOCKTOKEN2', 'rent': 34.5},
          {'token': '0xMOCKTOKEN3', 'rent': 57.8}
        ]
      },
      {
        'date': '2025-06-01',
        'wallet': '0xOTHERWALLET000000000000000000000001',
        'rents': [
          {'token': '0xMOCKTOKEN4', 'rent': 56.2},
          {'token': '0xMOCKTOKEN5', 'rent': 35.8}
        ]
      },
      {
        'date': '2025-06-01',
        'wallet': '0xOTHERWALLET000000000000000000000002',
        'rents': [
          {'token': '0xMOCKTOKEN6', 'rent': 35.1},
          {'token': '0xMOCKTOKEN7', 'rent': 23.5},
          {'token': '0xMOCKTOKEN8', 'rent': 38.5}
        ]
      }
    ];
    // سایر فیلدهای تحلیلی را هم مقداردهی می‌کنیم
    walletValue = 22000.0; // Wallet 1: 16500, Wallet 2: 12500, Wallet 3: 16000
    roiGlobalValue = 0.078;
    netGlobalApy = 0.078;
    totalWalletValue = 45000.0; // مجموع کل پورتفولیو
    totalRealtTokens = 8;
    totalRealtInvestment = 45000.0;
    netRealtRentYear = 3517.1;
    realtInitialPrice = 45000.0;
    realtActualPrice = 45000.0;
    totalRealtUnits = 8;
    rentedRealtUnits = 8;
    averageRealtAnnualYield = 0.078;
    usdcDepositApy = 0.035;
    usdcBorrowApy = 0.055;
    xdaiDepositApy = 0.028;
    xdaiBorrowApy = 0.048;
    apyAverage = 0.078;
    healthFactor = 1.8;
    ltv = 0.35;
    walletTokenCount = 8;
    rmmTokenCount = 1; // TOKEN5 از RMM
    totalTokenCount = 8;
    duplicateTokenCount = 0;
    // تکمیل سایر فیلدهای آماری و تحلیلی
    rmmValue = 5000.0; // فقط TOKEN5
    perWalletRmmValues = {
      '0xd7a6A4b95E29CE5f8f45404d1251178DAFE75AF3': 0.0,
      '0xOTHERWALLET000000000000000000000001': 5000.0, // TOKEN5
      '0xOTHERWALLET000000000000000000000002': 0.0
    };
    rwaHoldingsValue = 0.0;
    rentedUnits = 8;
    totalUnits = 8;
    initialTotalValue = 45000.0;
    yamTotalValue = 0.0;
    totalTokens = 370.0; // مجموع همه amounts
    walletTokensSums = 370.0;
    rmmTokensSums = 45.0; // فقط TOKEN5
    averageAnnualYield = 0.078;
    dailyRent = 9.64; // مجموع daily income
    weeklyRent = 67.48;
    monthlyRent = 291.9; // مجموع monthly income
    yearlyRent = 3517.1; // مجموع yearly income
    userIdToAddresses = {
      'russell': [
        '0xd7a6A4b95E29CE5f8f45404d1251178DAFE75AF3',
        '0xOTHERWALLET000000000000000000000001',
        '0xOTHERWALLET000000000000000000000002'
      ]
    };
    totalUsdcDepositBalance = 2500.0;
    totalUsdcBorrowBalance = 800.0;
    totalXdaiDepositBalance = 1500.0;
    totalXdaiBorrowBalance = 500.0;
    gnosisUsdcBalance = 3200.0; // کیف پول فیک Russell: $3200
    gnosisXdaiBalance = 850.0;
    gnosisRegBalance = 120.0;
    gnosisVaultRegBalance = 85.0;
    walletStats = [
      {
        'wallet': '0xd7a6A4b95E29CE5f8f45404d1251178DAFE75AF3',
        'value': 22000.0, // TOKEN1 + TOKEN2 + TOKEN3
        'tokens': 3,
        'apy': 0.0757, // متوسط APY سه توکن
        'roi': 0.085,
        'ltv': 0.32,
        'healthFactor': 2.1
      },
      {
        'wallet': '0xOTHERWALLET000000000000000000000001',
        'value': 12500.0, // TOKEN4 + TOKEN5
        'tokens': 2,
        'apy': 0.090, // متوسط APY دو توکن
        'roi': 0.078,
        'ltv': 0.38,
        'healthFactor': 1.9
      },
      {
        'wallet': '0xOTHERWALLET000000000000000000000002',
        'value': 16000.0, // TOKEN6 + TOKEN7 + TOKEN8
        'tokens': 3,
        'apy': 0.075, // متوسط APY سه توکن
        'roi': 0.071,
        'ltv': 0.35,
        'healthFactor': 1.7
      }
    ];
    evmAddresses = [
      '0xd7a6A4b95E29CE5f8f45404d1251178DAFE75AF3',
      '0xOTHERWALLET000000000000000000000001',
      '0xOTHERWALLET000000000000000000000002'
    ];
    propertyData = [];
    perWalletBalances = [
      {'wallet': '0xd7a6A4b95E29CE5f8f45404d1251178DAFE75AF3', 'balance': 22000.0},
      {'wallet': '0xOTHERWALLET000000000000000000000001', 'balance': 12500.0},
      {'wallet': '0xOTHERWALLET000000000000000000000002', 'balance': 16000.0}
    ];
    cumulativeRentsByToken = {
      '0xMOCKTOKEN1': 462.0,
      '0xMOCKTOKEN2': 423.6,
      '0xMOCKTOKEN3': 715.0,
      '0xMOCKTOKEN4': 460.0,
      '0xMOCKTOKEN5': 220.2,
      '0xMOCKTOKEN6': 144.0,
      '0xMOCKTOKEN7': 48.4,
      '0xMOCKTOKEN8': 39.6
    };
    cumulativeRentsByWallet = {
      '0xd7a6A4b95E29CE5f8f45404d1251178DAFE75AF3': {
        '0xMOCKTOKEN1': 462.0,
        '0xMOCKTOKEN2': 423.6,
        '0xMOCKTOKEN3': 715.0
      },
      '0xOTHERWALLET000000000000000000000001': {'0xMOCKTOKEN4': 460.0, '0xMOCKTOKEN5': 220.2},
      '0xOTHERWALLET000000000000000000000002': {'0xMOCKTOKEN6': 144.0, '0xMOCKTOKEN7': 48.4, '0xMOCKTOKEN8': 39.6}
    };
    tokensWalletCount = {
      '0xMOCKTOKEN1': 1,
      '0xMOCKTOKEN2': 1,
      '0xMOCKTOKEN3': 1,
      '0xMOCKTOKEN4': 1,
      '0xMOCKTOKEN5': 1,
      '0xMOCKTOKEN6': 1,
      '0xMOCKTOKEN7': 1,
      '0xMOCKTOKEN8': 1
    };
    rentData = [
      {'token': '0xMOCKTOKEN1', 'rent': 38.5, 'date': '2025-08-01'},
      {'token': '0xMOCKTOKEN2', 'rent': 35.3, 'date': '2025-08-01'},
      {'token': '0xMOCKTOKEN3', 'rent': 59.6, 'date': '2025-08-01'},
      {'token': '0xMOCKTOKEN4', 'rent': 57.5, 'date': '2025-08-01'},
      {'token': '0xMOCKTOKEN5', 'rent': 36.7, 'date': '2025-08-01'},
      {'token': '0xMOCKTOKEN6', 'rent': 36.0, 'date': '2025-08-01'},
      {'token': '0xMOCKTOKEN7', 'rent': 24.2, 'date': '2025-08-01'},
      {'token': '0xMOCKTOKEN8', 'rent': 39.6, 'date': '2025-08-01'}
    ];
    detailedRentData = [
      {
        'date': '2025-08-01',
        'wallet': '0xd7a6A4b95E29CE5f8f45404d1251178DAFE75AF3',
        'token': '0xMOCKTOKEN1',
        'rent': 38.5
      },
      {
        'date': '2025-08-01',
        'wallet': '0xd7a6A4b95E29CE5f8f45404d1251178DAFE75AF3',
        'token': '0xMOCKTOKEN2',
        'rent': 35.3
      },
      {
        'date': '2025-08-01',
        'wallet': '0xd7a6A4b95E29CE5f8f45404d1251178DAFE75AF3',
        'token': '0xMOCKTOKEN3',
        'rent': 59.6
      },
      {'date': '2025-08-01', 'wallet': '0xOTHERWALLET000000000000000000000001', 'token': '0xMOCKTOKEN4', 'rent': 57.5},
      {'date': '2025-08-01', 'wallet': '0xOTHERWALLET000000000000000000000001', 'token': '0xMOCKTOKEN5', 'rent': 36.7},
      {'date': '2025-08-01', 'wallet': '0xOTHERWALLET000000000000000000000002', 'token': '0xMOCKTOKEN6', 'rent': 36.0},
      {'date': '2025-08-01', 'wallet': '0xOTHERWALLET000000000000000000000002', 'token': '0xMOCKTOKEN7', 'rent': 24.2},
      {'date': '2025-08-01', 'wallet': '0xOTHERWALLET000000000000000000000002', 'token': '0xMOCKTOKEN8', 'rent': 39.6}
    ];
    notifyListeners();

    // ذخیره داده‌های Russell در SharedPreferences
    await _saveRussellDataToPrefs();
  }

  /// ذخیره داده‌های Russell در SharedPreferences
  Future<void> _saveRussellDataToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final russellData = {
      // Portfolio data
      'portfolio': _portfolio,
      'initialTotalValue': initialTotalValue,
      'totalTokenCount': totalTokenCount,

      // Rent data
      'monthlyRent': monthlyRent,
      'yearlyRent': yearlyRent,
      'dailyRent': dailyRent,
      'weeklyRent': weeklyRent,
      'rentData': rentData,
      'detailedRentData': detailedRentData,
      'cumulativeRentsByToken': cumulativeRentsByToken,
      'cumulativeRentsByWallet': cumulativeRentsByWallet,

      // Wallet & Balance data
      'evmAddresses': evmAddresses,
      'perWalletBalances': perWalletBalances,
      'walletStats': walletStats,
      'gnosisUsdcBalance': gnosisUsdcBalance,
      'gnosisXdaiBalance': gnosisXdaiBalance,
      'gnosisRegBalance': gnosisRegBalance,
      'gnosisVaultRegBalance': gnosisVaultRegBalance,

      // Statistics
      'averageAnnualYield': averageAnnualYield,
      'rmmValue': rmmValue,
      'perWalletRmmValues': perWalletRmmValues,
      'rwaHoldingsValue': rwaHoldingsValue,
      'rentedUnits': rentedUnits,
      'totalUnits': totalUnits,
      'yamTotalValue': yamTotalValue,
      'totalTokens': totalTokens,
      'walletTokensSums': walletTokensSums,
      'rmmTokensSums': rmmTokensSums,
      'tokensWalletCount': tokensWalletCount,

      // User mapping
      'userIdToAddresses': userIdToAddresses,

      'lastUpdated': DateTime.now().toIso8601String(),
    };
    await prefs.setString('russell_portfolio_data', jsonEncode(russellData));
    debugPrint('✅ Russell data saved successfully');
  }

  /// بارگذاری داده‌های Russell از SharedPreferences
  Future<void> _loadRussellDataFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final russellDataJson = prefs.getString('russell_portfolio_data');

    if (russellDataJson != null) {
      try {
        final russellData = jsonDecode(russellDataJson) as Map<String, dynamic>;

        // Portfolio data
        _portfolio = List<Map<String, dynamic>>.from(russellData['portfolio'] ?? []);

        // Add mock data if portfolio is empty
        if (_portfolio.isEmpty) {
          _generateMockPortfolioData();
        }
        initialTotalValue = (russellData['initialTotalValue'] as num?)?.toDouble() ?? 0.0;
        totalTokenCount = russellData['totalTokenCount'] as int? ?? 0;

        // Rent data
        monthlyRent = (russellData['monthlyRent'] as num?)?.toDouble() ?? 0.0;
        yearlyRent = (russellData['yearlyRent'] as num?)?.toDouble() ?? 0.0;
        dailyRent = (russellData['dailyRent'] as num?)?.toDouble() ?? 0.0;
        weeklyRent = (russellData['weeklyRent'] as num?)?.toDouble() ?? 0.0;
        rentData = List<Map<String, dynamic>>.from(russellData['rentData'] ?? []);
        detailedRentData = List<Map<String, dynamic>>.from(russellData['detailedRentData'] ?? []);
        cumulativeRentsByToken = Map<String, double>.from(russellData['cumulativeRentsByToken'] ?? {});
        cumulativeRentsByWallet = Map<String, Map<String, double>>.from((russellData['cumulativeRentsByWallet'] ?? {})
            .map((k, v) => MapEntry(k, Map<String, double>.from(v ?? {}))));

        // Wallet & Balance data
        evmAddresses = List<String>.from(russellData['evmAddresses'] ?? []);
        perWalletBalances = List<Map<String, dynamic>>.from(russellData['perWalletBalances'] ?? []);
        walletStats = List<Map<String, dynamic>>.from(russellData['walletStats'] ?? []);
        gnosisUsdcBalance = (russellData['gnosisUsdcBalance'] as num?)?.toDouble() ?? 0.0;
        gnosisXdaiBalance = (russellData['gnosisXdaiBalance'] as num?)?.toDouble() ?? 0.0;
        gnosisRegBalance = (russellData['gnosisRegBalance'] as num?)?.toDouble() ?? 0.0;
        gnosisVaultRegBalance = (russellData['gnosisVaultRegBalance'] as num?)?.toDouble() ?? 0.0;

        // Statistics
        averageAnnualYield = (russellData['averageAnnualYield'] as num?)?.toDouble() ?? 0.0;
        rmmValue = (russellData['rmmValue'] as num?)?.toDouble() ?? 0.0;
        perWalletRmmValues = Map<String, double>.from(russellData['perWalletRmmValues'] ?? {});
        rwaHoldingsValue = (russellData['rwaHoldingsValue'] as num?)?.toDouble() ?? 0.0;
        rentedUnits = russellData['rentedUnits'] as int? ?? 0;
        totalUnits = russellData['totalUnits'] as int? ?? 0;
        yamTotalValue = (russellData['yamTotalValue'] as num?)?.toDouble() ?? 0.0;
        totalTokens = (russellData['totalTokens'] as num?)?.toDouble() ?? 0.0;
        walletTokensSums = (russellData['walletTokensSums'] as num?)?.toDouble() ?? 0.0;
        rmmTokensSums = (russellData['rmmTokensSums'] as num?)?.toDouble() ?? 0.0;
        tokensWalletCount = Map<String, int>.from(russellData['tokensWalletCount'] ?? {});

        // User mapping
        userIdToAddresses = Map<String, List<String>>.from(
            (russellData['userIdToAddresses'] ?? {}).map((k, v) => MapEntry(k, List<String>.from(v ?? []))));

        debugPrint('✅ Russell data loaded successfully from SharedPreferences');
        notifyListeners();
      } catch (e) {
        debugPrint('❌ Error loading Russell data: $e');
      }
    }
  }

  /// به‌روزرسانی و ذخیره داده‌های Russell در زمان تغییرات
  Future<void> updateRussellDataIfNeeded() async {
    // اگر کاربر فعلی Russell است، داده‌ها را ذخیره کنیم
    if (DataManager.appStateRef?.currentUser?.username.toLowerCase() == 'russell') {
      await _saveRussellDataToPrefs();
    }
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
    // ذخیره خودکار داده‌های Russell هر بار که تغییری ایجاد می‌شود
    _autoSaveRussellData();
  }

  void _autoSaveRussellData() async {
    try {
      if (DataManager.appStateRef?.currentUser?.username.toLowerCase() == 'russell') {
        await _saveRussellDataToPrefs();
      }
    } catch (e) {
      debugPrint('Error auto-saving Russell data: $e');
    }
  }

  /// پاک کردن داده‌های ذخیره‌شده Russell (برای تست یا reset)
  Future<void> clearRussellData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('russell_portfolio_data');
    debugPrint('🗑️ Russell data cleared from SharedPreferences');
  }

  /// Sets enhanced mock data specifically for analytics/statistics charts
  void setEnhancedAnalyticsDataForRussell() async {
    final now = DateTime.now();

    // Enhanced wallet balance history for more detailed charts
    final balanceHistory = <BalanceRecord>[];
    for (int i = 365; i >= 0; i -= 3) {
      // Every 3 days for detailed history
      final timestamp = now.subtract(Duration(days: i));
      final baseValue = 8500.0;
      final seasonalVariation = 1000 * (0.5 + 0.5 * sin((i / 365) * 2 * pi));
      final growth = (365 - i) * 7.5; // Steady growth
      final noise = (Random().nextDouble() - 0.5) * 200; // Random variation
      final balance = baseValue + seasonalVariation + growth + noise;

      balanceHistory.add(BalanceRecord(
          tokenType: 'totalWalletValue',
          balance: balance.clamp(8000.0, 30000.0), // Reasonable bounds
          timestamp: timestamp));
    }
    walletBalanceHistory = balanceHistory;

    // Enhanced ROI history for ROI charts
    final roiHistoryData = <ROIRecord>[];
    for (int i = 365; i >= 0; i -= 7) {
      // Weekly ROI data
      final timestamp = now.subtract(Duration(days: i));
      final baseRoi = 8.5;
      final growth = (365 - i) * 0.01; // ROI improvement over time
      final variation = 2.0 * sin((i / 30) * 2 * pi); // Monthly cycles
      final roi = baseRoi + growth + variation;

      roiHistoryData.add(ROIRecord(roi: roi.clamp(5.0, 15.0), timestamp: timestamp));
    }
    roiHistory = roiHistoryData;

    // Enhanced APY history for APY charts
    final apyHistoryData = <APYRecord>[];
    for (int i = 365; i >= 0; i -= 7) {
      // Weekly APY data
      final timestamp = now.subtract(Duration(days: i));
      final baseApy = 7.2;
      final seasonalFactor = 1.5 * sin((i / 90) * 2 * pi); // Quarterly cycles
      final apy = baseApy + seasonalFactor;

      apyHistoryData.add(APYRecord(apy: apy.clamp(5.0, 10.0), timestamp: timestamp));
    }
    apyHistory = apyHistoryData;

    // Enhanced rent data with historical depth
    final enhancedRentData = <Map<String, dynamic>>[];
    final enhancedDetailedRentData = <Map<String, dynamic>>[];

    for (int i = 24; i >= 0; i--) {
      // 24 months of rent history
      final date = DateTime(now.year, now.month - i, 1);
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-01';

      final baseRent1 = 37.8;
      final baseRent2 = 35.1;
      final baseRent3 = 42.5;

      // Add seasonal variation and growth
      final seasonalMultiplier = 1 + 0.1 * sin((i / 12) * 2 * pi);
      final growthFactor = 1 + (24 - i) * 0.005; // 0.5% monthly growth

      final rent1 = baseRent1 * seasonalMultiplier * growthFactor;
      final rent2 = baseRent2 * seasonalMultiplier * growthFactor;
      final rent3 = baseRent3 * seasonalMultiplier * growthFactor;

      enhancedRentData.addAll([
        {'token': '0xMOCKTOKEN1', 'rent': rent1, 'date': dateStr},
        {'token': '0xMOCKTOKEN2', 'rent': rent2, 'date': dateStr},
        {'token': '0xMOCKTOKEN3', 'rent': rent3, 'date': dateStr},
      ]);

      enhancedDetailedRentData.addAll([
        {
          'date': dateStr,
          'wallet': '0xd7a6A4b95E29CE5f8f45404d1251178DAFE75AF3',
          'token': '0xMOCKTOKEN1',
          'rent': rent1
        },
        {
          'date': dateStr,
          'wallet': '0xd7a6A4b95E29CE5f8f45404d1251178DAFE75AF3',
          'token': '0xMOCKTOKEN2',
          'rent': rent2
        },
        {'date': dateStr, 'wallet': '0xOTHERWALLET000000000000000000000001', 'token': '0xMOCKTOKEN3', 'rent': rent3},
      ]);
    }

    rentData = enhancedRentData;
    detailedRentData = enhancedDetailedRentData;

    // Enhanced wallet tokens data for distribution charts
    walletTokens = [
      // Russell's main wallet (Wallet 1)
      {
        'wallet': '0xd7a6A4b95E29CE5f8f45404d1251178DAFE75AF3',
        'token': '0xMOCKTOKEN1',
        'shortName': 'Detroit House A',
        'amount': 100.0,
        'value': 5500.0,
        'productType': 'real_estate_rental',
        'propertyType': 'single_family',
        'country': 'USA',
        'city': 'Detroit'
      },
      {
        'wallet': '0xd7a6A4b95E29CE5f8f45404d1251178DAFE75AF3',
        'token': '0xMOCKTOKEN2',
        'shortName': 'Detroit Duplex B',
        'amount': 75.0,
        'value': 5500.0,
        'productType': 'real_estate_rental',
        'propertyType': 'duplex',
        'country': 'USA',
        'city': 'Detroit'
      },
      {
        'wallet': '0xd7a6A4b95E29CE5f8f45404d1251178DAFE75AF3',
        'token': '0xMOCKTOKEN3',
        'shortName': 'Miami Condo',
        'amount': 80.0,
        'value': 0.0,
        'productType': 'real_estate_rental',
        'propertyType': 'condo',
        'country': 'USA',
        'city': 'Miami'
      },

      // Second wallet for distribution (Wallet 2)
      {
        'wallet': '0xOTHERWALLET000000000000000000000001',
        'token': '0xMOCKTOKEN4',
        'shortName': 'Dallas Office',
        'amount': 60.0,
        'value': 7500.0,
        'productType': 'loan_income',
        'propertyType': 'office',
        'country': 'USA',
        'city': 'Dallas'
      },
      {
        'wallet': '0xOTHERWALLET000000000000000000000001',
        'token': '0xMOCKTOKEN5',
        'shortName': 'Austin Retail',
        'amount': 45.0,
        'value': 5000.0,
        'productType': 'factoring_profitshare',
        'propertyType': 'retail',
        'country': 'USA',
        'city': 'Austin'
      },

      // Third wallet (Wallet 3)
      {
        'wallet': '0xOTHERWALLET000000000000000000000002',
        'token': '0xMOCKTOKEN6',
        'shortName': 'Chicago Loft',
        'amount': 35.0,
        'value': 6000.0,
        'productType': 'real_estate_rental',
        'propertyType': 'loft',
        'country': 'USA',
        'city': 'Chicago'
      },
      {
        'wallet': '0xOTHERWALLET000000000000000000000002',
        'token': '0xMOCKTOKEN7',
        'shortName': 'NYC Studio',
        'amount': 25.0,
        'value': 5000.0,
        'productType': 'real_estate_rental',
        'propertyType': 'studio',
        'country': 'USA',
        'city': 'New York'
      },
      {
        'wallet': '0xOTHERWALLET000000000000000000000002',
        'token': '0xMOCKTOKEN8',
        'shortName': 'Phoenix Warehouse',
        'amount': 50.0,
        'value': 5000.0,
        'productType': 'loan_income',
        'propertyType': 'warehouse',
        'country': 'USA',
        'city': 'Phoenix'
      }
    ];

    // Enhanced cumulative rents
    cumulativeRentsByToken = {
      '0xMOCKTOKEN1': 462.0,
      '0xMOCKTOKEN2': 423.6,
      '0xMOCKTOKEN3': 715.0,
      '0xMOCKTOKEN4': 460.0,
      '0xMOCKTOKEN5': 220.2,
      '0xMOCKTOKEN6': 144.0,
      '0xMOCKTOKEN7': 48.4,
      '0xMOCKTOKEN8': 39.6
    };

    cumulativeRentsByWallet = {
      '0xd7a6A4b95E29CE5f8f45404d1251178DAFE75AF3': {
        '0xMOCKTOKEN1': 462.0,
        '0xMOCKTOKEN2': 423.6,
        '0xMOCKTOKEN3': 715.0
      },
      '0xOTHERWALLET000000000000000000000001': {'0xMOCKTOKEN4': 460.0, '0xMOCKTOKEN5': 220.2},
      '0xOTHERWALLET000000000000000000000002': {'0xMOCKTOKEN6': 144.0, '0xMOCKTOKEN7': 48.4, '0xMOCKTOKEN8': 39.6}
    };

    // Enhanced monthly/yearly rent calculations
    monthlyRent = 115.4; // Sum of recent monthly rents
    yearlyRent = 1384.8; // Projected yearly
    dailyRent = 3.85; // Daily average
    weeklyRent = 26.95; // Weekly average

    // Enhanced portfolio with diverse product types
    final enhancedPortfolioItems = [
      {
        'uuid': '0xMOCKTOKEN3',
        'shortName': 'Miami Waterfront',
        'country': 'USA',
        'regionCode': 'FL',
        'city': 'Miami',
        'productType': 'real_estate_rental',
        'totalValue': 6500.0,
        'amount': 50.0,
        'annualPercentageYield': 0.072,
        'totalRentReceived': 520.0,
        'propertyType': 'condo',
        'dailyIncome': 1.42,
        'monthlyIncome': 43.3,
        'yearlyIncome': 468.0,
        'rentedUnits': 1,
        'totalUnits': 1,
        'source': 'wallet'
      },
      {
        'uuid': '0xMOCKTOKEN4',
        'shortName': 'Dallas Office Complex',
        'country': 'USA',
        'regionCode': 'TX',
        'city': 'Dallas',
        'productType': 'loan_income',
        'totalValue': 3750.0,
        'amount': 25.0,
        'annualPercentageYield': 0.087,
        'totalRentReceived': 290.0,
        'propertyType': 'office',
        'dailyIncome': 0.96,
        'monthlyIncome': 29.2,
        'yearlyIncome': 326.0,
        'rentedUnits': 1,
        'totalUnits': 1,
        'source': 'wallet'
      },
      {
        'uuid': '0xMOCKTOKEN5',
        'shortName': 'Austin Retail Space',
        'country': 'USA',
        'regionCode': 'TX',
        'city': 'Austin',
        'productType': 'factoring_profitshare',
        'totalValue': 4200.0,
        'amount': 60.0,
        'annualPercentageYield': 0.078,
        'totalRentReceived': 180.0,
        'propertyType': 'retail',
        'dailyIncome': 0.49,
        'monthlyIncome': 15.0,
        'yearlyIncome': 180.0,
        'rentedUnits': 1,
        'totalUnits': 1,
        'source': 'RMM'
      },
      {
        'uuid': '0xMOCKTOKEN6',
        'shortName': 'Chicago Loft',
        'country': 'USA',
        'regionCode': 'IL',
        'city': 'Chicago',
        'productType': 'real_estate_rental',
        'totalValue': 6800.0,
        'amount': 40.0,
        'annualPercentageYield': 0.065,
        'totalRentReceived': 340.0,
        'propertyType': 'loft',
        'dailyIncome': 1.21,
        'monthlyIncome': 36.8,
        'yearlyIncome': 442.0,
        'rentedUnits': 1,
        'totalUnits': 1,
        'source': 'wallet'
      },
      {
        'uuid': '0xMOCKTOKEN7',
        'shortName': 'NYC Studio',
        'country': 'USA',
        'regionCode': 'NY',
        'city': 'New York',
        'productType': 'real_estate_rental',
        'totalValue': 4500.0,
        'amount': 20.0,
        'annualPercentageYield': 0.058,
        'totalRentReceived': 225.0,
        'propertyType': 'studio',
        'dailyIncome': 0.71,
        'monthlyIncome': 21.7,
        'yearlyIncome': 261.0,
        'rentedUnits': 1,
        'totalUnits': 1,
        'source': 'wallet'
      }
    ];

    // Add to existing portfolio
    for (final item in enhancedPortfolioItems) {
      _portfolio.add(item);
    }

    // Enhanced transaction data for transaction analysis
    transactionsHistory = [
      {
        'hash': '0xabc123',
        'timestamp': now.subtract(Duration(days: 30)).millisecondsSinceEpoch,
        'amount': 100.0,
        'type': 'buy',
        'token': '0xMOCKTOKEN1',
        'price': 55.0,
        'wallet': '0xd7a6A4b95E29CE5f8f45404d1251178DAFE75AF3'
      },
      {
        'hash': '0xdef456',
        'timestamp': now.subtract(Duration(days: 60)).millisecondsSinceEpoch,
        'amount': 50.0,
        'type': 'buy',
        'token': '0xMOCKTOKEN2',
        'price': 110.0,
        'wallet': '0xd7a6A4b95E29CE5f8f45404d1251178DAFE75AF3'
      },
      {
        'hash': '0xghi789',
        'timestamp': now.subtract(Duration(days: 90)).millisecondsSinceEpoch,
        'amount': 25.0,
        'type': 'sell',
        'token': '0xMOCKTOKEN1',
        'price': 58.0,
        'wallet': '0xd7a6A4b95E29CE5f8f45404d1251178DAFE75AF3'
      },
    ];

    // Update total values to reflect enhanced data
    totalWalletValue = 27200.0;
    walletValue = 23000.0;
    rmmValue = 4200.0;

    // Update wallet stats for multi-wallet distribution
    walletStats = [
      {
        'wallet': '0xd7a6A4b95E29CE5f8f45404d1251178DAFE75AF3',
        'address': '0xd7a6A4b95E29CE5f8f45404d1251178DAFE75AF3',
        'value': 0.0,
        'tokens': 2,
        'apy': 0.075,
        'roi': 0.12,
        'ltv': 0.35,
        'healthFactor': 1.8,
        'walletValueSum': 0.0,
        'rmmValue': 0.0,
        'tokenCount': 2,
        'walletTokensSum': 150.0,
        'rmmTokensSum': 0.0
      },
      {
        'wallet': '0xOTHERWALLET000000000000000000000001',
        'address': '0xOTHERWALLET000000000000000000000001',
        'value': 16200.0,
        'tokens': 3,
        'apy': 0.082,
        'roi': 0.095,
        'ltv': 0.28,
        'healthFactor': 2.1,
        'walletValueSum': 16200.0,
        'rmmValue': 2100.0,
        'tokenCount': 3,
        'walletTokensSum': 160.0,
        'rmmTokensSum': 30.0
      },
      {
        'wallet': '0xOTHERWALLET000000000000000000000002',
        'address': '0xOTHERWALLET000000000000000000000002',
        'value': 11300.0,
        'tokens': 2,
        'apy': 0.062,
        'roi': 0.088,
        'ltv': 0.42,
        'healthFactor': 1.6,
        'walletValueSum': 11300.0,
        'rmmValue': 0.0,
        'tokenCount': 2,
        'walletTokensSum': 60.0,
        'rmmTokensSum': 0.0
      }
    ];

    // Save the enhanced data
    await saveWalletBalanceHistory();
    notifyListeners();
  }

  // Constantes pour les types de transaction
  static const String transactionTypeTransfer = 'transfer';
  static const String transactionTypePurchase = 'purchase';
  static const String transactionTypeYam = 'yam';

  // Préfixes de log pour différents niveaux hiérarchiques
  static const String _logMain = "[MAIN] 📊";
  static const String _logSub = "  [SUB] 📌";
  static const String _logTask = "    [TASK] 🔹";
  static const String _logDetail = "      [DETAIL] ▫️";
  static const String _logWarning = "⚠️";
  static const String _logError = "❌";
  static const String _logSuccess = "✅";

  // Singleton pour DataManager
  static final DataManager _instance = DataManager._internal(
    archiveManager: ArchiveManager(),
    apyManager: ApyManager(),
  );

  factory DataManager() => _instance;

  // Variables finales pour les managers
  final ArchiveManager _archiveManager;
  final ApyManager apyManager;
  final CacheService _cacheService = CacheService();

  // Flags pour suivre l'état d'exécution des fonctions de chargement de données
  bool _isLoadingFromCache = false;
  bool _isUpdatingMainInformations = false;
  bool _isUpdatingSecondaryInformations = false;

  // Constructeur privé pour le singleton
  DataManager._internal({
    required ArchiveManager archiveManager,
    required ApyManager apyManager,
  })  : _archiveManager = archiveManager,
        apyManager = apyManager {
    _initializeServices(); // Initialiser les services
    loadCustomInitPrices(); // Charger les prix personnalisés lors de l'initialisation
    _loadApyReactivityPreference(); // Charger la préférence de réactivité APY

    // Initialiser l'ArchiveManager avec une référence à cette instance
    _archiveManager.setDataManager(this);
  }

  /// Initialise les services nécessaires
  Future<void> _initializeServices() async {
    try {
      await _cacheService.initialize();
      debugPrint("✅ CacheService initialisé");
    } catch (e) {
      debugPrint("❌ Erreur initialisation CacheService: $e");
    }
  }

  // --- Top-level wallet sync helpers for Russell login/logout ---
  Future<void> saveWalletForUserId({
    required String userId,
    required String address,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    // Update userIdToAddresses
    String? savedData = prefs.getString('userIdToAddresses');
    Map<String, dynamic> userIdToAddresses = {};
    if (savedData != null) {
      final decodedMap = Map<String, dynamic>.from(jsonDecode(savedData));
      userIdToAddresses = decodedMap.map((userId, encodedAddresses) {
        final addresses = List<String>.from(jsonDecode(encodedAddresses));
        return MapEntry(userId, addresses);
      });
    }
    List<String> addresses = userIdToAddresses[userId]?.cast<String>() ?? [];
    if (!addresses.contains(address.toLowerCase())) {
      addresses.add(address.toLowerCase());
      userIdToAddresses[userId] = addresses;
      final userIdToAddressesJson = userIdToAddresses.map((userId, addresses) {
        return MapEntry(userId, jsonEncode(addresses));
      });
      await prefs.setString('userIdToAddresses', jsonEncode(userIdToAddressesJson));
    }
    // Update evmAddresses
    List<String> evmAddresses = prefs.getStringList('evmAddresses') ?? [];
    if (!evmAddresses.contains(address.toLowerCase())) {
      evmAddresses.add(address.toLowerCase());
      await prefs.setStringList('evmAddresses', evmAddresses);
    }
  }

  Future<void> removeWalletForUserId({
    required String userId,
    required String address,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    // Update userIdToAddresses
    String? savedData = prefs.getString('userIdToAddresses');
    Map<String, dynamic> userIdToAddresses = {};
    if (savedData != null) {
      final decodedMap = Map<String, dynamic>.from(jsonDecode(savedData));
      userIdToAddresses = decodedMap.map((userId, encodedAddresses) {
        final addresses = List<String>.from(jsonDecode(encodedAddresses));
        return MapEntry(userId, addresses);
      });
    }
    List<String> addresses = userIdToAddresses[userId]?.cast<String>() ?? [];
    addresses.remove(address.toLowerCase());
    if (addresses.isEmpty) {
      userIdToAddresses.remove(userId);
    } else {
      userIdToAddresses[userId] = addresses;
    }
    final userIdToAddressesJson = userIdToAddresses.map((userId, addresses) {
      return MapEntry(userId, jsonEncode(addresses));
    });
    await prefs.setString('userIdToAddresses', jsonEncode(userIdToAddressesJson));
    // Update evmAddresses
    List<String> evmAddresses = prefs.getStringList('evmAddresses') ?? [];
    evmAddresses.remove(address.toLowerCase());
    await prefs.setStringList('evmAddresses', evmAddresses);
  }

  /// Charge la préférence de réactivité APY depuis SharedPreferences
  Future<void> _loadApyReactivityPreference() async {
    final startTime = DateTime.now();
    debugPrint("$_logTask Chargement de la préférence de réactivité APY...");

    try {
      final prefs = await SharedPreferences.getInstance();
      double reactivity = prefs.getDouble('apyReactivity') ?? 0.2;

      // Appliquer la valeur de réactivité aux paramètres de l'ApyManager
      adjustApyReactivity(reactivity);

      final duration = DateTime.now().difference(startTime);
      debugPrint("$_logSuccess Préférence de réactivité APY chargée: $reactivity (${duration.inMilliseconds}ms)");
    } catch (e) {
      debugPrint("$_logError Erreur lors du chargement de la préférence de réactivité APY: $e");
    }
  }

  bool isLoading = true;
  bool isLoadingSecondary = true;
  bool isLoadingMain = true;
  bool isLoadingTransactions = true;
  bool isUpdatingData = false; // Nouvelle variable pour suivre les mises à jour en cours

  // Variables globales pour la gestion des données
  Map<String, dynamic> tokenDataFetched = {};
  List<Map<String, dynamic>> portfolioCalculated = [];
  Map<String, String> contractAddressList = {};
  List<Map<String, dynamic>> yamWalletsTransactionsFetched = [];
  List<Map<String, dynamic>> yamMarketFetched = [];
  List<Map<String, dynamic>> rmmBalances = [];
  List<Map<String, dynamic>> transactionsHistory = [];
  List<Map<String, dynamic>> detailedRentData = [];

  // Structures de données pour les loyers
  Map<String, double> cumulativeRentsByToken = {}; // Pour tous les wallets combinés
  Map<String, Map<String, double>> cumulativeRentsByWallet = {}; // Par wallet puis par token
  Map<String, int> tokensWalletCount = {}; // Nombre de wallets possédant chaque token
  List<Map<String, dynamic>> rentHistory = [];

  // Nouvelle structure de données pour les statistiques détaillées des wallets
  List<Map<String, dynamic>> walletStats = [];

  List<String> evmAddresses = [];
  double totalWalletValue = 0;
  double roiGlobalValue = 0;
  double netGlobalApy = 0;
  double walletValue = 0;
  double rmmValue = 0;
  Map<String, double> perWalletRmmValues = {};
  double rwaHoldingsValue = 0;
  int rentedUnits = 0;
  int totalUnits = 0;
  double initialTotalValue = 0.0;
  double yamTotalValue = 0.0;
  double totalTokens = 0.0;
  double walletTokensSums = 0.0;
  double rmmTokensSums = 0.0;
  double averageAnnualYield = 0;
  double dailyRent = 0;
  double weeklyRent = 0;
  double monthlyRent = 0;
  double yearlyRent = 0;
  Map<String, List<String>> userIdToAddresses = {};
  double totalUsdcDepositBalance = 0;
  double totalUsdcBorrowBalance = 0;
  double totalXdaiDepositBalance = 0;
  double totalXdaiBorrowBalance = 0;
  double gnosisUsdcBalance = 0;
  double gnosisXdaiBalance = 0;
  double gnosisRegBalance = 0;
  double gnosisVaultRegBalance = 0;
  int totalRealtTokens = 0;
  double totalRealtInvestment = 0.0;
  double netRealtRentYear = 0.0;
  double realtInitialPrice = 0.0;
  double realtActualPrice = 0.0;
  int totalRealtUnits = 0;
  int rentedRealtUnits = 0;
  double averageRealtAnnualYield = 0.0;
  double usdcDepositApy = 0.0;
  double usdcBorrowApy = 0.0;
  double xdaiDepositApy = 0.0;
  double xdaiBorrowApy = 0.0;
  double apyAverage = 0.0;
  double healthFactor = 0.0;
  double ltv = 0.0;
  int walletTokenCount = 0;
  int rmmTokenCount = 0;
  int totalTokenCount = 0;
  int duplicateTokenCount = 0;
  List<Map<String, dynamic>> rentData = [];
  List<Map<String, dynamic>> propertyData = [];
  List<Map<String, dynamic>> perWalletBalances = [];

  List<Map<String, dynamic>> _allTokens = []; // Liste privée pour tous les tokens
  List<Map<String, dynamic>> get allTokens => _allTokens;
  List<Map<String, dynamic>> _portfolio = [];
  List<Map<String, dynamic>> get portfolio => _portfolio;

  // متد جدید برای دریافت پورتفولیوی ترکیبی شامل خریدهای محلی
  Future<List<Map<String, dynamic>>> getCombinedPortfolio() async {
    final List<Map<String, dynamic>> combinedPortfolio = List.from(_portfolio);

    try {
      final localPurchases = await LocalPortfolioService.getPortfolio();

      for (final purchase in localPurchases) {
        // تبدیل خرید محلی به فرمت پورتفولیو
        final portfolioItem = {
          'uuid': purchase['propertyId'],
          'propertyId': purchase['propertyId'], // اضافه کردن propertyId برای استفاده در sell
          'shortName': purchase['shortName'],
          'title': purchase['title'],
          'amount': purchase['tokenAmount'],
          'tokenPrice': purchase['tokenPrice'],
          'value': purchase['totalValue'],
          'totalValue': purchase['totalValue'], // اضافه کردن totalValue
          'imageLink': purchase['imageUrl'] != null && purchase['imageUrl'].isNotEmpty
              ? [purchase['imageUrl']]
              : ['assets/logo.png'], // fallback image
          'fullName': purchase['title'], // اضافه کردن fullName برای فیلترها
          'country': purchase['country'] ?? 'Unknown',
          'city': purchase['city'] ?? 'Unknown',
          'annualPercentageYield': purchase['annualYield'] ?? 0.0,
          'isLocalPurchase': true, // برچسب برای تشخیص خریدهای محلی
          'purchaseDate': purchase['purchaseDate'],
          'lastPurchaseDate': purchase['lastPurchaseDate'],
          // اضافه کردن فیلدهای پیش‌فرض برای سازگاری
          'dailyIncome': 0.0,
          'monthlyIncome': 0.0,
          'yearlyIncome': 0.0,
          'rentedUnits': 0,
          'totalUnits': 1,
          'rentStartDate': purchase['purchaseDate'],
          'source': 'local',
          'inWallet': false,
          'inRMM': false,
          'initialTotalValue': purchase['totalValue'] ?? 0.0, // اضافه کردن این فیلد
          'totalRentReceived': 0.0, // اضافه کردن این فیلد
        };

        combinedPortfolio.add(portfolioItem);
      }
    } catch (e) {
      print('Error loading local portfolio: $e');
    }

    return combinedPortfolio;
  }

  List<Map<String, dynamic>> _recentUpdates = [];
  List<Map<String, dynamic>> get recentUpdates => _recentUpdates;
  List<Map<String, dynamic>> walletTokens = [];
  List<Map<String, dynamic>> realTokens = [];
  List<Map<String, dynamic>> tempRentData = [];
  List<BalanceRecord> balanceHistory = [];
  List<BalanceRecord> walletBalanceHistory = [];
  List<ROIRecord> roiHistory = [];
  List<APYRecord> apyHistory = [];
  List<HealthAndLtvRecord> healthAndLtvHistory = [];
  List<RentedRecord> rentedHistory = [];
  Map<String, double> customInitPrices = {};
  List<Map<String, dynamic>> propertiesForSale = [];
  List<Map<String, dynamic>> propertiesForSaleFetched = [];
  List<Map<String, dynamic>> yamMarketData = [];
  List<Map<String, dynamic>> yamMarket = [];
  List<Map<String, dynamic>> yamHistory = [];
  Map<String, List<Map<String, dynamic>>> transactionsByToken = {};
  List<Map<String, dynamic>> whitelistTokens = [];
  List<Map<String, dynamic>> tokenHistoryData = []; // Historique des modifications des tokens

  var customInitPricesBox = Hive.box('CustomInitPrices');

  DateTime? lastArchiveTime; // Variable pour stocker le dernier archivage
  DateTime? _lastUpdated; // Stocker la dernière mise à jour
  final Duration _updateCooldown = Duration(minutes: 5); // Délai minimal avant la prochaine mise à jour

  // Remplacer les propriétés APY du DataManager par une instance de ApyManager

  // Supprimer les propriétés suivantes du DataManager car elles sont maintenant dans ApyManager :
  // depositApyUsdc, depositApyXdai, borrowApyUsdc, borrowApyXdai, initialInvestment

  // ... existing code ...

  Future<void> loadWalletsAddresses({bool forceFetch = false}) async {
    final startTime = DateTime.now();
    debugPrint("$_logTask Chargement des adresses de wallets...");

    final prefs = await SharedPreferences.getInstance();
    // Charger les adresses
    evmAddresses = prefs.getStringList('evmAddresses') ?? [];

    final duration = DateTime.now().difference(startTime);
    debugPrint("$_logSuccess ${evmAddresses.length} adresses de wallets chargées (${duration.inMilliseconds}ms)");
  }

  Future<void> updateMainInformations({bool forceFetch = false}) async {
    // Vérifier si déjà en cours d'exécution
    if (_isUpdatingMainInformations) {
      debugPrint("$_logWarning updateMainInformations déjà en cours d'exécution, requête ignorée");
      return;
    }

    // Vérifier si des adresses de wallet sont disponibles
    if (evmAddresses.isEmpty) {
      debugPrint("$_logWarning updateMainInformations : aucune adresse de wallet disponible");
      return;
    }

    // Marquer comme en cours d'exécution et activer les shimmers
    _isUpdatingMainInformations = true;
    isUpdatingData = true; // Active les shimmers dans l'UI
    notifyListeners(); // Notifier les observateurs pour afficher les shimmers

    final startTime = DateTime.now();
    var box = Hive.box('realTokens'); // Ouvrir la boîte Hive pour le cache

    debugPrint("$_logMain Début de la mise à jour des informations principales...");

    // Vérifier si une mise à jour est nécessaire
    if (!forceFetch && _lastUpdated != null && DateTime.now().difference(_lastUpdated!) < _updateCooldown) {
      debugPrint("$_logWarning Mise à jour ignorée: déjà effectuée récemment");
      _isUpdatingMainInformations = false; // Réinitialiser le flag
      isUpdatingData = false; // Désactiver les shimmers
      notifyListeners(); // Notifier les observateurs
      return;
    }

    _lastUpdated = DateTime.now();

    try {
      // Fonction générique pour fetch + cache
      Future<void> fetchData({
        required Future<List<dynamic>> Function() apiCall,
        required String cacheKey,
        required void Function(List<Map<String, dynamic>>) updateVariable,
        required String debugName,
      }) async {
        final fetchStartTime = DateTime.now();
        try {
          debugPrint("$_logSub Récupération des données $debugName...");
          var data = await apiCall();
          if (data.isNotEmpty) {
            final fetchDuration = DateTime.now().difference(fetchStartTime);
            debugPrint("$_logSuccess Données $debugName mises à jour (${fetchDuration.inMilliseconds}ms)");
            box.put(cacheKey, json.encode(data));
            updateVariable(List<Map<String, dynamic>>.from(data));
          } else {
            debugPrint("$_logWarning Pas de nouvelles données $debugName, chargement du cache");
            var cachedData = box.get(cacheKey);
            if (cachedData != null) {
              updateVariable(List<Map<String, dynamic>>.from(json.decode(cachedData)));
            }
          }
          notifyListeners();
        } catch (e) {
          debugPrint("$_logError Erreur lors de la mise à jour $debugName: $e");
        }
      }

      // Exécution des mises à jour en parallèle
      await Future.wait([
        // fetchData(
        //     apiCall: () => ApiService.fetchWalletTokens(forceFetch: forceFetch),
        //     cacheKey: 'cachedTokenData_tokens',
        //     updateVariable: (data) => walletTokens = data,
        //     debugName: "Tokens"),

        fetchData(
            apiCall: () => ApiService.fetchRealTokens(forceFetch: forceFetch),
            cacheKey: 'cachedRealTokens',
            updateVariable: (data) => realTokens = data,
            debugName: "RealTokens"),
        // fetchData(
        //     apiCall: () => ApiService.fetchRmmBalances(forceFetch: forceFetch),
        //     cacheKey: 'rmmBalances',
        //     updateVariable: (data) {
        //       rmmBalances = data;
        //       fetchRmmBalances();
        //     },
        //     debugName: "RMM Balances"),
        // fetchData(
        //     apiCall: () => ApiService.fetchRentData(forceFetch: forceFetch),
        //     cacheKey: 'tempRentData',
        //     updateVariable: (data) => tempRentData = data,
        //     debugName: "Loyer temporaire"),
        fetchData(
            apiCall: () => ApiService.fetchPropertiesForSale(),
            cacheKey: 'cachedPropertiesForSaleData',
            updateVariable: (data) => propertiesForSaleFetched = data,
            debugName: "Propriétés en vente"),
        // Ajout de l'appel pour récupérer les tokens whitelistés pour chaque wallet
        fetchData(
            apiCall: () => ApiService.fetchWhitelistTokens(forceFetch: forceFetch),
            cacheKey: 'cachedWhitelistTokens',
            updateVariable: (data) => whitelistTokens = data,
            debugName: "Whitelist"),
        // Ajout de l'appel pour récupérer l'historique des tokens
        // fetchData(
        //     apiCall: () => ApiService.fetchTokenHistory(forceFetch: forceFetch),
        //     cacheKey: 'cachedTokenHistoryData',
        //     updateVariable: (data) => tokenHistoryData = data,
        //     debugName: "Token History")
      ]);

      // Charger les historiques
      debugPrint("$_logSub Chargement des historiques...");
      final histStartTime = DateTime.now();

      loadWalletBalanceHistory();
      loadRentedHistory();
      loadRoiHistory();
      loadApyHistory();
      loadHealthAndLtvHistory();

      final histDuration = DateTime.now().difference(histStartTime);
      debugPrint("$_logSuccess Historiques chargés (${histDuration.inMilliseconds}ms)");

      isLoadingMain = false;

      final totalDuration = DateTime.now().difference(startTime);
      debugPrint("$_logMain Mise à jour principale terminée (${totalDuration.inMilliseconds}ms)");
    } catch (e) {
      debugPrint("$_logError Erreur globale dans updateMainInformations: $e");
    } finally {
      _isUpdatingMainInformations = false; // Réinitialiser le flag
      isUpdatingData = false; // Désactiver les shimmers
      notifyListeners(); // Notifier les observateurs que la mise à jour est terminée
    }
  }

  Future<void> updateSecondaryInformations(BuildContext context, {bool forceFetch = false}) async {
    // Vérifier si déjà en cours d'exécution
    if (_isUpdatingSecondaryInformations) {
      debugPrint("$_logWarning updateSecondaryInformations déjà en cours d'exécution, requête ignorée");
      return;
    }

    // Vérifier si des adresses de wallet sont disponibles
    if (evmAddresses.isEmpty) {
      debugPrint("$_logWarning updateSecondaryInformations : aucune adresse de wallet disponible");
      return;
    }

    // Marquer comme en cours d'exécution
    _isUpdatingSecondaryInformations = true;

    final startTime = DateTime.now();
    var box = Hive.box('realTokens'); // Ouvrir la boîte Hive pour le cache

    debugPrint("$_logMain Début de la mise à jour des informations secondaires...");

    try {
      // Fonction générique pour fetch + cache
      Future<void> fetchData({
        required Future<List<dynamic>> Function() apiCall,
        required String cacheKey,
        required void Function(List<Map<String, dynamic>>) updateVariable,
        required String debugName,
      }) async {
        final fetchStartTime = DateTime.now();
        try {
          debugPrint("$_logSub Récupération des données $debugName...");
          var data = await apiCall();
          if (data.isNotEmpty) {
            final fetchDuration = DateTime.now().difference(fetchStartTime);
            debugPrint("$_logSuccess Données $debugName mises à jour (${fetchDuration.inMilliseconds}ms)");
            box.put(cacheKey, json.encode(data));
            updateVariable(List<Map<String, dynamic>>.from(data));
          } else {
            debugPrint("$_logWarning Pas de nouvelles données $debugName, chargement du cache");
            var cachedData = box.get(cacheKey);
            if (cachedData != null) {
              updateVariable(List<Map<String, dynamic>>.from(json.decode(cachedData)));
            }
          }
          notifyListeners();
        } catch (e) {
          debugPrint("$_logError Erreur lors de la mise à jour $debugName: $e");
        }
      }

      // Exécution des mises à jour en parallèle
      await Future.wait([
        // fetchData(
        //     apiCall: () => ApiService.fetchYamWalletsTransactions(forceFetch: forceFetch),
        //     cacheKey: 'cachedWalletsTransactions',
        //     updateVariable: (data) => yamWalletsTransactionsFetched = data,
        //     debugName: "YAM Wallets Transactions"),
        fetchData(
            apiCall: () => ApiService.fetchYamMarket(forceFetch: forceFetch),
            cacheKey: 'cachedYamMarket',
            updateVariable: (data) => yamMarketFetched = data,
            debugName: "YAM Market"),
        // fetchData(
        //     apiCall: () => ApiService.fetchTokenVolumes(forceFetch: forceFetch),
        //     cacheKey: 'yamHistory',
        //     updateVariable: (data) {
        //       rmmBalances = data;
        //       fetchYamHistory();
        //     },
        //     debugName: "YAM Volumes History"),
        // fetchData(
        //     apiCall: () => ApiService.fetchTransactionsHistory(forceFetch: forceFetch),
        //     cacheKey: 'transactionsHistory',
        //     updateVariable: (data) async {
        //       transactionsHistory = data;
        //       await processTransactionsHistory(context, transactionsHistory, yamWalletsTransactionsFetched);
        //     },
        //     debugName: "Transactions History"),
        // fetchData(
        //     apiCall: () => ApiService.fetchDetailedRentDataForAllWallets(forceFetch: forceFetch),
        //     cacheKey: 'detailedRentData',
        //     updateVariable: (data) {
        //       detailedRentData = data;
        //       // Traiter les données détaillées de loyer immédiatement après les avoir récupérées
        //       processDetailedRentData();
        //     },
        //     debugName: "Detailed rents"),
      ]);

      isLoadingSecondary = false;

      final totalDuration = DateTime.now().difference(startTime);
      debugPrint("$_logMain Mise à jour secondaire terminée (${totalDuration.inMilliseconds}ms)");
    } catch (e) {
      debugPrint("$_logError Erreur globale dans updateSecondaryInformations: $e");
    } finally {
      _isUpdatingSecondaryInformations = false; // Réinitialiser le flag quoi qu'il arrive
    }
  }

  // Nouvelle méthode pour traiter les données détaillées de loyer
  void processDetailedRentData() {
    final startTime = DateTime.now();
    debugPrint("$_logSub Traitement des données détaillées de loyer...");

    // Réinitialiser les structures de données
    cumulativeRentsByToken = {};
    cumulativeRentsByWallet = {};
    tokensWalletCount = {};
    rentHistory = [];

    // Si aucune donnée détaillée, sortir
    if (detailedRentData.isEmpty) {
      debugPrint("$_logWarning Aucune donnée détaillée de loyer disponible");
      return;
    }

    try {
      // Parcourir chaque entrée de date
      for (var dateEntry in detailedRentData) {
        // Vérifier les champs obligatoires date et rents
        if (!dateEntry.containsKey('date') || !dateEntry.containsKey('rents')) {
          debugPrint("$_logWarning Format de données incorrect pour une entrée");
          continue;
        }

        String date = dateEntry['date'];
        List<dynamic> rents = dateEntry['rents'];

        // Récupérer le wallet s'il existe, sinon utiliser "unknown"
        String wallet = "unknown";
        if (dateEntry.containsKey('wallet') && dateEntry['wallet'] != null) {
          wallet = dateEntry['wallet'].toLowerCase();
        }

        // Initialiser le map pour ce wallet s'il n'existe pas
        if (!cumulativeRentsByWallet.containsKey(wallet)) {
          cumulativeRentsByWallet[wallet] = {};
        }

        // Ajouter l'entrée à l'historique
        rentHistory.add({'date': date, 'wallet': wallet, 'rents': List<Map<String, dynamic>>.from(rents)});

        // Parcourir chaque loyer pour cette date
        for (var rentEntry in rents) {
          String token = rentEntry['token'].toLowerCase();
          double rent = (rentEntry['rent'] is num)
              ? (rentEntry['rent'] as num).toDouble()
              : double.tryParse(rentEntry['rent'].toString()) ?? 0.0;

          // Additionner au total cumulé pour ce token (tous wallets confondus)
          cumulativeRentsByToken[token] = (cumulativeRentsByToken[token] ?? 0.0) + rent;

          // Additionner au total cumulé pour ce token dans ce wallet
          cumulativeRentsByWallet[wallet]![token] = (cumulativeRentsByWallet[wallet]![token] ?? 0.0) + rent;

          // Compter les wallets uniques pour chaque token
          Set<String> walletsForToken = {};
          for (var walletKey in cumulativeRentsByWallet.keys) {
            if (cumulativeRentsByWallet[walletKey]!.containsKey(token) &&
                cumulativeRentsByWallet[walletKey]![token]! > 0) {
              walletsForToken.add(walletKey);
            }
          }
          tokensWalletCount[token] = walletsForToken.length;
        }
      }

      final duration = DateTime.now().difference(startTime);
      debugPrint(
          "$_logSuccess Traitement terminé: ${cumulativeRentsByToken.length} tokens, ${cumulativeRentsByWallet.length} wallets, ${rentHistory.length} entrées (${duration.inMilliseconds}ms)");
    } catch (e) {
      debugPrint("$_logError Erreur lors du traitement des données détaillées de loyer: $e");
    }
  }

  // Méthode existante modifiée pour utiliser les données précalculées
  double getRentDetailsForToken(String token) {
    // Utiliser directement la valeur précalculée si disponible
    if (cumulativeRentsByToken.containsKey(token.toLowerCase())) {
      return cumulativeRentsByToken[token.toLowerCase()]!;
    }

    // Si la valeur n'est pas précalculée (fallback), on calcule à la demande
    debugPrint(
        "$_logWarning Calcul des loyers à la demande pour le token: $token (non trouvé dans les données précalculées)");
    double totalRent = 0.0;

    // Parcourir chaque entrée de la liste detailedRentData
    for (var entry in detailedRentData) {
      if (entry.containsKey('rents') && entry['rents'] is List) {
        List rents = entry['rents'];

        for (var rentEntry in rents) {
          if (rentEntry['token'] != null && rentEntry['token'].toLowerCase() == token.toLowerCase()) {
            double rentAmount = (rentEntry['rent'] ?? 0.0).toDouble();
            totalRent += rentAmount;
          }
        }
      }
    }

    return totalRent;
  }

  /// Méthode optimisée pour charger le cache en premier puis mettre à jour en arrière-plan
  Future<void> loadFromCacheThenUpdate(BuildContext context) async {
    // Vérifier si déjà en cours d'exécution
    if (_isLoadingFromCache) {
      debugPrint("$_logWarning loadFromCacheThenUpdate déjà en cours d'exécution, requête ignorée");
      return;
    }

    // Marquer comme en cours d'exécution
    _isLoadingFromCache = true;

    final startTime = DateTime.now();
    debugPrint("$_logMain Chargement optimisé cache-first...");

    try {
      var box = Hive.box('realTokens');

      // Charger les adresses de wallet
      await loadWalletsAddresses();

      if (evmAddresses.isEmpty) {
        debugPrint("$_logWarning Aucune adresse de wallet disponible");
        _isLoadingFromCache = false;
        return;
      }

      // Fonction générique de chargement depuis le cache avec gestion d'erreur
      Future<void> loadFromCacheWithFallback({
        required String cacheKey,
        required void Function(List<Map<String, dynamic>>) updateVariable,
        required String debugName,
        String? alternativeCacheKey,
      }) async {
        try {
          // Essayer avec la clé principale
          var cachedData = box.get(cacheKey);

          // Si pas de données, essayer avec la clé alternative
          if (cachedData == null && alternativeCacheKey != null) {
            cachedData = box.get(alternativeCacheKey);
          }

          if (cachedData != null) {
            try {
              final decodedData = List<Map<String, dynamic>>.from(json.decode(cachedData));
              updateVariable(decodedData);
              debugPrint("$_logSuccess Cache $debugName chargé: ${decodedData.length} éléments");
            } catch (e) {
              debugPrint("$_logError Erreur décodage cache $debugName: $e");
            }
          } else {
            debugPrint("$_logWarning Pas de cache disponible pour $debugName");
          }
        } catch (e) {
          debugPrint("$_logError Erreur chargement cache $debugName: $e");
        }
      }

      // 1. Chargement prioritaire en parallèle des données principales
      debugPrint("$_logSub Chargement prioritaire du cache principal...");
      await Future.wait([
        loadFromCacheWithFallback(
            cacheKey: 'cachedData_wallet_tokens',
            alternativeCacheKey: 'cachedTokenData_tokens',
            updateVariable: (data) => walletTokens = data,
            debugName: "Tokens"),
        loadFromCacheWithFallback(
            cacheKey: 'cachedRealTokens', updateVariable: (data) => realTokens = data, debugName: "RealTokens"),
        loadFromCacheWithFallback(
            cacheKey: 'rmmBalances',
            updateVariable: (data) {
              rmmBalances = data;
              if (data.isNotEmpty) fetchRmmBalances();
            },
            debugName: "RMM Balances"),
      ]);

      // Calculer les données essentielles immédiatement après le chargement du cache principal
      if (realTokens.isNotEmpty && walletTokens.isNotEmpty) {
        await fetchAndCalculateData();
        await fetchAndStoreAllTokens();
        fetchPropertyData();
      }

      // 2. Chargement en parallèle des données secondaires
      debugPrint("$_logSub Chargement du cache secondaire...");
      await Future.wait([
        loadFromCacheWithFallback(
            cacheKey: 'cachedRentData', updateVariable: (data) => rentData = data, debugName: "Données de loyer"),
        loadFromCacheWithFallback(
            cacheKey: 'cachedData_tempRentData',
            alternativeCacheKey: 'tempRentData',
            updateVariable: (data) => tempRentData = data,
            debugName: "Loyer temporaire"),
        loadFromCacheWithFallback(
            cacheKey: 'cachedData_cachedPropertiesForSaleData',
            alternativeCacheKey: 'cachedPropertiesForSaleData',
            updateVariable: (data) => propertiesForSaleFetched = data,
            debugName: "Propriétés en vente"),
        loadFromCacheWithFallback(
            cacheKey: 'cachedData_cachedWhitelistTokens',
            alternativeCacheKey: 'cachedWhitelistTokens',
            updateVariable: (data) => whitelistTokens = data,
            debugName: "Whitelist"),
        loadFromCacheWithFallback(
            cacheKey: 'cachedData_cachedTokenHistoryData',
            alternativeCacheKey: 'cachedTokenHistoryData',
            updateVariable: (data) {
              tokenHistoryData = data;
              if (data.isNotEmpty) processTokenHistory();
            },
            debugName: "Token History"),
        loadFromCacheWithFallback(
            cacheKey: 'cachedData_cachedWalletsTransactions',
            alternativeCacheKey: 'cachedWalletsTransactions',
            updateVariable: (data) => yamWalletsTransactionsFetched = data,
            debugName: "YAM Wallets Transactions"),
        loadFromCacheWithFallback(
            cacheKey: 'cachedData_cachedYamMarket',
            alternativeCacheKey: 'cachedYamMarket',
            updateVariable: (data) => yamMarketFetched = data,
            debugName: "YAM Market"),
        loadFromCacheWithFallback(
            cacheKey: 'cachedData_yamHistory',
            alternativeCacheKey: 'yamHistory',
            updateVariable: (data) {
              yamHistory = data;
              if (data.isNotEmpty) fetchYamHistory();
            },
            debugName: "YAM Volumes History"),
        loadFromCacheWithFallback(
            cacheKey: 'cachedData_transactionsHistory',
            alternativeCacheKey: 'transactionsHistory',
            updateVariable: (data) async {
              transactionsHistory = data;
              if (data.isNotEmpty && yamWalletsTransactionsFetched.isNotEmpty) {
                await processTransactionsHistory(context, transactionsHistory, yamWalletsTransactionsFetched);
              }
            },
            debugName: "Transactions History"),
        loadFromCacheWithFallback(
            cacheKey: 'cachedData_detailedRentData',
            alternativeCacheKey: 'detailedRentData',
            updateVariable: (data) {
              detailedRentData = data;
              if (data.isNotEmpty) processDetailedRentData();
            },
            debugName: "Detailed rents")
      ]);

      // 3. Charger les historiques persistants
      debugPrint("$_logSub Chargement des historiques...");
      await Future.wait([
        loadWalletBalanceHistory(),
        loadRentedHistory(),
        loadRoiHistory(),
        loadApyHistory(),
        loadHealthAndLtvHistory(),
      ]);

      // Traitement final des données secondaires
      if (propertiesForSaleFetched.isNotEmpty) {
        await fetchAndStorePropertiesForSale();
      }
      if (yamMarketFetched.isNotEmpty) {
        await fetchAndStoreYamMarketData();
      }

      // Marquer le chargement initial comme terminé
      isLoadingMain = false;
      isLoadingSecondary = false;
      isLoading = false;
      isLoadingTransactions = false;

      final cacheDuration = DateTime.now().difference(startTime);
      debugPrint("$_logMain Cache chargé et données calculées (${cacheDuration.inMilliseconds}ms)");

      // Notifier que les données du cache sont prêtes
      notifyListeners();

      // 4. Lancer les mises à jour API en arrière-plan (sans bloquer l'UI)
      debugPrint("$_logMain Démarrage des mises à jour en arrière-plan...");
      _startBackgroundUpdate(context);
    } catch (e) {
      debugPrint("$_logError Erreur globale dans loadFromCacheThenUpdate: $e");
      // En cas d'erreur, s'assurer que l'UI n'est pas bloquée
      isLoadingMain = false;
      isLoadingSecondary = false;
      isLoading = false;
      notifyListeners();
    } finally {
      _isLoadingFromCache = false;
    }
  }

  /// Lance les mises à jour API en arrière-plan sans bloquer l'UI
  void _startBackgroundUpdate(BuildContext context) {
    Future.microtask(() async {
      try {
        // Activer les indicateurs de mise à jour en arrière-plan
        isUpdatingData = true;
        notifyListeners();

        // Lancer les mises à jour en parallèle
        await Future.wait([
          updateMainInformations(forceFetch: false),
          updateSecondaryInformations(context, forceFetch: false),
        ]);

        // Recalculer les données avec les nouvelles informations
        if (realTokens.isNotEmpty && walletTokens.isNotEmpty) {
          await fetchAndCalculateData();
          await fetchAndStoreAllTokens();
          await fetchAndStorePropertiesForSale();
          await fetchAndStoreYamMarketData();
          // Traiter l'historique des tokens si disponible
          if (tokenHistoryData.isNotEmpty) {
            processTokenHistory();
          }
        }

        debugPrint("$_logSuccess Mise à jour en arrière-plan terminée");
      } catch (e) {
        debugPrint("$_logError Erreur lors de la mise à jour en arrière-plan: $e");
      } finally {
        // Désactiver les indicateurs de mise à jour
        isUpdatingData = false;
        notifyListeners();
      }
    });
  }

  /// Méthode centralisée pour mettre à jour toutes les données
  /// Cette méthode coordonne toutes les mises à jour et évite la duplication de code
  Future<void> updateAllData(BuildContext context, {bool forceFetch = false}) async {
    if (evmAddresses.isEmpty) {
      debugPrint("$_logWarning updateAllData : aucune adresse de wallet disponible");
      return;
    }

    // Mettre à jour les informations principales et secondaires
    await updateMainInformations(forceFetch: forceFetch);
    await updateSecondaryInformations(context, forceFetch: forceFetch);

    // Mettre à jour les autres données
    await fetchRentData(forceFetch: forceFetch);
    await fetchAndCalculateData(forceFetch: forceFetch);
    fetchPropertyData();
    await fetchAndStoreAllTokens();
    await fetchAndStoreYamMarketData();
    await fetchAndStorePropertiesForSale();
  }

  /// Méthode pour forcer une mise à jour complète (rafraîchissement)
  Future<void> forceRefreshAllData(BuildContext context) async {
    debugPrint("$_logMain Forçage de la mise à jour de toutes les données...");
    // Vérifier si des adresses de wallet sont disponibles

    // Charger les adresses de wallet
    await loadWalletsAddresses();

    if (evmAddresses.isEmpty) {
      debugPrint("$_logWarning updateMainInformations : aucune adresse de wallet disponible");
      return;
    }

    await updateAllData(context, forceFetch: true);
    debugPrint("$_logSuccess Mise à jour forcée terminée");
  }

  /// Charge l'historique des balances de portefeuille depuis Hive
  Future<void> loadWalletBalanceHistory() async {
    final startTime = DateTime.now();
    debugPrint("$_logTask Chargement de l'historique des balances...");

    try {
      var box = Hive.box('balanceHistory');
      List<dynamic>? balanceHistoryJson = box.get('balanceHistory_totalWalletValue');

      // Convertir chaque élément JSON en objet BalanceRecord et l'ajouter à walletBalanceHistory
      walletBalanceHistory = balanceHistoryJson != null
          ? balanceHistoryJson
              .map((recordJson) => BalanceRecord.fromJson(Map<String, dynamic>.from(recordJson)))
              .toList()
          : [];

      // Si l'historique est vide, on ajoute des données mock limitées
      if (walletBalanceHistory.isEmpty) {
        _generateMockWalletData();
        saveWalletBalanceHistory();
      }

      // Assigner à balanceHistory (utilisée pour les calculs d'APY) aussi
      balanceHistory = List.from(walletBalanceHistory);

      // Calculer l'APY après chargement de l'historique si nous avons suffisamment de données
      if (balanceHistory.length >= 2) {
        try {
          // Calcul de l'APY déplacé vers calculateApyValues
          // Nous ne calculons pas l'APY ici, mais attendons que toutes les données soient chargées
          debugPrint(
              "$_logTask Historique de balance chargé, APY sera calculé quand toutes les données seront disponibles");
        } catch (e) {
          debugPrint("$_logError Erreur lors du traitement initial de l'historique: $e");
        }
      } else {
        debugPrint(
            "$_logWarning Historique insuffisant pour calculer l'APY: ${balanceHistory.length} enregistrement(s)");
      }

      final duration = DateTime.now().difference(startTime);
      debugPrint(
          "$_logSuccess Historique de balance chargé: ${walletBalanceHistory.length} entrées (${duration.inMilliseconds}ms)");
    } catch (e) {
      debugPrint("$_logError Erreur lors du chargement de l'historique de balance: $e");
    }
  }

  /// Generate limited mock wallet balance data for demonstration
  void _generateMockWalletData() {
    final now = DateTime.now();
    final baseValue = 50000.0; // Base wallet value in USD

    // Generate 30 days of mock data with some variation
    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));

      // Add some realistic variation (±5% from base)
      final variation = (i % 7) * 0.01 - 0.02; // Weekly pattern
      final randomVariation = (i.hashCode % 200 - 100) * 0.0001; // Small random variation
      final balance = baseValue * (1 + variation + randomVariation);

      walletBalanceHistory.add(BalanceRecord(balance: balance, timestamp: date, tokenType: 'totalWalletValue'));
    }

    // Add some mock portfolio data points
    final portfolioBase = 45000.0;
    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final variation = (i % 5) * 0.008 - 0.015;
      final balance = portfolioBase * (1 + variation);

      walletBalanceHistory.add(BalanceRecord(balance: balance, timestamp: date, tokenType: 'portfolioValue'));
    }

    debugPrint("$_logSuccess Generated ${walletBalanceHistory.length} mock wallet balance records");
  }

  /// Generate limited mock portfolio data for demonstration
  void _generateMockPortfolioData() {
    final now = DateTime.now();

    // Add 3-4 mock properties with realistic data
    _portfolio = [
      {
        'uuid': '0x18f5dce3bbf97fb2896e2c47d7b3da3de68b48a5',
        'shortName': 'S-Dexter-24',
        'fullName': '24 Dexter Street, Detroit, MI',
        'tokenPrice': 52.85,
        'amount': 15.0,
        'totalValue': 792.75,
        'initialTotalValue': 750.0,
        'country': 'USA',
        'city': 'Detroit',
        'state': 'MI',
        'annualPercentageYield': 0.098,
        'totalRentReceived': 89.25,
        'propertyType': 'single-family',
        'dailyIncome': 0.21,
        'monthlyIncome': 6.45,
        'yearlyIncome': 77.4,
        'rentedUnits': 1,
        'totalUnits': 1,
        'source': 'wallet',
        'imageLink': ['https://realt.co/wp-content/uploads/2021/04/24-Dexter-Street-Detroit-MI-48238.jpg'],
        'lastUpdate': now.millisecondsSinceEpoch,
      },
      {
        'uuid': '0x219b06037c382cf3b619fd609755b6d5f0e5bd71',
        'shortName': 'S-Riopelle-14319',
        'fullName': '14319 Riopelle Street, Detroit, MI',
        'tokenPrice': 63.12,
        'amount': 10.0,
        'totalValue': 631.20,
        'initialTotalValue': 620.0,
        'country': 'USA',
        'city': 'Detroit',
        'state': 'MI',
        'annualPercentageYield': 0.085,
        'totalRentReceived': 67.80,
        'propertyType': 'duplex',
        'dailyIncome': 0.18,
        'monthlyIncome': 5.37,
        'yearlyIncome': 64.4,
        'rentedUnits': 2,
        'totalUnits': 2,
        'source': 'wallet',
        'imageLink': ['https://realt.co/wp-content/uploads/2021/04/14319-Riopelle-Street-Detroit-MI-48212.jpg'],
        'lastUpdate': now.millisecondsSinceEpoch,
      },
      {
        'uuid': '0x3f463ee4962e5b6ca21b0d40fa8e7b6c19dda67c',
        'shortName': 'S-Warwick-10612',
        'fullName': '10612 Warwick Street, Detroit, MI',
        'tokenPrice': 45.75,
        'amount': 20.0,
        'totalValue': 915.0,
        'initialTotalValue': 900.0,
        'country': 'USA',
        'city': 'Detroit',
        'state': 'MI',
        'annualPercentageYield': 0.112,
        'totalRentReceived': 125.40,
        'propertyType': 'single-family',
        'dailyIncome': 0.28,
        'monthlyIncome': 8.55,
        'yearlyIncome': 102.6,
        'rentedUnits': 1,
        'totalUnits': 1,
        'source': 'wallet',
        'imageLink': ['https://realt.co/wp-content/uploads/2021/04/10612-Warwick-Street-Detroit-MI-48224.jpg'],
        'lastUpdate': now.millisecondsSinceEpoch,
      }
    ];

    // Update related values
    totalTokenCount = _portfolio.length;
    initialTotalValue = _portfolio.fold(0.0, (sum, item) => sum + (item['initialTotalValue'] as double));
    monthlyRent = _portfolio.fold(0.0, (sum, item) => sum + (item['monthlyIncome'] as double));
    yearlyRent = monthlyRent * 12;
    dailyRent = yearlyRent / 365;
    weeklyRent = yearlyRent / 52;

    // Add mock EVM address if needed
    if (evmAddresses.isEmpty) {
      evmAddresses = ['0xd7a6A4b95E29CE5f8f45404d1251178DAFE75AF3'];
    }

    // Generate mock rent history for last 30 days
    _generateMockRentData();

    debugPrint("$_logSuccess Generated ${_portfolio.length} mock portfolio items");
  }

  /// Generate mock rent history data
  void _generateMockRentData() {
    final now = DateTime.now();
    rentData = [];

    // Generate 30 days of rent payments with some variation
    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dailyAmount = dailyRent + (i % 3) * 0.1 - 0.05; // Small variation

      if (i % 7 == 0 && dailyAmount > 0) {
        // Weekly rent payments
        rentData.add({
          'date': date.toIso8601String().split('T')[0],
          'rent': dailyAmount * 7, // Weekly amount
          'currency': 'USD',
          'wallet': '0xd7a6A4b95E29CE5f8f45404d1251178DAFE75AF3',
          'token': _portfolio.isNotEmpty ? _portfolio[i % _portfolio.length]['uuid'] : 'mock-token'
        });
      }
    }

    debugPrint("$_logSuccess Generated ${rentData.length} mock rent records");
  }

  Future<void> loadRentedHistory() async {
    final startTime = DateTime.now();
    debugPrint("$_logTask Chargement de l'historique des locations...");

    try {
      var box = Hive.box('rentedArchive');
      List<dynamic>? rentedHistoryJson = box.get('rented_history');

      if (rentedHistoryJson == null) {
        debugPrint("$_logWarning Aucun historique de location trouvé");
        return;
      }

      rentedHistory = rentedHistoryJson.map((recordJson) {
        return RentedRecord.fromJson(Map<String, dynamic>.from(recordJson));
      }).toList();

      notifyListeners();

      final duration = DateTime.now().difference(startTime);
      debugPrint(
          "$_logSuccess Historique de location chargé: ${rentedHistory.length} entrées (${duration.inMilliseconds}ms)");
    } catch (e) {
      debugPrint("$_logError Erreur lors du chargement de l'historique de location: $e");
    }
  }

  Future<void> loadRoiHistory() async {
    final startTime = DateTime.now();
    debugPrint("$_logTask Chargement de l'historique ROI...");

    try {
      var box = Hive.box('roiValueArchive');
      List<dynamic>? roiHistoryJson = box.get('roi_history');

      // Vérifier si les données sont nulles
      if (roiHistoryJson == null) {
        debugPrint("$_logWarning Aucun historique ROI trouvé, initialisation avec liste vide");
        roiHistory = [];
        return;
      }

      // Convertir les données JSON en objets ROIRecord
      try {
        roiHistory = roiHistoryJson.map((recordJson) {
          return ROIRecord.fromJson(Map<String, dynamic>.from(recordJson));
        }).toList();
      } catch (e) {
        debugPrint("$_logError Erreur lors de la conversion des enregistrements ROI: $e");
        roiHistory = [];
      }

      notifyListeners();

      final duration = DateTime.now().difference(startTime);
      debugPrint("$_logSuccess Historique ROI chargé: ${roiHistory.length} entrées (${duration.inMilliseconds}ms)");
    } catch (e) {
      debugPrint("$_logError Erreur lors du chargement de l'historique ROI: $e");
      roiHistory = [];
    }
  }

  Future<void> loadApyHistory() async {
    final startTime = DateTime.now();
    debugPrint("$_logTask Chargement de l'historique APY...");

    try {
      // Utiliser la boîte correcte qui est ouverte dans main.dart
      var box = Hive.box('apyValueArchive');
      List<dynamic>? apyHistoryJson = box.get('apy_history');

      if (apyHistoryJson == null) {
        debugPrint("$_logWarning Aucun historique APY trouvé");
        return;
      }

      // Charger l'historique avec gestion d'erreur robuste
      apyHistory = [];
      for (var recordJson in apyHistoryJson) {
        try {
          // S'assurer que recordJson est bien un Map
          Map<String, dynamic> recordMap;
          if (recordJson is Map<String, dynamic>) {
            recordMap = recordJson;
          } else if (recordJson is Map) {
            recordMap = Map<String, dynamic>.from(recordJson);
          } else {
            debugPrint("$_logWarning Format de données APY invalide ignoré: $recordJson");
            continue;
          }

          // Gestion spéciale du timestamp
          if (recordMap.containsKey('timestamp')) {
            var timestampValue = recordMap['timestamp'];
            DateTime parsedTimestamp;

            try {
              if (timestampValue is int) {
                // Timestamp en millisecondes
                parsedTimestamp = DateTime.fromMillisecondsSinceEpoch(timestampValue);
              } else if (timestampValue is double) {
                // Timestamp en millisecondes (format double)
                parsedTimestamp = DateTime.fromMillisecondsSinceEpoch(timestampValue.toInt());
              } else if (timestampValue is String) {
                // Essayer de parser comme timestamp en millisecondes d'abord
                try {
                  int timestampMs = int.parse(timestampValue);
                  parsedTimestamp = DateTime.fromMillisecondsSinceEpoch(timestampMs);
                } catch (e) {
                  // Si ça échoue, essayer de parser comme date ISO
                  parsedTimestamp = DateTime.parse(timestampValue);
                }
              } else {
                debugPrint("$_logWarning Type de timestamp non supporté: ${timestampValue.runtimeType}");
                continue;
              }

              // Remplacer le timestamp dans recordMap avec le DateTime parsé
              recordMap['timestamp'] = parsedTimestamp.toIso8601String();
            } catch (e) {
              debugPrint("$_logWarning Erreur lors du parsing du timestamp: $timestampValue, erreur: $e");
              continue;
            }
          }

          // Validation et conversion sécurisée des types pour les valeurs APY
          if (recordMap.containsKey('apy') || recordMap.containsKey('netApy')) {
            // Convertir les valeurs String en double si nécessaire
            if (recordMap['apy'] is String) {
              recordMap['apy'] = double.tryParse(recordMap['apy']) ?? 0.0;
            }
            if (recordMap['netApy'] is String) {
              recordMap['netApy'] = double.tryParse(recordMap['netApy']) ?? 0.0;
            }
            if (recordMap['grossApy'] is String) {
              recordMap['grossApy'] = double.tryParse(recordMap['grossApy']) ?? 0.0;
            }

            apyHistory.add(APYRecord.fromJson(recordMap));
          } else {
            debugPrint("$_logWarning Données APY incomplètes ignorées: $recordMap");
          }
        } catch (e) {
          debugPrint("$_logWarning Erreur lors du traitement d'un enregistrement APY: $e");
          debugPrint("$_logWarning Données problématiques: $recordJson");
          continue;
        }
      }

      notifyListeners();

      final duration = DateTime.now().difference(startTime);
      debugPrint("$_logSuccess Historique APY chargé: ${apyHistory.length} entrées (${duration.inMilliseconds}ms)");
    } catch (e) {
      debugPrint("$_logError Erreur lors du chargement de l'historique APY: $e");
      // Initialiser avec une liste vide en cas d'erreur
      apyHistory = [];
    }
  }

  Future<void> loadHealthAndLtvHistory() async {
    final startTime = DateTime.now();
    debugPrint("$_logTask Chargement de l'historique Health & LTV...");

    try {
      var box = Hive.box('HealthAndLtvValueArchive');
      List<dynamic>? healthAndLtvHistoryJson = box.get('healthAndLtv_history');

      if (healthAndLtvHistoryJson == null) {
        debugPrint("$_logWarning Aucun historique Health & LTV trouvé");
        return;
      }

      // Charger l'historique
      healthAndLtvHistory = healthAndLtvHistoryJson.map((recordJson) {
        return HealthAndLtvRecord.fromJson(Map<String, dynamic>.from(recordJson));
      }).toList();

      notifyListeners();

      final duration = DateTime.now().difference(startTime);
      debugPrint(
          "$_logSuccess Historique Health & LTV chargé: ${healthAndLtvHistory.length} entrées (${duration.inMilliseconds}ms)");
    } catch (e) {
      debugPrint("$_logError Erreur lors du chargement de l'historique Health & LTV: $e");
    }
  }

  // Sauvegarde l'historique des balances dans Hive
  Future<void> saveWalletBalanceHistory() async {
    final startTime = DateTime.now();
    debugPrint("$_logTask Sauvegarde de l'historique des balances...");

    try {
      var box = Hive.box('walletValueArchive');

      // Convertir les données en format JSON
      List<Map<String, dynamic>> balanceHistoryJson = walletBalanceHistory.map((record) => record.toJson()).toList();

      // Sauvegarder dans Hive
      await box.put('balanceHistory_totalWalletValue', balanceHistoryJson);

      // S'assurer que les données dans balanceHistory sont aussi à jour
      balanceHistory = List.from(walletBalanceHistory);

      // Mise à jour également dans la boîte 'balanceHistory' pour assurer la cohérence
      var boxBalance = Hive.box('balanceHistory');
      await boxBalance.put('balanceHistory_totalWalletValue', balanceHistoryJson);

      final duration = DateTime.now().difference(startTime);
      debugPrint(
          "$_logSuccess Historique des balances sauvegardé: ${walletBalanceHistory.length} entrées (${duration.inMilliseconds}ms)");

      notifyListeners();
    } catch (e) {
      debugPrint("$_logError Erreur lors de la sauvegarde de l'historique: $e");
    }
  }

  Future<void> saveRentedHistory() async {
    final startTime = DateTime.now();
    debugPrint("$_logTask Sauvegarde de l'historique des locations...");

    try {
      var box = Hive.box('rentedArchive');
      List<Map<String, dynamic>> rentedHistoryJson = rentedHistory.map((record) => record.toJson()).toList();
      await box.put('rented_history', rentedHistoryJson);

      final duration = DateTime.now().difference(startTime);
      debugPrint("$_logSuccess Historique des locations sauvegardé (${duration.inMilliseconds}ms)");

      notifyListeners();
    } catch (e) {
      debugPrint("$_logError Erreur lors de la sauvegarde de l'historique des locations: $e");
    }
  }

  // Méthode pour ajouter des adresses à un userId
  void addAddressesForUserId(String userId, List<String> addresses) {
    final startTime = DateTime.now();
    debugPrint("$_logTask Ajout d'adresses pour userId: $userId...");

    try {
      if (userIdToAddresses.containsKey(userId)) {
        userIdToAddresses[userId]!.addAll(addresses);
      } else {
        userIdToAddresses[userId] = addresses;
      }
      saveUserIdToAddresses();

      final duration = DateTime.now().difference(startTime);
      debugPrint("$_logSuccess Adresses ajoutées pour userId: $userId (${duration.inMilliseconds}ms)");

      notifyListeners();
    } catch (e) {
      debugPrint("$_logError Erreur lors de l'ajout d'adresses pour userId: $e");
    }
  }

  // Sauvegarder la Map des userIds et adresses dans SharedPreferences
  Future<void> saveUserIdToAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final userIdToAddressesJson = userIdToAddresses.map((userId, addresses) {
      return MapEntry(userId, jsonEncode(addresses)); // Encoder les adresses en JSON
    });

    prefs.setString('userIdToAddresses', jsonEncode(userIdToAddressesJson));
  }

  // Charger les userIds et leurs adresses depuis SharedPreferences
  Future<void> loadUserIdToAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('userIdToAddresses');

    if (savedData != null) {
      final decodedMap = Map<String, dynamic>.from(jsonDecode(savedData));
      userIdToAddresses = decodedMap.map((userId, encodedAddresses) {
        final addresses = List<String>.from(jsonDecode(encodedAddresses));
        return MapEntry(userId, addresses);
      });
    }
    notifyListeners();
  }

  // Supprimer une adresse spécifique
  void removeAddressForUserId(String userId, String address) {
    if (userIdToAddresses.containsKey(userId)) {
      userIdToAddresses[userId]!.remove(address);
      if (userIdToAddresses[userId]!.isEmpty) {
        userIdToAddresses.remove(userId); // Supprimer le userId si plus d'adresses
      }
      saveUserIdToAddresses(); // Sauvegarder après suppression
      notifyListeners();
    }
  }

  // Supprimer un userId et toutes ses adresses
  void removeUserId(String userId) {
    userIdToAddresses.remove(userId);
    saveUserIdToAddresses(); // Sauvegarder après suppression
    notifyListeners();
  }

  // Méthode pour récupérer les adresses associées à un userId
  List<String>? getAddressesForUserId(String userId) {
    return userIdToAddresses[userId];
  }

  // Méthode pour obtenir tous les userIds
  List<String> getAllUserIds() {
    return userIdToAddresses.keys.toList();
  }

  Future<void> fetchAndStoreAllTokens() async {
    var box = Hive.box('realTokens');

    // Variables temporaires pour calculer les nouvelles valeurs
    int tempTotalTokens = 0;
    double tempTotalInvestment = 0.0;
    double tempNetRentYear = 0.0;
    double tempInitialPrice = 0.0;
    double tempActualPrice = 0.0;
    int tempTotalUnits = 0;
    int tempRentedUnits = 0;
    double tempAnnualYieldSum = 0.0;
    int yieldCount = 0;

    final cachedRealTokens = box.get('cachedRealTokens');
    if (cachedRealTokens != null) {
      realTokens = List<Map<String, dynamic>>.from(json.decode(cachedRealTokens));
      debugPrint("Données RealTokens en cache utilisées.");
    }
    List<Map<String, dynamic>> allTokensList = [];

    // Si des tokens existent, les ajouter à la liste des tokens
    if (realTokens.isNotEmpty) {
      _recentUpdates = _extractRecentUpdates(realTokens);
      for (var realToken in realTokens.cast<Map<String, dynamic>>()) {
        // Vérification: Ne pas ajouter si totalTokens est 0 ou si fullName commence par "OLD-"
        // Récupérer la valeur customisée de initPrice si elle existe
        final tokenContractAddress = realToken['uuid'].toLowerCase() ?? ''; // Utiliser l'adresse du contrat du token

        if (realToken['totalTokens'] != null &&
            realToken['totalTokens'] > 0 &&
            realToken['fullName'] != null &&
            !realToken['fullName'].startsWith('OLD-') &&
            realToken['uuid'].toLowerCase() != Parameters.rwaTokenAddress.toLowerCase()) {
          // 1. Calculer le prix initial depuis l'historique (la valeur la plus ancienne)
          double initPrice = 0.0;
          // Vérifier s'il y a un historique pour ce token
          List<Map<String, dynamic>> tokenHistory = getTokenHistory(tokenContractAddress);
          if (tokenHistory.isNotEmpty) {
            // Trier par date pour obtenir la plus ancienne entrée
            tokenHistory.sort((a, b) {
              String dateA = a['date'] ?? '';
              String dateB = b['date'] ?? '';
              return dateA.compareTo(dateB); // Tri croissant pour avoir la plus ancienne en premier
            });

            // Prendre le prix du token de la première entrée (la plus ancienne)
            var oldestEntry = tokenHistory.first;
            initPrice = (oldestEntry['token_price'] as num?)?.toDouble() ??
                (realToken['historic']?['init_price'] as num?)?.toDouble() ??
                0.0;
          } else {
            // Si pas d'historique, utiliser le prix initial des données historiques
            initPrice = (realToken['historic']?['init_price'] as num?)?.toDouble() ?? 0.0;
          }

          // 2. Calculer le prix d'achat moyen pondéré à partir des transactions (ou prix personnalisé)
          double? customInitPrice = customInitPrices[tokenContractAddress];
          double averagePurchasePrice = customInitPrice ?? initPrice; // Utiliser initPrice comme valeur par défaut

          String fullName = realToken['fullName'];
          String country = LocationUtils.extractCountry(fullName);
          String regionCode = LocationUtils.extractRegion(fullName);
          String city = LocationUtils.extractCity(fullName);

          // Récupérer les loyers cumulés pour ce token
          double totalRentReceived = cumulativeRentsByToken[tokenContractAddress] ?? 0.0;

          allTokensList.add({
            'uuid': tokenContractAddress,
            'shortName': realToken['shortName'],
            'fullName': realToken['fullName'],
            'country': country,
            'regionCode': regionCode,
            'city': city,
            'imageLink': realToken['imageLink'],
            'lat': realToken['coordinate']['lat'],
            'lng': realToken['coordinate']['lng'],
            'totalTokens': realToken['totalTokens'],
            'tokenPrice': realToken['tokenPrice'],
            'totalValue': realToken['totalInvestment'],
            'amount': 0.0,
            'annualPercentageYield': realToken['annualPercentageYield'],
            'dailyIncome': realToken['netRentDayPerToken'] * realToken['totalTokens'],
            'monthlyIncome': realToken['netRentMonthPerToken'] * realToken['totalTokens'],
            'yearlyIncome': realToken['netRentYearPerToken'] * realToken['totalTokens'],
            'initialLaunchDate': realToken['initialLaunchDate']?['date'],
            'totalInvestment': realToken['totalInvestment'],
            'underlyingAssetPrice': realToken['underlyingAssetPrice'] ?? 0.0,
            'initialMaintenanceReserve': realToken['initialMaintenanceReserve'],
            'rentalType': realToken['rentalType'],
            'rentStartDate': realToken['rentStartDate']?['date'],
            'rentedUnits': realToken['rentedUnits'],
            'totalUnits': realToken['totalUnits'],
            'grossRentMonth': realToken['grossRentMonth'],
            'netRentMonth': realToken['netRentMonth'],
            'constructionYear': realToken['constructionYear'],
            'propertyStories': realToken['propertyStories'],
            'lotSize': realToken['lotSize'],
            'squareFeet': realToken['squareFeet'],
            'marketplaceLink': realToken['marketplaceLink'],
            'propertyType': realToken['propertyType'],
            'productType': realToken['productType'],
            'historic': realToken['historic'],
            'ethereumContract': realToken['ethereumContract'],
            'gnosisContract': realToken['gnosisContract'],
            'initPrice': initPrice,
            'averagePurchasePrice': averagePurchasePrice,
            'totalRentReceived': totalRentReceived,
            'initialTotalValue': averagePurchasePrice,
            'propertyMaintenanceMonthly': realToken['propertyMaintenanceMonthly'],
            'propertyManagement': realToken['propertyManagement'],
            'realtPlatform': realToken['realtPlatform'],
            'insurance': realToken['insurance'],
            'propertyTaxes': realToken['propertyTaxes'],
            'realtListingFee': realToken['realtListingFee'],
            'renovationReserve': realToken['renovationReserve'],
            'miscellaneousCosts': realToken['miscellaneousCosts'],
            'section8paid': realToken['section8paid'] ?? 0.0,

            'yamTotalVolume': 0.0, // Ajout de la valeur Yam calculée
            'yamAverageValue': 0.0, // Ajout de la valeur moyenne Yam calculée
            'transactions': []
          });

          tempTotalTokens += 1; // Conversion explicite en int
          tempTotalInvestment += realToken['totalInvestment'] ?? 0.0;
          tempNetRentYear += realToken['netRentYearPerToken'] * (realToken['totalTokens'] as num).toInt();
          tempTotalUnits += (realToken['totalUnits'] as num?)?.toInt() ?? 0; // Conversion en int avec vérification
          tempRentedUnits += (realToken['rentedUnits'] as num?)?.toInt() ?? 0;
          // Gérer le cas où tokenPrice est soit un num soit une liste
          dynamic tokenPriceData = realToken['tokenPrice'];
          double? tokenPrice;
          int totalTokens = (realToken['totalTokens'] as num).toInt();

          if (tokenPriceData is List && tokenPriceData.isNotEmpty) {
            tokenPrice = (tokenPriceData.first as num).toDouble(); // Utiliser le premier élément de la liste
          } else if (tokenPriceData is num) {
            tokenPrice = tokenPriceData.toDouble(); // Utiliser directement si c'est un num
          }

          tempInitialPrice += averagePurchasePrice * totalTokens;

          if (tokenPrice != null) {
            tempActualPrice += tokenPrice * totalTokens;
          }

          // Calcul du rendement annuel
          if (realToken['annualPercentageYield'] != null) {
            tempAnnualYieldSum += realToken['annualPercentageYield'];
            yieldCount++;
          }
        }
      }
    }

    // Mettre à jour la liste des tokens
    _allTokens = allTokensList;

    // Mise à jour des variables partagées
    totalRealtTokens = tempTotalTokens; //en retire le RWA token dans le calcul
    totalRealtInvestment = tempTotalInvestment;
    realtInitialPrice = tempInitialPrice;
    realtActualPrice = tempActualPrice;
    netRealtRentYear = tempNetRentYear;
    totalRealtUnits = tempTotalUnits;
    rentedRealtUnits = tempRentedUnits;
    averageRealtAnnualYield = yieldCount > 0 ? tempAnnualYieldSum / yieldCount : 0.0;

    _archiveManager.archiveRentedValue(rentedRealtUnits / totalRealtUnits * 100);

    // Notifie les widgets que les données ont changé
    notifyListeners();
  }

  // Méthode pour récupérer et calculer les données pour le Dashboard et Portfolio
  Future<void> fetchAndCalculateData({bool forceFetch = false}) async {
    debugPrint("🗃️ Début récupération et calcul des données pour le Dashboard et Portfolio");
    // Vérifier si des adresses de wallet sont disponibles
    if (evmAddresses.isEmpty) {
      debugPrint("$_logWarning updateMainInformations : aucune adresse de wallet disponible");
      return;
    }

    var box = Hive.box('realTokens');
    initialTotalValue = 0.0;
    yamTotalValue = 0.0;

    // Charger les données en cache si disponibles
    final cachedTokens = box.get('cachedTokenData_tokens');
    if (cachedTokens != null) {
      walletTokens = List<Map<String, dynamic>>.from(json.decode(cachedTokens));
    }

    // Variables temporaires de calcul global
    double walletValueSum = 0.0;
    double rmmValueSum = 0.0;
    double rwaValue = 0.0;
    double walletTokensSum = 0.0;
    double rmmTokensSum = 0.0;
    double annualYieldSum = 0.0;
    double dailyRentSum = 0.0;
    double monthlyRentSum = 0.0;
    double yearlyRentSum = 0.0;
    int yieldCount = 0;
    List<Map<String, dynamic>> newPortfolio = [];

    // Réinitialisation des compteurs globaux
    walletTokenCount = 0;
    rmmTokenCount = 0;
    rentedUnits = 0;
    totalUnits = 0;

    // Sets pour stocker les tokens et adresses uniques
    Set<String> uniqueWalletTokens = {};
    Set<String> uniqueRmmTokens = {};
    Set<String> uniqueRentedUnitAddresses = {};
    Set<String> uniqueTotalUnitAddresses = {};

    // Fonction locale pour parser le fullName (utilise LocationUtils)
    Map<String, String> parseFullName(String fullName) {
      return {
        'country': LocationUtils.extractCountry(fullName),
        'regionCode': LocationUtils.extractRegion(fullName),
        'city': LocationUtils.extractCity(fullName),
      };
    }

    // Fonction locale pour mettre à jour les compteurs d'unités (pour éviter le comptage en double)
    void updateUnitCounters(String tokenAddress, Map<String, dynamic> realToken) {
      if (!uniqueRentedUnitAddresses.contains(tokenAddress)) {
        rentedUnits += (realToken['rentedUnits'] ?? 0) as int;
        uniqueRentedUnitAddresses.add(tokenAddress);
      }
      if (!uniqueTotalUnitAddresses.contains(tokenAddress)) {
        totalUnits += (realToken['totalUnits'] ?? 0) as int;
        uniqueTotalUnitAddresses.add(tokenAddress);
      }
    }

    // Créer des index Maps pour optimiser les recherches O(1) au lieu de O(n)
    Map<String, Map<String, dynamic>> realTokensIndex = {};
    for (var realToken in realTokens.cast<Map<String, dynamic>>()) {
      realTokensIndex[realToken['uuid'].toLowerCase()] = realToken;
    }

    Map<String, Map<String, dynamic>> yamHistoryIndex = {};
    for (var yam in yamHistory) {
      yamHistoryIndex[yam['id'].toLowerCase()] = yam;
    }

    for (var walletToken in walletTokens) {
      final tokenAddress = walletToken['token'].toLowerCase();

      // Recherche optimisée O(1) au lieu de O(n)
      final matchingRealToken = realTokensIndex[tokenAddress];
      if (matchingRealToken == null) {
        debugPrint("⚠️ Aucun RealToken correspondant trouvé pour le token: $tokenAddress");
        continue;
      }

      final double tokenPrice = matchingRealToken['tokenPrice'] ?? 0.0;
      final double tokenValue = walletToken['amount'] * tokenPrice;

      // Mise à jour des compteurs d'unités (une seule fois par token)
      updateUnitCounters(tokenAddress, matchingRealToken);

      // Séparation entre tokens RWA et autres
      if (tokenAddress == Parameters.rwaTokenAddress.toLowerCase()) {
        rwaValue += tokenValue;
      } else {
        if (walletToken['type'] == "wallet") {
          walletValueSum += tokenValue;
          walletTokensSum += walletToken['amount'];
          uniqueWalletTokens.add(tokenAddress);
        } else {
          rmmValueSum += tokenValue;
          rmmTokensSum += walletToken['amount'];
          uniqueRmmTokens.add(tokenAddress);
        }

        // Calcul des revenus si la date de lancement est passée
        final today = DateTime.now();
        final launchDateString = matchingRealToken['rentStartDate']?['date'];
        if (launchDateString != null) {
          final launchDate = DateTime.tryParse(launchDateString);
          if (launchDate != null && launchDate.isBefore(today)) {
            annualYieldSum += matchingRealToken['annualPercentageYield'];
            yieldCount++;
            dailyRentSum += matchingRealToken['netRentDayPerToken'] * walletToken['amount'];
            monthlyRentSum += matchingRealToken['netRentMonthPerToken'] * walletToken['amount'];
            yearlyRentSum += matchingRealToken['netRentYearPerToken'] * walletToken['amount'];
          }
        }
      }

      // Récupération du prix d'initialisation depuis l'historique du token
      final tokenContractAddress = matchingRealToken['uuid'].toLowerCase();

      // 1. Calculer le prix initial depuis l'historique (la valeur la plus ancienne)
      double initPrice = 0.0;
      // Vérifier s'il y a un historique pour ce token
      List<Map<String, dynamic>> tokenHistory = getTokenHistory(tokenContractAddress);
      if (tokenHistory.isNotEmpty) {
        // Trier par date pour obtenir la plus ancienne entrée
        tokenHistory.sort((a, b) {
          String dateA = a['date'] ?? '';
          String dateB = b['date'] ?? '';
          return dateA.compareTo(dateB); // Tri croissant pour avoir la plus ancienne en premier
        });

        // Prendre le prix du token de la première entrée (la plus ancienne)
        var oldestEntry = tokenHistory.first;
        initPrice = (oldestEntry['token_price'] as num?)?.toDouble() ??
            (matchingRealToken['historic']?['init_price'] as num?)?.toDouble() ??
            0.0;
      } else {
        // Si pas d'historique, utiliser le prix initial des données historiques
        initPrice = (matchingRealToken['historic']?['init_price'] as num?)?.toDouble() ?? 0.0;
      }

      // 2. Calculer le prix d'achat moyen pondéré à partir des transactions
      double averagePurchasePrice = initPrice; // Valeur par défaut
      double? customInitPrice = customInitPrices[tokenContractAddress];

      // Si un prix personnalisé existe, l'utiliser comme prix d'achat moyen
      if (customInitPrice != null) {
        averagePurchasePrice = customInitPrice;
      }
      // Sinon, calculer à partir des transactions si disponibles
      else if (transactionsByToken.containsKey(tokenContractAddress) &&
          transactionsByToken[tokenContractAddress]!.isNotEmpty) {
        List<Map<String, dynamic>> tokenTransactions = transactionsByToken[tokenContractAddress]!;
        double totalWeightedPrice = 0.0;
        double totalQuantity = 0.0;
        int transactionCount = 0;

        for (var transaction in tokenTransactions) {
          if (transaction['price'] != null &&
              transaction['price'] > 0 &&
              transaction['transactionType'] != transactionTypeTransfer &&
              transaction['amount'] != null &&
              transaction['amount'] > 0) {
            double price = transaction['price'];
            double amount = transaction['amount'];
            totalWeightedPrice += price * amount;
            totalQuantity += amount;
            transactionCount++;
          }
        }

        if (transactionCount > 0 && totalQuantity > 0) {
          averagePurchasePrice = totalWeightedPrice / totalQuantity;
        }
      }

      // Parsing du fullName pour obtenir country, regionCode et city
      final nameDetails = parseFullName(matchingRealToken['fullName']);

      // Récupération des données Yam avec index optimisé
      final yamData = yamHistoryIndex[tokenContractAddress] ?? <String, dynamic>{};
      final double yamTotalVolume = yamData['totalVolume'] ?? 1.0;
      final double yamAverageValue =
          (yamData['averageValue'] != null && yamData['averageValue'] != 0) ? yamData['averageValue'] : tokenPrice;

      // Fusion dans le portfolio par token (agrégation si le même token apparaît plusieurs fois)
      int index = newPortfolio.indexWhere((item) => item['uuid'] == tokenContractAddress);
      if (index != -1) {
        Map<String, dynamic> existingItem = newPortfolio[index];
        List<String> wallets =
            existingItem['wallets'] is List<String> ? List<String>.from(existingItem['wallets']) : [];
        if (!wallets.contains(walletToken['wallet'])) {
          wallets.add(walletToken['wallet']);
          // Log dès qu'un nouveau wallet est ajouté pour ce token
        }
        existingItem['wallets'] += wallets;
        existingItem['amount'] += walletToken['amount'];
        existingItem['totalValue'] = existingItem['amount'] * tokenPrice;
        existingItem['initialTotalValue'] = existingItem['amount'] * averagePurchasePrice;
        existingItem['dailyIncome'] = matchingRealToken['netRentDayPerToken'] * existingItem['amount'];
        existingItem['monthlyIncome'] = matchingRealToken['netRentMonthPerToken'] * existingItem['amount'];
        existingItem['yearlyIncome'] = matchingRealToken['netRentYearPerToken'] * existingItem['amount'];
      } else {
        Map<String, dynamic> portfolioItem = {
          'id': matchingRealToken['id'],
          'uuid': tokenContractAddress,
          'shortName': matchingRealToken['shortName'],
          'fullName': matchingRealToken['fullName'],
          'country': nameDetails['country'],
          'regionCode': nameDetails['regionCode'],
          'city': nameDetails['city'],
          'imageLink': matchingRealToken['imageLink'],
          'lat': matchingRealToken['coordinate']['lat'],
          'lng': matchingRealToken['coordinate']['lng'],
          'amount': walletToken['amount'],
          'totalTokens': matchingRealToken['totalTokens'],
          'source': walletToken['type'],
          'tokenPrice': tokenPrice,
          'totalValue': tokenValue,
          'initialTotalValue': walletToken['amount'] * averagePurchasePrice,
          'annualPercentageYield': matchingRealToken['annualPercentageYield'],
          'dailyIncome': matchingRealToken['netRentDayPerToken'] * walletToken['amount'],
          'monthlyIncome': matchingRealToken['netRentMonthPerToken'] * walletToken['amount'],
          'yearlyIncome': matchingRealToken['netRentYearPerToken'] * walletToken['amount'],
          'initialLaunchDate': matchingRealToken['initialLaunchDate']?['date'],
          'bedroomBath': matchingRealToken['bedroomBath'],
          // financials details
          'totalInvestment': matchingRealToken['totalInvestment'] ?? 0.0,
          'underlyingAssetPrice': matchingRealToken['underlyingAssetPrice'] ?? 0.0,
          'realtListingFee': matchingRealToken['realtListingFee'],
          'initialMaintenanceReserve': matchingRealToken['initialMaintenanceReserve'],
          'renovationReserve': matchingRealToken['renovationReserve'],
          'miscellaneousCosts': matchingRealToken['miscellaneousCosts'],
          'grossRentMonth': matchingRealToken['grossRentMonth'],
          'netRentMonth': matchingRealToken['netRentMonth'],
          'propertyMaintenanceMonthly': matchingRealToken['propertyMaintenanceMonthly'],
          'propertyManagement': matchingRealToken['propertyManagement'],
          'realtPlatform': matchingRealToken['realtPlatform'],
          'insurance': matchingRealToken['insurance'],
          'propertyTaxes': matchingRealToken['propertyTaxes'],
          'rentalType': matchingRealToken['rentalType'],
          'rentStartDate': matchingRealToken['rentStartDate']?['date'],
          'rentedUnits': matchingRealToken['rentedUnits'],
          'totalUnits': matchingRealToken['totalUnits'],
          'constructionYear': matchingRealToken['constructionYear'],
          'propertyStories': matchingRealToken['propertyStories'],
          'lotSize': matchingRealToken['lotSize'],
          'squareFeet': matchingRealToken['squareFeet'],
          'marketplaceLink': matchingRealToken['marketplaceLink'],
          'propertyType': matchingRealToken['propertyType'],
          'productType': matchingRealToken['productType'],
          'historic': matchingRealToken['historic'],
          'ethereumContract': matchingRealToken['ethereumContract'],
          'gnosisContract': matchingRealToken['gnosisContract'],
          'totalRentReceived': 0.0, // sera mis à jour juste après
          'initPrice': initPrice,
          'averagePurchasePrice': averagePurchasePrice,
          'section8paid': matchingRealToken['section8paid'] ?? 0.0,
          'yamTotalVolume': yamTotalVolume,
          'yamAverageValue': yamAverageValue,
          'transactions': transactionsByToken[tokenContractAddress] ?? [],
          // Nouveau champ "wallets" pour suivre dans quels wallets ce token apparaît
          'wallets': [walletToken['wallet']],
        };
        newPortfolio.add(portfolioItem);
        // Log de création de l'entrée dans le portfolio pour ce token
      }

      initialTotalValue += walletToken['amount'] * averagePurchasePrice;
      yamTotalValue += walletToken['amount'] * yamAverageValue;

      // Mise à jour du loyer total pour ce token
      if (tokenAddress.isNotEmpty) {
        // Utiliser directement la valeur précalculée au lieu d'appeler getRentDetailsForToken
        double rentDetails = cumulativeRentsByToken[tokenAddress.toLowerCase()] ?? 0.0;
        int index = newPortfolio.indexWhere((item) => item['uuid'] == tokenAddress);
        if (index != -1) {
          newPortfolio[index]['totalRentReceived'] = rentDetails;
        }
      }
    } // Fin de la boucle sur walletTokens

    // -------- Regroupement par wallet --------
    // Pour chaque token dans la liste brute, on regroupe par wallet et on cumule :
    // - La valeur totale des tokens de type "wallet"
    // - La somme des quantités
    // - Le nombre de tokens présents
    Map<String, Map<String, dynamic>> walletTotals = {};
    for (var token in walletTokens) {
      final String wallet = token['wallet'];
      // Initialisation si nécessaire
      if (!walletTotals.containsKey(wallet)) {
        walletTotals[wallet] = {
          'walletValueSum': 0.0,
          'walletTokensSum': 0.0,
          'tokenCount': 0,
        };
      }
      final tokenAddress = token['token'].toLowerCase();
      final matchingRealToken = realTokens.cast<Map<String, dynamic>>().firstWhere(
            (rt) => rt['uuid'].toLowerCase() == tokenAddress,
            orElse: () => <String, dynamic>{},
          );
      if (matchingRealToken.isEmpty) continue;
      final double tokenPrice = matchingRealToken['tokenPrice'] ?? 0.0;
      final double tokenValue = token['amount'] * tokenPrice;
      // On additionne uniquement pour les tokens de type "wallet"
      if (token['type'] == "wallet") {
        walletTotals[wallet]!['walletValueSum'] += tokenValue;
        walletTotals[wallet]!['walletTokensSum'] += token['amount'];
      }
      walletTotals[wallet]!['tokenCount'] += 1;
    }

    // Affichage des statistiques par wallet
    walletStats = []; // Réinitialiser la liste des statistiques
    walletTotals.forEach((wallet, totals) {
      // Ajouter les statistiques dans la variable globale
      walletStats.add({
        'address': wallet,
        'walletValueSum': totals['walletValueSum'] as double,
        'walletTokensSum': totals['walletTokensSum'] as double,
        'tokenCount': totals['tokenCount'] as int,
        'rmmTokensSum': 0.0, // Sera mis à jour plus tard
        'rmmValue': 0.0, // Sera mis à jour plus tard
      });
    });

    // -------- Calcul de la valeur RMM par wallet --------
    Map<String, double> walletRmmValues = {};
    Map<String, double> walletRmmTokensSum = {}; // Pour compter le nombre de tokens en RMM

    for (var token in walletTokens) {
      // On considère ici uniquement les tokens de type RMM (donc différents de "wallet")
      if (token['type'] != "wallet") {
        final String wallet = token['wallet'];
        final String tokenAddress = token['token'].toLowerCase();
        // Recherche du token correspondant dans realTokens (comme déjà fait précédemment)
        final matchingRealToken = realTokens.cast<Map<String, dynamic>>().firstWhere(
              (rt) => rt['uuid'].toLowerCase() == tokenAddress,
              orElse: () => <String, dynamic>{},
            );
        if (matchingRealToken.isEmpty) continue;
        final double tokenPrice = matchingRealToken['tokenPrice'] ?? 0.0;
        final double tokenValue = token['amount'] * tokenPrice;
        // Cumuler la valeur RMM pour ce wallet
        walletRmmValues[wallet] = (walletRmmValues[wallet] ?? 0.0) + tokenValue;
        // Cumuler le nombre de tokens en RMM
        walletRmmTokensSum[wallet] = (walletRmmTokensSum[wallet] ?? 0.0) + token['amount'];
      }
    }
    // Stocker ces valeurs dans une variable accessible (par exemple, dans DataManager)
    perWalletRmmValues = walletRmmValues;

    // Mettre à jour les statistiques des wallets avec les valeurs RMM
    for (var stat in walletStats) {
      final String address = stat['address'] as String;
      stat['rmmValue'] = walletRmmValues[address] ?? 0.0;
      stat['rmmTokensSum'] = walletRmmTokensSum[address] ?? 0.0;
    }

    // -------- Mise à jour des variables globales pour le Dashboard --------
    totalWalletValue = walletValueSum +
        rmmValueSum +
        rwaValue +
        totalUsdcDepositBalance +
        totalXdaiDepositBalance -
        totalUsdcBorrowBalance -
        totalXdaiBorrowBalance;
    _archiveManager.archiveTotalWalletValue(totalWalletValue);

    walletValue = double.parse(walletValueSum.toStringAsFixed(3));
    rmmValue = double.parse(rmmValueSum.toStringAsFixed(3));
    rwaHoldingsValue = double.parse(rwaValue.toStringAsFixed(3));
    walletTokensSums = double.parse(walletTokensSum.toStringAsFixed(3));
    rmmTokensSums = double.parse(rmmTokensSum.toStringAsFixed(3));
    totalTokens = (walletTokensSum + rmmTokensSum);
    averageAnnualYield = yieldCount > 0 ? annualYieldSum / yieldCount : 0;
    dailyRent = dailyRentSum;
    weeklyRent = dailyRentSum * 7;
    monthlyRent = monthlyRentSum;
    yearlyRent = yearlyRentSum;

    walletTokenCount = uniqueWalletTokens.length;
    rmmTokenCount = uniqueRmmTokens.length;
    final Set<String> allUniqueTokens = {...uniqueWalletTokens, ...uniqueRmmTokens};
    totalTokenCount = allUniqueTokens.length;
    duplicateTokenCount = uniqueWalletTokens.intersection(uniqueRmmTokens).length;

    _portfolio = newPortfolio;

    // Calculer le ROI global
    double totalRent = getTotalRentReceived();
    if (initialTotalValue > 0.000001) {
      // Vérifier si initialTotalValue n'est pas trop proche de 0
      roiGlobalValue = totalRent / initialTotalValue * 100;
      // Limiter le ROI à une valeur maximale raisonnable (par exemple 3650%)
      if (roiGlobalValue.isInfinite || roiGlobalValue.isNaN || roiGlobalValue > 3650) {
        roiGlobalValue = 3650;
      }
    } else {
      roiGlobalValue = 0.0;
    }

    // Archiver uniquement si nous avons des données de loyer
    if (rentData.isNotEmpty && totalRent > 0) {
      debugPrint("💾 Archivage de la valeur ROI: $roiGlobalValue");
      _archiveManager.archiveRoiValue(roiGlobalValue);
    } else {
      debugPrint("⚠️ Pas d'archivage ROI: liste des loyers vide ou montant total des loyers nul");
    }

    // Calculer l'APY uniquement si toutes les données nécessaires sont disponibles
    safeCalculateApyValues();

    healthFactor = (rmmValue * 0.7) / (totalUsdcBorrowBalance + totalXdaiBorrowBalance);
    ltv = ((totalUsdcBorrowBalance + totalXdaiBorrowBalance) / rmmValue * 100);
    _archiveManager.archiveHealthAndLtvValue(healthFactor, ltv);

    notifyListeners();
  }

  List<Map<String, dynamic>> getCumulativeRentEvolution() {
    List<Map<String, dynamic>> cumulativeRentList = [];
    double cumulativeRent = 0.0;

    // Filtrer les entrées valides et trier par `rentStartDate`
    final validPortfolioEntries = _portfolio.where((entry) {
      return entry['rentStartDate'] != null && entry['dailyIncome'] != null;
    }).toList()
      ..sort((a, b) {
        DateTime dateA = DateTime.parse(a['rentStartDate']);
        DateTime dateB = DateTime.parse(b['rentStartDate']);
        return dateA.compareTo(dateB);
      });

    // Accumuler les loyers
    for (var portfolioEntry in validPortfolioEntries) {
      DateTime rentStartDate = DateTime.parse(portfolioEntry['rentStartDate']);
      double dailyIncome = portfolioEntry['dailyIncome'] ?? 0.0;

      // Ajouter loyer au cumul
      cumulativeRent += dailyIncome * 7; // Supposons un calcul hebdomadaire

      // Ajouter à la liste des loyers cumulés
      cumulativeRentList.add({
        'rentStartDate': rentStartDate,
        'cumulativeRent': cumulativeRent,
      });
    }

    return cumulativeRentList;
  }

  // Méthode pour extraire les mises à jour récentes sur les 30 derniers jours
  List<Map<String, dynamic>> _extractRecentUpdates(List<dynamic> realTokensRaw) {
    final List<Map<String, dynamic>> realTokens = realTokensRaw.cast<Map<String, dynamic>>();
    List<Map<String, dynamic>> recentUpdates = [];

    for (var token in realTokens) {
      // Vérification si update30 existe, est une liste et est non vide
      if (token.containsKey('update30') && token['update30'] is List && token['update30'].isNotEmpty) {
        // Récupérer les informations de base du token
        final String shortName = token['shortName'] ?? 'Nom inconnu';
        final String imageLink = (token['imageLink'] != null && token['imageLink'].isNotEmpty)
            ? token['imageLink'][0]
            : 'Lien d\'image non disponible';

        // Filtrer et formater les mises à jour pertinentes
        List<Map<String, dynamic>> updatesWithDetails = List<Map<String, dynamic>>.from(token['update30'])
            .where((update) => update.containsKey('key') && _isRelevantKey(update['key'])) // Vérifier que 'key' existe
            .map((update) => _formatUpdateDetails(update, shortName, imageLink)) // Formater les détails
            .toList();

        // Ajouter les mises à jour extraites dans recentUpdates
        recentUpdates.addAll(updatesWithDetails);
      }
    }

    // Trier les mises à jour par date
    recentUpdates.sort((a, b) => DateTime.parse(b['timsync']).compareTo(DateTime.parse(a['timsync'])));
    return recentUpdates;
  }

  // Vérifier les clés pertinentes
  bool _isRelevantKey(String key) {
    return key == 'netRentYearPerToken' || key == 'annualPercentageYield';
  }

  // Formater les détails des mises à jour
  Map<String, dynamic> _formatUpdateDetails(Map<String, dynamic> update, String shortName, String imageLink) {
    String formattedKey = 'Donnée inconnue';
    String formattedOldValue = 'Valeur inconnue';
    String formattedNewValue = 'Valeur inconnue';

    // Vérifiez que les clés existent avant de les utiliser
    if (update['key'] == 'netRentYearPerToken') {
      double newValue = double.tryParse(update['new_value'] ?? '0') ?? 0.0;
      double oldValue = double.tryParse(update['old_value'] ?? '0') ?? 0.0;
      formattedKey = 'Net Rent Per Token (Annuel)';
      formattedOldValue = "${oldValue.toStringAsFixed(2)} USD";
      formattedNewValue = "${newValue.toStringAsFixed(2)} USD";
    } else if (update['key'] == 'annualPercentageYield') {
      double newValue = double.tryParse(update['new_value'] ?? '0') ?? 0.0;
      double oldValue = double.tryParse(update['old_value'] ?? '0') ?? 0.0;
      formattedKey = 'Rendement Annuel (%)';
      formattedOldValue = "${oldValue.toStringAsFixed(2)}%";
      formattedNewValue = "${newValue.toStringAsFixed(2)}%";
    }

    return {
      'shortName': shortName,
      'formattedKey': formattedKey,
      'formattedOldValue': formattedOldValue,
      'formattedNewValue': formattedNewValue,
      'timsync': update['timsync'] ?? '', // Assurez-vous que 'timsync' existe
      'imageLink': imageLink,
    };
  }

  // Méthode pour récupérer les données des loyers
  Future<void> fetchRentData({bool forceFetch = false}) async {
    var box = Hive.box('realTokens');

    // Charger les données en cache si disponibles
    final cachedRentData = box.get('cachedRentData');
    if (cachedRentData != null) {
      rentData = List<Map<String, dynamic>>.from(json.decode(cachedRentData));
      debugPrint("Données rentData en cache utilisées.");
    }
    Future(() async {
      try {
        // Exécuter l'appel d'API pour récupérer les données de loyer

        // Vérifier si les résultats ne sont pas vides avant de mettre à jour les variables
        if (tempRentData.isNotEmpty) {
          debugPrint("Mise à jour des données de rentData avec de nouvelles valeurs.");
          rentData = tempRentData; // Mise à jour de la variable locale
          box.put('cachedRentData', json.encode(tempRentData));
        } else {
          debugPrint("Les résultats des données de rentData sont vides, pas de mise à jour.");
        }
      } catch (e) {
        debugPrint("Erreur lors de la récupération des données de loyer: $e");
      }
    }).then((_) {
      notifyListeners(); // Notifier les listeners une fois les données mises à jour
    });
  }

  Future<void> processTransactionsHistory(BuildContext context, List<Map<String, dynamic>> transactionsHistory,
      List<Map<String, dynamic>> yamTransactions) async {
    // 🚨 IMPORTANT: Cette fonction traite les transactions et leur attribue des prix
    // Elle ne doit JAMAIS modifier l'historique des tokens (tokenHistoryData)
    // L'historique des tokens contient UNIQUEMENT les prix du marché du token,
    // pas les prix d'achat individuels des utilisateurs

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Set<String> evmAddresses = Set.from(prefs.getStringList('evmAddresses') ?? {});

    Map<String, List<Map<String, dynamic>>> tempTransactionsByToken = {};

    for (var transaction in transactionsHistory) {
      final String? tokenId = transaction['Token ID']?.toLowerCase();
      final String? timestampStr = transaction['timestamp'];
      final double? amount = (transaction['amount'] as num?)?.toDouble();
      final String? sender = transaction['sender']?.toLowerCase();
      final String? transactionId = transaction['Transaction ID']?.toLowerCase();

      if (tokenId == null || timestampStr == null || amount == null || transactionId == null) {
        continue;
      }

      try {
        // ✅ Convertir le timestamp Unix en DateTime
        final int timestampMs;
        try {
          timestampMs = int.parse(timestampStr) * 1000; // Convertir en millisecondes
        } catch (e) {
          continue;
        }

        DateTime dateTime;
        try {
          dateTime = DateTime.fromMillisecondsSinceEpoch(timestampMs, isUtc: true);
        } catch (e) {
          continue;
        }

        final bool isInternalTransfer = evmAddresses.contains(sender);
        // Utiliser les textes capturés au lieu de S.of(context)
        String transactionType = isInternalTransfer ? transactionTypeTransfer : transactionTypePurchase;

        try {
          final matchingYamTransaction = yamTransactions.firstWhere(
            (yamTransaction) {
              final String? yamId = yamTransaction['transaction_id']?.toLowerCase();
              if (yamId == null || yamId.isEmpty) return false;
              final String yamIdTrimmed = yamId.substring(0, yamId.length - 10);
              final bool match = transactionId.startsWith(yamIdTrimmed);
              return match;
            },
            orElse: () => {},
          );

          double? price;
          if (matchingYamTransaction.isNotEmpty) {
            final double? rawPrice = (matchingYamTransaction['price'] as num?)?.toDouble();
            price = rawPrice ?? 0.0;
            // Utiliser le texte capturé pour YAM
            transactionType = transactionTypeYam;
          } else {
            // Pour les transactions d'achat/transfert, utiliser UNIQUEMENT les prix du marché du token
            // JAMAIS ajouter de prix à l'historique du token basé sur la transaction
            if (transactionType == transactionTypePurchase || transactionType == transactionTypeTransfer) {
              // Chercher le token dans realTokens pour obtenir un prix initial
              final matchingRealToken = realTokens.cast<Map<String, dynamic>>().firstWhere(
                    (rt) => rt['uuid'].toLowerCase() == tokenId,
                    orElse: () => <String, dynamic>{},
                  );

              if (matchingRealToken.isNotEmpty) {
                // 1. D'abord chercher dans token['history'] avec la bonne date
                List<Map<String, dynamic>> tokenHistory = getTokenHistory(tokenId);

                // debugPrint("🔍 PRIX_DEBUG: Historique pour token $tokenId: ${tokenHistory.length} entrées");
                if (tokenHistory.isNotEmpty) {
                  // debugPrint("🔍 PRIX_DEBUG:   Structure première entrée: ${tokenHistory.first.keys.toList()}");
                }

                if (tokenHistory.isNotEmpty) {
                  // Trier l'historique par date (du plus ancien au plus récent)
                  tokenHistory.sort((a, b) {
                    String dateA = a['date'] ?? '';
                    String dateB = b['date'] ?? '';
                    return dateA.compareTo(dateB);
                  });

                  // Chercher l'entrée d'historique à la date de transaction ou antérieure la plus proche
                  Map<String, dynamic>? bestEntry;
                  DateTime transactionDate = dateTime;
                  DateTime? closestPreviousDate;

                  // debugPrint("🔍 PRIX_DEBUG: Recherche prix pour transaction $tokenId du ${transactionDate.toString().split(' ')[0]}");

                  for (var historyEntry in tokenHistory) {
                    try {
                      // Convertir la date depuis le format YYYY-MM-DD vers DateTime
                      DateTime historyDate = DateTime.parse(historyEntry['date']);

                      // debugPrint("🔍 PRIX_DEBUG:   Comparaison avec entrée historique ${historyDate.toString().split(' ')[0]} (token_price: ${historyEntry['token_price']})");

                      // Ne prendre que les dates antérieures ou égales à la date de transaction
                      if (historyDate.isBefore(transactionDate) ||
                          historyDate.isAtSameMomentAs(transactionDate) ||
                          (historyDate.year == transactionDate.year &&
                              historyDate.month == transactionDate.month &&
                              historyDate.day == transactionDate.day)) {
                        // debugPrint("🔍 PRIX_DEBUG:     ✅ Date antérieure/égale trouvée");

                        // Prendre la date antérieure la plus proche ET qui a un token_price valide
                        if (historyEntry['token_price'] != null &&
                            (closestPreviousDate == null || historyDate.isAfter(closestPreviousDate))) {
                          closestPreviousDate = historyDate;
                          bestEntry = historyEntry;
                          // debugPrint("🔍 PRIX_DEBUG:     ✅ Nouvelle meilleure entrée sélectionnée avec prix valide: ${historyEntry['token_price']}");
                        } else if (historyEntry['token_price'] == null) {
                          // debugPrint("🔍 PRIX_DEBUG:     ⚠️ Entrée ignorée car token_price est null");
                        }
                      } else {
                        // debugPrint("🔍 PRIX_DEBUG:     ❌ Date postérieure, ignorée");
                      }
                    } catch (e) {
                      // debugPrint("🔍 PRIX_DEBUG:     ❌ Erreur parsing date: $e");
                      continue;
                    }
                  }

                  // Utiliser le prix de l'entrée trouvée dans token['history']
                  if (bestEntry != null && bestEntry['token_price'] != null) {
                    price = (bestEntry['token_price'] as num?)?.toDouble() ?? 0.0;
                    // حذف متغیر استفاده‌نشده dateUsed
                    // debugPrint("💰 PRIX_DEBUG: Transaction $tokenId ${dateTime.toString().split(' ')[0]}: Prix historique token['history'] utilisé ${price.toStringAsFixed(2)} (date historique: $dateUsed)");
                  } else {
                    // debugPrint("🔍 PRIX_DEBUG: Aucune entrée avec prix valide trouvée pour $tokenId avant ${dateTime.toString().split(' ')[0]}");

                    // Chercher n'importe quelle entrée avec un prix valide dans l'historique (même future)
                    Map<String, dynamic>? fallbackEntry;
                    for (var historyEntry in tokenHistory) {
                      if (historyEntry['token_price'] != null) {
                        fallbackEntry = historyEntry;
                        break; // Prendre la première entrée avec un prix valide
                      }
                    }

                    if (fallbackEntry != null) {
                      price = (fallbackEntry['token_price'] as num?)?.toDouble() ?? 0.0;
                      // debugPrint("💰 PRIX_DEBUG: Transaction $tokenId ${dateTime.toString().split(' ')[0]}: Prix de fallback depuis l'historique utilisé ${price.toStringAsFixed(2)} (date: ${fallbackEntry['date']})");
                    } else {
                      // 3. Si aucune entrée avec prix dans token['history'], utiliser historic.init_price en dernier recours
                      price = (matchingRealToken['historic']?['init_price'] as num?)?.toDouble() ??
                          (matchingRealToken['tokenPrice'] as num?)?.toDouble() ??
                          0.0;
                      // debugPrint("💰 PRIX_DEBUG: Transaction $tokenId ${dateTime.toString().split(' ')[0]}: Prix historic.init_price utilisé en dernier recours ${price.toStringAsFixed(2)}");
                    }
                  }
                } else {
                  // 3. Si pas de token['history'], utiliser historic.init_price puis tokenPrice
                  price = (matchingRealToken['historic']?['init_price'] as num?)?.toDouble() ??
                      (matchingRealToken['tokenPrice'] as num?)?.toDouble() ??
                      0.0;
                  // debugPrint("💰 PRIX_DEBUG: Transaction $tokenId ${dateTime.toString().split(' ')[0]}: Aucun historique, prix par défaut ${price.toStringAsFixed(2)}");
                }
              } else {
                price = 0.0; // Prix par défaut si aucune information n'est disponible
                debugPrint("⚠️ // PRIX_DEBUG: Transaction $tokenId: Token non trouvé, prix = 0.0");
              }
            } else {
              // Pour les autres types de transactions, prix = 0
              price = 0.0;
            }
          }

          tempTransactionsByToken.putIfAbsent(tokenId, () => []).add({
            "amount": amount,
            "dateTime": dateTime,
            "transactionType": transactionType,
            "price": price,
          });
        } catch (e) {
          debugPrint("⚠️ Erreur lors du traitement des informations YAM: $e");
          continue;
        }
      } catch (e) {
        debugPrint("⚠️ Erreur de parsing de la transaction: $transaction. Détail: $e");
        continue;
      }
    }

    // ✅ **Ajout des transactions YAM manquantes**
    for (var yamTransaction in yamTransactions) {
      final String? yamId = yamTransaction['transaction_id']?.toLowerCase();
      if (yamId == null || yamId.isEmpty) continue;

      final String yamIdTrimmed = yamId.substring(0, yamId.length - 10);
      final bool alreadyExists = transactionsHistory
          .any((transaction) => transaction['Transaction ID']?.toLowerCase().startsWith(yamIdTrimmed) ?? false);

      if (!alreadyExists) {
        final String? yamTimestamp = yamTransaction['timestamp'];
        final double? yamPrice = (yamTransaction['price'] as num?)?.toDouble();
        final double? yamQuantity = (yamTransaction['quantity'] as num?)?.toDouble();
        final String? offerTokenAddress = yamTransaction['offer_token_address']?.toLowerCase();

        if (yamTimestamp == null || yamPrice == null || yamQuantity == null || offerTokenAddress == null) {
          continue;
        }

        final int timestampMs;
        try {
          timestampMs = int.parse(yamTimestamp) * 1000;
        } catch (e) {
          continue;
        }

        tempTransactionsByToken.putIfAbsent(offerTokenAddress, () => []).add({
          "amount": yamQuantity,
          "dateTime": DateTime.fromMillisecondsSinceEpoch(timestampMs, isUtc: true),
          "transactionType": transactionTypeYam,
          "price": yamPrice,
        });
      }
    }

    debugPrint("✅ Fin du traitement des transactions.");
    transactionsByToken.addAll(tempTransactionsByToken);
    isLoadingTransactions = false;
  }

  // Méthode pour récupérer les données des propriétés
  Future<void> fetchPropertyData({bool forceFetch = false}) async {
    List<Map<String, dynamic>> tempPropertyData = [];
    debugPrint("📊 Début de la récupération des données de propriété...");

    // Utiliser directement walletTokens au lieu de créer une nouvelle liste
    if (walletTokens.isEmpty) {
      debugPrint("⚠️ Aucun token dans walletTokens");
      notifyListeners();
      return;
    }

    // حذف متغیر استفاده‌نشده tokenProcessed
    // Parcourir chaque token du portefeuille
    for (var token in walletTokens) {
      if (token['token'] == null) continue;

      final String tokenAddress = token['token'].toLowerCase();

      // Correspondre avec les RealTokens
      final matchingRealToken = realTokens.cast<Map<String, dynamic>>().firstWhere(
            (realToken) => realToken['uuid'].toLowerCase() == tokenAddress,
            orElse: () => <String, dynamic>{},
          );

      if (matchingRealToken.isNotEmpty && matchingRealToken['propertyType'] != null) {
        final int propertyType = matchingRealToken['propertyType'];
        // حذف افزایش متغیر استفاده‌نشده tokenProcessed

        // Vérifiez si le type de propriété existe déjà dans propertyData
        final existingIndex = tempPropertyData.indexWhere((data) => data['propertyType'] == propertyType);

        if (existingIndex >= 0) {
          // Incrémenter le compte si la propriété existe déjà
          tempPropertyData[existingIndex]['count'] += 1;
        } else {
          // Ajouter une nouvelle entrée si la propriété n'existe pas encore
          tempPropertyData.add({'propertyType': propertyType, 'count': 1});
        }
      }
    }

    propertyData = tempPropertyData;
    notifyListeners();
  }

  // Méthode pour réinitialiser toutes les données
  Future<void> resetData() async {
    // Remettre toutes les variables à leurs valeurs initiales
    totalWalletValue = 0;
    walletValue = 0;
    rmmValue = 0;
    rwaHoldingsValue = 0;
    rentedUnits = 0;
    totalUnits = 0;
    totalTokens = 0;
    walletTokensSums = 0.0;
    rmmTokensSums = 0.0;
    averageAnnualYield = 0;
    dailyRent = 0;
    weeklyRent = 0;
    monthlyRent = 0;
    yearlyRent = 0;
    totalUsdcDepositBalance = 0;
    totalUsdcBorrowBalance = 0;
    totalXdaiDepositBalance = 0;
    totalXdaiBorrowBalance = 0;

    // Réinitialiser toutes les variables relatives à RealTokens
    totalRealtTokens = 0;
    totalRealtInvestment = 0.0;
    netRealtRentYear = 0.0;
    realtInitialPrice = 0.0;
    realtActualPrice = 0.0;
    totalRealtUnits = 0;
    rentedRealtUnits = 0;
    averageRealtAnnualYield = 0.0;

    // Réinitialiser les compteurs de tokens
    walletTokenCount = 0;
    rmmTokenCount = 0;
    totalTokenCount = 0;
    duplicateTokenCount = 0;

    // Vider les listes de données
    rentData = [];
    detailedRentData = [];
    propertyData = [];
    rmmBalances = [];
    perWalletBalances = [];
    walletTokens = [];
    realTokens = [];
    tempRentData = [];
    _portfolio = [];
    _recentUpdates = [];

    // Réinitialiser la map userIdToAddresses
    userIdToAddresses.clear();

    // Notifier les observateurs que les données ont été réinitialisées
    notifyListeners();

    // Supprimer également les préférences sauvegardées si nécessaire
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Si vous voulez vider toutes les préférences

    // Vider les caches Hive
    var box = Hive.box('realTokens');
    await box.clear(); // Vider la boîte Hive utilisée pour le cache des tokens

    debugPrint('Toutes les données ont été réinitialisées.');
  }

  Future<void> fetchRmmBalances() async {
    try {
      // Totaux globaux
      double totalUsdcDepositSum = 0;
      double totalUsdcBorrowSum = 0;
      double totalXdaiDepositSum = 0;
      double totalXdaiBorrowSum = 0;
      double totalGnosisUsdcSum = 0;
      double totalGnosisXdaiSum = 0;
      double totalGnosisRegSum = 0;
      double totalGnosisVaultRegSum = 0;
      // Liste pour stocker les données par wallet
      List<Map<String, dynamic>> walletDetails = [];

      String? timestamp;

      // Itérer sur chaque balance (chaque wallet)
      for (var balance in rmmBalances) {
        double usdcDeposit = balance['usdcDepositBalance'];
        double usdcBorrow = balance['usdcBorrowBalance'];
        double xdaiDeposit = balance['xdaiDepositBalance'];
        double xdaiBorrow = balance['xdaiBorrowBalance'];
        double gnosisUsdc = balance['gnosisUsdcBalance'];
        double gnosisXdai = balance['gnosisXdaiBalance'];
        double gnosisReg = balance['gnosisRegBalance'];
        double gnosisVaultReg = balance['gnosisVaultRegBalance'];
        timestamp = balance['timestamp']; // Dernier timestamp mis à jour

        // Mise à jour des totaux globaux
        totalUsdcDepositSum += usdcDeposit;
        totalUsdcBorrowSum += usdcBorrow;
        totalXdaiDepositSum += xdaiDeposit;
        totalXdaiBorrowSum += xdaiBorrow;
        totalGnosisUsdcSum += gnosisUsdc;
        totalGnosisXdaiSum += gnosisXdai;
        totalGnosisRegSum += gnosisReg;
        totalGnosisVaultRegSum += gnosisVaultReg;
        // Stocker les données propres au wallet
        walletDetails.add({
          'address': balance['address'],
          'usdcDeposit': usdcDeposit,
          'usdcBorrow': usdcBorrow,
          'xdaiDeposit': xdaiDeposit,
          'xdaiBorrow': xdaiBorrow,
          'gnosisUsdc': gnosisUsdc,
          'gnosisReg': gnosisReg,
          'gnosisVaultReg': gnosisVaultReg,
          'gnosisXdai': gnosisXdai,
          'timestamp': timestamp,
        });
      }

      // Mise à jour des variables globales avec les totaux cumulés
      totalUsdcDepositBalance = totalUsdcDepositSum;
      totalUsdcBorrowBalance = totalUsdcBorrowSum;
      totalXdaiDepositBalance = totalXdaiDepositSum;
      totalXdaiBorrowBalance = totalXdaiBorrowSum;
      // اگر کاربر راسل است مقدار gnosisUsdcBalance را همیشه ۲۰۰۰ نگه دار
      final currentUser = DataManager.appStateRef?.currentUser;
      if (currentUser != null && currentUser.username.toLowerCase() == 'russell') {
        gnosisUsdcBalance = 2000.0; // کیف پول فیک Russell: $2000
      } else {
        gnosisUsdcBalance = totalGnosisUsdcSum;
      }
      gnosisRegBalance = totalGnosisRegSum;
      gnosisXdaiBalance = totalGnosisXdaiSum;
      gnosisVaultRegBalance = totalGnosisVaultRegSum;
      // Stocker les détails par wallet
      perWalletBalances = walletDetails;

      // Calcul de l'APY GLOBAL uniquement après avoir accumulé les totaux
      try {
        usdcDepositApy = await calculateAPY('usdcDeposit');
        usdcBorrowApy = await calculateAPY('usdcBorrow');
        xdaiDepositApy = await calculateAPY('xdaiDeposit');
        xdaiBorrowApy = await calculateAPY('xdaiBorrow');
      } catch (e) {
        debugPrint('Erreur lors du calcul de l\'APY global: $e');
      }

      notifyListeners(); // Notifier l'interface que les données ont été mises à jour

      // Archivage global si une heure s'est écoulée depuis le dernier archivage
      if (lastArchiveTime == null || DateTime.now().difference(lastArchiveTime!).inMinutes >= 5) {
        if (timestamp != null) {
          _archiveManager.archiveBalance('usdcDeposit', totalUsdcDepositSum, timestamp);
          _archiveManager.archiveBalance('usdcBorrow', totalUsdcBorrowSum, timestamp);
          _archiveManager.archiveBalance('xdaiDeposit', totalXdaiDepositSum, timestamp);
          _archiveManager.archiveBalance('xdaiBorrow', totalXdaiBorrowSum, timestamp);
          lastArchiveTime = DateTime.now();
        }
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération des balances RMM: $e');
    }
  }

  Future<double> calculateAPY(String tokenType) async {
    // Récupérer l'historique des balances
    List<BalanceRecord> history = await _archiveManager.getBalanceHistory(tokenType);

    // Vérifier s'il y a au moins deux enregistrements pour calculer l'APY
    if (history.length < 2) {
      return 0.0; // Retourner 0.0 au lieu de lever une exception
    }

    try {
      // Utiliser la nouvelle méthode de calcul d'APY plus réactive
      double averageAPYForLastPairs = apyManager.calculateSmartAPY(history);

      // Vérifier si le résultat est NaN
      if (averageAPYForLastPairs.isNaN) {
        return 0.0;
      }

      // Si aucune paire valide n'est trouvée, retourner 0
      if (averageAPYForLastPairs == 0) {
        return 0.0;
      }

      // Calculer l'APY moyen global sur toutes les paires en utilisant la méthode exponentielle
      double globalApy = apyManager.calculateExponentialMovingAverageAPY(history);

      // Vérifier si le résultat global est NaN
      if (!globalApy.isNaN) {
        apyAverage = globalApy;
      }

      return averageAPYForLastPairs;
    } catch (e) {
      debugPrint("Error calculating APY for $tokenType: $e");
      return 0.0;
    }
  }

  double getTotalRentReceived() {
    return rentData.fold(
        0.0,
        (total, rentEntry) =>
            total + (rentEntry['rent'] is String ? double.parse(rentEntry['rent']) : rentEntry['rent']));
  }

  // Méthode pour charger les valeurs définies manuellement depuis Hive
  Future<void> loadCustomInitPrices() async {
    final savedData = customInitPricesBox.get('customInitPrices') as String?;

    if (savedData != null) {
      final decodedMap = Map<String, dynamic>.from(jsonDecode(savedData));
      customInitPrices = decodedMap.map((key, value) => MapEntry(key, value as double));
    }
    notifyListeners();
  }

  // Méthode pour sauvegarder les valeurs manuelles dans Hive
  Future<void> saveCustomInitPrices() async {
    final encodedData = jsonEncode(customInitPrices);
    await customInitPricesBox.put('customInitPrices', encodedData);
  }

  // Méthode pour définir une valeur initPrice personnalisée
  void setCustomInitPrice(String tokenUuid, double initPrice) {
    customInitPrices[tokenUuid] = initPrice;
    saveCustomInitPrices(); // Sauvegarder après modification
    notifyListeners();
  }

  void removeCustomInitPrice(String tokenUuid) {
    customInitPrices.remove(tokenUuid);
    saveCustomInitPrices(); // Sauvegarde les changements dans Hive
    notifyListeners();
  }

  Future<void> fetchAndStorePropertiesForSale() async {
    try {
      if (propertiesForSaleFetched.isNotEmpty) {
        propertiesForSale = propertiesForSaleFetched.map((property) {
          // Chercher le RealToken correspondant à partir de realTokens en comparant `title` et `fullName`
          final String propertyTitle = property['title']?.toString() ?? '';

          Map<String, dynamic> matchingToken = <String, dynamic>{};

          // Stratégie de correspondance multiple
          if (propertyTitle.isNotEmpty) {
            // 1. Correspondance exacte avec shortName
            matchingToken = allTokens.firstWhere(
              (token) => token['shortName']?.toString().toLowerCase() == propertyTitle.toLowerCase(),
              orElse: () => <String, dynamic>{},
            );

            // 2. Si pas trouvé, essayer avec fullName
            if (matchingToken.isEmpty) {
              matchingToken = allTokens.firstWhere(
                (token) => token['fullName']?.toString().toLowerCase() == propertyTitle.toLowerCase(),
                orElse: () => <String, dynamic>{},
              );
            }

            // 3. Si pas trouvé, essayer une correspondance partielle avec shortName (insensible à la casse)
            if (matchingToken.isEmpty) {
              matchingToken = allTokens.firstWhere(
                (token) =>
                    token['shortName'] != null &&
                    propertyTitle.toLowerCase().contains(token['shortName'].toString().toLowerCase()),
                orElse: () => <String, dynamic>{},
              );
            }

            // 4. Si pas trouvé, essayer une correspondance partielle inverse (insensible à la casse)
            if (matchingToken.isEmpty) {
              matchingToken = allTokens.firstWhere(
                (token) =>
                    token['shortName'] != null &&
                    token['shortName'].toString().toLowerCase().contains(propertyTitle.toLowerCase()),
                orElse: () => <String, dynamic>{},
              );
            }

            // 5. Si toujours pas trouvé, essayer une correspondance plus flexible basée sur des mots-clés
            if (matchingToken.isEmpty) {
              for (var token in allTokens) {
                if (token['shortName'] != null) {
                  final tokenShortName = token['shortName'].toString().toLowerCase();
                  final propertyTitleLower = propertyTitle.toLowerCase();

                  // Extraire les mots-clés principaux du shortName
                  final tokenWords = tokenShortName.split(' ').where((word) => word.length > 2).toList();

                  // Vérifier si tous les mots-clés principaux sont présents
                  bool allWordsMatch = tokenWords.every((word) => propertyTitleLower.contains(word));

                  if (allWordsMatch && tokenWords.isNotEmpty) {
                    matchingToken = token;
                    break;
                  }
                }
              }
            }
          }

          // Retourner les données avec fallback pour les cas non correspondants
          return {
            'title': property['title'],
            'fullName': matchingToken['fullName'] ?? property['title'],
            'shortName': matchingToken['shortName'] ?? property['title'],
            'marketplaceLink': matchingToken['marketplaceLink'] ?? 'https://realt.co',
            'country': matchingToken['country'] ?? 'Unknown',
            'city': matchingToken['city'] ?? 'Unknown',
            'tokenPrice': matchingToken['tokenPrice'] ?? 0.0,
            'annualPercentageYield': matchingToken['annualPercentageYield'] ?? 0.0,
            'totalTokens': property['stock'] ?? 0.0, // Utiliser le stock de l'API si pas de correspondance
            'rentStartDate': matchingToken['rentStartDate'],
            'status': property['status'],
            'productId': property['product_id'],
            'stock': property['stock'],
            'maxPurchase': property['max_purchase'],
            'imageLink': matchingToken['imageLink'] ?? [],
          };
        }).toList();

        debugPrint("✅ DataManager: ${propertiesForSale.length} propriétés en vente traitées");
      } else {
        debugPrint("⚠️ DataManager: Aucune propriété en vente trouvée");
      }
    } catch (e) {
      debugPrint("DataManager: Erreur lors de la récupération des propriétés en vente: $e");
    }

    // Notifie les widgets que les données ont changé
    notifyListeners();
  }

  Future<void> fetchAndStoreYamMarketData() async {
    var box = Hive.box('realTokens');

    // Récupération des données en cache, si disponibles
    final cachedData = box.get('cachedYamMarket');
    // حذف متغیر استفاده‌نشده yamMarketData

    if (cachedData != null) {
      yamMarketFetched = List<Map<String, dynamic>>.from(json.decode(cachedData));
    } else {
      debugPrint("⚠️ Aucune donnée YamMarket en cache.");
    }

    // حذف متغیرهای استفاده‌نشده totalTokenValue، totalOffers و totalTokenAmount

    List<Map<String, dynamic>> allOffersList = [];

    if (yamMarketFetched.isNotEmpty) {
      for (var offer in yamMarketFetched) {
        // Vérifier si le token de l'offre correspond à un token de allTokens
        final matchingToken = allTokens.firstWhere(
            (token) =>
                token['uuid'] == offer['token_to_sell']?.toLowerCase() ||
                token['uuid'] == offer['token_to_buy']?.toLowerCase(), orElse: () {
          return <String, dynamic>{};
        });

        // Vérifier si un token a été trouvé
        if (matchingToken.isEmpty) {
          continue;
        }

        // Récupérer et convertir les valeurs nécessaires
        // ...existing code...
        // ...existing code...

        // Ajouter l'offre traitée à la liste
        allOffersList.add({
          'id': offer['id'],
          'shortName': matchingToken['shortName'] ?? 'Unknown',
          'country': matchingToken['country'] ?? 'Unknown',
          'city': matchingToken['city'] ?? 'Unknown',
          'rentStartDate': matchingToken['rentStartDate'],
          'tokenToPay': offer['token_to_pay'],
          'imageLink': matchingToken['imageLink'],
          'holderAddress': offer['holder_address'],
          'token_amount': offer['token_amount'],
          'token_price': matchingToken['tokenPrice'],
          'annualPercentageYield': matchingToken['annualPercentageYield'],
          'tokenDigit': offer['token_digit'],
          'creationDate': offer['creation_date'],
          'token_to_pay': offer['token_to_pay'],
          'token_to_sell': offer['token_to_sell'],
          'token_to_buy': offer['token_to_buy'],
          'id_offer': offer['id_offer'],
          'tokenToPayDigit': offer['token_to_pay_digit'],
          'token_value': offer['token_value'],
          'blockNumber': offer['block_number'],
          'supp': offer['supp'],
          'timsync': offer['timsync'],
          'buyHolderAddress': offer['buy_holder_address'],
        });
      }

      yamMarket = allOffersList;

      notifyListeners();
    } else {
      debugPrint("⚠️ Aucune donnée YamMarket disponible après traitement.");
    }
  }

  void fetchYamHistory() {
    var box = Hive.box('realTokens');
    final yamHistoryJson = box.get('yamHistory');

    if (yamHistoryJson == null) {
      debugPrint("❌ fetchYamHistory -> Aucune donnée Yam History trouvée dans Hive.");
      return;
    }

    List<dynamic> yamHistoryData = json.decode(yamHistoryJson);

    // Regroupement par token
    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var entry in yamHistoryData) {
      String token = entry['token'];
      if (grouped[token] == null) {
        grouped[token] = [];
      }
      grouped[token]!.add(Map<String, dynamic>.from(entry));
    }

    List<Map<String, dynamic>> tokenStatistics = [];
    grouped.forEach((token, entries) {
      double totalVolume = 0;
      double totalQuantity = 0;
      for (var day in entries) {
        totalVolume += (day['volume'] as num).toDouble();
        totalQuantity += (day['quantity'] as num).toDouble();
      }
      double averageValue = totalQuantity > 0 ? totalVolume / totalQuantity : 0;
      tokenStatistics.add({
        'id': token,
        'totalVolume': totalVolume,
        'averageValue': averageValue,
      });
    });

    debugPrint("fetchYamHistory -> Mise à jour des statistiques des tokens Yam.");
    yamHistory = tokenStatistics;
    notifyListeners();
  }

  // Méthode centralisée pour calculer et archiver les valeurs d'APY
  void calculateApyValues() {
    // Calculer l'APY global avec la méthode centralisée
    netGlobalApy = calculateGlobalApy();

    // Calculer l'APY moyen pondéré par les montants
    double totalDepositAmount = totalUsdcDepositBalance + totalXdaiDepositBalance;
    double totalBorrowAmount = totalUsdcBorrowBalance + totalXdaiBorrowBalance;

    // APY pondéré pour les dépôts (gains) - toujours positif
    double weightedDepositApy = 0.0;
    if (totalDepositAmount > 0) {
      weightedDepositApy =
          (usdcDepositApy * totalUsdcDepositBalance + xdaiDepositApy * totalXdaiDepositBalance) / totalDepositAmount;
    }

    // APY pondéré pour les emprunts (coûts) - toujours positif
    double weightedBorrowApy = 0.0;
    if (totalBorrowAmount > 0) {
      weightedBorrowApy =
          (usdcBorrowApy * totalUsdcBorrowBalance + xdaiBorrowApy * totalXdaiBorrowBalance) / totalBorrowAmount;
    }

    // Calcul du total des intérêts gagnés et payés
    double depositInterest = weightedDepositApy * totalDepositAmount;
    double borrowInterest = weightedBorrowApy * totalBorrowAmount;

    // Intérêt net (positif si les coûts d'emprunt sont supérieurs aux gains de dépôt,
    // négatif si les gains de dépôt sont supérieurs aux coûts d'emprunt)
    double netInterest = borrowInterest - depositInterest;

    // Total des montants impliqués
    double totalAmount = totalDepositAmount + totalBorrowAmount;

    // Calculer l'APY moyen pondéré final
    if (totalAmount > 0) {
      apyAverage = netInterest / totalAmount;
    } else {
      apyAverage = 0.0;
    }

    // Vérifier si le résultat est NaN
    if (apyAverage.isNaN) {
      apyAverage = 0.0;
    }

    // Archiver l'APY global calculé
    _archiveApyValue(netGlobalApy, apyAverage);

    // Calculer l'APY pour chaque wallet individuel
    Map<String, double> walletApys = apyManager.calculateWalletApys(walletStats);

    // Mettre à jour les statistiques de wallet avec les APY calculés
    for (var wallet in walletStats) {
      final String address = wallet['address'] as String;
      wallet['apy'] = walletApys[address] ?? 0.0;
    }
  }

  /// Ajuste la réactivité du calcul d'APY
  ///
  /// [reactivityLevel] : niveau de réactivité entre 0 (très lisse) et 1 (très réactif)
  /// [historyDays] : nombre de jours d'historique à prendre en compte (optionnel)
  void adjustApyReactivity(double reactivityLevel, {int? historyDays}) {
    if (reactivityLevel < 0 || reactivityLevel > 1) {
      return;
    }

    // Calculer l'alpha pour l'EMA en fonction du niveau de réactivité
    // Une réactivité de 0 donne un alpha de 0.05 (très lisse)
    // Une réactivité de 1 donne un alpha de 0.8 (très réactif)
    double alpha = 0.05 + (reactivityLevel * 0.75);

    // Déterminer le nombre de jours d'historique
    // Si non spécifié, ajuster en fonction de la réactivité
    // Plus la réactivité est élevée, moins on a besoin d'historique
    // Plage de 1 à 20 jours avec des valeurs discrètes
    int days = historyDays ?? (20 - (reactivityLevel * 19).round()).clamp(1, 20);

    // Appliquer les nouveaux paramètres à l'ApyManager
    apyManager.setApyCalculationParameters(
      newEmaAlpha: alpha,
      newMaxHistoryDays: days,
    );

    // Recalculer l'APY avec les nouveaux paramètres
    if (balanceHistory.length >= 2) {
      try {
        safeCalculateApyValues();
      } catch (e) {
        debugPrint("❌ Erreur lors du recalcul de l'APY: $e");
      }
    } else {
      debugPrint(
          "⚠️ Historique insuffisant pour recalculer l'APY: ${balanceHistory.length} enregistrement(s) disponible(s) (minimum requis: 2)");
    }

    // Notifier les widgets pour qu'ils se mettent à jour
    notifyListeners();
  }

  void _archiveApyValue(double netApy, double grossApy) {
    debugPrint('🔍 _archiveApyValue: netApy: $netApy, grossApy: $grossApy');
    // Vérifier si nous avons moins de 20 éléments dans l'historique
    if (apyHistory.length < 20) {
      // Si moins de 20 éléments, vérifier si 15 minutes se sont écoulées depuis le dernier archivage
      if (apyHistory.isNotEmpty) {
        final lastRecord = apyHistory.last;
        final timeSinceLastRecord = DateTime.now().difference(lastRecord.timestamp);
        if (timeSinceLastRecord.inMinutes < 15) {
          debugPrint(
              '⏳ Archivage APY ignoré: moins de 15 minutes depuis le dernier enregistrement (${timeSinceLastRecord.inMinutes}m)');
          return;
        }
      }
    } else {
      // Si 20 éléments ou plus, vérifier si 1 heure s'est écoulée depuis le dernier archivage
      if (apyHistory.isNotEmpty) {
        final lastRecord = apyHistory.last;
        final timeSinceLastRecord = DateTime.now().difference(lastRecord.timestamp);
        if (timeSinceLastRecord.inHours < 1) {
          debugPrint(
              '⏳ Archivage APY ignoré: moins d\'une heure depuis le dernier enregistrement (${timeSinceLastRecord.inMinutes}m)');
          return;
        }
      }
    }

    // 1. Ajouter à la liste en mémoire
    apyHistory.add(APYRecord(apy: netApy, timestamp: DateTime.now()));

    // 2. Déléguer à l'ArchiveManager pour la persistance dans Hive
    _archiveManager.archiveApyValue(netApy, grossApy);

    // 3. Notifier les widgets pour mise à jour de l'UI
    notifyListeners();
  }

  // Valeurs d'APY calculées à partir de l'historique
  double apyAverageFromHistory = 0.0;
  double usdcDepositApyFromHistory = 0.0;
  double usdcBorrowApyFromHistory = 0.0;
  double xdaiDepositApyFromHistory = 0.0;
  double xdaiBorrowApyFromHistory = 0.0;

  // Valeurs d'APY basées sur les taux fixes
  double apyAverageFromRates = 0.0;
  double usdcDepositApyFromRates = 0.0;
  double usdcBorrowApyFromRates = 0.0;
  double xdaiDepositApyFromRates = 0.0;
  double xdaiBorrowApyFromRates = 0.0;

  Future<void> updateApyValues() async {
    try {
      // Calculer l'APY à partir de l'historique pour chaque type de balance
      usdcDepositApy = apyManager.calculateSmartAPY(await _archiveManager.getBalanceHistory('usdcDeposit'));
      usdcBorrowApy = apyManager.calculateSmartAPY(await _archiveManager.getBalanceHistory('usdcBorrow'));
      xdaiDepositApy = apyManager.calculateSmartAPY(await _archiveManager.getBalanceHistory('xdaiDeposit'));
      xdaiBorrowApy = apyManager.calculateSmartAPY(await _archiveManager.getBalanceHistory('xdaiBorrow'));

      // Vérifier et corriger les valeurs NaN
      if (usdcDepositApy.isNaN) usdcDepositApy = 0.0;
      if (usdcBorrowApy.isNaN) usdcBorrowApy = 0.0;
      if (xdaiDepositApy.isNaN) xdaiDepositApy = 0.0;
      if (xdaiBorrowApy.isNaN) xdaiBorrowApy = 0.0;

      // Nous appelons cette méthode pour mettre à jour apyAverage et netGlobalApy
      safeCalculateApyValues();

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erreur lors de la mise à jour des valeurs APY: $e');
      }
    }
  }

  // Méthode centralisée pour calculer l'APY global avec la formule originale
  double calculateGlobalApy() {
    try {
      // Calculer le dénominateur
      double denominator = walletValue +
          rmmValue +
          totalUsdcDepositBalance +
          totalXdaiDepositBalance +
          totalUsdcBorrowBalance +
          totalXdaiBorrowBalance;

      // Si le dénominateur est très proche de 0, retourner 0
      if (denominator < 0.000001) {
        debugPrint("⚠️ Le dénominateur est trop proche de 0 pour calculer l'APY global");
        return 0.0;
      }

      // Calculer le numérateur
      double numerator = (averageAnnualYield * (walletValue + rmmValue)) +
          (totalUsdcDepositBalance * usdcDepositApy + totalXdaiDepositBalance * xdaiDepositApy) -
          (totalUsdcBorrowBalance * usdcBorrowApy + totalXdaiBorrowBalance * xdaiBorrowApy);

      // Calculer le résultat
      double result = numerator / denominator;

      // Vérifier si le résultat est NaN, infini ou trop grand
      if (result.isNaN || result.isInfinite || result.abs() > 3650) {
        debugPrint(
            "⚠️ L'APY global calculé est ${result.isNaN ? "NaN" : result.isInfinite ? "infini" : "trop grand"}, retourne 0.0");
        return 0.0;
      }

      return result;
    } catch (e) {
      debugPrint("❌ Erreur lors du calcul de l'APY global: $e");
      return 0.0;
    }
  }

  // Nouvelle méthode pour obtenir l'historique des loyers d'un token spécifique
  List<Map<String, dynamic>> getRentHistoryForToken(String token) {
    token = token.toLowerCase();
    List<Map<String, dynamic>> history = [];

    // Parcourir l'historique des loyers par date
    for (var dateEntry in rentHistory) {
      String date = dateEntry['date'];
      List<Map<String, dynamic>> rents = List<Map<String, dynamic>>.from(dateEntry['rents']);

      // Rechercher ce token dans les loyers de cette date
      for (var rentEntry in rents) {
        if (rentEntry['token'].toLowerCase() == token) {
          // Ajouter l'entrée à l'historique spécifique au token
          history.add({'date': date, 'wallet': dateEntry['wallet'], 'rent': rentEntry['rent']});
          break; // On ne prend qu'une entrée par date pour ce token
        }
      }
    }

    return history;
  }

  // Méthode pour obtenir tous les loyers cumulés (déjà disponible via cumulativeRentsByToken)
  Map<String, double> getAllCumulativeRents() {
    return Map<String, double>.from(cumulativeRentsByToken);
  }

  // Nouvelle méthode pour obtenir le nombre de wallets possédant un token
  int getWalletCountForToken(String token) {
    return tokensWalletCount[token.toLowerCase()] ?? 0;
  }

  // Nouvelle méthode pour obtenir les loyers cumulés par wallet
  Map<String, Map<String, double>> getRentsByWallet() {
    return Map<String, Map<String, double>>.from(cumulativeRentsByWallet);
  }

  /// Méthode centralisée pour calculer l'APY seulement si toutes les données nécessaires sont disponibles
  /// Cette méthode devrait être appelée après le chargement des données importantes
  bool safeCalculateApyValues() {
    // Vérifier que nous avons suffisamment de données pour calculer l'APY
    if (balanceHistory.length < 2) {
      debugPrint(
          "⚠️ Historique insuffisant pour calculer l'APY: ${balanceHistory.length} enregistrement(s) (minimum requis: 2)");
      return false;
    }

    // Vérifier que les données financières essentielles sont disponibles
    if (totalUsdcDepositBalance == 0.0 &&
        totalXdaiDepositBalance == 0.0 &&
        totalUsdcBorrowBalance == 0.0 &&
        totalXdaiBorrowBalance == 0.0 &&
        walletValue == 0.0 &&
        rmmValue == 0.0) {
      debugPrint("⚠️ Données financières insuffisantes pour calculer l'APY");
      return false;
    }

    try {
      // Calculer l'APY à partir des données disponibles
      calculateApyValues();
      debugPrint("✅ APY calculé avec succès: $netGlobalApy%");
      return true;
    } catch (e) {
      debugPrint("❌ Erreur lors du calcul de l'APY: $e");
      return false;
    }
  }

  dynamic sanitizeValue(dynamic value) {
    if (value is Map) {
      return value.map((key, val) => MapEntry(key, sanitizeValue(val)));
    } else if (value is List) {
      return value.map(sanitizeValue).toList();
    } else if (value is num) {
      // Gérer les valeurs infinies et NaN
      if (value.isInfinite || value.isNaN) {
        return 0.0;
      }
      // Limiter les valeurs extrêmes
      if (value.abs() > 1e9) {
        return value.isNegative ? -1e9 : 1e9;
      }
      return value.toDouble();
    }
    return value;
  }

  Future<void> saveRoiHistory() async {
    try {
      var box = Hive.box('roiValueArchive');
      List<Map<String, dynamic>> roiHistoryJson = roiHistory.map((record) => record.toJson()).toList();
      await box.put('roi_history', roiHistoryJson);
      await box.flush(); // Forcer l'écriture sur le disque
      debugPrint("✅ Historique ROI sauvegardé avec succès.");
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Erreur lors de la sauvegarde de l'historique ROI : $e");
    }
  }

  Future<void> saveApyHistory() async {
    try {
      var box = Hive.box('apyValueArchive');
      List<Map<String, dynamic>> apyHistoryJson = apyHistory.map((record) => record.toJson()).toList();
      await box.put('apy_history', apyHistoryJson);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erreur lors de la sauvegarde de l\'historique APY : $e');
    }
  }

  /// Diagnostique l'état du cache des wallets pour identifier les problèmes de données
  Future<Map<String, dynamic>> diagnoseCacheStatus() async {
    try {
      debugPrint("$_logTask Lancement du diagnostic du cache pour ${evmAddresses.length} wallets");

      final diagnostics = await ApiService.diagnoseCacheStatus(evmAddresses);

      // Log des résultats principaux
      final globalCache = diagnostics['globalCacheStatus'];
      debugPrint("$_logDetail Cache global rent: ${globalCache['cachedRentData']}");
      debugPrint("$_logDetail Cache global detailed: ${globalCache['cachedDetailedRentDataAll']}");
      debugPrint("$_logDetail Dernière erreur 429 rent: ${globalCache['lastRent429Time']}");
      debugPrint("$_logDetail Dernière erreur 429 detailed: ${globalCache['lastDetailedRent429Time']}");

      final walletDiagnostics = diagnostics['walletDiagnostics'] as Map<String, dynamic>;
      int walletsWithRentCache = 0;
      int walletsWithDetailedCache = 0;

      for (String wallet in evmAddresses) {
        final walletInfo = walletDiagnostics[wallet];
        if (walletInfo != null && walletInfo['rentCacheExists'] == true) {
          walletsWithRentCache++;
        }
        if (walletInfo != null && walletInfo['detailedCacheExists'] == true) {
          walletsWithDetailedCache++;
        }
      }

      debugPrint("$_logDetail Wallets avec cache rent: $walletsWithRentCache/${evmAddresses.length}");
      debugPrint("$_logDetail Wallets avec cache detailed: $walletsWithDetailedCache/${evmAddresses.length}");

      debugPrint("$_logSuccess Diagnostic du cache terminé");
      return diagnostics;
    } catch (e) {
      debugPrint("$_logError Erreur lors du diagnostic du cache: $e");
      return {
        'error': 'Erreur lors du diagnostic: $e',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Traite et associe l'historique des tokens aux données existantes
  void processTokenHistory() {
    final startTime = DateTime.now();
    debugPrint("$_logSub Traitement de l'historique des tokens...");

    if (tokenHistoryData.isEmpty) {
      debugPrint("$_logWarning Aucune donnée d'historique de token disponible");
      return;
    }

    try {
      // Grouper l'historique par token_uuid
      Map<String, List<Map<String, dynamic>>> historyByToken = {};

      for (var historyEntry in tokenHistoryData) {
        String tokenUuid = historyEntry['token_uuid']?.toLowerCase() ?? '';
        if (tokenUuid.isNotEmpty) {
          if (!historyByToken.containsKey(tokenUuid)) {
            historyByToken[tokenUuid] = [];
          }
          historyByToken[tokenUuid]!.add(historyEntry);
        }
      }

      // Trier l'historique de chaque token par date (du plus récent au plus ancien)
      historyByToken.forEach((tokenUuid, history) {
        history.sort((a, b) {
          String dateA = a['date'] ?? '';
          String dateB = b['date'] ?? '';
          return dateB.compareTo(dateA); // Tri décroissant
        });
      });

      // Associer l'historique aux tokens dans allTokens
      for (var token in _allTokens) {
        String tokenUuid = token['uuid']?.toLowerCase() ?? '';
        if (historyByToken.containsKey(tokenUuid)) {
          token['history'] = historyByToken[tokenUuid];
        } else {
          token['history'] = <Map<String, dynamic>>[];
        }
      }

      // Associer l'historique aux tokens dans portfolio
      for (var token in _portfolio) {
        String tokenUuid = token['uuid']?.toLowerCase() ?? '';
        if (historyByToken.containsKey(tokenUuid)) {
          token['history'] = historyByToken[tokenUuid];
        } else {
          token['history'] = <Map<String, dynamic>>[];
        }
      }

      final duration = DateTime.now().difference(startTime);
      debugPrint(
          "$_logSuccess Historique des tokens traité: ${historyByToken.length} tokens avec historique (${duration.inMilliseconds}ms)");
    } catch (e) {
      debugPrint("$_logError Erreur lors du traitement de l'historique des tokens: $e");
    }
  }

  /// Méthode pour obtenir l'historique d'un token spécifique
  List<Map<String, dynamic>> getTokenHistory(String tokenUuid) {
    tokenUuid = tokenUuid.toLowerCase();
    return tokenHistoryData.where((entry) => entry['token_uuid']?.toLowerCase() == tokenUuid).toList()
      ..sort((a, b) {
        String dateA = a['date'] ?? '';
        String dateB = b['date'] ?? '';
        return dateB.compareTo(dateA); // Tri décroissant
      });
  }

  /// Méthode pour obtenir les modifications récentes (derniers 30 jours)
  List<Map<String, dynamic>> getRecentTokenChanges({int? days = 365, bool includeAllChanges = false}) {
    // Si days est null, pas de filtre de date (tous les changements)
    final DateTime? cutoffDate = days != null ? DateTime.now().subtract(Duration(days: days)) : null;

    List<Map<String, dynamic>> recentChanges = [];

    // Grouper par token pour détecter les changements
    Map<String, List<Map<String, dynamic>>> historyByToken = {};

    for (var entry in tokenHistoryData) {
      String tokenUuid = entry['token_uuid']?.toLowerCase() ?? '';
      String dateStr = entry['date'] ?? '';

      if (tokenUuid.isNotEmpty && dateStr.isNotEmpty) {
        try {
          DateTime entryDate = DateTime.parse(dateStr);
          // Si pas de limite de date (cutoffDate = null) ou si la date est après la limite
          if (cutoffDate == null || entryDate.isAfter(cutoffDate)) {
            if (!historyByToken.containsKey(tokenUuid)) {
              historyByToken[tokenUuid] = [];
            }
            historyByToken[tokenUuid]!.add(entry);
          }
        } catch (e) {
          debugPrint("⚠️ Erreur de parsing de date pour l'entrée: $entry");
        }
      }
    }

    // Pour chaque token, détecter les changements entre les entrées
    historyByToken.forEach((tokenUuid, history) {
      // Trier par date
      history.sort((a, b) => DateTime.parse(a['date']).compareTo(DateTime.parse(b['date'])));

      for (int i = 1; i < history.length; i++) {
        var previous = history[i - 1];
        var current = history[i];

        // Détecter les changements dans les champs importants
        List<Map<String, dynamic>> changes = _detectChanges(previous, current, tokenUuid, includeAllChanges);
        recentChanges.addAll(changes);
      }
    });

    // Trier les changements par date (du plus récent au plus ancien)
    recentChanges.sort((a, b) => DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));

    return recentChanges;
  }

  /// Détecte les changements entre deux entrées d'historique
  List<Map<String, dynamic>> _detectChanges(
      Map<String, dynamic> previous, Map<String, dynamic> current, String tokenUuid, bool includeAllChanges) {
    List<Map<String, dynamic>> changes = [];

    // Champs liés aux loyers (toujours affichés)
    final rentFields = {
      'gross_rent_year': 'Loyer brut annuel',
      'net_rent_year': 'Loyer net annuel',
      'rented_units': 'Unités louées',
    };

    // Autres champs (affichés seulement si includeAllChanges = true)
    final otherFields = {
      'token_price': 'Prix du token',
      'underlying_asset_price': 'Prix de l\'actif sous-jacent',
      'total_investment': 'Investissement total',
      'initial_maintenance_reserve': 'Réserve de maintenance initiale',
      'renovation_reserve': 'Réserve de rénovation',
    };

    // Combiner les champs selon le paramètre
    Map<String, String> fieldsToWatch = Map.from(rentFields);
    if (includeAllChanges) {
      fieldsToWatch.addAll(otherFields);
    }

    // Trouver le token correspondant pour obtenir les informations d'affichage
    Map<String, dynamic> tokenInfo = _allTokens.firstWhere(
      (token) => token['uuid']?.toLowerCase() == tokenUuid,
      orElse: () => {'shortName': 'Token inconnu', 'imageLink': ''},
    );

    // Gérer le cas où imageLink peut être une liste
    String imageLink = '';
    var imageData = tokenInfo['imageLink'];
    if (imageData is List && imageData.isNotEmpty) {
      imageLink = imageData.first?.toString() ?? '';
    } else if (imageData is String) {
      imageLink = imageData;
    }
    tokenInfo['imageLink'] = imageLink;

    fieldsToWatch.forEach((field, label) {
      var prevValue = previous[field];
      var currValue = current[field];

      if (prevValue != null && currValue != null && prevValue != currValue) {
        changes.add({
          'token_uuid': tokenUuid,
          'shortName': tokenInfo['shortName'] ?? 'Token inconnu',
          'imageLink': tokenInfo['imageLink'] ?? '',
          'field': field,
          'fieldLabel': label,
          'previousValue': prevValue,
          'currentValue': currValue,
          'date': current['date'],
          'changeType': _getChangeType(field, prevValue, currValue),
        });
      }
    });

    return changes;
  }

  /// Détermine le type de changement (hausse, baisse, modification)
  String _getChangeType(String field, dynamic prevValue, dynamic currValue) {
    if (prevValue is num && currValue is num) {
      if (currValue > prevValue) {
        return 'increase';
      } else if (currValue < prevValue) {
        return 'decrease';
      }
    }
    return 'change';
  }
}
