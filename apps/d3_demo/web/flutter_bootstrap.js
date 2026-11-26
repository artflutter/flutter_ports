{{flutter_js}}
{{flutter_build_config}}

// Select WebAssembly or JavaScript via ?build=wasm / ?build=js (matching the
// landing page in tool/pages/d3.html), with Gecko and WebKit Wasm enabled.
const build = new URLSearchParams(location.search).get('build');
const config = {preferWebParagraph: true};
if (build === 'js' || (build !== 'wasm' && typeof window.TextCluster !== 'undefined')) {
  config.renderer = 'canvaskit';
}
config.wasmAllowList = {gecko: true, webkit: true};

_flutter.loader.load({config});
