// Ported from d3-interpolate v3.0.1 src/index.js (ISC, Mike Bostock).

/// Port of `src/index.js` of d3-interpolate 3.0.1: the public names of
/// d3-interpolate.
///
/// The names follow index.js, with three changes of the typed values of the
/// port. `interpolateObject` (src/object.js) and `interpolateString`
/// (src/string.js) have no Dart form: the generic `interpolate` takes typed
/// values only. `interpolateTransformCss` and `interpolateTransformSvg`
/// parse a CSS or SVG transform text; the port has no text parse, so it
/// exports `decompose`, `TransformParts` and `interpolateTransform`, the
/// interpolator of two decomposed transforms. The callable classes
/// `InterpolateRgb`, `InterpolateCubehelix` and `InterpolateZoom` hold the
/// function properties `gamma` and `rho`, and `ZoomInterpolator` holds
/// `duration`.
///
/// The exports are in the order of their paths (the lint
/// `directives_ordering`), not in the order of index.js. A name that
/// index.js renames (`hslLong as interpolateHslLong`) is a constant of this
/// file (D3 ADR 0008 §6).
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_interpolate_port/d3_interpolate.dart';

export 'package:flutter_d3_interpolate_port/src/array.dart';
export 'package:flutter_d3_interpolate_port/src/basis.dart';
export 'package:flutter_d3_interpolate_port/src/basisClosed.dart';
export 'package:flutter_d3_interpolate_port/src/cubehelix.dart';
export 'package:flutter_d3_interpolate_port/src/date.dart';
export 'package:flutter_d3_interpolate_port/src/discrete.dart';
export 'package:flutter_d3_interpolate_port/src/hcl.dart';
export 'package:flutter_d3_interpolate_port/src/hsl.dart';
export 'package:flutter_d3_interpolate_port/src/hue.dart';
export 'package:flutter_d3_interpolate_port/src/lab.dart';
export 'package:flutter_d3_interpolate_port/src/number.dart';
export 'package:flutter_d3_interpolate_port/src/numberArray.dart';
// DIVERGES(d3-interpolate): adapt-interpolate-typed-values, no object.js.
export 'package:flutter_d3_interpolate_port/src/piecewise.dart';
export 'package:flutter_d3_interpolate_port/src/quantize.dart';
export 'package:flutter_d3_interpolate_port/src/rgb.dart';
export 'package:flutter_d3_interpolate_port/src/round.dart';
// DIVERGES(d3-interpolate): adapt-interpolate-typed-values, no string.js.
// DIVERGES(d3-interpolate): adapt-interpolate-typed-transform, no Css, Svg.
export 'package:flutter_d3_interpolate_port/src/transform/decompose.dart';
export 'package:flutter_d3_interpolate_port/src/transform/index.dart';
export 'package:flutter_d3_interpolate_port/src/value.dart';
export 'package:flutter_d3_interpolate_port/src/zoom.dart';

/// index.js:15 `rgbBasis as interpolateRgbBasis`: a uniform nonrational
/// B-spline through a list of colors in RGB, `rgbBasis` of rgb.dart.
const Rgb Function(double t) Function(List<Color> colors) interpolateRgbBasis =
    rgbBasis;

/// index.js:15 `rgbBasisClosed as interpolateRgbBasisClosed`: a closed
/// uniform nonrational B-spline through a list of colors in RGB,
/// `rgbBasisClosed` of rgb.dart.
const Rgb Function(double t) Function(List<Color> colors)
interpolateRgbBasisClosed = rgbBasisClosed;

/// index.js:16 `hslLong as interpolateHslLong`: the interpolator of two
/// colors in HSL, with no shortest path between the hues, `hslLong` of
/// hsl.dart.
const Hsl Function(double t) Function(Color start, Color end)
interpolateHslLong = hslLong;

/// index.js:18 `hclLong as interpolateHclLong`: the interpolator of two
/// colors in HCL, with no shortest path between the hues, `hclLong` of
/// hcl.dart.
const Hcl Function(double t) Function(Color start, Color end)
interpolateHclLong = hclLong;

/// index.js:19 `cubehelixLong as interpolateCubehelixLong`: the Cubehelix
/// interpolator factory with no shortest path between the hues, with the
/// gamma 1 and its method `gamma`, `cubehelixLong` of cubehelix.dart.
///
/// The constant is of the class [InterpolateCubehelix], which
/// this file exports.
const InterpolateCubehelix interpolateCubehelixLong = cubehelixLong;
