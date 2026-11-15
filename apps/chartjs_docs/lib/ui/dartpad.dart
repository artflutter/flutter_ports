// Original code, not ported from Chart.js: the DartPad links of the docs.

import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/link.dart';

/// The folder of the DartPad archives, next to the docs site. The workflow
/// `pages` writes one archive for each sample with a `main` function, with
/// `tool/dartpad_archives.dart`: `lib/<path>.dart` becomes `<path>.tar.gz`,
/// with the sample as one file `lib/main.dart` and a pubspec that gets the
/// packages from pub.dev.
const String dartPadArchives =
    'https://artflutter.github.io/flutter_ports/docs/dartpad';

/// The DartPad address that opens and runs the sample [file], relative to the
/// docs app. DartPad runs `lib/main.dart` of the archive. The address
/// collapses the file tree, so the page shows the code of the sample, its
/// problems and its chart.
Uri dartPadUri(String file) {
  if (!file.startsWith('lib/') || !file.endsWith('.dart')) {
    throw ArgumentError.value(file, 'file', 'not a Dart file of lib/');
  }
  final path = file.substring('lib/'.length, file.length - '.dart'.length);
  return Uri.https('dartpad.dev', '/', {
    'url': '$dartPadArchives/$path.tar.gz',
    'panels': '-filetree',
  });
}

/// A **Try in DartPad** button that opens the sample [file] in DartPad, in a
/// new tab.
class const DartPadLink(
  /// The sample file, relative to the docs app. It has a `main` function.
  final String file, {
  super.key,
}) extends StatelessWidget {
  /// Creates the button of [file].
  this;

  @override
  Widget build(BuildContext context) => Link(
    uri: dartPadUri(file),
    target: LinkTarget.blank,
    builder: (context, open) => TextButton.icon(
      onPressed: open,
      icon: const Icon(Icons.open_in_new, size: 16),
      label: const Text('Try in DartPad'),
    ),
  );
}
