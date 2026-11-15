// Original code, not ported from Chart.js: the link buttons of the docs.

import 'package:chartjs_docs/ui/code_block.dart';
import 'package:chartjs_docs/ui/doc_blocks.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/link.dart';

/// A shell command in a panel, for example the command that adds a package.
class const DocCommand(
  /// The command.
  final String command, {
  super.key,
}) extends StatelessWidget {
  /// Creates the panel of [command].
  this;

  @override
  Widget build(BuildContext context) =>
      DocPanel(child: CodeBlock(code: command));
}

/// A row of link buttons under a block.
class const DocLinks(
  /// The buttons, usually [DocPageButton] and [DocUrlButton].
  final List<Widget> children, {
  super.key,
}) extends StatelessWidget {
  /// Creates the row of [children].
  this;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Wrap(spacing: 8, runSpacing: 8, children: children),
  );
}

/// A button that opens the page [route] of the site.
class const DocPageButton({
  /// The route of the page, for example `/plugins/zoom`.
  required final String route,

  /// The label of the button. The button gives it its text style.
  required final Widget label,
  super.key,
}) extends StatelessWidget {
  /// Creates the button of [route].
  this;

  @override
  Widget build(BuildContext context) => FilledButton.tonalIcon(
    onPressed: () => Navigator.of(context).pushReplacementNamed(route),
    icon: const Icon(Icons.menu_book, size: 16),
    label: label,
  );
}

/// A button that opens the address [url] in a new tab.
class const DocUrlButton({
  /// The address.
  required final String url,

  /// The label of the button. The button gives it its text style.
  required final Widget label,
  super.key,
}) extends StatelessWidget {
  /// Creates the button of [url].
  this;

  @override
  Widget build(BuildContext context) => Link(
    uri: Uri.parse(url),
    target: LinkTarget.blank,
    builder: (context, open) => OutlinedButton.icon(
      onPressed: open,
      icon: const Icon(Icons.open_in_new, size: 16),
      label: label,
    ),
  );
}
