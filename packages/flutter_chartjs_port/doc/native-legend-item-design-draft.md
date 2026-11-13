# LegendItem — class design draft

```dart
class LegendItem({
  required List<String> text,
  ChartPaint fillStyle = const ChartPaint.unchanged(),
  ChartPaint fontColor = const ChartPaint.unchanged(),
  bool hidden = false,
  StrokeCap? lineCap,
  List<double>? lineDash,
  double? lineDashOffset,
  StrokeJoin? lineJoin,
  double? lineWidth,
  ChartPaint strokeStyle = const ChartPaint.unchanged(),
  PointStyle? pointStyle,
  double? rotation,
  TextAlign? textAlign,
  TRBLCorners? borderRadius,
  int? datasetIndex,
  int? index,
}) {
  this;

  // Null arguments retain the current field. Nullable fields can be cleared
  // directly on the returned mutable item.
  LegendItem copyWith({
    List<String>? text,
    ChartPaint? fillStyle,
    ChartPaint? fontColor,
    bool? hidden,
    StrokeCap? lineCap,
    List<double>? lineDash,
    double? lineDashOffset,
    StrokeJoin? lineJoin,
    double? lineWidth,
    ChartPaint? strokeStyle,
    PointStyle? pointStyle,
    double? rotation,
    TextAlign? textAlign,
    TRBLCorners? borderRadius,
    int? datasetIndex,
    int? index,
  }) => LegendItem(
    text: text ?? this.text,
    fillStyle: fillStyle ?? this.fillStyle,
    fontColor: fontColor ?? this.fontColor,
    hidden: hidden ?? this.hidden,
    lineCap: lineCap ?? this.lineCap,
    lineDash: lineDash ?? this.lineDash,
    lineDashOffset: lineDashOffset ?? this.lineDashOffset,
    lineJoin: lineJoin ?? this.lineJoin,
    lineWidth: lineWidth ?? this.lineWidth,
    strokeStyle: strokeStyle ?? this.strokeStyle,
    pointStyle: pointStyle ?? this.pointStyle,
    rotation: rotation ?? this.rotation,
    textAlign: textAlign ?? this.textAlign,
    borderRadius: borderRadius ?? this.borderRadius,
    datasetIndex: datasetIndex ?? this.datasetIndex,
    index: index ?? this.index,
  );

  // Text and hidden replace their values. Null optional fields and unchanged
  // paints inherit. Neither input is mutated; merge(null) returns this.
  LegendItem merge(LegendItem? other) {
    if (other == null) return this;
    return copyWith(
      text: other.text,
      fillStyle: other.fillStyle is UnchangedChartPaint
          ? null
          : other.fillStyle,
      fontColor: other.fontColor is UnchangedChartPaint
          ? null
          : other.fontColor,
      hidden: other.hidden,
      lineCap: other.lineCap,
      lineDash: other.lineDash,
      lineDashOffset: other.lineDashOffset,
      lineJoin: other.lineJoin,
      lineWidth: other.lineWidth,
      strokeStyle: other.strokeStyle is UnchangedChartPaint
          ? null
          : other.strokeStyle,
      pointStyle: other.pointStyle,
      rotation: other.rotation,
      textAlign: other.textAlign,
      borderRadius: other.borderRadius,
      datasetIndex: other.datasetIndex,
      index: other.index,
    );
  }
}
```

Uses the same primary-constructor style as `TooltipCallbacks`, its `List<String>` text convention,
and the existing `ChartPaint`. `TRBLCorners` is the existing typed corner contract, already implemented
by `TooltipCornerRadii`. `ChartPaint.unchanged()` selects the legend's resolved baseline paint.
Fields remain mutable for legend interaction. Plugins can extend `LegendItem` with typed fields and behavior,
or implement its contract. Generators and consumers accept these implementations and preserve their identity;
they must not require an exact runtime class or copy items into base-class instances.
`copyWith` and `merge` are overridable. A subclass overrides `copyWith` to return its own type and retain its
additional fields; it overrides `merge` when those fields also participate in merging. The inherited `merge`
calls `copyWith` virtually. Copies share referenced lists, paints and point styles.
No new text or paint wrappers or `Object?` fields.
