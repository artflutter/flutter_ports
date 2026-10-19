// Ported from Chart.js v4.5.1 test/specs/platform.dom.tests.js (MIT, Chart.js Contributors).
import 'package:chartjs_test_utils/pure.dart';
import 'package:test/test.dart';

// platform.flutter.dart replaces platform.dom.js (Chart.js ADR 0014). The
// cases that create a chart wait for core.controller. The cases of DOM ids,
// iframes and DOM nodes have no Flutter counterpart.
// test/port/platform/platform.flutter_test.dart and chart_host_test.dart
// test the Flutter platform and the chart host without a chart.

void main() {
  setUpSpecs();
  group('Platform.dom', () {
    group('context acquisition', () {
      test(
        'should use the DomPlatform by default',
        () {},
        skip: 'blocked: core.controller',
      );

      test(
        'should gracefully handle invalid item',
        () {},
        skip: 'blocked: core.controller',
      );

      test(
        'should accept a DOM element id',
        () {},
        skip: 'n/a: Flutter has no DOM element ids',
      );

      test(
        'should accept a canvas element',
        () {},
        skip: 'blocked: core.controller',
      );

      test(
        'should accept a canvas context2D',
        () {},
        skip: 'blocked: core.controller',
      );

      test(
        'should accept an array containing canvas',
        () {},
        skip: 'blocked: core.controller',
      );

      test(
        'should accept a canvas from an iframe',
        () {},
        skip: 'n/a: Flutter has no iframes',
      );
    });

    group('config.options.aspectRatio', () {
      test(
        'should use default "global" aspect ratio for render and display '
        'sizes',
        () {},
        skip: 'blocked: core.controller',
      );

      test(
        'should use default "chart" aspect ratio for render and display sizes',
        () {},
        skip: 'blocked: core.controller',
      );

      test(
        'should use "user" aspect ratio for render and display sizes',
        () {},
        skip: 'blocked: core.controller',
      );

      test(
        'should not apply aspect ratio when height specified',
        () {},
        skip: 'blocked: core.controller',
      );
    });

    group('config.options.responsive: false', () {
      test(
        'should use default canvas size for render and display sizes',
        () {},
        skip: 'blocked: core.controller',
      );

      test(
        'should use canvas attributes for render and display sizes',
        () {},
        skip: 'blocked: core.controller',
      );

      test(
        'should use canvas style for render and display sizes (if no '
        'attributes)',
        () {},
        skip: 'blocked: core.controller',
      );

      test(
        'should use attributes for the render size and style for the display '
        'size',
        () {},
        skip: 'blocked: core.controller',
      );

      test(
        'should support decimal display width and/or height',
        () {},
        skip: 'blocked: core.controller',
      );
    });

    group('config.options.responsive: true (maintainAspectRatio: true)', () {
      test(
        'should fit parent using aspect ratio to calculate size',
        () {},
        skip: 'blocked: core.controller',
      );
    });

    group('controller.destroy', () {
      test(
        'should reset context to default values',
        () {},
        skip: 'blocked: core.controller',
      );

      test(
        'should restore canvas initial values',
        () {},
        skip: 'blocked: core.controller',
      );
    });

    group('event handling', () {
      test(
        'should notify plugins about events',
        () {},
        skip: 'blocked: core.controller',
      );
    });

    group('isAttached', () {
      test(
        'should detect detached when canvas is attached to DOM',
        () {},
        skip:
            'n/a: the spec builds a DOM tree; '
            'test/port/platform/platform.flutter_test.dart tests isAttached '
            'with a chart host',
      );
    });
  });
}
