// Original code, not ported from Chart.js: site design drafts.
import 'package:chartjs_gallery/main.dart' show GalleryHome;
import 'package:chartjs_gallery/site_drafts/package_health.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

const _ink = Color(0xFF17252C);
const _blue = Color(0xFF205CF5);
const _lime = Color(0xFFC9F56B);
const _orange = Color(0xFFBC482D);
const _repo = 'https://github.com/artflutter/flutter_ports';
const _names = ['Signal', 'Workbench', 'Fieldnotes'];
const _descriptions = [
  'Great ideas from JavaScript. At home in Flutter.',
  'An open workbench for the curious developer.',
  'A considered collection of familiar libraries.',
];

/// Three runnable design directions for the flutter_ports official site.
class SiteDraftsApp extends StatefulWidget {
  /// Creates the local design preview.
  const SiteDraftsApp({super.key, this.initialDirection = 0});

  /// Direction to show first: Signal, Workbench, or Fieldnotes.
  final int initialDirection;

  @override
  State<SiteDraftsApp> createState() => _SiteDraftsAppState();
}

class _SiteDraftsAppState extends State<SiteDraftsApp> {
  late int _direction = widget.initialDirection;

  @override
  Widget build(BuildContext context) {
    final dark = _direction == 1;
    final accent = [_blue, _lime, _orange][_direction];
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'flutter_ports • ${_names[_direction]}',
      theme: ThemeData(
        brightness: dark ? Brightness.dark : Brightness.light,
        colorSchemeSeed: accent,
        scaffoldBackgroundColor: switch (_direction) {
          1 => const Color(0xFF111714),
          2 => const Color(0xFFF4F0E7),
          _ => const Color(0xFFFAFCFF),
        },
        textTheme:
            ThemeData(brightness: dark ? Brightness.dark : Brightness.light)
                .textTheme
                .apply(
                  bodyColor: dark ? const Color(0xFFF1F4EB) : _ink,
                  displayColor: dark ? const Color(0xFFF1F4EB) : _ink,
                ),
        dividerColor: dark ? const Color(0xFF354138) : const Color(0xFFDADFD9),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: dark ? _ink : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ),
      home: _DraftPage(
        key: ValueKey(_direction),
        direction: _direction,
        onDirection: (value) => setState(() => _direction = value),
      ),
    );
  }
}

class _DraftPage extends StatefulWidget {
  const _DraftPage({
    required this.direction,
    required this.onDirection,
    super.key,
  });
  final int direction;
  final ValueChanged<int> onDirection;

  @override
  State<_DraftPage> createState() => _DraftPageState();
}

class _DraftPageState extends State<_DraftPage> {
  late final Future<PackageHealthSnapshot> _health =
      PackageHealthSnapshot.load();
  final GlobalKey _libraryKey = GlobalKey();
  final GlobalKey _demoKey = GlobalKey();
  final GlobalKey _communityKey = GlobalKey();
  bool get _dark => widget.direction == 1;
  Color get _accent => [_blue, _lime, _orange][widget.direction];

  void _scrollTo(GlobalKey key) {
    final target = key.currentContext;
    if (target != null) {
      final reduced = MediaQuery.disableAnimationsOf(context);
      Scrollable.ensureVisible(
        target,
        duration: Duration(milliseconds: reduced ? 0 : 450),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _resource(String title, String body, String link) =>
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(body),
                  const SizedBox(height: 20),
                  SelectableText(link),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            FilledButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: link));
                if (context.mounted && mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    this.context,
                  ).showSnackBar(const SnackBar(content: Text('Link copied')));
                }
              },
              child: const Text('Copy link'),
            ),
          ],
        ),
      );

  void _docs() => _resource(
    'Explore flutter_ports',
    'An initiative to bring great JavaScript libraries to native Dart and '
        'Flutter. Charts are our first chapter. Explore the source, design '
        'decisions, and progress of each port in the repository.',
    _repo,
  );

  void _gallery() => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => ChartTheme(
        data: _dark
            ? const ChartThemeData.dark()
            : const ChartThemeData.light(),
        child: const GalleryHome(),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          _reviewBar(),
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.sizeOf(context).width < 650
                          ? 22
                          : 56,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _navigation(),
                        switch (widget.direction) {
                          1 => _workbench(),
                          2 => _fieldnotes(),
                          _ => _signal(),
                        },
                        _libraries(),
                        _principles(),
                        _community(),
                        _footer(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _reviewBar() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: _dark ? const Color(0xFF1B231E) : const Color(0xFFEDF0F2),
      border: Border(
        bottom: BorderSide(
          color: _dark ? const Color(0xFF354138) : const Color(0xFFDADFE5),
        ),
      ),
    ),
    child: Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 6,
      children: [
        const Text(
          'DESIGN DRAFTS',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.6,
          ),
        ),
        for (var i = 0; i < 3; i++)
          ChoiceChip(
            label: Text('${i + 1}  ${_names[i]}'),
            selected: widget.direction == i,
            onSelected: (_) => widget.onDirection(i),
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
          ),
      ],
    ),
  );

  Widget _navigation() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 28),
    child: LayoutBuilder(
      builder: (context, constraints) => Row(
        children: [
          Icon(Icons.bolt_rounded, color: _accent, size: 28),
          const SizedBox(width: 9),
          const Expanded(
            child: Text(
              'flutter_ports',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
              ),
            ),
          ),
          if (constraints.maxWidth > 650) ...[
            TextButton(
              onPressed: () => _scrollTo(_libraryKey),
              child: const Text('Our ports'),
            ),
            TextButton(
              onPressed: () => _scrollTo(_communityKey),
              child: const Text('Community'),
            ),
            TextButton(onPressed: _docs, child: const Text('Docs')),
            const SizedBox(width: 20),
          ],
          IconButton(
            tooltip: 'Source repository',
            onPressed: () => _resource(
              'Built in the open',
              'Explore the source, follow porting progress, or contribute on '
                  'GitHub.',
              _repo,
            ),
            icon: const Icon(Icons.code_rounded),
          ),
        ],
      ),
    ),
  );

  Widget _eyebrow(String text) => Text(
    text,
    style: TextStyle(
      color: _accent,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 2,
    ),
  );

  Widget _headline(String text, {double size = 72}) => Text(
    text,
    style: TextStyle(
      fontSize: size,
      height: 1.04,
      letterSpacing: -2.8,
      fontWeight: FontWeight.w800,
    ),
  );

  Widget _body(String text, {double size = 17}) => Text(
    text,
    style: TextStyle(
      fontSize: size,
      height: 1.65,
      color: _dark ? const Color(0xFFB1BDB3) : const Color(0xFF5F6C74),
    ),
  );

  Widget _actions({String primary = 'Explore our ports'}) => Wrap(
    spacing: 16,
    runSpacing: 12,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      FilledButton(
        onPressed: () => _scrollTo(_libraryKey),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(primary)),
            const SizedBox(width: 20),
            const Icon(Icons.arrow_forward, size: 18),
          ],
        ),
      ),
      TextButton(onPressed: _docs, child: const Text('Read the docs  ↗')),
    ],
  );

  Widget _signal() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 40),
      LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 800;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _eyebrow('FAMILIAR LIBRARIES. NATIVE FLUTTER.'),
              const SizedBox(height: 26),
              _headline(
                'Great ideas.\nNative Flutter.',
                size: narrow ? 54 : 76,
              ),
              const SizedBox(height: 24),
              _body(
                'The JavaScript ecosystem has great ideas. We bring them to '
                'Dart and Flutter with the care they deserve. Beautiful '
                'native experiences that make Flutter shine.',
              ),
              const SizedBox(height: 30),
              _actions(),
              const SizedBox(height: 28),
              _eyebrow('OPEN SOURCE  /  BUILT ENTIRELY WITH FLUTTER'),
            ],
          );
          final demo = Container(
            key: _demoKey,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFFEBF1FF),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const _LiveChart(accent: _blue, dark: false),
          );
          return narrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [copy, const SizedBox(height: 36), demo],
                )
              : Row(
                  children: [
                    Expanded(child: copy),
                    const SizedBox(width: 38),
                    Expanded(child: demo),
                  ],
                );
        },
      ),
      const SizedBox(height: 54),
      _platformStrip(),
      const SizedBox(height: 56),
    ],
  );

  Widget _workbench() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 32),
      _eyebrow('GREAT JAVASCRIPT IDEAS. FLUTTER CRAFT.'),
      const SizedBox(height: 24),
      LayoutBuilder(
        builder: (context, constraints) => _headline(
          'Same curiosity.\nNew canvas.',
          size: constraints.maxWidth < 650 ? 57 : 88,
        ),
      ),
      const SizedBox(height: 22),
      _body(
        'Bring the best of JavaScript into Flutter. Port the logic. '
        'Craft the experience. Make something that feels right at home.',
      ),
      const SizedBox(height: 30),
      _actions(),
      const SizedBox(height: 42),
      Container(
        key: _demoKey,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF3D4A3C)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFF3D4A3C))),
              ),
              child: const Row(
                children: [
                  Icon(Icons.terminal, size: 18, color: _lime),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'playground / chartjs / native',
                      style: TextStyle(fontSize: 12, letterSpacing: 1),
                    ),
                  ),
                  Text('● LIVE', style: TextStyle(color: _lime, fontSize: 11)),
                ],
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                const chart = Padding(
                  padding: EdgeInsets.all(22),
                  child: _LiveChart(accent: _lime, dark: true, framed: false),
                );
                final code = Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _eyebrow('YOUR NEXT WIDGET'),
                      const SizedBox(height: 24),
                      const SelectableText(
                        'ChartView(\n  config: ChartConfig(\n'
                        '    type: ChartKind.line,\n'
                        "    labels: ['Mon', 'Tue', 'Wed'],\n"
                        '    datasets: [\n      LineDataset(\n'
                        '        data: [24, 38, 31],\n'
                        '      ),\n    ],\n  ),\n)',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                          height: 1.9,
                          color: Color(0xFFCBD7C1),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _body('Dart in. Pixels out.', size: 14),
                    ],
                  ),
                );
                return constraints.maxWidth < 750
                    ? Column(children: [chart, code])
                    : Row(
                        children: [
                          const Expanded(flex: 3, child: chart),
                          Expanded(flex: 2, child: code),
                        ],
                      );
              },
            ),
          ],
        ),
      ),
      const SizedBox(height: 30),
      _platformStrip(),
      const SizedBox(height: 56),
    ],
  );

  Widget _fieldnotes() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Divider(),
      const SizedBox(height: 26),
      Wrap(
        spacing: 32,
        runSpacing: 12,
        children: [
          _eyebrow('A COLLECTION IN DART'),
          const Text(
            'VOL. 01 / FLUTTER',
            style: TextStyle(fontSize: 10, letterSpacing: 1.3),
          ),
        ],
      ),
      const SizedBox(height: 40),
      LayoutBuilder(
        builder: (context, constraints) {
          final title = _headline(
            'Good libraries\ntravel well.',
            size: constraints.maxWidth < 750 ? 58 : 94,
          );
          final note = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _body(
                'Good ideas deserve to go further. We bring remarkable '
                'JavaScript libraries into Dart and Flutter, and celebrate '
                'the people doing the same.',
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => _scrollTo(_libraryKey),
                child: const Text('Meet the collection  ↓'),
              ),
            ],
          );
          return constraints.maxWidth < 800
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [title, const SizedBox(height: 24), note],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(flex: 3, child: title),
                    Expanded(flex: 2, child: note),
                  ],
                );
        },
      ),
      const SizedBox(height: 40),
      Container(
        key: _demoKey,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xFFE9E3D6),
          borderRadius: BorderRadius.circular(4),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final note = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _eyebrow('01 / THE FIRST PORT'),
                const SizedBox(height: 28),
                _headline('Chart.js', size: 46),
                const SizedBox(height: 14),
                _body('Eight chart types.\nOne familiar way to tell a story.'),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: _gallery,
                  child: const Text('Explore Chart.js  ↗'),
                ),
                const SizedBox(height: 24),
                const Text(
                  'UPSTREAM v4.6.1 • MIT',
                  style: TextStyle(fontSize: 10, letterSpacing: 1.3),
                ),
              ],
            );
            const chart = _LiveChart(
              accent: _orange,
              dark: false,
              framed: false,
              initialType: 1,
            );
            return constraints.maxWidth < 750
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [note, const SizedBox(height: 30), chart],
                  )
                : Row(
                    children: [
                      Expanded(child: note),
                      const SizedBox(width: 42),
                      const Expanded(flex: 2, child: chart),
                    ],
                  );
          },
        ),
      ),
      const SizedBox(height: 28),
      _platformStrip(),
      const SizedBox(height: 56),
    ],
  );

  Widget _platformStrip() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 20),
    decoration: BoxDecoration(
      border: Border.symmetric(
        horizontal: BorderSide(color: Theme.of(context).dividerColor),
      ),
    ),
    child: Wrap(
      spacing: 28,
      runSpacing: 16,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          'ONE FLUTTER CODEBASE',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        for (final platform in [
          'Android',
          'iOS',
          'Web / Wasm',
          'macOS',
          'Windows',
          'Linux',
        ])
          Text(platform, style: const TextStyle(fontSize: 13)),
      ],
    ),
  );

  Widget _libraries() => Column(
    key: _libraryKey,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _eyebrow('OUR PORTS / CHAPTER 01'),
      const SizedBox(height: 16),
      _headline(
        widget.direction == 1
            ? 'Built in the open.'
            : 'Familiar names. Fresh possibilities.',
        size: 34,
      ),
      const SizedBox(height: 14),
      _body(
        'We’re starting with charts. The ambition reaches across the '
        'JavaScript ecosystem.',
        size: 16,
      ),
      const SizedBox(height: 28),
      for (final port in [
        (
          '01',
          'Chart.js',
          'v4.6.1',
          'Eight chart types, six scales, seven plugins.',
          'Implemented · unpublished',
          'flutter_chartjs_port',
        ),
        (
          '02',
          'D3',
          'v7.9.0',
          'The foundation for expressive data visualization.',
          'Phase 0 · design',
          'flutter_d3_port',
        ),
        (
          '03',
          'Apache ECharts',
          '6.1.0',
          'A charting ecosystem, together with zrender.',
          'Phase 0 · design',
          'flutter_echarts_port',
        ),
        (
          '04',
          'Zoom',
          '2.2.0+fb81d331',
          'Pan and zoom for the Chart.js port.',
          'Phase 0 · design',
          'flutter_chartjs_plugin_zoom_port',
        ),
      ])
        InkWell(
          onTap: () => _resource(
            port.$2,
            '${port.$4}\n\n${port.$5}. '
                '${port.$1 == '01' ? 'See parity.' : 'Design only.'}',
            '$_repo/tree/main/packages/${port.$6}',
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) => Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 40,
                        child: Text(
                          port.$1,
                          style: TextStyle(color: _accent, fontSize: 12),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              port.$2,
                              style: const TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(port.$3, style: const TextStyle(fontSize: 11)),
                            if (constraints.maxWidth < 800) ...[
                              const SizedBox(height: 12),
                              Text(
                                port.$5,
                                style: TextStyle(fontSize: 11, color: _accent),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (constraints.maxWidth >= 800) ...[
                        Expanded(flex: 3, child: _body(port.$4, size: 14)),
                        Expanded(
                          flex: 2,
                          child: Text(
                            port.$5,
                            style: TextStyle(fontSize: 12, color: _accent),
                          ),
                        ),
                      ],
                      const Icon(Icons.north_east, size: 19),
                    ],
                  ),
                ),

                const SizedBox(height: 18),
                PackageHealth(
                  package: port.$6,
                  snapshot: _health,
                  onSource: _resource,
                ),
              ],
            ),
          ),
        ),
      const SizedBox(height: 16),
      _body(
        'Our ports are in development and not yet published to pub.dev.',
        size: 12,
      ),
    ],
  );

  Widget _principles() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 64),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final items =
            [
                  (
                    '01 / NATIVE',
                    'Flutter, all the way.',
                    'Native Dart foundations. Thoughtful Flutter experiences. '
                        'We want every port to show what this platform can do.',
                  ),
                  (
                    '02 / FAITHFUL',
                    'Familiar by design.',
                    'Ported from pinned upstream sources, with a documented '
                        'parity tracker and explicit differences.',
                  ),
                  (
                    '03 / OPEN',
                    'Follow every step.',
                    'Source, architecture decisions, and porting progress '
                        'live together in the repository. Come build the next '
                        'chapter.',
                  ),
                ]
                .map(
                  (item) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _eyebrow(item.$1),
                      const SizedBox(height: 18),
                      Text(
                        item.$2,
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _body(item.$3, size: 14),
                    ],
                  ),
                )
                .toList();
        return constraints.maxWidth < 750
            ? Column(
                children: [
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 32),
                      child: item,
                    ),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0) const SizedBox(width: 40),
                    Expanded(child: items[i]),
                  ],
                ],
              );
      },
    ),
  );

  Widget _community() => Container(
    key: _communityKey,
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 64),
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: _accent.withValues(alpha: _dark ? 0.06 : 0.04),
      border: Border.all(color: _accent.withValues(alpha: 0.25)),
      borderRadius: BorderRadius.circular(widget.direction == 2 ? 4 : 16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _eyebrow('COMMUNITY SPOTLIGHT'),
        const SizedBox(height: 18),
        _headline('Awesome Flutter Ports', size: 38),
        const SizedBox(height: 16),
        _body(
          'Great work deserves company. Discover the people bringing '
          'the JavaScript ecosystem to Dart and Flutter.',
        ),
        const SizedBox(height: 12),
        _body(
          'Independent projects, made and maintained by their creators.',
          size: 12,
        ),
        const SizedBox(height: 28),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 900 ? 3 : 1;
            final width = (constraints.maxWidth - (columns - 1) * 20) / columns;
            return Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                for (final port in [
                  (
                    '01 / DEVELOPER TOOLS',
                    'Highlight.js → Dart',
                    'highlighting',
                    'Syntax highlighting in Dart, with a companion '
                        'Flutter widget.',
                    'Akvelon & contributors',
                    'https://github.com/akvelon/dart-highlighting',
                  ),
                  (
                    '02 / GEOSPATIAL',
                    'Turf.js → Dart',
                    'turf',
                    'Spatial analysis and GeoJSON tools translated '
                        'from Turf.js.',
                    'dartclub & contributors',
                    'https://github.com/dartclub/turf_dart',
                  ),
                  (
                    '03 / MAPS & DATA',
                    'Supercluster → Dart',
                    'supercluster',
                    'Point clustering from Mapbox’s library, with '
                        'mutable support.',
                    'Rory Stephenson & contributors',
                    'https://github.com/rorystephenson/supercluster_dart',
                  ),
                ])
                  SizedBox(
                    width: width,
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _eyebrow(port.$1),
                          const SizedBox(height: 24),
                          Text(
                            port.$2,
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(port.$3, style: TextStyle(color: _accent)),
                          const SizedBox(height: 18),
                          _body(port.$4, size: 14),
                          const SizedBox(height: 22),
                          Text(
                            'By ${port.$5}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Published on pub.dev',
                            style: TextStyle(fontSize: 11),
                          ),
                          const SizedBox(height: 18),
                          PackageHealth(
                            package: port.$3,
                            snapshot: _health,
                            onSource: _resource,
                          ),
                          const SizedBox(height: 18),
                          OutlinedButton(
                            onPressed: () => _resource(
                              port.$3,
                              '${port.$4}\n\nBy ${port.$5}.\n\n'
                              'Package: https://pub.dev/packages/${port.$3}',
                              port.$6,
                            ),
                            child: const Text('Explore project  ↗'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 20,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _body('Know a port that belongs here?', size: 15),
            TextButton.icon(
              onPressed: () => _resource(
                'Suggest a community port',
                'Share the original JavaScript library, the Dart or Flutter '
                    'project, its creators, and what makes it worth exploring. '
                    'Use this link to open a suggestion on GitHub.',
                '$_repo/issues/new?title=Awesome+Flutter+Ports+suggestion',
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Suggest a port'),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _footer() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Divider(),
      const SizedBox(height: 22),
      Wrap(
        spacing: 30,
        runSpacing: 16,
        children: [
          const Text(
            'flutter_ports',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
          ),
          Text(
            _descriptions[widget.direction],
            style: const TextStyle(fontSize: 13),
          ),
          const Text(
            'Built with Flutter. Including this page.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
      const SizedBox(height: 20),
      _body(
        'Independent open-source ports. Not affiliated with or endorsed by '
        'the upstream projects. Apache ECharts is a trademark of the Apache '
        'Software Foundation.',
        size: 11,
      ),
      const SizedBox(height: 36),
    ],
  );
}

class _LiveChart extends StatefulWidget {
  const _LiveChart({
    required this.accent,
    required this.dark,
    this.framed = true,
    this.initialType = 0,
  });
  final Color accent;
  final bool dark;
  final bool framed;
  final int initialType;

  @override
  State<_LiveChart> createState() => _LiveChartState();
}

class _LiveChartState extends State<_LiveChart> {
  late int _type = widget.initialType;
  int _revision = 0;
  List<double> _data = [24, 38, 31, 57, 45, 68, 76];

  void _refresh() => setState(() {
    _revision++;
    _data = List.generate(7, (i) => 20.0 + ((i * 17 + _revision * 23) % 62));
  });

  @override
  Widget build(BuildContext context) {
    final secondary = widget.dark
        ? const Color(0xFF65BEA1)
        : const Color(0xFF9AAEC7);
    final chartConfig = ChartConfig(
      type: [ChartKind.line, ChartKind.bar, ChartKind.doughnut][_type],
      maintainAspectRatio: false,
      labels: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
      legend: const ChartLegend(display: false),
      datasets: [
        switch (_type) {
          1 => BarDataset(
            label: 'Sample series',
            data: _data,
            backgroundColor: ChartValue.constant(widget.accent),
            borderRadius: 5,
          ),
          2 => DoughnutDataset(
            label: 'Sample series',
            data: _data,
            backgroundColor: ChartValue.indexed([
              widget.accent,
              secondary,
              const Color(0xFFE8BA67),
              const Color(0xFFDA7A6B),
              const Color(0xFF829587),
              const Color(0xFFB3C6A3),
              const Color(0xFF6B8FAD),
            ]),
            borderWidth: 0,
          ),
          _ => LineDataset(
            label: 'Sample series',
            data: _data,
            borderColor: ChartValue.constant(widget.accent),
            backgroundColor: ChartValue.constant(
              widget.accent.withValues(alpha: 0.10),
            ),
            fill: ChartFill.origin,
            tension: 0.38,
            pointRadius: 3,
            borderWidth: 3,
          ),
        },
      ],
    );
    return Container(
      padding: widget.framed ? const EdgeInsets.all(22) : EdgeInsets.zero,
      decoration: widget.framed
          ? BoxDecoration(
              color: widget.dark ? const Color(0xFF1B231E) : Colors.white,
              borderRadius: BorderRadius.circular(14),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: widget.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'LIVE PORT / CHART.JS',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.3,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Change sample data',
                onPressed: _refresh,
                icon: const Icon(Icons.refresh, size: 19),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'First up: Chart.js, in Flutter.',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < 3; i++)
                ChoiceChip(
                  label: Text(
                    ['Line', 'Bar', 'Doughnut'][i],
                    style: const TextStyle(fontSize: 11),
                  ),
                  selected: _type == i,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _type = i),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 240,
            child: ChartView(
              key: ValueKey(_type),
              config: chartConfig,
              theme: widget.dark
                  ? const ChartThemeData.dark()
                  : const ChartThemeData.light(),
              semanticLabel:
                  '${['Line', 'Bar', 'Doughnut'][_type]} chart of '
                  'illustrative sample data for seven days',
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'ILLUSTRATIVE DATA  /  HOVER OR TAP TO EXPLORE',
            style: TextStyle(fontSize: 8, letterSpacing: 1.1),
          ),
        ],
      ),
    );
  }
}
