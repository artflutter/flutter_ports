// Original code, not ported from Chart.js: core.animations.defaults tests.
import 'package:flutter/animation.dart' show Curves;
import 'package:flutter_chartjs_port/src/core/core.animation.dart'
    show Interpolator;
import 'package:flutter_chartjs_port/src/core/core.animations.defaults.dart';
import 'package:flutter_chartjs_port/src/js/js_function.dart' show jsCall;
import 'package:flutter_chartjs_port/src/js/js_object.dart'
    show JsObjectFace, jsGet;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:test/test.dart';

import 'recording_defaults.dart';

// core.animations.defaults.js has no spec. The expected values come from
// Node.js v24.12.0 (V8 13.6) on x64. It ran the upstream
// applyAnimationsDefaults on an object that records each call
// (recording_defaults.dart), and called the recorded functions.

void main() {
  group('applyAnimationsDefaults', () {
    late RecordingDefaults defaults;

    setUp(() {
      defaults = RecordingDefaults();
      applyAnimationsDefaults(defaults);
    });

    /// The values argument of the call at [index].
    JsObjectFace values(int index) => defaults.calls[index][2]! as JsObjectFace;

    test('sets and describes the animation defaults', () {
      const setAnimation =
          '["set","animation",{"delay":"<undefined>","duration":1000,'
          '"easing":"<curve>","fn":"<undefined>","from":"<undefined>",'
          '"loop":"<undefined>","to":"<undefined>","type":"<undefined>"}]';
      const describeAnimation =
          '["describe","animation",{"_fallback":false,"_indexable":false,'
          '"_scriptable":"<fn>"}]';
      const setAnimations =
          '["set","animations",{"colors":{"type":"color",'
          '"properties":["color","borderColor","backgroundColor"]},'
          '"numbers":{"type":"number",'
          '"properties":["x","y","borderWidth","radius","tension"]}}]';
      const setTransitions =
          '["set","transitions",{"active":{"animation":{"duration":400}},'
          '"resize":{"animation":{"duration":0}},'
          '"show":{"animations":{"colors":{"from":"transparent"},'
          '"visible":{"type":"boolean","duration":0}}},'
          '"hide":{"animations":{"colors":{"to":"transparent"},'
          '"visible":{"type":"boolean","easing":"<curve>","fn":"<fn>"}}}}]';
      expect(defaults.calls.map(probeJson), [
        setAnimation,
        describeAnimation,
        setAnimations,
        '["describe","animations",{"_fallback":"animation"}]',
        setTransitions.replaceAll('"transparent"', '[0,0,0,0]'),
      ]);
    });

    test('the easing defaults are Flutter curves', () {
      // core.animations.defaults.js:8 and :66 (row adapt-flutter-curves).
      expect(values(0)['easing'], same(Curves.easeOutQuart));
      final hide = jsGet(jsGet(values(4), 'hide'), 'animations');
      expect(jsGet(jsGet(hide, 'visible'), 'easing'), same(Curves.linear));
    });

    test('stores undefined as own keys of animation', () {
      final animation = values(0);
      for (final key in ['delay', 'fn', 'from', 'loop', 'to', 'type']) {
        expect(animation.jsHas(key), isTrue, reason: key);
        expect(animation[key], same(undefined), reason: key);
      }
    });

    test('animation._scriptable excludes the callbacks', () {
      final scriptable = values(1)['_scriptable'];
      expect(jsCall(scriptable, ['onProgress']), isFalse);
      expect(jsCall(scriptable, ['onComplete']), isFalse);
      expect(jsCall(scriptable, ['fn']), isFalse);
      expect(jsCall(scriptable, ['duration']), isTrue);
    });

    test('the hide transition fn is v | 0', () {
      final transitions = values(4);
      final hide = transitions['hide']! as JsObjectFace;
      final animations = hide['animations']! as JsObjectFace;
      final visible = animations['visible']! as JsObjectFace;
      final fn = visible['fn'];
      // Chart.js ADR 0130: an Interpolator; `v` is `from`.
      Object? call(List<Object?> args) =>
          (fn! as Interpolator)(args.single, undefined, 0.5);
      expect(call([true]), 1);
      expect(call([false]), 0);
      expect(call([0.7]), 0);
      expect(call([-1.5]), -1);
      expect(call([2147483648.0]), -2147483648);
      expect(call([double.nan]), 0);
      expect(call([undefined]), 0);
      expect(call([null]), 0);
      expect(call(['3']), 3);
      // core.animation.js calls fn(from, to, factor). fn reads from only.
      expect((fn! as Interpolator)(true, false, 0.5), 1);
      expect(call([true]), isA<double>());
    });
  });
}
