// Original code, not ported from Chart.js: the observation oracle O1 (Chart.js ADR 0054).
// The header text names the test and the ADR, and has no URI.
// ignore_for_file: lines_longer_than_80_chars
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:chartjs_test_utils/flutter.dart';
import 'package:clock/clock.dart';
import 'package:flutter_chartjs_port/src/core/core.animation.dart';
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/core.defaults.dart' show defaults;
import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.easing.dart'
    show effects;
import 'package:flutter_chartjs_port/src/js/js_array.dart'
    show JsProxyObject, jsObjectKeys;
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_function.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/platform/native_event.dart';
import 'package:flutter_chartjs_port/src/platform/platform.flutter.dart'
    show fromNativeEvent;
import 'package:flutter_chartjs_port/src/types/animation.dart' as types;
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/index.dart' show handFixtures;
import '../core/resolver_trace_cases.dart'
    show resolverTraceFunctions, resolverTraceSetups;
import '../core/resolver_trace_reference.dart' show resolverTraceReference;
import '../scales/scale_chart_harness.dart' show copyReference, drawCalls;
import 'observation_digests.dart';

// The observation oracle O1 of Chart.js ADR 0054: it pins the JS-observable
// behavior of the option model as one SHA-256 digest for each run of a
// config. A later change of the Dart representation of the options (typed
// classes in place of Maps, `double` in place of `int`) keeps each digest.
// Thus the canonical text has only JS-observable facts: a number is its JS
// string, a Map is its keys and values in the order of `Object.keys`, and no
// line names the Dart class of an options object.
//
// The corpus: the hand fixtures of test/fixtures/index.dart, the pure data
// configs of doc/upstream/fixtures.json, the bench and focused configs of the
// differential test D1 and the cases of the resolver trace D2
// (test/port/core/resolver_trace_reference.dart). Each case has two tests:
// `(plain)` runs the config as given, and `(trace)` wraps each function value
// of the config in a recorder and adds the ordered user calls to the text.
// The defaults restore of the harness runs between the two tests.
//
// Run it alone:
//   flutter test test/port/options/observation_test.dart
// Write the digests again (macOS only):
//   O1_UPDATE=1 flutter test test/port/options/observation_test.dart
// Write the texts into a folder (one file for each test):
//   O1_DUMP=<folder> flutter test test/port/options/observation_test.dart
// Write the texts of a base commit and of the current tree, and list the
// files that differ:
//   tool/observation_diff.sh <base commit>
//
// The digests are the digests of the macOS VM: the transcendental functions
// and the text metrics can differ in the last bits on another OS. Thus the
// tests compare the digests only on macOS. On another OS, each test still
// runs its case, so a throw of the observation code fails there too.

/// The fixed `Date.now()` of each run: the `start` of each animation is
/// `Date.now() + delay` (core.animation.js:37).
final DateTime _now = DateTime.utc(2026, 10, 31);

/// Whether the run writes observation_digests.dart (`O1_UPDATE=1`).
final bool _update = Platform.environment['O1_UPDATE'] == '1';

/// The folder of the environment variable `O1_DUMP`: when it is set, each
/// test writes its text there.
final String? _dumpFolder = Platform.environment['O1_DUMP'];

/// The path of the digests, relative to the package root (the working
/// directory of `flutter test`).
const String _digestsPath = 'test/port/options/observation_digests.dart';

/// The digests of the tests of this run, for [_update].
final Map<String, String> _collected = {};

/// The input of one run: the config and the options of `acquireChart`.
typedef _Input = ({Map<String, Object?> config, Map<String, Object?>? options});

/// One config of the corpus: `make` gives a new config and the options of
/// `acquireChart` at each call. `cleanup` undoes a change of the global
/// scopes after a run.
typedef _Case = ({
  String name,
  _Input Function() make,
  void Function()? cleanup,
});

void main() {
  final cases = _cases();
  final names = <String>[];
  final stems = <String>{};
  for (final c in cases) {
    for (final kind in const ['plain', 'trace']) {
      final name = '${c.name} ($kind)';
      // The dump file of a test is its sanitized name: two tests must not
      // share it. This also makes the case names unique.
      if (!stems.add(_stem(name))) {
        throw StateError('Two tests share the dump file name of $name.');
      }
      names.add(name);
    }
  }

  for (final c in cases) {
    for (final wrap in const [false, true]) {
      final name = '${c.name} (${wrap ? 'trace' : 'plain'})';
      testWidgets(name, (tester) async {
        final text = _run(c, wrap: wrap);
        // The animator of an animated case asked for a frame. The charts are
        // released, so the frame runs no chart.
        await tester.pump();
        _dump(name, text);
        _check(name, text);
      });
    }
  }

  if (_update) {
    tearDownAll(() {
      if (!Platform.isMacOS) return;
      // A run of a part of the tests keeps the stored digests of the other
      // tests. A name that is not a test of this file goes.
      File(_digestsPath).writeAsStringSync(
        _digestsSource({
          for (final name in names)
            name: ?(_collected[name] ?? observationDigests[name]),
        }),
      );
    });
  }
}

// ---------------------------------------------------------------------------
// The corpus.

/// The cases of the oracle, in the order of their tests.
List<_Case> _cases() => [
  for (final MapEntry(key: path, value: hand) in handFixtures.entries)
    (
      name: 'fixture $path',
      make: () => _fixtureInput(path, hand.load()),
      cleanup: null,
    ),
  for (final path in _dataFixtures.keys)
    (
      name: 'fixture $path',
      make: () => _fixtureInput(
        path,
        _copyJson(_dataFixtures[path])! as Map<String, Object?>,
      ),
      cleanup: null,
    ),
  for (final c in _benchCases)
    (name: 'bench ${c.name}', make: c.make, cleanup: c.cleanup),
  for (final c in _focusedCases)
    (name: 'focused ${c.name}', make: c.make, cleanup: c.cleanup),
  for (final c in resolverTraceReference)
    (
      name: 'trace ${c.name}',
      make: () {
        // The functions record into a list that no one reads: the recorder
        // of a trace run records the calls.
        final functions = resolverTraceFunctions(<Object?>[]);
        if (c.setup case final setup?) resolverTraceSetups[setup]!(functions);
        return (
          config: copyReference(c.config, functions)! as Map<String, Object?>,
          options: null,
        );
      },
      cleanup: null,
    ),
];

/// The pure data configs of doc/upstream/fixtures.json, by fixture path,
/// decoded once. A run takes a deep copy ([_copyJson]): the chart writes
/// into its config.
final Map<String, Object?> _dataFixtures =
    jsonDecode(File('doc/upstream/fixtures.json').readAsStringSync())!
        as Map<String, Object?>;

/// A deep copy of the decoded JSON [value].
Object? _copyJson(Object? value) => switch (value) {
  final Map<String, Object?> map => <String, Object?>{
    for (final MapEntry(:key, :value) in map.entries) key: _copyJson(value),
  },
  final List<Object?> list => <Object?>[
    for (final item in list) _copyJson(item),
  ],
  _ => value,
};

/// The input of the fixture [path] from its loaded [json] `{config,
/// options}`: the `options` default and the plugin rule of specFromFixture
/// (fixture.js:43-48).
_Input _fixtureInput(String path, Map<String, Object?> json) {
  final config = json['config']! as Map<String, Object?>;
  final options =
      (jsTruthy(config['options'])
              ? config['options']
              : (config['options'] = <String, Object?>{}))!
          as Map<String, Object?>;
  // plugins are disabled by default, except if the path contains 'plugin'
  // or there are instance plugins
  if (!path.contains('plugin') &&
      identical(jsGet(config, 'plugins'), undefined)) {
    options['plugins'] = jsTruthy(options['plugins'])
        ? options['plugins']
        : false;
  }
  return (config: config, options: json['options'] as Map<String, Object?>?);
}

// ---------------------------------------------------------------------------
// The digests.

/// The name of the dump file of the test [name], without `.txt`.
String _stem(String name) => name.replaceAll(RegExp('[^A-Za-z0-9.]+'), '_');

/// Writes [text] into [_dumpFolder].
void _dump(String name, String text) {
  final folder = _dumpFolder;
  if (folder == null) return;
  File('$folder/${_stem(name)}.txt')
    ..createSync(recursive: true)
    ..writeAsStringSync(text);
}

/// Compares the digest of [text] with the stored digest of the test [name],
/// or collects it for [_update].
void _check(String name, String text) {
  final digest = sha256Hex(utf8.encode(text));
  if (_update) {
    if (!Platform.isMacOS) {
      fail('O1_UPDATE=1 writes the digests of the macOS VM: run it on macOS.');
    }
    _collected[name] = digest;
    return;
  }
  final stored = observationDigests[name];
  if (stored == null) {
    fail(
      '$name: $_digestsPath has no digest of this test. Run O1_UPDATE=1 '
      'flutter test test/port/options/observation_test.dart on macOS.',
    );
  }
  if (Platform.isMacOS && stored != digest) {
    fail(
      '$name: the observations changed (digest $digest, stored $stored). '
      'Run tool/observation_diff.sh <base commit> to write the texts of both '
      'trees.',
    );
  }
}

/// The source of observation_digests.dart with [digests], sorted by name,
/// in the form of `dart format`.
String _digestsSource(Map<String, String> digests) {
  final out = StringBuffer()
    ..writeln(
      '// Original code, not ported from Chart.js: the digests of the '
      'observation oracle O1.',
    )
    ..writeln(
      '// Generated by test/port/options/observation_test.dart with '
      'O1_UPDATE=1. Do not edit.',
    )
    ..writeln('// ignore_for_file: lines_longer_than_80_chars')
    ..writeln()
    ..writeln(
      '/// The SHA-256 of the canonical text of each test of the observation '
      'oracle',
    )
    ..writeln('/// O1, by test name, on the macOS VM.');
  if (digests.isEmpty) {
    out.writeln('const Map<String, String> observationDigests = {};');
    return out.toString();
  }
  out.writeln('const Map<String, String> observationDigests = {');
  for (final name in digests.keys.toList()..sort()) {
    out
      ..writeln('  ${_dartString(name)}:')
      ..writeln("      '${digests[name]}',");
  }
  out.writeln('};');
  return out.toString();
}

/// [s] as a single-quoted Dart string literal.
String _dartString(String s) {
  final escaped = s
      .replaceAll(r'\', r'\\')
      .replaceAll(r'$', r'\$')
      .replaceAll("'", r"\'");
  return "'$escaped'";
}

// ---------------------------------------------------------------------------
// The run of one case.

/// One run of [c]: the canonical text of the observations after the
/// construction and after each step, then, with [wrap], the user-call trace.
String _run(_Case c, {required bool wrap}) {
  final out = StringBuffer();
  final trace = <String>[];
  final input = c.make();
  if (wrap) _wrapFunctions(input.config, 'config', trace);
  try {
    withClock(Clock.fixed(_now), () {
      trace.add('== construct');
      final Chart chart;
      try {
        chart = acquireChart(input.config, input.options);
      } on Object catch (e) {
        out.writeln('construct throws ${_throwText(e)}');
        return;
      }
      try {
        trace.add('== observe construct');
        _observe(chart, 'construct', out, draw: true);
        for (final (name, step, draw) in _steps) {
          trace.add('== $name');
          try {
            step(chart);
          } on Object catch (e) {
            out.writeln('$name throws ${_throwText(e)}');
          }
          trace.add('== observe $name');
          _observe(chart, name, out, draw: draw);
        }
      } finally {
        releaseChart(chart);
      }
    });
  } finally {
    c.cleanup?.call();
  }
  if (wrap) {
    final calls = trace.where((line) => !line.startsWith('== ')).length;
    out.writeln('trace ($calls calls):');
    trace.forEach(out.writeln);
  }
  return out.toString();
}

/// The steps after the construction: the name, the call, and whether the
/// observation records the draw calls.
final List<(String, void Function(Chart chart), bool)> _steps = [
  ('update', (chart) => chart.update(), false),
  ('update none', (chart) => chart.update('none'), true),
  ('hover', _hover, true),
  ('mouseout', (chart) => _event(chart, 'mouseout', -1, 0), false),
  ('reset', (chart) => chart.reset(), false),
  ('hide 0', (chart) => chart.hide(0), false),
  ('show 0', (chart) => chart.show(0), false),
  ('update again', (chart) => chart.update(), false),
];

/// An event of [type] at ([x], [y]), handled at once: no frame pumps while
/// the chart lives (the event path of `_benchEvent` of the gallery
/// benchmark).
void _event(Chart chart, String type, double x, double y) {
  final event = NativeEvent(
    type: type,
    offsetX: x,
    offsetY: y,
    target: chart.canvas,
  );
  // The handler of the chart, as the throttled platform listener calls it.
  chart.eventHandler(fromNativeEvent(event, chart));
}

/// A `mousemove` at the tooltip position of the first data element of the
/// first visible dataset, else at the center of the chart area.
void _hover(Chart chart) {
  final datasets = jsGet(chart.data, 'datasets');
  final count = datasets is List<Object?> ? datasets.length : 0;
  for (var i = 0; i < count; i++) {
    if (!chart.isDatasetVisible(i)) continue;
    final data = chart.getDatasetMeta(i).data;
    if (data.isEmpty) continue;
    final point = (data.first as Element).tooltipPosition(false);
    if (point.x.isFinite && point.y.isFinite) {
      _event(chart, 'mousemove', point.x, point.y);
      return;
    }
  }
  final area = chart.chartArea;
  if (area == null) {
    throw StateError('no chart area');
  }
  _event(
    chart,
    'mousemove',
    (area.left + area.right) / 2,
    (area.top + area.bottom) / 2,
  );
}

// ---------------------------------------------------------------------------
// The observations.

/// The properties that the observation reads by name from each element.
const List<String> _properties = [
  'x',
  'y',
  'skip',
  'stop',
  'parsed',
  'raw',
  'angle',
  'base',
  'horizontal',
  'width',
  'height',
  'inflateAmount',
  'startAngle',
  'endAngle',
  'innerRadius',
  'outerRadius',
  'circumference',
  'fullCircles',
  'pixelMargin',
  'active',
  'hidden',
];

/// The names of the `getProps(names, true)` read of each element.
const List<String> _propNames = [
  'x',
  'y',
  'base',
  'width',
  'height',
  'startAngle',
  'endAngle',
  'innerRadius',
  'outerRadius',
  'circumference',
];

/// The keys of a context that the observation and the trace read.
const List<String> _contextKeys = [
  'type',
  'index',
  'dataIndex',
  'datasetIndex',
  'mode',
  'active',
];

/// Writes the observation of [chart] after the step [step] into [out].
void _observe(
  Chart chart,
  String step,
  StringBuffer out, {
  required bool draw,
}) {
  out.writeln('== $step');
  final datasets = jsGet(chart.data, 'datasets');
  final count = datasets is List<Object?> ? datasets.length : 0;
  for (var i = 0; i < count; i++) {
    final meta = chart.getDatasetMeta(i);
    out.writeln(
      'dataset $i type ${_canon(meta['type'])} visible '
      '${chart.isDatasetVisible(i)}',
    );
    final dataset = meta.dataset;
    if (dataset != null) {
      _observeElement('  dataset element', dataset, out);
    }
    for (var k = 0; k < meta.data.length; k++) {
      _observeElement('  data $k', meta.data[k], out);
      if (k > 0) {
        // JS `===` of the options of two neighbor elements: the shared
        // options of core.datasetController.js:804-831 and :885-891.
        final previous = meta.data[k - 1] as types.ElementPropertyRead;
        final current = meta.data[k] as types.ElementPropertyRead;
        out.writeln(
          '    same-options-as-previous '
          '${identical(current['options'], previous['options'])}',
        );
      }
    }
    if (meta.controller case final controller?) {
      if (meta.data.isNotEmpty) {
        out.writeln(
          '  resolveDataElementOptions(0, active) '
          '${_guarded(() => _canon(controller.resolveDataElementOptions(0, 'active')))}',
        );
      }
      if (dataset != null) {
        out.writeln(
          '  resolveDatasetElementOptions(active) '
          '${_guarded(() => _canon(controller.resolveDatasetElementOptions('active')))}',
        );
      }
    }
  }
  out.writeln(
    'active ${_canon([
      for (final a in chart.getActiveElements()) [a.datasetIndex, a.index],
    ])}',
  );
  if (draw) {
    out.writeln('draw');
    try {
      for (final call in drawCalls(chart)) {
        out.writeln('  ${_canon(call, 0, 12)}');
      }
    } on Object catch (e) {
      out.writeln('  <throws ${_throwText(e)}>');
    }
  }
}

/// Writes the observation of one element.
void _observeElement(String label, types.Element element, StringBuffer out) {
  out.writeln('$label ${element.runtimeType}');
  final read = element as types.ElementPropertyRead;
  final options = read['options'];
  out
    ..writeln('    options ${_guarded(() => _canon(options))}')
    ..writeln(
      '    \$shared ${_guarded(() => _canon(options is Map<String, Object?> ? jsGet(options, r'$shared') : undefined))}',
    );
  for (final name in _properties) {
    out.writeln('    $name ${_guarded(() => _canon(read[name]))}');
  }
  out.writeln('    getProps ${_guarded(() => _props(element))}');
  final context = read[r'$context'];
  if (context is Map<String, Object?>) {
    out.writeln(
      '    \$context keys ${_canon(jsObjectKeys(context))} '
      '${[for (final key in _contextKeys) '$key=${_guarded(() => _canon(jsGet(context, key), 0, 1))}'].join(' ')}',
    );
  } else {
    out.writeln('    \$context ${_canon(context)}');
  }
  final animations = read[r'$animations'];
  if (animations is Map<String, types.Animation>) {
    final keys = jsObjectKeys(animations);
    out.writeln('    \$animations ${_canon(keys)}');
    for (final key in keys) {
      final animation = animations[key]! as Animation;
      final easing = effects.entries
          .where((e) => identical(e.value, animation.easing))
          .map((e) => e.key)
          .firstOrNull;
      out.writeln(
        '      $key from ${_canon(animation.from)} to ${_canon(animation.to)} '
        'duration ${_canon(animation.duration)} start ${_canon(animation.start)} '
        'loop ${animation.loop} easing ${easing ?? '<other>'} '
        'active ${animation.active()}',
      );
    }
  } else {
    out.writeln('    \$animations ${_canon(animations)}');
  }
}

/// The text of `element.getProps(_propNames, true)`: `self` when the result
/// is the element (core.element.ts:35-37), else `object`, then the value of
/// each name.
String _props(types.Element element) {
  final props = (element as Element).getProps(_propNames, true);
  final kind = identical(props, element) ? 'self' : 'object';
  return '$kind {${[for (final name in _propNames) '${jsonEncode(name)}: ${_guarded(() => _canon(props[name]))}'].join(', ')}}';
}

/// [text], or the throw of [text] as a line.
String _guarded(String Function() text) {
  try {
    return text();
  } on Object catch (e) {
    return '<throws ${_throwText(e)}>';
  }
}

/// The JS kind of the throw [e]: a Dart [TypeError] or [NoSuchMethodError]
/// is a JS `TypeError`, a [StateError] is a JS `Error` with its message, and
/// a [RangeError] is a JS `RangeError`. Another throw gives its Dart class.
/// No line has the message of a [TypeError], which names Dart classes.
String _throwText(Object e) => switch (e) {
  TypeError() || NoSuchMethodError() => 'TypeError',
  StateError(:final message) => 'Error ${jsonEncode(message)}',
  RangeError() => 'RangeError',
  _ => '${e.runtimeType}',
};

/// The canonical text of [value]: JS kinds only, never the Dart class of an
/// object.
///
/// - `undefined`, `null`, `true` and `false`; a number is its JS string
///   `String(n)` ([jsNumberToString]), so 3 and 3.0 give one text; a string
///   is its JSON text. -0 gives `0`, as `String(-0)` does. On the Map
///   model, a negative zero reaches only the canvas arguments of
///   `translate` and `fillText`. The negation of a `double` option 0 gives
///   -0 where an `int` option 0 gave 0 (JavaScript gives -0 too). A sign
///   of zero that reaches a division or `atan2` changes other values of the
///   text.
/// - A function is `<fn>`, a class value is `<class Name>`, a `DateTime` is
///   `Date(<time value>)` and an element is `<element Class>`.
/// - A List is `[a, b]`. A `Map<String, Object?>` is `{"k": v}` with the
///   keys of `Object.keys` ([jsObjectKeys]) and the values of the JS
///   property read ([jsGet]). Another Map is `{k: v}` over its entries.
/// - Another object is `<object>`. A List or a Map deeper than [maxDepth]
///   is `<list>`, `<object>` or `<map>`.
String _canon(Object? value, [int depth = 0, int maxDepth = 4]) {
  if (identical(value, undefined)) return 'undefined';
  switch (value) {
    case null:
      return 'null';
    case final bool b:
      return '$b';
    case final num n:
      return jsNumberToString(n);
    case final String s:
      return jsonEncode(s);
    case Function() || JsFunction():
      return '<fn>';
    case final JsClass c:
      return '<class ${c.name}>';
    case final DateTime d:
      return 'Date(${d.millisecondsSinceEpoch})';
    case final types.Element e:
      return '<element ${e.runtimeType}>';
  }
  if (depth >= maxDepth) {
    return switch (value) {
      List<Object?>() => '<list>',
      Map<String, Object?>() => '<object>',
      Map<Object?, Object?>() => '<map>',
      _ => '<object>',
    };
  }
  switch (value) {
    case final List<Object?> list:
      return '[${[for (final item in list) _canon(item, depth + 1, maxDepth)].join(', ')}]';
    case final Map<String, Object?> map:
      return '{${[for (final key in jsObjectKeys(map)) '${jsonEncode(key)}: ${_guarded(() => _canon(jsGet(map, key), depth + 1, maxDepth))}'].join(', ')}}';
    case final Map<Object?, Object?> map:
      return '{${[for (final MapEntry(:key, :value) in map.entries) '${_canon(key, depth + 1, maxDepth)}: ${_canon(value, depth + 1, maxDepth)}'].join(', ')}}';
  }
  return '<object>';
}

// ---------------------------------------------------------------------------
// The user-call trace.

/// Whether [function] takes [count] positional arguments and no named
/// argument: the test of `_takes` of js_function.dart.
bool _takes(Function function, int count) => switch (count) {
  0 => function is Object? Function(),
  1 => function is Object? Function(Never),
  2 => function is Object? Function(Never, Never),
  3 => function is Object? Function(Never, Never, Never),
  4 => function is Object? Function(Never, Never, Never, Never),
  5 => function is Object? Function(Never, Never, Never, Never, Never),
  _ => false,
};

/// The count k when [function] takes exactly k positional arguments (k
/// required and k in all, 0 to 4), else Dart `null`.
int? _exactArity(Function function) {
  for (var k = 0; k <= 4; k++) {
    if (_takes(function, k)) return _takes(function, k + 1) ? null : k;
  }
  return null;
}

/// Replaces each function value under [value] with a recorder that writes
/// one line into [trace] and calls the function. A closure with a range of
/// argument counts stays as it is.
void _wrapFunctions(Object? value, String path, List<String> trace) {
  switch (value) {
    case final Map<String, Object?> map:
      for (final key in List.of(map.keys)) {
        final wrapped = _wrapped(map[key], '$path.$key', trace);
        if (wrapped != null) {
          map[key] = wrapped;
        } else {
          _wrapFunctions(map[key], '$path.$key', trace);
        }
      }
    case final List<Object?> list:
      for (var i = 0; i < list.length; i++) {
        final wrapped = _wrapped(list[i], '$path[$i]', trace);
        if (wrapped != null) {
          list[i] = wrapped;
        } else {
          _wrapFunctions(list[i], '$path[$i]', trace);
        }
      }
  }
}

/// The recorder of [value] when it is a function with an exact arity, else
/// Dart `null`.
Object? _wrapped(Object? value, String path, List<String> trace) {
  switch (value) {
    case final JsFunction f:
      final k = _exactArity(f.function);
      if (k == null || k == 0) return null;
      return JsFunction(_recorder(f.function, k, path, trace, self: true));
    case final Function f:
      final k = _exactArity(f);
      if (k == null) return null;
      return _recorder(f, k, path, trace, self: false);
  }
  return null;
}

/// A closure of [k] `Object?` parameters that records its arguments and
/// calls [function]. With [self], the first parameter is `this`.
Function _recorder(
  Function function,
  int k,
  String path,
  List<String> trace, {
  required bool self,
}) {
  void record(List<Object?> args) =>
      trace.add(_traceLine(path, self ? args.skip(1).toList() : args));
  // The recorder calls the closure by arity: a cast to a function type does
  // not fit a closure with typed parameters.
  final f = function as dynamic;
  return switch (k) {
    0 => () {
      record(const []);
      // A closure call by arity (see above).
      // ignore: avoid_dynamic_calls
      return f();
    },
    1 => (Object? a) {
      record([a]);
      // A closure call by arity (see above).
      // ignore: avoid_dynamic_calls
      return f(a);
    },
    2 => (Object? a, Object? b) {
      record([a, b]);
      // A closure call by arity (see above).
      // ignore: avoid_dynamic_calls
      return f(a, b);
    },
    3 => (Object? a, Object? b, Object? c) {
      record([a, b, c]);
      // A closure call by arity (see above).
      // ignore: avoid_dynamic_calls
      return f(a, b, c);
    },
    _ => (Object? a, Object? b, Object? c, Object? d) {
      record([a, b, c, d]);
      // A closure call by arity (see above).
      // ignore: avoid_dynamic_calls
      return f(a, b, c, d);
    },
  };
}

/// One line of the trace: the path, the context keys of the first argument
/// (or its text) and the JS kind of the second argument ([_argKind]), or
/// `-` for a function without a second parameter.
String _traceLine(String path, List<Object?> args) {
  final first = args.isEmpty ? undefined : args[0];
  final String head;
  if (first is Map<String, Object?>) {
    head = [
      for (final key in _contextKeys)
        switch (jsGet(first, key)) {
          final Object? v when identical(v, undefined) => '$key=-',
          final v => '$key=${_canon(v, 0, 1)}',
        },
    ].join(' ');
  } else {
    head = _canon(first, 0, 2);
  }
  final second = args.length > 1 ? _argKind(args[1]) : '-';
  return '$path | $head | $second';
}

/// The kind of the second argument of a user function: `absent` for the
/// [undefined] sentinel (an argument that the caller does not give),
/// `resolver` for a resolver proxy, `object` for another Map, else the
/// `typeof` name.
String _argKind(Object? value) => identical(value, undefined)
    ? 'absent'
    : value is JsProxyObject
    ? 'resolver'
    : value is Map
    ? 'object'
    : jsTypeof(value);

// ---------------------------------------------------------------------------
// The bench-like configs of D1 (stressChartConfig of the gallery at N 50).

const int _n = 50;

const String _background = 'rgba(54, 162, 235, 0.45)';

const String _backgroundOdd = 'rgba(255, 99, 132, 0.45)';

/// `stressScriptableBackground` of the gallery.
Object? _scriptableBackground(Object? context) =>
    jsToNumber(jsGet(context, 'dataIndex')) % 2 == 0
    ? _background
    : _backgroundOdd;

/// A fixed field of fractions in 0 to 1 (no Random).
double _fx(int i) => ((i * 37) % 101) / 100;

double _fy(int i) => ((i * 53 + 17) % 97) / 96;

double _fr(int i) => 2 + 4 * (((i * 29) % 31) / 30);

Map<String, Object?> _hidden(String type, {double? min, double? max}) =>
    <String, Object?>{
      'type': type,
      'display': false,
      'ticks': <String, Object?>{'display': false},
      'min': ?min,
      'max': ?max,
    };

Map<String, Object?> _unitScales() => <String, Object?>{
  'x': <String, Object?>{
    'type': 'linear',
    'display': false,
    'ticks': <String, Object?>{'display': false},
    'suggestedMin': 0.0,
    'suggestedMax': 1.0,
  },
  'y': <String, Object?>{
    'type': 'linear',
    'display': false,
    'ticks': <String, Object?>{'display': false},
    'min': 0.0,
    'max': 1.0,
  },
};

/// The config of `stressChartConfig` of [type] with N 50, with the default
/// events. [animation] is the chart option `animation`.
Map<String, Object?> _benchConfig(
  String type, {
  Object? backgroundColor = _background,
  Object? animation = false,
  bool primitive = false,
}) {
  final points = type == 'line' || type == 'scatter';
  final arcs = type == 'doughnut' || type == 'pie' || type == 'polarArea';
  final labeled = (!points && type != 'bubble') || primitive;
  final data = <Object?>[
    for (var i = 0; i < _n; i++)
      if (primitive)
        _fy(i)
      else if (points)
        <String, Object?>{'x': _fx(i), 'y': _fy(i)}
      else if (type == 'bubble')
        <String, Object?>{'x': _fx(i), 'y': _fy(i), 'r': _fr(i)}
      else if (arcs)
        0.05 + 0.95 * _fy(i)
      else
        _fy(i),
  ];
  final scales = switch (type) {
    'line' when primitive => <String, Object?>{
      'x': _hidden('category'),
      'y': _hidden('linear', min: 0, max: 1),
    },
    'line' || 'scatter' => _unitScales(),
    'bar' => <String, Object?>{
      'x': _hidden('category'),
      'y': _hidden('linear', min: 0, max: 1),
    },
    'bubble' => <String, Object?>{
      'x': _hidden('linear', min: 0, max: 1),
      'y': _hidden('linear', min: 0, max: 1),
    },
    'polarArea' || 'radar' => <String, Object?>{
      'r': _hidden('radialLinear', min: 0, max: 1),
    },
    _ => null,
  };
  return <String, Object?>{
    'type': type,
    'data': <String, Object?>{
      if (labeled) 'labels': <Object?>[for (var i = 0; i < _n; i++) 'Point $i'],
      'datasets': <Object?>[
        <String, Object?>{
          'data': data,
          'backgroundColor': backgroundColor,
          'borderColor': '#36A2EB',
          'borderWidth': 1.0,
          if (points) ...<String, Object?>{
            'pointStyle': 'circle',
            'radius': 3.0,
            'showLine': false,
            'clip': false,
          },
        },
      ],
    },
    'options': <String, Object?>{
      'animation': animation,
      'maintainAspectRatio': false,
      'plugins': <String, Object?>{'legend': false},
      if (points && !primitive) ...<String, Object?>{
        'parsing': false,
        'layout': <String, Object?>{'autoPadding': false},
      },
      'scales': ?scales,
      'responsive': false,
      'devicePixelRatio': 1.0,
    },
  };
}

/// A case of a config without acquireChart options.
_Case _configCase(
  String name,
  Map<String, Object?> Function() config, {
  void Function()? cleanup,
}) => (
  name: name,
  make: () => (config: config(), options: null),
  cleanup: cleanup,
);

/// The default animations of the cases `motion.*`.
Map<String, Object?> _motion() => <String, Object?>{};

final List<_Case> _benchCases = [
  _configCase('chart.a/b line', () => _benchConfig('line')),
  _configCase('chart.b scatter', () => _benchConfig('scatter')),
  _configCase(
    'chart.c',
    () => _benchConfig('line', backgroundColor: _scriptableBackground),
  ),
  _configCase(
    'chart.c.indexable',
    () => _benchConfig(
      'line',
      backgroundColor: <Object?>[_background, _backgroundOdd],
    ),
  ),
  _configCase(
    'chart.line.primitive',
    () => _benchConfig('line', primitive: true),
  ),
  for (final type in [
    'bar',
    'bubble',
    'doughnut',
    'pie',
    'polarArea',
    'radar',
  ])
    _configCase('chart.$type', () => _benchConfig(type)),
  _configCase(
    'motion.line',
    () => _benchConfig('line', animation: _motion()),
  ),
  _configCase('motion.bar', () => _benchConfig('bar', animation: _motion())),
  _configCase(
    'motion.line.delay',
    () => _benchConfig(
      'line',
      animation: <String, Object?>{
        'delay': (Object? ctx) =>
            jsGet(ctx, 'type') == 'data' ? jsGet(ctx, 'dataIndex') : 0.0,
      },
    ),
  ),
];

// ---------------------------------------------------------------------------
// The focused configs of D1.

/// A line chart of [n] points with the labels `a`, `b`, ... and the
/// datasets [datasets].
Map<String, Object?> _line(
  List<Map<String, Object?>> datasets, {
  Map<String, Object?> options = const {},
  String type = 'line',
  int n = 6,
}) => <String, Object?>{
  'type': type,
  'data': <String, Object?>{
    'labels': <Object?>[for (var i = 0; i < n; i++) 'L$i'],
    'datasets': <Object?>[...datasets],
  },
  'options': <String, Object?>{...options},
};

List<Object?> _values(int n, [int seed = 0]) => <Object?>[
  for (var i = 0; i < n; i++) (((i + seed) * 7) % 11).toDouble(),
];

/// The config of the probe of judge-r.md §2.3: a scriptable
/// `pointBorderWidth` writes `radius` through its second argument (the
/// sub-resolver) at dataIndex 2.
Map<String, Object?> _hazardConfig() => _line(
  [
    <String, Object?>{
      'data': _values(8),
      'pointBorderWidth': (Object? ctx, Object? options) {
        if (jsGet(ctx, 'dataIndex') == 2.0) {
          (options! as Map<String, Object?>)['radius'] = 9.0;
        }
        return 1.0;
      },
    },
  ],
  n: 8,
  options: <String, Object?>{
    'plugins': <String, Object?>{'legend': false, 'tooltip': false},
  },
);

Object? _dataIndex(Object? ctx) => jsGet(ctx, 'dataIndex');

/// `Chart.defaults.elements.point`.
Map<String, Object?> _pointDefaults() =>
    jsGet(jsGet(defaults, 'elements'), 'point')! as Map<String, Object?>;

/// A case whose scriptable data option deletes
/// `Chart.defaults.animation.easing` in the middle of an animated update
/// (the guard G5 of judge-r.md §2.3). The cleanup puts back the entries of
/// `Chart.defaults.animation` in their order.
_Case _animationDefaultsCase() {
  late List<MapEntry<String, Object?>> saved;
  Map<String, Object?> animation() =>
      jsGet(defaults, 'animation')! as Map<String, Object?>;
  return _configCase(
    'a scriptable option deletes defaults.animation.easing',
    () {
      saved = animation().entries.toList();
      return _line(
        [
          <String, Object?>{
            'data': _values(6),
            'pointRadius': (Object? ctx) {
              if (jsGet(ctx, 'dataIndex') == 3.0) {
                animation().remove('easing');
              }
              return 3.0;
            },
          },
        ],
        options: <String, Object?>{
          'animation': <String, Object?>{'duration': 500.0},
        },
      );
    },
    cleanup: () => animation()
      ..clear()
      ..addEntries(saved),
  );
}

/// A scriptable option with a constant result.
Object? _constantBackground(Object? ctx) => 'rgba(0, 0, 0, 0.1)';

double _index(Object? ctx) => switch (_dataIndex(ctx)) {
  final double i => i,
  _ => -1,
};

final List<_Case> _focusedCases = [
  _configCase(
    'scriptable on the dataset',
    () => _line([
      <String, Object?>{
        'data': _values(6),
        'pointRadius': (Object? ctx) => 2 + _index(ctx) % 3,
        'borderColor': (Object? ctx, Object? options) =>
            jsGet(ctx, 'type') == 'dataset' ? '#ff0000' : '#00ff00',
      },
    ]),
  ),
  _configCase(
    'scriptable on options.datasets.line',
    () => _line(
      [
        <String, Object?>{'data': _values(6)},
      ],
      options: <String, Object?>{
        'datasets': <String, Object?>{
          'line': <String, Object?>{
            'pointBackgroundColor': (Object? ctx) =>
                _index(ctx) > 2 ? 'red' : 'blue',
          },
        },
      },
    ),
  ),
  _configCase(
    'scriptable on options.elements.point',
    () => _line(
      [
        <String, Object?>{'data': _values(6)},
      ],
      options: <String, Object?>{
        'elements': <String, Object?>{
          'point': <String, Object?>{
            'radius': (Object? ctx) => 1 + _index(ctx),
            'hoverRadius': (Object? ctx, Object? options) =>
                jsToNumber(jsGet(options, 'radius')) + 2,
          },
        },
      },
    ),
  ),
  _configCase(
    'scriptable on the chart options',
    () => _line(
      [
        <String, Object?>{'data': _values(6)},
        <String, Object?>{'data': _values(6, 3)},
      ],
      options: <String, Object?>{
        'borderWidth': (Object? ctx) =>
            jsGet(ctx, 'datasetIndex') == 1.0 ? 3.0 : 1.0,
        'backgroundColor': _constantBackground,
      },
    ),
  ),
  _configCase(
    'indexable arrays',
    () => _line([
      <String, Object?>{
        'data': _values(6),
        'pointRadius': <Object?>[2.0, 4.0, 6.0],
        'pointBackgroundColor': <Object?>['red', 'green', 'blue'],
        'borderDash': <Object?>[4.0, 2.0],
      },
    ]),
  ),
  _configCase(
    'hover prefixes',
    () => _line([
      <String, Object?>{
        'data': _values(6),
        'pointHoverRadius': 7.0,
        'hoverBackgroundColor': (Object? ctx) =>
            jsGet(ctx, 'active') == true ? 'red' : 'blue',
        'pointHoverBorderWidth': (Object? ctx) => 1 + _index(ctx),
      },
    ]),
  ),
  _configCase(
    'object option: bar borderRadius',
    () => _line(
      [
        <String, Object?>{
          'data': _values(6),
          'borderRadius': <String, Object?>{
            'topLeft': 4.0,
            'topRight': _index,
            'bottomLeft': 0.0,
            'bottomRight': 2.0,
          },
          'borderSkipped': false,
        },
      ],
      type: 'bar',
    ),
  ),
  _configCase(
    'object option: arc borderRadius',
    () => _line(
      [
        <String, Object?>{
          'data': _values(6, 1),
          'borderRadius': <String, Object?>{
            'outerStart': 2.0,
            'outerEnd': (Object? ctx) => 1 + _index(ctx),
            'innerStart': 1.0,
            'innerEnd': 0.0,
          },
        },
      ],
      type: 'doughnut',
    ),
  ),
  _configCase(
    'fallbacks: interaction, tooltip, legend labels',
    () => _line(
      [
        <String, Object?>{'data': _values(6)},
        <String, Object?>{'data': _values(6, 2), 'hidden': true},
      ],
      options: <String, Object?>{
        'hover': <String, Object?>{'mode': 'nearest', 'intersect': false},
        'interaction': <String, Object?>{'axis': 'x'},
        'plugins': <String, Object?>{
          'tooltip': <String, Object?>{
            'backgroundColor': (Object? ctx) => 'rgba(1, 2, 3, 0.5)',
            'callbacks': <String, Object?>{
              'label': (Object? item) => 'item',
            },
          },
          'legend': <String, Object?>{
            'labels': <String, Object?>{
              'font': (Object? ctx) => <String, Object?>{'size': 11.0},
              'color': (Object? ctx) => '#333333',
            },
          },
        },
      },
    ),
  ),
  _configCase(
    'a scriptable option writes ctx.parsed',
    () => _line([
      <String, Object?>{
        'data': _values(6),
        'pointRadius': (Object? ctx) {
          if (jsGet(ctx, 'dataIndex') == 1.0) {
            (jsGet(ctx, 'parsed')! as Map<String, Object?>)['x'] = 10.0;
          }
          return 3.0;
        },
      },
    ]),
  ),
  _configCase('a write through the sub-resolver', _hazardConfig),
  _configCase(
    'animation: scriptable delay',
    () => _line(
      [
        <String, Object?>{'data': _values(8)},
      ],
      n: 8,
      options: <String, Object?>{
        'animation': <String, Object?>{
          'duration': 1000.0,
          'delay': (Object? ctx, Object? options) {
            final i = jsGet(ctx, 'dataIndex');
            return i is double ? i * 10 : 0.0;
          },
        },
      },
    ),
  ),
  _configCase(
    'animation: scriptable duration',
    () => _line(
      [
        <String, Object?>{'data': _values(8)},
      ],
      n: 8,
      options: <String, Object?>{
        'animation': <String, Object?>{
          'duration': (Object? ctx) => 100 + 10 * _index(ctx),
        },
      },
    ),
  ),
  _configCase(
    'animation: false on a dataset',
    () => _line(
      [
        <String, Object?>{'data': _values(6), 'animation': false},
        <String, Object?>{'data': _values(6, 4)},
      ],
      options: <String, Object?>{
        'animation': <String, Object?>{'duration': 500.0},
      },
    ),
  ),
  _configCase(
    'animation: an animations entry with properties',
    () => _line(
      [
        <String, Object?>{'data': _values(6)},
      ],
      options: <String, Object?>{
        'animation': <String, Object?>{'duration': 400.0},
        'animations': <String, Object?>{
          'radius': <String, Object?>{
            'properties': <Object?>['radius', 'borderWidth'],
            'type': 'number',
            'from': 0.0,
            'duration': 300.0,
            'easing': 'easeOutBounce',
          },
          'colors': <String, Object?>{
            'duration': (Object? ctx) => 50 + _index(ctx),
          },
        },
      },
    ),
  ),
  _configCase(
    'animation: transitions of hide and show',
    () => _line(
      [
        <String, Object?>{'data': _values(6)},
        <String, Object?>{'data': _values(6, 5)},
      ],
      type: 'bar',
      options: <String, Object?>{
        'animation': <String, Object?>{'duration': 300.0, 'loop': false},
        'transitions': <String, Object?>{
          'hide': <String, Object?>{
            'animation': <String, Object?>{'duration': 200.0},
          },
          'show': <String, Object?>{
            'animations': <String, Object?>{
              'x': <String, Object?>{'from': 0.0},
              'y': <String, Object?>{'from': 0.0},
            },
          },
        },
      },
    ),
  ),
  _configCase(
    'a scriptable option adds a key to defaults.elements.point',
    () => _line([
      <String, Object?>{
        'data': _values(6),
        'pointRadius': (Object? ctx) {
          if (jsGet(ctx, 'dataIndex') == 2.0) {
            _pointDefaults()['d1Extra'] = 5.0;
          }
          return 3.0;
        },
      },
    ]),
    cleanup: () => _pointDefaults().remove('d1Extra'),
  ),
  _animationDefaultsCase(),
  _configCase(
    'bar: skipNull with two datasets',
    () => _line(
      [
        <String, Object?>{
          'data': <Object?>[1.0, null, 3.0, null, 5.0, 2.0],
          'skipNull': true,
        },
        <String, Object?>{
          'data': <Object?>[null, 2.0, 1.0, 4.0, null, 3.0],
          'skipNull': true,
        },
      ],
      type: 'bar',
    ),
  ),
  _configCase(
    'bar: stacked with stack groups',
    () => _line(
      [
        <String, Object?>{'data': _values(6), 'stack': 'a'},
        <String, Object?>{'data': _values(6, 1), 'stack': 'a'},
        <String, Object?>{'data': _values(6, 2), 'stack': 'b'},
      ],
      type: 'bar',
      options: <String, Object?>{
        'scales': <String, Object?>{
          'x': <String, Object?>{'stacked': true},
          'y': <String, Object?>{'stacked': true},
        },
      },
    ),
  ),
  _configCase(
    'mixed: bar and line',
    () => _line(
      [
        <String, Object?>{'data': _values(6), 'type': 'bar'},
        <String, Object?>{
          'data': _values(6, 3),
          'type': 'line',
          'pointRadius': (Object? ctx) => 2 + _index(ctx),
        },
      ],
      type: 'bar',
    ),
  ),
  _configCase(
    'scatter and bubble with scriptable radius',
    () => <String, Object?>{
      'type': 'bubble',
      'data': <String, Object?>{
        'datasets': <Object?>[
          <String, Object?>{
            'data': <Object?>[
              for (var i = 0; i < 6; i++)
                <String, Object?>{'x': _fx(i), 'y': _fy(i), 'r': _fr(i)},
            ],
            'radius': (Object? ctx) => 3 + _index(ctx),
          },
          <String, Object?>{
            'type': 'scatter',
            'data': <Object?>[
              for (var i = 0; i < 6; i++)
                <String, Object?>{'x': _fy(i), 'y': _fx(i)},
            ],
          },
        ],
      },
    },
  ),
  _configCase(
    'polar area and radar with scriptable colors',
    () => _line(
      [
        <String, Object?>{
          'data': _values(6, 1),
          'backgroundColor': (Object? ctx) =>
              _index(ctx).toInt().isEven ? 'red' : 'blue',
        },
      ],
      type: 'polarArea',
    ),
  ),
  _configCase(
    'radar with scriptable point options',
    () => _line(
      [
        <String, Object?>{
          'data': _values(6, 2),
          'pointRadius': (Object? ctx) => 2 + _index(ctx),
          'fill': true,
        },
      ],
      type: 'radar',
    ),
  ),
];
