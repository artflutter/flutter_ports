// Ported from Chart.js v4.6.1 test/specs/plugin.subtitle.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';

import '../fixtures/index.dart' as fixture;

// The upstream spec has only the fixture group `auto` (Chart.js ADR 0029).
// The fixture runner builds charts, so the file runs on the VM. The one
// fixture `plugin.subtitle/basic.js` is pure data and needs no hand port.

void main() {
  group('plugin.subtitle', () {
    group('auto', fixture.specs('plugin.subtitle'));
  });
}
