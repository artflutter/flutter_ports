// Original code, not ported from Chart.js: the DartPad links of the docs.

import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/link.dart';

/// The archive of the samples, next to the docs site. The workflow `pages`
/// writes it with `tool/dartpad_archive.sh`: the folder `chartjs_docs` with
/// the samples. DartPad gets `flutter_chartjs_port` from pub.dev.
const String dartPadArchive =
    'https://artflutter.github.io/flutter_ports/docs/dartpad/chartjs_samples.tar.gz';

/// The DartPad address that opens the sample [file] and the app [entrypoint]
/// of the archive, and runs [entrypoint]. Both paths are relative to the
/// docs app.
Uri dartPadUri({required String file, required String entrypoint}) =>
    Uri.https('dartpad.dev', '/', {
      'url': dartPadArchive,
      'file': ['chartjs_docs/$file', 'chartjs_docs/$entrypoint'],
      'entrypoint': 'chartjs_docs/$entrypoint',
    });

/// A **Try in DartPad** button that opens [file] and [entrypoint] in DartPad,
/// in a new tab.
class const DartPadLink({
  /// The sample file, relative to the docs app.
  required final String file,

  /// The file with the `main` function of the sample, relative to the docs
  /// app.
  required final String entrypoint,
  super.key,
}) extends StatelessWidget {
  /// Creates the button of [file].
  this;

  @override
  Widget build(BuildContext context) => Link(
    uri: dartPadUri(file: file, entrypoint: entrypoint),
    target: LinkTarget.blank,
    builder: (context, open) => TextButton.icon(
      onPressed: open,
      icon: const Icon(Icons.open_in_new, size: 16),
      label: const Text('Try in DartPad'),
    ),
  );
}
