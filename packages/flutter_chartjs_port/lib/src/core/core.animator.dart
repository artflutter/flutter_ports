// Ported from Chart.js v4.6.1 src/core/core.animator.js (MIT, Chart.js Contributors).

/// Port of `src/core/core.animator.js` (Chart.js ADR 0019, section 8).
///
/// One module-level [Animator], [animator], ticks the animations of all the
/// charts on [requestAnimFrame] (Chart.js ADR 0016, decision 6). `Date.now()`
/// is [jsDateNow]. Inside `testWidgets`, `tester.pump` moves its clock.
///
/// - The frame callback runs inside [jsRunWithMicrotaskCheckpoint]. Thus the
///   promise chains that it starts finish at the end of the callback, as
///   after a `requestAnimationFrame` callback of a browser
///   (`platform-animation-promise-checkpoint`).
/// - [Animator.update] walks the charts with [jsMapForEach], the ECMAScript
///   `Map.prototype.forEach`. A listener can destroy a chart or start a new
///   chart.
/// - A chart under `TickerMode(enabled: false)` is muted with
///   [Animator.mute] and [Animator.unmute] (Chart.js ADR 0016, decision 7,
///   `platform-animator-mute` and `platform-animator-skip-muted`). The chart
///   host reports the ticker state through `ChartHost.onTickerModeChanged`,
///   and the owner of the chart makes the calls.
/// - `_getAnims` and `_update` are [Animator.getAnims] and [Animator.update],
///   and `_Anims` is [Anims]: the fixtures of Chart.js read them (Chart.js ADR
///   0029, section 6, and Chart.js ADR 0012). `_refresh` is the field
///   [Animator.refresh], because a fixture replaces it on the singleton
///   (`harness-method-fields`).
///
/// This file imports `helpers.extras.dart`. Thus it is not a pure layer.
library;

import 'package:flutter_chartjs_port/src/core/core.animation.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.extras.dart'
    show requestAnimFrame;
import 'package:flutter_chartjs_port/src/js/js_date.dart';
import 'package:flutter_chartjs_port/src/js/js_map.dart';
import 'package:flutter_chartjs_port/src/js/js_math.dart';
import 'package:flutter_chartjs_port/src/js/js_promise.dart';
import 'package:flutter_chartjs_port/src/types/animation.dart' as types;
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:meta/meta.dart';

/// core.animator.js:132-133 the type of the `cb` of [Animator.listen]: a
/// function of an [AnimationEvent].
typedef AnimationListener = void Function(AnimationEvent event);

/// core.animator.js:27-32 the event object
/// `{chart, initial, numSteps, currentStep}` of the listeners
/// (animation.d.ts:13 `AnimationEvent`).
///
/// Dart `null` stands for JS `undefined` in [initial], [numSteps] and
/// [currentStep]. `core.controller.js:694` passes `{chart: this}` only. JS
/// `null` never reaches these fields.
final class AnimationEvent implements types.AnimationEvent {
  /// The object literal `{chart, initial, numSteps, currentStep}`.
  AnimationEvent({
    required this.chart,
    this.initial,
    this.numSteps,
    this.currentStep,
  });

  @override
  final types.Chart chart;

  @override
  final bool? initial;

  @override
  final double? numSteps;

  @override
  final double? currentStep;
}

/// core.animator.js:116-124 the record of one chart: the object literal
/// `{running, initial, items, listeners}` of `_getAnims`, with the `start`
/// and the `duration` that `start` writes (:169-170).
///
/// It is not private, because [Animator.getAnims] returns it to the fixtures
/// (Chart.js ADR 0029, section 6).
@internal
final class Anims {
  /// core.animator.js:117 `running: false`.
  bool running = false;

  /// core.animator.js:118 `initial: true`.
  bool initial = true;

  /// core.animator.js:119 `items: []`, the animations.
  List<Animation> items = [];

  /// core.animator.js:120-123 `listeners: {complete: [], progress: []}`.
  final Map<String, List<AnimationListener>> listeners = {
    'complete': [],
    'progress': [],
  };

  /// core.animator.js:169 `start`. Dart `null` stands for `undefined`,
  /// before the first [Animator.start].
  double? start;

  /// core.animator.js:170 `duration`. Dart `null` stands for `undefined`,
  /// before the first [Animator.start].
  double? duration;
}

/// core.animator.js:12 `Animator`.
///
/// Please use the module's default export which provides a singleton
/// instance
/// Note: class is export for typedoc
class Animator {
  /// core.animator.js:13 `constructor()`.
  Animator();

  /// core.animator.js:14 `_request`: the id of the pending frame callback,
  /// or Dart `null` (JS `null`). The ids of `scheduleFrameCallback` start at
  /// 1. Thus `_request != null` is the upstream test of truthiness.
  int? _request;

  /// core.animator.js:15 `_charts`, a JS `Map` from each chart to its
  /// record. A Dart `Map` keeps the insertion order. A `types.Chart` does
  /// not override `==`, so the keys compare by identity, as in a JS `Map`.
  final Map<types.Chart, Anims> _charts = {};

  /// core.animator.js:16 `_running`.
  bool _running = false;

  /// core.animator.js:17 `_lastDate`. Upstream writes it (:102) and never
  /// reads it. A `late` field stands for its `undefined` start value.
  // The field keeps the upstream structure.
  // ignore: unused_field
  late double _lastDate;

  /// The muted charts of [mute] (Chart.js ADR 0016, decision 7). An
  /// [Expando] keeps no destroyed chart alive.
  // DIVERGES(chartjs): platform-animator-mute, the TickerMode mute.
  final Expando<bool> _muted = Expando<bool>('muted');

  /// core.animator.js:23 `_notify(chart, anims, date, type)`: calls each
  /// listener of the event [type] with a new event object.
  ///
  /// It walks the listeners by index up to their length at the start, as
  /// `Array.prototype.forEach` does.
  void _notify(types.Chart chart, Anims anims, double date, String type) {
    final callbacks = anims.listeners[type]!;
    final numSteps = anims.duration;

    for (var i = 0, len = callbacks.length; i < len; i++) {
      // forEach skips the indices that the array no longer has.
      if (i >= callbacks.length) break;
      callbacks[i](
        AnimationEvent(
          chart: chart,
          initial: anims.initial,
          numSteps: numSteps,
          currentStep: jsMin(
            date - (anims.start ?? double.nan),
            numSteps ?? double.nan,
          ),
        ),
      );
    }
  }

  /// core.animator.js:38 `_refresh()`: registers one frame callback.
  ///
  /// A field that holds a function: a fixture replaces it on the singleton
  /// (`doughnut-animation.js:59-60`), and each call reads the field, as
  /// `this._refresh()` reads the property upstream (:49, :171). [unmute]
  /// calls the field too. The initializer gives the tear-off of a private
  /// method with the upstream body (Chart.js ADR 0029, section 6).
  // DIVERGES(chartjs): harness-method-fields, a fixture replaces it.
  @internal
  late void Function() refresh = _refreshMethod;

  /// The upstream body of `_refresh` (core.animator.js:38-52).
  ///
  /// The callback runs inside [jsRunWithMicrotaskCheckpoint]: the promise
  /// jobs that it queues run at its end (Chart.js ADR 0019, section 7).
  /// `requestAnimFrame.call(window, …)` is a plain call (Chart.js ADR 0016,
  /// decision 1).
  void _refreshMethod() {
    if (_request != null) {
      return;
    }
    _running = true;

    _request = requestAnimFrame(() {
      // DIVERGES(chartjs): platform-animation-promise-checkpoint, a checkpoint.
      jsRunWithMicrotaskCheckpoint(() {
        update();
        _request = null;

        if (_running) {
          refresh();
        }
      });
    });
  }

  /// core.animator.js:57 `_update(date = Date.now())`: ticks the active
  /// animations of each running chart, from the last to the first.
  ///
  /// Dart `null` for [date] stands for the omitted argument. A muted chart
  /// waits (Chart.js ADR 0016, decision 7). It does not count in
  /// `remaining`. It drops the underscore, because a fixture calls it
  /// (Chart.js ADR 0029, section 6).
  @internal
  void update([double? date]) {
    date ??= jsDateNow();
    var remaining = 0;

    jsMapForEach(_charts, (anims, chart) {
      if (!anims.running || anims.items.isEmpty) {
        return;
      }
      // DIVERGES(chartjs): platform-animator-skip-muted, a muted chart waits.
      if (_muted[chart] ?? false) return;
      final items = anims.items;
      var i = items.length - 1;
      var draw = false;
      Animation item;

      for (; i >= 0; --i) {
        item = items[i];

        if (item.active()) {
          if (item.total > (anims.duration ?? double.nan)) {
            // if the animation has been updated and its duration prolonged,
            // update to total duration of current animations run (for
            // progress event)
            anims.duration = item.total;
          }
          item.tick(date!);
          draw = true;
        } else {
          // Remove the item by replacing it with last item and removing the
          // last
          // A lot faster than splice.
          items[i] = items[items.length - 1];
          items.removeLast();
        }
      }

      if (draw) {
        chart.draw();
        _notify(chart, anims, date!, 'progress');
      }

      if (items.isEmpty) {
        anims.running = false;
        _notify(chart, anims, date!, 'complete');
        anims.initial = false;
      }

      remaining += items.length;
    });

    _lastDate = date;

    if (remaining == 0) {
      _running = false;
    }
  }

  /// core.animator.js:112 `_getAnims(chart)`: the record of [chart]. It
  /// creates the record at the first call.
  ///
  /// It drops the underscore, because a fixture reads it (Chart.js ADR 0029,
  /// section 6).
  @internal
  Anims getAnims(types.Chart chart) {
    final charts = _charts;
    var anims = charts[chart];
    if (anims == null) {
      anims = Anims();
      charts[chart] = anims;
    }
    return anims;
  }

  /// core.animator.js:135 `listen(chart, event, cb)`.
  ///
  /// @param {Chart} chart
  /// @param {string} event - event name
  /// @param {Function} cb - callback
  ///
  /// An [event] other than `'complete'` and `'progress'` throws a
  /// [TypeError], as the `undefined.push` of JavaScript does.
  void listen(types.Chart chart, String event, AnimationListener cb) {
    getAnims(chart).listeners[event]!.add(cb);
  }

  /// core.animator.js:144 `add(chart, items)`: Add animations
  ///
  /// @param {Chart} chart
  /// @param {Animation[]} items - animations
  ///
  /// Dart `null` for [items] stands for `undefined`
  /// (core.animator.tests.js:43).
  void add(types.Chart chart, List<Animation>? items) {
    if (items == null || items.isEmpty) {
      return;
    }
    getAnims(chart).items.addAll(items);
  }

  /// core.animator.js:155 `has(chart)`: Counts number of active animations
  /// for the chart
  ///
  /// @param {Chart} chart
  ///
  /// It creates the record of [chart], as [getAnims] does.
  bool has(types.Chart chart) {
    return getAnims(chart).items.isNotEmpty;
  }

  /// core.animator.js:163 `start(chart)`: Start animating (all charts)
  ///
  /// @param {Chart} chart
  void start(types.Chart chart) {
    final anims = _charts[chart];
    if (anims == null) {
      return;
    }
    anims
      ..running = true
      ..start = jsDateNow()
      ..duration = anims.items.fold<double>(
        0,
        (acc, cur) => jsMax(acc, cur.duration),
      );
    refresh();
  }

  /// core.animator.js:174 `running(chart)`.
  bool running(types.Chart chart) {
    if (!_running) {
      return false;
    }
    final anims = _charts[chart];
    if (anims == null || !anims.running || anims.items.isEmpty) {
      return false;
    }
    return true;
  }

  /// core.animator.js:189 `stop(chart)`: Stop all animations for the chart
  ///
  /// @param {Chart} chart
  ///
  /// It gives the chart a new empty list (:200). A running [update] keeps
  /// the old list.
  void stop(types.Chart chart) {
    final anims = _charts[chart];
    if (anims == null || anims.items.isEmpty) {
      return;
    }
    final items = anims.items;
    var i = items.length - 1;

    for (; i >= 0; --i) {
      items[i].cancel();
    }
    anims.items = [];
    _notify(chart, anims, jsDateNow(), 'complete');
  }

  /// core.animator.js:208 `remove(chart)`: Remove chart from Animator
  ///
  /// @param {Chart} chart
  ///
  /// True when the animator had a record of [chart], as `Map.delete` gives.
  bool remove(types.Chart chart) {
    // A record is never Dart null, so null means that no key was removed.
    return _charts.remove(chart) != null;
  }

  /// Mutes [chart]: [update] skips it until [unmute] (Chart.js ADR 0016,
  /// decision 7).
  ///
  /// The owner of the chart calls it when its chart host reports that
  /// `TickerMode` turned off, and for a chart that it creates under
  /// `TickerMode(enabled: false)`. A muted chart does not count in
  /// `remaining`. When all charts with animations are muted, the loop ends.
  /// While a chart is muted, its `onComplete` and `onProgress` callbacks
  /// wait.
  // DIVERGES(chartjs): platform-animator-mute, the TickerMode mute.
  void mute(types.Chart chart) {
    _muted[chart] = true;
  }

  /// Removes the mark of [mute] (Chart.js ADR 0016, decision 7).
  ///
  /// The owner of the chart calls it when its chart host reports that
  /// `TickerMode` turned on. If the chart has animations, the loop starts
  /// again. The animations continue at the current `Date.now()`, as a muted
  /// `Ticker` lets the time pass.
  ///
  /// The test reads the record without [has], because [has] creates a
  /// record, as [getAnims] does. Thus the unmute of a destroyed chart,
  /// whose record `remove` deleted, creates no record, and [_charts] keeps
  /// no destroyed chart alive.
  // DIVERGES(chartjs): platform-animator-mute, the TickerMode mute.
  void unmute(types.Chart chart) {
    _muted[chart] = null;
    final anims = _charts[chart];
    if (anims != null && anims.items.isNotEmpty) {
      refresh();
    }
  }
}

/// core.animator.js:214 the singleton instance.
final Animator animator = Animator();
