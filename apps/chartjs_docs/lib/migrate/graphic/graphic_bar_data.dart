// Original code, not ported from Chart.js: the data of the Graphic bar demos (MIT, LIN Chen).
// ignore_for_file: lines_longer_than_80_chars
// A copy of the data of example/lib/data.dart of Graphic that the bar charts
// use, with Dart records in place of the Maps. The bar charts also use
// `adjustData` of graphic_data.dart.
// #docregion graphic-bar-data

/// The sales of five game genres, `basicData` of Graphic.
const List<({String genre, int sold})> basicData = [
  (genre: 'Sports', sold: 275),
  (genre: 'Strategy', sold: 115),
  (genre: 'Action', sold: 120),
  (genre: 'Shooter', sold: 350),
  (genre: 'Other', sold: 150),
];

/// A range of values for each of eight ids, `intervalData` of Graphic.
const List<({String id, int min, int max})> intervalData = [
  (id: 'No.1', min: 76, max: 100),
  (id: 'No.2', min: 56, max: 108),
  (id: 'No.3', min: 38, max: 129),
  (id: 'No.4', min: 58, max: 155),
  (id: 'No.5', min: 45, max: 120),
  (id: 'No.6', min: 23, max: 99),
  (id: 'No.7', min: 18, max: 56),
  (id: 'No.8', min: 18, max: 34),
];
// #enddocregion graphic-bar-data
