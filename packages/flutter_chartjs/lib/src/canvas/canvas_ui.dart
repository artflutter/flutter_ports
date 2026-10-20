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
///   a chart frame is one picture.
/// - A partial `clearRect` draws with `BlendMode.clear`. A composite
///   operation other than `source-over` blends with the content. Then
///   [UiCanvasContext.paint] draws the pictures inside a layer, so that
///   the clear does not reach what is below the canvas.
/// - [UiCanvasContext.paint] ends the current recording. When more than a
///   few pictures pile up without a full clear, the context flattens them
///   into one image of the bitmap size, so that memory stays bounded.
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

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_chartjs/src/canvas/canvas.dart';
import 'package:flutter_chartjs/src/canvas/canvas_ui_batch.dart';
import 'package:flutter_chartjs/src/canvas/canvas_ui_paint.dart';
import 'package:flutter_chartjs/src/canvas/canvas_ui_path.dart';
import 'package:flutter_chartjs/src/canvas/canvas_ui_text.dart';
import 'package:meta/meta.dart';

export 'package:flutter_chartjs/src/canvas/canvas_ui_paint.dart'
    show UiCanvasGradient, UiCanvasPattern, UiImageSource;
export 'package:flutter_chartjs/src/canvas/canvas_ui_text.dart'
    show CanvasFont, parseCanvasFont;

/// The count of pictures above which [UiCanvasContext.paint] flattens the
/// content into one image.
const int _maxPictures = 8;

const ui.Color _black = ui.Color(0xFF000000);

const String _defaultFontString = '10px sans-serif';

/// The step of the rotation of drawn text: 2 degrees (see
/// `UiCanvasContext._snappedTextMatrix`).
const double _textAngleStep = math.pi / 90;

final CanvasFont _defaultFont = parseCanvasFont(_defaultFontString)!;

const Map<String, ui.StrokeCap> _lineCaps = {
  'butt': ui.StrokeCap.butt,
  'round': ui.StrokeCap.round,
  'square': ui.StrokeCap.square,
};

const Map<String, ui.StrokeJoin> _lineJoins = {
  'miter': ui.StrokeJoin.miter,
  'round': ui.StrokeJoin.round,
  'bevel': ui.StrokeJoin.bevel,
};

const Set<String> _textAligns = {'start', 'end', 'left', 'right', 'center'};

const Set<String> _textBaselines = {
  'top',
  'hanging',
  'middle',
  'alphabetic',
  'ideographic',
  'bottom',
};

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
    // the attribute text is not a behavior of Chart.js ADR 0009.
    _serialized = true;
  }

  /// `cssText`: the declarations as `name: value;`, with ` !important` for
  /// an important one, joined by one space. The CSSOM serializes a
  /// declaration block in this form.
  String get cssText => [
    for (final MapEntry(key: name, value: (value, priority))
        in _properties.entries)
      priority.isEmpty ? '$name: $value;' : '$name: $value !$priority;',
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
  String lineCap = 'butt';
  ui.StrokeCap cap = ui.StrokeCap.butt;
  String lineJoin = 'miter';
  ui.StrokeJoin join = ui.StrokeJoin.miter;
  double miterLimit = 10;
  List<double> lineDash = const [];
  double lineDashOffset = 0;
  String font = _defaultFontString;
  CanvasFont fontValue = _defaultFont;
  String textAlign = 'start';
  String textBaseline = 'alphabetic';
  String direction = 'inherit';
  double globalAlpha = 1;
  String compositeOperation = 'source-over';
  ui.BlendMode blendMode = ui.BlendMode.srcOver;
  List<_Clip> clips = const [];

  void copyFrom(_State other) {
    transform.copyFrom(other.transform);
    fillColor = other.fillColor;
    fillShader = other.fillShader;
    strokeColor = other.strokeColor;
    strokeShader = other.strokeShader;
    lineWidth = other.lineWidth;
    lineCap = other.lineCap;
    cap = other.cap;
    lineJoin = other.lineJoin;
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
    compositeOperation = other.compositeOperation;
    blendMode = other.blendMode;
    clips = other.clips;
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
final class UiCanvasContext implements CanvasRenderingContext2D {
  UiCanvasContext._(this._element) {
    _s = _states[0];
    _path = UiPathBuilder(_s.transform);
  }

  final UiCanvasElement _element;

  final List<_State> _states = [_State()];
  int _depth = 0;
  late _State _s;
  late final UiPathBuilder _path;

  final ui.Path _scratch = ui.Path();
  final Float64List _m4 = Float64List(16);

  final ui.Paint _fillPaint = ui.Paint();
  final ui.Paint _strokePaint = ui.Paint()..style = ui.PaintingStyle.stroke;
  final ui.Paint _imagePaint = ui.Paint()..filterQuality = ui.FilterQuality.low;
  final ui.Paint _clearPaint = ui.Paint()..blendMode = ui.BlendMode.clear;
  final ui.Paint _layerPaint = ui.Paint();

  ui.PictureRecorder? _recorder;
  ui.Canvas? _canvas;
  // Full-circle fills and strokes not drawn yet. Every other access to the
  // recording canvas draws them first, so the draw order stays.
  final CircleBatch _batch = CircleBatch();
  bool _hasContent = false;
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

  /// The builder of the current path, for tests: its `singleRect`,
  /// `singleCircle` and `singleRRect` select the fast paths of [fill] and
  /// [clip].
  @visibleForTesting
  UiPathBuilder get debugPath => _path;

  /// The outer and the inner shape that `fill('evenodd')` of the current
  /// path draws with `drawDRRect`, or `null` when it draws the path, for
  /// tests.
  @visibleForTesting
  ({ui.RRect outer, ui.RRect inner})? get debugRing => _ring();

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
    if (_pictures.length > _maxPictures) _flatten();
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

  /// Releases the pictures. The context draws nothing after this call.
  void dispose() {
    if (_disposed) return;
    _discardRecording();
    _dropPictures();
    _disposed = true;
    _onChanged = null;
  }

  // The recording.

  ui.Canvas get _c {
    if (_batch.length > 0) _flushBatch();
    return _canvas ?? _begin();
  }

  /// Draws the pending circles of [_batch].
  void _flushBatch() {
    _batch.flush(_canvas ?? _begin());
  }

  /// Adds a fill or a stroke of [circle] in [color] to [_batch]. The
  /// caller checked that the paint has no shader and the `srcOver` mode.
  /// Returns false for a circle that the batch does not take.
  bool _batchCircle(
    ({double x, double y, double radius}) circle,
    ui.Color color, {
    required bool stroke,
    double width = 0,
  }) {
    if (circle.radius + width / 2 > maxBatchRadius ||
        circle.x.abs() > maxBatchCenter ||
        circle.y.abs() > maxBatchCenter) {
      return false;
    }
    if (!_batch.accepts(circle.radius, color, stroke: stroke, width: width)) {
      _flushBatch();
    }
    _batch.add(
      circle.x,
      circle.y,
      circle.radius,
      color,
      stroke: stroke,
      width: width,
    );
    _drew();
    return true;
  }

  /// Starts a recording. The saved states and their clips are replayed, so
  /// that the `ui.Canvas` stack matches the state stack.
  ui.Canvas _begin() {
    final recorder = _recorder = ui.PictureRecorder();
    final canvas = _canvas = ui.Canvas(recorder);
    var applied = 0;
    for (var i = 0; i <= _depth; i++) {
      final clips = _states[i].clips;
      for (; applied < clips.length; applied++) {
        clips[applied].applyTo(canvas);
      }
      if (i < _depth) canvas.save();
    }
    return canvas;
  }

  void _endRecording() {
    if (_batch.length > 0) _flushBatch();
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
  }

  void _discardRecording() {
    _batch.clear();
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
    _flatImage?.dispose();
    _flatImage = null;
    _needsLayer = false;
  }

  void _changed() {
    if (_notified) return;
    _notified = true;
    _onChanged?.call();
  }

  void _drew() {
    _hasContent = true;
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
        (x: x, y: y, radius: radius),
        color,
        stroke: true,
        width: s.lineWidth * scale,
      )) {
        return;
      }
    }
    if (!_setupStroke(scale, mapped: true)) return;
    _c.drawCircle(ui.Offset(x, y), radius, _strokePaint);
    _drew();
  }

  /// Whether a draw with [color] or [shader] can join the circle batch: a
  /// plain color in the `srcOver` mode.
  bool _batchable(ui.Color? color, UiShaderSource? shader) =>
      shader == null && color != null && _s.blendMode == ui.BlendMode.srcOver;

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

  @override
  void save() {
    if (_states.length == _depth + 1) _states.add(_State());
    if (_batch.length > 0) _flushBatch();
    final next = _states[_depth + 1]..copyFrom(_s);
    _depth++;
    _s = next;
    _path.transform = next.transform;
    _canvas?.save();
  }

  @override
  void restore() {
    if (_depth == 0) return;
    if (_batch.length > 0) _flushBatch();
    _depth--;
    _s = _states[_depth];
    _path.transform = _s.transform;
    _canvas?.restore();
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
  String? get globalCompositeOperation => _s.compositeOperation;

  /// A name that has no `ui.BlendMode` does nothing, as an unknown name in
  /// the DOM.
  @override
  set globalCompositeOperation(String? value) {
    final mode = compositeOperations[value];
    if (mode == null) return;
    _s
      ..compositeOperation = value!
      ..blendMode = mode;
  }

  // Styles.

  static Object _styleValue(ui.Color? color, UiShaderSource? shader) =>
      shader ?? serializeCssColor(color!);

  @override
  Object? get fillStyle => _styleValue(_s.fillColor, _s.fillShader);

  /// A CSS color string, a [UiCanvasGradient] or a [UiCanvasPattern]. A
  /// color that does not parse and another value do nothing.
  @override
  set fillStyle(Object? value) {
    if (value is String) {
      final color = parseCssColor(value);
      if (color == null) return;
      _s
        ..fillColor = color
        ..fillShader = null;
    } else if (value is UiShaderSource) {
      _s
        ..fillShader = value
        ..fillColor = null;
    }
  }

  @override
  Object? get strokeStyle => _styleValue(_s.strokeColor, _s.strokeShader);

  /// A CSS color string, a [UiCanvasGradient] or a [UiCanvasPattern]. A
  /// color that does not parse and another value do nothing.
  @override
  set strokeStyle(Object? value) {
    if (value is String) {
      final color = parseCssColor(value);
      if (color == null) return;
      _s
        ..strokeColor = color
        ..strokeShader = null;
    } else if (value is UiShaderSource) {
      _s
        ..strokeShader = value
        ..strokeColor = null;
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
    if (t.isAxisAligned) {
      _c.drawRect(_mappedRect(x, y, w, h), _fillPaint);
    } else {
      _c.drawPath(_rectPath(x, y, w, h), _fillPaint);
    }
    _drew();
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
      _c
        ..save()
        ..transform(s.transform.writeMatrix4(_m4))
        ..drawPath(path, _fillPaint)
        ..restore();
    } else {
      if (_path.isEmpty) return;
      final circle = _path.singleCircle;
      // A transform that overflowed to a center of NaN: the path has a NaN
      // point, and Skia draws nothing.
      if (circle != null && (circle.x.isNaN || circle.y.isNaN)) return;
      if (circle != null && _batchable(s.fillColor, s.fillShader)) {
        final color = _batchColor(s.fillColor!);
        if (color == null) return;
        if (_batchCircle(circle, color, stroke: false)) return;
      }
      if (!_setupPaint(
        _fillPaint,
        s.fillColor,
        s.fillShader,
        mapped: true,
      )) {
        return;
      }
      final rect = _path.singleRect;
      if (rect != null) {
        _c.drawRect(rect, _fillPaint);
      } else if (circle != null) {
        _c.drawCircle(
          ui.Offset(circle.x, circle.y),
          circle.radius,
          _fillPaint,
        );
      } else {
        final rrect = _path.singleRRect;
        final ring = rrect == null && fillType == ui.PathFillType.evenOdd
            ? _ring()
            : null;
        if (rrect != null) {
          _c.drawRRect(rrect, _fillPaint);
        } else if (ring != null) {
          _c.drawDRRect(ring.outer, ring.inner, _fillPaint);
        } else {
          _c.drawPath(_path.path..fillType = fillType, _fillPaint);
        }
      }
    }
    _drew();
  }

  /// The two shapes of the current path as an outer and an inner shape, when
  /// the path is two `rect` or `roundRect` commands ([UiPathBuilder.shapePair])
  /// and one of them is inside the other ([rrectContains]). Then the
  /// even-odd fill of the path is `drawDRRect(outer, inner)`: the border
  /// ring of a bar (`element.bar.js:188-192`). An inner shape with no width
  /// or no height takes the path: Skia then draws the outer shape, but the
  /// other engines are not examined.
  ({ui.RRect outer, ui.RRect inner})? _ring() {
    final pair = _path.shapePair;
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
      _strokeUser(uiPathOf(path));
    } else if (_path.isEmpty) {
      return;
    } else if (t.isSimilarity) {
      final circle = _path.singleCircle;
      if (circle != null && _s.lineDash.isEmpty) {
        _strokeCircle(circle.x, circle.y, circle.radius, t.scaleFactor);
      } else {
        _strokeMapped(_path.path, t.scaleFactor);
      }
    } else {
      _strokeUser(_path.path.transform(t.writeInverseMatrix4(_m4)));
    }
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
    s.clips = [...s.clips, clip];
    final canvas = _canvas;
    if (canvas != null) clip.applyTo(canvas);
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
  String? get lineCap => _s.lineCap;

  @override
  set lineCap(String? value) {
    final cap = _lineCaps[value];
    if (cap == null) return;
    _s
      ..lineCap = value!
      ..cap = cap;
  }

  @override
  String? get lineJoin => _s.lineJoin;

  @override
  set lineJoin(String? value) {
    final join = _lineJoins[value];
    if (join == null) return;
    _s
      ..lineJoin = value!
      ..join = join;
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
  String? get textAlign => _s.textAlign;

  @override
  set textAlign(String? value) {
    if (!_textAligns.contains(value)) return;
    _s.textAlign = value!;
  }

  @override
  String? get textBaseline => _s.textBaseline;

  @override
  set textBaseline(String? value) {
    if (!_textBaselines.contains(value)) return;
    _s.textBaseline = value!;
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
  double _alignOffset(double width, bool rtl) => switch (_s.textAlign) {
    'left' => 0,
    'right' => -width,
    'center' => -width / 2,
    'end' => rtl ? 0 : -width,
    _ => rtl ? -width : 0,
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
    final canvas = _c;
    // A gradient or a pattern needs the paragraph space of its shader.
    if (source == null && t.isTranslation && sx == 1) {
      canvas.drawParagraph(
        layout.paragraph,
        ui.Offset(t.e + x + dx, t.f + y + top),
      );
    } else {
      canvas
        ..save()
        ..transform(
          t.isSimilarity && !t.isAxisAligned
              ? _snappedTextMatrix(t, x, y)
              : t.writeMatrix4(_m4),
        )
        ..translate(x, y);
      if (sx != 1) canvas.scale(sx, 1);
      canvas
        ..drawParagraph(layout.paragraph, ui.Offset(dx, top))
        ..restore();
    }
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
  /// away from its angle, a display-only difference (Chart.js ADR 0009).
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
    _c
      ..save()
      ..transform(t.writeMatrix4(_m4))
      ..drawImageRect(
        source,
        ui.Rect.fromLTWH(
          0,
          0,
          source.width.toDouble(),
          source.height.toDouble(),
        ),
        ui.Rect.fromLTRB(
          math.min(dx, dx + w),
          math.min(dy, dy + h),
          math.max(dx, dx + w),
          math.max(dy, dy + h),
        ),
        _imagePaint,
      )
      ..restore();
    _drew();
  }
}
