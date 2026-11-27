// Original code, not ported from d3-geo: sealed typed GeoJSON hierarchy.

/// Sealed statically typed GeoJSON geometry and feature hierarchy for `d3-geo`
/// (D3 ADR 0024).
///
/// Provides zero-`dynamic` geometry values (`GeoSphere`, `GeoPoint`,
/// `GeoMultiPoint`, `GeoLineString`, `GeoMultiLineString`, `GeoPolygon`,
/// `GeoMultiPolygon`, `GeoGeometryCollection`, `GeoFeature<P>`,
/// `GeoFeatureCollection<P>`), typed [GeoPosition] / [GeoExtent] records, and
/// optional `fromJson` / `toJson` converters on `Map<String, Object?>`.
library;

/// A 2D geographic or planar coordinate `(lon, lat)` or `(x, y)`.
typedef GeoPosition = (double lon, double lat);

/// A 2D bounding extent `((x0, y0), (x1, y1))` or
/// `((lon0, lat0), (lon1, lat1))`.
typedef GeoExtent = (GeoPosition min, GeoPosition max);

/// Three-axis spherical Euler rotation angles `(lambda, phi, gamma)` in
/// degrees.
typedef GeoRotationAngles = (double lambda, double phi, double gamma);

/// Base sealed class for all GeoJSON objects accepted by `d3-geo` functions.
sealed class const GeoJsonObject() {
  /// Creates a [GeoJsonObject].
  this;

  /// The GeoJSON `type` discriminator (e.g. `'Point'`, `'Polygon'`, `'Sphere'`,
  /// `'Feature'`, `'FeatureCollection'`).
  String get type;

  /// Serializes this object to a JSON-compatible map.
  Map<String, Object?> toJson();

  /// Parses a GeoJSON `Map<String, Object?>` into a typed [GeoJsonObject].
  ///
  /// Throws [FormatException] when `type` is missing or unrecognized.
  static GeoJsonObject fromJson(Map<String, Object?> json) {
    final type = json['type'];
    return switch (type) {
      'Sphere' => const GeoSphere(),
      'Point' => GeoPoint.fromJson(json),
      'MultiPoint' => GeoMultiPoint.fromJson(json),
      'LineString' => GeoLineString.fromJson(json),
      'MultiLineString' => GeoMultiLineString.fromJson(json),
      'Polygon' => GeoPolygon.fromJson(json),
      'MultiPolygon' => GeoMultiPolygon.fromJson(json),
      'GeometryCollection' => GeoGeometryCollection.fromJson(json),
      'Feature' => GeoFeature<Map<String, Object?>>.fromJson(json),
      'FeatureCollection' =>
        GeoFeatureCollection<Map<String, Object?>>.fromJson(json),
      _ => throw FormatException('Unsupported GeoJSON type: $type'),
    };
  }
}

/// Base sealed class for all GeoJSON geometry objects (including D3's
/// `GeoSphere`).
sealed class const GeoGeometry() extends GeoJsonObject {
  /// Creates a [GeoGeometry].
  this;

  /// Parses a GeoJSON geometry map into a typed [GeoGeometry].
  ///
  /// Returns `null` when [json] is `null`. Throws [FormatException] on unknown
  /// geometry types.
  static GeoGeometry? fromJson(Map<String, Object?>? json) {
    if (json == null) return null;
    final type = json['type'];
    return switch (type) {
      'Sphere' => const GeoSphere(),
      'Point' => GeoPoint.fromJson(json),
      'MultiPoint' => GeoMultiPoint.fromJson(json),
      'LineString' => GeoLineString.fromJson(json),
      'MultiLineString' => GeoMultiLineString.fromJson(json),
      'Polygon' => GeoPolygon.fromJson(json),
      'MultiPolygon' => GeoMultiPolygon.fromJson(json),
      'GeometryCollection' => GeoGeometryCollection.fromJson(json),
      _ => throw FormatException('Unsupported GeoJSON geometry type: $type'),
    };
  }
}

/// The whole unit sphere (`{type: "Sphere"}`).
final class const GeoSphere() extends GeoGeometry {
  /// Creates a [GeoSphere].
  this;

  @override
  String get type => 'Sphere';

  @override
  Map<String, Object?> toJson() => <String, Object?>{'type': 'Sphere'};
}

/// A GeoJSON `Point` geometry with a single [coordinates] position and optional
/// third coordinate [elevation].
final class const GeoPoint(
  /// Position `(lon, lat)` or `(x, y)`.
  final GeoPosition coordinates, {

  /// Optional third coordinate (`z` / elevation) forwarded to `GeoStream.point`.
  final double? elevation,
}) extends GeoGeometry {
  /// Creates a [GeoPoint] at [coordinates] with optional [elevation].
  this;

  /// Parses a GeoJSON `Point` map.
  factory fromJson(Map<String, Object?> json) {
    final raw = json['coordinates']! as List<Object?>;
    final (pos, z) = _parsePosition(raw);
    return GeoPoint(pos, elevation: z);
  }

  @override
  String get type => 'Point';

  @override
  Map<String, Object?> toJson() => <String, Object?>{
    'type': 'Point',
    'coordinates': _encodePosition(coordinates, elevation),
  };
}

/// A GeoJSON `MultiPoint` geometry.
final class const GeoMultiPoint(
  /// Sequence of positions.
  final List<GeoPosition> coordinates, {

  /// Optional parallel list of third coordinates (`z`).
  final List<double?>? elevations,
}) extends GeoGeometry {
  /// Creates a [GeoMultiPoint] from [coordinates] and optional [elevations].
  this;

  /// Parses a GeoJSON `MultiPoint` map.
  factory fromJson(Map<String, Object?> json) {
    final raw = json['coordinates']! as List<Object?>;
    final (coords, zs) = _parsePositionList(raw);
    return GeoMultiPoint(coords, elevations: zs);
  }

  @override
  String get type => 'MultiPoint';

  @override
  Map<String, Object?> toJson() => <String, Object?>{
    'type': 'MultiPoint',
    'coordinates': _encodePositionList(coordinates, elevations),
  };
}

/// A GeoJSON `LineString` geometry.
final class const GeoLineString(
  /// Sequence of vertices along the line.
  final List<GeoPosition> coordinates, {

  /// Optional parallel list of third coordinates (`z`).
  final List<double?>? elevations,
}) extends GeoGeometry {
  /// Creates a [GeoLineString] from [coordinates] and optional [elevations].
  this;

  /// Parses a GeoJSON `LineString` map.
  factory fromJson(Map<String, Object?> json) {
    final raw = json['coordinates']! as List<Object?>;
    final (coords, zs) = _parsePositionList(raw);
    return GeoLineString(coords, elevations: zs);
  }

  @override
  String get type => 'LineString';

  @override
  Map<String, Object?> toJson() => <String, Object?>{
    'type': 'LineString',
    'coordinates': _encodePositionList(coordinates, elevations),
  };
}

/// A GeoJSON `MultiLineString` geometry.
final class const GeoMultiLineString(
  /// Lines, each a list of vertices.
  final List<List<GeoPosition>> coordinates, {

  /// Optional parallel nested lists of third coordinates (`z`).
  final List<List<double?>?>? elevations,
}) extends GeoGeometry {
  /// Creates a [GeoMultiLineString] from [coordinates] and optional
  /// [elevations].
  this;

  /// Parses a GeoJSON `MultiLineString` map.
  factory fromJson(Map<String, Object?> json) {
    final raw = json['coordinates']! as List<Object?>;
    final (lines, zs) = _parseRingList(raw);
    return GeoMultiLineString(lines, elevations: zs);
  }

  @override
  String get type => 'MultiLineString';

  @override
  Map<String, Object?> toJson() => <String, Object?>{
    'type': 'MultiLineString',
    'coordinates': _encodeRingList(coordinates, elevations),
  };
}

/// A GeoJSON `Polygon` geometry (exterior ring followed by zero or more holes).
final class const GeoPolygon(
  /// Closed linear rings (first and last position coincide).
  final List<List<GeoPosition>> coordinates, {

  /// Optional parallel nested lists of third coordinates (`z`).
  final List<List<double?>?>? elevations,
}) extends GeoGeometry {
  /// Creates a [GeoPolygon] from [coordinates] and optional [elevations].
  this;

  /// Parses a GeoJSON `Polygon` map.
  factory fromJson(Map<String, Object?> json) {
    final raw = json['coordinates']! as List<Object?>;
    final (rings, zs) = _parseRingList(raw);
    return GeoPolygon(rings, elevations: zs);
  }

  @override
  String get type => 'Polygon';

  @override
  Map<String, Object?> toJson() => <String, Object?>{
    'type': 'Polygon',
    'coordinates': _encodeRingList(coordinates, elevations),
  };
}

/// A GeoJSON `MultiPolygon` geometry.
final class const GeoMultiPolygon(
  /// Polygons, each a list of closed linear rings.
  final List<List<List<GeoPosition>>> coordinates, {

  /// Optional parallel nested lists of third coordinates (`z`).
  final List<List<List<double?>?>?>? elevations,
}) extends GeoGeometry {
  /// Creates a [GeoMultiPolygon] from [coordinates] and optional [elevations].
  this;

  /// Parses a GeoJSON `MultiPolygon` map.
  factory fromJson(Map<String, Object?> json) {
    final raw = json['coordinates']! as List<Object?>;
    final polygons = <List<List<GeoPosition>>>[];
    List<List<List<double?>?>?>? allZs;
    for (var i = 0; i < raw.length; ++i) {
      final (rings, zs) = _parseRingList(raw[i]! as List<Object?>);
      polygons.add(rings);
      if (zs != null) {
        allZs ??= List<List<List<double?>?>?>.filled(raw.length, null);
        allZs[i] = zs;
      }
    }
    return GeoMultiPolygon(polygons, elevations: allZs);
  }

  @override
  String get type => 'MultiPolygon';

  @override
  Map<String, Object?> toJson() => <String, Object?>{
    'type': 'MultiPolygon',
    'coordinates': <List<List<List<double>>>>[
      for (var i = 0; i < coordinates.length; ++i)
        _encodeRingList(
          coordinates[i],
          elevations != null && i < elevations!.length ? elevations![i] : null,
        ),
    ],
  };
}

/// A GeoJSON `GeometryCollection` containing zero or more [geometries].
final class const GeoGeometryCollection(
  /// Member geometries (`null` entries are ignored during streaming).
  final List<GeoGeometry?> geometries,
) extends GeoGeometry {
  /// Creates a [GeoGeometryCollection] containing [geometries].
  this;

  /// Parses a GeoJSON `GeometryCollection` map.
  factory fromJson(Map<String, Object?> json) {
    final raw = json['geometries']! as List<Object?>;
    return GeoGeometryCollection(<GeoGeometry?>[
      for (final item in raw)
        GeoGeometry.fromJson(item as Map<String, Object?>?),
    ]);
  }

  @override
  String get type => 'GeometryCollection';

  @override
  Map<String, Object?> toJson() => <String, Object?>{
    'type': 'GeometryCollection',
    'geometries': <Map<String, Object?>?>[
      for (final g in geometries) g?.toJson(),
    ],
  };
}

/// A GeoJSON `Feature` wrapping a nullable [geometry] and typed [properties].
final class const GeoFeature<P>({
  /// The feature's geometry, or `null` for an unlocated feature.
  final GeoGeometry? geometry,

  /// Optional strongly typed properties payload.
  final P? properties,

  /// Optional feature identifier string.
  final String? id,
}) extends GeoJsonObject {
  /// Creates a [GeoFeature] with optional [geometry], [properties], and [id].
  this;

  /// Parses a GeoJSON `Feature` map.
  ///
  /// Supply [propertiesFromJson] to decode `json['properties']` into [P].
  /// When [propertiesFromJson] is omitted and `P` accepts
  /// `Map<String, Object?>`, the raw properties map is passed through.
  factory fromJson(
    Map<String, Object?> json, {
    P Function(Map<String, Object?>)? propertiesFromJson,
  }) {
    final geomMap = json['geometry'] as Map<String, Object?>?;
    final rawProps = json['properties'] as Map<String, Object?>?;
    final P? props;
    if (rawProps == null) {
      props = null;
    } else if (propertiesFromJson != null) {
      props = propertiesFromJson(rawProps);
    } else {
      props = rawProps as P;
    }
    final rawId = json['id'];
    return GeoFeature<P>(
      geometry: GeoGeometry.fromJson(geomMap),
      properties: props,
      id: rawId?.toString(),
    );
  }

  @override
  String get type => 'Feature';

  @override
  Map<String, Object?> toJson({
    Map<String, Object?> Function(P)? propertiesToJson,
  }) {
    final props = properties;
    return <String, Object?>{
      'type': 'Feature',
      if (id != null) 'id': id,
      'geometry': geometry?.toJson(),
      'properties': props == null
          ? null
          : propertiesToJson != null
          ? propertiesToJson(props)
          : props is Map<String, Object?>
          ? props
          : null,
    };
  }
}

/// A GeoJSON `FeatureCollection` containing a typed list of [features].
final class const GeoFeatureCollection<P>(
  /// Features in this collection.
  final List<GeoFeature<P>> features,
) extends GeoJsonObject {
  /// Creates a [GeoFeatureCollection] from [features].
  this;

  /// Parses a GeoJSON `FeatureCollection` map.
  factory fromJson(
    Map<String, Object?> json, {
    P Function(Map<String, Object?>)? propertiesFromJson,
  }) {
    final raw = json['features']! as List<Object?>;
    return GeoFeatureCollection<P>(<GeoFeature<P>>[
      for (final item in raw)
        GeoFeature<P>.fromJson(
          item! as Map<String, Object?>,
          propertiesFromJson: propertiesFromJson,
        ),
    ]);
  }

  @override
  String get type => 'FeatureCollection';

  @override
  Map<String, Object?> toJson({
    Map<String, Object?> Function(P)? propertiesToJson,
  }) => <String, Object?>{
    'type': 'FeatureCollection',
    'features': <Map<String, Object?>>[
      for (final f in features) f.toJson(propertiesToJson: propertiesToJson),
    ],
  };
}

(GeoPosition, double?) _parsePosition(List<Object?> raw) {
  final lon = (raw[0]! as num).toDouble();
  final lat = (raw[1]! as num).toDouble();
  final z = raw.length > 2 && raw[2] != null
      ? (raw[2]! as num).toDouble()
      : null;
  return ((lon, lat), z);
}

(List<GeoPosition>, List<double?>?) _parsePositionList(List<Object?> raw) {
  final n = raw.length;
  final coords = <GeoPosition>[];
  List<double?>? zs;
  for (var i = 0; i < n; ++i) {
    final (pos, z) = _parsePosition(raw[i]! as List<Object?>);
    coords.add(pos);
    if (z != null) {
      zs ??= List<double?>.filled(n, null);
      zs[i] = z;
    }
  }
  return (coords, zs);
}

(List<List<GeoPosition>>, List<List<double?>?>?) _parseRingList(
  List<Object?> raw,
) {
  final n = raw.length;
  final rings = <List<GeoPosition>>[];
  List<List<double?>?>? allZs;
  for (var i = 0; i < n; ++i) {
    final (ring, zs) = _parsePositionList(raw[i]! as List<Object?>);
    rings.add(ring);
    if (zs != null) {
      allZs ??= List<List<double?>?>.filled(n, null);
      allZs[i] = zs;
    }
  }
  return (rings, allZs);
}

List<double> _encodePosition(GeoPosition pos, double? z) =>
    z == null ? <double>[pos.$1, pos.$2] : <double>[pos.$1, pos.$2, z];

List<List<double>> _encodePositionList(
  List<GeoPosition> coords,
  List<double?>? zs,
) => <List<double>>[
  for (var i = 0; i < coords.length; ++i)
    _encodePosition(coords[i], zs != null && i < zs.length ? zs[i] : null),
];

List<List<List<double>>> _encodeRingList(
  List<List<GeoPosition>> rings,
  List<List<double?>?>? allZs,
) => <List<List<double>>>[
  for (var i = 0; i < rings.length; ++i)
    _encodePositionList(
      rings[i],
      allZs != null && i < allZs.length ? allZs[i] : null,
    ),
];
