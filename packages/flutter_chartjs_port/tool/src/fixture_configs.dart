// Original code, not ported from Chart.js: the typed configs of the fixtures.
// The writer builds Dart source in string interpolations, which the formatter
// does not break.
// ignore_for_file: lines_longer_than_80_chars

/// The writer of the typed fixture configs (Chart.js ADR 0199): it turns the
/// config of one upstream fixture, `{config, options, description}`, into
/// the Dart source of a `FixtureConfig` of `chartjs_test_utils`, with the
/// typed `ChartConfig` of the typed API of `lib/src/typed/`.
///
/// The input is a tree of [FixtureValue]s: the decoded JSON of
/// `doc/upstream/fixtures.json` ([fixtureValueOf]), or the literals of a
/// hand port, where a Dart expression that is not a literal stays its
/// source ([FixtureCode]).
///
/// The rules:
/// 1. Each option with a typed parameter of the same value type goes to that
///    parameter. Each other option goes to the `extra` Map of the nearest
///    typed class, in the order of the upstream keys.
/// 2. A value takes the native form of `nativeFixtureColors` of
///    `chartjs_test_utils`: a CSS color is a `ChartPaint.solid` of its
///    `Color` ([cssColorExpression]), a keyword of an option with an enum is
///    the enum value, and `fill: false` is `FillTarget.none`.
/// 3. The axes are typed only when the typed ids of Chart.js ADR 0191 are the
///    upstream ids and no two axes are equal. Else all axes go to
///    `extra['scales']`.
/// 4. A config that a `ChartConfig` cannot hold keeps its Map
///    (`FixtureConfig.map`): no dataset, a first dataset of another type than
///    the chart, a chart type with no dataset class, a label that is no
///    `Object`, or a key of `config` or `data` with no typed parameter.
///    [FixtureEmitter.mapReason] gives the reason.
library;

import 'dart:convert';

// ---------------------------------------------------------------------------
// The value tree.

/// A value of a fixture config.
sealed class FixtureValue() {
  /// The comments before the value in a hand port, one item for each line.
  List<String> get comments;
}

/// An object literal: its entries in their order.
final class FixtureMap(
  /// The entries, in the source order.
  final List<FixtureEntry> entries, {
  @override final List<String> comments = const [],
}) extends FixtureValue {
  /// An object with [entries].
  this;

  /// The value of [key], or Dart `null`.
  FixtureValue? operator [](String key) {
    for (final entry in entries) {
      if (entry.key == key) return entry.value;
    }
    return null;
  }

  /// Whether the object has [key].
  bool has(String key) => entries.any((entry) => entry.key == key);

  /// The keys, in the source order.
  List<String> get keys => [for (final entry in entries) entry.key];
}

/// One entry of a [FixtureMap].
final class FixtureEntry(
  /// The key.
  final String key,

  /// The value.
  final FixtureValue value, {

  /// The comments before the entry in a hand port.
  final List<String> comments = const [],
}) {
  /// The entry [key] with [value].
  this;
}

/// An array literal.
final class FixtureList(
  /// The items.
  final List<FixtureValue> items, {
  @override final List<String> comments = const [],
}) extends FixtureValue {
  /// An array of [items].
  this;
}

/// A string.
final class FixtureString(
  /// The value.
  final String value, {
  @override final List<String> comments = const [],
}) extends FixtureValue {
  /// The string [value].
  this;
}

/// A number, with its source text.
final class FixtureNumber(
  /// The value.
  final num value,

  /// The Dart literal: an `int` literal for an integer of the source.
  final String text, {
  @override final List<String> comments = const [],
}) extends FixtureValue {
  /// The number [value] with the Dart literal [text].
  this;
}

/// `true` or `false`.
final class FixtureBool(
  /// The value.
  final bool value, {
  @override final List<String> comments = const [],
}) extends FixtureValue {
  /// The boolean [value].
  this;
}

/// `null`.
final class FixtureNull({@override final List<String> comments = const []})
    extends FixtureValue {
  /// The `null` value.
  this;
}

/// A Dart expression of a hand port that is no literal: a closure, an enum
/// value, an object of the port.
final class FixtureCode(
  /// The source of the expression.
  final String source, {
  @override final List<String> comments = const [],
}) extends FixtureValue {
  /// The expression [source].
  this;

  /// Whether the expression is a closure.
  bool get isFunction =>
      RegExp(r'^(async\s+)?\(').hasMatch(source) &&
      (source.contains('=>') || source.contains(') {'));
}

/// The value tree of the decoded JSON [json].
FixtureValue fixtureValueOf(Object? json) => switch (json) {
  null => FixtureNull(),
  final bool b => FixtureBool(b),
  final int i => FixtureNumber(i, '$i'),
  final double d => FixtureNumber(d, _doubleText(d)),
  final String s => FixtureString(s),
  final List<Object?> list => FixtureList([
    for (final item in list) fixtureValueOf(item),
  ]),
  final Map<String, Object?> map => FixtureMap([
    for (final MapEntry(:key, :value) in map.entries)
      FixtureEntry(key, fixtureValueOf(value)),
  ]),
  _ => throw ArgumentError.value(json, 'json', 'no JSON value'),
};

/// The Dart literal of the double [d] of a JSON text: a double literal.
String _doubleText(double d) {
  final text = d.toString();
  return text.contains('.') || text.contains('e') ? text : '$text.0';
}

// ---------------------------------------------------------------------------
// CSS colors.

/// The CSS color names of the fixtures, with their `#rrggbb` value.
///
/// A name of another color stops the writer: add it here.
/// `test/tool/fixture_configs_test.dart` compares each entry with the
/// `paintOfCss` of `chartjs_test_utils`.
const Map<String, int> cssColorNames = {
  'black': 0x000000,
  'blue': 0x0000ff,
  'brown': 0xa52a2a,
  'cyan': 0x00ffff,
  'gray': 0x808080,
  'green': 0x008000,
  'grey': 0x808080,
  'lightgray': 0xd3d3d3,
  'lightgrey': 0xd3d3d3,
  'lime': 0x00ff00,
  'magenta': 0xff00ff,
  'navy': 0x000080,
  'orange': 0xffa500,
  'pink': 0xffc0cb,
  'purple': 0x800080,
  'red': 0xff0000,
  'silver': 0xc0c0c0,
  'white': 0xffffff,
  'yellow': 0xffff00,
};

/// The red, green, blue and alpha channels of the CSS color [text], with
/// alpha in 0 to 255 (`hexParse`, `rgbParse` and `nameParse` of
/// @kurkle/color), or Dart `null` for another text.
({int r, int g, int b, double a})? cssChannels(String text) {
  if (text.startsWith('#')) {
    int digit(int i) {
      final c = text.codeUnitAt(i) | 32;
      if (c >= 48 && c <= 57) return c - 48;
      return c >= 97 && c <= 102 ? c - 87 : 0;
    }

    return switch (text.length) {
      4 || 5 => (
        r: digit(1) * 17,
        g: digit(2) * 17,
        b: digit(3) * 17,
        a: text.length == 5 ? digit(4) * 17.0 : 255.0,
      ),
      7 || 9 => (
        r: digit(1) << 4 | digit(2),
        g: digit(3) << 4 | digit(4),
        b: digit(5) << 4 | digit(6),
        a: text.length == 9 ? (digit(7) << 4 | digit(8)).toDouble() : 255.0,
      ),
      _ => null,
    };
  }
  final rgb = RegExp(
    r'^rgba?\(\s*([-+.\d]+)[\s,]+([-+.e\d]+)[\s,]+([-+.e\d]+)(?:[\s,/]+([-+.e\d]+))?\s*\)$',
  ).firstMatch(text);
  if (rgb != null) {
    int byte(String s) => double.parse(s).clamp(0, 255).toInt() & 255;
    final alpha = rgb[4];
    return (
      r: byte(rgb[1]!),
      g: byte(rgb[2]!),
      b: byte(rgb[3]!),
      a: alpha == null ? 255.0 : (double.parse(alpha) * 255).clamp(0, 255),
    );
  }
  if (text.toLowerCase() == 'transparent') return (r: 0, g: 0, b: 0, a: 0.0);
  final named = cssColorNames[text.toLowerCase()];
  if (named == null) return null;
  return (r: named >> 16 & 255, g: named >> 8 & 255, b: named & 255, a: 255.0);
}

/// The Dart expression of the `Color` of the CSS color [text], as
/// `paintOfCss` of `chartjs_test_utils` gives it: `Color(0xAARRGGBB)` when
/// the alpha is a byte, else `Color.fromRGBO`. Dart `null` for a text that
/// is no color.
String? cssColorExpression(String text) {
  final channels = cssChannels(text);
  if (channels == null) return null;
  final (:r, :g, :b, :a) = channels;
  // KurkleColor.fromRgbaBytes, then rgbaBytes and Color.fromRGBO of
  // paintOfCss: the opacity is ((a / 255) * 255) / 255.
  final opacity = ((a / 255).clamp(0.0, 1.0) * 255) / 255;
  final alpha = (opacity * 255).round();
  if (alpha / 255 == opacity) {
    final argb = (alpha << 24 | r << 16 | g << 8 | b).toRadixString(16);
    return 'Color(0x${argb.padLeft(8, '0').toUpperCase()})';
  }
  return 'Color.fromRGBO($r, $g, $b, $opacity)';
}

// ---------------------------------------------------------------------------
// The literals.

/// The Dart string literal of [s].
String dartString(String s) {
  final escaped = s
      .replaceAll(r'\', r'\\')
      .replaceAll(r'$', r'\$')
      .replaceAll('\n', r'\n')
      .replaceAll('\r', r'\r')
      .replaceAll('\t', r'\t');
  if (!escaped.contains("'")) return "'$escaped'";
  if (!escaped.contains('"')) return '"$escaped"';
  return "'${escaped.replaceAll("'", r"\'")}'";
}

/// The comments of [comments] as lines before a value.
String _commentLines(List<String> comments) =>
    comments.isEmpty ? '' : '${comments.join('\n')}\n';

/// The Dart literal of [value] as it is: `<String, Object?>{...}` for an
/// object and `<Object?>[...]` for an array, with the comments of a hand
/// port.
String literalOf(FixtureValue value) {
  final comments = _commentLines(value.comments);
  return switch (value) {
    FixtureMap(:final entries) =>
      '$comments<String, Object?>{${[for (final entry in entries) '${_commentLines(entry.comments)}${dartString(entry.key)}: ${literalOf(entry.value)}'].map(_comma).join()}}',
    FixtureList(:final items) =>
      '$comments<Object?>[${_items(items.map(literalOf))}]',
    FixtureString(value: final s) => '$comments${dartString(s)}',
    FixtureNumber(:final text) => '$comments$text',
    FixtureBool(value: final b) => '$comments$b',
    FixtureNull() => '${comments}null',
    FixtureCode(:final source) => '$comments$source',
  };
}

// ---------------------------------------------------------------------------
// The native values of nativeFixtureColors.

/// Whether [key] is a color option (`_isColor` of `nativeFixtureColors`).
bool isColorKey(String key) =>
    key == 'color' ||
    key == 'multiKeyBackground' ||
    key == 'above' ||
    key == 'below' ||
    key.endsWith('Color') ||
    key == 'fillStyle' ||
    key == 'strokeStyle';

/// The enum values by name of the enums of the keywords.
const Map<String, List<String>> _enums = {
  'StrokeCap': ['butt', 'round', 'square'],
  'StrokeJoin': ['miter', 'round', 'bevel'],
  'ChartAlign': ['start', 'center', 'end'],
  'ChartPosition': ['top', 'left', 'bottom', 'right', 'center', 'chartArea'],
  'ArcBorderAlign': ['center', 'inner'],
  'ArcSpacingMode': ['angular', 'proportional', 'parallel'],
  'TimeUnit': [
    'millisecond',
    'second',
    'minute',
    'hour',
    'day',
    'week',
    'month',
    'quarter',
    'year',
  ],
  'TextDirection': ['rtl', 'ltr'],
  'TextAlign': ['left', 'right', 'center', 'justify', 'start', 'end'],
  'SteppedLine': ['before', 'after', 'middle'],
  'BorderSkippedEdge': [
    'start',
    'end',
    'middle',
    'bottom',
    'left',
    'top',
    'right',
  ],
  'BorderSkip': ['start', 'end', 'middle', 'bottom', 'left', 'top', 'right'],
  'ScaleBounds': ['data', 'ticks'],
  'TickSource': ['auto', 'data', 'labels'],
  'TickAlign': ['start', 'center', 'end', 'inner'],
  'TickCrossAlign': ['near', 'center', 'far'],
  'InteractionAxis': ['x', 'y', 'xy', 'r'],
};

/// The enum expression of the keyword [name] of the enum [type], or Dart
/// `null` when the enum has no value of that name.
String? enumExpression(String type, String name) =>
    (_enums[type] ?? const []).contains(name) ? '$type.$name' : null;

/// The writer of one fixture config.
final class FixtureEmitter(
  /// The fixture path, relative to `test/fixtures/`.
  final String path,
) {
  /// The writer of the config of the fixture [path].
  this;

  /// The reason why the config keeps its Map, or Dart `null`.
  String? mapReason;

  /// Each option that goes to an `extra` Map: `<class>.extra['<key>']`.
  final List<String> extras = [];

  /// The local declarations before the config: the axes that a dataset
  /// names.
  final List<String> declarations = [];

  // -------------------------------------------------------------------------
  // The native values.

  /// The native form of the color value [value]: `color` of
  /// `nativeFixtureColors`.
  String nativeColor(FixtureValue value) {
    final comments = _commentLines(value.comments);
    switch (value) {
      case FixtureBool(value: false):
        return '${comments}null';
      case FixtureString(value: final s):
        if (s.isEmpty) return '${comments}null';
        final color = cssColorExpression(s);
        if (color == null) {
          throw FormatException('$path: the color "$s" is no CSS color.');
        }
        return '${comments}ChartPaint.solid($color)';
      case FixtureList(:final items):
        return '$comments<Object?>[${_items(items.map(nativeColor))}]';
      default:
        return literalOf(value);
    }
  }

  /// The native form of the keyword [value] of the enum [type]
  /// (`_enumValue` of `nativeFixtureColors`): a name of a value of the enum
  /// is that value, an array takes each item so, and another value stays.
  String nativeEnum(String type, FixtureValue value) {
    final comments = _commentLines(value.comments);
    return switch (value) {
      FixtureString(value: final s) =>
        '$comments${enumExpression(type, s) ?? dartString(s)}',
      FixtureList(:final items) =>
        '$comments<Object?>[${_items(items.map((i) => nativeEnum(type, i)))}]',
      _ => literalOf(value),
    };
  }

  /// The native form of the value [value] of the key [key] in an object of
  /// the key [owner], whose object has the key [grand]: the walk of
  /// `nativeFixtureColors`, and `fill: false` as `FillTarget.none`
  /// (`nativeFixtureFalseFills`).
  String nativeValue(
    String key,
    FixtureValue value, {
    String? owner,
    String? grand,
  }) {
    final comments = _commentLines(value.comments);
    if (isColorKey(key)) return nativeColor(value);
    if (value is FixtureCode) return literalOf(value);
    switch (key) {
      case 'fill' when value is FixtureBool && !value.value:
        return '${comments}FillTarget.none';
      case 'borderCapStyle' || 'lineCap':
        return nativeEnum('StrokeCap', value);
      case 'borderJoinStyle' || 'lineJoin':
        return nativeEnum('StrokeJoin', value);
      case 'align'
          when owner == 'legend' || owner == 'title' || owner == 'subtitle':
        return nativeEnum('ChartAlign', value);
      case 'position' when owner != 'tooltip':
        if (owner == 'title') {
          if (value case FixtureString(value: final s)) {
            final position =
                enumExpression('ChartAlign', s) ??
                enumExpression('ChartPosition', s);
            if (position != null) return '$comments$position';
          }
          return literalOf(value);
        }
        if (value case FixtureMap(entries: [final entry])) {
          return '${comments}ScaleValuePosition(${dartString(entry.key)}, ${literalOf(entry.value)})';
        }
        return nativeEnum('ChartPosition', value);
      case 'borderAlign':
        return nativeEnum('ArcBorderAlign', value);
      case 'spacingMode':
        return nativeEnum('ArcSpacingMode', value);
      case 'unit' || 'minUnit' || 'round' when owner == 'time':
        return nativeEnum('TimeUnit', value);
      case 'textDirection':
        return nativeEnum('TextDirection', value);
      case 'textAlign' || 'titleAlign' || 'bodyAlign' || 'footerAlign':
        return nativeEnum('TextAlign', value);
      case 'stepped':
        return nativeEnum('SteppedLine', value);
      case 'borderSkipped':
        return nativeEnum('BorderSkippedEdge', value);
      case 'display' when owner == 'pointLabels' || grand == 'scales':
        return '$comments${_scaleDisplay(value) ?? literalOf(value)}';
      case 'text' when owner == 'title' || owner == 'subtitle':
        return switch (value) {
          FixtureString(value: final s) =>
            '$comments<String>[${dartString(s)}]',
          FixtureList(:final items) =>
            '$comments<String>[${[for (final item in items) dartString(_jsText(item))].map(_comma).join()}]',
          _ => literalOf(value),
        };
      case 'borderDash' || 'hoverBorderDash' || 'tickBorderDash'
          when value is FixtureList &&
              value.items.every((item) => item is FixtureNumber):
        return '$comments<double>[${_items(value.items.map((i) => (i as FixtureNumber).text))}]';
      case 'barThickness':
        return switch (value) {
          FixtureNumber(:final text) => '${comments}BarThickness.pixels($text)',
          FixtureString(value: 'flex') => '${comments}BarThickness.flex',
          _ => literalOf(value),
        };
      case 'stacked':
        return '$comments${_stackMode(value) ?? literalOf(value)}';
      case 'bounds':
        return nativeEnum('ScaleBounds', value);
      case 'source' when owner == 'ticks':
        return nativeEnum('TickSource', value);
      case 'align' when owner == 'ticks':
        return nativeEnum('TickAlign', value);
      case 'crossAlign' when owner == 'ticks':
        return nativeEnum('TickCrossAlign', value);
    }
    if (value is FixtureMap) {
      final entries = [
        for (final entry in value.entries)
          _entryOf(
            entry,
            nativeValue(entry.key, entry.value, owner: key, grand: owner),
          ),
      ];
      return '$comments<String, Object?>{${_items(entries)}}';
    }
    return literalOf(value);
  }

  /// The JS text of a line of a title text.
  String _jsText(FixtureValue value) => switch (value) {
    FixtureString(value: final s) => s,
    FixtureNumber(:final value) =>
      value == value.roundToDouble() && value.abs() < 1e21
          ? value.toInt().toString()
          : '$value',
    FixtureBool(:final value) => '$value',
    _ => throw FormatException('$path: a title line that is no text.'),
  };

  /// The `ScaleDisplay` of an upstream `display`, or Dart `null`.
  String? _scaleDisplay(FixtureValue value) => switch (value) {
    FixtureBool(value: true) => 'ScaleDisplay.on',
    FixtureBool(value: false) => 'ScaleDisplay.off',
    FixtureString(value: 'auto') => 'ScaleDisplay.auto',
    FixtureCode(:final source) when source.startsWith('ScaleDisplay.') =>
      source,
    _ => null,
  };

  /// The `StackMode` of an upstream `stacked`, or Dart `null`.
  String? _stackMode(FixtureValue value) => switch (value) {
    FixtureBool(value: true) => 'StackMode.on',
    FixtureBool(value: false) => 'StackMode.off',
    FixtureString(value: 'single') => 'StackMode.single',
    FixtureCode(:final source) when source.startsWith('StackMode.') => source,
    _ => null,
  };

  // -------------------------------------------------------------------------
  // The typed config.

  /// The source of the `FixtureConfig` of [json], `{config, options,
  /// description}`. When the config cannot be typed, [mapReason] gives the
  /// reason and the result is `FixtureConfig.map` of [json].
  String emit(FixtureMap json) {
    final config = json['config'];
    final typed = config is FixtureMap ? _chartConfig(config) : null;
    if (typed == null) {
      mapReason ??= 'the fixture has no config object';
      declarations.clear();
    }
    final args = <String>[typed ?? literalOf(config ?? FixtureMap([]))];
    for (final entry in json.entries) {
      final c = _commentLines(entry.comments);
      switch (entry.key) {
        case 'config':
          break;
        case 'options':
          args.addAll(_acquireOptions(entry.value, c));
        case 'description':
          args.add('${c}description: ${literalOf(entry.value)}');
        case 'threshold' || 'tolerance' || 'debug':
          // The image comparison has no port (Chart.js ADR 0034, section 4).
          break;
        default:
          throw FormatException('$path: the fixture key ${entry.key}.');
      }
    }
    final kind = typed == null ? 'map' : 'typed';
    return 'FixtureConfig.$kind(${args.map(_comma).join()})';
  }

  /// The arguments `options` (the typed `AcquireOptions` of Chart.js ADR
  /// 0200) and `run` of the fixture options [options]. `spriteText` has no
  /// port (utils.js:90-92).
  List<String> _acquireOptions(FixtureValue options, String comments) {
    if (options is! FixtureMap) {
      throw FormatException('$path: the fixture options are no object.');
    }
    final acquire = <String>[];
    final run = <String>[];
    for (final entry in options.entries) {
      final c = _commentLines(entry.comments);
      final value = entry.value;
      switch (entry.key) {
        case 'canvas' when value is FixtureMap:
          final size = [
            for (final key in const ['width', 'height'])
              if (value[key] case final FixtureValue v) '$key: ${literalOf(v)}',
          ];
          acquire.add('${c}canvas: HarnessCanvas(${size.join(', ')})');
        case 'useOffscreenCanvas' || 'useShadowDOM' || 'persistent':
          acquire.add('$c${entry.key}: ${literalOf(value)}');
        case 'run':
          run.add('${c}run: ${literalOf(value)}');
        case 'spriteText':
          break;
        default:
          throw FormatException('$path: the fixture option ${entry.key}.');
      }
    }
    return [
      if (acquire.isNotEmpty)
        '${comments}options: AcquireOptions(${acquire.map(_comma).join()})',
      ...run,
    ];
  }

  /// The source of the `ChartConfig` of [config], or Dart `null` with
  /// [mapReason].
  String? _chartConfig(FixtureMap config) {
    for (final key in config.keys) {
      if (!const {'type', 'data', 'options', 'plugins'}.contains(key)) {
        mapReason = 'the config key `$key` has no parameter of ChartConfig';
        return null;
      }
    }
    final type = config['type'];
    if (type == null) {
      mapReason =
          'the config has no chart type, and a ChartConfig takes the type of '
          'its first dataset (Chart.js ADR 0190)';
      return null;
    }
    if (type is! FixtureString || !_datasetClasses.containsKey(type.value)) {
      mapReason = 'the chart type has no dataset class';
      return null;
    }
    final chartType = type.value;
    final data = config['data'];
    if (data is! FixtureMap) {
      mapReason =
          'the config has no data: a ChartConfig needs a dataset (Chart.js '
          'ADR 0190)';
      return null;
    }
    for (final key in data.keys) {
      if (key != 'labels' && key != 'datasets') {
        mapReason = 'the data key `$key` has no parameter of ChartConfig';
        return null;
      }
    }
    final datasets = data['datasets'];
    if (datasets is! FixtureList || datasets.items.isEmpty) {
      mapReason =
          'the config has no dataset: a ChartConfig needs one (Chart.js ADR '
          '0190)';
      return null;
    }
    final options = config['options'];
    if (options != null && options is! FixtureMap) {
      mapReason = 'the options are no object';
      return null;
    }
    final optionsMap = options is FixtureMap ? options : FixtureMap([]);
    final indexAxis = switch (optionsMap['indexAxis']) {
      FixtureString(value: final s) => s,
      FixtureCode(source: final s) when RegExp(r'YAxis|\.y\b').hasMatch(s) =>
        'y',
      _ => 'x',
    };
    final args = <String>[];
    // The datasets.
    final scales = _Scales(this, chartType, indexAxis, optionsMap['scales']);
    final datasetSources = <String>[];
    for (final (i, item) in datasets.items.indexed) {
      if (item is! FixtureMap) {
        mapReason = 'the dataset $i is no object';
        return null;
      }
      final kind = switch (item['type']) {
        FixtureString(value: final s) => s,
        null => chartType,
        _ => null,
      };
      if (kind == null || !_datasetClasses.containsKey(kind)) {
        mapReason = 'the dataset $i has a type with no dataset class';
        return null;
      }
      if (i == 0 && kind != chartType) {
        mapReason =
            'the first dataset has another type than the chart: the class of '
            'the first dataset gives the chart type (Chart.js ADR 0190)';
        return null;
      }
      final dataset = _dataset(item, kind, chartType, scales);
      if (dataset == null) return null;
      datasetSources.add(dataset);
    }
    // labels
    final labels = data['labels'];
    String? labelsSource;
    if (labels != null) {
      if (labels is FixtureList &&
          labels.items.every(
            (item) =>
                item is FixtureString ||
                item is FixtureNumber ||
                (item is FixtureList &&
                    item.items.every((line) => line is FixtureString)) ||
                (item is FixtureCode && !item.source.contains('null')),
          )) {
        labelsSource = '<Object>[${_items(labels.items.map(literalOf))}]';
      } else if (labels is FixtureCode) {
        labelsSource = labels.source;
      } else {
        mapReason = 'a label is no Object of ChartConfig.labels';
        return null;
      }
    }
    args.add(
      '${_commentLines(datasets.comments)}datasets: [${datasetSources.map(_comma).join()}]',
    );
    if (labelsSource != null) {
      args.add('${_commentLines(labels!.comments)}labels: $labelsSource');
    }
    // The options.
    final extra = <String>[];
    final pluginOptions = <String>[];
    final disabled = <String>[];
    String? scalesSource;
    for (final entry in optionsMap.entries) {
      final key = entry.key;
      final value = entry.value;
      final c = _commentLines(entry.comments);
      String? typed;
      switch (key) {
        case 'scales':
          scalesSource = scales.typedSource;
          if (scalesSource == null) {
            extra.add('$c${dartString(key)}: ${nativeValue(key, value)}');
            extras.add('ChartConfig.extra[scales]');
          } else {
            args.add('${c}scales: $scalesSource');
          }
          continue;
        case 'indexAxis':
          typed = switch (value) {
            FixtureString(value: 'x') => 'CartesianAxis.x',
            FixtureString(value: 'y') => 'CartesianAxis.y',
            FixtureCode(:final source) => source,
            _ => null,
          };
        case 'parsing' || 'responsive' || 'maintainAspectRatio' || 'normalized'
            when value is FixtureBool:
          typed = literalOf(value);
        case 'aspectRatio' || 'devicePixelRatio' when value is FixtureNumber:
          typed = literalOf(value);
        case 'color':
          typed = _paint(this, value, key, 'options');
        case 'locale'
            when value is FixtureCode &&
                value.source.startsWith('Locale(') &&
                !value.isFunction:
          typed = value.source;
        case 'layout':
          if (value is FixtureMap &&
              value.keys.length == 1 &&
              value['padding'] is FixtureCode &&
              !(value['padding']! as FixtureCode).isFunction) {
            args.add('${c}padding: ${literalOf(value['padding']!)}');
            continue;
          }
        case 'interaction' when value is FixtureMap:
          typed = _group('ChartInteraction', value, const {
            'mode': _code,
            'intersect': _bool,
            'axis': _interactionAxis,
            'includeInvisible': _bool,
          }, key: key);
        case 'animation':
          if (value is FixtureBool && !value.value) {
            typed = 'ChartAnimation.none';
          } else if (value is FixtureCode) {
            typed = value.source;
          }
        case 'elements' when value is FixtureMap:
          typed = _elements(value);
        case 'onClick' || 'onHover' when value is FixtureCode:
          typed = value.source;
        case 'events'
            when value is FixtureList &&
                value.items.every((i) => i is FixtureString):
          typed = '<String>[${_items(value.items.map(literalOf))}]';
        case 'plugins' when value is FixtureMap:
          final rest = <FixtureEntry>[];
          for (final plugin in value.entries) {
            final off = _pluginClasses[plugin.key];
            final v = plugin.value;
            if (off != null && v is FixtureBool && !v.value) {
              disabled.add(
                '${_commentLines(plugin.comments)}PluginOff<$off>()',
              );
            } else if (v is FixtureCode &&
                _pluginOptionClasses.any(
                  (name) =>
                      v.source.startsWith('$name(') ||
                      v.source.startsWith('const $name('),
                )) {
              pluginOptions.add('${_commentLines(plugin.comments)}${v.source}');
            } else {
              rest.add(plugin);
            }
          }
          if (rest.isNotEmpty) {
            final restMap = FixtureMap(rest);
            extra.add('$c${dartString(key)}: ${nativeValue(key, restMap)}');
            for (final plugin in rest) {
              extras.add('ChartConfig.extra[plugins.${plugin.key}]');
            }
          }
          continue;
      }
      if (typed != null) {
        args.add('$c${_param(key)}: $typed');
      } else {
        extra.add('$c${dartString(key)}: ${nativeValue(key, value)}');
        extras.add('ChartConfig.extra[$key]');
      }
    }
    if (pluginOptions.isNotEmpty) {
      args.add('pluginOptions: [${pluginOptions.map(_comma).join()}]');
    }
    if (disabled.isNotEmpty) {
      args.add('disabledPlugins: [${disabled.map(_comma).join()}]');
    }
    final plugins = config['plugins'];
    if (plugins != null) {
      args.add(
        '${_commentLines(plugins.comments)}plugins: ${_pluginList(plugins)}',
      );
    }
    if (extra.isNotEmpty) {
      args.add('extra: <String, Object?>{${extra.map(_comma).join()}}');
    }
    if (options != null && options.comments.isNotEmpty) {
      args.first = '${_commentLines(options.comments)}${args.first}';
    }
    return 'ChartConfig(${args.map(_comma).join()})';
  }

  /// The source of the inline plugins [plugins].
  String _pluginList(FixtureValue plugins) => switch (plugins) {
    FixtureList(:final items) => '[${_items(items.map(literalOf))}]',
    _ => literalOf(plugins),
  };

  /// The parameter name of the option [key] of ChartConfig.
  static String _param(String key) => key;

  /// The source of a typed group [type] of the object [value]: each key of
  /// [fields] whose converter gives a value is a parameter, and each other
  /// key goes to `extra`.
  String _group(
    String type,
    FixtureMap value,
    Map<String, _Convert> fields, {
    required String key,
    String? owner,
    List<String> leading = const [],
  }) {
    final args = [...leading];
    final extra = <String>[];
    for (final entry in value.entries) {
      final convert = fields[entry.key];
      final typed = convert?.call(this, entry.value, entry.key, key);
      final c = _commentLines(entry.comments);
      if (typed != null) {
        args.add('$c${_paramName(entry.key)}: $typed');
      } else {
        extra.add(
          '$c${dartString(entry.key)}: '
          '${nativeValue(entry.key, entry.value, owner: key, grand: owner)}',
        );
        extras.add('$type.extra[${entry.key}]');
      }
    }
    if (extra.isNotEmpty) {
      args.add('extra: <String, Object?>{${extra.map(_comma).join()}}');
    }
    return '${_commentLines(value.comments)}$type(${args.map(_comma).join()})';
  }

  static String _paramName(String key) => key;

  /// The source of the `ChartElements` of [elements].
  String _elements(FixtureMap elements) {
    final args = <String>[];
    final extra = <String>[];
    for (final entry in elements.entries) {
      final value = entry.value;
      final c = _commentLines(entry.comments);
      final style = switch (entry.key) {
        'point' => ('PointElementStyle', _pointStyleFields),
        'line' => ('LineElementStyle', _lineStyleFields),
        'bar' => ('BarElementStyle', _barStyleFields),
        'arc' => ('ArcElementStyle', _arcStyleFields),
        _ => null,
      };
      if (style != null && value is FixtureMap) {
        args.add(
          '$c${entry.key}: ${_group(style.$1, value, style.$2, key: entry.key, owner: 'elements')}',
        );
      } else {
        extra.add(
          '$c${dartString(entry.key)}: ${nativeValue(entry.key, value, owner: 'elements')}',
        );
        extras.add('ChartElements.extra[${entry.key}]');
      }
    }
    if (extra.isNotEmpty) {
      args.add('extra: <String, Object?>{${extra.map(_comma).join()}}');
    }
    return '${_commentLines(elements.comments)}ChartElements(${args.map(_comma).join()})';
  }

  /// The source of the dataset [item] of the type [kind], or Dart `null`
  /// with [mapReason].
  String? _dataset(
    FixtureMap item,
    String kind,
    String chartType,
    _Scales scales,
  ) {
    final type = _datasetClasses[kind]!;
    final fields = _datasetFields(kind);
    final args = <String>[];
    final extra = <String>[];
    for (final entry in item.entries) {
      final key = entry.key;
      final value = entry.value;
      final c = _commentLines(entry.comments);
      String? typed;
      if (key == 'type') {
        // The class gives the type. A type equal to the chart type has no
        // key in the lowering: the default of the chart.
        continue;
      } else if (key == 'data') {
        typed = _data(kind, value);
      } else if (key == 'label') {
        typed = value is FixtureString ? literalOf(value) : null;
      } else if (key == 'xAxisID' || key == 'yAxisID') {
        if (value is FixtureString &&
            kind != 'radar' &&
            !kind.contains('pie') &&
            kind != 'doughnut' &&
            kind != 'polarArea') {
          typed = scales.variableOf(value.value);
          if (typed != null) {
            args.add('$c${key == 'xAxisID' ? 'xAxis' : 'yAxis'}: $typed');
            continue;
          }
        }
      } else if (key == 'tooltip' &&
          value is FixtureMap &&
          value.keys.length == 1 &&
          value['callbacks'] is FixtureCode) {
        args.add('${c}tooltipCallbacks: ${literalOf(value['callbacks']!)}');
        continue;
      } else if (fields[key] case final convert?) {
        typed = convert(this, value, key, null);
      }
      if (typed != null) {
        args.add('$c$key: $typed');
      } else {
        final native = key == 'data' || key == 'label'
            ? literalOf(value)
            : nativeValue(key, value);
        extra.add('$c${dartString(key)}: $native');
        extras.add('Dataset.extra[$key]');
      }
    }
    if (extra.isNotEmpty) {
      args.add('extra: <String, Object?>{${extra.map(_comma).join()}}');
    }
    return '${_commentLines(item.comments)}$type(${args.map(_comma).join()})';
  }

  /// The typed data of a dataset of [kind], or Dart `null`.
  String? _data(String kind, FixtureValue value) {
    if (value is! FixtureList) return null;
    final items = value.items;
    final numbers = items.every((i) => i is FixtureNumber || i is FixtureNull);
    final list = '[${_items(items.map(literalOf))}]';
    switch (kind) {
      case 'pie' || 'doughnut' || 'polarArea' || 'radar':
        return numbers ? '<num?>$list' : null;
      case 'bubble':
        final points = <String>[];
        for (final i in items) {
          final point = _point(i, bubble: true);
          if (point == null) return null;
          points.add(point);
        }
        return '[${points.map(_comma).join()}]';
      default:
        if (numbers) return '.values(<num?>$list)';
        final points = <String>[];
        for (final i in items) {
          final point = _point(i, bubble: false);
          if (point == null) return null;
          points.add(point);
        }
        return '.points([${points.map(_comma).join()}])';
    }
  }

  /// The `DataPoint` of the data item [item] `{x, y}` or `{x, y, r}`, or
  /// Dart `null`.
  String? _point(FixtureValue item, {required bool bubble}) {
    final point = _pointOf(item, bubble: bubble);
    return point == null ? null : '${_commentLines(item.comments)}$point';
  }

  String? _pointOf(FixtureValue item, {required bool bubble}) {
    if (item is! FixtureMap ||
        item.entries.any((entry) => entry.comments.isNotEmpty)) {
      return null;
    }
    final keys = item.keys.toSet();
    final x = item['x'];
    final y = item['y'];
    final r = item['r'];
    if (bubble) {
      if (keys.length != 3 ||
          x is! FixtureNumber ||
          y is! FixtureNumber ||
          r is! FixtureNumber) {
        return null;
      }
      return 'DataPoint.bubble(${x.text}, ${y.text}, ${r.text})';
    }
    if (keys.length != 2 || x == null || y == null) return null;
    if (y is! FixtureNumber && y is! FixtureNull) return null;
    final yText = literalOf(y);
    return switch (x) {
      FixtureNumber(:final text) => 'DataPoint($text, $yText)',
      FixtureString(value: final s) =>
        'DataPoint.label(${dartString(s)}, $yText)',
      _ => null,
    };
  }
}

/// A converter of a typed parameter: the source of [value] of the option
/// [key] in the object of the key [owner], or Dart `null` when the
/// parameter cannot hold it.
typedef _Convert = String? Function(
  FixtureEmitter emitter,
  FixtureValue value,
  String key,
  String? owner,
);

String? _bool(FixtureEmitter e, FixtureValue v, String k, String? o) =>
    v is FixtureBool ? '${v.value}' : null;

String? _double(FixtureEmitter e, FixtureValue v, String k, String? o) =>
    v is FixtureNumber ? v.text : null;

String? _int(FixtureEmitter e, FixtureValue v, String k, String? o) =>
    v is FixtureNumber && v.value is int ? v.text : null;

String? _string(FixtureEmitter e, FixtureValue v, String k, String? o) =>
    v is FixtureString ? dartString(v.value) : null;

String? _code(FixtureEmitter e, FixtureValue v, String k, String? o) =>
    v is FixtureCode ? v.source : null;

/// A `ChartPaint`: a CSS color text or an expression of the port.
String? _paint(FixtureEmitter e, FixtureValue v, String k, String? o) =>
    switch (v) {
      FixtureString(value: final s) when s.isNotEmpty =>
        cssColorExpression(s) == null ? null : e.nativeColor(v),
      FixtureCode(:final source)
          when !v.isFunction && !source.startsWith('<') =>
        source,
      _ => null,
    };

/// A `ChartValue<ChartPaint>`.
String? _paintValue(FixtureEmitter e, FixtureValue v, String k, String? o) {
  switch (v) {
    case FixtureString():
      final paint = _paint(e, v, k, o);
      return paint == null ? null : '.constant($paint)';
    case FixtureList(:final items):
      final paints = <String>[];
      for (final item in items) {
        if (item.comments.isNotEmpty) return null;
        final paint = _paint(e, item, k, o);
        if (paint == null) return null;
        paints.add(paint);
      }
      return '.indexed(<ChartPaint>[${paints.map(_comma).join()}])';
    case FixtureCode(:final source) when v.isFunction:
      return '.resolver($source)';
    default:
      return null;
  }
}

/// A `ChartValue<double>`.
String? _doubleValue(FixtureEmitter e, FixtureValue v, String k, String? o) {
  switch (v) {
    case FixtureNumber(:final text):
      return '.constant($text)';
    case FixtureList(:final items)
        when items.every((i) => i is FixtureNumber && i.comments.isEmpty):
      return '.indexed(<double>[${_items(items.map((i) => (i as FixtureNumber).text))}])';
    case FixtureCode(:final source) when v.isFunction:
      return '.resolver($source)';
    default:
      return null;
  }
}

/// A `ChartValue<PointStyle>`.
String? _pointStyleValue(
  FixtureEmitter e,
  FixtureValue v,
  String k,
  String? o,
) => switch (v) {
  FixtureCode(:final source) when v.isFunction => '.resolver($source)',
  FixtureCode(:final source) when !source.startsWith('<') =>
    '.constant($source)',
  _ => null,
};

/// An enum of the name [type].
_Convert _enum(String type) =>
    (e, v, k, o) => switch (v) {
      FixtureString(value: final s) => enumExpression(type, s),
      FixtureCode(:final source) when source.startsWith('$type.') => source,
      _ => null,
    };

String? _interactionAxis(
  FixtureEmitter e,
  FixtureValue v,
  String k,
  String? o,
) => _enum('InteractionAxis')(e, v, k, o);

/// A `List<double>` of numbers.
String? _doubles(FixtureEmitter e, FixtureValue v, String k, String? o) =>
    v is FixtureList &&
        v.items.every((i) => i is FixtureNumber && i.comments.isEmpty)
    ? '<double>[${_items(v.items.map((i) => (i as FixtureNumber).text))}]'
    : null;

/// A `BorderSkip`: `false`, `true` or an edge keyword.
String? _borderSkip(FixtureEmitter e, FixtureValue v, String k, String? o) =>
    switch (v) {
      FixtureBool(value: false) => 'BorderSkip.none',
      FixtureBool(value: true) => 'BorderSkip.all',
      FixtureString(value: final s) => enumExpression('BorderSkip', s),
      _ => null,
    };

/// A `BarThickness`.
String? _barThickness(FixtureEmitter e, FixtureValue v, String k, String? o) =>
    switch (v) {
      FixtureNumber(:final text) => 'BarThickness.pixels($text)',
      FixtureString(value: 'flex') => 'BarThickness.flex',
      FixtureCode(:final source) when source.startsWith('BarThickness') =>
        source,
      _ => null,
    };

/// A `SteppedLine` keyword.
String? _stepped(FixtureEmitter e, FixtureValue v, String k, String? o) =>
    _enum('SteppedLine')(e, v, k, o);

/// An expression of the port that is not a closure: a class value.
String? _object(FixtureEmitter e, FixtureValue v, String k, String? o) =>
    v is FixtureCode && !v.isFunction && !v.source.startsWith('<')
    ? v.source
    : null;

/// A closure of the port.
String? _function(FixtureEmitter e, FixtureValue v, String k, String? o) =>
    v is FixtureCode && v.isFunction ? v.source : null;

/// A `FillTarget`: `false` or an expression of the port.
String? _fill(FixtureEmitter e, FixtureValue v, String k, String? o) =>
    switch (v) {
      FixtureBool(value: false) => 'FillTarget.none',
      FixtureCode(:final source) when source.startsWith('FillTarget') => source,
      _ => null,
    };

/// A `StrokeCap` or a `StrokeJoin`.
String? _strokeCap(FixtureEmitter e, FixtureValue v, String k, String? o) =>
    _enum('StrokeCap')(e, v, k, o);

String? _strokeJoin(FixtureEmitter e, FixtureValue v, String k, String? o) =>
    _enum('StrokeJoin')(e, v, k, o);

/// The dataset classes by chart type.
const Map<String, String> _datasetClasses = {
  'bar': 'BarDataset',
  'line': 'LineDataset',
  'scatter': 'ScatterDataset',
  'bubble': 'BubbleDataset',
  'pie': 'PieDataset',
  'doughnut': 'DoughnutDataset',
  'polarArea': 'PolarAreaDataset',
  'radar': 'RadarDataset',
};

/// The plugin classes of the built-in plugins, by plugin id.
const Map<String, String> _pluginClasses = {
  'colors': 'ColorsPlugin',
  'decimation': 'DecimationPlugin',
  'filler': 'FillerPlugin',
  'legend': 'LegendPlugin',
  'subtitle': 'SubtitlePlugin',
  'title': 'TitlePlugin',
  'tooltip': 'TooltipPlugin',
};

/// The options classes of the built-in plugins.
const List<String> _pluginOptionClasses = [
  'ColorsPluginOptions',
  'DecimationOptions',
  'FillerOptions',
  'LegendOptions',
  'SubtitleOptions',
  'TitleOptions',
  'TooltipOptions',
];

/// The typed parameters of a dataset of [kind], by option key.
Map<String, _Convert> _datasetFields(String kind) {
  const common = <String, _Convert>{
    'hidden': _bool,
    'order': _int,
    'clip': _object,
    'backgroundColor': _paintValue,
    'borderColor': _paintValue,
    'borderWidth': _double,
    'hoverBackgroundColor': _paintValue,
    'hoverBorderColor': _paintValue,
    'hoverBorderWidth': _double,
  };
  const line = <String, _Convert>{
    'fill': _fill,
    'tension': _double,
    'borderDash': _doubles,
    'borderCapStyle': _strokeCap,
    'borderJoinStyle': _strokeJoin,
    'spanGaps': _bool,
    'showLine': _bool,
    'stepped': _stepped,
    'cubicInterpolationMode': _object,
    'segment': _object,
    'pointRadius': _doubleValue,
    'pointHoverRadius': _doubleValue,
    'pointStyle': _pointStyleValue,
    'pointBackgroundColor': _paintValue,
    'pointBorderColor': _paintValue,
    'pointBorderWidth': _double,
    'pointHoverBackgroundColor': _paintValue,
    'pointHoverBorderColor': _paintValue,
    'borderDashOffset': _double,
    'capBezierPoints': _bool,
    'drawActiveElementsOnTop': _bool,
    'pointHitRadius': _doubleValue,
    'pointHoverBorderWidth': _doubleValue,
    'pointRotation': _doubleValue,
  };
  const arc = <String, _Convert>{
    'offset': _double,
    'hoverOffset': _double,
    'spacing': _double,
    'borderAlign': _arcBorderAlign,
    'borderJoinStyle': _strokeJoin,
    'borderRadius': _double,
    'selfJoin': _bool,
    'spacingMode': _arcSpacingMode,
  };
  return switch (kind) {
    'bar' => {
      ...common,
      'stack': _string,
      'indexAxis': _indexAxis,
      'borderRadius': _double,
      'barPercentage': _double,
      'categoryPercentage': _double,
      'barThickness': _barThickness,
      'maxBarThickness': _double,
      'minBarLength': _double,
      'grouped': _bool,
      'borderSkipped': _borderSkip,
      'base': _double,
      'inflateAmount': _double,
      'skipNull': _bool,
      'hoverBorderRadius': _double,
      'pointStyle': _object,
    },
    'line' => {...common, 'stack': _string, 'indexAxis': _indexAxis, ...line},
    'scatter' => {...common, 'stack': _string, ...line},
    'radar' => {...common, ...line},
    'bubble' => {
      ...common,
      'radius': _double,
      'hoverRadius': _double,
      'pointStyle': _object,
      'drawActiveElementsOnTop': _bool,
    },
    'pie' || 'doughnut' => {
      ...common,
      ...arc,
      'weight': _double,
      'circumference': _double,
      'rotation': _double,
      'cutout': _object,
      'radius': _object,
    },
    'polarArea' => {...common, ...arc, 'angle': _double},
    _ => common,
  };
}

String? _indexAxis(FixtureEmitter e, FixtureValue v, String k, String? o) =>
    switch (v) {
      FixtureString(value: 'x') => 'CartesianAxis.x',
      FixtureString(value: 'y') => 'CartesianAxis.y',
      FixtureCode(:final source) => source,
      _ => null,
    };

const Map<String, _Convert> _pointStyleFields = {
  'radius': _double,
  'pointStyle': _object,
  'backgroundColor': _paint,
  'borderColor': _paint,
  'borderWidth': _double,
  'hitRadius': _double,
  'hoverRadius': _double,
  'rotation': _double,
  'hoverBackgroundColor': _paint,
  'hoverBorderColor': _paint,
  'hoverBorderWidth': _double,
  'drawActiveElementsOnTop': _bool,
};

const Map<String, _Convert> _lineStyleFields = {
  'tension': _double,
  'backgroundColor': _paint,
  'borderColor': _paint,
  'borderWidth': _double,
  'borderDash': _doubles,
  'borderCapStyle': _strokeCap,
  'borderJoinStyle': _strokeJoin,
  'fill': _fill,
  'stepped': _stepped,
  'cubicInterpolationMode': _object,
  'segment': _object,
  'borderDashOffset': _double,
  'capBezierPoints': _bool,
};

const Map<String, _Convert> _barStyleFields = {
  'backgroundColor': _paint,
  'borderColor': _paint,
  'borderWidth': _double,
  'borderRadius': _double,
  'borderSkipped': _borderSkip,
  'inflateAmount': _double,
};

const Map<String, _Convert> _arcStyleFields = {
  'backgroundColor': _paint,
  'borderColor': _paint,
  'borderWidth': _double,
  'offset': _double,
  'spacing': _double,
  'borderAlign': _arcBorderAlign,
  'spacingMode': _arcSpacingMode,
  'borderDash': _doubles,
  'borderDashOffset': _double,
  'borderJoinStyle': _strokeJoin,
  'selfJoin': _bool,
  'circular': _bool,
  'angle': _double,
};

String? _arcBorderAlign(
  FixtureEmitter e,
  FixtureValue v,
  String k,
  String? o,
) => _enum('ArcBorderAlign')(e, v, k, o);

String? _arcSpacingMode(
  FixtureEmitter e,
  FixtureValue v,
  String k,
  String? o,
) => _enum('ArcSpacingMode')(e, v, k, o);

// ---------------------------------------------------------------------------
// The axes.

/// The axes of `options.scales` of a config.
final class _Scales(
  final FixtureEmitter emitter,
  final String chartType,
  final String indexAxis,
  FixtureValue? scales,
) {
  this {
    if (scales is FixtureMap) _read(scales);
  }

  /// The source of the typed `scales` List, or Dart `null` when the axes go
  /// to `extra`.
  String? typedSource;

  /// The variable of each typed axis that a dataset names, by scale id.
  final Map<String, String> _variables = {};

  /// The typed axis source by scale id.
  final Map<String, String> _axes = {};

  void _read(FixtureMap scales) {
    final extras = emitter.extras.length;
    if (!_readTyped(scales)) {
      // The axes go to `extra`: drop the extra entries of the typed try.
      emitter.extras.removeRange(extras, emitter.extras.length);
      _axes.clear();
    }
  }

  /// Reads [scales] as typed axes. Returns `false` when they go to `extra`.
  bool _readTyped(FixtureMap scales) {
    final counts = <String, int>{};
    final sources = <String>[];
    for (final entry in scales.entries) {
      final id = entry.key;
      final conf = entry.value;
      if (conf is! FixtureMap) return false;
      final letter = _letterOf(id, conf);
      if (letter == null) return false;
      final n = counts[letter] ?? 0;
      counts[letter] = n + 1;
      final typedId = n == 0 ? letter : '$letter$n';
      if (typedId != id) return false;
      final source = _axis(letter, conf);
      // The typed axes are distinct by `==` (Chart.js ADR 0191).
      if (source == null || _axes.containsValue(source)) return false;
      _axes[id] = source;
      sources.add('${_commentLines(entry.comments)}$source');
    }
    typedSource = '[${sources.map(_comma).join()}]';
    return true;
  }

  /// The variable of the typed axis [id] for an axis field of a dataset, or
  /// Dart `null` when the axes are not typed or have no such id.
  String? variableOf(String id) {
    if (typedSource == null) return null;
    final axis = _axes[id];
    if (axis == null) return null;
    final name = _variables[id] ??= '${id}Axis';
    if (!emitter.declarations.any((d) => d.startsWith('final $name '))) {
      emitter.declarations.add('final $name = $axis;');
      typedSource = typedSource!.replaceFirst(axis, name);
    }
    return name;
  }

  /// The axis letter of the scale [id] (`determineAxis` of core.config.js).
  String? _letterOf(String id, FixtureMap conf) {
    if (id == 'x' || id == 'y' || id == 'r') return id;
    final axis = _axisLetter(conf['axis']);
    if (axis != null) return axis;
    final position = conf['position'];
    if (position is FixtureString) {
      switch (position.value) {
        case 'top' || 'bottom':
          return 'x';
        case 'left' || 'right':
          return 'y';
      }
    }
    if (position is FixtureCode) {
      if (position.source.endsWith('.top') ||
          position.source.endsWith('.bottom')) {
        return 'x';
      }
      if (position.source.endsWith('.left') ||
          position.source.endsWith('.right')) {
        return 'y';
      }
    }
    final first = id[0].toLowerCase();
    return const {'x', 'y', 'r'}.contains(first) && id.length > 1
        ? first
        : null;
  }

  /// The scale type of the axis [letter] when the config gives none: the
  /// default scales of the chart type.
  String? _defaultType(String letter) => switch (chartType) {
    'bar' || 'line' =>
      letter == 'r' ? null : (letter == indexAxis ? 'category' : 'linear'),
    'scatter' || 'bubble' => letter == 'r' ? null : 'linear',
    'radar' || 'polarArea' => letter == 'r' ? 'radialLinear' : null,
    _ => null,
  };

  /// The source of the typed axis of [conf], or Dart `null`.
  String? _axis(String letter, FixtureMap conf) {
    final typeValue = conf['type'];
    final type = switch (typeValue) {
      FixtureString(value: final s) => s,
      null => _defaultType(letter),
      _ => null,
    };
    if (type == null) return null;
    final className = _axisClasses[type];
    if (className == null) return null;
    if ((type == 'radialLinear') != (letter == 'r')) return null;
    final fields = <String, _Convert>{
      'display': _display,
      'position': _position,
      'reverse': _bool,
      'stacked': _stacked,
      'ticks': _ticks,
      'grid': _grid,
      'title': _title,
      'border': _object,
      'bounds': _enum('ScaleBounds'),
      'alignToPixels': _bool,
      'backgroundColor': _paint,
      'clip': _bool,
      'weight': _double,
      for (final hook in _scaleHooks) hook: _function,
      if (type != 'radialLinear') ...{
        'offset': _bool,
        'stack': _string,
        'stackWeight': _double,
      },
      if (type == 'linear' || type == 'radialLinear') 'grace': _grace,
      ...switch (type) {
        'category' => {'labels': _labels, 'min': _string, 'max': _string},
        'linear' => {
          'min': _double,
          'max': _double,
          'suggestedMin': _double,
          'suggestedMax': _double,
          'beginAtZero': _bool,
        },
        'logarithmic' => {
          'min': _double,
          'max': _double,
          'suggestedMin': _double,
          'suggestedMax': _double,
        },
        'time' || 'timeseries' => {'min': _code, 'max': _code, 'time': _time},
        'radialLinear' => {
          'min': _double,
          'max': _double,
          'suggestedMin': _double,
          'suggestedMax': _double,
          'beginAtZero': _bool,
          'startAngle': _double,
          'pointLabels': _pointLabels,
          'angleLines': _angleLines,
        },
        _ => {},
      },
    };
    final args = <String>[if (type != 'radialLinear') 'CartesianAxis.$letter'];
    final extra = <String>[];
    for (final entry in conf.entries) {
      final key = entry.key;
      final c = _commentLines(entry.comments);
      if (key == 'type') continue;
      if (key == 'axis' && _axisLetter(conf['axis']) == letter) continue;
      final typed = fields[key]?.call(emitter, entry.value, key, 'scales');
      if (typed != null) {
        if (typed.startsWith('\u0000')) {
          // A group that spreads into several parameters.
          args.add(typed.substring(1));
        } else {
          args.add('$c$key: $typed');
        }
      } else {
        extra.add(
          '$c${dartString(key)}: '
          '${emitter.nativeValue(key, entry.value, owner: 'id', grand: 'scales')}',
        );
        emitter.extras.add('$className.extra[$key]');
      }
    }
    if (extra.isNotEmpty) {
      args.add('extra: <String, Object?>{${extra.map(_comma).join()}}');
    }
    return '$className(${args.map(_comma).join()})';
  }
}

const Map<String, String> _axisClasses = {
  'category': 'CategoryAxis',
  'linear': 'LinearAxis',
  'logarithmic': 'LogarithmicAxis',
  'time': 'TimeAxis',
  'timeseries': 'TimeSeriesAxis',
  'radialLinear': 'RadialLinearAxis',
};

String? _display(FixtureEmitter e, FixtureValue v, String k, String? o) =>
    e._scaleDisplay(v);

String? _stacked(FixtureEmitter e, FixtureValue v, String k, String? o) =>
    e._stackMode(v);

String? _position(FixtureEmitter e, FixtureValue v, String k, String? o) =>
    switch (v) {
      FixtureString(value: final s) => enumExpression('ChartPosition', s),
      FixtureCode(:final source) when source.startsWith('ChartPosition.') =>
        source,
      _ => null,
    };

String? _labels(FixtureEmitter e, FixtureValue v, String k, String? o) =>
    v is FixtureList &&
        v.items.every(
          (i) =>
              (i is FixtureString || i is FixtureNumber) && i.comments.isEmpty,
        )
    ? '<Object>[${_items(v.items.map(literalOf))}]'
    : null;

String? _text(FixtureEmitter e, FixtureValue v, String k, String? o) =>
    switch (v) {
      FixtureString(value: final s) => '<String>[${dartString(s)}]',
      FixtureList(:final items)
          when items.every((i) => i is FixtureString && i.comments.isEmpty) =>
        '<String>[${_items(items.map(literalOf))}]',
      _ => null,
    };

String? _ticks(FixtureEmitter e, FixtureValue v, String k, String? o) =>
    v is FixtureMap
    ? e._group(
        'AxisTicks',
        v,
        {
          'display': _bool,
          'color': _paint,
          'font': _object,
          'padding': _double,
          'stepSize': _double,
          'maxRotation': _double,
          'autoSkip': _bool,
          'align': _enum('TickAlign'),
          'crossAlign': _enum('TickCrossAlign'),
          'source': _enum('TickSource'),
          'callback': _function,
          'backdropColor': _paint,
          'backdropPadding': _object,
          'showLabelBackdrop': _bool,
          'textStrokeColor': _paint,
          'textStrokeWidth': _double,
          'z': _double,
          'sampleSize': _double,
          'autoSkipPadding': _double,
          'includeBounds': _bool,
          'labelOffset': _double,
          'minRotation': _double,
          'mirror': _bool,
          'maxTicksLimit': _double,
          'format': _object,
          'precision': _double,
          'count': _double,
        },
        key: 'ticks',
        owner: 'id',
      )
    : null;

String? _grid(FixtureEmitter e, FixtureValue v, String k, String? o) =>
    v is FixtureMap
    ? e._group(
        'AxisGrid',
        v,
        {
          'display': _bool,
          'color': _paint,
          'lineWidth': _double,
          'drawOnChartArea': _bool,
          'drawTicks': _bool,
          'offset': _bool,
          'tickLength': _double,
          'circular': _bool,
          'tickBorderDash': _doubles,
          'tickBorderDashOffset': _double,
          'tickColor': _paint,
          'tickWidth': _double,
          'z': _double,
        },
        key: 'grid',
        owner: 'id',
      )
    : null;

String? _title(FixtureEmitter e, FixtureValue v, String k, String? o) =>
    v is FixtureMap
    ? e._group(
        'AxisTitle',
        v,
        {
          'display': _bool,
          'text': _text,
          'color': _paint,
          'font': _object,
          'align': _enum('ChartAlign'),
          'padding': _object,
          'strokeColor': _paint,
          'strokeWidth': _double,
        },
        key: 'title',
        owner: 'id',
      )
    : null;

/// The 14 scale hooks of Chart.js ADR 0130 (`ScaleHook`).
const List<String> _scaleHooks = [
  'beforeUpdate',
  'beforeSetDimensions',
  'afterSetDimensions',
  'beforeDataLimits',
  'afterDataLimits',
  'beforeBuildTicks',
  'afterBuildTicks',
  'beforeTickToLabelConversion',
  'afterTickToLabelConversion',
  'beforeCalculateLabelRotation',
  'afterCalculateLabelRotation',
  'beforeFit',
  'afterFit',
  'afterUpdate',
];

/// A `GraceLength`: a number is a `ValueGrace`, a percent text a
/// `PercentGrace` (row `adapt-length-objects`).
String? _grace(FixtureEmitter e, FixtureValue v, String k, String? o) =>
    switch (v) {
      FixtureNumber(:final text) => 'ValueGrace($text)',
      FixtureString(value: final s) when RegExp(r'^-?[0-9.]+%$').hasMatch(s) =>
        'PercentGrace(${s.substring(0, s.length - 1)})',
      FixtureCode(:final source)
          when !v.isFunction && source.contains('Grace(') =>
        source,
      _ => null,
    };

/// The `time` options of a time axis: typed parameters of the axis when
/// each key has one, else Dart `null` (the object goes to `extra`).
String? _time(FixtureEmitter e, FixtureValue v, String k, String? o) {
  if (v is! FixtureMap) return null;
  final args = <String>[];
  for (final entry in v.entries) {
    if (entry.comments.isNotEmpty) return null;
    final value = entry.value;
    switch (entry.key) {
      case 'unit':
        final unit = _enum('TimeUnit')(e, value, 'unit', 'time');
        if (unit == null) return null;
        args.add('unit: $unit');
      case 'tooltipFormat' when value is FixtureString:
        args.add('tooltipFormat: ${literalOf(value)}');
      case 'parser' when value is FixtureString:
        args.add('parser: ${literalOf(value)}');
      case 'parser' when value is FixtureCode && value.isFunction:
        args.add('parserFunction: ${value.source}');
      case 'round' || 'minUnit':
        final unit = _enum('TimeUnit')(e, value, entry.key, 'time');
        if (unit == null) return null;
        args.add('${entry.key}: $unit');
      case 'isoWeekday' when value is FixtureBool && value.value:
        args.add('isoWeekday: 1');
      case 'isoWeekday'
          when value is FixtureNumber && value.value == value.value.toInt():
        args.add('isoWeekday: ${value.value.toInt()}');
      default:
        return null;
    }
  }
  return '\u0000${args.join(', ')}';
}

/// The `pointLabels` of a radial axis: typed parameters when each key has
/// one, else Dart `null`.
String? _pointLabels(FixtureEmitter e, FixtureValue v, String k, String? o) {
  if (v is! FixtureMap) return null;
  final args = <String>[];
  for (final entry in v.entries) {
    if (entry.comments.isNotEmpty) return null;
    final value = entry.value;
    final typed = switch (entry.key) {
      'display' => e._scaleDisplay(value),
      'color' => _paint(e, value, 'color', 'pointLabels'),
      'font' => _object(e, value, 'font', 'pointLabels'),
      'padding' => _double(e, value, 'padding', 'pointLabels'),
      'callback' => _function(e, value, 'callback', 'pointLabels'),
      _ => null,
    };
    if (typed == null) return null;
    final name = entry.key[0].toUpperCase() + entry.key.substring(1);
    args.add('pointLabels$name: $typed');
  }
  return '\u0000${args.join(', ')}';
}

/// The `angleLines` of a radial axis: typed parameters when each key has
/// one, else Dart `null`.
String? _angleLines(FixtureEmitter e, FixtureValue v, String k, String? o) {
  if (v is! FixtureMap) return null;
  final args = <String>[];
  for (final entry in v.entries) {
    if (entry.comments.isNotEmpty) return null;
    final value = entry.value;
    final typed = switch (entry.key) {
      'display' => _bool(e, value, 'display', 'angleLines'),
      'color' => _paint(e, value, 'color', 'angleLines'),
      'lineWidth' => _double(e, value, 'lineWidth', 'angleLines'),
      _ => null,
    };
    if (typed == null) return null;
    final name = entry.key[0].toUpperCase() + entry.key.substring(1);
    args.add('angleLines$name: $typed');
  }
  return '\u0000${args.join(', ')}';
}

/// The JSON of [value] for a doc comment.
String jsonOf(Object? value) => const JsonEncoder().convert(value);

/// [items] with a comma after each one: the arguments of a call or the
/// items of a literal.
String _items(Iterable<String> items) => items.map(_comma).join();

String _comma(String item) => '$item,\n';

/// The entry [entry] of an object literal with the value source [value].
String _entryOf(FixtureEntry entry, String value) =>
    '${_commentLines(entry.comments)}${dartString(entry.key)}: $value';

/// The letter of the scale option `axis`: a text or an axis object of the
/// port (`const XAxis()`), or Dart `null`.
String? _axisLetter(FixtureValue? axis) => switch (axis) {
  FixtureString(value: final s) => s,
  FixtureCode(:final source) when source.contains('XAxis') => 'x',
  FixtureCode(:final source) when source.contains('YAxis') => 'y',
  _ => null,
};
