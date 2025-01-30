'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter.js": "f393d3c16b631f36852323de8e583132",
"splash/img/dark-2x.png": "d4adb792d3220b226e158bb1d4eed27f",
"splash/img/light-4x.png": "362e288f98ed4d69f1113034cca13ed0",
"splash/img/light-3x.png": "62d22d78ad3784c9ea10987ba5d4f230",
"splash/img/dark-3x.png": "62d22d78ad3784c9ea10987ba5d4f230",
"splash/img/light-1x.png": "d02eb1ffd0a0d2c7a887a6a4124a2a46",
"splash/img/dark-4x.png": "362e288f98ed4d69f1113034cca13ed0",
"splash/img/dark-1x.png": "d02eb1ffd0a0d2c7a887a6a4124a2a46",
"splash/img/light-2x.png": "d4adb792d3220b226e158bb1d4eed27f",
"icons/Icon-maskable-192.png": "6532cf9ec88323613f6963bb25d5f8e4",
"icons/Icon-512.png": "167bfcca4f415be4271ace3d1edbc488",
"icons/Icon-192.png": "6532cf9ec88323613f6963bb25d5f8e4",
"icons/Icon-maskable-512.png": "167bfcca4f415be4271ace3d1edbc488",
"version.json": "8e51b70eb3f6e85f267cdd2224aa69e1",
"flutter_bootstrap.js": "df96977bfc771562f20ccc2eb233af8b",
"manifest.json": "08a5101b9a09cf8dcdf4d97178f23581",
"main.dart.js": "99bad7a5ed6ff50aef78c43423b32edf",
"index.html": "a83d2d76647009d2af8523ed079144b7",
"/": "a83d2d76647009d2af8523ed079144b7",
"assets/AssetManifest.json": "6328b64799ce1460e20039ae639fd960",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/fonts/MaterialIcons-Regular.otf": "3921262d9abc928040d3ad4c36a6ce33",
"assets/AssetManifest.bin": "732443822491b26f06f10b88eae35518",
"assets/packages/flutter_map/lib/assets/flutter_map_logo.png": "208d63cc917af9713fc9572bd5c09362",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "e986ebe42ef785b27164c36a9abc7818",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/AssetManifest.bin.json": "59d9fa6fe4f514617687302155404ebf",
"assets/NOTICES": "572c18aab81d6fc126c0468fd18027a0",
"assets/assets/logo_community.png": "87a40a9ed1a1b1531a498c2b6ad51167",
"assets/assets/ethereum.png": "856bfdb63dc0d6fad6b92fc6a29719e1",
"assets/assets/gnosis.png": "c0978d191f2b7c14ab6d8e5ca688ec1d",
"assets/assets/logo.png": "c0e79a501950ac6b2b5ed7ee31cb4974",
"assets/assets/bmc.png": "6cf1bb9efbe4c4b97962c918692db1ae",
"assets/assets/icons/RMM.jpg": "0b091944c5e1e7a2cde49fa7b2a7f44f",
"assets/assets/icons/xdai.png": "50405b6215a560f0f20bb7864a8a8827",
"assets/assets/icons/usdc.png": "25bcb059251caa734d596e764838b1aa",
"assets/assets/icons/YAM.jpg": "7529316cf9e6d796d27efd7e0f3331b2",
"assets/assets/country/panama.png": "822f456209226a836f7d4459e453cdb5",
"assets/assets/country/usa.png": "5566dea3b847d771b50094756904bc6a",
"assets/assets/country/suisse.png": "c23c77ca1513f327065e8a28397c2b2c",
"assets/assets/RealT_Logo.png": "3ae1de374ab525a406da82e9c43e569d",
"canvaskit/canvaskit.wasm": "1f237a213d7370cf95f443d896176460",
"canvaskit/skwasm.worker.js": "89990e8c92bcb123999aa81f7e203b1c",
"canvaskit/skwasm.wasm": "9f0c0c02b82a910d12ce0543ec130e60",
"canvaskit/chromium/canvaskit.wasm": "b1ac05b29c127d86df4bcfbf50dd902a",
"canvaskit/chromium/canvaskit.js": "671c6b4f8fcc199dcc551c7bb125f239",
"canvaskit/chromium/canvaskit.js.symbols": "a012ed99ccba193cf96bb2643003f6fc",
"canvaskit/canvaskit.js": "66177750aff65a66cb07bb44b8c6422b",
"canvaskit/canvaskit.js.symbols": "48c83a2ce573d9692e8d970e288d75f7",
"canvaskit/skwasm.js": "694fda5704053957c2594de355805228",
"canvaskit/skwasm.js.symbols": "262f4827a1317abb59d71d6c587a93e2",
"favicon.png": "b03db3b9579ae6118c8e543c28981cc2"};
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
