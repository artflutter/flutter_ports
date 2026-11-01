import 'package:chartjs_gallery/demo/demo_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chartjs_port/helpers.dart' as helpers;
// Numerical color operations; chart inputs are Flutter Color values.
// ignore: implementation_imports
import 'package:flutter_chartjs_port/src/kurkle_color/index.esm.dart' as kc;

/// Native color samples used by the chart API.
const List<Color> sampleColors = [
  Color(0xFFFF0000),
  Color(0xFF36A2EB),
  Color.fromRGBO(255, 99, 132, 0.5),
  Color(0xFF33CC33),
  Color(0xFF9966FF),
  Color(0x804BC0C0),
];

String _argb(Color color) =>
    '0x${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';

kc.Color _numeric(Color color) => helpers.color(color) as kc.Color;

/// Native colors, hover colors and numerical color mixing.
class ColorDemo extends StatefulWidget {
  /// Creates the colors tab.
  const ColorDemo({super.key});

  @override
  State<ColorDemo> createState() => _ColorDemoState();
}

class _ColorDemoState extends State<ColorDemo> {
  Color _mixA = sampleColors[0];
  Color _mixB = sampleColors[1];
  double _weight = 0.5;

  @override
  Widget build(BuildContext context) {
    final mixed = _numeric(_mixA).mix(_numeric(_mixB), _weight);
    Widget dropdown(String key, Color value, ValueChanged<Color> change) =>
        DropdownButton<Color>(
          key: ValueKey(key),
          value: value,
          items: [
            for (final color in sampleColors)
              DropdownMenuItem(
                value: color,
                child: Row(
                  children: [
                    ColorSwatchBox(color: color, size: 18),
                    const SizedBox(width: 8),
                    Mono(_argb(color)),
                  ],
                ),
              ),
          ],
          onChanged: (color) {
            if (color != null) setState(() => change(color));
          },
        );
    return DemoPageBody(
      children: [
        DemoCard(
          title: 'Flutter Color values',
          source: 'Color(0xFF36A2EB) · getHoverColor(color)',
          child: Column(
            children: [
              for (final color in sampleColors)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      ColorSwatchBox(color: color),
                      const SizedBox(width: 12),
                      Expanded(child: Mono(_argb(color))),
                      const Text('hover'),
                      const SizedBox(width: 8),
                      ColorSwatchBox(
                        color: helpers.getHoverColor(color)! as Color,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        DemoCard(
          title: 'Mix two colors',
          source: 'Numerical color mixing',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 16,
                children: [
                  dropdown('color.mixA', _mixA, (value) => _mixA = value),
                  dropdown('color.mixB', _mixB, (value) => _mixB = value),
                ],
              ),
              Slider(
                key: const ValueKey('color.weight'),
                value: _weight,
                divisions: 20,
                label: _weight.toStringAsFixed(2),
                onChanged: (value) => setState(() => _weight = value),
              ),
              Row(
                key: const ValueKey('color.mixed'),
                children: [
                  ColorSwatchBox(color: flutterColor(mixed), size: 56),
                  const SizedBox(width: 12),
                  Mono(_argb(flutterColor(mixed)!)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
