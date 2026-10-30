// Original code, not ported from Chart.js: the cases of the upstream page of the P3 comparison.
//
// The cases of the upstream page of the P3 comparison (performance.md section
// 14.9, Chart.js ADR 0053): the JS form of the cases of
// apps/chartjs_gallery/lib/bench/chart_bench.dart that have an upstream form,
// with the same configs, data, steps and timing loop. README.md of this
// folder lists the cases and the cells. bench.js runs them in a browser.
//
// The module has no import. makeCases() gets the Chart.js values from its
// caller: bench.js gives the values of the pinned dist in the browser. A
// smoke check can give the values of the same dist in Node.js.
//
// The rules of the Dart cases that this file keeps:
// - The Dart chart of a case has no host, so the port gives it the
//   BasicPlatform (detectPlatform). A case with animations has the platform
//   _AnimatedPlatform: a BasicPlatform with the no-op updateConfig of
//   BasePlatform, which keeps the option `animation`. runCase() gives each
//   chart the same platform class: BasicPlatform, or AnimatedBasicPlatform.
// - The field of moving points is StressPointField of
//   apps/chartjs_gallery/lib/demo/stress_chart_config.dart: field.json holds
//   its start values (field_gen.dart), and Field.step() is the JS form of
//   StressPointField.step.
// - An event goes to the event handler of the chart at once, as _benchEvent
//   does: no platform listener and no throttle. A tick of the animator is
//   `animator._update(date)`, as _benchTick does.
// - The timing loop is runChartBenchCase and _Loop: a warm-up, a
//   calibration and timed batches. A browser has no picture recording, so a
//   BENCH line has no `end` figures.

/** The bitmap of the canvas: chartBenchWidth x chartBenchHeight. */
export const WIDTH = 800;
export const HEIGHT = 480;

/** chartBenchStep: one frame at 60 Hz, in seconds. */
export const STEP = 1 / 60;

/** chartBenchFrameMs, chartBenchFadeFrames and chartBenchFadePhase. */
const FRAME_MS = STEP * 1000;
const FADE_FRAMES = 12;
const FADE_PHASE = 0.6180339887498949;

/** The point counts: chartBenchDefaultCounts, chartBenchPluginCounts and chartBenchMotionCounts. */
export const DEFAULT_COUNTS = [1000, 5000, 20000];
const PLUGIN_COUNTS = [100, 1000];
const MOTION_COUNTS = [1000, 20000];

/** stressPointCounts and stressArcCounts. */
const POINT_COUNTS = [1000, 5000, 20000];
const ARC_COUNTS = [100, 1000, 5000];

/** stressChartBackground and stressChartBackgroundOdd. */
const BG = 'rgba(54, 162, 235, 0.45)';
const BG_ODD = 'rgba(255, 99, 132, 0.45)';

/** chartBenchOptions. */
const BENCH_OPTIONS = {responsive: false, devicePixelRatio: 1.0};

/** _benchBorders and _benchFills. */
const BORDERS = [
  'rgb(54, 162, 235)',
  'rgb(255, 99, 132)',
  'rgb(255, 159, 64)',
  'rgb(255, 205, 86)',
  'rgb(75, 192, 192)',
  'rgb(153, 102, 255)',
  'rgb(201, 203, 207)',
];
const FILLS = [
  'rgba(54, 162, 235, 0.5)',
  'rgba(255, 99, 132, 0.5)',
  'rgba(255, 159, 64, 0.5)',
  'rgba(255, 205, 86, 0.5)',
  'rgba(75, 192, 192, 0.5)',
  'rgba(153, 102, 255, 0.5)',
  'rgba(201, 203, 207, 0.5)',
];

/** StressChartType: the counts, the option sharing and the point types. */
const TYPES = {
  line: {counts: POINT_COUNTS, sharing: true, points: true},
  scatter: {counts: POINT_COUNTS, sharing: false, points: true},
  bar: {counts: POINT_COUNTS, sharing: true},
  bubble: {counts: POINT_COUNTS, sharing: true},
  doughnut: {counts: ARC_COUNTS, sharing: true},
  pie: {counts: ARC_COUNTS, sharing: true},
  polarArea: {counts: ARC_COUNTS, sharing: false},
  radar: {counts: ARC_COUNTS, sharing: false},
};

/** ChartBenchCall.frameMetric. */
const frameMetric = (call) =>
  call === 'draw' ? 'draw+end' : call === 'motion' ? 'update' : 'update+draw+end';

/** The nearest-rank percentile of the sorted samples (_percentile). */
function percentile(sorted, p) {
  const rank = Math.ceil(p * sorted.length) - 1;
  return sorted[Math.min(Math.max(rank, 0), sorted.length - 1)];
}

/** The figures of a part: the median, the 10th and the 90th percentile in ms. */
function figures(part, samples) {
  samples.sort((a, b) => a - b);
  const at = (p) => percentile(samples, p).toFixed(3);
  return {[`${part}MedianMs`]: at(0.5), [`${part}P10Ms`]: at(0.1), [`${part}P90Ms`]: at(0.9)};
}

/**
 * The cases, the selection and the timing loop.
 *
 * `env` has the Chart.js values `Chart`, `BasicPlatform`, `animator` and
 * `getRelativePosition` (helpers.dom), the decoded `field` (field.json),
 * `build` and `platform` (the BENCH keys) and `makeCanvas()` (a canvas of
 * WIDTH x HEIGHT).
 */
export function makeCases(env) {
  const {Chart, BasicPlatform, animator, getRelativePosition, field: FIELD} = env;

  /** _AnimatedPlatform: a BasicPlatform that keeps the option `animation`. */
  class AnimatedBasicPlatform extends BasicPlatform {
    updateConfig() {
      // no-op (platform.base.js:80-82)
    }
  }

  /** StressPointField(count), from the start values of field.json. */
  class Field {
    constructor(count) {
      if (count > FIELD.count) throw new Error(`field.json has ${FIELD.count} points, not ${count}`);
      this.x = Float64Array.from(FIELD.x.slice(0, count));
      this.y = Float64Array.from(FIELD.y.slice(0, count));
      this.vx = Float64Array.from(FIELD.vx.slice(0, count));
      this.vy = Float64Array.from(FIELD.vy.slice(0, count));
    }
    /** StressPointField.step. */
    step(n, dt) {
      const {x, y, vx, vy} = this;
      for (let i = 0; i < n; i++) {
        let px = x[i] + vx[i] * dt;
        let py = y[i] + vy[i] * dt;
        if (px < 0 || px > 1) { vx[i] = -vx[i]; px = Math.min(Math.max(px, 0), 1); }
        if (py < 0 || py > 1) { vy[i] = -vy[i]; py = Math.min(Math.max(py, 0), 1); }
        x[i] = px; y[i] = py;
      }
    }
  }

  const labeled = (t) => !TYPES[t].points && t !== 'bubble';
  const arcs = (t) => t === 'doughnut' || t === 'pie' || t === 'polarArea';

  /** StressChartScene. */
  class Scene {
    constructor(type, n, field) {
      this.type = type; this.n = n;
      this.labels = labeled(type) ? Array.from({length: n}, (_, i) => `Point ${i}`) : [];
      if (TYPES[type].points) {
        this.data = Array.from({length: n}, (_, i) => ({x: field.x[i], y: field.y[i]}));
      } else if (type === 'bubble') {
        this.data = Array.from({length: n}, (_, i) => {
          const v = field.vx[i] / 0.3;
          return {x: field.x[i], y: field.y[i], r: 2 + 4 * v * v};
        });
      } else if (arcs(type)) {
        this.data = Array.from({length: n}, (_, i) => 0.05 + 0.95 * field.y[i]);
      } else {
        this.data = Array.from({length: n}, (_, i) => field.y[i]);
      }
    }
    /** StressChartScene.write. */
    write(field) {
      const {data, n, type} = this;
      const {x, y} = field;
      if (TYPES[type].points || type === 'bubble') {
        for (let i = 0; i < n; i++) { const d = data[i]; d.x = x[i]; d.y = y[i]; }
        return;
      }
      if (arcs(type)) {
        for (let i = 0; i < n; i++) data[i] = 0.05 + 0.95 * y[i];
        return;
      }
      for (let i = 0; i < n; i++) data[i] = y[i];
    }
  }

  /** stressHiddenScale. */
  const hidden = (type, min, max) => {
    const s = {type, display: false, ticks: {display: false}};
    if (min !== undefined) s.min = min;
    if (max !== undefined) s.max = max;
    return s;
  };

  /** _stressScales, with unitScales(hideTicks: true) for line and scatter. */
  function scalesOf(type) {
    switch (type) {
      case 'line': case 'scatter':
        return {
          x: {type: 'linear', display: false, ticks: {display: false}, suggestedMin: 0.0, suggestedMax: 1.0},
          y: {type: 'linear', display: false, ticks: {display: false}, min: 0.0, max: 1.0},
        };
      case 'bar': return {x: hidden('category'), y: hidden('linear', 0, 1)};
      case 'bubble': return {x: hidden('linear', 0, 1), y: hidden('linear', 0, 1)};
      case 'polarArea': case 'radar': return {r: hidden('radialLinear', 0, 1)};
      default: return null;
    }
  }

  /** stressScriptableBackground. */
  const scriptableBackground = (context) => (+context.dataIndex) % 2 === 0 ? BG : BG_ODD;

  /** stressChartConfig with `options: chartBenchOptions`. */
  function stressChartConfig(scene, scriptable, plugins) {
    const type = scene.type;
    const points = TYPES[type].points;
    const dataset = {
      data: scene.data,
      backgroundColor: scriptable ? scriptableBackground : BG,
      borderColor: '#36A2EB',
      borderWidth: 1.0,
    };
    if (points) Object.assign(dataset, {pointStyle: 'circle', radius: 3.0, showLine: false, clip: false});
    const options = {animation: false, events: [], maintainAspectRatio: false, plugins: {legend: false}};
    if (points) Object.assign(options, {parsing: false, layout: {autoPadding: false}});
    const scales = scalesOf(type);
    if (scales) options.scales = scales;
    Object.assign(options, BENCH_OPTIONS);
    const data = {};
    if (scene.labels.length) data.labels = scene.labels;
    data.datasets = [dataset];
    return {type, data, options, plugins: [...plugins]};
  }

  /** StressChartTiming. */
  class Timing {
    constructor() {
      this.reset();
      this.elementsStart = -1;
      this.layoutStart = 0;
      this.dsUpdateStart = 0;
      this.dsDrawStart = 0;
      const self = this;
      this.plugin = {
        id: 'stressChartTiming',
        beforeElementsUpdate() { self.elementsStart = performance.now(); },
        beforeLayout() {
          const now = performance.now();
          if (self.elementsStart >= 0) { self.elements += now - self.elementsStart; self.elementsStart = -1; }
          self.layoutStart = now;
        },
        afterLayout() { self.layout += performance.now() - self.layoutStart; },
        beforeDatasetsUpdate() { self.dsUpdateStart = performance.now(); },
        afterDatasetsUpdate() { self.datasetsUpdate += performance.now() - self.dsUpdateStart; },
        beforeDatasetsDraw() { self.dsDrawStart = performance.now(); },
        afterDatasetsDraw() { self.datasetsDraw += performance.now() - self.dsDrawStart; },
      };
    }
    take() {
      const p = {elements: this.elements, layout: this.layout, datasetsUpdate: this.datasetsUpdate, datasetsDraw: this.datasetsDraw};
      this.reset();
      return p;
    }
    reset() { this.elements = 0; this.layout = 0; this.datasetsUpdate = 0; this.datasetsDraw = 0; }
  }

  /** _PluginTiming: the parts of Timing, and with `tooltip` the part tooltipDraw. */
  class PluginTiming {
    constructor(tooltip = false) {
      this.tooltip = tooltip;
      this.parts = new Timing();
      this.tooltipStart = 0;
      this.tooltipTicks = 0;
    }
    get plugins() {
      const self = this;
      return [
        this.parts.plugin,
        ...(this.tooltip ? [{
          id: 'benchTooltipTiming',
          beforeTooltipDraw() { self.tooltipStart = performance.now(); },
          afterTooltipDraw() { self.tooltipTicks += performance.now() - self.tooltipStart; },
        }] : []),
      ];
    }
    take() {
      const parts = {...this.parts.take(), ...(this.tooltip ? {tooltipDraw: this.tooltipTicks} : {})};
      this.tooltipTicks = 0;
      return parts;
    }
  }

  /** _BenchSeries. */
  class BenchSeries {
    constructor(datasets, n, {scale = 1, offset = 0, gapEvery = 0} = {}) {
      this.datasets = datasets; this.n = n;
      this.scale = scale; this.offset = offset; this.gapEvery = gapEvery;
      this.field = new Field(datasets * n);
      this.data = [];
      for (let k = 0; k < datasets; k++) this.data.push(Array.from({length: n}, (_, i) => this.value(k, i)));
    }
    labels() { return Array.from({length: this.n}, (_, i) => `Point ${i}`); }
    value(k, i) {
      return this.gapEvery > 0 && i % this.gapEvery === this.gapEvery - 1
        ? null
        : this.offset + this.scale * this.field.y[k * this.n + i];
    }
    step() {
      this.field.step(this.datasets * this.n, STEP);
      for (let k = 0; k < this.datasets; k++) {
        const values = this.data[k];
        for (let i = 0; i < this.n; i++) values[i] = this.value(k, i);
      }
    }
  }

  /** _benchDataset. */
  const benchDataset = (k, data, more) => ({
    label: `Dataset ${k + 1}`,
    data,
    borderColor: BORDERS[k % BORDERS.length],
    backgroundColor: FILLS[k % FILLS.length],
    borderWidth: 1.0,
    ...more,
  });

  /** _benchConfig. */
  const benchConfig = (type, series, {datasets, options, plugins = []}) => ({
    type,
    data: {labels: series.labels(), datasets},
    options: {...BENCH_OPTIONS, ...options},
    plugins: [...plugins],
  });

  /** _benchHiddenScales. */
  const benchHiddenScales = ({min, max, stacked = false}) => ({
    x: hidden('category'),
    y: {...hidden('linear', min, max), ...(stacked ? {stacked: true} : {})},
  });

  /** _stressCase. */
  const stressCase = (name, call, type, {scriptable = false, counts = null} = {}) => ({
    mode: 'chart', name, call, counts,
    keys: {type, sharing: TYPES[type].sharing, scriptable},
    scene(n) {
      const field = new Field(n);
      const scene = new Scene(type, n, field);
      const timing = new Timing();
      return {
        config: stressChartConfig(scene, scriptable, [timing.plugin]),
        change: () => { field.step(n, STEP); scene.write(field); },
        takeParts: () => timing.take(),
      };
    },
  });

  /** _pluginCase: a case of phase 8 names its primary metric. */
  const pluginCase = (mode, name, call, {counts, keys, scene}) => ({
    mode, name, call, counts, keys, primary: frameMetric(call), scene,
  });

  /** _leastWorkPlugins. */
  const leastWorkPlugins = () => ({
    legend: {display: false},
    title: {display: false},
    subtitle: {display: false},
    colors: {enabled: false},
    decimation: {enabled: false},
  });

  /** _dispatchCase. */
  const dispatchCase = (config, datasets, call) => pluginCase('plugins', 'line', call, {
    counts: [datasets === 3 ? 1000 : 100],
    keys: {config, datasets},
    scene(n) {
      const series = new BenchSeries(datasets, n);
      return {
        config: benchConfig('line', series, {
          datasets: Array.from({length: datasets}, (_, k) => benchDataset(k, series.data[k])),
          options: {
            animation: false,
            events: [],
            scales: benchHiddenScales({min: 0, max: 1}),
            plugins: config === 'A' ? leastWorkPlugins() : false,
          },
        }),
        change: () => series.step(),
      };
    },
  });

  /** _benchEvent: the chart event of fromNativeEvent (platform.dom.js:109-118). */
  function benchEvent(chart, type, x, y) {
    const native = {type, offsetX: x, offsetY: y, target: chart.canvas};
    const position = getRelativePosition(native, chart);
    chart._eventHandler({
      type,
      chart,
      native,
      x: position.x !== undefined ? position.x : null,
      y: position.y !== undefined ? position.y : null,
    });
  }

  /** _benchTick. */
  const benchTick = (date) => animator._update(date);

  /** _benchFinishAnimations. */
  function benchFinishAnimations() {
    const date = Date.now() + 3600000;
    benchTick(date);
    benchTick(date);
  }

  /** _BenchPointer. */
  class BenchPointer {
    constructor() { this.xs = []; this.y = 0; }
    measure(chart) {
      this.xs = chart.getDatasetMeta(0).data.map((element) => element.x);
      const area = chart.chartArea;
      this.y = (area.top + area.bottom) / 2;
    }
    move(chart, index) { benchEvent(chart, 'mousemove', this.xs[index], this.y); }
    out(chart) { benchEvent(chart, 'mouseout', -1, this.y); }
  }

  /** _tooltipScene. */
  function tooltipScene(datasets, n, {tooltip, animate, prepare, frame}) {
    const series = new BenchSeries(datasets, n);
    const timing = new PluginTiming(true);
    const config = benchConfig('line', series, {
      datasets: Array.from({length: datasets}, (_, k) => benchDataset(k, series.data[k])),
      options: {
        ...(animate ? {} : {animation: false}),
        interaction: {mode: 'index', intersect: false},
        plugins: {legend: false, ...(tooltip ? {} : {tooltip: false})},
      },
      plugins: timing.plugins,
    });
    if (animate) config.platform = AnimatedBasicPlatform;
    return {config, takeParts: () => timing.take(), prepare, frame};
  }

  const tooltipKeys = (datasets, tooltip) => ({datasets, tooltip});

  /** _hoverCase. */
  const hoverCase = (datasets, tooltip) => pluginCase('tooltip', 'hover', 'frame', {
    counts: PLUGIN_COUNTS,
    keys: tooltipKeys(datasets, tooltip),
    scene(n) {
      const pointer = new BenchPointer();
      let index = 0;
      return tooltipScene(datasets, n, {
        tooltip,
        animate: false,
        prepare: (chart) => pointer.measure(chart),
        frame: (chart) => {
          index = (index + 1) % n;
          pointer.move(chart, index);
        },
      });
    },
  });

  /** _stillCase. */
  const stillCase = (datasets, tooltip) => pluginCase('tooltip', 'still', 'draw', {
    counts: PLUGIN_COUNTS,
    keys: tooltipKeys(datasets, tooltip),
    scene(n) {
      const pointer = new BenchPointer();
      return tooltipScene(datasets, n, {
        tooltip,
        animate: true,
        prepare: (chart) => {
          benchFinishAnimations();
          pointer.measure(chart);
          pointer.move(chart, Math.trunc(n / 2));
          benchFinishAnimations();
        },
      });
    },
  });

  /** _fadeCase. */
  const fadeCase = (datasets) => pluginCase('tooltip', 'fade', 'frame', {
    counts: PLUGIN_COUNTS,
    keys: tooltipKeys(datasets, true),
    scene(n) {
      const pointer = new BenchPointer();
      let frame = 0;
      let fade = 0;
      let phase = 0.0;
      let shown = false;
      let start = 0.0;
      return tooltipScene(datasets, n, {
        tooltip: true,
        animate: true,
        prepare: (chart) => {
          benchFinishAnimations();
          pointer.measure(chart);
        },
        frame: (chart) => {
          if (frame === 0) {
            shown = !shown;
            if (shown) pointer.move(chart, Math.trunc(n / 2));
            else pointer.out(chart);
            start = Date.now();
            phase = (fade * FADE_PHASE) % 1;
            fade++;
          }
          frame++;
          benchTick(start + (frame + phase) * FRAME_MS);
          if (frame === FADE_FRAMES) frame = 0;
        },
      });
    },
  });

  /** _fillCase. */
  const fillCase = (name, call) => pluginCase('fill', name, call, {
    counts: PLUGIN_COUNTS,
    keys: {datasets: 3},
    scene(n) {
      const timing = new PluginTiming();
      const series = name === 'gaps'
        ? new BenchSeries(3, n, {scale: 2, offset: -1, gapEvery: 12})
        : new BenchSeries(3, n);
      let scales;
      let fills;
      switch (name) {
        case 'gaps':
          scales = benchHiddenScales({min: -1, max: 1});
          fills = [0, 1, 2].map(() => ({target: 'origin', above: FILLS[1], below: FILLS[0]}));
          break;
        case 'stack':
          scales = benchHiddenScales({min: 0, max: 3, stacked: true});
          fills = ['stack', 'stack', 'stack'];
          break;
        default:
          scales = {r: hidden('radialLinear', 0, 1)};
          fills = ['origin', '-1', '-1'];
      }
      return {
        config: benchConfig(name === 'radar' ? 'radar' : 'line', series, {
          datasets: [0, 1, 2].map((k) => benchDataset(k, series.data[k], {fill: fills[k], pointRadius: 0.0})),
          options: {animation: false, events: [], scales, plugins: {legend: false}},
          plugins: timing.plugins,
        }),
        change: () => series.step(),
        takeParts: () => timing.take(),
      };
    },
  });

  /** _boxCase. */
  const boxCase = (mode, call, {legend, title}) => pluginCase(mode, 'line', call, {
    counts: PLUGIN_COUNTS,
    keys: {datasets: 3, legend, title},
    scene(n) {
      const timing = new PluginTiming();
      const series = new BenchSeries(3, n);
      return {
        config: benchConfig('line', series, {
          datasets: [0, 1, 2].map((k) => benchDataset(k, series.data[k])),
          options: {
            animation: false,
            events: [],
            plugins: {
              ...(legend ? {} : {legend: false}),
              ...(title ? {title: {display: true, text: 'Chart.js Line Chart'}} : {}),
            },
          },
          plugins: timing.plugins,
        }),
        change: () => series.step(),
        takeParts: () => timing.take(),
      };
    },
  });

  /** _motionCase. */
  const motionCase = (type) => ({
    mode: 'motion', name: type, call: 'motion', counts: MOTION_COUNTS,
    keys: {type, sharing: TYPES[type].sharing, scriptable: false},
    primary: frameMetric('motion'),
    scene(n) {
      const field = new Field(n);
      const scene = new Scene(type, n, field);
      const timing = new Timing();
      const config = stressChartConfig(scene, false, [timing.plugin]);
      // The default animations: no option `animation: false`.
      delete config.options.animation;
      config.platform = AnimatedBasicPlatform;
      return {config, takeParts: () => timing.take(), prepare: () => benchFinishAnimations()};
    },
  });

  /** stressDelayByIndex of motion.line.delay. */
  const delayByIndex = (ctx) => ctx.type === 'data' ? ctx.dataIndex : 0;

  /** _motionDelayCase: motion.line with a scriptable delay. */
  const motionDelayCase = () => ({
    mode: 'motion', name: 'line.delay', call: 'motion', counts: MOTION_COUNTS, explicit: true,
    keys: {type: 'line', sharing: true, scriptable: false, delay: true},
    primary: frameMetric('motion'),
    scene(n) {
      const field = new Field(n);
      const scene = new Scene('line', n, field);
      const timing = new Timing();
      const config = stressChartConfig(scene, false, [timing.plugin]);
      // The default animations with a scriptable delay.
      config.options.animation = {delay: delayByIndex};
      config.platform = AnimatedBasicPlatform;
      return {config, takeParts: () => timing.take(), prepare: () => benchFinishAnimations()};
    },
  });

  /** _indexableCase: chart.c with an indexable backgroundColor. */
  const indexableCase = () => ({
    mode: 'chart', name: 'c.indexable', call: 'update', counts: null, explicit: true,
    keys: {type: 'line', sharing: true, scriptable: false, indexable: true},
    primary: frameMetric('update'),
    scene(n) {
      const field = new Field(n);
      const scene = new Scene('line', n, field);
      const timing = new Timing();
      const config = stressChartConfig(scene, false, [timing.plugin]);
      config.data.datasets[0].backgroundColor = [BG, BG_ODD];
      return {
        config,
        change: () => { field.step(n, STEP); scene.write(field); },
        takeParts: () => timing.take(),
      };
    },
  });

  /** _primitiveCase: a line of parsed numbers on a hidden category axis. */
  const primitiveCase = () => ({
    mode: 'chart', name: 'line.primitive', call: 'update', counts: null, explicit: true,
    keys: {type: 'line', sharing: true, scriptable: false, parsing: true},
    primary: frameMetric('update'),
    scene(n) {
      const field = new Field(n);
      const data = Array.from({length: n}, (_, i) => field.y[i]);
      const timing = new Timing();
      const config = {
        type: 'line',
        data: {
          labels: Array.from({length: n}, (_, i) => `Point ${i}`),
          datasets: [{
            data,
            backgroundColor: BG,
            borderColor: '#36A2EB',
            borderWidth: 1.0,
            pointStyle: 'circle',
            radius: 3.0,
            showLine: false,
            clip: false,
          }],
        },
        options: {
          animation: false,
          events: [],
          maintainAspectRatio: false,
          plugins: {legend: false},
          layout: {autoPadding: false},
          scales: {x: hidden('category'), y: hidden('linear', 0, 1)},
          ...BENCH_OPTIONS,
        },
        plugins: [timing.plugin],
      };
      return {
        config,
        change: () => {
          field.step(n, STEP);
          for (let i = 0; i < n; i++) data[i] = field.y[i];
        },
        takeParts: () => timing.take(),
      };
    },
  });

  // chartBenchCases without the axes cases and the theme cases, then
  // chartBenchExplicitCases.
  const cases = [
    stressCase('a', 'draw', 'line'),
    stressCase('b', 'update', 'line'),
    stressCase('b', 'update', 'scatter'),
    stressCase('c', 'update', 'line', {scriptable: true}),
    ...['bar', 'bubble', 'doughnut', 'pie', 'polarArea', 'radar'].flatMap((t) =>
      ['draw', 'update'].map((call) => stressCase(t, call, t, {counts: TYPES[t].counts}))),
    // _pluginCases.
    ...[3, 100].flatMap((datasets) => ['draw', 'update'].flatMap((call) =>
      ['A', 'B'].map((config) => dispatchCase(config, datasets, call)))),
    ...[3, 10].flatMap((datasets) => [
      hoverCase(datasets, true),
      hoverCase(datasets, false),
      stillCase(datasets, true),
      stillCase(datasets, false),
      fadeCase(datasets),
    ]),
    ...['gaps', 'stack', 'radar'].flatMap((name) => ['draw', 'update'].map((call) => fillCase(name, call))),
    ...['draw', 'update'].flatMap((call) => [
      boxCase('legend', call, {legend: true, title: false}),
      boxCase('legend', call, {legend: false, title: false}),
      boxCase('title', call, {legend: false, title: true}),
    ]),
    // _motionCases.
    motionCase('line'),
    motionCase('bar'),
    // chartBenchExplicitCases.
    motionDelayCase(),
    indexableCase(),
    primitiveCase(),
  ];
  for (const c of cases) {
    c.id = `${c.mode}.${c.name}`;
    c.explicit = c.explicit === true;
  }

  /** ChartBenchCase.selectedBy. */
  const selectedBy = (c, s) => c.explicit ? s === c.id : s === c.mode || s === c.name || s === c.id;

  /** selectChartBenchCases. */
  function select(selection) {
    const selectors = (selection || '').split(',').map((s) => s.trim()).filter(Boolean);
    if (!selectors.length) return cases.filter((c) => !c.explicit);
    for (const s of selectors) {
      if (!cases.some((c) => selectedBy(c, s))) throw new Error(`CASES: ${s} selects no case`);
    }
    return cases.filter((c) => selectors.some((s) => selectedBy(c, s)));
  }

  /** _BenchChart: the time of each draw, and the count of the notifies. */
  class BenchChart extends Chart {
    drawTicks = 0;
    notifies = 0;
    draw() {
      const start = performance.now();
      super.draw();
      this.drawTicks = (this.drawTicks || 0) + (performance.now() - start);
    }
    notifyPlugins(hook, args, filter) {
      this.notifies = (this.notifies || 0) + 1;
      return super.notifyPlugins(hook, args, filter);
    }
  }

  /** runChartBenchCase and _Loop, without the end of the recording. */
  function runCase(benchCase, n, settings) {
    const startMs = Date.now();
    const wall0 = performance.now();
    const scene = benchCase.scene(n);
    // The port gives a chart with no host the BasicPlatform.
    if (!('platform' in scene.config)) scene.config.platform = BasicPlatform;
    const canvas = env.makeCanvas();
    const chart = new BenchChart(canvas, scene.config);
    try {
      scene.prepare?.(chart);
      const call = benchCase.call;
      let updateT = 0;
      let drawT = 0;
      const iterate = () => {
        if (call === 'update') scene.change?.();
        // The animations of the last motion update end, outside the timing.
        if (call === 'motion') chart.stop();
        chart.drawTicks = 0;
        chart.notifies = 0;
        const start = performance.now();
        switch (call) {
          case 'draw': chart.draw(); break;
          case 'update': chart.update('none'); break;
          case 'frame': scene.frame(chart); break;
          case 'motion': chart.update(); break;
          default: throw new Error(`call ${call}`);
        }
        const called = performance.now();
        drawT += chart.drawTicks;
        updateT += called - start - chart.drawTicks;
      };
      const reset = () => { updateT = 0; drawT = 0; scene.takeParts?.(); };
      const w0 = performance.now();
      let warmupIterations = 0;
      let first = 0;
      let elapsed;
      do {
        iterate();
        warmupIterations++;
        elapsed = performance.now() - w0;
        if (warmupIterations === 1) first = elapsed;
      } while (elapsed < settings.warmupMs);
      const perIteration = warmupIterations === 1 ? first : (elapsed - first) / (warmupIterations - 1);
      const batchIterations = perIteration <= 0
        ? 1
        : Math.min(Math.max(Math.round(settings.batchMs / perIteration), 1), 1 << 20);
      const update = [];
      const draw = [];
      const parts = {};
      for (let b = 0; b < settings.batches; b++) {
        reset();
        for (let i = 0; i < batchIterations; i++) iterate();
        update.push(updateT / batchIterations);
        draw.push(drawT / batchIterations);
        const p = scene.takeParts?.() ?? {};
        for (const k of Object.keys(p)) (parts[k] ||= []).push(p[k] / batchIterations);
      }
      const wallMs = Math.round(performance.now() - wall0);
      return {
        mode: benchCase.mode,
        case: benchCase.name,
        n,
        ...benchCase.keys,
        call,
        ...(benchCase.primary ? {primary: benchCase.primary} : {}),
        iterations: settings.batches * batchIterations,
        notifies: chart.notifies,
        ...(call !== 'draw' ? figures('update', update) : {}),
        ...figures('draw', draw),
        ...Object.fromEntries(Object.entries(parts).flatMap(([k, v]) => Object.entries(figures(k, v)))),
        batches: settings.batches,
        batchIterations,
        batchMs: settings.batchMs,
        warmupMs: settings.warmupMs,
        warmupIterations,
        width: WIDTH,
        height: HEIGHT,
        dpr: 1,
        build: env.build,
        platform: env.platform,
        startMs,
        wallMs,
      };
    } finally {
      chart.destroy();
    }
  }

  /**
   * The check of the field: 120 steps of 1/60 s of the first 5000 points,
   * as field_gen.dart writes it. Both sums must be equal.
   */
  function fieldCheck() {
    const f = new Field(FIELD.check.n);
    for (let s = 0; s < FIELD.check.steps; s++) f.step(FIELD.check.n, STEP);
    let sumX = 0;
    let sumY = 0;
    for (let i = 0; i < FIELD.check.n; i++) { sumX += f.x[i]; sumY += f.y[i]; }
    return {sumX, sumY, dartSumX: FIELD.check.sumX, dartSumY: FIELD.check.sumY,
      equal: sumX === FIELD.check.sumX && sumY === FIELD.check.sumY};
  }

  return {cases, select, runCase, fieldCheck};
}
