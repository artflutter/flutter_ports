// Original code, not ported from Chart.js: chart host input reference generator.
//
// It writes test/port/platform/chart_host_input_reference.dart, the data of
// test/port/platform/chart_host_input_test.dart: the input path of the
// legend and the tooltip (the host, the throttle, `_eventHandler`, the
// legend and the tooltip) against a build of the pinned Chart.js (Chart.js
// ADR 0037, section 17). See the headers of
// tool/reference/controller_chart_common.mjs and
// tool/reference/scale_chart_common.mjs for the method, the build, the
// checks of loadChartJs and the limits of the text measure.
//
// The method
// ----------
//
// Each case is a line chart of makeChart (the `_acquireChart` config of the
// Dart test: a 512 x 512 canvas, `animation: false`) with 2 datasets and 4
// labels, legend callbacks that log (`onClick` then calls the default
// `onClick`) and an inline plugin `log` whose `beforeEvent` logs each chart
// event. The components are the components of the Dart registry:
// registerBuiltins (Chart.js ADR 0041, section 1).
//
// A step of a case is one frame: a list of gesture actions, then the end of
// the frame. The actions are the Flutter pointer events of the Dart test:
// `touchDown` (with the kind `stylus` as an optional fourth item),
// `touchMove` and `touchUp` (one touch-like pointer at a time), `wait` (the
// time of the frame, for the long press), and `mouseAdd`, `mouseMove` and
// `mouseRemove` (one mouse pointer). The class Browser below gives the DOM
// events that Chrome sends to the canvas for each action (Chart.js ADR 0037,
// sections 6 to 9): the touch boundary events, the compatibility mouse
// events of a tap and of a long press, the `mouseout` and `mouseleave` of a
// tap outside, and the boundary events of the mouse. The touch rules come
// from the device check P4 of Chart.js ADR 0037 (Chrome 155.0.8059.84 on a
// Pixel 8a) and the Chromium source at that tag:
//
// - A stylus in contact gives the touch events (P4 row ST1).
// - A move with no change of the point gives no event (P4 rows T12, T13 and
//   LP300 to LP700; passthrough_touch_event_queue.cc, HasPointChanged).
// - The slop limit is the slop plus 0.05, the stylus slop 1.5 times the
//   touch slop (gesture_detector.cc, kSlopEpsilon;
//   gesture_configuration_android.cc).
// - The tap candidate gives only `pointermove` inside its slop limit (P4
//   rows S04 and S07; touch_event_manager.cc).
// - The first move past the slop limit begins the pan, also after a long
//   press: `pointermove`, `touchmove`, then `pointercancel`, `pointerout`
//   and `pointerleave` at the client point (0, 0), then only `touchmove`
//   and `touchend` (P4 rows T14, T15 and S10 to S30;
//   pointer_event_manager.cc, pointer_event_factory.cc).
// - The compatibility events and `click` of a tap, and the `mousemove` of a
//   long press, are at the down position, and so is the `mouseout` of a tap
//   or a long press outside (P4 rows S04 and S07; gesture_provider.cc).
// - A stylus tap is at the up position: its compatibility events and
//   `click`, or the `mouseout` and `mouseleave` of the canvas when the up
//   position is outside it (P4 row STN10; Blink event_handler.cc gives a
//   pen no touch adjustment). The long press of a stylus stays at the down
//   position (gesture_detector.cc).
//
// The model sends one DOM event for each action that gives events. Chrome
// coalesces the moves of one frame (Chart.js ADR 0037, Open 10). Thus the
// mouse cases with two or more moves in one step pin the model, not a
// Chrome log. The
// `BasicPlatform` of Node.js has no event listeners. Thus the
// generator feeds `chart._eventHandler` itself with the chart events that
// `fromNativeEvent` makes (platform.dom.js:109-119): for each type that
// `options.events` lists (core.controller.js:976-990), the last event of
// that type in the frame, in the order of the first event of each type in
// the frame (the throttled proxies of platform.dom.js:240-254 and
// helpers.extras.ts:27-45, Chart.js ADR 0037, section 11). The position is
// the `Math.round` of the offsets (helpers.dom.ts:127-130). A `touchend` or
// a `touchcancel` has no touches and no offsets: its position is NaN
// (helpers.dom.ts:73-93).
//
// The observation after each step: the DOM events of the frame as
// `[type, x, y]` (the position that `getRelativePosition` gives), the chart
// events of the `log` plugin as `[type, native type, x, y, replay]`,
// `chart.getActiveElements()` and `chart.tooltip.getActiveElements()` as
// `[datasetIndex, index]`, `chart.tooltip.opacity`, the legend log of the
// step (`hover|leave|click:<e.type>:<item.text>`) and
// `chart.isDatasetVisible(i)` of each dataset, and `chart._lastEvent` as
// `[type, native type, x, y]` or null (input spec section 4.4; the Dart
// test reads `lastEvent`, the `@internal` name of the port, Chart.js ADR
// 0012). Each case ends
// with `chart.update()`, which replays `_lastEvent`
// (core.controller.js:529-532): the key `replay` has the chart events of
// that update.
//
// The header of the data file has the DOM types of each step, as comment
// lines.
//
// Usage, from packages/flutter_chartjs_port, with an x64 build of Node.js
// v24.12.0 and the Dart SDK on the PATH:
//
//   CHARTJS_DIST=<build>/dist/chart.js \
//     node tool/reference/chart_host_input_reference.mjs
//
// The path can also be the first argument.

import {fileURLToPath} from 'node:url';

import {
  loadChartJs,
  makeChart,
  named,
  registerBuiltins,
  writeReference,
} from './controller_chart_common.mjs';

const OUT = fileURLToPath(
  new URL('../../test/port/platform/chart_host_input_reference.dart', import.meta.url),
);

const C = await loadChartJs();
registerBuiltins(C);

/** The canvas size of `_acquireChart` (chartjs-test-utils src/utils.js:41). */
const SIZE = 512;

/**
 * The touch slop: `computeHitSlop(PointerDeviceKind.touch, null)` of the
 * test view, `kTouchSlop` (Chart.js ADR 0037, section 8). The view of
 * flutter_test has no platform touch slop.
 */
const SLOP = 18;

/** Chromium `kSlopEpsilon` (gesture_detector.cc): the slop limit is the slop plus this. */
const SLOP_EPSILON = 0.05;

/** The stylus slop is 1.5 times the touch slop (gesture_configuration_android.cc). */
const STYLUS_SLOP_FACTOR = 1.5;

/** The slop limit of a pointer of [kind]: 18.05 for a touch, 27.05 for a stylus. */
const limit = (kind) => (kind === 'stylus' ? SLOP * STYLUS_SLOP_FACTOR : SLOP) + SLOP_EPSILON;

/**
 * The position of the cancel events of a pan in the canvas: Chrome gives
 * `pointercancel`, `pointerout` and `pointerleave` the client point (0, 0)
 * (P4 D3), and the canvas of `_acquireChart` is at the origin of the test
 * view.
 */
const ORIGIN = {x: 0, y: 0};

/** `kLongPressTimeout` in ms (Chart.js ADR 0037, section 8). */
const LONG_PRESS = 500;

/** EVENT_TYPES of platform.dom.js:21-31. */
const EVENT_TYPES = {
  touchstart: 'mousedown',
  touchmove: 'mousemove',
  touchend: 'mouseup',
  pointerenter: 'mouseenter',
  pointerdown: 'mousedown',
  pointermove: 'mousemove',
  pointerup: 'mouseup',
  pointerleave: 'mouseout',
  pointerout: 'mouseout',
};

/** True when [p] hits the canvas box. */
const inside = (p) => p.x >= 0 && p.y >= 0 && p.x < SIZE && p.y < SIZE;

/**
 * The DOM events that Chrome sends to the canvas for the gesture actions of
 * the Dart test (Chart.js ADR 0037, sections 6 to 9). One canvas, one
 * touch-like pointer and one mouse pointer at a time. The model has its own
 * state and does not read the chart.
 */
class Browser {
  constructor() {
    /** The DOM events of the current frame: `[type, x, y]`. */
    this.dom = [];
    /** The time in ms. */
    this.now = 0;
    /** True while the compatibility mouse is over the canvas (section 9). */
    this.owner = false;
    /** The touch-like pointer: `{p, p0, kind, onHost, panned}`, or null. */
    this.touch = null;
    /** The tap candidate of the touch (section 8): `{p0, down, long}`, or null. */
    this.tap = null;
    /** The position of the mouse pointer, or null. */
    this.mouse = null;
  }

  emit(types, p) {
    for (const type of types) this.dom.push([type, p.x, p.y]);
  }

  /** A touch event: its position comes from `touches`. */
  emitTouch(type, p) {
    this.dom.push(type === 'touchend' || type === 'touchcancel' ? [type, NaN, NaN] : [type, p.x, p.y]);
  }

  touchDown(x, y, kind = 'touch') {
    if (this.touch) throw new Error('One touch pointer at a time.');
    const p = {x, y};
    const onHost = inside(p);
    this.touch = {p, p0: p, kind, onHost, panned: false};
    if (onHost) {
      this.emit(['pointerover', 'pointerenter', 'pointerdown'], p);
      this.emitTouch('touchstart', p);
      this.tap = {p0: p, down: this.now, long: false};
    } else {
      // The global route watches the touches outside only while the
      // compatibility mouse is over a canvas (section 9).
      this.tap = this.owner ? {p0: p, down: this.now, long: false} : null;
    }
  }

  touchMove(x, y) {
    const p = {x, y};
    const touch = this.touch;
    // No event for a move with no change of the point (P4 D2).
    if (p.x === touch.p.x && p.y === touch.p.y) return;
    touch.p = p;
    const beyond = !touch.panned && Math.hypot(p.x - touch.p0.x, p.y - touch.p0.y) > limit(touch.kind);
    if (touch.onHost) {
      if (touch.panned) {
        this.emitTouch('touchmove', p);
      } else if (beyond) {
        // The pan begins: Chrome cancels the pointer events (P4 D3), also
        // after a long press.
        this.emit(['pointermove'], p);
        this.emitTouch('touchmove', p);
        this.emit(['pointercancel', 'pointerout', 'pointerleave'], ORIGIN);
        touch.panned = true;
        this.tap = null;
      } else {
        // The tap candidate gives no touchmove inside its slop limit (P4 D1).
        this.emit(['pointermove'], p);
        if (!this.tap) this.emitTouch('touchmove', p);
      }
    } else if (beyond) {
      this.tap = null;
    }
  }

  touchUp() {
    const {p, onHost, panned} = this.touch;
    const tap = this.tap && !this.tap.long;
    if (onHost && panned) {
      this.emitTouch('touchend', p);
    } else if (onHost) {
      this.emit(['pointerup', 'pointerout', 'pointerleave'], p);
      this.emitTouch('touchend', p);
      if (tap) {
        // The compatibility events of a tap are at its tap point (P4 D4 and
        // STN10). Chrome hit-tests the tap there.
        const q = this.tapPoint();
        if (inside(q)) {
          if (!this.owner) this.emit(['mouseover', 'mouseenter'], q);
          this.owner = true;
          this.emit(['mousemove', 'mousedown', 'mouseup', 'click'], q);
        } else if (this.owner) {
          this.emit(['mouseout', 'mouseleave'], q);
          this.owner = false;
        }
      }
    } else if (tap && this.owner) {
      this.emit(['mouseout', 'mouseleave'], this.tapPoint());
      this.owner = false;
    }
    this.touch = null;
    this.tap = null;
  }

  /**
   * The tap point of the touch-like pointer: the up position (the last
   * position of the model) for a stylus, which Chrome gives no touch
   * adjustment (P4 STN10), else the down position (P4 D4).
   */
  tapPoint() {
    return this.touch.kind === 'stylus' ? this.touch.p : this.tap.p0;
  }

  wait(ms) {
    this.now += ms;
    const tap = this.tap;
    if (!tap || tap.long || this.now - tap.down < LONG_PRESS) return;
    // The long press is at the down position (P4 D4).
    const p = tap.p0;
    if (this.touch.onHost) {
      tap.long = true;
      if (!this.owner) this.emit(['mouseover', 'mouseenter'], p);
      this.owner = true;
      this.emit(['mousemove'], p);
    } else {
      if (this.owner) this.emit(['mouseout', 'mouseleave'], p);
      this.owner = false;
      this.tap = null;
    }
  }

  mouseAdd(x, y) {
    if (this.mouse) throw new Error('One mouse pointer at a time.');
    const p = {x, y};
    if (inside(p)) throw new Error('Add the mouse pointer outside the canvas.');
    this.mouse = p;
  }

  mouseMove(x, y) {
    const p = {x, y};
    const was = inside(this.mouse);
    const is = inside(p);
    if (was && !is) this.emit(['pointerout', 'pointerleave', 'mouseout', 'mouseleave'], p);
    if (!was && is) this.emit(['pointerover', 'pointerenter', 'mouseover', 'mouseenter'], p);
    if (is) this.emit(['pointermove', 'mousemove'], p);
    this.mouse = p;
  }

  mouseRemove() {
    if (inside(this.mouse)) {
      this.emit(['pointerout', 'pointerleave', 'mouseout', 'mouseleave'], this.mouse);
    }
    this.mouse = null;
  }
}

/**
 * The end of a frame: one `_eventHandler` call for each type of
 * `options.events` in [dom], with the last event of that type, in the
 * order of the first event of each type (Chart.js ADR 0037, section 11).
 */
function endFrame(chart, dom) {
  const listened = chart.options.events;
  const last = new Map();
  for (const event of dom) {
    if (listened.includes(event[0])) last.set(event[0], event);
  }
  for (const [type, x, y] of last.values()) {
    chart._eventHandler({type: EVENT_TYPES[type] || type, chart, native: {type}, x, y});
  }
}

// The logs of the current case.
let events = [];
let legend = [];

const logEvent = named('logEvent', (chart, args) => {
  const e = args.event;
  events.push([e.type, e.native.type, e.x, e.y, args.replay === true]);
});
const legendHover = named('legendHover', (e, item) => {
  legend.push(`hover:${e.type}:${item.text}`);
});
const legendLeave = named('legendLeave', (e, item) => {
  legend.push(`leave:${e.type}:${item.text}`);
});
const legendClick = named('legendClick', function (e, item, legendBox) {
  legend.push(`click:${e.type}:${item.text}`);
  C.Chart.defaults.plugins.legend.onClick.call(this, e, item, legendBox);
});

/** The config of a case: [events] is `options.events`, or the default. */
function config(eventTypes) {
  return {
    type: 'line',
    data: {
      labels: ['a', 'b', 'c', 'd'],
      datasets: [
        {label: 'one', data: [1, 3, 2, 4]},
        {label: 'two', data: [4, 2, 3, 1]},
      ],
    },
    options: {
      ...(eventTypes ? {events: eventTypes} : {}),
      plugins: {
        legend: {onHover: legendHover, onLeave: legendLeave, onClick: legendClick},
      },
    },
    plugins: [{id: 'log', beforeEvent: logEvent}],
  };
}

/** A copy of [v] that keeps the functions. */
function copy(v) {
  if (Array.isArray(v)) return v.map(copy);
  if (v && typeof v === 'object') {
    return Object.fromEntries(Object.entries(v).map(([k, x]) => [k, copy(x)]));
  }
  return v;
}

/** `chart._lastEvent` as `[type, native type, x, y]`, or null. */
function lastEvent(chart) {
  const e = chart._lastEvent;
  return e ? [e.type, e.native.type, e.x, e.y] : null;
}

/** `[datasetIndex, index]` of each active element. */
const activeItems = (list) => list.map((a) => [a.datasetIndex, a.index]);

/** The points of a chart of [config]: see the cases below. */
function points() {
  const chart = makeChart(config());
  const round = (p) => ({x: Math.round(p.x), y: Math.round(p.y)});
  const point = chart.getDatasetMeta(0).data[1];
  const center = (box) => round({x: box.left + box.width / 2, y: box.top + box.height / 2});
  const [box, box2] = chart.legend.legendHitBoxes;
  const area = chart.chartArea;
  const at = {
    // Point 1 of dataset 0.
    P: round(point),
    // The center of legend item 1.
    L: center(box),
    // The center of legend item 2.
    L2: center(box2),
    // The center of the chart area: no element.
    E: round({x: (area.left + area.right) / 2, y: (area.top + area.bottom) / 2}),
    // A point of the 800 x 600 test view outside the canvas.
    O: {x: 700, y: 300},
  };
  // The start of the drag: 40 px below P, and a point between.
  at.Q = {x: at.P.x, y: at.P.y + 40};
  at.R = {x: at.P.x, y: at.P.y + 20};
  for (const key of ['E', 'Q', 'R']) {
    const p = at[key];
    if (!chart.isPointInArea(p)) throw new Error(`${key} is not in the chart area.`);
    const e = {type: 'mousemove', chart, native: {type: 'mousemove'}, x: p.x, y: p.y};
    const near = chart.getElementsAtEventForMode(e, 'nearest', {intersect: true}, false);
    if (near.length) throw new Error(`${key} hits an element.`);
  }
  for (const key of ['L', 'L2']) {
    if (chart.isPointInArea(at[key])) throw new Error(`${key} is not outside the chart area.`);
  }
  chart.destroy();
  return at;
}

const AT = points();
const {P, L, L2, E, O, Q, R} = AT;
// The stylus tap from legend item 1 lifts 20 px above it, outside the canvas.
if (inside({x: L.x, y: L.y - 20})) throw new Error('L is more than 20 px below the top.');

/** The steps of a touch tap at [p]: the down, then the up. */
const tap = (p) => [[['touchDown', p.x, p.y]], [['touchUp']]];

/** The steps of a long press at [p]: the down, the wait, then the up. */
const longPress = (p) => [[['touchDown', p.x, p.y]], [['wait', LONG_PRESS]], [['touchUp']]];

/** The default `events` with [extra]. */
const defaultEventsWith = (...extra) => [...C.Chart.defaults.events, ...extra];

/** The DOM type lines of the header: at most 80 characters each. */
const notes = [];

/** Runs the case [name] with the steps [steps] and the events [eventTypes]. */
function runCase(name, steps, eventTypes) {
  const cfg = config(eventTypes);
  const saved = copy(cfg);
  events = [];
  legend = [];
  const chart = makeChart(cfg);
  const browser = new Browser();
  const observations = [];
  notes.push(`${name}:`);
  for (const [i, step] of steps.entries()) {
    browser.dom = [];
    events = [];
    legend = [];
    // The Dart test pumps the time of a `wait` at the end of the step.
    if (step.length > 1 && step.some(([action]) => action === 'wait')) {
      throw new Error('A wait is alone in its step.');
    }
    for (const [action, ...args] of step) browser[action](...args);
    const dom = browser.dom;
    endFrame(chart, dom);
    observations.push({
      dom,
      events,
      active: activeItems(chart.getActiveElements()),
      tooltip: activeItems(chart.tooltip.getActiveElements()),
      opacity: chart.tooltip.opacity,
      legend,
      visible: chart.data.datasets.map((_, d) => chart.isDatasetVisible(d)),
      lastEvent: lastEvent(chart),
    });
    let line = `  ${i}:`;
    for (const [type] of dom.length ? dom : [['(none)']]) {
      if (line.length + 1 + type.length > 77) {
        notes.push(line);
        line = '   ';
      }
      line += ` ${type}`;
    }
    notes.push(line);
  }
  events = [];
  chart.update();
  const replay = events;
  chart.destroy();
  return {name, config: saved, options: {}, expected: {steps, observations, replay}};
}

const cases = [
  runCase('a touch tap on a point', tap(P)),
  runCase('a tap outside the chart after a tap on a point', [...tap(P), ...tap(O)]),
  runCase('a tap on an empty point of the chart area after a tap on a point', [
    ...tap(P),
    ...tap(E),
  ]),
  runCase('events mousemove only: a touch tap on a point', tap(P), ['mousemove']),
  runCase('a tap on legend item 1, then a tap outside', [...tap(L), ...tap(O)]),
  runCase('events with mouseup: a tap on legend item 1', tap(L), defaultEventsWith('mouseup')),
  runCase('events with pointerup: a tap on legend item 1', tap(L), defaultEventsWith('pointerup')),
  runCase('events with pointerout: a touch tap on a point', tap(P), defaultEventsWith('pointerout')),
  runCase('events touchstart and pointerout: a touch tap on a point', tap(P), [
    'touchstart',
    'pointerout',
  ]),
  runCase('events with touchend: a touch tap on a point', tap(P), defaultEventsWith('touchend')),
  // The NaN position of the touchend is outside the chart area: without the
  // compatibility mousemove and click, the lift keeps the tooltip.
  runCase('events touchstart and touchend: a touch tap on a point', tap(P), [
    'touchstart',
    'touchend',
  ]),
  runCase('a long press on a point, then on legend item 1', [...longPress(P), ...longPress(L)]),
  // Without touchstart, only the mousemove of the long press shows the
  // tooltip before the lift.
  runCase('events mousemove, mouseout and click: a long press on a point', longPress(P), [
    'mousemove',
    'mouseout',
    'click',
  ]),
  runCase('mouse: a move onto legend item 1 and an exit in one frame', [
    [
      ['mouseAdd', O.x, O.y],
      ['mouseMove', L.x, L.y],
      ['mouseMove', O.x, O.y],
    ],
  ]),
  runCase('mouse: an exit and a move back onto legend item 1 in one frame', [
    [
      ['mouseAdd', O.x, O.y],
      ['mouseMove', L.x, L.y],
    ],
    [
      ['mouseMove', O.x, O.y],
      ['mouseMove', L.x, L.y],
    ],
  ]),
  // Two mousemove events in one frame: the proxy gives the last one, at
  // legend item 1 (helpers.extras.ts:27-45).
  runCase('mouse: legend item 2, an exit and legend item 1 in one frame', [
    [
      ['mouseAdd', O.x, O.y],
      ['mouseMove', L2.x, L2.y],
      ['mouseMove', O.x, O.y],
      ['mouseMove', L.x, L.y],
    ],
  ]),
  runCase('mouse: a removal of the pointer inside legend item 1', [
    [
      ['mouseAdd', O.x, O.y],
      ['mouseMove', L.x, L.y],
    ],
    [['mouseRemove']],
  ]),
  runCase('a tap on a point with a move of 10 px inside the slop', [
    [['touchDown', P.x, P.y]],
    [['touchMove', P.x + 10, P.y]],
    [['touchUp']],
  ]),
  runCase('a touch held on legend item 1 with a move to the same position', [
    [['touchDown', L.x, L.y]],
    [['touchMove', L.x, L.y]],
    [['touchUp']],
  ]),
  runCase(
    'events with pointerup, pointerout: a drag from E to legend item 1',
    [
      [['touchDown', E.x, E.y]],
      [['touchMove', E.x, E.y - 40]],
      [['touchMove', L.x, L.y]],
      [['touchUp']],
    ],
    defaultEventsWith('pointerup', 'pointerout'),
  ),
  runCase('a stylus tap on a point', [[['touchDown', P.x, P.y, 'stylus']], [['touchUp']]]),
  runCase(
    'events mousemove only: a stylus tap on a point',
    [[['touchDown', P.x, P.y, 'stylus']], [['touchUp']]],
    ['mousemove'],
  ),
  // 20 px is past the touch slop limit (18.05) and inside the stylus slop
  // limit (27.05). The tap is at the up position, 20 px from the point
  // (P4 STN10): the tooltip does not show.
  runCase('a stylus drag of 20 px from a point stays a tap', [
    [['touchDown', P.x, P.y, 'stylus']],
    [['touchMove', P.x + 20, P.y]],
    [['touchUp']],
  ]),
  runCase('a stylus drag of 30 px from a point cancels', [
    [['touchDown', P.x, P.y, 'stylus']],
    [['touchMove', P.x + 30, P.y]],
    [['touchUp']],
  ]),
  // The up position of the stylus tap is outside the canvas (P4 STN10): the
  // compatibility mouse leaves the canvas, and legend item 1 gets no click.
  runCase('a tap on a point, then a stylus tap from legend item 1 to outside', [
    ...tap(P),
    [['touchDown', L.x, L.y, 'stylus']],
    [['touchMove', L.x, L.y - 20]],
    [['touchUp']],
  ]),
  runCase('a tap on a point, then a stylus tap outside with a move of 10 px', [
    ...tap(P),
    [['touchDown', O.x, O.y, 'stylus']],
    [['touchMove', O.x + 10, O.y]],
    [['touchUp']],
  ]),
  runCase('a long press on a point, then a drag past the slop', [
    [['touchDown', P.x, P.y]],
    [['wait', LONG_PRESS]],
    [['touchMove', Q.x, Q.y]],
    [['touchUp']],
  ]),
  runCase('a touch drag on the chart with the default events', [
    [['touchDown', Q.x, Q.y]],
    [['touchMove', R.x, R.y]],
    [['touchMove', P.x, P.y]],
    [['touchUp']],
  ]),
];

writeReference(OUT, 'chartHostInput', cases, {
  title: 'chart host input',
  notes: [
    `The points: P (${P.x}, ${P.y}) point 1 of dataset 0, L (${L.x}, ${L.y}) the`,
    `center of legend item 1, L2 (${L2.x}, ${L2.y}) the center of legend item 2,`,
    `E (${E.x}, ${E.y}) the center of the chart area,`,
    `O (${O.x}, ${O.y}) outside the canvas, Q (${Q.x}, ${Q.y}) and R (${R.x}, ${R.y})`,
    'the drag. The DOM types of each step:',
    ...notes,
  ],
});
