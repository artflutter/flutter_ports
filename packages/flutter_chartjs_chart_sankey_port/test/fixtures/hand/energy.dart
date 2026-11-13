// Ported from chartjs-chart-sankey v0.19.1 test/fixtures/energy.js (MIT, Jukka Kurkela).
// DIVERGES(sankey): adapt-sankey-native-colors, native paint inputs.
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'dart:ui' show Color;

import 'package:flutter_chartjs_port/chartjs.dart' show ChartPaint;
import 'package:flutter_chartjs_port/js_semantics.dart'
    show jsGet, jsToString, jsTruthy;

/// `export default` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() {
  const colors = <ChartPaint>[
    ChartPaint.solid(Color(0xFF1F77B4)), // #1F77B4
    ChartPaint.solid(Color(0xFFFF7F0E)), // #FF7F0E
    ChartPaint.solid(Color(0xFF2CA02C)), // #2CA02C
    ChartPaint.solid(Color(0xFFD62728)), // #D62728
    ChartPaint.solid(Color(0xFF9467BD)), // #9467BD
    ChartPaint.solid(Color(0xFF8C564B)), // #8C564B
    ChartPaint.solid(Color(0xFFE377C2)), // #E377C2
    ChartPaint.solid(Color(0xFF7F7F7F)), // #7F7F7F
    ChartPaint.solid(Color(0xFFBCBD22)), // #BCBD22
  ];

  final category = <String, Object?>{
    "Agricultural 'waste'": 'Agricultural',
    'Agriculture': 'Agriculture',
    'Bio-conversion': 'Bio-conversion',
    'Biofuel imports': 'Biofuel',
    'Biomass imports': 'Biomass',
    'Coal': 'Coal',
    'Coal imports': 'Coal',
    'Coal reserves': 'Coal',
    'District heating': 'District',
    'Domestic aviation': 'Domestic',
    'Electricity grid': 'Electricity',
    'Gas': 'Gas',
    'Gas imports': 'Gas',
    'Gas reserves': 'Gas',
    'Geothermal': 'Geothermal',
    'H2': 'H2',
    'H2 conversion': 'H2',
    'Heating and cooling - commercial': 'Heating',
    'Heating and cooling - homes': 'Heating',
    'Hydro': 'Hydro',
    'Industry': 'Industry',
    'International aviation': 'International',
    'International shipping': 'International',
    'Lighting & appliances - commercial': 'Lighting',
    'Lighting & appliances - homes': 'Lighting',
    'Liquid': 'Liquid',
    'Losses': 'Losses',
    'Marine algae': 'Marine',
    'National navigation': 'National',
    'Ngas': 'Ngas',
    'Nuclear': 'Nuclear',
    'Oil': 'Oil',
    'Oil imports': 'Oil',
    'Oil reserves': 'Oil',
    'Other waste': 'Other',
    'Over generation / exports': 'Over',
    'Pumped heat': 'Pumped',
    'Rail transport': 'Rail',
    'Road transport': 'Road',
    'Solar': 'Solar',
    'Solar PV': 'Solar',
    'Solar Thermal': 'Solar',
    'Solid': 'Solid',
    'Thermal generation': 'Thermal',
    'Tidal': 'Tidal',
    'UK land based bioenergy': 'UK',
    'Wave': 'Wave',
    'Wind': 'Wind',
  };

  final catColors = <String, Object?>{};
  var colorIndex = 0;

  Object? getColor(Object? item) {
    final cat = jsGet(category, item);
    if (!jsTruthy(jsGet(catColors, cat))) {
      catColors[jsToString(cat)] = colors[colorIndex.remainder(9)];
      colorIndex++;
    }
    return jsGet(catColors, cat);
  }

  final data = <Object?>[
    <String, Object?>{
      'flow': 124.729,
      'from': "Agricultural 'waste'",
      'to': 'Bio-conversion',
    },
    <String, Object?>{'flow': 0.597, 'from': 'Bio-conversion', 'to': 'Liquid'},
    <String, Object?>{'flow': 26.862, 'from': 'Bio-conversion', 'to': 'Losses'},
    <String, Object?>{'flow': 280.322, 'from': 'Bio-conversion', 'to': 'Solid'},
    <String, Object?>{'flow': 81.144, 'from': 'Bio-conversion', 'to': 'Gas'},
    <String, Object?>{'flow': 35, 'from': 'Biofuel imports', 'to': 'Liquid'},
    <String, Object?>{'flow': 35, 'from': 'Biomass imports', 'to': 'Solid'},
    <String, Object?>{
      'flow': 10.639,
      'from': 'District heating',
      'to': 'Industry',
    },
    <String, Object?>{
      'flow': 22.505,
      'from': 'District heating',
      'to': 'Heating and cooling - commercial',
    },
    <String, Object?>{
      'flow': 46.184,
      'from': 'District heating',
      'to': 'Heating and cooling - homes',
    },
    <String, Object?>{
      'flow': 104.453,
      'from': 'Electricity grid',
      'to': 'Over generation / exports',
    },
    <String, Object?>{
      'flow': 113.726,
      'from': 'Electricity grid',
      'to': 'Heating and cooling - homes',
    },
    <String, Object?>{
      'flow': 27.14,
      'from': 'Electricity grid',
      'to': 'H2 conversion',
    },
    <String, Object?>{
      'flow': 342.165,
      'from': 'Electricity grid',
      'to': 'Industry',
    },
    <String, Object?>{
      'flow': 37.797,
      'from': 'Electricity grid',
      'to': 'Road transport',
    },
    <String, Object?>{
      'flow': 4.412,
      'from': 'Electricity grid',
      'to': 'Agriculture',
    },
    <String, Object?>{
      'flow': 40.858,
      'from': 'Electricity grid',
      'to': 'Heating and cooling - commercial',
    },
    <String, Object?>{
      'flow': 56.691,
      'from': 'Electricity grid',
      'to': 'Losses',
    },
    <String, Object?>{
      'flow': 7.863,
      'from': 'Electricity grid',
      'to': 'Rail transport',
    },
    <String, Object?>{
      'flow': 90.008,
      'from': 'Electricity grid',
      'to': 'Lighting & appliances - commercial',
    },
    <String, Object?>{
      'flow': 93.494,
      'from': 'Electricity grid',
      'to': 'Lighting & appliances - homes',
    },
    <String, Object?>{'flow': 40.719, 'from': 'Gas imports', 'to': 'Ngas'},
    <String, Object?>{'flow': 82.233, 'from': 'Gas reserves', 'to': 'Ngas'},
    <String, Object?>{
      'flow': 0.129,
      'from': 'Gas',
      'to': 'Heating and cooling - commercial',
    },
    <String, Object?>{'flow': 1.401, 'from': 'Gas', 'to': 'Losses'},
    <String, Object?>{
      'flow': 151.891,
      'from': 'Gas',
      'to': 'Thermal generation',
    },
    <String, Object?>{'flow': 2.096, 'from': 'Gas', 'to': 'Agriculture'},
    <String, Object?>{'flow': 48.58, 'from': 'Gas', 'to': 'Industry'},
    <String, Object?>{
      'flow': 7.013,
      'from': 'Geothermal',
      'to': 'Electricity grid',
    },
    <String, Object?>{'flow': 20.897, 'from': 'H2 conversion', 'to': 'H2'},
    <String, Object?>{'flow': 6.242, 'from': 'H2 conversion', 'to': 'Losses'},
    <String, Object?>{'flow': 20.897, 'from': 'H2', 'to': 'Road transport'},
    <String, Object?>{'flow': 6.995, 'from': 'Hydro', 'to': 'Electricity grid'},
    <String, Object?>{'flow': 121.066, 'from': 'Liquid', 'to': 'Industry'},
    <String, Object?>{
      'flow': 128.69,
      'from': 'Liquid',
      'to': 'International shipping',
    },
    <String, Object?>{
      'flow': 135.835,
      'from': 'Liquid',
      'to': 'Road transport',
    },
    <String, Object?>{
      'flow': 14.458,
      'from': 'Liquid',
      'to': 'Domestic aviation',
    },
    <String, Object?>{
      'flow': 206.267,
      'from': 'Liquid',
      'to': 'International aviation',
    },
    <String, Object?>{'flow': 3.64, 'from': 'Liquid', 'to': 'Agriculture'},
    <String, Object?>{
      'flow': 33.218,
      'from': 'Liquid',
      'to': 'National navigation',
    },
    <String, Object?>{'flow': 4.413, 'from': 'Liquid', 'to': 'Rail transport'},
    <String, Object?>{
      'flow': 4.375,
      'from': 'Marine algae',
      'to': 'Bio-conversion',
    },
    <String, Object?>{'flow': 122.952, 'from': 'Ngas', 'to': 'Gas'},
    <String, Object?>{
      'flow': 839.978,
      'from': 'Nuclear',
      'to': 'Thermal generation',
    },
    <String, Object?>{'flow': 504.287, 'from': 'Oil imports', 'to': 'Oil'},
    <String, Object?>{'flow': 107.703, 'from': 'Oil reserves', 'to': 'Oil'},
    <String, Object?>{'flow': 611.99, 'from': 'Oil', 'to': 'Liquid'},
    <String, Object?>{'flow': 56.587, 'from': 'Other waste', 'to': 'Solid'},
    <String, Object?>{
      'flow': 77.81,
      'from': 'Other waste',
      'to': 'Bio-conversion',
    },
    <String, Object?>{
      'flow': 193.026,
      'from': 'Pumped heat',
      'to': 'Heating and cooling - homes',
    },
    <String, Object?>{
      'flow': 70.672,
      'from': 'Pumped heat',
      'to': 'Heating and cooling - commercial',
    },
    <String, Object?>{
      'flow': 59.901,
      'from': 'Solar PV',
      'to': 'Electricity grid',
    },
    <String, Object?>{
      'flow': 19.263,
      'from': 'Solar Thermal',
      'to': 'Heating and cooling - homes',
    },
    <String, Object?>{'flow': 19.263, 'from': 'Solar', 'to': 'Solar Thermal'},
    <String, Object?>{'flow': 59.901, 'from': 'Solar', 'to': 'Solar PV'},
    <String, Object?>{'flow': 0.882, 'from': 'Solid', 'to': 'Agriculture'},
    <String, Object?>{
      'flow': 400.12,
      'from': 'Solid',
      'to': 'Thermal generation',
    },
    <String, Object?>{'flow': 46.477, 'from': 'Solid', 'to': 'Industry'},
    <String, Object?>{
      'flow': 525.531,
      'from': 'Thermal generation',
      'to': 'Electricity grid',
    },
    <String, Object?>{
      'flow': 787.129,
      'from': 'Thermal generation',
      'to': 'Losses',
    },
    <String, Object?>{
      'flow': 79.329,
      'from': 'Thermal generation',
      'to': 'District heating',
    },
    <String, Object?>{'flow': 9.452, 'from': 'Tidal', 'to': 'Electricity grid'},
    <String, Object?>{
      'flow': 182.01,
      'from': 'UK land based bioenergy',
      'to': 'Bio-conversion',
    },
    <String, Object?>{'flow': 19.013, 'from': 'Wave', 'to': 'Electricity grid'},
    <String, Object?>{
      'flow': 289.366,
      'from': 'Wind',
      'to': 'Electricity grid',
    },
  ];

  return <String, Object?>{
    'config': <String, Object?>{
      'data': <String, Object?>{
        'datasets': <Object?>[
          <String, Object?>{
            'color': const ChartPaint.solid(Color(0x00000000)), // transparent
            'colorFrom': (Object? c) => getColor(
              jsGet(
                jsGet(
                  jsGet(jsGet(c, 'dataset'), 'data'),
                  jsGet(c, 'dataIndex'),
                ),
                'from',
              ),
            ),
            'colorTo': (Object? c) => getColor(
              jsGet(
                jsGet(
                  jsGet(jsGet(c, 'dataset'), 'data'),
                  jsGet(c, 'dataIndex'),
                ),
                'to',
              ),
            ),
            'data': data,
          },
        ],
      },
      'type': 'sankey',
    },
    'options': <String, Object?>{
      'canvas': <String, Object?>{'height': 750, 'width': 1000},
    },
  };
}
