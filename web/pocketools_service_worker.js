"use strict";

const POCKETOOLS_CACHE_PREFIX = "pocketools-pwa-";
const POCKETOOLS_CACHE_VERSION = "v3";
const POCKETOOLS_CACHE_NAME =
  `${POCKETOOLS_CACHE_PREFIX}${POCKETOOLS_CACHE_VERSION}`;

const POCKETOOLS_PRECACHE_RESOURCES = Object.freeze([
  "./",
  "index.html",
  "flutter_bootstrap.js",
  "flutter.js",
  "main.dart.js",
  "manifest.json",
  "version.json",
  "favicon.png",
  "icons/Icon-192.png",
  "icons/Icon-512.png",
  "icons/Icon-maskable-192.png",
  "icons/Icon-maskable-512.png",
  "assets/AssetManifest.bin",
  "assets/AssetManifest.bin.json",
  "assets/FontManifest.json",
  "assets/NOTICES",
  "assets/fonts/MaterialIcons-Regular.otf",
  "assets/shaders/ink_sparkle.frag",
  "assets/shaders/stretch_effect.frag",
  "canvaskit/canvaskit.js",
  "canvaskit/canvaskit.wasm",
  "canvaskit/chromium/canvaskit.js",
  "canvaskit/chromium/canvaskit.wasm",
  "canvaskit/webparagraph/canvaskit.js",
  "canvaskit/webparagraph/canvaskit.wasm",
  "canvaskit/skwasm.js",
  "canvaskit/skwasm.wasm",
  "canvaskit/skwasm_heavy.js",
  "canvaskit/skwasm_heavy.wasm",
  "canvaskit/wimp.js",
  "canvaskit/wimp.wasm",
]);

const pocketoolsScopeUrl = new URL(self.registration.scope);
const pocketoolsIndexRequest = new Request(
  new URL("index.html", pocketoolsScopeUrl),
);

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches
      .open(POCKETOOLS_CACHE_NAME)
      .then((cache) =>
        cache.addAll(
          POCKETOOLS_PRECACHE_RESOURCES.map(
            (resource) => new URL(resource, pocketoolsScopeUrl),
          ),
        ),
      )
      .then(() => self.skipWaiting()),
  );
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((keys) =>
        Promise.all(
          keys
            .filter(
              (key) =>
                key.startsWith(POCKETOOLS_CACHE_PREFIX) &&
                key !== POCKETOOLS_CACHE_NAME,
            )
            .map((key) => caches.delete(key)),
        ),
      )
      .then(() => self.clients.claim()),
  );
});

self.addEventListener("fetch", (event) => {
  const request = event.request;
  if (request.method !== "GET" || request.headers.has("range")) return;

  const requestUrl = new URL(request.url);
  if (requestUrl.origin !== pocketoolsScopeUrl.origin) return;

  if (request.mode === "navigate") {
    event.respondWith(pocketoolsNavigationResponse(request));
    return;
  }
  if (!pocketoolsIsSafeStaticRequest(requestUrl)) return;
  event.respondWith(pocketoolsStaticResponse(requestUrl));
});

async function pocketoolsNavigationResponse(request) {
  const cache = await caches.open(POCKETOOLS_CACHE_NAME);
  try {
    const response = await fetch(new Request(request, { cache: "no-store" }));
    if (response.ok) {
      await cache.put(pocketoolsIndexRequest, response.clone());
      return response;
    }
  } catch (_) {
    // The last known shell below is the intentional offline fallback.
  }
  return (await cache.match(pocketoolsIndexRequest)) || Response.error();
}

async function pocketoolsStaticResponse(requestUrl) {
  const cache = await caches.open(POCKETOOLS_CACHE_NAME);
  const cacheKey = new Request(
    new URL(requestUrl.pathname, pocketoolsScopeUrl.origin),
  );
  try {
    const response = await fetch(
      new Request(cacheKey, { cache: "no-store" }),
    );
    if (response.ok && response.type === "basic") {
      await cache.put(cacheKey, response.clone());
    }
    return response;
  } catch (_) {
    return (await cache.match(cacheKey)) || Response.error();
  }
}

function pocketoolsIsSafeStaticRequest(requestUrl) {
  if (!requestUrl.pathname.startsWith(pocketoolsScopeUrl.pathname)) {
    return false;
  }
  const relativePath = requestUrl.pathname.slice(
    pocketoolsScopeUrl.pathname.length,
  );
  return (
    relativePath.startsWith("assets/") ||
    relativePath.startsWith("canvaskit/") ||
    relativePath.startsWith("icons/") ||
    /\.(?:bin|frag|html|js|json|otf|png|wasm)$/.test(relativePath)
  );
}
