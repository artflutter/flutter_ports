# Chart.js ADR 0014: Input events and the chart host

- Status: accepted (2026-10-21)
- Superseded by: [Chart.js ADR 0037](0037-legend-and-tooltip-input-path.md) (2026-10-29)
- Date: 2026-10-19
- Full text: `git show ac269e6feef50e1b382722e1ff4c17f0079cb130:packages/flutter_chartjs_port/doc/adr/0014-input-events-and-chart-host.md`

## Summary

`platform.flutter.dart` replaces `platform.dom.js`, and the port-only `ChartHost` render object shows one canvas.
The host sizes the chart in its first layout and reports later size, DPR and attach changes.
The host stretches the bitmap to the display size of the canvas and clips to its box.
Flutter pointer events give the DOM event names that a browser fires for the same input.
The host reads raw pointer events with no drag claim, and only a `click` listener adds a tap recognizer.

## Where each part went

- §1 (the platform files and `NativeEvent`): [Chart.js ADR 0037](0037-legend-and-tooltip-input-path.md) §1.
- §2 (the chart host): [Chart.js ADR 0037](0037-legend-and-tooltip-input-path.md) §2.
- §3 (the first size): [Chart.js ADR 0037](0037-legend-and-tooltip-input-path.md) §3.
- §4 (the later size, DPR and attach changes): [Chart.js ADR 0037](0037-legend-and-tooltip-input-path.md) §4.
- §5 (the size rules, the attributes and the stretch): [Chart.js ADR 0037](0037-legend-and-tooltip-input-path.md)
  §5.
- §6 (the event names): [Chart.js ADR 0037](0037-legend-and-tooltip-input-path.md) §6.
- §7 (the tap recognizer of a `click` listener): replaced by the click rule of
  [Chart.js ADR 0037](0037-legend-and-tooltip-input-path.md) §7.
- §7 (the gesture arena and the touch scope): [Chart.js ADR 0037](0037-legend-and-tooltip-input-path.md) §10.
- §7 (the claims of a `touch-action: none` sequence and of a prevented `wheel`):
  [Chart.js ADR 0108](0108-input-surface-and-exports-for-add-on-plugins.md) §8.
- §8 (the listeners and the throttle): [Chart.js ADR 0037](0037-legend-and-tooltip-input-path.md) §11.
- §8 (the listener option `passive`): [Chart.js ADR 0108](0108-input-surface-and-exports-for-add-on-plugins.md)
  §6.
- §9 (the event position): [Chart.js ADR 0037](0037-legend-and-tooltip-input-path.md) §12.
- §10 (the type members): [Chart.js ADR 0037](0037-legend-and-tooltip-input-path.md) §13.
- §11 (the harness detach without an unmount): [Chart.js ADR 0022](0022-chart-test-harness.md) §10.
- §11 (the keyboard, the public widget and the ticker mode):
  [Chart.js ADR 0037](0037-legend-and-tooltip-input-path.md) §16.
- Evidence (the host tests): [Chart.js ADR 0037](0037-legend-and-tooltip-input-path.md) Evidence E7.
- Open (the touch sizes): [Chart.js ADR 0050](0050-public-theme-api.md), Decision, the bullet "No touch sizes".
- Open (the tooltip after a touch lift, #7738): [Chart.js ADR 0037](0037-legend-and-tooltip-input-path.md) §8
  and §9.
- Open (the compatibility mouse events of a touch tap): [Chart.js ADR 0037](0037-legend-and-tooltip-input-path.md)
  §9.
- Open (`dblclick` and `contextmenu`): [Chart.js ADR 0037](0037-legend-and-tooltip-input-path.md) §16.
- Open (trackpad `PointerPanZoom` gestures as `wheel`): [Chart.js ADR 0137](0137-trackpad-wheel-events.md).
- Open (a DPR change on a real device): [Chart.js ADR 0037](0037-legend-and-tooltip-input-path.md) Open 8.
- Open (the arena-free click): [Chart.js ADR 0037](0037-legend-and-tooltip-input-path.md) §7.
- Open (a mouse drag that starts outside the chart): [Chart.js ADR 0037](0037-legend-and-tooltip-input-path.md)
  Open 7.
