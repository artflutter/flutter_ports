// Original code, not ported from Chart.js: the DartPad app of a sample.

/// The "Try in DartPad" link of the basic line chart opens this file and
/// `lib/examples/line/basic.dart`, and DartPad runs this file.
library;

import 'package:chartjs_docs/examples/line/basic.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

/// Registers the chart components and shows the chart of [basicLine].
void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: ChartView(config: basicLine),
          ),
        ),
      ),
    ),
  );
}
