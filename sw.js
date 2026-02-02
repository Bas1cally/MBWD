const CACHE_NAME = 'mbwd-app-v28';
const urlsToCache = [
  './',
  './index.html',
  './manifest.json',
  './icon-192.png',
  './icon-512.png',
  './apple-touch-icon.png',
  './favicon.png',
  './login-logo.png',
  './mercedes-banner.png',
  './dashboard-logo.png',
  './docs/054_CL_Corpuls3_EKG_Defibrillator.pdf',
  './docs/054_CL_AccuvacRescue_Absaugpumpe.pdf',
  './docs/054_CL_Medumat_Standard_Beatmungsgeraet.pdf',
  './docs/054_CL_MANV_Tasche_RTW.pdf',
  './docs/054_CL_Notfallrucksaecke_Rot_Gelb.pdf',
  './docs/054_CL_Notfallrucksack_Kinder.pdf'
];

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(urlsToCache))
  );
  self.skipWaiting();
});

self.addEventListener('fetch', event => {
  const url = new URL(event.request.url);
  // Don't cache blob: URLs, Supabase API calls, or external CDN resources unboundedly
  if (url.protocol === 'blob:') return;
  if (url.hostname.includes('supabase.co') || url.hostname.includes('supabase.io')) return;

  event.respondWith(
    Promise.race([
      fetch(event.request).then(response => {
        // Only cache same-origin and successful responses
        if (response.ok && url.origin === self.location.origin) {
          const responseClone = response.clone();
          caches.open(CACHE_NAME).then(cache => {
            cache.put(event.request, responseClone);
          });
        }
        return response;
      }),
      // Timeout: fall back to cache after 5 seconds
      new Promise((_, reject) => setTimeout(reject, 5000))
    ]).catch(() => {
      return caches.match(event.request);
    })
  );
});

self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(cacheNames => {
      return Promise.all(
        cacheNames
          .filter(cacheName => cacheName !== CACHE_NAME)
          .map(cacheName => caches.delete(cacheName))
      );
    })
  );
  self.clients.claim();
});
