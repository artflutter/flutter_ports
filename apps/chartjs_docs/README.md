# chartjs_docs

The documentation site of `flutter_chartjs_port`. Each example on a page is a live `ChartView`.

Run `dart run melos run docs` to open the site in Chrome.

The code panels read the Dart files of `lib/examples/` and `lib/migrate/<library>/` as assets. The markers
`// #docregion <name>` and `// #enddocregion <name>` select the lines of a panel. Thus a panel shows the code
that draws its chart.

The pages "Migrate from fl_chart", "Migrate from Graphic" and "Migrate from Syncfusion" rebuild the line
chart demos of these libraries with the port. A browser address such as `#/migrate/fl_chart` opens a page.
