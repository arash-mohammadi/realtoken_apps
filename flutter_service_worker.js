'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter_bootstrap.js": "859e486c98c0783519df30f07d1b6b9b",
"version.json": "3ca2254dafa676c2e7983219de7dc88e",
"splash/img/light-2x.png": "d4adb792d3220b226e158bb1d4eed27f",
"splash/img/dark-4x.png": "362e288f98ed4d69f1113034cca13ed0",
"splash/img/light-3x.png": "62d22d78ad3784c9ea10987ba5d4f230",
"splash/img/dark-3x.png": "62d22d78ad3784c9ea10987ba5d4f230",
"splash/img/light-4x.png": "362e288f98ed4d69f1113034cca13ed0",
"splash/img/dark-2x.png": "d4adb792d3220b226e158bb1d4eed27f",
"splash/img/dark-1x.png": "d02eb1ffd0a0d2c7a887a6a4124a2a46",
"splash/img/light-1x.png": "d02eb1ffd0a0d2c7a887a6a4124a2a46",
"index.html": "84e7eb851fb4564236f1a2eef43ac2bd",
"/": "84e7eb851fb4564236f1a2eef43ac2bd",
"main.dart.js": "64687a450b09dcfe863f339b3ba65e7d",
"flutter.js": "76f08d47ff9f5715220992f993002504",
"favicon.png": "b03db3b9579ae6118c8e543c28981cc2",
"icons/Icon-192.png": "6532cf9ec88323613f6963bb25d5f8e4",
"icons/Icon-maskable-192.png": "6532cf9ec88323613f6963bb25d5f8e4",
"icons/Icon-maskable-512.png": "167bfcca4f415be4271ace3d1edbc488",
"icons/Icon-512.png": "167bfcca4f415be4271ace3d1edbc488",
"manifest.json": "08a5101b9a09cf8dcdf4d97178f23581",
"assets/AssetManifest.json": "999cbeff63142c85494c9a15eff671ac",
"assets/NOTICES": "e958aedb6bea695da8e861c6a8be5f3c",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/AssetManifest.bin.json": "bb911eae3b9f96b59fbb223cda6b9033",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "8e1e5432cb9b11528f06502c235df63e",
"assets/packages/flutter_map/lib/assets/flutter_map_logo.png": "208d63cc917af9713fc9572bd5c09362",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin": "c31fd68952771ae64baa8513e9524593",
"assets/fonts/MaterialIcons-Regular.otf": "f81d981bc9fef49b1388938b1480a721",
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
"assets/assets/bmc.png": "6cf1bb9efbe4c4b97962c918692db1ae",
"assets/assets/country/colombia.png": "b665283c03f3ef18a89535ebab849504",
"assets/assets/country/usa.png": "667ce794f6f12b2ba891dcc02839df16",
"assets/assets/country/panama.png": "c230d2786b3bf87746b7f4b52e108064",
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
