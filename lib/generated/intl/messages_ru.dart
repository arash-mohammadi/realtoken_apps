// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a ru locale. All the
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
  String get localeName => 'ru';

  static String m0(biometricType) => "Аутентификация ${biometricType}";

  static String m1(days) => "+${days} д";

  static String m2(biometricType) => "Устройство поддерживает ${biometricType}";

  static String m3(error) => "Ошибка: ${error}";

  static String m4(error) => "Ошибка: ${error}";

  static String m5(language) => "Язык изменен на ${language}";

  static String m6(days) => "Следующий RONday через ${days} дней";

  static String m7(rented, total) => "Арендовано: ${rented}/${total}";

  static String m8(weeks) => "ROI: ${weeks} недель";

  static String m9(theme) => "Тема обновлена на ${theme}";

  static String m10(rented, total) => "Арендовано: ${rented}/${total}";

  static String m11(address) => "Кошелек сохранен: ${address}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "GDrive_connexion":
            MessageLookupByLibrary.simpleMessage("Подключение Google Drive"),
        "about": MessageLookupByLibrary.simpleMessage("О приложении"),
        "aboutImportExport": MessageLookupByLibrary.simpleMessage(
            "Сохранение и импорт истории балансов в ZIP-файл."),
        "aboutImportExportTitle":
            MessageLookupByLibrary.simpleMessage("Функция импорта/экспорта"),
        "addAddress": MessageLookupByLibrary.simpleMessage("Добавить адрес"),
        "addressCopied":
            MessageLookupByLibrary.simpleMessage("Адрес скопирован"),
        "addressCopiedMessage":
            MessageLookupByLibrary.simpleMessage("Адрес скопирован в буфер"),
        "adjustmentSaved":
            MessageLookupByLibrary.simpleMessage("Корректировка сохранена"),
        "adjustments": MessageLookupByLibrary.simpleMessage("Корректировки"),
        "advanced": MessageLookupByLibrary.simpleMessage("Расширенные"),
        "all": MessageLookupByLibrary.simpleMessage("Все"),
        "allCities": MessageLookupByLibrary.simpleMessage("Все города"),
        "allCountries": MessageLookupByLibrary.simpleMessage("Все страны"),
        "allRegions": MessageLookupByLibrary.simpleMessage("Все регионы"),
        "allWorkCorrectly":
            MessageLookupByLibrary.simpleMessage("Все работает корректно"),
        "amount": MessageLookupByLibrary.simpleMessage("Количество"),
        "annualPercentageYield":
            MessageLookupByLibrary.simpleMessage("Годовая доходность"),
        "annualYield":
            MessageLookupByLibrary.simpleMessage("Чистая доходность"),
        "annually": MessageLookupByLibrary.simpleMessage("Ежегодно"),
        "appDescription": MessageLookupByLibrary.simpleMessage(
            "мобильное приложение для сообщества"),
        "appName": MessageLookupByLibrary.simpleMessage("RealToken"),
        "appTitle": MessageLookupByLibrary.simpleMessage("RealTokens"),
        "appearance": MessageLookupByLibrary.simpleMessage("Внешний вид"),
        "application": MessageLookupByLibrary.simpleMessage("Приложение"),
        "apy": MessageLookupByLibrary.simpleMessage("APY"),
        "apyHistory": MessageLookupByLibrary.simpleMessage("История APY"),
        "areYouSureClearData":
            MessageLookupByLibrary.simpleMessage("Очистить кеш и данные?"),
        "ascending": MessageLookupByLibrary.simpleMessage("По возрастанию"),
        "assetPrice": MessageLookupByLibrary.simpleMessage("Цена актива"),
        "assets": MessageLookupByLibrary.simpleMessage("Активы"),
        "authenticateWithBiometric": m0,
        "author": MessageLookupByLibrary.simpleMessage("Автор"),
        "autoSync": MessageLookupByLibrary.simpleMessage("Автосинхронизация"),
        "averageApy": MessageLookupByLibrary.simpleMessage("средний APY"),
        "balance": MessageLookupByLibrary.simpleMessage("Баланс"),
        "barChart":
            MessageLookupByLibrary.simpleMessage("Столбчатая диаграмма"),
        "bedroomBath": MessageLookupByLibrary.simpleMessage("Спальни/Ванные"),
        "biometricAuthSuccessful":
            MessageLookupByLibrary.simpleMessage("Биометрия активирована"),
        "biometricAuthentication": MessageLookupByLibrary.simpleMessage(
            "Биометрическая аутентификация"),
        "biometricAuthenticationDisabled":
            MessageLookupByLibrary.simpleMessage("Биометрия отключена"),
        "biometricAuthenticationFailed":
            MessageLookupByLibrary.simpleMessage("Ошибка аутентификации"),
        "biometricError":
            MessageLookupByLibrary.simpleMessage("Ошибка биометрии"),
        "biometricsNotAvailable":
            MessageLookupByLibrary.simpleMessage("Биометрия недоступна"),
        "blockchain": MessageLookupByLibrary.simpleMessage("Блокчейн"),
        "borrowBalance": MessageLookupByLibrary.simpleMessage("Заимствования"),
        "brute": MessageLookupByLibrary.simpleMessage("Валовая"),
        "buy_token": MessageLookupByLibrary.simpleMessage("Купить"),
        "calendar": MessageLookupByLibrary.simpleMessage("Календарь"),
        "cancel": MessageLookupByLibrary.simpleMessage("Отмена"),
        "changelog": MessageLookupByLibrary.simpleMessage("История изменений"),
        "characteristics":
            MessageLookupByLibrary.simpleMessage("Характеристики"),
        "chartType": MessageLookupByLibrary.simpleMessage("Тип графика"),
        "checkingBiometricCapabilities":
            MessageLookupByLibrary.simpleMessage("Проверка биометрии..."),
        "chinese": MessageLookupByLibrary.simpleMessage("Китайский"),
        "choice_all": MessageLookupByLibrary.simpleMessage("Все"),
        "choice_buy": MessageLookupByLibrary.simpleMessage("Купить"),
        "choice_sell": MessageLookupByLibrary.simpleMessage("Продать"),
        "city": MessageLookupByLibrary.simpleMessage("Город"),
        "clearCacheData":
            MessageLookupByLibrary.simpleMessage("Очистить кеш/данные"),
        "close": MessageLookupByLibrary.simpleMessage("Закрыть"),
        "commercial": MessageLookupByLibrary.simpleMessage("Коммерческая"),
        "condominium": MessageLookupByLibrary.simpleMessage("Кондоминиум"),
        "configureInSystemSettings":
            MessageLookupByLibrary.simpleMessage("Настройте в системе"),
        "confirm": MessageLookupByLibrary.simpleMessage("Подтвердить"),
        "confirmAction":
            MessageLookupByLibrary.simpleMessage("Подтвердите действие"),
        "connectBeforeSync": MessageLookupByLibrary.simpleMessage(
            "Сначала подключите Google Drive"),
        "connectBeforeSyncMessage": MessageLookupByLibrary.simpleMessage(
            "Сначала подключите Google Drive"),
        "connected": MessageLookupByLibrary.simpleMessage("Подключено"),
        "constructionYear":
            MessageLookupByLibrary.simpleMessage("Год постройки"),
        "continueWithoutAuthentication": MessageLookupByLibrary.simpleMessage(
            "Продолжить без аутентификации"),
        "contractType": MessageLookupByLibrary.simpleMessage("Тип контракта"),
        "convertSqft":
            MessageLookupByLibrary.simpleMessage("Конвертировать кв.футы в м²"),
        "copied": MessageLookupByLibrary.simpleMessage("Скопировано!"),
        "copy": MessageLookupByLibrary.simpleMessage("Копировать"),
        "copyAddress": MessageLookupByLibrary.simpleMessage("Копировать адрес"),
        "country": MessageLookupByLibrary.simpleMessage("Страна"),
        "creation_date": MessageLookupByLibrary.simpleMessage("Дата создания"),
        "crypto": MessageLookupByLibrary.simpleMessage("Криптовалюта"),
        "cryptoDonationAddress": MessageLookupByLibrary.simpleMessage(
            "Адрес для криптопожертвований"),
        "cumulativeRentGraph":
            MessageLookupByLibrary.simpleMessage("Накопленная аренда"),
        "currency": MessageLookupByLibrary.simpleMessage("Валюта"),
        "current_price": MessageLookupByLibrary.simpleMessage("Текущая цена:"),
        "current_yield":
            MessageLookupByLibrary.simpleMessage("Текущая доходность:"),
        "daily": MessageLookupByLibrary.simpleMessage("Ежедневно"),
        "dao_description":
            MessageLookupByLibrary.simpleMessage("Форум RealTokens DAO"),
        "dark": MessageLookupByLibrary.simpleMessage("Темная"),
        "darkTheme": MessageLookupByLibrary.simpleMessage("Темная тема"),
        "dashboard": MessageLookupByLibrary.simpleMessage("Панель управления"),
        "dataBackup": MessageLookupByLibrary.simpleMessage("Резервная копия"),
        "date": MessageLookupByLibrary.simpleMessage("Дата"),
        "dateNotCommunicated":
            MessageLookupByLibrary.simpleMessage("Дата не сообщена"),
        "day": MessageLookupByLibrary.simpleMessage("День"),
        "days": MessageLookupByLibrary.simpleMessage("Дни"),
        "daysLimit": MessageLookupByLibrary.simpleMessage("Лимит дней"),
        "daysShort": m1,
        "delta_price": MessageLookupByLibrary.simpleMessage("Изменение цены"),
        "depositBalance": MessageLookupByLibrary.simpleMessage("Депозиты"),
        "deposits": MessageLookupByLibrary.simpleMessage("Депозиты"),
        "depositsAndLoans":
            MessageLookupByLibrary.simpleMessage("Депозиты и займы"),
        "descending": MessageLookupByLibrary.simpleMessage("По убыванию"),
        "deviceDoesNotSupport": MessageLookupByLibrary.simpleMessage(
            "Устройство не поддерживает биометрию"),
        "deviceDoesNotSupportBiometric":
            MessageLookupByLibrary.simpleMessage("Биометрия не поддерживается"),
        "deviceSupportsBiometric": m2,
        "donate": MessageLookupByLibrary.simpleMessage("Пожертвовать"),
        "donationMessage": MessageLookupByLibrary.simpleMessage(
            "Если вам нравится это приложение, вы можете поддержать его развитие."),
        "duplex": MessageLookupByLibrary.simpleMessage("Дуплекс"),
        "duplicate": MessageLookupByLibrary.simpleMessage(
            "Объекты в нескольких кошельках/RMM"),
        "duplicate_title":
            MessageLookupByLibrary.simpleMessage("Дублирующиеся объекты"),
        "edit": MessageLookupByLibrary.simpleMessage("Редактировать"),
        "editWalletBalance": MessageLookupByLibrary.simpleMessage(
            "Редактировать историю баланса"),
        "enableBiometricAuthentication":
            MessageLookupByLibrary.simpleMessage("Включить биометрию"),
        "english": MessageLookupByLibrary.simpleMessage("Английский"),
        "enterValidNumber":
            MessageLookupByLibrary.simpleMessage("Введите корректное число"),
        "errorDuringTest": m3,
        "error_occurred": m4,
        "ethereumContract":
            MessageLookupByLibrary.simpleMessage("Контракт Ethereum"),
        "expectedYield":
            MessageLookupByLibrary.simpleMessage("Ожидаемая доходность"),
        "exportButton": MessageLookupByLibrary.simpleMessage("Экспорт"),
        "exportData": MessageLookupByLibrary.simpleMessage("Экспорт данных"),
        "exportFailed": MessageLookupByLibrary.simpleMessage("Ошибка экспорта"),
        "exportSuccess":
            MessageLookupByLibrary.simpleMessage("Данные экспортированы"),
        "feedback": MessageLookupByLibrary.simpleMessage("Обратная связь"),
        "filterNotInWallet":
            MessageLookupByLibrary.simpleMessage("Нет в кошельке"),
        "finances": MessageLookupByLibrary.simpleMessage("Финансы"),
        "french": MessageLookupByLibrary.simpleMessage("Французский"),
        "futureRents": MessageLookupByLibrary.simpleMessage("Будущие платежи"),
        "gnosisContract":
            MessageLookupByLibrary.simpleMessage("Контракт Gnosis"),
        "googleDriveConnection":
            MessageLookupByLibrary.simpleMessage("Подключение Google Drive"),
        "googleDriveTitle":
            MessageLookupByLibrary.simpleMessage("Google Drive"),
        "gridView": MessageLookupByLibrary.simpleMessage("Сетка"),
        "grossRentMonth":
            MessageLookupByLibrary.simpleMessage("Валовая аренда в месяц"),
        "groupedRentGraph":
            MessageLookupByLibrary.simpleMessage("Арендные платежи"),
        "healthFactorSafer": MessageLookupByLibrary.simpleMessage(
            "Фактор здоровья: выше = безопаснее"),
        "hello": MessageLookupByLibrary.simpleMessage("Привет"),
        "hf": MessageLookupByLibrary.simpleMessage("HF"),
        "hours": MessageLookupByLibrary.simpleMessage("Часы"),
        "importButton": MessageLookupByLibrary.simpleMessage("Импорт"),
        "importData": MessageLookupByLibrary.simpleMessage("Импорт данных"),
        "importExportData":
            MessageLookupByLibrary.simpleMessage("Импорт/экспорт данных (zip)"),
        "importFailed": MessageLookupByLibrary.simpleMessage("Ошибка импорта"),
        "importSuccess":
            MessageLookupByLibrary.simpleMessage("Данные импортированы"),
        "initialInvestment":
            MessageLookupByLibrary.simpleMessage("Начальные инвестиции"),
        "initialLaunchDate":
            MessageLookupByLibrary.simpleMessage("Дата запуска"),
        "initialMaintenanceReserve":
            MessageLookupByLibrary.simpleMessage("Резерв на обслуживание"),
        "initialPrice":
            MessageLookupByLibrary.simpleMessage("Средняя цена покупки"),
        "initialPriceModified_description":
            MessageLookupByLibrary.simpleMessage(
                "Средняя цена токена для расчета ROI."),
        "initialPriceRemoved": MessageLookupByLibrary.simpleMessage(
            "Средняя цена покупки удалена"),
        "initialPriceUpdated":
            MessageLookupByLibrary.simpleMessage("Средняя цена обновлена"),
        "insights": MessageLookupByLibrary.simpleMessage("Аналитика"),
        "insurance": MessageLookupByLibrary.simpleMessage("Страхование"),
        "internal_transfer":
            MessageLookupByLibrary.simpleMessage("Внутренний перевод"),
        "invalidCoordinates":
            MessageLookupByLibrary.simpleMessage("Неверные координаты"),
        "invalidDataForChart":
            MessageLookupByLibrary.simpleMessage("Ошибка отображения графика"),
        "invalidWalletAddress":
            MessageLookupByLibrary.simpleMessage("Неверный адрес"),
        "invalidWalletInQR":
            MessageLookupByLibrary.simpleMessage("Неверный QR-код кошелька"),
        "investment": MessageLookupByLibrary.simpleMessage("Инвестиция"),
        "italian": MessageLookupByLibrary.simpleMessage("Итальянский"),
        "language": MessageLookupByLibrary.simpleMessage("Язык"),
        "languageUpdated": m5,
        "lastExecution":
            MessageLookupByLibrary.simpleMessage("Последнее обновление"),
        "lastRentReceived":
            MessageLookupByLibrary.simpleMessage("Последняя полученная аренда"),
        "last_update":
            MessageLookupByLibrary.simpleMessage("Последнее обновление:"),
        "legend": MessageLookupByLibrary.simpleMessage("Легенда"),
        "light": MessageLookupByLibrary.simpleMessage("Светлая"),
        "lineChart": MessageLookupByLibrary.simpleMessage("Линейный график"),
        "links": MessageLookupByLibrary.simpleMessage("Ссылки"),
        "listView": MessageLookupByLibrary.simpleMessage("Список"),
        "loans": MessageLookupByLibrary.simpleMessage("Займы"),
        "localStorage":
            MessageLookupByLibrary.simpleMessage("Локальное хранилище"),
        "lotSize": MessageLookupByLibrary.simpleMessage("Размер участка"),
        "ltv": MessageLookupByLibrary.simpleMessage("LTV"),
        "ltvSafer":
            MessageLookupByLibrary.simpleMessage("LTV: ниже = безопаснее"),
        "manageAddresses":
            MessageLookupByLibrary.simpleMessage("Добавить кошелек"),
        "manageEvmAddresses":
            MessageLookupByLibrary.simpleMessage("Управление кошельками"),
        "manualAdjustment":
            MessageLookupByLibrary.simpleMessage("Ручная корректировка"),
        "manualAdjustmentDescription": MessageLookupByLibrary.simpleMessage(
            "Ручная корректировка суммы портфеля"),
        "manualEdit":
            MessageLookupByLibrary.simpleMessage("Ручное редактирование"),
        "maps": MessageLookupByLibrary.simpleMessage("Карты"),
        "mfrPortfolio": MessageLookupByLibrary.simpleMessage("Портфель MFR"),
        "miscellaneousCosts":
            MessageLookupByLibrary.simpleMessage("Прочие расходы"),
        "mixedUse":
            MessageLookupByLibrary.simpleMessage("Смешанное использование"),
        "month": MessageLookupByLibrary.simpleMessage("Месяц"),
        "monthly": MessageLookupByLibrary.simpleMessage("Ежемесячно"),
        "multiFamily":
            MessageLookupByLibrary.simpleMessage("Многоквартирный дом"),
        "nameUnavailable":
            MessageLookupByLibrary.simpleMessage("Название недоступно"),
        "net": MessageLookupByLibrary.simpleMessage("Чистая"),
        "netAnnualRent":
            MessageLookupByLibrary.simpleMessage("Чистая годовая аренда"),
        "netApy": MessageLookupByLibrary.simpleMessage("Чистый APY"),
        "netApyHelp": MessageLookupByLibrary.simpleMessage(
            "Чистая доходность рассчитывается с учетом депозитов и займов."),
        "netRentMonth":
            MessageLookupByLibrary.simpleMessage("Чистая аренда в месяц"),
        "network": MessageLookupByLibrary.simpleMessage("Сеть"),
        "newVersionAvailable":
            MessageLookupByLibrary.simpleMessage("Доступна новая версия"),
        "new_yield": MessageLookupByLibrary.simpleMessage("Новая доходность:"),
        "nextRondayInDays": m6,
        "nextRondays": MessageLookupByLibrary.simpleMessage("Следующие Ronday"),
        "noCommunicatedDate":
            MessageLookupByLibrary.simpleMessage("Дата не указана"),
        "noDataAvailable": MessageLookupByLibrary.simpleMessage(
            "Нет данных, добавьте новый кошелек"),
        "noDataAvailableDot":
            MessageLookupByLibrary.simpleMessage("Нет данных."),
        "noFutureRents":
            MessageLookupByLibrary.simpleMessage("Нет будущих платежей"),
        "noImageAvailable":
            MessageLookupByLibrary.simpleMessage("Изображение недоступно"),
        "noPriceEvolution": MessageLookupByLibrary.simpleMessage(
            "Нет данных по цене. Последняя цена:"),
        "noPropertiesForSale":
            MessageLookupByLibrary.simpleMessage("Нет объектов на продажу"),
        "noRecentUpdates":
            MessageLookupByLibrary.simpleMessage("Нет последних изменений."),
        "noRentReceived": MessageLookupByLibrary.simpleMessage(
            "Арендные платежи не получены"),
        "noScheduledRonday":
            MessageLookupByLibrary.simpleMessage("RONday не запланирован"),
        "noThanks": MessageLookupByLibrary.simpleMessage("Нет, спасибо"),
        "noTokensAvailable":
            MessageLookupByLibrary.simpleMessage("Нет доступных токенов"),
        "noTokensFound":
            MessageLookupByLibrary.simpleMessage("Токены не найдены"),
        "noTokensWithValidCoordinates":
            MessageLookupByLibrary.simpleMessage("Нет токенов с координатами"),
        "noTransactionsAvailable":
            MessageLookupByLibrary.simpleMessage("Нет транзакций"),
        "noWalletsAvailable":
            MessageLookupByLibrary.simpleMessage("Нет доступных кошельков"),
        "noYieldEvolution": MessageLookupByLibrary.simpleMessage(
            "Нет данных по доходности. Последний показатель:"),
        "no_market_offers_available":
            MessageLookupByLibrary.simpleMessage("Нет рыночных предложений"),
        "notConnected": MessageLookupByLibrary.simpleMessage("Не подключено"),
        "notSpecified": MessageLookupByLibrary.simpleMessage("Не указано"),
        "not_whitelisted_warning":
            MessageLookupByLibrary.simpleMessage("Токен не в белом списке"),
        "notifications": MessageLookupByLibrary.simpleMessage("Уведомления"),
        "occupancyRate":
            MessageLookupByLibrary.simpleMessage("Уровень заполненности"),
        "occupancyStatusHigh": MessageLookupByLibrary.simpleMessage("Высокий"),
        "occupancyStatusLow": MessageLookupByLibrary.simpleMessage("Низкий"),
        "occupancyStatusMedium":
            MessageLookupByLibrary.simpleMessage("Средний"),
        "offer_id": MessageLookupByLibrary.simpleMessage("ID предложения"),
        "offer_price":
            MessageLookupByLibrary.simpleMessage("Цена предложения:"),
        "offering": MessageLookupByLibrary.simpleMessage("Предложение"),
        "offers_list_header":
            MessageLookupByLibrary.simpleMessage("Список предложений"),
        "ok": MessageLookupByLibrary.simpleMessage("OK"),
        "other": MessageLookupByLibrary.simpleMessage("Другое"),
        "others": MessageLookupByLibrary.simpleMessage("Другое"),
        "othersTitle":
            MessageLookupByLibrary.simpleMessage("Детали раздела «Другое»"),
        "overview": MessageLookupByLibrary.simpleMessage("Обзор"),
        "paypal": MessageLookupByLibrary.simpleMessage("PayPal"),
        "period": MessageLookupByLibrary.simpleMessage("Период"),
        "personalization":
            MessageLookupByLibrary.simpleMessage("Персонализация"),
        "pleaseAuthenticateToAccess":
            MessageLookupByLibrary.simpleMessage("Требуется аутентификация"),
        "portfolio": MessageLookupByLibrary.simpleMessage("Портфель"),
        "portfolioGlobal":
            MessageLookupByLibrary.simpleMessage("Общий портфель"),
        "portuguese": MessageLookupByLibrary.simpleMessage("Португальский"),
        "presentInWallet":
            MessageLookupByLibrary.simpleMessage("Есть в кошельке"),
        "price": MessageLookupByLibrary.simpleMessage("Цена"),
        "priceEvolution": MessageLookupByLibrary.simpleMessage("Динамика цены"),
        "priceEvolutionPercentage":
            MessageLookupByLibrary.simpleMessage("Изменение цены:"),
        "projection": MessageLookupByLibrary.simpleMessage("прогноз"),
        "properties": MessageLookupByLibrary.simpleMessage("Недвижимость"),
        "propertiesForSale":
            MessageLookupByLibrary.simpleMessage("Объекты на продажу"),
        "properties_for_sale":
            MessageLookupByLibrary.simpleMessage("Объекты на продажу"),
        "propertyMaintenanceMonthly": MessageLookupByLibrary.simpleMessage(
            "Обслуживание объекта (ежемесячно)"),
        "propertyManagement":
            MessageLookupByLibrary.simpleMessage("Управление недвижимостью"),
        "propertyStories":
            MessageLookupByLibrary.simpleMessage("Количество этажей"),
        "propertyTaxes":
            MessageLookupByLibrary.simpleMessage("Налоги на недвижимость"),
        "propertyType":
            MessageLookupByLibrary.simpleMessage("Тип недвижимости"),
        "purchase": MessageLookupByLibrary.simpleMessage("Покупка"),
        "quantity": MessageLookupByLibrary.simpleMessage("Количество"),
        "rateApp": MessageLookupByLibrary.simpleMessage("Оценить приложение"),
        "realTPerformance":
            MessageLookupByLibrary.simpleMessage("Производительность RealT"),
        "realTTitle": MessageLookupByLibrary.simpleMessage("RealT"),
        "realTokensList":
            MessageLookupByLibrary.simpleMessage("Список RealTokens"),
        "realt": MessageLookupByLibrary.simpleMessage("RealT"),
        "realtActualPrice":
            MessageLookupByLibrary.simpleMessage("Текущая цена"),
        "realtListingFee":
            MessageLookupByLibrary.simpleMessage("Комиссия RealT"),
        "realtPlatform":
            MessageLookupByLibrary.simpleMessage("Платформа RealT"),
        "recentChanges":
            MessageLookupByLibrary.simpleMessage("Последние изменения"),
        "recentUpdatesTitle":
            MessageLookupByLibrary.simpleMessage("Последние 30 дней"),
        "refresh": MessageLookupByLibrary.simpleMessage("Обновить"),
        "region": MessageLookupByLibrary.simpleMessage("Регион"),
        "regionFilterLabel": MessageLookupByLibrary.simpleMessage("Регион"),
        "renovationReserve":
            MessageLookupByLibrary.simpleMessage("Резерв на ремонт"),
        "rentDistribution":
            MessageLookupByLibrary.simpleMessage("Распределение аренды"),
        "rentDistributionByWallet": MessageLookupByLibrary.simpleMessage(
            "Распределение аренды по кошелькам"),
        "rentGraph":
            MessageLookupByLibrary.simpleMessage("График арендных платежей"),
        "rentStartDate": MessageLookupByLibrary.simpleMessage("Первая аренда"),
        "rentStartFuture":
            MessageLookupByLibrary.simpleMessage("Аренда не начата"),
        "rentalStatus": MessageLookupByLibrary.simpleMessage("Статус аренды"),
        "rentalStatusAll": MessageLookupByLibrary.simpleMessage("Все"),
        "rentalStatusNotRented":
            MessageLookupByLibrary.simpleMessage("Не арендовано"),
        "rentalStatusPartiallyRented":
            MessageLookupByLibrary.simpleMessage("Частично арендовано"),
        "rentalStatusRented":
            MessageLookupByLibrary.simpleMessage("Арендовано"),
        "rentalStatusTitle":
            MessageLookupByLibrary.simpleMessage("Статус аренды"),
        "rentalType": MessageLookupByLibrary.simpleMessage("Тип аренды"),
        "rented": MessageLookupByLibrary.simpleMessage("Арендовано"),
        "rentedUnits": m7,
        "rentedUnitsSimple":
            MessageLookupByLibrary.simpleMessage("Арендованные единицы"),
        "rents": MessageLookupByLibrary.simpleMessage("Арендные платежи"),
        "resortBungalow":
            MessageLookupByLibrary.simpleMessage("Курортный бунгало"),
        "revenue": MessageLookupByLibrary.simpleMessage("Доход"),
        "reviewRequestUnavailable": MessageLookupByLibrary.simpleMessage(
            "Открыть страницу приложения в Store?"),
        "rmm": MessageLookupByLibrary.simpleMessage("RMM"),
        "rmmDetails": MessageLookupByLibrary.simpleMessage("Детали RMM"),
        "rmmHealth": MessageLookupByLibrary.simpleMessage("Состояние RMM"),
        "rmmValue": MessageLookupByLibrary.simpleMessage("Стоимость RMM"),
        "rmm_description": MessageLookupByLibrary.simpleMessage(
            "Платформа для кредитования под залог токенов недвижимости."),
        "roiAlertInfo": MessageLookupByLibrary.simpleMessage(
            "Функция ROI в бета-режиме. Расчет основан на доходах и начальной стоимости токена."),
        "roiHistory": MessageLookupByLibrary.simpleMessage("История ROI"),
        "roiPerProperties": MessageLookupByLibrary.simpleMessage("ROI объекта"),
        "roi_label": m8,
        "russian": MessageLookupByLibrary.simpleMessage("Русский"),
        "rwaHoldings": MessageLookupByLibrary.simpleMessage("RWA Holdings SA"),
        "save": MessageLookupByLibrary.simpleMessage("Сохранить"),
        "scanQRCode":
            MessageLookupByLibrary.simpleMessage("Сканировать QR-код"),
        "searchHint": MessageLookupByLibrary.simpleMessage("Поиск..."),
        "search_hint":
            MessageLookupByLibrary.simpleMessage("Поиск по названию..."),
        "secondary": MessageLookupByLibrary.simpleMessage("Вторичный"),
        "secondary_offers_related_to_token":
            MessageLookupByLibrary.simpleMessage("YAM предложения по токену"),
        "section8paid": MessageLookupByLibrary.simpleMessage("Секция 8"),
        "security": MessageLookupByLibrary.simpleMessage("Безопасность"),
        "selectCurrency":
            MessageLookupByLibrary.simpleMessage("Выберите валюту"),
        "sell_token": MessageLookupByLibrary.simpleMessage("Продать"),
        "sendDonations": MessageLookupByLibrary.simpleMessage(
            "Отправьте пожертвования на адрес:"),
        "serviceStatus": MessageLookupByLibrary.simpleMessage("Статус сервиса"),
        "serviceStatusPage":
            MessageLookupByLibrary.simpleMessage("Статус сервисов"),
        "settings": MessageLookupByLibrary.simpleMessage("Настройки"),
        "settingsCategory": MessageLookupByLibrary.simpleMessage("Настройки"),
        "settingsTitle": MessageLookupByLibrary.simpleMessage("Настройки"),
        "sfrPortfolio": MessageLookupByLibrary.simpleMessage("Портфель SFR"),
        "showNetTotal":
            MessageLookupByLibrary.simpleMessage("Показать чистый итог"),
        "showNetTotalDescription": MessageLookupByLibrary.simpleMessage(
            "Учитывать депозиты/займы в расчетах"),
        "showOnlyWhitelisted":
            MessageLookupByLibrary.simpleMessage("Только белый список"),
        "showTotalInvested":
            MessageLookupByLibrary.simpleMessage("Показать общие инвестиции"),
        "showYamProjection":
            MessageLookupByLibrary.simpleMessage("Показать прогноз YAM"),
        "singleFamily": MessageLookupByLibrary.simpleMessage("Отдельный дом"),
        "somethingWrong": MessageLookupByLibrary.simpleMessage(
            "Данные могут быть устаревшими"),
        "sortByAPY": MessageLookupByLibrary.simpleMessage("Сортировать по APY"),
        "sortByInitialLaunchDate": MessageLookupByLibrary.simpleMessage(
            "Сортировать по дате добавления"),
        "sortByName":
            MessageLookupByLibrary.simpleMessage("Сортировать по имени"),
        "sortByValue":
            MessageLookupByLibrary.simpleMessage("Сортировать по стоимости"),
        "sort_date": MessageLookupByLibrary.simpleMessage("Дата"),
        "sort_delta": MessageLookupByLibrary.simpleMessage("Дельта"),
        "sort_label": MessageLookupByLibrary.simpleMessage("Сортировка:"),
        "spanish": MessageLookupByLibrary.simpleMessage("Испанский"),
        "specialThanks": MessageLookupByLibrary.simpleMessage(
            "Особая благодарность @Sigri, @ehpst и @pitsbi за поддержку."),
        "squareFeet":
            MessageLookupByLibrary.simpleMessage("Внутренняя площадь"),
        "statistics": MessageLookupByLibrary.simpleMessage("Статистика"),
        "support": MessageLookupByLibrary.simpleMessage("Поддержка"),
        "supportProject":
            MessageLookupByLibrary.simpleMessage("Поддержать проект"),
        "syncComplete":
            MessageLookupByLibrary.simpleMessage("Синхронизация завершена"),
        "syncCompleteWithGoogleDrive": MessageLookupByLibrary.simpleMessage(
            "Синхронизация с Google Drive завершена"),
        "syncWithGoogleDrive": MessageLookupByLibrary.simpleMessage(
            "Синхронизация с Google Drive"),
        "synchronization":
            MessageLookupByLibrary.simpleMessage("Синхронизация"),
        "testAuthenticationReason": MessageLookupByLibrary.simpleMessage(
            "Тест биометрической аутентификации"),
        "testBiometricAuthentication":
            MessageLookupByLibrary.simpleMessage("Тест биометрии"),
        "testBiometricDescription":
            MessageLookupByLibrary.simpleMessage("Проверьте работу биометрии"),
        "testFailed": MessageLookupByLibrary.simpleMessage("Тест не пройден"),
        "testSuccessful": MessageLookupByLibrary.simpleMessage("Тест успешен"),
        "testingAuthentication": MessageLookupByLibrary.simpleMessage(
            "Тестирование аутентификации..."),
        "textSize": MessageLookupByLibrary.simpleMessage("Размер текста"),
        "thankYouForFeedback":
            MessageLookupByLibrary.simpleMessage("Спасибо за отзыв!"),
        "thankYouMessage": MessageLookupByLibrary.simpleMessage(
            "Спасибо всем, кто участвовал в разработке проекта."),
        "thanks": MessageLookupByLibrary.simpleMessage("Благодарности"),
        "themeUpdated": m9,
        "timeBeforeLiquidation":
            MessageLookupByLibrary.simpleMessage("до ликвидации"),
        "timestamp": MessageLookupByLibrary.simpleMessage("Время"),
        "tokenAddress": MessageLookupByLibrary.simpleMessage("Адрес токена"),
        "tokenDistribution":
            MessageLookupByLibrary.simpleMessage("Распределение токенов"),
        "tokenDistributionByCity": MessageLookupByLibrary.simpleMessage(
            "Распределение токенов по городам"),
        "tokenDistributionByCountry": MessageLookupByLibrary.simpleMessage(
            "Распределение токенов по странам"),
        "tokenDistributionByRegion": MessageLookupByLibrary.simpleMessage(
            "Распределение токенов по регионам"),
        "tokenDistributionByWallet": MessageLookupByLibrary.simpleMessage(
            "Распределение токенов по кошелькам"),
        "tokenNotWhitelisted":
            MessageLookupByLibrary.simpleMessage("Токен не в белом списке"),
        "tokenPrice": MessageLookupByLibrary.simpleMessage("Цена токена"),
        "tokenSymbol": MessageLookupByLibrary.simpleMessage("Символ токена"),
        "tokenTypeTitle": MessageLookupByLibrary.simpleMessage("Тип токена"),
        "tokenWhitelisted":
            MessageLookupByLibrary.simpleMessage("Токен в белом списке"),
        "token_amount":
            MessageLookupByLibrary.simpleMessage("Количество токенов"),
        "token_value": MessageLookupByLibrary.simpleMessage("Стоимость токена"),
        "tokens": MessageLookupByLibrary.simpleMessage("Токены"),
        "total": MessageLookupByLibrary.simpleMessage("Итого"),
        "totalBalance": MessageLookupByLibrary.simpleMessage("Общий баланс"),
        "totalExpenses": MessageLookupByLibrary.simpleMessage("Всего расходов"),
        "totalInvestment":
            MessageLookupByLibrary.simpleMessage("Общие инвестиции"),
        "totalPortfolio":
            MessageLookupByLibrary.simpleMessage("Общий портфель"),
        "totalRentReceived":
            MessageLookupByLibrary.simpleMessage("Общий доход"),
        "totalTokens": MessageLookupByLibrary.simpleMessage("Всего токенов"),
        "totalTokensLabel":
            MessageLookupByLibrary.simpleMessage("Всего токенов"),
        "totalUnits": MessageLookupByLibrary.simpleMessage("Всего единиц"),
        "totalValue": MessageLookupByLibrary.simpleMessage("Общая стоимость"),
        "transactionHistory":
            MessageLookupByLibrary.simpleMessage("История транзакций"),
        "transactionType":
            MessageLookupByLibrary.simpleMessage("Тип транзакции"),
        "underlyingAssetPrice":
            MessageLookupByLibrary.simpleMessage("Цена актива"),
        "unitesLouees": m10,
        "units": MessageLookupByLibrary.simpleMessage("ед."),
        "unknown": MessageLookupByLibrary.simpleMessage("Неизвестно"),
        "unknownCity":
            MessageLookupByLibrary.simpleMessage("Неизвестный город"),
        "unknownCountry":
            MessageLookupByLibrary.simpleMessage("Неизвестная страна"),
        "unknownDate": MessageLookupByLibrary.simpleMessage("Неизвестная дата"),
        "unknownRegion":
            MessageLookupByLibrary.simpleMessage("Неизвестный регион"),
        "unknownTokenName":
            MessageLookupByLibrary.simpleMessage("Неизвестное название"),
        "unknownTransaction":
            MessageLookupByLibrary.simpleMessage("Неизвестная транзакция"),
        "usdcBorrowBalance":
            MessageLookupByLibrary.simpleMessage("Баланс USDC-заимствований"),
        "usdcDepositBalance":
            MessageLookupByLibrary.simpleMessage("Баланс USDC-депозитов"),
        "verifyingAuthentication":
            MessageLookupByLibrary.simpleMessage("Проверка аутентификации..."),
        "version": MessageLookupByLibrary.simpleMessage("Версия"),
        "viewOnMap":
            MessageLookupByLibrary.simpleMessage("Посмотреть на карте"),
        "viewOnRealT":
            MessageLookupByLibrary.simpleMessage("Посмотреть на RealT"),
        "wallet": MessageLookupByLibrary.simpleMessage("Кошелек"),
        "walletAddress": MessageLookupByLibrary.simpleMessage("Адрес кошелька"),
        "walletBalanceHistory":
            MessageLookupByLibrary.simpleMessage("История баланса кошелька"),
        "walletDetails":
            MessageLookupByLibrary.simpleMessage("Детали кошелька"),
        "walletSaved": m11,
        "wallets": MessageLookupByLibrary.simpleMessage("Кошельки"),
        "walletsContainingToken":
            MessageLookupByLibrary.simpleMessage("Кошельки с этим токеном"),
        "walletsWithoutRmmUsage":
            MessageLookupByLibrary.simpleMessage("Кошельки без RMM"),
        "week": MessageLookupByLibrary.simpleMessage("Неделя"),
        "weekly": MessageLookupByLibrary.simpleMessage("Еженедельно"),
        "weeks": MessageLookupByLibrary.simpleMessage("Недели"),
        "whitelistInfoContent": MessageLookupByLibrary.simpleMessage(
            "Токены из белого списка доступны для покупки."),
        "whitelistInfoTitle":
            MessageLookupByLibrary.simpleMessage("Информация о белом списке"),
        "wiki_community_description": MessageLookupByLibrary.simpleMessage(
            "Ресурсы для сообщества RealT."),
        "xdaiBorrowBalance":
            MessageLookupByLibrary.simpleMessage("Баланс XDAI-заимствований"),
        "xdaiDepositBalance":
            MessageLookupByLibrary.simpleMessage("Баланс XDAI-депозитов"),
        "yam": MessageLookupByLibrary.simpleMessage("YAM"),
        "yamHistory": MessageLookupByLibrary.simpleMessage("История YAM"),
        "yamProjectionDescription":
            MessageLookupByLibrary.simpleMessage("Прогноз портфеля от YAM"),
        "yam_description": MessageLookupByLibrary.simpleMessage(
            "Инструмент для инвесторов RealT."),
        "year": MessageLookupByLibrary.simpleMessage("Год"),
        "yesWithPleasure":
            MessageLookupByLibrary.simpleMessage("Да, с удовольствием"),
        "yieldEvolution":
            MessageLookupByLibrary.simpleMessage("Динамика доходности"),
        "yieldEvolutionPercentage":
            MessageLookupByLibrary.simpleMessage("Изменение доходности:")
      };
}
