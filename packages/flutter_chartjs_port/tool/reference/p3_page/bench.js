// Original code, not ported from Chart.js: the browser driver of the upstream page of the P3 comparison.
//
// The upstream side of the P3 comparison (performance.md section 14.9,
// Chart.js ADR 0053): the cases of cases.js with the pinned build of
// Chart.js and its plugins, in a browser. serve.mjs serves this folder, the
// dist of the build and field.json. README.md gives the steps.
//
// Start: window.startBench(), or the query parameter autostart=1. The query
// parameters: cases=<selectors> (as CASES of lib/main_bench.dart),
// n=<counts> (as N), run=<tag>, batches, batchMs and warmupMs (15, 200 and
// 1000 when absent, as BATCHES, BATCH_MS and WARMUP_MS). Output: the lines
// `FIELD {json}`, `ENV {json}`, one line `BENCH {json}` for each case and N,
// and `BENCH done` at the end (or `BENCH error <stack>`). Each line goes to
// the console and to POST /log?run=<tag>.

import {Chart, registerables, BasicPlatform, animator} from './dist/chart.js';
import {getRelativePosition} from './dist/helpers.js';
import {DEFAULT_COUNTS, HEIGHT, WIDTH, makeCases} from './cases.js';

// src/index.umd.ts:28: the controllers, the elements, the scales and the
// seven plugins, as registerables of the port.
Chart.register(...registerables);

const params = new URLSearchParams(location.search);
const RUN = params.get('run') || 'manual';
const SETTINGS = {
  batches: +(params.get('batches') || 15),
  batchMs: +(params.get('batchMs') || 200),
  warmupMs: +(params.get('warmupMs') || 1000),
};

const status = document.getElementById('status');

function out(line) {
  console.log(line);
  status.textContent = line.slice(0, 160);
  fetch(`/log?run=${encodeURIComponent(RUN)}`, {method: 'POST', body: line}).catch(() => {});
}

function makeCanvas() {
  const canvas = document.createElement('canvas');
  canvas.width = WIDTH;
  canvas.height = HEIGHT;
  document.getElementById('host').replaceChildren(canvas);
  return canvas;
}

const nextFrame = () => new Promise((resolve) => requestAnimationFrame(() => setTimeout(resolve, 0)));

window.startBench = async function startBench() {
  if (window.__started) return 'already';
  window.__started = true;
  try {
    const build = await (await fetch('build.json')).json();
    const field = await (await fetch('field.json')).json();
    const {select, runCase, fieldCheck} = makeCases({
      Chart,
      BasicPlatform,
      animator,
      getRelativePosition,
      field,
      makeCanvas,
      build: `chartjs-${build.version}-${build.commit.slice(0, 8)}-dist/chart.js`,
      platform: 'browser',
    });
    out(`FIELD ${JSON.stringify(fieldCheck())}`);
    out(`ENV ${JSON.stringify({
      ua: navigator.userAgent,
      crossOriginIsolated: self.crossOriginIsolated,
      dpr: devicePixelRatio,
      settings: SETTINGS,
      chartVersion: Chart.version,
      build,
    })}`);
    const cases = select(params.get('cases'));
    const counts = params.get('n') ? params.get('n').split(',').map((s) => +s.trim()) : null;
    for (const c of cases) {
      for (const n of counts || c.counts || DEFAULT_COUNTS) {
        status.textContent = `Case ${c.id} ${JSON.stringify(c.keys)}, N ${n}`;
        // The status shows before the case holds the main thread.
        await nextFrame();
        out(`BENCH ${JSON.stringify(runCase(c, n, SETTINGS))}`);
      }
    }
    out('BENCH done');
  } catch (e) {
    out(`BENCH error ${(e && e.stack) || e}`);
  }
  return 'started';
};

if (params.get('autostart') === '1') window.startBench();
