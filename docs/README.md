# Docs

## Prior art

- [Overview](prior-art/README.md): is there already a native Chart.js port for Dart/Flutter?
  (No.) Summary, method, and what it means for this repository.
- [Chart.js packages](prior-art/chartjs-packages.md): how each Chart.js package on pub.dev and
  GitHub works, from the Dart API to the pixels.
- [Running real Chart.js without a WebView](prior-art/js-runtimes.md): embedded JS engines and
  web runtimes on Flutter, and the Canvas 2D prior art they contain.
- [Other JavaScript chart libraries](prior-art/other-chart-libraries.md): ECharts, Highcharts,
  ApexCharts, Plotly, D3 and others in Dart/Flutter, wrappers versus native ports.

## Decisions

- [ADR 0001: Native ports, not wrappers](adr/0001-native-ports-not-wrappers.md)
- [ADR 0002: Pin upstream sources as git submodules at release tags](adr/0002-pin-upstream-sources.md)
- [ADR 0003: Package names](adr/0003-package-names.md)

## Chart.js port

- [Overview and roadmap](chartjs/README.md)
- [Parity tracker](chartjs/parity.md)
