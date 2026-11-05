import Cocoa
import FlutterMacOS
import CoreGraphics

class MainFlutterWindow: NSWindow {
  private var benchmarkChannel: FlutterMethodChannel?
  private var windowObservers: [NSObjectProtocol] = []

  override func awakeFromNib() {
    let controller = FlutterViewController()
    contentViewController = controller
    RegisterGeneratedPlugins(registry: controller)
    super.awakeFromNib()

    title = "Chart benchmark lab"
    minSize = NSSize(width: 700, height: 620)
    // Apply placement after Cocoa finishes restoring the window frame.
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
      guard let window = self else { return }
      let requested = ProcessInfo.processInfo.environment["BENCH_DISPLAY_ID"]
      let target = NSScreen.screens.first { screen in
        guard let id = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else { return false }
        if let requested = requested { return id.stringValue == requested }
        return CGDisplayIsBuiltin(CGDirectDisplayID(id.uint32Value)) != 0
      } ?? NSScreen.main
      if let screen = target {
        let bounds = screen.visibleFrame
        window.setContentSize(NSSize(width: min(1360, bounds.width - 32),
                                     height: min(900, bounds.height - 64)))
        window.setFrameOrigin(NSPoint(x: bounds.minX + 16, y: bounds.minY + 16))
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
      }
    }
    benchmarkChannel = FlutterMethodChannel(
      name: "dev.artflutter.chart_benchmark_lab/window",
      binaryMessenger: controller.engine.binaryMessenger)
    benchmarkChannel?.setMethodCallHandler { [weak self] call, result in
      guard call.method == "isVisible", let window = self else {
        result(FlutterMethodNotImplemented)
        return
      }
      result(window.occlusionState.contains(.visible) && !window.isMiniaturized && !NSApp.isHidden)
    }
    for name in [NSWindow.didChangeOcclusionStateNotification,
                 NSWindow.didMiniaturizeNotification,
                 NSWindow.didDeminiaturizeNotification] {
      windowObservers.append(NotificationCenter.default.addObserver(
        forName: name, object: self, queue: .main) { [weak self] _ in
          self?.reportVisibility()
        })
    }
    for name in [NSApplication.didHideNotification, NSApplication.didUnhideNotification] {
      windowObservers.append(NotificationCenter.default.addObserver(
        forName: name, object: NSApp, queue: .main) { [weak self] _ in
          self?.reportVisibility()
        })
    }
    windowObservers.append(NotificationCenter.default.addObserver(
      forName: NSWindow.didChangeScreenNotification, object: self, queue: .main) { [weak self] _ in
        self?.benchmarkChannel?.invokeMethod("screenChanged", arguments: nil)
      })
  }

  private func reportVisibility() {
    let visible = occlusionState.contains(.visible) && !isMiniaturized && !NSApp.isHidden
    benchmarkChannel?.invokeMethod("visibility", arguments: visible)
  }

  deinit {
    for observer in windowObservers { NotificationCenter.default.removeObserver(observer) }
  }
}
