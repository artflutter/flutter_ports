// GitHub Pages cannot send the COOP and COEP headers that the worker thread of
// skwasm needs. On that host, this service worker adds them to each response of
// the page. The first visit loads the page, starts the worker and reloads once.
//
// It runs only on github.io, so a local run keeps its own server. It runs only
// in a browser where the Flutter loader can select skwasm (getBrowserEngine of
// flutter_js gives "blink", "gecko" or "webkit", and flutter_bootstrap.js
// permits the last two): another browser takes the JavaScript build, which has
// no threads.
if (typeof window === 'undefined') {
  self.addEventListener('install', () => self.skipWaiting());
  self.addEventListener('activate', (event) => {
    event.waitUntil(self.clients.claim());
  });
  self.addEventListener('fetch', (event) => {
    const request = event.request;
    if (request.cache === 'only-if-cached' && request.mode !== 'same-origin') {
      return;
    }
    event.respondWith(fetch(request).then((response) => {
      // An opaque response has no headers to change.
      if (response.status === 0) return response;
      const headers = new Headers(response.headers);
      headers.set('Cross-Origin-Opener-Policy', 'same-origin');
      headers.set('Cross-Origin-Embedder-Policy', 'require-corp');
      headers.set('Cross-Origin-Resource-Policy', 'cross-origin');
      return new Response(response.body, {
        status: response.status,
        statusText: response.statusText,
        headers,
      });
    }));
  });
} else if (!window.crossOriginIsolated && window.isSecureContext &&
    'serviceWorker' in navigator && location.hostname.endsWith('.github.io') &&
    (navigator.vendor === 'Google Inc.' || navigator.userAgent.includes('Edg/') ||
     navigator.vendor === 'Apple Computer, Inc.' ||
     (navigator.vendor === '' && navigator.userAgent.includes('Firefox')))) {
  navigator.serviceWorker.register(document.currentScript.src).then((registration) => {
    // sessionStorage covers each page of the origin in this tab, and each lab
    // page has its own worker. Thus each page has its own key.
    const key = `isolate.reloaded:${location.pathname}`;
    // One reload for each session, so that a page that stays without isolation
    // still runs, on one thread.
    const reload = () => {
      if (sessionStorage.getItem(key)) return;
      sessionStorage.setItem(key, '1');
      location.reload();
    };
    // A reload before this state can bypass the worker, and then the page has
    // no headers.
    const worker = registration.installing || registration.waiting || registration.active;
    if (worker.state === 'activated') {
      reload();
    } else {
      worker.addEventListener('statechange', () => {
        if (worker.state === 'activated') reload();
      });
    }
  });
}
