// Ported from Chart.js v4.6.1 test/fixtures/plugin.filler/line/shape.js (MIT, Chart.js Contributors).
// Each call runs the module body again and gives new objects
// (fixture.js:24): the chart keeps the Lists of its config and writes
// into some of them.
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADR 0115).
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The config of the upstream file, as tool 4 decoded it. Each call
/// makes new objects.
FixtureConfig fixture() => FixtureConfig.typed(
  ChartConfig(
    datasets: [
      LineDataset(
        data: .points([
          DataPoint(1, 0),
          DataPoint(0.9975640502598242, 0.0697564737441253),
          DataPoint(0.9902680687415704, 0.13917310096006544),
          DataPoint(0.9781476007338057, 0.20791169081775934),
          DataPoint(0.9612616959383189, 0.27563735581699916),
          DataPoint(0.9396926207859084, 0.3420201433256687),
          DataPoint(0.9135454576426009, 0.40673664307580015),
          DataPoint(0.882947592858927, 0.46947156278589075),
          DataPoint(0.848048096156426, 0.5299192642332049),
          DataPoint(0.8090169943749475, 0.5877852522924731),
          DataPoint(0.766044443118978, 0.6427876096865393),
          DataPoint(0.7193398003386512, 0.6946583704589973),
          DataPoint(0.6691306063588582, 0.7431448254773942),
          DataPoint(0.6156614753256583, 0.7880107536067219),
          DataPoint(0.5591929034707469, 0.8290375725550416),
          DataPoint(0.5000000000000001, 0.8660254037844386),
          DataPoint(0.43837114678907746, 0.898794046299167),
          DataPoint(0.37460659341591196, 0.9271838545667874),
          DataPoint(0.3090169943749473, 0.9510565162951536),
          DataPoint(0.24192189559966745, 0.9702957262759966),
          DataPoint(0.17364817766693, 0.9848077530122081),
          DataPoint(0.10452846326765301, 0.9945218953682734),
          DataPoint(0.034899496702500414, 0.9993908270190958),
          DataPoint(-0.03489949670250162, 0.9993908270190958),
          DataPoint(-0.10452846326765422, 0.9945218953682733),
          DataPoint(-0.1736481776669312, 0.9848077530122079),
          DataPoint(-0.24192189559966865, 0.9702957262759963),
          DataPoint(-0.3090169943749484, 0.9510565162951532),
          DataPoint(-0.37460659341591307, 0.927183854566787),
          DataPoint(-0.43837114678907835, 0.8987940462991666),
          DataPoint(-0.500000000000001, 0.866025403784438),
          DataPoint(-0.5591929034707478, 0.8290375725550411),
          DataPoint(-0.6156614753256593, 0.7880107536067211),
          DataPoint(-0.6691306063588592, 0.7431448254773934),
          DataPoint(-0.7193398003386522, 0.6946583704589963),
          DataPoint(-0.766044443118979, 0.6427876096865381),
          DataPoint(-0.8090169943749485, 0.5877852522924718),
          DataPoint(-0.848048096156427, 0.5299192642332035),
          DataPoint(-0.8829475928589278, 0.46947156278588914),
          DataPoint(-0.9135454576426016, 0.40673664307579843),
          DataPoint(-0.9396926207859091, 0.34202014332566677),
          DataPoint(-0.9612616959383194, 0.2756373558169971),
          DataPoint(-0.9781476007338061, 0.20791169081775712),
          DataPoint(-0.9902680687415707, 0.1391731009600631),
          DataPoint(-0.9975640502598244, 0.06975647374412286),
          DataPoint(-1, -2.5420705791856405e-15),
          DataPoint(-0.9975640502598241, -0.06975647374412794),
          DataPoint(-0.9902680687415699, -0.13917310096006816),
          DataPoint(-0.978147600733805, -0.20791169081776212),
          DataPoint(-0.961261695938318, -0.275637355817002),
          DataPoint(-0.9396926207859073, -0.34202014332567154),
          DataPoint(-0.9135454576425996, -0.40673664307580304),
          DataPoint(-0.8829475928589254, -0.46947156278589364),
          DataPoint(-0.8480480961564242, -0.5299192642332078),
          DataPoint(-0.8090169943749455, -0.5877852522924759),
          DataPoint(-0.7660444431189758, -0.642787609686542),
          DataPoint(-0.7193398003386486, -0.6946583704589999),
          DataPoint(-0.6691306063588555, -0.7431448254773967),
          DataPoint(-0.6156614753256553, -0.7880107536067242),
          DataPoint(-0.5591929034707436, -0.8290375725550438),
          DataPoint(-0.49999999999999656, -0.8660254037844406),
          DataPoint(-0.43837114678907374, -0.8987940462991688),
          DataPoint(-0.3746065934159082, -0.927183854566789),
          DataPoint(-0.30901699437494334, -0.9510565162951549),
          DataPoint(-0.24192189559966348, -0.9702957262759976),
          DataPoint(-0.17364817766692595, -0.9848077530122088),
          DataPoint(-0.10452846326764893, -0.9945218953682738),
          DataPoint(-0.03489949670249632, -0.9993908270190959),
          DataPoint(0.034899496702505715, -0.9993908270190955),
          DataPoint(0.10452846326765829, -0.9945218953682728),
          DataPoint(0.17364817766693522, -0.9848077530122072),
          DataPoint(0.24192189559967262, -0.9702957262759953),
          DataPoint(0.3090169943749523, -0.951056516295152),
          DataPoint(0.3746065934159169, -0.9271838545667854),
          DataPoint(0.4383711467890822, -0.8987940462991647),
          DataPoint(0.5000000000000047, -0.8660254037844359),
          DataPoint(0.5591929034707515, -0.8290375725550386),
          DataPoint(0.6156614753256627, -0.7880107536067185),
          DataPoint(0.6691306063588625, -0.7431448254773905),
          DataPoint(0.7193398003386552, -0.6946583704589931),
          DataPoint(0.7660444431189818, -0.6427876096865348),
          DataPoint(0.8090169943749509, -0.5877852522924683),
          DataPoint(0.8480480961564292, -0.5299192642331998),
          DataPoint(0.8829475928589299, -0.4694715627858853),
          DataPoint(0.9135454576426034, -0.4067366430757945),
          DataPoint(0.9396926207859105, -0.3420201433256627),
          DataPoint(0.9612616959383207, -0.27563735581699295),
          DataPoint(0.978147600733807, -0.2079116908177529),
          DataPoint(0.9902680687415713, -0.13917310096005883),
          DataPoint(0.9975640502598248, -0.06975647374411856),
        ]),
        // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
        fill: FillTarget.shape,
        backgroundColor: .constant(
          ChartPaint.solid(Color.fromRGBO(255, 0, 0, 0.5)),
        ),
      ),
    ],
    scales: [
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      LinearAxis(CartesianAxis.x, display: ScaleDisplay.off),
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      LinearAxis(CartesianAxis.y, display: ScaleDisplay.off),
    ],
    disabledPlugins: [PluginOff<LegendPlugin>()],
  ),
);
