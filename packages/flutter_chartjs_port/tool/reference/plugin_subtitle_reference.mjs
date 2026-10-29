// Original code, not ported from Chart.js: subtitle plugin reference generator.
//
// It writes test/port/plugins/plugin_subtitle_reference.dart, the data of
// test/port/plugins/plugin.subtitle_test.dart: real charts with the
// subtitle and title plugins of a build of the pinned Chart.js (Chart.js
// ADR 0041, section 3). See the headers of
// tool/reference/plugin_chart_common.mjs,
// tool/reference/controller_chart_common.mjs and
// tool/reference/scale_chart_common.mjs for the method and the limits.
//
// The cases are the unit cases of Chart.js ADR 0041, section 3 item 7 (row
// `subtitle`): the subtitle alone, with a title (the box order, also after
// a `weight` step that puts the subtitle above the title), `position:
// 'left'`, `display: false` (with the steps that stop and start the
// plugin), `padding`, and a text array with `font`, `color` and `align`.
// The row also names a case with a legend: the full case of wave 4
// `full: subtitle, title and legend` (Chart.js ADR 0041, section 4 item 3),
// with the default plugin options, so the three boxes are at the top with
// the weights 1000 (legend, plugin.legend.js:642), 1500 (subtitle,
// plugin.subtitle.js:42) and 2000 (title, plugin.title.js:155). Each unit
// case sets `options.plugins` with unitPlugins(['subtitle', 'title'])
// (Chart.js ADR 0041, sections 4 and 7).
// The observation has the keys `plugins.subtitle` and `plugins.title` (the
// observers `observeSubtitle` and `observeTitle` below and in the Dart test
// file). The test file runs the cases again with the light preset
// (theming.md section 8 test 3).
//
// Usage, from packages/flutter_chartjs_port, with the darwin-arm64 build of
// Node.js v24.22.1 (Chart.js ADR 0045):
//
//   CHARTJS_DIST=<build>/dist/chart.js \
//     node tool/reference/plugin_subtitle_reference.mjs
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

const OUT = fileURLToPath(
  new URL('../../test/port/plugins/plugin_subtitle_reference.dart', import.meta.url),
);

const C = await loadChartJs();
registerBuiltins(C);

/** The class `Title` of plugin.title.js:7, the class of the subtitle box. */
const Title = C.registry.getPlugin('title')._element;

/**
 * `{lines, options}` of the title box [box], or `null` without a box.
 * `lines` is the `lineCount` of plugin.title.js:43 (the length of an array
 * text, else 1), and `options` is the plain copy of the resolved options
 * of the box. `_padding` is private in the port (Chart.js ADR 0038,
 * section 7): the box in `boxes` and the draw calls show its effect.
 */
function observeBox(box) {
  if (!box) return null;
  const text = box.options.text;
  return {
    lines: Array.isArray(text) ? text.length : 1,
    options: plain(box.options),
  };
}

/**
 * The observer `plugins.subtitle`: the `Title` box of `chart.boxes` that
 * is not `chart.titleBlock`. The subtitle map is private
 * (plugin.subtitle.js:4). Two subtitle boxes stop the generator.
 */
function observeSubtitle(chart) {
  const boxes = chart.boxes.filter((b) => b instanceof Title && b !== chart.titleBlock);
  if (boxes.length > 1) throw new Error('More than one subtitle box.');
  return observeBox(boxes[0]);
}

/** The observer `plugins.title`: the box `chart.titleBlock`. */
function observeTitle(chart) {
  return observeBox(chart.titleBlock);
}

/**
 * A line chart with two datasets, the subtitle options [subtitleOptions]
 * and the title options [titleOptions].
 */
function line(subtitleOptions, titleOptions) {
  const pluginOptions = {};
  if (subtitleOptions !== undefined) pluginOptions.subtitle = subtitleOptions;
  if (titleOptions !== undefined) pluginOptions.title = titleOptions;
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
      plugins: unitPlugins(['subtitle', 'title'], pluginOptions),
    },
  };
}

/** runPluginCase with the observers of the subtitle and the title. */
const subtitleCase = (name, config, opts = {}) =>
  runPluginCase(name, config, {
    ...opts,
    observers: {subtitle: observeSubtitle, title: observeTitle},
  });

const cases = [
  subtitleCase('alone', line({display: true, text: 'Chart subtitle'})),
  subtitleCase(
    'with a title',
    line({display: true, text: 'Chart subtitle'}, {display: true, text: 'Chart title'}),
    {steps: [['setOption', 'plugins.subtitle.weight', 2500]]},
  ),
  subtitleCase(
    'position left',
    line({display: true, text: 'Left subtitle', position: 'left', align: 'start'}),
  ),
  subtitleCase('display false (the default)', line(), {
    steps: [
      ['setOption', 'plugins.subtitle.text', 'Later'],
      ['setOption', 'plugins.subtitle.display', true],
      ['setOption', 'plugins.subtitle', false],
      ['setOption', 'plugins.subtitle', {display: true, text: 'Back'}],
    ],
  }),
  subtitleCase(
    'padding',
    line(
      {display: true, text: 'Padded', position: 'bottom', padding: {top: 6, bottom: 12}},
      {display: true, text: 'Title', position: 'bottom', padding: 4},
    ),
  ),
  subtitleCase(
    'a text array with font, color and align',
    line(
      {
        display: true,
        text: ['Line one', 'Line two'],
        align: 'end',
        color: 'rgb(0, 128, 0)',
        font: {size: 14, family: 'Arial', style: 'italic', lineHeight: 1.5},
      },
      {display: true, text: 'Title', align: 'start'},
    ),
  ),
];

// ---------------------------------------------------------------------------
// The full cases of Chart.js ADR 0041, section 4 item 2 (wave 4): the
// default plugin options, so each registered plugin runs (no unitPlugins).
// A full case exists only where another plugin changes the result (section
// 4 item 3).

cases.push(
  subtitleCase('full: subtitle, title and legend', {
    ...line(),
    options: {
      plugins: {
        subtitle: {display: true, text: 'Chart subtitle'},
        title: {display: true, text: 'Chart title'},
      },
    },
  }),
);

writeControllerReference(OUT, 'pluginSubtitle', cases, {title: 'subtitle plugin'});
