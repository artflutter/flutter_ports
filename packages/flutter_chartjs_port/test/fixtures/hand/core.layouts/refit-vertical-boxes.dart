// Ported from Chart.js v4.6.1 test/fixtures/core.layouts/refit-vertical-boxes.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
// Each call runs the module body again and gives new objects
// (fixture.js:24): the chart keeps the Lists of its config and writes
// into some of them.
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADRs 0115
/// and 0197).
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The config of the upstream file, as tool 4 decoded it, with the
/// title options as one object. Each call makes new objects.
FixtureConfig fixture() => FixtureConfig.typed(
  ChartConfig(
    datasets: [
      LineDataset(
        backgroundColor: .constant(
          ChartPaint.solid(Color.fromRGBO(252, 233, 79, 0.5)),
        ),
        borderColor: .constant(ChartPaint.solid(Color(0xFFFCE94F))),
        borderWidth: 1,
        data: .values(<num?>[101, 185, 24, 311, 17, 21, 462, 340, 140, 24]),
      ),
    ],
    labels: <Object>[
      'Aaron',
      'Adam',
      'Albert',
      'Alex',
      'Allan',
      'Aman',
      'Anthony',
      'Autoenrolment',
      'Avril',
      'Bernard',
    ],
    maintainAspectRatio: false,
    extra: <String, Object?>{
      'plugins': <String, Object?>{
        'legend': true,
        // DIVERGES(chartjs): adapt-native-plugin-options, one options object.
        'title': const TitleOptions(display: true, text: ['test']),
      },
    },
  ),
  options: <String, Object?>{
    'spriteText': true,
    'canvas': <String, Object?>{'height': 185, 'width': 185},
  },
);
