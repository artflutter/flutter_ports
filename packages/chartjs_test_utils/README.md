# chartjs_test_utils

This package is the test harness of [flutter_chartjs](../flutter_chartjs). It ports
[chartjs-test-utils](https://github.com/chartjs/chartjs-test-utils) 0.4.0 module by module. Chart.js
uses chartjs-test-utils in its own specs.

The package is not published. It is a dev_dependency of `flutter_chartjs` only.
[porting-flow.md](../flutter_chartjs/doc/porting-flow.md) section 3 gives the module plan and the
phase of each module.

## Libraries

- `package:chartjs_test_utils/pure.dart`: the spec set-up for `dart test`. `dart test` does not
  read `flutter_test_config.dart`. Thus each pure-layer spec file calls `setUpSpecs()` first in
  `main()`. `setUpSpecs()` takes a snapshot of `defaults`, `overrides` and `descriptors` of
  `core.defaults` once for each file. It restores the snapshot after each test. This library
  imports only `package:test` and pure layers. Thus it compiles with dart2js and dart2wasm.

## License

MIT. The [LICENSE](LICENSE) file names the chartjs-test-utils Contributors and the holder of this
repository.
