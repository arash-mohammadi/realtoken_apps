'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"icons/Icon-maskable-512.png": "167bfcca4f415be4271ace3d1edbc488",
"icons/Icon-512.png": "167bfcca4f415be4271ace3d1edbc488",
"icons/Icon-maskable-192.png": "6532cf9ec88323613f6963bb25d5f8e4",
"icons/Icon-192.png": "6532cf9ec88323613f6963bb25d5f8e4",
"flutter_bootstrap.js": "ed7673a7a71c04cfbd143a6b175f4777",
"canvaskit/skwasm.worker.js": "89990e8c92bcb123999aa81f7e203b1c",
"canvaskit/skwasm.wasm": "828c26a0b1cc8eb1adacbdd0c5e8bcfa",
"canvaskit/chromium/canvaskit.wasm": "ea5ab288728f7200f398f60089048b48",
"canvaskit/chromium/canvaskit.js.symbols": "e115ddcfad5f5b98a90e389433606502",
"canvaskit/chromium/canvaskit.js": "b7ba6d908089f706772b2007c37e6da4",
"canvaskit/skwasm.js": "ac0f73826b925320a1e9b0d3fd7da61c",
"canvaskit/canvaskit.wasm": "e7602c687313cfac5f495c5eac2fb324",
"canvaskit/skwasm.js.symbols": "96263e00e3c9bd9cd878ead867c04f3c",
"canvaskit/canvaskit.js.symbols": "efc2cd87d1ff6c586b7d4c7083063a40",
"canvaskit/canvaskit.js": "26eef3024dbc64886b7f48e1b6fb05cf",
"main.dart.js": "73bb0cd3bfb36f8550cf9fef9f5d975e",
"version.json": "a30c2960779611b13eb09f5b6b065959",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "e986ebe42ef785b27164c36a9abc7818",
"assets/packages/flutter_map/lib/assets/flutter_map_logo.png": "208d63cc917af9713fc9572bd5c09362",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/env_config.txt": "b33150e03fcf8803a5620022eee56dd0",
"assets/AssetManifest.json": "141749236c83dc098a68c1c73c1326fe",
"assets/assets/icons/usdc.png": "25bcb059251caa734d596e764838b1aa",
"assets/assets/icons/YAM.jpg": "7529316cf9e6d796d27efd7e0f3331b2",
"assets/assets/icons/RMM.jpg": "0b091944c5e1e7a2cde49fa7b2a7f44f",
"assets/assets/icons/xdai.png": "50405b6215a560f0f20bb7864a8a8827",
"assets/assets/RealT_Logo.png": "3ae1de374ab525a406da82e9c43e569d",
"assets/assets/DAO.png": "29de93b3112568d60c29a1e50b693c2f",
"assets/assets/logo_community.png": "87a40a9ed1a1b1531a498c2b6ad51167",
"assets/assets/ethereum.png": "856bfdb63dc0d6fad6b92fc6a29719e1",
"assets/assets/bmc.png": "6cf1bb9efbe4c4b97962c918692db1ae",
"assets/assets/logo.png": "c0e79a501950ac6b2b5ed7ee31cb4974",
"assets/assets/gnosis.png": "c0978d191f2b7c14ab6d8e5ca688ec1d",
"assets/assets/country/panama.png": "822f456209226a836f7d4459e453cdb5",
"assets/assets/country/suisse.png": "c23c77ca1513f327065e8a28397c2b2c",
"assets/assets/country/usa.png": "5566dea3b847d771b50094756904bc6a",
"assets/NOTICES": "f5cb7d913e3b0f820871359d0b6c7cd0",
"assets/AssetManifest.bin": "c55e664b0975780394d7b7d9ab1e4736",
"assets/fonts/MaterialIcons-Regular.otf": "cfae38c15fe923c16ebb592023f4e093",
"assets/AssetManifest.bin.json": "76742f503dc8a8f2bf1623d4b375111c",
"splash/img/dark-3x.png": "62d22d78ad3784c9ea10987ba5d4f230",
"splash/img/light-4x.png": "362e288f98ed4d69f1113034cca13ed0",
"splash/img/dark-2x.png": "d4adb792d3220b226e158bb1d4eed27f",
"splash/img/light-3x.png": "62d22d78ad3784c9ea10987ba5d4f230",
"splash/img/dark-1x.png": "d02eb1ffd0a0d2c7a887a6a4124a2a46",
"splash/img/dark-4x.png": "362e288f98ed4d69f1113034cca13ed0",
"splash/img/light-1x.png": "d02eb1ffd0a0d2c7a887a6a4124a2a46",
"splash/img/light-2x.png": "d4adb792d3220b226e158bb1d4eed27f",
"favicon.png": "b03db3b9579ae6118c8e543c28981cc2",
"index.html": "a83d2d76647009d2af8523ed079144b7",
"/": "a83d2d76647009d2af8523ed079144b7",
"manifest.json": "08a5101b9a09cf8dcdf4d97178f23581",
"flutter.js": "4b2350e14c6650ba82871f60906437ea"};
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
