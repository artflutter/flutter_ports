// Original code, not ported from Chart.js: native numeric bar update contracts.

import 'package:flutter_chartjs_port/src/options/parsed.dart' show ParsedItem;
import 'package:flutter_chartjs_port/src/options/props.dart' show BorderSkipped;
import 'package:flutter_chartjs_port/src/types/index.dart' as types;

/// A chart with ordinary context, pixel-ratio and visibility reads. Unknown
/// subclasses must not opt in merely because their topology reads are native.
abstract interface class BulkBarChart() {
  /// True only when no user code runs in those chart reads.
  bool get supportsBulkBarUpdate;
}

/// A scale whose numeric projection and grid-width lookup can be reused.
abstract interface class BulkBarScale() {
  /// Whether numeric value reads have the built-in linear-scale behavior.
  bool get supportsBulkBarUpdate;

  /// Whether the already-resolved grid lookup cannot run user code. This
  /// probe neither creates a tick context nor resolves a missing option.
  bool get hasStaticBulkBarGrid;
}

/// The direct write contract for exact native bar elements. Custom elements
/// retain DatasetController.updateElement and their property interception.
abstract interface class BulkBarElement() {
  /// True only for the exact built-in element. An explicit test opt-in must
  /// preserve ordinary active/context reads as well as native property writes.
  bool get supportsBulkBarWrites;

  /// Assign the same fields, in the same order, as the controller's ordinary
  /// property record. Each element receives its own skipped-edge object.
  void writeBulkBar({
    required bool horizontal,
    required double base,
    required double x,
    required double y,
    required double height,
    required double width,
    required Object options,
    required BorderSkipped skipped,
    required double inflate,
  });
}

/// Cached scalar inputs for the supported uniform-category numeric path.
typedef BulkBarOptions = ({
  double base,
  double? thickness,
  double categoryPercentage,
  double barPercentage,
  double maxThickness,
});

final _elementLists = <Type>{
  <types.Element>[].runtimeType,
  List<types.Element>.empty().runtimeType,
};
final _parsedLists = <Type>{
  <Object?>[].runtimeType,
  List<Object?>.empty().runtimeType,
  <ParsedItem>[].runtimeType,
  List<ParsedItem>.empty().runtimeType,
};

/// Only native arrays are preflighted; unknown List getters are never probed.
bool nativeBulkBarLists(List<types.Element> bars, List<Object?> parsed) =>
    nativeBulkBarElements(bars) && _parsedLists.contains(parsed.runtimeType);

/// Native element containers; prepared inputs are qualified by updateData.
bool nativeBulkBarElements(List<types.Element> bars) =>
    _elementLists.contains(bars.runtimeType);
