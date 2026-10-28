// Original code, not ported from Chart.js: core.layouts reference generator.
//
// It writes test/port/core/layouts_reference.dart, the data of
// test/port/core/core.layouts_test.dart: scenes of fake charts with fake
// boxes, the calls that `layouts.update` makes on the boxes in order, the
// box sizes and positions, the chart area, the box order, and the Node.js
// version, V8 version and architecture in the header. The scenes are fixed,
// so a rerun on the same Node.js writes the same file. Nothing in lib/ or
// test/ runs this script (porting-flow.md section 4).
//
// The script runs the pinned upstream source
// third_party/Chart.js/src/core/core.layouts.js with the type stripping of
// Node.js. A resolve hook maps the upstream `./x.js` imports to the `.ts`
// files, and `@kurkle/color` to third_party/kurkle-color/src/index.esm.js
// (helpers.options.ts imports helpers.core.ts, and the helpers reach
// helpers.color.ts). Each scene calls `layouts.configure` and `layouts.addBox` for each
// box, as `buildOrUpdateScales` does (core.controller.js:377-378), then
// `layouts.update`. A scene with `reconfigure` calls `layouts.configure` a
// second time after `layouts.addBox`, as the legend and the title do in
// `beforeUpdate` (plugin.legend.js:603-604, :617, plugin.title.js:115-116,
// :141). Then `addBox` does not normalize the weight. A fake box has the members that core.layouts.js reads.
// Its `update` sets its width and height from the given size with a fixed
// rule, as a scale does. Check out the submodules first
// (`dart run melos run upstream`).
//
// Usage, from packages/flutter_chartjs_port, with an x64 build of Node.js v24.12.0
// (on Apple silicon, the darwin-x64 build runs under Rosetta) and with the
// Dart SDK on the PATH (the script formats the output with `dart format`):
//
//   node tool/reference/layouts_reference.mjs
//
// The reference is V8 13.6 on x64 (Chart.js ADR 0032). The script does not
// stop on another architecture.

import {execFileSync} from 'node:child_process';
import {existsSync, writeFileSync} from 'node:fs';
import {registerHooks} from 'node:module';
import {fileURLToPath} from 'node:url';

const THIRD_PARTY = new URL('../../../../third_party/', import.meta.url);
const SOURCE = new URL('Chart.js/src/core/core.layouts.js', THIRD_PARTY);
const KURKLE = new URL('kurkle-color/src/index.esm.js', THIRD_PARTY);
const OUT = fileURLToPath(
  new URL('../../test/port/core/layouts_reference.dart', import.meta.url),
);

for (const url of [SOURCE, KURKLE]) {
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

const {default: layouts} = await import(SOURCE.href);

/** The calls of the current scene, in order. */
let log = [];

/**
 * A fake box of [spec]. Its `update` sets the width to the given width and
 * the height from the rule `[at, thick, thin]`: `thick` below the width
 * `at`, else `thin`. A vertical box swaps the roles. `getPadding` and
 * `beforeLayout` exist when the spec has them.
 */
function box(spec) {
  const b = {
    $name: spec.name,
    options: spec.options,
    axis: spec.axis,
    isHorizontal() {
      return spec.horizontal;
    },
    update(maxWidth, maxHeight, margins) {
      log.push([
        'update',
        spec.name,
        [maxWidth, maxHeight, margins.left, margins.top, margins.right, margins.bottom],
      ]);
      const [at, thick, thin] = spec.size;
      if (spec.horizontal) {
        this.width = maxWidth;
        this.height = maxWidth < at ? thick : thin;
      } else {
        this.height = maxHeight;
        this.width = maxHeight < at ? thick : thin;
      }
    },
    draw(chartArea) {
      log.push(['draw', spec.name, [chartArea.left, chartArea.top]]);
    },
  };
  if (spec.padding) {
    const [left, top, right, bottom] = spec.padding;
    b.getPadding = () => ({left, top, right, bottom});
  }
  if (spec.beforeLayout) {
    b.beforeLayout = () => log.push(['beforeLayout', spec.name, []]);
  }
  return b;
}

/** The configure options of [spec]: its present keys only. */
function configureOptions(spec) {
  const options = {};
  for (const key of ['fullSize', 'position', 'weight']) {
    if (spec[key] !== undefined) options[key] = spec[key];
  }
  return options;
}

const scenes = [];

/** Adds the scene [name] and runs the layout. */
function addScene(
  name,
  {padding = 0, width, height, minPadding = 0, reconfigure = false, boxes},
) {
  log = [];
  const chart = {options: {layout: {padding}}, boxes: []};
  const made = boxes.map((spec) => {
    const b = box(spec);
    layouts.configure(chart, b, configureOptions(spec));
    layouts.addBox(chart, b);
    return b;
  });
  if (reconfigure) {
    made.forEach((b, i) => layouts.configure(chart, b, configureOptions(boxes[i])));
  }
  let error = null;
  try {
    layouts.update(chart, width, height, minPadding);
  } catch (e) {
    error = e.constructor.name;
  }
  scenes.push({
    name,
    padding,
    width,
    height,
    minPadding,
    reconfigure,
    boxes,
    error,
    log,
    results: made.map((b) => ({
      name: b.$name,
      left: b.left,
      top: b.top,
      right: b.right,
      bottom: b.bottom,
      width: b.width,
      height: b.height,
      fullSize: b.fullSize,
      position: b.position,
      weight: b.weight,
    })),
    chartArea: error === null ? chart.chartArea : null,
    order: chart.boxes.map((b) => b.$name),
  });
}

/** A scale on the axis [axis] at [position]. */
function scale(name, position, axis, extra = {}) {
  const horizontal = position === 'top' || position === 'bottom';
  return {
    name,
    position,
    axis,
    horizontal,
    options: {display: true},
    size: horizontal ? [300, 40, 25] : [200, 45, 30],
    padding: [0, 0, 0, 0],
    beforeLayout: true,
    ...extra,
  };
}

/** A legend or title box. */
function block(name, position, weight, extra = {}) {
  const horizontal = position === 'top' || position === 'bottom';
  return {
    name,
    position,
    weight,
    fullSize: true,
    horizontal,
    options: {},
    size: horizontal ? [0, 32, 32] : [0, 80, 80],
    padding: null,
    beforeLayout: false,
    ...extra,
  };
}

addScene('two scales', {
  width: 250,
  height: 150,
  boxes: [scale('x', 'bottom', 'x'), scale('y', 'left', 'y')],
});

addScene('scales at the top and the right', {
  width: 250,
  height: 150,
  boxes: [scale('x', 'top', 'x'), scale('y', 'right', 'y')],
});

addScene('a legend and two scales', {
  width: 512,
  height: 512,
  boxes: [scale('x', 'bottom', 'x'), scale('y', 'left', 'y'), block('legend', 'top', 1000)],
});

addScene('weights', {
  width: 512,
  height: 400,
  boxes: [
    scale('x0', 'top', 'x', {weight: 1}),
    scale('x1', 'top', 'x', {weight: 2}),
    scale('x2', 'top', 'x'),
    scale('x3', 'bottom', 'x', {weight: 1}),
    scale('x4', 'bottom', 'x', {weight: 2}),
    scale('y0', 'left', 'y', {weight: 1}),
    scale('y1', 'left', 'y', {weight: 2}),
    scale('y2', 'left', 'y'),
    scale('y3', 'right', 'y', {weight: 1}),
    scale('y4', 'right', 'y', {weight: 2}),
  ],
});

addScene('equal weights keep the index order', {
  width: 400,
  height: 300,
  boxes: [
    scale('a', 'left', 'y', {weight: 3}),
    scale('b', 'left', 'y', {weight: 3}),
    scale('c', 'bottom', 'x', {weight: 0}),
    scale('d', 'bottom', 'x', {weight: 0}),
  ],
});

addScene('full size boxes', {
  width: 512,
  height: 300,
  boxes: [
    scale('x', 'bottom', 'x'),
    scale('x2', 'top', 'x', {fullSize: true}),
    scale('y', 'left', 'y'),
    block('legend', 'top', 1000),
    block('title', 'top', 2000),
    block('subtitle', 'bottom', 1500),
    block('side', 'left', 100),
  ],
});

addScene('layout padding', {
  padding: {left: 5, top: 10, right: 15, bottom: 20},
  width: 300,
  height: 200,
  boxes: [scale('x', 'bottom', 'x'), scale('y', 'left', 'y'), block('legend', 'top', 1000)],
});

addScene('layout padding as a number and minimum padding', {
  padding: 8,
  width: 300,
  height: 200,
  minPadding: 12,
  boxes: [scale('x', 'bottom', 'x'), scale('y', 'left', 'y')],
});

addScene('minimum padding as an object', {
  width: 300,
  height: 200,
  minPadding: {top: 30, left: 2},
  boxes: [scale('x', 'bottom', 'x'), scale('y', 'left', 'y')],
});

addScene('box padding', {
  width: 300,
  height: 200,
  boxes: [
    scale('x', 'bottom', 'x', {padding: [14, 0, 9, 3]}),
    scale('y', 'left', 'y', {padding: [0, 6, 0, 6]}),
    scale('y2', 'right', 'y', {padding: [2, 50, 4, 1]}),
  ],
});

addScene('stacks', {
  width: 500,
  height: 400,
  boxes: [
    scale('ya', 'left', 'y', {options: {stack: 'a', stackWeight: 1}}),
    scale('yb', 'left', 'y', {options: {stack: 'a', stackWeight: 2}}),
    scale('yc', 'left', 'y', {options: {stack: 'a', stackWeight: null}}),
    scale('yd', 'left', 'y', {options: {stack: 'b'}}),
    scale('xa', 'bottom', 'x', {options: {stack: 'a', stackWeight: 1}}),
    scale('xb', 'bottom', 'x', {options: {stack: 'a', stackWeight: 3}}),
    scale('xc', 'top', 'x', {options: {stack: 'a'}}),
  ],
});

addScene('stacks with a full size box', {
  width: 500,
  height: 400,
  boxes: [
    scale('xa', 'bottom', 'x', {options: {stack: 's', stackWeight: 1}, fullSize: true}),
    scale('xb', 'bottom', 'x', {options: {stack: 's', stackWeight: 1}}),
    scale('ya', 'right', 'y', {options: {stack: 1, stackWeight: 2}}),
    scale('yb', 'right', 'y', {options: {stack: 1, stackWeight: 2}}),
  ],
});

addScene('a box in the chart area', {
  width: 400,
  height: 400,
  boxes: [scale('r', 'chartArea', 'r'), block('legend', 'top', 1000)],
});

addScene('dynamic positions', {
  width: 500,
  height: 300,
  boxes: [
    scale('x', 'bottom', 'x'),
    scale('y', 'left', 'y'),
    scale('xc', 'center', 'x', {horizontal: true, size: [300, 20, 10]}),
    scale('yc', {x: 0}, 'y', {horizontal: false}),
    scale('xd', {y: 5}, 'x', {horizontal: true, size: [300, 20, 10]}),
  ],
});

addScene('hidden vertical boxes', {
  width: 400,
  height: 300,
  boxes: [
    scale('x', 'bottom', 'x'),
    scale('y', 'left', 'y', {options: {display: false}}),
    scale('y2', 'right', 'y', {options: {display: false}}),
    scale('y3', 'right', 'y'),
  ],
});

addScene('refits', {
  width: 330,
  height: 250,
  boxes: [
    scale('x', 'bottom', 'x', {size: [280, 80, 20]}),
    scale('y', 'left', 'y', {size: [180, 70, 30]}),
    scale('y2', 'right', 'y', {size: [150, 40, 10]}),
    scale('x2', 'top', 'x', {size: [260, 30, 5]}),
  ],
});

addScene('no room', {
  width: 40,
  height: 30,
  boxes: [scale('x', 'bottom', 'x'), scale('y', 'left', 'y'), block('legend', 'top', 1000)],
});

addScene('configure defaults', {
  width: 300,
  height: 200,
  boxes: [
    scale('a', undefined, 'x', {horizontal: true}),
    scale('b', 'left', 'y', {weight: null, fullSize: 0}),
    scale('c', 'left', 'y', {weight: NaN}),
    scale('d', 'bottom', 'x', {weight: -1, fullSize: 1}),
  ],
});

addScene('a box without options', {
  width: 300,
  height: 200,
  boxes: [scale('x', 'bottom', 'x'), scale('y', 'left', 'y', {options: undefined})],
});

addScene('configure after addBox without weights', {
  width: 300,
  height: 200,
  reconfigure: true,
  boxes: [
    scale('l0', 'left', 'y'),
    scale('l1', 'left', 'y'),
    scale('b0', 'bottom', 'x'),
    scale('b1', 'bottom', 'x'),
    block('t0', 'top', undefined),
    block('t1', 'top', undefined),
  ],
});

addScene('configure after addBox with null and 0', {
  width: 300,
  height: 200,
  reconfigure: true,
  boxes: [
    scale('l0', 'left', 'y', {weight: null}),
    scale('l1', 'left', 'y', {weight: 0}),
    scale('r0', 'right', 'y', {weight: 0}),
    scale('r1', 'right', 'y', {weight: null}),
    block('t0', 'top', 0),
    block('t1', 'top', null),
  ],
});

addScene('configure after addBox with strings and booleans', {
  width: 400,
  height: 300,
  reconfigure: true,
  boxes: [
    scale('l0', 'left', 'y', {weight: '5'}),
    scale('l1', 'left', 'y', {weight: 5}),
    scale('l2', 'left', 'y', {weight: '5'}),
    scale('b0', 'bottom', 'x', {weight: '10'}),
    scale('b1', 'bottom', 'x', {weight: 9}),
    block('t0', 'top', true),
    block('t1', 'top', 1),
    block('t2', 'top', 'a'),
  ],
});

addScene('no boxes', {
  padding: {left: 3, top: 4, right: 5, bottom: 6},
  width: 100,
  height: 50,
  boxes: [],
});

/** The Dart literal of a number. */
function num(v) {
  if (Number.isNaN(v)) return 'double.nan';
  if (v === Infinity) return 'double.infinity';
  if (v === -Infinity) return 'double.negativeInfinity';
  if (Object.is(v, -0)) return '-0.0';
  return String(v);
}

/** Whether the data has an `undefined` literal, which needs its import. */
let usesUndefined = false;

/** The Dart literal of a value. */
function dart(v) {
  if (v === null) return 'null';
  if (v === undefined) {
    usesUndefined = true;
    return 'undefined';
  }
  if (typeof v === 'number') return num(v);
  if (typeof v === 'boolean') return String(v);
  if (typeof v === 'string' && /^[\w ]*$/.test(v)) return `'${v}'`;
  if (typeof v === 'object' && Object.getPrototypeOf(v) === Object.prototype) {
    const entries = Object.keys(v).map((k) => `${dart(k)}: ${dart(v[k])}`);
    return `<String, Object?>{${entries.join(', ')}}`;
  }
  throw new Error(`No Dart literal for ${String(v)}`);
}

/** The Dart literal of a box number: NaN for `undefined`. */
function prop(v) {
  return v === undefined ? 'double.nan' : num(v);
}

function dartBox(b) {
  return `      (
        name: '${b.name}',
        position: ${dart(b.position)},
        weight: ${dart(b.weight)},
        fullSize: ${dart(b.fullSize)},
        axis: ${b.axis === undefined ? 'null' : dart(b.axis)},
        horizontal: ${b.horizontal},
        options: ${b.options === undefined ? 'null' : dart(b.options)},
        size: (${b.size.map(num).join(', ')}),
        padding: ${b.padding ? `(${b.padding.map(num).join(', ')})` : 'null'},
        beforeLayout: ${b.beforeLayout},
      ),
`;
}

function dartResult(r) {
  return `      (
        name: '${r.name}',
        left: ${prop(r.left)},
        top: ${prop(r.top)},
        right: ${prop(r.right)},
        bottom: ${prop(r.bottom)},
        width: ${prop(r.width)},
        height: ${prop(r.height)},
        fullSize: ${dart(r.fullSize)},
        position: ${dart(r.position)},
        weight: ${dart(r.weight)},
      ),
`;
}

const body = scenes
  .map(
    (s) => `  (
    name: '${s.name}',
    padding: ${dart(s.padding)},
    width: ${num(s.width)},
    height: ${num(s.height)},
    minPadding: ${dart(s.minPadding)},
    reconfigure: ${s.reconfigure},
    boxes: [
${s.boxes.map(dartBox).join('')}    ],
    error: ${s.error === null ? 'null' : `'${s.error}'`},
    log: [
${s.log.map(([call, name, args]) => `      ('${call}', '${name}', [${args.map(num).join(', ')}]),\n`).join('')}    ],
    results: [
${s.results.map(dartResult).join('')}    ],
    chartArea: ${
      s.chartArea
        ? `(${['left', 'top', 'right', 'bottom', 'width', 'height'].map((k) => num(s.chartArea[k])).join(', ')})`
        : 'null'
    },
    order: [${s.order.map((n) => `'${n}'`).join(', ')}],
  ),
`,
  )
  .join('');

const out = `// Original code, not ported from Chart.js: core.layouts reference data.

// Generated by tool/reference/layouts_reference.mjs. Do not edit.
// Node.js ${process.version} (${process.platform}-${process.arch}), V8 ${process.versions.v8}:
// src/core/core.layouts.js at the pinned Chart.js. ${scenes.length} scenes.
${usesUndefined ? "\nimport 'package:flutter_chartjs_port/src/js/js_undefined.dart';\n" : ''}
/// The Node.js version that generated the data.
const String layoutsReferenceNode = '${process.version}';

/// The V8 version that generated the data.
const String layoutsReferenceV8 = '${process.versions.v8}';

/// The architecture of the Node.js build that generated the data.
const String layoutsReferenceArch = '${process.arch}';

/// A fake box: the options \`position\`, \`weight\` and \`fullSize\` of
/// \`layouts.configure\` (the \`undefined\` sentinel for an absent key), its
/// \`axis\` (null for \`undefined\`), \`isHorizontal()\`, its \`options\` (null
/// for \`undefined\`), the size rule \`(at, thick, thin)\` of its \`update\`,
/// the result \`(left, top, right, bottom)\` of \`getPadding\` (null for a box
/// without \`getPadding\`), and whether it has \`beforeLayout\`.
typedef LayoutsReferenceBox = ({
  String name,
  Object? position,
  Object? weight,
  Object? fullSize,
  String? axis,
  bool horizontal,
  Map<String, Object?>? options,
  (double, double, double) size,
  (double, double, double, double)? padding,
  bool beforeLayout,
});

/// The state of a box after \`layouts.update\`. NaN stands for \`undefined\`.
/// \`fullSize\`, \`position\` and \`weight\` are the JavaScript values.
typedef LayoutsReferenceResult = ({
  String name,
  double left,
  double top,
  double right,
  double bottom,
  double width,
  double height,
  Object? fullSize,
  Object? position,
  Object? weight,
});

/// A fake chart: the \`layout.padding\` option, the size and the minimum
/// padding of \`layouts.update\`, whether \`layouts.configure\` runs again
/// after \`layouts.addBox\` (\`reconfigure\`), the boxes in the order of
/// \`layouts.addBox\`, the name of the error class that \`layouts.update\`
/// throws (or null), the calls of the boxes \`(call, box, arguments)\` in
/// order, the boxes after the update, the chart area \`(left, top, right,
/// bottom, width, height)\` (null after an error), and the order of
/// \`chart.boxes\`. The arguments of \`update\` are the width, the height and
/// the four edges \`left\`, \`top\`, \`right\` and \`bottom\` of the margins.
/// The argument of \`draw\` is the \`left\` and \`top\` of the chart area.
typedef LayoutsReferenceScene = ({
  String name,
  Object? padding,
  double width,
  double height,
  Object? minPadding,
  bool reconfigure,
  List<LayoutsReferenceBox> boxes,
  String? error,
  List<(String, String, List<double>)> log,
  List<LayoutsReferenceResult> results,
  (double, double, double, double, double, double)? chartArea,
  List<String> order,
});

/// The scenes.
const List<LayoutsReferenceScene> layoutsReference = [
${body}];
`;

writeFileSync(OUT, out);
execFileSync('dart', ['format', OUT], {stdio: 'inherit'});
console.log(`Wrote ${OUT}: ${scenes.length} scenes.`);
