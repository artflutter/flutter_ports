// Original code, not ported from any project: the index of each ADR folder
// and the check of the supersession pointers (docs/adr/README.md).

import 'dart:io';

/// The ADR folders and the name that the docs give to an ADR of each folder.
const _folders = <String, String>{
  'docs/adr': 'ADR',
  'packages/flutter_chartjs_port/doc/adr': 'Chart.js ADR',
  'packages/flutter_d3_port/doc/adr': 'D3 ADR',
  'packages/flutter_echarts_port/doc/adr': 'ECharts ADR',
  'packages/flutter_chartjs_plugin_zoom_port/doc/adr': 'Zoom ADR',
  'packages/flutter_chartjs_chart_sankey_port/doc/adr': 'Sankey ADR',
};

const _start = '<!-- adr-index:start -->';
const _end = '<!-- adr-index:end -->';

final _fileName = RegExp(r'^(\d{4})-.*\.md$');
// A 4-digit number that is not part of a date or of a longer number.
final _number = RegExp(r'(?<![\d-])(\d{4})(?![\d-])');

/// Writes `README.md` of each ADR folder (the lines between the markers).
/// With `--check`, writes nothing and fails when an index differs or when a
/// supersession has no pointer back.
void main(List<String> args) {
  final check = args.contains('--check');
  final errors = <String>[];
  for (final MapEntry(key: folder, value: name) in _folders.entries) {
    final dir = Directory(folder);
    if (!dir.existsSync()) continue;
    final adrs = _readFolder(dir, errors);
    _checkPointers(folder, name, adrs, errors);
    final readme = File('$folder/README.md');
    final old = readme.existsSync()
        ? readme.readAsStringSync()
        : _newReadme(name);
    final updated = _withIndex(old, adrs, readme.path, errors);
    if (updated == null || updated == old) continue;
    if (check) {
      errors.add(
        '${readme.path}: the index is stale; run dart run tool/adr_index.dart',
      );
    } else {
      readme.writeAsStringSync(updated);
      stdout.writeln('wrote ${readme.path}');
    }
  }
  if (errors.isEmpty) return;
  errors.forEach(stderr.writeln);
  exitCode = 1;
}

typedef _Adr = ({
  String number,
  String file,
  String title,
  String status,
  Set<String> supersedes,
  Set<String> supersededBy,
  Set<String> supersededInPartBy,
});

Map<String, _Adr> _readFolder(Directory dir, List<String> errors) {
  final adrs = <String, _Adr>{};
  final files = dir.listSync().whereType<File>().toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final file in files) {
    final base = file.uri.pathSegments.last;
    final match = _fileName.firstMatch(base);
    if (match == null) continue;
    final number = match.group(1)!;
    final lines = file.readAsLinesSync();
    final title = lines.isEmpty
        ? ''
        : lines.first.replaceFirst(RegExp(r'^#.*?\d{4}:\s*'), '');
    final bullets = _headerBullets(lines);
    String? status;
    final supersedes = <String>{};
    final by = <String>{};
    final inPart = <String>{};
    for (final bullet in bullets) {
      if (bullet.startsWith('- Status:')) {
        status = RegExp(r'^- Status:\s*([A-Za-z]+)')
            .firstMatch(bullet)
            ?.group(1)
            ?.toLowerCase();
      } else if (bullet.startsWith('- Superseded in part by')) {
        inPart.addAll(_numbers(bullet, number));
      } else if (bullet.startsWith('- Superseded by')) {
        by.addAll(_numbers(bullet, number));
      } else if (bullet.startsWith('- Supersedes')) {
        final rest = bullet.substring('- Supersedes'.length);
        if (!RegExp(r'^\W*nothing', caseSensitive: false).hasMatch(rest)) {
          supersedes.addAll(_numbers(bullet, number));
        }
      }
    }
    if (status == null) {
      errors.add('${file.path}: no "- Status:" line in the header');
    }
    adrs[number] = (
      number: number,
      file: base,
      title: title,
      status: status ?? 'unknown',
      supersedes: supersedes,
      supersededBy: by,
      supersededInPartBy: inPart,
    );
  }
  return adrs;
}

/// The bullets of the header block: the lines before the first `## ` heading
/// that start with `- `, each with its continuation lines.
List<String> _headerBullets(List<String> lines) {
  final bullets = <String>[];
  for (final line in lines.skip(1)) {
    if (line.startsWith('## ')) break;
    if (line.startsWith('- ')) {
      bullets.add(line);
    } else if (line.startsWith(' ') &&
        bullets.isNotEmpty &&
        line.trim().isNotEmpty) {
      bullets[bullets.length - 1] += ' ${line.trim()}';
    } else if (line.trim().isEmpty && bullets.isNotEmpty) {
      bullets.add('');
    }
  }
  return bullets;
}

Set<String> _numbers(String text, String self) =>
    {for (final m in _number.allMatches(text)) m.group(1)!}..remove(self);

void _checkPointers(
  String folder,
  String name,
  Map<String, _Adr> adrs,
  List<String> errors,
) {
  for (final adr in adrs.values) {
    final where = '$folder/${adr.file}';
    for (final n in {
      ...adr.supersedes,
      ...adr.supersededBy,
      ...adr.supersededInPartBy,
    }) {
      if (!adrs.containsKey(n)) {
        errors.add('$where: names $name $n, which is not in the folder');
      }
    }
    final proposed = adr.status == 'proposed';
    for (final n in adr.supersedes) {
      final old = adrs[n];
      if (old == null) continue;
      final pointsBack =
          old.supersededBy.contains(adr.number) ||
          old.supersededInPartBy.contains(adr.number);
      if (proposed && pointsBack) {
        errors.add(
          '$folder/${old.file}: names the proposed $name ${adr.number} '
          'as its successor',
        );
      } else if (!proposed && !pointsBack) {
        errors.add(
          '$folder/${old.file}: no "Superseded by" or '
          '"Superseded in part by" line names $name ${adr.number}',
        );
      }
    }
    for (final n in {...adr.supersededBy, ...adr.supersededInPartBy}) {
      final successor = adrs[n];
      if (successor != null && !successor.supersedes.contains(adr.number)) {
        errors.add(
          '$folder/${successor.file}: its "Supersedes" line does not '
          'name $name ${adr.number}',
        );
      }
    }
  }
}

String _newReadme(String name) =>
    '# ${name}s\n\nThe list below comes from the header of each ADR '
    '(`dart run tool/adr_index.dart`). The rules and the template of an ADR '
    'are in `docs/adr/README.md`.\n\n$_start\n$_end\n';

String? _withIndex(
  String readme,
  Map<String, _Adr> adrs,
  String path,
  List<String> errors,
) {
  final a = readme.indexOf(_start);
  final b = readme.indexOf(_end);
  if (a < 0 || b < a) {
    errors.add('$path: the markers $_start and $_end are missing');
    return null;
  }
  final lines = [for (final adr in adrs.values) _line(adr)];
  final head = readme.substring(0, a + _start.length);
  return '$head\n${lines.join('\n')}\n${readme.substring(b)}';
}

String _line(_Adr adr) {
  final parts = <String>[adr.status];
  String list(Set<String> s) => (s.toList()..sort()).join(', ');
  if (adr.supersedes.isNotEmpty) {
    parts.add('supersedes ${list(adr.supersedes)}');
  }
  if (adr.supersededBy.isNotEmpty) {
    parts.add('superseded by ${list(adr.supersededBy)}');
  }
  if (adr.supersededInPartBy.isNotEmpty) {
    parts.add('superseded in part by ${list(adr.supersededInPartBy)}');
  }
  return '- [${adr.number}](${adr.file}) ${adr.title}: ${parts.join(', ')}.';
}
