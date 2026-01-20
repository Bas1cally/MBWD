const CACHE_NAME = 'mbwd-app-v15';
const urlsToCache = [
  './',
  './index.html',
  './manifest.json',
  './icon-192.png',
  './icon-512.png',
  './docs/054_CL_Corpuls3_EKG_Defibrillator.pdf',
  './docs/054_CL_AccuvacRescue_Absaugpumpe.pdf',
  './docs/054_CL_Medumat_Standard_Beatmungsgerät.pdf',
  './docs/054_CL_MANV_Tasche_RTW.pdf',
  './docs/054_CL_Notfallrucksäcke_Rot_Gelb.pdf',
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
  event.respondWith(
    fetch(event.request)
      .then(response => {
        // Clone and cache the response
        const responseClone = response.clone();
        caches.open(CACHE_NAME).then(cache => {
          cache.put(event.request, responseClone);
        });
        return response;
      })
      .catch(() => {
        // Fallback to cache if offline
        return caches.match(event.request);
      })
  );
});

self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(cacheNames => {
      return Promise.all(
        cacheNames.map(cacheName => {
          if (cacheName !== CACHE_NAME) {
            return caches.delete(cacheName);
          }
        })
      );
    })
  );
  self.clients.claim();
});
