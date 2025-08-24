// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'en';

  static String m0(biometricType) => "Authenticate with ${biometricType}";

  static String m1(error) => "Error during test: ${error}";

  static String m2(days) => "${days} days ago";

  static String m3(days) => "+${days} d";

  static String m4(biometricType) => "This device supports ${biometricType}";

  static String m5(error) => "Error during test: ${error}";

  static String m6(error) => "Error: ${error}";

  static String m7(count) => "You own ${count} tokens of this property.";

  static String m8(language) => "Language updated to ${language}";

  static String m9(days) => "Next RONday in ${days} days";

  static String m10(count, name, price) =>
      "You have successfully purchased ${count} tokens of ${name} for ${price}.";

  static String m11(rented, total) => "Rented units: ${rented}/${total}";

  static String m12(weeks) => "ROI: ${weeks} weeks";

  static String m13(count, name, price) =>
      "You have successfully sold ${count} tokens of ${name} for ${price}.";

  static String m14(size) => "Text size updated: ${size}";

  static String m15(theme) => "Theme updated to ${theme}";

  static String m16(rented, total) => "Rented units: ${rented}/${total}";

  static String m17(address) => "Wallet saved: ${address}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "about": MessageLookupByLibrary.simpleMessage("About"),
        "aboutImportExport": MessageLookupByLibrary.simpleMessage(
            "This function allows you to save and re-import balance history data (wallet and RMM) into a ZIP file."),
        "aboutImportExportTitle":
            MessageLookupByLibrary.simpleMessage("Import/Export Function"),
        "addAddress": MessageLookupByLibrary.simpleMessage("Add address"),
        "addressCopied":
            MessageLookupByLibrary.simpleMessage("Address copied to clipboard"),
        "addressCopiedMessage": MessageLookupByLibrary.simpleMessage(
            "The address has been copied to the clipboard."),
        "adjustmentSaved": MessageLookupByLibrary.simpleMessage(
            "Adjustment saved successfully"),
        "adjustments": MessageLookupByLibrary.simpleMessage("Adjustments"),
        "advanced": MessageLookupByLibrary.simpleMessage("Advanced"),
        "all": MessageLookupByLibrary.simpleMessage("All"),
        "allChanges": MessageLookupByLibrary.simpleMessage("All\nchanges"),
        "allCities": MessageLookupByLibrary.simpleMessage("All Cities"),
        "allCountries": MessageLookupByLibrary.simpleMessage("All Countries"),
        "allProductTypes": MessageLookupByLibrary.simpleMessage("All types"),
        "allRegions": MessageLookupByLibrary.simpleMessage("All Regions"),
        "allTokens": MessageLookupByLibrary.simpleMessage("All tokens"),
        "allWallets": MessageLookupByLibrary.simpleMessage("All wallets"),
        "allWorkCorrectly": MessageLookupByLibrary.simpleMessage(
            "Everything is working correctly"),
        "all_data": MessageLookupByLibrary.simpleMessage("All Data"),
        "amount": MessageLookupByLibrary.simpleMessage("Amount"),
        "analytics": MessageLookupByLibrary.simpleMessage("Analytics"),
        "annualPercentageYield":
            MessageLookupByLibrary.simpleMessage("Annual yield"),
        "annualYield": MessageLookupByLibrary.simpleMessage("Net Yield"),
        "annually": MessageLookupByLibrary.simpleMessage("Annually"),
        "appDescription":
            MessageLookupByLibrary.simpleMessage("mobile app for Community"),
        "appName": MessageLookupByLibrary.simpleMessage("MeProp Asset Tracker"),
        "appTitle":
            MessageLookupByLibrary.simpleMessage("MeProp Asset Tracker"),
        "appearance": MessageLookupByLibrary.simpleMessage("Appearance"),
        "application": MessageLookupByLibrary.simpleMessage("Application"),
        "applyProductTypes": MessageLookupByLibrary.simpleMessage("Apply"),
        "applyWallets": MessageLookupByLibrary.simpleMessage("Apply"),
        "apy": MessageLookupByLibrary.simpleMessage("APY"),
        "apyHistory": MessageLookupByLibrary.simpleMessage("APY History"),
        "apyReactivityHeader":
            MessageLookupByLibrary.simpleMessage("APY Reactivity"),
        "areYouSureClearData": MessageLookupByLibrary.simpleMessage(
            "Are you sure you want to clear cache and data?"),
        "ascending": MessageLookupByLibrary.simpleMessage("Ascending"),
        "assetPrice": MessageLookupByLibrary.simpleMessage("Asset Price"),
        "assets": MessageLookupByLibrary.simpleMessage("Assets"),
        "authFailureMessage": MessageLookupByLibrary.simpleMessage(
            "Authentication failed. Please try again."),
        "authenticateReason": MessageLookupByLibrary.simpleMessage(
            "Authenticate to enable biometrics"),
        "authenticateWithBiometric": m0,
        "authenticating":
            MessageLookupByLibrary.simpleMessage("Authenticating..."),
        "author": MessageLookupByLibrary.simpleMessage("Author"),
        "autoSync":
            MessageLookupByLibrary.simpleMessage("Automatic synchronization"),
        "auto_mode": MessageLookupByLibrary.simpleMessage("Auto Mode"),
        "availableTokens":
            MessageLookupByLibrary.simpleMessage("Available Tokens"),
        "averageApy": MessageLookupByLibrary.simpleMessage("average APY"),
        "averageROI": MessageLookupByLibrary.simpleMessage("Average ROI"),
        "balance": MessageLookupByLibrary.simpleMessage("Balance"),
        "barChart": MessageLookupByLibrary.simpleMessage("Bar Chart"),
        "bedroomBath": MessageLookupByLibrary.simpleMessage("Bedroom/Bath"),
        "biometricAuthSuccessful": MessageLookupByLibrary.simpleMessage(
            "Biometric authentication activated successfully"),
        "biometricAuthentication":
            MessageLookupByLibrary.simpleMessage("Biometric authentication"),
        "biometricAuthenticationDisabled": MessageLookupByLibrary.simpleMessage(
            "Biometric authentication disabled"),
        "biometricAuthenticationFailed": MessageLookupByLibrary.simpleMessage(
            "Biometric authentication failed"),
        "biometricCheckError": MessageLookupByLibrary.simpleMessage(
            "Error: Unable to verify biometrics"),
        "biometricChecking": MessageLookupByLibrary.simpleMessage(
            "Verifying biometric capabilities..."),
        "biometricDisabled": MessageLookupByLibrary.simpleMessage(
            "Biometric authentication disabled"),
        "biometricEnabledSnackbar": MessageLookupByLibrary.simpleMessage(
            "Biometric authentication enabled"),
        "biometricEnabledSuccess": MessageLookupByLibrary.simpleMessage(
            "Biometric authentication enabled successfully"),
        "biometricError":
            MessageLookupByLibrary.simpleMessage("Biometric error"),
        "biometricNotAvailable":
            MessageLookupByLibrary.simpleMessage("Biometrics not available"),
        "biometricNotSupportedDetails": MessageLookupByLibrary.simpleMessage(
            "Your device does not support biometric authentication or no biometric data is enrolled on the device."),
        "biometricTestError": m1,
        "biometricTestFailed": MessageLookupByLibrary.simpleMessage(
            "Test failed. Please try again."),
        "biometricTestInProgress":
            MessageLookupByLibrary.simpleMessage("Authentication test..."),
        "biometricTestReason": MessageLookupByLibrary.simpleMessage(
            "This is a biometric authentication test"),
        "biometricTestSuccess": MessageLookupByLibrary.simpleMessage(
            "Test successful! Biometric authentication is working correctly."),
        "biometricTitle":
            MessageLookupByLibrary.simpleMessage("Biometric authentication"),
        "biometricsNotAvailable":
            MessageLookupByLibrary.simpleMessage("Biometrics not available"),
        "blockchain": MessageLookupByLibrary.simpleMessage("Blockchain"),
        "borrowBalance": MessageLookupByLibrary.simpleMessage("Borrows"),
        "brute": MessageLookupByLibrary.simpleMessage("Gross"),
        "buy": MessageLookupByLibrary.simpleMessage("Buy"),
        "buy_token": MessageLookupByLibrary.simpleMessage("Buy"),
        "cacheDataCleared":
            MessageLookupByLibrary.simpleMessage("Cache and data cleared"),
        "calendar": MessageLookupByLibrary.simpleMessage("Calendar"),
        "cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
        "cannotOpenSettings": MessageLookupByLibrary.simpleMessage(
            "Unable to open settings. Please configure them manually."),
        "cannotSellProperty":
            MessageLookupByLibrary.simpleMessage("Cannot Sell Property"),
        "changelog": MessageLookupByLibrary.simpleMessage("Changelog"),
        "characteristics":
            MessageLookupByLibrary.simpleMessage("Characteristics"),
        "chartType": MessageLookupByLibrary.simpleMessage("Chart type"),
        "checkingBiometricCapabilities": MessageLookupByLibrary.simpleMessage(
            "Checking biometric capabilities..."),
        "chinese": MessageLookupByLibrary.simpleMessage("中文"),
        "choice_all": MessageLookupByLibrary.simpleMessage("All"),
        "choice_buy": MessageLookupByLibrary.simpleMessage("Buy"),
        "choice_sell": MessageLookupByLibrary.simpleMessage("Sell"),
        "city": MessageLookupByLibrary.simpleMessage("City"),
        "clearCacheAndData":
            MessageLookupByLibrary.simpleMessage("Clear cache and data"),
        "clearCacheData":
            MessageLookupByLibrary.simpleMessage("Clear Cache/Data"),
        "close": MessageLookupByLibrary.simpleMessage("Close"),
        "commercial": MessageLookupByLibrary.simpleMessage("Commercial"),
        "completeHistory":
            MessageLookupByLibrary.simpleMessage("Complete\nHistory"),
        "condominium": MessageLookupByLibrary.simpleMessage("Condominium"),
        "configureInSystemSettings": MessageLookupByLibrary.simpleMessage(
            "Configure in system settings"),
        "confirm": MessageLookupByLibrary.simpleMessage("Confirm"),
        "confirmAction": MessageLookupByLibrary.simpleMessage("Confirm Action"),
        "confirmDeletionMessage": MessageLookupByLibrary.simpleMessage(
            "Are you sure you want to clear all data and cache? This action is irreversible."),
        "confirmDeletionTitle":
            MessageLookupByLibrary.simpleMessage("Confirm deletion"),
        "confirmPurchase":
            MessageLookupByLibrary.simpleMessage("Confirm Purchase"),
        "confirmSell": MessageLookupByLibrary.simpleMessage("Confirm Sale"),
        "connectBeforeSync": MessageLookupByLibrary.simpleMessage(
            "Connect to Google Drive before synchronization"),
        "connectBeforeSyncMessage": MessageLookupByLibrary.simpleMessage(
            "Connect to Google Drive before synchronization"),
        "connected": MessageLookupByLibrary.simpleMessage("Connected"),
        "constructionYear":
            MessageLookupByLibrary.simpleMessage("Year of construction"),
        "continueWithoutAuthentication": MessageLookupByLibrary.simpleMessage(
            "Continue without authentication"),
        "contractType": MessageLookupByLibrary.simpleMessage("Contract type"),
        "convertSqft":
            MessageLookupByLibrary.simpleMessage("Convert sqft to m²"),
        "copied": MessageLookupByLibrary.simpleMessage("Copied!"),
        "copy": MessageLookupByLibrary.simpleMessage("Copy"),
        "copyAddress": MessageLookupByLibrary.simpleMessage("Copy address"),
        "country": MessageLookupByLibrary.simpleMessage("Country"),
        "creation_date": MessageLookupByLibrary.simpleMessage("Creation Date"),
        "crypto": MessageLookupByLibrary.simpleMessage("Crypto"),
        "cryptoDonation":
            MessageLookupByLibrary.simpleMessage("Or donate in crypto:"),
        "cryptoDonationAddress":
            MessageLookupByLibrary.simpleMessage("Crypto Donation Address"),
        "cumulativeRentGraph":
            MessageLookupByLibrary.simpleMessage("Cumulative Rent"),
        "currency": MessageLookupByLibrary.simpleMessage("Currency"),
        "current_price": MessageLookupByLibrary.simpleMessage("Current Price:"),
        "current_yield": MessageLookupByLibrary.simpleMessage("Current Yield:"),
        "daily": MessageLookupByLibrary.simpleMessage("Daily"),
        "dao_description": MessageLookupByLibrary.simpleMessage(
            "Forum for proposals and discussion of MeProp DAO"),
        "dark": MessageLookupByLibrary.simpleMessage("Dark"),
        "darkTheme": MessageLookupByLibrary.simpleMessage("Dark Theme"),
        "dashboard": MessageLookupByLibrary.simpleMessage("Dashboard"),
        "dashboardLater": MessageLookupByLibrary.simpleMessage("Later"),
        "dashboardSyncProblem":
            MessageLookupByLibrary.simpleMessage("Sync problem"),
        "dashboardTotalRent":
            MessageLookupByLibrary.simpleMessage("Total rent"),
        "dataBackup": MessageLookupByLibrary.simpleMessage("Data backup"),
        "dataManagement":
            MessageLookupByLibrary.simpleMessage("Data management"),
        "date": MessageLookupByLibrary.simpleMessage("Date"),
        "dateNotCommunicated":
            MessageLookupByLibrary.simpleMessage("Date not communicated"),
        "day": MessageLookupByLibrary.simpleMessage("Day"),
        "days": MessageLookupByLibrary.simpleMessage("Days"),
        "daysAgo": m2,
        "daysLimit": MessageLookupByLibrary.simpleMessage("Days Limit"),
        "daysShort": m3,
        "delete": MessageLookupByLibrary.simpleMessage("Delete"),
        "delta_price": MessageLookupByLibrary.simpleMessage("Delta Price"),
        "depositBalance": MessageLookupByLibrary.simpleMessage("Deposits"),
        "deposits": MessageLookupByLibrary.simpleMessage("Deposits"),
        "depositsAndLoans":
            MessageLookupByLibrary.simpleMessage("Deposits & Loans"),
        "descending": MessageLookupByLibrary.simpleMessage("Descending"),
        "details": MessageLookupByLibrary.simpleMessage("Details"),
        "deviceDoesNotSupport": MessageLookupByLibrary.simpleMessage(
            "Your device does not support biometric authentication or no biometric data is registered in the device settings."),
        "deviceDoesNotSupportBiometric": MessageLookupByLibrary.simpleMessage(
            "This device does not support biometric authentication"),
        "deviceSupportsBiometric": m4,
        "displayHeader": MessageLookupByLibrary.simpleMessage("Display"),
        "display_period":
            MessageLookupByLibrary.simpleMessage("Display Period"),
        "donate": MessageLookupByLibrary.simpleMessage("Donate"),
        "donationMessage": MessageLookupByLibrary.simpleMessage(
            "If you like this app and want to support its development, you can donate."),
        "donationTotal":
            MessageLookupByLibrary.simpleMessage("Total donations"),
        "drawerAccounts": MessageLookupByLibrary.simpleMessage("Accounts"),
        "drawerFeatures": MessageLookupByLibrary.simpleMessage("Features"),
        "drawerSupportAndSettings":
            MessageLookupByLibrary.simpleMessage("Support & Settings"),
        "duplex": MessageLookupByLibrary.simpleMessage("Duplex"),
        "duplicate": MessageLookupByLibrary.simpleMessage(
            "Properties present in multiple wallets/RMM"),
        "duplicate_title":
            MessageLookupByLibrary.simpleMessage("Duplicate properties"),
        "edit": MessageLookupByLibrary.simpleMessage("Edit"),
        "editWalletBalance":
            MessageLookupByLibrary.simpleMessage("Edit Wallet Balance History"),
        "enableBiometric": MessageLookupByLibrary.simpleMessage(
            "Enable biometric authentication"),
        "enableBiometricAuthentication": MessageLookupByLibrary.simpleMessage(
            "Enable biometric authentication"),
        "enableNotifications":
            MessageLookupByLibrary.simpleMessage("Enable notifications"),
        "english": MessageLookupByLibrary.simpleMessage("English"),
        "enterAmount": MessageLookupByLibrary.simpleMessage("Enter Amount"),
        "enterValidNumber":
            MessageLookupByLibrary.simpleMessage("Please enter a valid number"),
        "error": MessageLookupByLibrary.simpleMessage("Error"),
        "errorDuringTest": m5,
        "errorLoadingData":
            MessageLookupByLibrary.simpleMessage("Error loading data"),
        "error_occurred": m6,
        "ethereumContract":
            MessageLookupByLibrary.simpleMessage("Ethereum contract"),
        "everyContributionCounts": MessageLookupByLibrary.simpleMessage(
            "Every contribution counts 🙏"),
        "expectedYield": MessageLookupByLibrary.simpleMessage("Expected Yield"),
        "exportAllTransactionsCsv": MessageLookupByLibrary.simpleMessage(
            "Export all transactions as CSV"),
        "exportAllTransactionsDescription": MessageLookupByLibrary.simpleMessage(
            "You can export all your transactions (purchases, transfers, rents) as a CSV file for analysis or archiving."),
        "exportAllTransactionsTitle":
            MessageLookupByLibrary.simpleMessage("Export all transactions"),
        "exportButton": MessageLookupByLibrary.simpleMessage("Export"),
        "exportData": MessageLookupByLibrary.simpleMessage("Export Data"),
        "exportFailed":
            MessageLookupByLibrary.simpleMessage("Failed to export data"),
        "exportRentsCsv":
            MessageLookupByLibrary.simpleMessage("Export rents as CSV"),
        "exportRentsDescription": MessageLookupByLibrary.simpleMessage(
            "You can export your rent history as a CSV file for use in a spreadsheet or for your declarations."),
        "exportRentsTitle":
            MessageLookupByLibrary.simpleMessage("Export rents"),
        "exportSuccess":
            MessageLookupByLibrary.simpleMessage("Data exported successfully"),
        "feedback": MessageLookupByLibrary.simpleMessage("Feedback"),
        "filterNotInWallet":
            MessageLookupByLibrary.simpleMessage("Not in wallet"),
        "filterOptions": MessageLookupByLibrary.simpleMessage("Filters"),
        "filter_all": MessageLookupByLibrary.simpleMessage("All"),
        "filter_buy": MessageLookupByLibrary.simpleMessage("Buy"),
        "filter_sell": MessageLookupByLibrary.simpleMessage("Sell"),
        "finances": MessageLookupByLibrary.simpleMessage("Finances"),
        "french": MessageLookupByLibrary.simpleMessage("Francais"),
        "fullyRented": MessageLookupByLibrary.simpleMessage("Fully rented"),
        "futureRents": MessageLookupByLibrary.simpleMessage("Future Rents"),
        "gDriveConnection":
            MessageLookupByLibrary.simpleMessage("Google Drive Connection"),
        "gnosisContract":
            MessageLookupByLibrary.simpleMessage("Gnosis contract"),
        "googleDriveConnection":
            MessageLookupByLibrary.simpleMessage("Google Drive connection"),
        "googleDriveTitle":
            MessageLookupByLibrary.simpleMessage("Google Drive"),
        "gridView": MessageLookupByLibrary.simpleMessage("Grid"),
        "grossRentMonth":
            MessageLookupByLibrary.simpleMessage("Gross rent per month"),
        "groupedRentGraph": MessageLookupByLibrary.simpleMessage("Rents"),
        "healthFactorSafer": MessageLookupByLibrary.simpleMessage(
            "Health Factor: Higher = Safer"),
        "hello": MessageLookupByLibrary.simpleMessage("Hello"),
        "hf": MessageLookupByLibrary.simpleMessage("HF"),
        "historyDays": MessageLookupByLibrary.simpleMessage("History (days)"),
        "hours": MessageLookupByLibrary.simpleMessage("Hours"),
        "importButton": MessageLookupByLibrary.simpleMessage("Import"),
        "importData": MessageLookupByLibrary.simpleMessage("Import Data"),
        "importExportData":
            MessageLookupByLibrary.simpleMessage("Import or export data (zip)"),
        "importFailed":
            MessageLookupByLibrary.simpleMessage("Failed to import data"),
        "importSuccess":
            MessageLookupByLibrary.simpleMessage("Data imported successfully"),
        "initialInvestment":
            MessageLookupByLibrary.simpleMessage("Initial Investment"),
        "initialLaunchDate":
            MessageLookupByLibrary.simpleMessage("Initial launch date"),
        "initialMaintenanceReserve":
            MessageLookupByLibrary.simpleMessage("Maintenance reserve"),
        "initialPrice":
            MessageLookupByLibrary.simpleMessage("Average purchase price"),
        "initialPriceModified_description": MessageLookupByLibrary.simpleMessage(
            "Value of the token at the average price you obtained it. This price will be considered for calculating the ROI among other things."),
        "initialPriceRemoved": MessageLookupByLibrary.simpleMessage(
            "Average purchase price removed"),
        "initialPriceUpdated": MessageLookupByLibrary.simpleMessage(
            "Average purchase price updated"),
        "insights": MessageLookupByLibrary.simpleMessage("Insights"),
        "insufficientTokens": m7,
        "insurance": MessageLookupByLibrary.simpleMessage("Insurance"),
        "internal_transfer":
            MessageLookupByLibrary.simpleMessage("Internal Transfer"),
        "invalidAmount":
            MessageLookupByLibrary.simpleMessage("Invalid amount entered."),
        "invalidCoordinates": MessageLookupByLibrary.simpleMessage(
            "Invalid coordinates for the property"),
        "invalidDataForChart": MessageLookupByLibrary.simpleMessage(
            "Invalid data for chart display"),
        "invalidWalletAddress":
            MessageLookupByLibrary.simpleMessage("Invalid wallet address"),
        "invalidWalletInQR":
            MessageLookupByLibrary.simpleMessage("Invalid wallet in QR Code"),
        "investment": MessageLookupByLibrary.simpleMessage("Investment"),
        "italian": MessageLookupByLibrary.simpleMessage("Italiano"),
        "language": MessageLookupByLibrary.simpleMessage("Language"),
        "languageUpdated": m8,
        "lastExecution": MessageLookupByLibrary.simpleMessage("Last update"),
        "lastRentReceived":
            MessageLookupByLibrary.simpleMessage("Your last rent received"),
        "last_update": MessageLookupByLibrary.simpleMessage("Last update:"),
        "legend": MessageLookupByLibrary.simpleMessage("Legend"),
        "light": MessageLookupByLibrary.simpleMessage("Light"),
        "light_mode": MessageLookupByLibrary.simpleMessage("Light Mode"),
        "lineChart": MessageLookupByLibrary.simpleMessage("Line Chart"),
        "linkedAddressesHeader":
            MessageLookupByLibrary.simpleMessage("Linked addresses"),
        "links": MessageLookupByLibrary.simpleMessage("Links"),
        "listView": MessageLookupByLibrary.simpleMessage("List"),
        "loans": MessageLookupByLibrary.simpleMessage("Loans"),
        "localStorage": MessageLookupByLibrary.simpleMessage("Local Storage"),
        "lotSize": MessageLookupByLibrary.simpleMessage("Lot size"),
        "ltv": MessageLookupByLibrary.simpleMessage("LTV"),
        "ltvSafer": MessageLookupByLibrary.simpleMessage("LTV: Lower = Safer"),
        "manageAddresses": MessageLookupByLibrary.simpleMessage("Add wallet"),
        "manageEvmAddresses":
            MessageLookupByLibrary.simpleMessage("Manage Wallets"),
        "manualAdjustment":
            MessageLookupByLibrary.simpleMessage("Manual Adjustment"),
        "manualAdjustmentDescription": MessageLookupByLibrary.simpleMessage(
            "Add or subtract a manually entered amount to the total portfolio value"),
        "manualEdit": MessageLookupByLibrary.simpleMessage("Manual Edit"),
        "maps": MessageLookupByLibrary.simpleMessage("Maps"),
        "mfrPortfolio": MessageLookupByLibrary.simpleMessage("MFR Portfolio"),
        "miscellaneousCosts":
            MessageLookupByLibrary.simpleMessage("Miscellaneous Costs"),
        "mixedUse": MessageLookupByLibrary.simpleMessage("Mixed-Use"),
        "modification": MessageLookupByLibrary.simpleMessage("modification"),
        "modifications": MessageLookupByLibrary.simpleMessage("modifications"),
        "month": MessageLookupByLibrary.simpleMessage("Month"),
        "monthly": MessageLookupByLibrary.simpleMessage("Monthly"),
        "months12": MessageLookupByLibrary.simpleMessage("12 Months"),
        "months3": MessageLookupByLibrary.simpleMessage("3 Months"),
        "months6": MessageLookupByLibrary.simpleMessage("6 Months"),
        "multiFamily": MessageLookupByLibrary.simpleMessage("Multi Family"),
        "nameUnavailable":
            MessageLookupByLibrary.simpleMessage("Name Unavailable"),
        "net": MessageLookupByLibrary.simpleMessage("Net"),
        "netAnnualRent":
            MessageLookupByLibrary.simpleMessage("Net Annual Rent"),
        "netApy": MessageLookupByLibrary.simpleMessage("Net APY"),
        "netApyHelp": MessageLookupByLibrary.simpleMessage(
            "The net yield is calculated by weighting the yields of the portfolios (wallet/RMM) and the deposit/borrow balances with their respective rates."),
        "netRentMonth":
            MessageLookupByLibrary.simpleMessage("Net rent per month"),
        "network": MessageLookupByLibrary.simpleMessage("Network"),
        "newValue": MessageLookupByLibrary.simpleMessage("New:"),
        "newVersionAvailable":
            MessageLookupByLibrary.simpleMessage("New Version Available"),
        "new_yield": MessageLookupByLibrary.simpleMessage("New Yield:"),
        "nextRondayInDays": m9,
        "nextRondays": MessageLookupByLibrary.simpleMessage("Next Rondays"),
        "noChangesFoundInCompleteHistory": MessageLookupByLibrary.simpleMessage(
            "No changes found in complete history"),
        "noChangesFoundInPastYear": MessageLookupByLibrary.simpleMessage(
            "No changes found in the past year"),
        "noCommunicatedDate":
            MessageLookupByLibrary.simpleMessage("Date not provided"),
        "noDataAvailable": MessageLookupByLibrary.simpleMessage(
            "No data available, please add a new wallet"),
        "noDataAvailableDot":
            MessageLookupByLibrary.simpleMessage("No data available."),
        "noFutureRents":
            MessageLookupByLibrary.simpleMessage("No future rents"),
        "noImageAvailable":
            MessageLookupByLibrary.simpleMessage("Image link not available"),
        "noPriceEvolution": MessageLookupByLibrary.simpleMessage(
            "No price evolution. The last price is:"),
        "noPropertiesForSale":
            MessageLookupByLibrary.simpleMessage("No properties for sale"),
        "noRecentUpdates": MessageLookupByLibrary.simpleMessage(
            "No recent changes available."),
        "noRentDataAvailable":
            MessageLookupByLibrary.simpleMessage("No rent data available."),
        "noRentDataToShare":
            MessageLookupByLibrary.simpleMessage("No rent data to share."),
        "noRentReceived":
            MessageLookupByLibrary.simpleMessage("No rent received"),
        "noScheduledRonday":
            MessageLookupByLibrary.simpleMessage("No scheduled RONday"),
        "noThanks": MessageLookupByLibrary.simpleMessage("No, thanks"),
        "noTokensAvailable":
            MessageLookupByLibrary.simpleMessage("No tokens available"),
        "noTokensFound":
            MessageLookupByLibrary.simpleMessage("No tokens found"),
        "noTokensOwned": MessageLookupByLibrary.simpleMessage(
            "You don\'t own any tokens of this property."),
        "noTokensWithValidCoordinates": MessageLookupByLibrary.simpleMessage(
            "No tokens with valid coordinates found on the map"),
        "noTransactionOrRentToExport": MessageLookupByLibrary.simpleMessage(
            "No transaction or rent to export."),
        "noTransactionsAvailable":
            MessageLookupByLibrary.simpleMessage("No transactions available"),
        "noWalletMessage": MessageLookupByLibrary.simpleMessage(
            "To use the application, you must first add at least one Ethereum wallet address."),
        "noWalletsAvailable":
            MessageLookupByLibrary.simpleMessage("No wallets available."),
        "noYieldEvolution": MessageLookupByLibrary.simpleMessage(
            "No yield evolution. The last yield is:"),
        "no_market_offers_available":
            MessageLookupByLibrary.simpleMessage("No market offers available"),
        "notAvailable": MessageLookupByLibrary.simpleMessage("N/A"),
        "notConnected": MessageLookupByLibrary.simpleMessage("Not connected"),
        "notRented": MessageLookupByLibrary.simpleMessage("Not rented"),
        "notSpecified": MessageLookupByLibrary.simpleMessage("Not specified"),
        "not_whitelisted_warning": MessageLookupByLibrary.simpleMessage(
            "Token not whitelisted, offer disabled"),
        "notifications": MessageLookupByLibrary.simpleMessage("Notifications"),
        "notificationsDisabledTitle":
            MessageLookupByLibrary.simpleMessage("Notifications disabled"),
        "numberOfTokens":
            MessageLookupByLibrary.simpleMessage("Number of Tokens"),
        "occupancyRate": MessageLookupByLibrary.simpleMessage("Occupancy Rate"),
        "occupancyStatusHigh": MessageLookupByLibrary.simpleMessage("High"),
        "occupancyStatusLow": MessageLookupByLibrary.simpleMessage("Low"),
        "occupancyStatusMedium": MessageLookupByLibrary.simpleMessage("Medium"),
        "offer_id": MessageLookupByLibrary.simpleMessage("Offer ID"),
        "offer_price": MessageLookupByLibrary.simpleMessage("Offer Price:"),
        "offering": MessageLookupByLibrary.simpleMessage("Offering"),
        "offers_list_header":
            MessageLookupByLibrary.simpleMessage("Offers List"),
        "ok": MessageLookupByLibrary.simpleMessage("OK"),
        "old": MessageLookupByLibrary.simpleMessage("Previous:"),
        "other": MessageLookupByLibrary.simpleMessage("Other"),
        "others": MessageLookupByLibrary.simpleMessage("Others"),
        "othersTitle": MessageLookupByLibrary.simpleMessage(
            "Details of the Others section"),
        "overview": MessageLookupByLibrary.simpleMessage("Overview"),
        "ownedTokens": MessageLookupByLibrary.simpleMessage("Owned Tokens"),
        "partiallyRented":
            MessageLookupByLibrary.simpleMessage("Partially rented"),
        "paypal": MessageLookupByLibrary.simpleMessage("PayPal"),
        "performanceByRegion":
            MessageLookupByLibrary.simpleMessage("Performance by Region"),
        "period": MessageLookupByLibrary.simpleMessage("Period"),
        "personalization":
            MessageLookupByLibrary.simpleMessage("Personalization"),
        "pleaseAuthenticateToAccess": MessageLookupByLibrary.simpleMessage(
            "Please authenticate to continue"),
        "portfolio": MessageLookupByLibrary.simpleMessage("Portfolio"),
        "portfolioGlobal":
            MessageLookupByLibrary.simpleMessage("Global Portfolio"),
        "portuguese": MessageLookupByLibrary.simpleMessage("Português"),
        "presentInWallet":
            MessageLookupByLibrary.simpleMessage("Present in wallet"),
        "price": MessageLookupByLibrary.simpleMessage("Price"),
        "priceEvolution":
            MessageLookupByLibrary.simpleMessage("Price evolution"),
        "priceEvolutionPercentage":
            MessageLookupByLibrary.simpleMessage("Price evolution:"),
        "primaryColorHeader":
            MessageLookupByLibrary.simpleMessage("Primary color"),
        "productTypeFactoringProfitshare":
            MessageLookupByLibrary.simpleMessage("Factoring Profit Share"),
        "productTypeHeader":
            MessageLookupByLibrary.simpleMessage("Product types"),
        "productTypeLoanIncome":
            MessageLookupByLibrary.simpleMessage("Loan Income"),
        "productTypeOther": MessageLookupByLibrary.simpleMessage("Other"),
        "productTypeRealEstateRental":
            MessageLookupByLibrary.simpleMessage("Real Estate Rental"),
        "projection": MessageLookupByLibrary.simpleMessage("projection"),
        "properties": MessageLookupByLibrary.simpleMessage("Properties"),
        "propertiesBuyThisProperty":
            MessageLookupByLibrary.simpleMessage("Buy this property"),
        "propertiesFactoring":
            MessageLookupByLibrary.simpleMessage("Factoring"),
        "propertiesForSale":
            MessageLookupByLibrary.simpleMessage("Properties for Sale"),
        "propertiesNoMarketplaceAvailable":
            MessageLookupByLibrary.simpleMessage(
                "Trading is not available for this property."),
        "propertiesPrice": MessageLookupByLibrary.simpleMessage("Price"),
        "propertiesProperty": MessageLookupByLibrary.simpleMessage("Property"),
        "propertiesStock": MessageLookupByLibrary.simpleMessage("Stock"),
        "propertiesYield": MessageLookupByLibrary.simpleMessage("Yield"),
        "properties_for_sale":
            MessageLookupByLibrary.simpleMessage("Properties For Sale"),
        "propertyMaintenanceMonthly": MessageLookupByLibrary.simpleMessage(
            "Property maintenance (monthly)"),
        "propertyManagement":
            MessageLookupByLibrary.simpleMessage("Property management"),
        "propertyPrice": MessageLookupByLibrary.simpleMessage("Property Price"),
        "propertyStories":
            MessageLookupByLibrary.simpleMessage("Number of stories"),
        "propertyTaxes": MessageLookupByLibrary.simpleMessage("Property Taxes"),
        "propertyType": MessageLookupByLibrary.simpleMessage("Property Type"),
        "purchase": MessageLookupByLibrary.simpleMessage("Purchase"),
        "purchaseConfirmation": m10,
        "purchaseDetails":
            MessageLookupByLibrary.simpleMessage("Purchase Details"),
        "purchaseSuccessful":
            MessageLookupByLibrary.simpleMessage("Purchase Successful"),
        "quantity": MessageLookupByLibrary.simpleMessage("Quantity"),
        "rateApp": MessageLookupByLibrary.simpleMessage("Rate App"),
        "reRequestPermission":
            MessageLookupByLibrary.simpleMessage("Re-request permission"),
        "reactive": MessageLookupByLibrary.simpleMessage("Reactive"),
        "realTPerformance":
            MessageLookupByLibrary.simpleMessage("MeProp Performance"),
        "realTTitle": MessageLookupByLibrary.simpleMessage("MeProp"),
        "realTokensList": MessageLookupByLibrary.simpleMessage("MeProps list"),
        "realt": MessageLookupByLibrary.simpleMessage("MeProp"),
        "realtActualPrice":
            MessageLookupByLibrary.simpleMessage("Actual Price"),
        "realtListingFee":
            MessageLookupByLibrary.simpleMessage("MeProp Listing Fee"),
        "realtPlatform":
            MessageLookupByLibrary.simpleMessage("MeProp Platform"),
        "realtStats": MessageLookupByLibrary.simpleMessage("MeProp stats"),
        "recentChanges": MessageLookupByLibrary.simpleMessage("Recent changes"),
        "recentUpdatesTitle":
            MessageLookupByLibrary.simpleMessage("Last 30 days"),
        "refresh": MessageLookupByLibrary.simpleMessage("Refresh"),
        "refusedNotificationsStartup": MessageLookupByLibrary.simpleMessage(
            "You have refused notifications at startup"),
        "refusedNotificationsStartupLong": MessageLookupByLibrary.simpleMessage(
            "You refused notifications at first launch. Use the button above to re-request permission if you change your mind."),
        "region": MessageLookupByLibrary.simpleMessage("Region"),
        "regionFilterLabel": MessageLookupByLibrary.simpleMessage("Region"),
        "regionHeader": MessageLookupByLibrary.simpleMessage("Region"),
        "renovationReserve":
            MessageLookupByLibrary.simpleMessage("Renovation Reserve"),
        "rentDetailsTitle":
            MessageLookupByLibrary.simpleMessage("Rent details"),
        "rentDistribution":
            MessageLookupByLibrary.simpleMessage("Rent Distribution"),
        "rentDistributionByProductType": MessageLookupByLibrary.simpleMessage(
            "Rent Distribution by Product Type"),
        "rentDistributionByWallet":
            MessageLookupByLibrary.simpleMessage("Rent distribution by wallet"),
        "rentGraph":
            MessageLookupByLibrary.simpleMessage("Rent Received Graph"),
        "rentNoDataAvailable":
            MessageLookupByLibrary.simpleMessage("No rent data available."),
        "rentNoDataToShare":
            MessageLookupByLibrary.simpleMessage("No rent data to share."),
        "rentStartDate": MessageLookupByLibrary.simpleMessage("First rent"),
        "rentStartFuture":
            MessageLookupByLibrary.simpleMessage("Rent not started"),
        "rentalStatus": MessageLookupByLibrary.simpleMessage("Rental status"),
        "rentalStatusAll": MessageLookupByLibrary.simpleMessage("All"),
        "rentalStatusDistribution":
            MessageLookupByLibrary.simpleMessage("Rental status distribution"),
        "rentalStatusNotRented":
            MessageLookupByLibrary.simpleMessage("Not Rented"),
        "rentalStatusPartiallyRented":
            MessageLookupByLibrary.simpleMessage("Partially Rented"),
        "rentalStatusRented": MessageLookupByLibrary.simpleMessage("Rented"),
        "rentalStatusTitle":
            MessageLookupByLibrary.simpleMessage("Rental Status"),
        "rentalType": MessageLookupByLibrary.simpleMessage("Rental type"),
        "rented": MessageLookupByLibrary.simpleMessage("Rented"),
        "rentedUnits": m11,
        "rentedUnitsSimple":
            MessageLookupByLibrary.simpleMessage("Rented Units"),
        "rents": MessageLookupByLibrary.simpleMessage("Rents"),
        "resortBungalow":
            MessageLookupByLibrary.simpleMessage("Resort Bungalow"),
        "revenue": MessageLookupByLibrary.simpleMessage("Revenue"),
        "reviewRequestUnavailable": MessageLookupByLibrary.simpleMessage(
            "The review request couldn\'t be displayed. Would you like to open the app page in the Store to leave a review?"),
        "rmm": MessageLookupByLibrary.simpleMessage("RMM"),
        "rmmDetails": MessageLookupByLibrary.simpleMessage("RMM Details"),
        "rmmHealth": MessageLookupByLibrary.simpleMessage("RMM Health"),
        "rmmValue": MessageLookupByLibrary.simpleMessage("RMM Value"),
        "rmm_description": MessageLookupByLibrary.simpleMessage(
            "Platform for lending and borrowing using real estate tokens."),
        "roiAlertInfo": MessageLookupByLibrary.simpleMessage(
            "This ROI feature is in beta and is currently calculated based on the income received from the property and the initial token value."),
        "roiByToken": MessageLookupByLibrary.simpleMessage("ROI by Token"),
        "roiHistory": MessageLookupByLibrary.simpleMessage("ROI History"),
        "roiPerProperties":
            MessageLookupByLibrary.simpleMessage("Property ROI"),
        "roi_label": m12,
        "russian": MessageLookupByLibrary.simpleMessage("Russian"),
        "rwaHoldings": MessageLookupByLibrary.simpleMessage("RWA Holdings SA"),
        "save": MessageLookupByLibrary.simpleMessage("Save"),
        "scanQRCode": MessageLookupByLibrary.simpleMessage("Scan QR Code"),
        "searchHint": MessageLookupByLibrary.simpleMessage("Search..."),
        "search_hint":
            MessageLookupByLibrary.simpleMessage("Search by name..."),
        "secondary": MessageLookupByLibrary.simpleMessage("Secondary"),
        "secondary_offers_related_to_token":
            MessageLookupByLibrary.simpleMessage("YAM offers related to token"),
        "section8paid": MessageLookupByLibrary.simpleMessage("Section 8"),
        "security": MessageLookupByLibrary.simpleMessage("Security"),
        "securityHeader": MessageLookupByLibrary.simpleMessage("Security"),
        "selectCurrency":
            MessageLookupByLibrary.simpleMessage("Select Currency"),
        "sell": MessageLookupByLibrary.simpleMessage("Sell"),
        "sellAmount": MessageLookupByLibrary.simpleMessage("Sale Amount"),
        "sellConfirmation": m13,
        "sellDetails": MessageLookupByLibrary.simpleMessage("Sale Details"),
        "sellSuccessful":
            MessageLookupByLibrary.simpleMessage("Sale Successful"),
        "sellThisProperty":
            MessageLookupByLibrary.simpleMessage("Sell Property"),
        "sell_token": MessageLookupByLibrary.simpleMessage("Sell"),
        "sendDonations": MessageLookupByLibrary.simpleMessage(
            "Send your donations to the following address:"),
        "serviceStatus": MessageLookupByLibrary.simpleMessage("Service Status"),
        "serviceStatusPage":
            MessageLookupByLibrary.simpleMessage("Services status"),
        "settings": MessageLookupByLibrary.simpleMessage("Settings"),
        "settingsCategory": MessageLookupByLibrary.simpleMessage("Settings"),
        "settingsTitle": MessageLookupByLibrary.simpleMessage("Settings"),
        "sfrPortfolio": MessageLookupByLibrary.simpleMessage("SFR Portfolio"),
        "showAll": MessageLookupByLibrary.simpleMessage("Show All"),
        "showNetTotal": MessageLookupByLibrary.simpleMessage("Show Net Total"),
        "showNetTotalDescription": MessageLookupByLibrary.simpleMessage(
            "Include deposits and borrows in total portfolio calculation"),
        "showOnlyWhitelisted":
            MessageLookupByLibrary.simpleMessage("Whitelist only"),
        "showTop10": MessageLookupByLibrary.simpleMessage("Show Top 10"),
        "showTotalInvested":
            MessageLookupByLibrary.simpleMessage("Show Total Invested"),
        "showYamProjection":
            MessageLookupByLibrary.simpleMessage("Show YAM projection"),
        "singleFamily": MessageLookupByLibrary.simpleMessage("Single Family"),
        "smooth": MessageLookupByLibrary.simpleMessage("Smooth"),
        "somethingWrong": MessageLookupByLibrary.simpleMessage(
            "The data may not be up to date"),
        "sortBy": MessageLookupByLibrary.simpleMessage("Sort By"),
        "sortByAPY": MessageLookupByLibrary.simpleMessage("Sort by APY"),
        "sortByCount": MessageLookupByLibrary.simpleMessage("Sort by Count"),
        "sortByInitialLaunchDate":
            MessageLookupByLibrary.simpleMessage("Sort by recently added"),
        "sortByName": MessageLookupByLibrary.simpleMessage("Sort by Name"),
        "sortByROI": MessageLookupByLibrary.simpleMessage("Sort by ROI"),
        "sortByValue": MessageLookupByLibrary.simpleMessage("Sort by Value"),
        "sort_ascending": MessageLookupByLibrary.simpleMessage("Ascending"),
        "sort_date": MessageLookupByLibrary.simpleMessage("Date"),
        "sort_delta": MessageLookupByLibrary.simpleMessage("Delta"),
        "sort_descending": MessageLookupByLibrary.simpleMessage("Descending"),
        "sort_label": MessageLookupByLibrary.simpleMessage("Sort:"),
        "spanish": MessageLookupByLibrary.simpleMessage("Español"),
        "specialThanks": MessageLookupByLibrary.simpleMessage(
            "Special thanks to @Sigri, @ehpst, and @pitsbi for their support."),
        "specialThanksJojodunet": MessageLookupByLibrary.simpleMessage(
            "Special thanks to @Jojodunet for his tenacity and hours spent testing and retesting the app!"),
        "squareFeet": MessageLookupByLibrary.simpleMessage("Interior size"),
        "statistics": MessageLookupByLibrary.simpleMessage("Statistics"),
        "street_view": MessageLookupByLibrary.simpleMessage("Street View"),
        "support": MessageLookupByLibrary.simpleMessage("Support"),
        "supportProject":
            MessageLookupByLibrary.simpleMessage("Support the project"),
        "syncComplete": MessageLookupByLibrary.simpleMessage(
            "Synchronization completed with Google Drive"),
        "syncCompleteWithGoogleDrive": MessageLookupByLibrary.simpleMessage(
            "Synchronization completed with Google Drive"),
        "syncWithGoogleDrive":
            MessageLookupByLibrary.simpleMessage("Sync with Google Drive"),
        "synchronization":
            MessageLookupByLibrary.simpleMessage("Synchronization"),
        "testAuthenticationDescription": MessageLookupByLibrary.simpleMessage(
            "You can test biometric authentication to verify it works correctly."),
        "testAuthenticationHeader":
            MessageLookupByLibrary.simpleMessage("Test authentication"),
        "testAuthenticationReason": MessageLookupByLibrary.simpleMessage(
            "This is a biometric authentication test"),
        "testBiometricAuthentication": MessageLookupByLibrary.simpleMessage(
            "Test biometric authentication"),
        "testBiometricDescription": MessageLookupByLibrary.simpleMessage(
            "You can test biometric authentication to verify it works properly."),
        "testFailed": MessageLookupByLibrary.simpleMessage("Test failed"),
        "testNow": MessageLookupByLibrary.simpleMessage("Test now"),
        "testSuccessful":
            MessageLookupByLibrary.simpleMessage("Test successful"),
        "testingAuthentication":
            MessageLookupByLibrary.simpleMessage("Testing authentication..."),
        "textSize": MessageLookupByLibrary.simpleMessage("Text size"),
        "textSizeUpdated": m14,
        "thankYouForFeedback": MessageLookupByLibrary.simpleMessage(
            "Thank you for your feedback!"),
        "thankYouMessage": MessageLookupByLibrary.simpleMessage(
            "Thank you to everyone who contributed to this project."),
        "thanks": MessageLookupByLibrary.simpleMessage("Thanks"),
        "thanksDonators": MessageLookupByLibrary.simpleMessage(
            "Thanks also to all the donors who support the development of this application!"),
        "themeHeader": MessageLookupByLibrary.simpleMessage("Theme"),
        "themeUpdated": m15,
        "timeBeforeLiquidation":
            MessageLookupByLibrary.simpleMessage("before liquidation"),
        "time_range": MessageLookupByLibrary.simpleMessage("Time Range"),
        "timestamp": MessageLookupByLibrary.simpleMessage("Timestamp"),
        "today": MessageLookupByLibrary.simpleMessage("Today"),
        "tokenAddress": MessageLookupByLibrary.simpleMessage("Token address"),
        "tokenCountEvolution":
            MessageLookupByLibrary.simpleMessage("Token Count Evolution"),
        "tokenDistribution":
            MessageLookupByLibrary.simpleMessage("Token Distribution"),
        "tokenDistributionByCity":
            MessageLookupByLibrary.simpleMessage("Token Distribution by City"),
        "tokenDistributionByCountry": MessageLookupByLibrary.simpleMessage(
            "Token Distribution by Country"),
        "tokenDistributionByProductType": MessageLookupByLibrary.simpleMessage(
            "Token Distribution by Product Type"),
        "tokenDistributionByRegion": MessageLookupByLibrary.simpleMessage(
            "Token Distribution by Region"),
        "tokenDistributionByWallet": MessageLookupByLibrary.simpleMessage(
            "Token Distribution by Wallet"),
        "tokenHistory": MessageLookupByLibrary.simpleMessage("Token History"),
        "tokenNotWhitelisted":
            MessageLookupByLibrary.simpleMessage("Token not whitelisted"),
        "tokenPrice": MessageLookupByLibrary.simpleMessage("Token Price"),
        "tokenSymbol": MessageLookupByLibrary.simpleMessage("Token symbol"),
        "tokenTypeTitle": MessageLookupByLibrary.simpleMessage("Token Type"),
        "tokenWhitelisted":
            MessageLookupByLibrary.simpleMessage("Token whitelisted"),
        "token_amount": MessageLookupByLibrary.simpleMessage("Token Amount"),
        "token_value": MessageLookupByLibrary.simpleMessage("Token Value"),
        "tokens": MessageLookupByLibrary.simpleMessage("Tokens"),
        "tokensInMap": MessageLookupByLibrary.simpleMessage("Tokens"),
        "toolsTitle": MessageLookupByLibrary.simpleMessage("Tools"),
        "total": MessageLookupByLibrary.simpleMessage("Total"),
        "totalBalance": MessageLookupByLibrary.simpleMessage("Total Balance"),
        "totalCost": MessageLookupByLibrary.simpleMessage("Total Cost"),
        "totalExpenses": MessageLookupByLibrary.simpleMessage("Total Expenses"),
        "totalInvestment":
            MessageLookupByLibrary.simpleMessage("Total investment"),
        "totalPortfolio":
            MessageLookupByLibrary.simpleMessage("Total Portfolio"),
        "totalProperties":
            MessageLookupByLibrary.simpleMessage("Total Properties"),
        "totalRent": MessageLookupByLibrary.simpleMessage("Total rent"),
        "totalRentReceived":
            MessageLookupByLibrary.simpleMessage("Total of revenues"),
        "totalRevenue": MessageLookupByLibrary.simpleMessage("Total Revenue"),
        "totalTokens": MessageLookupByLibrary.simpleMessage("Total Tokens"),
        "totalTokensLabel":
            MessageLookupByLibrary.simpleMessage("Total tokens"),
        "totalUnits": MessageLookupByLibrary.simpleMessage("Total units"),
        "totalValue": MessageLookupByLibrary.simpleMessage("Total Value"),
        "transactionAnalysis":
            MessageLookupByLibrary.simpleMessage("Transaction Analysis"),
        "transactionCount":
            MessageLookupByLibrary.simpleMessage("Transaction Count"),
        "transactionHistory":
            MessageLookupByLibrary.simpleMessage("Transaction History"),
        "transactionType":
            MessageLookupByLibrary.simpleMessage("Transaction Type"),
        "transactionVolume":
            MessageLookupByLibrary.simpleMessage("Transaction Volume"),
        "unavailable": MessageLookupByLibrary.simpleMessage("Unavailable"),
        "underlyingAssetPrice":
            MessageLookupByLibrary.simpleMessage("Asset price"),
        "unit": MessageLookupByLibrary.simpleMessage("unit"),
        "unitesLouees": m16,
        "units": MessageLookupByLibrary.simpleMessage("units"),
        "unknown": MessageLookupByLibrary.simpleMessage("Unknown"),
        "unknownCity": MessageLookupByLibrary.simpleMessage("Unknown City"),
        "unknownCountry":
            MessageLookupByLibrary.simpleMessage("Unknown country"),
        "unknownDate": MessageLookupByLibrary.simpleMessage("Unknown date"),
        "unknownRegion": MessageLookupByLibrary.simpleMessage("Unknown Region"),
        "unknownToken": MessageLookupByLibrary.simpleMessage("Unknown token"),
        "unknownTokenName":
            MessageLookupByLibrary.simpleMessage("Unknown name"),
        "unknownTransaction":
            MessageLookupByLibrary.simpleMessage("Unknown transaction"),
        "unlinkedAddressesHeader":
            MessageLookupByLibrary.simpleMessage("Unlinked addresses"),
        "usdcBorrowBalance":
            MessageLookupByLibrary.simpleMessage("USDC Borrow Balance"),
        "usdcDepositBalance":
            MessageLookupByLibrary.simpleMessage("USDC Deposit Balance"),
        "verifyingAuthentication":
            MessageLookupByLibrary.simpleMessage("Verifying authentication..."),
        "version": MessageLookupByLibrary.simpleMessage("Version"),
        "viewOnMap": MessageLookupByLibrary.simpleMessage("View on map"),
        "viewOnRealT": MessageLookupByLibrary.simpleMessage("View on MeProp"),
        "wallet": MessageLookupByLibrary.simpleMessage("Wallet"),
        "walletAddress": MessageLookupByLibrary.simpleMessage("Wallet address"),
        "walletBalanceHistory":
            MessageLookupByLibrary.simpleMessage("Wallet Balance History"),
        "walletDetails": MessageLookupByLibrary.simpleMessage("Wallet Details"),
        "walletHeader": MessageLookupByLibrary.simpleMessage("Wallets"),
        "walletSaved": m17,
        "wallets": MessageLookupByLibrary.simpleMessage("Wallets"),
        "walletsContainingToken": MessageLookupByLibrary.simpleMessage(
            "Wallets containing this token"),
        "walletsWithoutRmmUsage":
            MessageLookupByLibrary.simpleMessage("Wallets without RMM usage"),
        "week": MessageLookupByLibrary.simpleMessage("Week"),
        "weekly": MessageLookupByLibrary.simpleMessage("Weekly"),
        "weeks": MessageLookupByLibrary.simpleMessage("Weeks"),
        "whitelistInfoContent": MessageLookupByLibrary.simpleMessage(
            "If your token is whitelisted, you can purchase on the secondary market.\n\nIf your token is not whitelisted, you cannot purchase on the secondary market.\n\nYou can request whitelist in your personal space on relationnel.co."),
        "whitelistInfoTitle":
            MessageLookupByLibrary.simpleMessage("Whitelist Information"),
        "whitelisted": MessageLookupByLibrary.simpleMessage("Whitelisted"),
        "wiki_community_description": MessageLookupByLibrary.simpleMessage(
            "Resources and tutorials for the MeProp community."),
        "xdaiBorrowBalance":
            MessageLookupByLibrary.simpleMessage("XDAI Borrow Balance"),
        "xdaiDepositBalance":
            MessageLookupByLibrary.simpleMessage("XDAI Deposit Balance"),
        "yam": MessageLookupByLibrary.simpleMessage("YAM"),
        "yamHistory": MessageLookupByLibrary.simpleMessage("Yam history"),
        "yamHistoryHeader": MessageLookupByLibrary.simpleMessage("YAM History"),
        "yamProjectionDescription":
            MessageLookupByLibrary.simpleMessage("Portfolio projection by YAM"),
        "yam_description": MessageLookupByLibrary.simpleMessage(
            "Management tool for the MeProp investors\' community."),
        "year": MessageLookupByLibrary.simpleMessage("Year"),
        "yesWithPleasure":
            MessageLookupByLibrary.simpleMessage("Yes, with pleasure"),
        "yesterday": MessageLookupByLibrary.simpleMessage("Yesterday"),
        "yieldEvolution":
            MessageLookupByLibrary.simpleMessage("Yield evolution"),
        "yieldEvolutionPercentage":
            MessageLookupByLibrary.simpleMessage("Yield evolution:"),
        "yourAvailableTokens":
            MessageLookupByLibrary.simpleMessage("Your Available Tokens")
      };
}
