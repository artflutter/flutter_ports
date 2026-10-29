// Original code, not ported from Chart.js: title plugin reference generator.
//
// It writes test/port/plugins/plugin_title_reference.dart, the data of
// test/port/plugins/plugin.title_test.dart: real charts with the title
// plugin of a build of the pinned Chart.js (Chart.js ADR 0041, section 3).
// See the headers of tool/reference/plugin_chart_common.mjs,
// tool/reference/controller_chart_common.mjs and
// tool/reference/scale_chart_common.mjs for the method and the limits.
//
// The cases are the unit cases of Chart.js ADR 0041, section 3 item 7 (row
// `title`): `display`, each `position`, `align`, `fullSize: false`,
// `padding` as a number and as an object, a text array, `font` and
// `color`, and a scriptable `text` and a number `text`. The draw calls come
// after the last step, and `align` changes only the draw. Thus each `align`
// case ends on the value under test: `start` and `end` at the top, at the
// left and at the right (the `align` branch, items 5 and 7). Each unit case
// sets `options.plugins` with unitPlugins(['title']) (Chart.js ADR 0041,
// sections 4 and 7). The observation has the key `plugins.title` (the
// observer `observeTitle` below and in the Dart test file). The test file
// runs the cases again with the light preset (theming.md section 8 test 3).
//
// The full case (names that start with `full:`, Chart.js ADR 0041, section
// 4 item 2) has the default plugin options: the title with the default
// legend, the box order and the chart area, then the legend at the left.
//
// Usage, from packages/flutter_chartjs_port, with the darwin-arm64 build of
// Node.js v24.22.1 (Chart.js ADR 0045):
//
//   CHARTJS_DIST=<build>/dist/chart.js \
//     node tool/reference/plugin_title_reference.mjs
//
// The path can also be the first argument.

import {fileURLToPath} from 'node:url';

import {
  loadChartJs,
  plain,
  registerBuiltins,
  runPluginCase,
  unitPlugins,
  writeControllerReference,
} from './plugin_chart_common.mjs';
import {named} from './controller_chart_common.mjs';

const OUT = fileURLToPath(
  new URL('../../test/port/plugins/plugin_title_reference.dart', import.meta.url),
);

const C = await loadChartJs();
registerBuiltins(C);

/**
 * The observer `plugins.title`: `null` without a title block, else
 * `{lines, options}`. `lines` is the `lineCount` of plugin.title.js:43 (the
 * length of an array text, else 1), and `options` is the plain copy of the
 * resolved options of the box. `_padding` is private in the port (Chart.js
 * ADR 0038, section 7): the box in `boxes` and the draw calls show its
 * effect.
 */
function observeTitle(chart) {
  const title = chart.titleBlock;
  if (!title) return null;
  const text = title.options.text;
  return {
    lines: Array.isArray(text) ? text.length : 1,
    options: plain(title.options),
  };
}

/** The scriptable `text` of the case `a scriptable text`. */
const titleText = named('titleText', (ctx) => `Chart of type ${ctx.chart.config.type}`);

/** A line chart with two datasets and the title options [titleOptions]. */
function line(titleOptions) {
  return {
    type: 'line',
    data: {
      labels: ['January', 'February', 'March', 'April'],
      datasets: [
        {label: 'one', data: [10, 30, 20, 40], borderColor: 'blue'},
        {label: 'two', data: [25, 5, 35, 15], borderColor: 'green'},
      ],
    },
    options: {
      plugins: unitPlugins(['title'], titleOptions === undefined ? {} : {title: titleOptions}),
    },
  };
}

/** runPluginCase with the observer of the title. */
const titleCase = (name, config, opts = {}) =>
  runPluginCase(name, config, {...opts, observers: {title: observeTitle}});

const cases = [
  titleCase('display false (the default)', line(), {
    steps: [
      ['setOption', 'plugins.title.text', 'Later'],
      ['setOption', 'plugins.title.display', true],
    ],
  }),
  titleCase('display true', line({display: true, text: 'Chart title'}), {
    steps: [
      ['setOption', 'plugins.title.display', false],
      ['setOption', 'plugins.title', false],
      ['setOption', 'plugins.title', {display: true, text: 'Back'}],
    ],
  }),
  titleCase('position bottom', line({display: true, text: 'Bottom title', position: 'bottom'})),
  titleCase(
    'position left with align start',
    line({display: true, text: 'Left title', position: 'left', align: 'start'}),
  ),
  titleCase(
    'position left with align end',
    line({display: true, text: 'Left title', position: 'left', align: 'center'}),
    {steps: [['setOption', 'plugins.title.align', 'end']]},
  ),
  titleCase(
    'position right with align start',
    line({display: true, text: 'Right title', position: 'right', align: 'start'}),
  ),
  titleCase(
    'position right with align end',
    line({display: true, text: 'Right title', position: 'right', align: 'end'}),
  ),
  titleCase('align start and end', line({display: true, text: 'Aligned', align: 'start'}), {
    steps: [['setOption', 'plugins.title.align', 'end']],
  }),
  titleCase('align end and start', line({display: true, text: 'Aligned', align: 'end'}), {
    steps: [['setOption', 'plugins.title.align', 'start']],
  }),
  titleCase('fullSize false', line({display: true, text: 'Not full size', fullSize: false}), {
    steps: [['setOption', 'plugins.title.position', 'left']],
  }),
  titleCase('padding as a number', line({display: true, text: 'Padded', padding: 25})),
  titleCase(
    'padding as an object',
    line({display: true, text: 'Padded', padding: {top: 4, bottom: 16, left: 30}}),
    {steps: [['setOption', 'plugins.title.position', 'left']]},
  ),
  titleCase(
    'a text array',
    line({
      display: true,
      text: ['Line one', 'Line two', 'Line three'],
      font: {lineHeight: 1.5},
    }),
    {steps: [['setOption', 'plugins.title.position', 'right']]},
  ),
  titleCase(
    'font and color',
    line({
      display: true,
      text: 'Styled',
      color: 'rgb(255, 0, 0)',
      font: {size: 18, family: 'Arial', style: 'italic', weight: 'normal'},
    }),
  ),
  titleCase('a scriptable text', line({display: true, text: titleText})),
  titleCase('a number text', line({display: true, text: 0})),
];

// ---------------------------------------------------------------------------
// The full cases of Chart.js ADR 0041, section 4 item 2 (wave 4): the
// default plugin options, so each registered plugin runs (no unitPlugins).
// A full case exists only where another plugin changes the result (section
// 4 item 3).

cases.push(
  titleCase(
    'full: title with the default legend',
    {...line(), options: {plugins: {title: {display: true, text: 'Chart title'}}}},
    {steps: [['setOption', 'plugins.legend.position', 'left']]},
  ),
);

writeControllerReference(OUT, 'pluginTitle', cases, {title: 'title plugin'});
