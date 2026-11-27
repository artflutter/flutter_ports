## 0.1.0

- Initial release: native, fully statically typed Dart port of `d3-geo` 3.1.1.
- Sealed typed GeoJSON hierarchy (`GeoJsonObject`, `GeoSphere`, `GeoPoint`,
  `GeoMultiPoint`, `GeoLineString`, `GeoMultiLineString`, `GeoPolygon`,
  `GeoMultiPolygon`, `GeoGeometryCollection`, `GeoFeature<P>`,
  `GeoFeatureCollection<P>`), typed `GeoStream`, `GeoTransform`, `GeoRotation`,
  `GeoPath`, `GeoGraticuleGenerator`, `GeoCircleGenerator`, and all 15 built-in
  projections + 13 `*Raw` projection primitives.
- Pure Dart library (`d3_geo.dart`) plus direct Flutter `dart:ui.Path` helpers
  (`flutter_d3_geo_port.dart`) powered by `UiPathContext`.
