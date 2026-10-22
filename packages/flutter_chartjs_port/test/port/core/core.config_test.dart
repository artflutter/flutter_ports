// Original code, not ported from Chart.js: core.config cases with no spec.
import 'dart:async';
import 'dart:convert';

import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/src/core/core.config.dart';
import 'package:flutter_chartjs_port/src/core/core.defaults.dart';
import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/core/core.typedRegistry.dart';
import 'package:flutter_chartjs_port/src/elements/element.arc.dart';
import 'package:flutter_chartjs_port/src/elements/element.bar.dart';
import 'package:flutter_chartjs_port/src/elements/element.line.dart';
import 'package:flutter_chartjs_port/src/elements/element.point.dart';
import 'package:flutter_chartjs_port/src/elements/element_options.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.config.dart'
    as helpers;
import 'package:flutter_chartjs_port/src/js/js_array.dart';
import 'package:flutter_chartjs_port/src/js/js_function.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:test/test.dart';

// Upstream has no spec for src/core/core.config.js (AGENTS.md rule 3). The
// expected values come from src/core/core.config.js at v4.5.1, with the
// types of its .ts imports stripped by Node.js v24.12.0 on x64. The probe
// writes into the `defaults` and `overrides` of core.defaults.js, as the
// registry writes the defaults of the scales, the controllers and the
// elements. The harness restores both after each test (setUpSpecs).
//
// The theme groups `theme-H0` to `theme-H3` pin the hunks of Chart.js ADR
// 0001 (theming.md §3.1). Their expected values come from a JavaScript
// prototype of the four hunks on a copy of core.config.js in the same
// Node.js, beside the upstream file. The tests are theming.md §8 test 1 at
// the config level (no extra scope without a theme, the §3.2 position of the
// theme scope) and the rows of §8 test 2 that need no palette and no
// registry: elements, scales, plugins and chart level.
//
// Module-level caches persist from test to test, as in JavaScript: the key
// lists of `cachedKeys`. Each test that reads the identity of key lists uses
// its own dataset types.

/// `JSON.stringify(value, replacer)` with the replacer of the Node.js probe:
/// `undefined` is `"<undefined>"` and a function is `"<fn>"`. A Map gives its
/// keys in the `Object.keys` order, also a resolver.
String _json(Object? value) => switch (value) {
  null => 'null',
  Undefined() => '"<undefined>"',
  final bool b => b ? 'true' : 'false',
  final double d => jsNumberToString(d),
  num() => throw ArgumentError.value(value, 'value', 'is an int'),
  final String s => jsonEncode(s),
  _ when jsIsFunction(value) => '"<fn>"',
  final List<Object?> list => '[${list.map(_json).join(',')}]',
  final Map<String, Object?> map =>
    '{${jsObjectKeys(map).map((k) => _entry(map, k)).join(',')}}',
  _ => throw ArgumentError.value(value, 'value', 'has no JSON form'),
};

/// The JSON member `"key":value` of [key] in [map].
String _entry(Map<String, Object?> map, String key) =>
    '${jsonEncode(key)}:${_json(map[key])}';

/// The labels of the scope objects of a probe: the name of a known object,
/// `{}#n` for the n-th new empty object, or `?<json>` for another value.
String Function(Object?) _labeller(List<(Object?, String)> named) {
  final names = Map<Object?, String>.identity();
  for (final (scope, name) in named) {
    names[scope] = name;
  }
  final seen = Map<Object?, String>.identity();
  var fresh = 0;
  return (scope) {
    final name = names[scope] ?? seen[scope];
    if (name != null) return name;
    final label = scope is Map<String, Object?> && jsObjectKeys(scope).isEmpty
        ? '{}#${fresh++}'
        : '?${_json(scope)}';
    seen[scope] = label;
    return label;
  };
}

/// The summary of a merged scale of the probe: each own key, with `"{...}"`
/// for a value that is an object.
Map<String, Object?> _scaleSummary(Object? scale) {
  final map = scale! as Map<String, Object?>;
  return {
    for (final key in jsObjectKeys(map))
      key: map[key] is Map ? '{...}' : map[key],
  };
}

/// The summaries of the merged scales of [config].
String _scales(Object? config) {
  final scales = Config(config).options['scales']! as Map<String, Object?>;
  return _json({
    for (final id in jsObjectKeys(scales)) id: _scaleSummary(scales[id]),
  });
}

/// The lines that [body] prints: `console.error` and `console.warn`.
List<String> _prints(void Function() body) {
  final lines = <String>[];
  runZoned(
    body,
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) => lines.add(line),
    ),
  );
  return lines;
}

/// The value of the dot path [path] in the Map [root].
Object? _at(Object? root, String path) {
  var node = root;
  for (final key in path.split('.')) {
    node = jsGet(node, key);
  }
  return node;
}

/// The default `ticks.backdropColor` of the scales.
const String _backdrop = 'rgba(255, 255, 255, 0.75)';

/// A [StateError] with the message of `determineAxis`.
Matcher _axisError(String id) => throwsA(
  isA<StateError>().having(
    (e) => e.message,
    'message',
    "Cannot determine type of '$id' axis. "
        "Please provide 'axis' or 'position' option.",
  ),
);

/// The test scale types and chart types of the scale probe, as the registry
/// would write their defaults and overrides.
void _setUpScaleTypes() {
  defaults
    ..set('scales.tlin', <String, Object?>{
      'axis': 'y',
      'beginAtZero': false,
      'lin': 1.0,
    })
    ..set('scales.tcat', <String, Object?>{'offset': false, 'cat': 1.0})
    ..set('scales.trad', <String, Object?>{'axis': 'r', 'rad': 1.0})
    ..override('tbar', <String, Object?>{
      'scales': <String, Object?>{
        '_index_': <String, Object?>{
          'type': 'tcat',
          'offset': true,
          'grid': <String, Object?>{'offset': true},
        },
        '_value_': <String, Object?>{'type': 'tlin', 'beginAtZero': true},
      },
    })
    ..override('tline', <String, Object?>{
      'scales': <String, Object?>{
        '_index_': <String, Object?>{'type': 'tcat'},
        '_value_': <String, Object?>{'type': 'tlin'},
      },
    });
}

/// The summary of the scale `x` of the scale probe for the chart type
/// `tbar` and one dataset.
const String _tbarX =
    '"axis":"x","type":"tcat","offset":true,"grid":"{...}","cat":1,'
    '"display":true,"reverse":false,"beginAtZero":false,"bounds":"ticks",'
    '"clip":true,"grace":0,"border":"{...}","title":"{...}","ticks":"{...}"';

/// The summary of the scale `y` of the scale probe for the chart type
/// `tbar` and one dataset.
const String _tbarY =
    '"axis":"y","type":"tlin","beginAtZero":true,"lin":1,"display":true,'
    '"offset":false,"reverse":false,"bounds":"ticks","clip":true,"grace":0,'
    '"grid":"{...}","border":"{...}","title":"{...}","ticks":"{...}"';

/// The keys of the scope objects that follow the main keys of a merged
/// scale: the defaults of `defaults.scale`.
const String _scaleTail =
    '"display":true,"offset":false,"reverse":false,"beginAtZero":false,'
    '"bounds":"ticks","clip":true,"grace":0,"grid":"{...}","border":"{...}",'
    '"title":"{...}","ticks":"{...}"';

/// The test element type and chart type of the scope probe.
void _setUpScopeTypes() {
  defaults
    ..set('elements.tbar', <String, Object?>{
      'backgroundColor': 'D-el',
      'borderWidth': 0.0,
    })
    ..set('datasets.tbar', <String, Object?>{'categoryPercentage': 0.8})
    ..override('tbar', <String, Object?>{
      'elements': <String, Object?>{
        'tbar': <String, Object?>{'borderWidth': 2.0},
      },
      'datasets': <String, Object?>{
        'tbar': <String, Object?>{'x': 1.0},
      },
    });
}

/// A [types.ChartConfiguration] that is not a [Config], for `chartThemeOf`.
final class _OtherConfiguration implements types.ChartConfiguration {
  @override
  final Map<String, Object?> options = {
    themeConfigKey: <String, Object?>{'color': 'T'},
  };

  @override
  final Map<String, Object?> data = {};
}

void main() {
  setUpSpecs();

  // Chart.js ADR 0021, section 7: the four element classes register through
  // a new TypedRegistry, as `Chart.register` registers them. This runs before
  // the snapshot of the restore (setUpSpecs). Thus each test finds the
  // entries of `defaults.elements` and `descriptors.elements`.
  [
    ArcElement.jsClass,
    BarElement.jsClass,
    LineElement.jsClass,
    PointElement.jsClass,
  ].forEach(TypedRegistry(Element.jsClass, 'elements').register);

  group('getIndexAxis', () {
    setUp(() {
      defaults.set('datasets.dsY', <String, Object?>{'indexAxis': 'y'});
    });

    test('the dataset options, the options, the dataset defaults, x', () {
      expect(getIndexAxis('nothing', <String, Object?>{}), 'x');
      expect(getIndexAxis('dsY', <String, Object?>{}), 'y');
      expect(getIndexAxis('dsY', <String, Object?>{'indexAxis': 'r'}), 'r');
      expect(
        getIndexAxis('dsY', <String, Object?>{
          'indexAxis': 'r',
          'datasets': <String, Object?>{
            'dsY': <String, Object?>{'indexAxis': 'q'},
          },
        }),
        'q',
      );
      expect(
        getIndexAxis('dsY', <String, Object?>{
          'indexAxis': 'r',
          'datasets': <String, Object?>{
            'other': <String, Object?>{'indexAxis': 'q'},
          },
        }),
        'r',
      );
    });

    test('a falsy value goes to the next source', () {
      expect(
        getIndexAxis('nothing', <String, Object?>{
          'indexAxis': 0.0,
          'datasets': <String, Object?>{
            'nothing': <String, Object?>{'indexAxis': ''},
          },
        }),
        'x',
      );
      expect(getIndexAxis(undefined, <String, Object?>{}), 'x');
    });

    test('reads a resolver', () {
      final options = helpers.createResolver([
        <String, Object?>{'indexAxis': 'y'},
      ]);
      expect(getIndexAxis('nothing', options), 'y');
    });

    test('null options throw a TypeError', () {
      expect(() => getIndexAxis('nothing', null), throwsA(isA<TypeError>()));
    });
  });

  group('determineAxis', () {
    test('an id x, y or r is the axis', () {
      expect(determineAxis('x', const []), 'x');
      expect(determineAxis('y', const []), 'y');
      expect(determineAxis('r', const []), 'r');
      expect(() => determineAxis('z', [<String, Object?>{}]), _axisError('z'));
    });

    test('the axis option, the position, the first character', () {
      Object? axis(String id, List<Object?> options) =>
          determineAxis(id, options);
      Map<String, Object?> o(String key, Object? value) => {key: value};
      expect(axis('foo', [o('axis', 'y')]), 'y');
      expect(axis('foo', [o('position', 'top')]), 'x');
      expect(axis('foo', [o('position', 'bottom')]), 'x');
      expect(axis('foo', [o('position', 'left')]), 'y');
      expect(axis('foo', [o('position', 'right')]), 'y');
      expect(
        () => axis('foo', [o('position', 'chartArea')]),
        _axisError('foo'),
      );
      expect(axis('xAxis', [<String, Object?>{}]), 'x');
      expect(axis('Yaxis', [<String, Object?>{}]), 'y');
      expect(axis('R2', [<String, Object?>{}]), 'r');
      expect(axis('ra', [<String, Object?>{}]), 'r');
      expect(axis('foo', [<String, Object?>{}, o('axis', 'x')]), 'x');
      expect(
        axis('foo', [<String, Object?>{}, <String, Object?>{}, o('axis', 'r')]),
        'r',
      );
      expect(
        axis('foo', [
          <String, Object?>{'axis': 'y', 'position': 'top'},
        ]),
        'y',
      );
      expect(axis('xfoo', [o('position', 'left')]), 'y');
      expect(axis('foo', [o('axis', 7.0)]), 7.0);
      expect(
        axis('foo', [
          <String, Object?>{'axis': 0.0, 'position': 'top'},
        ]),
        'x',
      );
    });

    test('throws an Error without an axis', () {
      expect(
        () => determineAxis('zz', [<String, Object?>{}]),
        _axisError('zz'),
      );
      expect(() => determineAxis('foo', const []), _axisError('foo'));
      expect(() => determineAxis('foo', [5.0]), _axisError('foo'));
      expect(() => determineAxis('foo', ['top']), _axisError('foo'));
    });

    test('an undefined or null item that the loop reaches throws', () {
      expect(
        () => determineAxis('foo', [
          <String, Object?>{},
          <String, Object?>{},
          undefined,
        ]),
        throwsA(isA<TypeError>()),
      );
      expect(
        () => determineAxis('foo', [<String, Object?>{}, undefined]),
        throwsA(isA<TypeError>()),
      );
      expect(determineAxis('xx', [<String, Object?>{}, undefined]), 'x');
      expect(() => determineAxis('foo', [null]), throwsA(isA<TypeError>()));
    });
  });

  group('initConfig', () {
    test('an absent or null config', () {
      for (final config in [Config(), Config(undefined)]) {
        expect(_json(config.data), '{"datasets":[],"labels":[]}');
        expect(_json(config.options), '{"plugins":{},"scales":{}}');
        expect(config.type, same(undefined));
      }
    });

    test('keeps the config object and its key order', () {
      final raw = <String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'labels': ['a'],
        },
        'options': <String, Object?>{
          'plugins': <String, Object?>{'legend': false},
        },
      };
      final config = Config(raw);
      expect(config.data, same(raw['data']));
      expect(config.options, same(raw['options']));
      expect(
        _json(raw),
        '{"type":"line","data":{"labels":["a"],"datasets":[]},'
        '"options":{"plugins":{"legend":false},"scales":{}}}',
      );
    });

    test('null plugins stay, falsy datasets and labels become arrays', () {
      final raw = <String, Object?>{
        'options': <String, Object?>{'plugins': null},
        'data': <String, Object?>{'datasets': null, 'labels': 0.0},
      };
      Config(raw);
      expect(
        _json(raw),
        '{"options":{"plugins":null,"scales":{}},'
        '"data":{"datasets":[],"labels":[]}}',
      );
      final raw2 = <String, Object?>{'options': null};
      Config(raw2);
      expect(
        _json(raw2),
        '{"options":{"plugins":{},"scales":{}},'
        '"data":{"datasets":[],"labels":[]}}',
      );
    });

    test('a primitive throws a TypeError, as upstream', () {
      expect(() => Config('abc'), throwsA(isA<TypeError>()));
      expect(() => Config(5.0), throwsA(isA<TypeError>()));
      expect(
        () => Config(<String, Object?>{'data': 'abc'}),
        throwsA(isA<TypeError>()),
      );
      expect(
        () => Config(<String, Object?>{'options': 'abc'}),
        throwsA(isA<TypeError>()),
      );
    });

    test('datasets that are not an array throw a TypeError', () {
      expect(
        () => Config(<String, Object?>{
          'data': <String, Object?>{
            'datasets': <String, Object?>{'a': 1.0},
          },
        }),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('getters and setters', () {
    test('platform, plugins and type read the raw config', () {
      final plugins = [
        <String, Object?>{'id': 'p'},
      ];
      void platform() {}
      final raw = <String, Object?>{
        'type': 'bar',
        'platform': platform,
        'plugins': plugins,
      };
      final config = Config(raw);
      expect(config.platform, same(platform));
      expect(config.plugins, same(plugins));
      expect(config.type, 'bar');
      config.type = 'line';
      expect([config.type, raw['type']], ['line', 'line']);
      final none = Config(<String, Object?>{});
      expect(none.platform, same(undefined));
      expect(none.plugins, same(undefined));
      expect(none.type, same(undefined));
    });

    test('set data runs initData', () {
      final raw = <String, Object?>{'type': 'bar'};
      final config = Config(raw);
      expect(config.data, same(raw['data']));
      config.data = <String, Object?>{
        'labels': [1.0],
      };
      expect(_json(raw['data']), '{"labels":[1],"datasets":[]}');
      expect(config.data, same(raw['data']));
      config.data = null;
      expect(_json(raw['data']), '{"datasets":[],"labels":[]}');
    });

    test('set options writes the raw config', () {
      final raw = <String, Object?>{'type': 'bar'};
      final config = Config(raw);
      final options = <String, Object?>{'a': 1.0};
      config.options = options;
      expect(config.options, same(options));
      expect(raw['options'], same(options));
    });
  });

  group('mergeScaleConfig', () {
    setUp(_setUpScaleTypes);

    test('the keys of defaults.scale', () {
      expect(
        jsObjectKeys(defaults['scale']! as Map<String, Object?>),
        [
          'display',
          'offset',
          'reverse',
          'beginAtZero',
          'bounds',
          'clip',
          'grace',
          'grid',
          'border',
          'title',
          'ticks',
        ],
      );
    });

    test('the scales of the chart type overrides for each dataset', () {
      final dataset = <String, Object?>{'data': <Object?>[]};
      expect(
        _scales(<String, Object?>{
          'type': 'tbar',
          'data': <String, Object?>{
            'datasets': [dataset],
          },
        }),
        '{"x":{$_tbarX},"y":{$_tbarY}}',
      );
      expect(_scales(<String, Object?>{'type': 'tbar'}), '{}');
    });

    test('indexAxis y swaps _index_ and _value_', () {
      final y = _tbarX.replaceFirst('"axis":"x"', '"axis":"y"');
      final x = _tbarY.replaceFirst('"axis":"y"', '"axis":"x"');
      expect(
        _scales(<String, Object?>{
          'type': 'tbar',
          'data': <String, Object?>{
            'datasets': [<String, Object?>{}],
          },
          'options': <String, Object?>{'indexAxis': 'y'},
        }),
        '{"y":{$y},"x":{$x}}',
      );
      expect(
        _scales(<String, Object?>{
          'type': 'tbar',
          'data': <String, Object?>{
            'datasets': [
              <String, Object?>{'indexAxis': 'y'},
            ],
          },
        }),
        '{"y":{$y},"x":{$x}}',
      );
    });

    test('the axis ids of a dataset name the scales', () {
      expect(
        _scales(<String, Object?>{
          'type': 'tbar',
          'data': <String, Object?>{
            'datasets': [
              <String, Object?>{'xAxisID': 'x2', 'yAxisID': 'y2'},
            ],
          },
        }),
        '{"x2":{$_tbarX},"y2":{$_tbarY}}',
      );
    });

    test('a dataset of another type adds the scales of its type', () {
      expect(
        _scales(<String, Object?>{
          'type': 'tbar',
          'data': <String, Object?>{
            'datasets': [
              <String, Object?>{},
              <String, Object?>{'type': 'tline', 'yAxisID': 'right'},
            ],
          },
        }),
        '{"x":{$_tbarX},"y":{$_tbarY},"right":{"axis":"y","type":"tlin",'
        '"beginAtZero":false,"lin":1,"display":true,"offset":false,'
        '"reverse":false,"bounds":"ticks","clip":true,"grace":0,'
        '"grid":"{...}","border":"{...}","title":"{...}","ticks":"{...}"}}',
      );
    });

    test('user scales beat the overrides', () {
      expect(
        _scales(<String, Object?>{
          'type': 'tbar',
          'data': <String, Object?>{
            'datasets': [<String, Object?>{}],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{
                'offset': false,
                'type': 'tlin',
                'extra': 1.0,
              },
              'myY': <String, Object?>{'position': 'left'},
              'r2': <String, Object?>{},
            },
          },
        }),
        '{"x":{"axis":"x","offset":false,"type":"tlin","extra":1,'
        '"grid":"{...}","beginAtZero":false,"lin":1,"display":true,'
        '"reverse":false,"bounds":"ticks","clip":true,"grace":0,'
        '"border":"{...}","title":"{...}","ticks":"{...}"},'
        '"myY":{"axis":"y","position":"left",${_tbarY.substring(11)}},'
        '"r2":{"axis":"r",${_tbarY.substring(11)}},'
        '"y":{$_tbarY}}',
      );
    });

    test('the axis of the scale type defaults and of the datasets', () {
      expect(
        _scales(<String, Object?>{
          'type': 'tline',
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'foo': <String, Object?>{'type': 'trad'},
            },
          },
        }),
        '{"foo":{"axis":"r","type":"trad","rad":1,$_scaleTail}}',
      );
      expect(
        _scales(<String, Object?>{
          'type': 'tline',
          'data': <String, Object?>{
            'datasets': [
              <String, Object?>{'yAxisID': 'foo'},
            ],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{'foo': <String, Object?>{}},
          },
        }),
        '{"foo":{"axis":"y","type":"tlin","beginAtZero":false,"lin":1,'
        '"display":true,"offset":false,"reverse":false,"bounds":"ticks",'
        '"clip":true,"grace":0,"grid":"{...}","border":"{...}",'
        '"title":"{...}","ticks":"{...}"},'
        '"x":{"axis":"x","type":"tcat","offset":false,"cat":1,'
        '"display":true,"reverse":false,"beginAtZero":false,'
        '"bounds":"ticks","clip":true,"grace":0,"grid":"{...}",'
        '"border":"{...}","title":"{...}","ticks":"{...}"}}',
      );
      expect(
        _scales(<String, Object?>{
          'type': 'tline',
          'data': <String, Object?>{
            'datasets': [
              <String, Object?>{'xAxisID': 'foo', 'yAxisID': 'foo'},
            ],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{'foo': <String, Object?>{}},
          },
        }),
        '{"foo":{"axis":"x","type":"tcat","offset":false,"cat":1,'
        '"display":true,"reverse":false,"beginAtZero":false,'
        '"bounds":"ticks","clip":true,"grace":0,"grid":"{...}",'
        '"border":"{...}","title":"{...}","ticks":"{...}"}}',
      );
    });

    test('a scale without an axis throws a TypeError', () {
      // `defaults.scales[undefined].axis` throws (core.config.js:46).
      expect(
        () => _scales(<String, Object?>{
          'type': 'tline',
          'options': <String, Object?>{
            'scales': <String, Object?>{'foo': <String, Object?>{}},
          },
        }),
        throwsA(isA<TypeError>()),
      );
      expect(
        () => _scales(<String, Object?>{
          'type': 'tline',
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'foo': <String, Object?>{'type': 'nope'},
            },
          },
        }),
        throwsA(isA<TypeError>()),
      );
    });

    test('an invalid scale and a resolver print and are skipped', () {
      late String invalid;
      late String proxy;
      late String scalesString;
      final lines = _prints(() {
        invalid = _scales(<String, Object?>{
          'type': 'tline',
          'options': <String, Object?>{
            'scales': <String, Object?>{'x': 5.0, 'y': null, 'z': 'abc'},
          },
        });
        proxy = _scales(<String, Object?>{
          'type': 'tline',
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': helpers.attachContext(
                helpers.createResolver([<String, Object?>{}]),
                <String, Object?>{},
              ),
              'y': helpers.createResolver([
                <String, Object?>{'a': 1.0},
              ]),
            },
          },
        });
        scalesString = _scales(<String, Object?>{
          'type': 'tline',
          'options': <String, Object?>{'scales': 'ab'},
        });
      });
      expect(invalid, '{}');
      expect(
        proxy,
        '{"y":{"axis":"y","a":1,"type":"tlin","beginAtZero":false,"lin":1,'
        '"display":true,"offset":false,"reverse":false,"bounds":"ticks",'
        '"clip":true,"grace":0,"grid":"{...}","border":"{...}",'
        '"title":"{...}","ticks":"{...}"}}',
      );
      expect(scalesString, '{}');
      expect(lines, [
        'Invalid scale configuration for scale: x',
        'Invalid scale configuration for scale: y',
        'Invalid scale configuration for scale: z',
        'Ignoring resolver passed as options for scale: x',
        'Invalid scale configuration for scale: 0',
        'Invalid scale configuration for scale: 1',
      ]);
    });

    test('no chart type, an array of scales, an axis option', () {
      expect(
        _scales(<String, Object?>{
          'data': <String, Object?>{
            'datasets': [<String, Object?>{}],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{'x': <String, Object?>{}},
          },
        }),
        '{"x":{"axis":"x",$_scaleTail}}',
      );
      expect(
        _scales(<String, Object?>{
          'type': 'tline',
          'options': <String, Object?>{
            'scales': [
              <String, Object?>{'axis': 'x'},
            ],
          },
        }),
        '{"0":{"axis":"x","type":"tcat","offset":false,"cat":1,'
        '"display":true,"reverse":false,"beginAtZero":false,'
        '"bounds":"ticks","clip":true,"grace":0,"grid":"{...}",'
        '"border":"{...}","title":"{...}","ticks":"{...}"}}',
      );
      expect(
        _scales(<String, Object?>{
          'type': 'tline',
          'data': <String, Object?>{
            'datasets': [<String, Object?>{}],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{'axis': 'y'},
            },
          },
        }),
        '{"x":{"axis":"x","type":"tcat","offset":false,"cat":1,'
        '"display":true,"reverse":false,"beginAtZero":false,'
        '"bounds":"ticks","clip":true,"grace":0,"grid":"{...}",'
        '"border":"{...}","title":"{...}","ticks":"{...}"},'
        '"y":{"axis":"y","type":"tlin","beginAtZero":false,"lin":1,'
        '"display":true,"offset":false,"reverse":false,"bounds":"ticks",'
        '"clip":true,"grace":0,"grid":"{...}","border":"{...}",'
        '"title":"{...}","ticks":"{...}"}}',
      );
    });

    test('dataset values that are not strings or objects', () {
      expect(
        _scales(<String, Object?>{
          'type': 'tbar',
          'data': <String, Object?>{
            'datasets': [
              <String, Object?>{'xAxisID': 5.0},
            ],
          },
        }),
        '{"5":{$_tbarX},"y":{$_tbarY}}',
      );
      expect(
        () => _scales(<String, Object?>{
          'type': 'tbar',
          'data': <String, Object?>{
            'datasets': [null],
          },
        }),
        throwsA(isA<TypeError>()),
      );
      expect(
        _scales(<String, Object?>{
          'type': 'tbar',
          'data': <String, Object?>{
            'datasets': [5.0],
          },
        }),
        '{"x":{$_tbarX},"y":{$_tbarY}}',
      );
      expect(
        _scales(<String, Object?>{
          'type': 'tbar',
          'data': <String, Object?>{
            'datasets': [
              <String, Object?>{'indexAxis': 7.0},
            ],
          },
        }),
        '{"7":{${_tbarX.replaceFirst('"axis":"x"', '"axis":7')}},'
        '"x":{${_tbarY.replaceFirst('"axis":"y"', '"axis":"x"')}}}',
      );
    });

    test('the values of the merged scales', () {
      final config = Config(<String, Object?>{
        'type': 'tbar',
        'data': <String, Object?>{
          'datasets': [<String, Object?>{}],
        },
        'options': <String, Object?>{
          'scales': <String, Object?>{
            'x': <String, Object?>{
              'grid': <String, Object?>{'color': 'red'},
            },
          },
        },
      });
      const border =
          '"border":{"display":true,"dash":[],"dashOffset":0,"width":1,'
          '"color":"rgba(0,0,0,0.1)"}';
      const title =
          '"title":{"display":false,"text":"","padding":{"top":4,'
          '"bottom":4},"color":"#666"}';
      const ticks =
          '"ticks":{"minRotation":0,"maxRotation":50,"mirror":false,'
          '"textStrokeWidth":0,"textStrokeColor":"","padding":3,'
          '"display":true,"autoSkip":true,"autoSkipPadding":3,'
          '"labelOffset":0,"callback":"<fn>","minor":{},"major":{},'
          '"align":"center","crossAlign":"near","showLabelBackdrop":false,'
          '"backdropColor":"$_backdrop","backdropPadding":2,'
          '"color":"#666"}';
      expect(
        _json(_at(config.options, 'scales.x')),
        '{"axis":"x","grid":{"color":"red","offset":true,"display":true,'
        '"lineWidth":1,"drawOnChartArea":true,"drawTicks":true,'
        '"tickLength":8,"tickWidth":"<fn>","tickColor":"<fn>"},'
        '"type":"tcat","offset":true,"cat":1,"display":true,'
        '"reverse":false,"beginAtZero":false,"bounds":"ticks","clip":true,'
        '"grace":0,$border,$title,$ticks}',
      );
      expect(
        _json(_at(config.options, 'scales.y')),
        '{"axis":"y","type":"tlin","beginAtZero":true,"lin":1,'
        '"display":true,"offset":false,"reverse":false,"bounds":"ticks",'
        '"clip":true,"grace":0,"grid":{"display":true,"lineWidth":1,'
        '"drawOnChartArea":true,"drawTicks":true,"tickLength":8,'
        '"tickWidth":"<fn>","tickColor":"<fn>","offset":false,'
        '"color":"rgba(0,0,0,0.1)"},$border,$title,$ticks}',
      );
    });
  });

  group('update', () {
    setUp(_setUpScaleTypes);

    test('merges the scales again into new objects', () {
      final raw = <String, Object?>{
        'type': 'tbar',
        'data': <String, Object?>{
          'datasets': [<String, Object?>{}],
        },
        'options': <String, Object?>{
          'scales': <String, Object?>{
            'x': <String, Object?>{'min': 1.0},
          },
        },
      };
      final config = Config(raw);
      final first = config.options['scales']! as Map<String, Object?>;
      (first['x']! as Map<String, Object?>)['max'] = 9.0;
      config.update();
      final scales = config.options['scales']! as Map<String, Object?>;
      expect(identical(first, scales), isFalse);
      expect(identical(first['x'], scales['x']), isFalse);
      expect(
        _json(_scaleSummary(scales['x'])),
        '{"axis":"x","min":1,"type":"tcat","offset":true,"grid":"{...}",'
        '"cat":1,"display":true,"reverse":false,"beginAtZero":false,'
        '"bounds":"ticks","clip":true,"grace":0,"border":"{...}",'
        '"title":"{...}","ticks":"{...}","max":9}',
      );
    });

    test('initializes new options and new data', () {
      final config =
          Config(<String, Object?>{
              'type': 'tbar',
              'data': <String, Object?>{
                'datasets': [<String, Object?>{}],
              },
            })
            ..options = <String, Object?>{
              'plugins': <String, Object?>{'a': 1.0},
            }
            ..update();
      expect(jsObjectKeys(config.options), ['plugins', 'scales']);
      expect(_json(config.options['plugins']), '{"a":1}');
      expect(
        jsObjectKeys(config.options['scales']! as Map<String, Object?>),
        ['x', 'y'],
      );
      config
        ..data = <String, Object?>{
          'datasets': [
            <String, Object?>{'type': 'tline', 'xAxisID': 'xx'},
          ],
        }
        ..update();
      expect(
        jsObjectKeys(config.options['scales']! as Map<String, Object?>),
        ['x', 'y', 'xx'],
      );
      config
        ..options = null
        ..update();
      expect(jsObjectKeys(config.options), ['plugins', 'scales']);
      expect(
        jsObjectKeys(config.options['scales']! as Map<String, Object?>),
        ['xx', 'y'],
      );
    });
  });

  group('scope keys', () {
    test('datasetScopeKeys', () {
      final config = Config(<String, Object?>{'type': 'bar'});
      final config2 = Config(<String, Object?>{'type': 'line'});
      expect(config.datasetScopeKeys('k1bar'), [
        ['datasets.k1bar', ''],
      ]);
      expect(
        config.datasetScopeKeys('k1bar'),
        same(config2.datasetScopeKeys('k1bar')),
      );
      expect(config.datasetScopeKeys(undefined), [
        ['datasets.undefined', ''],
      ]);
      expect(config.datasetScopeKeys(1.0), [
        ['datasets.1', ''],
      ]);
      expect(
        identical(config.datasetScopeKeys(1.0), config.datasetScopeKeys('1')),
        isFalse,
      );
    });

    test('datasetAnimationScopeKeys', () {
      final config = Config(<String, Object?>{'type': 'bar'});
      final keys = config.datasetAnimationScopeKeys('k2bar', 'active');
      expect(keys, [
        ['datasets.k2bar.transitions.active', 'transitions.active'],
        ['datasets.k2bar', ''],
      ]);
      expect(config.datasetAnimationScopeKeys('k2bar', 'active'), same(keys));
    });

    test('datasetElementScopeKeys', () {
      final config = Config(<String, Object?>{'type': 'bar'});
      final config2 = Config(<String, Object?>{'type': 'line'});
      final keys = config.datasetElementScopeKeys('k3bar', 'bar');
      expect(keys, [
        ['datasets.k3bar.elements.bar', 'datasets.k3bar', 'elements.bar', ''],
      ]);
      expect(config2.datasetElementScopeKeys('k3bar', 'bar'), same(keys));
      expect(config.datasetElementScopeKeys('k3bar', undefined), [
        [
          'datasets.k3bar.elements.undefined',
          'datasets.k3bar',
          'elements.undefined',
          '',
        ],
      ]);
    });

    test('the cache key of a dataset type can be an element key', () {
      final config = Config(<String, Object?>{'type': 'bar'});
      final datasetKeys = config.datasetScopeKeys('k4q-point');
      expect(config.datasetElementScopeKeys('k4q', 'point'), same(datasetKeys));
      expect(datasetKeys, [
        ['datasets.k4q-point', ''],
      ]);
      final elementKeys = config.datasetElementScopeKeys('k5', 'point');
      expect(config.datasetScopeKeys('k5-point'), same(elementKeys));
      expect(elementKeys, [
        ['datasets.k5.elements.point', 'datasets.k5', 'elements.point', ''],
      ]);
    });

    test('pluginScopeKeys', () {
      final config = Config(<String, Object?>{'type': 'k6bar'});
      final config2 = Config(<String, Object?>{'type': 'k6line'});
      final legend = config.pluginScopeKeys(<String, Object?>{'id': 'legend'});
      expect(legend, [
        ['plugins.legend'],
      ]);
      expect(
        config.pluginScopeKeys(<String, Object?>{'id': 'legend'}),
        same(legend),
      );
      expect(
        config.pluginScopeKeys(<String, Object?>{
          'id': 'tooltip',
          'additionalOptionScopes': ['interaction', 'x.y'],
        }),
        [
          ['plugins.tooltip', 'interaction', 'x.y'],
        ],
      );
      expect(config.pluginScopeKeys(<String, Object?>{'id': 'tooltip'}), [
        ['plugins.tooltip', 'interaction', 'x.y'],
      ]);
      expect(config2.pluginScopeKeys(<String, Object?>{'id': 'tooltip'}), [
        ['plugins.tooltip'],
      ]);
      expect(
        config.pluginScopeKeys(<String, Object?>{'id': 'z'}),
        same(config.datasetScopeKeys('k6bar-plugin-z')),
      );
      expect(config.pluginScopeKeys(<String, Object?>{'id': 2.5}), [
        ['plugins.2.5'],
      ]);
      expect(config.pluginScopeKeys(<String, Object?>{}), [
        ['plugins.undefined'],
      ]);
    });
  });

  group('getOptionScopes', () {
    setUp(_setUpScopeTypes);

    late Map<String, Object?> dataset;
    late Map<String, Object?> options;
    late String Function(Object?) label;

    setUp(() {
      dataset = <String, Object?>{
        'data': <Object?>[],
        'datasets': <String, Object?>{
          'tbar': <String, Object?>{
            'elements': <String, Object?>{
              'tbar': <String, Object?>{'a': 1.0},
            },
          },
        },
        'elements': <String, Object?>{
          'tbar': <String, Object?>{'b': 1.0},
        },
      };
      options = <String, Object?>{
        'datasets': <String, Object?>{
          'tbar': <String, Object?>{
            'elements': <String, Object?>{
              'tbar': <String, Object?>{'c': 1.0},
            },
          },
        },
        'elements': <String, Object?>{
          'tbar': <String, Object?>{'d': 1.0},
        },
      };
      label = _labeller([
        (dataset, 'dataset'),
        (_at(dataset, 'datasets.tbar'), 'dataset.datasets.tbar'),
        (
          _at(dataset, 'datasets.tbar.elements.tbar'),
          'dataset.datasets.tbar.elements.tbar',
        ),
        (_at(dataset, 'elements.tbar'), 'dataset.elements.tbar'),
        (options, 'options'),
        (_at(options, 'datasets.tbar'), 'options.datasets.tbar'),
        (
          _at(options, 'datasets.tbar.elements.tbar'),
          'options.datasets.tbar.elements.tbar',
        ),
        (_at(options, 'elements.tbar'), 'options.elements.tbar'),
        (overrides['tbar'], 'overrides.tbar'),
        (_at(overrides, 'tbar.elements.tbar'), 'overrides.tbar.elements.tbar'),
        (_at(overrides, 'tbar.datasets.tbar'), 'overrides.tbar.datasets.tbar'),
        (defaults, 'defaults'),
        (_at(defaults, 'elements.tbar'), 'defaults.elements.tbar'),
        (_at(defaults, 'datasets.tbar'), 'defaults.datasets.tbar'),
        (_at(defaults, 'transitions.active'), 'defaults.transitions.active'),
        (descriptors, 'descriptors'),
      ]);
    });

    Config config() => Config(<String, Object?>{
      'type': 'tbar',
      'data': <String, Object?>{
        'datasets': [dataset],
      },
      'options': options,
    });

    test('the scopes of an element', () {
      final c = config();
      final scopes = c.getOptionScopes(
        dataset,
        c.datasetElementScopeKeys('tbar', 'tbar'),
      );
      expect(scopes.map(label), [
        'dataset',
        'dataset.datasets.tbar.elements.tbar',
        'dataset.datasets.tbar',
        'dataset.elements.tbar',
        'options.datasets.tbar.elements.tbar',
        'options.datasets.tbar',
        'options.elements.tbar',
        'options',
        'overrides.tbar.datasets.tbar',
        'overrides.tbar.elements.tbar',
        'overrides.tbar',
        'defaults.datasets.tbar',
        'defaults.elements.tbar',
        'defaults',
        'descriptors',
      ]);
    });

    test('the scopes of a dataset and of an animation', () {
      final c = config();
      expect(
        c.getOptionScopes(dataset, c.datasetScopeKeys('tbar')).map(label),
        [
          'dataset',
          'dataset.datasets.tbar',
          'options.datasets.tbar',
          'options',
          'overrides.tbar.datasets.tbar',
          'overrides.tbar',
          'defaults.datasets.tbar',
          'defaults',
          'descriptors',
        ],
      );
      expect(
        c
            .getOptionScopes(
              dataset,
              c.datasetAnimationScopeKeys('tbar', 'active'),
            )
            .map(label),
        [
          'dataset',
          'defaults.transitions.active',
          'dataset.datasets.tbar',
          'options.datasets.tbar',
          'options',
          'overrides.tbar.datasets.tbar',
          'overrides.tbar',
          'defaults.datasets.tbar',
          'defaults',
          'descriptors',
        ],
      );
    });

    test('a falsy main scope adds no scope', () {
      final c = config();
      final keys = c.datasetElementScopeKeys('tbar', 'tbar');
      const expected = [
        'options.datasets.tbar.elements.tbar',
        'options.datasets.tbar',
        'options.elements.tbar',
        'options',
        'overrides.tbar.datasets.tbar',
        'overrides.tbar.elements.tbar',
        'overrides.tbar',
        'defaults.datasets.tbar',
        'defaults.elements.tbar',
        'defaults',
        'descriptors',
      ];
      expect(c.getOptionScopes(undefined, keys).map(label), expected);
      expect(c.getOptionScopes(false, keys).map(label), expected);
      expect(
        c.getOptionScopes(undefined, keys),
        same(c.getOptionScopes(undefined, keys)),
      );
    });

    test('no scope gives one new empty object', () {
      final c = config();
      expect(
        c
            .getOptionScopes(undefined, [
              ['nope.nope'],
            ])
            .map(label),
        ['{}#0'],
      );
      expect(c.getOptionScopes(dataset, []).map(label), ['{}#1']);
    });

    test('a chart type without overrides gives a new empty object', () {
      final c = Config(<String, Object?>{
        'type': 'tnone',
        'data': <String, Object?>{
          'datasets': [dataset],
        },
        'options': options,
      });
      expect(
        c
            .getOptionScopes(
              dataset,
              c.datasetElementScopeKeys('tnone', 'tbar'),
            )
            .map(label),
        [
          'dataset',
          'dataset.elements.tbar',
          'options.elements.tbar',
          'options',
          '{}#0',
          'defaults.elements.tbar',
          'defaults',
          'descriptors',
        ],
      );
    });

    test('a primitive at a key is a scope', () {
      final c = Config(<String, Object?>{
        'type': 'tbar',
        'options': <String, Object?>{
          'plugins': <String, Object?>{
            'legend': false,
            'title': 0.0,
            'tooltip': null,
          },
        },
      });
      expect(
        c
            .getOptionScopes(<String, Object?>{}, [
              [
                'plugins.legend',
                'plugins.title',
                'plugins.tooltip',
                'plugins.none',
              ],
            ])
            .map(label),
        ['{}#0', '?false', '?0', '?null'],
      );
    });

    test('a scope that a caller adds stays in the cached list', () {
      final c = Config(<String, Object?>{'type': 'tbar'});
      final plugin = <String, Object?>{
        'id': 'local',
        'defaults': <String, Object?>{'p': 1.0},
      };
      final keys = c.pluginScopeKeys(plugin);
      final main = <String, Object?>{};
      final first = c.getOptionScopes(main, keys)..add(plugin['defaults']);
      final second = c.getOptionScopes(main, keys);
      expect(second, same(first));
      expect(second.length, 2);
    });
  });

  group('chartOptionScopes', () {
    setUp(_setUpScopeTypes);

    test('the scopes of the chart options', () {
      final options = <String, Object?>{'color': 'O'};
      final config = Config(<String, Object?>{
        'type': 'tbar',
        'options': options,
      });
      final label = _labeller([
        (options, 'options'),
        (overrides['tbar'], 'overrides.tbar'),
        (_at(defaults, 'datasets.tbar'), 'defaults.datasets.tbar'),
        (defaults, 'defaults'),
        (descriptors, 'descriptors'),
      ]);
      final scopes = config.chartOptionScopes();
      expect(scopes.map(label), [
        'options',
        'overrides.tbar',
        'defaults.datasets.tbar',
        '?{"type":"tbar"}',
        'defaults',
        'descriptors',
      ]);
      expect(identical(config.chartOptionScopes(), scopes), isFalse);
    });

    test('a type without overrides and no type', () {
      final none = Config(<String, Object?>{'type': 'tnone'});
      final label = _labeller([
        (none.options, 'options'),
        (defaults, 'defaults'),
        (descriptors, 'descriptors'),
      ]);
      expect(none.chartOptionScopes().map(label), [
        'options',
        '{}#0',
        '{}#1',
        '?{"type":"tnone"}',
        'defaults',
        'descriptors',
      ]);
      final noType = Config(<String, Object?>{});
      final scopes = noType.chartOptionScopes();
      expect(_json(scopes[3]), '{"type":"<undefined>"}');
      expect(jsObjectKeys(scopes[3]! as Map<String, Object?>), ['type']);
    });
  });

  group('resolveNamedOptions', () {
    late Config config;
    late List<Object?> scopes;

    setUp(() {
      config = Config(<String, Object?>{'type': 'tbar'});
      scopes = [
        <String, Object?>{
          'radius': 3.0,
          'hoverRadius': 4.0,
          'pointRadius': 5.0,
          'pointStyle': 'circle',
          'nul': null,
          'und': undefined,
          'borderColor': 'B',
          'hoverBorderColor': 'H',
        },
        <String, Object?>{'extra': 1.0},
      ];
    });

    test('static options are shared', () {
      final result = config.resolveNamedOptions(
        scopes,
        ['radius', 'pointStyle', 'nul', 'und', 'missing', 'extra'],
        () => throw StateError('no context'),
      );
      expect(
        _json(result),
        r'{"$shared":true,"radius":3,"pointStyle":"circle","nul":null,'
        '"und":"<undefined>","missing":"<undefined>","extra":1}',
      );
      expect(jsObjectKeys(result), [
        r'$shared',
        'radius',
        'pointStyle',
        'nul',
        'und',
        'missing',
        'extra',
      ]);
    });

    test('the prefixes', () {
      expect(
        _json(
          config.resolveNamedOptions(
            scopes,
            ['radius'],
            <String, Object?>{},
            ['point', ''],
          ),
        ),
        r'{"$shared":true,"radius":5}',
      );
      expect(
        _json(
          config.resolveNamedOptions(
            scopes,
            ['radius', 'borderColor'],
            <String, Object?>{},
            ['pointHover', 'hover', 'point', ''],
          ),
        ),
        r'{"$shared":true,"radius":4,"borderColor":"H"}',
      );
    });

    test('each call gives a new object', () {
      expect(
        identical(
          config.resolveNamedOptions(scopes, ['radius'], <String, Object?>{}),
          config.resolveNamedOptions(scopes, ['radius'], <String, Object?>{}),
        ),
        isFalse,
      );
    });

    test('a scriptable option calls the context function once', () {
      var calls = 0;
      final context = <String, Object?>{'index': 1.0};
      final scriptable = [
        <String, Object?>{
          'radius': (Object? c) => (jsGet(c, 'index')! as double) * 2,
          'other': 1.0,
          'borderColor': 'B',
          'hoverBorderColor': 'H',
          'backgroundColor': (Object? c, Object? o) => jsGet(o, 'borderColor'),
        },
      ];
      final result = config.resolveNamedOptions(
        scriptable,
        [
          'radius',
          'other',
        ],
        () {
          calls++;
          return context;
        },
      );
      expect(_json(result), r'{"$shared":false,"radius":2,"other":1}');
      expect(calls, 1);
    });

    test('the sub-resolver of a scriptable option has no hover prefix', () {
      final scriptable = [
        <String, Object?>{
          'borderColor': 'B',
          'hoverBorderColor': 'H',
          'backgroundColor': (Object? c, Object? o) => jsGet(o, 'borderColor'),
        },
      ];
      final context = <String, Object?>{'index': 1.0};
      expect(
        _json(
          config.resolveNamedOptions(
            scriptable,
            ['backgroundColor', 'borderColor'],
            context,
            ['hover', ''],
          ),
        ),
        r'{"$shared":false,"backgroundColor":"B","borderColor":"H"}',
      );
      expect(
        _json(
          config.resolveNamedOptions(
            scriptable,
            ['backgroundColor', 'borderColor'],
            context,
            ['Hover', 'HOVERx', 'x', ''],
          ),
        ),
        r'{"$shared":false,"backgroundColor":"B","borderColor":"B"}',
      );
    });

    test('indexable and nested scriptable options need the context', () {
      final context = <String, Object?>{'index': 4.0};
      expect(
        _json(
          config.resolveNamedOptions(
            [
              <String, Object?>{
                'radius': [1.0, 2.0, 3.0],
              },
            ],
            ['radius'],
            context,
          ),
        ),
        r'{"$shared":false,"radius":2}',
      );
      expect(
        _json(
          config.resolveNamedOptions(
            [
              <String, Object?>{'radius': <Object?>[]},
            ],
            ['radius'],
            context,
          ),
        ),
        r'{"$shared":false,"radius":[]}',
      );
      final font = config.resolveNamedOptions(
        [
          <String, Object?>{
            'font': <String, Object?>{
              'size': (Object? c) => 10 + (jsGet(c, 'index')! as double) / 2,
            },
          },
        ],
        ['font'],
        <String, Object?>{'index': 4.0},
      );
      expect(_json(font), r'{"$shared":false,"font":{"size":12}}');
      expect(
        config.resolveNamedOptions(
          [
            <String, Object?>{
              'font': <String, Object?>{
                'size': 3.0,
                'inner': <String, Object?>{'f': () => 1.0},
              },
            },
          ],
          ['font'],
          context,
        )[r'$shared'],
        isTrue,
      );
    });

    test('the descriptors of the scopes', () {
      final notScriptable = config.resolveNamedOptions(
        [
          <String, Object?>{'_scriptable': false, 'radius': () => 1.0},
        ],
        ['radius'],
        <String, Object?>{},
      );
      expect(notScriptable[r'$shared'], isTrue);
      expect(jsIsFunction(notScriptable['radius']), isTrue);
      expect(
        _json(
          config.resolveNamedOptions(
            [
              <String, Object?>{
                '_indexable': false,
                'radius': [1.0, 2.0],
              },
            ],
            ['radius'],
            <String, Object?>{'index': 1.0},
          ),
        ),
        r'{"$shared":true,"radius":[1,2]}',
      );
      expect(
        config.resolveNamedOptions(
          [
            <String, Object?>{
              '_scriptable': (String n) => n != 'radius',
              'radius': () => 1.0,
              'width': () => 2.0,
            },
          ],
          ['radius', 'width'],
          <String, Object?>{},
        )[r'$shared'],
        isFalse,
      );
      expect(
        config.resolveNamedOptions(
          [
            <String, Object?>{
              'onClick': () => 1.0,
              'events': ['a', 'b'],
            },
            defaults,
            descriptors,
          ],
          ['onClick', 'events'],
          <String, Object?>{'index': 1.0},
        )[r'$shared'],
        isTrue,
      );
    });

    test(r'empty names, duplicate names and $shared as a name', () {
      expect(
        _json(config.resolveNamedOptions(scopes, [], <String, Object?>{})),
        r'{"$shared":true}',
      );
      expect(
        _json(
          config.resolveNamedOptions(scopes, [
            'radius',
            'radius',
          ], <String, Object?>{}),
        ),
        r'{"$shared":true,"radius":3}',
      );
      expect(
        _json(
          config.resolveNamedOptions(
            [
              <String, Object?>{r'$shared': 'x'},
            ],
            [r'$shared'],
            <String, Object?>{},
          ),
        ),
        r'{"$shared":"x"}',
      );
      final scriptable = config.resolveNamedOptions(
        [
          <String, Object?>{r'$shared': 'x', 'a': () => 1.0},
        ],
        [r'$shared', 'a'],
        <String, Object?>{},
      );
      expect(jsObjectKeys(scriptable), [r'$shared', 'a']);
      expect(_json(scriptable), r'{"$shared":"x","a":1}');
      expect(
        jsObjectKeys(
          config.resolveNamedOptions(
            [
              <String, Object?>{'b': 1.0, '10': 2.0},
            ],
            ['b', '10'],
            <String, Object?>{},
          ),
        ),
        ['10', r'$shared', 'b'],
      );
    });
  });

  group('createResolver', () {
    test('caches the resolver of the scopes and the prefixes', () {
      final config = Config(<String, Object?>{'type': 'tbar'});
      final scopes = [
        <String, Object?>{'a': 1.0},
      ];
      final resolver = config.createResolver(scopes);
      expect(resolver, isA<helpers.Resolver>());
      expect(config.createResolver(scopes), same(resolver));
      expect(config.createResolver(scopes, undefined, ['']), same(resolver));
      expect(
        identical(
          config.createResolver(scopes, undefined, ['x', '']),
          resolver,
        ),
        isFalse,
      );
      expect(
        config.createResolver(scopes, undefined, ['x,y']),
        same(config.createResolver(scopes, undefined, ['x', 'y'])),
      );
      expect(
        identical(
          config.createResolver([
            <String, Object?>{'a': 1.0},
          ]),
          resolver,
        ),
        isFalse,
      );
      expect(jsObjectKeys(resolver), ['a']);
      final joined = config.createResolver(scopes, undefined, ['a', 'b']);
      expect(config.createResolver(scopes, undefined, ['a,b']), same(joined));
      expect(jsGet(joined, '_scopes'), same(scopes));
    });

    test('an object context gives a new context resolver', () {
      final config = Config(<String, Object?>{'type': 'tbar'});
      final scopes = [
        <String, Object?>{'a': 1.0},
      ];
      final resolver = config.createResolver(scopes);
      final context = config.createResolver(scopes, <String, Object?>{
        'index': 1.0,
      });
      expect(context, isA<helpers.ContextResolver>());
      expect(
        identical(
          config.createResolver(scopes, <String, Object?>{'index': 1.0}),
          context,
        ),
        isFalse,
      );
      expect(jsGet(context, '_proxy'), same(resolver));
      expect(jsGet(context, '_cacheable'), isFalse);
      expect(jsGet(resolver, '_cacheable'), isTrue);
      expect(context['a'], 1.0);
      expect(config.createResolver(scopes, 'abc'), same(resolver));
      expect(
        config.createResolver(scopes, () => <String, Object?>{}),
        same(resolver),
      );
    });

    test('the descriptor defaults', () {
      final config = Config(<String, Object?>{'type': 'tbar'});
      final resolver = config.createResolver(
        [<String, Object?>{}],
        <String, Object?>{'index': 1.0},
        [''],
        const helpers.DescriptorDefaults(
          scriptable: false,
          indexable: false,
          allKeys: true,
        ),
      );
      final descriptors =
          jsGet(resolver, '_descriptors')! as helpers.Descriptor;
      expect(
        [descriptors.scriptable, descriptors.indexable, descriptors.allKeys],
        [false, false, true],
      );
    });

    test('resolveNamedOptions and createResolver share the cache', () {
      final config = Config(<String, Object?>{'type': 'tbar'});
      final scopes = [
        <String, Object?>{
          'radius': [1.0, 2.0],
        },
      ];
      config.resolveNamedOptions(
        scopes,
        ['radius'],
        <String, Object?>{
          'index': 0.0,
        },
      );
      expect(
        config.createResolver(scopes),
        same(config.createResolver(scopes)),
      );
    });
  });

  group('caches and clearCache', () {
    setUp(_setUpScopeTypes);

    test('getOptionScopes caches the key lists of cachedKeys', () {
      final dataset = <String, Object?>{'data': <Object?>[]};
      final config = Config(<String, Object?>{
        'type': 'tbar',
        'data': <String, Object?>{
          'datasets': [dataset],
        },
      });
      final keys = config.datasetElementScopeKeys('tbar', 'tbar');
      final scopes = config.getOptionScopes(dataset, keys);
      expect(config.getOptionScopes(dataset, keys), same(scopes));
      final reset = config.getOptionScopes(dataset, keys, true);
      expect(identical(reset, scopes), isFalse);
      expect(config.getOptionScopes(dataset, keys), same(reset));
      final own = [
        ['datasets.tbar', ''],
      ];
      expect(
        identical(
          config.getOptionScopes(dataset, own),
          config.getOptionScopes(dataset, own),
        ),
        isFalse,
      );
      config.clearCache();
      expect(identical(config.getOptionScopes(dataset, keys), reset), isFalse);
    });

    test('clearCache and update clear the resolvers', () {
      final config = Config(<String, Object?>{'type': 'tbar'});
      final scopes = [
        <String, Object?>{'a': 1.0},
      ];
      final resolver = config.createResolver(scopes);
      config.clearCache();
      final second = config.createResolver(scopes);
      expect(identical(second, resolver), isFalse);
      config.update();
      expect(identical(config.createResolver(scopes), second), isFalse);
    });
  });

  group('adapt-config-objects', () {
    // Upstream writes the properties of an array or a function config, data
    // or options. The port needs a Map for the config and the options, and
    // throws a TypeError.
    test('an array config or options throws a TypeError', () {
      expect(() => Config(<Object?>[]), throwsA(isA<TypeError>()));
      expect(
        () => Config(<String, Object?>{'options': <Object?>[]}),
        throwsA(isA<TypeError>()),
      );
    });

    test('an array data gives a new Map with datasets and labels', () {
      // Upstream keeps the array and writes `datasets` and `labels` into it
      // (core.config.js:122-127). No Chart.js code reads its items.
      final array = <Object?>[];
      final config = Config(<String, Object?>{'data': array});
      expect(config.data, isNot(same(array)));
      expect(_json(config.data), '{"datasets":[],"labels":[]}');

      config.data = <Object?>[1, 2];
      expect(_json(config.data), '{"datasets":[],"labels":[]}');
    });

    test('a function data throws a TypeError', () {
      expect(
        () => Config(<String, Object?>{'data': () => 1}),
        throwsA(isA<TypeError>()),
      );
    });

    test('the options getter throws after a set of null', () {
      // Upstream returns null.
      final config = Config(<String, Object?>{})..options = null;
      expect(() => config.options, throwsA(isA<TypeError>()));
      config.update();
      expect(_json(config.options), '{"plugins":{},"scales":{}}');
    });

    test('the data getter throws after a write into the raw config', () {
      // Upstream returns the value.
      final raw = <String, Object?>{};
      final config = Config(raw);
      raw['data'] = 'abc';
      expect(() => config.data, throwsA(isA<TypeError>()));
    });

    test('a context that is not an object throws a TypeError', () {
      // Upstream gives the scriptable option the value: {radius: 'ctx'}.
      final config = Config(<String, Object?>{'type': 'tbar'});
      final scopes = [
        <String, Object?>{'radius': (Object? c) => c},
      ];
      expect(
        () => config.resolveNamedOptions(scopes, ['radius'], 'ctx'),
        throwsA(isA<TypeError>()),
      );
      expect(
        () => config.resolveNamedOptions(scopes, ['radius'], undefined),
        throwsA(isA<TypeError>()),
      );
    });

    test('additionalOptionScopes is a List of strings', () {
      // Upstream spreads a string into its characters. A key that is not a
      // string throws a TypeError in getOptionScopes.
      final config = Config(<String, Object?>{'type': 'k7bar'});
      expect(
        () => config.pluginScopeKeys(<String, Object?>{
          'id': 'a',
          'additionalOptionScopes': 'ab',
        }),
        throwsA(isA<TypeError>()),
      );
      expect(
        () => config.pluginScopeKeys(<String, Object?>{
          'id': 'b',
          'additionalOptionScopes': [5.0],
        }),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('adapt-typed-element-options', () {
    // Chart.js ADR 0021, section 7. main() registers the four element
    // classes through a new TypedRegistry. The names of each element type
    // are the keys of `defaults.elements.<id>`: the keys of its defaults,
    // then the keys of its defaultRoutes, as registerDefaults gives them
    // (core.typedRegistry.js:84-113). The element scopes are
    // `defaults.elements.<id>` and `descriptors.elements.<id>`.
    final ids = [PointElement.id, LineElement.id, BarElement.id, ArcElement.id];

    /// `defaults.elements.<id>`.
    Map<String, Object?> elementDefaultsOf(String id) =>
        jsGet(defaults['elements'], id)! as Map<String, Object?>;

    /// `descriptors.elements.<id>`, or Dart null for an element type
    /// without descriptors.
    Object? elementDescriptorsOf(String id) {
      final value = jsGet(descriptors['elements'], id);
      return identical(value, undefined) ? null : value;
    }

    /// The names of the element type [id]:
    /// `Object.keys(defaults.elements[id])`.
    List<String> namesOf(String id) => jsObjectKeys(elementDefaultsOf(id));

    final knownKeys = <String, List<String>>{
      PointElement.id: PointOptions.knownKeys,
      LineElement.id: LineOptions.knownKeys,
      BarElement.id: BarOptions.knownKeys,
      ArcElement.id: ArcOptions.knownKeys,
    };

    /// The scopes of the element type: [first], the element defaults, the
    /// defaults, the element descriptors and the descriptors, in the order
    /// of getOptionScopes. The registry describes the element descriptors
    /// under `elements.<id>` (core.typedRegistry.js:68-70).
    List<Object?> scopesOf(
      Map<String, Object?> first,
      Map<String, Object?> elementDefaults,
      Object? elementDescriptors,
    ) => [first, elementDefaults, defaults, ?elementDescriptors, descriptors];

    /// The two runs of resolveNamedOptions for [id], [scopes] and [names],
    /// typed and plain, and the `into` object of the typed run.
    (Map<String, Object?>, Map<String, Object?>, Map<String, Object?>) runs(
      String id,
      List<Object?> scopes,
      List<String> names,
    ) {
      final config = Config(<String, Object?>{'type': 'tbar'});
      final into = createElementOptions(id);
      final context = <String, Object?>{'index': 1.0};
      final prefixes = [id, ''];
      final typed = config.resolveNamedOptions(
        scopes,
        names,
        context,
        prefixes,
        into,
      );
      final plain = config.resolveNamedOptions(
        scopes,
        names,
        context,
        prefixes,
      );
      return (typed, plain, into);
    }

    test('the names are the known keys of the typed class', () {
      // The registry pin: the only property of Chart.js ADR 0020 that the
      // key order needs.
      for (final id in ids) {
        expect(
          namesOf(id),
          knownKeys[id]!
              .where((k) => k != r'$shared' && k != r'$animations')
              .where((k) => k != 'segment')
              .toList(),
          reason: id,
        );
      }
    });

    test('static scopes: the typed result is into', () {
      for (final id in ids) {
        final names = namesOf(id);
        final scopes = scopesOf(
          <String, Object?>{},
          elementDefaultsOf(id),
          elementDescriptorsOf(id),
        );
        final (typed, plain, into) = runs(id, scopes, names);
        expect(typed, same(into), reason: id);
        expect(typed, isA<ElementOptions>(), reason: id);
        expect(plain, isNot(isA<ElementOptions>()), reason: id);
        expect(typed[r'$shared'], isTrue, reason: id);
        expect(jsObjectKeys(typed), [r'$shared', ...names], reason: id);
        expect(_json(typed), _json(plain), reason: id);
        expect(jsObjectIsFrozen(typed), isFalse, reason: id);
      }
    });

    test('a scriptable, an indexable, null and undefined', () {
      for (final id in ids) {
        final names = namesOf(id);
        final first = names.first;
        final cases = <(Map<String, Object?>, bool)>[
          ({first: (Object? c) => 7.0}, false),
          (
            {
              first: [1.0, 2.0],
            },
            false,
          ),
          ({first: null}, true),
          ({first: undefined}, true),
        ];
        for (final (scope, shared) in cases) {
          final scopes = scopesOf(
            scope,
            elementDefaultsOf(id),
            elementDescriptorsOf(id),
          );
          final (typed, plain, into) = runs(id, scopes, names);
          final reason = '$id ${_json(scope)}';
          expect(typed, same(into), reason: reason);
          expect(jsObjectKeys(typed), [r'$shared', ...names], reason: reason);
          expect(_json(typed), _json(plain), reason: reason);
          expect(typed[r'$shared'], shared, reason: reason);
        }
      }
    });

    test('a default key added after the registration is the last key', () {
      for (final id in ids) {
        elementDefaultsOf(id)['addedKey'] = 5.0;
        final names = namesOf(id);
        expect(names.last, 'addedKey', reason: id);
        final scopes = scopesOf(
          <String, Object?>{},
          elementDefaultsOf(id),
          elementDescriptorsOf(id),
        );
        final (typed, plain, _) = runs(id, scopes, names);
        expect(jsObjectKeys(typed).last, 'addedKey', reason: id);
        expect(jsObjectKeys(plain).last, 'addedKey', reason: id);
        expect(_json(typed), _json(plain), reason: id);
      }
    });

    test('a known key first in the names keeps its place in the class', () {
      // The P6 pin. A default that a program writes before the registration
      // comes first in the names (Chart.js ADR 0021, probe E1, P6). The test
      // removes the entry `point` of `defaults.elements`, writes the
      // default, and registers PointElement through a second new
      // TypedRegistry. The plain run gives the order of the names. The typed
      // run gives the order of the known keys. The restore puts back
      // `defaults` after the test.
      final names = namesOf(PointElement.id);
      (defaults['elements']! as Map<String, Object?>).remove(PointElement.id);
      defaults.set('elements.point', <String, Object?>{'radius': 9.0});
      TypedRegistry(Element.jsClass, 'elements').register(PointElement.jsClass);
      final moved = namesOf(PointElement.id);
      expect(moved, ['radius', ...names.where((n) => n != 'radius')]);
      final scopes = scopesOf(
        <String, Object?>{},
        elementDefaultsOf(PointElement.id),
        elementDescriptorsOf(PointElement.id),
      );
      final (typed, plain, _) = runs(PointElement.id, scopes, moved);
      expect(jsObjectKeys(plain), [r'$shared', ...moved]);
      expect(jsObjectKeys(typed), [r'$shared', ...names]);
      for (final key in moved) {
        expect(_json(typed[key]), _json(plain[key]), reason: key);
      }
    });

    test('another element type id gives GenericElementOptions', () {
      final names = ['b', 'a', '10'];
      final scopes = [
        <String, Object?>{'a': 1.0, 'b': 2.0, '10': 3.0},
      ];
      final (typed, plain, into) = runs('custom', scopes, names);
      expect(typed, isA<GenericElementOptions>());
      expect(typed, same(into));
      expect(jsObjectKeys(typed), jsObjectKeys(plain));
      expect(_json(typed), _json(plain));
    });

    test('names of no element type, with into null, give a plain Map', () {
      final config = Config(<String, Object?>{'type': 'tbar'});
      final result = config.resolveNamedOptions(
        [
          <String, Object?>{'x': 1.0},
        ],
        ['x'],
        <String, Object?>{},
      );
      expect(result, isNot(isA<ElementOptions>()));
      expect(result, isA<Map<String, Object?>>());
      expect(_json(result), r'{"$shared":true,"x":1}');
    });
  });

  group('theme-H0', () {
    // theming.md §8 test 1 at the config level: no theme equals upstream.
    test(r'the key is $theme', () {
      expect(themeConfigKey, r'$theme');
    });

    test('a value that is not a Map is no theme', () {
      defaults.override('tthm', <String, Object?>{});
      for (final theme in [null, 'not a map', 5.0, undefined]) {
        final config = Config(<String, Object?>{
          'type': 'tthm',
          themeConfigKey: theme,
        });
        final label = _labeller([
          (config.options, 'options'),
          (overrides['tthm'], 'overrides.tthm'),
          (defaults, 'defaults'),
          (descriptors, 'descriptors'),
        ]);
        expect(config.chartOptionScopes().map(label), [
          'options',
          'overrides.tthm',
          '{}#0',
          '?{"type":"tthm"}',
          'defaults',
          'descriptors',
        ], reason: '$theme');
      }
    });

    test('initConfig keeps the theme in the config', () {
      final theme = <String, Object?>{'color': 'T'};
      final raw = <String, Object?>{themeConfigKey: theme};
      Config(raw);
      expect(raw[themeConfigKey], same(theme));
      expect(jsObjectKeys(raw), [r'$theme', 'data', 'options']);
    });

    // The public reader of Chart.js ADR 0042 for hunk H5 of plugin.colors.
    test('chartThemeOf gives the theme map of a Config', () {
      final theme = <String, Object?>{'color': 'T'};
      final config = Config(<String, Object?>{themeConfigKey: theme});
      expect(chartThemeOf(config), same(theme));
    });

    test('chartThemeOf gives null for no theme, a theme that is not a Map '
        'and a configuration that is not a Config', () {
      expect(chartThemeOf(Config(<String, Object?>{})), isNull);
      for (final theme in [null, 'not a map', 5.0, undefined, <Object?>[]]) {
        final config = Config(<String, Object?>{themeConfigKey: theme});
        expect(chartThemeOf(config), isNull, reason: '$theme');
      }
      expect(chartThemeOf(_OtherConfiguration()), isNull);
    });
  });

  group('theme-H2', () {
    late Map<String, Object?> dataset;
    late Map<String, Object?> options;
    late Map<String, Object?> theme;
    late String Function(Object?) label;

    setUp(() {
      defaults
        ..override('tthm', <String, Object?>{
          'elements': <String, Object?>{
            'tbar': <String, Object?>{'o': 1.0},
          },
        })
        ..set('elements.tbar', <String, Object?>{'d': 1.0});
      dataset = <String, Object?>{'data': <Object?>[]};
      options = <String, Object?>{
        'elements': <String, Object?>{
          'tbar': <String, Object?>{'u': 1.0},
        },
      };
      theme = <String, Object?>{
        'elements': <String, Object?>{
          'tbar': <String, Object?>{'t': 1.0},
        },
        'datasets': <String, Object?>{
          'tthm': <String, Object?>{
            'elements': <String, Object?>{
              'tbar': <String, Object?>{'t': 2.0},
            },
          },
        },
        'transitions': <String, Object?>{
          'theme': <String, Object?>{
            'animation': <String, Object?>{'duration': 200.0},
          },
        },
        'plugins': <String, Object?>{
          'tp': <String, Object?>{'t': 3.0},
        },
      };
      label = _labeller([
        (dataset, 'dataset'),
        (options, 'options'),
        (_at(options, 'elements.tbar'), 'options.elements.tbar'),
        (overrides['tthm'], 'overrides.tthm'),
        (_at(overrides, 'tthm.elements.tbar'), 'overrides.tthm.elements.tbar'),
        (theme, 'theme'),
        (_at(theme, 'elements.tbar'), 'theme.elements.tbar'),
        (_at(theme, 'datasets.tthm'), 'theme.datasets.tthm'),
        (
          _at(theme, 'datasets.tthm.elements.tbar'),
          'theme.datasets.tthm.elements.tbar',
        ),
        (_at(theme, 'transitions.theme'), 'theme.transitions.theme'),
        (_at(theme, 'plugins.tp'), 'theme.plugins.tp'),
        (defaults, 'defaults'),
        (_at(defaults, 'elements.tbar'), 'defaults.elements.tbar'),
        (descriptors, 'descriptors'),
      ]);
    });

    Config config({bool themed = true}) => Config(<String, Object?>{
      'type': 'tthm',
      'data': <String, Object?>{
        'datasets': [dataset],
      },
      'options': options,
      if (themed) themeConfigKey: theme,
    });

    test('no theme adds no scope', () {
      final c = config(themed: false);
      expect(
        c
            .getOptionScopes(dataset, c.datasetElementScopeKeys('tthm', 'tbar'))
            .map(label),
        [
          'dataset',
          'options.elements.tbar',
          'options',
          'overrides.tthm.elements.tbar',
          'overrides.tthm',
          'defaults.elements.tbar',
          'defaults',
          'descriptors',
        ],
      );
    });

    test('the theme scopes come between the overrides and the defaults', () {
      final c = config();
      expect(
        c
            .getOptionScopes(dataset, c.datasetElementScopeKeys('tthm', 'tbar'))
            .map(label),
        [
          'dataset',
          'options.elements.tbar',
          'options',
          'overrides.tthm.elements.tbar',
          'overrides.tthm',
          'theme.datasets.tthm.elements.tbar',
          'theme.datasets.tthm',
          'theme.elements.tbar',
          'theme',
          'defaults.elements.tbar',
          'defaults',
          'descriptors',
        ],
      );
      expect(
        c.getOptionScopes(dataset, c.datasetScopeKeys('tthm')).map(label),
        [
          'dataset',
          'options',
          'overrides.tthm',
          'theme.datasets.tthm',
          'theme',
          'defaults',
          'descriptors',
        ],
      );
      expect(
        c
            .getOptionScopes(
              dataset,
              c.datasetAnimationScopeKeys('tthm', 'theme'),
            )
            .map(label),
        [
          'dataset',
          'theme.transitions.theme',
          'options',
          'overrides.tthm',
          'theme.datasets.tthm',
          'theme',
          'defaults',
          'descriptors',
        ],
      );
      expect(
        c
            .getOptionScopes(
              undefined,
              c.pluginScopeKeys(<String, Object?>{'id': 'tp'}),
            )
            .map(label),
        ['theme.plugins.tp'],
      );
    });

    test('the element precedence of theming.md §3.2', () {
      // theming.md §8 test 2, the element rows. The plain value is the
      // value without a theme.
      String run(List<String> levels, {bool themeRoot = false}) {
        overrides.remove('tthm');
        defaults.set('elements.tbar', <String, Object?>{});
        (_at(defaults, 'elements')! as Map<String, Object?>)['tbar'] =
            <String, Object?>{};
        final dataset = <String, Object?>{'data': <Object?>[]};
        final options = <String, Object?>{};
        final theme = <String, Object?>{};
        if (levels.contains('dataset')) {
          dataset['backgroundColor'] = 'L1-dataset';
        }
        if (levels.contains('options')) {
          options['elements'] = <String, Object?>{
            'tbar': <String, Object?>{'backgroundColor': 'L2-options'},
          };
        }
        if (levels.contains('overrides')) {
          defaults.override('tthm', <String, Object?>{
            'elements': <String, Object?>{
              'tbar': <String, Object?>{'backgroundColor': 'L3-overrides'},
            },
          });
        }
        if (levels.contains('theme')) {
          theme['elements'] = <String, Object?>{
            'tbar': <String, Object?>{'backgroundColor': 'L4-theme'},
          };
        }
        if (themeRoot) theme['backgroundColor'] = 'T-root';
        if (levels.contains('defaults')) {
          (_at(defaults, 'elements.tbar')!
                  as Map<String, Object?>)['backgroundColor'] =
              'L5-defaults';
        }
        final c = Config(<String, Object?>{
          'type': 'tthm',
          'data': <String, Object?>{
            'datasets': [dataset],
          },
          'options': options,
          if (levels.contains('theme') || themeRoot) themeConfigKey: theme,
        });
        final scopes = c.getOptionScopes(
          dataset,
          c.datasetElementScopeKeys('tthm', 'tbar'),
        );
        return c.resolveNamedOptions(
              scopes,
              ['backgroundColor'],
              <String, Object?>{},
              ['tbar', ''],
            )['backgroundColor']!
            as String;
      }

      const all = ['dataset', 'options', 'overrides', 'theme', 'defaults'];
      expect(run(all), 'L1-dataset');
      expect(run(all.sublist(1)), 'L2-options');
      expect(run(all.sublist(2)), 'L3-overrides');
      expect(run(all.sublist(3)), 'L4-theme');
      expect(run(all.sublist(4)), 'L5-defaults');
      expect(run(const []), 'rgba(0,0,0,0.1)');
      // Without the theme level, each run equals the upstream run.
      expect(run(['overrides', 'defaults']), 'L3-overrides');
      expect(run(['defaults']), 'L5-defaults');
      // The theme root beats defaults.elements.tbar: the compiler never
      // emits a root backgroundColor (theming.md §3.3).
      expect(run(['defaults'], themeRoot: true), 'T-root');
      expect(run(['theme', 'defaults'], themeRoot: true), 'L4-theme');
    });

    test('the lookup is prefix-major', () {
      overrides.remove('tthm');
      final dataset = <String, Object?>{'data': <Object?>[]};
      final c = Config(<String, Object?>{
        'type': 'tthm',
        'data': <String, Object?>{
          'datasets': [dataset],
        },
        'options': <String, Object?>{'backgroundColor': 'user'},
        themeConfigKey: <String, Object?>{'tbarBackgroundColor': 'theme'},
      });
      final scopes = c.getOptionScopes(
        dataset,
        c.datasetElementScopeKeys('tthm', 'tbar'),
      );
      expect(
        c.resolveNamedOptions(
          scopes,
          ['backgroundColor'],
          <String, Object?>{},
          ['tbar', ''],
        )['backgroundColor'],
        'theme',
      );
    });

    test('the defaults derive the hover color from the theme color', () {
      overrides.remove('tthm');
      (_at(defaults, 'elements')! as Map<String, Object?>)['tbar'] =
          <String, Object?>{};
      final dataset = <String, Object?>{'data': <Object?>[]};
      final c = Config(<String, Object?>{
        'type': 'tthm',
        'data': <String, Object?>{
          'datasets': [dataset],
        },
        'options': <String, Object?>{},
        themeConfigKey: <String, Object?>{
          'elements': <String, Object?>{
            'tbar': <String, Object?>{'backgroundColor': 'rgb(200, 0, 0)'},
          },
        },
      });
      final scopes = c.getOptionScopes(
        dataset,
        c.datasetElementScopeKeys('tthm', 'tbar'),
      );
      expect(
        _json(
          c.resolveNamedOptions(
            scopes,
            ['backgroundColor', 'hoverBackgroundColor'],
            <String, Object?>{},
            ['tbarHover', 'hover', 'tbar', ''],
          ),
        ),
        r'{"$shared":false,"backgroundColor":"#B40000",'
        '"hoverBackgroundColor":"#B40000"}',
      );
    });

    test('the plugin precedence of theming.md §3.2', () {
      // theming.md §8 test 2, the plugin rows.
      Object? run(List<String> levels) {
        overrides.remove('tthm');
        (defaults['plugins']! as Map<String, Object?>).remove('tp');
        final options = <String, Object?>{'plugins': <String, Object?>{}};
        final theme = <String, Object?>{};
        if (levels.contains('user')) {
          (options['plugins']! as Map<String, Object?>)['tp'] =
              <String, Object?>{'k': 'P1-user'};
        }
        if (levels.contains('overrides')) {
          defaults.override('tthm', <String, Object?>{
            'plugins': <String, Object?>{
              'tp': <String, Object?>{'k': 'P2-overrides'},
            },
          });
        }
        if (levels.contains('theme')) {
          theme['plugins'] = <String, Object?>{
            'tp': <String, Object?>{'k': 'P3-theme'},
          };
        }
        if (levels.contains('defaults')) {
          defaults.set('plugins.tp', <String, Object?>{'k': 'P4-defaults'});
        }
        final c = Config(<String, Object?>{
          'type': 'tthm',
          'options': options,
          themeConfigKey: theme,
        });
        final opts = _at(c.options, 'plugins.tp');
        final scopes = c.getOptionScopes(
          opts,
          c.pluginScopeKeys(<String, Object?>{'id': 'tp'}),
        );
        final resolver = c.createResolver(
          scopes,
          <String, Object?>{},
          [''],
          const helpers.DescriptorDefaults(
            scriptable: false,
            indexable: false,
            allKeys: true,
          ),
        );
        return resolver['k'];
      }

      const all = ['user', 'overrides', 'theme', 'defaults'];
      expect(run(all), 'P1-user');
      expect(run(all.sublist(1)), 'P2-overrides');
      expect(run(all.sublist(2)), 'P3-theme');
      expect(run(all.sublist(3)), 'P4-defaults');
      expect(run(const []), same(undefined));
    });
  });

  group('theme-H3', () {
    test('no theme adds no scope', () {
      defaults.override('tthm', <String, Object?>{'k': 1.0});
      final config = Config(<String, Object?>{'type': 'tthm'});
      final label = _labeller([
        (config.options, 'options'),
        (overrides['tthm'], 'overrides.tthm'),
        (defaults, 'defaults'),
        (descriptors, 'descriptors'),
      ]);
      expect(config.chartOptionScopes().map(label), [
        'options',
        'overrides.tthm',
        '{}#0',
        '?{"type":"tthm"}',
        'defaults',
        'descriptors',
      ]);
    });

    test('the theme comes after the type overrides', () {
      defaults.override('tthm', <String, Object?>{'k': 1.0});
      final theme = <String, Object?>{'color': 'T'};
      final config = Config(<String, Object?>{
        'type': 'tthm',
        themeConfigKey: theme,
      });
      final label = _labeller([
        (config.options, 'options'),
        (overrides['tthm'], 'overrides.tthm'),
        (theme, 'theme'),
        (defaults, 'defaults'),
        (descriptors, 'descriptors'),
      ]);
      expect(config.chartOptionScopes().map(label), [
        'options',
        'overrides.tthm',
        'theme',
        '{}#0',
        '?{"type":"tthm"}',
        'defaults',
        'descriptors',
      ]);
    });

    test('the chart-level precedence of theming.md §3.2', () {
      // theming.md §8 test 2, the chart-level rows.
      Object? run(List<String> levels) {
        overrides.remove('tthm');
        (defaults['datasets']! as Map<String, Object?>).remove('tthm');
        final options = <String, Object?>{};
        final theme = <String, Object?>{};
        if (levels.contains('user')) options['k'] = 'C1-user';
        if (levels.contains('overrides')) {
          defaults.override('tthm', <String, Object?>{'k': 'C2-overrides'});
        }
        if (levels.contains('theme')) theme['k'] = 'C3-theme';
        if (levels.contains('datasetDefaults')) {
          defaults.set('datasets.tthm', <String, Object?>{
            'k': 'C4-dataset-defaults',
          });
        }
        if (levels.contains('defaults')) defaults['k'] = 'C5-defaults';
        final config = Config(<String, Object?>{
          'type': 'tthm',
          'options': options,
          themeConfigKey: theme,
        });
        final value = config.createResolver(
          config.chartOptionScopes(),
          <String, Object?>{},
        )['k'];
        defaults.remove('k');
        return value;
      }

      const all = ['user', 'overrides', 'theme', 'datasetDefaults', 'defaults'];
      expect(run(all), 'C1-user');
      expect(run(all.sublist(1)), 'C2-overrides');
      expect(run(all.sublist(2)), 'C3-theme');
      expect(run(all.sublist(3)), 'C4-dataset-defaults');
      expect(run(all.sublist(4)), 'C5-defaults');
      expect(run(const []), same(undefined));
    });
  });

  group('theme-H1', () {
    setUp(() {
      defaults.set('scales.tlin', <String, Object?>{'axis': 'y'});
    });

    test('the scale precedence of theming.md §3.2', () {
      // theming.md §8 test 2, the scale rows.
      Object? run(List<String> levels) {
        overrides
          ..remove('tthm')
          ..remove('tthm2');
        (defaults['scales']! as Map<String, Object?>)['tlin'] =
            <String, Object?>{'axis': 'y'};
        final scale = defaults['scale']! as Map<String, Object?>;
        defaults
          ..override('tthm', <String, Object?>{
            'scales': <String, Object?>{
              '_index_': <String, Object?>{'type': 'tlin'},
              '_value_': <String, Object?>{'type': 'tlin'},
            },
          })
          ..override('tthm2', <String, Object?>{
            'scales': <String, Object?>{
              '_index_': <String, Object?>{'type': 'tlin'},
            },
          });
        final x = <String, Object?>{};
        final themeScales = <String, Object?>{};
        final themeScale = <String, Object?>{};
        if (levels.contains('user')) x['tc'] = 'S1-user';
        if (levels.contains('chartOverride')) {
          (_at(overrides, 'tthm.scales._index_')!
                  as Map<String, Object?>)['tc'] =
              'S2-chart-override';
        }
        if (levels.contains('datasetOverride')) {
          (_at(overrides, 'tthm2.scales._index_')!
                  as Map<String, Object?>)['tc'] =
              'S3-dataset-override';
        }
        if (levels.contains('themeType')) {
          themeScales['tlin'] = <String, Object?>{'tc': 'S4-theme-type'};
        }
        if (levels.contains('themeScale')) themeScale['tc'] = 'S5-theme-scale';
        if (levels.contains('defaultsType')) {
          (_at(defaults, 'scales.tlin')! as Map<String, Object?>)['tc'] =
              'S6-defaults-type';
        }
        if (levels.contains('defaultsScale')) scale['tc'] = 'S7-defaults-scale';
        final config = Config(<String, Object?>{
          'type': 'tthm',
          'data': <String, Object?>{
            'datasets': [
              <String, Object?>{'type': 'tthm2'},
            ],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{'x': x},
          },
          themeConfigKey: <String, Object?>{
            'scales': themeScales,
            'scale': themeScale,
          },
        });
        scale.remove('tc');
        return _at(config.options, 'scales.x.tc');
      }

      const all = [
        'user',
        'chartOverride',
        'datasetOverride',
        'themeType',
        'themeScale',
        'defaultsType',
        'defaultsScale',
      ];
      expect(run(all), 'S1-user');
      expect(run(all.sublist(1)), 'S2-chart-override');
      expect(run(all.sublist(2)), 'S3-dataset-override');
      expect(run(all.sublist(3)), 'S4-theme-type');
      expect(run(all.sublist(4)), 'S5-theme-scale');
      expect(run(all.sublist(5)), 'S6-defaults-type');
      expect(run(all.sublist(6)), 'S7-defaults-scale');
      expect(run(const []), same(undefined));
    });

    test('the theme fills the nested keys first', () {
      defaults.override('tthm', <String, Object?>{
        'scales': <String, Object?>{
          '_index_': <String, Object?>{'type': 'tlin'},
        },
      });
      Map<String, Object?> raw({required bool themed}) => {
        'type': 'tthm',
        'data': <String, Object?>{
          'datasets': [<String, Object?>{}],
        },
        'options': <String, Object?>{
          'scales': <String, Object?>{
            'x': <String, Object?>{
              'grid': <String, Object?>{'lineWidth': 3.0},
            },
          },
        },
        if (themed)
          themeConfigKey: <String, Object?>{
            'scales': <String, Object?>{
              'tlin': <String, Object?>{
                'grid': <String, Object?>{'color': 'theme-grid'},
              },
            },
            'scale': <String, Object?>{
              'grid': <String, Object?>{
                'color': 'theme-scale-grid',
                'tickColor': 'theme-tick',
              },
              'ticks': <String, Object?>{'color': 'theme-ticks'},
            },
          },
      };
      final themed = Config(raw(themed: true));
      expect(
        _json(_at(themed.options, 'scales.x.grid')),
        '{"lineWidth":3,"color":"theme-grid","tickColor":"theme-tick",'
        '"display":true,"drawOnChartArea":true,"drawTicks":true,'
        '"tickLength":8,"tickWidth":"<fn>","offset":false}',
      );
      expect(_at(themed.options, 'scales.x.ticks.color'), 'theme-ticks');
      expect(
        jsObjectKeys(_at(themed.options, 'scales.x')! as Map<String, Object?>),
        [
          'axis',
          'grid',
          'type',
          'ticks',
          'display',
          'offset',
          'reverse',
          'beginAtZero',
          'bounds',
          'clip',
          'grace',
          'border',
          'title',
        ],
      );
      // No theme equals upstream.
      final plain = Config(raw(themed: false));
      expect(
        _json(_at(plain.options, 'scales.x.grid')),
        '{"lineWidth":3,"display":true,"drawOnChartArea":true,'
        '"drawTicks":true,"tickLength":8,"tickWidth":"<fn>",'
        '"tickColor":"<fn>","offset":false,"color":"rgba(0,0,0,0.1)"}',
      );
      expect(
        jsObjectKeys(_at(plain.options, 'scales.x')! as Map<String, Object?>),
        [
          'axis',
          'grid',
          'type',
          'display',
          'offset',
          'reverse',
          'beginAtZero',
          'bounds',
          'clip',
          'grace',
          'border',
          'title',
          'ticks',
        ],
      );
    });

    test('a theme without scales, and scales that are not a Map', () {
      defaults.override('tthm', <String, Object?>{
        'scales': <String, Object?>{
          '_index_': <String, Object?>{'type': 'tlin'},
        },
      });
      Object? tc(Map<String, Object?> theme) => _at(
        Config(<String, Object?>{
          'type': 'tthm',
          'data': <String, Object?>{
            'datasets': [<String, Object?>{}],
          },
          'options': <String, Object?>{},
          themeConfigKey: theme,
        }).options,
        'scales.x.tc',
      );
      expect(
        tc(<String, Object?>{
          'scale': <String, Object?>{'tc': 'only-scale'},
        }),
        'only-scale',
      );
      expect(
        tc(<String, Object?>{
          'scales': 5.0,
          'scale': <String, Object?>{'tc': 'scale-5'},
        }),
        'scale-5',
      );
    });

    test('a theme scale key creates no axis', () {
      final config = Config(<String, Object?>{
        'type': 'tnone',
        'data': <String, Object?>{
          'datasets': [<String, Object?>{}],
        },
        'options': <String, Object?>{},
        themeConfigKey: <String, Object?>{
          'scales': <String, Object?>{
            'x': <String, Object?>{'tc': 1.0},
            'tlin': <String, Object?>{'tc': 2.0},
          },
        },
      });
      expect(config.options['scales'], <String, Object?>{});
    });
  });
}
