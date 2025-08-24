// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a it locale. All the
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
  String get localeName => 'it';

  static String m2(days) => "${days} giorni fa";

  static String m3(days) => "+${days} g";

  static String m4(biometricType) =>
      "Il tuo dispositivo supporta ${biometricType}";

  static String m5(error) => "Errore durante il test: ${error}";

  static String m6(error) => "Errore: ${error}";

  static String m8(language) => "Lingua aggiornata a ${language}";

  static String m9(days) => "Prossimo RONday tra ${days} giorni";

  static String m10(count, name, price) =>
      "Hai acquistato con successo ${count} token di ${name} per ${price}.";

  static String m11(rented, total) => "Unità affittate";

  static String m12(weeks) => "ROI: ${weeks} settimane";

  static String m15(theme) => "Tema aggiornato a ${theme}";

  static String m17(address) => "Portafoglio salvato: ${address}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "about": MessageLookupByLibrary.simpleMessage("Informazioni"),
        "aboutImportExport": MessageLookupByLibrary.simpleMessage(
            "Questa funzione consente di salvare e reimportare i dati storici dei saldi (portafoglio e RMM) in un file ZIP."),
        "aboutImportExportTitle": MessageLookupByLibrary.simpleMessage(
            "Funzione di Importazione/Esportazione"),
        "addAddress":
            MessageLookupByLibrary.simpleMessage("Aggiungi indirizzo"),
        "addressCopied": MessageLookupByLibrary.simpleMessage(
            "Indirizzo copiato negli appunti"),
        "adjustments": MessageLookupByLibrary.simpleMessage("Aggiustamenti"),
        "advanced": MessageLookupByLibrary.simpleMessage("Avanzato"),
        "all": MessageLookupByLibrary.simpleMessage("Tutti"),
        "allChanges":
            MessageLookupByLibrary.simpleMessage("Tutti i\ncambiamenti"),
        "allCities": MessageLookupByLibrary.simpleMessage("Tutte le città"),
        "allCountries": MessageLookupByLibrary.simpleMessage("Tutti i paesi"),
        "allProductTypes": MessageLookupByLibrary.simpleMessage("Tutti tipi"),
        "allRegions": MessageLookupByLibrary.simpleMessage("Tutte le regioni"),
        "allWallets": MessageLookupByLibrary.simpleMessage("Tutti wallets"),
        "allWorkCorrectly": MessageLookupByLibrary.simpleMessage(
            "Tutto funziona correttamente"),
        "all_data": MessageLookupByLibrary.simpleMessage("Tutti i Dati"),
        "amount": MessageLookupByLibrary.simpleMessage("Importo"),
        "analytics": MessageLookupByLibrary.simpleMessage("Analisi"),
        "annualPercentageYield":
            MessageLookupByLibrary.simpleMessage("Rendimento annuale"),
        "annualYield": MessageLookupByLibrary.simpleMessage("Rendimento netto"),
        "annually": MessageLookupByLibrary.simpleMessage("Annuale"),
        "appDescription":
            MessageLookupByLibrary.simpleMessage("app mobile per la comunità"),
        "appName": MessageLookupByLibrary.simpleMessage("MeProp Asset Tracker"),
        "appTitle":
            MessageLookupByLibrary.simpleMessage("MeProp Asset Tracker"),
        "appearance": MessageLookupByLibrary.simpleMessage("Aspetto"),
        "application": MessageLookupByLibrary.simpleMessage("Applicazione"),
        "applyProductTypes": MessageLookupByLibrary.simpleMessage("Applicare"),
        "applyWallets": MessageLookupByLibrary.simpleMessage("Applicare"),
        "apy": MessageLookupByLibrary.simpleMessage("Rendimento annuo"),
        "apyHistory": MessageLookupByLibrary.simpleMessage("Storico APY"),
        "areYouSureClearData": MessageLookupByLibrary.simpleMessage(
            "Sei sicuro di voler cancellare cache e dati?"),
        "ascending": MessageLookupByLibrary.simpleMessage("Crescente"),
        "assetPrice":
            MessageLookupByLibrary.simpleMessage("Prezzo dell\'asset"),
        "assets": MessageLookupByLibrary.simpleMessage("Attività"),
        "author": MessageLookupByLibrary.simpleMessage("Autore"),
        "autoSync":
            MessageLookupByLibrary.simpleMessage("Sincronizzazione automatica"),
        "auto_mode": MessageLookupByLibrary.simpleMessage("Auto"),
        "availableTokens":
            MessageLookupByLibrary.simpleMessage("Token disponibili"),
        "averageApy": MessageLookupByLibrary.simpleMessage("Rendimento medio"),
        "averageROI": MessageLookupByLibrary.simpleMessage("ROI Medio"),
        "balance": MessageLookupByLibrary.simpleMessage("Saldo"),
        "barChart": MessageLookupByLibrary.simpleMessage("Grafico a barre"),
        "bedroomBath": MessageLookupByLibrary.simpleMessage("Camera/Bagno"),
        "biometricAuthSuccessful": MessageLookupByLibrary.simpleMessage(
            "Autenticazione biometrica attivata con successo"),
        "biometricAuthentication":
            MessageLookupByLibrary.simpleMessage("Autenticazione biometrica"),
        "biometricAuthenticationDisabled": MessageLookupByLibrary.simpleMessage(
            "Autenticazione biometrica disattivata"),
        "biometricError": MessageLookupByLibrary.simpleMessage(
            "Errore: Impossibile verificare la biometria"),
        "biometricsNotAvailable":
            MessageLookupByLibrary.simpleMessage("Biometria non disponibile"),
        "blockchain": MessageLookupByLibrary.simpleMessage("Blockchain"),
        "borrowBalance": MessageLookupByLibrary.simpleMessage("Prestiti"),
        "brute": MessageLookupByLibrary.simpleMessage("Lordo"),
        "buy": MessageLookupByLibrary.simpleMessage("Acquistare"),
        "buy_token": MessageLookupByLibrary.simpleMessage("Acquista"),
        "calendar": MessageLookupByLibrary.simpleMessage("Calendario"),
        "cancel": MessageLookupByLibrary.simpleMessage("Annulla"),
        "cannotSellProperty": MessageLookupByLibrary.simpleMessage(
            "Impossibile Vendere la Proprietà"),
        "changelog":
            MessageLookupByLibrary.simpleMessage("Registro delle modifiche"),
        "characteristics":
            MessageLookupByLibrary.simpleMessage("Caratteristiche"),
        "chartType": MessageLookupByLibrary.simpleMessage("Tipo di grafico"),
        "checkingBiometricCapabilities": MessageLookupByLibrary.simpleMessage(
            "Verifica delle capacità biometriche..."),
        "chinese": MessageLookupByLibrary.simpleMessage("中文"),
        "choice_all": MessageLookupByLibrary.simpleMessage("Tutti"),
        "choice_buy": MessageLookupByLibrary.simpleMessage("Compra"),
        "choice_sell": MessageLookupByLibrary.simpleMessage("Vendi"),
        "city": MessageLookupByLibrary.simpleMessage("Città"),
        "clearCacheData":
            MessageLookupByLibrary.simpleMessage("Cancella Cache/Dati"),
        "close": MessageLookupByLibrary.simpleMessage("Chiudi"),
        "commercial": MessageLookupByLibrary.simpleMessage("Commerciale"),
        "completeHistory":
            MessageLookupByLibrary.simpleMessage("Cronologia\nCompleta"),
        "condominium": MessageLookupByLibrary.simpleMessage("Condominio"),
        "configureInSystemSettings": MessageLookupByLibrary.simpleMessage(
            "Configura nelle impostazioni di sistema"),
        "confirm": MessageLookupByLibrary.simpleMessage("Conferma"),
        "confirmAction":
            MessageLookupByLibrary.simpleMessage("Conferma azione"),
        "confirmPurchase":
            MessageLookupByLibrary.simpleMessage("Conferma acquisto"),
        "connectBeforeSync": MessageLookupByLibrary.simpleMessage(
            "Connettiti a Google Drive prima della sincronizzazione"),
        "connectBeforeSyncMessage": MessageLookupByLibrary.simpleMessage(
            "Connettiti a Google Drive prima della sincronizzazione"),
        "connected": MessageLookupByLibrary.simpleMessage("Connesso"),
        "constructionYear":
            MessageLookupByLibrary.simpleMessage("Anno di costruzione"),
        "contractType":
            MessageLookupByLibrary.simpleMessage("Tipo di contratto"),
        "convertSqft":
            MessageLookupByLibrary.simpleMessage("Converti sqft in m²"),
        "copy": MessageLookupByLibrary.simpleMessage("Copia"),
        "copyAddress": MessageLookupByLibrary.simpleMessage("Copia indirizzo"),
        "country": MessageLookupByLibrary.simpleMessage("Paese"),
        "creation_date":
            MessageLookupByLibrary.simpleMessage("Data di creazione"),
        "crypto": MessageLookupByLibrary.simpleMessage("Criptovaluta"),
        "cryptoDonation":
            MessageLookupByLibrary.simpleMessage("Oppure dona in cripto:"),
        "cryptoDonationAddress": MessageLookupByLibrary.simpleMessage(
            "Indirizzo per le donazioni in criptovaluta"),
        "cumulativeRentGraph":
            MessageLookupByLibrary.simpleMessage("affitti cumulativi"),
        "currency": MessageLookupByLibrary.simpleMessage("Valuta"),
        "current_price":
            MessageLookupByLibrary.simpleMessage("Prezzo Attuale:"),
        "current_yield":
            MessageLookupByLibrary.simpleMessage("Rendimento Attuale:"),
        "daily": MessageLookupByLibrary.simpleMessage("Giornaliero"),
        "dao_description": MessageLookupByLibrary.simpleMessage(
            "Forum per proposte e discussioni di MeProp DAO"),
        "dark": MessageLookupByLibrary.simpleMessage("Scuro"),
        "darkTheme": MessageLookupByLibrary.simpleMessage("Tema scuro"),
        "dashboard": MessageLookupByLibrary.simpleMessage("Cruscotto"),
        "dataBackup": MessageLookupByLibrary.simpleMessage("Backup dei dati"),
        "date": MessageLookupByLibrary.simpleMessage("Data"),
        "dateNotCommunicated":
            MessageLookupByLibrary.simpleMessage("Data non comunicata"),
        "day": MessageLookupByLibrary.simpleMessage("Giorno"),
        "days": MessageLookupByLibrary.simpleMessage("Giorni"),
        "daysAgo": m2,
        "daysLimit": MessageLookupByLibrary.simpleMessage("Limite di giorni"),
        "daysShort": m3,
        "delete": MessageLookupByLibrary.simpleMessage("Elimina"),
        "delta_price":
            MessageLookupByLibrary.simpleMessage("Differenza di prezzo"),
        "depositBalance": MessageLookupByLibrary.simpleMessage("Depositi"),
        "deposits": MessageLookupByLibrary.simpleMessage("Depositi"),
        "depositsAndLoans":
            MessageLookupByLibrary.simpleMessage("Depositi e Prestiti"),
        "descending": MessageLookupByLibrary.simpleMessage("Decrescente"),
        "details": MessageLookupByLibrary.simpleMessage("Dettagli"),
        "deviceDoesNotSupport": MessageLookupByLibrary.simpleMessage(
            "Il tuo dispositivo non supporta l\'autenticazione biometrica o nessun dato biometrico è registrato nelle impostazioni del dispositivo."),
        "deviceDoesNotSupportBiometric": MessageLookupByLibrary.simpleMessage(
            "Il tuo dispositivo non supporta l\'autenticazione biometrica"),
        "deviceSupportsBiometric": m4,
        "display_period":
            MessageLookupByLibrary.simpleMessage("Periodo di Visualizzazione"),
        "donate": MessageLookupByLibrary.simpleMessage("Donare"),
        "donationMessage": MessageLookupByLibrary.simpleMessage(
            "Se ti piace questa app e vuoi supportare il suo sviluppo, puoi donare."),
        "donationTotal":
            MessageLookupByLibrary.simpleMessage("Totale delle donazioni"),
        "drawerAccounts": MessageLookupByLibrary.simpleMessage("Conti"),
        "drawerFeatures": MessageLookupByLibrary.simpleMessage("Funzionalità"),
        "drawerSupportAndSettings":
            MessageLookupByLibrary.simpleMessage("Supporto e Impostazioni"),
        "duplex": MessageLookupByLibrary.simpleMessage("Duplex"),
        "duplicate": MessageLookupByLibrary.simpleMessage(
            "Proprietà presenti in più portafogli/RMM"),
        "duplicate_title":
            MessageLookupByLibrary.simpleMessage("Proprietà duplicate"),
        "edit": MessageLookupByLibrary.simpleMessage("Modifica"),
        "editWalletBalance":
            MessageLookupByLibrary.simpleMessage("Modifica Storico del Wallet"),
        "enableBiometricAuthentication": MessageLookupByLibrary.simpleMessage(
            "Attiva l\'autenticazione biometrica"),
        "english": MessageLookupByLibrary.simpleMessage("English"),
        "enterAmount":
            MessageLookupByLibrary.simpleMessage("Inserisci l\'importo"),
        "enterValidNumber": MessageLookupByLibrary.simpleMessage(
            "Per favore, inserisci un numero valido"),
        "errorDuringTest": m5,
        "errorLoadingData": MessageLookupByLibrary.simpleMessage(
            "Errore nel caricamento dei dati"),
        "error_occurred": m6,
        "ethereumContract":
            MessageLookupByLibrary.simpleMessage("Contratto Ethereum"),
        "everyContributionCounts":
            MessageLookupByLibrary.simpleMessage("Ogni contributo conta 🙏"),
        "expectedYield":
            MessageLookupByLibrary.simpleMessage("Rendimento atteso"),
        "exportAllTransactionsCsv": MessageLookupByLibrary.simpleMessage(
            "Esporta tutte le transazioni in CSV"),
        "exportAllTransactionsDescription": MessageLookupByLibrary.simpleMessage(
            "Puoi esportare tutte le tue transazioni (acquisti, trasferimenti, affitti) in formato CSV per analisi o archiviazione."),
        "exportAllTransactionsTitle": MessageLookupByLibrary.simpleMessage(
            "Esporta tutte le transazioni"),
        "exportButton": MessageLookupByLibrary.simpleMessage("Esportare"),
        "exportData": MessageLookupByLibrary.simpleMessage("Esporta dati"),
        "exportFailed":
            MessageLookupByLibrary.simpleMessage("Esportazione dati fallita"),
        "exportRentsCsv":
            MessageLookupByLibrary.simpleMessage("Esporta affitti in CSV"),
        "exportRentsDescription": MessageLookupByLibrary.simpleMessage(
            "Puoi esportare la cronologia dei tuoi affitti in formato CSV per utilizzarla in un foglio di calcolo o per le tue dichiarazioni."),
        "exportRentsTitle":
            MessageLookupByLibrary.simpleMessage("Esporta affitti"),
        "exportSuccess":
            MessageLookupByLibrary.simpleMessage("Dati esportati con successo"),
        "feedback": MessageLookupByLibrary.simpleMessage("Feedback"),
        "filterNotInWallet":
            MessageLookupByLibrary.simpleMessage("Non nel portafoglio"),
        "filterOptions":
            MessageLookupByLibrary.simpleMessage("Opzioni di Filtro"),
        "filter_all": MessageLookupByLibrary.simpleMessage("Tutto"),
        "filter_buy": MessageLookupByLibrary.simpleMessage("Acquisto"),
        "filter_sell": MessageLookupByLibrary.simpleMessage("Vendita"),
        "finances": MessageLookupByLibrary.simpleMessage("Finanze"),
        "french": MessageLookupByLibrary.simpleMessage("Francais"),
        "fullyRented":
            MessageLookupByLibrary.simpleMessage("Completamente Affittato"),
        "futureRents": MessageLookupByLibrary.simpleMessage("Affitti futuri"),
        "gDriveConnection":
            MessageLookupByLibrary.simpleMessage("Connessione a Google Drive"),
        "gnosisContract":
            MessageLookupByLibrary.simpleMessage("Contratto Gnosis"),
        "googleDriveConnection":
            MessageLookupByLibrary.simpleMessage("Connessione Google Drive"),
        "googleDriveTitle":
            MessageLookupByLibrary.simpleMessage("Google Drive"),
        "gridView": MessageLookupByLibrary.simpleMessage("Griglia"),
        "grossRentMonth":
            MessageLookupByLibrary.simpleMessage("Affitto lordo al mese"),
        "groupedRentGraph": MessageLookupByLibrary.simpleMessage("Affitti"),
        "healthFactorSafer": MessageLookupByLibrary.simpleMessage(
            "Health Factor: Più alto = Più sicuro"),
        "hello": MessageLookupByLibrary.simpleMessage("Ciao"),
        "hf": MessageLookupByLibrary.simpleMessage("HF"),
        "historyDays":
            MessageLookupByLibrary.simpleMessage("Cronologia (giorni)"),
        "hours": MessageLookupByLibrary.simpleMessage("Ore"),
        "importButton": MessageLookupByLibrary.simpleMessage("Importare"),
        "importData": MessageLookupByLibrary.simpleMessage("Importa dati"),
        "importExportData": MessageLookupByLibrary.simpleMessage(
            "Importa o esporta dati (zip)"),
        "importFailed":
            MessageLookupByLibrary.simpleMessage("Importazione dati fallita"),
        "importSuccess":
            MessageLookupByLibrary.simpleMessage("Dati importati con successo"),
        "initialLaunchDate":
            MessageLookupByLibrary.simpleMessage("Data di lancio iniziale"),
        "initialMaintenanceReserve":
            MessageLookupByLibrary.simpleMessage("Riserva di manutenzione"),
        "initialPrice":
            MessageLookupByLibrary.simpleMessage("Prezzo medio d\'acquisto"),
        "initialPriceModified_description": MessageLookupByLibrary.simpleMessage(
            "Valore del token al prezzo medio al quale lo hai ottenuto. Questo prezzo sarà preso in considerazione per il calcolo del ROI, tra le altre cose."),
        "initialPriceRemoved": MessageLookupByLibrary.simpleMessage(
            "Prezzo medio d\'acquisto rimosso"),
        "initialPriceUpdated": MessageLookupByLibrary.simpleMessage(
            "Prezzo medio d\'acquisto aggiornato"),
        "insights": MessageLookupByLibrary.simpleMessage("Approfondimenti"),
        "insurance": MessageLookupByLibrary.simpleMessage("Assicurazione"),
        "internal_transfer":
            MessageLookupByLibrary.simpleMessage("Trasferimento interno"),
        "invalidCoordinates": MessageLookupByLibrary.simpleMessage(
            "Coordinate non valide per la proprietà"),
        "invalidDataForChart": MessageLookupByLibrary.simpleMessage(
            "Dati non validi per la visualizzazione del grafico"),
        "invalidWalletAddress": MessageLookupByLibrary.simpleMessage(
            "Indirizzo del portafoglio non valido"),
        "invalidWalletInQR": MessageLookupByLibrary.simpleMessage(
            "Portafoglio non valido nel codice QR"),
        "investment": MessageLookupByLibrary.simpleMessage("Investimento"),
        "italian": MessageLookupByLibrary.simpleMessage("Italiano"),
        "language": MessageLookupByLibrary.simpleMessage("Lingua"),
        "languageUpdated": m8,
        "lastExecution":
            MessageLookupByLibrary.simpleMessage("Ultimo aggiornamento"),
        "lastRentReceived": MessageLookupByLibrary.simpleMessage(
            "Il tuo ultimo affitto ricevuto"),
        "last_update":
            MessageLookupByLibrary.simpleMessage("Ultimo aggiornamento:"),
        "legend": MessageLookupByLibrary.simpleMessage("Legenda"),
        "light": MessageLookupByLibrary.simpleMessage("Chiaro"),
        "light_mode": MessageLookupByLibrary.simpleMessage("Chiaro"),
        "lineChart": MessageLookupByLibrary.simpleMessage("Grafico a linee"),
        "links": MessageLookupByLibrary.simpleMessage("Collegamenti"),
        "listView": MessageLookupByLibrary.simpleMessage("Lista"),
        "loans": MessageLookupByLibrary.simpleMessage("Prestiti"),
        "localStorage":
            MessageLookupByLibrary.simpleMessage("Archiviazione locale"),
        "lotSize": MessageLookupByLibrary.simpleMessage("Superficie del lotto"),
        "ltv": MessageLookupByLibrary.simpleMessage("LTV"),
        "ltvSafer":
            MessageLookupByLibrary.simpleMessage("LTV: Più basso = Più sicuro"),
        "manageAddresses":
            MessageLookupByLibrary.simpleMessage("Aggiungi portafoglio"),
        "manageEvmAddresses":
            MessageLookupByLibrary.simpleMessage("Gestisci Portafogli"),
        "manualEdit": MessageLookupByLibrary.simpleMessage("Modifica Manuale"),
        "maps": MessageLookupByLibrary.simpleMessage("Mappe"),
        "mfrPortfolio": MessageLookupByLibrary.simpleMessage("Portafoglio MFR"),
        "miscellaneousCosts":
            MessageLookupByLibrary.simpleMessage("Costi Vari"),
        "mixedUse": MessageLookupByLibrary.simpleMessage("Uso misto"),
        "modification": MessageLookupByLibrary.simpleMessage("modifica"),
        "modifications": MessageLookupByLibrary.simpleMessage("modifiche"),
        "month": MessageLookupByLibrary.simpleMessage("Mese"),
        "monthly": MessageLookupByLibrary.simpleMessage("Mensile"),
        "months12": MessageLookupByLibrary.simpleMessage("12 Mesi"),
        "months3": MessageLookupByLibrary.simpleMessage("3 Mesi"),
        "months6": MessageLookupByLibrary.simpleMessage("6 Mesi"),
        "multiFamily": MessageLookupByLibrary.simpleMessage("Multifamiliare"),
        "nameUnavailable":
            MessageLookupByLibrary.simpleMessage("Nome non disponibile"),
        "net": MessageLookupByLibrary.simpleMessage("Netto"),
        "netAnnualRent":
            MessageLookupByLibrary.simpleMessage("Affitto netto annuale"),
        "netApy": MessageLookupByLibrary.simpleMessage("APY Netto"),
        "netApyHelp": MessageLookupByLibrary.simpleMessage(
            "Il rendimento netto viene calcolato ponderando i rendimenti dei portafogli (wallet/RMM) e i saldi di deposito/prestito con i rispettivi tassi."),
        "netRentMonth":
            MessageLookupByLibrary.simpleMessage("Affitto netto al mese"),
        "network": MessageLookupByLibrary.simpleMessage("Rete"),
        "newValue": MessageLookupByLibrary.simpleMessage("Nuovo:"),
        "newVersionAvailable":
            MessageLookupByLibrary.simpleMessage("Nuova versione disponibile"),
        "new_yield": MessageLookupByLibrary.simpleMessage("Nuovo Rendimento:"),
        "nextRondayInDays": m9,
        "nextRondays": MessageLookupByLibrary.simpleMessage("Prossimi Rondays"),
        "noChangesFoundInCompleteHistory": MessageLookupByLibrary.simpleMessage(
            "Nessun cambiamento trovato nella cronologia completa"),
        "noChangesFoundInPastYear": MessageLookupByLibrary.simpleMessage(
            "Nessun cambiamento trovato nell\'ultimo anno"),
        "noCommunicatedDate":
            MessageLookupByLibrary.simpleMessage("Data non fornita"),
        "noDataAvailable": MessageLookupByLibrary.simpleMessage(
            "Nessun dato disponibile, per favore aggiungi un nuovo portafoglio"),
        "noFutureRents":
            MessageLookupByLibrary.simpleMessage("Nessun affitto futuro"),
        "noImageAvailable": MessageLookupByLibrary.simpleMessage(
            "Link immagine non disponibile"),
        "noPriceEvolution": MessageLookupByLibrary.simpleMessage(
            "Nessuna evoluzione del prezzo. L\'ultimo prezzo è:"),
        "noPropertiesForSale": MessageLookupByLibrary.simpleMessage(
            "Nessuna proprietà in vendita"),
        "noRecentUpdates": MessageLookupByLibrary.simpleMessage(
            "Nessun cambiamento recente disponibile."),
        "noRentDataAvailable": MessageLookupByLibrary.simpleMessage(
            "Nessun dato di affitto disponibile."),
        "noRentDataToShare": MessageLookupByLibrary.simpleMessage(
            "Nessun dato di affitto da condividere."),
        "noRentReceived":
            MessageLookupByLibrary.simpleMessage("Nessun affitto ricevuto"),
        "noScheduledRonday":
            MessageLookupByLibrary.simpleMessage("Nessun RONday programmato"),
        "noTokensAvailable":
            MessageLookupByLibrary.simpleMessage("Nessun token disponibile"),
        "noTokensFound":
            MessageLookupByLibrary.simpleMessage("Nessun token trovato"),
        "noTokensOwned": MessageLookupByLibrary.simpleMessage(
            "Non possiedi alcun token di questa proprietà."),
        "noTokensWithValidCoordinates": MessageLookupByLibrary.simpleMessage(
            "Nessun token con coordinate valide trovato sulla mappa"),
        "noTransactionOrRentToExport": MessageLookupByLibrary.simpleMessage(
            "Nessuna transazione o affitto da esportare."),
        "noTransactionsAvailable": MessageLookupByLibrary.simpleMessage(
            "Nessuna transazione disponibile"),
        "noWalletMessage": MessageLookupByLibrary.simpleMessage(
            "Per utilizzare l\'applicazione, devi prima aggiungere almeno un indirizzo di wallet Ethereum."),
        "noYieldEvolution": MessageLookupByLibrary.simpleMessage(
            "Nessuna evoluzione del rendimento. L\'ultimo rendimento è:"),
        "no_market_offers_available": MessageLookupByLibrary.simpleMessage(
            "Nessuna offerta di mercato disponibile"),
        "notAvailable": MessageLookupByLibrary.simpleMessage("N/A"),
        "notConnected": MessageLookupByLibrary.simpleMessage("Non connesso"),
        "notRented": MessageLookupByLibrary.simpleMessage("Non Affittato"),
        "notSpecified": MessageLookupByLibrary.simpleMessage("Non specificato"),
        "not_whitelisted_warning": MessageLookupByLibrary.simpleMessage(
            "Token non autorizzato, offerta disabilitata"),
        "notifications": MessageLookupByLibrary.simpleMessage("Notifiche"),
        "numberOfTokens":
            MessageLookupByLibrary.simpleMessage("Numero di token"),
        "offer_id": MessageLookupByLibrary.simpleMessage("ID Offerta"),
        "offer_price": MessageLookupByLibrary.simpleMessage("Prezzo Offerta:"),
        "offering": MessageLookupByLibrary.simpleMessage("Offerta"),
        "offers_list_header":
            MessageLookupByLibrary.simpleMessage("Elenco delle Offerte"),
        "ok": MessageLookupByLibrary.simpleMessage("OK"),
        "old": MessageLookupByLibrary.simpleMessage("Precedente:"),
        "other": MessageLookupByLibrary.simpleMessage("Altro"),
        "others": MessageLookupByLibrary.simpleMessage("Altri"),
        "othersTitle": MessageLookupByLibrary.simpleMessage(
            "Dettagli della sezione Altri"),
        "ownedTokens": MessageLookupByLibrary.simpleMessage("Token Posseduti"),
        "partiallyRented":
            MessageLookupByLibrary.simpleMessage("Parzialmente Affittato"),
        "paypal": MessageLookupByLibrary.simpleMessage("PayPal"),
        "performanceByRegion":
            MessageLookupByLibrary.simpleMessage("Performance per Regione"),
        "period": MessageLookupByLibrary.simpleMessage("Periodo"),
        "personalization":
            MessageLookupByLibrary.simpleMessage("Personalizzazione"),
        "portfolio": MessageLookupByLibrary.simpleMessage("Portafoglio"),
        "portfolioGlobal":
            MessageLookupByLibrary.simpleMessage("Portafoglio Globale"),
        "portuguese": MessageLookupByLibrary.simpleMessage("Português"),
        "presentInWallet":
            MessageLookupByLibrary.simpleMessage("Presente nel portafoglio"),
        "price": MessageLookupByLibrary.simpleMessage("Prezzo"),
        "priceEvolution":
            MessageLookupByLibrary.simpleMessage("Evoluzione del prezzo"),
        "priceEvolutionPercentage":
            MessageLookupByLibrary.simpleMessage("Evoluzione del prezzo:"),
        "productTypeFactoringProfitshare": MessageLookupByLibrary.simpleMessage(
            "Condivisione Profitti Factoring"),
        "productTypeHeader":
            MessageLookupByLibrary.simpleMessage("Tipi di prodotto"),
        "productTypeLoanIncome":
            MessageLookupByLibrary.simpleMessage("Reddito da Prestito"),
        "productTypeOther": MessageLookupByLibrary.simpleMessage("Altro"),
        "productTypeRealEstateRental":
            MessageLookupByLibrary.simpleMessage("Affitto Immobiliare"),
        "projection": MessageLookupByLibrary.simpleMessage("proiezione"),
        "properties": MessageLookupByLibrary.simpleMessage("Proprietà"),
        "propertiesBuyThisProperty":
            MessageLookupByLibrary.simpleMessage("Acquista questa proprietà"),
        "propertiesFactoring":
            MessageLookupByLibrary.simpleMessage("Factoring"),
        "propertiesForSale":
            MessageLookupByLibrary.simpleMessage("Proprietà in vendita"),
        "propertiesNoMarketplaceAvailable":
            MessageLookupByLibrary.simpleMessage(
                "La negoziazione non è disponibile per questa proprietà."),
        "propertiesPrice": MessageLookupByLibrary.simpleMessage("Prezzo"),
        "propertiesProperty": MessageLookupByLibrary.simpleMessage("Proprietà"),
        "propertiesStock": MessageLookupByLibrary.simpleMessage("Stock"),
        "propertiesYield": MessageLookupByLibrary.simpleMessage("Rendimento"),
        "properties_for_sale":
            MessageLookupByLibrary.simpleMessage("Proprietà in vendita"),
        "propertyMaintenanceMonthly": MessageLookupByLibrary.simpleMessage(
            "Manutenzione della proprietà (mensile)"),
        "propertyManagement":
            MessageLookupByLibrary.simpleMessage("Gestione della proprietà"),
        "propertyPrice":
            MessageLookupByLibrary.simpleMessage("Prezzo della proprietà"),
        "propertyStories":
            MessageLookupByLibrary.simpleMessage("Numero di piani"),
        "propertyTaxes":
            MessageLookupByLibrary.simpleMessage("Tasse sulla proprietà"),
        "propertyType":
            MessageLookupByLibrary.simpleMessage("Tipo di proprietà"),
        "purchase": MessageLookupByLibrary.simpleMessage("Acquisto"),
        "purchaseConfirmation": m10,
        "purchaseDetails":
            MessageLookupByLibrary.simpleMessage("Dettagli dell\'acquisto"),
        "purchaseSuccessful":
            MessageLookupByLibrary.simpleMessage("Acquisto riuscito"),
        "quantity": MessageLookupByLibrary.simpleMessage("Quantità"),
        "rateApp":
            MessageLookupByLibrary.simpleMessage("Valuta l\'applicazione"),
        "realTPerformance":
            MessageLookupByLibrary.simpleMessage("Performance di MeProp"),
        "realTTitle": MessageLookupByLibrary.simpleMessage("MeProp"),
        "realTokensList":
            MessageLookupByLibrary.simpleMessage("Elenco MeProps"),
        "realt": MessageLookupByLibrary.simpleMessage("MeProp"),
        "realtActualPrice":
            MessageLookupByLibrary.simpleMessage("Prezzo attuale"),
        "realtListingFee":
            MessageLookupByLibrary.simpleMessage("Tassa di Annuncio MeProp"),
        "realtPlatform":
            MessageLookupByLibrary.simpleMessage("Piattaforma MeProp"),
        "realtStats":
            MessageLookupByLibrary.simpleMessage("Statistiche MeProp"),
        "recentChanges":
            MessageLookupByLibrary.simpleMessage("Cambiamenti recenti"),
        "recentUpdatesTitle":
            MessageLookupByLibrary.simpleMessage("Ultimi 30 giorni"),
        "refresh": MessageLookupByLibrary.simpleMessage("Aggiorna"),
        "region": MessageLookupByLibrary.simpleMessage("Regione"),
        "regionFilterLabel": MessageLookupByLibrary.simpleMessage("Regione"),
        "regionHeader": MessageLookupByLibrary.simpleMessage("Regione"),
        "renovationReserve":
            MessageLookupByLibrary.simpleMessage("Fondo di Ristrutturazione"),
        "rentDetailsTitle":
            MessageLookupByLibrary.simpleMessage("Dettagli degli affitti"),
        "rentDistribution":
            MessageLookupByLibrary.simpleMessage("Distribuzione degli affitti"),
        "rentDistributionByProductType": MessageLookupByLibrary.simpleMessage(
            "Distribuzione Affitti per Tipo di Prodotto"),
        "rentDistributionByWallet": MessageLookupByLibrary.simpleMessage(
            "Distribuzione degli affitti per portafoglio"),
        "rentGraph": MessageLookupByLibrary.simpleMessage(
            "Grafico degli affitti ricevuti"),
        "rentNoDataAvailable": MessageLookupByLibrary.simpleMessage(
            "Nessun dato sugli affitti disponibile."),
        "rentNoDataToShare": MessageLookupByLibrary.simpleMessage(
            "Nessun dato sugli affitti da condividere."),
        "rentStartDate": MessageLookupByLibrary.simpleMessage("Primo affitto"),
        "rentStartFuture":
            MessageLookupByLibrary.simpleMessage("Affitto non ancora iniziato"),
        "rentalStatus":
            MessageLookupByLibrary.simpleMessage("Stato dell\'affitto"),
        "rentalStatusAll": MessageLookupByLibrary.simpleMessage("Tutti"),
        "rentalStatusDistribution": MessageLookupByLibrary.simpleMessage(
            "Distribuzione per Stato di Affitto"),
        "rentalStatusNotRented":
            MessageLookupByLibrary.simpleMessage("Non affittato"),
        "rentalStatusPartiallyRented":
            MessageLookupByLibrary.simpleMessage("Parzialmente affittato"),
        "rentalStatusRented": MessageLookupByLibrary.simpleMessage("Affittato"),
        "rentalStatusTitle":
            MessageLookupByLibrary.simpleMessage("Stato di locazione"),
        "rentalType": MessageLookupByLibrary.simpleMessage("Tipo di affitto"),
        "rented": MessageLookupByLibrary.simpleMessage("Affittato"),
        "rentedUnits": m11,
        "rents": MessageLookupByLibrary.simpleMessage("Affitti"),
        "resortBungalow":
            MessageLookupByLibrary.simpleMessage("Bungalow di villeggiatura"),
        "revenue": MessageLookupByLibrary.simpleMessage("Entrate"),
        "rmm": MessageLookupByLibrary.simpleMessage("RMM"),
        "rmmDetails": MessageLookupByLibrary.simpleMessage("Dettagli RMM"),
        "rmmHealth": MessageLookupByLibrary.simpleMessage("Salute RMM"),
        "rmmValue": MessageLookupByLibrary.simpleMessage("Valore RMM"),
        "rmm_description": MessageLookupByLibrary.simpleMessage(
            "Piattaforma per prestare e prendere in prestito utilizzando token immobiliari."),
        "roiAlertInfo": MessageLookupByLibrary.simpleMessage(
            "Questa funzione ROI è in fase beta ed è attualmente calcolata in base ai ricavi ricevuti dalla proprietà e al valore iniziale del token."),
        "roiByToken": MessageLookupByLibrary.simpleMessage("ROI per Token"),
        "roiHistory": MessageLookupByLibrary.simpleMessage("Storico ROI"),
        "roiPerProperties":
            MessageLookupByLibrary.simpleMessage("ROI per proprietà"),
        "roi_label": m12,
        "russian": MessageLookupByLibrary.simpleMessage("Russo"),
        "rwaHoldings": MessageLookupByLibrary.simpleMessage("RWA Holdings SA"),
        "save": MessageLookupByLibrary.simpleMessage("Salva"),
        "scanQRCode":
            MessageLookupByLibrary.simpleMessage("Scansiona codice QR"),
        "searchHint": MessageLookupByLibrary.simpleMessage("Cerca..."),
        "search_hint":
            MessageLookupByLibrary.simpleMessage("Cerca per nome..."),
        "secondary": MessageLookupByLibrary.simpleMessage("Secondario"),
        "secondary_offers_related_to_token":
            MessageLookupByLibrary.simpleMessage("Offerte YAM legate al token"),
        "section8paid": MessageLookupByLibrary.simpleMessage("Sezione 8"),
        "security": MessageLookupByLibrary.simpleMessage("Sicurezza"),
        "sell": MessageLookupByLibrary.simpleMessage("Vendere"),
        "sellThisProperty":
            MessageLookupByLibrary.simpleMessage("Vendi Proprietà"),
        "sell_token": MessageLookupByLibrary.simpleMessage("Vendere"),
        "sendDonations": MessageLookupByLibrary.simpleMessage(
            "Invia le tue donazioni al seguente indirizzo:"),
        "serviceStatus":
            MessageLookupByLibrary.simpleMessage("Stato del servizio"),
        "serviceStatusPage":
            MessageLookupByLibrary.simpleMessage("Stato dei servizi"),
        "settings": MessageLookupByLibrary.simpleMessage("Impostazioni"),
        "settingsCategory":
            MessageLookupByLibrary.simpleMessage("Impostazioni"),
        "settingsTitle": MessageLookupByLibrary.simpleMessage("Impostazioni"),
        "sfrPortfolio": MessageLookupByLibrary.simpleMessage("Portafoglio SFR"),
        "showAll": MessageLookupByLibrary.simpleMessage("Mostra Tutto"),
        "showOnlyWhitelisted":
            MessageLookupByLibrary.simpleMessage("Mostra solo i whitelistati"),
        "showTop10": MessageLookupByLibrary.simpleMessage("Mostra Top 10"),
        "showYamProjection":
            MessageLookupByLibrary.simpleMessage("Mostra proiezione YAM"),
        "singleFamily": MessageLookupByLibrary.simpleMessage("Casa singola"),
        "somethingWrong": MessageLookupByLibrary.simpleMessage(
            "I dati potrebbero non essere aggiornati"),
        "sortBy": MessageLookupByLibrary.simpleMessage("Ordina Per"),
        "sortByAPY":
            MessageLookupByLibrary.simpleMessage("Ordina per rendimento annuo"),
        "sortByCount":
            MessageLookupByLibrary.simpleMessage("Ordina per Numero"),
        "sortByInitialLaunchDate":
            MessageLookupByLibrary.simpleMessage("Ordina per data di aggiunta"),
        "sortByName": MessageLookupByLibrary.simpleMessage("Ordina per nome"),
        "sortByROI": MessageLookupByLibrary.simpleMessage("Ordina per ROI"),
        "sortByValue":
            MessageLookupByLibrary.simpleMessage("Ordina per valore"),
        "sort_ascending": MessageLookupByLibrary.simpleMessage("Crescente"),
        "sort_date": MessageLookupByLibrary.simpleMessage("Data"),
        "sort_delta": MessageLookupByLibrary.simpleMessage("Delta"),
        "sort_descending": MessageLookupByLibrary.simpleMessage("Decrescente"),
        "sort_label": MessageLookupByLibrary.simpleMessage("Ordina:"),
        "spanish": MessageLookupByLibrary.simpleMessage("Español"),
        "specialThanks": MessageLookupByLibrary.simpleMessage(
            "Ringraziamenti speciali a @Sigri, @ehpst e @pitsbi per il loro supporto."),
        "specialThanksJojodunet": MessageLookupByLibrary.simpleMessage(
            "Un ringraziamento speciale a @Jojodunet per la sua tenacia e le ore trascorse a testare e ritestare l\'app!"),
        "squareFeet":
            MessageLookupByLibrary.simpleMessage("Dimensione interna"),
        "statistics": MessageLookupByLibrary.simpleMessage("Statistiche"),
        "street_view": MessageLookupByLibrary.simpleMessage("Vista Strada"),
        "support": MessageLookupByLibrary.simpleMessage("Supporto"),
        "supportProject":
            MessageLookupByLibrary.simpleMessage("Sostieni il progetto"),
        "syncComplete": MessageLookupByLibrary.simpleMessage(
            "Sincronizzazione completata con Google Drive"),
        "syncCompleteWithGoogleDrive": MessageLookupByLibrary.simpleMessage(
            "Sincronizzazione completata con Google Drive"),
        "syncWithGoogleDrive": MessageLookupByLibrary.simpleMessage(
            "Sincronizza con Google Drive"),
        "synchronization":
            MessageLookupByLibrary.simpleMessage("Sincronizzazione"),
        "testAuthenticationReason": MessageLookupByLibrary.simpleMessage(
            "Questo è un test di autenticazione biometrica"),
        "testBiometricAuthentication": MessageLookupByLibrary.simpleMessage(
            "Testa l\'autenticazione biometrica"),
        "testBiometricDescription": MessageLookupByLibrary.simpleMessage(
            "Puoi testare l\'autenticazione biometrica per verificare che funzioni correttamente."),
        "testFailed": MessageLookupByLibrary.simpleMessage(
            "Test fallito. Si prega di riprovare."),
        "testSuccessful": MessageLookupByLibrary.simpleMessage(
            "Test riuscito! L\'autenticazione biometrica funziona correttamente."),
        "testingAuthentication":
            MessageLookupByLibrary.simpleMessage("Test di autenticazione..."),
        "textSize":
            MessageLookupByLibrary.simpleMessage("Dimensione del testo"),
        "thankYouMessage": MessageLookupByLibrary.simpleMessage(
            "Grazie a tutti coloro che hanno contribuito a questo progetto."),
        "thanks": MessageLookupByLibrary.simpleMessage("Grazie"),
        "thanksDonators": MessageLookupByLibrary.simpleMessage(
            "Grazie anche a tutti i donatori che supportano lo sviluppo di questa applicazione!"),
        "themeUpdated": m15,
        "timeBeforeLiquidation":
            MessageLookupByLibrary.simpleMessage("prima della liquidazione"),
        "time_range":
            MessageLookupByLibrary.simpleMessage("Intervallo di Tempo"),
        "timestamp": MessageLookupByLibrary.simpleMessage("Data e ora"),
        "today": MessageLookupByLibrary.simpleMessage("Oggi"),
        "tokenAddress":
            MessageLookupByLibrary.simpleMessage("Indirizzo del token"),
        "tokenCountEvolution": MessageLookupByLibrary.simpleMessage(
            "Evoluzione del Numero di Token"),
        "tokenDistribution": MessageLookupByLibrary.simpleMessage(
            "Distribuzione dei token per tipo di proprietà"),
        "tokenDistributionByCity": MessageLookupByLibrary.simpleMessage(
            "Distribuzione dei token per città"),
        "tokenDistributionByCountry": MessageLookupByLibrary.simpleMessage(
            "Distribuzione dei token per paese"),
        "tokenDistributionByProductType": MessageLookupByLibrary.simpleMessage(
            "Distribuzione Token per Tipo di Prodotto"),
        "tokenDistributionByRegion": MessageLookupByLibrary.simpleMessage(
            "Distribuzione dei token per regione"),
        "tokenHistory":
            MessageLookupByLibrary.simpleMessage("Cronologia token"),
        "tokenNotWhitelisted":
            MessageLookupByLibrary.simpleMessage("Token non whitelistato"),
        "tokenPrice": MessageLookupByLibrary.simpleMessage("Prezzo del token"),
        "tokenSymbol":
            MessageLookupByLibrary.simpleMessage("Simbolo del token"),
        "tokenTypeTitle": MessageLookupByLibrary.simpleMessage("Tipo di token"),
        "tokenWhitelisted":
            MessageLookupByLibrary.simpleMessage("Token whitelistato"),
        "token_amount":
            MessageLookupByLibrary.simpleMessage("Quantità di token"),
        "token_value": MessageLookupByLibrary.simpleMessage("Valore del token"),
        "tokens": MessageLookupByLibrary.simpleMessage("Token"),
        "tokensInMap": MessageLookupByLibrary.simpleMessage("Token"),
        "toolsTitle": MessageLookupByLibrary.simpleMessage("Strumenti"),
        "total": MessageLookupByLibrary.simpleMessage("Totale"),
        "totalBalance": MessageLookupByLibrary.simpleMessage("Saldo Totale"),
        "totalCost": MessageLookupByLibrary.simpleMessage("Costo totale"),
        "totalExpenses": MessageLookupByLibrary.simpleMessage("Spese Totali"),
        "totalInvestment":
            MessageLookupByLibrary.simpleMessage("Investimento totale"),
        "totalPortfolio":
            MessageLookupByLibrary.simpleMessage("Portafoglio Totale"),
        "totalProperties":
            MessageLookupByLibrary.simpleMessage("Totale Proprietà"),
        "totalRent": MessageLookupByLibrary.simpleMessage("Affitto Totale"),
        "totalRentReceived":
            MessageLookupByLibrary.simpleMessage("Totale delle entrate"),
        "totalTokens": MessageLookupByLibrary.simpleMessage("Totale Token"),
        "totalUnits":
            MessageLookupByLibrary.simpleMessage("Numero totale di unità"),
        "totalValue": MessageLookupByLibrary.simpleMessage("Valore totale"),
        "transactionAnalysis":
            MessageLookupByLibrary.simpleMessage("Analisi delle Transazioni"),
        "transactionCount":
            MessageLookupByLibrary.simpleMessage("Numero di Transazioni"),
        "transactionHistory": MessageLookupByLibrary.simpleMessage(
            "Cronologia delle transazioni"),
        "transactionType":
            MessageLookupByLibrary.simpleMessage("Tipo di transazione"),
        "transactionVolume":
            MessageLookupByLibrary.simpleMessage("Volume delle Transazioni"),
        "unavailable": MessageLookupByLibrary.simpleMessage("Non disponibile"),
        "underlyingAssetPrice":
            MessageLookupByLibrary.simpleMessage("Prezzo dell\'asset"),
        "unit": MessageLookupByLibrary.simpleMessage("unità"),
        "units": MessageLookupByLibrary.simpleMessage("unità"),
        "unknown": MessageLookupByLibrary.simpleMessage("Sconosciuto"),
        "unknownCity":
            MessageLookupByLibrary.simpleMessage("Città sconosciuta"),
        "unknownCountry":
            MessageLookupByLibrary.simpleMessage("Paese sconosciuto"),
        "unknownDate": MessageLookupByLibrary.simpleMessage("Data sconosciuta"),
        "unknownToken":
            MessageLookupByLibrary.simpleMessage("Token sconosciuto"),
        "unknownTokenName":
            MessageLookupByLibrary.simpleMessage("Nome sconosciuto"),
        "unknownTransaction":
            MessageLookupByLibrary.simpleMessage("Transazione sconosciuta"),
        "usdcBorrowBalance":
            MessageLookupByLibrary.simpleMessage("Saldo prestiti USDC"),
        "usdcDepositBalance":
            MessageLookupByLibrary.simpleMessage("Saldo depositi USDC"),
        "version": MessageLookupByLibrary.simpleMessage("Versione"),
        "viewOnMap": MessageLookupByLibrary.simpleMessage("Vedi sulla mappa"),
        "viewOnRealT": MessageLookupByLibrary.simpleMessage("Vedi su MeProp"),
        "wallet": MessageLookupByLibrary.simpleMessage("Portafoglio"),
        "walletAddress":
            MessageLookupByLibrary.simpleMessage("Indirizzo del portafoglio"),
        "walletBalanceHistory": MessageLookupByLibrary.simpleMessage(
            "Storico del Saldo del Wallet"),
        "walletDetails":
            MessageLookupByLibrary.simpleMessage("Dettagli del Portafoglio"),
        "walletHeader": MessageLookupByLibrary.simpleMessage("Wallets"),
        "walletSaved": m17,
        "walletsContainingToken": MessageLookupByLibrary.simpleMessage(
            "Portafogli contenenti questo token"),
        "walletsWithoutRmmUsage":
            MessageLookupByLibrary.simpleMessage("Wallet senza utilizzo RMM"),
        "week": MessageLookupByLibrary.simpleMessage("Settimana"),
        "weekly": MessageLookupByLibrary.simpleMessage("Settimanale"),
        "weeks": MessageLookupByLibrary.simpleMessage("Settimane"),
        "whitelistInfoContent": MessageLookupByLibrary.simpleMessage(
            "Se il tuo token è whitelistato, puoi acquistare sul mercato secondario.\n\nSe il tuo token non è whitelistato, non puoi acquistare sul mercato secondario.\n\nPuoi richiedere la whitelist nel tuo spazio personale su relationnel.co."),
        "whitelistInfoTitle": MessageLookupByLibrary.simpleMessage(
            "Informazioni sulla whitelist"),
        "whitelisted": MessageLookupByLibrary.simpleMessage("In Lista Bianca"),
        "wiki_community_description": MessageLookupByLibrary.simpleMessage(
            "Risorse e tutorial per la comunità MeProp."),
        "xdaiBorrowBalance":
            MessageLookupByLibrary.simpleMessage("Saldo prestiti XDAI"),
        "xdaiDepositBalance":
            MessageLookupByLibrary.simpleMessage("Saldo depositi XDAI"),
        "yam": MessageLookupByLibrary.simpleMessage("YAM"),
        "yamHistory": MessageLookupByLibrary.simpleMessage("Cronologia Yam"),
        "yamProjectionDescription": MessageLookupByLibrary.simpleMessage(
            "Proiezione del portafoglio da YAM"),
        "yam_description": MessageLookupByLibrary.simpleMessage(
            "Strumento di gestione per la comunità di investitori di MeProp."),
        "year": MessageLookupByLibrary.simpleMessage("Anno"),
        "yesterday": MessageLookupByLibrary.simpleMessage("Ieri"),
        "yieldEvolution":
            MessageLookupByLibrary.simpleMessage("Evoluzione del rendimento"),
        "yieldEvolutionPercentage":
            MessageLookupByLibrary.simpleMessage("Evoluzione del rendimento:"),
        "yourAvailableTokens":
            MessageLookupByLibrary.simpleMessage("I tuoi token disponibili")
      };
}
