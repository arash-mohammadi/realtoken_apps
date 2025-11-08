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

## مشاهده‌ها و نکات تکمیلی
- تمام فراخوانی‌ها از طریق `ApiService` از الگوی کش Hive و کنترل فاصله‌ی بین درخواست‌ها استفاده می‌کنند؛ در صورت خطا یا نرخ‌محدودیت، داده از کش خوانده می‌شود.
- متد `_httpGetWithRetry` (بالای فایل `api_service.dart`) روی اکثر GETهای حساس اعمال شده و حداکثر 3 تلاش با delay افزایشی انجام می‌دهد؛ این رفتار در مستند بالا برای اندپوینت‌های مربوطه ذکر شد.
- درخواست‌های JSON-RPC به نود گنوسیس تنها خواندنی هستند (`eth_call`/`eth_getBalance`) و هیچ state تغییری ندارند، اما از آن‌جا که محدودیت نرخ نود رعایت شود، کش 1 دقیقه‌ای برای هر والت/کانترکت تعریف شده است.
- برای اضافه کردن API جدید کافی‌ست آن را به `ApiService` بیافزایید و این فایل را با اندپوینت، متد، ساختار درخواست/پاسخ و مکان مصرف به‌روزرسانی کنید تا شمارش کلی دقیق بماند.
