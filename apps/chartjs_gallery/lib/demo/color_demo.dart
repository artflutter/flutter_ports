// The package exports nothing from lib/src yet; the public API comes in
// phase 9. The demo imports the ported files directly.
// ignore_for_file: implementation_imports

import 'package:chartjs_gallery/demo/demo_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chartjs/src/helpers/helpers.color.dart'
    show getHoverColor;
import 'package:flutter_chartjs/src/kurkle_color/index.esm.dart' as kc;

/// The CSS colors that the tab parses: names, hex, functional notations.
const List<String> sampleColors = [
  'red',
  '#36A2EB',
  'rgba(255, 99, 132, 0.5)',
  'hsl(120, 60%, 50%)',
  'hwb(60 3% 60%)',
  '#4bc0c080',
  'rebeccapurple',
  'not-a-color',
];

/// The colors of the ported `@kurkle/color` and of `helpers.color`.
///
/// Each CSS color goes through `new Color(css)`, then `rgbString()`,
/// `hexString()` and `hslString()`, and through `getHoverColor`, which
/// Chart.js uses for the hover colors of its defaults. A slider mixes two
/// colors with `Color.mix`.
class ColorDemo extends StatefulWidget {
  /// Creates the colors tab.
  const ColorDemo({super.key});

  @override
  State<ColorDemo> createState() => _ColorDemoState();
}

class _ColorDemoState extends State<ColorDemo> {
  final TextEditingController _input = TextEditingController(
    text: 'hsla(200, 80%, 45%, 0.7)',
  );
  String _mixA = '#FF6384';
  String _mixB = '#36A2EB';
  double _weight = 0.5;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DemoPageBody(
      children: [
        DemoCard(
          title: 'Parse any CSS color',
          source:
              'kurkle_color: Color(css).rgbString() / hexString() / '
              'hslString() · helpers.color: getHoverColor(css)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const ValueKey('color.input'),
                controller: _input,
                decoration: const InputDecoration(
                  labelText: 'CSS color',
                  hintText: "e.g. 'orange', '#abc', 'rgb(10 20 30 / 50%)'",
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              _ColorRow(css: _input.text),
            ],
          ),
        ),
        DemoCard(
          title: 'Sample colors',
          source: 'Swatch · rgbString · hexString · hslString · hover',
          child: Column(
            children: [
              for (final css in sampleColors) ...[
                _ColorRow(css: css),
                if (css != sampleColors.last) const Divider(height: 20),
              ],
            ],
          ),
        ),
        DemoCard(
          title: 'Mix two colors',
          source: 'kurkle_color: Color(a).mix(Color(b), weight)',
          child: _buildMix(context),
        ),
      ],
    );
  }

  Widget _buildMix(BuildContext context) {
    final mixed = kc.Color(_mixA).mix(kc.Color(_mixB), _weight);
    const choices = [
      '#FF6384',
      '#36A2EB',
      '#FFCE56',
      '#4BC0C0',
      '#9966FF',
      'rgba(0,0,0,0.2)',
      'white',
    ];
    DropdownMenuItem<String> item(String css) => DropdownMenuItem(
      value: css,
      child: Row(
        children: [
          ColorSwatchBox(color: cssColor(css), size: 18),
          const SizedBox(width: 8),
          Flexible(child: Text(css, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
    // isExpanded with a width cap: the dropdown keeps its width and
    // ellipsizes long items instead of overflowing on a narrow screen or
    // with a large text scale.
    Widget dropdown(String key, String value, ValueChanged<String> set) =>
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200),
          child: DropdownButton<String>(
            key: ValueKey(key),
            isExpanded: true,
            value: value,
            items: [for (final c in choices) item(c)],
            onChanged: (v) => setState(() => set(v ?? value)),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            dropdown('color.mixA', _mixA, (v) => _mixA = v),
            const Text('mixed with'),
            dropdown('color.mixB', _mixB, (v) => _mixB = v),
          ],
        ),
        Row(
          children: [
            const Text('weight'),
            Expanded(
              child: Slider(
                key: const ValueKey('color.weight'),
                value: _weight,
                divisions: 20,
                label: _weight.toStringAsFixed(2),
                onChanged: (v) => setState(() => _weight = v),
              ),
            ),
            Mono(_weight.toStringAsFixed(2)),
          ],
        ),
        Row(
          children: [
            ColorSwatchBox(color: cssColor(_mixA)),
            const SizedBox(width: 8),
            const Icon(Icons.add, size: 18),
            const SizedBox(width: 8),
            ColorSwatchBox(color: cssColor(_mixB)),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, size: 18),
            const SizedBox(width: 8),
            ColorSwatchBox(color: flutterColor(mixed), size: 56),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                key: const ValueKey('color.mixed'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Mono('${mixed.rgbString()}'),
                  Mono('${mixed.hexString()}'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'mix() at weight 0 … 1 (the weight goes to the first color)',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 28,
          child: Row(
            children: [
              for (var i = 0; i <= 20; i++)
                Expanded(
                  child: ColoredBox(
                    color:
                        flutterColor(
                          kc.Color(_mixA).mix(kc.Color(_mixB), i / 20),
                        ) ??
                        Colors.transparent,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One parsed color: the swatch, the three strings and the hover color.
class _ColorRow extends StatelessWidget {
  const _ColorRow({required this.css});

  final String css;

  @override
  Widget build(BuildContext context) {
    // Each call makes a new Color: the manipulation methods change it.
    final parsed = kc.Color(css);
    final valid = parsed.valid;
    final hover = valid ? getHoverColor(css) as String? : null;
    final theme = Theme.of(context);
    final strings = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("'$css'", style: theme.textTheme.titleSmall),
        if (!valid)
          Text(
            'valid: false (rgbString() is undefined)',
            style: TextStyle(color: theme.colorScheme.error),
          )
        else ...[
          Mono('${parsed.rgbString()}'),
          Mono('${parsed.hexString()}'),
          Mono('${parsed.hslString()}'),
        ],
      ],
    );
    final hoverBox = Column(
      children: [
        ColorSwatchBox(color: cssColor(hover), size: 32),
        const SizedBox(height: 2),
        Text('hover', style: theme.textTheme.labelSmall),
        if (hover != null) Mono(hover, style: theme.textTheme.labelSmall),
      ],
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ColorSwatchBox(color: flutterColor(parsed), size: 48),
        const SizedBox(width: 12),
        Expanded(child: strings),
        const SizedBox(width: 8),
        hoverBox,
      ],
    );
  }
}
