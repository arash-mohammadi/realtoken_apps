# فهرست کامل APIهای اپلیکیشن RealToken Apps

این سند بر اساس جستجوی کامل کد (تمام `http`/JSON-RPC ها در پوشه `lib` و سرویس‌های جانبی) تنظیم شد. منبع اصلی پیاده‌سازی‌ها [lib/services/api_service.dart](lib/services/api_service.dart) است؛ ادغام‌های دیگر در [lib/services/google_drive_service.dart](lib/services/google_drive_service.dart)، [lib/structure/drawer.dart](lib/structure/drawer.dart) و [lib/pages/changelog_page.dart](lib/pages/changelog_page.dart) انجام می‌شود.

## دامنه‌ها و نقش آن‌ها
| دامنه/سرویس | نقش | توضیح کوتاه |
| --- | --- | --- |
| `https://api.vfhome.fr` | بک‌اند اختصاصی | والت‌ها، تراکنش‌ها، تاریخچه قیمت/حجم |
| `https://api.pitsbi.io/api` | RealTokens/YAM | لیست دارایی‌ها و آفرهای YAM |
| `https://ehpst.duckdns.org/realt_rent_tracker/api` | Rent Tracker | اجاره، وایت‌لیست و اجارهٔ جزیی |
| `https://api.coingecko.com` | نرخ ارز | قیمت xDAI و تبدیل |
| `https://rpc.gnosischain.com` | JSON-RPC گنوسیس | خواندن مانده ERC20، xDAI و Vault |
| `https://realt.co/wp-json/realt/v1` | مارکت‌پلیس | املاک در حال فروش |
| `https://api.github.com` | به‌روزرسانی اپ | آخرین ریلیز گیت‌هاب |
| `https://raw.githubusercontent.com` | محتوا | دریافت `CHANGELOG.md` |
| Google Drive API (files.list/get/create/delete) | پشتیبان‌گیری | همگام‌سازی بکاپ در `appDataFolder` |
| کاشی نقشه OSM/Carto (`https://tile.openstreetmap.org/...`, `https://{s}.basemaps.cartocdn.com/...`) | کاشی نقشه | رندر نقشه در صفحه Map |

## اندپوینت‌ها به تفکیک صفحه/ویژگی

### پورتفو، داشبورد و ارزش دارایی
| متد و آدرس | پارامتر ورودی | پاسخ/دادهٔ مصرفی | توضیح |
| --- | --- | --- | --- |
| GET `https://api.vfhome.fr/wallet_userId/{address}` | `address` (path) | `{status,userId,addresses[]}` | واکشی شناسه کاربر و آدرس‌های مرتبط برای والت |
| GET `https://api.vfhome.fr/wallet_tokens/{wallet}` | `wallet` (path) | لیست توکن‌های والت | پر کردن پورتفو و مقداردهی دارایی‌ها |
| GET `https://api.vfhome.fr/transactions_history/{wallet}` | `wallet` (path) | آرایه تراکنش‌ها | تاریخچه تراکنش‌های هر والت، ادغام چند والت |
| GET `https://api.vfhome.fr/YAM_transactions_history/{wallet}` | `wallet` (path) | آرایه تراکنش‌های YAM | تاریخچه معاملات YAM برای والت‌ها |
| GET `https://api.vfhome.fr/token_history/?limit=10000` | query `limit` | آرایه قیمت تاریخی | نمودار ارزش توکن‌ها |
| GET `https://api.vfhome.fr/tokens_volume/` | — | آرایه حجم معاملات | چارت حجم معاملات |
| POST `https://rpc.gnosischain.com` (`eth_call`, selector `0x70a08231`) | JSON-RPC: `to` قرارداد، `data` شامل آدرس | `result` هگز → `BigInt` | مانده هر توکن ERC20 برای نمایش مقدار دارایی |
| POST `https://rpc.gnosischain.com` (`eth_getBalance`) | JSON-RPC: آدرس در `params` | `result` هگز → `BigInt` | مانده xDAI (نقدینگی) |
| POST `https://rpc.gnosischain.com` (`eth_call`, selector `0xf262a083`) | JSON-RPC: `to` Vault، `data` با آدرس | `result` هگز → `BigInt` | سهم Vault REG هر والت |
| GET `https://api.coingecko.com/api/v3/coins/xdai` | — | `market_data.current_price` | نرخ تبدیل xDAI و ارزها |

### بازار اولیه RealTokens
| متد و آدرس | پارامتر | پاسخ/دادهٔ مصرفی | توضیح |
| --- | --- | --- | --- |
| GET `https://api.pitsbi.io/api/last_get_realTokens_mobileapps` | — | رشته زمان ISO | تشخیص نیاز به رفرش داده‌های توکن |
| GET `https://api.pitsbi.io/api/realTokens_mobileapps` | — | لیست کامل دارایی‌ها (RealToken DTO) | فهرست دارایی‌ها و جزئیات کارت/صفحه توکن |

### بازار ثانویه YAM
| متد و آدرس | پارامتر | پاسخ/دادهٔ مصرفی | توضیح |
| --- | --- | --- | --- |
| GET `https://api.pitsbi.io/api/last_update_yam_offers_mobileapps` | — | زمان آخرین آپدیت | اعتبارسنجی کش آفرها |
| GET `https://api.pitsbi.io/api/get_yam_offers_mobileapps` | — | لیست `YamOffer` | نمایش آفرهای خرید/فروش |

### Rent / درآمد اجاره
| متد و آدرس | پارامتر | پاسخ/دادهٔ مصرفی | توضیح |
| --- | --- | --- | --- |
| GET `https://ehpst.duckdns.org/realt_rent_tracker/api/rent_holder/{wallet}` | `wallet` | لیست `{date,rent,token}` | نمودار درآمد اجاره |
| GET `https://ehpst.duckdns.org/realt_rent_tracker/api/whitelist2/{wallet}` | `wallet` | لیست توکن‌ها | فیلتر توکن‌های مجاز کاربر |
| GET `https://ehpst.duckdns.org/realt_rent_tracker/api/detailed_rent_holder/{wallet}` | `wallet` | آرایه اجارهٔ جزیی + الحاق `wallet` | جزئیات خط‌به‌خط درآمد |

### Properties For Sale (مارکت‌پلیس)
| متد و آدرس | پارامتر | پاسخ/دادهٔ مصرفی | توضیح |
| --- | --- | --- | --- |
| GET `https://realt.co/wp-json/realt/v1/products/for_sale` | — | `data.products[]` | نمایش املاک در حال فروش |

### به‌روزرسانی نسخه و چنج‌لاگ
| متد و آدرس | پارامتر | پاسخ/دادهٔ مصرفی | توضیح |
| --- | --- | --- | --- |
| GET `https://api.github.com/repos/RealToken-Community/realtoken_apps/releases/latest` | Header `Accept: application/vnd.github.v3+json` | JSON ریلیز (`tag_name`, ...) | مقایسه نسخه و اعلان آپدیت |
| GET `https://raw.githubusercontent.com/RealToken-Community/realtoken_apps/refs/heads/main/CHANGELOG.md` | — | متن Markdown | نمایش چنج‌لاگ در اپ |

### همگام‌سازی و بکاپ Google Drive
| API (Google Drive v3) | متد/درخواست | خروجی | توضیح |
| --- | --- | --- | --- |
| `files.list` در فضای `appDataFolder` | جستجو با `q` (نام `MeProp_Backup.zip`) | لیست فایل‌ها | یافتن بکاپ موجود |
| `files.get` با `downloadOptions: fullMedia` | دانلود باینری ZIP | استریم فایل | دریافت بکاپ برای بازیابی |
| `files.create` + `uploadMedia` | آپلود ZIP به `appDataFolder` | متادیتا فایل | ذخیره بکاپ تازه |
| `files.delete` | حذف با `fileId` | وضعیت حذف | پاک‌سازی بکاپ قدیمی |

### کاشی نقشه (صفحه Map)
| متد و آدرس | نوع محتوا | توضیح |
| --- | --- | --- |
| GET `https://tile.openstreetmap.org/{z}/{x}/{y}.png` | PNG tiles | نقشه پایه OSM |
| GET `https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png` | PNG tiles | تم تاریک Carto |
| GET `https://www.google.com/maps/@?api=1&map_action=pano&viewpoint=lat,lng` | deep link | باز کردن Street View در مرورگر |

## مدل‌های Request/Response (بر اساس مصرف اپ)

> نکته: این مدل‌ها «حداقل فیلدهایی» هستند که اپ در کد مصرف می‌کند. ممکن است API فیلدهای بیشتری هم برگرداند ولی تا زمانی که این فیلدها حفظ شوند، اپ کار می‌کند.

### 1) GET https://api.vfhome.fr/wallet_userId/{address}
**Request**
- Path: `address` (رشته 0x…)

**Response**
```ts
type WalletUserResponse =
	| { status: "success"; userId: string; addresses: string[] }
	| { status: "error"; message: string };
```

### 2) GET https://api.vfhome.fr/wallet_tokens/{wallet}
**Request**
- Path: `wallet`

**Response**
```ts
interface WalletTokenDto {
	wallet: string;
	token: string;           // آدرس قرارداد RealToken
	amount: number;          // تعداد
	type: "wallet" | "rmm";  // منبع موجودی
}
```

### 3) GET https://api.pitsbi.io/api/last_get_realTokens_mobileapps
**Response**
- `string` (متن خام ISO8601 مثل `2025-01-01T12:34:56Z`)

### 4) GET https://api.pitsbi.io/api/realTokens_mobileapps
**Response (مدل فشرده‌شده بر اساس فیلدهای مصرفی در اپ)**
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

	propertyType: number;
	productType: string;
	rentalType: string;
	rentedUnits: number;

	coordinate: { lat: number; lng: number };
	imageLink: string[];
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
	historic?: Record<string, unknown>;

	ethereumContract?: string;
	gnosisContract?: string;
}
```

### 5) GET https://api.pitsbi.io/api/last_update_yam_offers_mobileapps
**Response**
- `string` (ISO8601)

### 6) GET https://api.pitsbi.io/api/get_yam_offers_mobileapps
**Response**
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

### 7) GET https://ehpst.duckdns.org/realt_rent_tracker/api/rent_holder/{wallet}
**Response**
```ts
interface RentEntry {
	date: string;
	rent: number | string;
	token: string;
}
```

### 8) GET https://ehpst.duckdns.org/realt_rent_tracker/api/whitelist2/{wallet}
**Response**
```ts
interface WhitelistEntry {
	token: string;
	// ممکن است فیلدهای دیگری هم وجود داشته باشد ولی اپ فقط token را چک می‌کند.
	[k: string]: unknown;
}
```

### 9) GET https://ehpst.duckdns.org/realt_rent_tracker/api/detailed_rent_holder/{wallet}
**Response**
```ts
interface DetailedRentSlice {
	date: string;
	token_uuid?: string;
	token?: string;
	rentStartDate?: string;
	rents: { token: string; rent: number }[];
	dailyIncome?: number;

	// اپ هنگام ذخیره در کش اضافه می‌کند (ممکن است از API خام نیاید)
	wallet?: string;
}
```

### 10) GET https://api.coingecko.com/api/v3/coins/xdai
**Response (فقط بخش مصرفی)**
```ts
interface CoinGeckoXdaiResponse {
	market_data: {
		current_price: Record<string, number>; // usd/eur/...
	};
}
```

### 11) POST https://rpc.gnosischain.com (JSON-RPC eth_call balanceOf)
**Request**
```json
{
	"jsonrpc": "2.0",
	"method": "eth_call",
	"params": [
		{ "to": "0xCONTRACT", "data": "0x70a08231...PADDED_ADDRESS" },
		"latest"
	],
	"id": 1
}
```
**Response**
```json
{ "jsonrpc": "2.0", "id": 1, "result": "0x..." }
```

### 12) POST https://rpc.gnosischain.com (JSON-RPC eth_getBalance)
**Request**
```json
{ "jsonrpc": "2.0", "method": "eth_getBalance", "params": ["0xADDRESS", "latest"], "id": 1 }
```
**Response**
```json
{ "jsonrpc": "2.0", "id": 1, "result": "0x..." }
```

### 13) POST https://rpc.gnosischain.com (JSON-RPC eth_call selector 0xf262a083)
**Request**
```json
{
	"jsonrpc": "2.0",
	"method": "eth_call",
	"params": [
		{ "to": "0xVAULT_CONTRACT", "data": "0xf262a083...PADDED_ADDRESS" },
		"latest"
	],
	"id": 1
}
```
**Response**
```json
{ "jsonrpc": "2.0", "id": 1, "result": "0x..." }
```

### 14) GET https://realt.co/wp-json/realt/v1/products/for_sale
**Response (مدل حداقلی مصرفی)**
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

interface ProductsForSaleResponse {
	products: RealtyProduct[];
	[k: string]: unknown;
}
```

### 15) GET https://api.vfhome.fr/tokens_volume/
**Response (پیشنهادی/مصرفی)**
```ts
interface TokenVolumePoint {
	token_uuid: string;
	date: string;
	volume: number;
}
```

### 16) GET https://api.vfhome.fr/transactions_history/{wallet}
**Response**
```ts
interface TransactionHistoryEntry {
	"Token ID": string;
	timestamp: string;
	amount: number;
	sender: string;
	"Transaction ID": string;
}
```

### 17) GET https://api.vfhome.fr/YAM_transactions_history/{wallet}
**Response**
```ts
interface YamTransactionEntry {
	transaction_id: string;
	price: number;
	quantity: number;
	offer_token_address: string;
	timestamp: string;
}
```

### 18) GET https://api.vfhome.fr/token_history/?limit=10000
**Response**
```ts
interface TokenHistoryEntry {
	token_uuid: string;
	date: string;
	token_price: number;
}
```

### 19) GET https://api.github.com/repos/RealToken-Community/realtoken_apps/releases/latest
**Response**
```ts
interface GithubRelease {
	tag_name: string;
	name: string;
	body: string;
	html_url: string;
	published_at: string;
}
```

### 20) GET https://raw.githubusercontent.com/RealToken-Community/realtoken_apps/refs/heads/main/CHANGELOG.md
**Response**
- `text/plain` یا `text/markdown` (بدنه Markdown خام)

### Google Drive API (SDK)
اپ از Google Drive v3 با scopes زیر استفاده می‌کند:
- `https://www.googleapis.com/auth/drive.file`
- `https://www.googleapis.com/auth/drive.appdata`

**مدل‌های حداقلی مفهومی**
```ts
interface DriveFile {
	id: string;
	name: string;
	parents?: string[];
}

interface DriveFileList {
	files: DriveFile[];
}
```
عملیات‌ها:
- `files.list` (برای پیدا کردن `MeProp_Backup.zip` در `appDataFolder`)
- `files.get` (دانلود ZIP)
- `files.create` (آپلود ZIP)
- `files.delete` (حذف فایل)

### OneSignal (SDK)
اپ OneSignal را مقداردهی می‌کند و با APIهای داخلی SDK کار می‌کند (اندپوینت‌های HTTP در کد شما مستقیم قابل استخراج نیستند چون داخل SDK هستند).
- `OneSignal.initialize(<appId>)`
- `OneSignal.Notifications.requestPermission(true)`
- `OneSignal.User.pushSubscription.optIn()/optOut()`

### Firebase (SDK)
در کد Flutter فقط `Firebase.initializeApp(...)` دیده می‌شود و فراخوانی مستقیم Firestore/Functions/Auth مشاهده نشد. (در صورت اضافه شدن هر سرویس Firebase، این سند باید با مدل‌های آن سرویس بروزرسانی شود.)

## ابزارهای جانبی (Python داخل ریپو)
این‌ها جزو اجرای Flutter نیستند ولی در همین ریپو درخواست شبکه دارند:

### GET https://api.realtoken.community/v1/tokenHistory
در [main.py](main.py) و [token_history_additions.py](token_history_additions.py) مصرف می‌شود.

**Response (حداقل چیزی که اسکریپت انتظار دارد)**
```ts
interface ExternalTokenHistoryEntry {
	uuid: string;
	history: unknown[];
	[k: string]: unknown;
}
type ExternalTokenHistoryResponse = ExternalTokenHistoryEntry[];
```

## نکات اجرایی (از کد)
- اکثر GET ها با ریتری و timeout (۱۵–۴۵ ثانیه بسته به اندپوینت) در `ApiService` اجرا می‌شوند؛ در خطای 429 دادهٔ کش حفظ می‌شود.
- JSON-RPC های گنوسیس فقط خواندنی هستند؛ نتایج به `BigInt` تبدیل و در کش Hive ذخیره می‌شوند.
- کش زمانی برای برخی داده‌ها: RealTokens/YAM (چند ساعت)، token volumes (۴ ساعت)، products for sale (۶ ساعت)، تراکنش‌ها و تاریخچه قیمت (۳–۴۵ دقیقه/ساعت بسته به متد).
- Google Drive با OAuth (`drive.file` و `drive.appdata`) برای پشتیبان‌گیری ترکیب Hive/SharedPreferences استفاده می‌شود؛ بکاپ در فایل فشرده `MeProp_Backup.zip` نگهداری می‌شود.

## ارجاع فایل‌های کد
- پیاده‌سازی اصلی API: [lib/services/api_service.dart](lib/services/api_service.dart)
- توابع کمکی ریتری: [lib/services/api_service_helpers.dart](lib/services/api_service_helpers.dart)
- Google Drive و بکاپ: [lib/services/google_drive_service.dart](lib/services/google_drive_service.dart)
- اعلان نسخه: [lib/structure/drawer.dart](lib/structure/drawer.dart)
- صفحه چنج‌لاگ: [lib/pages/changelog_page.dart](lib/pages/changelog_page.dart)
- تنظیمات دامنه‌ها: [lib/utils/parameters.dart](lib/utils/parameters.dart)
