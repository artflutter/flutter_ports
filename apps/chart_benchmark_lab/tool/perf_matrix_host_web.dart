// The host side of the matrix driver in a browser.
import 'dart:js_interop';

@JS('fetch')
external JSPromise<JSAny?> _fetch(JSString url, JSAny init);

/// The value of an option of the page address.
String? hostEnv(String name) => Uri.base.queryParameters[name];

/// A browser needs no result file.
void hostStart() {}

/// Gives one result line to the server of the page.
void hostLine(String line) {
  // The console of the browser, for a person who watches the run.
  // ignore: avoid_print
  print(line);
  _fetch(
    '/line'.toJS,
    <String, Object?>{'method': 'POST', 'body': line}.jsify()!,
  );
}

/// A page stays open at its end.
Future<void> hostExit() async {}
