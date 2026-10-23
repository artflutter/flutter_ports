// Original code, not ported from Chart.js: scale chart generator code.
//
// The shared code of the generators of the phase 6 scale reference tests
// (tool/reference/scale_*_reference.mjs). A generator builds charts with a
// build of the pinned Chart.js in Node.js, records what the charts give, and
// writes a Dart file of reference data for a test in test/port/scales/.
// Nothing in lib/ or test/ runs this code (porting-flow.md section 4).
//
// The method (a decision of the phase 6 plan). The port-only reference
// tests of the phase 6 scales build real charts with acquireChart (Chart.js
// ADR 0022) in testWidgets cases. A test controller registers through its
// class value in main(), before the snapshot of the defaults restore
// (Chart.js ADR 0020, section 8, and Chart.js ADR 0022, section 8). The
// expected values come from a build of the pinned Chart.js in the x64 Node.js
// (Chart.js ADR 0032), with the same test controllers as DatasetController
// subclasses in JavaScript. Node.js has no canvas. Thus the Node.js side uses
// a mock context that measures text with the advance widths and the 'kern'
// pairs of Liberation Sans 2.1.5, the test font of the harness
// (packages/chartjs_test_utils/lib/fonts/). The mock has a font stack for
// save and restore, and its first font is '10px sans-serif', as on a canvas.
// Against the 80 Chrome widths of
// test/port/canvas/text_metrics_reference.dart, the largest difference is
// 5.0e-7 px. The Dart side records the draw calls with a recording context
// that the test puts in place of chart.ctx, of each scale.ctx and of the
// writable ctx of each dataset controller after the layout
// (test/port/scales/scale_chart_harness.dart, Chart.js ADR 0030). Thus the
// draw calls of both sides have the element draws (see drawCalls).
//
// The users of this file: the generators of the phase 6 scale reference
// tests, and tool/reference/controller_chart_common.mjs with the generators
// of the phase 7 controller reference tests
// (tool/reference/controller_*_reference.mjs, Chart.js ADR 0030) and of the
// phase 8 plugin reference tests (tool/reference/plugin_*_reference.mjs,
// through tool/reference/plugin_chart_common.mjs, Chart.js ADR 0041). Each
// of them registers the components and the plugins of
// test/flutter_test_config.dart with registerBuiltins (Chart.js ADR 0041,
// section 1).
//
// How to run a generator
// ----------------------
//
// Build Chart.js at the pinned commit (the `commit` of the Chart.js entry of
// tool/port_sources.yaml) in a scratch clone outside the repository. npm has
// no build of a commit pin. The `packageManager` of the Chart.js
// package.json gives pnpm 8, which corepack supplies:
//
//   git clone --filter=blob:none https://github.com/chartjs/Chart.js <build>
//   git -C <build> checkout <commit>
//   cd <build>
//   corepack pnpm install --frozen-lockfile
//   corepack pnpm build
//
// The dist imports @kurkle/color from <build>/node_modules. Then, from
// packages/flutter_chartjs_port, with an x64 build of Node.js v24.12.0 and with
// the Dart SDK on the PATH (the generator formats its output with
// `dart format`):
//
//   CHARTJS_DIST=<build>/dist/chart.js \
//     node tool/reference/scale_<name>_reference.mjs
//
// The first argument can also give the path of dist/chart.js. On Apple
// silicon, run the darwin-x64 build of Node.js under Rosetta:
//
//   /usr/bin/arch -x86_64 <node-v24.12.0-darwin-x64>/bin/node \
//     tool/reference/scale_<name>_reference.mjs <build>/dist/chart.js
//
// The generator stops unless all of these are true:
// - Node.js is an x64 build.
// - The package.json next to dist/ gives the name chart.js and the release
//   of the pin: the version of tool/port_sources.yaml without its "v" and
//   before "+". A commit pin does not change the package.json version.
// - The folder of that package.json is the top folder of a git checkout at
//   the pinned commit, and no tracked file of the checkout has a change.
// - The submodule third_party/chartjs-test-utils is at the `commit` of its
//   entry in tool/port_sources.yaml and has no change in src/ (checkPin).
//   Check it out with `dart run melos run upstream`.
// The check cannot find a dist/ that is older than the checkout. Thus, run
// the build again after each checkout.
// The output file records the pin version and the commit of the build.
//
// A check of the method (2026-10-20): the same steps at the tag v4.5.1 give
// dist/chart.js, dist/helpers.js and dist/chunks/helpers.dataset.js of the
// chart.js 4.5.1 npm package. The only difference is the year in the
// banner. At the commit pin, the helpers chunk is dist/chunks/index.js,
// because the lockfile of the commit has rollup 3.30.0 (3.20.2 at v4.5.1).
// Its code is the code of v4.5.1 with the upstream changes of the range.
//
// The build of phase 7 (2026-10-20, on macOS with the darwin-x64 Node.js
// under Rosetta) used these files. Compare them to find a changed input:
// - node-v24.12.0-darwin-x64.tar.gz from https://nodejs.org/dist/v24.12.0/,
//   SHA-256 b82ea4c62fd08e250cab59d625e75d77cc5b0a3d60c6698ebee4545c88a169c5
//   (the line of SHASUMS256.txt in the same folder).
// - dist/chart.js, SHA-256
//   bc550e26bbb4efa6dcc19fe8ec942327930306a9ef8b63f0ec44d650a7745e17.
// - dist/chunks/index.js, SHA-256
//   87b29e4c0d409eff30f9d9108feba6291c080e23641382e91fbf5fc125ff1977.
// The fsevents build error of `pnpm install` on macOS comes from an optional
// package. It does not change the build.
//
// The limits of the text measure. Outside them, the mock stops with an
// error:
// - ASCII text only (U+0020 to U+007E): no combining mark and no fallback
//   font.
// - Integer px sizes. Then each advance is a dyadic number and the sums are
//   exact, also in the float32 sums of Flutter.
// - The fonts of `toFontString` only: `[style ][weight ]<size>px
//   <families>`. A canvas ignores the font strings 'null', 'undefined' and
//   '', and so does the mock. Another font string that does not have this
//   form stops the mock: the canvas of the harness parses more forms
//   (parseCanvasFont of lib/src/canvas/canvas_ui_text.dart).
// - The regular and bold faces only: no italic or oblique style. The
//   regular face is the weight 'normal' or a number from 1 to 500. The bold
//   face is the weight 'bold' or a number from 550 to 1000. A number
//   between 500 and 550 stops the mock: the canvas of the harness rounds it
//   to 500 (regular), and a browser takes the next heavier face (bold).
// - The families of the harness only: 'Helvetica Neue', Helvetica, Arial,
//   'Liberation Sans' and sans-serif.
// Only the width of measureText is a real value. The bounding box values
// are the fixed values of the upstream mock: no scale reads them.
//
// How to write a generator: see tool/reference/scale_chart_harness_reference.mjs.
// It calls loadChartJs(), registerBuiltins() with its own classes, runCase()
// for each chart, and writeReference().

import {execFileSync} from 'node:child_process';
import {existsSync, readFileSync, realpathSync, writeFileSync} from 'node:fs';
import {relative} from 'node:path';
import {fileURLToPath, pathToFileURL} from 'node:url';

const THIRD_PARTY = new URL('../../../../third_party/', import.meta.url);
const CONTEXT = new URL('chartjs-test-utils/src/context.js', THIRD_PARTY);
const FONTS = new URL('../../../chartjs_test_utils/lib/fonts/', import.meta.url);
const PACKAGE_ROOT = fileURLToPath(new URL('../../', import.meta.url));
const PORT_SOURCES = new URL('../port_sources.yaml', import.meta.url);

/** Writes [message] to stderr and stops the process. */
function stop(message) {
  console.error(message);
  process.exit(1);
}

/**
 * Reads the Chart.js pin of tool/port_sources.yaml. `version` is the version
 * of the entry without its "v": `<release>+<sha8>` for a commit pin
 * (doc/upstream-tracking.md 2.4). `release` is the part before "+", the
 * version of the Chart.js package.json at the pin. `commit` is the full
 * commit of the submodule pin.
 */
function readPin() {
  const path = fileURLToPath(PORT_SOURCES);
  const entry = readFileSync(path, 'utf8')
    .split(/^ {2}- header: /m)
    .find((e) => e.startsWith('Chart.js\n'));
  const version = entry?.match(/^ {4}version: "?v([^"\s]+)"?\s*$/m)?.[1];
  const commit = entry?.match(/^ {6}commit: "?([0-9a-f]{40})"?\s*$/m)?.[1];
  if (!version || !commit) stop(`${path} has no version and commit for Chart.js.`);
  const [release, sha8] = version.split('+');
  if (sha8 !== undefined && !commit.startsWith(sha8)) {
    stop(`${path}: the version ${version} does not name the commit ${commit}.`);
  }
  return {version, release, commit};
}

/** The Chart.js pin of tool/port_sources.yaml (readPin). */
const PIN = readPin();

if (!existsSync(fileURLToPath(CONTEXT))) {
  stop(
    `${fileURLToPath(CONTEXT)} is missing. ` +
      'Check out the submodules with `dart run melos run upstream`.',
  );
}

/**
 * The submodules that this file reads: the header of the entry in
 * tool/port_sources.yaml, the folder in third_party/ and the folders that the
 * file imports from. The Chart.js code comes from the build of dist/, not
 * from third_party/Chart.js (checkBuildCommit).
 */
const PINNED = [
  {header: 'chartjs-test-utils', folder: 'chartjs-test-utils', paths: ['src']},
];

/**
 * Stops unless each submodule of PINNED is at the `commit` of its entry in
 * tool/port_sources.yaml, with no change in the folders that this file
 * imports from. It is a copy of checkPin in theme_precedence_reference.mjs.
 * The read of a commit is the one of readPin. A folder that is not a git
 * checkout also stops the process.
 */
function checkPin() {
  const sources = fileURLToPath(PORT_SOURCES);
  const entries = readFileSync(sources, 'utf8').split(/^ {2}- header: /m);
  for (const {header, folder, paths} of PINNED) {
    const entry = entries.find(
      (e) => e.startsWith(`${header}\n`) || e.startsWith(`"${header}"\n`),
    );
    const commit = entry?.match(/^ {6}commit: "?([0-9a-f]{40})"?\s*$/m)?.[1];
    if (!commit) stop(`${sources} has no commit for ${header}.`);
    const checkout = fileURLToPath(new URL(folder, THIRD_PARTY));
    const git = (...args) => {
      try {
        return execFileSync('git', ['-C', checkout, ...args], {
          encoding: 'utf8',
          stdio: ['ignore', 'pipe', 'pipe'],
        }).trim();
      } catch (error) {
        stop(
          `git ${args.join(' ')} failed in ${checkout}: ` +
            `${error.message.trim()}\n` +
            'Check out the submodules with `dart run melos run upstream`.',
        );
      }
    };
    const head = git('rev-parse', 'HEAD');
    if (head !== commit) {
      stop(
        `${checkout} is at ${head}, not at the pin ${commit} of ${header}. ` +
          'Check out the submodules with `dart run melos run upstream`.',
      );
    }
    if (git('status', '--porcelain', '--', ...paths) !== '') {
      stop(`${checkout} has changes in ${paths.join(', ')}. The generator reads the pin.`);
    }
  }
}

checkPin();

// context.js is an ES module in a package without a "type".
const {default: Context} = await import(
  'data:text/javascript;base64,' +
    Buffer.from(readFileSync(CONTEXT, 'utf8')).toString('base64')
);

// ---------------------------------------------------------------------------
// The dist.

/** The module of the dist, after loadChartJs(). */
let chartJs = null;

/** The git commit of the build, after loadChartJs(). */
let buildCommit = null;

/**
 * The cartesian test controller `scaleTest`: category on the index axis and
 * linear on the value axis. loadChartJs() sets it.
 */
export let ScaleTestController = null;

/**
 * The radial test controller `radialTest`: radialLinear on the axis r.
 * loadChartJs() sets it.
 */
export let RadialTestController = null;

/**
 * Stops the process unless the folder [root] is the top folder of a git
 * checkout at the pinned commit, with no change to a tracked file. Returns
 * the commit.
 */
function checkBuildCommit(root) {
  const git = (...args) =>
    execFileSync('git', ['-C', root, ...args], {
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'pipe'],
    }).trim();
  const build = `Build Chart.js in a clone at the commit ${PIN.commit} (see the header).`;
  let top = null;
  try {
    top = git('rev-parse', '--show-toplevel');
  } catch {
    stop(`${root} is not a git checkout. ${build}`);
  }
  if (realpathSync(top) !== realpathSync(root)) {
    stop(`${root} is not the top folder of the git checkout ${top}. ${build}`);
  }
  const head = git('rev-parse', 'HEAD');
  if (head !== PIN.commit) {
    stop(`The build is at the commit ${head}; the pin is ${PIN.commit}. ${build}`);
  }
  const changes = git('status', '--porcelain', '--untracked-files=no');
  if (changes) stop(`The checkout ${root} has changes to tracked files:\n${changes}`);
  return head;
}

/**
 * Loads a build of the pinned Chart.js and returns its module.
 *
 * The path of dist/chart.js comes from the first argument of the process or
 * from the environment variable CHARTJS_DIST. The function stops the process
 * unless Node.js is an x64 build (Chart.js ADR 0032), the package.json next
 * to dist/ gives the name chart.js and the release of the pin, and its
 * folder is a git checkout at the pinned commit without changes
 * (checkBuildCommit). A second call returns the same module.
 */
export async function loadChartJs() {
  if (chartJs) return chartJs;
  if (process.arch !== 'x64') {
    stop(
      `The reference is V8 on x64; this Node.js is ${process.arch}. ` +
        'Run an x64 build of Node.js.',
    );
  }
  const dist = process.argv[2] ?? process.env.CHARTJS_DIST;
  if (!dist || !existsSync(dist)) {
    stop('Give the path of dist/chart.js of the build as the first argument, or set CHARTJS_DIST.');
  }
  const url = pathToFileURL(dist);
  const packageJson = new URL('../package.json', url);
  if (!existsSync(fileURLToPath(packageJson))) {
    stop(`${fileURLToPath(packageJson)} is missing: ${dist} is not in a Chart.js build.`);
  }
  const {name, version} = JSON.parse(readFileSync(packageJson, 'utf8'));
  if (name !== 'chart.js') {
    stop(`${fileURLToPath(packageJson)} gives the package ${name}, not chart.js.`);
  }
  if (version !== PIN.release) {
    stop(`The build is chart.js ${version}; the pin is ${PIN.version}.`);
  }
  const commit = checkBuildCommit(fileURLToPath(new URL('..', url)));
  chartJs = await import(url.href);
  buildCommit = commit;
  ScaleTestController = cartesianTestController('scaleTest', {
    scales: {_index_: {type: 'category'}, _value_: {type: 'linear'}},
  });
  RadialTestController = radialTestController('radialTest', {
    aspectRatio: 1,
    scales: {r: {type: 'radialLinear'}},
  });
  return chartJs;
}

/** The module of the dist. loadChartJs() must run first. */
function loaded() {
  if (!chartJs) throw new Error('Call loadChartJs() first.');
  return chartJs;
}

/**
 * Registers the built-in components as test/flutter_test_config.dart does
 * (harness-register-builtins): src/index.umd.ts:28, then the line of
 * test/index.js:25-28. Then [extra]. Chart.js ADR 0041, section 1.
 *
 * The dist `C.plugins` is a plain object, so `register` walks it. The
 * registry then has the eight controllers, the six scales, the four
 * elements and the seven plugins, in the key order of the namespaces, as
 * the Dart registry of each test. Each generator on the dist calls it, the
 * scale generators with their test classes as [extra].
 */
export function registerBuiltins(C, ...extra) {
  C.Chart.register(C.controllers, C.scales, C.elements, C.plugins);
  // Disable colors plugin for tests (test/index.js:25-28).
  C.Chart.defaults.plugins.colors.enabled = false;
  if (extra.length) C.Chart.register(...extra);
}

// ---------------------------------------------------------------------------
// The test controllers. test/port/scales/scale_chart_harness.dart has the
// same classes in Dart.

/**
 * A cartesian test controller with the id [id] and the overrides
 * [overrides]: a point for each value, at the pixels of its index scale and
 * of its value scale (controller.line.js:83-112 without the line, the gaps
 * and the stacks).
 */
export function cartesianTestController(id, overrides) {
  const {DatasetController} = loaded();
  return class ScaleTestController extends DatasetController {
    static id = id;
    static defaults = {datasetElementType: false, dataElementType: 'point'};
    static overrides = overrides;

    update(mode) {
      const meta = this._cachedMeta;
      this.updateElements(meta.data, 0, meta.data.length, mode);
    }

    updateElements(points, start, count, mode) {
      const {iScale, vScale} = this._cachedMeta;
      const iAxis = iScale.axis;
      const vAxis = vScale.axis;
      const {sharedOptions, includeOptions} = this._getSharedOptions(start, mode);
      for (let i = start; i < start + count; ++i) {
        const point = points[i];
        const parsed = this.getParsed(i);
        const properties = {
          [iAxis]: iScale.getPixelForValue(parsed[iAxis], i),
          [vAxis]: vScale.getPixelForValue(parsed[vAxis], i),
        };
        if (includeOptions) {
          properties.options =
            sharedOptions ||
            this.resolveDataElementOptions(i, point.active ? 'active' : mode);
        }
        this.updateElement(point, i, properties, mode);
      }
    }
  };
}

/**
 * A radial test controller with the id [id] and the overrides [overrides]:
 * a point for each value, at the position of `getPointPositionForValue` of
 * the scale r (controller.radar.js:81-103 without the line). The index axis
 * is r. Thus a primitive value parses to `{r: value}`.
 */
export function radialTestController(id, overrides) {
  const {DatasetController} = loaded();
  return class RadialTestController extends DatasetController {
    static id = id;
    static defaults = {
      datasetElementType: false,
      dataElementType: 'point',
      indexAxis: 'r',
    };
    static overrides = overrides;

    update(mode) {
      const meta = this._cachedMeta;
      this.updateElements(meta.data, 0, meta.data.length, mode);
    }

    updateElements(points, start, count, mode) {
      const scale = this._cachedMeta.rScale;
      for (let i = start; i < start + count; i++) {
        const position = scale.getPointPositionForValue(i, this.getParsed(i).r);
        this.updateElement(
          points[i],
          i,
          {
            x: position.x,
            y: position.y,
            angle: position.angle,
            options: this.resolveDataElementOptions(i, mode),
          },
          mode,
        );
      }
    }
  };
}

/**
 * Gives [fn] the name [name] and returns it. A config writes a named
 * function as `'fn:<name>'`: the Dart test has a function of the same name.
 */
export function named(name, fn) {
  fn.dartName = name;
  return fn;
}

// ---------------------------------------------------------------------------
// The text measure: Liberation Sans 2.1.5.

/** The first font of a canvas (the HTML default). */
const INITIAL_FONT = '10px sans-serif';

/** The family names of the test font of the harness (fonts.dart). */
const FAMILIES = new Set(['Helvetica Neue', 'Helvetica', 'Arial', 'Liberation Sans', 'sans-serif']);

/**
 * The tables of the TrueType font [file] in packages/chartjs_test_utils/lib/
 * fonts/ that a width needs: the units per em (`head`), the advance widths
 * (`hhea`, `hmtx`), the glyph of each ASCII character (`cmap` format 4 of
 * platform 3, encoding 1) and the pairs of the `kern` table (format 0). For
 * printable ASCII, the `kern` pairs of Liberation Sans 2.1.5 equal the
 * GPOS `kern` feature, which Flutter and Chrome apply.
 */
function readFont(file) {
  const b = readFileSync(new URL(file, FONTS));
  const u16 = (o) => b.readUInt16BE(o);
  const i16 = (o) => b.readInt16BE(o);
  const u32 = (o) => b.readUInt32BE(o);
  const tables = {};
  for (let i = 0, n = u16(4); i < n; i++) {
    const record = 12 + 16 * i;
    tables[b.toString('latin1', record, record + 4)] = u32(record + 8);
  }
  for (const tag of ['head', 'hhea', 'hmtx', 'cmap', 'kern']) {
    if (tables[tag] === undefined) throw new Error(`${file} has no ${tag} table.`);
  }
  const unitsPerEm = u16(tables.head + 18);
  const metrics = u16(tables.hhea + 34);
  const advance = (glyph) => u16(tables.hmtx + 4 * Math.min(glyph, metrics - 1));

  // cmap: the subtable of format 4 for platform 3 (Windows), encoding 1
  // (Unicode BMP).
  const cmap = tables.cmap;
  let format4 = null;
  for (let i = 0, n = u16(cmap + 2); i < n; i++) {
    const offset = cmap + u32(cmap + 8 + 8 * i);
    if (u16(cmap + 4 + 8 * i) === 3 && u16(cmap + 6 + 8 * i) === 1 && u16(offset) === 4) {
      format4 = offset;
    }
  }
  if (format4 === null) throw new Error(`${file} has no cmap subtable 3/1 of format 4.`);
  const glyphs = new Map();
  const segments = u16(format4 + 6) / 2;
  const ends = format4 + 14;
  const starts = ends + 2 * segments + 2;
  const deltas = starts + 2 * segments;
  const rangeOffsets = deltas + 2 * segments;
  for (let code = 0x20; code <= 0x7e; code++) {
    let glyph = 0;
    for (let s = 0; s < segments; s++) {
      if (u16(ends + 2 * s) < code) continue;
      const start = u16(starts + 2 * s);
      if (start > code) break;
      const delta = i16(deltas + 2 * s);
      const rangeOffset = u16(rangeOffsets + 2 * s);
      if (rangeOffset === 0) {
        glyph = (code + delta) & 0xffff;
      } else {
        glyph = u16(rangeOffsets + 2 * s + rangeOffset + 2 * (code - start));
        if (glyph !== 0) glyph = (glyph + delta) & 0xffff;
      }
      break;
    }
    if (glyph === 0) throw new Error(`${file} has no glyph for U+${code.toString(16)}.`);
    glyphs.set(code, glyph);
  }

  // kern: version 0, horizontal subtables of format 0.
  const kern = tables.kern;
  if (u16(kern) !== 0) throw new Error(`${file} has a kern table of version ${u16(kern)}.`);
  const pairs = new Map();
  let subtable = kern + 4;
  for (let t = 0, n = u16(kern + 2); t < n; t++) {
    const length = u16(subtable + 2);
    const coverage = u16(subtable + 4);
    // Format 0, horizontal, no minimum values, not cross-stream.
    if (coverage >> 8 !== 0 || (coverage & 0xf) !== 1) {
      throw new Error(`${file} has a kern subtable with the coverage ${coverage}.`);
    }
    for (let i = 0, count = u16(subtable + 6); i < count; i++) {
      const pair = subtable + 14 + 6 * i;
      pairs.set(u16(pair) * 0x10000 + u16(pair + 2), i16(pair + 4));
    }
    subtable += length;
  }

  return {
    unitsPerEm,
    /** The width of the ASCII [text] in font units, with the kerning. */
    units(text) {
      let units = 0;
      let previous = null;
      for (let i = 0; i < text.length; i++) {
        const glyph = glyphs.get(text.charCodeAt(i));
        units += advance(glyph);
        if (previous !== null) units += pairs.get(previous * 0x10000 + glyph) ?? 0;
        previous = glyph;
      }
      return units;
    },
  };
}

const REGULAR = readFont('LiberationSans-Regular.ttf');
const BOLD = readFont('LiberationSans-Bold.ttf');

/** The font strings that a canvas ignores and that the mock ignores too. */
const IGNORED_FONTS = new Set(['null', 'undefined', '']);

/**
 * The parts of a CSS font of `toFontString` (helpers.options.ts):
 * `[style ][weight ]<size>px <family list>`.
 *
 * The font strings of IGNORED_FONTS give null: a canvas ignores the write of
 * such a font (toFontString gives null for a font without a size or a
 * family). Another font that does not have this form stops with an error:
 * the canvas of the harness can parse it, and then the two sides measure in
 * different fonts.
 */
function parseFont(font) {
  if (IGNORED_FONTS.has(font)) return null;
  const match =
    /^\s*(?:(normal|italic|oblique)\s+)?(?:(normal|bold|bolder|lighter|\d+(?:\.\d+)?)\s+)?(\d+(?:\.\d+)?)px\s+(\S.*)$/.exec(
      font,
    );
  if (!match) {
    throw new Error(`The mock cannot parse the font ${JSON.stringify(font)}.`);
  }
  const families = match[4]
    .split(',')
    .map((family) => family.trim().replace(/^(['"])(.*)\1$/, '$2'));
  return {
    string: font,
    style: match[1] ?? 'normal',
    weight: match[2] ?? 'normal',
    size: Number(match[3]),
    families,
  };
}

/**
 * The width of [text] in the parsed font [font], in Liberation Sans. It
 * stops with an error outside the limits of the header.
 */
function liberationWidth(font, text) {
  if (!/^[\x20-\x7e]*$/.test(text)) {
    throw new Error(`The mock measures ASCII text only: ${JSON.stringify(text)}.`);
  }
  if (font.style !== 'normal') {
    throw new Error(`The mock has no ${font.style} face: ${font.string}.`);
  }
  if (!Number.isInteger(font.size)) {
    throw new Error(`The mock measures integer px sizes only: ${font.string}.`);
  }
  for (const family of font.families) {
    if (!FAMILIES.has(family)) {
      throw new Error(`The family ${family} is not a family of the harness: ${font.string}.`);
    }
  }
  const face = fontFace(font);
  return (face.units(text) * font.size) / face.unitsPerEm;
}

/**
 * The face of the parsed font [font]: REGULAR for the weight 'normal' or a
 * number from 1 to 500, BOLD for the weight 'bold' or a number from 550 to
 * 1000. The canvas of the harness rounds a number to the nearest 100
 * (parseCanvasFont), and the engine takes the regular face for 100 to 500
 * and the bold face for 600 to 900. Other weights stop with an error.
 */
function fontFace(font) {
  const {weight} = font;
  if (weight === 'normal') return REGULAR;
  if (weight === 'bold') return BOLD;
  if (/^\d/.test(weight)) {
    const n = Number(weight);
    if (n >= 1 && n <= 500) return REGULAR;
    if (n >= 550 && n <= 1000) return BOLD;
  }
  throw new Error(`The mock has no weight ${weight}: ${font.string}.`);
}

/**
 * Each text that a LiberationContext measured, by font and text:
 * `{font, text, width}`. writeReference() writes them, and the Dart test
 * measures them again on the canvas of the harness.
 */
const measured = new Map();

/**
 * The mock context of chartjs-test-utils (third_party/chartjs-test-utils/
 * src/context.js) with the text widths of Liberation Sans 2.1.5.
 *
 * - `measureText` gives the width of the text in the current font, with the
 *   kerning (see liberationWidth). It records the call as the mock does.
 * - The current font is the last font that parses (parseFont), as on a
 *   canvas. The first font is '10px sans-serif'. `save` and `restore` push
 *   and pop it: the time scale measures with the current font
 *   (scale.time.js:591-593). A write of the canvas size resets the font
 *   and the saved fonts (resetFontState).
 * - The text of `measureText`, `fillText` and `strokeText` gets the DOM
 *   `ToString`: the canvas interface of the port takes a String.
 * - `resetTransform` records its call: the mock has no such method, and
 *   `clearCanvas` calls it.
 *
 * The mock defines its methods as own properties in its constructor
 * (context.js:150). A method of this class body would not replace them.
 * Thus the constructor replaces them after `super()`. The `font` setter is
 * an own accessor that cannot change: `record` sees its writes.
 */
export class LiberationContext extends Context {
  constructor() {
    super();
    this.resetFontState();
    for (const name of ['fillText', 'strokeText']) {
      const method = this[name];
      this[name] = (text, ...rest) => method(String(text), ...rest);
    }
    const save = this.save;
    this.save = (...args) => {
      save(...args);
      this._fontStack.push(this._parsedFont);
    };
    const restore = this.restore;
    this.restore = (...args) => {
      restore(...args);
      if (this._fontStack.length) this._parsedFont = this._fontStack.pop();
      this._font = this._parsedFont.string;
    };
    this.measureText = (value) => {
      const text = String(value);
      this.record('measureText', [text]);
      if (!text) {
        return {
          actualBoundingBoxAscent: 0,
          actualBoundingBoxDescent: 0,
          actualBoundingBoxLeft: 0,
          actualBoundingBoxRight: 0,
          width: 0,
        };
      }
      const font = this._parsedFont;
      const width = liberationWidth(font, text);
      measured.set(`${font.string}\n${text}`, {font: font.string, text, width});
      return {
        actualBoundingBoxAscent: 4,
        actualBoundingBoxDescent: 8,
        actualBoundingBoxLeft: 15,
        actualBoundingBoxRight: 25,
        width,
      };
    };
  }

  record(name, args) {
    super.record(name, args);
    if (name === 'setFont') {
      // A canvas keeps its font when the new value does not parse.
      this._parsedFont = parseFont(String(args[0])) ?? this._parsedFont;
      this._font = this._parsedFont.string;
    }
  }

  resetTransform() {
    this.record('resetTransform', []);
  }

  /**
   * Sets the first font, '10px sans-serif', and drops the saved fonts. A
   * write of the canvas size resets the context to its default state (HTML,
   * "set bitmap dimensions"), as `_resetForResize` of canvas_ui.dart does.
   * retinaScale writes the size (helpers.dom.ts:236-237).
   */
  resetFontState() {
    this._font = INITIAL_FONT;
    this._parsedFont = parseFont(INITIAL_FONT);
    this._fontStack = [];
  }
}

/**
 * A canvas `style` with the three methods of CSSStyleDeclaration that
 * helpers.rtl.ts:55-73 calls (`overrideTextDirection` and
 * `restoreTextDirection`), and the CSSOM rules of `setProperty`: a priority
 * other than '' and 'important' (ASCII case-insensitive) does nothing, an
 * empty value (also `null`, [LegacyNullToEmptyString]) removes the
 * property, and a `direction` value that does not parse does nothing. The
 * plain properties `width` and `height` of controller_reference.mjs still
 * read and write on the object. As `_Style` of
 * test/port/helpers/helpers.rtl_test.dart.
 */
function domStyle() {
  const directions = new Set([
    'ltr',
    'rtl',
    'inherit',
    'initial',
    'unset',
    'revert',
    'revert-layer',
  ]);
  const props = new Map();
  return {
    getPropertyValue: (name) => props.get(String(name))?.[0] ?? '',
    getPropertyPriority: (name) => props.get(String(name))?.[1] ?? '',
    setProperty(name, value, priority = '') {
      name = String(name);
      value = value === null ? '' : String(value);
      priority = priority === null ? '' : String(priority);
      const important = priority.toLowerCase() === 'important';
      if (priority !== '' && !important) return;
      if (value === '') {
        props.delete(name);
        return;
      }
      if (name === 'direction') {
        // A keyword parses ASCII case-insensitive and serializes in lower case.
        value = value.toLowerCase();
        if (!directions.has(value)) return;
      }
      props.set(name, [value, important ? 'important' : '']);
    },
  };
}

/**
 * A canvas of [width] x [height] with a LiberationContext, as a DOM canvas:
 * the `id` `''`, the `style` of [domStyle], and a write of `width` or
 * `height` takes the `ToUint32` of the value and resets the font state of
 * the context. The default is the 512 x 512 canvas of `_acquireChart`
 * (chartjs-test-utils src/utils.js:41).
 */
export function fakeCanvas(width = 512, height = 512) {
  const ctx = new LiberationContext();
  let w = width;
  let h = height;
  const canvas = {
    id: '',
    get width() {
      return w;
    },
    set width(value) {
      w = value >>> 0;
      ctx.resetFontState();
    },
    get height() {
      return h;
    },
    set height(value) {
      h = value >>> 0;
      ctx.resetFontState();
    },
    style: domStyle(),
    getContext(id) {
      return id === '2d' ? ctx : null;
    },
  };
  ctx.canvas = canvas;
  return canvas;
}

/**
 * The chart of [config] as `_acquireChart(config, options)` of
 * chartjs-test-utils makes it (src/utils.js:36-105, and
 * packages/chartjs_test_utils/lib/src/utils.dart), on a fake canvas.
 *
 * - The canvas is 512 x 512, or the `width` and `height` of
 *   `options.canvas`. Give both: a canvas without the attribute `height`
 *   gets the height of the aspect ratio on the DOM platform, and not on
 *   BasicPlatform. Other options stop with an error.
 * - The function writes `animation: false`, `responsive: false` and
 *   `locale: 'en-US'` into the options of [config] when they are absent, as
 *   `_acquireChart` does.
 * - The chart gets the context, not the canvas (src/utils.js:94). Node.js
 *   has no DOM, so the chart gets BasicPlatform. A non-responsive chart
 *   with the device pixel ratio 1 lays out as on the DOM platform.
 */
export function makeChart(config, options = {}) {
  const C = loaded();
  config = config || {};
  for (const key of Object.keys(options)) {
    if (key !== 'canvas') throw new Error(`makeChart has no option ${key}.`);
  }
  const attributes = options.canvas || {height: 512, width: 512};
  for (const key of Object.keys(attributes)) {
    if (key !== 'width' && key !== 'height') {
      throw new Error(`makeChart has no canvas attribute ${key}.`);
    }
  }
  if (!Number.isInteger(attributes.width) || !Number.isInteger(attributes.height)) {
    throw new Error('Give the canvas width and height as integers.');
  }
  const canvas = fakeCanvas(attributes.width, attributes.height);

  // by default, remove chart animation and auto resize
  config.options = config.options || {};
  config.options.animation =
    config.options.animation === undefined ? false : config.options.animation;
  config.options.responsive =
    config.options.responsive === undefined ? false : config.options.responsive;
  config.options.locale = config.options.locale || 'en-US';

  return new C.Chart(canvas.getContext('2d'), config);
}

// ---------------------------------------------------------------------------
// The observations.

/** [v], or NaN for undefined: the Dart fields give NaN for JS undefined. */
const number = (v) => (v === undefined ? NaN : v);

/**
 * The observations of [chart] after its layout. observeChart of
 * scale_chart_harness.dart gives the same keys.
 *
 * - `chartArea`: `[left, top, right, bottom]`.
 * - `scales`: for each scale id, in the order of `chart.scales`: `type`,
 *   `axis`, `position`, `min`, `max`, `ticks` (`[value, label, major]`),
 *   `box` (`[left, top, right, bottom]`), `labelRotation`, `paddings`
 *   (`[left, top, right, bottom]`), `tickPixels` (`getPixelForTick(i)` of
 *   each tick), `valuePixels` (`getPixelForValue` of min, of the middle and
 *   of max), `valueForPixel` (`getValueForPixel` of the start, the middle
 *   and the end of the box along the axis) and `basePixel`
 *   (`getBasePixel()`). [extra], when given, adds the keys of
 *   `extra(scale, chart)`.
 * - `points`: for each dataset, `[x, y]` of each data element.
 *
 * A number field that is undefined is NaN. `getValueForPixel` of the base
 * class gives undefined, which is null here (Dart null). The numbers that
 * JSON cannot hold are `{num: 'NaN'}`, `{num: 'Infinity'}`, `{num:
 * '-Infinity'}` and `{num: '-0'}`.
 */
export function observe(chart, extra) {
  const scales = {};
  for (const id of Object.keys(chart.scales)) {
    const s = chart.scales[id];
    const ticks = s.ticks;
    const horizontal = s.isHorizontal();
    const start = horizontal ? s.left : s.top;
    const end = horizontal ? s.right : s.bottom;
    scales[id] = {
      type: s.type,
      axis: s.axis,
      position: s.position,
      min: number(s.min),
      max: number(s.max),
      ticks: ticks.map((t) => [t.value, t.label, t.major === true]),
      box: [s.left, s.top, s.right, s.bottom].map(number),
      labelRotation: number(s.labelRotation),
      paddings: [s.paddingLeft, s.paddingTop, s.paddingRight, s.paddingBottom].map(number),
      tickPixels: ticks.map((_, i) => s.getPixelForTick(i)),
      valuePixels: [s.min, (s.min + s.max) / 2, s.max].map((v) => s.getPixelForValue(v)),
      valueForPixel: [start, (start + end) / 2, end].map((p) => s.getValueForPixel(p) ?? null),
      basePixel: s.getBasePixel(),
      ...(extra ? extra(s, chart) : {}),
    };
  }
  const area = chart.chartArea;
  return jsonValue({
    chartArea: [area.left, area.top, area.right, area.bottom],
    scales,
    points: chart.data.datasets.map((_, i) =>
      chart.getDatasetMeta(i).data.map((p) => [number(p.x), number(p.y)]),
    ),
  });
}

// ---------------------------------------------------------------------------
// The calls: a copy of tool/reference/scale_reference.mjs (the records of
// the Dart MockContext, harness-mock-optional-args, js_webidl.dart), with
// `arc`.

/**
 * The declared parameter counts of the Dart MockContext methods with
 * optional parameters, and the value of an absent argument
 * (harness-mock-optional-args): the mock records every declared parameter.
 */
const PAD = {clip: 2, fill: 2, stroke: 1, fillText: 4, strokeText: 4, arc: 6};

/**
 * The value that the Dart MockContext records for a canvas setter when
 * upstream assigns `v`: the conversions of lib/src/js/js_webidl.dart.
 */
function setterValue(name, v) {
  if (v === undefined) return null;
  switch (name) {
    case 'setLineWidth':
    case 'setLineDashOffset':
      return Number(v);
    default:
      return v;
  }
}

/**
 * A JSON value with each number that JSON cannot hold as `{num: s}`.
 *
 * A `Path2D` (the recorder of tool/reference/controller_chart_common.mjs)
 * becomes `{path: <id>, calls: [[name, ...args], ...]}`: the id of the path
 * in [ids], and its commands with the arguments of dartCall. The ids start
 * at 1 in the order of the first sight. [ids] maps each path to its id: one
 * Map for one dartCalls call. The Dart side gives the same form
 * (recordedCalls of test/port/canvas/path2d_record.dart).
 */
export function jsonValue(v, ids = new Map()) {
  if (typeof v === 'number' && (!Number.isFinite(v) || Object.is(v, -0))) {
    return {num: Object.is(v, -0) ? '-0' : String(v)};
  }
  if (Array.isArray(v)) return v.map((x) => jsonValue(x, ids));
  if (globalThis.Path2D && v instanceof globalThis.Path2D) {
    if (!ids.has(v)) ids.set(v, ids.size + 1);
    return {
      path: ids.get(v),
      calls: v.calls.map(([name, args]) => dartCall(name, args, ids)),
    };
  }
  if (v && typeof v === 'object') {
    return Object.fromEntries(Object.entries(v).map(([k, x]) => [k, jsonValue(x, ids)]));
  }
  return v;
}

/**
 * The canvas and Path2D methods whose parameters are all numbers
 * (`unrestricted double`). The DOM applies `ToNumber` to each argument. The
 * port passes a `double`, NaN for `undefined`. A radar line with a tension
 * and no filler gives `undefined` control points to `bezierCurveTo`.
 */
const NUMBER_METHODS = new Set([
  'moveTo',
  'lineTo',
  'bezierCurveTo',
  'quadraticCurveTo',
  'translate',
  'rotate',
  'rect',
  'fillRect',
  'strokeRect',
  'clearRect',
]);

/**
 * The arguments that the Dart MockContext records for the upstream
 * arguments `args` of the method `name`: the WebIDL conversions of the
 * canvas interface. The text of `measureText`, `fillText` and `strokeText`
 * is a `DOMString`: `ToString`. Their `x` and `y` are numbers. An absent
 * optional argument (`undefined`) is `null`. The first five arguments of
 * `arc` are numbers: `ToNumber`, as the DOM converts them. A bubble with a
 * string radius gives the string to `arc` (controller.bubble.js:165). The
 * Dart `arc` records an absent `counterclockwise` as its default, false: a
 * point draws `arc(x, y, r, 0, TAU)` with 5 arguments (helpers.canvas.ts).
 */
function dartArgs(name, args) {
  if (NUMBER_METHODS.has(name)) return args.map(Number);
  if (name === 'measureText') return [String(args[0])];
  if (name === 'fillText' || name === 'strokeText') {
    return [
      String(args[0]),
      Number(args[1]),
      Number(args[2]),
      args[3] === undefined ? null : Number(args[3]),
    ];
  }
  if (name === 'arc') {
    const list = args.map((a, i) => (i < 5 ? Number(a) : a === undefined ? null : a));
    while (list.length < 6) list.push(null);
    if (list[5] === null) list[5] = false;
    return list;
  }
  return args.map((a) => (a === undefined ? null : a));
}

/** The calls of dartCalls, which `dart` writes as a raw string. */
export class CallsText {
  constructor(text) {
    this.text = text;
  }
}

/**
 * The call that the Dart MockContext records for the upstream call [name]
 * with the arguments [args], as the JSON array `[name, ...args]` (see
 * dartCalls). A `Path2D` argument gets its id in [ids] (jsonValue).
 */
function dartCall(name, args, ids) {
  const list = dartArgs(name, args);
  const pad = PAD[name];
  if (pad) while (list.length < pad) list.push(null);
  if (name.startsWith('set') && name !== 'setLineDash' && name !== 'setTransform') {
    list[0] = setterValue(name, args[0]);
  }
  if (name === 'setLineDash') list[0] = list[0].map(Number);
  return [name, ...list.map((a) => jsonValue(a, ids))];
}

/**
 * The calls that the Dart MockContext records for the upstream calls, as
 * text: one JSON array `[name, ...args]` for each line. A number that JSON
 * cannot hold is `{"num": "NaN"}`, `{"num": "Infinity"}`, `{"num":
 * "-Infinity"}` or `{"num": "-0"}`. A `Path2D` argument is `{"path": <id>,
 * "calls": [...]}` (jsonValue). The ids start at 1 in each call of this
 * function.
 *
 * The port draws a rounded rectangle with one `roundRect` call
 * (differences.md `adapt-rounded-rect-path`). The recording context of the
 * Dart test records it as the upstream arcs and lines. Thus the upstream
 * calls stay as they are here.
 */
export function dartCalls(calls) {
  const ids = new Map();
  const lines = calls.map(({name, args}) => JSON.stringify(dartCall(name, args, ids)));
  return new CallsText(lines.join('\n'));
}

/**
 * The calls of one `chart.draw()`, after the layout, with the element
 * draws: the context of the chart is also the context of each scale, of
 * each dataset controller (core.datasetController.js:257), of each title
 * box (plugin.title.js:16) and of the legend box (plugin.legend.js:56). The
 * Dart test (drawCalls of scale_chart_harness.dart) puts its recording
 * context in the same five places.
 */
export function drawCalls(chart) {
  const ctx = chart.ctx;
  ctx.resetCalls();
  chart.draw();
  const calls = dartCalls(ctx.getCalls());
  ctx.resetCalls();
  return calls;
}

/**
 * A copy of a config before the chart writes into it: the chart adds the
 * harness defaults to the options and listens to the data arrays. A
 * function stays the same function.
 */
function copy(v) {
  if (Array.isArray(v)) return v.map(copy);
  if (v && typeof v === 'object') {
    return Object.fromEntries(Object.keys(v).map((k) => [k, copy(v[k])]));
  }
  return v;
}

/**
 * Runs one case: the chart of [config] with the acquireChart [options]
 * (makeChart), its observations (observe, with [extra]) and the calls of
 * one draw (drawCalls). It returns `{name, config, options, expected}`,
 * with a copy of [config] and [options] before the chart writes into them.
 * The chart is destroyed at the end.
 */
export function runCase(name, config, {options = {}, extra} = {}) {
  const literal = copy(config);
  const optionsLiteral = copy(options);
  const chart = makeChart(config, copy(options));
  try {
    const expected = observe(chart, extra);
    expected.drawCalls = drawCalls(chart);
    return {name, config: literal, options: optionsLiteral, expected};
  } finally {
    chart.destroy();
  }
}

// ---------------------------------------------------------------------------
// The output.

/**
 * The Dart literal of a number. An integer below 1e21 gets `.0`. From 1e21
 * on, `String` gives the exponent form, for example `1e+21`, which is a
 * Dart double literal as it is.
 */
function num(v) {
  if (Number.isNaN(v)) return 'double.nan';
  if (v === Infinity) return 'double.infinity';
  if (v === -Infinity) return 'double.negativeInfinity';
  if (Object.is(v, -0)) return '-0.0';
  return Number.isInteger(v) && Math.abs(v) < 1e21 ? `${v}.0` : String(v);
}

/** The Dart escapes of the control characters in a string literal. */
const CONTROL_ESCAPES = {'\n': '\\n', '\r': '\\r', '\t': '\\t'};

/**
 * The Dart literal of a JS value. A named function is `'fn:<name>'`.
 * [state.undefined] becomes true when the literal has the sentinel
 * `undefined`.
 */
function dart(v, state) {
  if (v === null) return 'null';
  if (v === undefined) {
    state.undefined = true;
    return 'undefined';
  }
  if (typeof v === 'number') return num(v);
  if (typeof v === 'boolean') return String(v);
  if (typeof v === 'function') {
    if (!v.dartName) throw new Error(`An unnamed function: ${String(v)}`);
    return dart(`fn:${v.dartName}`, state);
  }
  if (typeof v === 'string') {
    // Single quotes, or double quotes for a string with a single quote
    // (prefer_single_quotes, avoid_escaping_inner_quotes).
    // A control character gets an escape: a Dart string on one line cannot
    // hold a line break.
    const quote = v.includes("'") && !v.includes('"') ? '"' : "'";
    // A raw string for a `$` or a backslash (use_raw_strings), when it
    // needs no escape: no control character and no quote of its kind.
    if (/[\\$]/.test(v) && !/[\x00-\x1f\x7f]/.test(v) && !v.includes(quote)) {
      return `r${quote}${v}${quote}`;
    }
    const escaped = v
      .replace(/[\\$]/g, '\\$&')
      .replaceAll(quote, `\\${quote}`)
      .replace(
        /[\x00-\x1f\x7f]/g,
        (c) => CONTROL_ESCAPES[c] ?? `\\x${c.charCodeAt(0).toString(16).padStart(2, '0')}`,
      );
    return `${quote}${escaped}${quote}`;
  }
  if (v instanceof CallsText) {
    if (v.text.includes("'''")) throw new Error('A call with three quotes');
    if (v.text === '') return "''";
    const raw = /[\\$]/.test(v.text) ? 'r' : '';
    return `${raw}'''\n${v.text}\n'''`;
  }
  if (Array.isArray(v)) return `<Object?>[${v.map((x) => dart(x, state)).join(', ')}]`;
  if (typeof v === 'object') {
    const entries = Object.keys(v).map((k) => `${dart(k, state)}: ${dart(v[k], state)}`);
    return `<String, Object?>{${entries.join(', ')}}`;
  }
  throw new Error(`No Dart literal for ${String(v)}`);
}

/**
 * Writes the Dart file [outPath] with the [cases] of runCase() and the
 * widths of every text that a LiberationContext measured, and formats it
 * with `dart format`.
 *
 * [name] is the lowerCamelCase prefix of the Dart names: for
 * `scaleLinear`, the constants `scaleLinearReferenceNode`, `...V8`,
 * `...Arch`, `...Dist` and `...Commit`, the typedefs
 * `ScaleLinearReferenceCase` and `ScaleLinearReferenceWidth`, and the lists
 * `scaleLinearReference` and `scaleLinearReferenceWidths`. [title] is the
 * subject of the port-only marker on line 1. [notes] are lines of a
 * comment after the header (the probes of the controller generators). A
 * comment line of more than 80 characters stops the generator: the lint
 * lines_longer_than_80_chars fails `analyze --fatal-infos` on it, and a
 * data file must not change by hand.
 */
export function writeReference(outPath, name, cases, {title = name, notes = []} = {}) {
  loaded();
  for (const line of notes) {
    const comment = `// ${line}`.trimEnd();
    if (comment.length > 80) {
      throw new Error(
        `The note line "${comment}" has ${comment.length} characters. A ` +
          'comment line of a data file has at most 80 (the lint ' +
          'lines_longer_than_80_chars). Write the probe with shorter lines.',
      );
    }
  }
  const type = name[0].toUpperCase() + name.slice(1);
  const state = {undefined: false};
  const body = cases
    .map(
      (c) =>
        `  (name: ${dart(c.name, state)}, config: ${dart(c.config, state)}, ` +
        `options: ${dart(c.options, state)}, expected: ${dart(c.expected, state)}),\n`,
    )
    .join('');
  const widths = [...measured.values()]
    .map((m) => `  (font: ${dart(m.font, state)}, text: ${dart(m.text, state)}, width: ${num(m.width)}),\n`)
    .join('');
  const generator = relative(PACKAGE_ROOT, fileURLToPath(pathToFileURL(process.argv[1])));
  const out = `// Original code, not ported from Chart.js: ${title} reference data.

// Generated by ${generator}. Do not edit.
// Node.js ${process.version} (${process.platform}-${process.arch}), V8 ${process.versions.v8}:
// a build of Chart.js v${PIN.version} at the commit
// ${buildCommit}, with the Liberation Sans mock
// context of tool/reference/scale_chart_common.mjs. ${cases.length} cases, ${measured.size} widths.
${notes.length ? `//\n${notes.map((line) => `// ${line}`.trimEnd()).join('\n')}\n` : ''}${state.undefined ? "\nimport 'package:flutter_chartjs_port/src/js/js_undefined.dart';\n" : ''}
/// The Node.js version that generated the data.
const String ${name}ReferenceNode = '${process.version}';

/// The V8 version that generated the data.
const String ${name}ReferenceV8 = '${process.versions.v8}';

/// The architecture of the Node.js build that generated the data.
const String ${name}ReferenceArch = '${process.arch}';

/// The Chart.js version of the build that generated the data: the pin
/// version of tool/port_sources.yaml, without its "v".
const String ${name}ReferenceDist = '${PIN.version}';

/// The Chart.js commit of the build that generated the data.
const String ${name}ReferenceCommit = '${buildCommit}';

/// One chart of the generator (runCase of scale_chart_common.mjs).
///
/// - \`config\`: the chart config, before the harness defaults.
///   \`'fn:<name>'\` is a named function of the Dart test.
/// - \`options\`: the options of acquireChart (the canvas size).
/// - \`expected\`: the observations of \`observe\` (\`chartArea\`,
///   \`scales\` by id and \`points\`), and \`drawCalls\`, the calls of one
///   \`chart.draw()\` as JSON lines \`[name, ...args]\`.
typedef ${type}ReferenceCase = ({
  String name,
  Map<String, Object?> config,
  Map<String, Object?> options,
  Map<String, Object?> expected,
});

/// The width of \`text\` in the CSS font \`font\` that the generator
/// measured in Liberation Sans 2.1.5.
typedef ${type}ReferenceWidth = ({String font, String text, double width});

/// The cases.
const List<${type}ReferenceCase> ${name}Reference = [
${body}];

/// Each text that the cases measured, with its font and width.
const List<${type}ReferenceWidth> ${name}ReferenceWidths = [
${widths}];
`;
  writeFileSync(outPath, out);
  execFileSync('dart', ['format', outPath], {stdio: 'inherit'});
  console.log(`Wrote ${cases.length} cases and ${measured.size} widths to ${outPath}`);
}
