// Original code, not ported from Chart.js: light theme reference generator.
//
// It writes test/port/theme/light_reference.dart, the data of
// test/port/theme/presets_test.dart: the upstream values that the phase 5
// part of the light preset restates (theming.md sections 4 and 9), and the
// options that the upstream resolver gives without a theme for the four
// elements, a scale and the chart level, with the Node.js version, V8
// version and architecture in the header. The cases are fixed, so a rerun on
// the same Node.js writes the same file. Nothing in lib/ or test/ runs this
// script (porting-flow.md section 4).
//
// The script runs the pinned upstream sources with the type stripping of
// Node.js: src/core/core.defaults.js (with core.scale.defaults.js),
// src/core/core.registry.js, src/elements/index.js, src/core/core.config.js
// and src/helpers/helpers.options.ts. A resolve hook maps the upstream
// `./x.js` imports to the `.ts` files, and `@kurkle/color` to
// third_party/kurkle-color/src/index.esm.js. `registry.addElements` registers
// the four element classes, as the chart registers them: their defaults go to
// `defaults.elements.<id>`, with the routes of `defaultRoutes`
// (core.typedRegistry.js:84-113). Check out the submodules first
// (`dart run melos run upstream`).
//
// The element cases resolve the options of an element of a dataset as
// `_resolveElementOptions` does (core.datasetController.js:804-835): the
// scopes of `datasetElementScopeKeys`, the keys of `defaults.elements.<id>`
// as the names, and the prefixes of the modes 'default' and 'active'. The
// scale case resolves the scale `x` of the type `tlin`, a type without
// defaults, through `chartOptionScopes`, as `buildOrUpdateScales` and
// `Scale.init` do (core.controller.js:327-397, core.scale.js:231). Its fonts
// are the `toFont` results of `_resolveTickFontOptions` (core.scale.js:1700)
// and of `getTitleHeight` (core.scale.js:100, 646).
//
// Usage, from packages/flutter_chartjs, with an x64 build of Node.js v24.12.0
// (on Apple silicon, the darwin-x64 build runs under Rosetta) and with the
// Dart SDK on the PATH (the script formats the output with `dart format`):
//
//   node tool/reference/theme_light_reference.mjs
//
// The reference is V8 13.6 on x64 (Chart.js ADR 0010), and the script stops
// on any other architecture.

import {execFileSync} from 'node:child_process';
import {existsSync, writeFileSync} from 'node:fs';
import {registerHooks} from 'node:module';
import {fileURLToPath} from 'node:url';

if (process.arch !== 'x64') {
  console.error(
    `The reference is V8 on x64; this Node.js is ${process.arch}. ` +
      'Run an x64 build of Node.js.',
  );
  process.exit(1);
}

const THIRD_PARTY = new URL('../../../../third_party/', import.meta.url);
const SRC = new URL('Chart.js/src/', THIRD_PARTY);
const DEFAULTS = new URL('core/core.defaults.js', SRC);
const REGISTRY = new URL('core/core.registry.js', SRC);
const ELEMENTS = new URL('elements/index.js', SRC);
const CONFIG = new URL('core/core.config.js', SRC);
const OPTIONS = new URL('helpers/helpers.options.ts', SRC);
const KURKLE = new URL('kurkle-color/src/index.esm.js', THIRD_PARTY);
const OUT = fileURLToPath(
  new URL('../../test/port/theme/light_reference.dart', import.meta.url),
);

for (const url of [DEFAULTS, REGISTRY, ELEMENTS, CONFIG, OPTIONS, KURKLE]) {
  if (!existsSync(fileURLToPath(url))) {
    console.error(
      `${fileURLToPath(url)} is missing. ` +
        'Check out the submodules with `dart run melos run upstream`.',
    );
    process.exit(1);
  }
}

registerHooks({
  resolve(specifier, context, nextResolve) {
    if (
      specifier === '@kurkle/color' &&
      context.parentURL?.includes('/third_party/Chart.js/')
    ) {
      return nextResolve(KURKLE.href, context);
    }
    // The upstream sources import `../helpers/helpers.core.js` and the other
    // modules with a `.js` suffix; most files on disk are `.ts`.
    if (
      specifier.endsWith('.js') &&
      context.parentURL?.includes('/third_party/Chart.js/')
    ) {
      const js = new URL(specifier, context.parentURL);
      const ts = new URL(specifier.replace(/\.js$/, '.ts'), context.parentURL);
      if (!existsSync(fileURLToPath(js)) && existsSync(fileURLToPath(ts))) {
        return nextResolve(ts.href, context);
      }
    }
    return nextResolve(specifier, context);
  },
});

const {default: defaults} = await import(DEFAULTS.href);
const {default: registry} = await import(REGISTRY.href);
const elements = await import(ELEMENTS.href);
const {default: Config} = await import(CONFIG.href);
const {toFont} = await import(OPTIONS.href);

// The module namespace object has no prototype, so registry.addElements
// cannot take it as one object.
registry.addElements(...Object.values(elements));

/** The value of the dot path [path] in [root]. */
const at = (root, path) =>
  path.split('.').reduce((node, key) => node[key], root);

// The keys that the phase 5 part of the light preset emits (theming.md
// section 4), each with the upstream key that it restates. A font restates
// the global defaults.font: toFont reads it for an absent font
// (helpers.options.ts:115-117).
const RESTATED = [
  ['color', 'color'],
  ['scale.ticks.color', 'scale.ticks.color'],
  ['scale.title.color', 'scale.title.color'],
  ['scale.grid.color', 'scale.grid.color'],
  ['scale.border.color', 'scale.border.color'],
  ['scale.ticks.backdropColor', 'scale.ticks.backdropColor'],
  ['scale.ticks.font', 'font'],
  ['scale.title.font', 'font'],
  ['elements.point.borderColor', 'elements.point.borderColor'],
  ['elements.point.backgroundColor', 'elements.point.backgroundColor'],
  ['elements.line.borderColor', 'elements.line.borderColor'],
  ['elements.line.backgroundColor', 'elements.line.backgroundColor'],
  ['elements.bar.borderColor', 'elements.bar.borderColor'],
  ['elements.bar.backgroundColor', 'elements.bar.backgroundColor'],
  ['elements.arc.backgroundColor', 'elements.arc.backgroundColor'],
  ['elements.arc.borderColor', 'elements.arc.borderColor'],
];
const restated = Object.fromEntries(
  RESTATED.map(([path, source]) => [path, structuredClone(at(defaults, source))]),
);

// The element options, as _resolveElementOptions resolves them.
const elementCases = [];
for (const type of ['point', 'line', 'bar', 'arc']) {
  for (const mode of ['default', 'active']) {
    const config = new Config({
      type: 'tthm',
      data: {datasets: [{data: []}]},
      options: {},
    });
    const dataset = config.data.datasets[0];
    const scopes = config.getOptionScopes(
      dataset,
      config.datasetElementScopeKeys('tthm', type),
    );
    const names = Object.keys(defaults.elements[type]);
    const prefixes =
      mode === 'active' ? [`${type}Hover`, 'hover', type, ''] : [type, ''];
    const options = config.resolveNamedOptions(
      scopes,
      names,
      () => ({active: mode === 'active', mode}),
      prefixes,
    );
    elementCases.push({type, mode, names, prefixes, options: {...options}});
  }
}

/** The fields of a toFont result, in the order of helpers.options.ts:131. */
const fontFields = (font) => ({
  family: font.family,
  lineHeight: font.lineHeight,
  size: font.size,
  style: font.style,
  weight: font.weight,
  string: font.string,
});

// The scale options of a scale `x` of the type `tlin`, and the chart color.
const scaleConfig = new Config({
  type: 'tthm',
  data: {datasets: [{data: []}]},
  options: {scales: {x: {type: 'tlin'}}},
});
const chartOptions = scaleConfig.createResolver(
  scaleConfig.chartOptionScopes(),
  {chart: {}},
);
const x = chartOptions.scales.x;
const scale = {
  'ticks.color': x.ticks.color,
  'ticks.backdropColor': x.ticks.backdropColor,
  'title.color': x.title.color,
  'grid.color': x.grid.color,
  'grid.tickColor': x.grid.tickColor,
  'border.color': x.border.color,
  'ticks.font': fontFields(toFont(x.ticks.font)),
  'title.font': fontFields(toFont(x.title.font, chartOptions.font)),
};
const chartColor = chartOptions.color;

function num(v) {
  if (Number.isNaN(v)) return 'double.nan';
  if (v === Infinity) return 'double.infinity';
  if (v === -Infinity) return 'double.negativeInfinity';
  if (Object.is(v, -0)) return '-0.0';
  return Number.isInteger(v) ? `${v}.0` : String(v);
}

/** The Dart literal of a JS value. */
function dart(v) {
  if (v === null) return 'null';
  if (v === undefined) return 'undefined';
  if (typeof v === 'number') return num(v);
  if (typeof v === 'boolean') return String(v);
  if (typeof v === 'function') throw new Error(`A function: ${String(v)}`);
  if (typeof v === 'string') {
    // Single quotes, or double quotes for a string with a single quote
    // (prefer_single_quotes, avoid_escaping_inner_quotes).
    const quote = v.includes("'") && !v.includes('"') ? '"' : "'";
    // A raw string for a `$` or a backslash (use_raw_strings).
    if (/[\\$]/.test(v) && !v.includes(quote)) return `r${quote}${v}${quote}`;
    const escaped = v.replace(/[\\$]/g, '\\$&').replaceAll(quote, `\\${quote}`);
    return `${quote}${escaped}${quote}`;
  }
  if (Array.isArray(v)) return `<Object?>[${v.map(dart).join(', ')}]`;
  if (typeof v === 'object') {
    const entries = Object.keys(v).map((k) => `${dart(k)}: ${dart(v[k])}`);
    return `<String, Object?>{${entries.join(', ')}}`;
  }
  throw new Error(`No Dart literal for ${String(v)}`);
}

const elementBody = elementCases
  .map(
    (c) =>
      `  (type: ${dart(c.type)}, mode: ${dart(c.mode)}, ` +
      `names: <String>[${c.names.map(dart).join(', ')}], ` +
      `prefixes: <String>[${c.prefixes.map(dart).join(', ')}], ` +
      `options: ${dart(c.options)}),\n`,
  )
  .join('');

const data = `${dart(restated)}${elementBody}${dart(scale)}`;
const usesUndefined = /\bundefined\b/.test(data);

const out = `// Original code, not ported from Chart.js: light theme reference data.

// Generated by tool/reference/theme_light_reference.mjs. Do not edit.
// Node.js ${process.version} (${process.platform}-${process.arch}), V8 ${process.versions.v8}:
// src/core/core.defaults.js, src/core/core.config.js and the four elements
// at the pinned Chart.js, with the elements registered.
// ${elementCases.length} element cases.
${usesUndefined ? "\nimport 'package:flutter_chartjs/src/js/js_undefined.dart';\n" : ''}
/// The Node.js version that generated the data.
const String themeLightReferenceNode = '${process.version}';

/// The V8 version that generated the data.
const String themeLightReferenceV8 = '${process.versions.v8}';

/// The architecture of the Node.js build that generated the data.
const String themeLightReferenceArch = '${process.arch}';

/// The upstream value of each key that the phase 5 part of the light preset
/// emits (theming.md section 4), by the dot path of the key. A font key
/// restates the global \`defaults.font\`.
const Map<String, Object?> themeLightRestated = ${dart(restated)};

/// One element case: the options that the upstream resolver gives without a
/// theme for an element of the type \`type\` in a dataset of the chart type
/// \`tthm\`, in the mode \`mode\`, with the names \`names\` and the prefixes
/// \`prefixes\`. The \`options\` hold \`$shared\` first.
typedef ThemeLightElementCase = ({
  String type,
  String mode,
  List<String> names,
  List<String> prefixes,
  Map<String, Object?> options,
});

/// The element cases: the four elements in the modes 'default' and 'active'.
const List<ThemeLightElementCase> themeLightElements = [
${elementBody}];

/// The options of the scale \`x\` of the type \`tlin\` without a theme, by the
/// dot path of the key. A font is the \`toFont\` result.
const Map<String, Object?> themeLightScale = ${dart(scale)};

/// The chart-level \`color\` without a theme.
const ${typeof chartColor === 'string' ? 'String' : 'Object?'} themeLightChartColor = ${dart(chartColor)};
`;

writeFileSync(OUT, out);
execFileSync('dart', ['format', OUT], {stdio: 'inherit'});
console.log(`Wrote ${elementCases.length} element cases to ${OUT}`);
