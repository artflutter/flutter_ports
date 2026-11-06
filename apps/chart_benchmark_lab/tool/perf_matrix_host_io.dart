// The host side of the matrix driver on a native target.
import 'dart:io';

File? _lines;

/// The value of an option of the process environment.
String? hostEnv(String name) => Platform.environment[name];

/// Starts a new result file. A phone keeps the lines in its temporary folder,
/// because a profile app on iOS gives no reliable console.
void hostStart() {
  try {
    _lines = File('${Directory.systemTemp.path}/matrix_lines.txt')
      ..writeAsStringSync('');
  } on FileSystemException {
    _lines = null;
  }
}

/// Gives one result line to the host.
void hostLine(String line) {
  if (Platform.isMacOS) {
    stdout.writeln(line);
  } else {
    // The console of the platform: logcat on Android.
    // ignore: avoid_print
    print(line);
  }
  _lines?.writeAsStringSync('$line\n', mode: FileMode.append, flush: true);
}

/// Ends the app.
Future<void> hostExit() async {
  if (Platform.isMacOS) await stdout.flush();
  exit(0);
}
