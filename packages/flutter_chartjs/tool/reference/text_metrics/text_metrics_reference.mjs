// Original code, not ported from Chart.js: Chrome text-metric reference generator.
//
// It writes test/port/canvas/text_metrics_reference.dart, the data of
// test/port/canvas/text_metrics_test.dart: the Chrome canvas measureText
// values of each case of text_metrics.html, with Liberation Sans 2.1.5 from
// packages/chartjs_test_utils/lib/fonts/, and the Chrome version and the OS
// in the header. The cases are fixed, so a rerun with the same Chrome and the
// same font files writes the same file. Nothing in lib/ or test/ runs this
// script (porting-flow.md section 4). doc/text-metrics.md records the result.
//
// The script serves the packages/ directory on a local HTTP port, so that
// the page can load the font files, and runs headless Chrome on
// text_metrics.html with --dump-dom. Then it reads the JSON of the page.
//
// Usage, from packages/flutter_chartjs, with Google Chrome and with the Dart
// SDK on the PATH (the script formats the output with `dart format`):
//
//   node tool/reference/text_metrics/text_metrics_reference.mjs
//
// The CHROME environment variable sets the Chrome binary. The default is the
// Google Chrome app on macOS and `google-chrome` on other systems. The
// reference is Chrome, not V8: Chart.js ADR 0032 does not apply, and any
// Node.js 22.15 or later runs the script.

import {execFile, execFileSync} from 'node:child_process';
import {mkdtempSync, readFileSync, rmSync, writeFileSync} from 'node:fs';
import {createServer} from 'node:http';
import {arch, platform, release, tmpdir} from 'node:os';
import {extname, join, normalize, sep} from 'node:path';
import {fileURLToPath} from 'node:url';

const PACKAGES = fileURLToPath(new URL('../../../../', import.meta.url));
const PAGE = 'flutter_chartjs/tool/reference/text_metrics/text_metrics.html';
const OUT = fileURLToPath(
  new URL('../../../test/port/canvas/text_metrics_reference.dart', import.meta.url),
);
const CHROME =
  process.env.CHROME ??
  (platform() === 'darwin'
    ? '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
    : 'google-chrome');

const TYPES = {'.html': 'text/html; charset=utf-8', '.ttf': 'font/ttf'};

/** A static server for the .html and .ttf files under PACKAGES. */
const server = createServer((request, response) => {
  const path = normalize(join(PACKAGES, decodeURIComponent(new URL(request.url, 'http://x').pathname)));
  const type = TYPES[extname(path)];
  if (!path.startsWith(PACKAGES) || path.includes(`${sep}..${sep}`) || !type) {
    response.writeHead(404).end();
    return;
  }
  try {
    const body = readFileSync(path);
    response.writeHead(200, {'content-type': type}).end(body);
  } catch {
    response.writeHead(404).end();
  }
});
await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
const url = `http://127.0.0.1:${server.address().port}/${PAGE}`;

const profile = mkdtempSync(join(tmpdir(), 'text-metrics-chrome-'));
let dom;
try {
  dom = await new Promise((resolve, reject) => {
    execFile(
      CHROME,
      [
        '--headless=new',
        '--disable-gpu',
        '--no-first-run',
        '--no-default-browser-check',
        `--user-data-dir=${profile}`,
        '--virtual-time-budget=10000',
        '--dump-dom',
        url,
      ],
      {maxBuffer: 16 * 1024 * 1024},
      (error, stdout) => (error ? reject(error) : resolve(stdout)),
    );
  });
} finally {
  server.close();
  rmSync(profile, {recursive: true, force: true});
}

const match = /<pre id="result">([\s\S]*?)<\/pre>/.exec(dom);
const text = (match?.[1] ?? '')
  .replaceAll('&lt;', '<')
  .replaceAll('&gt;', '>')
  .replaceAll('&quot;', '"')
  .replaceAll('&amp;', '&');
if (!text.startsWith('{')) {
  console.error(`The page did not give a result: ${text || dom}`);
  process.exit(1);
}
const result = JSON.parse(text);
const unloaded = result.cases.filter((c) => !c.loaded);
if (unloaded.length > 0) {
  console.error(
    'The Chart.js family list did not resolve to the loaded font for: ' +
      unloaded.map((c) => `${c.font} ${JSON.stringify(c.text)}`).join(', '),
  );
  process.exit(1);
}

const chrome = execFileSync(CHROME, ['--version'], {encoding: 'utf8'}).trim();
const os =
  platform() === 'darwin'
    ? `macOS ${execFileSync('sw_vers', ['-productVersion'], {encoding: 'utf8'}).trim()}`
    : `${platform()} ${release()}`;
const machine = `${os} (${arch()})`;

/**
 * A Dart string literal of [s], with \u escapes for non-ASCII, in double
 * quotes when [s] has a single quote and no double quote. A long [s] becomes
 * adjacent literals that end with a space after 50 characters, for the
 * 80-column limit.
 */
function str(s) {
  const quote = s.includes("'") && !s.includes('"') ? '"' : "'";
  const pieces = [];
  let out = '';
  for (const ch of s) {
    const code = ch.codePointAt(0);
    if (ch === quote || ch === '\\' || ch === '$') out += `\\${ch}`;
    else if (code < 0x20 || code > 0x7e) out += `\\u{${code.toString(16).toUpperCase()}}`;
    else out += ch;
    if (out.length >= 50 && ch === ' ') {
      pieces.push(out);
      out = '';
    }
  }
  if (out.length > 0 || pieces.length === 0) pieces.push(out);
  return pieces.map((p) => `${quote}${p}${quote}`).join(' ');
}

/** The Dart literal of the CSS font [font], with the family as a constant. */
function fontLiteral(font) {
  if (!font.endsWith(result.family)) return str(font);
  return `'${font.slice(0, -result.family.length)}$textMetricsFamily'`;
}

const fontIndex = new Map(result.fonts.map((f, i) => [f.font, i]));
const fonts = result.fonts
  .map(
    (f) => `  (
    font: ${fontLiteral(f.font)},
    fontAscent: ${f.fontAscent},
    fontDescent: ${f.fontDescent},
    baselines: {
${Object.entries(f.baselines)
  .map(([k, v]) => `      ${str(k)}: ${v},\n`)
  .join('')}    },
  ),
`,
  )
  .join('');
const cases = result.cases
  .map(
    (c) => `  (
    font: ${fontIndex.get(c.font)},
    text: ${str(c.text)},
    width: ${c.width},
    left: ${c.left},
    right: ${c.right},
    ascent: ${c.ascent},
    descent: ${c.descent},
  ),
`,
  )
  .join('');

const dart = `// Original code, not ported from Chart.js: Chrome text-metric reference data.

// Generated by tool/reference/text_metrics/text_metrics_reference.mjs.
// Do not edit. ${chrome} on ${machine}, headless:
// canvas measureText with Liberation Sans 2.1.5. ${result.cases.length} cases.

/// The Chrome version that generated the reference.
const String textMetricsChrome = ${str(chrome)};

/// The user agent of the headless Chrome that generated the reference.
const String textMetricsUserAgent = ${str(result.userAgent)};

/// The OS and the architecture of the machine that generated the reference.
const String textMetricsMachine = ${str(machine)};

/// The Chart.js default family list (\`core.defaults.ts\`).
const String textMetricsFamily = ${str(result.family)};

/// The text of the \`baselines\` values of [TextMetricsFont].
const String textMetricsBaselineText = ${str(result.baselineText)};

/// One CSS font of the probe and its Chrome metrics, with \`textAlign\`
/// \`start\` and \`direction\` \`ltr\`: \`fontBoundingBoxAscent\` and
/// \`fontBoundingBoxDescent\` with \`textBaseline\` \`alphabetic\`, and the
/// \`actualBoundingBoxAscent\` of [textMetricsBaselineText] for each
/// \`textBaseline\`.
typedef TextMetricsFont = ({
  String font,
  double fontAscent,
  double fontDescent,
  Map<String, double> baselines,
});

/// One measured text: the index of its font in [textMetricsFonts], the text
/// and the Chrome \`measureText\` values with \`textAlign\` \`start\`,
/// \`textBaseline\` \`alphabetic\` and \`direction\` \`ltr\`: \`width\` and the
/// four \`actualBoundingBox*\` values.
typedef TextMetricsCase = ({
  int font,
  String text,
  double width,
  double left,
  double right,
  double ascent,
  double descent,
});

/// The fonts of the probe.
const List<TextMetricsFont> textMetricsFonts = [
${fonts}];

/// The measured texts of the probe.
const List<TextMetricsCase> textMetricsCases = [
${cases}];
`;

writeFileSync(OUT, dart);
execFileSync('dart', ['format', OUT], {stdio: 'inherit'});
console.log(`Wrote ${result.cases.length} cases (${chrome}, ${machine}) to ${OUT}`);
