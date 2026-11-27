## 0.1.0

- Initial release: native, fully statically typed pure-Dart port of `d3-time`
  v3.1.0 (`TimeInterval`, `CountableTimeInterval`, `timeInterval`,
  `countableTimeInterval`, all local and UTC calendar intervals from
  millisecond through year plus `unixDay`/`timeUnixDay`, convenience range
  aliases, and `timeTicks`/`timeTicksWith`/`timeTickInterval`/`utcTicks`/
  `utcTicksWith`/`utcTickInterval`) with zero `dynamic`, native `DateTime`
  support, and hot-path optimizations for AOT, WebAssembly, and JavaScript.
