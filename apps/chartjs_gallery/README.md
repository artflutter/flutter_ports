# chartjs_gallery

Gallery and visual test bed for [`flutter_chartjs_port`](../../packages/flutter_chartjs_port), on Android,
iOS, web and macOS. It shows every Chart.js chart type with the charts of the
[Chart.js docs](https://www.chartjs.org/docs/latest/charts/) and runs each one through the ported
controllers and plugins. Each chart shows the legend, and the tooltip on a hover or a tap. The
Area page has the fill actions `origin`, `start`, `end` and `false` of the Area sample as its
variants. The page "Phase 3: canvas and host" has the canvas, element, core and scale demos and the
stress tests.

The type pages and the core and scale demos show their chart in the public widget `ChartView` and
import `package:flutter_chartjs_port/flutter_chartjs_port.dart`. The demos that draw without a
chart, the stress host `HOST=canvas` and the white-box tests also import files of `lib/src/`: the
comment above each such import gives the reason.

From the repository root:

```sh
dart run melos run gallery                # Chrome
dart run melos run gallery:macos          # macOS
dart run melos run gallery:device         # connected Android/iOS device, emulator or simulator
dart run melos run gallery:build:web      # web build (WebAssembly with a JavaScript fallback)
dart run melos run gallery:build:android  # debug APK
dart run melos run gallery:build:ios      # iOS build without code signing
```

CI builds the web, Android and iOS targets on every push and pull request.

Not published (`publish_to: none`).
