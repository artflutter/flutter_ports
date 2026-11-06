// Prints the screens in window coordinates, then each normal window: owner, x, y, width, height.
import AppKit
import CoreGraphics
let mainH = NSScreen.screens[0].frame.height
for s in NSScreen.screens {
  let f = s.frame
  print("screen \(s.localizedName) x=\(Int(f.minX)) y=\(Int(mainH - f.maxY)) w=\(Int(f.width)) h=\(Int(f.height)) hz=\(s.maximumFramesPerSecond)")
}
let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as! [[String: Any]]
for w in list where (w[kCGWindowLayer as String] as? Int) == 0 {
  let b = w[kCGWindowBounds as String] as! [String: CGFloat]
  print("window \(w[kCGWindowOwnerName as String] ?? "?") x=\(Int(b["X"]!)) y=\(Int(b["Y"]!)) w=\(Int(b["Width"]!)) h=\(Int(b["Height"]!))")
}
