// Original code, not ported from Chart.js: core.layouts.defaults tests.
import 'package:flutter_chartjs/src/core/core.layouts.defaults.dart';
import 'package:test/test.dart';

import 'recording_defaults.dart';

// core.layouts.defaults.js has no spec. The expected calls come from Node.js
// v24.12.0 (V8 13.6) on x64. It ran the upstream applyLayoutsDefaults on an
// object that records each call (recording_defaults.dart).

void main() {
  group('applyLayoutsDefaults', () {
    test('sets the layout defaults', () {
      final defaults = RecordingDefaults();
      applyLayoutsDefaults(defaults);
      const setLayout =
          '["set","layout",{"autoPadding":true,'
          '"padding":{"top":0,"right":0,"bottom":0,"left":0}}]';
      expect(defaults.calls.map(probeJson), [
        setLayout,
      ]);
    });
  });
}
