/* ============================================================
   STOCK AVENUE GHANA — SERVICE WORKER
   Kept deliberately minimal: its only job is to satisfy the
   browser's installability requirement (a registered service
   worker with a fetch handler) and lightly cache the core shell
   pages so the site opens a little faster on repeat visits.
   It does NOT cache product data — that always comes fresh from
   Supabase so prices, stock and photos are never stale.
   ============================================================ */
const CACHE_NAME = "stock-avenue-shell-v1";
const SHELL_FILES = [
  "/index.html",
  "/shop.html",
  "/collections.html",
  "/about.html",
  "/contact.html",
  "/manifest.json"
];

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(SHELL_FILES)).catch(() => {})
  );
  self.skipWaiting();
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys().then((names) =>
      Promise.all(names.filter((n) => n !== CACHE_NAME).map((n) => caches.delete(n)))
    )
  );
  self.clients.claim();
});

self.addEventListener("fetch", (event) => {
  // Network-first: always try the live site/data first so content
  // never goes stale; fall back to the cached shell only if offline.
  event.respondWith(
    fetch(event.request).catch(() => caches.match(event.request))
  );
});
