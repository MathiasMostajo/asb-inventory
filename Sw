// ASB Inventory Service Worker
// Network-first strategy: always try live data, fall back to cache only when offline.
const CACHE = 'qajon-v1';
const SHELL = ['./index.html', './manifest.json', './icon-192.png', './icon-512.png'];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(SHELL)).then(() => self.skipWaiting()));
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)))).then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', e => {
  const url = e.request.url;
  // Never cache Supabase API calls or Google Translate - always go to network
  if (url.includes('supabase.co') || url.includes('translate.google') || url.includes('gstatic.com')) {
    return;
  }
  // For app shell: network first, cache fallback
  e.respondWith(
    fetch(e.request).then(resp => {
      if (resp && resp.status === 200 && e.request.method === 'GET') {
        const clone = resp.clone();
        caches.open(CACHE).then(c => c.put(e.request, clone));
      }
      return resp;
    }).catch(() => caches.match(e.request).then(r => r || caches.match('./index.html')))
  );
});
