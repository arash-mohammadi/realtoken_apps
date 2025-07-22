'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter_bootstrap.js": "5e193f1d1d94117d0c3d0234491a75b2",
"version.json": "ba1eb48b8575a39b5dd6c812c886dbf7",
"splash/img/light-2x.png": "d4adb792d3220b226e158bb1d4eed27f",
"splash/img/dark-4x.png": "362e288f98ed4d69f1113034cca13ed0",
"splash/img/light-3x.png": "62d22d78ad3784c9ea10987ba5d4f230",
"splash/img/dark-3x.png": "62d22d78ad3784c9ea10987ba5d4f230",
"splash/img/light-4x.png": "362e288f98ed4d69f1113034cca13ed0",
"splash/img/dark-2x.png": "d4adb792d3220b226e158bb1d4eed27f",
"splash/img/dark-1x.png": "d02eb1ffd0a0d2c7a887a6a4124a2a46",
"splash/img/light-1x.png": "d02eb1ffd0a0d2c7a887a6a4124a2a46",
"index.html": "823788ae155573cd6b440e1a17ac6f46",
"/": "823788ae155573cd6b440e1a17ac6f46",
"main.dart.js": "566b11ad817281b66f70dd3c26044c7d",
"flutter.js": "76f08d47ff9f5715220992f993002504",
"favicon.png": "b03db3b9579ae6118c8e543c28981cc2",
"icons/Icon-192.png": "6532cf9ec88323613f6963bb25d5f8e4",
"icons/Icon-maskable-192.png": "6532cf9ec88323613f6963bb25d5f8e4",
"icons/Icon-maskable-512.png": "167bfcca4f415be4271ace3d1edbc488",
"icons/Icon-512.png": "167bfcca4f415be4271ace3d1edbc488",
"manifest.json": "5eeaec34b2c6590227e6f166f0e4b0fa",
"assets/AssetManifest.json": "90ea3c8ab677088d896004caa3dd9f41",
"assets/NOTICES": "bd3b66f5f8f715c5944ea4f22d199958",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/AssetManifest.bin.json": "11594cb0ea307c2151f070bfe6db8325",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "b93248a553f9e8bc17f1065929d5934b",
"assets/packages/flutter_map/lib/assets/flutter_map_logo.png": "208d63cc917af9713fc9572bd5c09362",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin": "85a16bedc86e9b4c98d8557fc8ea8a09",
"assets/fonts/MaterialIcons-Regular.otf": "e7069dfd19b331be16bed984668fe080",
"assets/assets/DAO.png": "29de93b3112568d60c29a1e50b693c2f",
"assets/assets/logo_community.png": "87a40a9ed1a1b1531a498c2b6ad51167",
"assets/assets/ethereum.png": "856bfdb63dc0d6fad6b92fc6a29719e1",
"assets/assets/logo.png": "c0e79a501950ac6b2b5ed7ee31cb4974",
"assets/assets/RealT_Logo.png": "3ae1de374ab525a406da82e9c43e569d",
"assets/assets/icons/YAM.jpg": "7529316cf9e6d796d27efd7e0f3331b2",
"assets/assets/icons/xdai.png": "74fefd57575f0ca060668b360fea0d08",
"assets/assets/icons/usdc.png": "25bcb059251caa734d596e764838b1aa",
"assets/assets/icons/excel.png": "682a5c3e893a9ef91d487e589359d032",
"assets/assets/icons/RMM.jpg": "0b091944c5e1e7a2cde49fa7b2a7f44f",
"assets/assets/icons/reg.png": "5132c254d14efe21d9ba9149a1e52117",
"assets/assets/states/ut.png": "a3f7ed743de633748d94a991270a445d",
"assets/assets/states/me.png": "8bb48dcfaf78a3c3be71ec6ca150b9bc",
"assets/assets/states/la.png": "80be3ef8976c720a71f1b6a86f79d999",
"assets/assets/states/co.png": "447e1c164919642c1a1e0c0b0f9646fa",
"assets/assets/states/nh.png": "38fb194e55b3dd75a4fdbc5426df65c2",
"assets/assets/states/ms.png": "c0541f9e3d2e8708cb1c7084f06bb63f",
"assets/assets/states/md.png": "0fbdfc6afc39da9a904bec913b46f4bb",
"assets/assets/states/nj.png": "601e2062d0e895e8d88b8089b6da7352",
"assets/assets/states/ar.png": "1cb99428e047ddb419313fbfc5d13b85",
"assets/assets/states/wi.png": "f43eb1715ce4c856f20a482c33c88c54",
"assets/assets/states/ok.png": "94c054d56857db977358a4676e7eecb2",
"assets/assets/states/mt.png": "f9d6a94250dfaf1eb26241e3c3794a14",
"assets/assets/states/ny.png": "5796fc033eec551e2a40dce4ef8d2124",
"assets/assets/states/wy.png": "191c8bb54f37d7412ade1e3f9ac7a656",
"assets/assets/states/oh.png": "d0ea85385335ba944b292fe869a03234",
"assets/assets/states/ma.png": "4a1c998abc557c1992291578b3c59b86",
"assets/assets/states/nm.png": "5862f2fa5e7bcb89d70a27a28812bf09",
"assets/assets/states/in.png": "f9056e9f0955c91794a450ac7cb683c3",
"assets/assets/states/sc.png": "45eb7b00741ba2aed683c845b2033ca9",
"assets/assets/states/hi.png": "e8b0d0b967bd2d53ea2bfbbd132e5a1b",
"assets/assets/states/ks.png": "f90fb740baab87dc4a39f0847cff546f",
"assets/assets/states/il.png": "6db5a695dde06dfd9b0128af6ca48802",
"assets/assets/states/ga.png": "febd39f1e08256680e7c50d91dd9887d",
"assets/assets/states/sd.png": "2651f3547af9002ee555ace9f2b4e25f",
"assets/assets/states/ky.png": "e552ab02f90d67f30f50773b087947a1",
"assets/assets/states/id.png": "fc5519f20b2f11eaaf0c63fbb73d5c54",
"assets/assets/states/ia.png": "bc4a32c51066401add1e75260d2a827e",
"assets/assets/states/de.png": "82fbab752f088d1d9494e12195e1c435",
"assets/assets/states/fl.png": "fcbd37b5e4418a90d8a60999be6fd086",
"assets/assets/states/pa.png": "3c7ea3563eee4a6b65eedf5f35d53bc4",
"assets/assets/states/ri.png": "c90b84f2160ce6258f01b7208c442e25",
"assets/assets/states/ty.png": "8c808e3442a3594a5b0648872c69640f",
"assets/assets/states/tn.png": "236080edc5ad0d0856b98b0f31ba0973",
"assets/assets/states/nv.png": "d1c9de0a9a8e3523177df583bda07b34",
"assets/assets/states/or.png": "dfddfdaefb6ee1ea1f03f064e0429482",
"assets/assets/states/tx.png": "f142016064b2bf1f2d2b7bf31f7b0406",
"assets/assets/states/wa.png": "02836d64867ddc0a3d146a91e6d76d6b",
"assets/assets/states/wv.png": "7486f4880844b7f602f925f9a99ae309",
"assets/assets/states/nc.png": "af14c019fbaafa2b4748933f355e1ee0",
"assets/assets/states/mo.png": "53e5a56ce7b2c2ffa89855ae9c965c2c",
"assets/assets/states/al.png": "fbe53e3fcc6dc7fd2578afc2f187a322",
"assets/assets/states/az.png": "8c36fbd72baf7bdc7be3ec279daab4d2",
"assets/assets/states/mn.png": "2599048dcf2addc64c4a38efb5780810",
"assets/assets/states/ca.png": "fa00496805ea54b6f53da934880501b7",
"assets/assets/states/va.png": "54c5b61c254eb28f40a781ab48e8f314",
"assets/assets/states/vt.png": "d855820ac4846a653111207a5e435f4e",
"assets/assets/states/mi.png": "957a85eabd218e27324ee45cd9fc9188",
"assets/assets/states/ne.png": "5d5273e1ad66246e768e6601656eb185",
"assets/assets/states/ak.png": "beacdc8fb6078f69547105306e5ed464",
"assets/assets/states/ct.png": "a5cdec694d92310b009ffab13a448e66",
"assets/assets/states/nd.png": "3eff93ccfa71c97a31c8aa4afbfeffff",
"assets/assets/bmc.png": "6cf1bb9efbe4c4b97962c918692db1ae",
"assets/assets/country/colombia.png": "b665283c03f3ef18a89535ebab849504",
"assets/assets/country/usa.png": "667ce794f6f12b2ba891dcc02839df16",
"assets/assets/country/panama.png": "c230d2786b3bf87746b7f4b52e108064",
"assets/assets/country/series_xx.png": "6b9991df5f13e9c7814b55bcc621aada",
"assets/assets/country/suisse.png": "5ec8bdb0e920c858622156d13a76fdc8",
"assets/assets/gnosis.png": "c0978d191f2b7c14ab6d8e5ca688ec1d",
"assets/env_config.txt": "8727ea19bae0ec18097d36215e619c78",
"canvaskit/skwasm_st.js": "d1326ceef381ad382ab492ba5d96f04d",
"canvaskit/skwasm.js": "f2ad9363618c5f62e813740099a80e63",
"canvaskit/skwasm.js.symbols": "80806576fa1056b43dd6d0b445b4b6f7",
"canvaskit/canvaskit.js.symbols": "68eb703b9a609baef8ee0e413b442f33",
"canvaskit/skwasm.wasm": "f0dfd99007f989368db17c9abeed5a49",
"canvaskit/chromium/canvaskit.js.symbols": "5a23598a2a8efd18ec3b60de5d28af8f",
"canvaskit/chromium/canvaskit.js": "34beda9f39eb7d992d46125ca868dc61",
"canvaskit/chromium/canvaskit.wasm": "64a386c87532ae52ae041d18a32a3635",
"canvaskit/skwasm_st.js.symbols": "c7e7aac7cd8b612defd62b43e3050bdd",
"canvaskit/canvaskit.js": "86e461cf471c1640fd2b461ece4589df",
"canvaskit/canvaskit.wasm": "efeeba7dcc952dae57870d4df3111fad",
"canvaskit/skwasm_st.wasm": "56c3973560dfcbf28ce47cebe40f3206"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
