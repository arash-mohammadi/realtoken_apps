# مستند فراخوانی‌های API در پروژه `realtoken_apps`

## خلاصه سریع
- **تعداد کل فراخوانی‌های مجزا:** 20 اندپوینت HTTP/JSON-RPC که در کد صدا زده می‌شوند (جزئیات در جدول بعدی).
- **تعداد ریموت‌ریپو / دامنه‌ی خارجی:** 8 سرویس متمایز.
- **پوشش:** تمام `http.*`‌ها، کلاینت تکرار‌شونده `_httpGetWithRetry` و فراخوانی‌های JSON-RPC در `lib/services/api_service.dart` به‌همراه دو مصرف‌کننده دیگر (`lib/structure/drawer.dart` و `lib/pages/changelog_page.dart`).

### ریموت‌ریپوها و نقش آن‌ها
| دامنه | نقش | اندپوینت‌های استفاده‌شده |
| --- | --- | --- |
| `api.vfhome.fr` | بک‌اند FastAPI اختصاصی (والت‌ها، تراکنش‌ها، آمار) | `/wallet_userId`, `/wallet_tokens`, `/tokens_volume/`, `/transactions_history`, `/YAM_transactions_history`, `/token_history` |
| `api.pitsbi.io` | سرویس RealTokens/YAM (لیست توکن‌ها و آفرها) | `/realTokens_mobileapps`, `/last_get_realTokens_mobileapps`, `/get_yam_offers_mobileapps`, `/last_update_yam_offers_mobileapps` |
| `ehpst.duckdns.org` | Rent Tracker (loy­er, whitelist, detailed rent) | `/rent_holder`, `/whitelist2`, `/detailed_rent_holder` |
| `api.coingecko.com` | نرخ بازار رمز‌ارزها | `/api/v3/coins/xdai` |
| `rpc.gnosischain.com` | نود JSON-RPC گنوسیس برای خواندن موجودی قراردادها و xDAI | متدهای `eth_call`, `eth_getBalance` با بدنه‌های سفارشی |
| `realt.co` | وردپرس مارکت‌پلیس جهت دریافت محصولات در حال فروش | `/wp-json/realt/v1/products/for_sale` |
| `api.github.com` | بررسی آخرین نسخه اپلیکیشن | `/repos/RealToken-Community/realtoken_apps/releases/latest` |
| `raw.githubusercontent.com` | دریافت فایل CHANGELOG.md | `/RealToken-Community/realtoken_apps/refs/heads/main/CHANGELOG.md` |

## جدول کامل فراخوانی‌ها
| # | اندپوینت / دامنه | متد | درخواست (Headers/Body/Timeout) | پاسخ و داده‌ی مصرفی | مرجع در کد |
| --- | --- | --- | --- | --- | --- |
| 1 | `https://api.vfhome.fr/wallet_userId/{address}` | GET | `Content-Type: application/json`; پارامتر مسیری `address`; timeout پیش‌فرض `http.get`. | JSON شمای `{"status": "...", "userId": "...", "addresses": []}`؛ خروجی به `Map<String,dynamic>` تبدیل می‌شود. | `fetchUserAndAddresses` – `lib/services/api_service.dart:242-290` |
| 2 | `https://api.vfhome.fr/wallet_tokens/{wallet}` | GET | بدون بدنه؛ از `_httpGetWithRetry` با تاخیر و `timeout=15s` و retry استفاده می‌شود. | لیست توکن‌های والت (List<dynamic>) جهت ساخت پورتفو. | `fetchWalletTokens` – `lib/services/api_service.dart:293-356` |
| 3 | `https://api.pitsbi.io/api/last_get_realTokens_mobileapps` | GET | Timeout 10s؛ برای تشخیص به‌روزرسانی. | متن ISO8601 آخرین آپدیت؛ در Hive ذخیره می‌شود. | `fetchRealTokens.shouldUpdate` – `lib/services/api_service.dart:358-377` |
| 4 | `https://api.pitsbi.io/api/realTokens_mobileapps` | GET | Timeout 30s. | لیست کامل RealTokens (List<dynamic>)؛ بعد از موفقیت timestamp ردیابی می‌شود. | `fetchRealTokens` – `lib/services/api_service.dart:380-407` |
| 5 | `https://api.pitsbi.io/api/last_update_yam_offers_mobileapps` | GET | Timeout 10s (چک) و 5s (پس از ذخیره). | تاریخ آخرین آپدیت آفرهای YAM برای مقایسه با کش. | `fetchYamMarket.shouldUpdate` و بخش ذخیره – `lib/services/api_service.dart:427-468` |
| 6 | `https://api.pitsbi.io/api/get_yam_offers_mobileapps` | GET | Timeout 30s. | لیست آفرهای YAM (List<dynamic>) جهت نمایش بازار ثانویه. | `fetchYamMarket` – `lib/services/api_service.dart:449-468` |
| 7 | `https://ehpst.duckdns.org/realt_rent_tracker/api/rent_holder/{wallet}` | GET | از `_httpGetWithRetry` با `timeout=30s`; در صورت HTTP 429 کش فعلی حفظ می‌شود. | آرایه‌ای از رکوردهای اجاره `{date, rent, ...}`؛ برای ساخت نمودار درآمد. | `fetchRentData` – `lib/services/api_service.dart:485-720` |
| 8 | `https://ehpst.duckdns.org/realt_rent_tracker/api/whitelist2/{wallet}` | GET | Timeout 15s؛ در صورت 429 شکست را لاگ می‌کند. | لیست توکن‌های whitelist شده‌ی والت؛ در کش Hive ذخیره می‌شود. | `fetchWhitelistTokens` – `lib/services/api_service.dart:760-844` |
| 9 | `https://ehpst.duckdns.org/realt_rent_tracker/api/detailed_rent_holder/{wallet}` | GET | Timeout 2 دقیقه؛ هنگام 429 پردازش متوقف می‌شود. | آرایه‌ای از جزئیات لاین‌به‌لاین اجاره همراه با الحاق `wallet`. | `fetchDetailedRentDataForAllWallets` – `lib/services/api_service.dart:1190-1375` |
|10 | `https://api.coingecko.com/api/v3/coins/xdai` | GET | Timeout 15s. | شیء `market_data.current_price`؛ به Map تبدیل و برای نقدینگی/واحد نمایش نگه داشته می‌شود. | `fetchCurrencies` – `lib/services/api_service.dart:845-874` |
|11 | `https://rpc.gnosischain.com` (`eth_call` با `balanceOf`) | POST | بدنه JSON-RPC: `{"jsonrpc":"2.0","method":"eth_call","params":[{"to": contract,"data":"0x70a08231...{address}"},"latest"],"id":1}`؛ هدر `Content-Type: application/json`. | مقدار هگزادسیمال موجودی ERC20 → `BigInt` → تبدیل به double. کش در Hive (`balanceCache`). | `_fetchBalance` – `lib/services/api_service.dart:990-1050` |
|12 | `https://rpc.gnosischain.com` (`eth_getBalance`) | POST | JSON-RPC: `{"method":"eth_getBalance","params":[address,"latest"]}`. | موجودی native xDAI (`BigInt`)؛ برای نمایش نقدینگی و RMM به‌کار می‌رود. | `_fetchNativeBalance` – `lib/services/api_service.dart:1052-1096` |
|13 | `https://rpc.gnosischain.com` (`eth_call` با selector `0xf262a083`) | POST | JSON-RPC با بدنه حاوی `{"to": contract,"data": "0xf262a083...address"}`؛ timeout پیش‌فرض. | سهم Vault REG برای هر والت؛ نتیجه در کش ذخیره می‌شود. | `_fetchVaultBalance` – `lib/services/api_service.dart:1098-1147` |
|14 | `https://realt.co/wp-json/realt/v1/products/for_sale` | GET | Timeout 30s؛ کش 6ساعته. | `data["products"]` (List<Map<String,dynamic>>) جهت صفحه Properties For Sale. | `fetchPropertiesForSale` – `lib/services/api_service.dart:1538-1605` |
|15 | `https://api.vfhome.fr/tokens_volume/` | GET | Timeout 30s؛ کش 4ساعته. | داده‌ی حجمی معاملات (List<dynamic>). | `fetchTokenVolumes` – `lib/services/api_service.dart:1607-1634` |
|16 | `https://api.vfhome.fr/transactions_history/{wallet}` | GET | از `_httpGetWithRetry` با `timeout=30s`; درخواست‌ها به‌صورت موازی و حداکثر 3 همزمان. | لیست تراکنش‌های هر والت؛ سپس مرج می‌شود. | `fetchTransactionsHistory` – `lib/services/api_service.dart:1636-1680` |
|17 | `https://api.vfhome.fr/YAM_transactions_history/{wallet}` | GET | همان الگو با `_httpGetWithRetry`; cache 3ساعته. | تاریخچه تراکنش‌های مرتبط با YAM برای هر والت. | `fetchYamWalletsTransactions` – `lib/services/api_service.dart:1682-1732` |
|18 | `https://api.vfhome.fr/token_history/?limit=10000` | GET | `_httpGetWithRetry` با `timeout=45s`. | لیست حداکثر 10000 رکورد تاریخچه توکن؛ برای چارت‌های هولدینگ. | `fetchTokenHistory` – `lib/services/api_service.dart:1820-1852` |
|19 | `https://api.github.com/repos/RealToken-Community/realtoken_apps/releases/latest` | GET | Timeout 10s؛ Header `Accept: application/vnd.github.v3+json`. | JSON اطلاعات آخرین release (tag_name). نتیجه در کش `PerformanceUtils`. | `_loadVersions` در Drawer – `lib/structure/drawer.dart:74-109` |
|20 | `https://raw.githubusercontent.com/RealToken-Community/realtoken_apps/refs/heads/main/CHANGELOG.md` | GET | بدون header اضافی؛ در صورت خطا پیام فارسی نمایش داده می‌شود. | بدنه متنی markdown برای نمایش changelog. | `_fetchMarkdown` – `lib/pages/changelog_page.dart:24-44` |

> **نکته درباره شمارش:** ردیف‌های 7، 8، 9، 16، 17 و 18 برای هر والت چند بار اجرا می‌شوند، اما از نظر این مستند یک اندپوینت منحصربه‌فرد محسوب شده و در عدد نهایی 20 لحاظ گردیده‌اند. همچنین سه فراخوانی JSON-RPC (ردیف‌های 11 تا 13) با وجود اشتراک در دامنه، به‌دلیل تفاوت متد و بدنه به‌صورت جدا حساب شده‌اند.

## مدل‌های داده و ساختار پاسخ‌ها
در ادامه، برای هر اندپوینت تعریف‌شده در جدول بالا، ورودی/خروجی و فیلدهای کلیدی (بر اساس کدی که مصرفشان می‌کند) آورده شده‌است. برای سیستم بک‌اند پیشنهادی می‌توانید همین مدل‌ها را مستقیماً به DTO/Schema تبدیل کنید.

### 1. GET `/wallet_userId/{address}`
- **Request**: پارامتر مسیر `address` (رشته 0x…).
- **Response**:
```ts
type WalletUserResponse =
  | { status: "success"; userId: string; addresses: string[] }
  | { status: "error"; message: string };
```
  - ارجاع: `lib/services/api_service.dart:251-289`.

### 2. GET `/wallet_tokens/{wallet}`
- **Request**: پارامتر مسیر `wallet`؛ از `_httpGetWithRetry` با timeout 15s و retry استفاده می‌شود.
- **Response**: آرایه‌ای از `WalletTokenDto`.
```ts
interface WalletTokenDto {
  wallet: string;          // آدرس دارنده (lib/managers/data_manager.dart:1623-1650)
  token: string;           // قرارداد RealToken (line 1497)
  amount: number;          // تعداد توکن (1508, 1519)
  type: "wallet" | "rmm";  // منبع موجودی (1517-1525)
  // فیلدهای دیگری هم ممکن است از API بازگردند اما در اپ مصرف نمی‌شود.
}
```

### 3. GET `/last_get_realTokens_mobileapps`
- **Response**: بدنه متنی شامل `YYYY-MM-DDTHH:mm:ssZ`.
- **مصرف**: تنها برای مقایسه زمان کش (`lib/services/api_service.dart:358-377`).

### 4. GET `/realTokens_mobileapps`
- **Response**: آرایه‌ای از `RealTokenDto` با متادیتای کامل دارایی‌ها. مهم‌ترین فیلدهای مصرفی:
```ts
interface RealTokenDto {
  uuid: string;
  id: string;
  shortName: string;
  fullName: string;
  tokenPrice: number;
  totalTokens: number;
  totalUnits: number;
  rentStartDate?: { date: string };
  initialLaunchDate?: { date: string };
  netRentDayPerToken: number;
  netRentMonthPerToken: number;
  netRentYearPerToken: number;
  annualPercentageYield: number;
  grossRentMonth: number;
  netRentMonth: number;
  propertyType: int;
  productType: string;
  rentalType: string;
  rentedUnits: number;
  coordinate: { lat: double; lng: double };
  imageLink: List<string>;
  marketplaceLink: string;
  totalInvestment: number;
  underlyingAssetPrice?: number;
  realtListingFee?: number;
  initialMaintenanceReserve?: number;
  renovationReserve?: number;
  miscellaneousCosts?: number;
  propertyMaintenanceMonthly?: number;
  propertyManagement?: number;
  insurance?: number;
  propertyTaxes?: number;
  section8paid?: number;
  lotSize?: number;
  squareFeet?: number;
  bedroomBath?: string;
  propertyStories?: number;
  constructionYear?: number;
  historic?: Map;
  ethereumContract?: string;
  gnosisContract?: string;
}
```
  - مصرف: `lib/managers/data_manager.dart:1507-1695` و `1968-2174`.

### 5. GET `/last_update_yam_offers_mobileapps`
- **Response**: رشته زمان ISO برای اعتبارسنجی کش (`lib/services/api_service.dart:427-468`).

### 6. GET `/get_yam_offers_mobileapps`
- **Response**: آرایه‌ای از `YamOffer`.
```ts
interface YamOffer {
  id: string;
  id_offer: string;
  shortName: string;
  token_amount: number;
  token_price: number;
  token_value?: number;
  token_to_buy?: number;
  token_to_sell?: number;
  token_to_pay?: number;
  token_to_pay_digit?: number;
  token_digit?: number;
  annualPercentageYield?: number;
  creationDate?: string;
  creation_date?: string;
  timsync?: string;
  holder_address?: string;
  buy_holder_address?: string;
  offer_token_address?: string;
  block_number?: number;
  supp?: number;
}
```
- مصرف‌کنندگان: `lib/modals/token_details/tabs/market_tab.dart` و `lib/pages/propertiesForSale/PropertiesForSaleSecondary.dart`.

### 7. GET `/rent_holder/{wallet}`
- **Response**: لیست `RentEntry`.
```ts
interface RentEntry {
  date: string;
  rent: number | string;
  token: string;
}
```
- ارجاعات: `lib/services/api_service.dart:665-670` و `lib/managers/data_manager.dart:519-568`.

### 8. GET `/whitelist2/{wallet}`
- **Response**: آرایه‌ای از آبجکت‌هایی که حداقل حاوی `token: string` هستند؛ اپ فقط همین فیلد را بررسی می‌کند (`lib/pages/realtokens_page.dart:124-1260`).

### 9. GET `/detailed_rent_holder/{wallet}`
- **Response**: آرایه `DetailedRentSlice`.
```ts
interface DetailedRentSlice {
  date: string;
  token_uuid?: string;
  token?: string;
  rentStartDate?: string;
  rents: { token: string; rent: number }[];
  dailyIncome?: number;
  wallet?: string;  // اپ هنگام ذخیره اضافه می‌کند، api خام فقط اطلاعات اجاره را برمی‌گرداند.
}
```
- ارجاع: `lib/services/api_service.dart:1311-1357` و `lib/managers/data_manager.dart:560-569`.

### 10. GET `https://api.coingecko.com/api/v3/coins/xdai`
- **Response**: آبجکت کامل CoinGecko؛ اپ فقط `market_data.current_price` را به `Map<String,double>` می‌خواند (`lib/services/api_service.dart:863-874`).

### 11. POST `https://rpc.gnosischain.com` (eth_call → مانده ERC20)
- **Request**: JSON-RPC با `method: "eth_call"`, پارامتر `{"to": contract,"data":"0x70a08231...address"}`.
- **Response**: `{"result":"0xHEX"}` → `BigInt` (`lib/services/api_service.dart:990-1043`).

### 12. POST `https://rpc.gnosischain.com` (eth_getBalance)
- **Request**: `{"method":"eth_getBalance","params":[address,"latest"]}`.
- **Response**: `result` هگز برای xDAI (`lib/services/api_service.dart:1045-1089`).

### 13. POST `https://rpc.gnosischain.com` (Vault selector `0xf262a083`)
- **Request**: `eth_call` با داده‌ی `0xf262a083 + paddedAddress`.
- **Response**: هگز 32بایتی → `BigInt` (`lib/services/api_service.dart:1098-1147`).

### 14. GET `https://realt.co/wp-json/realt/v1/products/for_sale`
- **Response**:
```ts
interface RealtyProduct {
  shortName: string;
  title: string;
  city: string;
  country: string;
  tokenPrice: number;
  totalTokens: number;
  stock: number;
  status: string;
  annualPercentageYield: number;
  imageLink: string[];
  marketplaceLink: string;
}
```
- مصرف در `lib/pages/propertiesForSale/...`.

### 15. GET `/tokens_volume/`
- **Response**: لیستی از نقاط حجم. اپ انتظار دارد هر عنصر حداقل شامل شناسه توکن و مقدار حجم باشد؛ توصیه می‌شود ساختار زیر را ثابت نگه دارید:
```ts
interface TokenVolumePoint {
  token_uuid: string;
  date: string;
  volume: number;
}
```
- ارجاع: `lib/services/api_service.dart:1607-1634`.

### 16. GET `/transactions_history/{wallet}`
- **Response**:
```ts
interface TransactionHistoryEntry {
  "Token ID": string;
  timestamp: string;
  amount: number;
  sender: string;
  "Transaction ID": string;
}
```
- پردازش در `lib/managers/data_manager.dart:2008-2075`.

### 17. GET `/YAM_transactions_history/{wallet}`
- **Response**:
```ts
interface YamTransactionEntry {
  transaction_id: string;
  price: number;
  quantity: number;
  offer_token_address: string;
  timestamp: string;
}
```
- ارجاع: `lib/managers/data_manager.dart:2058-2075`.

### 18. GET `/token_history/?limit=10000`
- **Response**:
```ts
interface TokenHistoryEntry {
  token_uuid: string;
  date: string;
  token_price: number;
}
```
- استفاده در `lib/managers/data_manager.dart:2083-2135`.

### 19. GET `https://api.github.com/.../releases/latest`
- **Response**:
```ts
interface GithubRelease {
  tag_name: string;
  name: string;
  body: string;
  html_url: string;
  published_at: string;
}
```
- مصرف: `lib/structure/drawer.dart:74-109`.

### 20. GET `https://raw.githubusercontent.com/.../CHANGELOG.md`
- **Response**: متن Markdown خالص که مستقیماً نمایش داده می‌شود (`lib/pages/changelog_page.dart:24-44`).

### نکات طراحی بک‌اند
- اندپوینت‌های وابسته به والت (Rent، تاریخچه تراکنش، YAM) انتظار دارند خروجی به‌صورت قابل ادغام بین چند والت باشد؛ بنابراین وجود کلیدهای `date/timestamp`, `token`, `wallet` برای تشخیص رکوردها حیاتی است.
- گسترش اسکیمای پاسخ آزاد است تا زمانی که فیلدهای فعلی حفظ شوند. برای فیلدهای استفاده‌نشده (مثل داده‌های اضافه در whitelist) از `additionalProperties` استفاده کنید تا ناسازگاری ایجاد نشود.

## مشاهده‌ها و نکات تکمیلی
- تمام فراخوانی‌ها از طریق `ApiService` از الگوی کش Hive و کنترل فاصله‌ی بین درخواست‌ها استفاده می‌کنند؛ در صورت خطا یا نرخ‌محدودیت، داده از کش خوانده می‌شود.
- متد `_httpGetWithRetry` (بالای فایل `api_service.dart`) روی اکثر GETهای حساس اعمال شده و حداکثر 3 تلاش با delay افزایشی انجام می‌دهد؛ این رفتار در مستند بالا برای اندپوینت‌های مربوطه ذکر شد.
- درخواست‌های JSON-RPC به نود گنوسیس تنها خواندنی هستند (`eth_call`/`eth_getBalance`) و هیچ state تغییری ندارند، اما از آن‌جا که محدودیت نرخ نود رعایت شود، کش 1 دقیقه‌ای برای هر والت/کانترکت تعریف شده است.
- برای اضافه کردن API جدید کافی‌ست آن را به `ApiService` بیافزایید و این فایل را با اندپوینت، متد، ساختار درخواست/پاسخ و مکان مصرف به‌روزرسانی کنید تا شمارش کلی دقیق بماند.
