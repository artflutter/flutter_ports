import 'dart:js_interop';

@JS('Worker')
extension type _Worker._(JSObject _) implements JSObject {
  external factory(String url);

  external void terminate();
}

@JS('Blob')
extension type _Blob._(JSObject _) implements JSObject {
  external factory(JSArray<JSString> parts);
}

@JS('URL.createObjectURL')
external String _createObjectUrl(_Blob blob);

@JS('URL.revokeObjectURL')
external void _revokeObjectUrl(String url);

/// One busy Web Worker while a test runs.
///
/// A chart with a small workload leaves the CPU almost idle, so the system
/// keeps the browser threads on efficiency cores at low clocks, and a frame
/// takes longer than on a busy CPU. A spinning worker makes the system raise
/// the clocks and move the browser to performance cores.
class CpuLoad() {
  /// No load until [start].
  this;

  _Worker? _worker;
  String? _url;

  /// Starts the spinning worker, once.
  void start() {
    if (_worker != null) return;
    final url = _createObjectUrl(_Blob(['for (;;) {}'.toJS].toJS));
    _url = url;
    _worker = _Worker(url);
  }

  /// Ends the spinning worker.
  void stop() {
    _worker?.terminate();
    _worker = null;
    if (_url case final url?) _revokeObjectUrl(url);
    _url = null;
  }
}
