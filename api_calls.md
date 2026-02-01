# API Calls Documentation (Web App)

> Collapsible sections for each endpoint. Fill in **method**, **request body**, and **response**.

## Main Domains
- https://api.vfhome.fr  
- https://api.pitsbi.io/api  
- https://ehpst.duckdns.org/realt_rent_tracker/api  
- https://api.coingecko.com  
- https://rpc.gnosischain.com  
- https://realt.co/wp-json/realt/v1  
- https://api.github.com  
- https://raw.githubusercontent.com  

---

## Portfolio & Transactions

<details>
<summary><code>https://api.vfhome.fr/wallet_userId/0xd7a6A4b95E29CE5f8f45404d1251178DAFE75AF3</code></summary>

**Method:** `GET`

### Response
```json
[]
```
</details>

<details>
<summary><code>https://api.vfhome.fr/wallet_tokens/{wallet}</code></summary>

**Method:** `GET`

### Response
```json
[
  {
    "wallet": "0xd7a6A4b95E29CE5f8f45404d1251178DAFE75AF3",
    "token": "0xMOCKTOKEN1",
    "amount": 100.0,
    "type": "wallet"
  },
  {
    "wallet": "0xd7a6A4b95E29CE5f8f45404d1251178DAFE75AF3",
    "token": "0xMOCKTOKEN2",
    "amount": 75.0,
    "type": "rmm"
  }
]
```
</details>

<details>
<summary><code>https://api.vfhome.fr/transactions_history/{wallet}</code></summary>

**Method:** `GET`

### Request body
None

### Response
```json
[
  {
    "Token ID": "0xMOCKTOKEN1",
    "timestamp": "1678886400",
    "amount": 50.0,
    "sender": "0xSENDERADDRESS",
    "Transaction ID": "0xTRANSACTIONHASH"
  }
]
```
</details>

<details>
<summary><code>https://api.vfhome.fr/YAM_transactions_history/{wallet}</code></summary>

**Method:** `GET`

### Request body
None

### Response
```json
[
  {
    "transaction_id": "0xTRANSACTIONHASH",
    "timestamp": "1678886400",
    "price": 50.5,
    "quantity": 10.0,
    "offer_token_address": "0xMOCKTOKEN1"
  }
]
```
</details>

<details>
<summary><code>https://api.vfhome.fr/token_history/?limit=10000</code></summary>

**Method:** `GET`

### Request body
None

### Response
```json
[
  {
    "token_uuid": "0xMOCKTOKEN1",
    "date": "2023-01-01",
    "token_price": 50.5,
    "underlying_asset_price": 150000.0,
    "total_investment": 160000.0,
    "gross_rent_year": 15000.0,
    "net_rent_year": 12000.0,
    "rented_units": 1,
    "canal": "primary",
    "renovation_reserve": 5000.0,
    "initial_maintenance_reserve": 2000.0
  }
]
```
</details>

<details>
<summary><code>https://api.vfhome.fr/tokens_volume/</code></summary>

**Method:** `GET`

### Request body
None

### Response
```json
[
  {
    "token": "0xMOCKTOKEN1",
    "volume": 500.0,
    "quantity": 10.0,
    "date": "2023-01-01"
  }
]
```
</details>

---

## RealTokens & YAM

<details>
<summary><code>https://api.pitsbi.io/api/last_get_realTokens_mobileapps</code></summary>

**Method:** `GET`

### Response
```text
"2026-01-03T20:01:50.817557Z"
```

</details>

<details>
<summary><code>https://api.pitsbi.io/api/realTokens_mobileapps</code></summary>

**Method:** `GET`

### Request body
None

### Response
```json
[
   {
    "id": 230,
    "fullName": "9415-9417 Ravenswood St, Detroit, MI 48204",
    "shortName": "9415-9417 Ravenswood",
    "symbol": "REALTOKEN-S-9415-9417-RAVENSWOOD-ST-DETROIT-MI",
    "tokenPrice": 53.59,
    "canal": "release",
    "currency": "USD",
    "totalTokens": 1850,
    "totalTokensRegSummed": 1850,
    "uuid": "0x65d81BF81a65b177012B323F14970071c5099226",
    "ethereumContract": "0x65d81bf81a65b177012b323f14970071c5099226",
    "xDaiContract": "0x65d81bf81a65b177012b323f14970071c5099226",
    "gnosisContract": "0x65d81bf81a65b177012b323f14970071c5099226",
    "goerliContract": null,
    "totalInvestment": 99150,
    "grossRentYear": 18660,
    "grossRentMonth": 1555,
    "propertyManagement": 124.4,
    "propertyManagementPercent": 0.08,
    "realtPlatform": 31.1,
    "realtPlatformPercent": 0.02,
    "insurance": 55,
    "propertyTaxes": 130,
    "utilities": 0,
    "initialMaintenanceReserve": 1150,
    "neighborhood": "Petoskey-Otsego",
    "netRentDay": 0,
    "netRentMonth": 0,
    "netRentYear": 0,
    "netRentDayPerToken": 0,
    "netRentMonthPerToken": 0,
    "netRentYearPerToken": 0,
    "annualPercentageYield": 0,
    "coordinate": {
      "lat": "42.367476",
      "lng": "-83.130921"
    },
    "marketplaceLink": "https://realt.co/product/9415-9417-ravenswood-st-detroit-mi-48204/",
    "imageLink": [
      "https://realt.co/wp-content/uploads/2022/04/9415-9417-Ravenswood-hero-1.jpg",
      "https://realt.co/wp-content/uploads/2022/04/9415-9417-Ravenswood-side-1.jpg",
      "https://realt.co/wp-content/uploads/2022/04/9415-9417-Ravenswood-aerial-1.jpg",
      "https://realt.co/wp-content/uploads/2022/04/9415-9417-Ravenswood-aerial-2.jpg",
      "https://realt.co/wp-content/uploads/2022/04/9415-9417-Ravenswood-living-1.jpg",
      "https://realt.co/wp-content/uploads/2022/04/9415-9417-Ravenswood-living-2.jpg"
    ],
    "propertyType": 3,
    "propertyTypeName": "Duplex",
    "squareFeet": 2078,
    "lotSize": 3615,
    "bedroomBath": "3 Bed / 2 Bath",
    "hasTenants": true,
    "rentedUnits": 0,
    "totalUnits": 2,
    "termOfLease": null,
    "renewalDate": null,
    "section8paid": 0,
    "subsidyStatus": "no",
    "subsidyStatusValue": null,
    "subsidyBy": null,
    "sellPropertyTo": "intl_investors_only",
    "secondaryMarketplace": {
      "UniswapV1": 0,
      "UniswapV2": 0
    },
    "secondaryMarketplaces": [
      {
        "chainId": 100,
        "chainName": "xDaiChain",
        "dexName": "LevinSwap",
        "contractPool": "0x0ab05decf91899da0a4037a0e50ad9a132888adb",
        "pair": {
          "contract": "0x6a023ccd1ff6f2045c3309768ead9e68f978f6e1",
          "symbol": "WETH",
          "name": "Wrapped Ether on xDai"
        }
      }
    ],
    "blockchainAddresses": {
      "xDai": {
        "chainId": 100,
        "contract": "0x65d81BF81a65b177012B323F14970071c5099226",
        "chainName": "xDaiChain",
        "distributor": "0xfe0dbc610c72505be8dab1f22fea2d60933ebc36",
        "rmmPoolAddress": "0x03C4413365C7376a0Ab90288C142bED8c05d2E97",
        "rmmV3WrapperAddress": "0x10497611Ee6524D75FC45E3739F472F83e282AD5",
        "chainlinkPriceContract": "0x3a9BD51f304aD6e986ee4f19B8a92C63c48D686f"
      },
      "sepolia": {
        "chainId": 11155111,
        "contract": 0,
        "chainName": "Sepolia testnet",
        "distributor": 0,
        "rmmPoolAddress": 0,
        "chainlinkPriceContract": 0
      },
      "ethereum": {
        "chainId": 1,
        "contract": "0x65d81BF81a65b177012B323F14970071c5099226",
        "chainName": "Ethereum",
        "distributor": "0xfe0dbc610c72505be8dab1f22fea2d60933ebc36",
        "maintenance": "0x2944c261Fe6bFbED7e432fcf66a860af7aF7033a"
      }
    },
    "underlyingAssetPrice": 98000,
    "renovationReserve": null,
    "propertyMaintenanceMonthly": 155,
    "rentStartDate": {
      "date": "2022-05-01 00:00:00.000000",
      "timezone": "UTC",
      "timezone_type": 3
    },
    "lastUpdate": {
      "date": "2023-08-15 22:21:47.000000",
      "timezone": "UTC",
      "timezone_type": 3
    },
    "originSecondaryMarketplaces": [
      {
        "chainId": 100,
        "chainName": "xDaiChain",
        "dexName": "LevinSwap",
        "contractPool": "0x0ab05decf91899da0a4037a0e50ad9a132888adb"
      }
    ],
    "initialLaunchDate": {
      "date": "2022-04-28 00:00:00.000000",
      "timezone": "UTC",
      "timezone_type": 3
    },
    "seriesNumber": 202,
    "constructionYear": 1922,
    "constructionType": "Brick",
    "roofType": "Asphalt",
    "assetParking": "1 Space",
    "foundation": "Masonry",
    "heating": "Forced Air / Natural Gas",
    "cooling": "None",
    "tokenIdRules": 100198,
    "rentCalculationType": "constant",
    "realtListingFeePercent": null,
    "realtListingFee": null,
    "miscellaneousCosts": null,
    "propertyStories": 2,
    "rentalType": "long_term",
    "productType": "real_estate_rental",
    "timsync": "2025-12-17T07:44:00.087828",
    "update7": [
      {
        "id": 88400,
        "realtokens_id": 230,
        "key": "annualPercentageYield",
        "old_value": "0",
        "new_value": "12.824094854324",
        "timsync": "2025-12-29T23:41:46.658135"
      }
    ],
    "update30": [
      {
        "id": 88400,
        "realtokens_id": 230,
        "key": "annualPercentageYield",
        "old_value": "0",
        "new_value": "12.824094854324",
        "timsync": "2025-12-29T23:41:46.658135"
      }
    ],
    "historic": {
      "yields": [
        {
          "timsync": "2022-05-01T00:00:00",
          "yield": 11.426678704797,
          "days_rented": 435.57893641647
        },
        {
          "timsync": "2023-07-10T13:53:40",
          "yield": 4.8722373292446,
          "days_rented": 160.172718647905
        },
        {
          "timsync": "2023-12-17T18:02:22",
          "yield": 12.949893954045,
          "days_rented": 42.3212527267014
        },
        {
          "timsync": "2024-01-29T01:44:59",
          "yield": 12.223903177005,
          "days_rented": 217.200861944907
        },
        {
          "timsync": "2024-09-02T06:34:13",
          "yield": 12.822995461422,
          "days_rented": 321.22624183809
        },
        {
          "timsync": "2025-07-20T12:00:01",
          "yield": 0,
          "days_rented": 162.487334006192
        },
        {
          "timsync": "2025-12-29T23:41:46",
          "yield": 12.824094854324,
          "days_rented": 4.81439281396991
        }
      ],
      "prices": [
        {
          "timsync": "2022-05-01T00:00:00",
          "price": 50.59
        },
        {
          "timsync": "2024-01-29T01:44:59",
          "price": 53.59
        }
      ],
      "avg_yield": 9.77937488316988,
      "init_yield": 11.426678704797,
      "init_price": 50.59
    },
    "is_rmm": true,
    "rent_start": "2022-05-01T00:00:00",
    "actions": {
      "exhibit_number": 45,
      "volume": 3,
      "priority": 1,
      "realt_status": "Scheduled",
      "coc": false
    },
    "pool": {
      "nbTokenRealt": 8.01461493106966,
      "realtName": "RealToken S 9415-9417 Ravenswood St Detroit MI",
      "coinId": "0x6a023ccd1ff6f2045c3309768ead9e68f978f6e1",
      "coinName": "Wrapped Ether on xDai",
      "realtRatio": 0.533685826811165,
      "holderRatio": 0.466314173188835
    },
    "firstRentStartDate": "2022-05-01T00:00:00"
  }
]
```
</details>

<details>
<summary><code>https://api.pitsbi.io/api/last_update_yam_offers_mobileapps</code></summary>

**Method:** `GET`

### Response
```json
"2026-01-03T20:50:57.639204Z"
```
</details>

<details>
<summary><code>https://api.pitsbi.io/api/get_yam_offers_mobileapps</code></summary>

**Method:** `GET`


### Response
```json
[
  {
    "id": 235032,
    "id_offer": 210236,
    "token_to_buy": null,
    "token_to_sell": "0x4ae9d3343bbc6a894b7ee7f843c224c953f1661b",
    "token_to_pay": "0xddafbb505ad214d7b80b1f830fccc89b60fb7a83",
    "token_to_pay_digit": 6,
    "holder_address": "0x9efcdbd0b0509f0b09c98c0250a9c00c9b5ee8ea",
    "buy_holder_address": "0x0000000000000000000000000000000000000000",
    "token_amount": 0.954144989339019,
    "token_value": 49.25,
    "token_digit": 18,
    "block_number": 0,
    "verif_supp": 0,
    "supp": false,
    "creation_date": "2026-01-03T18:09:21.059628",
    "timsync": "2026-01-03T18:09:34.668164"
  },
  {
    "id": 150763,
    "id_offer": 126665,
    "token_to_buy": null,
    "token_to_sell": "0xb5dd2b6e0a0422e069e1d2cc3ed16533488a05e3",
    "token_to_pay": "0xe91d153e0b41518a2ce8dd3d7944fa863463a97d",
    "token_to_pay_digit": 18,
    "holder_address": "0xab1c40889175ea24b83175d9e09ee335ddf5a1ab",
    "buy_holder_address": "0x0000000000000000000000000000000000000000",
    "token_amount": 1,
    "token_value": 64,
    "token_digit": 18,
    "block_number": 0,
    "verif_supp": 0,
    "supp": false,
    "creation_date": "2025-06-15T20:09:18.621512",
    "timsync": "2026-01-03T18:12:34.995217"
  },
]
```
</details>

---

## Rent

<details>
<summary><code>https://ehpst.duckdns.org/realt_rent_tracker/api/rent_holder/{wallet}</code></summary>

**Method:** `GET`

### Request body
None

### Response
```json
[
  {
    "date": "2023-01-01",
    "rent": 12.5,
    "token": "0xMOCKTOKEN1"
  }
]
```
</details>

<details>
<summary><code>https://ehpst.duckdns.org/realt_rent_tracker/api/whitelist2/{wallet}</code></summary>

**Method:** `GET`

### Request body
None

### Response
```json
[
  {
    "token": "0xMOCKTOKEN1"
  }
]
```
</details>

<details>
<summary><code>https://ehpst.duckdns.org/realt_rent_tracker/api/detailed_rent_holder/{wallet}</code></summary>

**Method:** `GET`

### Request body
None

### Response
```json
[
  {
    "date": "2023-01-01",
    "rents": [
      {
        "token": "0xMOCKTOKEN1",
        "rent": 12.5
      }
    ]
  }
]
```
</details>

---

## Marketplace & Price

<details>
<summary><code>https://realt.co/wp-json/realt/v1/products/for_sale</code></summary>

**Method:** `GET`

### Request body
none

### Response
```json
{
  "time": 1767474068,
  "date": "2026-01-03 21:01:08 UTC",
  "products": [
    {
      "title": "Factoring, Profit Share, Type B, Series 19",
      "status": "Available",
      "product_id": 958950,
      "stock": 1733,
      "max_purchase": 400
    },
    {
      "title": "Vervana T1v2, Playa Venao, Los Santos, Panama",
      "status": "Available",
      "product_id": 949273,
      "stock": 1436.785728,
      "max_purchase": 2050
    },
    {
      "title": "Vigo 1207, Medellin, Antioquia, Colombia",
      "status": "Available",
      "product_id": 949261,
      "stock": 720,
      "max_purchase": 230
    },
  ]
}
```
</details>

<details>
<summary><code>https://api.coingecko.com/api/v3/coins/xdai</code></summary>

**Method:** `GET`

### Request body
None

### Response
```json
{
  "market_data": {
    "current_price": {
      "usd": 1.0,
      "eur": 0.92,
      "chf": 0.89,
      "gbp": 0.79
    }
  }
}
```
</details>

---

## Other

<details>
<summary><code>https://api.github.com/repos/RealToken-Community/realtoken_apps/releases/latest</code></summary>

**Method:** `GET`

### Response used
```json
{
  "tag_name": "v1.2.3",
  "name": "Release 1.2.3",
  "body": "Release notes...",
  "html_url": "https://github.com/RealToken-Community/realtoken_apps/releases/tag/v1.2.3",
  "published_at": "2023-01-01T12:00:00Z"
}
```

### full response 
```json
{
  "url": "https://api.github.com/repos/RealToken-Community/realtoken_apps/releases/221015140",
  "assets_url": "https://api.github.com/repos/RealToken-Community/realtoken_apps/releases/221015140/assets",
  "upload_url": "https://uploads.github.com/repos/RealToken-Community/realtoken_apps/releases/221015140/assets{?name,label}",
  "html_url": "https://github.com/RealToken-Community/realtoken_apps/releases/tag/1.10.1",
  "id": 221015140,
  "author": {
    "login": "byackee",
    "id": 4707496,
    "node_id": "MDQ6VXNlcjQ3MDc0OTY=",
    "avatar_url": "https://avatars.githubusercontent.com/u/4707496?v=4",
    "gravatar_id": "",
    "url": "https://api.github.com/users/byackee",
    "html_url": "https://github.com/byackee",
    "followers_url": "https://api.github.com/users/byackee/followers",
    "following_url": "https://api.github.com/users/byackee/following{/other_user}",
    "gists_url": "https://api.github.com/users/byackee/gists{/gist_id}",
    "starred_url": "https://api.github.com/users/byackee/starred{/owner}{/repo}",
    "subscriptions_url": "https://api.github.com/users/byackee/subscriptions",
    "organizations_url": "https://api.github.com/users/byackee/orgs",
    "repos_url": "https://api.github.com/users/byackee/repos",
    "events_url": "https://api.github.com/users/byackee/events{/privacy}",
    "received_events_url": "https://api.github.com/users/byackee/received_events",
    "type": "User",
    "user_view_type": "public",
    "site_admin": false
  },
  "node_id": "RE_kwDOM40uy84NLGxk",
  "tag_name": "1.10.1",
  "target_commitish": "main",
  "name": "Release V1.10.1",
  "draft": false,
  "immutable": false,
  "prerelease": false,
  "created_at": "2025-05-25T05:58:20Z",
  "updated_at": "2025-05-26T13:46:00Z",
  "published_at": "2025-05-26T13:46:00Z",
  "assets": [
    {
      "url": "https://api.github.com/repos/RealToken-Community/realtoken_apps/releases/assets/258240625",
      "id": 258240625,
      "node_id": "RA_kwDOM40uy84PZHBx",
      "name": "app-release.apk",
      "label": null,
      "uploader": {
        "login": "byackee",
        "id": 4707496,
        "node_id": "MDQ6VXNlcjQ3MDc0OTY=",
        "avatar_url": "https://avatars.githubusercontent.com/u/4707496?v=4",
        "gravatar_id": "",
        "url": "https://api.github.com/users/byackee",
        "html_url": "https://github.com/byackee",
        "followers_url": "https://api.github.com/users/byackee/followers",
        "following_url": "https://api.github.com/users/byackee/following{/other_user}",
        "gists_url": "https://api.github.com/users/byackee/gists{/gist_id}",
        "starred_url": "https://api.github.com/users/byackee/starred{/owner}{/repo}",
        "subscriptions_url": "https://api.github.com/users/byackee/subscriptions",
        "organizations_url": "https://api.github.com/users/byackee/orgs",
        "repos_url": "https://api.github.com/users/byackee/repos",
        "events_url": "https://api.github.com/users/byackee/events{/privacy}",
        "received_events_url": "https://api.github.com/users/byackee/received_events",
        "type": "User",
        "user_view_type": "public",
        "site_admin": false
      },
      "content_type": "application/vnd.android.package-archive",
      "state": "uploaded",
      "size": 97871735,
      "digest": null,
      "download_count": 58,
      "created_at": "2025-05-26T13:45:46Z",
      "updated_at": "2025-05-26T13:45:52Z",
      "browser_download_url": "https://github.com/RealToken-Community/realtoken_apps/releases/download/1.10.1/app-release.apk"
    }
  ],
  "tarball_url": "https://api.github.com/repos/RealToken-Community/realtoken_apps/tarball/1.10.1",
  "zipball_url": "https://api.github.com/repos/RealToken-Community/realtoken_apps/zipball/1.10.1",
  "body": "- fix secondary market on properties tab\r\n- minors improvments"
}
```
</details>

<details>
<summary><code>https://api.realtoken.community/v1/tokenHistory</code></summary>

**Method:** `GET`

### Response
```json
[
  {
    "uuid": "0xe5f7ef61443fc36ae040650aa585b0395aef77c8",
    "history": [
      {
        "date": "20210111",
        "values": {
          "canal": "release",
          "tokenPrice": 63.75,
          "underlyingAssetPrice": 68000,
          "initialMaintenanceReserve": 500,
          "totalInvestment": 63750,
          "grossRentYear": 10740,
          "netRentYear": 8223.4,
          "rentedUnits": 1
        }
      },
      {
        "date": "20210329",
        "values": {
          "netRentYear": 8223.36
        }
      },
      {
        "date": "20210402",
        "values": {
          "netRentYear": 8223.4
        }
      },
      {
        "date": "20210528",
        "values": {
          "totalInvestment": 68500
        }
      },
      {
        "date": "20210602",
        "values": {
          "tokenPrice": 68.5
        }
      },
      {
        "date": "20230711",
        "values": {
          "grossRentYear": 0,
          "netRentYear": 0,
          "rentedUnits": 0
        }
      },
      {
        "date": "20231031",
        "values": {
          "grossRentYear": 11640,
          "netRentYear": 9042.4,
          "rentedUnits": 1
        }
      },
      {
        "date": "20231209",
        "values": {
          "renovationReserve": 0
        }
      },
      {
        "date": "20231212",
        "values": {
          "canal": "tokens_migrated"
        }
      }
    ]
  },
  {
    "uuid": "0xeD42CeDcADbFbCAA3E6F411B09567C2C0b5AD28F",
    "history": [
      {
        "date": "20210111",
        "values": {
          "canal": "release",
          "tokenPrice": 62.7,
          "underlyingAssetPrice": 57000,
          "initialMaintenanceReserve": 500,
          "totalInvestment": 62700,
          "grossRentYear": 9300,
          "netRentYear": 6518,
          "rentedUnits": 1
        }
      },
      {
        "date": "20210329",
        "values": {
          "netRentYear": 6517.92
        }
      },
      {
        "date": "20210330",
        "values": {
          "netRentYear": 6518.04
        }
      },
      {
        "date": "20210402",
        "values": {
          "netRentYear": 6518
        }
      },
      {
        "date": "20210622",
        "values": {
          "tokenPrice": 65.5,
          "underlyingAssetPrice": 65000,
          "totalInvestment": 65500
        }
      },
      {
        "date": "20230711",
        "values": {
          "grossRentYear": 0,
          "netRentYear": 0
        }
      },
      {
        "date": "20230905",
        "values": {
          "rentedUnits": 0
        }
      },
      {
        "date": "20230921",
        "values": {
          "grossRentYear": 11160,
          "netRentYear": 8210.6,
          "rentedUnits": 1
        }
      },
      {
        "date": "20231209",
        "values": {
          "renovationReserve": 0
        }
      },
      {
        "date": "20231212",
        "values": {
          "canal": "tokens_migrated"
        }
      }
    ]
  },
]
```
</details>

---

<details>
<summary><code>https://rpc.gnosischain.com</code> (ERC20 Balance)</summary>

**Method:** `POST`

**Headers:**
- `Content-Type`: `application/json`

### Request Body
```json
{
  "jsonrpc": "2.0",
  "method": "eth_call",
  "params": [
    {
      "to": "CONTRACT_ADDRESS",
      "data": "0x70a08231000000000000000000000000<ADDRESS_WITHOUT_0X>"
    },
    "latest"
  ],
  "id": 1
}
```

### Response
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": "0x0000000000000000000000000000000000000000000000000000000000000000"
}
```
</details>

<details>
<summary><code>https://rpc.gnosischain.com</code> (Native xDAI Balance)</summary>

**Method:** `POST`

**Headers:**
- `Content-Type`: `application/json`

### Request Body
```json
{
  "jsonrpc": "2.0",
  "method": "eth_getBalance",
  "params": [
    "ADDRESS",
    "latest"
  ],
  "id": 1
}
```

### Response
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": "0x1234567890abcdef"
}
```
</details>

<details>
<summary><code>https://rpc.gnosischain.com</code> (RMM Vault Balance)</summary>

**Method:** `POST`

**Headers:**
- `Content-Type`: `application/json`

### Request Body
```json
{
  "jsonrpc": "2.0",
  "method": "eth_call",
  "params": [
    {
      "to": "CONTRACT_ADDRESS",
      "data": "0xf262a083<PADDED_ADDRESS>"
    },
    "latest"
  ],
  "id": 1
}
```

### Response
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": "0x0000000000000000000000000000000000000000000000000000000000000000"
}
```
</details>


---



ina ro khodam ezafe kardam

/api/portfolio/buy
<details>
<summary><code>127.0.0.1/api/portfolio/buy</code></summary>
**Method:** `POST`

### Request body
```json
{
  "wallet": "0xUSERWALLETADDRESS",
  "userId": "user_12345",          // شناسه کاربر (از AppState)
  "propertyId": "0x1234...",       // شناسه یا آدرس قرارداد ملک (uuid)
  "amount": 5.0,                   // تعداد توکن خریداری شده
  "pricePerToken": 50.25,          // قیمت واحد در لحظه خرید
  "currency": "USD",               // ارز خرید (اختیاری)
  "purchaseDate": "2024-01-04T12:00:00Z" // تاریخ خرید
}

### Response
```json
{
  "success": true,
  "message": "Purchase recorded successfully",
  "transactionId": "tx_987654321"
}
```
</details>


<details>
<summary><code>127.0.0.1/api/portfolio/sell</code></summary>
**Method:** `POST`

### Request body
```json
{
  "wallet": "0xUSERWALLETADDRESS",
  "userId": "user_12345",          // شناسه کاربر
  "propertyId": "0x1234...",       // شناسه ملکی که فروخته می‌شود
  "amount": 2.0,                   // تعداد توکن فروخته شده
  "sellPricePerToken": 55.00,      // قیمت واحد در لحظه فروش (اختیاری، برای محاسبه سود)
  "sellDate": "2024-05-20T14:30:00Z"
}
```

### Response
```json
{
  "success": true,
  "message": "Sale recorded successfully",
  "remainingBalance": 3.0         
}
```

