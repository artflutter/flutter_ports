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

import 'package:flutter_d3_color_port/d3_color.dart' show Color, Hcl, Hsl, Rgb;
import 'package:flutter_d3_interpolate_port/src/cubehelix.dart' as cubehelix;
import 'package:flutter_d3_interpolate_port/src/hcl.dart' as hcl;
import 'package:flutter_d3_interpolate_port/src/hsl.dart' as hsl;
import 'package:flutter_d3_interpolate_port/src/rgb.dart' as rgb;

export 'package:flutter_d3_interpolate_port/src/array.dart'
    show interpolateArray;
export 'package:flutter_d3_interpolate_port/src/basis.dart'
    show interpolateBasis;
export 'package:flutter_d3_interpolate_port/src/basisClosed.dart'
    show interpolateBasisClosed;
export 'package:flutter_d3_interpolate_port/src/cubehelix.dart'
    show InterpolateCubehelix, interpolateCubehelix;
export 'package:flutter_d3_interpolate_port/src/date.dart' show interpolateDate;
export 'package:flutter_d3_interpolate_port/src/discrete.dart'
    show interpolateDiscrete;
export 'package:flutter_d3_interpolate_port/src/hcl.dart' show interpolateHcl;
export 'package:flutter_d3_interpolate_port/src/hsl.dart' show interpolateHsl;
export 'package:flutter_d3_interpolate_port/src/hue.dart' show interpolateHue;
export 'package:flutter_d3_interpolate_port/src/lab.dart' show interpolateLab;
export 'package:flutter_d3_interpolate_port/src/number.dart'
    show interpolateNumber;
export 'package:flutter_d3_interpolate_port/src/numberArray.dart'
    show interpolateNumberArray;
// DIVERGES(d3-interpolate): adapt-interpolate-typed-values, no object.js.
export 'package:flutter_d3_interpolate_port/src/piecewise.dart' show piecewise;
export 'package:flutter_d3_interpolate_port/src/quantize.dart' show quantize;
export 'package:flutter_d3_interpolate_port/src/rgb.dart'
    show InterpolateRgb, interpolateRgb;
export 'package:flutter_d3_interpolate_port/src/round.dart'
    show interpolateRound;
// DIVERGES(d3-interpolate): adapt-interpolate-typed-values, no string.js.
// DIVERGES(d3-interpolate): adapt-interpolate-typed-transform, no Css, Svg.
export 'package:flutter_d3_interpolate_port/src/transform/decompose.dart'
    show TransformParts, decompose;
export 'package:flutter_d3_interpolate_port/src/transform/index.dart'
    show interpolateTransform;
export 'package:flutter_d3_interpolate_port/src/value.dart' show interpolate;
export 'package:flutter_d3_interpolate_port/src/zoom.dart'
    show InterpolateZoom, ZoomInterpolator, ZoomView, interpolateZoom;

/// index.js:15 `rgbBasis as interpolateRgbBasis`: a uniform nonrational
/// B-spline through a list of colors in RGB, `rgbBasis` of rgb.dart.
const Rgb Function(double t) Function(List<Color> colors) interpolateRgbBasis =
    rgb.rgbBasis;

/// index.js:15 `rgbBasisClosed as interpolateRgbBasisClosed`: a closed
/// uniform nonrational B-spline through a list of colors in RGB,
/// `rgbBasisClosed` of rgb.dart.
const Rgb Function(double t) Function(List<Color> colors)
interpolateRgbBasisClosed = rgb.rgbBasisClosed;

/// index.js:16 `hslLong as interpolateHslLong`: the interpolator of two
/// colors in HSL, with no shortest path between the hues, `hslLong` of
/// hsl.dart.
const Hsl Function(double t) Function(Color start, Color end)
interpolateHslLong = hsl.hslLong;

/// index.js:18 `hclLong as interpolateHclLong`: the interpolator of two
/// colors in HCL, with no shortest path between the hues, `hclLong` of
/// hcl.dart.
const Hcl Function(double t) Function(Color start, Color end)
interpolateHclLong = hcl.hclLong;

/// index.js:19 `cubehelixLong as interpolateCubehelixLong`: the Cubehelix
/// interpolator factory with no shortest path between the hues, with the
/// gamma 1 and its method `gamma`, `cubehelixLong` of cubehelix.dart.
///
/// The constant is of the class [cubehelix.InterpolateCubehelix], which
/// this file exports.
const cubehelix.InterpolateCubehelix interpolateCubehelixLong =
    cubehelix.cubehelixLong;
