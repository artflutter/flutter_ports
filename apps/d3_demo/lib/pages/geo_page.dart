// Original code, not ported from D3: flutter_d3_geo_port interactive demo.

import 'dart:math' as math;

import 'package:flutter_d3_geo_port/flutter_d3_geo_port.dart' as d3g;
import 'package:flutter_d3_path_port/flutter_d3_path_port.dart' as d3p;
import 'package:material_ui/material_ui.dart';

const double _earthRadiusKm = 6371.0088;

enum _GeoProjectionKind(final String label) {
  orthographic('Orthographic'),
  naturalEarth1('NaturalEarth1'),
  equalEarth('EqualEarth'),
  mercator('Mercator'),
  stereographic('Stereographic'),
  albers('Albers'),
  conicEqualArea('ConicEqualArea'),
}

final class const _City(final String name, final d3g.GeoPosition coords);

const List<_City> _cities = <_City>[
  _City('San Francisco', (-122.4194, 37.7749)),
  _City('New York', (-74.0060, 40.7128)),
  _City('London', (-0.1276, 51.5072)),
  _City('Tokyo', (139.6917, 35.6895)),
  _City('Sydney', (151.2093, -33.8688)),
  _City('Rio de Janeiro', (-43.1729, -22.9068)),
  _City('Cape Town', (18.4241, -33.9249)),
  _City('Reykjavik', (-21.9426, 64.1466)),
];

/// Lightweight embedded Natural Earth low-res landmass polygons (clockwise
/// spherical winding).
const d3g.GeoMultiPolygon _worldLand = d3g.GeoMultiPolygon(
  <List<List<d3g.GeoPosition>>>[
    // North America
    <List<d3g.GeoPosition>>[
      <d3g.GeoPosition>[
        (-168, 65),
        (-162, 70),
        (-141, 70),
        (-125, 70),
        (-110, 68),
        (-95, 68),
        (-82, 66),
        (-78, 62),
        (-64, 60),
        (-56, 52),
        (-60, 46),
        (-67, 45),
        (-70, 42),
        (-75, 38),
        (-80, 32),
        (-81, 25),
        (-83, 30),
        (-90, 29),
        (-97, 26),
        (-96, 19),
        (-88, 21),
        (-83, 15),
        (-83, 10),
        (-78, 8),
        (-80, 9),
        (-85, 11),
        (-92, 15),
        (-105, 20),
        (-110, 24),
        (-114, 31),
        (-117, 33),
        (-122, 37),
        (-124, 42),
        (-124, 48),
        (-130, 54),
        (-138, 59),
        (-150, 60),
        (-160, 56),
        (-165, 60),
        (-168, 65),
      ],
    ],
    // Greenland
    <List<d3g.GeoPosition>>[
      <d3g.GeoPosition>[
        (-44, 60),
        (-52, 64),
        (-55, 70),
        (-68, 76),
        (-62, 81),
        (-35, 83),
        (-18, 81),
        (-20, 74),
        (-25, 70),
        (-36, 65),
        (-44, 60),
      ],
    ],
    // Cuba
    <List<d3g.GeoPosition>>[
      <d3g.GeoPosition>[(-85, 22), (-80, 23), (-74, 20), (-82, 21), (-85, 22)],
    ],
    // South America
    <List<d3g.GeoPosition>>[
      <d3g.GeoPosition>[
        (-78, 9),
        (-72, 11),
        (-62, 10),
        (-50, 2),
        (-35, -6),
        (-38, -14),
        (-42, -23),
        (-52, -33),
        (-58, -38),
        (-65, -43),
        (-68, -55),
        (-74, -52),
        (-73, -40),
        (-71, -30),
        (-70, -18),
        (-81, -5),
        (-79, 2),
        (-78, 9),
      ],
    ],
    // Africa
    <List<d3g.GeoPosition>>[
      <d3g.GeoPosition>[
        (-17, 15),
        (-13, 28),
        (-6, 36),
        (10, 37),
        (15, 32),
        (25, 32),
        (33, 31),
        (40, 20),
        (43, 12),
        (51, 11),
        (41, -2),
        (40, -15),
        (35, -24),
        (28, -33),
        (18, -34),
        (14, -22),
        (12, -6),
        (9, 4),
        (2, 6),
        (-8, 5),
        (-16, 11),
        (-17, 15),
      ],
    ],
    // Madagascar
    <List<d3g.GeoPosition>>[
      <d3g.GeoPosition>[
        (49, -12),
        (50, -16),
        (47, -25),
        (44, -25),
        (44, -18),
        (49, -12),
      ],
    ],
    // Eurasia
    <List<d3g.GeoPosition>>[
      <d3g.GeoPosition>[
        (-9, 37),
        (-9, 43),
        (-2, 43),
        (-4, 48),
        (2, 51),
        (8, 54),
        (10, 58),
        (5, 61),
        (15, 68),
        (28, 71),
        (40, 67),
        (55, 69),
        (70, 73),
        (104, 77),
        (140, 73),
        (178, 66),
        (170, 60),
        (160, 56),
        (140, 53),
        (135, 44),
        (129, 35),
        (122, 39),
        (122, 31),
        (114, 22),
        (108, 16),
        (105, 10),
        (100, 13),
        (103, 2),
        (98, 8),
        (90, 22),
        (80, 8),
        (73, 19),
        (66, 25),
        (56, 26),
        (59, 22),
        (44, 13),
        (35, 29),
        (36, 36),
        (27, 37),
        (23, 38),
        (14, 45),
        (8, 44),
        (3, 42),
        (-5, 36),
        (-9, 37),
      ],
    ],
    // Great Britain
    <List<d3g.GeoPosition>>[
      <d3g.GeoPosition>[
        (-5, 50),
        (-3, 54),
        (-5, 58),
        (-2, 58),
        (1, 53),
        (1, 51),
        (-5, 50),
      ],
    ],
    // Iceland
    <List<d3g.GeoPosition>>[
      <d3g.GeoPosition>[
        (-24, 65),
        (-18, 66),
        (-14, 65),
        (-19, 63.5),
        (-24, 65),
      ],
    ],
    // Japan
    <List<d3g.GeoPosition>>[
      <d3g.GeoPosition>[
        (130, 31),
        (131, 34),
        (136, 37),
        (139, 40),
        (141, 45),
        (145, 43),
        (141, 41),
        (141, 36),
        (135, 34),
        (130, 31),
      ],
    ],
    // Australia
    <List<d3g.GeoPosition>>[
      <d3g.GeoPosition>[
        (114, -22),
        (122, -18),
        (131, -12),
        (136, -12),
        (142, -11),
        (149, -20),
        (153, -28),
        (150, -37),
        (141, -38),
        (135, -34),
        (129, -32),
        (115, -34),
        (113, -26),
        (114, -22),
      ],
    ],
    // New Zealand
    <List<d3g.GeoPosition>>[
      <d3g.GeoPosition>[
        (173, -35),
        (178, -38),
        (175, -41),
        (171, -44),
        (167, -46),
        (170, -41),
        (174, -39),
        (173, -35),
      ],
    ],
    // Sumatra & Java
    <List<d3g.GeoPosition>>[
      <d3g.GeoPosition>[
        (95, 5),
        (100, 1),
        (106, -6),
        (114, -8),
        (105, -7),
        (99, -1),
        (95, 5),
      ],
    ],
    // Borneo
    <List<d3g.GeoPosition>>[
      <d3g.GeoPosition>[
        (109, 1),
        (117, 6),
        (119, 1),
        (116, -3),
        (110, -3),
        (109, 1),
      ],
    ],
    // New Guinea
    <List<d3g.GeoPosition>>[
      <d3g.GeoPosition>[
        (132, -1),
        (141, -3),
        (150, -10),
        (142, -9),
        (135, -5),
        (132, -1),
      ],
    ],
    // Antarctica
    <List<d3g.GeoPosition>>[
      <d3g.GeoPosition>[
        (-180, -72),
        (-120, -73),
        (-60, -64),
        (-40, -72),
        (0, -70),
        (60, -67),
        (120, -67),
        (165, -72),
        (180, -72),
        (180, -85),
        (0, -85),
        (-180, -85),
        (-180, -72),
      ],
    ],
  ],
);

/// Interactive showcase for `flutter_d3_geo_port`: live drag-to-rotate 3D
/// Orthographic globe & world map projections, graticule & Tissot `geoCircle`
/// overlays, and great-circle `geoDistance` / `geoInterpolate` city routes
/// drawn directly via `UiPathContext`.
class const GeoDemoPage({super.key}) extends StatefulWidget {
  /// Creates the `d3-geo` demo page.
  this;

  @override
  State<GeoDemoPage> createState() => _GeoDemoPageState();
}

class _GeoDemoPageState()
    extends State<GeoDemoPage>
    with SingleTickerProviderStateMixin {
  _GeoProjectionKind _kind = _GeoProjectionKind.orthographic;
  double _rotLon = 10;
  double _rotLat = -22;
  bool _autoSpin = false;
  bool _showGraticule = true;
  bool _showTissot = false;
  double _circleRadius = 15;
  int _cityA = 0; // San Francisco
  int _cityB = 3; // Tokyo

  late final AnimationController _spinController =
      AnimationController(vsync: this, duration: const Duration(seconds: 24))
        ..addListener(() {
          if (!mounted || !_autoSpin) return;
          setState(() {
            _rotLon = (_rotLon + 0.45) % 360;
            if (_rotLon > 180) _rotLon -= 360;
          });
        });

  final d3g.GeoMultiLineString _graticule = d3g.geoGraticule10();

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  void _toggleSpin(bool value) {
    setState(() {
      _autoSpin = value;
      if (value) {
        _spinController.repeat();
      } else {
        _spinController.stop();
      }
    });
  }

  d3g.GeoProjection _buildProjection(Size size) {
    final w = size.width;
    final h = size.height;
    final minDim = math.min(w, h);
    const pad = 16.0;
    final extent = ((pad, pad), (w - pad, h - pad));

    switch (_kind) {
      case _GeoProjectionKind.orthographic:
        return d3g.geoOrthographic()
          ..rotate = (_rotLon, _rotLat, 0)
          ..translate = (w / 2, h / 2)
          ..scale = minDim * 0.43;
      case _GeoProjectionKind.naturalEarth1:
        return d3g.geoNaturalEarth1()
          ..rotate = (_rotLon, 0, 0)
          ..fitExtent(extent, const d3g.GeoSphere());
      case _GeoProjectionKind.equalEarth:
        return d3g.geoEqualEarth()
          ..rotate = (_rotLon, 0, 0)
          ..fitExtent(extent, const d3g.GeoSphere());
      case _GeoProjectionKind.mercator:
        return d3g.geoMercator()
          ..rotate = (_rotLon, 0, 0)
          ..translate = (w / 2, h / 2)
          ..scale = minDim * 0.165
          ..clipExtent = extent;
      case _GeoProjectionKind.stereographic:
        return d3g.geoStereographic()
          ..rotate = (_rotLon, _rotLat, 0)
          ..translate = (w / 2, h / 2)
          ..scale = minDim * 0.34
          ..clipExtent = extent;
      case _GeoProjectionKind.albers:
        return d3g.geoAlbers()
          ..rotate = (_rotLon + 96, 0, 0)
          ..translate = (w / 2, h / 2)
          ..scale = minDim * 0.48
          ..clipExtent = extent;
      case _GeoProjectionKind.conicEqualArea:
        return d3g.geoConicEqualArea()
          ..rotate = (_rotLon, 0, 0)
          ..parallels = const (20, 60)
          ..translate = (w / 2, h / 2)
          ..scale = minDim * 0.34
          ..clipExtent = extent;
    }
  }

  void _handleTap(Offset localPos, Size size) {
    final proj = _buildProjection(size);
    var bestIdx = -1;
    var bestDist = 26.0;
    for (var i = 0; i < _cities.length; ++i) {
      final p = proj(_cities[i].coords);
      if (p == null) continue;
      final d = (Offset(p.$1, p.$2) - localPos).distance;
      if (d < bestDist) {
        bestDist = d;
        bestIdx = i;
      }
    }
    if (bestIdx >= 0 && bestIdx != _cityB) {
      setState(() {
        _cityA = _cityB;
        _cityB = bestIdx;
      });
    }
  }

  void _selectCityChip(int index) {
    if (index == _cityB) return;
    setState(() {
      _cityA = _cityB;
      _cityB = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fromCity = _cities[_cityA];
    final toCity = _cities[_cityB];
    final distRad = d3g.geoDistance(fromCity.coords, toCity.coords);
    final distKm = distRad * _earthRadiusKm;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Interactive World Projections, 3D Globe & Spherical Geometry',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Drag to rotate the sphere, switch between 7 built-in projections, '
          'toggle graticule and geoCircle overlays, and click any two cities '
          'to inspect their great-circle geoInterpolate route — rendered '
          'directly to Flutter Canvas via UiPathContext.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: scheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final kind in _GeoProjectionKind.values)
                      ChoiceChip(
                        label: Text(kind.label),
                        selected: _kind == kind,
                        onSelected: (_) => setState(() => _kind = kind),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FilterChip(
                      label: const Text('Graticule'),
                      selected: _showGraticule,
                      onSelected: (v) => setState(() => _showGraticule = v),
                    ),
                    FilterChip(
                      label: const Text('Tissot / Circles'),
                      selected: _showTissot,
                      onSelected: (v) => setState(() => _showTissot = v),
                    ),
                    FilterChip(
                      label: const Text('Auto-spin'),
                      selected: _autoSpin,
                      onSelected: _toggleSpin,
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Reset rotation'),
                      onPressed: () => setState(() {
                        _rotLon = 10;
                        _rotLat = -22;
                      }),
                    ),
                  ],
                ),
                if (_showTissot) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Circle radius: ${_circleRadius.round()}°',
                        style: theme.textTheme.labelLarge,
                      ),
                      Expanded(
                        child: Slider(
                          value: _circleRadius,
                          min: 5,
                          max: 45,
                          divisions: 40,
                          onChanged: (v) => setState(() => _circleRadius = v),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final height = math.min<double>(
                      460,
                      math.max<double>(300, width * 0.55),
                    );
                    final size = Size(width, height);
                    final projection = _buildProjection(size);
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          setState(() {
                            _rotLon = (_rotLon + details.delta.dx * 0.35) % 360;
                            if (_rotLon > 180) _rotLon -= 360;
                            _rotLat = (_rotLat - details.delta.dy * 0.35).clamp(
                              -85.0,
                              85.0,
                            );
                          });
                        },
                        onTapUp: (details) =>
                            _handleTap(details.localPosition, size),
                        child: SizedBox(
                          width: width,
                          height: height,
                          child: CustomPaint(
                            painter: _GeoMapPainter(
                              projection: projection,
                              graticule: _graticule,
                              showGraticule: _showGraticule,
                              showTissot: _showTissot,
                              circleRadius: _circleRadius,
                              fromCity: fromCity,
                              toCity: toCity,
                              scheme: scheme,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Chip(
                      avatar: Icon(
                        Icons.flight_takeoff,
                        size: 16,
                        color: scheme.primary,
                      ),
                      label: Text('${fromCity.name} → ${toCity.name}'),
                    ),
                    Chip(
                      avatar: Icon(
                        Icons.straighten,
                        size: 16,
                        color: scheme.secondary,
                      ),
                      label: Text(
                        '${distKm.round()} km '
                        '(${distRad.toStringAsFixed(3)} rad)',
                      ),
                    ),
                    Chip(
                      label: Text(
                        'Rotate: (${_rotLon.round()}°, ${_rotLat.round()}°)',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (var i = 0; i < _cities.length; ++i)
                      ActionChip(
                        avatar: Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: (i == _cityA || i == _cityB)
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                        ),
                        label: Text(_cities[i].name),
                        side: (i == _cityA || i == _cityB)
                            ? BorderSide(color: scheme.primary, width: 1.5)
                            : null,
                        onPressed: () => _selectCityChip(i),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

final class _GeoMapPainter({
  required final d3g.GeoProjection projection,
  required final d3g.GeoMultiLineString graticule,
  required final bool showGraticule,
  required final bool showTissot,
  required final double circleRadius,
  required final _City fromCity,
  required final _City toCity,
  required final ColorScheme scheme,
}) extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final isDark = scheme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0B1120) : const Color(0xFFF1F5F9);
    final oceanColor = isDark
        ? const Color(0xFF102A43)
        : const Color(0xFFDCEEFB);
    final landFill = isDark ? const Color(0xFF2D6A4F) : const Color(0xFF52B788);
    final landStroke = isDark
        ? const Color(0xFF95D5B2)
        : const Color(0xFF1B4332);
    final gratColor = (isDark ? Colors.white : const Color(0xFF334155))
        .withValues(alpha: 0.22);

    canvas.drawRect(Offset.zero & size, Paint()..color = bgColor);

    final pathGen = d3g.geoPath(projection);
    final uiPath = Path();
    final ctx = d3p.UiPathContext(uiPath);

    // 1. Sphere (ocean backdrop + horizon outline)
    uiPath.reset();
    pathGen.draw(const d3g.GeoSphere(), ctx);
    canvas
      ..drawPath(uiPath, Paint()..color = oceanColor)
      ..drawPath(
        uiPath,
        Paint()
          ..color = scheme.outline
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.25,
      );

    // 2. Graticule
    if (showGraticule) {
      uiPath.reset();
      pathGen.draw(graticule, ctx);
      canvas.drawPath(
        uiPath,
        Paint()
          ..color = gratColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.75,
      );
    }

    // 3. Embedded Natural Earth low-res landmass polygons
    uiPath.reset();
    pathGen.draw(_worldLand, ctx);
    canvas
      ..drawPath(uiPath, Paint()..color = landFill)
      ..drawPath(
        uiPath,
        Paint()
          ..color = landStroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9,
      );

    // 4. Optional Tissot / spherical geoCircle radius overlays
    if (showTissot) {
      final circleGen = d3g.geoCircle(radius: circleRadius, precision: 6);
      final tissotFill = Paint()
        ..color = scheme.tertiary.withValues(alpha: 0.20);
      final tissotStroke = Paint()
        ..color = scheme.tertiary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1;

      // Selected city range circle + classic Tissot grid
      final centers = <d3g.GeoPosition>[
        fromCity.coords,
        toCity.coords,
        const (-90, 0),
        const (0, 0),
        const (90, 0),
        const (0, 45),
        const (0, -45),
      ];
      for (final c in centers) {
        circleGen.center = c;
        uiPath.reset();
        pathGen.draw(circleGen(), ctx);
        canvas
          ..drawPath(uiPath, tissotFill)
          ..drawPath(uiPath, tissotStroke);
      }
    }

    // 5. Great-circle geoInterpolate flight path between clicked cities
    final interp = d3g.geoInterpolate(fromCity.coords, toCity.coords);
    const steps = 64;
    final arcCoords = <d3g.GeoPosition>[
      for (var i = 0; i <= steps; ++i) interp(i / steps),
    ];
    uiPath.reset();
    pathGen.draw(d3g.GeoLineString(arcCoords), ctx);
    canvas.drawPath(
      uiPath,
      Paint()
        ..color = scheme.error
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // 6. Clickable city markers (clipped automatically via geoPath/stream)
    final markerPaint = Paint()..color = scheme.primary;
    final selectedPaint = Paint()..color = scheme.error;
    final ringPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    for (final city in _cities) {
      d3g.GeoPosition? projected;
      final sink = d3g.GeoStreamCallbacks(
        point: (x, y, [z]) => projected = (x, y),
      );
      d3g.geoStream(d3g.GeoPoint(city.coords), projection.stream(sink));
      if (projected == null) continue;
      final pos = Offset(projected!.$1, projected!.$2);
      final isSelected = city.name == fromCity.name || city.name == toCity.name;
      final r = isSelected ? 6.0 : 4.0;
      canvas
        ..drawCircle(pos, r, isSelected ? selectedPaint : markerPaint)
        ..drawCircle(pos, r, ringPaint);
      if (isSelected) {
        TextPainter(
            text: TextSpan(
              text: city.name,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                shadows: [
                  Shadow(
                    color: isDark ? Colors.black : Colors.white,
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            textDirection: TextDirection.ltr,
          )
          ..layout()
          ..paint(canvas, pos + const Offset(8, -7));
      }
    }
  }

  @override
  bool shouldRepaint(_GeoMapPainter oldDelegate) => true;
}
