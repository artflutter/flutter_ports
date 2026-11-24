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
// expected values come from a build of the pinned Chart.js in the arm64 Node.js
// (Chart.js ADR 0146), with the same test controllers as DatasetController
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
// packages/flutter_chartjs_port, with the darwin-arm64 build of Node.js
// v24.22.1 (Chart.js ADR 0146) and with the Dart SDK on the PATH (the
// generator formats its output with `dart format`):
//
//   CHARTJS_DIST=<build>/dist/chart.js \
//     node tool/reference/scale_<name>_reference.mjs
//
// The first argument can also give the path of dist/chart.js. Under
// corepack, `pnpm build` can stop in `emitDeclarations`
// (ERR_PNPM_BAD_PM_VERSION) after rollup wrote dist/. The generators need
// only dist/: `corepack pnpm exec rollup -c` builds it alone.
//
// The generator stops unless all of these are true:
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
// The data at the tag v4.6.1 (2026-10-29, on macOS with the darwin-arm64
// Node.js, Chart.js ADR 0045) came from these files. Compare them to find a
// changed input:
// - node-v24.22.1-darwin-arm64.tar.gz from https://nodejs.org/dist/v24.22.1/,
//   SHA-256 89c682593d76cd44233fa53b1563264e7de9cbb189cad169135c5b4fadfbc0a7
//   (the line of SHASUMS256.txt in the same folder).
// - dist/chart.js, SHA-256
//   5a059a341daded15d6333d1bda10f5d990c9458c4ef7f222a5b11c45913cd0df.
// - dist/chunks/index.js, SHA-256
//   7f8e207fc91dada433bd757fba6c551bc347305f2fddc9e3fdb4232edb8890cd.
// The build of phase 7 (2026-10-20) ran the darwin-x64 Node.js v24.12.0
// under Rosetta at the commit pin. Chart.js ADR 0045 replaced that engine.
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
// How to write a generator: see tool/reference/scale_linear_reference.mjs.
// It calls loadChartJs(), registerBuiltins() with its own classes, runCase()
// for each chart, and writeReference().

import {dartClip, isClipValue} from './clip_value.mjs';
import {constFill, fillTargetCode} from './fill_target.mjs';
import {dartCanvasFont, dartFont, fontRecord} from './font_record.mjs';
import {execFileSync} from 'node:child_process';
import {appendFileSync, existsSync, readFileSync, realpathSync, writeFileSync} from 'node:fs';
import {dirname, relative} from 'node:path';
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
 * imports from.
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
let nativeReferenceColor;

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
 * unless the package.json next
 * to dist/ gives the name chart.js and the release of the pin, and its
 * folder is a git checkout at the pinned commit without changes
 * (checkBuildCommit). A second call returns the same module.
 */
export async function loadChartJs() {
  if (chartJs) return chartJs;
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
  nativeReferenceColor = (await import(new URL('helpers.js', url))).color;
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
// the Dart MockContext, harness-mock-optional-args, canvas_values.dart), with
// `arc`.

/**
 * The declared parameter counts of the Dart MockContext methods with
 * optional parameters, and the value of an absent argument
 * (harness-mock-optional-args): the mock records every declared parameter.
 */
const PAD = {clip: 2, fill: 2, stroke: 1, fillText: 4, strokeText: 4, arc: 6};

/**
 * The value that the Dart MockContext records for a canvas setter when
 * upstream assigns `v`: the conversions of lib/src/canvas/canvas_values.dart.
 */
function setterValue(name, v) {
  if (v === undefined) return null;
  switch (name) {
    // The font is a ChartTextStyle (row adapt-text-style-fonts): the record
    // of its values.
    case 'setFont':
      return fontRecord(v);
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
  // A value of the Dart writer stays (row adapt-chart-position-enum).
  if (v instanceof DartPadding || v instanceof DartBorderRadius || v instanceof DartClip || v instanceof DartBorder || v instanceof DartEnum || v instanceof DartStringList || v instanceof DartDoubleList || v instanceof DartBarThickness || v instanceof DartScalePosition) return v;
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
 * An interaction mode of upstream (a key of `Interaction.modes`) as a value
 * of the Dart data: the mode class of the port, for example
 * `NearestInteractionMode()`. The port has no table from a name to a mode
 * (row adapt-interaction-mode-objects).
 */
export class DartMode {
  constructor(name) {
    this.name = name;
  }
}

/**
 * An interaction axis of upstream (`'x'`, `'y'`, `'xy'` or `'r'`) as a value
 * of the Dart data: the enum value of the port with the name of the keyword
 * (row adapt-interaction-axis-enum).
 */
export class DartAxis {
  constructor(name) {
    this.name = name;
  }
}

/**
 * The axis of a scale or the index axis (`'x'`, `'y'` or `'r'`) as a value
 * of the Dart data: the axis class of the port, `XAxis()`, `YAxis()` or
 * `RAxis()` (row adapt-axis-objects).
 */
export class DartFont {
  constructor(font) {
    this.font = font;
  }
}

/**
 * The chart option `locale` (a BCP 47 tag) as a value of the Dart data: a
 * Flutter `Locale` of its language and region (row adapt-intl-number-format).
 */
export class DartLocale {
  constructor(tag) {
    const parts = tag.split('-');
    if (parts.length > 2) throw new Error(`No Locale for the tag ${tag}.`);
    this.parts = parts;
  }
}

/**
 * The tick option `format` (an object of `Intl.NumberFormat` options) as a
 * value of the Dart data: a `NumberFormat` of package:intl in the current
 * locale (row adapt-intl-number-format). It takes the keys `style`
 * (`'decimal'` or `'percent'`), `minimumFractionDigits` and
 * `maximumFractionDigits` only. A `NumberFormat` formats the tick as it is,
 * so a case gives both digit keys: then upstream and the port agree.
 */
export class DartNumberFormat {
  constructor(options) {
    for (const key of Object.keys(options)) {
      if (!['style', 'minimumFractionDigits', 'maximumFractionDigits'].includes(key)) {
        throw new Error(`No NumberFormat for the format key ${key}.`);
      }
    }
    if (!['decimal', 'percent', undefined].includes(options.style)) {
      throw new Error(`No NumberFormat for the style ${options.style}.`);
    }
    this.options = options;
  }
}

// Native Dart values emitted directly into tooltip reference data.
class NativeTooltipCallbacks { constructor(value) { this.value = value; } }
class NativeTooltipStyle { constructor(value) { this.value = value; } }
class NativeTooltipPointStyle { constructor(value) { this.value = value; } }
class NativeTooltipPaint { constructor(value) { this.value = value; } }

/**
 * The tooltip options of an input config (`options.plugins.tooltip`): the
 * TooltipOptions object of the port (Chart.js ADR 0192). A function of the
 * generator (filter, itemSort, external, a custom positioner, a callback)
 * comes from the `functions` table of the Dart test file.
 */
class NativeTooltipOptions { constructor(value) { this.value = value; } }

/**
 * The options of the filler or the colors plugin of an input config
 * (`options.plugins.filler`, `options.plugins.colors`): the FillerOptions or
 * the ColorsPluginOptions object of the port (Chart.js ADR 0196). [type] is
 * the Dart class.
 */
class NativePluginOptions { constructor(type, value) { this.type = type; this.value = value; } }

/** The Dart class of the options object of each plugin id of Chart.js ADR 0196. */
const PLUGIN_OPTIONS_CLASSES = {filler: 'FillerOptions', colors: 'ColorsPluginOptions'};

/** The function type of each function option of the tooltip. */
const TOOLTIP_FUNCTION_TYPES = {
  filter: 'TooltipItemFilter',
  itemSort: 'TooltipItemComparator',
  external: 'TooltipExternal',
};

/** The paint options of the tooltip. */
const TOOLTIP_PAINTS = new Set([
  'backgroundColor', 'titleColor', 'bodyColor', 'footerColor', 'borderColor', 'multiKeyBackground',
]);

/** Whether the tooltip options [value] hold a function of the generator. */
function tooltipOptionsHaveFunctions(value) {
  return Object.keys(value).some(
    (k) => k in TOOLTIP_FUNCTION_TYPES || k === 'callbacks' ||
      (k === 'position' && !(value[k] in POSITIONER_CLASSES)),
  );
}

/**
 * The legend options of an input config (`options.plugins.legend`): the
 * LegendOptions object of the port (Chart.js ADR 0193). A function of the
 * generator (onClick, onHover, onLeave, generateLabels, filter, sort) comes
 * from the `functions` table of the Dart test file. A function at a
 * scriptable key (a label `color`) goes into the one function `scripted`
 * (row adapt-legend-scripted).
 */
class NativeLegendOptions { constructor(value) { this.value = value; } }

/** The function type of each function option of the legend. */
const LEGEND_FUNCTION_TYPES = {
  onClick: 'LegendEventHandler',
  onHover: 'LegendEventHandler',
  onLeave: 'LegendEventHandler',
};

/** The function type of each function option of the legend labels. */
const LEGEND_LABEL_FUNCTION_TYPES = {
  generateLabels: 'LegendLabelsGenerator',
  filter: 'LegendItemFilter',
  sort: 'LegendItemComparator',
};

/** The name of the function [x] of the generator, or null. */
function functionName(x) {
  if (typeof x === 'function') return x.dartName ?? null;
  if (typeof x === 'string' && x.startsWith('fn:')) return x.slice(3);
  return null;
}

/** Whether the legend options [value] hold a function of the generator. */
function legendOptionsHaveFunctions(value) {
  const has = (o) => Object.values(o ?? {}).some((x) => functionName(x) !== null);
  return has(value) || has(value.labels) || has(value.title);
}

/**
 * The options of the title or the subtitle plugin of an input config
 * (`options.plugins.title`, `options.plugins.subtitle`): the TitleOptions or
 * the SubtitleOptions object of the port (Chart.js ADR 0197). [type] is the
 * Dart class. A function of the generator at a scriptable key (a `text`)
 * goes into the one function `scripted` (row adapt-title-scripted).
 */
class NativeTitleOptions { constructor(type, value) { this.type = type; this.value = value; } }

/** The Dart class of the options object of each plugin id of Chart.js ADR 0197. */
const TITLE_OPTIONS_CLASSES = {title: 'TitleOptions', subtitle: 'SubtitleOptions'};

/** Whether the title options [value] hold a function of the generator. */
function titleOptionsHaveFunctions(value) {
  return Object.values(value).some((x) => functionName(x) !== null);
}

/**
 * The decimation options of an input config (`options.plugins.decimation`):
 * the DecimationOptions object of the port (Chart.js ADR 0194).
 */
class NativeDecimationOptions { constructor(value) { this.value = value; } }

/** Native padding literal (row adapt-edge-insets-padding). */
export class DartPadding {
  constructor(value) { this.value = value; }
}

/**
 * The object form of a corner option as a Flutter BorderRadius (row
 * adapt-flutter-border-radius): the keys topLeft, topRight, bottomLeft and
 * bottomRight. A number stays a number.
 */
export class DartBorderRadius {
  constructor(value) { this.value = value; }
}

/** The corner keys of a BorderRadius, in the order of its constructor. */
const CORNER_KEYS = ['topLeft', 'topRight', 'bottomLeft', 'bottomRight'];

/** Whether [value] is the object form of a bar, legend, tooltip or point label corner option. */
function isCornerObject(value) {
  return value !== null && typeof value === 'object' && value.constructor === Object &&
    Object.keys(value).length > 0 && Object.keys(value).every((k) => CORNER_KEYS.includes(k));
}

/** The Dart literal of the corners [value]: a number or an object of corners. */
export function dartBorderRadius(value) {
  if (typeof value === 'number') {
    return value ? `BorderRadius.all(Radius.circular(${nativeNumber(value)}))` : 'BorderRadius.zero';
  }
  const corners = CORNER_KEYS.filter((k) => Number(value[k]) || 0)
    .map((k) => `${k}: Radius.circular(${nativeNumber(Number(value[k]))})`);
  return corners.length ? `BorderRadius.only(${corners.join(', ')})` : 'BorderRadius.zero';
}

/** A value of the dataset option `clip` as a ChartClip of the Dart data. */
export class DartClip {
  constructor(value) { this.value = value; }
}

/**
 * A value of the scale option `border` as a ScaleBorder of the Dart data
 * (row adapt-native-scale-border): a RadialAxisBorder for the scale `r`,
 * else an AxisBorder.
 */
export class DartBorder {
  constructor(value, radial) { this.value = value; this.radial = radial; }
}

/**
 * Whether keyedValue writes a scale border object as a ScaleBorder: in the
 * config and the options of a case of writeReference, not in an
 * observation, which keeps the upstream object.
 */
let borderObjects = false;

export function dartPadding(value) {
  if (value == null) return 'EdgeInsets.zero';
  if (typeof value === 'number') return value === 0 ? 'EdgeInsets.zero' : `EdgeInsets.all(${value})`;
  const side = (name, axis) => Number(value[name] ?? value[axis]) || 0;
  if (['left','right','top','bottom','x','y'].every(k => !Number(value[k]))) return 'EdgeInsets.zero';
  return `EdgeInsets.fromLTRB(${side('left', 'x')}, ${side('top', 'y')}, ${side('right', 'x')}, ${side('bottom', 'y')})`;
}

/** The option keys whose object is a font (row adapt-text-style-fonts). */
const FONT_KEYS = new Set(['font', 'titleFont', 'bodyFont', 'footerFont']);

export class DartScaleAxis {
  constructor(name) {
    this.name = name;
  }
}

/** The keys of a config whose object holds an interaction `mode`. */
const INTERACTION_SCOPES = new Set(['interaction', 'hover', 'tooltip']);

/**
 * A tooltip positioner of upstream (a key of `Tooltip.positioners`) as a
 * value of the Dart data: the positioner class of the port for `average`
 * and `nearest`. The port has no table from a name to a positioner (row
 * adapt-tooltip-positioner-objects). Another key is a positioner of the
 * generator: the data hold `'fn:positioner:<key>'`, and the Dart test gives
 * its positioner object of that name, as it gives a named function.
 */
export class DartPositioner {
  constructor(name) {
    this.name = name;
  }
}

/**
 * The keys whose string value is a line cap or a line join of upstream: the
 * Dart data hold the Flutter enum value with the name of the keyword (row
 * adapt-flutter-stroke-enums). The options have `borderCapStyle` and
 * `borderJoinStyle`, and a legend item has `lineCap` and `lineJoin`.
 */
const STROKE_ENUMS = {
  borderCapStyle: 'StrokeCap',
  lineCap: 'StrokeCap',
  borderJoinStyle: 'StrokeJoin',
  lineJoin: 'StrokeJoin',
  // The text aligns (row adapt-flutter-text-align): the Flutter TextAlign.
  textAlign: 'TextAlign',
  textDirection: 'TextDirection',
  titleAlign: 'TextAlign',
  bodyAlign: 'TextAlign',
  footerAlign: 'TextAlign',
};

/**
 * The scale options whose value is an enum of `scale_option_enums.dart`
 * with the name of the keyword (row adapt-scale-option-enums): the key, the
 * key of the enclosing object (null for any), the enum and its values.
 */
const SCALE_ENUMS = {
  bounds: {owner: null, type: 'ScaleBounds', values: new Set(['data', 'ticks'])},
  source: {owner: 'ticks', type: 'TickSource', values: new Set(['auto', 'data', 'labels'])},
  align: {owner: 'ticks', type: 'TickAlign', values: new Set(['start', 'center', 'end', 'inner'])},
  crossAlign: {owner: 'ticks', type: 'TickCrossAlign', values: new Set(['near', 'center', 'far'])},
};

/**
 * The owners of a box `align` (row adapt-chart-align-enum): the legend, the
 * title, the subtitle, an axis title, and the `options` of a box in the
 * observations. The `position` of a legend title is a `ChartAlign` too.
 */
const ALIGN_OWNERS = new Set(['legend', 'title', 'subtitle', 'options']);

/**
 * The owners of a `display` that stays a bool: each object with a `display`
 * but a scale and its point labels (row adapt-scale-display-enum).
 */
const BOOL_DISPLAY_OWNERS = new Set([
  'angleLines',
  'border',
  'grid',
  'labels',
  'legend',
  'options',
  'plugins.legend',
  'plugins.subtitle',
  'plugins.title',
  'plugins.tooltip',
  'subtitle',
  'ticks',
  'title',
  'tooltip',
]);

/** The values of `ChartAlign`. */
const ALIGN_VALUES = new Set(['start', 'center', 'end']);

/** The values of the enum `ChartPosition` of the port. */
const POSITION_VALUES = new Set(['top', 'left', 'bottom', 'right', 'center', 'chartArea']);

/**
 * The Dart value of the position [value] of a box outside an object key
 * (row adapt-chart-position-enum): the enum value for a name, a
 * ScaleValuePosition for the object form, else the value itself.
 */
export function positionValue(value) {
  return keyedValue('position', value, 'box');
}

/**
 * The Dart value of the text align [value] outside an object key (row
 * adapt-flutter-text-align): the Flutter enum value for a keyword, else the
 * value itself.
 */
export function textAlignValue(value) {
  return keyedValue('textAlign', value, 'item');
}

/** The object form `{id: value}` of a position: a `ScaleValuePosition`. */
export class DartScalePosition {
  constructor(scaleId, value) {
    this.scaleId = scaleId;
    this.value = value;
  }
}

/** The values of the Flutter enums `StrokeCap` and `StrokeJoin`. */
const STROKE_VALUES = {
  StrokeCap: new Set(['butt', 'round', 'square']),
  StrokeJoin: new Set(['miter', 'round', 'bevel']),
  TextDirection: new Set(['ltr', 'rtl']),
  TextAlign: new Set(['left', 'right', 'center', 'start', 'end']),
};

/** A value of a Flutter enum as a value of the Dart data. */
/** The lines of a title `text`, a `List<String>` (row adapt-title-text-lines). */
export class DartStringList {
  constructor(lines) {
    this.lines = lines;
  }
}

/** A dash pattern, a `List<double>` (row adapt-dash-lists). */
export class DartDoubleList {
  constructor(values) {
    this.values = values;
  }
}

/** A bar `barThickness`, a `BarThickness` (row adapt-bar-thickness-class). */
export class DartBarThickness {
  constructor(value) {
    this.value = value;
  }
}

export class DartEnum {
  constructor(type, name) {
    this.type = type;
    this.name = name;
  }
}

/**
 * The algorithm classes of the decimation plugin of the port, by the
 * upstream names of the option `algorithm` (row
 * adapt-decimation-algorithm-objects): the data hold the class.
 */
const DECIMATION_ALGORITHMS = {
  lttb: 'LttbDecimationAlgorithm()',
  'min-max': 'MinMaxDecimationAlgorithm()',
};

/**
 * The mode classes of the port by the keywords of the line option
 * `cubicInterpolationMode` (row adapt-cubic-interpolation-mode-objects).
 */
const CUBIC_MODES = {
  default: 'DefaultCubicInterpolationMode()',
  monotone: 'MonotoneCubicInterpolationMode()',
};

/**
 * The style classes of the port by the style names of the option
 * `pointStyle` (row adapt-point-style-objects).
 */
const POINT_STYLES = {
  circle: 'CirclePointStyle()',
  cross: 'CrossPointStyle()',
  crossRot: 'CrossRotPointStyle()',
  dash: 'DashPointStyle()',
  line: 'LinePointStyle()',
  rect: 'RectPointStyle()',
  rectRounded: 'RectRoundedPointStyle()',
  rectRot: 'RectRotPointStyle()',
  star: 'StarPointStyle()',
  triangle: 'TrianglePointStyle()',
};

/**
 * A fill value of upstream as a value of the Dart data: the FillTarget of the
 * port (Chart.js ADR 0140, row adapt-fill-target-objects). [code] is the Dart
 * expression.
 */
export class DartFill {
  constructor(code) {
    this.code = code;
    this.split = code.includes('.split(');
  }
}

/**
 * A length of upstream as a value of the Dart data (row adapt-length-objects):
 * [type] is PercentRadius, PixelRadius, PercentGrace or ValueGrace.
 */
export class DartLength {
  constructor(type, value) {
    this.type = type;
    this.value = value;
  }
}

/**
 * The length of the value [value] of the key [k], or undefined: `cutout` and
 * `grace` take a percent text or a number, and `radius` a percent text (a
 * number `radius` is also the radius of a point).
 */
function lengthValue(k, value) {
  const percent = typeof value === 'string' && /^-?[0-9.]+%$/.test(value);
  const number = typeof value === 'number';
  if (k === 'grace' && (percent || number)) {
    return percent ? new DartLength('PercentGrace', parseFloat(value)) : new DartLength('ValueGrace', value);
  }
  if (k === 'cutout' && (percent || number)) {
    return percent ? new DartLength('PercentRadius', parseFloat(value)) : new DartLength('PixelRadius', value);
  }
  if (k === 'radius' && percent) return new DartLength('PercentRadius', parseFloat(value));
  return undefined;
}

/** A point style name of upstream as a value of the Dart data. */
export class DartPointStyle {
  constructor(name) {
    this.name = name;
  }
}

/** A cubic interpolation mode of upstream as a value of the Dart data. */
export class DartCubicMode {
  constructor(name) {
    this.name = name;
  }
}

/** A decimation algorithm of upstream as a value of the Dart data. */
class DartAlgorithm {
  constructor(name) {
    this.name = name;
  }
}

/** The names of the nine values of the enum TimeUnit of the port. */
const TIME_UNIT_NAMES = new Set([
  'millisecond', 'second', 'minute', 'hour', 'day', 'week', 'month',
  'quarter', 'year',
]);

/** The chart types: the keys of the options of a dataset type. */
const CHART_TYPES = new Set([
  'bar', 'bubble', 'doughnut', 'line', 'pie', 'polarArea', 'radar', 'scatter',
]);

/** The positioner classes of the port by their upstream keys. */
const POSITIONER_CLASSES = {
  average: 'AverageTooltipPositioner()',
  nearest: 'NearestTooltipPositioner()',
};

/**
 * The value [value] of the key [k] in the object of the key [owner], as a
 * value of the Dart data: a name of upstream becomes the native value of
 * the port (a mode or positioner class, an enum value), each by the rule of
 * its row. Another value stays.
 */
function keyedValue(k, value, owner) {
  if (value instanceof DartCode) return value;
  if (k === 'tooltip' && owner === 'plugins' && value && value.constructor === Object) {
    return new NativeTooltipOptions(value);
  }
  if (k === 'legend' && owner === 'plugins' && value && value.constructor === Object) {
    return new NativeLegendOptions(value);
  }
  if (k === 'decimation' && owner === 'plugins' && value && value.constructor === Object) {
    return new NativeDecimationOptions(value);
  }
  if (k in PLUGIN_OPTIONS_CLASSES && owner === 'plugins' && value && value.constructor === Object) {
    return new NativePluginOptions(PLUGIN_OPTIONS_CLASSES[k], value);
  }
  if (k in TITLE_OPTIONS_CLASSES && owner === 'plugins' && value && value.constructor === Object) {
    return new NativeTitleOptions(TITLE_OPTIONS_CLASSES[k], value);
  }
  if (k === 'callbacks' && value && value.constructor === Object &&
      Object.values(value).every(v => typeof v === 'function' || typeof v === 'string' && v.startsWith('fn:'))) {
    return new NativeTooltipCallbacks(value);
  }
  if (k === 'labelColors' && Array.isArray(value)) return value.map(v => new NativeTooltipStyle(v));
  if (k === 'labelPointStyles' && Array.isArray(value)) return value.map(v => new NativeTooltipPointStyle(v));
  if (k === 'labelTextColors' && Array.isArray(value)) return value.map(v => new NativeTooltipPaint(v));
  if (['plugins.tooltip', 'body'].includes(owner) && ['title', 'beforeBody', 'afterBody', 'footer', 'before', 'lines', 'after'].includes(k) && Array.isArray(value)) {
    return value.map(line => typeof line === 'number' ? String(line) : line);
  }
  // The dataset option clip, in a dataset, in the chart options and in the
  // options of a dataset type (row adapt-chart-clip-option). The clip of a
  // scale is a bool and stays.
  if (k === 'clip' && (owner === 'datasets' || owner === 'options' || CHART_TYPES.has(owner)) && isClipValue(value)) {
    return new DartClip(value);
  }
  // The scale option border of an input config (row adapt-native-scale-border).
  if (borderObjects && k === 'border' && value && value.constructor === Object) {
    return new DartBorder(value, owner === 'r');
  }
  // The object form of a corner option (row adapt-flutter-border-radius).
  // The arc corners (outerStart, ...) stay an object.
  if (['borderRadius', 'hoverBorderRadius', 'cornerRadius'].includes(k)) {
    const corner = (v) => (isCornerObject(v) ? new DartBorderRadius(v) : v);
    if (Array.isArray(value)) return value.map(corner);
    if (isCornerObject(value)) return corner(value);
  }
  if (k === 'backdropPadding' || (k === 'padding' && ['layout', 'title', 'subtitle', 'tooltip'].includes(owner))) {
    if (typeof value === 'number' || (value && value.constructor === Object)) return new DartPadding(value);
  }
  // The object form of a position (row adapt-chart-position-enum): the
  // value of the scale of the one key of the object.
  if (
    k === 'position' &&
    owner !== 'tooltip' &&
    value !== null &&
    typeof value === 'object' &&
    value.constructor === Object &&
    Object.keys(value).length === 1
  ) {
    const [id] = Object.keys(value);
    return new DartScalePosition(id, value[id]);
  }
  // A point style name, also in an indexable list (row
  // adapt-point-style-objects). `false` stays.
  const length = lengthValue(k, value);
  if (length) return length;
  if (k === 'pointStyle') {
    const style = (v) => (typeof v === 'string' && v in POINT_STYLES ? new DartPointStyle(v) : v);
    return Array.isArray(value) ? value.map(style) : style(value);
  }
  // A font object is a ChartTextStyle (row adapt-text-style-fonts).
  if (
    FONT_KEYS.has(k) &&
    value !== null &&
    typeof value === 'object' &&
    !Array.isArray(value) &&
    Object.getPrototypeOf(value) === Object.prototype
  ) {
    return new DartFont(value);
  }
  // The chart locale is a Locale, and an object of number format options a
  // NumberFormat (row adapt-intl-number-format).
  if (k === 'locale' && owner === 'options' && typeof value === 'string') {
    return new DartLocale(value);
  }
  if (
    k === 'format' &&
    owner === 'ticks' &&
    value !== null &&
    typeof value === 'object' &&
    Object.getPrototypeOf(value) === Object.prototype
  ) {
    return new DartNumberFormat(value);
  }
  // A fill value is a FillTarget (Chart.js ADR 0140, row
  // adapt-fill-target-objects). `undefined`, `null`, a function and the
  // marker of a function stay.
  if (
    k === 'fill' &&
    value !== undefined &&
    value !== null &&
    typeof value !== 'function' &&
    !(typeof value === 'object' && ('$fn' in value || '$undefined' in value))
  ) {
    // A color of a split fill is the paint of nativeFixturePaint: the walk of
    // nativeFixtureColors does not enter the FillTarget.
    const code = fillTargetCode(value, (color) => {
      if (typeof color !== 'string' || /['\\$]/.test(color)) throw new Error(`A split fill color: ${color}`);
      return `nativeFixturePaint('${color}')`;
    });
    if (code === null) throw new Error(`No FillTarget for the fill ${JSON.stringify(value)}`);
    return new DartFill(code);
  }
  // The `text` of a title is its lines (row adapt-title-text-lines): the
  // chart title, the subtitle, a scale title, the legend title, and the
  // `options` of a title box in the observations.
  if (
    k === 'text' &&
    ['title', 'subtitle', 'options'].includes(owner) &&
    (typeof value === 'string' || typeof value === 'number' || Array.isArray(value))
  ) {
    return new DartStringList((Array.isArray(value) ? value : [value]).map(String));
  }
  // The bar `barThickness` is a BarThickness (row adapt-bar-thickness-class).
  if (k === 'barThickness' && (typeof value === 'number' || value === 'flex')) {
    return new DartBarThickness(value);
  }
  // A dash pattern is a list of doubles (row adapt-dash-lists).
  if (
    ['borderDash', 'hoverBorderDash', 'tickBorderDash'].includes(k) &&
    Array.isArray(value) &&
    value.every((x) => typeof x === 'number')
  ) {
    return new DartDoubleList(value);
  }
  // The bar `inflateAmount` `'auto'` is `undefined` (row
  // adapt-inflate-amount-auto).
  if (k === 'inflateAmount' && value === 'auto') return undefined;
  // The scale `stacked` (row adapt-stacked-option-enum).
  if (k === 'stacked' && (typeof value === 'boolean' || value === 'single')) {
    return new DartEnum('StackMode', value === true ? 'on' : value === false ? 'off' : value);
  }
  // The `display` of a scale and of the point labels (row
  // adapt-scale-display-enum). The `display` of another object stays a bool.
  if (
    k === 'display' &&
    !BOOL_DISPLAY_OWNERS.has(owner) &&
    (typeof value === 'boolean' || value === 'auto')
  ) {
    return new DartEnum('ScaleDisplay', value === true ? 'on' : value === false ? 'off' : value);
  }
  if (typeof value !== 'string') return value;
  if (k === 'mode' && INTERACTION_SCOPES.has(owner)) return new DartMode(value);
  if (k === 'axis' && INTERACTION_SCOPES.has(owner)) return new DartAxis(value);
  // The axis of a scale and the index axis (row adapt-axis-objects).
  if ((k === 'axis' || k === 'indexAxis') && ['x', 'y', 'r'].includes(value)) {
    return new DartScaleAxis(value);
  }
  if (k === 'algorithm' && owner === 'decimation') return new DartAlgorithm(value);
  if (k === 'cubicInterpolationMode' && value in CUBIC_MODES) return new DartCubicMode(value);
  if (k === 'position' && owner === 'tooltip') return new DartPositioner(value);
  const stroke = STROKE_ENUMS[k];
  if (stroke && STROKE_VALUES[stroke].has(value)) return new DartEnum(stroke, value);
  if (
    ALIGN_VALUES.has(value) &&
    ((k === 'align' && ALIGN_OWNERS.has(owner)) || (k === 'position' && owner === 'title'))
  ) {
    return new DartEnum('ChartAlign', value);
  }
  // The position of a box (row adapt-chart-position-enum): the legend, a
  // title and a scale. The tooltip `position` is a positioner (above), and
  // the `center` of the legend title is an align (above).
  if (k === 'position' && POSITION_VALUES.has(value)) {
    return new DartEnum('ChartPosition', value);
  }
  // The tooltip aligns (row adapt-tooltip-align-enums): the keys are of the
  // tooltip only.
  if (k === 'xAlign' && ['left', 'center', 'right'].includes(value)) {
    return new DartEnum('TooltipXAlign', value);
  }
  if (k === 'yAlign' && ['top', 'center', 'bottom'].includes(value)) {
    return new DartEnum('TooltipYAlign', value);
  }
  // The arc options (row adapt-arc-option-enums): the keys are of the arc
  // only.
  if (k === 'borderAlign' && ['center', 'inner'].includes(value)) {
    return new DartEnum('ArcBorderAlign', value);
  }
  if (k === 'spacingMode' && ['angular', 'proportional', 'parallel'].includes(value)) {
    return new DartEnum('ArcSpacingMode', value);
  }
  // The keyword forms of the line `stepped` and the bar `borderSkipped`
  // (rows adapt-stepped-line-enum and adapt-border-skipped-enum).
  if (k === 'stepped' && ['before', 'after', 'middle'].includes(value)) {
    return new DartEnum('SteppedLine', value);
  }
  if (
    k === 'borderSkipped' &&
    ['start', 'end', 'middle', 'bottom', 'left', 'top', 'right'].includes(value)
  ) {
    return new DartEnum('BorderSkippedEdge', value);
  }
  // The filler draw time (row adapt-filler-draw-time-enum).
  if (
    k === 'drawTime' &&
    owner === 'filler' &&
    ['beforeDraw', 'beforeDatasetDraw', 'beforeDatasetsDraw'].includes(value)
  ) {
    return new DartEnum('FillerDrawTime', value);
  }
  // The time unit (row adapt-time-unit-enum): `time.unit`, `time.minUnit`
  // and `time.round`, and the unit of a time scale in the observations.
  if (
    TIME_UNIT_NAMES.has(value) &&
    (k === 'unit' || ((k === 'minUnit' || k === 'round') && owner === 'time'))
  ) {
    return new DartEnum('TimeUnit', value);
  }
  const scaleEnum = SCALE_ENUMS[k];
  if (
    scaleEnum &&
    (scaleEnum.owner === null || scaleEnum.owner === owner) &&
    scaleEnum.values.has(value)
  ) {
    return new DartEnum(scaleEnum.type, value);
  }
  return value;
}

/**
 * The Dart literal of a JS value. A named function is `'fn:<name>'`. A
 * DartMode, and a string `mode` of the object [owner] of
 * INTERACTION_SCOPES, is the mode class of the port. A DartAxis, and a
 * string `axis` of such an object, is the axis enum value of the port. A DartPositioner, and
 * a string `position` of the object `tooltip`, is the positioner class of
 * the port. A string of a key of STROKE_ENUMS is the Flutter enum value.
 * [state.undefined] becomes true when the literal has the sentinel
 * `undefined`, [state.modes] when it has a mode class,
 * [state.positioners] when it has a positioner class, and [state.strokes]
 * gets the name of each Flutter enum of the literal.
 */
function nativeNumber(value) {
  return Number.isInteger(value) && !Object.is(value, -0) ? String(value) : num(value);
}

function nativeConstant(write) {
  if (inConst) return write();
  inConst = true;
  try { return `const ${write()}`; } finally { inConst = false; }
}

function dart(v, state, owner) {
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
  if (v instanceof DartCode) {
    return v.isConst && v.ctor && constLeaves && !inConst ? `const ${v.code}` : v.code;
  }
  if (v instanceof CallsText) {
    if (v.text.includes("'''")) throw new Error('A call with three quotes');
    if (v.text === '') return "''";
    const raw = /[\\$]/.test(v.text) ? 'r' : '';
    return `${raw}'''\n${v.text}\n'''`;
  }
  if (v instanceof DartMode) {
    state.modes = true;
    return constLeaves ? nativeConstant(() => `${v.name[0].toUpperCase()}${v.name.slice(1)}InteractionMode()`) : `${v.name[0].toUpperCase()}${v.name.slice(1)}InteractionMode()`;
  }
  if (v instanceof DartAlgorithm) {
    const type = DECIMATION_ALGORITHMS[v.name];
    if (!type) throw new Error(`No algorithm class for ${v.name}`);
    state.algorithms = true;
    return type;
  }
  if (v instanceof DartCubicMode) {
    state.cubicModes = true;
    return constLeaves ? nativeConstant(() => CUBIC_MODES[v.name]) : CUBIC_MODES[v.name];
  }
  if (v instanceof DartLength) {
    if (v.type.endsWith('Grace')) state.graceLengths = true;
    else state.radiusLengths = true;
    return `${v.type}(${Number.isInteger(v.value) && !Object.is(v.value, -0) ? String(v.value) : dart(v.value, state)})`;
  }
  if (v instanceof DartFill) {
    state.fillTargets = true;
    // A split fill is not const (Chart.js ADR 0140).
    if (v.split) state.fixturePaints = true;
    // Outside a const leaf of a final list, a constructor call takes const.
    return constLeaves && !inConst ? constFill(v.code) : v.code;
  }
  if (v instanceof DartPointStyle) {
    state.pointStyles = true;
    return constLeaves ? nativeConstant(() => POINT_STYLES[v.name]) : POINT_STYLES[v.name];
  }
  if (v instanceof DartAxis) {
    state.modes = true;
    return `InteractionAxis.${v.name}`;
  }
  if (v instanceof NativeTooltipCallbacks) {
    state.tooltipCallbacks = true;
    const listHooks = new Set(['beforeTitle','title','afterTitle','beforeBody','afterBody','beforeFooter','footer','afterFooter']);
    const fields = Object.entries(v.value).map(([key, fn]) => {
      const name = typeof fn === 'function' ? fn.dartName : fn.slice(3);
      if (!name) throw new Error(`Unnamed native tooltip callback ${key}`);
      const result = key === 'labelColor' ? 'TooltipLabelStyle' : key === 'labelTextColor' ? 'ChartPaint' : key === 'labelPointStyle' ? 'TooltipLabelPointStyle' : 'List<String>';
      const type = listHooks.has(key) ? 'TooltipItemsCallback' : `TooltipItemCallback<${result}>`;
      return `${key}: functions[${dart(name, state)}]! as ${type}`;
    });
    return `TooltipCallbacks(${fields.join(', ')})`;
  }
  if (v instanceof NativeTooltipOptions) {
    state.tooltipValues = true;
    const write = () => {
      const fields = Object.keys(v.value).map((k) => {
        const x = v.value[k];
        const fnType = TOOLTIP_FUNCTION_TYPES[k];
        if (fnType) {
          const name = typeof x === 'function' ? x.dartName : x.slice(3);
          if (!name) throw new Error(`Unnamed tooltip function ${k}`);
          state.tooltipCallbacks = true;
          return `${k}: functions[${dart(name, state)}]! as ${fnType}`;
        }
        if (k === 'position' && typeof x === 'string' && !(x in POSITIONER_CLASSES)) {
          state.tooltipCallbacks = true;
          return `position: functions[${dart(`positioner:${x}`, state)}]! as TooltipPositioner`;
        }
        if (TOOLTIP_PAINTS.has(k)) return `${k}: ${dart(new NativeTooltipPaint(x), state)}`;
        if (k === 'events') return `events: <String>[${x.map((e) => dart(e, state)).join(', ')}]`;
        if (k === 'animation' && x === false) return 'animation: TooltipAnimation.off';
        if (k === 'cornerRadius') {
          state.borderRadii = true;
          return `cornerRadius: ${dartBorderRadius(x)}`;
        }
        if (typeof x === 'number') return `${k}: ${nativeNumber(x)}`;
        if (x && x.constructor === Object && !['padding', 'callbacks'].includes(k)) {
          throw new Error(`A tooltip option object with no field form: ${k}`);
        }
        return `${k}: ${dart(keyedValue(k, x, 'tooltip'), state, k)}`;
      });
      return `TooltipOptions(${fields.join(', ')})`;
    };
    if (tooltipOptionsHaveFunctions(v.value)) return write();
    return constLeaves ? nativeConstant(write) : write();
  }
  if (v instanceof NativeLegendOptions) {
    state.tooltipValues = true;
    // The functions at scriptable keys, as `[object field, key, name]`.
    const scripted = [];
    const nested = (cls, owner, o, types) => {
      const fields = [];
      let functions = false;
      for (const k of Object.keys(o)) {
        const x = o[k];
        const name = functionName(x);
        if (name !== null && types[k]) {
          state.tooltipCallbacks = true;
          functions = true;
          fields.push(`${k}: functions[${dart(name, state)}]! as ${types[k]}`);
        } else if (name !== null) {
          scripted.push([owner, k, name]);
        } else if (k === 'color') {
          fields.push(`color: ${dart(new NativeTooltipPaint(x), state)}`);
        } else if (k === 'borderRadius') {
          // `borderRadius || style.borderRadius` (plugin.legend.js:697): a
          // falsy number is no field.
          if (typeof x === 'number' && !x) continue;
          state.borderRadii = true;
          fields.push(`borderRadius: ${nativeConstant(() => dartBorderRadius(x))}`);
        } else if (k === 'padding' && owner === 'title') {
          fields.push(`padding: ${dart(new DartPadding(x), state)}`);
        } else if (k === 'text' && owner === 'title') {
          fields.push(`text: ${dart(keyedValue(k, x, 'title'), state, k)}`);
        } else if (typeof x === 'number') {
          fields.push(`${k}: ${nativeNumber(x)}`);
        } else if (x && x.constructor === Object && k !== 'font') {
          throw new Error(`A legend ${owner} option object with no field form: ${k}`);
        } else {
          fields.push(`${k}: ${dart(keyedValue(k, x, owner), state, k)}`);
        }
      }
      const literal = `${cls}(${fields.join(', ')})`;
      return !functions && constLeaves ? nativeConstant(() => literal) : literal;
    };
    const write = () => {
      scripted.length = 0;
      const fields = Object.keys(v.value).map((k) => {
        const x = v.value[k];
        if (k === 'labels') return `labels: ${nested('LegendLabelOptions', 'labels', x, LEGEND_LABEL_FUNCTION_TYPES)}`;
        if (k === 'title') return `title: ${nested('LegendTitleOptions', 'title', x, {})}`;
        const name = functionName(x);
        if (name !== null) {
          const fnType = LEGEND_FUNCTION_TYPES[k];
          if (!fnType) throw new Error(`A scriptable legend option of no field form: ${k}`);
          state.tooltipCallbacks = true;
          return `${k}: functions[${dart(name, state)}]! as ${fnType}`;
        }
        if (k === 'events') return `events: <String>[${x.map((e) => dart(e, state)).join(', ')}]`;
        if (typeof x === 'number') return `${k}: ${nativeNumber(x)}`;
        if (x && x.constructor === Object && k !== 'position') {
          throw new Error(`A legend option object with no field form: ${k}`);
        }
        return `${k}: ${dart(keyedValue(k, x, 'legend'), state, k)}`;
      });
      if (scripted.length) {
        // The scriptable options of the generator as the one function
        // `scripted`: it calls each function with the chart context and the
        // options, as the resolver of upstream calls it with the context and
        // the sub-resolver (row adapt-legend-scripted).
        state.tooltipCallbacks = true;
        const byOwner = {};
        for (const [owner, key, name] of scripted) {
          if (owner !== 'labels' || key !== 'color') {
            throw new Error(`A scriptable legend option of no scripted form: ${owner}.${key}`);
          }
          (byOwner[owner] ??= []).push(
            `${key}: (functions[${dart(name, state)}]! as Object? Function(Object?, Object?))(context, options)! as ChartPaint`,
          );
        }
        fields.push(
          `scripted: (context, options) => LegendOptions(${Object.entries(byOwner)
            .map(([owner, f]) => `${owner}: LegendLabelOptions(${f.join(', ')})`)
            .join(', ')})`,
        );
      }
      return `LegendOptions(${fields.join(', ')})`;
    };
    if (legendOptionsHaveFunctions(v.value)) return write();
    return constLeaves ? nativeConstant(write) : write();
  }
  if (v instanceof NativeDecimationOptions) {
    state.algorithms = true;
    const write = () => {
      const fields = Object.keys(v.value).map((k) => {
        const x = v.value[k];
        if (k === 'algorithm') return `algorithm: ${dart(new DartAlgorithm(x), state)}`;
        if (k === 'samples' || k === 'threshold') {
          if (typeof x !== 'number') throw new Error(`A decimation ${k} that is not a number`);
          return `${k}: ${nativeNumber(x)}`;
        }
        if (k === 'enabled' && typeof x === 'boolean') return `enabled: ${x}`;
        if (k === 'events') return `events: <String>[${x.map((e) => dart(e, state)).join(', ')}]`;
        throw new Error(`A decimation option with no field form: ${k}`);
      });
      return `DecimationOptions(${fields.join(', ')})`;
    };
    return constLeaves ? nativeConstant(write) : write();
  }
  if (v instanceof NativeTitleOptions) {
    state.pluginOptions = true;
    const write = () => {
      const fields = [];
      const scripted = [];
      for (const k of Object.keys(v.value)) {
        const x = v.value[k];
        const name = functionName(x);
        if (name !== null) {
          scripted.push([k, name]);
        } else if (k === 'text') {
          fields.push(`text: ${dart(keyedValue(k, x, 'title'), state, k)}`);
        } else if (k === 'color') {
          fields.push(`color: ${dart(new NativeTooltipPaint(x), state)}`);
        } else if (k === 'padding') {
          fields.push(`padding: ${dart(new DartPadding(x), state)}`);
        } else if (k === 'events') {
          fields.push(`events: <String>[${x.map((e) => dart(e, state)).join(', ')}]`);
        } else if (typeof x === 'number') {
          fields.push(`${k}: ${nativeNumber(x)}`);
        } else if (x && x.constructor === Object && k !== 'font') {
          throw new Error(`A ${v.type} option object with no field form: ${k}`);
        } else {
          fields.push(`${k}: ${dart(keyedValue(k, x, 'title'), state, k)}`);
        }
      }
      if (scripted.length) {
        // The scriptable options of the generator as the one function
        // `scripted`: it calls each function with the chart context and the
        // options, as the resolver of upstream calls it with the context and
        // the sub-resolver (row adapt-title-scripted).
        state.tooltipCallbacks = true;
        const over = scripted.map(([k, name]) => {
          if (k !== 'text') throw new Error(`A scriptable ${v.type} option of no scripted form: ${k}`);
          return `text: (functions[${dart(name, state)}]! as Object? Function(Object?, Object?))(context, options)! as List<String>`;
        });
        fields.push(`scripted: (context, options) => ${v.type}(${over.join(', ')})`);
      }
      return `${v.type}(${fields.join(', ')})`;
    };
    if (titleOptionsHaveFunctions(v.value)) return write();
    return constLeaves ? nativeConstant(write) : write();
  }
  if (v instanceof NativePluginOptions) {
    state.pluginOptions = true;
    const write = () => {
      const fields = Object.keys(v.value).map((k) => {
        const x = v.value[k];
        if (typeof x === 'boolean') return `${k}: ${x}`;
        if (k === 'drawTime' && typeof x === 'string') return `drawTime: FillerDrawTime.${x}`;
        if (k === 'events') return `events: <String>[${x.map((e) => dart(e, state)).join(', ')}]`;
        throw new Error(`A ${v.type} option with no field form: ${k}`);
      });
      return `${v.type}(${fields.join(', ')})`;
    };
    return constLeaves ? nativeConstant(write) : write();
  }
  if (v instanceof NativeTooltipPaint) {
    state.tooltipValues = true;
    if (v.value == null || v.value === false) return nativeConstant(() => 'ChartPaint.unchanged()');
    const color = nativeReferenceColor(v.value);
    if (!color.valid) throw new Error(`Unsupported reference paint ${v.value}`);
    const {r, g, b, a} = color.rgb;
    (state.strokes ??= new Set()).add('Color');
    return nativeConstant(() => `ChartPaint.solid(Color.fromRGBO(${r}, ${g}, ${b}, ${nativeNumber(a)}))`);
  }
  if (v instanceof NativeTooltipStyle) {
    state.tooltipValues = true;
    const o = v.value;
    const width = o.borderWidth && typeof o.borderWidth === 'object' ? Math.max(...Object.values(o.borderWidth)) : o.borderWidth || 1;
    const fields = [
      `borderColor: ${dart(new NativeTooltipPaint(o.borderColor), state)}`,
      `backgroundColor: ${dart(new NativeTooltipPaint(o.backgroundColor), state)}`,
    ];
    if (width !== 1) fields.push(`borderWidth: ${nativeNumber(width)}`);
    if (o.borderDash?.length) fields.push(`borderDash: const <double>[${o.borderDash.map(nativeNumber).join(', ')}]`);
    if (o.borderDashOffset) fields.push(`borderDashOffset: ${nativeNumber(o.borderDashOffset)}`);
    const radius = o.borderRadius;
    const corners = radius && typeof radius === 'object' ? dartBorderRadius(radius) : radius ? dartBorderRadius(radius) : null;
    if (corners && corners !== 'BorderRadius.zero') {
      state.borderRadii = true;
      fields.push(`borderRadius: ${nativeConstant(() => corners)}`);
    }
    return `TooltipLabelStyle(${fields.join(', ')})`;
  }
  if (v instanceof NativeTooltipPointStyle) {
    state.tooltipValues = true;
    return nativeConstant(() => v.value.pointStyle === false ? 'TooltipLabelPointStyle.hidden()' :
      `TooltipLabelPointStyle.draw(${dart(keyedValue('pointStyle', v.value.pointStyle || 'circle'), state)}${v.value.rotation ? `, rotation: ${nativeNumber(v.value.rotation)}` : ''})`);
  }
  if (v instanceof DartClip) {
    state.clips = true;
    return dartClip(v.value);
  }
  if (v instanceof DartBorder) {
    state.borders = true;
    const fields = Object.keys(v.value).map((k) => {
      const x = v.value[k];
      if (k === 'dash') return `dash: <double>[${x.map((d) => nativeNumber(d)).join(', ')}]`;
      if (k === 'display' && !v.radial) return `display: ${dart(x, state)}`;
      if (k === 'dashOffset' || (!v.radial && ['width', 'z'].includes(k))) {
        return `${k}: ${nativeNumber(x)}`;
      }
      throw new Error(`A border key of no field: ${k}`);
    });
    return `${v.radial ? 'RadialAxisBorder' : 'AxisBorder'}(${fields.join(', ')})`;
  }
  if (v instanceof DartPadding) {
    state.edgeInsets = true;
    return dartPadding(v.value);
  }
  if (v instanceof DartBorderRadius) {
    state.borderRadii = true;
    const literal = dartBorderRadius(v.value);
    return constLeaves ? nativeConstant(() => literal) : literal;
  }
  if (v instanceof DartFont) {
    const literal = dartFont(v.font);
    state.textStyles = true;
    if (literal.includes('FontStyle.')) (state.strokes ??= new Set()).add('FontStyle');
    if (literal.includes('FontWeight')) (state.strokes ??= new Set()).add('FontWeight');
    return constLeaves ? nativeConstant(() => literal) : literal;
  }
  if (v instanceof DartLocale) {
    (state.strokes ??= new Set()).add('Locale');
    return `Locale(${v.parts.map((p) => dart(p, state)).join(', ')})`;
  }
  if (v instanceof DartNumberFormat) {
    state.numberFormats = true;
    const o = v.options;
    const pattern = o.style === 'percent' ? 'percentPattern' : 'decimalPattern';
    const digits = ['minimumFractionDigits', 'maximumFractionDigits']
      .filter((key) => key in o)
      .sort((a, b) => (a === 'maximumFractionDigits' ? -1 : b === 'maximumFractionDigits' ? 1 : 0))
      .map((key) => `..${key} = ${o[key]}`)
      .join('');
    return digits ? `(NumberFormat.${pattern}()${digits})` : `NumberFormat.${pattern}()`;
  }
  if (v instanceof DartScaleAxis) {
    state.scaleAxes = true;
    return constLeaves ? nativeConstant(() => `${v.name.toUpperCase()}Axis()`) : `${v.name.toUpperCase()}Axis()`;
  }
  if (v instanceof DartBarThickness) {
    // The file of BorderSkippedEdge also holds BarThickness.
    state.borderSkips = true;
    if (v.value === 'flex') return 'BarThickness.flex';
    const code = `BarThickness.pixels(${nativeNumber(v.value)})`;
    return constLeaves ? nativeConstant(() => code) : code;
  }
  if (v instanceof DartDoubleList) {
    // A whole number is an int literal (prefer_int_literals).
    return `<double>[${v.values.map((x) => (Number.isInteger(x) && !Object.is(x, -0) ? String(x) : num(x))).join(', ')}]`;
  }
  if (v instanceof DartStringList) {
    return `<String>[${v.lines.map((line) => dart(line, state)).join(', ')}]`;
  }
  if (v instanceof DartEnum) {
    if (v.type in STROKE_VALUES) {
      (state.strokes ??= new Set()).add(v.type);
    } else if (['ChartAlign', 'TooltipXAlign', 'TooltipYAlign'].includes(v.type)) {
      state.aligns = true;
    } else if (['ArcBorderAlign', 'ArcSpacingMode'].includes(v.type)) {
      state.arcEnums = true;
    } else if (v.type === 'FillerDrawTime') {
      state.fillerEnums = true;
    } else if (v.type === 'TimeUnit') {
      state.timeUnits = true;
    } else if (v.type === 'ChartPosition') {
      state.positions = true;
    } else if (v.type === 'SteppedLine') {
      state.steppedLines = true;
    } else if (v.type === 'BorderSkippedEdge') {
      state.borderSkips = true;
    } else if (v.type === 'StackMode') {
      state.stackModes = true;
    } else {
      state.scaleEnums = true;
    }
    return `${v.type}.${v.name}`;
  }
  if (v instanceof DartScalePosition) {
    state.positions = true;
    return `ScaleValuePosition(${dart(v.scaleId, state)}, ${dart(v.value, state)})`;
  }
  if (v instanceof DartPositioner) {
    const type = POSITIONER_CLASSES[v.name];
    if (!type) return dart(`fn:positioner:${v.name}`, state);
    state.positioners = true;
    return type;
  }
  if (Array.isArray(v)) {
    // A step `['setOption', path, value]` writes the option of the last key
    // of the path: its value takes the form of that key.
    if (v.length === 3 && v[0] === 'setOption' && typeof v[1] === 'string') {
      const keys = v[1].split('.');
      const value = keyedValue(keys[keys.length - 1], v[2], keys[keys.length - 2]);
      return `<Object?>[${[v[0], v[1]].map((x) => dart(x, state)).join(', ')}, ${dart(value, state, keys[keys.length - 1])}]`;
    }
    return constLiteral(v, owner, () => `<Object?>[${v.map((x) => dart(x, state, owner)).join(', ')}]`);
  }
  if (typeof v === 'object') {
    return constLiteral(v, owner, () => {
      const entries = Object.keys(v).map(
        (k) => `${dart(k, state)}: ${dart(keyedValue(k, v[k], owner), state, k)}`,
      );
      return `<String, Object?>{${entries.join(', ')}}`;
    });
  }
  throw new Error(`No Dart literal for ${String(v)}`);
}

/** The Dart literal of an input value: dart with borderObjects. */
function inputDart(v, state) {
  borderObjects = true;
  try { return dart(v, state); } finally { borderObjects = false; }
}

/** Whether the writer marks each object and array without a NumberFormat const. */
let constLeaves = false;

/**
 * The Dart `AcquireOptions` of the acquireChart [options] of a case
 * (Chart.js ADR 0200): only `canvas` with a whole `width` and `height`
 * has a form here; another key stops the generator.
 */
function acquireOptionsDart(options = {}) {
  const {canvas, ...rest} = options;
  if (Object.keys(rest).length) {
    throw new Error(`The acquireChart options ${Object.keys(rest).join(', ')} have no AcquireOptions form here.`);
  }
  let args = '';
  if (canvas !== undefined) {
    const {width, height, ...more} = canvas;
    if (Object.keys(more).length) {
      throw new Error(`The canvas options ${Object.keys(more).join(', ')} have no HarnessCanvas form here.`);
    }
    const parts = [];
    for (const [key, value] of [['width', width], ['height', height]]) {
      if (value === undefined) continue;
      if (!Number.isInteger(value)) throw new Error(`The canvas ${key} ${value} is not a whole number.`);
      parts.push(`${key}: ${value}`);
    }
    args = `canvas: HarnessCanvas(${parts.join(', ')})`;
  }
  return `${constLeaves ? 'const ' : ''}AcquireOptions(${args})`;
}

/** Whether the writer is inside a const object or array. */
let inConst = false;

/**
 * The literal of [write] for the object or array [v] in the object of the
 * key [owner]: with `const` when [constLeaves] is set, the writer is not
 * inside a const literal and [v] holds no NumberFormat.
 */
function constLiteral(v, owner, write) {
  if (!constLeaves || inConst || hasNumberFormat(v, owner)) return write();
  inConst = true;
  try {
    return `const ${write()}`;
  } finally {
    inConst = false;
  }
}

/** Whether the object or array [v] holds a NumberFormat of the Dart data. */
function hasNumberFormat(v, owner) {
  if (v instanceof DartFill) return v.split;
  if (v instanceof DartCode) return !v.isConst;
  if (v instanceof DartNumberFormat || v instanceof NativeTooltipStyle || v instanceof NativeTooltipCallbacks) return true;
  if (v instanceof NativeTooltipOptions) return tooltipOptionsHaveFunctions(v.value);
  if (v instanceof NativeLegendOptions) return legendOptionsHaveFunctions(v.value);
  if (v instanceof NativeTitleOptions) return titleOptionsHaveFunctions(v.value);
  if (Array.isArray(v)) return v.some((x) => hasNumberFormat(x, owner));
  if (v === null || typeof v !== 'object' || v.constructor !== Object) return false;
  return Object.keys(v).some((k) => hasNumberFormat(keyedValue(k, v[k], owner), k));
}

/**
 * The Dart literal of the CSS font text [css] of a width, a ChartTextStyle,
 * with the imports that it needs in [state].
 */
function canvasFont(css, state) {
  const literal = dartCanvasFont(css);
  state.textStyles = true;
  if (literal.includes('FontStyle.')) (state.strokes ??= new Set()).add('FontStyle');
  if (literal.includes('FontWeight')) (state.strokes ??= new Set()).add('FontWeight');
  return literal;
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
export function writeReference(outPath, name, cases, {title = name, notes = [], typed = true, keyOrder = false} = {}) {
  loaded();
  keyOrderMode = keyOrder;
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
  const writeBody = () => {
    typedReport = {extra: new Map(), maps: []};
    return cases
      .map(
        (c) =>
          `  (name: ${dart(c.name, state)}, config: ${typed ? typedConfigCode(c, state, name) ?? inputDart(c.config, state) : inputDart(c.config, state)}, ` +
          `options: ${acquireOptionsDart(c.options)}, expected: ${dart(c.expected, state)}),\n`,
      )
      .join('');
  };
  let body = writeBody();
  // A NumberFormat has no const constructor: the list is final, and each
  // object or array without a NumberFormat is const, so that its objects of
  // the port (an axis, a font) stay canonical.
  if (state.numberFormats || state.tooltipValues || state.tooltipCallbacks || state.fixturePaints || state.closures) {
    constLeaves = true;
    try {
      body = writeBody();
    } finally {
      constLeaves = false;
    }
  }
  const widths = [...measured.values()]
    .map((m) => `  (font: ${canvasFont(m.font, state)}, text: ${dart(m.text, state)}, width: ${num(m.width)}),\n`)
    .join('');
  const generator = relative(PACKAGE_ROOT, fileURLToPath(pathToFileURL(process.argv[1])));
  const out = `// Original code, not ported from Chart.js: ${title} reference data.

// Generated by ${generator}. Do not edit.
// Node.js ${process.version} (${process.platform}-${process.arch}), V8 ${process.versions.v8}:
// a build of Chart.js v${PIN.version} at the commit
// ${buildCommit}, with the Liberation Sans mock
// context of tool/reference/scale_chart_common.mjs. ${cases.length} cases, ${measured.size} widths.
${notes.length ? `//\n${notes.map((line) => `// ${line}`.trimEnd()).join('\n')}\n` : ''}${state.closures ? '\n// The typed configs make new data Lists at each call, as the Map form.\n// ignore_for_file: prefer_const_constructors\n// ignore_for_file: prefer_const_literals_to_create_immutables\n' : ''}${state.strokes && !state.borderRadii ? `\nimport 'dart:ui' show ${[...state.strokes].sort().join(', ')};\n` : ''}
import 'package:chartjs_test_utils/flutter.dart';
${state.fixturePaints ? "import 'package:chartjs_test_utils/pure.dart' show nativeFixturePaint;\n" : ''}${state.borderRadii ? "import 'package:flutter/painting.dart';\n" : state.edgeInsets ? "import 'package:flutter/painting.dart' show EdgeInsets;\n" : ''}${state.algorithms || state.aligns || state.arcEnums || state.borderSkips || state.borders || state.clips || state.cubicModes || state.fillTargets || state.fillerEnums || state.graceLengths || state.modes || state.pointStyles || state.positioners || state.positions || state.radiusLengths || state.scaleAxes || state.scaleEnums || state.stackModes || state.steppedLines || state.textStyles || state.timeUnits || state.tooltipCallbacks || state.tooltipValues || state.pluginOptions || state.undefined || state.typedConfigs ? `import 'package:flutter_chartjs_port/${state.positioners || state.typedConfigs ? 'chartjs' : 'chartjs_core'}.dart';\n` : ''}${state.numberFormats ? "import 'package:intl/intl.dart';\n" : ''}${supportImports(outPath, state)}
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
/// - \`config\`: the chart config, before the harness defaults: a
///   function that gives a new typed \`ChartConfig\` at each call, or the
///   Map of a config with no typed form. \`'fn:<name>'\` is a named
///   function of the Dart test.
/// - \`options\`: the options of acquireChart (the canvas size), an
///   \`AcquireOptions\` (Chart.js ADR 0200).
/// - \`expected\`: the observations of \`observe\` (\`chartArea\`,
///   \`scales\` by id and \`points\`), and \`drawCalls\`, the calls of one
///   \`chart.draw()\` as JSON lines \`[name, ...args]\`.
typedef ${type}ReferenceCase = ({
  String name,
  Object config,
  AcquireOptions options,
  Map<String, Object?> expected,
});

/// The width of \`text\` in the font \`font\` that the generator
/// measured in Liberation Sans 2.1.5: the fields of the CSS font text of
/// the mock context (row adapt-text-style-fonts).
typedef ${type}ReferenceWidth = ({
  ChartTextStyle font,
  String text,
  double width,
});

/// The cases.${state.numberFormats ? '\n///\n/// A \`NumberFormat\` of package:intl has no const constructor, so the\n/// list is final.' : ''}
${state.tooltipCallbacks ? '' : (state.numberFormats || state.tooltipValues || state.fixturePaints || state.closures ? 'final ' : 'const ')}List<${type}ReferenceCase> ${name}Reference${state.tooltipCallbacks ? '(Map<String, Object?> functions) =>' : ' ='} [
${body}];

/// Each text that the cases measured, with its font and width.
const List<${type}ReferenceWidth> ${name}ReferenceWidths = [
${widths}];
`;
  writeFileSync(outPath, out);
  execFileSync('dart', ['format', outPath], {stdio: 'inherit'});
  console.log(`Wrote ${cases.length} cases and ${measured.size} widths to ${outPath}`);
  if (process.env.TYPED_CONFIG_REPORT) {
    appendFileSync(
      process.env.TYPED_CONFIG_REPORT,
      `${JSON.stringify({file: name, cases: cases.length, extra: Object.fromEntries(typedReport.extra), maps: typedReport.maps})}\n`,
    );
  }
}

/**
 * The relative imports of the test support files that the typed configs of
 * [state] use, for the data file [outPath].
 */
function supportImports(outPath, state) {
  const files = [];
  if (state.nativePlugins) files.push('native_plugin.dart');
  if (state.testDatasets) files.push('test_dataset.dart');
  if (!files.length) return '';
  const support = relative(dirname(outPath), `${PACKAGE_ROOT}test/support`);
  return `\n${files.map((f) => `import '${support}/${f}';\n`).join('')}`;
}

/**
 * The Dart literal of the JS value [v] (the literal of writeReference), for
 * a generator that writes its own data file (resolver_trace_reference.mjs).
 * [state.undefined] becomes true when the literal has the sentinel
 * `undefined`.
 */
export function dartLiteral(v, state = {undefined: false}, leaves = false) {
  // [leaves]: the literal goes into a list that is not const (the cases of a
  // function of the test functions): each leaf that can be const takes
  // const.
  const before = constLeaves;
  constLeaves = leaves;
  try {
    return dart(v, state);
  } finally {
    constLeaves = before;
  }
}

/**
 * The facts of the loaded build for the header of a generator that writes
 * its own data file: the pin version without its "v", the commit of the
 * build, and the count of the texts that a LiberationContext measured.
 * loadChartJs() must run first.
 */
export function referenceBuild() {
  loaded();
  return {version: PIN.version, commit: buildCommit, measured: measured.size};
}

// ---------------------------------------------------------------------------
// The typed config.

/**
 * A Dart expression in a value of the Dart data: `code` as it is. [isConst]
 * tells whether the expression can stand in a const literal, and [ctor]
 * whether it is a constructor call that takes `const` outside one.
 */
export class DartCode {
  constructor(code, {isConst = false, ctor = false} = {}) {
    this.code = code;
    this.isConst = isConst;
    this.ctor = ctor;
  }
}

/** A config that keeps its Map form: the reason is the message. */
class KeepMap extends Error {}

/** Stops the typed form of the current config with [reason]. */
function keepMap(reason) {
  throw new KeepMap(reason);
}

/**
 * The record of the typed configs of a run: `extra` counts the cases of each
 * option path that goes through an `extra` Map, `maps` lists each case that
 * keeps its Map form with its reason. The environment variable
 * TYPED_CONFIG_REPORT names a JSON lines file that gets one line for each
 * data file.
 */
let typedReport = {extra: new Map(), maps: []};

/** The option paths of the `extra` Maps of the current case. */
let caseExtras = null;

/** Records the option path [path] of an `extra` Map of the current case. */
function noteExtra(path) {
  caseExtras?.add(path);
}

/**
 * A node of the typed writer: the Dart expression [code], whether it can be
 * const ([c]), and whether it is a constructor call or a collection literal
 * that takes `const` outside a const parent ([ctor]).
 */
const node = (code, c = true, ctor = false) => ({code, c, ctor});

/** The code of the child [n] in a parent that is const ([parentConst]) or not. */
function inner(n, parentConst) {
  return !parentConst && n.c && n.ctor ? `const ${n.code}` : n.code;
}

/** A constructor call of [name] with the named or positional [args] (`[label, node]`). */
function call(name, args) {
  const present = args.filter(([, n]) => n !== undefined);
  const c = present.every(([, n]) => n.c);
  const text = present.map(([k, n]) => `${k === null ? '' : `${k}: `}${inner(n, c)}`).join(', ');
  return node(`${name}(${text})`, c, true);
}

/** A list literal of [items] with the type argument [type]; [mutable] keeps it from const. */
function listNode(items, {type = '', mutable = false} = {}) {
  const c = !mutable && items.every((n) => n.c);
  return node(`${type ? `<${type}>` : ''}[${items.map((n) => inner(n, c)).join(', ')}]`, c, true);
}

/** The node of a JS value of the Dart data (dart) in the object of the key [owner]. */
function literalNode(v, state, owner) {
  const c = !hasNumberFormat(v, owner);
  const beforeLeaves = constLeaves;
  const beforeConst = inConst;
  constLeaves = true;
  inConst = c;
  try {
    const code = dart(v, state, owner);
    return node(code, c, /[)\]}]$/.test(code) && !code.startsWith('const '));
  } finally {
    constLeaves = beforeLeaves;
    inConst = beforeConst;
  }
}

/** The node of a whole number for a `double` parameter (prefer_int_literals). */
function doubleNode(v) {
  if (typeof v !== 'number') return undefined;
  return node(nativeNumber(v));
}

/** The node of a data value of a `num?` List: a double literal, as the Map data. */
function dataNumber(v) {
  if (v === null) return node('null');
  return node(num(v));
}

/** The node of a boolean. */
const boolNode = (v) => (typeof v === 'boolean' ? node(String(v)) : undefined);

/** The node of a string. */
const stringNode = (v, state) => (typeof v === 'string' ? node(dart(v, state)) : undefined);

/** The keys of a color option of nativeFixtureColors (`_isColor`). */
function isColorKey(k) {
  return (
    k === 'color' ||
    k === 'multiKeyBackground' ||
    k === 'above' ||
    k === 'below' ||
    k.endsWith('Color') ||
    k === 'fillStyle' ||
    k === 'strokeStyle'
  );
}

/**
 * The Dart expression of the paint of the CSS color text [value], as
 * `paintOfCss` of chartjs_test_utils gives it: the bytes of @kurkle/color
 * and the alpha byte over 255. Dart `null` for a text that is no color.
 */
function paintCode(value, state) {
  if (typeof value !== 'string' || value === '') return null;
  const color = nativeReferenceColor(value);
  if (!color || !color.valid) return null;
  const {r, g, b, a} = color._rgb;
  (state.strokes ??= new Set()).add('Color');
  state.typedConfigs = true;
  return `ChartPaint.solid(Color.fromRGBO(${r}, ${g}, ${b}, ${nativeNumber(a / 255)}))`;
}

/** The node of the paint of [value], or undefined for a value that is no color text. */
function paintNode(value, state) {
  const code = paintCode(value, state);
  return code === null ? undefined : node(code, true, true);
}

/**
 * The value of an `extra` Map for the option [k] with the value [v]: the
 * color conversion of nativeFixtureColors (a color text is a paint, `false`
 * and `''` are `null`), and each named function of the generator is the
 * function of the `functions` table of the Dart test. A color function stops
 * the typed form: nativeFixtureColors wraps it in a function of paints.
 */
function nativeExtra(k, v, state, path) {
  if (typeof v === 'function' || (typeof v === 'string' && v.startsWith('fn:'))) {
    if (k !== null && isColorKey(k)) keepMap(`the color option ${path} is a function of CSS texts`);
    return functionCode(v, state);
  }
  if (k !== null && isColorKey(k)) {
    if (v === false || v === '') return null;
    if (typeof v === 'string') {
      const code = paintCode(v, state);
      return code === null ? v : new DartCode(code, {isConst: true, ctor: true});
    }
    if (Array.isArray(v)) return v.map((x) => nativeExtra(k, x, state, path));
    return v;
  }
  if (Array.isArray(v)) {
    return v.map((x) => (typeof x === 'function' ? functionCode(x, state) : x));
  }
  if (v !== null && typeof v === 'object' && v.constructor === Object && !['font', 'padding', 'fill', 'format'].includes(k)) {
    return Object.fromEntries(Object.keys(v).map((x) => [x, nativeExtra(x, v[x], state, `${path}.${x}`)]));
  }
  return v;
}

/** The DartCode of the named function [v] of the generator: an item of `functions`. */
function functionCode(v, state, type = null) {
  const name = typeof v === 'function' ? v.dartName : v.slice(3);
  if (!name) throw new Error(`An unnamed function: ${String(v)}`);
  state.tooltipCallbacks = true;
  state.typedConfigs = true;
  return new DartCode(type ? `functions[${dart(name, state)}]! as ${type}` : `functions[${dart(name, state)}]`);
}

/** A Map literal `<String, Object?>{...}` of the `[key, node]` [entries]. */
function mapNode(entries, state) {
  const c = entries.every(([, n]) => n.c);
  return node(`<String, Object?>{${entries.map(([k, n]) => `${dart(k, state)}: ${inner(n, c)}`).join(', ')}}`, c, true);
}

/**
 * The number options of a dataset and of an element. A case that gives one
 * of them a text or a boolean (the parsed-data cases of Chart.js ADR 0030
 * section 7) keeps its Map: a typed scope holds such a value as a foreign
 * value of its key (the oracle O2 of Chart.js ADR 0054).
 */
const NUMBER_OPTIONS = new Set([
  'base', 'inflateAmount', 'minBarLength', 'maxBarThickness', 'barPercentage', 'categoryPercentage',
  'radius', 'hoverRadius', 'hitRadius', 'rotation', 'borderWidth', 'hoverBorderWidth', 'pointRadius',
  'pointHoverRadius', 'pointBorderWidth', 'pointHoverBorderWidth', 'pointHitRadius', 'pointRotation',
  'tension', 'offset', 'hoverOffset', 'spacing', 'weight', 'circumference', 'order', 'angle',
]);

/** Stops the typed form for a text or a boolean at a number option [k]. */
function checkNumberOption(k, v, path) {
  if (!NUMBER_OPTIONS.has(k) || !/^(data\.datasets\[\]|options\.elements)\./.test(path)) return;
  const foreign = (x) => typeof x === 'boolean' || (typeof x === 'string' && !(k === 'inflateAmount' && x === 'auto'));
  if (foreign(v) || (Array.isArray(v) && v.some(foreign))) {
    keepMap(`the number option ${path} has the value ${JSON.stringify(v)} of another type`);
  }
}

/**
 * The node of the `extra` Map [entries] of the object of the key [owner], or
 * undefined for no entry. [nodes] gives the node of a key that the caller
 * writes itself.
 */
function extraNode(entries, state, owner, path, nodes = {}) {
  const keys = Object.keys(entries);
  if (keys.length === 0) return undefined;
  return mapNode(
    keys.map((k) => {
      noteExtra(`${path}.${k}`);
      checkNumberOption(k, entries[k], `${path}.${k}`);
      if (k in nodes) return [k, nodes[k]];
      return [k, literalNode(keyedValue(k, nativeExtra(k, entries[k], state, `${path}.${k}`), owner), state, k)];
    }),
    state,
  );
}

/** A typed object: the fields of [spec] that the writer takes, the rest in `extra`. */
function typedObject(name, positional, o, spec, state, owner, path) {
  const args = positional.map((n) => [null, n]);
  const rest = {};
  for (const k of Object.keys(o)) {
    const field = spec[k];
    const n = field ? field(o[k]) : undefined;
    if (n === undefined) {
      rest[k] = o[k];
    } else {
      args.push([Array.isArray(n) ? n[0] : field.param ?? k, Array.isArray(n) ? n[1] : n]);
    }
  }
  args.push(['extra', extraNode(rest, state, owner, path)]);
  return call(name, args);
}

/** The Dart code of the keyword [v] of the enum [type] for the values [values]. */
function enumNode(type, values, v, state, flag) {
  if (typeof v !== 'string' || !values.includes(v)) return undefined;
  if (flag) state[flag] = true;
  return node(`${type}.${v}`);
}

/** The ScaleDisplay of a scale `display`. */
function scaleDisplayNode(v) {
  if (v === true) return node('ScaleDisplay.on');
  if (v === false) return node('ScaleDisplay.off');
  if (v === 'auto') return node('ScaleDisplay.auto');
  return undefined;
}

/** The node of a font object (row adapt-text-style-fonts). */
function fontNode(v, state) {
  if (v === null || typeof v !== 'object' || v.constructor !== Object) return undefined;
  return literalNode(new DartFont(v), state, 'font');
}

/** The node of a padding (EdgeInsets). */
function paddingNode(v, state) {
  if (typeof v !== 'number' && !(v && v.constructor === Object)) return undefined;
  state.edgeInsets = true;
  const code = dartPadding(v);
  return node(code, true, code !== 'EdgeInsets.zero');
}

/** The ChartValue node of a paint option: a constant or an indexed paint. */
function paintValueNode(v, state) {
  if (typeof v === 'string') {
    const paint = paintNode(v, state);
    return paint && call('ChartValue.constant', [[null, paint]]);
  }
  if (Array.isArray(v) && v.length > 0) {
    const items = v.map((x) => paintNode(x, state));
    if (items.some((x) => x === undefined)) return undefined;
    return call('ChartValue.indexed', [[null, listNode(items)]]);
  }
  return undefined;
}

/** The ChartValue node of a number option of a point. */
function numberValueNode(v) {
  if (typeof v === 'number') return call('ChartValue.constant', [[null, doubleNode(v)]]);
  if (Array.isArray(v) && v.length > 0 && v.every((x) => typeof x === 'number')) {
    return call('ChartValue.indexed', [[null, listNode(v.map(doubleNode))]]);
  }
  return undefined;
}

/** The node of a point style name. */
function pointStyleNode(v, state) {
  if (typeof v !== 'string' || !(v in POINT_STYLES)) return undefined;
  state.pointStyles = true;
  return node(POINT_STYLES[v], true, true);
}

/** The ChartValue node of a `pointStyle` of a line dataset. */
function pointStyleValueNode(v, state) {
  const one = pointStyleNode(v, state);
  if (one) return call('ChartValue.constant', [[null, one]]);
  if (Array.isArray(v) && v.length > 0) {
    const items = v.map((x) => pointStyleNode(x, state));
    if (items.some((x) => x === undefined)) return undefined;
    return call('ChartValue.indexed', [[null, listNode(items)]]);
  }
  return undefined;
}

/** The node of an axis class `XAxis()` or `YAxis()`. */
function axisClassNode(v, state) {
  if (v !== 'x' && v !== 'y') return undefined;
  state.scaleAxes = true;
  return node(`${v.toUpperCase()}Axis()`, true, true);
}

/** The node of a fill (FillTarget, Chart.js ADR 0140). */
function fillNode(v, state) {
  let split = false;
  const code = fillTargetCode(v, (color) => {
    split = true;
    const paint = paintCode(color, state);
    if (paint === null) keepMap(`the split fill color ${color} is no color`);
    return paint;
  });
  if (code === null) return undefined;
  state.fillTargets = true;
  if (split) return node(code, false, false);
  return node(code, true, code.includes('('));
}

/** The node of a dash list (row adapt-dash-lists). */
function dashNode(v) {
  if (!Array.isArray(v) || !v.every((x) => typeof x === 'number')) return undefined;
  return listNode(v.map(doubleNode));
}

/** The node of a radius length (cutout or radius of an arc dataset). */
function radiusNode(v, state) {
  if (typeof v === 'number') {
    state.radiusLengths = true;
    return node(`PixelRadius(${nativeNumber(v)})`, true, true);
  }
  if (typeof v === 'string' && /^-?[0-9.]+%$/.test(v)) {
    state.radiusLengths = true;
    return node(`PercentRadius(${nativeNumber(parseFloat(v))})`, true, true);
  }
  return undefined;
}

/** The function types of the keys of a line segment style (nativeSegmentStyle). */
const SEGMENT_TYPES = {
  borderColor: 'ChartPaint? Function(ScriptableLineSegmentContext)',
  backgroundColor: 'ChartPaint? Function(ScriptableLineSegmentContext)',
  borderWidth: 'double? Function(ScriptableLineSegmentContext)',
  borderDash: 'List<double>? Function(ScriptableLineSegmentContext)',
  borderDashOffset: 'double? Function(ScriptableLineSegmentContext)',
  borderCapStyle: 'StrokeCap? Function(ScriptableLineSegmentContext)',
  borderJoinStyle: 'StrokeJoin? Function(ScriptableLineSegmentContext)',
};

/** The node of a line segment style (Chart.js ADR 0142). */
function segmentNode(v, state) {
  if (v === null || typeof v !== 'object' || v.constructor !== Object) return undefined;
  const args = [];
  for (const k of Object.keys(v)) {
    const name = functionName(v[k]);
    if (!SEGMENT_TYPES[k] || name === null) return undefined;
    if (k === 'borderCapStyle') (state.strokes ??= new Set()).add('StrokeCap');
    if (k === 'borderJoinStyle') (state.strokes ??= new Set()).add('StrokeJoin');
    args.push([k, node(functionCode(v[k], state, SEGMENT_TYPES[k]).code, false)]);
  }
  return call('LineSegmentStyle', args);
}

/** The Dart data class and the field writers of each dataset kind. */
function datasetSpec(kind, state, axes, paths) {
  const number = (v) => doubleNode(v);
  const paint = (v) => paintValueNode(v, state);
  const axisRef = (v) => (typeof v === 'string' && axes.has(v) ? axes.get(v) : undefined);
  const common = {
    label: (v) => stringNode(v, state),
    hidden: boolNode,
    order: (v) => (Number.isInteger(v) && !Object.is(v, -0) ? node(String(v)) : undefined),
    clip: (v) => {
      if (!isClipValue(v)) return undefined;
      state.clips = true;
      const code = dartClip(v);
      return node(code, true, code.includes('('));
    },
    backgroundColor: paint,
    borderColor: paint,
    borderWidth: number,
    hoverBackgroundColor: paint,
    hoverBorderColor: paint,
    hoverBorderWidth: number,
  };
  const cartesian = {
    xAxisID: (v) => {
      const a = axisRef(v);
      return a && ['xAxis', a];
    },
    yAxisID: (v) => {
      const a = axisRef(v);
      return a && ['yAxis', a];
    },
    stack: (v) => stringNode(v, state),
  };
  const line = {
    fill: (v) => fillNode(v, state),
    tension: number,
    borderDash: dashNode,
    borderCapStyle: (v) => (['butt', 'round', 'square'].includes(v) ? strokeNode('StrokeCap', v, state) : undefined),
    borderJoinStyle: (v) => (['miter', 'round', 'bevel'].includes(v) ? strokeNode('StrokeJoin', v, state) : undefined),
    spanGaps: boolNode,
    showLine: boolNode,
    stepped: (v) => enumNode('SteppedLine', ['before', 'after', 'middle'], v, state, 'steppedLines'),
    cubicInterpolationMode: (v) => {
      if (!(v in CUBIC_MODES)) return undefined;
      state.cubicModes = true;
      return node(CUBIC_MODES[v], true, true);
    },
    segment: (v) => segmentNode(v, state),
    pointRadius: numberValueNode,
    pointHoverRadius: numberValueNode,
    pointStyle: (v) => pointStyleValueNode(v, state),
    pointBackgroundColor: paint,
    pointBorderColor: paint,
    pointBorderWidth: number,
    pointHoverBackgroundColor: paint,
    pointHoverBorderColor: paint,
    borderDashOffset: number,
    capBezierPoints: boolNode,
    drawActiveElementsOnTop: boolNode,
    pointHitRadius: numberValueNode,
    pointHoverBorderWidth: numberValueNode,
    pointRotation: numberValueNode,
  };
  const arc = {
    offset: number,
    hoverOffset: number,
    spacing: number,
    borderAlign: (v) => enumNode('ArcBorderAlign', ['center', 'inner'], v, state, 'arcEnums'),
    borderJoinStyle: (v) => (['miter', 'round', 'bevel'].includes(v) ? strokeNode('StrokeJoin', v, state) : undefined),
    borderRadius: number,
    selfJoin: boolNode,
    spacingMode: (v) => enumNode('ArcSpacingMode', ['angular', 'proportional', 'parallel'], v, state, 'arcEnums'),
  };
  const arcMore = {
    weight: number,
    circumference: number,
    rotation: number,
    cutout: (v) => radiusNode(v, state),
    radius: (v) => radiusNode(v, state),
  };
  const indexAxis = {indexAxis: (v) => axisClassNode(v, state)};
  switch (kind) {
    case 'bar':
      return {
        cls: 'BarDataset',
        data: 'cartesian',
        fields: {
          ...common,
          ...cartesian,
          ...indexAxis,
          borderRadius: number,
          barPercentage: number,
          categoryPercentage: number,
          barThickness: (v) => {
            if (v === 'flex') return node('BarThickness.flex');
            if (typeof v !== 'number') return undefined;
            state.borderSkips = true;
            return node(`BarThickness.pixels(${nativeNumber(v)})`, true, true);
          },
          maxBarThickness: number,
          minBarLength: number,
          grouped: boolNode,
          borderSkipped: (v) => {
            if (v === false) return node('BorderSkip.none');
            if (v === true) return node('BorderSkip.all');
            return enumNode('BorderSkip', ['start', 'end', 'middle', 'bottom', 'left', 'top', 'right'], v, state);
          },
          base: number,
          inflateAmount: number,
          skipNull: boolNode,
          hoverBorderRadius: number,
          pointStyle: (v) => pointStyleNode(v, state),
        },
      };
    case 'line':
      return {cls: 'LineDataset', data: 'cartesian', fields: {...common, ...cartesian, ...indexAxis, ...line}};
    case 'scatter':
      return {cls: 'ScatterDataset', data: 'cartesian', fields: {...common, ...cartesian, ...line}};
    case 'bubble':
      return {
        cls: 'BubbleDataset',
        data: 'bubble',
        fields: {
          ...common,
          xAxisID: cartesian.xAxisID,
          yAxisID: cartesian.yAxisID,
          radius: number,
          hoverRadius: number,
          pointStyle: (v) => pointStyleNode(v, state),
          drawActiveElementsOnTop: boolNode,
        },
      };
    case 'pie':
      return {cls: 'PieDataset', data: 'numbers', fields: {...common, ...arc, ...arcMore}};
    case 'doughnut':
      return {cls: 'DoughnutDataset', data: 'numbers', fields: {...common, ...arc, ...arcMore}};
    case 'polarArea':
      return {cls: 'PolarAreaDataset', data: 'numbers', fields: {...common, ...arc, angle: number}};
    case 'radar':
      return {cls: 'RadarDataset', data: 'numbers', fields: {...common, ...line}};
    default:
      return {
        cls: 'TestDataset',
        data: 'test',
        fields: {
          label: common.label,
          hidden: boolNode,
          order: common.order,
          backgroundColor: paint,
          borderColor: paint,
          borderWidth: number,
        },
      };
  }
}

/** The node of the Flutter stroke enum value [v] of [type]. */
function strokeNode(type, v, state) {
  (state.strokes ??= new Set()).add(type);
  return node(`${type}.${v}`);
}

/** Whether [v] is a plain object of the numbers [keys] (and nothing else). */
function numberObject(v, keys, optional = []) {
  if (v === null || typeof v !== 'object' || v.constructor !== Object) return false;
  const own = Object.keys(v);
  return (
    own.every((k) => keys.includes(k) || optional.includes(k)) &&
    keys.every((k) => typeof v[k] === 'number') &&
    optional.every((k) => !(k in v) || v[k] === null || typeof v[k] === 'number')
  );
}

/**
 * The data nodes of the dataset [d] of the form [form]: `[param, node]`, or
 * undefined for data that go through `extra`. A dataset whose data a step
 * changes ([changed]: the items of the steps) keeps the form that the items
 * of the steps fit.
 */
function dataNode(form, data, changed) {
  if (!Array.isArray(data)) return undefined;
  const numbers = (items) => items.every((x) => x === null || typeof x === 'number');
  const isPoint = (x) => numberObject(x, ['x'], ['y']) && Object.keys(x).includes('y');
  if (form === 'cartesian' || form === 'test') {
    if (numbers(data) && (!changed || numbers(changed))) {
      const list = listNode(data.map(dataNumber), {mutable: true});
      return form === 'test' ? ['data', list] : ['data', call('DatasetData.values', [[null, list]])];
    }
    if (data.length > 0 && data.every(isPoint) && !changed) {
      const list = listNode(
        data.map((p) => node(`DataPoint(${num(p.x)}, ${p.y === null ? 'null' : num(p.y)})`, false, true)),
        {mutable: true},
      );
      return form === 'test' ? ['points', list] : ['data', call('DatasetData.points', [[null, list]])];
    }
    return undefined;
  }
  if (form === 'numbers') {
    if (numbers(data) && (!changed || numbers(changed))) return ['data', listNode(data.map(dataNumber), {mutable: true})];
    return undefined;
  }
  if (form === 'bubble') {
    if (data.length > 0 && data.every((x) => numberObject(x, ['x', 'y', 'r'])) && !changed) {
      return [
        'data',
        listNode(data.map((p) => node(`DataPoint.bubble(${num(p.x)}, ${num(p.y)}, ${num(p.r)})`, false, true)), {mutable: true}),
      ];
    }
    return undefined;
  }
  return undefined;
}

/**
 * Whether the typed writer keeps the key order of each dataset Map
 * (writeReference option `keyOrder`): for a test that compares the keys of
 * the dataset object in their order.
 */
let keyOrderMode = false;

/** The node of one dataset of a chart of the type [chartType]. */
function datasetNode(ds, i, chartType, state, axes, changed, chartParsing) {
  const kind = ds.type ?? chartType;
  const parsing = 'parsing' in ds ? ds.parsing : chartParsing;
  if ((kind === 'doughnut' || kind === 'pie') && parsing === false) {
    keepMap(
      'a doughnut dataset of parsing: false takes its number items as parsed ' +
        'items with the number in r (_doughnutDataItems of the controller harness)',
    );
  }
  const spec = datasetSpec(kind, state, axes);
  if (spec.cls === 'TestDataset') state.testDatasets = true;
  const args = spec.cls === 'TestDataset' ? [[null, node(`ChartKind(${dart(kind, state)})`, true, true)]] : [];
  const rest = {};
  if ('data' in ds && !Array.isArray(ds.data)) {
    keepMap(`the dataset data ${JSON.stringify(ds.data)} is no array: a typed scope holds it as a foreign value`);
  }
  // The typed node of each key, in the key order of the dataset.
  const typed = [];
  for (const k of Object.keys(ds)) {
    if (k === 'type') continue;
    if (k === 'data') {
      typed.push([k, dataNode(spec.data, ds.data, changed)]);
      continue;
    }
    const field = spec.fields[k];
    const n = field ? field(ds[k]) : undefined;
    typed.push([k, n === undefined ? undefined : Array.isArray(n) ? n : [k, n]]);
  }
  // With keyOrder, the typed keys are the longest start of the keys that the
  // lowering writes in the same order: the lowering writes its keys in the
  // order of the class (label, data, then the fields of the spec) and the
  // `extra` keys after them, so the dataset keeps the key order of the Map.
  let typedKeys = new Set(typed.filter(([, n]) => n !== undefined).map(([k]) => k));
  if (keyOrderMode) {
    const rank = ['label', 'data', ...Object.keys(spec.fields).filter((k) => k !== 'label')];
    typedKeys = new Set();
    let last = -1;
    for (const [k, n] of typed) {
      const r = rank.indexOf(k);
      if (n === undefined || r <= last) break;
      typedKeys.add(k);
      last = r;
    }
  }
  for (const [k, n] of typed) {
    if (typedKeys.has(k)) args.push(n);
    else rest[k] = ds[k];
  }
  // The data of `extra` go to the chart by reference: a new List for each
  // config, as the Map form.
  const nodes = {};
  if (Array.isArray(rest.data)) {
    nodes.data = listNode(
      rest.data.map((x) => literalNode(nativeExtra(null, x, state, 'data'), state, 'data')),
      {type: 'Object?', mutable: true},
    );
  }
  args.push(['extra', extraNode(rest, state, 'datasets', 'data.datasets[]', nodes)]);
  return call(spec.cls, args);
}

/** The Dart class of each scale type with a typed axis. */
const AXIS_CLASSES = {
  category: 'CategoryAxis',
  linear: 'LinearAxis',
  logarithmic: 'LogarithmicAxis',
  time: 'TimeAxis',
  timeseries: 'TimeSeriesAxis',
  radialLinear: 'RadialLinearAxis',
};

/**
 * The scale type and the axis of the scale [id] of [config], as
 * mergeScaleConfig gives them (core.config.js:71-87): the `type` of the
 * scale options, else the type of the default scale of the chart type.
 */
function scaleTypeOf(config, id, conf) {
  const {Chart} = loaded();
  const options = config.options ?? {};
  const datasetDefaults = Chart.defaults.datasets[config.type] ?? {};
  const datasetOptions = (options.datasets ?? {})[config.type] ?? {};
  const indexAxis = datasetOptions.indexAxis || options.indexAxis || datasetDefaults.indexAxis || 'x';
  const fromDatasets = () => {
    const bound = (config.data?.datasets ?? []).filter((d) => d.xAxisID === id || d.yAxisID === id);
    if (!bound.length) return {};
    if (bound[0].xAxisID === id) return {axis: 'x'};
    return {axis: 'y'};
  };
  const fromPosition = (p) => (p === 'top' || p === 'bottom' ? 'x' : p === 'left' || p === 'right' ? 'y' : undefined);
  let axis;
  if (id === 'x' || id === 'y' || id === 'r') {
    axis = id;
  } else {
    for (const opts of [conf, fromDatasets(), Chart.defaults.scales[conf.type] ?? {}]) {
      const first = id.length > 1 && ['x', 'y', 'r'].includes(id[0].toLowerCase()) ? id[0].toLowerCase() : undefined;
      axis = opts.axis || fromPosition(opts.position) || first;
      if (axis) break;
    }
  }
  const scales = Chart.overrides[config.type]?.scales ?? {};
  const defaultId = axis === indexAxis ? '_index_' : '_value_';
  const type = conf.type ?? scales[axis]?.type ?? scales[defaultId]?.type;
  return {axis, type};
}

/** The 14 scale hooks of Chart.js ADR 0130 (`ScaleHook`). */
const SCALE_HOOKS = [
  'beforeUpdate', 'beforeSetDimensions', 'afterSetDimensions', 'beforeDataLimits', 'afterDataLimits',
  'beforeBuildTicks', 'afterBuildTicks', 'beforeTickToLabelConversion', 'afterTickToLabelConversion',
  'beforeCalculateLabelRotation', 'afterCalculateLabelRotation', 'beforeFit', 'afterFit', 'afterUpdate',
];

/** The field writers of a scale of the class [cls]. */
function axisSpec(cls, state) {
  const number = (v) => doubleNode(v);
  const ticks = (v) => {
    if (v === null || typeof v !== 'object' || v.constructor !== Object) return undefined;
    return typedObject('AxisTicks', [], v, {
      display: boolNode,
      color: (x) => paintNode(x, state),
      font: (x) => fontNode(x, state),
      padding: number,
      stepSize: number,
      maxRotation: number,
      autoSkip: boolNode,
      align: (x) => enumNode('TickAlign', ['start', 'center', 'end', 'inner'], x, state, 'scaleEnums'),
      crossAlign: (x) => enumNode('TickCrossAlign', ['near', 'center', 'far'], x, state, 'scaleEnums'),
      source: (x) => enumNode('TickSource', ['auto', 'data', 'labels'], x, state, 'scaleEnums'),
      callback: (x) => (functionName(x) === null ? undefined : node(functionCode(x, state, 'TickCallback').code, false)),
      backdropColor: (x) => paintNode(x, state),
      backdropPadding: (x) => paddingNode(x, state),
      showLabelBackdrop: boolNode,
      textStrokeColor: (x) => paintNode(x, state),
      textStrokeWidth: number,
      z: number,
      sampleSize: number,
      autoSkipPadding: number,
      includeBounds: boolNode,
      labelOffset: number,
      minRotation: number,
      mirror: boolNode,
      maxTicksLimit: number,
      precision: number,
      count: number,
    }, state, 'ticks', 'options.scales.<id>.ticks');
  };
  const grid = (v) => {
    if (v === null || typeof v !== 'object' || v.constructor !== Object) return undefined;
    return typedObject('AxisGrid', [], v, {
      display: boolNode,
      color: (x) => paintNode(x, state),
      lineWidth: number,
      drawOnChartArea: boolNode,
      drawTicks: boolNode,
      offset: boolNode,
      tickLength: number,
      circular: boolNode,
      tickBorderDash: dashNode,
      tickBorderDashOffset: number,
      tickColor: (x) => paintNode(x, state),
      tickWidth: number,
      z: number,
    }, state, 'grid', 'options.scales.<id>.grid');
  };
  const title = (v) => {
    if (v === null || typeof v !== 'object' || v.constructor !== Object) return undefined;
    return typedObject('AxisTitle', [], v, {
      display: boolNode,
      text: (x) => (typeof x === 'string' || Array.isArray(x) ? literalNode(new DartStringList((Array.isArray(x) ? x : [x]).map(String)), state, 'title') : undefined),
      color: (x) => paintNode(x, state),
      font: (x) => fontNode(x, state),
      align: (x) => enumNode('ChartAlign', ['start', 'center', 'end'], x, state, 'aligns'),
      padding: (x) => paddingNode(x, state),
      strokeColor: (x) => paintNode(x, state),
      strokeWidth: number,
    }, state, 'title', 'options.scales.<id>.title');
  };
  const head = {
    display: scaleDisplayNode,
    position: (v) => enumNode('ChartPosition', ['top', 'left', 'bottom', 'right', 'center', 'chartArea'], v, state, 'positions'),
    reverse: boolNode,
    stacked: (v) => {
      if (v === true) return node('StackMode.on');
      if (v === false) return node('StackMode.off');
      if (v === 'single') return node('StackMode.single');
      return undefined;
    },
    ticks,
    grid,
    title,
    alignToPixels: boolNode,
    backgroundColor: (v) => paintNode(v, state),
    clip: boolNode,
    weight: number,
    ...Object.fromEntries(SCALE_HOOKS.map((h) => [h, (x) => (functionName(x) === null ? undefined : node(functionCode(x, state, 'ScaleHook').code, false))])),
  };
  const cartesian = {offset: boolNode, stack: (v) => stringNode(v, state), stackWeight: number};
  const grace = (v) => {
    const length = lengthValue('grace', v);
    return length ? literalNode(length, state, 'grace') : undefined;
  };
  const border = (radial) => (v) => {
    if (v === null || typeof v !== 'object' || v.constructor !== Object) return undefined;
    const code = literalNode(new DartBorder(v, radial), state, 'border');
    return code;
  };
  const bounds = (v) => enumNode('ScaleBounds', ['data', 'ticks'], v, state, 'scaleEnums');
  const range = {min: number, max: number, suggestedMin: number, suggestedMax: number};
  switch (cls) {
    case 'CategoryAxis':
      return {
        ...head,
        labels: (v) => (Array.isArray(v) && v.every((x) => typeof x === 'string') ? listNode(v.map((x) => node(dart(x, state))), {mutable: true}) : undefined),
        min: (v) => stringNode(v, state),
        max: (v) => stringNode(v, state),
        bounds,
        border: border(false),
        ...cartesian,
      };
    case 'LinearAxis':
      return {...head, ...range, beginAtZero: boolNode, bounds, border: border(false), ...cartesian, grace};
    case 'LogarithmicAxis':
      return {...head, ...range, bounds, border: border(false), ...cartesian};
    case 'TimeAxis':
    case 'TimeSeriesAxis':
      return {...head, offsetAfterAutoskip: boolNode, bounds, border: border(false), ...cartesian};
    case 'RadialLinearAxis':
      return {...head, ...range, beginAtZero: boolNode, startAngle: number, border: border(true), grace};
    default:
      throw new Error(`No axis class ${cls}`);
  }
}

/** The node of the scale [id] with the options [conf] of the class [cls] on [axis]. */
function axisNode(cls, axis, conf, state, id) {
  const spec = axisSpec(cls, state);
  const path = 'options.scales.<id>';
  const positional = cls === 'RadialLinearAxis' ? [] : [node(`.${axis}`)];
  const args = positional.map((n) => [null, n]);
  const rest = {};
  for (const k of Object.keys(conf)) {
    if (k === 'type') continue;
    if (k === 'axis' && conf.axis === axis) continue;
    if (k === 'time' && (cls === 'TimeAxis' || cls === 'TimeSeriesAxis') && conf.time && conf.time.constructor === Object) {
      const timeRest = {};
      for (const t of Object.keys(conf.time)) {
        const v = conf.time[t];
        if (t === 'unit' && TIME_UNIT_NAMES.has(v)) {
          state.timeUnits = true;
          args.push(['unit', node(`TimeUnit.${v}`)]);
        } else if (t === 'tooltipFormat' && typeof v === 'string') {
          args.push(['tooltipFormat', node(dart(v, state))]);
        } else if (t === 'parser' && typeof v === 'string') {
          args.push(['parser', node(dart(v, state))]);
        } else if ((t === 'round' || t === 'minUnit') && TIME_UNIT_NAMES.has(v)) {
          state.timeUnits = true;
          args.push([t, node(`TimeUnit.${v}`)]);
        } else if (t === 'isoWeekday' && (v === true || Number.isInteger(v))) {
          args.push(['isoWeekday', node(String(v === true ? 1 : v))]);
        } else if (t === 'displayFormats' && v && v.constructor === Object && Object.values(v).every((x) => typeof x === 'string')) {
          args.push(['displayFormats', call('TimeDisplayFormats', Object.keys(v).map((u) => [u, node(dart(v[u], state))]))]);
        } else {
          timeRest[t] = v;
        }
      }
      for (const t of Object.keys(timeRest)) noteExtra(`${path}.time.${t}`);
      if (Object.keys(timeRest).length) rest.time = timeRest;
      continue;
    }
    if (cls === 'RadialLinearAxis' && (k === 'pointLabels' || k === 'angleLines') && conf[k] && conf[k].constructor === Object) {
      const sub = conf[k];
      const subRest = {};
      const prefix = k === 'pointLabels' ? 'pointLabels' : 'angleLines';
      const subSpec = k === 'pointLabels'
        ? {
            display: scaleDisplayNode,
            color: (x) => paintNode(x, state),
            font: (x) => fontNode(x, state),
            padding: doubleNode,
            callback: (x) => (functionName(x) === null ? undefined : node(functionCode(x, state, 'PointLabelCallback').code, false)),
          }
        : {display: boolNode, color: (x) => paintNode(x, state), lineWidth: doubleNode};
      for (const s of Object.keys(sub)) {
        const n = subSpec[s] ? subSpec[s](sub[s]) : undefined;
        if (n === undefined) subRest[s] = sub[s];
        else args.push([`${prefix}${s[0].toUpperCase()}${s.slice(1)}`, n]);
      }
      for (const t of Object.keys(subRest)) noteExtra(`${path}.${k}.${t}`);
      if (Object.keys(subRest).length) rest[k] = subRest;
      continue;
    }
    const n = spec[k] ? spec[k](conf[k]) : undefined;
    if (n === undefined) rest[k] = conf[k];
    else args.push([k, n]);
  }
  args.push(['extra', extraNode(rest, state, id, path)]);
  return call(cls, args);
}

/** The Dart class of the plugin of each id of src/plugins/index.js. */
const PLUGIN_CLASSES = {
  colors: 'ColorsPlugin',
  decimation: 'DecimationPlugin',
  filler: 'FillerPlugin',
  legend: 'LegendPlugin',
  subtitle: 'SubtitlePlugin',
  title: 'TitlePlugin',
  tooltip: 'TooltipPlugin',
};

/** The node of the options of the config [o] (the keys of `options`). */
function optionsArgs(config, o, state, axes) {
  const args = [];
  const rest = {};
  const pluginOptions = [];
  const disabled = [];
  const pluginRest = {};
  for (const k of Object.keys(o)) {
    const v = o[k];
    let n;
    switch (k) {
      case 'scales':
        continue;
      case 'indexAxis':
        n = axisClassNode(v, state);
        break;
      case 'parsing':
      case 'responsive':
      case 'maintainAspectRatio':
      case 'normalized':
        n = boolNode(v);
        break;
      case 'color':
        n = paintNode(v, state);
        break;
      case 'aspectRatio':
      case 'devicePixelRatio':
        n = doubleNode(v);
        break;
      case 'layout':
        if (v && v.constructor === Object && 'padding' in v) {
          const padding = paddingNode(v.padding, state);
          if (padding) {
            args.push(['padding', padding]);
            const {padding: _padding, ...layoutRest} = v;
            if (Object.keys(layoutRest).length) rest.layout = layoutRest;
            continue;
          }
        }
        break;
      case 'interaction':
        if (v && v.constructor === Object) {
          n = typedObject('ChartInteraction', [], v, {
            mode: (x) => (typeof x === 'string' ? literalNode(new DartMode(x), state, 'interaction') : undefined),
            intersect: boolNode,
            axis: (x) => (typeof x === 'string' ? literalNode(new DartAxis(x), state, 'interaction') : undefined),
            includeInvisible: boolNode,
          }, state, 'interaction', 'options.interaction');
        }
        break;
      case 'animation':
        if (v === false) {
          n = node('ChartAnimation.none');
        } else if (v && v.constructor === Object) {
          const ms = (x) =>
            x === 0 ? node('Duration.zero') : Number.isInteger(x) && x > 0 ? node(`Duration(milliseconds: ${x})`, true, true) : undefined;
          n = typedObject('ChartAnimation', [], v, {
            duration: ms,
            delay: ms,
            loop: boolNode,
            animateScale: boolNode,
            animateRotate: boolNode,
          }, state, 'animation', 'options.animation');
        }
        break;
      case 'elements':
        if (v && v.constructor === Object) n = elementsNode(v, state);
        break;
      case 'events':
        if (Array.isArray(v) && v.every((x) => typeof x === 'string')) {
          n = listNode(v.map((x) => node(dart(x, state))));
        }
        break;
      case 'plugins':
        if (v && v.constructor === Object) {
          for (const id of Object.keys(v)) {
            const x = v[id];
            if (x === false && id in PLUGIN_CLASSES) {
              disabled.push(node(`PluginOff<${PLUGIN_CLASSES[id]}>()`, true, true));
              continue;
            }
            const wrapped = keyedValue(id, x, 'plugins');
            if (wrapped !== x) {
              state.typedConfigs = true;
              pluginOptions.push(literalNode(wrapped, state, id));
              continue;
            }
            pluginRest[id] = x;
          }
          if (Object.keys(pluginRest).length) rest.plugins = pluginRest;
          continue;
        }
        break;
      default:
        break;
    }
    if (n === undefined) rest[k] = v;
    else args.push([k, n]);
  }
  if (pluginOptions.length) args.push(['pluginOptions', listNode(pluginOptions)]);
  if (disabled.length) args.push(['disabledPlugins', listNode(disabled)]);
  return {args, rest};
}

/** The node of `options.elements`. */
function elementsNode(v, state) {
  const paint = (x) => paintNode(x, state);
  const number = doubleNode;
  const specs = {
    point: ['PointElementStyle', {
      radius: number,
      pointStyle: (x) => pointStyleNode(x, state),
      backgroundColor: paint,
      borderColor: paint,
      borderWidth: number,
      hitRadius: number,
      hoverRadius: number,
      rotation: number,
      hoverBackgroundColor: paint,
      hoverBorderColor: paint,
      hoverBorderWidth: number,
      drawActiveElementsOnTop: boolNode,
    }],
    line: ['LineElementStyle', {
      tension: number,
      backgroundColor: paint,
      borderColor: paint,
      borderWidth: number,
      borderDash: dashNode,
      fill: (x) => fillNode(x, state),
      stepped: (x) => enumNode('SteppedLine', ['before', 'after', 'middle'], x, state, 'steppedLines'),
      borderDashOffset: number,
      capBezierPoints: boolNode,
    }],
    bar: ['BarElementStyle', {
      backgroundColor: paint,
      borderColor: paint,
      borderWidth: number,
      borderRadius: number,
      inflateAmount: number,
    }],
    arc: ['ArcElementStyle', {
      backgroundColor: paint,
      borderColor: paint,
      borderWidth: number,
      offset: number,
      spacing: number,
      borderAlign: (x) => enumNode('ArcBorderAlign', ['center', 'inner'], x, state, 'arcEnums'),
      spacingMode: (x) => enumNode('ArcSpacingMode', ['angular', 'proportional', 'parallel'], x, state, 'arcEnums'),
      borderDash: dashNode,
      borderDashOffset: number,
      borderJoinStyle: (x) => (['miter', 'round', 'bevel'].includes(x) ? strokeNode('StrokeJoin', x, state) : undefined),
      selfJoin: boolNode,
      circular: boolNode,
      angle: number,
    }],
  };
  const args = [];
  const rest = {};
  for (const k of Object.keys(v)) {
    const spec = specs[k];
    if (spec && v[k] && v[k].constructor === Object) {
      args.push([k, typedObject(spec[0], [], v[k], spec[1], state, k, `options.elements.${k}`)]);
    } else {
      rest[k] = v[k];
    }
  }
  args.push(['extra', extraNode(rest, state, 'elements', 'options.elements')]);
  return call('ChartElements', args);
}

/** The items of the steps of [expected] that a `push` or a `splice` puts into each dataset. */
function changedData(expected) {
  const changed = new Map();
  for (const step of expected?.steps ?? []) {
    const [action, d, ...args] = step.do ?? [];
    let items = null;
    if (action === 'push') items = args;
    if (action === 'splice') items = args.slice(2);
    if (items) changed.set(d, [...(changed.get(d) ?? []), ...items]);
  }
  return changed;
}

/**
 * The Dart code of the config of the case [c] as a typed config (Chart.js ADR
 * 0052): a function `() => ChartConfig(...)` that makes new data Lists at
 * each call, as `copyReference` makes new Maps. Dart `null` for a config
 * that keeps its Map form; the reason goes into the report.
 */
function typedConfigCode(c, state, file) {
  const config = c.config;
  caseExtras = new Set();
  const before = {...state, strokes: state.strokes && new Set(state.strokes)};
  const beforeBorders = borderObjects;
  borderObjects = true;
  try {
    const code = typedConfig(config, state, c);
    for (const path of caseExtras) typedReport.extra.set(path, (typedReport.extra.get(path) ?? 0) + 1);
    return code;
  } catch (e) {
    if (!(e instanceof KeepMap)) throw e;
    for (const k of Object.keys(state)) delete state[k];
    Object.assign(state, before);
    typedReport.maps.push({file, name: c.name, reason: e.message});
    return null;
  } finally {
    caseExtras = null;
    borderObjects = beforeBorders;
  }
}

/** The typed config code of [config] (typedConfigCode). */
function typedConfig(config, state, c) {
  if (config === null || typeof config !== 'object') keepMap('the config is not an object');
  for (const k of Object.keys(config)) {
    if (!['type', 'data', 'options', 'plugins'].includes(k)) keepMap(`the config key ${k} has no typed form`);
  }
  if (typeof config.type !== 'string') keepMap('the config has no chart type: a typed config takes it from its first dataset');
  const data = config.data ?? {};
  for (const k of Object.keys(data)) {
    if (k !== 'labels' && k !== 'datasets') keepMap(`data.${k} has no typed form`);
  }
  const datasets = data.datasets ?? [];
  if (!Array.isArray(datasets) || datasets.length === 0) keepMap('a typed config needs one dataset at least');
  const first = datasets[0]?.type ?? config.type;
  if (first !== config.type) keepMap(`the chart type ${config.type} differs from the type ${first} of the first dataset`);
  const args = [];
  if ('labels' in data) {
    const labels = data.labels;
    if (!Array.isArray(labels)) keepMap('data.labels is not an array');
    if (labels.some((x) => x === null || x === undefined)) keepMap('data.labels has an item null or undefined: the typed labels are a List<Object>');
    args.push([
      'labels',
      listNode(
        labels.map((x) => (typeof x === 'number' ? node(num(x)) : Array.isArray(x) ? literalNode(x, state, 'labels') : node(dart(x, state)))),
        {mutable: true},
      ),
    ]);
  }
  // The typed axes: the scales of `options.scales` in their order while the
  // id of each is the id of the typed lowering (scaleIdsOf of lower.dart).
  const options = config.options ?? {};
  const axes = new Map();
  const axisNodes = [];
  const scaleRest = {};
  if (options.scales && options.scales.constructor === Object) {
    const counts = {};
    const codes = new Set();
    let typed = true;
    for (const id of Object.keys(options.scales)) {
      const conf = options.scales[id];
      let n;
      if (typed && conf && conf.constructor === Object) {
        const {axis, type} = scaleTypeOf(config, id, conf);
        const cls = AXIS_CLASSES[type];
        const letter = axis;
        const count = counts[letter] ?? 0;
        const expectedId = count === 0 ? letter : `${letter}${count}`;
        if (cls && ['x', 'y', 'r'].includes(axis) && (cls === 'RadialLinearAxis') === (axis === 'r') && expectedId === id) {
          n = axisNode(cls, axis, conf, state, id);
          if (codes.has(n.code)) n = undefined;
          else {
            codes.add(n.code);
            counts[letter] = count + 1;
          }
        }
      }
      if (n === undefined) {
        typed = false;
        scaleRest[id] = conf;
      } else {
        axes.set(id, n);
        axisNodes.push(n);
      }
    }
  }
  const changed = changedData(c.expected);
  args.push([
    'datasets',
    listNode(datasets.map((ds, i) => datasetNode(ds, i, config.type, state, axes, changed.get(i), options.parsing))),
  ]);
  if (axisNodes.length || ('scales' in options && Object.keys(scaleRest).length === 0)) {
    args.push(['scales', listNode(axisNodes)]);
  }
  const {args: optionArgs, rest} = optionsArgs(config, options, state, axes);
  args.push(...optionArgs);
  if (Object.keys(scaleRest).length) rest.scales = scaleRest;
  if (config.plugins !== undefined) {
    if (!Array.isArray(config.plugins)) keepMap('the config plugins are not an array');
    state.nativePlugins = true;
    const plugins = config.plugins.map((p) => {
      const entries = Object.keys(p).map((k) => `${dart(k, state)}: ${typeof p[k] === 'function' ? functionCode(p[k], state).code : dart(p[k], state)}`);
      return node(`nativePlugin(<String, Object?>{${entries.join(', ')}})`, false, false);
    });
    args.push(['plugins', listNode(plugins)]);
  }
  args.push(['extra', extraNode(rest, state, 'options', 'options')]);
  state.typedConfigs = true;
  state.closures = true;
  const root = call('ChartConfig', args);
  return `() => ${inner(root, false)}`;
}
