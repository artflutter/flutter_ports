## Unreleased

- BREAKING: the options `mode`, `scaleMode` and `overScaleMode` of `ZoomOptions` and `PanOptions` are a
  sealed `ModeOption` (Zoom ADR 0008): a `Mode`, or a `ModeFromChart` that holds a `ModeFn`. A `Mode`
  value is unchanged; a function becomes `ModeFromChart((context) => ...)`. A value of another type
  no longer compiles.

## 0.1.0-beta.3

- On `flutter_chartjs_port` 0.1.0-beta.4.
- `LimitOptions` is a class (Zoom ADR 0007): `x` and `y` give the limits of a direction, and
  `axes` gives the limits of one axis object of a typed config. The limits of an axis win over
  the limits of its direction: `LimitOptions(x: ScaleLimits(minRange: 50), axes: {right: ...})`.
- `ZoomPlugin` is the class of `zoomPlugin`: `registry.getPlugin<ZoomPlugin>()` finds it.
- The plugin writes the scale range through `Scale.setRange` and `Scale.clearRange` of the host.

## 0.1.0-beta.2

- README: remove the status note of the port phases.
- pubspec: remove "Work in progress." from the description.

## 0.1.0-beta.1

- The first beta release, on `flutter_chartjs_port` 0.1.0-beta.2. The API can still change
  before 0.1.0.

- Ports each module of `src/` at 2.2.0+fb81d331: the zoom and pan API (`ZoomChart`), the wheel and
  drag zoom, the pointer pan and pinch, the scale limits and the plugin object `zoomPlugin`, on the
  public libraries of `flutter_chartjs_port`.
- Ports the upstream specs and the 12 fixtures. Port-only tests drive a `ChartView` with real
  pointer and key input.

## 0.0.1

- Initial scaffold. Tracks chartjs-plugin-zoom 2.2.0+fb81d331, a commit of `master` after the
  release v2.2.0. The package has no ported code.
