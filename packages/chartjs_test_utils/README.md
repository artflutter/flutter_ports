# chartjs_test_utils

This package is the test harness of [flutter_chartjs](../flutter_chartjs). It ports
[chartjs-test-utils](https://github.com/chartjs/chartjs-test-utils) 0.4.0 module by module. Chart.js
uses chartjs-test-utils in its own specs.

The package is not published. It is a dev_dependency of `flutter_chartjs` only.
[porting-flow.md](../flutter_chartjs/doc/porting-flow.md) section 3 gives the module plan and the
phase of each module.

## Libraries

- `package:chartjs_test_utils/pure.dart`: the pure part. This library imports only `package:test`
  and pure layers. Thus it compiles with dart2js and dart2wasm.
  - `setUpSpecs()`: the spec set-up for `dart test`. `dart test` does not read
    `flutter_test_config.dart`. Thus each pure-layer spec file calls `setUpSpecs()` first in
    `main()`. It calls `setUpDefaultsRestore()`, which takes a snapshot of `defaults`, `overrides`
    and `descriptors` of `core.defaults` once for each file and restores the snapshot after each
    test. `flutter_chartjs/test/flutter_test_config.dart` calls `setUpDefaultsRestore()` too.
  - `createMockContext()` and `MockContext` (`src/index.js`, `src/context.js`): the mock canvas
    context that records calls.
  - The matchers `toBeCloseToPixel`, `toBeCloseToPoint`, `toEqualOneOf` (`src/matchers.js`) and
    `toEqualOptions` (`src/matchers.options.js`), as `package:matcher` matchers:
    `expect(actual, toBeCloseToPixel(expected))`.
- `package:chartjs_test_utils/flutter.dart`: the part that needs the Flutter engine, for
  `flutter test` only. `installTestFont()` registers the test font, Liberation Sans 2.1.5, under
  the names `Helvetica Neue`, `Helvetica`, `Arial`, `Liberation Sans` and `sans-serif`. Phase 5
  adds `acquireChart` and the other chart helpers here.

## License

MIT. The [LICENSE](LICENSE) file names the chartjs-test-utils Contributors and the holder of this
repository. The font files in `lib/fonts/` are unchanged files of
[liberation-fonts-ttf-2.1.5](https://github.com/liberationfonts/liberation-fonts/releases/tag/2.1.5),
under the SIL Open Font License 1.1 ([lib/fonts/LICENSE](lib/fonts/LICENSE)). The LICENSE file has
the OFL as a separate component.
