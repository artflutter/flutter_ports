// Original code, not ported from Chart.js: realistic inputs for the benchmarks.

/// Inputs that mirror what Chart.js builds for a bar chart: the registered
/// bar defaults, the option scopes of a bar element, a chart config with
/// three datasets of 100 points, and the data contexts.
///
/// The scope list is the one that `Config.getOptionScopes` builds for
/// `datasetElementScopeKeys('bar', 'bar')` (`core.config.js:252`, `:296`):
/// the dataset, the chart options, `overrides.bar`, `defaults.datasets.bar`,
/// `defaults.elements.bar`, `defaults` and `descriptors`.
library;

import 'package:flutter_chartjs/src/core/core.defaults.dart';
import 'package:flutter_chartjs/src/helpers/helpers.options.dart';
import 'package:flutter_chartjs/src/js/js_array.dart';
import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/js/js_object.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:flutter_chartjs/src/types/basic.dart';

bool _registered = false;

/// Registers the bar controller and the bar element defaults once, as
/// `registry.add(BarController, BarElement)` does: `defaults.set` of their
/// `defaults`, `defaults.route` of the element `defaultRoutes` and
/// `defaults.override` of the controller `overrides`
/// (`core.registry.js`, `core.typedRegistry.js:69-93`).
void registerBarDefaults() {
  if (_registered) return;
  _registered = true;
  defaults
    // element.bar.js:148 BarElement.defaults.
    ..set('elements.bar', <String, Object?>{
      'borderSkipped': 'start',
      'borderWidth': 0.0,
      'borderRadius': 0.0,
      'inflateAmount': 'auto',
      'pointStyle': undefined,
    })
    // element.bar.js:159 BarElement.defaultRoutes.
    ..route('elements.bar', 'backgroundColor', '', 'backgroundColor')
    ..route('elements.bar', 'borderColor', '', 'borderColor')
    // controller.bar.js:265 BarController.defaults.
    ..set('datasets.bar', <String, Object?>{
      'datasetElementType': false,
      'dataElementType': 'bar',
      'categoryPercentage': 0.8,
      'barPercentage': 0.9,
      'grouped': true,
      'animations': <String, Object?>{
        'numbers': <String, Object?>{
          'type': 'number',
          'properties': <Object?>['x', 'y', 'base', 'width', 'height'],
        },
      },
    })
    // controller.bar.js:284 BarController.overrides.
    ..override('bar', <String, Object?>{
      'scales': <String, Object?>{
        '_index_': <String, Object?>{
          'type': 'category',
          'offset': true,
          'grid': <String, Object?>{'offset': true},
        },
        '_value_': <String, Object?>{'type': 'linear', 'beginAtZero': true},
      },
    });
}

/// A dataset with static options.
AnyObject staticBarDataset(int index) => <String, Object?>{
  'label': 'Dataset $index',
  'data': <Object?>[for (var i = 0; i < 100; i++) (i * 7 % 50).toDouble()],
  'backgroundColor': 'rgba(255, 99, 132, 0.5)',
  'borderColor': 'rgb(255, 99, 132)',
  'borderWidth': 1.0,
};

/// A dataset with scriptable and indexable options, as Chart.js samples
/// write them: a function of the context for `backgroundColor`, a function
/// of the context and the options for `borderWidth`, and an array for
/// `borderColor`.
AnyObject scriptableBarDataset(int index) => <String, Object?>{
  'label': 'Dataset $index',
  'data': <Object?>[for (var i = 0; i < 100; i++) (i * 7 % 50).toDouble()],
  'backgroundColor': (Object? ctx) =>
      jsToNumber(jsGet(ctx, 'dataIndex')) % 2 == 0
      ? 'rgba(255, 99, 132, 0.5)'
      : 'rgba(54, 162, 235, 0.5)',
  'borderColor': <Object?>['#ff6384', '#36a2eb', '#ffce56'],
  'borderWidth': (Object? ctx, Object? options) =>
      jsTruthy(jsGet(ctx, 'active')) ? 2.0 : 1.0,
};

/// The chart options of the bar chart config.
AnyObject barChartOptions() => <String, Object?>{
  'responsive': true,
  'maintainAspectRatio': false,
  'indexAxis': 'x',
  'scales': <String, Object?>{
    'x': <String, Object?>{
      'type': 'category',
      'grid': <String, Object?>{'display': false},
      'ticks': <String, Object?>{'maxRotation': 0.0, 'autoSkip': true},
    },
    'y': <String, Object?>{
      'type': 'linear',
      'beginAtZero': true,
      'ticks': <String, Object?>{
        'stepSize': 10.0,
        'font': <String, Object?>{'size': 12.0, 'weight': 'bold'},
      },
      'title': <String, Object?>{'display': true, 'text': 'Value'},
    },
  },
  'plugins': <String, Object?>{
    'legend': <String, Object?>{
      'position': 'top',
      'labels': <String, Object?>{'usePointStyle': true, 'boxWidth': 12.0},
    },
    'title': <String, Object?>{'display': true, 'text': 'Bar chart'},
    'tooltip': <String, Object?>{
      'mode': 'index',
      'intersect': false,
      'padding': <String, Object?>{'top': 6.0, 'bottom': 6.0},
    },
  },
  'animation': <String, Object?>{'duration': 400.0, 'easing': 'easeOutQuart'},
};

/// A bar chart config with three datasets of 100 points, scales and
/// plugins.
AnyObject barChartConfig() => <String, Object?>{
  'type': 'bar',
  'data': <String, Object?>{
    'labels': <Object?>[for (var i = 0; i < 100; i++) 'Label $i'],
    'datasets': <Object?>[for (var d = 0; d < 3; d++) staticBarDataset(d)],
  },
  'options': barChartOptions(),
};

/// The option scopes of a bar element of [dataset] in a chart with
/// [options] (`core.config.js:296`, `getOptionScopes`).
List<Object?> barElementScopes(AnyObject dataset, AnyObject options) {
  registerBarDefaults();
  return <Object?>[
    dataset,
    options,
    overrides['bar'],
    jsGet(defaults['datasets'], 'bar'),
    jsGet(defaults['elements'], 'bar'),
    defaults,
    descriptors,
  ];
}

/// The option names of a bar element: `Object.keys(defaults.elements.bar)`
/// (`core.datasetController.js:817`) and the three dataset options of the
/// bar ruler.
List<String> barOptionNames() {
  registerBarDefaults();
  return <String>[
    ...jsObjectKeys(jsGet(defaults['elements'], 'bar')! as AnyObject),
    'barPercentage',
    'categoryPercentage',
    'grouped',
  ];
}

/// The chart context, the dataset context and the data contexts of
/// [count] elements (`core.controller.js` `getContext`,
/// `core.datasetController.js:96-121`).
List<ContextObject> dataContexts(int count) {
  final chartContext = createContext(null, <String, Object?>{
    'chart': 'chart',
    'type': 'chart',
  });
  final datasetContext = createContext(chartContext, <String, Object?>{
    'active': false,
    'dataset': 'dataset',
    'datasetIndex': 0.0,
    'index': 0.0,
    'mode': 'default',
    'type': 'dataset',
  });
  return <ContextObject>[
    for (var i = 0; i < count; i++)
      createContext(datasetContext, <String, Object?>{
        'active': false,
        'dataIndex': i.toDouble(),
        'parsed': <String, Object?>{'x': i.toDouble(), 'y': 1.0},
        'raw': 1.0,
        'element': 'element',
        'index': i.toDouble(),
        'mode': 'default',
        'type': 'data',
      }),
  ];
}
