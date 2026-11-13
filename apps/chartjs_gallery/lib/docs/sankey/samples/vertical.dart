// Ported from chartjs-chart-sankey v0.19.1 src/content/docs/samples/vertical.md (MIT, Jukka Kurkela).

import 'package:chartjs_gallery/docs/sankey/scripts/utils.dart';
import 'package:flutter_chartjs_chart_sankey_port/flutter_chartjs_chart_sankey_port.dart'
    show SankeyColorMode, SankeyOrientation;
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart'
    show JsObjectFace;

/// `context.raw`: the data item of the scriptable context [context].
Map<String, Object?> _raw(Object? context) =>
    (context! as JsObjectFace)['raw']! as Map<String, Object?>;

/// The sample `Vertical` of `src/content/docs/samples/vertical.md:8-38`.
Map<String, Object?> sankeyVerticalSample() {
  final utils = SankeyDocsColors();
  // <block:data:1>
  final data = <String, Object?>{
    'datasets': <Object?>[
      <String, Object?>{
        'label': 'Customer journey',
        'orientation': SankeyOrientation.vertical,
        'data': <Object?>[
          <String, Object?>{
            'from': 'Visits',
            'to': 'Product views',
            'flow': 80,
          },
          <String, Object?>{'from': 'Visits', 'to': 'Exit', 'flow': 20},
          <String, Object?>{'from': 'Product views', 'to': 'Cart', 'flow': 32},
          <String, Object?>{'from': 'Product views', 'to': 'Exit', 'flow': 48},
          <String, Object?>{'from': 'Cart', 'to': 'Purchase', 'flow': 18},
          <String, Object?>{'from': 'Cart', 'to': 'Abandoned', 'flow': 14},
        ],
        'colorFrom': (Object? context) =>
            utils.getColor(_raw(context)['from']! as String),
        'colorTo': (Object? context) =>
            utils.getColor(_raw(context)['to']! as String),
        'colorMode': SankeyColorMode.gradient,
      },
    ],
  };
  // </block:data>

  // <block:config:0>
  final config = <String, Object?>{'type': 'sankey', 'data': data};
  // </block:config>

  return config;
}
