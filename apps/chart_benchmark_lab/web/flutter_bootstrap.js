{{flutter_js}}
{{flutter_build_config}}

// No serviceWorkerSettings. With them, the loader sees the worker of isolate.js
// and registers the worker of Flutter in the same scope. That worker unregisters
// itself and reloads the page, so that the page loses the COOP and COEP headers.
_flutter.loader.load();
