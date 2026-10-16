# chartjs_gallery

Gallery and visual test bed for [`flutter_chartjs`](../../packages/flutter_chartjs), on Android,
iOS, web and macOS. It lists every Chart.js chart type and will show each one as its port lands,
modelled on the [Chart.js samples](https://www.chartjs.org/docs/latest/samples/).

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
