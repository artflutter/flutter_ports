// Original code, not ported from Chart.js: the dart:ui canvas context.

/// The `dart:ui` implementation of the canvas layer (Chart.js ADR 0013 and
/// 0015, porting-flow.md 2.2 and 2.8).
///
/// [UiCanvasElement] stands for the HTML `<canvas>`: it has the bitmap size
/// in device pixels, a style and one [UiCanvasContext].
///
/// The context keeps a retained bitmap as `ui.Picture`s:
/// - Draw calls record into a `ui.PictureRecorder`. The content of the
///   canvas is the list of pictures recorded since the last full clear.
/// - A `clearRect` that covers the whole canvas, with no clip, drops the
///   list. `clearCanvas` does that at the start of each chart render, so
///   a chart frame starts a new paint generation.
/// - A partial `clearRect` draws with `BlendMode.clear`. A composite
///   operation other than `source-over` blends with the content. Then
///   [UiCanvasContext.paint] draws the pictures inside a layer, so that
///   the clear does not reach what is below the canvas.
/// - [UiCanvasContext.paint] ends the current recording. When more than a
///   few paint generations pile up without a full clear, the context flattens
///   them into one image of the bitmap size, so that memory stays bounded.
/// - A host with no need for such a layer adds the pictures to its scene
///   instead ([UiCanvasContext.addPicturesToScene], Chart.js ADR 0097).
/// - [UiCanvasContext.onChanged] tells the host that the content changed,
///   once until the next paint.
///
/// The device pixel ratio (DPR): `RenderView` already scales the scene by
/// the DPR. The pictures are in bitmap pixels, the space of the DOM
/// bitmap. The host gives [UiCanvasContext.paint] the scale from bitmap
/// pixels to logical pixels: the display size over the bitmap size, which
/// is `1 / DPR` after `retinaScale`. `retinaScale` also sets
/// `setTransform(dpr, 0, 0, dpr, 0, 0)`, so the net transform is the
/// identity in logical pixels. A DPR change does not touch the content: a
/// bitmap drawn at one DPR shows at the same display size until the chart
/// redraws it.
///
/// The current path is in bitmap space: the transform applies when a point
/// is added (`canvas_ui_path.dart`). Strokes scale the line width and the
/// dash by the transform. A path is outside `save()` and `restore()`. The
/// clip is part of the state.
library;

import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_arc_sector.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_circle_run.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_colors.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_dense_curve.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_font_tracking.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_line_fan.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_partitioned_fill.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_rect_bar.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui_batch.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui_paint.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui_path.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui_text.dart';
import 'package:meta/meta.dart';

export 'package:flutter_chartjs_port/src/canvas/canvas_ui_paint.dart'
    show UiCanvasGradient, UiCanvasPattern, UiImageSource;
export 'package:flutter_chartjs_port/src/canvas/canvas_ui_text.dart'
    show CanvasFont, parseCanvasFont;

/// The retained paint generations before flattening (ADR 0066). A large
/// generation can span multiple pictures without triggering rasterization.
const int _maxPaintGenerations = 8;

/// Bound native drawPicture's spatial-index consolidation. A pending circle
/// run that draws with the atlas does not consume this budget. A run that
/// draws each circle does, when the next circle ends it (Chart.js ADR 0097).
const int _maxPictureDraws = 256;

/// The largest center coordinate and radius of a sector that
/// [UiCanvasContext.tryDrawArcSector] takes, in bitmap pixels. Below it, the
/// rounding of the path points stays far below the tolerance of
/// [UiPathBuilder.singleSector], so the ordinary path is a sector too.
const double _maxSectorExtent = 100000;

/// The smallest inner radius and ring width of such a sector, in bitmap
/// pixels: far above that tolerance.
const double _minSectorWidth = 1e-3;

/// The largest absolute angle of such a sector, in radians, for the same
/// reason.
const double _maxSectorAngle = 1000;

/// The largest sweep of such a sector, in radians.
const double _maxSectorSweep = 2 * math.pi - 1e-6;

/// The largest sweep of a run of sectors, in radians: below a full turn, so
/// that `drawArc` keeps its two end angles.
const double _maxSectorRunSweep = 2 * math.pi - 1e-3;

/// The largest gap between two sectors of a run, in radians. The angles of
/// `pathArc` round by a few bits, so two neighbors do not meet exactly. At the
/// largest radius of a sector, this gap is 1e-4 bitmap pixels.
const double _maxSectorRunGap = 1e-9;

/// The largest absolute coordinate of a line of a fan, in bitmap pixels. Below
/// it, a `Float32List` element and the argument of `drawLine` narrow to one
/// finite float. The engine clamps the argument instead of giving Infinity.
const double _maxLineFanExtent = 1e30;

const ui.Color _black = ui.Color(0xFF000000);
const ui.Color _transparent = ui.Color(0x00000000);

const String _defaultFontString = '10px sans-serif';

/// The step of the rotation of drawn text: 2 degrees (see
/// `UiCanvasContext._snappedTextMatrix`).
const double _textAngleStep = math.pi / 90;

final CanvasFont _defaultFont = parseCanvasFont(_defaultFontString)!;

const Set<String> _directions = {'ltr', 'rtl', 'inherit'};

/// A map-backed [CSSStyleDeclaration]: the inline style of a
/// [UiCanvasElement], and the reflection of its `style` attribute
/// (Chart.js ADR 0022, section 4).
///
/// The declarations keep their order. A write of an existing property keeps
/// its place, as in the CSSOM. The style does not expand shorthand
/// properties and does not parse values.
final class UiCssStyleDeclaration implements CSSStyleDeclaration {
  /// An empty style.
  UiCssStyleDeclaration();

  final Map<String, (String, String)> _properties = {};

  /// The `style` attribute as it was set, or `null` for no attribute. After
  /// a CSSOM write, [_serialized] is true and the attribute is [cssText].
  String? _attribute;
  bool _serialized = false;

  static String _name(String property) =>
      property.startsWith('--') ? property : property.toLowerCase();

  @override
  String getPropertyValue(String property) =>
      _properties[_name(property)]?.$1 ?? '';

  @override
  String getPropertyPriority(String property) =>
      _properties[_name(property)]?.$2 ?? '';

  /// A [priority] other than `'important'`, `''` or `null` does nothing, as
  /// in the DOM.
  @override
  void setProperty(String property, String? value, [String? priority]) {
    if (priority != null && priority != '' && priority != 'important') {
      return;
    }
    final name = _name(property);
    if (value == null || value.isEmpty) {
      _properties.remove(name);
    } else {
      _properties[name] = (value, priority ?? '');
    }
    // Each write makes the attribute the serialization, also a write that
    // changes nothing. A compare of the old value cost 9 ns more on AOT, and
    // the attribute text is not a behavior of Chart.js ADR 0034.
    _serialized = true;
  }

  /// `cssText`: the declarations as `name: value;`, with ` !important` for
  /// an important one, joined by one space. The CSSOM serializes a
  /// declaration block in this form.
  String get cssText => [
    for (final MapEntry(key: name, value: (value, priority))
        in _properties.entries)
      if (priority.isEmpty) '$name: $value;' else '$name: $value !$priority;',
  ].join(' ');

  /// `cssText = text`: replaces the declarations with the declarations of
  /// [text]. Then the `style` attribute is [cssText], as the CSSOM updates
  /// it after the write.
  set cssText(String text) {
    _properties.clear();
    _parseDeclarations(text);
    _serialized = true;
  }

  /// The `style` attribute of the element: `getAttribute('style')`. It is
  /// the text of [styleAttribute] as it was set, until a CSSOM write
  /// ([setProperty], [cssText]) makes it the serialization [cssText]. It is
  /// `null` when the element has no `style` attribute.
  String? get styleAttribute => _serialized ? cssText : _attribute;

  /// `setAttribute('style', value)`, or `removeAttribute('style')` for
  /// `null`: replaces the declarations with the declarations of [value].
  set styleAttribute(String? value) {
    _attribute = value;
    _serialized = false;
    _properties.clear();
    if (value != null) _parseDeclarations(value);
  }

  static final RegExp _important = RegExp(
    r'!\s*important\s*$',
    caseSensitive: false,
  );

  /// Adds the declarations of [text]: `name: value` items separated by `;`
  /// outside parentheses and quotes, each with an optional `!important`.
  /// An item without a name or a value is ignored. A later normal
  /// declaration does not replace an earlier important one.
  void _parseDeclarations(String text) {
    var start = 0;
    var depth = 0;
    String? quote;
    for (var i = 0; i <= text.length; i++) {
      final char = i < text.length ? text[i] : ';';
      if (quote != null) {
        if (char == quote) quote = null;
      } else if (char == '"' || char == "'") {
        quote = char;
      } else if (char == '(') {
        depth++;
      } else if (char == ')' && depth > 0) {
        depth--;
      } else if (char == ';' && depth == 0) {
        _addDeclaration(text.substring(start, i));
        start = i + 1;
      }
    }
  }

  void _addDeclaration(String item) {
    final colon = item.indexOf(':');
    if (colon < 0) return;
    final name = _name(item.substring(0, colon).trim());
    var value = item.substring(colon + 1).trim();
    var priority = '';
    final important = _important.firstMatch(value);
    if (important != null) {
      value = value.substring(0, important.start).trim();
      priority = 'important';
    }
    if (name.isEmpty || value.isEmpty) return;
    if (priority.isEmpty && _properties[name]?.$2 == 'important') return;
    _properties[name] = (value, priority);
  }
}

/// The `dart:ui` [HTMLCanvasElement]: the bitmap size, the attributes, the
/// style and the one 2D context.
///
/// The `width` and `height` attributes set the bitmap size. The `style`
/// attribute reflects the inline [style] (Chart.js ADR 0022, section 4).
/// Another attribute keeps its value as a string. Attribute names are ASCII
/// case-insensitive, as in an HTML document.
///
/// It is a [CanvasNode]: the chart host that shows it sets [parentNode].
final class UiCanvasElement implements HTMLCanvasElement, CanvasNode {
  /// A canvas with the `width` attribute [width] and the `height` attribute
  /// [height], in device pixels. A `null` size has no attribute and the DOM
  /// default: 300 wide, 150 high.
  UiCanvasElement({int? width, int? height}) {
    if (width != null) this.width = width;
    if (height != null) this.height = height;
  }

  int _width = 300;
  int _height = 150;
  String? _widthAttribute;
  String? _heightAttribute;
  UiCanvasContext? _context;

  /// Setting the width sets the `width` attribute, resets the context state
  /// and clears the bitmap, even to the same value (the DOM rule).
  @override
  int get width => _width;

  @override
  set width(int value) => _setSize('width', '${math.max(0, value)}');

  /// Setting the height sets the `height` attribute, resets the context
  /// state and clears the bitmap, even to the same value (the DOM rule).
  @override
  int get height => _height;

  @override
  set height(int value) => _setSize('height', '${math.max(0, value)}');

  /// The attributes other than `width`, `height` and `style`, by lower-case
  /// name.
  final Map<String, String> _attributes = {};

  @override
  String? getAttribute(String name) => switch (name.toLowerCase()) {
    'width' => _widthAttribute,
    'height' => _heightAttribute,
    'style' => style.styleAttribute,
    final other => _attributes[other],
  };

  /// `setAttribute(name, value)`: `width` and `height` set the bitmap size,
  /// `style` replaces the inline style with the declarations of [value],
  /// and another name keeps [value].
  @override
  void setAttribute(String name, String value) {
    switch (name.toLowerCase()) {
      case 'width' || 'height':
        _setSize(name, value);
      case 'style':
        style.styleAttribute = value;
      case final other:
        _attributes[other] = value;
    }
  }

  /// `removeAttribute(name)`: the removal of `style` empties the inline
  /// style.
  @override
  void removeAttribute(String name) {
    switch (name.toLowerCase()) {
      case 'width' || 'height':
        if (getAttribute(name) != null) _setSize(name, null);
      case 'style':
        style.styleAttribute = null;
      case final other:
        _attributes.remove(other);
    }
  }

  /// Sets the `width` or `height` attribute to [value], or removes it for
  /// `null`, and resets the context. The size is [value] by the HTML rules
  /// for parsing non-negative integers (leading ASCII whitespace, an
  /// optional `+`, the digits up to the first other character, at most
  /// 2147483647), else the default. The DOM also reads `-0` as 0.
  void _setSize(String name, String? value) {
    final digits = value == null ? null : _sizePattern.firstMatch(value)?[1];
    var size = digits == null ? null : int.tryParse(digits);
    if (size != null && size > 0x7FFFFFFF) size = null;
    switch (name.toLowerCase()) {
      case 'width':
        _widthAttribute = value;
        _width = size ?? 300;
      case 'height':
        _heightAttribute = value;
        _height = size ?? 150;
      default:
        return;
    }
    _context?._resetForResize();
  }

  static final RegExp _sizePattern = RegExp(r'^[\t\n\f\r ]*\+?(\d+)');

  @override
  final UiCssStyleDeclaration style = UiCssStyleDeclaration();

  /// The container of the chart host that shows this canvas, or `null`.
  /// The host sets it when it attaches and clears it when it detaches.
  @override
  CanvasContainer? parentNode;

  /// `getContext('2d')`: the one context of this canvas.
  UiCanvasContext getContext2d() => _context ??= UiCanvasContext._(this);

  /// `getContext(contextId)`: the 2D context for `'2d'`, else `null`.
  @override
  UiCanvasContext? getContext(String contextId) =>
      contextId == '2d' ? getContext2d() : null;

  /// The bitmap of this canvas as an image source. Port-only.
  ///
  /// The DOM takes a canvas element where it takes a `CanvasImageSource`
  /// (`createPattern`, `drawImage`) and reads its bitmap at the call.
  /// [HTMLCanvasElement] cannot implement [CanvasImageSource] here (its
  /// `width` is an `int`), so a caller passes this snapshot instead. The
  /// image has [width] x [height] pixels and the caller owns it. A canvas
  /// without pixels throws a [StateError], as the DOM throws an
  /// `InvalidStateError`.
  UiImageSource toImageSource() {
    if (_width == 0 || _height == 0) {
      throw StateError('The canvas has no pixels.');
    }
    return UiImageSource(getContext2d()._snapshot());
  }

  /// `toDataURL(type, quality)`: the data URL of the bitmap at the call.
  ///
  /// A canvas with no pixels gives `'data:,'`, as the HTML standard gives.
  /// Else the call takes the snapshot of the bitmap at once, encodes it as
  /// PNG with `Image.toByteData` and disposes it. Thus a draw after the call
  /// is not in the result. Each [type] gives PNG, [quality] has no effect,
  /// and the bytes differ from the PNG encoder of Chrome.
  // DIVERGES(chartjs): platform-to-base64-image, a Future of a PNG data URL.
  @override
  Future<String> toDataURL([String? type, Object? quality]) async {
    if (_width == 0 || _height == 0) return 'data:,';
    final image = getContext2d()._snapshot();
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = data!.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      return 'data:image/png;base64,${base64Encode(bytes)}';
    } finally {
      image.dispose();
    }
  }
}

/// A clip of a state, in bitmap space.
sealed class _Clip {
  const _Clip();

  void applyTo(ui.Canvas canvas);
}

final class _RectClip extends _Clip {
  const _RectClip(this.rect);

  final ui.Rect rect;

  @override
  void applyTo(ui.Canvas canvas) => canvas.clipRect(rect);
}

final class _RRectClip extends _Clip {
  const _RRectClip(this.rrect);

  final ui.RRect rrect;

  @override
  void applyTo(ui.Canvas canvas) => canvas.clipRRect(rrect);
}

final class _PathClip extends _Clip {
  const _PathClip(this.path);

  final ui.Path path;

  @override
  void applyTo(ui.Canvas canvas) => canvas.clipPath(path);
}

/// One drawing state of the context: what `save()` saves.
final class _State {
  final UiTransform transform = UiTransform();
  ui.Color? fillColor = _black;
  UiShaderSource? fillShader;
  ui.Color? strokeColor = _black;
  UiShaderSource? strokeShader;
  double lineWidth = 1;
  ui.StrokeCap cap = ui.StrokeCap.butt;
  ui.StrokeJoin join = ui.StrokeJoin.miter;
  double miterLimit = 10;
  List<double> lineDash = const [];
  double lineDashOffset = 0;
  String font = _defaultFontString;
  CanvasFont fontValue = _defaultFont;
  ui.TextAlign textAlign = ui.TextAlign.start;
  CanvasTextBaseline textBaseline = CanvasTextBaseline.alphabetic;
  String direction = 'inherit';
  double globalAlpha = 1;
  ui.BlendMode blendMode = ui.BlendMode.srcOver;
  List<_Clip> clips = const [];
  double shadowBlur = 0;
  ui.Color shadowColor = _transparent;
  double shadowOffsetX = 0;
  double shadowOffsetY = 0;

  /// Whether a draw casts a shadow (the HTML rule: a color that is not
  /// transparent, and a blur or an offset). Each fast path tests this field.
  bool shadowOn = false;

  void updateShadowOn() {
    shadowOn =
        shadowColor.a != 0 &&
        (shadowBlur > 0 || shadowOffsetX != 0 || shadowOffsetY != 0);
  }

  void copyFrom(_State other) {
    transform.copyFrom(other.transform);
    fillColor = other.fillColor;
    fillShader = other.fillShader;
    strokeColor = other.strokeColor;
    strokeShader = other.strokeShader;
    lineWidth = other.lineWidth;
    cap = other.cap;
    join = other.join;
    miterLimit = other.miterLimit;
    lineDash = other.lineDash;
    lineDashOffset = other.lineDashOffset;
    font = other.font;
    fontValue = other.fontValue;
    textAlign = other.textAlign;
    textBaseline = other.textBaseline;
    direction = other.direction;
    globalAlpha = other.globalAlpha;
    blendMode = other.blendMode;
    clips = other.clips;
    shadowBlur = other.shadowBlur;
    shadowColor = other.shadowColor;
    shadowOffsetX = other.shadowOffsetX;
    shadowOffsetY = other.shadowOffsetY;
    shadowOn = other.shadowOn;
  }

  static final _State defaults = _State();
}

/// The result of [UiCanvasContext.measureText].
final class _UiTextMetrics implements TextMetrics {
  const _UiTextMetrics({
    required this.width,
    required this.actualBoundingBoxLeft,
    required this.actualBoundingBoxRight,
    required this.actualBoundingBoxAscent,
    required this.actualBoundingBoxDescent,
  });

  @override
  final double width;

  @override
  final double actualBoundingBoxLeft;

  @override
  final double actualBoundingBoxRight;

  @override
  final double actualBoundingBoxAscent;

  @override
  final double actualBoundingBoxDescent;
}

/// The `dart:ui` [CanvasRenderingContext2D] of a [UiCanvasElement].
///
/// See the library comment for the picture model. The host calls [paint]
/// in its paint phase and repaints when [onChanged] fires.
final class UiCanvasContext
    implements
        CanvasRenderingContext2D,
        CanvasTextMetricsSource,
        RectBarCanvas,
        ArcSectorCanvas,
        LineFanCanvas,
        PartitionedFillCanvas,
        CircleRunCanvas,
        DenseCurveCanvas {
  UiCanvasContext._(this._element) {
    _s = _states[0];
    _path = UiPathBuilder(_s.transform);
  }

  // The bitmap scale of x for the merge of the curves of a dense line
  // (Chart.js ADR 0114). A shadow keeps the upstream geometry, as it does for
  // each other fast path.
  @override
  double? get denseCurveScale {
    final s = _s;
    final t = s.transform;
    if (_disposed || s.shadowOn || !t.isAxisAligned || !t.isInvertible) {
      return null;
    }
    final scale = t.a.abs();
    return scale.isFinite && scale > 0 ? scale : null;
  }

  final UiCanvasElement _element;

  @override
  Object? get textMetricsGeneration => trackedTextMetricsGeneration();

  final List<_State> _states = [_State()];
  int _depth = 0;
  late _State _s;
  late final UiPathBuilder _path;

  final ui.Path _scratch = ui.Path();
  final Float64List _m4 = Float64List(16);

  final ui.Paint _fillPaint = ui.Paint();
  final ui.Paint _strokePaint = ui.Paint()..style = ui.PaintingStyle.stroke;
  // The fill of a ring sector: the stroke of its middle circle with butt
  // caps ([_fillSector]).
  final ui.Paint _sectorPaint = ui.Paint()..style = ui.PaintingStyle.stroke;
  final ui.Paint _imagePaint = ui.Paint()..filterQuality = ui.FilterQuality.low;
  final ui.Paint _clearPaint = ui.Paint()..blendMode = ui.BlendMode.clear;
  final ui.Paint _layerPaint = ui.Paint();

  ui.PictureRecorder? _recorder;
  ui.Canvas? _canvas;
  // Full-circle fills and strokes not drawn yet. Every other access to the
  // recording canvas draws them first, so the draw order stays.
  final CircleBatch _batch = CircleBatch();
  // Adjacent sector fills of one color not drawn yet, in bitmap space
  // (Chart.js ADR 0097). As for the circles, every other access to the
  // recording canvas draws them first. At most one of the two runs waits.
  int _sectorRun = 0;
  double _runX = 0;
  double _runY = 0;
  double _runRadius = 0;
  double _runInner = 0;
  double _runStart = 0;
  double _runSweep = 0;
  // The end of the last sector in user space, and the rotation of its
  // transform: the next sector goes on from it in user space, with no rounding
  // of the mapped angles.
  double _runEnd = 0;
  double _runAngle = 0;
  bool _runReflected = false;
  ui.Color _runColor = _black;
  final ui.Paint _runPaint = ui.Paint();
  // The numbers of the last line fan, kept for the next one: a redraw has the
  // same count ([tryStrokeLineFan]).
  Float64List? _fanEnds;
  Float32List? _fanPoints;
  bool _hasContent = false;
  int _pictureDraws = 0;
  int _paintGenerations = 0;
  bool _generationHasContent = false;
  final List<ui.Picture> _pictures = [];
  ui.Image? _flatImage;
  bool _needsLayer = false;
  bool _notified = false;
  bool _disposed = false;
  void Function()? _onChanged;

  @override
  UiCanvasElement get canvas => _element;

  /// Called when the content changes, once until the next [paint]. The
  /// host marks itself as needing paint.
  void Function()? get onChanged => _onChanged;

  set onChanged(void Function()? callback) {
    _onChanged = callback;
    _notified = false;
  }

  /// The canvas has no content: nothing drawn since the last full clear.
  bool get isEmpty => _pictures.isEmpty && !_hasContent;

  /// The count of retained pictures, for tests.
  @visibleForTesting
  int get debugPictureCount => _pictures.length + (_hasContent ? 1 : 0);

  /// The count of the fills and strokes of the circle run that waits for
  /// its draw, for tests.
  @visibleForTesting
  int get debugPendingCircles => _batch.length;

  /// The count of the sector fills that wait for their one draw, for tests.
  @visibleForTesting
  int get debugPendingSectors => _sectorRun;

  /// The builder of the current path, for tests: its `singleRect`,
  /// `singleCircle` and `singleRRect` select the fast paths of [fill] and
  /// [clip].
  @visibleForTesting
  UiPathBuilder get debugPath => _path;

  /// The outer and the inner shape that `fill('evenodd')` of the current
  /// path draws with `drawDRRect`, or `null` when it draws another shape or
  /// the path, for tests.
  @visibleForTesting
  ({ui.RRect outer, ui.RRect inner})? get debugRing {
    final pair = _path.shapePair;
    return pair == null || _soleShape(pair) != null ? null : _ring(pair);
  }

  /// The shape that [fill] of the current path draws alone with `drawRect`
  /// or `drawRRect`, because the other shape of the path has no area, or
  /// `null`, for tests.
  @visibleForTesting
  ui.RRect? get debugSoleShape {
    final pair = _path.shapePair;
    return pair == null ? null : _soleShape(pair);
  }

  /// The clips of the current state, for tests: a `ui.Rect` for
  /// `clipRect`, a `ui.RRect` for `clipRRect` and a `ui.Path` for
  /// `clipPath`.
  @visibleForTesting
  List<Object> get debugClips => [
    for (final clip in _s.clips)
      switch (clip) {
        _RectClip(:final rect) => rect,
        _RRectClip(:final rrect) => rrect,
        _PathClip(:final path) => path,
      },
  ];

  /// Draws the content at [offset], in logical pixels, clipped to the
  /// bitmap. [scaleX] and [scaleY] map the bitmap pixels to logical pixels:
  /// the host gives the display size over the bitmap size. It ends the
  /// current recording.
  void paint(
    ui.Canvas canvas,
    ui.Offset offset,
    double scaleX,
    double scaleY,
  ) {
    _notified = false;
    if (_disposed) return;
    _endRecording();
    if (_paintGenerations > _maxPaintGenerations) _flatten();
    if (_pictures.isEmpty) return;
    final bounds = _bitmapBounds;
    canvas
      ..save()
      ..translate(offset.dx, offset.dy);
    if (scaleX != 1 || scaleY != 1) canvas.scale(scaleX, scaleY);
    canvas.clipRect(bounds);
    if (_needsLayer) canvas.saveLayer(bounds, _layerPaint);
    _pictures.forEach(canvas.drawPicture);
    if (_needsLayer) canvas.restore();
    canvas.restore();
  }

  /// Starts the paint of a host that adds the pictures to its scene
  /// ([addPicturesToScene]), for a layer in place of `Canvas.drawPicture`
  /// (Chart.js ADR 0097). It does what [paint] does before its first draw.
  ///
  /// False when the content needs the `saveLayer` of [paint], which the host
  /// then calls: a composite operation or a partial clear blends with the
  /// content and must not reach what is below the canvas.
  @internal
  bool beginScenePaint() {
    _notified = false;
    if (_disposed) return true;
    _endRecording();
    if (_paintGenerations > _maxPaintGenerations) _flatten();
    return !_needsLayer;
  }

  /// Whether [addPicturesToScene] adds a picture.
  @internal
  bool get hasScenePictures => _pictures.isNotEmpty;

  /// The bitmap in its own space: the clip of the pictures in a scene.
  @internal
  ui.Rect get bitmapBounds => _bitmapBounds;

  /// Adds the pictures to [builder], in bitmap space.
  ///
  /// It reads the pictures that this context holds at the call, so it never
  /// touches a disposed picture. A scene keeps its own reference to each one.
  ///
  /// More than one picture asks the raster cache of the Skia backends to skip
  /// them: it would keep one bitmap of the chart for each picture.
  @internal
  void addPicturesToScene(ui.SceneBuilder builder) {
    final pictures = _pictures;
    final n = pictures.length;
    final willChange = n > 1;
    for (var i = 0; i < n; i++) {
      builder.addPicture(
        ui.Offset.zero,
        pictures[i],
        willChangeHint: willChange,
      );
    }
  }

  /// Releases the pictures. The context draws nothing after this call.
  void dispose() {
    if (_disposed) return;
    _discardRecording();
    _dropPictures();
    _disposed = true;
    _onChanged = null;
    _rectBarBorder = null;
    _rectBarBackground = null;
    _arcBorder = null;
    _arcBackground = null;
    _partitionedFillPath = null;
    _fanEnds = null;
    _fanPoints = null;
  }

  // The recording.

  ui.Canvas get _c {
    if (_batch.length > 0) _flushBatch();
    if (_sectorRun > 0) _flushSectorRun();
    return _canvas ?? _begin();
  }

  /// Draws the pending circles of [_batch].
  void _flushBatch() {
    _batch.flush(_canvas ?? _begin());
  }

  /// Draws the pending sectors with one `drawArc`. The caller may be in the
  /// middle of a draw, with [_fillPaint] set up: this draw uses paints of its
  /// own, and it never ends the recording.
  void _flushSectorRun() {
    _sectorRun = 0;
    _pictureDraws++;
    _drawSector(
      _canvas ?? _begin(),
      _runPaint..color = _runColor,
      _runX,
      _runY,
      _runRadius,
      _runInner,
      _runStart,
      _runSweep,
    );
  }

  /// Ends the sector run for a new draw, between two draws. Its one draw
  /// counts in the budget of the recording.
  void _endSectorRun() {
    if (_sectorRun == 0) return;
    _flushSectorRun();
    if (_pictureDraws >= _maxPictureDraws) _endRecording(split: true);
  }

  /// Adds a fill or a stroke of the scalar circle in [color] to [_batch]. The
  /// caller checked that the paint has no shader and the `srcOver` mode.
  /// Returns false for a circle that the batch does not take.
  // DIVERGES(chartjs): adapt-scalar-circle-inputs, no temporary circle record.
  bool _batchCircle(
    double x,
    double y,
    double radius,
    ui.Color color, {
    required bool stroke,
    double width = 0,
  }) {
    if (radius + width / 2 > maxBatchRadius ||
        x.abs() > maxBatchCenter ||
        y.abs() > maxBatchCenter ||
        !batchKeepsColor(color)) {
      return false;
    }
    _endSectorRun();
    if (!_batch.accepts(radius, color, stroke: stroke, width: width)) {
      // Circles that draw one by one count in the budget of the recording.
      // Here no native sequence is open. A run that ends inside
      // [_endRecording] or [restore] does not split.
      final direct = _batch.directLength;
      _flushBatch();
      if (direct > 0) {
        _pictureDraws += direct;
        if (_pictureDraws >= _maxPictureDraws) _endRecording(split: true);
      }
    }
    _batch.add(
      x,
      y,
      radius,
      color,
      stroke: stroke,
      width: width,
    );
    _drew(batched: true);
    return true;
  }

  /// Makes the canvas of each new recording from its recorder, for the tests
  /// that log the native draw calls. With `null`, the recording draws on
  /// `ui.Canvas(recorder)`.
  @visibleForTesting
  static ui.Canvas Function(ui.PictureRecorder recorder)? debugRecordingCanvas;

  /// Starts a recording. The clips of the saved states are replayed, with a
  /// save for each state with a clip of its own ([_ownsClips]), so that the
  /// `ui.Canvas` stack matches the clips of the state stack.
  ui.Canvas _begin() {
    final recorder = _recorder = ui.PictureRecorder();
    final canvas = _canvas =
        debugRecordingCanvas?.call(recorder) ?? ui.Canvas(recorder);
    var applied = 0;
    for (var i = 0; i <= _depth; i++) {
      final clips = _states[i].clips;
      if (i > 0 && applied < clips.length) canvas.save();
      for (; applied < clips.length; applied++) {
        clips[applied].applyTo(canvas);
      }
    }
    return canvas;
  }

  /// Whether the current state has a clip of its own: a clip that the state
  /// below it does not have. Only such a state has a save on the recording
  /// canvas. The layer maps each point through the transform when the point
  /// is added, so a save and a restore with no clip between them change no
  /// pixel, and the recording does not get them.
  bool get _ownsClips =>
      _depth > 0 && !identical(_s.clips, _states[_depth - 1].clips);

  void _endRecording({bool split = false}) {
    if (!split && _generationHasContent) {
      _paintGenerations++;
      _generationHasContent = false;
    }
    if (_batch.length > 0) _flushBatch();
    if (_sectorRun > 0) _flushSectorRun();
    final recorder = _recorder;
    if (recorder == null) return;
    final picture = recorder.endRecording();
    if (_hasContent) {
      _pictures.add(picture);
    } else {
      picture.dispose();
    }
    _recorder = null;
    _canvas = null;
    _hasContent = false;
    _pictureDraws = 0;
  }

  void _discardRecording() {
    _batch.clear();
    _sectorRun = 0;
    _pictureDraws = 0;
    final recorder = _recorder;
    if (recorder == null) {
      _hasContent = false;
      return;
    }
    recorder.endRecording().dispose();
    _recorder = null;
    _canvas = null;
    _hasContent = false;
  }

  void _dropPictures() {
    for (final picture in _pictures) {
      picture.dispose();
    }
    _pictures.clear();
    _paintGenerations = 0;
    _generationHasContent = false;
    _flatImage?.dispose();
    _flatImage = null;
    _needsLayer = false;
  }

  void _changed() {
    if (_notified) return;
    _notified = true;
    _onChanged?.call();
  }

  void _drew({bool batched = false}) {
    _hasContent = true;
    _generationHasContent = true;
    // All callers have finished their native save/transform/draw/restore
    // sequence. The next recording replays the remaining logical clips.
    if (!batched && ++_pictureDraws >= _maxPictureDraws) {
      _endRecording(split: true);
    }
    _changed();
  }

  /// Draws the pictures into one image of the bitmap size.
  void _flatten() {
    final width = _element._width;
    final height = _element._height;
    final image = width == 0 || height == 0 ? null : _rasterize();
    final needsLayer = _needsLayer;
    _dropPictures();
    _needsLayer = needsLayer;
    if (image == null) return;
    _flatImage = image;
    final imageRecorder = ui.PictureRecorder();
    ui.Canvas(imageRecorder).drawImage(image, ui.Offset.zero, _layerPaint);
    _pictures.add(imageRecorder.endRecording());
    _paintGenerations = 1;
  }

  /// The pictures drawn into one image of the bitmap size, in device
  /// pixels. The bitmap must have pixels.
  ui.Image _rasterize() {
    final bounds = _bitmapBounds;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    if (_needsLayer) canvas.saveLayer(bounds, _layerPaint);
    _pictures.forEach(canvas.drawPicture);
    if (_needsLayer) canvas.restore();
    final picture = recorder.endRecording();
    final image = picture.toImageSync(_element._width, _element._height);
    picture.dispose();
    return image;
  }

  /// The bitmap in its own space: `width` x `height` device pixels.
  ui.Rect get _bitmapBounds => ui.Rect.fromLTWH(
    0,
    0,
    _element._width.toDouble(),
    _element._height.toDouble(),
  );

  /// A snapshot of the bitmap; see [UiCanvasElement.toImageSource].
  ui.Image _snapshot() {
    _endRecording();
    return _rasterize();
  }

  void _resetForResize() {
    if (_disposed) return;
    _depth = 0;
    _s = _states[0]..copyFrom(_State.defaults);
    _path
      ..transform = _s.transform
      ..reset();
    _discardRecording();
    _dropPictures();
    _changed();
  }

  // Paints.

  /// The shader matrix of a draw in bitmap space: the current transform,
  /// or `null` for the identity.
  Float64List? _shaderMatrix() {
    final t = _s.transform;
    if (t.isTranslation && t.e == 0 && t.f == 0) return null;
    return t.writeMatrix4(_m4);
  }

  /// Sets [paint] for the color or the shader of a style. `false` when the
  /// draw paints nothing. A [mapped] draw is in bitmap space: the shader
  /// gets the current transform. Else the draw is in user space.
  bool _setupPaint(
    ui.Paint paint,
    ui.Color? color,
    UiShaderSource? source, {
    required bool mapped,
  }) {
    final s = _s;
    final alpha = s.globalAlpha;
    if (alpha == 0 && s.blendMode == ui.BlendMode.srcOver) return false;
    if (source != null) {
      final shader = source.shaderFor(mapped ? _shaderMatrix() : null);
      if (shader == null) return false;
      paint
        ..shader = shader
        ..color = alpha == 1 ? _black : _black.withValues(alpha: alpha);
    } else {
      final c = color!;
      paint
        ..shader = null
        ..color = alpha == 1 ? c : c.withValues(alpha: c.a * alpha);
    }
    if (s.blendMode != ui.BlendMode.srcOver) _needsLayer = true;
    paint.blendMode = s.blendMode;
    return true;
  }

  bool _setupStroke(double scale, {required bool mapped}) {
    final s = _s;
    if (!_setupPaint(
      _strokePaint,
      s.strokeColor,
      s.strokeShader,
      mapped: mapped,
    )) {
      return false;
    }
    _strokePaint
      ..strokeWidth = s.lineWidth * scale
      ..strokeCap = s.cap
      ..strokeJoin = s.join
      ..strokeMiterLimit = s.miterLimit;
    return true;
  }

  /// The sigma of the blur of a shadow. The HTML rule gives half of
  /// `shadowBlur`, in bitmap pixels. A draw under the transform ([user])
  /// divides it by the scale that the engine applies to a mask filter.
  double _shadowSigma({required bool user}) {
    final s = _s;
    final sigma = s.shadowBlur / 2;
    return user ? sigma / math.sqrt(s.transform.determinant.abs()) : sigma;
  }

  /// Draws the shadow of a shape with the paint [source] (Chart.js ADR 0106):
  /// [draw] with a paint of the shadow, moved by the offset. With [user], the
  /// shape is in user space. The offset then stays outside the transform.
  void _castShadow(
    ui.Paint source,
    void Function(ui.Paint paint) draw, {
    bool user = false,
  }) {
    final s = _s;
    final sigma = _shadowSigma(user: user);
    final paint = _shadowPaint
      ..style = source.style
      ..strokeWidth = source.strokeWidth
      ..strokeCap = source.strokeCap
      ..strokeJoin = source.strokeJoin
      ..strokeMiterLimit = source.strokeMiterLimit
      ..blendMode = source.blendMode
      ..maskFilter = sigma > 0
          ? ui.MaskFilter.blur(ui.BlurStyle.normal, sigma)
          : null;
    if (source.shader == null) {
      paint
        ..shader = null
        ..colorFilter = null
        ..color = s.shadowColor.withValues(
          alpha: s.shadowColor.a * source.color.a,
        );
    } else {
      // A transparent part of a gradient casts no shadow.
      paint
        ..shader = source.shader
        ..color = source.color
        ..colorFilter = ui.ColorFilter.mode(
          s.shadowColor,
          ui.BlendMode.srcIn,
        );
    }
    final canvas = _c
      ..save()
      ..translate(s.shadowOffsetX, s.shadowOffsetY);
    if (user) canvas.transform(s.transform.writeMatrix4(_m4));
    draw(paint);
    canvas.restore();
  }

  /// Strokes [path], in bitmap space, for a similarity transform of
  /// [scale].
  void _strokeMapped(ui.Path path, double scale) {
    if (!_setupStroke(scale, mapped: true)) return;
    final s = _s;
    final dashed = s.lineDash.isEmpty
        ? path
        : dashPath(
            path,
            s.lineDash,
            scale,
            s.lineDashOffset,
            caps: s.cap != ui.StrokeCap.butt,
          );
    if (s.shadowOn) _castShadow(_strokePaint, (p) => _c.drawPath(dashed, p));
    _c.drawPath(dashed, _strokePaint);
    _drew();
  }

  /// Strokes the full circle at (x, y) with the radius [radius], in bitmap
  /// space, for a similarity transform of the scale [scale]. A center of
  /// NaN draws nothing, as for a fill.
  void _strokeCircle(double x, double y, double radius, double scale) {
    if (x.isNaN || y.isNaN) return;
    final s = _s;
    if (_batchable(s.strokeColor, s.strokeShader)) {
      final color = _batchColor(s.strokeColor!);
      if (color == null) return;
      if (_batchCircle(
        x,
        y,
        radius,
        color,
        stroke: true,
        width: s.lineWidth * scale,
      )) {
        return;
      }
    }
    if (!_setupStroke(scale, mapped: true)) return;
    if (s.shadowOn) {
      _castShadow(
        _strokePaint,
        (p) => _c.drawCircle(ui.Offset(x, y), radius, p),
      );
    }
    _c.drawCircle(ui.Offset(x, y), radius, _strokePaint);
    _drew();
  }

  /// Strokes the one line of the current path with `drawLine`, for a
  /// similarity transform of the scale [scale] (Chart.js ADR 0097): no
  /// `ui.Path`, and the commands stay deferred for a later read. A line with
  /// no length, or with a coordinate that is not finite, takes the path.
  void _strokeLine(double scale) {
    final x0 = _path.lineX0;
    final y0 = _path.lineY0;
    final x1 = _path.lineX1;
    final y1 = _path.lineY1;
    if (!_finite4(x0, y0, x1, y1) || (x0 == x1 && y0 == y1)) {
      _strokeMapped(_path.path, scale);
      return;
    }
    if (!_setupStroke(scale, mapped: true)) return;
    if (_s.shadowOn) {
      _castShadow(
        _strokePaint,
        (p) => _c.drawLine(ui.Offset(x0, y0), ui.Offset(x1, y1), p),
      );
    }
    _c.drawLine(ui.Offset(x0, y0), ui.Offset(x1, y1), _strokePaint);
    _drew();
  }

  /// Whether a draw with [color] or [shader] can join the circle batch: a
  /// plain color in the `srcOver` mode.
  bool _batchable(ui.Color? color, UiShaderSource? shader) =>
      shader == null &&
      color != null &&
      _s.blendMode == ui.BlendMode.srcOver &&
      !_s.shadowOn;

  /// [color] times `globalAlpha`, as [_setupPaint] gives it, or `null`
  /// when `globalAlpha` is 0 and the draw paints nothing.
  ui.Color? _batchColor(ui.Color color) {
    final alpha = _s.globalAlpha;
    if (alpha == 0) return null;
    return alpha == 1 ? color : color.withValues(alpha: color.a * alpha);
  }

  /// Strokes [path], in user space, under the current transform.
  void _strokeUser(ui.Path path) {
    if (!_setupStroke(1, mapped: false)) return;
    final s = _s;
    final dashed = s.lineDash.isEmpty
        ? path
        : dashPath(
            path,
            s.lineDash,
            1,
            s.lineDashOffset,
            caps: s.cap != ui.StrokeCap.butt,
          );
    if (s.shadowOn) {
      _castShadow(_strokePaint, (p) => _c.drawPath(dashed, p), user: true);
    }
    _c
      ..save()
      ..transform(s.transform.writeMatrix4(_m4))
      ..drawPath(dashed, _strokePaint)
      ..restore();
    _drew();
  }

  static ui.PathFillType? _fillType(String? rule) => switch (rule) {
    null || 'nonzero' => ui.PathFillType.nonZero,
    'evenodd' => ui.PathFillType.evenOdd,
    _ => null,
  };

  static bool _finite4(double a, double b, double c, double d) =>
      a.isFinite && b.isFinite && c.isFinite && d.isFinite;

  /// Writes the rectangle (x, y, w, h) into [_scratch], through the current
  /// transform when [mapped]. A rectangle with no width or no height is a
  /// line.
  ui.Path _rectPath(double x, double y, double w, double h, {bool? mapped}) {
    final t = _s.transform;
    final map = mapped ?? true;
    double px(double x, double y) => map ? t.mapX(x, y) : x;
    double py(double x, double y) => map ? t.mapY(x, y) : y;
    _scratch
      ..reset()
      ..moveTo(px(x, y), py(x, y));
    if (w == 0 || h == 0) {
      _scratch.lineTo(px(x + w, y + h), py(x + w, y + h));
    } else {
      _scratch
        ..lineTo(px(x + w, y), py(x + w, y))
        ..lineTo(px(x + w, y + h), py(x + w, y + h))
        ..lineTo(px(x, y + h), py(x, y + h))
        ..close();
    }
    return _scratch;
  }

  ui.Rect _mappedRect(double x, double y, double w, double h) {
    final t = _s.transform;
    final x0 = t.mapX(x, y);
    final y0 = t.mapY(x, y);
    final x1 = t.mapX(x + w, y + h);
    final y1 = t.mapY(x + w, y + h);
    return ui.Rect.fromLTRB(
      math.min(x0, x1),
      math.min(y0, y1),
      math.max(x0, x1),
      math.max(y0, y1),
    );
  }

  // State.

  /// The recording canvas gets no save here: the first clip of the new
  /// state makes it ([clip]).
  @override
  void save() {
    if (_states.length == _depth + 1) _states.add(_State());
    final next = _states[_depth + 1]..copyFrom(_s);
    _depth++;
    _s = next;
    _path.transform = next.transform;
  }

  /// Only a state with a clip of its own ([_ownsClips]) draws the pending
  /// circles under its clip and restores the recording canvas.
  @override
  void restore() {
    if (_depth == 0) return;
    if (_ownsClips) {
      if (_batch.length > 0) _flushBatch();
      if (_sectorRun > 0) _flushSectorRun();
      _canvas?.restore();
    }
    _depth--;
    _s = _states[_depth];
    _path.transform = _s.transform;
  }

  // Transforms.

  @override
  void scale(double x, double y) {
    if (!x.isFinite || !y.isFinite) return;
    _s.transform.scale(x, y);
  }

  @override
  void rotate(double angle) {
    if (!angle.isFinite) return;
    _s.transform.rotate(angle);
  }

  @override
  void translate(double x, double y) {
    if (!x.isFinite || !y.isFinite) return;
    _s.transform.translate(x, y);
  }

  @override
  void transform(double a, double b, double c, double d, double e, double f) {
    if (!_finite4(a, b, c, d) || !e.isFinite || !f.isFinite) return;
    _s.transform.multiply(a, b, c, d, e, f);
  }

  @override
  void setTransform(
    double a,
    double b,
    double c,
    double d,
    double e,
    double f,
  ) {
    if (!_finite4(a, b, c, d) || !e.isFinite || !f.isFinite) return;
    _s.transform.setValues(a, b, c, d, e, f);
  }

  @override
  void resetTransform() => _s.transform.reset();

  // Compositing.

  @override
  double? get globalAlpha => _s.globalAlpha;

  @override
  set globalAlpha(double? value) {
    if (value == null || !(value >= 0 && value <= 1)) return;
    _s.globalAlpha = value;
  }

  @override
  double get shadowBlur => _s.shadowBlur;

  @override
  set shadowBlur(double? value) {
    if (value == null || !value.isFinite || value < 0) return;
    _s
      ..shadowBlur = value
      ..updateShadowOn();
  }

  @override
  Object get shadowColor => _s.shadowColor;

  /// A native Color. An invalid color throws without changing the current
  /// color, as for `fillStyle`.
  @override
  set shadowColor(Object? value) {
    if (value == null) return;
    _s
      ..shadowColor = requireUiColor(value, 'shadowColor')
      ..updateShadowOn();
  }

  @override
  double get shadowOffsetX => _s.shadowOffsetX;

  @override
  set shadowOffsetX(double? value) {
    if (value == null || !value.isFinite) return;
    _s
      ..shadowOffsetX = value
      ..updateShadowOn();
  }

  @override
  double get shadowOffsetY => _s.shadowOffsetY;

  @override
  set shadowOffsetY(double? value) {
    if (value == null || !value.isFinite) return;
    _s
      ..shadowOffsetY = value
      ..updateShadowOn();
  }

  @override
  CanvasCompositeOperation get globalCompositeOperation =>
      compositeOperationOf(_s.blendMode);

  @override
  set globalCompositeOperation(CanvasCompositeOperation? value) {
    if (value == null) return;
    _s.blendMode = blendModeOf(value);
  }

  // Styles.

  static Object _styleValue(ui.Color? color, UiShaderSource? shader) =>
      shader ?? color!;

  @override
  Object? get fillStyle => _styleValue(_s.fillColor, _s.fillShader);

  /// A native Color, a [UiCanvasGradient] or a [UiCanvasPattern].
  /// Invalid solid colors throw without changing the current style.
  @override
  set fillStyle(Object? value) {
    if (value == null) return;
    if (value is UiShaderSource) {
      _s
        ..fillShader = value
        ..fillColor = null;
    } else {
      _s
        ..fillColor = requireUiColor(value, 'fillStyle')
        ..fillShader = null;
    }
  }

  @override
  Object? get strokeStyle => _styleValue(_s.strokeColor, _s.strokeShader);

  /// A native Color, a [UiCanvasGradient] or a [UiCanvasPattern].
  /// Invalid solid colors throw without changing the current style.
  @override
  set strokeStyle(Object? value) {
    if (value == null) return;
    if (value is UiShaderSource) {
      _s
        ..strokeShader = value
        ..strokeColor = null;
    } else {
      _s
        ..strokeColor = requireUiColor(value, 'strokeStyle')
        ..strokeShader = null;
    }
  }

  @override
  UiCanvasGradient createLinearGradient(
    double x0,
    double y0,
    double x1,
    double y1,
  ) => UiCanvasGradient.linear(x0, y0, x1, y1);

  @override
  UiCanvasGradient createRadialGradient(
    double x0,
    double y0,
    double r0,
    double x1,
    double y1,
    double r1,
  ) => UiCanvasGradient.radial(x0, y0, r0, x1, y1, r1);

  @override
  UiCanvasGradient createConicGradient(double startAngle, double x, double y) =>
      UiCanvasGradient.conic(startAngle, x, y);

  /// A pattern of a [UiImageSource]. Another image source gives `null`.
  @override
  UiCanvasPattern? createPattern(CanvasImageSource image, String? repetition) {
    if (image is! UiImageSource) return null;
    return UiCanvasPattern(
      image.image,
      repetition == null || repetition.isEmpty ? 'repeat' : repetition,
    );
  }

  // Rectangles.

  @override
  void clearRect(double x, double y, double w, double h) {
    if (_disposed || !_finite4(x, y, w, h)) return;
    final t = _s.transform;
    if (!t.isInvertible || w == 0 || h == 0) return;
    if (t.isAxisAligned) {
      final rect = _mappedRect(x, y, w, h);
      if (_s.clips.isEmpty &&
          rect.left <= 0 &&
          rect.top <= 0 &&
          rect.right >= _element._width &&
          rect.bottom >= _element._height) {
        if (isEmpty) return;
        _discardRecording();
        _dropPictures();
        _changed();
        return;
      }
      if (isEmpty) return;
      _c.drawRect(rect, _clearPaint);
    } else {
      if (isEmpty) return;
      _c.drawPath(_rectPath(x, y, w, h), _clearPaint);
    }
    _needsLayer = true;
    _drew();
  }

  @override
  void fillRect(double x, double y, double w, double h) {
    if (_disposed || !_finite4(x, y, w, h)) return;
    final s = _s;
    final t = s.transform;
    if (!t.isInvertible || w == 0 || h == 0) return;
    if (!_setupPaint(_fillPaint, s.fillColor, s.fillShader, mapped: true)) {
      return;
    }
    if (s.shadowOn) {
      _castShadow(_fillPaint, (p) => _c.drawPath(_rectPath(x, y, w, h), p));
    }
    if (t.isAxisAligned) {
      _c.drawRect(_mappedRect(x, y, w, h), _fillPaint);
    } else {
      _c.drawPath(_rectPath(x, y, w, h), _fillPaint);
    }
    _drew();
  }

  ui.Color? _rectBarBorder;
  ui.Color? _rectBarBackground;

  // Only exact immutable sRGB colors qualify. Cache that validation by
  // identity; gradients, unusual color objects and non-finite channels keep
  // their ordinary setters and possible errors at the original point.
  static bool _rectBarColor(Object? value, ui.Color? validated) {
    if (validated != null && identical(value, validated)) return true;
    if (value is! ui.Color ||
        value.runtimeType != ui.Color ||
        value.colorSpace != ui.ColorSpace.sRGB) {
      return false;
    }
    return value.a >= 0 &&
        value.a <= 1 &&
        value.r >= 0 &&
        value.r <= 1 &&
        value.g >= 0 &&
        value.g <= 1 &&
        value.b >= 0 &&
        value.b <= 1;
  }

  /// Fused ordinary bars (ADR 0070). The logical style stack is untouched;
  /// the final inner path and each successful fill's recording count remain.
  @override
  @internal
  bool tryDrawRectBar({
    required double outerX,
    required double outerY,
    required double outerWidth,
    required double outerHeight,
    required double innerX,
    required double innerY,
    required double innerWidth,
    required double innerHeight,
    required Object? borderColor,
    required Object? backgroundColor,
  }) {
    // A callback can inspect or mutate the temporary style/path/save state.
    // Let the original sequence handle any draw that can notify user code.
    if (_disposed ||
        _s.shadowOn ||
        (!_notified && _onChanged != null) ||
        ui.Picture.onCreate != null ||
        ui.Picture.onDispose != null ||
        ui.Image.onCreate != null ||
        ui.Image.onDispose != null ||
        !identical(_path.transform, _s.transform) ||
        !_s.transform.isAxisAligned ||
        !_s.transform.isInvertible ||
        !_finite4(outerX, outerY, outerWidth, outerHeight) ||
        !_finite4(innerX, innerY, innerWidth, innerHeight) ||
        outerWidth <= 0 ||
        outerHeight <= 0 ||
        innerWidth < 0 ||
        innerHeight < 0 ||
        !_rectBarColor(borderColor, _rectBarBorder) ||
        !_rectBarColor(backgroundColor, _rectBarBackground)) {
      return false;
    }
    final outer = _mappedRect(outerX, outerY, outerWidth, outerHeight);
    final inner = _mappedRect(innerX, innerY, innerWidth, innerHeight);
    if (!outer.isFinite || !inner.isFinite) return false;
    final hasBorder = outerWidth != innerWidth || outerHeight != innerHeight;
    ({ui.RRect outer, ui.RRect inner})? ring;
    if (hasBorder && !inner.isEmpty) {
      ring = _ring((
        first: ui.RRect.fromRectXY(outer, 0, 0),
        second: ui.RRect.fromRectXY(inner, 0, 0),
      ));
      if (ring == null) return false;
    }
    final border = borderColor! as ui.Color;
    final background = backgroundColor! as ui.Color;
    _rectBarBorder = border;
    _rectBarBackground = background;
    if (hasBorder && _setupPaint(_fillPaint, border, null, mapped: true)) {
      final canvas = _c; // Flush pending circles in their original order.
      if (ring != null) {
        canvas.drawDRRect(ring.outer, ring.inner, _fillPaint);
      } else if (!outer.isEmpty) {
        canvas.drawRect(outer, _fillPaint);
      }
      _drew();
    }
    // Paths are outside save/restore. Retain the exact rect commands and
    // direction for a later stroke, clip, append or inspection by a plugin.
    _path
      ..reset()
      ..rect(innerX, innerY, innerWidth, innerHeight);
    if (inner.isEmpty) {
      // Empty fills still count/notify and may start the next recording.
      // With guarded solid colors their private paint mutation is unobserved.
      if (_s.globalAlpha != 0 || _s.blendMode != ui.BlendMode.srcOver) {
        if (_s.blendMode != ui.BlendMode.srcOver) _needsLayer = true;
        _c;
        _drew();
      }
    } else if (_setupPaint(_fillPaint, background, null, mapped: true)) {
      _c.drawRect(inner, _fillPaint);
      _drew();
    }
    return true;
  }

  ui.Color? _arcBorder;
  ui.Color? _arcBackground;

  /// `translate(0, 0)` adds 0 to the translation of a finite matrix.
  @override
  @internal
  bool get zeroTranslateIsNoOp {
    final t = _s.transform;
    return t.a.isFinite && t.b.isFinite && t.c.isFinite && t.d.isFinite;
  }

  /// A fused ordinary arc (Chart.js ADR 0097): the fill of the sector, with
  /// the numbers that [UiPathBuilder.singleSector] reads from the ordinary
  /// path. The logical styles, the save depth and the transform stay. The path
  /// of the ordinary sequence stays pending as the current path.
  ///
  /// Adjacent sectors of one color, one center and one pair of radii in the
  /// `srcOver` mode draw once, when the run ends: the seams between them
  /// disappear (differences.md row `adapt-sector-run-seams`).
  @override
  @internal
  bool tryDrawArcSector({
    required double x,
    required double y,
    required double outerRadius,
    required double innerRadius,
    required double startAngle,
    required double endAngle,
    required Object? backgroundColor,
    required Object? borderColor,
  }) {
    final s = _s;
    final t = s.transform;
    // A callback can inspect or mutate the temporary style/path/save state,
    // as for a fused bar. So can an observer of a picture or an image.
    if (_disposed ||
        s.shadowOn ||
        (!_notified && _onChanged != null) ||
        ui.Picture.onCreate != null ||
        ui.Picture.onDispose != null ||
        ui.Image.onCreate != null ||
        ui.Image.onDispose != null ||
        !identical(_path.transform, t) ||
        !t.isSimilarity ||
        !_rectBarColor(backgroundColor, _arcBackground) ||
        !_rectBarColor(borderColor, _arcBorder)) {
      return false;
    }
    final px = t.mapX(x, y);
    final py = t.mapY(x, y);
    final scale = t.scaleFactor;
    final radius = outerRadius * scale;
    final inner = innerRadius * scale;
    final middle = (startAngle + endAngle) / 2;
    final firstSweep = middle - startAngle;
    final secondSweep = endAngle - middle;
    if (!(px.abs() <= _maxSectorExtent) ||
        !(py.abs() <= _maxSectorExtent) ||
        !(radius <= _maxSectorExtent) ||
        !(radius - inner >= _minSectorWidth) ||
        (inner != 0 && !(inner >= _minSectorWidth)) ||
        !(startAngle.abs() <= _maxSectorAngle) ||
        !(endAngle.abs() <= _maxSectorAngle) ||
        !(firstSweep > 0) ||
        !(secondSweep > 0) ||
        !(firstSweep + secondSweep < _maxSectorSweep)) {
      return false;
    }
    final background = backgroundColor! as ui.Color;
    _arcBackground = background;
    _arcBorder = borderColor! as ui.Color;
    _path.setPendingSector(
      x,
      y,
      outerRadius,
      innerRadius,
      startAngle,
      endAngle,
      t,
    );
    // The angles of `_addArc` for a similarity transform, added as
    // `singleSector` adds them.
    final reflected = t.isReflected;
    final angle = t.angle;
    final start = reflected ? angle - startAngle : angle + startAngle;
    final sweep = reflected
        ? -firstSweep + -secondSweep
        : firstSweep + secondSweep;
    if (s.blendMode != ui.BlendMode.srcOver) {
      if (_setupPaint(_fillPaint, background, null, mapped: true)) {
        _drawSector(_c, _fillPaint, px, py, radius, inner, start, sweep);
        _drew();
      }
      return true;
    }
    final color = _batchColor(background);
    if (color == null) return true;
    // DIVERGES(chartjs): adapt-sector-run-seams, one draw for adjacent sectors.
    if (_sectorRun > 0 &&
        (startAngle - _runEnd).abs() <= _maxSectorRunGap &&
        px == _runX &&
        py == _runY &&
        radius == _runRadius &&
        inner == _runInner &&
        angle == _runAngle &&
        reflected == _runReflected &&
        (identical(color, _runColor) || color == _runColor) &&
        (_runSweep + sweep).abs() < _maxSectorRunSweep) {
      _sectorRun++;
      _runSweep += sweep;
      _runEnd = endAngle;
      _drew(batched: true);
      return true;
    }
    _endSectorRun();
    if (_batch.length > 0) _flushBatch();
    _sectorRun = 1;
    _runX = px;
    _runY = py;
    _runRadius = radius;
    _runInner = inner;
    _runStart = start;
    _runSweep = sweep;
    _runEnd = endAngle;
    _runAngle = angle;
    _runReflected = reflected;
    _runColor = color;
    _drew(batched: true);
    return true;
  }

  @override
  void strokeRect(double x, double y, double w, double h) {
    if (_disposed || !_finite4(x, y, w, h)) return;
    final t = _s.transform;
    if (!t.isInvertible || (w == 0 && h == 0)) return;
    if (t.isSimilarity) {
      _strokeMapped(_rectPath(x, y, w, h), t.scaleFactor);
    } else {
      _strokeUser(_rectPath(x, y, w, h, mapped: false));
    }
  }

  // Paths.

  @override
  void beginPath() => _path.reset();

  @override
  void closePath() => _path.closePath();

  @override
  void moveTo(double x, double y) => _path.moveTo(x, y);

  @override
  void lineTo(double x, double y) => _path.lineTo(x, y);

  @override
  void bezierCurveTo(
    double cp1x,
    double cp1y,
    double cp2x,
    double cp2y,
    double x,
    double y,
  ) => _path.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, x, y);

  @override
  void quadraticCurveTo(double cpx, double cpy, double x, double y) =>
      _path.quadraticCurveTo(cpx, cpy, x, y);

  @override
  void arc(
    double x,
    double y,
    double radius,
    double startAngle,
    double endAngle, [
    bool counterclockwise = false,
  ]) => _path.arc(x, y, radius, startAngle, endAngle, counterclockwise);

  @override
  void arcTo(double x1, double y1, double x2, double y2, double radius) =>
      _path.arcTo(x1, y1, x2, y2, radius);

  @override
  void ellipse(
    double x,
    double y,
    double radiusX,
    double radiusY,
    double rotation,
    double startAngle,
    double endAngle, [
    bool counterclockwise = false,
  ]) => _path.ellipse(
    x,
    y,
    radiusX,
    radiusY,
    rotation,
    startAngle,
    endAngle,
    counterclockwise,
  );

  @override
  void rect(double x, double y, double w, double h) => _path.rect(x, y, w, h);

  @override
  void roundRect(double x, double y, double w, double h, [Object? radii]) =>
      _path.roundRect(x, y, w, h, radii);

  // The values of the run of [tryStartCircleRun]: bitmap space.
  double _circleRunRadius = 0;
  double _circleRunWidth = 0;
  bool _circleRunStroke = false;

  /// Whether [tryAddRunCircle] lets the batch hold a run
  /// ([CircleBatch.hold]): its circles after the first then take no test of
  /// [_batchCircle]. Only the tests set it to false, for a comparison of the
  /// two forms.
  @visibleForTesting
  static bool debugHoldCircleRuns = true;

  /// Whether the batch holds the current circle run, for tests.
  @visibleForTesting
  bool get debugCircleRunHeld => _batch.holdsRun;

  @override
  bool tryStartCircleRun(double radius, {required bool stroke}) {
    // The radius, the width or the colors may differ from the last run.
    _batch.release();
    final s = _s;
    final t = s.transform;
    final fill = s.fillColor;
    final strokeColor = s.strokeColor;
    if (_disposed ||
        s.shadowOn ||
        (!_notified && _onChanged != null) ||
        ui.Picture.onCreate != null ||
        ui.Picture.onDispose != null ||
        ui.Image.onCreate != null ||
        ui.Image.onDispose != null ||
        !identical(_path.transform, t) ||
        !t.isSimilarity ||
        s.globalAlpha != 1 ||
        !(radius > 0) ||
        !_batchable(fill, s.fillShader) ||
        !batchKeepsColor(fill!)) {
      return false;
    }
    final mapped = radius * t.scaleFactor;
    var width = 0.0;
    if (stroke) {
      if (s.lineDash.isNotEmpty ||
          !_batchable(strokeColor, s.strokeShader) ||
          !batchKeepsColor(strokeColor!)) {
        return false;
      }
      width = s.lineWidth * t.scaleFactor;
    }
    // The radius test of [_batchCircle], once for the run.
    if (!(mapped + width / 2 <= maxBatchRadius)) return false;
    _circleRunRadius = mapped;
    _circleRunWidth = width;
    _circleRunStroke = stroke;
    return true;
  }

  @override
  bool tryAddRunCircle(double x, double y) {
    final s = _s;
    final t = s.transform;
    final px = t.mapX(x, y);
    final py = t.mapY(x, y);
    // Also false for NaN, which draws nothing on the ordinary path.
    if (!(px.abs() <= maxBatchCenter && py.abs() <= maxBatchCenter)) {
      return false;
    }
    final fill = s.fillColor!;
    final strokeColor = s.strokeColor;
    // A held run: the tests of [_batchCircle] would pass again. The run proved
    // the bounds of the radius and the width and the colors, the center is
    // proved above, the first circle ended the sector run, and the batch takes
    // each circle of the held run with no flush.
    if (_batch.addHeld(px, py, fill, _circleRunStroke ? strokeColor : null)) {
      _drew(batched: true);
      return true;
    }
    final radius = _circleRunRadius;
    final width = _circleRunWidth;
    var added = _batchCircle(px, py, radius, fill, stroke: false);
    if (_circleRunStroke) {
      final stroke = strokeColor!;
      added =
          _batchCircle(px, py, radius, stroke, stroke: true, width: width) &&
          added;
      if (added && debugHoldCircleRuns) {
        _batch.hold(radius, fill, stroke, width);
      }
    } else if (added && debugHoldCircleRuns) {
      _batch.hold(radius, fill, null, width);
    }
    return true;
  }

  UiPathBuilder? _partitionedFillPath;

  // DIVERGES(chartjs): adapt-web-long-path-pieces, long paths are slow on WebGL
  /// Whether this build runs in a browser: Skia on WebGL.
  static const bool _onWeb = bool.fromEnvironment('dart.library.js_interop');

  /// Whether the context draws long paths in pieces (Chart.js ADR 0113). Only
  /// the tests set this switch on the VM, for a comparison of the two forms.
  @visibleForTesting
  static bool debugDrawLongPathsInPieces = _onWeb;

  /// The fewest commands of a `Path2D` that a browser on a desktop system
  /// strokes in pieces (Chart.js ADR 0113): there one draw of a short line
  /// takes more raster time than its pieces.
  static const int desktopStrokePieceCommands = 2;

  /// The fewest commands of a `Path2D` that [stroke] draws in pieces (Chart.js
  /// ADR 0113): [desktopStrokePieceCommands] when [defaultTargetPlatform], the
  /// system of the browser, is macOS, Windows or Linux, else
  /// [minPieceCommands], as for a fill.
  static int get strokePieceMinCommands {
    final platform = defaultTargetPlatform;
    return platform == TargetPlatform.macOS ||
            platform == TargetPlatform.windows ||
            platform == TargetPlatform.linux
        ? desktopStrokePieceCommands
        : minPieceCommands;
  }

  /// The count of the fills and strokes in pieces, for the tests.
  @visibleForTesting
  int debugPieceDraws = 0;

  ui.Path? _pieceFill;
  final ui.Paint _pieceLayer = ui.Paint();

  /// The paint of the shadow of a shape ([_castShadow]).
  final ui.Paint _shadowPaint = ui.Paint();

  @override
  bool get takesPartitionedFill => !debugDrawLongPathsInPieces;

  @override
  int get deferredFillMinPoints =>
      debugDrawLongPathsInPieces ? minPieceCommands : 1024;

  /// Fills the deferred current path in pieces. See
  /// [UiPathBuilder.tryFillColumns]. The paint is ready.
  bool _tryFillInPieces(ui.PathFillType fillType) {
    final s = _s;
    if (!debugDrawLongPathsInPieces ||
        s.shadowOn ||
        s.fillShader != null ||
        s.blendMode != ui.BlendMode.srcOver) {
      return false;
    }
    final scratch = (_pieceFill ??= ui.Path())..fillType = fillType;
    final canvas = _c;
    final drawn = _path.tryFillColumns(scratch, (clip) {
      canvas
        ..save()
        ..clipRect(clip, doAntiAlias: false)
        ..drawPath(scratch, _fillPaint)
        ..restore();
    });
    if (drawn) debugPieceDraws++;
    return drawn;
  }

  /// Strokes [path2d] in pieces, with the styles of the context. A false result
  /// draws nothing. A translucent line goes through one layer, so that the
  /// pieces do not blend over each other.
  bool _tryStrokeInPieces(Path2D path2d) {
    final s = _s;
    final t = s.transform;
    if (!debugDrawLongPathsInPieces ||
        s.shadowOn ||
        path2d.version < strokePieceMinCommands ||
        s.lineDash.isNotEmpty ||
        s.strokeShader != null ||
        s.strokeColor == null ||
        s.blendMode != ui.BlendMode.srcOver ||
        s.cap != ui.StrokeCap.butt ||
        !t.isSimilarity) {
      return false;
    }
    // A translucent line of at most one pixel: the engine draws it as a
    // hairline, whose segments blend over each other. A layer gives another
    // tone.
    if (s.strokeColor!.a * s.globalAlpha < 1 &&
        s.lineWidth * t.scaleFactor <= 1) {
      return false;
    }
    final pieces = uiPathPiecesOf(path2d, t.scaleFactor, s.lineWidth);
    if (pieces == null) return false;
    // The paint with no color has nothing to draw, as in [_strokeUser].
    if (!_setupStroke(1, mapped: false)) return true;
    final color = _strokePaint.color;
    final translucent = color.a < 1;
    final canvas = _c
      ..save()
      ..transform(t.writeMatrix4(_m4));
    if (translucent) {
      _pieceLayer.color = ui.Color.fromRGBO(0, 0, 0, color.a);
      _strokePaint.color = color.withValues(alpha: 1);
      // A miter reaches at most half of the limit times the width.
      canvas.saveLayer(
        pieces.bounds.inflate(s.lineWidth * (s.miterLimit + 1)),
        _pieceLayer,
      );
    }
    final list = pieces.pieces;
    for (var i = 0; i < list.length; i++) {
      canvas.drawPath(list[i], _strokePaint);
    }
    if (translucent) canvas.restore();
    canvas.restore();
    debugPieceDraws++;
    _drew();
    return true;
  }

  @override
  void deferCurrentPath() => _path.deferLongPath();

  @override
  bool tryFillPartitionedPath(void Function(CanvasPath path) writePath) {
    if (_disposed ||
        _s.shadowOn ||
        (!_notified && _onChanged != null) ||
        ui.Picture.onCreate != null ||
        ui.Picture.onDispose != null ||
        ui.Image.onCreate != null ||
        ui.Image.onDispose != null ||
        _s.fillShader != null ||
        _s.fillColor == null ||
        _s.blendMode != ui.BlendMode.srcOver ||
        !_s.transform.isAxisAligned ||
        !_s.transform.isInvertible) {
      return false;
    }
    final builder = (_partitionedFillPath ??= UiPathBuilder(_s.transform))
      ..reset()
      ..transform = _s.transform;
    writePath(builder);
    if (_setupPaint(_fillPaint, _s.fillColor, null, mapped: true)) {
      _c.drawPath(builder.path, _fillPaint);
      _drew();
    }
    return true;
  }

  /// An unknown fill rule does nothing (the DOM throws a `TypeError`).
  @override
  void fill([Object? pathOrFillRule, CanvasFillRule? fillRule]) {
    if (_disposed) return;
    final path2d = pathOrFillRule is Path2D ? pathOrFillRule : null;
    final rule = path2d != null
        ? fillRule
        : (pathOrFillRule is String ? pathOrFillRule : null);
    final fillType = _fillType(rule);
    final s = _s;
    if (fillType == null || !s.transform.isInvertible) return;
    if (path2d != null) {
      final path = uiPathOf(path2d)..fillType = fillType;
      if (!_setupPaint(
        _fillPaint,
        s.fillColor,
        s.fillShader,
        mapped: false,
      )) {
        return;
      }
      if (s.shadowOn) {
        _castShadow(_fillPaint, (p) => _c.drawPath(path, p), user: true);
      }
      _c
        ..save()
        ..transform(s.transform.writeMatrix4(_m4))
        ..drawPath(path, _fillPaint)
        ..restore();
    } else {
      if (_path.isEmpty) return;
      final circle = _path.hasSingleCircle;
      final circleX = circle ? _path.circleX : 0.0;
      final circleY = circle ? _path.circleY : 0.0;
      final circleRadius = circle ? _path.circleRadius : 0.0;
      // A transform that overflowed to a center of NaN: the path has a NaN
      // point, and Skia draws nothing.
      if (circle && (circleX.isNaN || circleY.isNaN)) return;
      if (circle && _batchable(s.fillColor, s.fillShader)) {
        final color = _batchColor(s.fillColor!);
        if (color == null) return;
        if (_batchCircle(
          circleX,
          circleY,
          circleRadius,
          color,
          stroke: false,
        )) {
          return;
        }
      }
      if (!_setupPaint(
        _fillPaint,
        s.fillColor,
        s.fillShader,
        mapped: true,
      )) {
        return;
      }
      if (s.shadowOn) {
        _castShadow(
          _fillPaint,
          (p) => _c.drawPath(_path.path..fillType = fillType, p),
        );
      }
      final canvas = _c;
      final rect = _path.singleRect;
      // A rectangle or a rounded rectangle with no area has no pixels, so it
      // gets no draw call (canvas-cuts-plan.md §7, N2): for example the
      // inner rectangle of a bar that is narrower than its two borders.
      if (rect != null) {
        if (!rect.isEmpty) canvas.drawRect(rect, _fillPaint);
      } else if (circle) {
        canvas.drawCircle(
          ui.Offset(circleX, circleY),
          circleRadius,
          _fillPaint,
        );
      } else {
        final rrect = _path.singleRRect;
        final pair = rrect == null ? _path.shapePair : null;
        final sole = pair == null ? null : _soleShape(pair);
        final ring = sole == null && fillType == ui.PathFillType.evenOdd
            ? _ring(pair)
            : null;
        if (rrect != null) {
          if (!rrect.isEmpty) canvas.drawRRect(rrect, _fillPaint);
        } else if (sole != null) {
          if (!sole.isEmpty) {
            if (sole.isRect) {
              canvas.drawRect(sole.outerRect, _fillPaint);
            } else {
              canvas.drawRRect(sole, _fillPaint);
            }
          }
        } else if (ring != null) {
          canvas.drawDRRect(ring.outer, ring.inner, _fillPaint);
        } else {
          final sector = _path.singleSector;
          if (sector != null) {
            _fillSector(canvas, sector);
          } else if (!_tryFillInPieces(fillType)) {
            canvas.drawPath(_path.path..fillType = fillType, _fillPaint);
          }
        }
      }
    }
    _drew();
  }

  /// Fills [sector] with `drawArc` (canvas-cuts-plan.md §7, N4), with the
  /// paint of [_fillPaint]: a wedge with its center, or a ring sector as the
  /// stroke of its middle circle with butt caps and the width of the ring.
  /// The butt stroke of a circular arc covers the region between its two
  /// radii and its two end angles, which is the region of the path.
  void _fillSector(ui.Canvas canvas, UiSector sector) {
    final (:x, :y, :radius, :inner, :start, :sweep) = sector;
    _drawSector(canvas, _fillPaint, x, y, radius, inner, start, sweep);
  }

  /// The draw of [_fillSector], with the fill paint [fill].
  void _drawSector(
    ui.Canvas canvas,
    ui.Paint fill,
    double x,
    double y,
    double radius,
    double inner,
    double start,
    double sweep,
  ) {
    if (inner == 0) {
      canvas.drawArc(
        ui.Rect.fromLTRB(x - radius, y - radius, x + radius, y + radius),
        start,
        sweep,
        true,
        fill,
      );
      return;
    }
    final paint = _sectorPaint
      ..color = fill.color
      ..shader = fill.shader
      ..blendMode = fill.blendMode
      ..strokeWidth = radius - inner;
    final middle = (radius + inner) / 2;
    canvas.drawArc(
      ui.Rect.fromLTRB(x - middle, y - middle, x + middle, y + middle),
      start,
      sweep,
      false,
      paint,
    );
  }

  /// The shape of [pair] that has an area, when the other shape has no width
  /// or no height and both shapes are finite. A subpath with no area adds no
  /// winding and no coverage, for the nonzero and the even-odd rule, so the
  /// fill of the path is the fill of that shape alone: `drawRect` when its
  /// radii are 0, else `drawRRect`. It is the border ring of a bar
  /// (`element.bar.js:188-192`) that is narrower or lower than its two
  /// borders: `parseBorderWidth` clamps them, and the inner rectangle has a
  /// width or a height of 0. A shape with a coordinate that is not finite
  /// takes the path, as before.
  static ui.RRect? _soleShape(({ui.RRect first, ui.RRect second}) pair) {
    final (:first, :second) = pair;
    if (!first.isFinite || !second.isFinite) return null;
    if (second.width == 0 || second.height == 0) return first;
    if (first.width == 0 || first.height == 0) return second;
    return null;
  }

  /// The two shapes of [pair] as an outer and an inner shape, when one of
  /// them is inside the other ([rrectContains]). Then the even-odd fill of
  /// the path is `drawDRRect(outer, inner)`: the border ring of a bar
  /// (`element.bar.js:188-192`). An inner shape with no width or no height
  /// gives `null`: [_soleShape] fills the outer shape alone.
  static ({ui.RRect outer, ui.RRect inner})? _ring(
    ({ui.RRect first, ui.RRect second})? pair,
  ) {
    if (pair == null) return null;
    final (:first, :second) = pair;
    if (second.width > 0 && second.height > 0 && rrectContains(first, second)) {
      return (outer: first, inner: second);
    }
    if (first.width > 0 && first.height > 0 && rrectContains(second, first)) {
      return (outer: second, inner: first);
    }
    return null;
  }

  @override
  void stroke([Path2D? path]) {
    if (_disposed) return;
    final t = _s.transform;
    if (!t.isInvertible) return;
    if (path != null) {
      if (!_tryStrokeInPieces(path)) _strokeUser(uiPathOf(path));
    } else if (_path.isEmpty) {
      return;
    } else if (t.isSimilarity) {
      if (_path.hasSingleCircle && _s.lineDash.isEmpty) {
        _strokeCircle(
          _path.circleX,
          _path.circleY,
          _path.circleRadius,
          t.scaleFactor,
        );
      } else if (_path.hasSingleLine && _s.lineDash.isEmpty) {
        _strokeLine(t.scaleFactor);
      } else {
        _strokeMapped(_path.path, t.scaleFactor);
      }
    } else {
      _strokeUser(_path.path.transform(t.writeInverseMatrix4(_m4)));
    }
  }

  /// Whether [tryStrokeLineFan] also takes an engine without Impeller. Only the
  /// pixel twins set it: on `flutter_tester`, that engine is Skia on the CPU.
  @visibleForTesting
  static bool debugLineFanWithoutImpeller = false;

  /// One `drawRawPoints` of the lines of a fan (Chart.js ADR 0103), in place of
  /// one `drawLine` of [_strokeLine] for each line. The engine draws each line
  /// of the call as its own stroke, in order, so a translucent line still
  /// blends over the lines before it. The logical styles and the transform do
  /// not change. The path of the last line stays as the current path, with its
  /// commands deferred.
  ///
  /// Impeller and Skia on the CPU draw the same bytes for both forms. GPU Skia
  /// and the web are not proven, so they decline: `isShaderFilterSupported` is
  /// the only signal of the engine that `dart:ui` has, and it is false on both.
  /// A dash, a shader, another transform than a similarity and a line that
  /// [_strokeLine] gives to the path decline too, as does a context whose next
  /// draw would notify, and an observer of a picture or an image: a fan makes
  /// fewer pictures.
  @override
  @internal
  bool tryStrokeLineFan(
    double x,
    double y,
    int count,
    void Function(Float64List ends) writeEnds,
  ) {
    final s = _s;
    final t = s.transform;
    if (count < 2 ||
        _disposed ||
        s.shadowOn ||
        !(ui.ImageFilter.isShaderFilterSupported ||
            debugLineFanWithoutImpeller) ||
        (!_notified && _onChanged != null) ||
        ui.Picture.onCreate != null ||
        ui.Picture.onDispose != null ||
        ui.Image.onCreate != null ||
        ui.Image.onDispose != null ||
        !identical(_path.transform, t) ||
        !t.isInvertible ||
        !t.isSimilarity ||
        s.lineDash.isNotEmpty ||
        s.strokeShader != null ||
        s.strokeColor == null) {
      return false;
    }
    final x0 = t.mapX(x, y);
    final y0 = t.mapY(x, y);
    if (!(x0.abs() <= _maxLineFanExtent) || !(y0.abs() <= _maxLineFanExtent)) {
      return false;
    }
    final endCount = count * 2;
    var ends = _fanEnds;
    if (ends == null || ends.length != endCount) {
      ends = _fanEnds = Float64List(endCount);
    }
    writeEnds(ends);
    final pointCount = count * 4;
    var points = _fanPoints;
    if (points == null || points.length != pointCount) {
      points = _fanPoints = Float32List(pointCount);
    }
    var p = 0;
    for (var e = 0; e < endCount; e += 2) {
      final endX = ends[e];
      final endY = ends[e + 1];
      final x1 = t.mapX(endX, endY);
      final y1 = t.mapY(endX, endY);
      if (!(x1.abs() <= _maxLineFanExtent) ||
          !(y1.abs() <= _maxLineFanExtent) ||
          (x1 == x0 && y1 == y0)) {
        return false;
      }
      points
        ..[p] = x0
        ..[p + 1] = y0
        ..[p + 2] = x1
        ..[p + 3] = y1;
      p += 4;
    }
    _path
      ..reset()
      ..moveTo(x, y)
      ..lineTo(ends[endCount - 2], ends[endCount - 1]);
    if (!_setupStroke(t.scaleFactor, mapped: true)) return true;
    _c.drawRawPoints(ui.PointMode.lines, points, _strokePaint);
    _drew();
    return true;
  }

  /// An unknown fill rule does nothing (the DOM throws a `TypeError`).
  @override
  void clip([Object? pathOrFillRule, CanvasFillRule? fillRule]) {
    if (_disposed) return;
    final path2d = pathOrFillRule is Path2D ? pathOrFillRule : null;
    final rule = path2d != null
        ? fillRule
        : (pathOrFillRule is String ? pathOrFillRule : null);
    final fillType = _fillType(rule);
    final s = _s;
    if (fillType == null || !s.transform.isInvertible) return;
    _Clip clip;
    if (path2d != null) {
      clip = _PathClip(
        uiPathOf(path2d).transform(s.transform.writeMatrix4(_m4))
          ..fillType = fillType,
      );
    } else {
      final rect = _path.singleRect;
      final rrect = _path.singleRRect;
      clip = rect != null
          ? _RectClip(rect)
          : rrect != null
          ? _RRectClip(rrect)
          : _PathClip(ui.Path.from(_path.path)..fillType = fillType);
    }
    if (_batch.length > 0) _flushBatch();
    if (_sectorRun > 0) _flushSectorRun();
    // The first clip of a saved state makes the save of that state.
    final first = _depth > 0 && !_ownsClips;
    s.clips = [...s.clips, clip];
    final canvas = _canvas;
    if (canvas != null) {
      if (first) canvas.save();
      clip.applyTo(canvas);
    }
  }

  // Line styles.

  @override
  double? get lineWidth => _s.lineWidth;

  @override
  set lineWidth(double? value) {
    if (value == null || !value.isFinite || value <= 0) return;
    _s.lineWidth = value;
  }

  @override
  ui.StrokeCap? get lineCap => _s.cap;

  @override
  set lineCap(ui.StrokeCap? value) {
    if (value == null) return;
    _s.cap = value;
  }

  @override
  ui.StrokeJoin? get lineJoin => _s.join;

  @override
  set lineJoin(ui.StrokeJoin? value) {
    if (value == null) return;
    _s.join = value;
  }

  @override
  double? get miterLimit => _s.miterLimit;

  @override
  set miterLimit(double? value) {
    if (value == null || !value.isFinite || value <= 0) return;
    _s.miterLimit = value;
  }

  @override
  void setLineDash(List<double> segments) {
    for (final segment in segments) {
      if (!segment.isFinite || segment < 0) return;
    }
    // Chart.js sets the dash for each line that it draws, most often to
    // the value that the state already has: keep that list.
    final n = segments.length;
    final current = _s.lineDash;
    if (current.length == (n.isOdd ? 2 * n : n)) {
      var same = true;
      for (var i = 0; i < current.length; i++) {
        if (current[i] != segments[i % n]) {
          same = false;
          break;
        }
      }
      if (same) return;
    }
    _s.lineDash = n == 0
        ? const <double>[]
        : List.unmodifiable(n.isOdd ? [...segments, ...segments] : segments);
  }

  @override
  List<double> getLineDash() => List.of(_s.lineDash);

  @override
  double? get lineDashOffset => _s.lineDashOffset;

  @override
  set lineDashOffset(double? value) {
    if (value == null || !value.isFinite) return;
    _s.lineDashOffset = value;
  }

  // Text.

  /// Reads back the string as set. A font that does not parse does nothing.
  @override
  String? get font => _s.font;

  @override
  set font(String? value) {
    if (value == null) return;
    final parsed = parseCanvasFont(value);
    if (parsed == null) return;
    _s
      ..font = value
      ..fontValue = parsed;
  }

  @override
  ui.TextAlign? get textAlign => _s.textAlign;

  @override
  set textAlign(ui.TextAlign? value) {
    // The WebIDL setter ignores a value outside the enum: the type keeps out
    // each value but Dart `null`.
    if (value == null) return;
    _s.textAlign = value;
  }

  @override
  CanvasTextBaseline? get textBaseline => _s.textBaseline;

  // The WebIDL setter ignores a value outside the enum: the type keeps out
  // each value but Dart `null`.
  @override
  set textBaseline(CanvasTextBaseline? value) {
    if (value == null) return;
    _s.textBaseline = value;
  }

  @override
  String? get direction => _s.direction;

  @override
  set direction(String? value) {
    if (!_directions.contains(value)) return;
    _s.direction = value!;
  }

  bool get _isRtl {
    final direction = _s.direction;
    if (direction == 'inherit') {
      return _element.style.getPropertyValue('direction') == 'rtl';
    }
    return direction == 'rtl';
  }

  /// The x of the left edge of a text of [width] from its anchor.
  // DIVERGES(chartjs): adapt-flutter-text-align, the Flutter enum.
  double _alignOffset(double width, bool rtl) => switch (_s.textAlign) {
    ui.TextAlign.left => 0,
    ui.TextAlign.right => -width,
    ui.TextAlign.center => -width / 2,
    ui.TextAlign.end => rtl ? 0 : -width,
    ui.TextAlign.start || ui.TextAlign.justify => rtl ? -width : 0,
  };

  @override
  void fillText(String text, double x, double y, [double? maxWidth]) =>
      _drawText(text, x, y, maxWidth, stroke: false);

  @override
  void strokeText(String text, double x, double y, [double? maxWidth]) =>
      _drawText(text, x, y, maxWidth, stroke: true);

  void _drawText(
    String text,
    double x,
    double y,
    double? maxWidth, {
    required bool stroke,
  }) {
    if (_disposed || !x.isFinite || !y.isFinite) return;
    // A maxWidth of 0, a negative one or NaN draws nothing.
    if (maxWidth != null && !(maxWidth > 0)) return;
    final s = _s;
    final t = s.transform;
    final alpha = s.globalAlpha;
    if (!t.isInvertible || text.isEmpty || alpha == 0) return;
    final prepared = prepareCanvasText(text);
    final rtl = _isRtl;
    final direction = rtl ? ui.TextDirection.rtl : ui.TextDirection.ltr;
    final font = s.fontValue;
    final color = stroke ? s.strokeColor : s.fillColor;
    final source = stroke ? s.strokeShader : s.fillShader;

    double width;
    double sx;
    double dx;
    CanvasTextLayout layout;
    if (source == null) {
      final c = alpha == 1 ? color! : color!.withValues(alpha: color.a * alpha);
      if (c.a == 0) return;
      if (stroke) {
        // The paint is built on a cache miss only.
        layout = layoutCanvasText(
          font,
          prepared,
          direction,
          buildForeground: () => _textStrokePaint(c),
          cacheKey: (c, s.lineWidth, s.cap, s.join, s.miterLimit),
        );
      } else {
        layout = layoutCanvasText(
          font,
          prepared,
          direction,
          color: c,
          cacheKey: c,
        );
      }
      width = layout.width;
      sx = maxWidth != null && width > maxWidth ? maxWidth / width : 1;
      dx = _alignOffset(width, rtl);
    } else {
      // The shader maps the user space into the space of the paragraph,
      // which the draw below reaches with the transform, translate(x, y)
      // and scale(sx, 1): the shader is the inverse of the last two. Only
      // a maxWidth needs the width before the layout.
      if (maxWidth == null) {
        sx = 1;
      } else {
        final measured = measureCanvasText(font, prepared).width;
        sx = measured > maxWidth ? maxWidth / measured : 1;
      }
      final matrix = Float64List(16)
        ..[0] = 1 / sx
        ..[5] = 1
        ..[10] = 1
        ..[12] = -x / sx
        ..[13] = -y
        ..[15] = 1;
      final shader = source.shaderFor(matrix);
      if (shader == null) return;
      final paint = (stroke ? _textStrokePaint(_black) : ui.Paint())
        ..shader = shader
        ..color = _black.withValues(alpha: alpha);
      layout = layoutCanvasText(font, prepared, direction, foreground: paint);
      width = layout.width;
      dx = _alignOffset(width, rtl);
    }
    final shift = canvasBaselineShift(
      s.textBaseline,
      font.size,
      layout.ascent,
      layout.descent,
      layout.ideographic,
    );
    final top = shift - layout.ascent;
    // A gradient or a pattern needs the paragraph space of its shader.
    void place(ui.Paragraph paragraph) {
      if (source == null && t.isTranslation && sx == 1) {
        _c.drawParagraph(
          paragraph,
          ui.Offset(t.e + x + dx, t.f + y + top),
        );
      } else {
        final canvas = _c
          ..save()
          ..transform(
            t.isSimilarity && !t.isAxisAligned
                ? _snappedTextMatrix(t, x, y)
                : t.writeMatrix4(_m4),
          )
          ..translate(x, y);
        if (sx != 1) canvas.scale(sx, 1);
        canvas
          ..drawParagraph(paragraph, ui.Offset(dx, top))
          ..restore();
      }
    }

    if (s.shadowOn) {
      final sourceAlpha = source == null ? color!.a * alpha : alpha;
      final paint = stroke ? _textStrokePaint(_black) : ui.Paint();
      final sigma = _shadowSigma(user: true);
      paint
        ..color = s.shadowColor.withValues(
          alpha: s.shadowColor.a * sourceAlpha,
        )
        ..maskFilter = sigma > 0
            ? ui.MaskFilter.blur(ui.BlurStyle.normal, sigma)
            : null;
      final shadow = layoutCanvasText(
        font,
        prepared,
        direction,
        foreground: paint,
      );
      _c
        ..save()
        ..translate(s.shadowOffsetX, s.shadowOffsetY);
      place(shadow.paragraph);
      _c.restore();
      shadow.paragraph.dispose();
    }
    place(layout.paragraph);
    // An uncached layout (a gradient or a pattern) is not used again. The
    // recording keeps its own reference to the painted text.
    if (source != null) layout.paragraph.dispose();
    _drew();
  }

  /// The matrix of [t] with its rotation snapped to [_textAngleStep], for
  /// text drawn at the user point (x, y). The point keeps its exact bitmap
  /// position: only the rotation around it changes, by at most half a
  /// step.
  ///
  /// Skia (skwasm, CanvasKit) and Impeller cache the glyphs of a text for
  /// each exact rotation (a strike). Labels that turn in each frame ask
  /// for new strikes in each frame: on macOS 200 such labels took 85 ms of
  /// raster time. On skwasm the strike cache then churns, and its access
  /// from the main thread (paragraph shaping) races with its access from
  /// the render worker: the page crashed with `memory access out of
  /// bounds` in `SkStrikeCache::findOrCreateStrike`. With 20000 points
  /// and 200 turning labels, 2 of 3 runs crashed without a snap, 1 of 6
  /// with a step of 0.5 degrees, and 0 of 6 with 2 degrees. Snapped
  /// rotations reuse the cached strikes. A label shows at most 1 degree
  /// away from its angle, a display-only difference (Chart.js ADR 0034).
  Float64List _snappedTextMatrix(UiTransform t, double x, double y) {
    final angle = (t.angle / _textAngleStep).roundToDouble() * _textAngleStep;
    final scale = t.scaleFactor;
    final cos = math.cos(angle) * scale;
    final sin = math.sin(angle) * scale;
    final a = cos;
    final b = sin;
    final c = t.isReflected ? sin : -sin;
    final d = t.isReflected ? -cos : cos;
    final px = t.mapX(x, y);
    final py = t.mapY(x, y);
    return _m4
      ..fillRange(0, 16, 0)
      ..[0] = a
      ..[1] = b
      ..[4] = c
      ..[5] = d
      ..[10] = 1
      ..[12] = px - (a * x + c * y)
      ..[13] = py - (b * x + d * y)
      ..[15] = 1;
  }

  ui.Paint _textStrokePaint(ui.Color color) {
    final s = _s;
    return ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..color = color
      ..strokeWidth = s.lineWidth
      ..strokeCap = s.cap
      ..strokeJoin = s.join
      ..strokeMiterLimit = s.miterLimit;
  }

  /// `width` is the advance width. The `actualBoundingBox*` values are the
  /// advance box and the font ascent and descent, from the anchor of
  /// `textAlign` and `textBaseline`.
  @override
  TextMetrics measureText(String text) {
    final s = _s;
    final prepared = prepareCanvasText(text);
    if (prepared.isEmpty) {
      return const _UiTextMetrics(
        width: 0,
        actualBoundingBoxLeft: 0,
        actualBoundingBoxRight: 0,
        actualBoundingBoxAscent: 0,
        actualBoundingBoxDescent: 0,
      );
    }
    final font = s.fontValue;
    final metrics = measureCanvasText(font, prepared);
    final width = metrics.width;
    final dx = _alignOffset(width, _isRtl);
    final shift = canvasBaselineShift(
      s.textBaseline,
      font.size,
      metrics.ascent,
      metrics.descent,
      metrics.ideographic,
    );
    return _UiTextMetrics(
      width: width,
      actualBoundingBoxLeft: -dx,
      actualBoundingBoxRight: width + dx,
      actualBoundingBoxAscent: metrics.ascent - shift,
      actualBoundingBoxDescent: metrics.descent + shift,
    );
  }

  // Images.

  /// The shadow of an image goes through a layer, because a mask filter
  /// is not reliable on an image of each engine. The layer has the bounds of
  /// the image in bitmap space, with room for the blur.
  void _castImageShadow(ui.Image source, ui.Rect from, ui.Rect to) {
    final s = _s;
    final t = s.transform;
    final sigma = s.shadowBlur / 2;
    final xs = [
      t.mapX(to.left, to.top),
      t.mapX(to.right, to.top),
      t.mapX(to.left, to.bottom),
      t.mapX(to.right, to.bottom),
    ];
    final ys = [
      t.mapY(to.left, to.top),
      t.mapY(to.right, to.top),
      t.mapY(to.left, to.bottom),
      t.mapY(to.right, to.bottom),
    ];
    final bounds = ui.Rect.fromLTRB(
      xs.reduce(math.min),
      ys.reduce(math.min),
      xs.reduce(math.max),
      ys.reduce(math.max),
    ).inflate(sigma * 3 + 1);
    final layer = ui.Paint()
      ..blendMode = s.blendMode
      ..colorFilter = ui.ColorFilter.mode(s.shadowColor, ui.BlendMode.srcIn);
    if (sigma > 0) {
      layer.imageFilter = ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma);
    }
    _c
      ..save()
      ..translate(s.shadowOffsetX, s.shadowOffsetY)
      ..saveLayer(bounds, layer)
      ..transform(t.writeMatrix4(_m4))
      ..drawImageRect(source, from, to, _imagePaint)
      ..restore()
      ..restore();
  }

  /// Draws a [UiImageSource]. Another image source does nothing.
  @override
  void drawImage(
    CanvasImageSource image,
    double dx,
    double dy, [
    double? dw,
    double? dh,
  ]) {
    if (_disposed || image is! UiImageSource) return;
    final w = dw ?? image.width;
    final h = dh ?? image.height;
    final s = _s;
    final t = s.transform;
    if (!_finite4(dx, dy, w, h) || !t.isInvertible || w == 0 || h == 0) {
      return;
    }
    final alpha = s.globalAlpha;
    if (alpha == 0 && s.blendMode == ui.BlendMode.srcOver) return;
    if (s.blendMode != ui.BlendMode.srcOver) _needsLayer = true;
    _imagePaint
      ..color = alpha == 1 ? _black : _black.withValues(alpha: alpha)
      ..blendMode = s.blendMode;
    final source = image.image;
    final from = ui.Rect.fromLTWH(
      0,
      0,
      source.width.toDouble(),
      source.height.toDouble(),
    );
    final to = ui.Rect.fromLTRB(
      math.min(dx, dx + w),
      math.min(dy, dy + h),
      math.max(dx, dx + w),
      math.max(dy, dy + h),
    );
    if (s.shadowOn) _castImageShadow(source, from, to);
    _c
      ..save()
      ..transform(t.writeMatrix4(_m4))
      ..drawImageRect(source, from, to, _imagePaint)
      ..restore();
    _drew();
  }
}
