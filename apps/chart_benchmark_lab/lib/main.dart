import 'package:chart_benchmark_lab/benchmark/controller.dart';
import 'package:chart_benchmark_lab/ui/benchmark_page.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart' as cj;
import 'package:material_ui/material_ui.dart';

void main() {
  cj.Chart.register(cj.registerables);
  runApp(const ChartBenchmarkApp());
}

/// A separate app for reproducible public-widget chart comparisons.
class ChartBenchmarkApp extends StatelessWidget {
  /// Creates the benchmark dashboard.
  const ChartBenchmarkApp({this.onControllerReady, super.key});

  /// Optional driver hook for native smoke runs, called once at initialization.
  final ValueChanged<BenchmarkController>? onControllerReady;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Chart benchmark lab',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff4f46e5)),
      scaffoldBackgroundColor: const Color(0xfff4f6fa),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xffe1e6ef)),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        isDense: true,
        border: OutlineInputBorder(),
      ),
      textTheme: ThemeData.light().textTheme.apply(
        bodyColor: const Color(0xff17243b),
        displayColor: const Color(0xff17243b),
      ),
    ),
    // fl_chart and Syncfusion still read the theme of the old Material library.
    // ignore: deprecated_member_use
    builder: (context, child) => MaterialUiCompatibilityBridge(child: child!),
    home: BenchmarkPage(onControllerReady: onControllerReady),
  );
}
