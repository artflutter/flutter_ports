# chartjs_ergonomics

Atomic samples of the typed API of `flutter_chartjs_port`. Each sample shows one feature. The page shows
the chart of each sample and the code of the chart under it. The app is for a review of the API by eye.

The first chart type is the line chart. An accepted sample (`accepted: true` in
`lib/samples/line/index.dart`) shows as a closed panel with a check mark.

The workflow `pages` publishes the app at <https://artflutter.github.io/flutter_ports/ergonomics/>.

## Run

```sh
dart run melos run ergonomics
```

## Add a sample

1. Write `lib/samples/line/<name>.dart`. Put the code that the card shows between
   `// #docregion sample` and `// #enddocregion sample`.
2. Add a `Sample` entry to `lib/samples/line/index.dart`, with the title, one note and the chart.
3. Run `flutter test`. The test makes sure that each file has its region and its entry, and that each
   sample draws with no error.
