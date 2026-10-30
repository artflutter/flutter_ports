// Original code, not ported from Chart.js: generated from tool/options_schema.yaml by tool/options_gen.dart.
// Do not edit. Edit tool/options_schema.yaml and run
// `dart run melos run options:gen` (Chart.js ADR 0054 §2).

/// The typed option scopes of the typed internal model (Chart.js ADR
/// 0054 §3): one class `<Kind>Scope` for each kind of
/// `tool/options_schema.yaml`. Each declared key has a field of an
/// `Opt` cell, a getter and a setter of the cell (`<key>Cell`), and a
/// typed setter of a plain value. `OptionScope` keeps the key order,
/// the extras and the face.
///
/// This library is a pure layer.
library;

import 'package:flutter_chartjs_port/src/options/opt.dart';
import 'package:flutter_chartjs_port/src/options/option_keys.g.dart';
import 'package:flutter_chartjs_port/src/options/option_scope.dart';
import 'package:flutter_chartjs_port/src/options/scope_kinds.g.dart';

/// Port-only kind for index.d.ts:3914 ChartConfiguration, the raw root config
/// of a chart.
base class ChartConfigurationScope extends OptionScope {
  /// An empty scope.
  ChartConfigurationScope();

  @override
  ScopeKind get kind => ScopeKind.chartConfiguration;

  Opt<String>? _type;

  /// The cell of `type`, or Dart `null` when absent.
  Opt<String>? get typeCell => _type;

  /// Stores the cell of `type`. Dart `null` deletes the key.
  set typeCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.type);
    } else {
      store(OptionKey.type, cell);
    }
  }

  /// Stores the plain value [value] of `type`.
  set type(String value) => store(OptionKey.type, OptValue<String>(value));

  Opt<ChartDataScope>? _data;

  /// The cell of `data`, or Dart `null` when absent.
  Opt<ChartDataScope>? get dataCell => _data;

  /// Stores the cell of `data`. Dart `null` deletes the key.
  set dataCell(Opt<ChartDataScope>? cell) {
    if (cell == null) {
      delete(OptionKey.data);
    } else {
      store(OptionKey.data, cell);
    }
  }

  /// Stores the plain value [value] of `data`.
  set data(ChartDataScope value) =>
      store(OptionKey.data, OptScope<ChartDataScope>(value));

  Opt<ChartOptionsScope>? _options;

  /// The cell of `options`, or Dart `null` when absent.
  Opt<ChartOptionsScope>? get optionsCell => _options;

  /// Stores the cell of `options`. Dart `null` deletes the key.
  set optionsCell(Opt<ChartOptionsScope>? cell) {
    if (cell == null) {
      delete(OptionKey.options);
    } else {
      store(OptionKey.options, cell);
    }
  }

  /// Stores the plain value [value] of `options`.
  set options(ChartOptionsScope value) =>
      store(OptionKey.options, OptScope<ChartOptionsScope>(value));

  Opt<Object>? _plugins;

  /// The cell of `plugins`, or Dart `null` when absent.
  Opt<Object>? get pluginsCell => _plugins;

  /// Stores the cell of `plugins`. Dart `null` deletes the key.
  set pluginsCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.plugins);
    } else {
      store(OptionKey.plugins, cell);
    }
  }

  /// Stores the plain value [value] of `plugins`.
  set plugins(Object value) =>
      store(OptionKey.plugins, classify(OptionKey.plugins, value));

  Opt<Object>? _platform;

  /// The cell of `platform`, or Dart `null` when absent.
  Opt<Object>? get platformCell => _platform;

  /// Stores the cell of `platform`. Dart `null` deletes the key.
  set platformCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.platform);
    } else {
      store(OptionKey.platform, cell);
    }
  }

  /// Stores the plain value [value] of `platform`.
  set platform(Object value) =>
      store(OptionKey.platform, classify(OptionKey.platform, value));

  Opt<Object>? _dollarTheme;

  /// The cell of `$theme`, or Dart `null` when absent.
  Opt<Object>? get dollarThemeCell => _dollarTheme;

  /// Stores the cell of `$theme`. Dart `null` deletes the key.
  set dollarThemeCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.dollarTheme);
    } else {
      store(OptionKey.dollarTheme, cell);
    }
  }

  /// Stores the plain value [value] of `$theme`.
  set dollarTheme(Object value) =>
      store(OptionKey.dollarTheme, classify(OptionKey.dollarTheme, value));

  @override
  Opt<Object?>? cellOf(OptionKey key) => switch (key) {
    OptionKey.type => _type,
    OptionKey.data => _data,
    OptionKey.options => _options,
    OptionKey.plugins => _plugins,
    OptionKey.platform => _platform,
    OptionKey.dollarTheme => _dollarTheme,
    _ => null,
  };

  @override
  void setCell(OptionKey key, Opt<Object?>? cell) {
    switch (key) {
      case OptionKey.type:
        _type = fitCell(cell, classifyString);
      case OptionKey.data:
        _data = fitCell(cell, classifyScope<ChartDataScope>);
      case OptionKey.options:
        _options = fitCell(cell, classifyScope<ChartOptionsScope>);
      case OptionKey.plugins:
        _plugins = fitCell(cell, (raw) => classifyUnion(raw, 16));
      case OptionKey.platform:
        _platform = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.dollarTheme:
        _dollarTheme = fitCell(cell, (raw) => classifyUnion(raw, 64));
      default:
        throw ArgumentError.value(
          key,
          'key',
          'Not a key of ChartConfiguration',
        );
    }
  }

  @override
  bool hasField(OptionKey key) => switch (key) {
    OptionKey.type ||
    OptionKey.data ||
    OptionKey.options ||
    OptionKey.plugins ||
    OptionKey.platform ||
    OptionKey.dollarTheme => true,
    _ => false,
  };

  @override
  Opt<Object?> classify(OptionKey key, Object? raw) => switch (key) {
    OptionKey.type => classifyString(raw),
    OptionKey.data => classifyScope<ChartDataScope>(raw),
    OptionKey.options => classifyScope<ChartOptionsScope>(raw),
    OptionKey.plugins => classifyUnion(raw, 16),
    OptionKey.platform => classifyUnion(raw, 64),
    OptionKey.dollarTheme => classifyUnion(raw, 64),
    _ => kind.classifyOther(raw),
  };
}

/// index.d.ts:3892 ChartData, the `data` object of the config.
base class ChartDataScope extends OptionScope {
  /// An empty scope.
  ChartDataScope();

  @override
  ScopeKind get kind => ScopeKind.chartData;

  Opt<Object>? _labels;

  /// The cell of `labels`, or Dart `null` when absent.
  Opt<Object>? get labelsCell => _labels;

  /// Stores the cell of `labels`. Dart `null` deletes the key.
  set labelsCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.labels);
    } else {
      store(OptionKey.labels, cell);
    }
  }

  /// Stores the plain value [value] of `labels`.
  set labels(Object value) =>
      store(OptionKey.labels, classify(OptionKey.labels, value));

  Opt<Object>? _xLabels;

  /// The cell of `xLabels`, or Dart `null` when absent.
  Opt<Object>? get xLabelsCell => _xLabels;

  /// Stores the cell of `xLabels`. Dart `null` deletes the key.
  set xLabelsCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.xLabels);
    } else {
      store(OptionKey.xLabels, cell);
    }
  }

  /// Stores the plain value [value] of `xLabels`.
  set xLabels(Object value) =>
      store(OptionKey.xLabels, classify(OptionKey.xLabels, value));

  Opt<Object>? _yLabels;

  /// The cell of `yLabels`, or Dart `null` when absent.
  Opt<Object>? get yLabelsCell => _yLabels;

  /// Stores the cell of `yLabels`. Dart `null` deletes the key.
  set yLabelsCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.yLabels);
    } else {
      store(OptionKey.yLabels, cell);
    }
  }

  /// Stores the plain value [value] of `yLabels`.
  set yLabels(Object value) =>
      store(OptionKey.yLabels, classify(OptionKey.yLabels, value));

  Opt<Object>? _datasets;

  /// The cell of `datasets`, or Dart `null` when absent.
  Opt<Object>? get datasetsCell => _datasets;

  /// Stores the cell of `datasets`. Dart `null` deletes the key.
  set datasetsCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.datasets);
    } else {
      store(OptionKey.datasets, cell);
    }
  }

  /// Stores the plain value [value] of `datasets`.
  set datasets(Object value) =>
      store(OptionKey.datasets, classify(OptionKey.datasets, value));

  @override
  Opt<Object?>? cellOf(OptionKey key) => switch (key) {
    OptionKey.labels => _labels,
    OptionKey.xLabels => _xLabels,
    OptionKey.yLabels => _yLabels,
    OptionKey.datasets => _datasets,
    _ => null,
  };

  @override
  void setCell(OptionKey key, Opt<Object?>? cell) {
    switch (key) {
      case OptionKey.labels:
        _labels = fitCell(cell, (raw) => classifyUnion(raw, 16));
      case OptionKey.xLabels:
        _xLabels = fitCell(cell, (raw) => classifyUnion(raw, 16));
      case OptionKey.yLabels:
        _yLabels = fitCell(cell, (raw) => classifyUnion(raw, 16));
      case OptionKey.datasets:
        _datasets = fitCell(cell, (raw) => classifyUnion(raw, 16));
      default:
        throw ArgumentError.value(key, 'key', 'Not a key of ChartData');
    }
  }

  @override
  bool hasField(OptionKey key) => switch (key) {
    OptionKey.labels ||
    OptionKey.xLabels ||
    OptionKey.yLabels ||
    OptionKey.datasets => true,
    _ => false,
  };

  @override
  Opt<Object?> classify(OptionKey key, Object? raw) => switch (key) {
    OptionKey.labels => classifyUnion(raw, 16),
    OptionKey.xLabels => classifyUnion(raw, 16),
    OptionKey.yLabels => classifyUnion(raw, 16),
    OptionKey.datasets => classifyUnion(raw, 16),
    _ => kind.classifyOther(raw),
  };
}

/// index.d.ts:3843 ChartOptions (index.d.ts:1629 CoreChartOptions with
/// ParsingOptions and AnimationOptions, ElementChartOptions,
/// PluginChartOptions, DatasetChartOptions, ScaleChartOptions and the chart
/// options of each controller), the root options and Chart.defaults
/// (index.d.ts:706 Defaults).
base class ChartOptionsScope extends OptionScope {
  /// An empty scope.
  ChartOptionsScope();

  @override
  ScopeKind get kind => ScopeKind.chartOptions;

  Opt<Object>? _parsing;

  /// The cell of `parsing`, or Dart `null` when absent.
  Opt<Object>? get parsingCell => _parsing;

  /// Stores the cell of `parsing`. Dart `null` deletes the key.
  set parsingCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.parsing);
    } else {
      store(OptionKey.parsing, cell);
    }
  }

  /// Stores the plain value [value] of `parsing`.
  set parsing(Object value) =>
      store(OptionKey.parsing, classify(OptionKey.parsing, value));

  Opt<bool>? _normalized;

  /// The cell of `normalized`, or Dart `null` when absent.
  Opt<bool>? get normalizedCell => _normalized;

  /// Stores the cell of `normalized`. Dart `null` deletes the key.
  set normalizedCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.normalized);
    } else {
      store(OptionKey.normalized, cell);
    }
  }

  /// Stores the plain value [value] of `normalized`.
  set normalized(bool value) =>
      store(OptionKey.normalized, OptValue<bool>(value));

  Opt<Object>? _animation;

  /// The cell of `animation`, or Dart `null` when absent.
  Opt<Object>? get animationCell => _animation;

  /// Stores the cell of `animation`. Dart `null` deletes the key.
  set animationCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.animation);
    } else {
      store(OptionKey.animation, cell);
    }
  }

  /// Stores the plain value [value] of `animation`.
  set animation(Object value) =>
      store(OptionKey.animation, classify(OptionKey.animation, value));

  Opt<Object>? _animations;

  /// The cell of `animations`, or Dart `null` when absent.
  Opt<Object>? get animationsCell => _animations;

  /// Stores the cell of `animations`. Dart `null` deletes the key.
  set animationsCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.animations);
    } else {
      store(OptionKey.animations, cell);
    }
  }

  /// Stores the plain value [value] of `animations`.
  set animations(Object value) =>
      store(OptionKey.animations, classify(OptionKey.animations, value));

  Opt<TransitionsSpecScope>? _transitions;

  /// The cell of `transitions`, or Dart `null` when absent.
  Opt<TransitionsSpecScope>? get transitionsCell => _transitions;

  /// Stores the cell of `transitions`. Dart `null` deletes the key.
  set transitionsCell(Opt<TransitionsSpecScope>? cell) {
    if (cell == null) {
      delete(OptionKey.transitions);
    } else {
      store(OptionKey.transitions, cell);
    }
  }

  /// Stores the plain value [value] of `transitions`.
  set transitions(TransitionsSpecScope value) =>
      store(OptionKey.transitions, OptScope<TransitionsSpecScope>(value));

  Opt<DatasetOptionsByTypeScope>? _datasets;

  /// The cell of `datasets`, or Dart `null` when absent.
  Opt<DatasetOptionsByTypeScope>? get datasetsCell => _datasets;

  /// Stores the cell of `datasets`. Dart `null` deletes the key.
  set datasetsCell(Opt<DatasetOptionsByTypeScope>? cell) {
    if (cell == null) {
      delete(OptionKey.datasets);
    } else {
      store(OptionKey.datasets, cell);
    }
  }

  /// Stores the plain value [value] of `datasets`.
  set datasets(DatasetOptionsByTypeScope value) =>
      store(OptionKey.datasets, OptScope<DatasetOptionsByTypeScope>(value));

  Opt<String>? _indexAxis;

  /// The cell of `indexAxis`, or Dart `null` when absent.
  Opt<String>? get indexAxisCell => _indexAxis;

  /// Stores the cell of `indexAxis`. Dart `null` deletes the key.
  set indexAxisCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.indexAxis);
    } else {
      store(OptionKey.indexAxis, cell);
    }
  }

  /// Stores the plain value [value] of `indexAxis`.
  set indexAxis(String value) =>
      store(OptionKey.indexAxis, OptValue<String>(value));

  Opt<Object>? _clip;

  /// The cell of `clip`, or Dart `null` when absent.
  Opt<Object>? get clipCell => _clip;

  /// Stores the cell of `clip`. Dart `null` deletes the key.
  set clipCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.clip);
    } else {
      store(OptionKey.clip, cell);
    }
  }

  /// Stores the plain value [value] of `clip`.
  set clip(Object value) =>
      store(OptionKey.clip, classify(OptionKey.clip, value));

  Opt<Object>? _color;

  /// The cell of `color`, or Dart `null` when absent.
  Opt<Object>? get colorCell => _color;

  /// Stores the cell of `color`. Dart `null` deletes the key.
  set colorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.color);
    } else {
      store(OptionKey.color, cell);
    }
  }

  /// Stores the plain value [value] of `color`.
  set color(Object value) =>
      store(OptionKey.color, classify(OptionKey.color, value));

  Opt<Object>? _backgroundColor;

  /// The cell of `backgroundColor`, or Dart `null` when absent.
  Opt<Object>? get backgroundColorCell => _backgroundColor;

  /// Stores the cell of `backgroundColor`. Dart `null` deletes the key.
  set backgroundColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.backgroundColor);
    } else {
      store(OptionKey.backgroundColor, cell);
    }
  }

  /// Stores the plain value [value] of `backgroundColor`.
  set backgroundColor(Object value) => store(
    OptionKey.backgroundColor,
    classify(OptionKey.backgroundColor, value),
  );

  Opt<Object>? _hoverBackgroundColor;

  /// The cell of `hoverBackgroundColor`, or Dart `null` when absent.
  Opt<Object>? get hoverBackgroundColorCell => _hoverBackgroundColor;

  /// Stores the cell of `hoverBackgroundColor`. Dart `null` deletes the key.
  set hoverBackgroundColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBackgroundColor);
    } else {
      store(OptionKey.hoverBackgroundColor, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBackgroundColor`.
  set hoverBackgroundColor(Object value) => store(
    OptionKey.hoverBackgroundColor,
    classify(OptionKey.hoverBackgroundColor, value),
  );

  Opt<Object>? _borderColor;

  /// The cell of `borderColor`, or Dart `null` when absent.
  Opt<Object>? get borderColorCell => _borderColor;

  /// Stores the cell of `borderColor`. Dart `null` deletes the key.
  set borderColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.borderColor);
    } else {
      store(OptionKey.borderColor, cell);
    }
  }

  /// Stores the plain value [value] of `borderColor`.
  set borderColor(Object value) =>
      store(OptionKey.borderColor, classify(OptionKey.borderColor, value));

  Opt<Object>? _hoverBorderColor;

  /// The cell of `hoverBorderColor`, or Dart `null` when absent.
  Opt<Object>? get hoverBorderColorCell => _hoverBorderColor;

  /// Stores the cell of `hoverBorderColor`. Dart `null` deletes the key.
  set hoverBorderColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBorderColor);
    } else {
      store(OptionKey.hoverBorderColor, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBorderColor`.
  set hoverBorderColor(Object value) => store(
    OptionKey.hoverBorderColor,
    classify(OptionKey.hoverBorderColor, value),
  );

  Opt<FontSpecScope>? _font;

  /// The cell of `font`, or Dart `null` when absent.
  Opt<FontSpecScope>? get fontCell => _font;

  /// Stores the cell of `font`. Dart `null` deletes the key.
  set fontCell(Opt<FontSpecScope>? cell) {
    if (cell == null) {
      delete(OptionKey.font);
    } else {
      store(OptionKey.font, cell);
    }
  }

  /// Stores the plain value [value] of `font`.
  set font(FontSpecScope value) =>
      store(OptionKey.font, OptScope<FontSpecScope>(value));

  Opt<bool>? _responsive;

  /// The cell of `responsive`, or Dart `null` when absent.
  Opt<bool>? get responsiveCell => _responsive;

  /// Stores the cell of `responsive`. Dart `null` deletes the key.
  set responsiveCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.responsive);
    } else {
      store(OptionKey.responsive, cell);
    }
  }

  /// Stores the plain value [value] of `responsive`.
  set responsive(bool value) =>
      store(OptionKey.responsive, OptValue<bool>(value));

  Opt<bool>? _maintainAspectRatio;

  /// The cell of `maintainAspectRatio`, or Dart `null` when absent.
  Opt<bool>? get maintainAspectRatioCell => _maintainAspectRatio;

  /// Stores the cell of `maintainAspectRatio`. Dart `null` deletes the key.
  set maintainAspectRatioCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.maintainAspectRatio);
    } else {
      store(OptionKey.maintainAspectRatio, cell);
    }
  }

  /// Stores the plain value [value] of `maintainAspectRatio`.
  set maintainAspectRatio(bool value) =>
      store(OptionKey.maintainAspectRatio, OptValue<bool>(value));

  Opt<double>? _resizeDelay;

  /// The cell of `resizeDelay`, or Dart `null` when absent.
  Opt<double>? get resizeDelayCell => _resizeDelay;

  /// Stores the cell of `resizeDelay`. Dart `null` deletes the key.
  set resizeDelayCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.resizeDelay);
    } else {
      store(OptionKey.resizeDelay, cell);
    }
  }

  /// Stores the plain value [value] of `resizeDelay`.
  set resizeDelay(double value) =>
      store(OptionKey.resizeDelay, OptValue<double>(value));

  Opt<double>? _aspectRatio;

  /// The cell of `aspectRatio`, or Dart `null` when absent.
  Opt<double>? get aspectRatioCell => _aspectRatio;

  /// Stores the cell of `aspectRatio`. Dart `null` deletes the key.
  set aspectRatioCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.aspectRatio);
    } else {
      store(OptionKey.aspectRatio, cell);
    }
  }

  /// Stores the plain value [value] of `aspectRatio`.
  set aspectRatio(double value) =>
      store(OptionKey.aspectRatio, OptValue<double>(value));

  Opt<String>? _locale;

  /// The cell of `locale`, or Dart `null` when absent.
  Opt<String>? get localeCell => _locale;

  /// Stores the cell of `locale`. Dart `null` deletes the key.
  set localeCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.locale);
    } else {
      store(OptionKey.locale, cell);
    }
  }

  /// Stores the plain value [value] of `locale`.
  set locale(String value) => store(OptionKey.locale, OptValue<String>(value));

  Opt<Object>? _onResize;

  /// The cell of `onResize`, or Dart `null` when absent.
  Opt<Object>? get onResizeCell => _onResize;

  /// Stores the cell of `onResize`. Dart `null` deletes the key.
  set onResizeCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.onResize);
    } else {
      store(OptionKey.onResize, cell);
    }
  }

  /// Stores the plain value [value] of `onResize`.
  set onResize(Object value) =>
      store(OptionKey.onResize, classify(OptionKey.onResize, value));

  Opt<double>? _devicePixelRatio;

  /// The cell of `devicePixelRatio`, or Dart `null` when absent.
  Opt<double>? get devicePixelRatioCell => _devicePixelRatio;

  /// Stores the cell of `devicePixelRatio`. Dart `null` deletes the key.
  set devicePixelRatioCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.devicePixelRatio);
    } else {
      store(OptionKey.devicePixelRatio, cell);
    }
  }

  /// Stores the plain value [value] of `devicePixelRatio`.
  set devicePixelRatio(double value) =>
      store(OptionKey.devicePixelRatio, OptValue<double>(value));

  Opt<InteractionOptionsScope>? _interaction;

  /// The cell of `interaction`, or Dart `null` when absent.
  Opt<InteractionOptionsScope>? get interactionCell => _interaction;

  /// Stores the cell of `interaction`. Dart `null` deletes the key.
  set interactionCell(Opt<InteractionOptionsScope>? cell) {
    if (cell == null) {
      delete(OptionKey.interaction);
    } else {
      store(OptionKey.interaction, cell);
    }
  }

  /// Stores the plain value [value] of `interaction`.
  set interaction(InteractionOptionsScope value) =>
      store(OptionKey.interaction, OptScope<InteractionOptionsScope>(value));

  Opt<InteractionOptionsScope>? _hover;

  /// The cell of `hover`, or Dart `null` when absent.
  Opt<InteractionOptionsScope>? get hoverCell => _hover;

  /// Stores the cell of `hover`. Dart `null` deletes the key.
  set hoverCell(Opt<InteractionOptionsScope>? cell) {
    if (cell == null) {
      delete(OptionKey.hover);
    } else {
      store(OptionKey.hover, cell);
    }
  }

  /// Stores the plain value [value] of `hover`.
  set hover(InteractionOptionsScope value) =>
      store(OptionKey.hover, OptScope<InteractionOptionsScope>(value));

  Opt<Object>? _events;

  /// The cell of `events`, or Dart `null` when absent.
  Opt<Object>? get eventsCell => _events;

  /// Stores the cell of `events`. Dart `null` deletes the key.
  set eventsCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.events);
    } else {
      store(OptionKey.events, cell);
    }
  }

  /// Stores the plain value [value] of `events`.
  set events(Object value) =>
      store(OptionKey.events, classify(OptionKey.events, value));

  Opt<Object>? _onHover;

  /// The cell of `onHover`, or Dart `null` when absent.
  Opt<Object>? get onHoverCell => _onHover;

  /// Stores the cell of `onHover`. Dart `null` deletes the key.
  set onHoverCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.onHover);
    } else {
      store(OptionKey.onHover, cell);
    }
  }

  /// Stores the plain value [value] of `onHover`.
  set onHover(Object value) =>
      store(OptionKey.onHover, classify(OptionKey.onHover, value));

  Opt<Object>? _onClick;

  /// The cell of `onClick`, or Dart `null` when absent.
  Opt<Object>? get onClickCell => _onClick;

  /// Stores the cell of `onClick`. Dart `null` deletes the key.
  set onClickCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.onClick);
    } else {
      store(OptionKey.onClick, cell);
    }
  }

  /// Stores the plain value [value] of `onClick`.
  set onClick(Object value) =>
      store(OptionKey.onClick, classify(OptionKey.onClick, value));

  Opt<LayoutOptionsScope>? _layout;

  /// The cell of `layout`, or Dart `null` when absent.
  Opt<LayoutOptionsScope>? get layoutCell => _layout;

  /// Stores the cell of `layout`. Dart `null` deletes the key.
  set layoutCell(Opt<LayoutOptionsScope>? cell) {
    if (cell == null) {
      delete(OptionKey.layout);
    } else {
      store(OptionKey.layout, cell);
    }
  }

  /// Stores the plain value [value] of `layout`.
  set layout(LayoutOptionsScope value) =>
      store(OptionKey.layout, OptScope<LayoutOptionsScope>(value));

  Opt<ElementOptionsByTypeScope>? _elements;

  /// The cell of `elements`, or Dart `null` when absent.
  Opt<ElementOptionsByTypeScope>? get elementsCell => _elements;

  /// Stores the cell of `elements`. Dart `null` deletes the key.
  set elementsCell(Opt<ElementOptionsByTypeScope>? cell) {
    if (cell == null) {
      delete(OptionKey.elements);
    } else {
      store(OptionKey.elements, cell);
    }
  }

  /// Stores the plain value [value] of `elements`.
  set elements(ElementOptionsByTypeScope value) =>
      store(OptionKey.elements, OptScope<ElementOptionsByTypeScope>(value));

  Opt<PluginOptionsByTypeScope>? _plugins;

  /// The cell of `plugins`, or Dart `null` when absent.
  Opt<PluginOptionsByTypeScope>? get pluginsCell => _plugins;

  /// Stores the cell of `plugins`. Dart `null` deletes the key.
  set pluginsCell(Opt<PluginOptionsByTypeScope>? cell) {
    if (cell == null) {
      delete(OptionKey.plugins);
    } else {
      store(OptionKey.plugins, cell);
    }
  }

  /// Stores the plain value [value] of `plugins`.
  set plugins(PluginOptionsByTypeScope value) =>
      store(OptionKey.plugins, OptScope<PluginOptionsByTypeScope>(value));

  Opt<ScaleOptionsByIdScope>? _scales;

  /// The cell of `scales`, or Dart `null` when absent.
  Opt<ScaleOptionsByIdScope>? get scalesCell => _scales;

  /// Stores the cell of `scales`. Dart `null` deletes the key.
  set scalesCell(Opt<ScaleOptionsByIdScope>? cell) {
    if (cell == null) {
      delete(OptionKey.scales);
    } else {
      store(OptionKey.scales, cell);
    }
  }

  /// Stores the plain value [value] of `scales`.
  set scales(ScaleOptionsByIdScope value) =>
      store(OptionKey.scales, OptScope<ScaleOptionsByIdScope>(value));

  Opt<bool>? _skipNull;

  /// The cell of `skipNull`, or Dart `null` when absent.
  Opt<bool>? get skipNullCell => _skipNull;

  /// Stores the cell of `skipNull`. Dart `null` deletes the key.
  set skipNullCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.skipNull);
    } else {
      store(OptionKey.skipNull, cell);
    }
  }

  /// Stores the plain value [value] of `skipNull`.
  set skipNull(bool value) => store(OptionKey.skipNull, OptValue<bool>(value));

  Opt<Object>? _spanGaps;

  /// The cell of `spanGaps`, or Dart `null` when absent.
  Opt<Object>? get spanGapsCell => _spanGaps;

  /// Stores the cell of `spanGaps`. Dart `null` deletes the key.
  set spanGapsCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.spanGaps);
    } else {
      store(OptionKey.spanGaps, cell);
    }
  }

  /// Stores the plain value [value] of `spanGaps`.
  set spanGaps(Object value) =>
      store(OptionKey.spanGaps, classify(OptionKey.spanGaps, value));

  Opt<bool>? _showLine;

  /// The cell of `showLine`, or Dart `null` when absent.
  Opt<bool>? get showLineCell => _showLine;

  /// Stores the cell of `showLine`. Dart `null` deletes the key.
  set showLineCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.showLine);
    } else {
      store(OptionKey.showLine, cell);
    }
  }

  /// Stores the plain value [value] of `showLine`.
  set showLine(bool value) => store(OptionKey.showLine, OptValue<bool>(value));

  Opt<double>? _circumference;

  /// The cell of `circumference`, or Dart `null` when absent.
  Opt<double>? get circumferenceCell => _circumference;

  /// Stores the cell of `circumference`. Dart `null` deletes the key.
  set circumferenceCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.circumference);
    } else {
      store(OptionKey.circumference, cell);
    }
  }

  /// Stores the plain value [value] of `circumference`.
  set circumference(double value) =>
      store(OptionKey.circumference, OptValue<double>(value));

  Opt<Object>? _cutout;

  /// The cell of `cutout`, or Dart `null` when absent.
  Opt<Object>? get cutoutCell => _cutout;

  /// Stores the cell of `cutout`. Dart `null` deletes the key.
  set cutoutCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.cutout);
    } else {
      store(OptionKey.cutout, cell);
    }
  }

  /// Stores the plain value [value] of `cutout`.
  set cutout(Object value) =>
      store(OptionKey.cutout, classify(OptionKey.cutout, value));

  Opt<double>? _offset;

  /// The cell of `offset`, or Dart `null` when absent.
  Opt<double>? get offsetCell => _offset;

  /// Stores the cell of `offset`. Dart `null` deletes the key.
  set offsetCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.offset);
    } else {
      store(OptionKey.offset, cell);
    }
  }

  /// Stores the plain value [value] of `offset`.
  set offset(double value) => store(OptionKey.offset, OptValue<double>(value));

  Opt<Object>? _radius;

  /// The cell of `radius`, or Dart `null` when absent.
  Opt<Object>? get radiusCell => _radius;

  /// Stores the cell of `radius`. Dart `null` deletes the key.
  set radiusCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.radius);
    } else {
      store(OptionKey.radius, cell);
    }
  }

  /// Stores the plain value [value] of `radius`.
  set radius(Object value) =>
      store(OptionKey.radius, classify(OptionKey.radius, value));

  Opt<double>? _rotation;

  /// The cell of `rotation`, or Dart `null` when absent.
  Opt<double>? get rotationCell => _rotation;

  /// Stores the cell of `rotation`. Dart `null` deletes the key.
  set rotationCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.rotation);
    } else {
      store(OptionKey.rotation, cell);
    }
  }

  /// Stores the plain value [value] of `rotation`.
  set rotation(double value) =>
      store(OptionKey.rotation, OptValue<double>(value));

  Opt<double>? _spacing;

  /// The cell of `spacing`, or Dart `null` when absent.
  Opt<double>? get spacingCell => _spacing;

  /// Stores the cell of `spacing`. Dart `null` deletes the key.
  set spacingCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.spacing);
    } else {
      store(OptionKey.spacing, cell);
    }
  }

  /// Stores the plain value [value] of `spacing`.
  set spacing(double value) =>
      store(OptionKey.spacing, OptValue<double>(value));

  Opt<String>? _spacingMode;

  /// The cell of `spacingMode`, or Dart `null` when absent.
  Opt<String>? get spacingModeCell => _spacingMode;

  /// Stores the cell of `spacingMode`. Dart `null` deletes the key.
  set spacingModeCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.spacingMode);
    } else {
      store(OptionKey.spacingMode, cell);
    }
  }

  /// Stores the plain value [value] of `spacingMode`.
  set spacingMode(String value) =>
      store(OptionKey.spacingMode, OptValue<String>(value));

  Opt<double>? _startAngle;

  /// The cell of `startAngle`, or Dart `null` when absent.
  Opt<double>? get startAngleCell => _startAngle;

  /// Stores the cell of `startAngle`. Dart `null` deletes the key.
  set startAngleCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.startAngle);
    } else {
      store(OptionKey.startAngle, cell);
    }
  }

  /// Stores the plain value [value] of `startAngle`.
  set startAngle(double value) =>
      store(OptionKey.startAngle, OptValue<double>(value));

  Opt<ScaleOptionsScope>? _scale;

  /// The cell of `scale`, or Dart `null` when absent.
  Opt<ScaleOptionsScope>? get scaleCell => _scale;

  /// Stores the cell of `scale`. Dart `null` deletes the key.
  set scaleCell(Opt<ScaleOptionsScope>? cell) {
    if (cell == null) {
      delete(OptionKey.scale);
    } else {
      store(OptionKey.scale, cell);
    }
  }

  /// Stores the plain value [value] of `scale`.
  set scale(ScaleOptionsScope value) =>
      store(OptionKey.scale, OptScope<ScaleOptionsScope>(value));

  Opt<Object>? _hoverColor;

  /// The cell of `hoverColor`, or Dart `null` when absent.
  Opt<Object>? get hoverColorCell => _hoverColor;

  /// Stores the cell of `hoverColor`. Dart `null` deletes the key.
  set hoverColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverColor);
    } else {
      store(OptionKey.hoverColor, cell);
    }
  }

  /// Stores the plain value [value] of `hoverColor`.
  set hoverColor(Object value) =>
      store(OptionKey.hoverColor, classify(OptionKey.hoverColor, value));

  Opt<bool>? _drawActiveElementsOnTop;

  /// The cell of `drawActiveElementsOnTop`, or Dart `null` when absent.
  Opt<bool>? get drawActiveElementsOnTopCell => _drawActiveElementsOnTop;

  /// Stores the cell of `drawActiveElementsOnTop`. Dart `null` deletes the key.
  set drawActiveElementsOnTopCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.drawActiveElementsOnTop);
    } else {
      store(OptionKey.drawActiveElementsOnTop, cell);
    }
  }

  /// Stores the plain value [value] of `drawActiveElementsOnTop`.
  set drawActiveElementsOnTop(bool value) =>
      store(OptionKey.drawActiveElementsOnTop, OptValue<bool>(value));

  Opt<String>? _label;

  /// The cell of `label`, or Dart `null` when absent.
  Opt<String>? get labelCell => _label;

  /// Stores the cell of `label`. Dart `null` deletes the key.
  set labelCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.label);
    } else {
      store(OptionKey.label, cell);
    }
  }

  /// Stores the plain value [value] of `label`.
  set label(String value) => store(OptionKey.label, OptValue<String>(value));

  Opt<double>? _order;

  /// The cell of `order`, or Dart `null` when absent.
  Opt<double>? get orderCell => _order;

  /// Stores the cell of `order`. Dart `null` deletes the key.
  set orderCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.order);
    } else {
      store(OptionKey.order, cell);
    }
  }

  /// Stores the plain value [value] of `order`.
  set order(double value) => store(OptionKey.order, OptValue<double>(value));

  Opt<String>? _stack;

  /// The cell of `stack`, or Dart `null` when absent.
  Opt<String>? get stackCell => _stack;

  /// Stores the cell of `stack`. Dart `null` deletes the key.
  set stackCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.stack);
    } else {
      store(OptionKey.stack, cell);
    }
  }

  /// Stores the plain value [value] of `stack`.
  set stack(String value) => store(OptionKey.stack, OptValue<String>(value));

  Opt<bool>? _hidden;

  /// The cell of `hidden`, or Dart `null` when absent.
  Opt<bool>? get hiddenCell => _hidden;

  /// Stores the cell of `hidden`. Dart `null` deletes the key.
  set hiddenCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.hidden);
    } else {
      store(OptionKey.hidden, cell);
    }
  }

  /// Stores the plain value [value] of `hidden`.
  set hidden(bool value) => store(OptionKey.hidden, OptValue<bool>(value));

  Opt<double>? _base;

  /// The cell of `base`, or Dart `null` when absent.
  Opt<double>? get baseCell => _base;

  /// Stores the cell of `base`. Dart `null` deletes the key.
  set baseCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.base);
    } else {
      store(OptionKey.base, cell);
    }
  }

  /// Stores the plain value [value] of `base`.
  set base(double value) => store(OptionKey.base, OptValue<double>(value));

  Opt<Object>? _borderSkipped;

  /// The cell of `borderSkipped`, or Dart `null` when absent.
  Opt<Object>? get borderSkippedCell => _borderSkipped;

  /// Stores the cell of `borderSkipped`. Dart `null` deletes the key.
  set borderSkippedCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.borderSkipped);
    } else {
      store(OptionKey.borderSkipped, cell);
    }
  }

  /// Stores the plain value [value] of `borderSkipped`.
  set borderSkipped(Object value) =>
      store(OptionKey.borderSkipped, classify(OptionKey.borderSkipped, value));

  Opt<Object>? _borderRadius;

  /// The cell of `borderRadius`, or Dart `null` when absent.
  Opt<Object>? get borderRadiusCell => _borderRadius;

  /// Stores the cell of `borderRadius`. Dart `null` deletes the key.
  set borderRadiusCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.borderRadius);
    } else {
      store(OptionKey.borderRadius, cell);
    }
  }

  /// Stores the plain value [value] of `borderRadius`.
  set borderRadius(Object value) =>
      store(OptionKey.borderRadius, classify(OptionKey.borderRadius, value));

  Opt<Object>? _inflateAmount;

  /// The cell of `inflateAmount`, or Dart `null` when absent.
  Opt<Object>? get inflateAmountCell => _inflateAmount;

  /// Stores the cell of `inflateAmount`. Dart `null` deletes the key.
  set inflateAmountCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.inflateAmount);
    } else {
      store(OptionKey.inflateAmount, cell);
    }
  }

  /// Stores the plain value [value] of `inflateAmount`.
  set inflateAmount(Object value) =>
      store(OptionKey.inflateAmount, classify(OptionKey.inflateAmount, value));

  Opt<Object>? _borderWidth;

  /// The cell of `borderWidth`, or Dart `null` when absent.
  Opt<Object>? get borderWidthCell => _borderWidth;

  /// Stores the cell of `borderWidth`. Dart `null` deletes the key.
  set borderWidthCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.borderWidth);
    } else {
      store(OptionKey.borderWidth, cell);
    }
  }

  /// Stores the plain value [value] of `borderWidth`.
  set borderWidth(Object value) =>
      store(OptionKey.borderWidth, classify(OptionKey.borderWidth, value));

  Opt<double>? _hoverBorderWidth;

  /// The cell of `hoverBorderWidth`, or Dart `null` when absent.
  Opt<double>? get hoverBorderWidthCell => _hoverBorderWidth;

  /// Stores the cell of `hoverBorderWidth`. Dart `null` deletes the key.
  set hoverBorderWidthCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBorderWidth);
    } else {
      store(OptionKey.hoverBorderWidth, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBorderWidth`.
  set hoverBorderWidth(double value) =>
      store(OptionKey.hoverBorderWidth, OptValue<double>(value));

  Opt<String>? _xAxisID;

  /// The cell of `xAxisID`, or Dart `null` when absent.
  Opt<String>? get xAxisIDCell => _xAxisID;

  /// Stores the cell of `xAxisID`. Dart `null` deletes the key.
  set xAxisIDCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.xAxisID);
    } else {
      store(OptionKey.xAxisID, cell);
    }
  }

  /// Stores the plain value [value] of `xAxisID`.
  set xAxisID(String value) =>
      store(OptionKey.xAxisID, OptValue<String>(value));

  Opt<String>? _yAxisID;

  /// The cell of `yAxisID`, or Dart `null` when absent.
  Opt<String>? get yAxisIDCell => _yAxisID;

  /// Stores the cell of `yAxisID`. Dart `null` deletes the key.
  set yAxisIDCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.yAxisID);
    } else {
      store(OptionKey.yAxisID, cell);
    }
  }

  /// Stores the plain value [value] of `yAxisID`.
  set yAxisID(String value) =>
      store(OptionKey.yAxisID, OptValue<String>(value));

  Opt<double>? _barPercentage;

  /// The cell of `barPercentage`, or Dart `null` when absent.
  Opt<double>? get barPercentageCell => _barPercentage;

  /// Stores the cell of `barPercentage`. Dart `null` deletes the key.
  set barPercentageCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.barPercentage);
    } else {
      store(OptionKey.barPercentage, cell);
    }
  }

  /// Stores the plain value [value] of `barPercentage`.
  set barPercentage(double value) =>
      store(OptionKey.barPercentage, OptValue<double>(value));

  Opt<double>? _categoryPercentage;

  /// The cell of `categoryPercentage`, or Dart `null` when absent.
  Opt<double>? get categoryPercentageCell => _categoryPercentage;

  /// Stores the cell of `categoryPercentage`. Dart `null` deletes the key.
  set categoryPercentageCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.categoryPercentage);
    } else {
      store(OptionKey.categoryPercentage, cell);
    }
  }

  /// Stores the plain value [value] of `categoryPercentage`.
  set categoryPercentage(double value) =>
      store(OptionKey.categoryPercentage, OptValue<double>(value));

  Opt<Object>? _barThickness;

  /// The cell of `barThickness`, or Dart `null` when absent.
  Opt<Object>? get barThicknessCell => _barThickness;

  /// Stores the cell of `barThickness`. Dart `null` deletes the key.
  set barThicknessCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.barThickness);
    } else {
      store(OptionKey.barThickness, cell);
    }
  }

  /// Stores the plain value [value] of `barThickness`.
  set barThickness(Object value) =>
      store(OptionKey.barThickness, classify(OptionKey.barThickness, value));

  Opt<double>? _maxBarThickness;

  /// The cell of `maxBarThickness`, or Dart `null` when absent.
  Opt<double>? get maxBarThicknessCell => _maxBarThickness;

  /// Stores the cell of `maxBarThickness`. Dart `null` deletes the key.
  set maxBarThicknessCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.maxBarThickness);
    } else {
      store(OptionKey.maxBarThickness, cell);
    }
  }

  /// Stores the plain value [value] of `maxBarThickness`.
  set maxBarThickness(double value) =>
      store(OptionKey.maxBarThickness, OptValue<double>(value));

  Opt<double>? _minBarLength;

  /// The cell of `minBarLength`, or Dart `null` when absent.
  Opt<double>? get minBarLengthCell => _minBarLength;

  /// Stores the cell of `minBarLength`. Dart `null` deletes the key.
  set minBarLengthCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.minBarLength);
    } else {
      store(OptionKey.minBarLength, cell);
    }
  }

  /// Stores the plain value [value] of `minBarLength`.
  set minBarLength(double value) =>
      store(OptionKey.minBarLength, OptValue<double>(value));

  Opt<Object>? _pointStyle;

  /// The cell of `pointStyle`, or Dart `null` when absent.
  Opt<Object>? get pointStyleCell => _pointStyle;

  /// Stores the cell of `pointStyle`. Dart `null` deletes the key.
  set pointStyleCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.pointStyle);
    } else {
      store(OptionKey.pointStyle, cell);
    }
  }

  /// Stores the plain value [value] of `pointStyle`.
  set pointStyle(Object value) =>
      store(OptionKey.pointStyle, classify(OptionKey.pointStyle, value));

  Opt<bool>? _grouped;

  /// The cell of `grouped`, or Dart `null` when absent.
  Opt<bool>? get groupedCell => _grouped;

  /// Stores the cell of `grouped`. Dart `null` deletes the key.
  set groupedCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.grouped);
    } else {
      store(OptionKey.grouped, cell);
    }
  }

  /// Stores the plain value [value] of `grouped`.
  set grouped(bool value) => store(OptionKey.grouped, OptValue<bool>(value));

  Opt<TooltipDatasetOptionsScope>? _tooltip;

  /// The cell of `tooltip`, or Dart `null` when absent.
  Opt<TooltipDatasetOptionsScope>? get tooltipCell => _tooltip;

  /// Stores the cell of `tooltip`. Dart `null` deletes the key.
  set tooltipCell(Opt<TooltipDatasetOptionsScope>? cell) {
    if (cell == null) {
      delete(OptionKey.tooltip);
    } else {
      store(OptionKey.tooltip, cell);
    }
  }

  /// Stores the plain value [value] of `tooltip`.
  set tooltip(TooltipDatasetOptionsScope value) =>
      store(OptionKey.tooltip, OptScope<TooltipDatasetOptionsScope>(value));

  Opt<String>? _type;

  /// The cell of `type`, or Dart `null` when absent.
  Opt<String>? get typeCell => _type;

  /// Stores the cell of `type`. Dart `null` deletes the key.
  set typeCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.type);
    } else {
      store(OptionKey.type, cell);
    }
  }

  /// Stores the plain value [value] of `type`.
  set type(String value) => store(OptionKey.type, OptValue<String>(value));

  Opt<Object>? _data;

  /// The cell of `data`, or Dart `null` when absent.
  Opt<Object>? get dataCell => _data;

  /// Stores the cell of `data`. Dart `null` deletes the key.
  set dataCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.data);
    } else {
      store(OptionKey.data, cell);
    }
  }

  /// Stores the plain value [value] of `data`.
  set data(Object value) =>
      store(OptionKey.data, classify(OptionKey.data, value));

  Opt<Object>? _hoverBorderRadius;

  /// The cell of `hoverBorderRadius`, or Dart `null` when absent.
  Opt<Object>? get hoverBorderRadiusCell => _hoverBorderRadius;

  /// Stores the cell of `hoverBorderRadius`. Dart `null` deletes the key.
  set hoverBorderRadiusCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBorderRadius);
    } else {
      store(OptionKey.hoverBorderRadius, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBorderRadius`.
  set hoverBorderRadius(Object value) => store(
    OptionKey.hoverBorderRadius,
    classify(OptionKey.hoverBorderRadius, value),
  );

  Opt<String>? _rAxisID;

  /// The cell of `rAxisID`, or Dart `null` when absent.
  Opt<String>? get rAxisIDCell => _rAxisID;

  /// Stores the cell of `rAxisID`. Dart `null` deletes the key.
  set rAxisIDCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.rAxisID);
    } else {
      store(OptionKey.rAxisID, cell);
    }
  }

  /// Stores the plain value [value] of `rAxisID`.
  set rAxisID(String value) =>
      store(OptionKey.rAxisID, OptValue<String>(value));

  Opt<Object>? _fill;

  /// The cell of `fill`, or Dart `null` when absent.
  Opt<Object>? get fillCell => _fill;

  /// Stores the cell of `fill`. Dart `null` deletes the key.
  set fillCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.fill);
    } else {
      store(OptionKey.fill, cell);
    }
  }

  /// Stores the plain value [value] of `fill`.
  set fill(Object value) =>
      store(OptionKey.fill, classify(OptionKey.fill, value));

  Opt<Object>? _datasetElementType;

  /// The cell of `datasetElementType`, or Dart `null` when absent.
  Opt<Object>? get datasetElementTypeCell => _datasetElementType;

  /// Stores the cell of `datasetElementType`. Dart `null` deletes the key.
  set datasetElementTypeCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.datasetElementType);
    } else {
      store(OptionKey.datasetElementType, cell);
    }
  }

  /// Stores the plain value [value] of `datasetElementType`.
  set datasetElementType(Object value) => store(
    OptionKey.datasetElementType,
    classify(OptionKey.datasetElementType, value),
  );

  Opt<Object>? _dataElementType;

  /// The cell of `dataElementType`, or Dart `null` when absent.
  Opt<Object>? get dataElementTypeCell => _dataElementType;

  /// Stores the cell of `dataElementType`. Dart `null` deletes the key.
  set dataElementTypeCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.dataElementType);
    } else {
      store(OptionKey.dataElementType, cell);
    }
  }

  /// Stores the plain value [value] of `dataElementType`.
  set dataElementType(Object value) => store(
    OptionKey.dataElementType,
    classify(OptionKey.dataElementType, value),
  );

  Opt<Object>? _pointBackgroundColor;

  /// The cell of `pointBackgroundColor`, or Dart `null` when absent.
  Opt<Object>? get pointBackgroundColorCell => _pointBackgroundColor;

  /// Stores the cell of `pointBackgroundColor`. Dart `null` deletes the key.
  set pointBackgroundColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.pointBackgroundColor);
    } else {
      store(OptionKey.pointBackgroundColor, cell);
    }
  }

  /// Stores the plain value [value] of `pointBackgroundColor`.
  set pointBackgroundColor(Object value) => store(
    OptionKey.pointBackgroundColor,
    classify(OptionKey.pointBackgroundColor, value),
  );

  Opt<Object>? _pointBorderColor;

  /// The cell of `pointBorderColor`, or Dart `null` when absent.
  Opt<Object>? get pointBorderColorCell => _pointBorderColor;

  /// Stores the cell of `pointBorderColor`. Dart `null` deletes the key.
  set pointBorderColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.pointBorderColor);
    } else {
      store(OptionKey.pointBorderColor, cell);
    }
  }

  /// Stores the plain value [value] of `pointBorderColor`.
  set pointBorderColor(Object value) => store(
    OptionKey.pointBorderColor,
    classify(OptionKey.pointBorderColor, value),
  );

  Opt<double>? _pointBorderWidth;

  /// The cell of `pointBorderWidth`, or Dart `null` when absent.
  Opt<double>? get pointBorderWidthCell => _pointBorderWidth;

  /// Stores the cell of `pointBorderWidth`. Dart `null` deletes the key.
  set pointBorderWidthCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.pointBorderWidth);
    } else {
      store(OptionKey.pointBorderWidth, cell);
    }
  }

  /// Stores the plain value [value] of `pointBorderWidth`.
  set pointBorderWidth(double value) =>
      store(OptionKey.pointBorderWidth, OptValue<double>(value));

  Opt<double>? _pointHitRadius;

  /// The cell of `pointHitRadius`, or Dart `null` when absent.
  Opt<double>? get pointHitRadiusCell => _pointHitRadius;

  /// Stores the cell of `pointHitRadius`. Dart `null` deletes the key.
  set pointHitRadiusCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.pointHitRadius);
    } else {
      store(OptionKey.pointHitRadius, cell);
    }
  }

  /// Stores the plain value [value] of `pointHitRadius`.
  set pointHitRadius(double value) =>
      store(OptionKey.pointHitRadius, OptValue<double>(value));

  Opt<double>? _pointRadius;

  /// The cell of `pointRadius`, or Dart `null` when absent.
  Opt<double>? get pointRadiusCell => _pointRadius;

  /// Stores the cell of `pointRadius`. Dart `null` deletes the key.
  set pointRadiusCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.pointRadius);
    } else {
      store(OptionKey.pointRadius, cell);
    }
  }

  /// Stores the plain value [value] of `pointRadius`.
  set pointRadius(double value) =>
      store(OptionKey.pointRadius, OptValue<double>(value));

  Opt<double>? _pointRotation;

  /// The cell of `pointRotation`, or Dart `null` when absent.
  Opt<double>? get pointRotationCell => _pointRotation;

  /// Stores the cell of `pointRotation`. Dart `null` deletes the key.
  set pointRotationCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.pointRotation);
    } else {
      store(OptionKey.pointRotation, cell);
    }
  }

  /// Stores the plain value [value] of `pointRotation`.
  set pointRotation(double value) =>
      store(OptionKey.pointRotation, OptValue<double>(value));

  Opt<Object>? _pointHoverBackgroundColor;

  /// The cell of `pointHoverBackgroundColor`, or Dart `null` when absent.
  Opt<Object>? get pointHoverBackgroundColorCell => _pointHoverBackgroundColor;

  /// Stores the cell of `pointHoverBackgroundColor`. Dart `null` deletes the key.
  set pointHoverBackgroundColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.pointHoverBackgroundColor);
    } else {
      store(OptionKey.pointHoverBackgroundColor, cell);
    }
  }

  /// Stores the plain value [value] of `pointHoverBackgroundColor`.
  set pointHoverBackgroundColor(Object value) => store(
    OptionKey.pointHoverBackgroundColor,
    classify(OptionKey.pointHoverBackgroundColor, value),
  );

  Opt<Object>? _pointHoverBorderColor;

  /// The cell of `pointHoverBorderColor`, or Dart `null` when absent.
  Opt<Object>? get pointHoverBorderColorCell => _pointHoverBorderColor;

  /// Stores the cell of `pointHoverBorderColor`. Dart `null` deletes the key.
  set pointHoverBorderColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.pointHoverBorderColor);
    } else {
      store(OptionKey.pointHoverBorderColor, cell);
    }
  }

  /// Stores the plain value [value] of `pointHoverBorderColor`.
  set pointHoverBorderColor(Object value) => store(
    OptionKey.pointHoverBorderColor,
    classify(OptionKey.pointHoverBorderColor, value),
  );

  Opt<double>? _pointHoverBorderWidth;

  /// The cell of `pointHoverBorderWidth`, or Dart `null` when absent.
  Opt<double>? get pointHoverBorderWidthCell => _pointHoverBorderWidth;

  /// Stores the cell of `pointHoverBorderWidth`. Dart `null` deletes the key.
  set pointHoverBorderWidthCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.pointHoverBorderWidth);
    } else {
      store(OptionKey.pointHoverBorderWidth, cell);
    }
  }

  /// Stores the plain value [value] of `pointHoverBorderWidth`.
  set pointHoverBorderWidth(double value) =>
      store(OptionKey.pointHoverBorderWidth, OptValue<double>(value));

  Opt<double>? _pointHoverRadius;

  /// The cell of `pointHoverRadius`, or Dart `null` when absent.
  Opt<double>? get pointHoverRadiusCell => _pointHoverRadius;

  /// Stores the cell of `pointHoverRadius`. Dart `null` deletes the key.
  set pointHoverRadiusCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.pointHoverRadius);
    } else {
      store(OptionKey.pointHoverRadius, cell);
    }
  }

  /// Stores the plain value [value] of `pointHoverRadius`.
  set pointHoverRadius(double value) =>
      store(OptionKey.pointHoverRadius, OptValue<double>(value));

  Opt<String>? _borderCapStyle;

  /// The cell of `borderCapStyle`, or Dart `null` when absent.
  Opt<String>? get borderCapStyleCell => _borderCapStyle;

  /// Stores the cell of `borderCapStyle`. Dart `null` deletes the key.
  set borderCapStyleCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.borderCapStyle);
    } else {
      store(OptionKey.borderCapStyle, cell);
    }
  }

  /// Stores the plain value [value] of `borderCapStyle`.
  set borderCapStyle(String value) =>
      store(OptionKey.borderCapStyle, OptValue<String>(value));

  Opt<Object>? _borderDash;

  /// The cell of `borderDash`, or Dart `null` when absent.
  Opt<Object>? get borderDashCell => _borderDash;

  /// Stores the cell of `borderDash`. Dart `null` deletes the key.
  set borderDashCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.borderDash);
    } else {
      store(OptionKey.borderDash, cell);
    }
  }

  /// Stores the plain value [value] of `borderDash`.
  set borderDash(Object value) =>
      store(OptionKey.borderDash, classify(OptionKey.borderDash, value));

  Opt<double>? _borderDashOffset;

  /// The cell of `borderDashOffset`, or Dart `null` when absent.
  Opt<double>? get borderDashOffsetCell => _borderDashOffset;

  /// Stores the cell of `borderDashOffset`. Dart `null` deletes the key.
  set borderDashOffsetCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.borderDashOffset);
    } else {
      store(OptionKey.borderDashOffset, cell);
    }
  }

  /// Stores the plain value [value] of `borderDashOffset`.
  set borderDashOffset(double value) =>
      store(OptionKey.borderDashOffset, OptValue<double>(value));

  Opt<String>? _borderJoinStyle;

  /// The cell of `borderJoinStyle`, or Dart `null` when absent.
  Opt<String>? get borderJoinStyleCell => _borderJoinStyle;

  /// Stores the cell of `borderJoinStyle`. Dart `null` deletes the key.
  set borderJoinStyleCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.borderJoinStyle);
    } else {
      store(OptionKey.borderJoinStyle, cell);
    }
  }

  /// Stores the plain value [value] of `borderJoinStyle`.
  set borderJoinStyle(String value) =>
      store(OptionKey.borderJoinStyle, OptValue<String>(value));

  Opt<bool>? _capBezierPoints;

  /// The cell of `capBezierPoints`, or Dart `null` when absent.
  Opt<bool>? get capBezierPointsCell => _capBezierPoints;

  /// Stores the cell of `capBezierPoints`. Dart `null` deletes the key.
  set capBezierPointsCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.capBezierPoints);
    } else {
      store(OptionKey.capBezierPoints, cell);
    }
  }

  /// Stores the plain value [value] of `capBezierPoints`.
  set capBezierPoints(bool value) =>
      store(OptionKey.capBezierPoints, OptValue<bool>(value));

  Opt<String>? _cubicInterpolationMode;

  /// The cell of `cubicInterpolationMode`, or Dart `null` when absent.
  Opt<String>? get cubicInterpolationModeCell => _cubicInterpolationMode;

  /// Stores the cell of `cubicInterpolationMode`. Dart `null` deletes the key.
  set cubicInterpolationModeCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.cubicInterpolationMode);
    } else {
      store(OptionKey.cubicInterpolationMode, cell);
    }
  }

  /// Stores the plain value [value] of `cubicInterpolationMode`.
  set cubicInterpolationMode(String value) =>
      store(OptionKey.cubicInterpolationMode, OptValue<String>(value));

  Opt<double>? _tension;

  /// The cell of `tension`, or Dart `null` when absent.
  Opt<double>? get tensionCell => _tension;

  /// Stores the cell of `tension`. Dart `null` deletes the key.
  set tensionCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.tension);
    } else {
      store(OptionKey.tension, cell);
    }
  }

  /// Stores the plain value [value] of `tension`.
  set tension(double value) =>
      store(OptionKey.tension, OptValue<double>(value));

  Opt<Object>? _stepped;

  /// The cell of `stepped`, or Dart `null` when absent.
  Opt<Object>? get steppedCell => _stepped;

  /// Stores the cell of `stepped`. Dart `null` deletes the key.
  set steppedCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.stepped);
    } else {
      store(OptionKey.stepped, cell);
    }
  }

  /// Stores the plain value [value] of `stepped`.
  set stepped(Object value) =>
      store(OptionKey.stepped, classify(OptionKey.stepped, value));

  Opt<SegmentOptionsScope>? _segment;

  /// The cell of `segment`, or Dart `null` when absent.
  Opt<SegmentOptionsScope>? get segmentCell => _segment;

  /// Stores the cell of `segment`. Dart `null` deletes the key.
  set segmentCell(Opt<SegmentOptionsScope>? cell) {
    if (cell == null) {
      delete(OptionKey.segment);
    } else {
      store(OptionKey.segment, cell);
    }
  }

  /// Stores the plain value [value] of `segment`.
  set segment(SegmentOptionsScope value) =>
      store(OptionKey.segment, OptScope<SegmentOptionsScope>(value));

  Opt<String>? _hoverBorderCapStyle;

  /// The cell of `hoverBorderCapStyle`, or Dart `null` when absent.
  Opt<String>? get hoverBorderCapStyleCell => _hoverBorderCapStyle;

  /// Stores the cell of `hoverBorderCapStyle`. Dart `null` deletes the key.
  set hoverBorderCapStyleCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBorderCapStyle);
    } else {
      store(OptionKey.hoverBorderCapStyle, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBorderCapStyle`.
  set hoverBorderCapStyle(String value) =>
      store(OptionKey.hoverBorderCapStyle, OptValue<String>(value));

  Opt<Object>? _hoverBorderDash;

  /// The cell of `hoverBorderDash`, or Dart `null` when absent.
  Opt<Object>? get hoverBorderDashCell => _hoverBorderDash;

  /// Stores the cell of `hoverBorderDash`. Dart `null` deletes the key.
  set hoverBorderDashCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBorderDash);
    } else {
      store(OptionKey.hoverBorderDash, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBorderDash`.
  set hoverBorderDash(Object value) => store(
    OptionKey.hoverBorderDash,
    classify(OptionKey.hoverBorderDash, value),
  );

  Opt<double>? _hoverBorderDashOffset;

  /// The cell of `hoverBorderDashOffset`, or Dart `null` when absent.
  Opt<double>? get hoverBorderDashOffsetCell => _hoverBorderDashOffset;

  /// Stores the cell of `hoverBorderDashOffset`. Dart `null` deletes the key.
  set hoverBorderDashOffsetCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBorderDashOffset);
    } else {
      store(OptionKey.hoverBorderDashOffset, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBorderDashOffset`.
  set hoverBorderDashOffset(double value) =>
      store(OptionKey.hoverBorderDashOffset, OptValue<double>(value));

  Opt<String>? _hoverBorderJoinStyle;

  /// The cell of `hoverBorderJoinStyle`, or Dart `null` when absent.
  Opt<String>? get hoverBorderJoinStyleCell => _hoverBorderJoinStyle;

  /// Stores the cell of `hoverBorderJoinStyle`. Dart `null` deletes the key.
  set hoverBorderJoinStyleCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBorderJoinStyle);
    } else {
      store(OptionKey.hoverBorderJoinStyle, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBorderJoinStyle`.
  set hoverBorderJoinStyle(String value) =>
      store(OptionKey.hoverBorderJoinStyle, OptValue<String>(value));

  Opt<double>? _hitRadius;

  /// The cell of `hitRadius`, or Dart `null` when absent.
  Opt<double>? get hitRadiusCell => _hitRadius;

  /// Stores the cell of `hitRadius`. Dart `null` deletes the key.
  set hitRadiusCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.hitRadius);
    } else {
      store(OptionKey.hitRadius, cell);
    }
  }

  /// Stores the plain value [value] of `hitRadius`.
  set hitRadius(double value) =>
      store(OptionKey.hitRadius, OptValue<double>(value));

  Opt<double>? _hoverRadius;

  /// The cell of `hoverRadius`, or Dart `null` when absent.
  Opt<double>? get hoverRadiusCell => _hoverRadius;

  /// Stores the cell of `hoverRadius`. Dart `null` deletes the key.
  set hoverRadiusCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverRadius);
    } else {
      store(OptionKey.hoverRadius, cell);
    }
  }

  /// Stores the plain value [value] of `hoverRadius`.
  set hoverRadius(double value) =>
      store(OptionKey.hoverRadius, OptValue<double>(value));

  Opt<bool>? _selfJoin;

  /// The cell of `selfJoin`, or Dart `null` when absent.
  Opt<bool>? get selfJoinCell => _selfJoin;

  /// Stores the cell of `selfJoin`. Dart `null` deletes the key.
  set selfJoinCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.selfJoin);
    } else {
      store(OptionKey.selfJoin, cell);
    }
  }

  /// Stores the plain value [value] of `selfJoin`.
  set selfJoin(bool value) => store(OptionKey.selfJoin, OptValue<bool>(value));

  Opt<String>? _borderAlign;

  /// The cell of `borderAlign`, or Dart `null` when absent.
  Opt<String>? get borderAlignCell => _borderAlign;

  /// Stores the cell of `borderAlign`. Dart `null` deletes the key.
  set borderAlignCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.borderAlign);
    } else {
      store(OptionKey.borderAlign, cell);
    }
  }

  /// Stores the plain value [value] of `borderAlign`.
  set borderAlign(String value) =>
      store(OptionKey.borderAlign, OptValue<String>(value));

  Opt<bool>? _circular;

  /// The cell of `circular`, or Dart `null` when absent.
  Opt<bool>? get circularCell => _circular;

  /// Stores the cell of `circular`. Dart `null` deletes the key.
  set circularCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.circular);
    } else {
      store(OptionKey.circular, cell);
    }
  }

  /// Stores the plain value [value] of `circular`.
  set circular(bool value) => store(OptionKey.circular, OptValue<bool>(value));

  Opt<double>? _hoverOffset;

  /// The cell of `hoverOffset`, or Dart `null` when absent.
  Opt<double>? get hoverOffsetCell => _hoverOffset;

  /// Stores the cell of `hoverOffset`. Dart `null` deletes the key.
  set hoverOffsetCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverOffset);
    } else {
      store(OptionKey.hoverOffset, cell);
    }
  }

  /// Stores the plain value [value] of `hoverOffset`.
  set hoverOffset(double value) =>
      store(OptionKey.hoverOffset, OptValue<double>(value));

  Opt<double>? _weight;

  /// The cell of `weight`, or Dart `null` when absent.
  Opt<double>? get weightCell => _weight;

  /// Stores the cell of `weight`. Dart `null` deletes the key.
  set weightCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.weight);
    } else {
      store(OptionKey.weight, cell);
    }
  }

  /// Stores the plain value [value] of `weight`.
  set weight(double value) => store(OptionKey.weight, OptValue<double>(value));

  Opt<double>? _angle;

  /// The cell of `angle`, or Dart `null` when absent.
  Opt<double>? get angleCell => _angle;

  /// Stores the cell of `angle`. Dart `null` deletes the key.
  set angleCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.angle);
    } else {
      store(OptionKey.angle, cell);
    }
  }

  /// Stores the plain value [value] of `angle`.
  set angle(double value) => store(OptionKey.angle, OptValue<double>(value));

  Opt<double>? _cutoutPercentage;

  /// The cell of `cutoutPercentage`, or Dart `null` when absent.
  Opt<double>? get cutoutPercentageCell => _cutoutPercentage;

  /// Stores the cell of `cutoutPercentage`. Dart `null` deletes the key.
  set cutoutPercentageCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.cutoutPercentage);
    } else {
      store(OptionKey.cutoutPercentage, cell);
    }
  }

  /// Stores the plain value [value] of `cutoutPercentage`.
  set cutoutPercentage(double value) =>
      store(OptionKey.cutoutPercentage, OptValue<double>(value));

  @override
  Opt<Object?>? cellOf(OptionKey key) => switch (key) {
    OptionKey.parsing => _parsing,
    OptionKey.normalized => _normalized,
    OptionKey.animation => _animation,
    OptionKey.animations => _animations,
    OptionKey.transitions => _transitions,
    OptionKey.datasets => _datasets,
    OptionKey.indexAxis => _indexAxis,
    OptionKey.clip => _clip,
    OptionKey.color => _color,
    OptionKey.backgroundColor => _backgroundColor,
    OptionKey.hoverBackgroundColor => _hoverBackgroundColor,
    OptionKey.borderColor => _borderColor,
    OptionKey.hoverBorderColor => _hoverBorderColor,
    OptionKey.font => _font,
    OptionKey.responsive => _responsive,
    OptionKey.maintainAspectRatio => _maintainAspectRatio,
    OptionKey.resizeDelay => _resizeDelay,
    OptionKey.aspectRatio => _aspectRatio,
    OptionKey.locale => _locale,
    OptionKey.onResize => _onResize,
    OptionKey.devicePixelRatio => _devicePixelRatio,
    OptionKey.interaction => _interaction,
    OptionKey.hover => _hover,
    OptionKey.events => _events,
    OptionKey.onHover => _onHover,
    OptionKey.onClick => _onClick,
    OptionKey.layout => _layout,
    OptionKey.elements => _elements,
    OptionKey.plugins => _plugins,
    OptionKey.scales => _scales,
    OptionKey.skipNull => _skipNull,
    OptionKey.spanGaps => _spanGaps,
    OptionKey.showLine => _showLine,
    OptionKey.circumference => _circumference,
    OptionKey.cutout => _cutout,
    OptionKey.offset => _offset,
    OptionKey.radius => _radius,
    OptionKey.rotation => _rotation,
    OptionKey.spacing => _spacing,
    OptionKey.spacingMode => _spacingMode,
    OptionKey.startAngle => _startAngle,
    OptionKey.scale => _scale,
    OptionKey.hoverColor => _hoverColor,
    OptionKey.drawActiveElementsOnTop => _drawActiveElementsOnTop,
    OptionKey.label => _label,
    OptionKey.order => _order,
    OptionKey.stack => _stack,
    OptionKey.hidden => _hidden,
    OptionKey.base => _base,
    OptionKey.borderSkipped => _borderSkipped,
    OptionKey.borderRadius => _borderRadius,
    OptionKey.inflateAmount => _inflateAmount,
    OptionKey.borderWidth => _borderWidth,
    OptionKey.hoverBorderWidth => _hoverBorderWidth,
    OptionKey.xAxisID => _xAxisID,
    OptionKey.yAxisID => _yAxisID,
    OptionKey.barPercentage => _barPercentage,
    OptionKey.categoryPercentage => _categoryPercentage,
    OptionKey.barThickness => _barThickness,
    OptionKey.maxBarThickness => _maxBarThickness,
    OptionKey.minBarLength => _minBarLength,
    OptionKey.pointStyle => _pointStyle,
    OptionKey.grouped => _grouped,
    OptionKey.tooltip => _tooltip,
    OptionKey.type => _type,
    OptionKey.data => _data,
    OptionKey.hoverBorderRadius => _hoverBorderRadius,
    OptionKey.rAxisID => _rAxisID,
    OptionKey.fill => _fill,
    OptionKey.datasetElementType => _datasetElementType,
    OptionKey.dataElementType => _dataElementType,
    OptionKey.pointBackgroundColor => _pointBackgroundColor,
    OptionKey.pointBorderColor => _pointBorderColor,
    OptionKey.pointBorderWidth => _pointBorderWidth,
    OptionKey.pointHitRadius => _pointHitRadius,
    OptionKey.pointRadius => _pointRadius,
    OptionKey.pointRotation => _pointRotation,
    OptionKey.pointHoverBackgroundColor => _pointHoverBackgroundColor,
    OptionKey.pointHoverBorderColor => _pointHoverBorderColor,
    OptionKey.pointHoverBorderWidth => _pointHoverBorderWidth,
    OptionKey.pointHoverRadius => _pointHoverRadius,
    OptionKey.borderCapStyle => _borderCapStyle,
    OptionKey.borderDash => _borderDash,
    OptionKey.borderDashOffset => _borderDashOffset,
    OptionKey.borderJoinStyle => _borderJoinStyle,
    OptionKey.capBezierPoints => _capBezierPoints,
    OptionKey.cubicInterpolationMode => _cubicInterpolationMode,
    OptionKey.tension => _tension,
    OptionKey.stepped => _stepped,
    OptionKey.segment => _segment,
    OptionKey.hoverBorderCapStyle => _hoverBorderCapStyle,
    OptionKey.hoverBorderDash => _hoverBorderDash,
    OptionKey.hoverBorderDashOffset => _hoverBorderDashOffset,
    OptionKey.hoverBorderJoinStyle => _hoverBorderJoinStyle,
    OptionKey.hitRadius => _hitRadius,
    OptionKey.hoverRadius => _hoverRadius,
    OptionKey.selfJoin => _selfJoin,
    OptionKey.borderAlign => _borderAlign,
    OptionKey.circular => _circular,
    OptionKey.hoverOffset => _hoverOffset,
    OptionKey.weight => _weight,
    OptionKey.angle => _angle,
    OptionKey.cutoutPercentage => _cutoutPercentage,
    _ => null,
  };

  @override
  void setCell(OptionKey key, Opt<Object?>? cell) {
    switch (key) {
      case OptionKey.parsing:
        _parsing = fitCell(cell, (raw) => classifyUnion(raw, 34));
      case OptionKey.normalized:
        _normalized = fitCell(cell, classifyBool);
      case OptionKey.animation:
        _animation = fitCell(cell, (raw) => classifyUnion(raw, 34));
      case OptionKey.animations:
        _animations = fitCell(cell, (raw) => classifyUnion(raw, 34));
      case OptionKey.transitions:
        _transitions = fitCell(cell, classifyScope<TransitionsSpecScope>);
      case OptionKey.datasets:
        _datasets = fitCell(cell, classifyScope<DatasetOptionsByTypeScope>);
      case OptionKey.indexAxis:
        _indexAxis = fitCell(cell, classifyString);
      case OptionKey.clip:
        _clip = fitCell(cell, (raw) => classifyUnion(raw, 35));
      case OptionKey.color:
        _color = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.backgroundColor:
        _backgroundColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.hoverBackgroundColor:
        _hoverBackgroundColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.borderColor:
        _borderColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.hoverBorderColor:
        _hoverBorderColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.font:
        _font = fitCell(cell, classifyScope<FontSpecScope>);
      case OptionKey.responsive:
        _responsive = fitCell(cell, classifyBool);
      case OptionKey.maintainAspectRatio:
        _maintainAspectRatio = fitCell(cell, classifyBool);
      case OptionKey.resizeDelay:
        _resizeDelay = fitCell(cell, classifyNumber);
      case OptionKey.aspectRatio:
        _aspectRatio = fitCell(cell, classifyNumber);
      case OptionKey.locale:
        _locale = fitCell(cell, classifyString);
      case OptionKey.onResize:
        _onResize = fitCell(cell, (raw) => classifyUnion(raw, 8));
      case OptionKey.devicePixelRatio:
        _devicePixelRatio = fitCell(cell, classifyNumber);
      case OptionKey.interaction:
        _interaction = fitCell(cell, classifyScope<InteractionOptionsScope>);
      case OptionKey.hover:
        _hover = fitCell(cell, classifyScope<InteractionOptionsScope>);
      case OptionKey.events:
        _events = fitCell(cell, (raw) => classifyUnion(raw, 16));
      case OptionKey.onHover:
        _onHover = fitCell(cell, (raw) => classifyUnion(raw, 8));
      case OptionKey.onClick:
        _onClick = fitCell(cell, (raw) => classifyUnion(raw, 8));
      case OptionKey.layout:
        _layout = fitCell(cell, classifyScope<LayoutOptionsScope>);
      case OptionKey.elements:
        _elements = fitCell(cell, classifyScope<ElementOptionsByTypeScope>);
      case OptionKey.plugins:
        _plugins = fitCell(cell, classifyScope<PluginOptionsByTypeScope>);
      case OptionKey.scales:
        _scales = fitCell(cell, classifyScope<ScaleOptionsByIdScope>);
      case OptionKey.skipNull:
        _skipNull = fitCell(cell, classifyBool);
      case OptionKey.spanGaps:
        _spanGaps = fitCell(cell, (raw) => classifyUnion(raw, 3));
      case OptionKey.showLine:
        _showLine = fitCell(cell, classifyBool);
      case OptionKey.circumference:
        _circumference = fitCell(cell, classifyNumber);
      case OptionKey.cutout:
        _cutout = fitCell(cell, (raw) => classifyUnion(raw, 5));
      case OptionKey.offset:
        _offset = fitCell(cell, classifyNumber);
      case OptionKey.radius:
        _radius = fitCell(cell, (raw) => classifyUnion(raw, 5));
      case OptionKey.rotation:
        _rotation = fitCell(cell, classifyNumber);
      case OptionKey.spacing:
        _spacing = fitCell(cell, classifyNumber);
      case OptionKey.spacingMode:
        _spacingMode = fitCell(cell, classifyString);
      case OptionKey.startAngle:
        _startAngle = fitCell(cell, classifyNumber);
      case OptionKey.scale:
        _scale = fitCell(cell, classifyScope<ScaleOptionsScope>);
      case OptionKey.hoverColor:
        _hoverColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.drawActiveElementsOnTop:
        _drawActiveElementsOnTop = fitCell(cell, classifyBool);
      case OptionKey.label:
        _label = fitCell(cell, classifyString);
      case OptionKey.order:
        _order = fitCell(cell, classifyNumber);
      case OptionKey.stack:
        _stack = fitCell(cell, classifyString);
      case OptionKey.hidden:
        _hidden = fitCell(cell, classifyBool);
      case OptionKey.base:
        _base = fitCell(cell, classifyNumber);
      case OptionKey.borderSkipped:
        _borderSkipped = fitCell(cell, (raw) => classifyUnion(raw, 6));
      case OptionKey.borderRadius:
        _borderRadius = fitCell(cell, (raw) => classifyUnion(raw, 33));
      case OptionKey.inflateAmount:
        _inflateAmount = fitCell(cell, (raw) => classifyUnion(raw, 5));
      case OptionKey.borderWidth:
        _borderWidth = fitCell(cell, (raw) => classifyUnion(raw, 33));
      case OptionKey.hoverBorderWidth:
        _hoverBorderWidth = fitCell(cell, classifyNumber);
      case OptionKey.xAxisID:
        _xAxisID = fitCell(cell, classifyString);
      case OptionKey.yAxisID:
        _yAxisID = fitCell(cell, classifyString);
      case OptionKey.barPercentage:
        _barPercentage = fitCell(cell, classifyNumber);
      case OptionKey.categoryPercentage:
        _categoryPercentage = fitCell(cell, classifyNumber);
      case OptionKey.barThickness:
        _barThickness = fitCell(cell, (raw) => classifyUnion(raw, 5));
      case OptionKey.maxBarThickness:
        _maxBarThickness = fitCell(cell, classifyNumber);
      case OptionKey.minBarLength:
        _minBarLength = fitCell(cell, classifyNumber);
      case OptionKey.pointStyle:
        _pointStyle = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.grouped:
        _grouped = fitCell(cell, classifyBool);
      case OptionKey.tooltip:
        _tooltip = fitCell(cell, classifyScope<TooltipDatasetOptionsScope>);
      case OptionKey.type:
        _type = fitCell(cell, classifyString);
      case OptionKey.data:
        _data = fitCell(cell, (raw) => classifyUnion(raw, 16));
      case OptionKey.hoverBorderRadius:
        _hoverBorderRadius = fitCell(cell, (raw) => classifyUnion(raw, 33));
      case OptionKey.rAxisID:
        _rAxisID = fitCell(cell, classifyString);
      case OptionKey.fill:
        _fill = fitCell(cell, (raw) => classifyUnion(raw, 39));
      case OptionKey.datasetElementType:
        _datasetElementType = fitCell(cell, (raw) => classifyUnion(raw, 6));
      case OptionKey.dataElementType:
        _dataElementType = fitCell(cell, (raw) => classifyUnion(raw, 6));
      case OptionKey.pointBackgroundColor:
        _pointBackgroundColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.pointBorderColor:
        _pointBorderColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.pointBorderWidth:
        _pointBorderWidth = fitCell(cell, classifyNumber);
      case OptionKey.pointHitRadius:
        _pointHitRadius = fitCell(cell, classifyNumber);
      case OptionKey.pointRadius:
        _pointRadius = fitCell(cell, classifyNumber);
      case OptionKey.pointRotation:
        _pointRotation = fitCell(cell, classifyNumber);
      case OptionKey.pointHoverBackgroundColor:
        _pointHoverBackgroundColor = fitCell(
          cell,
          (raw) => classifyUnion(raw, 64),
        );
      case OptionKey.pointHoverBorderColor:
        _pointHoverBorderColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.pointHoverBorderWidth:
        _pointHoverBorderWidth = fitCell(cell, classifyNumber);
      case OptionKey.pointHoverRadius:
        _pointHoverRadius = fitCell(cell, classifyNumber);
      case OptionKey.borderCapStyle:
        _borderCapStyle = fitCell(cell, classifyString);
      case OptionKey.borderDash:
        _borderDash = fitCell(cell, (raw) => classifyUnion(raw, 16));
      case OptionKey.borderDashOffset:
        _borderDashOffset = fitCell(cell, classifyNumber);
      case OptionKey.borderJoinStyle:
        _borderJoinStyle = fitCell(cell, classifyString);
      case OptionKey.capBezierPoints:
        _capBezierPoints = fitCell(cell, classifyBool);
      case OptionKey.cubicInterpolationMode:
        _cubicInterpolationMode = fitCell(cell, classifyString);
      case OptionKey.tension:
        _tension = fitCell(cell, classifyNumber);
      case OptionKey.stepped:
        _stepped = fitCell(cell, (raw) => classifyUnion(raw, 6));
      case OptionKey.segment:
        _segment = fitCell(cell, classifyScope<SegmentOptionsScope>);
      case OptionKey.hoverBorderCapStyle:
        _hoverBorderCapStyle = fitCell(cell, classifyString);
      case OptionKey.hoverBorderDash:
        _hoverBorderDash = fitCell(cell, (raw) => classifyUnion(raw, 16));
      case OptionKey.hoverBorderDashOffset:
        _hoverBorderDashOffset = fitCell(cell, classifyNumber);
      case OptionKey.hoverBorderJoinStyle:
        _hoverBorderJoinStyle = fitCell(cell, classifyString);
      case OptionKey.hitRadius:
        _hitRadius = fitCell(cell, classifyNumber);
      case OptionKey.hoverRadius:
        _hoverRadius = fitCell(cell, classifyNumber);
      case OptionKey.selfJoin:
        _selfJoin = fitCell(cell, classifyBool);
      case OptionKey.borderAlign:
        _borderAlign = fitCell(cell, classifyString);
      case OptionKey.circular:
        _circular = fitCell(cell, classifyBool);
      case OptionKey.hoverOffset:
        _hoverOffset = fitCell(cell, classifyNumber);
      case OptionKey.weight:
        _weight = fitCell(cell, classifyNumber);
      case OptionKey.angle:
        _angle = fitCell(cell, classifyNumber);
      case OptionKey.cutoutPercentage:
        _cutoutPercentage = fitCell(cell, classifyNumber);
      default:
        throw ArgumentError.value(key, 'key', 'Not a key of ChartOptions');
    }
  }

  @override
  bool hasField(OptionKey key) => switch (key) {
    OptionKey.parsing ||
    OptionKey.normalized ||
    OptionKey.animation ||
    OptionKey.animations ||
    OptionKey.transitions ||
    OptionKey.datasets ||
    OptionKey.indexAxis ||
    OptionKey.clip ||
    OptionKey.color ||
    OptionKey.backgroundColor ||
    OptionKey.hoverBackgroundColor ||
    OptionKey.borderColor ||
    OptionKey.hoverBorderColor ||
    OptionKey.font ||
    OptionKey.responsive ||
    OptionKey.maintainAspectRatio ||
    OptionKey.resizeDelay ||
    OptionKey.aspectRatio ||
    OptionKey.locale ||
    OptionKey.onResize ||
    OptionKey.devicePixelRatio ||
    OptionKey.interaction ||
    OptionKey.hover ||
    OptionKey.events ||
    OptionKey.onHover ||
    OptionKey.onClick ||
    OptionKey.layout ||
    OptionKey.elements ||
    OptionKey.plugins ||
    OptionKey.scales ||
    OptionKey.skipNull ||
    OptionKey.spanGaps ||
    OptionKey.showLine ||
    OptionKey.circumference ||
    OptionKey.cutout ||
    OptionKey.offset ||
    OptionKey.radius ||
    OptionKey.rotation ||
    OptionKey.spacing ||
    OptionKey.spacingMode ||
    OptionKey.startAngle ||
    OptionKey.scale ||
    OptionKey.hoverColor ||
    OptionKey.drawActiveElementsOnTop ||
    OptionKey.label ||
    OptionKey.order ||
    OptionKey.stack ||
    OptionKey.hidden ||
    OptionKey.base ||
    OptionKey.borderSkipped ||
    OptionKey.borderRadius ||
    OptionKey.inflateAmount ||
    OptionKey.borderWidth ||
    OptionKey.hoverBorderWidth ||
    OptionKey.xAxisID ||
    OptionKey.yAxisID ||
    OptionKey.barPercentage ||
    OptionKey.categoryPercentage ||
    OptionKey.barThickness ||
    OptionKey.maxBarThickness ||
    OptionKey.minBarLength ||
    OptionKey.pointStyle ||
    OptionKey.grouped ||
    OptionKey.tooltip ||
    OptionKey.type ||
    OptionKey.data ||
    OptionKey.hoverBorderRadius ||
    OptionKey.rAxisID ||
    OptionKey.fill ||
    OptionKey.datasetElementType ||
    OptionKey.dataElementType ||
    OptionKey.pointBackgroundColor ||
    OptionKey.pointBorderColor ||
    OptionKey.pointBorderWidth ||
    OptionKey.pointHitRadius ||
    OptionKey.pointRadius ||
    OptionKey.pointRotation ||
    OptionKey.pointHoverBackgroundColor ||
    OptionKey.pointHoverBorderColor ||
    OptionKey.pointHoverBorderWidth ||
    OptionKey.pointHoverRadius ||
    OptionKey.borderCapStyle ||
    OptionKey.borderDash ||
    OptionKey.borderDashOffset ||
    OptionKey.borderJoinStyle ||
    OptionKey.capBezierPoints ||
    OptionKey.cubicInterpolationMode ||
    OptionKey.tension ||
    OptionKey.stepped ||
    OptionKey.segment ||
    OptionKey.hoverBorderCapStyle ||
    OptionKey.hoverBorderDash ||
    OptionKey.hoverBorderDashOffset ||
    OptionKey.hoverBorderJoinStyle ||
    OptionKey.hitRadius ||
    OptionKey.hoverRadius ||
    OptionKey.selfJoin ||
    OptionKey.borderAlign ||
    OptionKey.circular ||
    OptionKey.hoverOffset ||
    OptionKey.weight ||
    OptionKey.angle ||
    OptionKey.cutoutPercentage => true,
    _ => false,
  };

  @override
  Opt<Object?> classify(OptionKey key, Object? raw) => switch (key) {
    OptionKey.parsing => classifyUnion(raw, 34),
    OptionKey.normalized => classifyBool(raw),
    OptionKey.animation => classifyUnion(raw, 34),
    OptionKey.animations => classifyUnion(raw, 34),
    OptionKey.transitions => classifyScope<TransitionsSpecScope>(raw),
    OptionKey.datasets => classifyScope<DatasetOptionsByTypeScope>(raw),
    OptionKey.indexAxis => classifyString(raw),
    OptionKey.clip => classifyUnion(raw, 35),
    OptionKey.color => classifyUnion(raw, 64),
    OptionKey.backgroundColor => classifyUnion(raw, 64),
    OptionKey.hoverBackgroundColor => classifyUnion(raw, 64),
    OptionKey.borderColor => classifyUnion(raw, 64),
    OptionKey.hoverBorderColor => classifyUnion(raw, 64),
    OptionKey.font => classifyScope<FontSpecScope>(raw),
    OptionKey.responsive => classifyBool(raw),
    OptionKey.maintainAspectRatio => classifyBool(raw),
    OptionKey.resizeDelay => classifyNumber(raw),
    OptionKey.aspectRatio => classifyNumber(raw),
    OptionKey.locale => classifyString(raw),
    OptionKey.onResize => classifyUnion(raw, 8),
    OptionKey.devicePixelRatio => classifyNumber(raw),
    OptionKey.interaction => classifyScope<InteractionOptionsScope>(raw),
    OptionKey.hover => classifyScope<InteractionOptionsScope>(raw),
    OptionKey.events => classifyUnion(raw, 16),
    OptionKey.onHover => classifyUnion(raw, 8),
    OptionKey.onClick => classifyUnion(raw, 8),
    OptionKey.layout => classifyScope<LayoutOptionsScope>(raw),
    OptionKey.elements => classifyScope<ElementOptionsByTypeScope>(raw),
    OptionKey.plugins => classifyScope<PluginOptionsByTypeScope>(raw),
    OptionKey.scales => classifyScope<ScaleOptionsByIdScope>(raw),
    OptionKey.skipNull => classifyBool(raw),
    OptionKey.spanGaps => classifyUnion(raw, 3),
    OptionKey.showLine => classifyBool(raw),
    OptionKey.circumference => classifyNumber(raw),
    OptionKey.cutout => classifyUnion(raw, 5),
    OptionKey.offset => classifyNumber(raw),
    OptionKey.radius => classifyUnion(raw, 5),
    OptionKey.rotation => classifyNumber(raw),
    OptionKey.spacing => classifyNumber(raw),
    OptionKey.spacingMode => classifyString(raw),
    OptionKey.startAngle => classifyNumber(raw),
    OptionKey.scale => classifyScope<ScaleOptionsScope>(raw),
    OptionKey.hoverColor => classifyUnion(raw, 64),
    OptionKey.drawActiveElementsOnTop => classifyBool(raw),
    OptionKey.label => classifyString(raw),
    OptionKey.order => classifyNumber(raw),
    OptionKey.stack => classifyString(raw),
    OptionKey.hidden => classifyBool(raw),
    OptionKey.base => classifyNumber(raw),
    OptionKey.borderSkipped => classifyUnion(raw, 6),
    OptionKey.borderRadius => classifyUnion(raw, 33),
    OptionKey.inflateAmount => classifyUnion(raw, 5),
    OptionKey.borderWidth => classifyUnion(raw, 33),
    OptionKey.hoverBorderWidth => classifyNumber(raw),
    OptionKey.xAxisID => classifyString(raw),
    OptionKey.yAxisID => classifyString(raw),
    OptionKey.barPercentage => classifyNumber(raw),
    OptionKey.categoryPercentage => classifyNumber(raw),
    OptionKey.barThickness => classifyUnion(raw, 5),
    OptionKey.maxBarThickness => classifyNumber(raw),
    OptionKey.minBarLength => classifyNumber(raw),
    OptionKey.pointStyle => classifyUnion(raw, 64),
    OptionKey.grouped => classifyBool(raw),
    OptionKey.tooltip => classifyScope<TooltipDatasetOptionsScope>(raw),
    OptionKey.type => classifyString(raw),
    OptionKey.data => classifyUnion(raw, 16),
    OptionKey.hoverBorderRadius => classifyUnion(raw, 33),
    OptionKey.rAxisID => classifyString(raw),
    OptionKey.fill => classifyUnion(raw, 39),
    OptionKey.datasetElementType => classifyUnion(raw, 6),
    OptionKey.dataElementType => classifyUnion(raw, 6),
    OptionKey.pointBackgroundColor => classifyUnion(raw, 64),
    OptionKey.pointBorderColor => classifyUnion(raw, 64),
    OptionKey.pointBorderWidth => classifyNumber(raw),
    OptionKey.pointHitRadius => classifyNumber(raw),
    OptionKey.pointRadius => classifyNumber(raw),
    OptionKey.pointRotation => classifyNumber(raw),
    OptionKey.pointHoverBackgroundColor => classifyUnion(raw, 64),
    OptionKey.pointHoverBorderColor => classifyUnion(raw, 64),
    OptionKey.pointHoverBorderWidth => classifyNumber(raw),
    OptionKey.pointHoverRadius => classifyNumber(raw),
    OptionKey.borderCapStyle => classifyString(raw),
    OptionKey.borderDash => classifyUnion(raw, 16),
    OptionKey.borderDashOffset => classifyNumber(raw),
    OptionKey.borderJoinStyle => classifyString(raw),
    OptionKey.capBezierPoints => classifyBool(raw),
    OptionKey.cubicInterpolationMode => classifyString(raw),
    OptionKey.tension => classifyNumber(raw),
    OptionKey.stepped => classifyUnion(raw, 6),
    OptionKey.segment => classifyScope<SegmentOptionsScope>(raw),
    OptionKey.hoverBorderCapStyle => classifyString(raw),
    OptionKey.hoverBorderDash => classifyUnion(raw, 16),
    OptionKey.hoverBorderDashOffset => classifyNumber(raw),
    OptionKey.hoverBorderJoinStyle => classifyString(raw),
    OptionKey.hitRadius => classifyNumber(raw),
    OptionKey.hoverRadius => classifyNumber(raw),
    OptionKey.selfJoin => classifyBool(raw),
    OptionKey.borderAlign => classifyString(raw),
    OptionKey.circular => classifyBool(raw),
    OptionKey.hoverOffset => classifyNumber(raw),
    OptionKey.weight => classifyNumber(raw),
    OptionKey.angle => classifyNumber(raw),
    OptionKey.cutoutPercentage => classifyNumber(raw),
    _ => kind.classifyOther(raw),
  };
}

/// index.d.ts:3029 PluginOptionsByType, the scope `plugins` (by plugin id). A
/// plugin entry can be `false` (the plugin is off).
base class PluginOptionsByTypeScope extends OptionScope {
  /// An empty scope.
  PluginOptionsByTypeScope();

  @override
  ScopeKind get kind => ScopeKind.pluginOptionsByType;

  Opt<Object>? _colors;

  /// The cell of `colors`, or Dart `null` when absent.
  Opt<Object>? get colorsCell => _colors;

  /// Stores the cell of `colors`. Dart `null` deletes the key.
  set colorsCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.colors);
    } else {
      store(OptionKey.colors, cell);
    }
  }

  /// Stores the plain value [value] of `colors`.
  set colors(Object value) =>
      store(OptionKey.colors, classify(OptionKey.colors, value));

  Opt<Object>? _decimation;

  /// The cell of `decimation`, or Dart `null` when absent.
  Opt<Object>? get decimationCell => _decimation;

  /// Stores the cell of `decimation`. Dart `null` deletes the key.
  set decimationCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.decimation);
    } else {
      store(OptionKey.decimation, cell);
    }
  }

  /// Stores the plain value [value] of `decimation`.
  set decimation(Object value) =>
      store(OptionKey.decimation, classify(OptionKey.decimation, value));

  Opt<Object>? _filler;

  /// The cell of `filler`, or Dart `null` when absent.
  Opt<Object>? get fillerCell => _filler;

  /// Stores the cell of `filler`. Dart `null` deletes the key.
  set fillerCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.filler);
    } else {
      store(OptionKey.filler, cell);
    }
  }

  /// Stores the plain value [value] of `filler`.
  set filler(Object value) =>
      store(OptionKey.filler, classify(OptionKey.filler, value));

  Opt<Object>? _legend;

  /// The cell of `legend`, or Dart `null` when absent.
  Opt<Object>? get legendCell => _legend;

  /// Stores the cell of `legend`. Dart `null` deletes the key.
  set legendCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.legend);
    } else {
      store(OptionKey.legend, cell);
    }
  }

  /// Stores the plain value [value] of `legend`.
  set legend(Object value) =>
      store(OptionKey.legend, classify(OptionKey.legend, value));

  Opt<Object>? _subtitle;

  /// The cell of `subtitle`, or Dart `null` when absent.
  Opt<Object>? get subtitleCell => _subtitle;

  /// Stores the cell of `subtitle`. Dart `null` deletes the key.
  set subtitleCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.subtitle);
    } else {
      store(OptionKey.subtitle, cell);
    }
  }

  /// Stores the plain value [value] of `subtitle`.
  set subtitle(Object value) =>
      store(OptionKey.subtitle, classify(OptionKey.subtitle, value));

  Opt<Object>? _title;

  /// The cell of `title`, or Dart `null` when absent.
  Opt<Object>? get titleCell => _title;

  /// Stores the cell of `title`. Dart `null` deletes the key.
  set titleCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.title);
    } else {
      store(OptionKey.title, cell);
    }
  }

  /// Stores the plain value [value] of `title`.
  set title(Object value) =>
      store(OptionKey.title, classify(OptionKey.title, value));

  Opt<Object>? _tooltip;

  /// The cell of `tooltip`, or Dart `null` when absent.
  Opt<Object>? get tooltipCell => _tooltip;

  /// Stores the cell of `tooltip`. Dart `null` deletes the key.
  set tooltipCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.tooltip);
    } else {
      store(OptionKey.tooltip, cell);
    }
  }

  /// Stores the plain value [value] of `tooltip`.
  set tooltip(Object value) =>
      store(OptionKey.tooltip, classify(OptionKey.tooltip, value));

  @override
  Opt<Object?>? cellOf(OptionKey key) => switch (key) {
    OptionKey.colors => _colors,
    OptionKey.decimation => _decimation,
    OptionKey.filler => _filler,
    OptionKey.legend => _legend,
    OptionKey.subtitle => _subtitle,
    OptionKey.title => _title,
    OptionKey.tooltip => _tooltip,
    _ => null,
  };

  @override
  void setCell(OptionKey key, Opt<Object?>? cell) {
    switch (key) {
      case OptionKey.colors:
        _colors = fitCell(cell, (raw) => classifyUnion(raw, 34));
      case OptionKey.decimation:
        _decimation = fitCell(cell, (raw) => classifyUnion(raw, 34));
      case OptionKey.filler:
        _filler = fitCell(cell, (raw) => classifyUnion(raw, 34));
      case OptionKey.legend:
        _legend = fitCell(cell, (raw) => classifyUnion(raw, 34));
      case OptionKey.subtitle:
        _subtitle = fitCell(cell, (raw) => classifyUnion(raw, 34));
      case OptionKey.title:
        _title = fitCell(cell, (raw) => classifyUnion(raw, 34));
      case OptionKey.tooltip:
        _tooltip = fitCell(cell, (raw) => classifyUnion(raw, 34));
      default:
        throw ArgumentError.value(
          key,
          'key',
          'Not a key of PluginOptionsByType',
        );
    }
  }

  @override
  bool hasField(OptionKey key) => switch (key) {
    OptionKey.colors ||
    OptionKey.decimation ||
    OptionKey.filler ||
    OptionKey.legend ||
    OptionKey.subtitle ||
    OptionKey.title ||
    OptionKey.tooltip => true,
    _ => false,
  };

  @override
  Opt<Object?> classify(OptionKey key, Object? raw) => switch (key) {
    OptionKey.colors => classifyUnion(raw, 34),
    OptionKey.decimation => classifyUnion(raw, 34),
    OptionKey.filler => classifyUnion(raw, 34),
    OptionKey.legend => classifyUnion(raw, 34),
    OptionKey.subtitle => classifyUnion(raw, 34),
    OptionKey.title => classifyUnion(raw, 34),
    OptionKey.tooltip => classifyUnion(raw, 34),
    _ => kind.classifyOther(raw),
  };
}

/// index.d.ts:2201 ElementOptionsByType, the scope `elements` (by element type
/// id).
base class ElementOptionsByTypeScope extends OptionScope {
  /// An empty scope.
  ElementOptionsByTypeScope();

  @override
  ScopeKind get kind => ScopeKind.elementOptionsByType;

  Opt<ArcOptionsScope>? _arc;

  /// The cell of `arc`, or Dart `null` when absent.
  Opt<ArcOptionsScope>? get arcCell => _arc;

  /// Stores the cell of `arc`. Dart `null` deletes the key.
  set arcCell(Opt<ArcOptionsScope>? cell) {
    if (cell == null) {
      delete(OptionKey.arc);
    } else {
      store(OptionKey.arc, cell);
    }
  }

  /// Stores the plain value [value] of `arc`.
  set arc(ArcOptionsScope value) =>
      store(OptionKey.arc, OptScope<ArcOptionsScope>(value));

  Opt<BarOptionsScope>? _bar;

  /// The cell of `bar`, or Dart `null` when absent.
  Opt<BarOptionsScope>? get barCell => _bar;

  /// Stores the cell of `bar`. Dart `null` deletes the key.
  set barCell(Opt<BarOptionsScope>? cell) {
    if (cell == null) {
      delete(OptionKey.bar);
    } else {
      store(OptionKey.bar, cell);
    }
  }

  /// Stores the plain value [value] of `bar`.
  set bar(BarOptionsScope value) =>
      store(OptionKey.bar, OptScope<BarOptionsScope>(value));

  Opt<LineOptionsScope>? _line;

  /// The cell of `line`, or Dart `null` when absent.
  Opt<LineOptionsScope>? get lineCell => _line;

  /// Stores the cell of `line`. Dart `null` deletes the key.
  set lineCell(Opt<LineOptionsScope>? cell) {
    if (cell == null) {
      delete(OptionKey.line);
    } else {
      store(OptionKey.line, cell);
    }
  }

  /// Stores the plain value [value] of `line`.
  set line(LineOptionsScope value) =>
      store(OptionKey.line, OptScope<LineOptionsScope>(value));

  Opt<PointOptionsScope>? _point;

  /// The cell of `point`, or Dart `null` when absent.
  Opt<PointOptionsScope>? get pointCell => _point;

  /// Stores the cell of `point`. Dart `null` deletes the key.
  set pointCell(Opt<PointOptionsScope>? cell) {
    if (cell == null) {
      delete(OptionKey.point);
    } else {
      store(OptionKey.point, cell);
    }
  }

  /// Stores the plain value [value] of `point`.
  set point(PointOptionsScope value) =>
      store(OptionKey.point, OptScope<PointOptionsScope>(value));

  @override
  Opt<Object?>? cellOf(OptionKey key) => switch (key) {
    OptionKey.arc => _arc,
    OptionKey.bar => _bar,
    OptionKey.line => _line,
    OptionKey.point => _point,
    _ => null,
  };

  @override
  void setCell(OptionKey key, Opt<Object?>? cell) {
    switch (key) {
      case OptionKey.arc:
        _arc = fitCell(cell, classifyScope<ArcOptionsScope>);
      case OptionKey.bar:
        _bar = fitCell(cell, classifyScope<BarOptionsScope>);
      case OptionKey.line:
        _line = fitCell(cell, classifyScope<LineOptionsScope>);
      case OptionKey.point:
        _point = fitCell(cell, classifyScope<PointOptionsScope>);
      default:
        throw ArgumentError.value(
          key,
          'key',
          'Not a key of ElementOptionsByType',
        );
    }
  }

  @override
  bool hasField(OptionKey key) => switch (key) {
    OptionKey.arc || OptionKey.bar || OptionKey.line || OptionKey.point => true,
    _ => false,
  };

  @override
  Opt<Object?> classify(OptionKey key, Object? raw) => switch (key) {
    OptionKey.arc => classifyScope<ArcOptionsScope>(raw),
    OptionKey.bar => classifyScope<BarOptionsScope>(raw),
    OptionKey.line => classifyScope<LineOptionsScope>(raw),
    OptionKey.point => classifyScope<PointOptionsScope>(raw),
    _ => kind.classifyOther(raw),
  };
}

/// Port-only kind for index.d.ts:1631 CoreChartOptions `datasets` and
/// index.d.ts:3831 DatasetChartOptions, the scope `datasets` (by chart type,
/// index.d.ts:3755 ChartTypeRegistry order).
base class DatasetOptionsByTypeScope extends OptionScope {
  /// An empty scope.
  DatasetOptionsByTypeScope();

  @override
  ScopeKind get kind => ScopeKind.datasetOptionsByType;

  Opt<BarControllerDatasetOptionsScope>? _bar;

  /// The cell of `bar`, or Dart `null` when absent.
  Opt<BarControllerDatasetOptionsScope>? get barCell => _bar;

  /// Stores the cell of `bar`. Dart `null` deletes the key.
  set barCell(Opt<BarControllerDatasetOptionsScope>? cell) {
    if (cell == null) {
      delete(OptionKey.bar);
    } else {
      store(OptionKey.bar, cell);
    }
  }

  /// Stores the plain value [value] of `bar`.
  set bar(BarControllerDatasetOptionsScope value) =>
      store(OptionKey.bar, OptScope<BarControllerDatasetOptionsScope>(value));

  Opt<LineControllerDatasetOptionsScope>? _line;

  /// The cell of `line`, or Dart `null` when absent.
  Opt<LineControllerDatasetOptionsScope>? get lineCell => _line;

  /// Stores the cell of `line`. Dart `null` deletes the key.
  set lineCell(Opt<LineControllerDatasetOptionsScope>? cell) {
    if (cell == null) {
      delete(OptionKey.line);
    } else {
      store(OptionKey.line, cell);
    }
  }

  /// Stores the plain value [value] of `line`.
  set line(LineControllerDatasetOptionsScope value) =>
      store(OptionKey.line, OptScope<LineControllerDatasetOptionsScope>(value));

  Opt<LineControllerDatasetOptionsScope>? _scatter;

  /// The cell of `scatter`, or Dart `null` when absent.
  Opt<LineControllerDatasetOptionsScope>? get scatterCell => _scatter;

  /// Stores the cell of `scatter`. Dart `null` deletes the key.
  set scatterCell(Opt<LineControllerDatasetOptionsScope>? cell) {
    if (cell == null) {
      delete(OptionKey.scatter);
    } else {
      store(OptionKey.scatter, cell);
    }
  }

  /// Stores the plain value [value] of `scatter`.
  set scatter(LineControllerDatasetOptionsScope value) => store(
    OptionKey.scatter,
    OptScope<LineControllerDatasetOptionsScope>(value),
  );

  Opt<BubbleControllerDatasetOptionsScope>? _bubble;

  /// The cell of `bubble`, or Dart `null` when absent.
  Opt<BubbleControllerDatasetOptionsScope>? get bubbleCell => _bubble;

  /// Stores the cell of `bubble`. Dart `null` deletes the key.
  set bubbleCell(Opt<BubbleControllerDatasetOptionsScope>? cell) {
    if (cell == null) {
      delete(OptionKey.bubble);
    } else {
      store(OptionKey.bubble, cell);
    }
  }

  /// Stores the plain value [value] of `bubble`.
  set bubble(BubbleControllerDatasetOptionsScope value) => store(
    OptionKey.bubble,
    OptScope<BubbleControllerDatasetOptionsScope>(value),
  );

  Opt<DoughnutControllerDatasetOptionsScope>? _pie;

  /// The cell of `pie`, or Dart `null` when absent.
  Opt<DoughnutControllerDatasetOptionsScope>? get pieCell => _pie;

  /// Stores the cell of `pie`. Dart `null` deletes the key.
  set pieCell(Opt<DoughnutControllerDatasetOptionsScope>? cell) {
    if (cell == null) {
      delete(OptionKey.pie);
    } else {
      store(OptionKey.pie, cell);
    }
  }

  /// Stores the plain value [value] of `pie`.
  set pie(DoughnutControllerDatasetOptionsScope value) => store(
    OptionKey.pie,
    OptScope<DoughnutControllerDatasetOptionsScope>(value),
  );

  Opt<DoughnutControllerDatasetOptionsScope>? _doughnut;

  /// The cell of `doughnut`, or Dart `null` when absent.
  Opt<DoughnutControllerDatasetOptionsScope>? get doughnutCell => _doughnut;

  /// Stores the cell of `doughnut`. Dart `null` deletes the key.
  set doughnutCell(Opt<DoughnutControllerDatasetOptionsScope>? cell) {
    if (cell == null) {
      delete(OptionKey.doughnut);
    } else {
      store(OptionKey.doughnut, cell);
    }
  }

  /// Stores the plain value [value] of `doughnut`.
  set doughnut(DoughnutControllerDatasetOptionsScope value) => store(
    OptionKey.doughnut,
    OptScope<DoughnutControllerDatasetOptionsScope>(value),
  );

  Opt<PolarAreaControllerDatasetOptionsScope>? _polarArea;

  /// The cell of `polarArea`, or Dart `null` when absent.
  Opt<PolarAreaControllerDatasetOptionsScope>? get polarAreaCell => _polarArea;

  /// Stores the cell of `polarArea`. Dart `null` deletes the key.
  set polarAreaCell(Opt<PolarAreaControllerDatasetOptionsScope>? cell) {
    if (cell == null) {
      delete(OptionKey.polarArea);
    } else {
      store(OptionKey.polarArea, cell);
    }
  }

  /// Stores the plain value [value] of `polarArea`.
  set polarArea(PolarAreaControllerDatasetOptionsScope value) => store(
    OptionKey.polarArea,
    OptScope<PolarAreaControllerDatasetOptionsScope>(value),
  );

  Opt<RadarControllerDatasetOptionsScope>? _radar;

  /// The cell of `radar`, or Dart `null` when absent.
  Opt<RadarControllerDatasetOptionsScope>? get radarCell => _radar;

  /// Stores the cell of `radar`. Dart `null` deletes the key.
  set radarCell(Opt<RadarControllerDatasetOptionsScope>? cell) {
    if (cell == null) {
      delete(OptionKey.radar);
    } else {
      store(OptionKey.radar, cell);
    }
  }

  /// Stores the plain value [value] of `radar`.
  set radar(RadarControllerDatasetOptionsScope value) => store(
    OptionKey.radar,
    OptScope<RadarControllerDatasetOptionsScope>(value),
  );

  @override
  Opt<Object?>? cellOf(OptionKey key) => switch (key) {
    OptionKey.bar => _bar,
    OptionKey.line => _line,
    OptionKey.scatter => _scatter,
    OptionKey.bubble => _bubble,
    OptionKey.pie => _pie,
    OptionKey.doughnut => _doughnut,
    OptionKey.polarArea => _polarArea,
    OptionKey.radar => _radar,
    _ => null,
  };

  @override
  void setCell(OptionKey key, Opt<Object?>? cell) {
    switch (key) {
      case OptionKey.bar:
        _bar = fitCell(cell, classifyScope<BarControllerDatasetOptionsScope>);
      case OptionKey.line:
        _line = fitCell(cell, classifyScope<LineControllerDatasetOptionsScope>);
      case OptionKey.scatter:
        _scatter = fitCell(
          cell,
          classifyScope<LineControllerDatasetOptionsScope>,
        );
      case OptionKey.bubble:
        _bubble = fitCell(
          cell,
          classifyScope<BubbleControllerDatasetOptionsScope>,
        );
      case OptionKey.pie:
        _pie = fitCell(
          cell,
          classifyScope<DoughnutControllerDatasetOptionsScope>,
        );
      case OptionKey.doughnut:
        _doughnut = fitCell(
          cell,
          classifyScope<DoughnutControllerDatasetOptionsScope>,
        );
      case OptionKey.polarArea:
        _polarArea = fitCell(
          cell,
          classifyScope<PolarAreaControllerDatasetOptionsScope>,
        );
      case OptionKey.radar:
        _radar = fitCell(
          cell,
          classifyScope<RadarControllerDatasetOptionsScope>,
        );
      default:
        throw ArgumentError.value(
          key,
          'key',
          'Not a key of DatasetOptionsByType',
        );
    }
  }

  @override
  bool hasField(OptionKey key) => switch (key) {
    OptionKey.bar ||
    OptionKey.line ||
    OptionKey.scatter ||
    OptionKey.bubble ||
    OptionKey.pie ||
    OptionKey.doughnut ||
    OptionKey.polarArea ||
    OptionKey.radar => true,
    _ => false,
  };

  @override
  Opt<Object?> classify(OptionKey key, Object? raw) => switch (key) {
    OptionKey.bar => classifyScope<BarControllerDatasetOptionsScope>(raw),
    OptionKey.line => classifyScope<LineControllerDatasetOptionsScope>(raw),
    OptionKey.scatter => classifyScope<LineControllerDatasetOptionsScope>(raw),
    OptionKey.bubble => classifyScope<BubbleControllerDatasetOptionsScope>(raw),
    OptionKey.pie => classifyScope<DoughnutControllerDatasetOptionsScope>(raw),
    OptionKey.doughnut => classifyScope<DoughnutControllerDatasetOptionsScope>(
      raw,
    ),
    OptionKey.polarArea =>
      classifyScope<PolarAreaControllerDatasetOptionsScope>(raw),
    OptionKey.radar => classifyScope<RadarControllerDatasetOptionsScope>(raw),
    _ => kind.classifyOther(raw),
  };
}

/// Port-only kind for index.d.ts:740 Overrides, Chart.overrides
/// (core.defaults.js:7, by chart type).
base class OverridesByTypeScope extends OptionScope {
  /// An empty scope.
  OverridesByTypeScope();

  @override
  ScopeKind get kind => ScopeKind.overridesByType;

  Opt<ChartOptionsScope>? _bar;

  /// The cell of `bar`, or Dart `null` when absent.
  Opt<ChartOptionsScope>? get barCell => _bar;

  /// Stores the cell of `bar`. Dart `null` deletes the key.
  set barCell(Opt<ChartOptionsScope>? cell) {
    if (cell == null) {
      delete(OptionKey.bar);
    } else {
      store(OptionKey.bar, cell);
    }
  }

  /// Stores the plain value [value] of `bar`.
  set bar(ChartOptionsScope value) =>
      store(OptionKey.bar, OptScope<ChartOptionsScope>(value));

  Opt<ChartOptionsScope>? _line;

  /// The cell of `line`, or Dart `null` when absent.
  Opt<ChartOptionsScope>? get lineCell => _line;

  /// Stores the cell of `line`. Dart `null` deletes the key.
  set lineCell(Opt<ChartOptionsScope>? cell) {
    if (cell == null) {
      delete(OptionKey.line);
    } else {
      store(OptionKey.line, cell);
    }
  }

  /// Stores the plain value [value] of `line`.
  set line(ChartOptionsScope value) =>
      store(OptionKey.line, OptScope<ChartOptionsScope>(value));

  Opt<ChartOptionsScope>? _scatter;

  /// The cell of `scatter`, or Dart `null` when absent.
  Opt<ChartOptionsScope>? get scatterCell => _scatter;

  /// Stores the cell of `scatter`. Dart `null` deletes the key.
  set scatterCell(Opt<ChartOptionsScope>? cell) {
    if (cell == null) {
      delete(OptionKey.scatter);
    } else {
      store(OptionKey.scatter, cell);
    }
  }

  /// Stores the plain value [value] of `scatter`.
  set scatter(ChartOptionsScope value) =>
      store(OptionKey.scatter, OptScope<ChartOptionsScope>(value));

  Opt<ChartOptionsScope>? _bubble;

  /// The cell of `bubble`, or Dart `null` when absent.
  Opt<ChartOptionsScope>? get bubbleCell => _bubble;

  /// Stores the cell of `bubble`. Dart `null` deletes the key.
  set bubbleCell(Opt<ChartOptionsScope>? cell) {
    if (cell == null) {
      delete(OptionKey.bubble);
    } else {
      store(OptionKey.bubble, cell);
    }
  }

  /// Stores the plain value [value] of `bubble`.
  set bubble(ChartOptionsScope value) =>
      store(OptionKey.bubble, OptScope<ChartOptionsScope>(value));

  Opt<ChartOptionsScope>? _pie;

  /// The cell of `pie`, or Dart `null` when absent.
  Opt<ChartOptionsScope>? get pieCell => _pie;

  /// Stores the cell of `pie`. Dart `null` deletes the key.
  set pieCell(Opt<ChartOptionsScope>? cell) {
    if (cell == null) {
      delete(OptionKey.pie);
    } else {
      store(OptionKey.pie, cell);
    }
  }

  /// Stores the plain value [value] of `pie`.
  set pie(ChartOptionsScope value) =>
      store(OptionKey.pie, OptScope<ChartOptionsScope>(value));

  Opt<ChartOptionsScope>? _doughnut;

  /// The cell of `doughnut`, or Dart `null` when absent.
  Opt<ChartOptionsScope>? get doughnutCell => _doughnut;

  /// Stores the cell of `doughnut`. Dart `null` deletes the key.
  set doughnutCell(Opt<ChartOptionsScope>? cell) {
    if (cell == null) {
      delete(OptionKey.doughnut);
    } else {
      store(OptionKey.doughnut, cell);
    }
  }

  /// Stores the plain value [value] of `doughnut`.
  set doughnut(ChartOptionsScope value) =>
      store(OptionKey.doughnut, OptScope<ChartOptionsScope>(value));

  Opt<ChartOptionsScope>? _polarArea;

  /// The cell of `polarArea`, or Dart `null` when absent.
  Opt<ChartOptionsScope>? get polarAreaCell => _polarArea;

  /// Stores the cell of `polarArea`. Dart `null` deletes the key.
  set polarAreaCell(Opt<ChartOptionsScope>? cell) {
    if (cell == null) {
      delete(OptionKey.polarArea);
    } else {
      store(OptionKey.polarArea, cell);
    }
  }

  /// Stores the plain value [value] of `polarArea`.
  set polarArea(ChartOptionsScope value) =>
      store(OptionKey.polarArea, OptScope<ChartOptionsScope>(value));

  Opt<ChartOptionsScope>? _radar;

  /// The cell of `radar`, or Dart `null` when absent.
  Opt<ChartOptionsScope>? get radarCell => _radar;

  /// Stores the cell of `radar`. Dart `null` deletes the key.
  set radarCell(Opt<ChartOptionsScope>? cell) {
    if (cell == null) {
      delete(OptionKey.radar);
    } else {
      store(OptionKey.radar, cell);
    }
  }

  /// Stores the plain value [value] of `radar`.
  set radar(ChartOptionsScope value) =>
      store(OptionKey.radar, OptScope<ChartOptionsScope>(value));

  @override
  Opt<Object?>? cellOf(OptionKey key) => switch (key) {
    OptionKey.bar => _bar,
    OptionKey.line => _line,
    OptionKey.scatter => _scatter,
    OptionKey.bubble => _bubble,
    OptionKey.pie => _pie,
    OptionKey.doughnut => _doughnut,
    OptionKey.polarArea => _polarArea,
    OptionKey.radar => _radar,
    _ => null,
  };

  @override
  void setCell(OptionKey key, Opt<Object?>? cell) {
    switch (key) {
      case OptionKey.bar:
        _bar = fitCell(cell, classifyScope<ChartOptionsScope>);
      case OptionKey.line:
        _line = fitCell(cell, classifyScope<ChartOptionsScope>);
      case OptionKey.scatter:
        _scatter = fitCell(cell, classifyScope<ChartOptionsScope>);
      case OptionKey.bubble:
        _bubble = fitCell(cell, classifyScope<ChartOptionsScope>);
      case OptionKey.pie:
        _pie = fitCell(cell, classifyScope<ChartOptionsScope>);
      case OptionKey.doughnut:
        _doughnut = fitCell(cell, classifyScope<ChartOptionsScope>);
      case OptionKey.polarArea:
        _polarArea = fitCell(cell, classifyScope<ChartOptionsScope>);
      case OptionKey.radar:
        _radar = fitCell(cell, classifyScope<ChartOptionsScope>);
      default:
        throw ArgumentError.value(key, 'key', 'Not a key of OverridesByType');
    }
  }

  @override
  bool hasField(OptionKey key) => switch (key) {
    OptionKey.bar ||
    OptionKey.line ||
    OptionKey.scatter ||
    OptionKey.bubble ||
    OptionKey.pie ||
    OptionKey.doughnut ||
    OptionKey.polarArea ||
    OptionKey.radar => true,
    _ => false,
  };

  @override
  Opt<Object?> classify(OptionKey key, Object? raw) => switch (key) {
    OptionKey.bar => classifyScope<ChartOptionsScope>(raw),
    OptionKey.line => classifyScope<ChartOptionsScope>(raw),
    OptionKey.scatter => classifyScope<ChartOptionsScope>(raw),
    OptionKey.bubble => classifyScope<ChartOptionsScope>(raw),
    OptionKey.pie => classifyScope<ChartOptionsScope>(raw),
    OptionKey.doughnut => classifyScope<ChartOptionsScope>(raw),
    OptionKey.polarArea => classifyScope<ChartOptionsScope>(raw),
    OptionKey.radar => classifyScope<ChartOptionsScope>(raw),
    _ => kind.classifyOther(raw),
  };
}

/// Port-only kind for index.d.ts:3837 ScaleChartOptions `scales`, the scope
/// `scales` (by scale id in the options and the overrides, by scale type in
/// Chart.defaults.scales).
base class ScaleOptionsByIdScope extends OptionScope {
  /// An empty scope.
  ScaleOptionsByIdScope();

  @override
  ScopeKind get kind => ScopeKind.scaleOptionsById;

  @override
  Opt<Object?>? cellOf(OptionKey key) => null;

  @override
  void setCell(OptionKey key, Opt<Object?>? cell) {
    throw ArgumentError.value(key, 'key', 'Not a key of ScaleOptionsById');
  }

  @override
  bool hasField(OptionKey key) => false;

  @override
  Opt<Object?> classify(OptionKey key, Object? raw) => kind.classifyOther(raw);
}

/// index.d.ts:1766 AnimationsSpec, the scope `animations` (by animation name).
/// An entry can be `false`.
base class AnimationsSpecScope extends OptionScope {
  /// An empty scope.
  AnimationsSpecScope();

  @override
  ScopeKind get kind => ScopeKind.animationsSpec;

  Opt<Object>? _colors;

  /// The cell of `colors`, or Dart `null` when absent.
  Opt<Object>? get colorsCell => _colors;

  /// Stores the cell of `colors`. Dart `null` deletes the key.
  set colorsCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.colors);
    } else {
      store(OptionKey.colors, cell);
    }
  }

  /// Stores the plain value [value] of `colors`.
  set colors(Object value) =>
      store(OptionKey.colors, classify(OptionKey.colors, value));

  Opt<Object>? _numbers;

  /// The cell of `numbers`, or Dart `null` when absent.
  Opt<Object>? get numbersCell => _numbers;

  /// Stores the cell of `numbers`. Dart `null` deletes the key.
  set numbersCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.numbers);
    } else {
      store(OptionKey.numbers, cell);
    }
  }

  /// Stores the plain value [value] of `numbers`.
  set numbers(Object value) =>
      store(OptionKey.numbers, classify(OptionKey.numbers, value));

  Opt<Object>? _visible;

  /// The cell of `visible`, or Dart `null` when absent.
  Opt<Object>? get visibleCell => _visible;

  /// Stores the cell of `visible`. Dart `null` deletes the key.
  set visibleCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.visible);
    } else {
      store(OptionKey.visible, cell);
    }
  }

  /// Stores the plain value [value] of `visible`.
  set visible(Object value) =>
      store(OptionKey.visible, classify(OptionKey.visible, value));

  Opt<Object>? _opacity;

  /// The cell of `opacity`, or Dart `null` when absent.
  Opt<Object>? get opacityCell => _opacity;

  /// Stores the cell of `opacity`. Dart `null` deletes the key.
  set opacityCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.opacity);
    } else {
      store(OptionKey.opacity, cell);
    }
  }

  /// Stores the plain value [value] of `opacity`.
  set opacity(Object value) =>
      store(OptionKey.opacity, classify(OptionKey.opacity, value));

  @override
  Opt<Object?>? cellOf(OptionKey key) => switch (key) {
    OptionKey.colors => _colors,
    OptionKey.numbers => _numbers,
    OptionKey.visible => _visible,
    OptionKey.opacity => _opacity,
    _ => null,
  };

  @override
  void setCell(OptionKey key, Opt<Object?>? cell) {
    switch (key) {
      case OptionKey.colors:
        _colors = fitCell(cell, (raw) => classifyUnion(raw, 34));
      case OptionKey.numbers:
        _numbers = fitCell(cell, (raw) => classifyUnion(raw, 34));
      case OptionKey.visible:
        _visible = fitCell(cell, (raw) => classifyUnion(raw, 34));
      case OptionKey.opacity:
        _opacity = fitCell(cell, (raw) => classifyUnion(raw, 34));
      default:
        throw ArgumentError.value(key, 'key', 'Not a key of AnimationsSpec');
    }
  }

  @override
  bool hasField(OptionKey key) => switch (key) {
    OptionKey.colors ||
    OptionKey.numbers ||
    OptionKey.visible ||
    OptionKey.opacity => true,
    _ => false,
  };

  @override
  Opt<Object?> classify(OptionKey key, Object? raw) => switch (key) {
    OptionKey.colors => classifyUnion(raw, 34),
    OptionKey.numbers => classifyUnion(raw, 34),
    OptionKey.visible => classifyUnion(raw, 34),
    OptionKey.opacity => classifyUnion(raw, 34),
    _ => kind.classifyOther(raw),
  };
}

/// index.d.ts:1793 TransitionsSpec, the scope `transitions` (by update mode).
base class TransitionsSpecScope extends OptionScope {
  /// An empty scope.
  TransitionsSpecScope();

  @override
  ScopeKind get kind => ScopeKind.transitionsSpec;

  Opt<TransitionOptionsScope>? _active;

  /// The cell of `active`, or Dart `null` when absent.
  Opt<TransitionOptionsScope>? get activeCell => _active;

  /// Stores the cell of `active`. Dart `null` deletes the key.
  set activeCell(Opt<TransitionOptionsScope>? cell) {
    if (cell == null) {
      delete(OptionKey.active);
    } else {
      store(OptionKey.active, cell);
    }
  }

  /// Stores the plain value [value] of `active`.
  set active(TransitionOptionsScope value) =>
      store(OptionKey.active, OptScope<TransitionOptionsScope>(value));

  Opt<TransitionOptionsScope>? _resize;

  /// The cell of `resize`, or Dart `null` when absent.
  Opt<TransitionOptionsScope>? get resizeCell => _resize;

  /// Stores the cell of `resize`. Dart `null` deletes the key.
  set resizeCell(Opt<TransitionOptionsScope>? cell) {
    if (cell == null) {
      delete(OptionKey.resize);
    } else {
      store(OptionKey.resize, cell);
    }
  }

  /// Stores the plain value [value] of `resize`.
  set resize(TransitionOptionsScope value) =>
      store(OptionKey.resize, OptScope<TransitionOptionsScope>(value));

  Opt<TransitionOptionsScope>? _show;

  /// The cell of `show`, or Dart `null` when absent.
  Opt<TransitionOptionsScope>? get showCell => _show;

  /// Stores the cell of `show`. Dart `null` deletes the key.
  set showCell(Opt<TransitionOptionsScope>? cell) {
    if (cell == null) {
      delete(OptionKey.show);
    } else {
      store(OptionKey.show, cell);
    }
  }

  /// Stores the plain value [value] of `show`.
  set show(TransitionOptionsScope value) =>
      store(OptionKey.show, OptScope<TransitionOptionsScope>(value));

  Opt<TransitionOptionsScope>? _hide;

  /// The cell of `hide`, or Dart `null` when absent.
  Opt<TransitionOptionsScope>? get hideCell => _hide;

  /// Stores the cell of `hide`. Dart `null` deletes the key.
  set hideCell(Opt<TransitionOptionsScope>? cell) {
    if (cell == null) {
      delete(OptionKey.hide);
    } else {
      store(OptionKey.hide, cell);
    }
  }

  /// Stores the plain value [value] of `hide`.
  set hide(TransitionOptionsScope value) =>
      store(OptionKey.hide, OptScope<TransitionOptionsScope>(value));

  Opt<TransitionOptionsScope>? _reset;

  /// The cell of `reset`, or Dart `null` when absent.
  Opt<TransitionOptionsScope>? get resetCell => _reset;

  /// Stores the cell of `reset`. Dart `null` deletes the key.
  set resetCell(Opt<TransitionOptionsScope>? cell) {
    if (cell == null) {
      delete(OptionKey.reset);
    } else {
      store(OptionKey.reset, cell);
    }
  }

  /// Stores the plain value [value] of `reset`.
  set reset(TransitionOptionsScope value) =>
      store(OptionKey.reset, OptScope<TransitionOptionsScope>(value));

  @override
  Opt<Object?>? cellOf(OptionKey key) => switch (key) {
    OptionKey.active => _active,
    OptionKey.resize => _resize,
    OptionKey.show => _show,
    OptionKey.hide => _hide,
    OptionKey.reset => _reset,
    _ => null,
  };

  @override
  void setCell(OptionKey key, Opt<Object?>? cell) {
    switch (key) {
      case OptionKey.active:
        _active = fitCell(cell, classifyScope<TransitionOptionsScope>);
      case OptionKey.resize:
        _resize = fitCell(cell, classifyScope<TransitionOptionsScope>);
      case OptionKey.show:
        _show = fitCell(cell, classifyScope<TransitionOptionsScope>);
      case OptionKey.hide:
        _hide = fitCell(cell, classifyScope<TransitionOptionsScope>);
      case OptionKey.reset:
        _reset = fitCell(cell, classifyScope<TransitionOptionsScope>);
      default:
        throw ArgumentError.value(key, 'key', 'Not a key of TransitionsSpec');
    }
  }

  @override
  bool hasField(OptionKey key) => switch (key) {
    OptionKey.active ||
    OptionKey.resize ||
    OptionKey.show ||
    OptionKey.hide ||
    OptionKey.reset => true,
    _ => false,
  };

  @override
  Opt<Object?> classify(OptionKey key, Object? raw) => switch (key) {
    OptionKey.active => classifyScope<TransitionOptionsScope>(raw),
    OptionKey.resize => classifyScope<TransitionOptionsScope>(raw),
    OptionKey.show => classifyScope<TransitionOptionsScope>(raw),
    OptionKey.hide => classifyScope<TransitionOptionsScope>(raw),
    OptionKey.reset => classifyScope<TransitionOptionsScope>(raw),
    _ => kind.classifyOther(raw),
  };
}

/// Port-only name for index.d.ts:1788 TransitionSpec, the options of one
/// transition mode.
base class TransitionOptionsScope extends OptionScope {
  /// An empty scope.
  TransitionOptionsScope();

  @override
  ScopeKind get kind => ScopeKind.transitionOptions;

  Opt<Object>? _animation;

  /// The cell of `animation`, or Dart `null` when absent.
  Opt<Object>? get animationCell => _animation;

  /// Stores the cell of `animation`. Dart `null` deletes the key.
  set animationCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.animation);
    } else {
      store(OptionKey.animation, cell);
    }
  }

  /// Stores the plain value [value] of `animation`.
  set animation(Object value) =>
      store(OptionKey.animation, classify(OptionKey.animation, value));

  Opt<Object>? _animations;

  /// The cell of `animations`, or Dart `null` when absent.
  Opt<Object>? get animationsCell => _animations;

  /// Stores the cell of `animations`. Dart `null` deletes the key.
  set animationsCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.animations);
    } else {
      store(OptionKey.animations, cell);
    }
  }

  /// Stores the plain value [value] of `animations`.
  set animations(Object value) =>
      store(OptionKey.animations, classify(OptionKey.animations, value));

  @override
  Opt<Object?>? cellOf(OptionKey key) => switch (key) {
    OptionKey.animation => _animation,
    OptionKey.animations => _animations,
    _ => null,
  };

  @override
  void setCell(OptionKey key, Opt<Object?>? cell) {
    switch (key) {
      case OptionKey.animation:
        _animation = fitCell(cell, (raw) => classifyUnion(raw, 34));
      case OptionKey.animations:
        _animations = fitCell(cell, (raw) => classifyUnion(raw, 34));
      default:
        throw ArgumentError.value(key, 'key', 'Not a key of TransitionOptions');
    }
  }

  @override
  bool hasField(OptionKey key) => switch (key) {
    OptionKey.animation || OptionKey.animations => true,
    _ => false,
  };

  @override
  Opt<Object?> classify(OptionKey key, Object? raw) => switch (key) {
    OptionKey.animation => classifyUnion(raw, 34),
    OptionKey.animations => classifyUnion(raw, 34),
    _ => kind.classifyOther(raw),
  };
}

/// Port-only name over index.d.ts:1741 AnimationSpec, the entry keys of
/// index.d.ts:1766 AnimationsSpec, the callbacks of index.d.ts:1797
/// AnimationOptions `animation` and index.d.ts:293 DoughnutAnimationOptions,
/// the scope `animation` and each entry of `animations`.
base class AnimationOptionsScope extends OptionScope {
  /// An empty scope.
  AnimationOptionsScope();

  @override
  ScopeKind get kind => ScopeKind.animationOptions;

  Opt<double>? _duration;

  /// The cell of `duration`, or Dart `null` when absent.
  Opt<double>? get durationCell => _duration;

  /// Stores the cell of `duration`. Dart `null` deletes the key.
  set durationCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.duration);
    } else {
      store(OptionKey.duration, cell);
    }
  }

  /// Stores the plain value [value] of `duration`.
  set duration(double value) =>
      store(OptionKey.duration, OptValue<double>(value));

  Opt<String>? _easing;

  /// The cell of `easing`, or Dart `null` when absent.
  Opt<String>? get easingCell => _easing;

  /// Stores the cell of `easing`. Dart `null` deletes the key.
  set easingCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.easing);
    } else {
      store(OptionKey.easing, cell);
    }
  }

  /// Stores the plain value [value] of `easing`.
  set easing(String value) => store(OptionKey.easing, OptValue<String>(value));

  Opt<double>? _delay;

  /// The cell of `delay`, or Dart `null` when absent.
  Opt<double>? get delayCell => _delay;

  /// Stores the cell of `delay`. Dart `null` deletes the key.
  set delayCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.delay);
    } else {
      store(OptionKey.delay, cell);
    }
  }

  /// Stores the plain value [value] of `delay`.
  set delay(double value) => store(OptionKey.delay, OptValue<double>(value));

  Opt<bool>? _loop;

  /// The cell of `loop`, or Dart `null` when absent.
  Opt<bool>? get loopCell => _loop;

  /// Stores the cell of `loop`. Dart `null` deletes the key.
  set loopCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.loop);
    } else {
      store(OptionKey.loop, cell);
    }
  }

  /// Stores the plain value [value] of `loop`.
  set loop(bool value) => store(OptionKey.loop, OptValue<bool>(value));

  Opt<Object>? _properties;

  /// The cell of `properties`, or Dart `null` when absent.
  Opt<Object>? get propertiesCell => _properties;

  /// Stores the cell of `properties`. Dart `null` deletes the key.
  set propertiesCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.properties);
    } else {
      store(OptionKey.properties, cell);
    }
  }

  /// Stores the plain value [value] of `properties`.
  set properties(Object value) =>
      store(OptionKey.properties, classify(OptionKey.properties, value));

  Opt<String>? _type;

  /// The cell of `type`, or Dart `null` when absent.
  Opt<String>? get typeCell => _type;

  /// Stores the cell of `type`. Dart `null` deletes the key.
  set typeCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.type);
    } else {
      store(OptionKey.type, cell);
    }
  }

  /// Stores the plain value [value] of `type`.
  set type(String value) => store(OptionKey.type, OptValue<String>(value));

  Opt<Object>? _fn;

  /// The cell of `fn`, or Dart `null` when absent.
  Opt<Object>? get fnCell => _fn;

  /// Stores the cell of `fn`. Dart `null` deletes the key.
  set fnCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.fn);
    } else {
      store(OptionKey.fn, cell);
    }
  }

  /// Stores the plain value [value] of `fn`.
  set fn(Object value) => store(OptionKey.fn, classify(OptionKey.fn, value));

  Opt<Object>? _from;

  /// The cell of `from`, or Dart `null` when absent.
  Opt<Object>? get fromCell => _from;

  /// Stores the cell of `from`. Dart `null` deletes the key.
  set fromCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.from);
    } else {
      store(OptionKey.from, cell);
    }
  }

  /// Stores the plain value [value] of `from`.
  set from(Object value) =>
      store(OptionKey.from, classify(OptionKey.from, value));

  Opt<Object>? _to;

  /// The cell of `to`, or Dart `null` when absent.
  Opt<Object>? get toCell => _to;

  /// Stores the cell of `to`. Dart `null` deletes the key.
  set toCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.to);
    } else {
      store(OptionKey.to, cell);
    }
  }

  /// Stores the plain value [value] of `to`.
  set to(Object value) => store(OptionKey.to, classify(OptionKey.to, value));

  Opt<Object>? _onProgress;

  /// The cell of `onProgress`, or Dart `null` when absent.
  Opt<Object>? get onProgressCell => _onProgress;

  /// Stores the cell of `onProgress`. Dart `null` deletes the key.
  set onProgressCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.onProgress);
    } else {
      store(OptionKey.onProgress, cell);
    }
  }

  /// Stores the plain value [value] of `onProgress`.
  set onProgress(Object value) =>
      store(OptionKey.onProgress, classify(OptionKey.onProgress, value));

  Opt<Object>? _onComplete;

  /// The cell of `onComplete`, or Dart `null` when absent.
  Opt<Object>? get onCompleteCell => _onComplete;

  /// Stores the cell of `onComplete`. Dart `null` deletes the key.
  set onCompleteCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.onComplete);
    } else {
      store(OptionKey.onComplete, cell);
    }
  }

  /// Stores the plain value [value] of `onComplete`.
  set onComplete(Object value) =>
      store(OptionKey.onComplete, classify(OptionKey.onComplete, value));

  Opt<bool>? _animateRotate;

  /// The cell of `animateRotate`, or Dart `null` when absent.
  Opt<bool>? get animateRotateCell => _animateRotate;

  /// Stores the cell of `animateRotate`. Dart `null` deletes the key.
  set animateRotateCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.animateRotate);
    } else {
      store(OptionKey.animateRotate, cell);
    }
  }

  /// Stores the plain value [value] of `animateRotate`.
  set animateRotate(bool value) =>
      store(OptionKey.animateRotate, OptValue<bool>(value));

  Opt<bool>? _animateScale;

  /// The cell of `animateScale`, or Dart `null` when absent.
  Opt<bool>? get animateScaleCell => _animateScale;

  /// Stores the cell of `animateScale`. Dart `null` deletes the key.
  set animateScaleCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.animateScale);
    } else {
      store(OptionKey.animateScale, cell);
    }
  }

  /// Stores the plain value [value] of `animateScale`.
  set animateScale(bool value) =>
      store(OptionKey.animateScale, OptValue<bool>(value));

  @override
  Opt<Object?>? cellOf(OptionKey key) => switch (key) {
    OptionKey.duration => _duration,
    OptionKey.easing => _easing,
    OptionKey.delay => _delay,
    OptionKey.loop => _loop,
    OptionKey.properties => _properties,
    OptionKey.type => _type,
    OptionKey.fn => _fn,
    OptionKey.from => _from,
    OptionKey.to => _to,
    OptionKey.onProgress => _onProgress,
    OptionKey.onComplete => _onComplete,
    OptionKey.animateRotate => _animateRotate,
    OptionKey.animateScale => _animateScale,
    _ => null,
  };

  @override
  void setCell(OptionKey key, Opt<Object?>? cell) {
    switch (key) {
      case OptionKey.duration:
        _duration = fitCell(cell, classifyNumber);
      case OptionKey.easing:
        _easing = fitCell(cell, classifyString);
      case OptionKey.delay:
        _delay = fitCell(cell, classifyNumber);
      case OptionKey.loop:
        _loop = fitCell(cell, classifyBool);
      case OptionKey.properties:
        _properties = fitCell(cell, (raw) => classifyUnion(raw, 16));
      case OptionKey.type:
        _type = fitCell(cell, classifyString);
      case OptionKey.fn:
        _fn = fitCell(cell, (raw) => classifyUnion(raw, 8));
      case OptionKey.from:
        _from = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.to:
        _to = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.onProgress:
        _onProgress = fitCell(cell, (raw) => classifyUnion(raw, 8));
      case OptionKey.onComplete:
        _onComplete = fitCell(cell, (raw) => classifyUnion(raw, 8));
      case OptionKey.animateRotate:
        _animateRotate = fitCell(cell, classifyBool);
      case OptionKey.animateScale:
        _animateScale = fitCell(cell, classifyBool);
      default:
        throw ArgumentError.value(key, 'key', 'Not a key of AnimationOptions');
    }
  }

  @override
  bool hasField(OptionKey key) => switch (key) {
    OptionKey.duration ||
    OptionKey.easing ||
    OptionKey.delay ||
    OptionKey.loop ||
    OptionKey.properties ||
    OptionKey.type ||
    OptionKey.fn ||
    OptionKey.from ||
    OptionKey.to ||
    OptionKey.onProgress ||
    OptionKey.onComplete ||
    OptionKey.animateRotate ||
    OptionKey.animateScale => true,
    _ => false,
  };

  @override
  Opt<Object?> classify(OptionKey key, Object? raw) => switch (key) {
    OptionKey.duration => classifyNumber(raw),
    OptionKey.easing => classifyString(raw),
    OptionKey.delay => classifyNumber(raw),
    OptionKey.loop => classifyBool(raw),
    OptionKey.properties => classifyUnion(raw, 16),
    OptionKey.type => classifyString(raw),
    OptionKey.fn => classifyUnion(raw, 8),
    OptionKey.from => classifyUnion(raw, 64),
    OptionKey.to => classifyUnion(raw, 64),
    OptionKey.onProgress => classifyUnion(raw, 8),
    OptionKey.onComplete => classifyUnion(raw, 8),
    OptionKey.animateRotate => classifyBool(raw),
    OptionKey.animateScale => classifyBool(raw),
    _ => kind.classifyOther(raw),
  };
}

/// index.d.ts:1812 FontSpec, a font object (read by toFont,
/// helpers.options.ts).
base class FontSpecScope extends OptionScope {
  /// An empty scope.
  FontSpecScope();

  @override
  ScopeKind get kind => ScopeKind.fontSpec;

  Opt<String>? _family;

  /// The cell of `family`, or Dart `null` when absent.
  Opt<String>? get familyCell => _family;

  /// Stores the cell of `family`. Dart `null` deletes the key.
  set familyCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.family);
    } else {
      store(OptionKey.family, cell);
    }
  }

  /// Stores the plain value [value] of `family`.
  set family(String value) => store(OptionKey.family, OptValue<String>(value));

  Opt<double>? _size;

  /// The cell of `size`, or Dart `null` when absent.
  Opt<double>? get sizeCell => _size;

  /// Stores the cell of `size`. Dart `null` deletes the key.
  set sizeCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.size);
    } else {
      store(OptionKey.size, cell);
    }
  }

  /// Stores the plain value [value] of `size`.
  set size(double value) => store(OptionKey.size, OptValue<double>(value));

  Opt<String>? _style;

  /// The cell of `style`, or Dart `null` when absent.
  Opt<String>? get styleCell => _style;

  /// Stores the cell of `style`. Dart `null` deletes the key.
  set styleCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.style);
    } else {
      store(OptionKey.style, cell);
    }
  }

  /// Stores the plain value [value] of `style`.
  set style(String value) => store(OptionKey.style, OptValue<String>(value));

  Opt<Object>? _weight;

  /// The cell of `weight`, or Dart `null` when absent.
  Opt<Object>? get weightCell => _weight;

  /// Stores the cell of `weight`. Dart `null` deletes the key.
  set weightCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.weight);
    } else {
      store(OptionKey.weight, cell);
    }
  }

  /// Stores the plain value [value] of `weight`.
  set weight(Object value) =>
      store(OptionKey.weight, classify(OptionKey.weight, value));

  Opt<Object>? _lineHeight;

  /// The cell of `lineHeight`, or Dart `null` when absent.
  Opt<Object>? get lineHeightCell => _lineHeight;

  /// Stores the cell of `lineHeight`. Dart `null` deletes the key.
  set lineHeightCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.lineHeight);
    } else {
      store(OptionKey.lineHeight, cell);
    }
  }

  /// Stores the plain value [value] of `lineHeight`.
  set lineHeight(Object value) =>
      store(OptionKey.lineHeight, classify(OptionKey.lineHeight, value));

  @override
  Opt<Object?>? cellOf(OptionKey key) => switch (key) {
    OptionKey.family => _family,
    OptionKey.size => _size,
    OptionKey.style => _style,
    OptionKey.weight => _weight,
    OptionKey.lineHeight => _lineHeight,
    _ => null,
  };

  @override
  void setCell(OptionKey key, Opt<Object?>? cell) {
    switch (key) {
      case OptionKey.family:
        _family = fitCell(cell, classifyString);
      case OptionKey.size:
        _size = fitCell(cell, classifyNumber);
      case OptionKey.style:
        _style = fitCell(cell, classifyString);
      case OptionKey.weight:
        _weight = fitCell(cell, (raw) => classifyUnion(raw, 5));
      case OptionKey.lineHeight:
        _lineHeight = fitCell(cell, (raw) => classifyUnion(raw, 5));
      default:
        throw ArgumentError.value(key, 'key', 'Not a key of FontSpec');
    }
  }

  @override
  bool hasField(OptionKey key) => switch (key) {
    OptionKey.family ||
    OptionKey.size ||
    OptionKey.style ||
    OptionKey.weight ||
    OptionKey.lineHeight => true,
    _ => false,
  };

  @override
  Opt<Object?> classify(OptionKey key, Object? raw) => switch (key) {
    OptionKey.family => classifyString(raw),
    OptionKey.size => classifyNumber(raw),
    OptionKey.style => classifyString(raw),
    OptionKey.weight => classifyUnion(raw, 5),
    OptionKey.lineHeight => classifyUnion(raw, 5),
    _ => kind.classifyOther(raw),
  };
}

/// Port-only kind for geometric.d.ts Padding (TRBL and Point), the padding
/// object of toPadding and toTRBL (helpers.options.ts).
base class PaddingScope extends OptionScope {
  /// An empty scope.
  PaddingScope();

  @override
  ScopeKind get kind => ScopeKind.padding;

  Opt<double>? _top;

  /// The cell of `top`, or Dart `null` when absent.
  Opt<double>? get topCell => _top;

  /// Stores the cell of `top`. Dart `null` deletes the key.
  set topCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.top);
    } else {
      store(OptionKey.top, cell);
    }
  }

  /// Stores the plain value [value] of `top`.
  set top(double value) => store(OptionKey.top, OptValue<double>(value));

  Opt<double>? _right;

  /// The cell of `right`, or Dart `null` when absent.
  Opt<double>? get rightCell => _right;

  /// Stores the cell of `right`. Dart `null` deletes the key.
  set rightCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.right);
    } else {
      store(OptionKey.right, cell);
    }
  }

  /// Stores the plain value [value] of `right`.
  set right(double value) => store(OptionKey.right, OptValue<double>(value));

  Opt<double>? _bottom;

  /// The cell of `bottom`, or Dart `null` when absent.
  Opt<double>? get bottomCell => _bottom;

  /// Stores the cell of `bottom`. Dart `null` deletes the key.
  set bottomCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.bottom);
    } else {
      store(OptionKey.bottom, cell);
    }
  }

  /// Stores the plain value [value] of `bottom`.
  set bottom(double value) => store(OptionKey.bottom, OptValue<double>(value));

  Opt<double>? _left;

  /// The cell of `left`, or Dart `null` when absent.
  Opt<double>? get leftCell => _left;

  /// Stores the cell of `left`. Dart `null` deletes the key.
  set leftCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.left);
    } else {
      store(OptionKey.left, cell);
    }
  }

  /// Stores the plain value [value] of `left`.
  set left(double value) => store(OptionKey.left, OptValue<double>(value));

  Opt<double>? _x;

  /// The cell of `x`, or Dart `null` when absent.
  Opt<double>? get xCell => _x;

  /// Stores the cell of `x`. Dart `null` deletes the key.
  set xCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.x);
    } else {
      store(OptionKey.x, cell);
    }
  }

  /// Stores the plain value [value] of `x`.
  set x(double value) => store(OptionKey.x, OptValue<double>(value));

  Opt<double>? _y;

  /// The cell of `y`, or Dart `null` when absent.
  Opt<double>? get yCell => _y;

  /// Stores the cell of `y`. Dart `null` deletes the key.
  set yCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.y);
    } else {
      store(OptionKey.y, cell);
    }
  }

  /// Stores the plain value [value] of `y`.
  set y(double value) => store(OptionKey.y, OptValue<double>(value));

  @override
  Opt<Object?>? cellOf(OptionKey key) => switch (key) {
    OptionKey.top => _top,
    OptionKey.right => _right,
    OptionKey.bottom => _bottom,
    OptionKey.left => _left,
    OptionKey.x => _x,
    OptionKey.y => _y,
    _ => null,
  };

  @override
  void setCell(OptionKey key, Opt<Object?>? cell) {
    switch (key) {
      case OptionKey.top:
        _top = fitCell(cell, classifyNumber);
      case OptionKey.right:
        _right = fitCell(cell, classifyNumber);
      case OptionKey.bottom:
        _bottom = fitCell(cell, classifyNumber);
      case OptionKey.left:
        _left = fitCell(cell, classifyNumber);
      case OptionKey.x:
        _x = fitCell(cell, classifyNumber);
      case OptionKey.y:
        _y = fitCell(cell, classifyNumber);
      default:
        throw ArgumentError.value(key, 'key', 'Not a key of Padding');
    }
  }

  @override
  bool hasField(OptionKey key) => switch (key) {
    OptionKey.top ||
    OptionKey.right ||
    OptionKey.bottom ||
    OptionKey.left ||
    OptionKey.x ||
    OptionKey.y => true,
    _ => false,
  };

  @override
  Opt<Object?> classify(OptionKey key, Object? raw) => switch (key) {
    OptionKey.top => classifyNumber(raw),
    OptionKey.right => classifyNumber(raw),
    OptionKey.bottom => classifyNumber(raw),
    OptionKey.left => classifyNumber(raw),
    OptionKey.x => classifyNumber(raw),
    OptionKey.y => classifyNumber(raw),
    _ => kind.classifyOther(raw),
  };
}

/// Port-only name for index.d.ts:1735 CoreChartOptions `layout`, the scope
/// `layout`.
base class LayoutOptionsScope extends OptionScope {
  /// An empty scope.
  LayoutOptionsScope();

  @override
  ScopeKind get kind => ScopeKind.layoutOptions;

  Opt<bool>? _autoPadding;

  /// The cell of `autoPadding`, or Dart `null` when absent.
  Opt<bool>? get autoPaddingCell => _autoPadding;

  /// Stores the cell of `autoPadding`. Dart `null` deletes the key.
  set autoPaddingCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.autoPadding);
    } else {
      store(OptionKey.autoPadding, cell);
    }
  }

  /// Stores the plain value [value] of `autoPadding`.
  set autoPadding(bool value) =>
      store(OptionKey.autoPadding, OptValue<bool>(value));

  Opt<Object>? _padding;

  /// The cell of `padding`, or Dart `null` when absent.
  Opt<Object>? get paddingCell => _padding;

  /// Stores the cell of `padding`. Dart `null` deletes the key.
  set paddingCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.padding);
    } else {
      store(OptionKey.padding, cell);
    }
  }

  /// Stores the plain value [value] of `padding`.
  set padding(Object value) =>
      store(OptionKey.padding, classify(OptionKey.padding, value));

  @override
  Opt<Object?>? cellOf(OptionKey key) => switch (key) {
    OptionKey.autoPadding => _autoPadding,
    OptionKey.padding => _padding,
    _ => null,
  };

  @override
  void setCell(OptionKey key, Opt<Object?>? cell) {
    switch (key) {
      case OptionKey.autoPadding:
        _autoPadding = fitCell(cell, classifyBool);
      case OptionKey.padding:
        _padding = fitCell(cell, (raw) => classifyUnion(raw, 33));
      default:
        throw ArgumentError.value(key, 'key', 'Not a key of LayoutOptions');
    }
  }

  @override
  bool hasField(OptionKey key) => switch (key) {
    OptionKey.autoPadding || OptionKey.padding => true,
    _ => false,
  };

  @override
  Opt<Object?> classify(OptionKey key, Object? raw) => switch (key) {
    OptionKey.autoPadding => classifyBool(raw),
    OptionKey.padding => classifyUnion(raw, 33),
    _ => kind.classifyOther(raw),
  };
}

/// index.d.ts:751 InteractionOptions and index.d.ts:1605
/// CoreInteractionOptions, the scopes `interaction` and `hover`.
base class InteractionOptionsScope extends OptionScope {
  /// An empty scope.
  InteractionOptionsScope();

  @override
  ScopeKind get kind => ScopeKind.interactionOptions;

  Opt<String>? _mode;

  /// The cell of `mode`, or Dart `null` when absent.
  Opt<String>? get modeCell => _mode;

  /// Stores the cell of `mode`. Dart `null` deletes the key.
  set modeCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.mode);
    } else {
      store(OptionKey.mode, cell);
    }
  }

  /// Stores the plain value [value] of `mode`.
  set mode(String value) => store(OptionKey.mode, OptValue<String>(value));

  Opt<bool>? _intersect;

  /// The cell of `intersect`, or Dart `null` when absent.
  Opt<bool>? get intersectCell => _intersect;

  /// Stores the cell of `intersect`. Dart `null` deletes the key.
  set intersectCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.intersect);
    } else {
      store(OptionKey.intersect, cell);
    }
  }

  /// Stores the plain value [value] of `intersect`.
  set intersect(bool value) =>
      store(OptionKey.intersect, OptValue<bool>(value));

  Opt<String>? _axis;

  /// The cell of `axis`, or Dart `null` when absent.
  Opt<String>? get axisCell => _axis;

  /// Stores the cell of `axis`. Dart `null` deletes the key.
  set axisCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.axis);
    } else {
      store(OptionKey.axis, cell);
    }
  }

  /// Stores the plain value [value] of `axis`.
  set axis(String value) => store(OptionKey.axis, OptValue<String>(value));

  Opt<bool>? _includeInvisible;

  /// The cell of `includeInvisible`, or Dart `null` when absent.
  Opt<bool>? get includeInvisibleCell => _includeInvisible;

  /// Stores the cell of `includeInvisible`. Dart `null` deletes the key.
  set includeInvisibleCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.includeInvisible);
    } else {
      store(OptionKey.includeInvisible, cell);
    }
  }

  /// Stores the plain value [value] of `includeInvisible`.
  set includeInvisible(bool value) =>
      store(OptionKey.includeInvisible, OptValue<bool>(value));

  @override
  Opt<Object?>? cellOf(OptionKey key) => switch (key) {
    OptionKey.mode => _mode,
    OptionKey.intersect => _intersect,
    OptionKey.axis => _axis,
    OptionKey.includeInvisible => _includeInvisible,
    _ => null,
  };

  @override
  void setCell(OptionKey key, Opt<Object?>? cell) {
    switch (key) {
      case OptionKey.mode:
        _mode = fitCell(cell, classifyString);
      case OptionKey.intersect:
        _intersect = fitCell(cell, classifyBool);
      case OptionKey.axis:
        _axis = fitCell(cell, classifyString);
      case OptionKey.includeInvisible:
        _includeInvisible = fitCell(cell, classifyBool);
      default:
        throw ArgumentError.value(
          key,
          'key',
          'Not a key of InteractionOptions',
        );
    }
  }

  @override
  bool hasField(OptionKey key) => switch (key) {
    OptionKey.mode ||
    OptionKey.intersect ||
    OptionKey.axis ||
    OptionKey.includeInvisible => true,
    _ => false,
  };

  @override
  Opt<Object?> classify(OptionKey key, Object? raw) => switch (key) {
    OptionKey.mode => classifyString(raw),
    OptionKey.intersect => classifyBool(raw),
    OptionKey.axis => classifyString(raw),
    OptionKey.includeInvisible => classifyBool(raw),
    _ => kind.classifyOther(raw),
  };
}

/// Port-only name for the object form of index.d.ts:54 ParsingOptions
/// `parsing`, the keys of the parsed data (core.datasetController.js:561,
/// controller.doughnut.js:158, helpers.config.ts:444).
base class ParsingOptionsScope extends OptionScope {
  /// An empty scope.
  ParsingOptionsScope();

  @override
  ScopeKind get kind => ScopeKind.parsingOptions;

  Opt<String>? _key;

  /// The cell of `key`, or Dart `null` when absent.
  Opt<String>? get keyCell => _key;

  /// Stores the cell of `key`. Dart `null` deletes the key.
  set keyCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.key);
    } else {
      store(OptionKey.key, cell);
    }
  }

  /// Stores the plain value [value] of `key`.
  set key(String value) => store(OptionKey.key, OptValue<String>(value));

  Opt<String>? _xAxisKey;

  /// The cell of `xAxisKey`, or Dart `null` when absent.
  Opt<String>? get xAxisKeyCell => _xAxisKey;

  /// Stores the cell of `xAxisKey`. Dart `null` deletes the key.
  set xAxisKeyCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.xAxisKey);
    } else {
      store(OptionKey.xAxisKey, cell);
    }
  }

  /// Stores the plain value [value] of `xAxisKey`.
  set xAxisKey(String value) =>
      store(OptionKey.xAxisKey, OptValue<String>(value));

  Opt<String>? _yAxisKey;

  /// The cell of `yAxisKey`, or Dart `null` when absent.
  Opt<String>? get yAxisKeyCell => _yAxisKey;

  /// Stores the cell of `yAxisKey`. Dart `null` deletes the key.
  set yAxisKeyCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.yAxisKey);
    } else {
      store(OptionKey.yAxisKey, cell);
    }
  }

  /// Stores the plain value [value] of `yAxisKey`.
  set yAxisKey(String value) =>
      store(OptionKey.yAxisKey, OptValue<String>(value));

  @override
  Opt<Object?>? cellOf(OptionKey key) => switch (key) {
    OptionKey.key => _key,
    OptionKey.xAxisKey => _xAxisKey,
    OptionKey.yAxisKey => _yAxisKey,
    _ => null,
  };

  @override
  void setCell(OptionKey key, Opt<Object?>? cell) {
    switch (key) {
      case OptionKey.key:
        _key = fitCell(cell, classifyString);
      case OptionKey.xAxisKey:
        _xAxisKey = fitCell(cell, classifyString);
      case OptionKey.yAxisKey:
        _yAxisKey = fitCell(cell, classifyString);
      default:
        throw ArgumentError.value(key, 'key', 'Not a key of ParsingOptions');
    }
  }

  @override
  bool hasField(OptionKey key) => switch (key) {
    OptionKey.key || OptionKey.xAxisKey || OptionKey.yAxisKey => true,
    _ => false,
  };

  @override
  Opt<Object?> classify(OptionKey key, Object? raw) => switch (key) {
    OptionKey.key => classifyString(raw),
    OptionKey.xAxisKey => classifyString(raw),
    OptionKey.yAxisKey => classifyString(raw),
    _ => kind.classifyOther(raw),
  };
}

/// Port-only name for the object form of index.d.ts:75 `clip` (index.d.ts:463
/// ChartMetaClip), the clip of each side.
base class ChartAreaScope extends OptionScope {
  /// An empty scope.
  ChartAreaScope();

  @override
  ScopeKind get kind => ScopeKind.chartArea;

  Opt<Object>? _left;

  /// The cell of `left`, or Dart `null` when absent.
  Opt<Object>? get leftCell => _left;

  /// Stores the cell of `left`. Dart `null` deletes the key.
  set leftCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.left);
    } else {
      store(OptionKey.left, cell);
    }
  }

  /// Stores the plain value [value] of `left`.
  set left(Object value) =>
      store(OptionKey.left, classify(OptionKey.left, value));

  Opt<Object>? _top;

  /// The cell of `top`, or Dart `null` when absent.
  Opt<Object>? get topCell => _top;

  /// Stores the cell of `top`. Dart `null` deletes the key.
  set topCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.top);
    } else {
      store(OptionKey.top, cell);
    }
  }

  /// Stores the plain value [value] of `top`.
  set top(Object value) => store(OptionKey.top, classify(OptionKey.top, value));

  Opt<Object>? _right;

  /// The cell of `right`, or Dart `null` when absent.
  Opt<Object>? get rightCell => _right;

  /// Stores the cell of `right`. Dart `null` deletes the key.
  set rightCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.right);
    } else {
      store(OptionKey.right, cell);
    }
  }

  /// Stores the plain value [value] of `right`.
  set right(Object value) =>
      store(OptionKey.right, classify(OptionKey.right, value));

  Opt<Object>? _bottom;

  /// The cell of `bottom`, or Dart `null` when absent.
  Opt<Object>? get bottomCell => _bottom;

  /// Stores the cell of `bottom`. Dart `null` deletes the key.
  set bottomCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.bottom);
    } else {
      store(OptionKey.bottom, cell);
    }
  }

  /// Stores the plain value [value] of `bottom`.
  set bottom(Object value) =>
      store(OptionKey.bottom, classify(OptionKey.bottom, value));

  @override
  Opt<Object?>? cellOf(OptionKey key) => switch (key) {
    OptionKey.left => _left,
    OptionKey.top => _top,
    OptionKey.right => _right,
    OptionKey.bottom => _bottom,
    _ => null,
  };

  @override
  void setCell(OptionKey key, Opt<Object?>? cell) {
    switch (key) {
      case OptionKey.left:
        _left = fitCell(cell, (raw) => classifyUnion(raw, 3));
      case OptionKey.top:
        _top = fitCell(cell, (raw) => classifyUnion(raw, 3));
      case OptionKey.right:
        _right = fitCell(cell, (raw) => classifyUnion(raw, 3));
      case OptionKey.bottom:
        _bottom = fitCell(cell, (raw) => classifyUnion(raw, 3));
      default:
        throw ArgumentError.value(key, 'key', 'Not a key of ChartArea');
    }
  }

  @override
  bool hasField(OptionKey key) => switch (key) {
    OptionKey.left ||
    OptionKey.top ||
    OptionKey.right ||
    OptionKey.bottom => true,
    _ => false,
  };

  @override
  Opt<Object?> classify(OptionKey key, Object? raw) => switch (key) {
    OptionKey.left => classifyUnion(raw, 3),
    OptionKey.top => classifyUnion(raw, 3),
    OptionKey.right => classifyUnion(raw, 3),
    OptionKey.bottom => classifyUnion(raw, 3),
    _ => kind.classifyOther(raw),
  };
}

/// index.d.ts:2055 PointOptions and index.d.ts:2083 PointHoverOptions, the
/// options of a point element.
base class PointOptionsScope extends OptionScope {
  /// An empty scope.
  PointOptionsScope();

  @override
  ScopeKind get kind => ScopeKind.pointOptions;

  Opt<double>? _borderWidth;

  /// The cell of `borderWidth`, or Dart `null` when absent.
  Opt<double>? get borderWidthCell => _borderWidth;

  /// Stores the cell of `borderWidth`. Dart `null` deletes the key.
  set borderWidthCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.borderWidth);
    } else {
      store(OptionKey.borderWidth, cell);
    }
  }

  /// Stores the plain value [value] of `borderWidth`.
  set borderWidth(double value) =>
      store(OptionKey.borderWidth, OptValue<double>(value));

  Opt<Object>? _borderColor;

  /// The cell of `borderColor`, or Dart `null` when absent.
  Opt<Object>? get borderColorCell => _borderColor;

  /// Stores the cell of `borderColor`. Dart `null` deletes the key.
  set borderColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.borderColor);
    } else {
      store(OptionKey.borderColor, cell);
    }
  }

  /// Stores the plain value [value] of `borderColor`.
  set borderColor(Object value) =>
      store(OptionKey.borderColor, classify(OptionKey.borderColor, value));

  Opt<Object>? _backgroundColor;

  /// The cell of `backgroundColor`, or Dart `null` when absent.
  Opt<Object>? get backgroundColorCell => _backgroundColor;

  /// Stores the cell of `backgroundColor`. Dart `null` deletes the key.
  set backgroundColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.backgroundColor);
    } else {
      store(OptionKey.backgroundColor, cell);
    }
  }

  /// Stores the plain value [value] of `backgroundColor`.
  set backgroundColor(Object value) => store(
    OptionKey.backgroundColor,
    classify(OptionKey.backgroundColor, value),
  );

  Opt<double>? _radius;

  /// The cell of `radius`, or Dart `null` when absent.
  Opt<double>? get radiusCell => _radius;

  /// Stores the cell of `radius`. Dart `null` deletes the key.
  set radiusCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.radius);
    } else {
      store(OptionKey.radius, cell);
    }
  }

  /// Stores the plain value [value] of `radius`.
  set radius(double value) => store(OptionKey.radius, OptValue<double>(value));

  Opt<double>? _hitRadius;

  /// The cell of `hitRadius`, or Dart `null` when absent.
  Opt<double>? get hitRadiusCell => _hitRadius;

  /// Stores the cell of `hitRadius`. Dart `null` deletes the key.
  set hitRadiusCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.hitRadius);
    } else {
      store(OptionKey.hitRadius, cell);
    }
  }

  /// Stores the plain value [value] of `hitRadius`.
  set hitRadius(double value) =>
      store(OptionKey.hitRadius, OptValue<double>(value));

  Opt<Object>? _pointStyle;

  /// The cell of `pointStyle`, or Dart `null` when absent.
  Opt<Object>? get pointStyleCell => _pointStyle;

  /// Stores the cell of `pointStyle`. Dart `null` deletes the key.
  set pointStyleCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.pointStyle);
    } else {
      store(OptionKey.pointStyle, cell);
    }
  }

  /// Stores the plain value [value] of `pointStyle`.
  set pointStyle(Object value) =>
      store(OptionKey.pointStyle, classify(OptionKey.pointStyle, value));

  Opt<double>? _rotation;

  /// The cell of `rotation`, or Dart `null` when absent.
  Opt<double>? get rotationCell => _rotation;

  /// Stores the cell of `rotation`. Dart `null` deletes the key.
  set rotationCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.rotation);
    } else {
      store(OptionKey.rotation, cell);
    }
  }

  /// Stores the plain value [value] of `rotation`.
  set rotation(double value) =>
      store(OptionKey.rotation, OptValue<double>(value));

  Opt<bool>? _drawActiveElementsOnTop;

  /// The cell of `drawActiveElementsOnTop`, or Dart `null` when absent.
  Opt<bool>? get drawActiveElementsOnTopCell => _drawActiveElementsOnTop;

  /// Stores the cell of `drawActiveElementsOnTop`. Dart `null` deletes the key.
  set drawActiveElementsOnTopCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.drawActiveElementsOnTop);
    } else {
      store(OptionKey.drawActiveElementsOnTop, cell);
    }
  }

  /// Stores the plain value [value] of `drawActiveElementsOnTop`.
  set drawActiveElementsOnTop(bool value) =>
      store(OptionKey.drawActiveElementsOnTop, OptValue<bool>(value));

  Opt<double>? _hoverBorderWidth;

  /// The cell of `hoverBorderWidth`, or Dart `null` when absent.
  Opt<double>? get hoverBorderWidthCell => _hoverBorderWidth;

  /// Stores the cell of `hoverBorderWidth`. Dart `null` deletes the key.
  set hoverBorderWidthCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBorderWidth);
    } else {
      store(OptionKey.hoverBorderWidth, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBorderWidth`.
  set hoverBorderWidth(double value) =>
      store(OptionKey.hoverBorderWidth, OptValue<double>(value));

  Opt<Object>? _hoverBorderColor;

  /// The cell of `hoverBorderColor`, or Dart `null` when absent.
  Opt<Object>? get hoverBorderColorCell => _hoverBorderColor;

  /// Stores the cell of `hoverBorderColor`. Dart `null` deletes the key.
  set hoverBorderColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBorderColor);
    } else {
      store(OptionKey.hoverBorderColor, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBorderColor`.
  set hoverBorderColor(Object value) => store(
    OptionKey.hoverBorderColor,
    classify(OptionKey.hoverBorderColor, value),
  );

  Opt<Object>? _hoverBackgroundColor;

  /// The cell of `hoverBackgroundColor`, or Dart `null` when absent.
  Opt<Object>? get hoverBackgroundColorCell => _hoverBackgroundColor;

  /// Stores the cell of `hoverBackgroundColor`. Dart `null` deletes the key.
  set hoverBackgroundColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBackgroundColor);
    } else {
      store(OptionKey.hoverBackgroundColor, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBackgroundColor`.
  set hoverBackgroundColor(Object value) => store(
    OptionKey.hoverBackgroundColor,
    classify(OptionKey.hoverBackgroundColor, value),
  );

  Opt<double>? _hoverRadius;

  /// The cell of `hoverRadius`, or Dart `null` when absent.
  Opt<double>? get hoverRadiusCell => _hoverRadius;

  /// Stores the cell of `hoverRadius`. Dart `null` deletes the key.
  set hoverRadiusCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverRadius);
    } else {
      store(OptionKey.hoverRadius, cell);
    }
  }

  /// Stores the plain value [value] of `hoverRadius`.
  set hoverRadius(double value) =>
      store(OptionKey.hoverRadius, OptValue<double>(value));

  Opt<bool>? _dollarShared;

  /// The cell of `$shared`, or Dart `null` when absent.
  Opt<bool>? get dollarSharedCell => _dollarShared;

  /// Stores the cell of `$shared`. Dart `null` deletes the key.
  set dollarSharedCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.dollarShared);
    } else {
      store(OptionKey.dollarShared, cell);
    }
  }

  /// Stores the plain value [value] of `$shared`.
  set dollarShared(bool value) =>
      store(OptionKey.dollarShared, OptValue<bool>(value));

  Opt<Object>? _dollarAnimations;

  /// The cell of `$animations`, or Dart `null` when absent.
  Opt<Object>? get dollarAnimationsCell => _dollarAnimations;

  /// Stores the cell of `$animations`. Dart `null` deletes the key.
  set dollarAnimationsCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.dollarAnimations);
    } else {
      store(OptionKey.dollarAnimations, cell);
    }
  }

  /// Stores the plain value [value] of `$animations`.
  set dollarAnimations(Object value) => store(
    OptionKey.dollarAnimations,
    classify(OptionKey.dollarAnimations, value),
  );

  @override
  Opt<Object?>? cellOf(OptionKey key) => switch (key) {
    OptionKey.borderWidth => _borderWidth,
    OptionKey.borderColor => _borderColor,
    OptionKey.backgroundColor => _backgroundColor,
    OptionKey.radius => _radius,
    OptionKey.hitRadius => _hitRadius,
    OptionKey.pointStyle => _pointStyle,
    OptionKey.rotation => _rotation,
    OptionKey.drawActiveElementsOnTop => _drawActiveElementsOnTop,
    OptionKey.hoverBorderWidth => _hoverBorderWidth,
    OptionKey.hoverBorderColor => _hoverBorderColor,
    OptionKey.hoverBackgroundColor => _hoverBackgroundColor,
    OptionKey.hoverRadius => _hoverRadius,
    OptionKey.dollarShared => _dollarShared,
    OptionKey.dollarAnimations => _dollarAnimations,
    _ => null,
  };

  @override
  void setCell(OptionKey key, Opt<Object?>? cell) {
    switch (key) {
      case OptionKey.borderWidth:
        _borderWidth = fitCell(cell, classifyNumber);
      case OptionKey.borderColor:
        _borderColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.backgroundColor:
        _backgroundColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.radius:
        _radius = fitCell(cell, classifyNumber);
      case OptionKey.hitRadius:
        _hitRadius = fitCell(cell, classifyNumber);
      case OptionKey.pointStyle:
        _pointStyle = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.rotation:
        _rotation = fitCell(cell, classifyNumber);
      case OptionKey.drawActiveElementsOnTop:
        _drawActiveElementsOnTop = fitCell(cell, classifyBool);
      case OptionKey.hoverBorderWidth:
        _hoverBorderWidth = fitCell(cell, classifyNumber);
      case OptionKey.hoverBorderColor:
        _hoverBorderColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.hoverBackgroundColor:
        _hoverBackgroundColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.hoverRadius:
        _hoverRadius = fitCell(cell, classifyNumber);
      case OptionKey.dollarShared:
        _dollarShared = fitCell(cell, classifyBool);
      case OptionKey.dollarAnimations:
        _dollarAnimations = fitCell(cell, (raw) => classifyUnion(raw, 64));
      default:
        throw ArgumentError.value(key, 'key', 'Not a key of PointOptions');
    }
  }

  @override
  bool hasField(OptionKey key) => switch (key) {
    OptionKey.borderWidth ||
    OptionKey.borderColor ||
    OptionKey.backgroundColor ||
    OptionKey.radius ||
    OptionKey.hitRadius ||
    OptionKey.pointStyle ||
    OptionKey.rotation ||
    OptionKey.drawActiveElementsOnTop ||
    OptionKey.hoverBorderWidth ||
    OptionKey.hoverBorderColor ||
    OptionKey.hoverBackgroundColor ||
    OptionKey.hoverRadius ||
    OptionKey.dollarShared ||
    OptionKey.dollarAnimations => true,
    _ => false,
  };

  @override
  Opt<Object?> classify(OptionKey key, Object? raw) => switch (key) {
    OptionKey.borderWidth => classifyNumber(raw),
    OptionKey.borderColor => classifyUnion(raw, 64),
    OptionKey.backgroundColor => classifyUnion(raw, 64),
    OptionKey.radius => classifyNumber(raw),
    OptionKey.hitRadius => classifyNumber(raw),
    OptionKey.pointStyle => classifyUnion(raw, 64),
    OptionKey.rotation => classifyNumber(raw),
    OptionKey.drawActiveElementsOnTop => classifyBool(raw),
    OptionKey.hoverBorderWidth => classifyNumber(raw),
    OptionKey.hoverBorderColor => classifyUnion(raw, 64),
    OptionKey.hoverBackgroundColor => classifyUnion(raw, 64),
    OptionKey.hoverRadius => classifyNumber(raw),
    OptionKey.dollarShared => classifyBool(raw),
    OptionKey.dollarAnimations => classifyUnion(raw, 64),
    _ => kind.classifyOther(raw),
  };
}

/// index.d.ts:1954 LineOptions and index.d.ts:2015 LineHoverOptions, the
/// options of a line element.
base class LineOptionsScope extends OptionScope {
  /// An empty scope.
  LineOptionsScope();

  @override
  ScopeKind get kind => ScopeKind.lineOptions;

  Opt<double>? _borderWidth;

  /// The cell of `borderWidth`, or Dart `null` when absent.
  Opt<double>? get borderWidthCell => _borderWidth;

  /// Stores the cell of `borderWidth`. Dart `null` deletes the key.
  set borderWidthCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.borderWidth);
    } else {
      store(OptionKey.borderWidth, cell);
    }
  }

  /// Stores the plain value [value] of `borderWidth`.
  set borderWidth(double value) =>
      store(OptionKey.borderWidth, OptValue<double>(value));

  Opt<Object>? _borderColor;

  /// The cell of `borderColor`, or Dart `null` when absent.
  Opt<Object>? get borderColorCell => _borderColor;

  /// Stores the cell of `borderColor`. Dart `null` deletes the key.
  set borderColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.borderColor);
    } else {
      store(OptionKey.borderColor, cell);
    }
  }

  /// Stores the plain value [value] of `borderColor`.
  set borderColor(Object value) =>
      store(OptionKey.borderColor, classify(OptionKey.borderColor, value));

  Opt<Object>? _backgroundColor;

  /// The cell of `backgroundColor`, or Dart `null` when absent.
  Opt<Object>? get backgroundColorCell => _backgroundColor;

  /// Stores the cell of `backgroundColor`. Dart `null` deletes the key.
  set backgroundColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.backgroundColor);
    } else {
      store(OptionKey.backgroundColor, cell);
    }
  }

  /// Stores the plain value [value] of `backgroundColor`.
  set backgroundColor(Object value) => store(
    OptionKey.backgroundColor,
    classify(OptionKey.backgroundColor, value),
  );

  Opt<String>? _borderCapStyle;

  /// The cell of `borderCapStyle`, or Dart `null` when absent.
  Opt<String>? get borderCapStyleCell => _borderCapStyle;

  /// Stores the cell of `borderCapStyle`. Dart `null` deletes the key.
  set borderCapStyleCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.borderCapStyle);
    } else {
      store(OptionKey.borderCapStyle, cell);
    }
  }

  /// Stores the plain value [value] of `borderCapStyle`.
  set borderCapStyle(String value) =>
      store(OptionKey.borderCapStyle, OptValue<String>(value));

  Opt<Object>? _borderDash;

  /// The cell of `borderDash`, or Dart `null` when absent.
  Opt<Object>? get borderDashCell => _borderDash;

  /// Stores the cell of `borderDash`. Dart `null` deletes the key.
  set borderDashCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.borderDash);
    } else {
      store(OptionKey.borderDash, cell);
    }
  }

  /// Stores the plain value [value] of `borderDash`.
  set borderDash(Object value) =>
      store(OptionKey.borderDash, classify(OptionKey.borderDash, value));

  Opt<double>? _borderDashOffset;

  /// The cell of `borderDashOffset`, or Dart `null` when absent.
  Opt<double>? get borderDashOffsetCell => _borderDashOffset;

  /// Stores the cell of `borderDashOffset`. Dart `null` deletes the key.
  set borderDashOffsetCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.borderDashOffset);
    } else {
      store(OptionKey.borderDashOffset, cell);
    }
  }

  /// Stores the plain value [value] of `borderDashOffset`.
  set borderDashOffset(double value) =>
      store(OptionKey.borderDashOffset, OptValue<double>(value));

  Opt<String>? _borderJoinStyle;

  /// The cell of `borderJoinStyle`, or Dart `null` when absent.
  Opt<String>? get borderJoinStyleCell => _borderJoinStyle;

  /// Stores the cell of `borderJoinStyle`. Dart `null` deletes the key.
  set borderJoinStyleCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.borderJoinStyle);
    } else {
      store(OptionKey.borderJoinStyle, cell);
    }
  }

  /// Stores the plain value [value] of `borderJoinStyle`.
  set borderJoinStyle(String value) =>
      store(OptionKey.borderJoinStyle, OptValue<String>(value));

  Opt<bool>? _capBezierPoints;

  /// The cell of `capBezierPoints`, or Dart `null` when absent.
  Opt<bool>? get capBezierPointsCell => _capBezierPoints;

  /// Stores the cell of `capBezierPoints`. Dart `null` deletes the key.
  set capBezierPointsCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.capBezierPoints);
    } else {
      store(OptionKey.capBezierPoints, cell);
    }
  }

  /// Stores the plain value [value] of `capBezierPoints`.
  set capBezierPoints(bool value) =>
      store(OptionKey.capBezierPoints, OptValue<bool>(value));

  Opt<String>? _cubicInterpolationMode;

  /// The cell of `cubicInterpolationMode`, or Dart `null` when absent.
  Opt<String>? get cubicInterpolationModeCell => _cubicInterpolationMode;

  /// Stores the cell of `cubicInterpolationMode`. Dart `null` deletes the key.
  set cubicInterpolationModeCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.cubicInterpolationMode);
    } else {
      store(OptionKey.cubicInterpolationMode, cell);
    }
  }

  /// Stores the plain value [value] of `cubicInterpolationMode`.
  set cubicInterpolationMode(String value) =>
      store(OptionKey.cubicInterpolationMode, OptValue<String>(value));

  Opt<double>? _tension;

  /// The cell of `tension`, or Dart `null` when absent.
  Opt<double>? get tensionCell => _tension;

  /// Stores the cell of `tension`. Dart `null` deletes the key.
  set tensionCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.tension);
    } else {
      store(OptionKey.tension, cell);
    }
  }

  /// Stores the plain value [value] of `tension`.
  set tension(double value) =>
      store(OptionKey.tension, OptValue<double>(value));

  Opt<Object>? _stepped;

  /// The cell of `stepped`, or Dart `null` when absent.
  Opt<Object>? get steppedCell => _stepped;

  /// Stores the cell of `stepped`. Dart `null` deletes the key.
  set steppedCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.stepped);
    } else {
      store(OptionKey.stepped, cell);
    }
  }

  /// Stores the plain value [value] of `stepped`.
  set stepped(Object value) =>
      store(OptionKey.stepped, classify(OptionKey.stepped, value));

  Opt<Object>? _fill;

  /// The cell of `fill`, or Dart `null` when absent.
  Opt<Object>? get fillCell => _fill;

  /// Stores the cell of `fill`. Dart `null` deletes the key.
  set fillCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.fill);
    } else {
      store(OptionKey.fill, cell);
    }
  }

  /// Stores the plain value [value] of `fill`.
  set fill(Object value) =>
      store(OptionKey.fill, classify(OptionKey.fill, value));

  Opt<Object>? _spanGaps;

  /// The cell of `spanGaps`, or Dart `null` when absent.
  Opt<Object>? get spanGapsCell => _spanGaps;

  /// Stores the cell of `spanGaps`. Dart `null` deletes the key.
  set spanGapsCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.spanGaps);
    } else {
      store(OptionKey.spanGaps, cell);
    }
  }

  /// Stores the plain value [value] of `spanGaps`.
  set spanGaps(Object value) =>
      store(OptionKey.spanGaps, classify(OptionKey.spanGaps, value));

  Opt<SegmentOptionsScope>? _segment;

  /// The cell of `segment`, or Dart `null` when absent.
  Opt<SegmentOptionsScope>? get segmentCell => _segment;

  /// Stores the cell of `segment`. Dart `null` deletes the key.
  set segmentCell(Opt<SegmentOptionsScope>? cell) {
    if (cell == null) {
      delete(OptionKey.segment);
    } else {
      store(OptionKey.segment, cell);
    }
  }

  /// Stores the plain value [value] of `segment`.
  set segment(SegmentOptionsScope value) =>
      store(OptionKey.segment, OptScope<SegmentOptionsScope>(value));

  Opt<double>? _hoverBorderWidth;

  /// The cell of `hoverBorderWidth`, or Dart `null` when absent.
  Opt<double>? get hoverBorderWidthCell => _hoverBorderWidth;

  /// Stores the cell of `hoverBorderWidth`. Dart `null` deletes the key.
  set hoverBorderWidthCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBorderWidth);
    } else {
      store(OptionKey.hoverBorderWidth, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBorderWidth`.
  set hoverBorderWidth(double value) =>
      store(OptionKey.hoverBorderWidth, OptValue<double>(value));

  Opt<Object>? _hoverBorderColor;

  /// The cell of `hoverBorderColor`, or Dart `null` when absent.
  Opt<Object>? get hoverBorderColorCell => _hoverBorderColor;

  /// Stores the cell of `hoverBorderColor`. Dart `null` deletes the key.
  set hoverBorderColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBorderColor);
    } else {
      store(OptionKey.hoverBorderColor, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBorderColor`.
  set hoverBorderColor(Object value) => store(
    OptionKey.hoverBorderColor,
    classify(OptionKey.hoverBorderColor, value),
  );

  Opt<Object>? _hoverBackgroundColor;

  /// The cell of `hoverBackgroundColor`, or Dart `null` when absent.
  Opt<Object>? get hoverBackgroundColorCell => _hoverBackgroundColor;

  /// Stores the cell of `hoverBackgroundColor`. Dart `null` deletes the key.
  set hoverBackgroundColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBackgroundColor);
    } else {
      store(OptionKey.hoverBackgroundColor, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBackgroundColor`.
  set hoverBackgroundColor(Object value) => store(
    OptionKey.hoverBackgroundColor,
    classify(OptionKey.hoverBackgroundColor, value),
  );

  Opt<String>? _hoverBorderCapStyle;

  /// The cell of `hoverBorderCapStyle`, or Dart `null` when absent.
  Opt<String>? get hoverBorderCapStyleCell => _hoverBorderCapStyle;

  /// Stores the cell of `hoverBorderCapStyle`. Dart `null` deletes the key.
  set hoverBorderCapStyleCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBorderCapStyle);
    } else {
      store(OptionKey.hoverBorderCapStyle, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBorderCapStyle`.
  set hoverBorderCapStyle(String value) =>
      store(OptionKey.hoverBorderCapStyle, OptValue<String>(value));

  Opt<Object>? _hoverBorderDash;

  /// The cell of `hoverBorderDash`, or Dart `null` when absent.
  Opt<Object>? get hoverBorderDashCell => _hoverBorderDash;

  /// Stores the cell of `hoverBorderDash`. Dart `null` deletes the key.
  set hoverBorderDashCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBorderDash);
    } else {
      store(OptionKey.hoverBorderDash, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBorderDash`.
  set hoverBorderDash(Object value) => store(
    OptionKey.hoverBorderDash,
    classify(OptionKey.hoverBorderDash, value),
  );

  Opt<double>? _hoverBorderDashOffset;

  /// The cell of `hoverBorderDashOffset`, or Dart `null` when absent.
  Opt<double>? get hoverBorderDashOffsetCell => _hoverBorderDashOffset;

  /// Stores the cell of `hoverBorderDashOffset`. Dart `null` deletes the key.
  set hoverBorderDashOffsetCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBorderDashOffset);
    } else {
      store(OptionKey.hoverBorderDashOffset, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBorderDashOffset`.
  set hoverBorderDashOffset(double value) =>
      store(OptionKey.hoverBorderDashOffset, OptValue<double>(value));

  Opt<String>? _hoverBorderJoinStyle;

  /// The cell of `hoverBorderJoinStyle`, or Dart `null` when absent.
  Opt<String>? get hoverBorderJoinStyleCell => _hoverBorderJoinStyle;

  /// Stores the cell of `hoverBorderJoinStyle`. Dart `null` deletes the key.
  set hoverBorderJoinStyleCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBorderJoinStyle);
    } else {
      store(OptionKey.hoverBorderJoinStyle, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBorderJoinStyle`.
  set hoverBorderJoinStyle(String value) =>
      store(OptionKey.hoverBorderJoinStyle, OptValue<String>(value));

  Opt<bool>? _dollarShared;

  /// The cell of `$shared`, or Dart `null` when absent.
  Opt<bool>? get dollarSharedCell => _dollarShared;

  /// Stores the cell of `$shared`. Dart `null` deletes the key.
  set dollarSharedCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.dollarShared);
    } else {
      store(OptionKey.dollarShared, cell);
    }
  }

  /// Stores the plain value [value] of `$shared`.
  set dollarShared(bool value) =>
      store(OptionKey.dollarShared, OptValue<bool>(value));

  Opt<Object>? _dollarAnimations;

  /// The cell of `$animations`, or Dart `null` when absent.
  Opt<Object>? get dollarAnimationsCell => _dollarAnimations;

  /// Stores the cell of `$animations`. Dart `null` deletes the key.
  set dollarAnimationsCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.dollarAnimations);
    } else {
      store(OptionKey.dollarAnimations, cell);
    }
  }

  /// Stores the plain value [value] of `$animations`.
  set dollarAnimations(Object value) => store(
    OptionKey.dollarAnimations,
    classify(OptionKey.dollarAnimations, value),
  );

  @override
  Opt<Object?>? cellOf(OptionKey key) => switch (key) {
    OptionKey.borderWidth => _borderWidth,
    OptionKey.borderColor => _borderColor,
    OptionKey.backgroundColor => _backgroundColor,
    OptionKey.borderCapStyle => _borderCapStyle,
    OptionKey.borderDash => _borderDash,
    OptionKey.borderDashOffset => _borderDashOffset,
    OptionKey.borderJoinStyle => _borderJoinStyle,
    OptionKey.capBezierPoints => _capBezierPoints,
    OptionKey.cubicInterpolationMode => _cubicInterpolationMode,
    OptionKey.tension => _tension,
    OptionKey.stepped => _stepped,
    OptionKey.fill => _fill,
    OptionKey.spanGaps => _spanGaps,
    OptionKey.segment => _segment,
    OptionKey.hoverBorderWidth => _hoverBorderWidth,
    OptionKey.hoverBorderColor => _hoverBorderColor,
    OptionKey.hoverBackgroundColor => _hoverBackgroundColor,
    OptionKey.hoverBorderCapStyle => _hoverBorderCapStyle,
    OptionKey.hoverBorderDash => _hoverBorderDash,
    OptionKey.hoverBorderDashOffset => _hoverBorderDashOffset,
    OptionKey.hoverBorderJoinStyle => _hoverBorderJoinStyle,
    OptionKey.dollarShared => _dollarShared,
    OptionKey.dollarAnimations => _dollarAnimations,
    _ => null,
  };

  @override
  void setCell(OptionKey key, Opt<Object?>? cell) {
    switch (key) {
      case OptionKey.borderWidth:
        _borderWidth = fitCell(cell, classifyNumber);
      case OptionKey.borderColor:
        _borderColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.backgroundColor:
        _backgroundColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.borderCapStyle:
        _borderCapStyle = fitCell(cell, classifyString);
      case OptionKey.borderDash:
        _borderDash = fitCell(cell, (raw) => classifyUnion(raw, 16));
      case OptionKey.borderDashOffset:
        _borderDashOffset = fitCell(cell, classifyNumber);
      case OptionKey.borderJoinStyle:
        _borderJoinStyle = fitCell(cell, classifyString);
      case OptionKey.capBezierPoints:
        _capBezierPoints = fitCell(cell, classifyBool);
      case OptionKey.cubicInterpolationMode:
        _cubicInterpolationMode = fitCell(cell, classifyString);
      case OptionKey.tension:
        _tension = fitCell(cell, classifyNumber);
      case OptionKey.stepped:
        _stepped = fitCell(cell, (raw) => classifyUnion(raw, 6));
      case OptionKey.fill:
        _fill = fitCell(cell, (raw) => classifyUnion(raw, 39));
      case OptionKey.spanGaps:
        _spanGaps = fitCell(cell, (raw) => classifyUnion(raw, 3));
      case OptionKey.segment:
        _segment = fitCell(cell, classifyScope<SegmentOptionsScope>);
      case OptionKey.hoverBorderWidth:
        _hoverBorderWidth = fitCell(cell, classifyNumber);
      case OptionKey.hoverBorderColor:
        _hoverBorderColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.hoverBackgroundColor:
        _hoverBackgroundColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.hoverBorderCapStyle:
        _hoverBorderCapStyle = fitCell(cell, classifyString);
      case OptionKey.hoverBorderDash:
        _hoverBorderDash = fitCell(cell, (raw) => classifyUnion(raw, 16));
      case OptionKey.hoverBorderDashOffset:
        _hoverBorderDashOffset = fitCell(cell, classifyNumber);
      case OptionKey.hoverBorderJoinStyle:
        _hoverBorderJoinStyle = fitCell(cell, classifyString);
      case OptionKey.dollarShared:
        _dollarShared = fitCell(cell, classifyBool);
      case OptionKey.dollarAnimations:
        _dollarAnimations = fitCell(cell, (raw) => classifyUnion(raw, 64));
      default:
        throw ArgumentError.value(key, 'key', 'Not a key of LineOptions');
    }
  }

  @override
  bool hasField(OptionKey key) => switch (key) {
    OptionKey.borderWidth ||
    OptionKey.borderColor ||
    OptionKey.backgroundColor ||
    OptionKey.borderCapStyle ||
    OptionKey.borderDash ||
    OptionKey.borderDashOffset ||
    OptionKey.borderJoinStyle ||
    OptionKey.capBezierPoints ||
    OptionKey.cubicInterpolationMode ||
    OptionKey.tension ||
    OptionKey.stepped ||
    OptionKey.fill ||
    OptionKey.spanGaps ||
    OptionKey.segment ||
    OptionKey.hoverBorderWidth ||
    OptionKey.hoverBorderColor ||
    OptionKey.hoverBackgroundColor ||
    OptionKey.hoverBorderCapStyle ||
    OptionKey.hoverBorderDash ||
    OptionKey.hoverBorderDashOffset ||
    OptionKey.hoverBorderJoinStyle ||
    OptionKey.dollarShared ||
    OptionKey.dollarAnimations => true,
    _ => false,
  };

  @override
  Opt<Object?> classify(OptionKey key, Object? raw) => switch (key) {
    OptionKey.borderWidth => classifyNumber(raw),
    OptionKey.borderColor => classifyUnion(raw, 64),
    OptionKey.backgroundColor => classifyUnion(raw, 64),
    OptionKey.borderCapStyle => classifyString(raw),
    OptionKey.borderDash => classifyUnion(raw, 16),
    OptionKey.borderDashOffset => classifyNumber(raw),
    OptionKey.borderJoinStyle => classifyString(raw),
    OptionKey.capBezierPoints => classifyBool(raw),
    OptionKey.cubicInterpolationMode => classifyString(raw),
    OptionKey.tension => classifyNumber(raw),
    OptionKey.stepped => classifyUnion(raw, 6),
    OptionKey.fill => classifyUnion(raw, 39),
    OptionKey.spanGaps => classifyUnion(raw, 3),
    OptionKey.segment => classifyScope<SegmentOptionsScope>(raw),
    OptionKey.hoverBorderWidth => classifyNumber(raw),
    OptionKey.hoverBorderColor => classifyUnion(raw, 64),
    OptionKey.hoverBackgroundColor => classifyUnion(raw, 64),
    OptionKey.hoverBorderCapStyle => classifyString(raw),
    OptionKey.hoverBorderDash => classifyUnion(raw, 16),
    OptionKey.hoverBorderDashOffset => classifyNumber(raw),
    OptionKey.hoverBorderJoinStyle => classifyString(raw),
    OptionKey.dollarShared => classifyBool(raw),
    OptionKey.dollarAnimations => classifyUnion(raw, 64),
    _ => kind.classifyOther(raw),
  };
}

/// index.d.ts:2148 BarOptions and index.d.ts:2187 BarHoverOptions, the options
/// of a bar element.
base class BarOptionsScope extends OptionScope {
  /// An empty scope.
  BarOptionsScope();

  @override
  ScopeKind get kind => ScopeKind.barOptions;

  Opt<Object>? _borderColor;

  /// The cell of `borderColor`, or Dart `null` when absent.
  Opt<Object>? get borderColorCell => _borderColor;

  /// Stores the cell of `borderColor`. Dart `null` deletes the key.
  set borderColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.borderColor);
    } else {
      store(OptionKey.borderColor, cell);
    }
  }

  /// Stores the plain value [value] of `borderColor`.
  set borderColor(Object value) =>
      store(OptionKey.borderColor, classify(OptionKey.borderColor, value));

  Opt<Object>? _backgroundColor;

  /// The cell of `backgroundColor`, or Dart `null` when absent.
  Opt<Object>? get backgroundColorCell => _backgroundColor;

  /// Stores the cell of `backgroundColor`. Dart `null` deletes the key.
  set backgroundColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.backgroundColor);
    } else {
      store(OptionKey.backgroundColor, cell);
    }
  }

  /// Stores the plain value [value] of `backgroundColor`.
  set backgroundColor(Object value) => store(
    OptionKey.backgroundColor,
    classify(OptionKey.backgroundColor, value),
  );

  Opt<double>? _base;

  /// The cell of `base`, or Dart `null` when absent.
  Opt<double>? get baseCell => _base;

  /// Stores the cell of `base`. Dart `null` deletes the key.
  set baseCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.base);
    } else {
      store(OptionKey.base, cell);
    }
  }

  /// Stores the plain value [value] of `base`.
  set base(double value) => store(OptionKey.base, OptValue<double>(value));

  Opt<Object>? _borderSkipped;

  /// The cell of `borderSkipped`, or Dart `null` when absent.
  Opt<Object>? get borderSkippedCell => _borderSkipped;

  /// Stores the cell of `borderSkipped`. Dart `null` deletes the key.
  set borderSkippedCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.borderSkipped);
    } else {
      store(OptionKey.borderSkipped, cell);
    }
  }

  /// Stores the plain value [value] of `borderSkipped`.
  set borderSkipped(Object value) =>
      store(OptionKey.borderSkipped, classify(OptionKey.borderSkipped, value));

  Opt<Object>? _borderRadius;

  /// The cell of `borderRadius`, or Dart `null` when absent.
  Opt<Object>? get borderRadiusCell => _borderRadius;

  /// Stores the cell of `borderRadius`. Dart `null` deletes the key.
  set borderRadiusCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.borderRadius);
    } else {
      store(OptionKey.borderRadius, cell);
    }
  }

  /// Stores the plain value [value] of `borderRadius`.
  set borderRadius(Object value) =>
      store(OptionKey.borderRadius, classify(OptionKey.borderRadius, value));

  Opt<Object>? _inflateAmount;

  /// The cell of `inflateAmount`, or Dart `null` when absent.
  Opt<Object>? get inflateAmountCell => _inflateAmount;

  /// Stores the cell of `inflateAmount`. Dart `null` deletes the key.
  set inflateAmountCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.inflateAmount);
    } else {
      store(OptionKey.inflateAmount, cell);
    }
  }

  /// Stores the plain value [value] of `inflateAmount`.
  set inflateAmount(Object value) =>
      store(OptionKey.inflateAmount, classify(OptionKey.inflateAmount, value));

  Opt<Object>? _borderWidth;

  /// The cell of `borderWidth`, or Dart `null` when absent.
  Opt<Object>? get borderWidthCell => _borderWidth;

  /// Stores the cell of `borderWidth`. Dart `null` deletes the key.
  set borderWidthCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.borderWidth);
    } else {
      store(OptionKey.borderWidth, cell);
    }
  }

  /// Stores the plain value [value] of `borderWidth`.
  set borderWidth(Object value) =>
      store(OptionKey.borderWidth, classify(OptionKey.borderWidth, value));

  Opt<double>? _hoverBorderWidth;

  /// The cell of `hoverBorderWidth`, or Dart `null` when absent.
  Opt<double>? get hoverBorderWidthCell => _hoverBorderWidth;

  /// Stores the cell of `hoverBorderWidth`. Dart `null` deletes the key.
  set hoverBorderWidthCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBorderWidth);
    } else {
      store(OptionKey.hoverBorderWidth, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBorderWidth`.
  set hoverBorderWidth(double value) =>
      store(OptionKey.hoverBorderWidth, OptValue<double>(value));

  Opt<Object>? _hoverBorderColor;

  /// The cell of `hoverBorderColor`, or Dart `null` when absent.
  Opt<Object>? get hoverBorderColorCell => _hoverBorderColor;

  /// Stores the cell of `hoverBorderColor`. Dart `null` deletes the key.
  set hoverBorderColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBorderColor);
    } else {
      store(OptionKey.hoverBorderColor, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBorderColor`.
  set hoverBorderColor(Object value) => store(
    OptionKey.hoverBorderColor,
    classify(OptionKey.hoverBorderColor, value),
  );

  Opt<Object>? _hoverBackgroundColor;

  /// The cell of `hoverBackgroundColor`, or Dart `null` when absent.
  Opt<Object>? get hoverBackgroundColorCell => _hoverBackgroundColor;

  /// Stores the cell of `hoverBackgroundColor`. Dart `null` deletes the key.
  set hoverBackgroundColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBackgroundColor);
    } else {
      store(OptionKey.hoverBackgroundColor, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBackgroundColor`.
  set hoverBackgroundColor(Object value) => store(
    OptionKey.hoverBackgroundColor,
    classify(OptionKey.hoverBackgroundColor, value),
  );

  Opt<Object>? _hoverBorderRadius;

  /// The cell of `hoverBorderRadius`, or Dart `null` when absent.
  Opt<Object>? get hoverBorderRadiusCell => _hoverBorderRadius;

  /// Stores the cell of `hoverBorderRadius`. Dart `null` deletes the key.
  set hoverBorderRadiusCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBorderRadius);
    } else {
      store(OptionKey.hoverBorderRadius, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBorderRadius`.
  set hoverBorderRadius(Object value) => store(
    OptionKey.hoverBorderRadius,
    classify(OptionKey.hoverBorderRadius, value),
  );

  Opt<Object>? _pointStyle;

  /// The cell of `pointStyle`, or Dart `null` when absent.
  Opt<Object>? get pointStyleCell => _pointStyle;

  /// Stores the cell of `pointStyle`. Dart `null` deletes the key.
  set pointStyleCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.pointStyle);
    } else {
      store(OptionKey.pointStyle, cell);
    }
  }

  /// Stores the plain value [value] of `pointStyle`.
  set pointStyle(Object value) =>
      store(OptionKey.pointStyle, classify(OptionKey.pointStyle, value));

  Opt<bool>? _dollarShared;

  /// The cell of `$shared`, or Dart `null` when absent.
  Opt<bool>? get dollarSharedCell => _dollarShared;

  /// Stores the cell of `$shared`. Dart `null` deletes the key.
  set dollarSharedCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.dollarShared);
    } else {
      store(OptionKey.dollarShared, cell);
    }
  }

  /// Stores the plain value [value] of `$shared`.
  set dollarShared(bool value) =>
      store(OptionKey.dollarShared, OptValue<bool>(value));

  Opt<Object>? _dollarAnimations;

  /// The cell of `$animations`, or Dart `null` when absent.
  Opt<Object>? get dollarAnimationsCell => _dollarAnimations;

  /// Stores the cell of `$animations`. Dart `null` deletes the key.
  set dollarAnimationsCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.dollarAnimations);
    } else {
      store(OptionKey.dollarAnimations, cell);
    }
  }

  /// Stores the plain value [value] of `$animations`.
  set dollarAnimations(Object value) => store(
    OptionKey.dollarAnimations,
    classify(OptionKey.dollarAnimations, value),
  );

  @override
  Opt<Object?>? cellOf(OptionKey key) => switch (key) {
    OptionKey.borderColor => _borderColor,
    OptionKey.backgroundColor => _backgroundColor,
    OptionKey.base => _base,
    OptionKey.borderSkipped => _borderSkipped,
    OptionKey.borderRadius => _borderRadius,
    OptionKey.inflateAmount => _inflateAmount,
    OptionKey.borderWidth => _borderWidth,
    OptionKey.hoverBorderWidth => _hoverBorderWidth,
    OptionKey.hoverBorderColor => _hoverBorderColor,
    OptionKey.hoverBackgroundColor => _hoverBackgroundColor,
    OptionKey.hoverBorderRadius => _hoverBorderRadius,
    OptionKey.pointStyle => _pointStyle,
    OptionKey.dollarShared => _dollarShared,
    OptionKey.dollarAnimations => _dollarAnimations,
    _ => null,
  };

  @override
  void setCell(OptionKey key, Opt<Object?>? cell) {
    switch (key) {
      case OptionKey.borderColor:
        _borderColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.backgroundColor:
        _backgroundColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.base:
        _base = fitCell(cell, classifyNumber);
      case OptionKey.borderSkipped:
        _borderSkipped = fitCell(cell, (raw) => classifyUnion(raw, 6));
      case OptionKey.borderRadius:
        _borderRadius = fitCell(cell, (raw) => classifyUnion(raw, 33));
      case OptionKey.inflateAmount:
        _inflateAmount = fitCell(cell, (raw) => classifyUnion(raw, 5));
      case OptionKey.borderWidth:
        _borderWidth = fitCell(cell, (raw) => classifyUnion(raw, 33));
      case OptionKey.hoverBorderWidth:
        _hoverBorderWidth = fitCell(cell, classifyNumber);
      case OptionKey.hoverBorderColor:
        _hoverBorderColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.hoverBackgroundColor:
        _hoverBackgroundColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.hoverBorderRadius:
        _hoverBorderRadius = fitCell(cell, (raw) => classifyUnion(raw, 33));
      case OptionKey.pointStyle:
        _pointStyle = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.dollarShared:
        _dollarShared = fitCell(cell, classifyBool);
      case OptionKey.dollarAnimations:
        _dollarAnimations = fitCell(cell, (raw) => classifyUnion(raw, 64));
      default:
        throw ArgumentError.value(key, 'key', 'Not a key of BarOptions');
    }
  }

  @override
  bool hasField(OptionKey key) => switch (key) {
    OptionKey.borderColor ||
    OptionKey.backgroundColor ||
    OptionKey.base ||
    OptionKey.borderSkipped ||
    OptionKey.borderRadius ||
    OptionKey.inflateAmount ||
    OptionKey.borderWidth ||
    OptionKey.hoverBorderWidth ||
    OptionKey.hoverBorderColor ||
    OptionKey.hoverBackgroundColor ||
    OptionKey.hoverBorderRadius ||
    OptionKey.pointStyle ||
    OptionKey.dollarShared ||
    OptionKey.dollarAnimations => true,
    _ => false,
  };

  @override
  Opt<Object?> classify(OptionKey key, Object? raw) => switch (key) {
    OptionKey.borderColor => classifyUnion(raw, 64),
    OptionKey.backgroundColor => classifyUnion(raw, 64),
    OptionKey.base => classifyNumber(raw),
    OptionKey.borderSkipped => classifyUnion(raw, 6),
    OptionKey.borderRadius => classifyUnion(raw, 33),
    OptionKey.inflateAmount => classifyUnion(raw, 5),
    OptionKey.borderWidth => classifyUnion(raw, 33),
    OptionKey.hoverBorderWidth => classifyNumber(raw),
    OptionKey.hoverBorderColor => classifyUnion(raw, 64),
    OptionKey.hoverBackgroundColor => classifyUnion(raw, 64),
    OptionKey.hoverBorderRadius => classifyUnion(raw, 33),
    OptionKey.pointStyle => classifyUnion(raw, 64),
    OptionKey.dollarShared => classifyBool(raw),
    OptionKey.dollarAnimations => classifyUnion(raw, 64),
    _ => kind.classifyOther(raw),
  };
}

/// index.d.ts:1882 ArcOptions and index.d.ts:1944 ArcHoverOptions, the options
/// of an arc element.
base class ArcOptionsScope extends OptionScope {
  /// An empty scope.
  ArcOptionsScope();

  @override
  ScopeKind get kind => ScopeKind.arcOptions;

  Opt<double>? _borderWidth;

  /// The cell of `borderWidth`, or Dart `null` when absent.
  Opt<double>? get borderWidthCell => _borderWidth;

  /// Stores the cell of `borderWidth`. Dart `null` deletes the key.
  set borderWidthCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.borderWidth);
    } else {
      store(OptionKey.borderWidth, cell);
    }
  }

  /// Stores the plain value [value] of `borderWidth`.
  set borderWidth(double value) =>
      store(OptionKey.borderWidth, OptValue<double>(value));

  Opt<Object>? _borderColor;

  /// The cell of `borderColor`, or Dart `null` when absent.
  Opt<Object>? get borderColorCell => _borderColor;

  /// Stores the cell of `borderColor`. Dart `null` deletes the key.
  set borderColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.borderColor);
    } else {
      store(OptionKey.borderColor, cell);
    }
  }

  /// Stores the plain value [value] of `borderColor`.
  set borderColor(Object value) =>
      store(OptionKey.borderColor, classify(OptionKey.borderColor, value));

  Opt<Object>? _backgroundColor;

  /// The cell of `backgroundColor`, or Dart `null` when absent.
  Opt<Object>? get backgroundColorCell => _backgroundColor;

  /// Stores the cell of `backgroundColor`. Dart `null` deletes the key.
  set backgroundColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.backgroundColor);
    } else {
      store(OptionKey.backgroundColor, cell);
    }
  }

  /// Stores the plain value [value] of `backgroundColor`.
  set backgroundColor(Object value) => store(
    OptionKey.backgroundColor,
    classify(OptionKey.backgroundColor, value),
  );

  Opt<bool>? _selfJoin;

  /// The cell of `selfJoin`, or Dart `null` when absent.
  Opt<bool>? get selfJoinCell => _selfJoin;

  /// Stores the cell of `selfJoin`. Dart `null` deletes the key.
  set selfJoinCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.selfJoin);
    } else {
      store(OptionKey.selfJoin, cell);
    }
  }

  /// Stores the plain value [value] of `selfJoin`.
  set selfJoin(bool value) => store(OptionKey.selfJoin, OptValue<bool>(value));

  Opt<String>? _borderAlign;

  /// The cell of `borderAlign`, or Dart `null` when absent.
  Opt<String>? get borderAlignCell => _borderAlign;

  /// Stores the cell of `borderAlign`. Dart `null` deletes the key.
  set borderAlignCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.borderAlign);
    } else {
      store(OptionKey.borderAlign, cell);
    }
  }

  /// Stores the plain value [value] of `borderAlign`.
  set borderAlign(String value) =>
      store(OptionKey.borderAlign, OptValue<String>(value));

  Opt<Object>? _borderDash;

  /// The cell of `borderDash`, or Dart `null` when absent.
  Opt<Object>? get borderDashCell => _borderDash;

  /// Stores the cell of `borderDash`. Dart `null` deletes the key.
  set borderDashCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.borderDash);
    } else {
      store(OptionKey.borderDash, cell);
    }
  }

  /// Stores the plain value [value] of `borderDash`.
  set borderDash(Object value) =>
      store(OptionKey.borderDash, classify(OptionKey.borderDash, value));

  Opt<double>? _borderDashOffset;

  /// The cell of `borderDashOffset`, or Dart `null` when absent.
  Opt<double>? get borderDashOffsetCell => _borderDashOffset;

  /// Stores the cell of `borderDashOffset`. Dart `null` deletes the key.
  set borderDashOffsetCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.borderDashOffset);
    } else {
      store(OptionKey.borderDashOffset, cell);
    }
  }

  /// Stores the plain value [value] of `borderDashOffset`.
  set borderDashOffset(double value) =>
      store(OptionKey.borderDashOffset, OptValue<double>(value));

  Opt<String>? _borderJoinStyle;

  /// The cell of `borderJoinStyle`, or Dart `null` when absent.
  Opt<String>? get borderJoinStyleCell => _borderJoinStyle;

  /// Stores the cell of `borderJoinStyle`. Dart `null` deletes the key.
  set borderJoinStyleCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.borderJoinStyle);
    } else {
      store(OptionKey.borderJoinStyle, cell);
    }
  }

  /// Stores the plain value [value] of `borderJoinStyle`.
  set borderJoinStyle(String value) =>
      store(OptionKey.borderJoinStyle, OptValue<String>(value));

  Opt<Object>? _borderRadius;

  /// The cell of `borderRadius`, or Dart `null` when absent.
  Opt<Object>? get borderRadiusCell => _borderRadius;

  /// Stores the cell of `borderRadius`. Dart `null` deletes the key.
  set borderRadiusCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.borderRadius);
    } else {
      store(OptionKey.borderRadius, cell);
    }
  }

  /// Stores the plain value [value] of `borderRadius`.
  set borderRadius(Object value) =>
      store(OptionKey.borderRadius, classify(OptionKey.borderRadius, value));

  Opt<double>? _offset;

  /// The cell of `offset`, or Dart `null` when absent.
  Opt<double>? get offsetCell => _offset;

  /// Stores the cell of `offset`. Dart `null` deletes the key.
  set offsetCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.offset);
    } else {
      store(OptionKey.offset, cell);
    }
  }

  /// Stores the plain value [value] of `offset`.
  set offset(double value) => store(OptionKey.offset, OptValue<double>(value));

  Opt<bool>? _circular;

  /// The cell of `circular`, or Dart `null` when absent.
  Opt<bool>? get circularCell => _circular;

  /// Stores the cell of `circular`. Dart `null` deletes the key.
  set circularCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.circular);
    } else {
      store(OptionKey.circular, cell);
    }
  }

  /// Stores the plain value [value] of `circular`.
  set circular(bool value) => store(OptionKey.circular, OptValue<bool>(value));

  Opt<double>? _spacing;

  /// The cell of `spacing`, or Dart `null` when absent.
  Opt<double>? get spacingCell => _spacing;

  /// Stores the cell of `spacing`. Dart `null` deletes the key.
  set spacingCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.spacing);
    } else {
      store(OptionKey.spacing, cell);
    }
  }

  /// Stores the plain value [value] of `spacing`.
  set spacing(double value) =>
      store(OptionKey.spacing, OptValue<double>(value));

  Opt<String>? _spacingMode;

  /// The cell of `spacingMode`, or Dart `null` when absent.
  Opt<String>? get spacingModeCell => _spacingMode;

  /// Stores the cell of `spacingMode`. Dart `null` deletes the key.
  set spacingModeCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.spacingMode);
    } else {
      store(OptionKey.spacingMode, cell);
    }
  }

  /// Stores the plain value [value] of `spacingMode`.
  set spacingMode(String value) =>
      store(OptionKey.spacingMode, OptValue<String>(value));

  Opt<double>? _hoverBorderWidth;

  /// The cell of `hoverBorderWidth`, or Dart `null` when absent.
  Opt<double>? get hoverBorderWidthCell => _hoverBorderWidth;

  /// Stores the cell of `hoverBorderWidth`. Dart `null` deletes the key.
  set hoverBorderWidthCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBorderWidth);
    } else {
      store(OptionKey.hoverBorderWidth, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBorderWidth`.
  set hoverBorderWidth(double value) =>
      store(OptionKey.hoverBorderWidth, OptValue<double>(value));

  Opt<Object>? _hoverBorderColor;

  /// The cell of `hoverBorderColor`, or Dart `null` when absent.
  Opt<Object>? get hoverBorderColorCell => _hoverBorderColor;

  /// Stores the cell of `hoverBorderColor`. Dart `null` deletes the key.
  set hoverBorderColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBorderColor);
    } else {
      store(OptionKey.hoverBorderColor, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBorderColor`.
  set hoverBorderColor(Object value) => store(
    OptionKey.hoverBorderColor,
    classify(OptionKey.hoverBorderColor, value),
  );

  Opt<Object>? _hoverBackgroundColor;

  /// The cell of `hoverBackgroundColor`, or Dart `null` when absent.
  Opt<Object>? get hoverBackgroundColorCell => _hoverBackgroundColor;

  /// Stores the cell of `hoverBackgroundColor`. Dart `null` deletes the key.
  set hoverBackgroundColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBackgroundColor);
    } else {
      store(OptionKey.hoverBackgroundColor, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBackgroundColor`.
  set hoverBackgroundColor(Object value) => store(
    OptionKey.hoverBackgroundColor,
    classify(OptionKey.hoverBackgroundColor, value),
  );

  Opt<Object>? _hoverBorderDash;

  /// The cell of `hoverBorderDash`, or Dart `null` when absent.
  Opt<Object>? get hoverBorderDashCell => _hoverBorderDash;

  /// Stores the cell of `hoverBorderDash`. Dart `null` deletes the key.
  set hoverBorderDashCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBorderDash);
    } else {
      store(OptionKey.hoverBorderDash, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBorderDash`.
  set hoverBorderDash(Object value) => store(
    OptionKey.hoverBorderDash,
    classify(OptionKey.hoverBorderDash, value),
  );

  Opt<double>? _hoverBorderDashOffset;

  /// The cell of `hoverBorderDashOffset`, or Dart `null` when absent.
  Opt<double>? get hoverBorderDashOffsetCell => _hoverBorderDashOffset;

  /// Stores the cell of `hoverBorderDashOffset`. Dart `null` deletes the key.
  set hoverBorderDashOffsetCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBorderDashOffset);
    } else {
      store(OptionKey.hoverBorderDashOffset, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBorderDashOffset`.
  set hoverBorderDashOffset(double value) =>
      store(OptionKey.hoverBorderDashOffset, OptValue<double>(value));

  Opt<double>? _hoverOffset;

  /// The cell of `hoverOffset`, or Dart `null` when absent.
  Opt<double>? get hoverOffsetCell => _hoverOffset;

  /// Stores the cell of `hoverOffset`. Dart `null` deletes the key.
  set hoverOffsetCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverOffset);
    } else {
      store(OptionKey.hoverOffset, cell);
    }
  }

  /// Stores the plain value [value] of `hoverOffset`.
  set hoverOffset(double value) =>
      store(OptionKey.hoverOffset, OptValue<double>(value));

  Opt<double>? _angle;

  /// The cell of `angle`, or Dart `null` when absent.
  Opt<double>? get angleCell => _angle;

  /// Stores the cell of `angle`. Dart `null` deletes the key.
  set angleCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.angle);
    } else {
      store(OptionKey.angle, cell);
    }
  }

  /// Stores the plain value [value] of `angle`.
  set angle(double value) => store(OptionKey.angle, OptValue<double>(value));

  Opt<bool>? _dollarShared;

  /// The cell of `$shared`, or Dart `null` when absent.
  Opt<bool>? get dollarSharedCell => _dollarShared;

  /// Stores the cell of `$shared`. Dart `null` deletes the key.
  set dollarSharedCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.dollarShared);
    } else {
      store(OptionKey.dollarShared, cell);
    }
  }

  /// Stores the plain value [value] of `$shared`.
  set dollarShared(bool value) =>
      store(OptionKey.dollarShared, OptValue<bool>(value));

  Opt<Object>? _dollarAnimations;

  /// The cell of `$animations`, or Dart `null` when absent.
  Opt<Object>? get dollarAnimationsCell => _dollarAnimations;

  /// Stores the cell of `$animations`. Dart `null` deletes the key.
  set dollarAnimationsCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.dollarAnimations);
    } else {
      store(OptionKey.dollarAnimations, cell);
    }
  }

  /// Stores the plain value [value] of `$animations`.
  set dollarAnimations(Object value) => store(
    OptionKey.dollarAnimations,
    classify(OptionKey.dollarAnimations, value),
  );

  @override
  Opt<Object?>? cellOf(OptionKey key) => switch (key) {
    OptionKey.borderWidth => _borderWidth,
    OptionKey.borderColor => _borderColor,
    OptionKey.backgroundColor => _backgroundColor,
    OptionKey.selfJoin => _selfJoin,
    OptionKey.borderAlign => _borderAlign,
    OptionKey.borderDash => _borderDash,
    OptionKey.borderDashOffset => _borderDashOffset,
    OptionKey.borderJoinStyle => _borderJoinStyle,
    OptionKey.borderRadius => _borderRadius,
    OptionKey.offset => _offset,
    OptionKey.circular => _circular,
    OptionKey.spacing => _spacing,
    OptionKey.spacingMode => _spacingMode,
    OptionKey.hoverBorderWidth => _hoverBorderWidth,
    OptionKey.hoverBorderColor => _hoverBorderColor,
    OptionKey.hoverBackgroundColor => _hoverBackgroundColor,
    OptionKey.hoverBorderDash => _hoverBorderDash,
    OptionKey.hoverBorderDashOffset => _hoverBorderDashOffset,
    OptionKey.hoverOffset => _hoverOffset,
    OptionKey.angle => _angle,
    OptionKey.dollarShared => _dollarShared,
    OptionKey.dollarAnimations => _dollarAnimations,
    _ => null,
  };

  @override
  void setCell(OptionKey key, Opt<Object?>? cell) {
    switch (key) {
      case OptionKey.borderWidth:
        _borderWidth = fitCell(cell, classifyNumber);
      case OptionKey.borderColor:
        _borderColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.backgroundColor:
        _backgroundColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.selfJoin:
        _selfJoin = fitCell(cell, classifyBool);
      case OptionKey.borderAlign:
        _borderAlign = fitCell(cell, classifyString);
      case OptionKey.borderDash:
        _borderDash = fitCell(cell, (raw) => classifyUnion(raw, 16));
      case OptionKey.borderDashOffset:
        _borderDashOffset = fitCell(cell, classifyNumber);
      case OptionKey.borderJoinStyle:
        _borderJoinStyle = fitCell(cell, classifyString);
      case OptionKey.borderRadius:
        _borderRadius = fitCell(cell, (raw) => classifyUnion(raw, 33));
      case OptionKey.offset:
        _offset = fitCell(cell, classifyNumber);
      case OptionKey.circular:
        _circular = fitCell(cell, classifyBool);
      case OptionKey.spacing:
        _spacing = fitCell(cell, classifyNumber);
      case OptionKey.spacingMode:
        _spacingMode = fitCell(cell, classifyString);
      case OptionKey.hoverBorderWidth:
        _hoverBorderWidth = fitCell(cell, classifyNumber);
      case OptionKey.hoverBorderColor:
        _hoverBorderColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.hoverBackgroundColor:
        _hoverBackgroundColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.hoverBorderDash:
        _hoverBorderDash = fitCell(cell, (raw) => classifyUnion(raw, 16));
      case OptionKey.hoverBorderDashOffset:
        _hoverBorderDashOffset = fitCell(cell, classifyNumber);
      case OptionKey.hoverOffset:
        _hoverOffset = fitCell(cell, classifyNumber);
      case OptionKey.angle:
        _angle = fitCell(cell, classifyNumber);
      case OptionKey.dollarShared:
        _dollarShared = fitCell(cell, classifyBool);
      case OptionKey.dollarAnimations:
        _dollarAnimations = fitCell(cell, (raw) => classifyUnion(raw, 64));
      default:
        throw ArgumentError.value(key, 'key', 'Not a key of ArcOptions');
    }
  }

  @override
  bool hasField(OptionKey key) => switch (key) {
    OptionKey.borderWidth ||
    OptionKey.borderColor ||
    OptionKey.backgroundColor ||
    OptionKey.selfJoin ||
    OptionKey.borderAlign ||
    OptionKey.borderDash ||
    OptionKey.borderDashOffset ||
    OptionKey.borderJoinStyle ||
    OptionKey.borderRadius ||
    OptionKey.offset ||
    OptionKey.circular ||
    OptionKey.spacing ||
    OptionKey.spacingMode ||
    OptionKey.hoverBorderWidth ||
    OptionKey.hoverBorderColor ||
    OptionKey.hoverBackgroundColor ||
    OptionKey.hoverBorderDash ||
    OptionKey.hoverBorderDashOffset ||
    OptionKey.hoverOffset ||
    OptionKey.angle ||
    OptionKey.dollarShared ||
    OptionKey.dollarAnimations => true,
    _ => false,
  };

  @override
  Opt<Object?> classify(OptionKey key, Object? raw) => switch (key) {
    OptionKey.borderWidth => classifyNumber(raw),
    OptionKey.borderColor => classifyUnion(raw, 64),
    OptionKey.backgroundColor => classifyUnion(raw, 64),
    OptionKey.selfJoin => classifyBool(raw),
    OptionKey.borderAlign => classifyString(raw),
    OptionKey.borderDash => classifyUnion(raw, 16),
    OptionKey.borderDashOffset => classifyNumber(raw),
    OptionKey.borderJoinStyle => classifyString(raw),
    OptionKey.borderRadius => classifyUnion(raw, 33),
    OptionKey.offset => classifyNumber(raw),
    OptionKey.circular => classifyBool(raw),
    OptionKey.spacing => classifyNumber(raw),
    OptionKey.spacingMode => classifyString(raw),
    OptionKey.hoverBorderWidth => classifyNumber(raw),
    OptionKey.hoverBorderColor => classifyUnion(raw, 64),
    OptionKey.hoverBackgroundColor => classifyUnion(raw, 64),
    OptionKey.hoverBorderDash => classifyUnion(raw, 16),
    OptionKey.hoverBorderDashOffset => classifyNumber(raw),
    OptionKey.hoverOffset => classifyNumber(raw),
    OptionKey.angle => classifyNumber(raw),
    OptionKey.dollarShared => classifyBool(raw),
    OptionKey.dollarAnimations => classifyUnion(raw, 64),
    _ => kind.classifyOther(raw),
  };
}

/// Port-only kind (Chart.js ADR 0021 section 2), the options of a custom
/// element type or of an element subclass with its own id.
base class GenericElementOptionsScope extends OptionScope {
  /// An empty scope.
  GenericElementOptionsScope();

  @override
  ScopeKind get kind => ScopeKind.genericElementOptions;

  @override
  Opt<Object?>? cellOf(OptionKey key) => null;

  @override
  void setCell(OptionKey key, Opt<Object?>? cell) {
    throw ArgumentError.value(key, 'key', 'Not a key of GenericElementOptions');
  }

  @override
  bool hasField(OptionKey key) => false;

  @override
  Opt<Object?> classify(OptionKey key, Object? raw) => kind.classifyOther(raw);
}

/// Port-only kind for index.d.ts:2180 BorderRadius (bar) and index.d.ts:1873
/// ArcBorderRadius (arc), the radius of each corner.
base class BorderRadiusScope extends OptionScope {
  /// An empty scope.
  BorderRadiusScope();

  @override
  ScopeKind get kind => ScopeKind.borderRadius;

  Opt<double>? _topLeft;

  /// The cell of `topLeft`, or Dart `null` when absent.
  Opt<double>? get topLeftCell => _topLeft;

  /// Stores the cell of `topLeft`. Dart `null` deletes the key.
  set topLeftCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.topLeft);
    } else {
      store(OptionKey.topLeft, cell);
    }
  }

  /// Stores the plain value [value] of `topLeft`.
  set topLeft(double value) =>
      store(OptionKey.topLeft, OptValue<double>(value));

  Opt<double>? _topRight;

  /// The cell of `topRight`, or Dart `null` when absent.
  Opt<double>? get topRightCell => _topRight;

  /// Stores the cell of `topRight`. Dart `null` deletes the key.
  set topRightCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.topRight);
    } else {
      store(OptionKey.topRight, cell);
    }
  }

  /// Stores the plain value [value] of `topRight`.
  set topRight(double value) =>
      store(OptionKey.topRight, OptValue<double>(value));

  Opt<double>? _bottomLeft;

  /// The cell of `bottomLeft`, or Dart `null` when absent.
  Opt<double>? get bottomLeftCell => _bottomLeft;

  /// Stores the cell of `bottomLeft`. Dart `null` deletes the key.
  set bottomLeftCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.bottomLeft);
    } else {
      store(OptionKey.bottomLeft, cell);
    }
  }

  /// Stores the plain value [value] of `bottomLeft`.
  set bottomLeft(double value) =>
      store(OptionKey.bottomLeft, OptValue<double>(value));

  Opt<double>? _bottomRight;

  /// The cell of `bottomRight`, or Dart `null` when absent.
  Opt<double>? get bottomRightCell => _bottomRight;

  /// Stores the cell of `bottomRight`. Dart `null` deletes the key.
  set bottomRightCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.bottomRight);
    } else {
      store(OptionKey.bottomRight, cell);
    }
  }

  /// Stores the plain value [value] of `bottomRight`.
  set bottomRight(double value) =>
      store(OptionKey.bottomRight, OptValue<double>(value));

  Opt<double>? _outerStart;

  /// The cell of `outerStart`, or Dart `null` when absent.
  Opt<double>? get outerStartCell => _outerStart;

  /// Stores the cell of `outerStart`. Dart `null` deletes the key.
  set outerStartCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.outerStart);
    } else {
      store(OptionKey.outerStart, cell);
    }
  }

  /// Stores the plain value [value] of `outerStart`.
  set outerStart(double value) =>
      store(OptionKey.outerStart, OptValue<double>(value));

  Opt<double>? _outerEnd;

  /// The cell of `outerEnd`, or Dart `null` when absent.
  Opt<double>? get outerEndCell => _outerEnd;

  /// Stores the cell of `outerEnd`. Dart `null` deletes the key.
  set outerEndCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.outerEnd);
    } else {
      store(OptionKey.outerEnd, cell);
    }
  }

  /// Stores the plain value [value] of `outerEnd`.
  set outerEnd(double value) =>
      store(OptionKey.outerEnd, OptValue<double>(value));

  Opt<double>? _innerStart;

  /// The cell of `innerStart`, or Dart `null` when absent.
  Opt<double>? get innerStartCell => _innerStart;

  /// Stores the cell of `innerStart`. Dart `null` deletes the key.
  set innerStartCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.innerStart);
    } else {
      store(OptionKey.innerStart, cell);
    }
  }

  /// Stores the plain value [value] of `innerStart`.
  set innerStart(double value) =>
      store(OptionKey.innerStart, OptValue<double>(value));

  Opt<double>? _innerEnd;

  /// The cell of `innerEnd`, or Dart `null` when absent.
  Opt<double>? get innerEndCell => _innerEnd;

  /// Stores the cell of `innerEnd`. Dart `null` deletes the key.
  set innerEndCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.innerEnd);
    } else {
      store(OptionKey.innerEnd, cell);
    }
  }

  /// Stores the plain value [value] of `innerEnd`.
  set innerEnd(double value) =>
      store(OptionKey.innerEnd, OptValue<double>(value));

  @override
  Opt<Object?>? cellOf(OptionKey key) => switch (key) {
    OptionKey.topLeft => _topLeft,
    OptionKey.topRight => _topRight,
    OptionKey.bottomLeft => _bottomLeft,
    OptionKey.bottomRight => _bottomRight,
    OptionKey.outerStart => _outerStart,
    OptionKey.outerEnd => _outerEnd,
    OptionKey.innerStart => _innerStart,
    OptionKey.innerEnd => _innerEnd,
    _ => null,
  };

  @override
  void setCell(OptionKey key, Opt<Object?>? cell) {
    switch (key) {
      case OptionKey.topLeft:
        _topLeft = fitCell(cell, classifyNumber);
      case OptionKey.topRight:
        _topRight = fitCell(cell, classifyNumber);
      case OptionKey.bottomLeft:
        _bottomLeft = fitCell(cell, classifyNumber);
      case OptionKey.bottomRight:
        _bottomRight = fitCell(cell, classifyNumber);
      case OptionKey.outerStart:
        _outerStart = fitCell(cell, classifyNumber);
      case OptionKey.outerEnd:
        _outerEnd = fitCell(cell, classifyNumber);
      case OptionKey.innerStart:
        _innerStart = fitCell(cell, classifyNumber);
      case OptionKey.innerEnd:
        _innerEnd = fitCell(cell, classifyNumber);
      default:
        throw ArgumentError.value(key, 'key', 'Not a key of BorderRadius');
    }
  }

  @override
  bool hasField(OptionKey key) => switch (key) {
    OptionKey.topLeft ||
    OptionKey.topRight ||
    OptionKey.bottomLeft ||
    OptionKey.bottomRight ||
    OptionKey.outerStart ||
    OptionKey.outerEnd ||
    OptionKey.innerStart ||
    OptionKey.innerEnd => true,
    _ => false,
  };

  @override
  Opt<Object?> classify(OptionKey key, Object? raw) => switch (key) {
    OptionKey.topLeft => classifyNumber(raw),
    OptionKey.topRight => classifyNumber(raw),
    OptionKey.bottomLeft => classifyNumber(raw),
    OptionKey.bottomRight => classifyNumber(raw),
    OptionKey.outerStart => classifyNumber(raw),
    OptionKey.outerEnd => classifyNumber(raw),
    OptionKey.innerStart => classifyNumber(raw),
    OptionKey.innerEnd => classifyNumber(raw),
    _ => kind.classifyOther(raw),
  };
}

/// index.d.ts:2302 ComplexFillTarget and the object `{value}` of
/// index.d.ts:2300 FillTarget, the object form of `fill`.
base class FillTargetScope extends OptionScope {
  /// An empty scope.
  FillTargetScope();

  @override
  ScopeKind get kind => ScopeKind.fillTarget;

  Opt<Object>? _target;

  /// The cell of `target`, or Dart `null` when absent.
  Opt<Object>? get targetCell => _target;

  /// Stores the cell of `target`. Dart `null` deletes the key.
  set targetCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.target);
    } else {
      store(OptionKey.target, cell);
    }
  }

  /// Stores the plain value [value] of `target`.
  set target(Object value) =>
      store(OptionKey.target, classify(OptionKey.target, value));

  Opt<Object>? _above;

  /// The cell of `above`, or Dart `null` when absent.
  Opt<Object>? get aboveCell => _above;

  /// Stores the cell of `above`. Dart `null` deletes the key.
  set aboveCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.above);
    } else {
      store(OptionKey.above, cell);
    }
  }

  /// Stores the plain value [value] of `above`.
  set above(Object value) =>
      store(OptionKey.above, classify(OptionKey.above, value));

  Opt<Object>? _below;

  /// The cell of `below`, or Dart `null` when absent.
  Opt<Object>? get belowCell => _below;

  /// Stores the cell of `below`. Dart `null` deletes the key.
  set belowCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.below);
    } else {
      store(OptionKey.below, cell);
    }
  }

  /// Stores the plain value [value] of `below`.
  set below(Object value) =>
      store(OptionKey.below, classify(OptionKey.below, value));

  Opt<double>? _value;

  /// The cell of `value`, or Dart `null` when absent.
  Opt<double>? get valueCell => _value;

  /// Stores the cell of `value`. Dart `null` deletes the key.
  set valueCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.value);
    } else {
      store(OptionKey.value, cell);
    }
  }

  /// Stores the plain value [value] of `value`.
  set value(double value) => store(OptionKey.value, OptValue<double>(value));

  @override
  Opt<Object?>? cellOf(OptionKey key) => switch (key) {
    OptionKey.target => _target,
    OptionKey.above => _above,
    OptionKey.below => _below,
    OptionKey.value => _value,
    _ => null,
  };

  @override
  void setCell(OptionKey key, Opt<Object?>? cell) {
    switch (key) {
      case OptionKey.target:
        _target = fitCell(cell, (raw) => classifyUnion(raw, 39));
      case OptionKey.above:
        _above = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.below:
        _below = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.value:
        _value = fitCell(cell, classifyNumber);
      default:
        throw ArgumentError.value(key, 'key', 'Not a key of FillTarget');
    }
  }

  @override
  bool hasField(OptionKey key) => switch (key) {
    OptionKey.target ||
    OptionKey.above ||
    OptionKey.below ||
    OptionKey.value => true,
    _ => false,
  };

  @override
  Opt<Object?> classify(OptionKey key, Object? raw) => switch (key) {
    OptionKey.target => classifyUnion(raw, 39),
    OptionKey.above => classifyUnion(raw, 64),
    OptionKey.below => classifyUnion(raw, 64),
    OptionKey.value => classifyNumber(raw),
    _ => kind.classifyOther(raw),
  };
}

/// Port-only name for index.d.ts:2004 LineOptions `segment`, the scriptable
/// styles of a line segment.
base class SegmentOptionsScope extends OptionScope {
  /// An empty scope.
  SegmentOptionsScope();

  @override
  ScopeKind get kind => ScopeKind.segmentOptions;

  Opt<Object>? _backgroundColor;

  /// The cell of `backgroundColor`, or Dart `null` when absent.
  Opt<Object>? get backgroundColorCell => _backgroundColor;

  /// Stores the cell of `backgroundColor`. Dart `null` deletes the key.
  set backgroundColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.backgroundColor);
    } else {
      store(OptionKey.backgroundColor, cell);
    }
  }

  /// Stores the plain value [value] of `backgroundColor`.
  set backgroundColor(Object value) => store(
    OptionKey.backgroundColor,
    classify(OptionKey.backgroundColor, value),
  );

  Opt<Object>? _borderColor;

  /// The cell of `borderColor`, or Dart `null` when absent.
  Opt<Object>? get borderColorCell => _borderColor;

  /// Stores the cell of `borderColor`. Dart `null` deletes the key.
  set borderColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.borderColor);
    } else {
      store(OptionKey.borderColor, cell);
    }
  }

  /// Stores the plain value [value] of `borderColor`.
  set borderColor(Object value) =>
      store(OptionKey.borderColor, classify(OptionKey.borderColor, value));

  Opt<String>? _borderCapStyle;

  /// The cell of `borderCapStyle`, or Dart `null` when absent.
  Opt<String>? get borderCapStyleCell => _borderCapStyle;

  /// Stores the cell of `borderCapStyle`. Dart `null` deletes the key.
  set borderCapStyleCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.borderCapStyle);
    } else {
      store(OptionKey.borderCapStyle, cell);
    }
  }

  /// Stores the plain value [value] of `borderCapStyle`.
  set borderCapStyle(String value) =>
      store(OptionKey.borderCapStyle, OptValue<String>(value));

  Opt<Object>? _borderDash;

  /// The cell of `borderDash`, or Dart `null` when absent.
  Opt<Object>? get borderDashCell => _borderDash;

  /// Stores the cell of `borderDash`. Dart `null` deletes the key.
  set borderDashCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.borderDash);
    } else {
      store(OptionKey.borderDash, cell);
    }
  }

  /// Stores the plain value [value] of `borderDash`.
  set borderDash(Object value) =>
      store(OptionKey.borderDash, classify(OptionKey.borderDash, value));

  Opt<double>? _borderDashOffset;

  /// The cell of `borderDashOffset`, or Dart `null` when absent.
  Opt<double>? get borderDashOffsetCell => _borderDashOffset;

  /// Stores the cell of `borderDashOffset`. Dart `null` deletes the key.
  set borderDashOffsetCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.borderDashOffset);
    } else {
      store(OptionKey.borderDashOffset, cell);
    }
  }

  /// Stores the plain value [value] of `borderDashOffset`.
  set borderDashOffset(double value) =>
      store(OptionKey.borderDashOffset, OptValue<double>(value));

  Opt<String>? _borderJoinStyle;

  /// The cell of `borderJoinStyle`, or Dart `null` when absent.
  Opt<String>? get borderJoinStyleCell => _borderJoinStyle;

  /// Stores the cell of `borderJoinStyle`. Dart `null` deletes the key.
  set borderJoinStyleCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.borderJoinStyle);
    } else {
      store(OptionKey.borderJoinStyle, cell);
    }
  }

  /// Stores the plain value [value] of `borderJoinStyle`.
  set borderJoinStyle(String value) =>
      store(OptionKey.borderJoinStyle, OptValue<String>(value));

  Opt<double>? _borderWidth;

  /// The cell of `borderWidth`, or Dart `null` when absent.
  Opt<double>? get borderWidthCell => _borderWidth;

  /// Stores the cell of `borderWidth`. Dart `null` deletes the key.
  set borderWidthCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.borderWidth);
    } else {
      store(OptionKey.borderWidth, cell);
    }
  }

  /// Stores the plain value [value] of `borderWidth`.
  set borderWidth(double value) =>
      store(OptionKey.borderWidth, OptValue<double>(value));

  @override
  Opt<Object?>? cellOf(OptionKey key) => switch (key) {
    OptionKey.backgroundColor => _backgroundColor,
    OptionKey.borderColor => _borderColor,
    OptionKey.borderCapStyle => _borderCapStyle,
    OptionKey.borderDash => _borderDash,
    OptionKey.borderDashOffset => _borderDashOffset,
    OptionKey.borderJoinStyle => _borderJoinStyle,
    OptionKey.borderWidth => _borderWidth,
    _ => null,
  };

  @override
  void setCell(OptionKey key, Opt<Object?>? cell) {
    switch (key) {
      case OptionKey.backgroundColor:
        _backgroundColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.borderColor:
        _borderColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.borderCapStyle:
        _borderCapStyle = fitCell(cell, classifyString);
      case OptionKey.borderDash:
        _borderDash = fitCell(cell, (raw) => classifyUnion(raw, 16));
      case OptionKey.borderDashOffset:
        _borderDashOffset = fitCell(cell, classifyNumber);
      case OptionKey.borderJoinStyle:
        _borderJoinStyle = fitCell(cell, classifyString);
      case OptionKey.borderWidth:
        _borderWidth = fitCell(cell, classifyNumber);
      default:
        throw ArgumentError.value(key, 'key', 'Not a key of SegmentOptions');
    }
  }

  @override
  bool hasField(OptionKey key) => switch (key) {
    OptionKey.backgroundColor ||
    OptionKey.borderColor ||
    OptionKey.borderCapStyle ||
    OptionKey.borderDash ||
    OptionKey.borderDashOffset ||
    OptionKey.borderJoinStyle ||
    OptionKey.borderWidth => true,
    _ => false,
  };

  @override
  Opt<Object?> classify(OptionKey key, Object? raw) => switch (key) {
    OptionKey.backgroundColor => classifyUnion(raw, 64),
    OptionKey.borderColor => classifyUnion(raw, 64),
    OptionKey.borderCapStyle => classifyString(raw),
    OptionKey.borderDash => classifyUnion(raw, 16),
    OptionKey.borderDashOffset => classifyNumber(raw),
    OptionKey.borderJoinStyle => classifyString(raw),
    OptionKey.borderWidth => classifyNumber(raw),
    _ => kind.classifyOther(raw),
  };
}

/// index.d.ts:96 BarControllerDatasetOptions (index.d.ts:66
/// ControllerDatasetOptions, BarOptions, CommonHoverOptions, AnimationOptions)
/// with index.d.ts:149 BarControllerChartOptions, a bar dataset and
/// `datasets.bar`.
base class BarControllerDatasetOptionsScope extends OptionScope {
  /// An empty scope.
  BarControllerDatasetOptionsScope();

  @override
  ScopeKind get kind => ScopeKind.barControllerDatasetOptions;

  Opt<Object>? _parsing;

  /// The cell of `parsing`, or Dart `null` when absent.
  Opt<Object>? get parsingCell => _parsing;

  /// Stores the cell of `parsing`. Dart `null` deletes the key.
  set parsingCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.parsing);
    } else {
      store(OptionKey.parsing, cell);
    }
  }

  /// Stores the plain value [value] of `parsing`.
  set parsing(Object value) =>
      store(OptionKey.parsing, classify(OptionKey.parsing, value));

  Opt<bool>? _normalized;

  /// The cell of `normalized`, or Dart `null` when absent.
  Opt<bool>? get normalizedCell => _normalized;

  /// Stores the cell of `normalized`. Dart `null` deletes the key.
  set normalizedCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.normalized);
    } else {
      store(OptionKey.normalized, cell);
    }
  }

  /// Stores the plain value [value] of `normalized`.
  set normalized(bool value) =>
      store(OptionKey.normalized, OptValue<bool>(value));

  Opt<String>? _indexAxis;

  /// The cell of `indexAxis`, or Dart `null` when absent.
  Opt<String>? get indexAxisCell => _indexAxis;

  /// Stores the cell of `indexAxis`. Dart `null` deletes the key.
  set indexAxisCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.indexAxis);
    } else {
      store(OptionKey.indexAxis, cell);
    }
  }

  /// Stores the plain value [value] of `indexAxis`.
  set indexAxis(String value) =>
      store(OptionKey.indexAxis, OptValue<String>(value));

  Opt<Object>? _clip;

  /// The cell of `clip`, or Dart `null` when absent.
  Opt<Object>? get clipCell => _clip;

  /// Stores the cell of `clip`. Dart `null` deletes the key.
  set clipCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.clip);
    } else {
      store(OptionKey.clip, cell);
    }
  }

  /// Stores the plain value [value] of `clip`.
  set clip(Object value) =>
      store(OptionKey.clip, classify(OptionKey.clip, value));

  Opt<String>? _label;

  /// The cell of `label`, or Dart `null` when absent.
  Opt<String>? get labelCell => _label;

  /// Stores the cell of `label`. Dart `null` deletes the key.
  set labelCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.label);
    } else {
      store(OptionKey.label, cell);
    }
  }

  /// Stores the plain value [value] of `label`.
  set label(String value) => store(OptionKey.label, OptValue<String>(value));

  Opt<double>? _order;

  /// The cell of `order`, or Dart `null` when absent.
  Opt<double>? get orderCell => _order;

  /// Stores the cell of `order`. Dart `null` deletes the key.
  set orderCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.order);
    } else {
      store(OptionKey.order, cell);
    }
  }

  /// Stores the plain value [value] of `order`.
  set order(double value) => store(OptionKey.order, OptValue<double>(value));

  Opt<String>? _stack;

  /// The cell of `stack`, or Dart `null` when absent.
  Opt<String>? get stackCell => _stack;

  /// Stores the cell of `stack`. Dart `null` deletes the key.
  set stackCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.stack);
    } else {
      store(OptionKey.stack, cell);
    }
  }

  /// Stores the plain value [value] of `stack`.
  set stack(String value) => store(OptionKey.stack, OptValue<String>(value));

  Opt<bool>? _hidden;

  /// The cell of `hidden`, or Dart `null` when absent.
  Opt<bool>? get hiddenCell => _hidden;

  /// Stores the cell of `hidden`. Dart `null` deletes the key.
  set hiddenCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.hidden);
    } else {
      store(OptionKey.hidden, cell);
    }
  }

  /// Stores the plain value [value] of `hidden`.
  set hidden(bool value) => store(OptionKey.hidden, OptValue<bool>(value));

  Opt<Object>? _borderColor;

  /// The cell of `borderColor`, or Dart `null` when absent.
  Opt<Object>? get borderColorCell => _borderColor;

  /// Stores the cell of `borderColor`. Dart `null` deletes the key.
  set borderColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.borderColor);
    } else {
      store(OptionKey.borderColor, cell);
    }
  }

  /// Stores the plain value [value] of `borderColor`.
  set borderColor(Object value) =>
      store(OptionKey.borderColor, classify(OptionKey.borderColor, value));

  Opt<Object>? _backgroundColor;

  /// The cell of `backgroundColor`, or Dart `null` when absent.
  Opt<Object>? get backgroundColorCell => _backgroundColor;

  /// Stores the cell of `backgroundColor`. Dart `null` deletes the key.
  set backgroundColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.backgroundColor);
    } else {
      store(OptionKey.backgroundColor, cell);
    }
  }

  /// Stores the plain value [value] of `backgroundColor`.
  set backgroundColor(Object value) => store(
    OptionKey.backgroundColor,
    classify(OptionKey.backgroundColor, value),
  );

  Opt<double>? _base;

  /// The cell of `base`, or Dart `null` when absent.
  Opt<double>? get baseCell => _base;

  /// Stores the cell of `base`. Dart `null` deletes the key.
  set baseCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.base);
    } else {
      store(OptionKey.base, cell);
    }
  }

  /// Stores the plain value [value] of `base`.
  set base(double value) => store(OptionKey.base, OptValue<double>(value));

  Opt<Object>? _borderSkipped;

  /// The cell of `borderSkipped`, or Dart `null` when absent.
  Opt<Object>? get borderSkippedCell => _borderSkipped;

  /// Stores the cell of `borderSkipped`. Dart `null` deletes the key.
  set borderSkippedCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.borderSkipped);
    } else {
      store(OptionKey.borderSkipped, cell);
    }
  }

  /// Stores the plain value [value] of `borderSkipped`.
  set borderSkipped(Object value) =>
      store(OptionKey.borderSkipped, classify(OptionKey.borderSkipped, value));

  Opt<Object>? _borderRadius;

  /// The cell of `borderRadius`, or Dart `null` when absent.
  Opt<Object>? get borderRadiusCell => _borderRadius;

  /// Stores the cell of `borderRadius`. Dart `null` deletes the key.
  set borderRadiusCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.borderRadius);
    } else {
      store(OptionKey.borderRadius, cell);
    }
  }

  /// Stores the plain value [value] of `borderRadius`.
  set borderRadius(Object value) =>
      store(OptionKey.borderRadius, classify(OptionKey.borderRadius, value));

  Opt<Object>? _inflateAmount;

  /// The cell of `inflateAmount`, or Dart `null` when absent.
  Opt<Object>? get inflateAmountCell => _inflateAmount;

  /// Stores the cell of `inflateAmount`. Dart `null` deletes the key.
  set inflateAmountCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.inflateAmount);
    } else {
      store(OptionKey.inflateAmount, cell);
    }
  }

  /// Stores the plain value [value] of `inflateAmount`.
  set inflateAmount(Object value) =>
      store(OptionKey.inflateAmount, classify(OptionKey.inflateAmount, value));

  Opt<Object>? _borderWidth;

  /// The cell of `borderWidth`, or Dart `null` when absent.
  Opt<Object>? get borderWidthCell => _borderWidth;

  /// Stores the cell of `borderWidth`. Dart `null` deletes the key.
  set borderWidthCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.borderWidth);
    } else {
      store(OptionKey.borderWidth, cell);
    }
  }

  /// Stores the plain value [value] of `borderWidth`.
  set borderWidth(Object value) =>
      store(OptionKey.borderWidth, classify(OptionKey.borderWidth, value));

  Opt<double>? _hoverBorderWidth;

  /// The cell of `hoverBorderWidth`, or Dart `null` when absent.
  Opt<double>? get hoverBorderWidthCell => _hoverBorderWidth;

  /// Stores the cell of `hoverBorderWidth`. Dart `null` deletes the key.
  set hoverBorderWidthCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBorderWidth);
    } else {
      store(OptionKey.hoverBorderWidth, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBorderWidth`.
  set hoverBorderWidth(double value) =>
      store(OptionKey.hoverBorderWidth, OptValue<double>(value));

  Opt<Object>? _hoverBorderColor;

  /// The cell of `hoverBorderColor`, or Dart `null` when absent.
  Opt<Object>? get hoverBorderColorCell => _hoverBorderColor;

  /// Stores the cell of `hoverBorderColor`. Dart `null` deletes the key.
  set hoverBorderColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBorderColor);
    } else {
      store(OptionKey.hoverBorderColor, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBorderColor`.
  set hoverBorderColor(Object value) => store(
    OptionKey.hoverBorderColor,
    classify(OptionKey.hoverBorderColor, value),
  );

  Opt<Object>? _hoverBackgroundColor;

  /// The cell of `hoverBackgroundColor`, or Dart `null` when absent.
  Opt<Object>? get hoverBackgroundColorCell => _hoverBackgroundColor;

  /// Stores the cell of `hoverBackgroundColor`. Dart `null` deletes the key.
  set hoverBackgroundColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBackgroundColor);
    } else {
      store(OptionKey.hoverBackgroundColor, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBackgroundColor`.
  set hoverBackgroundColor(Object value) => store(
    OptionKey.hoverBackgroundColor,
    classify(OptionKey.hoverBackgroundColor, value),
  );

  Opt<Object>? _animation;

  /// The cell of `animation`, or Dart `null` when absent.
  Opt<Object>? get animationCell => _animation;

  /// Stores the cell of `animation`. Dart `null` deletes the key.
  set animationCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.animation);
    } else {
      store(OptionKey.animation, cell);
    }
  }

  /// Stores the plain value [value] of `animation`.
  set animation(Object value) =>
      store(OptionKey.animation, classify(OptionKey.animation, value));

  Opt<Object>? _animations;

  /// The cell of `animations`, or Dart `null` when absent.
  Opt<Object>? get animationsCell => _animations;

  /// Stores the cell of `animations`. Dart `null` deletes the key.
  set animationsCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.animations);
    } else {
      store(OptionKey.animations, cell);
    }
  }

  /// Stores the plain value [value] of `animations`.
  set animations(Object value) =>
      store(OptionKey.animations, classify(OptionKey.animations, value));

  Opt<TransitionsSpecScope>? _transitions;

  /// The cell of `transitions`, or Dart `null` when absent.
  Opt<TransitionsSpecScope>? get transitionsCell => _transitions;

  /// Stores the cell of `transitions`. Dart `null` deletes the key.
  set transitionsCell(Opt<TransitionsSpecScope>? cell) {
    if (cell == null) {
      delete(OptionKey.transitions);
    } else {
      store(OptionKey.transitions, cell);
    }
  }

  /// Stores the plain value [value] of `transitions`.
  set transitions(TransitionsSpecScope value) =>
      store(OptionKey.transitions, OptScope<TransitionsSpecScope>(value));

  Opt<String>? _xAxisID;

  /// The cell of `xAxisID`, or Dart `null` when absent.
  Opt<String>? get xAxisIDCell => _xAxisID;

  /// Stores the cell of `xAxisID`. Dart `null` deletes the key.
  set xAxisIDCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.xAxisID);
    } else {
      store(OptionKey.xAxisID, cell);
    }
  }

  /// Stores the plain value [value] of `xAxisID`.
  set xAxisID(String value) =>
      store(OptionKey.xAxisID, OptValue<String>(value));

  Opt<String>? _yAxisID;

  /// The cell of `yAxisID`, or Dart `null` when absent.
  Opt<String>? get yAxisIDCell => _yAxisID;

  /// Stores the cell of `yAxisID`. Dart `null` deletes the key.
  set yAxisIDCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.yAxisID);
    } else {
      store(OptionKey.yAxisID, cell);
    }
  }

  /// Stores the plain value [value] of `yAxisID`.
  set yAxisID(String value) =>
      store(OptionKey.yAxisID, OptValue<String>(value));

  Opt<double>? _barPercentage;

  /// The cell of `barPercentage`, or Dart `null` when absent.
  Opt<double>? get barPercentageCell => _barPercentage;

  /// Stores the cell of `barPercentage`. Dart `null` deletes the key.
  set barPercentageCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.barPercentage);
    } else {
      store(OptionKey.barPercentage, cell);
    }
  }

  /// Stores the plain value [value] of `barPercentage`.
  set barPercentage(double value) =>
      store(OptionKey.barPercentage, OptValue<double>(value));

  Opt<double>? _categoryPercentage;

  /// The cell of `categoryPercentage`, or Dart `null` when absent.
  Opt<double>? get categoryPercentageCell => _categoryPercentage;

  /// Stores the cell of `categoryPercentage`. Dart `null` deletes the key.
  set categoryPercentageCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.categoryPercentage);
    } else {
      store(OptionKey.categoryPercentage, cell);
    }
  }

  /// Stores the plain value [value] of `categoryPercentage`.
  set categoryPercentage(double value) =>
      store(OptionKey.categoryPercentage, OptValue<double>(value));

  Opt<Object>? _barThickness;

  /// The cell of `barThickness`, or Dart `null` when absent.
  Opt<Object>? get barThicknessCell => _barThickness;

  /// Stores the cell of `barThickness`. Dart `null` deletes the key.
  set barThicknessCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.barThickness);
    } else {
      store(OptionKey.barThickness, cell);
    }
  }

  /// Stores the plain value [value] of `barThickness`.
  set barThickness(Object value) =>
      store(OptionKey.barThickness, classify(OptionKey.barThickness, value));

  Opt<double>? _maxBarThickness;

  /// The cell of `maxBarThickness`, or Dart `null` when absent.
  Opt<double>? get maxBarThicknessCell => _maxBarThickness;

  /// Stores the cell of `maxBarThickness`. Dart `null` deletes the key.
  set maxBarThicknessCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.maxBarThickness);
    } else {
      store(OptionKey.maxBarThickness, cell);
    }
  }

  /// Stores the plain value [value] of `maxBarThickness`.
  set maxBarThickness(double value) =>
      store(OptionKey.maxBarThickness, OptValue<double>(value));

  Opt<double>? _minBarLength;

  /// The cell of `minBarLength`, or Dart `null` when absent.
  Opt<double>? get minBarLengthCell => _minBarLength;

  /// Stores the cell of `minBarLength`. Dart `null` deletes the key.
  set minBarLengthCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.minBarLength);
    } else {
      store(OptionKey.minBarLength, cell);
    }
  }

  /// Stores the plain value [value] of `minBarLength`.
  set minBarLength(double value) =>
      store(OptionKey.minBarLength, OptValue<double>(value));

  Opt<Object>? _pointStyle;

  /// The cell of `pointStyle`, or Dart `null` when absent.
  Opt<Object>? get pointStyleCell => _pointStyle;

  /// Stores the cell of `pointStyle`. Dart `null` deletes the key.
  set pointStyleCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.pointStyle);
    } else {
      store(OptionKey.pointStyle, cell);
    }
  }

  /// Stores the plain value [value] of `pointStyle`.
  set pointStyle(Object value) =>
      store(OptionKey.pointStyle, classify(OptionKey.pointStyle, value));

  Opt<bool>? _grouped;

  /// The cell of `grouped`, or Dart `null` when absent.
  Opt<bool>? get groupedCell => _grouped;

  /// Stores the cell of `grouped`. Dart `null` deletes the key.
  set groupedCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.grouped);
    } else {
      store(OptionKey.grouped, cell);
    }
  }

  /// Stores the plain value [value] of `grouped`.
  set grouped(bool value) => store(OptionKey.grouped, OptValue<bool>(value));

  Opt<TooltipDatasetOptionsScope>? _tooltip;

  /// The cell of `tooltip`, or Dart `null` when absent.
  Opt<TooltipDatasetOptionsScope>? get tooltipCell => _tooltip;

  /// Stores the cell of `tooltip`. Dart `null` deletes the key.
  set tooltipCell(Opt<TooltipDatasetOptionsScope>? cell) {
    if (cell == null) {
      delete(OptionKey.tooltip);
    } else {
      store(OptionKey.tooltip, cell);
    }
  }

  /// Stores the plain value [value] of `tooltip`.
  set tooltip(TooltipDatasetOptionsScope value) =>
      store(OptionKey.tooltip, OptScope<TooltipDatasetOptionsScope>(value));

  Opt<String>? _type;

  /// The cell of `type`, or Dart `null` when absent.
  Opt<String>? get typeCell => _type;

  /// Stores the cell of `type`. Dart `null` deletes the key.
  set typeCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.type);
    } else {
      store(OptionKey.type, cell);
    }
  }

  /// Stores the plain value [value] of `type`.
  set type(String value) => store(OptionKey.type, OptValue<String>(value));

  Opt<Object>? _data;

  /// The cell of `data`, or Dart `null` when absent.
  Opt<Object>? get dataCell => _data;

  /// Stores the cell of `data`. Dart `null` deletes the key.
  set dataCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.data);
    } else {
      store(OptionKey.data, cell);
    }
  }

  /// Stores the plain value [value] of `data`.
  set data(Object value) =>
      store(OptionKey.data, classify(OptionKey.data, value));

  Opt<bool>? _skipNull;

  /// The cell of `skipNull`, or Dart `null` when absent.
  Opt<bool>? get skipNullCell => _skipNull;

  /// Stores the cell of `skipNull`. Dart `null` deletes the key.
  set skipNullCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.skipNull);
    } else {
      store(OptionKey.skipNull, cell);
    }
  }

  /// Stores the plain value [value] of `skipNull`.
  set skipNull(bool value) => store(OptionKey.skipNull, OptValue<bool>(value));

  Opt<Object>? _hoverBorderRadius;

  /// The cell of `hoverBorderRadius`, or Dart `null` when absent.
  Opt<Object>? get hoverBorderRadiusCell => _hoverBorderRadius;

  /// Stores the cell of `hoverBorderRadius`. Dart `null` deletes the key.
  set hoverBorderRadiusCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBorderRadius);
    } else {
      store(OptionKey.hoverBorderRadius, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBorderRadius`.
  set hoverBorderRadius(Object value) => store(
    OptionKey.hoverBorderRadius,
    classify(OptionKey.hoverBorderRadius, value),
  );

  Opt<String>? _rAxisID;

  /// The cell of `rAxisID`, or Dart `null` when absent.
  Opt<String>? get rAxisIDCell => _rAxisID;

  /// Stores the cell of `rAxisID`. Dart `null` deletes the key.
  set rAxisIDCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.rAxisID);
    } else {
      store(OptionKey.rAxisID, cell);
    }
  }

  /// Stores the plain value [value] of `rAxisID`.
  set rAxisID(String value) =>
      store(OptionKey.rAxisID, OptValue<String>(value));

  Opt<Object>? _fill;

  /// The cell of `fill`, or Dart `null` when absent.
  Opt<Object>? get fillCell => _fill;

  /// Stores the cell of `fill`. Dart `null` deletes the key.
  set fillCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.fill);
    } else {
      store(OptionKey.fill, cell);
    }
  }

  /// Stores the plain value [value] of `fill`.
  set fill(Object value) =>
      store(OptionKey.fill, classify(OptionKey.fill, value));

  Opt<bool>? _drawActiveElementsOnTop;

  /// The cell of `drawActiveElementsOnTop`, or Dart `null` when absent.
  Opt<bool>? get drawActiveElementsOnTopCell => _drawActiveElementsOnTop;

  /// Stores the cell of `drawActiveElementsOnTop`. Dart `null` deletes the key.
  set drawActiveElementsOnTopCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.drawActiveElementsOnTop);
    } else {
      store(OptionKey.drawActiveElementsOnTop, cell);
    }
  }

  /// Stores the plain value [value] of `drawActiveElementsOnTop`.
  set drawActiveElementsOnTop(bool value) =>
      store(OptionKey.drawActiveElementsOnTop, OptValue<bool>(value));

  Opt<ElementOptionsByTypeScope>? _elements;

  /// The cell of `elements`, or Dart `null` when absent.
  Opt<ElementOptionsByTypeScope>? get elementsCell => _elements;

  /// Stores the cell of `elements`. Dart `null` deletes the key.
  set elementsCell(Opt<ElementOptionsByTypeScope>? cell) {
    if (cell == null) {
      delete(OptionKey.elements);
    } else {
      store(OptionKey.elements, cell);
    }
  }

  /// Stores the plain value [value] of `elements`.
  set elements(ElementOptionsByTypeScope value) =>
      store(OptionKey.elements, OptScope<ElementOptionsByTypeScope>(value));

  Opt<Object>? _datasetElementType;

  /// The cell of `datasetElementType`, or Dart `null` when absent.
  Opt<Object>? get datasetElementTypeCell => _datasetElementType;

  /// Stores the cell of `datasetElementType`. Dart `null` deletes the key.
  set datasetElementTypeCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.datasetElementType);
    } else {
      store(OptionKey.datasetElementType, cell);
    }
  }

  /// Stores the plain value [value] of `datasetElementType`.
  set datasetElementType(Object value) => store(
    OptionKey.datasetElementType,
    classify(OptionKey.datasetElementType, value),
  );

  Opt<Object>? _dataElementType;

  /// The cell of `dataElementType`, or Dart `null` when absent.
  Opt<Object>? get dataElementTypeCell => _dataElementType;

  /// Stores the cell of `dataElementType`. Dart `null` deletes the key.
  set dataElementTypeCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.dataElementType);
    } else {
      store(OptionKey.dataElementType, cell);
    }
  }

  /// Stores the plain value [value] of `dataElementType`.
  set dataElementType(Object value) => store(
    OptionKey.dataElementType,
    classify(OptionKey.dataElementType, value),
  );

  Opt<Object>? _descData;

  /// The cell of `_data`, or Dart `null` when absent.
  Opt<Object>? get descDataCell => _descData;

  /// Stores the cell of `_data`. Dart `null` deletes the key.
  set descDataCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.descData);
    } else {
      store(OptionKey.descData, cell);
    }
  }

  /// Stores the plain value [value] of `_data`.
  set descData(Object value) =>
      store(OptionKey.descData, classify(OptionKey.descData, value));

  Opt<Object>? _descDecimated;

  /// The cell of `_decimated`, or Dart `null` when absent.
  Opt<Object>? get descDecimatedCell => _descDecimated;

  /// Stores the cell of `_decimated`. Dart `null` deletes the key.
  set descDecimatedCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.descDecimated);
    } else {
      store(OptionKey.descDecimated, cell);
    }
  }

  /// Stores the plain value [value] of `_decimated`.
  set descDecimated(Object value) =>
      store(OptionKey.descDecimated, classify(OptionKey.descDecimated, value));

  @override
  Opt<Object?>? cellOf(OptionKey key) => switch (key) {
    OptionKey.parsing => _parsing,
    OptionKey.normalized => _normalized,
    OptionKey.indexAxis => _indexAxis,
    OptionKey.clip => _clip,
    OptionKey.label => _label,
    OptionKey.order => _order,
    OptionKey.stack => _stack,
    OptionKey.hidden => _hidden,
    OptionKey.borderColor => _borderColor,
    OptionKey.backgroundColor => _backgroundColor,
    OptionKey.base => _base,
    OptionKey.borderSkipped => _borderSkipped,
    OptionKey.borderRadius => _borderRadius,
    OptionKey.inflateAmount => _inflateAmount,
    OptionKey.borderWidth => _borderWidth,
    OptionKey.hoverBorderWidth => _hoverBorderWidth,
    OptionKey.hoverBorderColor => _hoverBorderColor,
    OptionKey.hoverBackgroundColor => _hoverBackgroundColor,
    OptionKey.animation => _animation,
    OptionKey.animations => _animations,
    OptionKey.transitions => _transitions,
    OptionKey.xAxisID => _xAxisID,
    OptionKey.yAxisID => _yAxisID,
    OptionKey.barPercentage => _barPercentage,
    OptionKey.categoryPercentage => _categoryPercentage,
    OptionKey.barThickness => _barThickness,
    OptionKey.maxBarThickness => _maxBarThickness,
    OptionKey.minBarLength => _minBarLength,
    OptionKey.pointStyle => _pointStyle,
    OptionKey.grouped => _grouped,
    OptionKey.tooltip => _tooltip,
    OptionKey.type => _type,
    OptionKey.data => _data,
    OptionKey.skipNull => _skipNull,
    OptionKey.hoverBorderRadius => _hoverBorderRadius,
    OptionKey.rAxisID => _rAxisID,
    OptionKey.fill => _fill,
    OptionKey.drawActiveElementsOnTop => _drawActiveElementsOnTop,
    OptionKey.elements => _elements,
    OptionKey.datasetElementType => _datasetElementType,
    OptionKey.dataElementType => _dataElementType,
    OptionKey.descData => _descData,
    OptionKey.descDecimated => _descDecimated,
    _ => null,
  };

  @override
  void setCell(OptionKey key, Opt<Object?>? cell) {
    switch (key) {
      case OptionKey.parsing:
        _parsing = fitCell(cell, (raw) => classifyUnion(raw, 34));
      case OptionKey.normalized:
        _normalized = fitCell(cell, classifyBool);
      case OptionKey.indexAxis:
        _indexAxis = fitCell(cell, classifyString);
      case OptionKey.clip:
        _clip = fitCell(cell, (raw) => classifyUnion(raw, 35));
      case OptionKey.label:
        _label = fitCell(cell, classifyString);
      case OptionKey.order:
        _order = fitCell(cell, classifyNumber);
      case OptionKey.stack:
        _stack = fitCell(cell, classifyString);
      case OptionKey.hidden:
        _hidden = fitCell(cell, classifyBool);
      case OptionKey.borderColor:
        _borderColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.backgroundColor:
        _backgroundColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.base:
        _base = fitCell(cell, classifyNumber);
      case OptionKey.borderSkipped:
        _borderSkipped = fitCell(cell, (raw) => classifyUnion(raw, 6));
      case OptionKey.borderRadius:
        _borderRadius = fitCell(cell, (raw) => classifyUnion(raw, 33));
      case OptionKey.inflateAmount:
        _inflateAmount = fitCell(cell, (raw) => classifyUnion(raw, 5));
      case OptionKey.borderWidth:
        _borderWidth = fitCell(cell, (raw) => classifyUnion(raw, 33));
      case OptionKey.hoverBorderWidth:
        _hoverBorderWidth = fitCell(cell, classifyNumber);
      case OptionKey.hoverBorderColor:
        _hoverBorderColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.hoverBackgroundColor:
        _hoverBackgroundColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.animation:
        _animation = fitCell(cell, (raw) => classifyUnion(raw, 34));
      case OptionKey.animations:
        _animations = fitCell(cell, (raw) => classifyUnion(raw, 34));
      case OptionKey.transitions:
        _transitions = fitCell(cell, classifyScope<TransitionsSpecScope>);
      case OptionKey.xAxisID:
        _xAxisID = fitCell(cell, classifyString);
      case OptionKey.yAxisID:
        _yAxisID = fitCell(cell, classifyString);
      case OptionKey.barPercentage:
        _barPercentage = fitCell(cell, classifyNumber);
      case OptionKey.categoryPercentage:
        _categoryPercentage = fitCell(cell, classifyNumber);
      case OptionKey.barThickness:
        _barThickness = fitCell(cell, (raw) => classifyUnion(raw, 5));
      case OptionKey.maxBarThickness:
        _maxBarThickness = fitCell(cell, classifyNumber);
      case OptionKey.minBarLength:
        _minBarLength = fitCell(cell, classifyNumber);
      case OptionKey.pointStyle:
        _pointStyle = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.grouped:
        _grouped = fitCell(cell, classifyBool);
      case OptionKey.tooltip:
        _tooltip = fitCell(cell, classifyScope<TooltipDatasetOptionsScope>);
      case OptionKey.type:
        _type = fitCell(cell, classifyString);
      case OptionKey.data:
        _data = fitCell(cell, (raw) => classifyUnion(raw, 16));
      case OptionKey.skipNull:
        _skipNull = fitCell(cell, classifyBool);
      case OptionKey.hoverBorderRadius:
        _hoverBorderRadius = fitCell(cell, (raw) => classifyUnion(raw, 33));
      case OptionKey.rAxisID:
        _rAxisID = fitCell(cell, classifyString);
      case OptionKey.fill:
        _fill = fitCell(cell, (raw) => classifyUnion(raw, 39));
      case OptionKey.drawActiveElementsOnTop:
        _drawActiveElementsOnTop = fitCell(cell, classifyBool);
      case OptionKey.elements:
        _elements = fitCell(cell, classifyScope<ElementOptionsByTypeScope>);
      case OptionKey.datasetElementType:
        _datasetElementType = fitCell(cell, (raw) => classifyUnion(raw, 6));
      case OptionKey.dataElementType:
        _dataElementType = fitCell(cell, (raw) => classifyUnion(raw, 6));
      case OptionKey.descData:
        _descData = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.descDecimated:
        _descDecimated = fitCell(cell, (raw) => classifyUnion(raw, 64));
      default:
        throw ArgumentError.value(
          key,
          'key',
          'Not a key of BarControllerDatasetOptions',
        );
    }
  }

  @override
  bool hasField(OptionKey key) => switch (key) {
    OptionKey.parsing ||
    OptionKey.normalized ||
    OptionKey.indexAxis ||
    OptionKey.clip ||
    OptionKey.label ||
    OptionKey.order ||
    OptionKey.stack ||
    OptionKey.hidden ||
    OptionKey.borderColor ||
    OptionKey.backgroundColor ||
    OptionKey.base ||
    OptionKey.borderSkipped ||
    OptionKey.borderRadius ||
    OptionKey.inflateAmount ||
    OptionKey.borderWidth ||
    OptionKey.hoverBorderWidth ||
    OptionKey.hoverBorderColor ||
    OptionKey.hoverBackgroundColor ||
    OptionKey.animation ||
    OptionKey.animations ||
    OptionKey.transitions ||
    OptionKey.xAxisID ||
    OptionKey.yAxisID ||
    OptionKey.barPercentage ||
    OptionKey.categoryPercentage ||
    OptionKey.barThickness ||
    OptionKey.maxBarThickness ||
    OptionKey.minBarLength ||
    OptionKey.pointStyle ||
    OptionKey.grouped ||
    OptionKey.tooltip ||
    OptionKey.type ||
    OptionKey.data ||
    OptionKey.skipNull ||
    OptionKey.hoverBorderRadius ||
    OptionKey.rAxisID ||
    OptionKey.fill ||
    OptionKey.drawActiveElementsOnTop ||
    OptionKey.elements ||
    OptionKey.datasetElementType ||
    OptionKey.dataElementType ||
    OptionKey.descData ||
    OptionKey.descDecimated => true,
    _ => false,
  };

  @override
  Opt<Object?> classify(OptionKey key, Object? raw) => switch (key) {
    OptionKey.parsing => classifyUnion(raw, 34),
    OptionKey.normalized => classifyBool(raw),
    OptionKey.indexAxis => classifyString(raw),
    OptionKey.clip => classifyUnion(raw, 35),
    OptionKey.label => classifyString(raw),
    OptionKey.order => classifyNumber(raw),
    OptionKey.stack => classifyString(raw),
    OptionKey.hidden => classifyBool(raw),
    OptionKey.borderColor => classifyUnion(raw, 64),
    OptionKey.backgroundColor => classifyUnion(raw, 64),
    OptionKey.base => classifyNumber(raw),
    OptionKey.borderSkipped => classifyUnion(raw, 6),
    OptionKey.borderRadius => classifyUnion(raw, 33),
    OptionKey.inflateAmount => classifyUnion(raw, 5),
    OptionKey.borderWidth => classifyUnion(raw, 33),
    OptionKey.hoverBorderWidth => classifyNumber(raw),
    OptionKey.hoverBorderColor => classifyUnion(raw, 64),
    OptionKey.hoverBackgroundColor => classifyUnion(raw, 64),
    OptionKey.animation => classifyUnion(raw, 34),
    OptionKey.animations => classifyUnion(raw, 34),
    OptionKey.transitions => classifyScope<TransitionsSpecScope>(raw),
    OptionKey.xAxisID => classifyString(raw),
    OptionKey.yAxisID => classifyString(raw),
    OptionKey.barPercentage => classifyNumber(raw),
    OptionKey.categoryPercentage => classifyNumber(raw),
    OptionKey.barThickness => classifyUnion(raw, 5),
    OptionKey.maxBarThickness => classifyNumber(raw),
    OptionKey.minBarLength => classifyNumber(raw),
    OptionKey.pointStyle => classifyUnion(raw, 64),
    OptionKey.grouped => classifyBool(raw),
    OptionKey.tooltip => classifyScope<TooltipDatasetOptionsScope>(raw),
    OptionKey.type => classifyString(raw),
    OptionKey.data => classifyUnion(raw, 16),
    OptionKey.skipNull => classifyBool(raw),
    OptionKey.hoverBorderRadius => classifyUnion(raw, 33),
    OptionKey.rAxisID => classifyString(raw),
    OptionKey.fill => classifyUnion(raw, 39),
    OptionKey.drawActiveElementsOnTop => classifyBool(raw),
    OptionKey.elements => classifyScope<ElementOptionsByTypeScope>(raw),
    OptionKey.datasetElementType => classifyUnion(raw, 6),
    OptionKey.dataElementType => classifyUnion(raw, 6),
    OptionKey.descData => classifyUnion(raw, 64),
    OptionKey.descDecimated => classifyUnion(raw, 64),
    _ => kind.classifyOther(raw),
  };
}

/// index.d.ts:189 LineControllerDatasetOptions (index.d.ts:66
/// ControllerDatasetOptions, PointPrefixedOptions, PointPrefixedHoverOptions,
/// LineOptions, LineHoverOptions, AnimationOptions) with index.d.ts:2317
/// FillerControllerDatasetOptions and index.d.ts:216
/// LineControllerChartOptions, a line or scatter dataset and `datasets.line`,
/// `datasets.scatter`.
base class LineControllerDatasetOptionsScope extends OptionScope {
  /// An empty scope.
  LineControllerDatasetOptionsScope();

  @override
  ScopeKind get kind => ScopeKind.lineControllerDatasetOptions;

  Opt<Object>? _parsing;

  /// The cell of `parsing`, or Dart `null` when absent.
  Opt<Object>? get parsingCell => _parsing;

  /// Stores the cell of `parsing`. Dart `null` deletes the key.
  set parsingCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.parsing);
    } else {
      store(OptionKey.parsing, cell);
    }
  }

  /// Stores the plain value [value] of `parsing`.
  set parsing(Object value) =>
      store(OptionKey.parsing, classify(OptionKey.parsing, value));

  Opt<bool>? _normalized;

  /// The cell of `normalized`, or Dart `null` when absent.
  Opt<bool>? get normalizedCell => _normalized;

  /// Stores the cell of `normalized`. Dart `null` deletes the key.
  set normalizedCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.normalized);
    } else {
      store(OptionKey.normalized, cell);
    }
  }

  /// Stores the plain value [value] of `normalized`.
  set normalized(bool value) =>
      store(OptionKey.normalized, OptValue<bool>(value));

  Opt<String>? _indexAxis;

  /// The cell of `indexAxis`, or Dart `null` when absent.
  Opt<String>? get indexAxisCell => _indexAxis;

  /// Stores the cell of `indexAxis`. Dart `null` deletes the key.
  set indexAxisCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.indexAxis);
    } else {
      store(OptionKey.indexAxis, cell);
    }
  }

  /// Stores the plain value [value] of `indexAxis`.
  set indexAxis(String value) =>
      store(OptionKey.indexAxis, OptValue<String>(value));

  Opt<Object>? _clip;

  /// The cell of `clip`, or Dart `null` when absent.
  Opt<Object>? get clipCell => _clip;

  /// Stores the cell of `clip`. Dart `null` deletes the key.
  set clipCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.clip);
    } else {
      store(OptionKey.clip, cell);
    }
  }

  /// Stores the plain value [value] of `clip`.
  set clip(Object value) =>
      store(OptionKey.clip, classify(OptionKey.clip, value));

  Opt<String>? _label;

  /// The cell of `label`, or Dart `null` when absent.
  Opt<String>? get labelCell => _label;

  /// Stores the cell of `label`. Dart `null` deletes the key.
  set labelCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.label);
    } else {
      store(OptionKey.label, cell);
    }
  }

  /// Stores the plain value [value] of `label`.
  set label(String value) => store(OptionKey.label, OptValue<String>(value));

  Opt<double>? _order;

  /// The cell of `order`, or Dart `null` when absent.
  Opt<double>? get orderCell => _order;

  /// Stores the cell of `order`. Dart `null` deletes the key.
  set orderCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.order);
    } else {
      store(OptionKey.order, cell);
    }
  }

  /// Stores the plain value [value] of `order`.
  set order(double value) => store(OptionKey.order, OptValue<double>(value));

  Opt<String>? _stack;

  /// The cell of `stack`, or Dart `null` when absent.
  Opt<String>? get stackCell => _stack;

  /// Stores the cell of `stack`. Dart `null` deletes the key.
  set stackCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.stack);
    } else {
      store(OptionKey.stack, cell);
    }
  }

  /// Stores the plain value [value] of `stack`.
  set stack(String value) => store(OptionKey.stack, OptValue<String>(value));

  Opt<bool>? _hidden;

  /// The cell of `hidden`, or Dart `null` when absent.
  Opt<bool>? get hiddenCell => _hidden;

  /// Stores the cell of `hidden`. Dart `null` deletes the key.
  set hiddenCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.hidden);
    } else {
      store(OptionKey.hidden, cell);
    }
  }

  /// Stores the plain value [value] of `hidden`.
  set hidden(bool value) => store(OptionKey.hidden, OptValue<bool>(value));

  Opt<Object>? _pointBackgroundColor;

  /// The cell of `pointBackgroundColor`, or Dart `null` when absent.
  Opt<Object>? get pointBackgroundColorCell => _pointBackgroundColor;

  /// Stores the cell of `pointBackgroundColor`. Dart `null` deletes the key.
  set pointBackgroundColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.pointBackgroundColor);
    } else {
      store(OptionKey.pointBackgroundColor, cell);
    }
  }

  /// Stores the plain value [value] of `pointBackgroundColor`.
  set pointBackgroundColor(Object value) => store(
    OptionKey.pointBackgroundColor,
    classify(OptionKey.pointBackgroundColor, value),
  );

  Opt<Object>? _pointBorderColor;

  /// The cell of `pointBorderColor`, or Dart `null` when absent.
  Opt<Object>? get pointBorderColorCell => _pointBorderColor;

  /// Stores the cell of `pointBorderColor`. Dart `null` deletes the key.
  set pointBorderColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.pointBorderColor);
    } else {
      store(OptionKey.pointBorderColor, cell);
    }
  }

  /// Stores the plain value [value] of `pointBorderColor`.
  set pointBorderColor(Object value) => store(
    OptionKey.pointBorderColor,
    classify(OptionKey.pointBorderColor, value),
  );

  Opt<double>? _pointBorderWidth;

  /// The cell of `pointBorderWidth`, or Dart `null` when absent.
  Opt<double>? get pointBorderWidthCell => _pointBorderWidth;

  /// Stores the cell of `pointBorderWidth`. Dart `null` deletes the key.
  set pointBorderWidthCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.pointBorderWidth);
    } else {
      store(OptionKey.pointBorderWidth, cell);
    }
  }

  /// Stores the plain value [value] of `pointBorderWidth`.
  set pointBorderWidth(double value) =>
      store(OptionKey.pointBorderWidth, OptValue<double>(value));

  Opt<double>? _pointHitRadius;

  /// The cell of `pointHitRadius`, or Dart `null` when absent.
  Opt<double>? get pointHitRadiusCell => _pointHitRadius;

  /// Stores the cell of `pointHitRadius`. Dart `null` deletes the key.
  set pointHitRadiusCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.pointHitRadius);
    } else {
      store(OptionKey.pointHitRadius, cell);
    }
  }

  /// Stores the plain value [value] of `pointHitRadius`.
  set pointHitRadius(double value) =>
      store(OptionKey.pointHitRadius, OptValue<double>(value));

  Opt<double>? _pointRadius;

  /// The cell of `pointRadius`, or Dart `null` when absent.
  Opt<double>? get pointRadiusCell => _pointRadius;

  /// Stores the cell of `pointRadius`. Dart `null` deletes the key.
  set pointRadiusCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.pointRadius);
    } else {
      store(OptionKey.pointRadius, cell);
    }
  }

  /// Stores the plain value [value] of `pointRadius`.
  set pointRadius(double value) =>
      store(OptionKey.pointRadius, OptValue<double>(value));

  Opt<double>? _pointRotation;

  /// The cell of `pointRotation`, or Dart `null` when absent.
  Opt<double>? get pointRotationCell => _pointRotation;

  /// Stores the cell of `pointRotation`. Dart `null` deletes the key.
  set pointRotationCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.pointRotation);
    } else {
      store(OptionKey.pointRotation, cell);
    }
  }

  /// Stores the plain value [value] of `pointRotation`.
  set pointRotation(double value) =>
      store(OptionKey.pointRotation, OptValue<double>(value));

  Opt<Object>? _pointStyle;

  /// The cell of `pointStyle`, or Dart `null` when absent.
  Opt<Object>? get pointStyleCell => _pointStyle;

  /// Stores the cell of `pointStyle`. Dart `null` deletes the key.
  set pointStyleCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.pointStyle);
    } else {
      store(OptionKey.pointStyle, cell);
    }
  }

  /// Stores the plain value [value] of `pointStyle`.
  set pointStyle(Object value) =>
      store(OptionKey.pointStyle, classify(OptionKey.pointStyle, value));

  Opt<Object>? _pointHoverBackgroundColor;

  /// The cell of `pointHoverBackgroundColor`, or Dart `null` when absent.
  Opt<Object>? get pointHoverBackgroundColorCell => _pointHoverBackgroundColor;

  /// Stores the cell of `pointHoverBackgroundColor`. Dart `null` deletes the key.
  set pointHoverBackgroundColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.pointHoverBackgroundColor);
    } else {
      store(OptionKey.pointHoverBackgroundColor, cell);
    }
  }

  /// Stores the plain value [value] of `pointHoverBackgroundColor`.
  set pointHoverBackgroundColor(Object value) => store(
    OptionKey.pointHoverBackgroundColor,
    classify(OptionKey.pointHoverBackgroundColor, value),
  );

  Opt<Object>? _pointHoverBorderColor;

  /// The cell of `pointHoverBorderColor`, or Dart `null` when absent.
  Opt<Object>? get pointHoverBorderColorCell => _pointHoverBorderColor;

  /// Stores the cell of `pointHoverBorderColor`. Dart `null` deletes the key.
  set pointHoverBorderColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.pointHoverBorderColor);
    } else {
      store(OptionKey.pointHoverBorderColor, cell);
    }
  }

  /// Stores the plain value [value] of `pointHoverBorderColor`.
  set pointHoverBorderColor(Object value) => store(
    OptionKey.pointHoverBorderColor,
    classify(OptionKey.pointHoverBorderColor, value),
  );

  Opt<double>? _pointHoverBorderWidth;

  /// The cell of `pointHoverBorderWidth`, or Dart `null` when absent.
  Opt<double>? get pointHoverBorderWidthCell => _pointHoverBorderWidth;

  /// Stores the cell of `pointHoverBorderWidth`. Dart `null` deletes the key.
  set pointHoverBorderWidthCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.pointHoverBorderWidth);
    } else {
      store(OptionKey.pointHoverBorderWidth, cell);
    }
  }

  /// Stores the plain value [value] of `pointHoverBorderWidth`.
  set pointHoverBorderWidth(double value) =>
      store(OptionKey.pointHoverBorderWidth, OptValue<double>(value));

  Opt<double>? _pointHoverRadius;

  /// The cell of `pointHoverRadius`, or Dart `null` when absent.
  Opt<double>? get pointHoverRadiusCell => _pointHoverRadius;

  /// Stores the cell of `pointHoverRadius`. Dart `null` deletes the key.
  set pointHoverRadiusCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.pointHoverRadius);
    } else {
      store(OptionKey.pointHoverRadius, cell);
    }
  }

  /// Stores the plain value [value] of `pointHoverRadius`.
  set pointHoverRadius(double value) =>
      store(OptionKey.pointHoverRadius, OptValue<double>(value));

  Opt<String>? _borderCapStyle;

  /// The cell of `borderCapStyle`, or Dart `null` when absent.
  Opt<String>? get borderCapStyleCell => _borderCapStyle;

  /// Stores the cell of `borderCapStyle`. Dart `null` deletes the key.
  set borderCapStyleCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.borderCapStyle);
    } else {
      store(OptionKey.borderCapStyle, cell);
    }
  }

  /// Stores the plain value [value] of `borderCapStyle`.
  set borderCapStyle(String value) =>
      store(OptionKey.borderCapStyle, OptValue<String>(value));

  Opt<Object>? _borderDash;

  /// The cell of `borderDash`, or Dart `null` when absent.
  Opt<Object>? get borderDashCell => _borderDash;

  /// Stores the cell of `borderDash`. Dart `null` deletes the key.
  set borderDashCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.borderDash);
    } else {
      store(OptionKey.borderDash, cell);
    }
  }

  /// Stores the plain value [value] of `borderDash`.
  set borderDash(Object value) =>
      store(OptionKey.borderDash, classify(OptionKey.borderDash, value));

  Opt<double>? _borderDashOffset;

  /// The cell of `borderDashOffset`, or Dart `null` when absent.
  Opt<double>? get borderDashOffsetCell => _borderDashOffset;

  /// Stores the cell of `borderDashOffset`. Dart `null` deletes the key.
  set borderDashOffsetCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.borderDashOffset);
    } else {
      store(OptionKey.borderDashOffset, cell);
    }
  }

  /// Stores the plain value [value] of `borderDashOffset`.
  set borderDashOffset(double value) =>
      store(OptionKey.borderDashOffset, OptValue<double>(value));

  Opt<String>? _borderJoinStyle;

  /// The cell of `borderJoinStyle`, or Dart `null` when absent.
  Opt<String>? get borderJoinStyleCell => _borderJoinStyle;

  /// Stores the cell of `borderJoinStyle`. Dart `null` deletes the key.
  set borderJoinStyleCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.borderJoinStyle);
    } else {
      store(OptionKey.borderJoinStyle, cell);
    }
  }

  /// Stores the plain value [value] of `borderJoinStyle`.
  set borderJoinStyle(String value) =>
      store(OptionKey.borderJoinStyle, OptValue<String>(value));

  Opt<bool>? _capBezierPoints;

  /// The cell of `capBezierPoints`, or Dart `null` when absent.
  Opt<bool>? get capBezierPointsCell => _capBezierPoints;

  /// Stores the cell of `capBezierPoints`. Dart `null` deletes the key.
  set capBezierPointsCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.capBezierPoints);
    } else {
      store(OptionKey.capBezierPoints, cell);
    }
  }

  /// Stores the plain value [value] of `capBezierPoints`.
  set capBezierPoints(bool value) =>
      store(OptionKey.capBezierPoints, OptValue<bool>(value));

  Opt<String>? _cubicInterpolationMode;

  /// The cell of `cubicInterpolationMode`, or Dart `null` when absent.
  Opt<String>? get cubicInterpolationModeCell => _cubicInterpolationMode;

  /// Stores the cell of `cubicInterpolationMode`. Dart `null` deletes the key.
  set cubicInterpolationModeCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.cubicInterpolationMode);
    } else {
      store(OptionKey.cubicInterpolationMode, cell);
    }
  }

  /// Stores the plain value [value] of `cubicInterpolationMode`.
  set cubicInterpolationMode(String value) =>
      store(OptionKey.cubicInterpolationMode, OptValue<String>(value));

  Opt<double>? _tension;

  /// The cell of `tension`, or Dart `null` when absent.
  Opt<double>? get tensionCell => _tension;

  /// Stores the cell of `tension`. Dart `null` deletes the key.
  set tensionCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.tension);
    } else {
      store(OptionKey.tension, cell);
    }
  }

  /// Stores the plain value [value] of `tension`.
  set tension(double value) =>
      store(OptionKey.tension, OptValue<double>(value));

  Opt<Object>? _stepped;

  /// The cell of `stepped`, or Dart `null` when absent.
  Opt<Object>? get steppedCell => _stepped;

  /// Stores the cell of `stepped`. Dart `null` deletes the key.
  set steppedCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.stepped);
    } else {
      store(OptionKey.stepped, cell);
    }
  }

  /// Stores the plain value [value] of `stepped`.
  set stepped(Object value) =>
      store(OptionKey.stepped, classify(OptionKey.stepped, value));

  Opt<Object>? _fill;

  /// The cell of `fill`, or Dart `null` when absent.
  Opt<Object>? get fillCell => _fill;

  /// Stores the cell of `fill`. Dart `null` deletes the key.
  set fillCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.fill);
    } else {
      store(OptionKey.fill, cell);
    }
  }

  /// Stores the plain value [value] of `fill`.
  set fill(Object value) =>
      store(OptionKey.fill, classify(OptionKey.fill, value));

  Opt<Object>? _spanGaps;

  /// The cell of `spanGaps`, or Dart `null` when absent.
  Opt<Object>? get spanGapsCell => _spanGaps;

  /// Stores the cell of `spanGaps`. Dart `null` deletes the key.
  set spanGapsCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.spanGaps);
    } else {
      store(OptionKey.spanGaps, cell);
    }
  }

  /// Stores the plain value [value] of `spanGaps`.
  set spanGaps(Object value) =>
      store(OptionKey.spanGaps, classify(OptionKey.spanGaps, value));

  Opt<SegmentOptionsScope>? _segment;

  /// The cell of `segment`, or Dart `null` when absent.
  Opt<SegmentOptionsScope>? get segmentCell => _segment;

  /// Stores the cell of `segment`. Dart `null` deletes the key.
  set segmentCell(Opt<SegmentOptionsScope>? cell) {
    if (cell == null) {
      delete(OptionKey.segment);
    } else {
      store(OptionKey.segment, cell);
    }
  }

  /// Stores the plain value [value] of `segment`.
  set segment(SegmentOptionsScope value) =>
      store(OptionKey.segment, OptScope<SegmentOptionsScope>(value));

  Opt<double>? _borderWidth;

  /// The cell of `borderWidth`, or Dart `null` when absent.
  Opt<double>? get borderWidthCell => _borderWidth;

  /// Stores the cell of `borderWidth`. Dart `null` deletes the key.
  set borderWidthCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.borderWidth);
    } else {
      store(OptionKey.borderWidth, cell);
    }
  }

  /// Stores the plain value [value] of `borderWidth`.
  set borderWidth(double value) =>
      store(OptionKey.borderWidth, OptValue<double>(value));

  Opt<Object>? _borderColor;

  /// The cell of `borderColor`, or Dart `null` when absent.
  Opt<Object>? get borderColorCell => _borderColor;

  /// Stores the cell of `borderColor`. Dart `null` deletes the key.
  set borderColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.borderColor);
    } else {
      store(OptionKey.borderColor, cell);
    }
  }

  /// Stores the plain value [value] of `borderColor`.
  set borderColor(Object value) =>
      store(OptionKey.borderColor, classify(OptionKey.borderColor, value));

  Opt<Object>? _backgroundColor;

  /// The cell of `backgroundColor`, or Dart `null` when absent.
  Opt<Object>? get backgroundColorCell => _backgroundColor;

  /// Stores the cell of `backgroundColor`. Dart `null` deletes the key.
  set backgroundColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.backgroundColor);
    } else {
      store(OptionKey.backgroundColor, cell);
    }
  }

  /// Stores the plain value [value] of `backgroundColor`.
  set backgroundColor(Object value) => store(
    OptionKey.backgroundColor,
    classify(OptionKey.backgroundColor, value),
  );

  Opt<String>? _hoverBorderCapStyle;

  /// The cell of `hoverBorderCapStyle`, or Dart `null` when absent.
  Opt<String>? get hoverBorderCapStyleCell => _hoverBorderCapStyle;

  /// Stores the cell of `hoverBorderCapStyle`. Dart `null` deletes the key.
  set hoverBorderCapStyleCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBorderCapStyle);
    } else {
      store(OptionKey.hoverBorderCapStyle, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBorderCapStyle`.
  set hoverBorderCapStyle(String value) =>
      store(OptionKey.hoverBorderCapStyle, OptValue<String>(value));

  Opt<Object>? _hoverBorderDash;

  /// The cell of `hoverBorderDash`, or Dart `null` when absent.
  Opt<Object>? get hoverBorderDashCell => _hoverBorderDash;

  /// Stores the cell of `hoverBorderDash`. Dart `null` deletes the key.
  set hoverBorderDashCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBorderDash);
    } else {
      store(OptionKey.hoverBorderDash, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBorderDash`.
  set hoverBorderDash(Object value) => store(
    OptionKey.hoverBorderDash,
    classify(OptionKey.hoverBorderDash, value),
  );

  Opt<double>? _hoverBorderDashOffset;

  /// The cell of `hoverBorderDashOffset`, or Dart `null` when absent.
  Opt<double>? get hoverBorderDashOffsetCell => _hoverBorderDashOffset;

  /// Stores the cell of `hoverBorderDashOffset`. Dart `null` deletes the key.
  set hoverBorderDashOffsetCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBorderDashOffset);
    } else {
      store(OptionKey.hoverBorderDashOffset, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBorderDashOffset`.
  set hoverBorderDashOffset(double value) =>
      store(OptionKey.hoverBorderDashOffset, OptValue<double>(value));

  Opt<String>? _hoverBorderJoinStyle;

  /// The cell of `hoverBorderJoinStyle`, or Dart `null` when absent.
  Opt<String>? get hoverBorderJoinStyleCell => _hoverBorderJoinStyle;

  /// Stores the cell of `hoverBorderJoinStyle`. Dart `null` deletes the key.
  set hoverBorderJoinStyleCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBorderJoinStyle);
    } else {
      store(OptionKey.hoverBorderJoinStyle, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBorderJoinStyle`.
  set hoverBorderJoinStyle(String value) =>
      store(OptionKey.hoverBorderJoinStyle, OptValue<String>(value));

  Opt<double>? _hoverBorderWidth;

  /// The cell of `hoverBorderWidth`, or Dart `null` when absent.
  Opt<double>? get hoverBorderWidthCell => _hoverBorderWidth;

  /// Stores the cell of `hoverBorderWidth`. Dart `null` deletes the key.
  set hoverBorderWidthCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBorderWidth);
    } else {
      store(OptionKey.hoverBorderWidth, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBorderWidth`.
  set hoverBorderWidth(double value) =>
      store(OptionKey.hoverBorderWidth, OptValue<double>(value));

  Opt<Object>? _hoverBorderColor;

  /// The cell of `hoverBorderColor`, or Dart `null` when absent.
  Opt<Object>? get hoverBorderColorCell => _hoverBorderColor;

  /// Stores the cell of `hoverBorderColor`. Dart `null` deletes the key.
  set hoverBorderColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBorderColor);
    } else {
      store(OptionKey.hoverBorderColor, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBorderColor`.
  set hoverBorderColor(Object value) => store(
    OptionKey.hoverBorderColor,
    classify(OptionKey.hoverBorderColor, value),
  );

  Opt<Object>? _hoverBackgroundColor;

  /// The cell of `hoverBackgroundColor`, or Dart `null` when absent.
  Opt<Object>? get hoverBackgroundColorCell => _hoverBackgroundColor;

  /// Stores the cell of `hoverBackgroundColor`. Dart `null` deletes the key.
  set hoverBackgroundColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBackgroundColor);
    } else {
      store(OptionKey.hoverBackgroundColor, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBackgroundColor`.
  set hoverBackgroundColor(Object value) => store(
    OptionKey.hoverBackgroundColor,
    classify(OptionKey.hoverBackgroundColor, value),
  );

  Opt<Object>? _animation;

  /// The cell of `animation`, or Dart `null` when absent.
  Opt<Object>? get animationCell => _animation;

  /// Stores the cell of `animation`. Dart `null` deletes the key.
  set animationCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.animation);
    } else {
      store(OptionKey.animation, cell);
    }
  }

  /// Stores the plain value [value] of `animation`.
  set animation(Object value) =>
      store(OptionKey.animation, classify(OptionKey.animation, value));

  Opt<Object>? _animations;

  /// The cell of `animations`, or Dart `null` when absent.
  Opt<Object>? get animationsCell => _animations;

  /// Stores the cell of `animations`. Dart `null` deletes the key.
  set animationsCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.animations);
    } else {
      store(OptionKey.animations, cell);
    }
  }

  /// Stores the plain value [value] of `animations`.
  set animations(Object value) =>
      store(OptionKey.animations, classify(OptionKey.animations, value));

  Opt<TransitionsSpecScope>? _transitions;

  /// The cell of `transitions`, or Dart `null` when absent.
  Opt<TransitionsSpecScope>? get transitionsCell => _transitions;

  /// Stores the cell of `transitions`. Dart `null` deletes the key.
  set transitionsCell(Opt<TransitionsSpecScope>? cell) {
    if (cell == null) {
      delete(OptionKey.transitions);
    } else {
      store(OptionKey.transitions, cell);
    }
  }

  /// Stores the plain value [value] of `transitions`.
  set transitions(TransitionsSpecScope value) =>
      store(OptionKey.transitions, OptScope<TransitionsSpecScope>(value));

  Opt<String>? _xAxisID;

  /// The cell of `xAxisID`, or Dart `null` when absent.
  Opt<String>? get xAxisIDCell => _xAxisID;

  /// Stores the cell of `xAxisID`. Dart `null` deletes the key.
  set xAxisIDCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.xAxisID);
    } else {
      store(OptionKey.xAxisID, cell);
    }
  }

  /// Stores the plain value [value] of `xAxisID`.
  set xAxisID(String value) =>
      store(OptionKey.xAxisID, OptValue<String>(value));

  Opt<String>? _yAxisID;

  /// The cell of `yAxisID`, or Dart `null` when absent.
  Opt<String>? get yAxisIDCell => _yAxisID;

  /// Stores the cell of `yAxisID`. Dart `null` deletes the key.
  set yAxisIDCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.yAxisID);
    } else {
      store(OptionKey.yAxisID, cell);
    }
  }

  /// Stores the plain value [value] of `yAxisID`.
  set yAxisID(String value) =>
      store(OptionKey.yAxisID, OptValue<String>(value));

  Opt<bool>? _showLine;

  /// The cell of `showLine`, or Dart `null` when absent.
  Opt<bool>? get showLineCell => _showLine;

  /// Stores the cell of `showLine`. Dart `null` deletes the key.
  set showLineCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.showLine);
    } else {
      store(OptionKey.showLine, cell);
    }
  }

  /// Stores the plain value [value] of `showLine`.
  set showLine(bool value) => store(OptionKey.showLine, OptValue<bool>(value));

  Opt<TooltipDatasetOptionsScope>? _tooltip;

  /// The cell of `tooltip`, or Dart `null` when absent.
  Opt<TooltipDatasetOptionsScope>? get tooltipCell => _tooltip;

  /// Stores the cell of `tooltip`. Dart `null` deletes the key.
  set tooltipCell(Opt<TooltipDatasetOptionsScope>? cell) {
    if (cell == null) {
      delete(OptionKey.tooltip);
    } else {
      store(OptionKey.tooltip, cell);
    }
  }

  /// Stores the plain value [value] of `tooltip`.
  set tooltip(TooltipDatasetOptionsScope value) =>
      store(OptionKey.tooltip, OptScope<TooltipDatasetOptionsScope>(value));

  Opt<String>? _type;

  /// The cell of `type`, or Dart `null` when absent.
  Opt<String>? get typeCell => _type;

  /// Stores the cell of `type`. Dart `null` deletes the key.
  set typeCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.type);
    } else {
      store(OptionKey.type, cell);
    }
  }

  /// Stores the plain value [value] of `type`.
  set type(String value) => store(OptionKey.type, OptValue<String>(value));

  Opt<Object>? _data;

  /// The cell of `data`, or Dart `null` when absent.
  Opt<Object>? get dataCell => _data;

  /// Stores the cell of `data`. Dart `null` deletes the key.
  set dataCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.data);
    } else {
      store(OptionKey.data, cell);
    }
  }

  /// Stores the plain value [value] of `data`.
  set data(Object value) =>
      store(OptionKey.data, classify(OptionKey.data, value));

  Opt<String>? _rAxisID;

  /// The cell of `rAxisID`, or Dart `null` when absent.
  Opt<String>? get rAxisIDCell => _rAxisID;

  /// Stores the cell of `rAxisID`. Dart `null` deletes the key.
  set rAxisIDCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.rAxisID);
    } else {
      store(OptionKey.rAxisID, cell);
    }
  }

  /// Stores the plain value [value] of `rAxisID`.
  set rAxisID(String value) =>
      store(OptionKey.rAxisID, OptValue<String>(value));

  Opt<bool>? _drawActiveElementsOnTop;

  /// The cell of `drawActiveElementsOnTop`, or Dart `null` when absent.
  Opt<bool>? get drawActiveElementsOnTopCell => _drawActiveElementsOnTop;

  /// Stores the cell of `drawActiveElementsOnTop`. Dart `null` deletes the key.
  set drawActiveElementsOnTopCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.drawActiveElementsOnTop);
    } else {
      store(OptionKey.drawActiveElementsOnTop, cell);
    }
  }

  /// Stores the plain value [value] of `drawActiveElementsOnTop`.
  set drawActiveElementsOnTop(bool value) =>
      store(OptionKey.drawActiveElementsOnTop, OptValue<bool>(value));

  Opt<ElementOptionsByTypeScope>? _elements;

  /// The cell of `elements`, or Dart `null` when absent.
  Opt<ElementOptionsByTypeScope>? get elementsCell => _elements;

  /// Stores the cell of `elements`. Dart `null` deletes the key.
  set elementsCell(Opt<ElementOptionsByTypeScope>? cell) {
    if (cell == null) {
      delete(OptionKey.elements);
    } else {
      store(OptionKey.elements, cell);
    }
  }

  /// Stores the plain value [value] of `elements`.
  set elements(ElementOptionsByTypeScope value) =>
      store(OptionKey.elements, OptScope<ElementOptionsByTypeScope>(value));

  Opt<Object>? _datasetElementType;

  /// The cell of `datasetElementType`, or Dart `null` when absent.
  Opt<Object>? get datasetElementTypeCell => _datasetElementType;

  /// Stores the cell of `datasetElementType`. Dart `null` deletes the key.
  set datasetElementTypeCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.datasetElementType);
    } else {
      store(OptionKey.datasetElementType, cell);
    }
  }

  /// Stores the plain value [value] of `datasetElementType`.
  set datasetElementType(Object value) => store(
    OptionKey.datasetElementType,
    classify(OptionKey.datasetElementType, value),
  );

  Opt<Object>? _dataElementType;

  /// The cell of `dataElementType`, or Dart `null` when absent.
  Opt<Object>? get dataElementTypeCell => _dataElementType;

  /// Stores the cell of `dataElementType`. Dart `null` deletes the key.
  set dataElementTypeCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.dataElementType);
    } else {
      store(OptionKey.dataElementType, cell);
    }
  }

  /// Stores the plain value [value] of `dataElementType`.
  set dataElementType(Object value) => store(
    OptionKey.dataElementType,
    classify(OptionKey.dataElementType, value),
  );

  Opt<Object>? _descData;

  /// The cell of `_data`, or Dart `null` when absent.
  Opt<Object>? get descDataCell => _descData;

  /// Stores the cell of `_data`. Dart `null` deletes the key.
  set descDataCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.descData);
    } else {
      store(OptionKey.descData, cell);
    }
  }

  /// Stores the plain value [value] of `_data`.
  set descData(Object value) =>
      store(OptionKey.descData, classify(OptionKey.descData, value));

  Opt<Object>? _descDecimated;

  /// The cell of `_decimated`, or Dart `null` when absent.
  Opt<Object>? get descDecimatedCell => _descDecimated;

  /// Stores the cell of `_decimated`. Dart `null` deletes the key.
  set descDecimatedCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.descDecimated);
    } else {
      store(OptionKey.descDecimated, cell);
    }
  }

  /// Stores the plain value [value] of `_decimated`.
  set descDecimated(Object value) =>
      store(OptionKey.descDecimated, classify(OptionKey.descDecimated, value));

  @override
  Opt<Object?>? cellOf(OptionKey key) => switch (key) {
    OptionKey.parsing => _parsing,
    OptionKey.normalized => _normalized,
    OptionKey.indexAxis => _indexAxis,
    OptionKey.clip => _clip,
    OptionKey.label => _label,
    OptionKey.order => _order,
    OptionKey.stack => _stack,
    OptionKey.hidden => _hidden,
    OptionKey.pointBackgroundColor => _pointBackgroundColor,
    OptionKey.pointBorderColor => _pointBorderColor,
    OptionKey.pointBorderWidth => _pointBorderWidth,
    OptionKey.pointHitRadius => _pointHitRadius,
    OptionKey.pointRadius => _pointRadius,
    OptionKey.pointRotation => _pointRotation,
    OptionKey.pointStyle => _pointStyle,
    OptionKey.pointHoverBackgroundColor => _pointHoverBackgroundColor,
    OptionKey.pointHoverBorderColor => _pointHoverBorderColor,
    OptionKey.pointHoverBorderWidth => _pointHoverBorderWidth,
    OptionKey.pointHoverRadius => _pointHoverRadius,
    OptionKey.borderCapStyle => _borderCapStyle,
    OptionKey.borderDash => _borderDash,
    OptionKey.borderDashOffset => _borderDashOffset,
    OptionKey.borderJoinStyle => _borderJoinStyle,
    OptionKey.capBezierPoints => _capBezierPoints,
    OptionKey.cubicInterpolationMode => _cubicInterpolationMode,
    OptionKey.tension => _tension,
    OptionKey.stepped => _stepped,
    OptionKey.fill => _fill,
    OptionKey.spanGaps => _spanGaps,
    OptionKey.segment => _segment,
    OptionKey.borderWidth => _borderWidth,
    OptionKey.borderColor => _borderColor,
    OptionKey.backgroundColor => _backgroundColor,
    OptionKey.hoverBorderCapStyle => _hoverBorderCapStyle,
    OptionKey.hoverBorderDash => _hoverBorderDash,
    OptionKey.hoverBorderDashOffset => _hoverBorderDashOffset,
    OptionKey.hoverBorderJoinStyle => _hoverBorderJoinStyle,
    OptionKey.hoverBorderWidth => _hoverBorderWidth,
    OptionKey.hoverBorderColor => _hoverBorderColor,
    OptionKey.hoverBackgroundColor => _hoverBackgroundColor,
    OptionKey.animation => _animation,
    OptionKey.animations => _animations,
    OptionKey.transitions => _transitions,
    OptionKey.xAxisID => _xAxisID,
    OptionKey.yAxisID => _yAxisID,
    OptionKey.showLine => _showLine,
    OptionKey.tooltip => _tooltip,
    OptionKey.type => _type,
    OptionKey.data => _data,
    OptionKey.rAxisID => _rAxisID,
    OptionKey.drawActiveElementsOnTop => _drawActiveElementsOnTop,
    OptionKey.elements => _elements,
    OptionKey.datasetElementType => _datasetElementType,
    OptionKey.dataElementType => _dataElementType,
    OptionKey.descData => _descData,
    OptionKey.descDecimated => _descDecimated,
    _ => null,
  };

  @override
  void setCell(OptionKey key, Opt<Object?>? cell) {
    switch (key) {
      case OptionKey.parsing:
        _parsing = fitCell(cell, (raw) => classifyUnion(raw, 34));
      case OptionKey.normalized:
        _normalized = fitCell(cell, classifyBool);
      case OptionKey.indexAxis:
        _indexAxis = fitCell(cell, classifyString);
      case OptionKey.clip:
        _clip = fitCell(cell, (raw) => classifyUnion(raw, 35));
      case OptionKey.label:
        _label = fitCell(cell, classifyString);
      case OptionKey.order:
        _order = fitCell(cell, classifyNumber);
      case OptionKey.stack:
        _stack = fitCell(cell, classifyString);
      case OptionKey.hidden:
        _hidden = fitCell(cell, classifyBool);
      case OptionKey.pointBackgroundColor:
        _pointBackgroundColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.pointBorderColor:
        _pointBorderColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.pointBorderWidth:
        _pointBorderWidth = fitCell(cell, classifyNumber);
      case OptionKey.pointHitRadius:
        _pointHitRadius = fitCell(cell, classifyNumber);
      case OptionKey.pointRadius:
        _pointRadius = fitCell(cell, classifyNumber);
      case OptionKey.pointRotation:
        _pointRotation = fitCell(cell, classifyNumber);
      case OptionKey.pointStyle:
        _pointStyle = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.pointHoverBackgroundColor:
        _pointHoverBackgroundColor = fitCell(
          cell,
          (raw) => classifyUnion(raw, 64),
        );
      case OptionKey.pointHoverBorderColor:
        _pointHoverBorderColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.pointHoverBorderWidth:
        _pointHoverBorderWidth = fitCell(cell, classifyNumber);
      case OptionKey.pointHoverRadius:
        _pointHoverRadius = fitCell(cell, classifyNumber);
      case OptionKey.borderCapStyle:
        _borderCapStyle = fitCell(cell, classifyString);
      case OptionKey.borderDash:
        _borderDash = fitCell(cell, (raw) => classifyUnion(raw, 16));
      case OptionKey.borderDashOffset:
        _borderDashOffset = fitCell(cell, classifyNumber);
      case OptionKey.borderJoinStyle:
        _borderJoinStyle = fitCell(cell, classifyString);
      case OptionKey.capBezierPoints:
        _capBezierPoints = fitCell(cell, classifyBool);
      case OptionKey.cubicInterpolationMode:
        _cubicInterpolationMode = fitCell(cell, classifyString);
      case OptionKey.tension:
        _tension = fitCell(cell, classifyNumber);
      case OptionKey.stepped:
        _stepped = fitCell(cell, (raw) => classifyUnion(raw, 6));
      case OptionKey.fill:
        _fill = fitCell(cell, (raw) => classifyUnion(raw, 39));
      case OptionKey.spanGaps:
        _spanGaps = fitCell(cell, (raw) => classifyUnion(raw, 3));
      case OptionKey.segment:
        _segment = fitCell(cell, classifyScope<SegmentOptionsScope>);
      case OptionKey.borderWidth:
        _borderWidth = fitCell(cell, classifyNumber);
      case OptionKey.borderColor:
        _borderColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.backgroundColor:
        _backgroundColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.hoverBorderCapStyle:
        _hoverBorderCapStyle = fitCell(cell, classifyString);
      case OptionKey.hoverBorderDash:
        _hoverBorderDash = fitCell(cell, (raw) => classifyUnion(raw, 16));
      case OptionKey.hoverBorderDashOffset:
        _hoverBorderDashOffset = fitCell(cell, classifyNumber);
      case OptionKey.hoverBorderJoinStyle:
        _hoverBorderJoinStyle = fitCell(cell, classifyString);
      case OptionKey.hoverBorderWidth:
        _hoverBorderWidth = fitCell(cell, classifyNumber);
      case OptionKey.hoverBorderColor:
        _hoverBorderColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.hoverBackgroundColor:
        _hoverBackgroundColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.animation:
        _animation = fitCell(cell, (raw) => classifyUnion(raw, 34));
      case OptionKey.animations:
        _animations = fitCell(cell, (raw) => classifyUnion(raw, 34));
      case OptionKey.transitions:
        _transitions = fitCell(cell, classifyScope<TransitionsSpecScope>);
      case OptionKey.xAxisID:
        _xAxisID = fitCell(cell, classifyString);
      case OptionKey.yAxisID:
        _yAxisID = fitCell(cell, classifyString);
      case OptionKey.showLine:
        _showLine = fitCell(cell, classifyBool);
      case OptionKey.tooltip:
        _tooltip = fitCell(cell, classifyScope<TooltipDatasetOptionsScope>);
      case OptionKey.type:
        _type = fitCell(cell, classifyString);
      case OptionKey.data:
        _data = fitCell(cell, (raw) => classifyUnion(raw, 16));
      case OptionKey.rAxisID:
        _rAxisID = fitCell(cell, classifyString);
      case OptionKey.drawActiveElementsOnTop:
        _drawActiveElementsOnTop = fitCell(cell, classifyBool);
      case OptionKey.elements:
        _elements = fitCell(cell, classifyScope<ElementOptionsByTypeScope>);
      case OptionKey.datasetElementType:
        _datasetElementType = fitCell(cell, (raw) => classifyUnion(raw, 6));
      case OptionKey.dataElementType:
        _dataElementType = fitCell(cell, (raw) => classifyUnion(raw, 6));
      case OptionKey.descData:
        _descData = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.descDecimated:
        _descDecimated = fitCell(cell, (raw) => classifyUnion(raw, 64));
      default:
        throw ArgumentError.value(
          key,
          'key',
          'Not a key of LineControllerDatasetOptions',
        );
    }
  }

  @override
  bool hasField(OptionKey key) => switch (key) {
    OptionKey.parsing ||
    OptionKey.normalized ||
    OptionKey.indexAxis ||
    OptionKey.clip ||
    OptionKey.label ||
    OptionKey.order ||
    OptionKey.stack ||
    OptionKey.hidden ||
    OptionKey.pointBackgroundColor ||
    OptionKey.pointBorderColor ||
    OptionKey.pointBorderWidth ||
    OptionKey.pointHitRadius ||
    OptionKey.pointRadius ||
    OptionKey.pointRotation ||
    OptionKey.pointStyle ||
    OptionKey.pointHoverBackgroundColor ||
    OptionKey.pointHoverBorderColor ||
    OptionKey.pointHoverBorderWidth ||
    OptionKey.pointHoverRadius ||
    OptionKey.borderCapStyle ||
    OptionKey.borderDash ||
    OptionKey.borderDashOffset ||
    OptionKey.borderJoinStyle ||
    OptionKey.capBezierPoints ||
    OptionKey.cubicInterpolationMode ||
    OptionKey.tension ||
    OptionKey.stepped ||
    OptionKey.fill ||
    OptionKey.spanGaps ||
    OptionKey.segment ||
    OptionKey.borderWidth ||
    OptionKey.borderColor ||
    OptionKey.backgroundColor ||
    OptionKey.hoverBorderCapStyle ||
    OptionKey.hoverBorderDash ||
    OptionKey.hoverBorderDashOffset ||
    OptionKey.hoverBorderJoinStyle ||
    OptionKey.hoverBorderWidth ||
    OptionKey.hoverBorderColor ||
    OptionKey.hoverBackgroundColor ||
    OptionKey.animation ||
    OptionKey.animations ||
    OptionKey.transitions ||
    OptionKey.xAxisID ||
    OptionKey.yAxisID ||
    OptionKey.showLine ||
    OptionKey.tooltip ||
    OptionKey.type ||
    OptionKey.data ||
    OptionKey.rAxisID ||
    OptionKey.drawActiveElementsOnTop ||
    OptionKey.elements ||
    OptionKey.datasetElementType ||
    OptionKey.dataElementType ||
    OptionKey.descData ||
    OptionKey.descDecimated => true,
    _ => false,
  };

  @override
  Opt<Object?> classify(OptionKey key, Object? raw) => switch (key) {
    OptionKey.parsing => classifyUnion(raw, 34),
    OptionKey.normalized => classifyBool(raw),
    OptionKey.indexAxis => classifyString(raw),
    OptionKey.clip => classifyUnion(raw, 35),
    OptionKey.label => classifyString(raw),
    OptionKey.order => classifyNumber(raw),
    OptionKey.stack => classifyString(raw),
    OptionKey.hidden => classifyBool(raw),
    OptionKey.pointBackgroundColor => classifyUnion(raw, 64),
    OptionKey.pointBorderColor => classifyUnion(raw, 64),
    OptionKey.pointBorderWidth => classifyNumber(raw),
    OptionKey.pointHitRadius => classifyNumber(raw),
    OptionKey.pointRadius => classifyNumber(raw),
    OptionKey.pointRotation => classifyNumber(raw),
    OptionKey.pointStyle => classifyUnion(raw, 64),
    OptionKey.pointHoverBackgroundColor => classifyUnion(raw, 64),
    OptionKey.pointHoverBorderColor => classifyUnion(raw, 64),
    OptionKey.pointHoverBorderWidth => classifyNumber(raw),
    OptionKey.pointHoverRadius => classifyNumber(raw),
    OptionKey.borderCapStyle => classifyString(raw),
    OptionKey.borderDash => classifyUnion(raw, 16),
    OptionKey.borderDashOffset => classifyNumber(raw),
    OptionKey.borderJoinStyle => classifyString(raw),
    OptionKey.capBezierPoints => classifyBool(raw),
    OptionKey.cubicInterpolationMode => classifyString(raw),
    OptionKey.tension => classifyNumber(raw),
    OptionKey.stepped => classifyUnion(raw, 6),
    OptionKey.fill => classifyUnion(raw, 39),
    OptionKey.spanGaps => classifyUnion(raw, 3),
    OptionKey.segment => classifyScope<SegmentOptionsScope>(raw),
    OptionKey.borderWidth => classifyNumber(raw),
    OptionKey.borderColor => classifyUnion(raw, 64),
    OptionKey.backgroundColor => classifyUnion(raw, 64),
    OptionKey.hoverBorderCapStyle => classifyString(raw),
    OptionKey.hoverBorderDash => classifyUnion(raw, 16),
    OptionKey.hoverBorderDashOffset => classifyNumber(raw),
    OptionKey.hoverBorderJoinStyle => classifyString(raw),
    OptionKey.hoverBorderWidth => classifyNumber(raw),
    OptionKey.hoverBorderColor => classifyUnion(raw, 64),
    OptionKey.hoverBackgroundColor => classifyUnion(raw, 64),
    OptionKey.animation => classifyUnion(raw, 34),
    OptionKey.animations => classifyUnion(raw, 34),
    OptionKey.transitions => classifyScope<TransitionsSpecScope>(raw),
    OptionKey.xAxisID => classifyString(raw),
    OptionKey.yAxisID => classifyString(raw),
    OptionKey.showLine => classifyBool(raw),
    OptionKey.tooltip => classifyScope<TooltipDatasetOptionsScope>(raw),
    OptionKey.type => classifyString(raw),
    OptionKey.data => classifyUnion(raw, 16),
    OptionKey.rAxisID => classifyString(raw),
    OptionKey.drawActiveElementsOnTop => classifyBool(raw),
    OptionKey.elements => classifyScope<ElementOptionsByTypeScope>(raw),
    OptionKey.datasetElementType => classifyUnion(raw, 6),
    OptionKey.dataElementType => classifyUnion(raw, 6),
    OptionKey.descData => classifyUnion(raw, 64),
    OptionKey.descDecimated => classifyUnion(raw, 64),
    _ => kind.classifyOther(raw),
  };
}

/// index.d.ts:162 BubbleControllerDatasetOptions (index.d.ts:66
/// ControllerDatasetOptions, PointOptions, PointHoverOptions), a bubble dataset
/// and `datasets.bubble`.
base class BubbleControllerDatasetOptionsScope extends OptionScope {
  /// An empty scope.
  BubbleControllerDatasetOptionsScope();

  @override
  ScopeKind get kind => ScopeKind.bubbleControllerDatasetOptions;

  Opt<Object>? _parsing;

  /// The cell of `parsing`, or Dart `null` when absent.
  Opt<Object>? get parsingCell => _parsing;

  /// Stores the cell of `parsing`. Dart `null` deletes the key.
  set parsingCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.parsing);
    } else {
      store(OptionKey.parsing, cell);
    }
  }

  /// Stores the plain value [value] of `parsing`.
  set parsing(Object value) =>
      store(OptionKey.parsing, classify(OptionKey.parsing, value));

  Opt<bool>? _normalized;

  /// The cell of `normalized`, or Dart `null` when absent.
  Opt<bool>? get normalizedCell => _normalized;

  /// Stores the cell of `normalized`. Dart `null` deletes the key.
  set normalizedCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.normalized);
    } else {
      store(OptionKey.normalized, cell);
    }
  }

  /// Stores the plain value [value] of `normalized`.
  set normalized(bool value) =>
      store(OptionKey.normalized, OptValue<bool>(value));

  Opt<String>? _indexAxis;

  /// The cell of `indexAxis`, or Dart `null` when absent.
  Opt<String>? get indexAxisCell => _indexAxis;

  /// Stores the cell of `indexAxis`. Dart `null` deletes the key.
  set indexAxisCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.indexAxis);
    } else {
      store(OptionKey.indexAxis, cell);
    }
  }

  /// Stores the plain value [value] of `indexAxis`.
  set indexAxis(String value) =>
      store(OptionKey.indexAxis, OptValue<String>(value));

  Opt<Object>? _clip;

  /// The cell of `clip`, or Dart `null` when absent.
  Opt<Object>? get clipCell => _clip;

  /// Stores the cell of `clip`. Dart `null` deletes the key.
  set clipCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.clip);
    } else {
      store(OptionKey.clip, cell);
    }
  }

  /// Stores the plain value [value] of `clip`.
  set clip(Object value) =>
      store(OptionKey.clip, classify(OptionKey.clip, value));

  Opt<String>? _label;

  /// The cell of `label`, or Dart `null` when absent.
  Opt<String>? get labelCell => _label;

  /// Stores the cell of `label`. Dart `null` deletes the key.
  set labelCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.label);
    } else {
      store(OptionKey.label, cell);
    }
  }

  /// Stores the plain value [value] of `label`.
  set label(String value) => store(OptionKey.label, OptValue<String>(value));

  Opt<double>? _order;

  /// The cell of `order`, or Dart `null` when absent.
  Opt<double>? get orderCell => _order;

  /// Stores the cell of `order`. Dart `null` deletes the key.
  set orderCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.order);
    } else {
      store(OptionKey.order, cell);
    }
  }

  /// Stores the plain value [value] of `order`.
  set order(double value) => store(OptionKey.order, OptValue<double>(value));

  Opt<String>? _stack;

  /// The cell of `stack`, or Dart `null` when absent.
  Opt<String>? get stackCell => _stack;

  /// Stores the cell of `stack`. Dart `null` deletes the key.
  set stackCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.stack);
    } else {
      store(OptionKey.stack, cell);
    }
  }

  /// Stores the plain value [value] of `stack`.
  set stack(String value) => store(OptionKey.stack, OptValue<String>(value));

  Opt<bool>? _hidden;

  /// The cell of `hidden`, or Dart `null` when absent.
  Opt<bool>? get hiddenCell => _hidden;

  /// Stores the cell of `hidden`. Dart `null` deletes the key.
  set hiddenCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.hidden);
    } else {
      store(OptionKey.hidden, cell);
    }
  }

  /// Stores the plain value [value] of `hidden`.
  set hidden(bool value) => store(OptionKey.hidden, OptValue<bool>(value));

  Opt<double>? _borderWidth;

  /// The cell of `borderWidth`, or Dart `null` when absent.
  Opt<double>? get borderWidthCell => _borderWidth;

  /// Stores the cell of `borderWidth`. Dart `null` deletes the key.
  set borderWidthCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.borderWidth);
    } else {
      store(OptionKey.borderWidth, cell);
    }
  }

  /// Stores the plain value [value] of `borderWidth`.
  set borderWidth(double value) =>
      store(OptionKey.borderWidth, OptValue<double>(value));

  Opt<Object>? _borderColor;

  /// The cell of `borderColor`, or Dart `null` when absent.
  Opt<Object>? get borderColorCell => _borderColor;

  /// Stores the cell of `borderColor`. Dart `null` deletes the key.
  set borderColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.borderColor);
    } else {
      store(OptionKey.borderColor, cell);
    }
  }

  /// Stores the plain value [value] of `borderColor`.
  set borderColor(Object value) =>
      store(OptionKey.borderColor, classify(OptionKey.borderColor, value));

  Opt<Object>? _backgroundColor;

  /// The cell of `backgroundColor`, or Dart `null` when absent.
  Opt<Object>? get backgroundColorCell => _backgroundColor;

  /// Stores the cell of `backgroundColor`. Dart `null` deletes the key.
  set backgroundColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.backgroundColor);
    } else {
      store(OptionKey.backgroundColor, cell);
    }
  }

  /// Stores the plain value [value] of `backgroundColor`.
  set backgroundColor(Object value) => store(
    OptionKey.backgroundColor,
    classify(OptionKey.backgroundColor, value),
  );

  Opt<double>? _radius;

  /// The cell of `radius`, or Dart `null` when absent.
  Opt<double>? get radiusCell => _radius;

  /// Stores the cell of `radius`. Dart `null` deletes the key.
  set radiusCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.radius);
    } else {
      store(OptionKey.radius, cell);
    }
  }

  /// Stores the plain value [value] of `radius`.
  set radius(double value) => store(OptionKey.radius, OptValue<double>(value));

  Opt<double>? _hitRadius;

  /// The cell of `hitRadius`, or Dart `null` when absent.
  Opt<double>? get hitRadiusCell => _hitRadius;

  /// Stores the cell of `hitRadius`. Dart `null` deletes the key.
  set hitRadiusCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.hitRadius);
    } else {
      store(OptionKey.hitRadius, cell);
    }
  }

  /// Stores the plain value [value] of `hitRadius`.
  set hitRadius(double value) =>
      store(OptionKey.hitRadius, OptValue<double>(value));

  Opt<Object>? _pointStyle;

  /// The cell of `pointStyle`, or Dart `null` when absent.
  Opt<Object>? get pointStyleCell => _pointStyle;

  /// Stores the cell of `pointStyle`. Dart `null` deletes the key.
  set pointStyleCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.pointStyle);
    } else {
      store(OptionKey.pointStyle, cell);
    }
  }

  /// Stores the plain value [value] of `pointStyle`.
  set pointStyle(Object value) =>
      store(OptionKey.pointStyle, classify(OptionKey.pointStyle, value));

  Opt<double>? _rotation;

  /// The cell of `rotation`, or Dart `null` when absent.
  Opt<double>? get rotationCell => _rotation;

  /// Stores the cell of `rotation`. Dart `null` deletes the key.
  set rotationCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.rotation);
    } else {
      store(OptionKey.rotation, cell);
    }
  }

  /// Stores the plain value [value] of `rotation`.
  set rotation(double value) =>
      store(OptionKey.rotation, OptValue<double>(value));

  Opt<bool>? _drawActiveElementsOnTop;

  /// The cell of `drawActiveElementsOnTop`, or Dart `null` when absent.
  Opt<bool>? get drawActiveElementsOnTopCell => _drawActiveElementsOnTop;

  /// Stores the cell of `drawActiveElementsOnTop`. Dart `null` deletes the key.
  set drawActiveElementsOnTopCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.drawActiveElementsOnTop);
    } else {
      store(OptionKey.drawActiveElementsOnTop, cell);
    }
  }

  /// Stores the plain value [value] of `drawActiveElementsOnTop`.
  set drawActiveElementsOnTop(bool value) =>
      store(OptionKey.drawActiveElementsOnTop, OptValue<bool>(value));

  Opt<double>? _hoverBorderWidth;

  /// The cell of `hoverBorderWidth`, or Dart `null` when absent.
  Opt<double>? get hoverBorderWidthCell => _hoverBorderWidth;

  /// Stores the cell of `hoverBorderWidth`. Dart `null` deletes the key.
  set hoverBorderWidthCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBorderWidth);
    } else {
      store(OptionKey.hoverBorderWidth, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBorderWidth`.
  set hoverBorderWidth(double value) =>
      store(OptionKey.hoverBorderWidth, OptValue<double>(value));

  Opt<Object>? _hoverBorderColor;

  /// The cell of `hoverBorderColor`, or Dart `null` when absent.
  Opt<Object>? get hoverBorderColorCell => _hoverBorderColor;

  /// Stores the cell of `hoverBorderColor`. Dart `null` deletes the key.
  set hoverBorderColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBorderColor);
    } else {
      store(OptionKey.hoverBorderColor, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBorderColor`.
  set hoverBorderColor(Object value) => store(
    OptionKey.hoverBorderColor,
    classify(OptionKey.hoverBorderColor, value),
  );

  Opt<Object>? _hoverBackgroundColor;

  /// The cell of `hoverBackgroundColor`, or Dart `null` when absent.
  Opt<Object>? get hoverBackgroundColorCell => _hoverBackgroundColor;

  /// Stores the cell of `hoverBackgroundColor`. Dart `null` deletes the key.
  set hoverBackgroundColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBackgroundColor);
    } else {
      store(OptionKey.hoverBackgroundColor, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBackgroundColor`.
  set hoverBackgroundColor(Object value) => store(
    OptionKey.hoverBackgroundColor,
    classify(OptionKey.hoverBackgroundColor, value),
  );

  Opt<double>? _hoverRadius;

  /// The cell of `hoverRadius`, or Dart `null` when absent.
  Opt<double>? get hoverRadiusCell => _hoverRadius;

  /// Stores the cell of `hoverRadius`. Dart `null` deletes the key.
  set hoverRadiusCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverRadius);
    } else {
      store(OptionKey.hoverRadius, cell);
    }
  }

  /// Stores the plain value [value] of `hoverRadius`.
  set hoverRadius(double value) =>
      store(OptionKey.hoverRadius, OptValue<double>(value));

  Opt<String>? _xAxisID;

  /// The cell of `xAxisID`, or Dart `null` when absent.
  Opt<String>? get xAxisIDCell => _xAxisID;

  /// Stores the cell of `xAxisID`. Dart `null` deletes the key.
  set xAxisIDCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.xAxisID);
    } else {
      store(OptionKey.xAxisID, cell);
    }
  }

  /// Stores the plain value [value] of `xAxisID`.
  set xAxisID(String value) =>
      store(OptionKey.xAxisID, OptValue<String>(value));

  Opt<String>? _yAxisID;

  /// The cell of `yAxisID`, or Dart `null` when absent.
  Opt<String>? get yAxisIDCell => _yAxisID;

  /// Stores the cell of `yAxisID`. Dart `null` deletes the key.
  set yAxisIDCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.yAxisID);
    } else {
      store(OptionKey.yAxisID, cell);
    }
  }

  /// Stores the plain value [value] of `yAxisID`.
  set yAxisID(String value) =>
      store(OptionKey.yAxisID, OptValue<String>(value));

  Opt<TooltipDatasetOptionsScope>? _tooltip;

  /// The cell of `tooltip`, or Dart `null` when absent.
  Opt<TooltipDatasetOptionsScope>? get tooltipCell => _tooltip;

  /// Stores the cell of `tooltip`. Dart `null` deletes the key.
  set tooltipCell(Opt<TooltipDatasetOptionsScope>? cell) {
    if (cell == null) {
      delete(OptionKey.tooltip);
    } else {
      store(OptionKey.tooltip, cell);
    }
  }

  /// Stores the plain value [value] of `tooltip`.
  set tooltip(TooltipDatasetOptionsScope value) =>
      store(OptionKey.tooltip, OptScope<TooltipDatasetOptionsScope>(value));

  Opt<String>? _type;

  /// The cell of `type`, or Dart `null` when absent.
  Opt<String>? get typeCell => _type;

  /// Stores the cell of `type`. Dart `null` deletes the key.
  set typeCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.type);
    } else {
      store(OptionKey.type, cell);
    }
  }

  /// Stores the plain value [value] of `type`.
  set type(String value) => store(OptionKey.type, OptValue<String>(value));

  Opt<Object>? _data;

  /// The cell of `data`, or Dart `null` when absent.
  Opt<Object>? get dataCell => _data;

  /// Stores the cell of `data`. Dart `null` deletes the key.
  set dataCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.data);
    } else {
      store(OptionKey.data, cell);
    }
  }

  /// Stores the plain value [value] of `data`.
  set data(Object value) =>
      store(OptionKey.data, classify(OptionKey.data, value));

  Opt<Object>? _animation;

  /// The cell of `animation`, or Dart `null` when absent.
  Opt<Object>? get animationCell => _animation;

  /// Stores the cell of `animation`. Dart `null` deletes the key.
  set animationCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.animation);
    } else {
      store(OptionKey.animation, cell);
    }
  }

  /// Stores the plain value [value] of `animation`.
  set animation(Object value) =>
      store(OptionKey.animation, classify(OptionKey.animation, value));

  Opt<Object>? _animations;

  /// The cell of `animations`, or Dart `null` when absent.
  Opt<Object>? get animationsCell => _animations;

  /// Stores the cell of `animations`. Dart `null` deletes the key.
  set animationsCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.animations);
    } else {
      store(OptionKey.animations, cell);
    }
  }

  /// Stores the plain value [value] of `animations`.
  set animations(Object value) =>
      store(OptionKey.animations, classify(OptionKey.animations, value));

  Opt<TransitionsSpecScope>? _transitions;

  /// The cell of `transitions`, or Dart `null` when absent.
  Opt<TransitionsSpecScope>? get transitionsCell => _transitions;

  /// Stores the cell of `transitions`. Dart `null` deletes the key.
  set transitionsCell(Opt<TransitionsSpecScope>? cell) {
    if (cell == null) {
      delete(OptionKey.transitions);
    } else {
      store(OptionKey.transitions, cell);
    }
  }

  /// Stores the plain value [value] of `transitions`.
  set transitions(TransitionsSpecScope value) =>
      store(OptionKey.transitions, OptScope<TransitionsSpecScope>(value));

  Opt<String>? _rAxisID;

  /// The cell of `rAxisID`, or Dart `null` when absent.
  Opt<String>? get rAxisIDCell => _rAxisID;

  /// Stores the cell of `rAxisID`. Dart `null` deletes the key.
  set rAxisIDCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.rAxisID);
    } else {
      store(OptionKey.rAxisID, cell);
    }
  }

  /// Stores the plain value [value] of `rAxisID`.
  set rAxisID(String value) =>
      store(OptionKey.rAxisID, OptValue<String>(value));

  Opt<Object>? _fill;

  /// The cell of `fill`, or Dart `null` when absent.
  Opt<Object>? get fillCell => _fill;

  /// Stores the cell of `fill`. Dart `null` deletes the key.
  set fillCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.fill);
    } else {
      store(OptionKey.fill, cell);
    }
  }

  /// Stores the plain value [value] of `fill`.
  set fill(Object value) =>
      store(OptionKey.fill, classify(OptionKey.fill, value));

  Opt<ElementOptionsByTypeScope>? _elements;

  /// The cell of `elements`, or Dart `null` when absent.
  Opt<ElementOptionsByTypeScope>? get elementsCell => _elements;

  /// Stores the cell of `elements`. Dart `null` deletes the key.
  set elementsCell(Opt<ElementOptionsByTypeScope>? cell) {
    if (cell == null) {
      delete(OptionKey.elements);
    } else {
      store(OptionKey.elements, cell);
    }
  }

  /// Stores the plain value [value] of `elements`.
  set elements(ElementOptionsByTypeScope value) =>
      store(OptionKey.elements, OptScope<ElementOptionsByTypeScope>(value));

  Opt<Object>? _datasetElementType;

  /// The cell of `datasetElementType`, or Dart `null` when absent.
  Opt<Object>? get datasetElementTypeCell => _datasetElementType;

  /// Stores the cell of `datasetElementType`. Dart `null` deletes the key.
  set datasetElementTypeCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.datasetElementType);
    } else {
      store(OptionKey.datasetElementType, cell);
    }
  }

  /// Stores the plain value [value] of `datasetElementType`.
  set datasetElementType(Object value) => store(
    OptionKey.datasetElementType,
    classify(OptionKey.datasetElementType, value),
  );

  Opt<Object>? _dataElementType;

  /// The cell of `dataElementType`, or Dart `null` when absent.
  Opt<Object>? get dataElementTypeCell => _dataElementType;

  /// Stores the cell of `dataElementType`. Dart `null` deletes the key.
  set dataElementTypeCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.dataElementType);
    } else {
      store(OptionKey.dataElementType, cell);
    }
  }

  /// Stores the plain value [value] of `dataElementType`.
  set dataElementType(Object value) => store(
    OptionKey.dataElementType,
    classify(OptionKey.dataElementType, value),
  );

  Opt<Object>? _descData;

  /// The cell of `_data`, or Dart `null` when absent.
  Opt<Object>? get descDataCell => _descData;

  /// Stores the cell of `_data`. Dart `null` deletes the key.
  set descDataCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.descData);
    } else {
      store(OptionKey.descData, cell);
    }
  }

  /// Stores the plain value [value] of `_data`.
  set descData(Object value) =>
      store(OptionKey.descData, classify(OptionKey.descData, value));

  Opt<Object>? _descDecimated;

  /// The cell of `_decimated`, or Dart `null` when absent.
  Opt<Object>? get descDecimatedCell => _descDecimated;

  /// Stores the cell of `_decimated`. Dart `null` deletes the key.
  set descDecimatedCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.descDecimated);
    } else {
      store(OptionKey.descDecimated, cell);
    }
  }

  /// Stores the plain value [value] of `_decimated`.
  set descDecimated(Object value) =>
      store(OptionKey.descDecimated, classify(OptionKey.descDecimated, value));

  @override
  Opt<Object?>? cellOf(OptionKey key) => switch (key) {
    OptionKey.parsing => _parsing,
    OptionKey.normalized => _normalized,
    OptionKey.indexAxis => _indexAxis,
    OptionKey.clip => _clip,
    OptionKey.label => _label,
    OptionKey.order => _order,
    OptionKey.stack => _stack,
    OptionKey.hidden => _hidden,
    OptionKey.borderWidth => _borderWidth,
    OptionKey.borderColor => _borderColor,
    OptionKey.backgroundColor => _backgroundColor,
    OptionKey.radius => _radius,
    OptionKey.hitRadius => _hitRadius,
    OptionKey.pointStyle => _pointStyle,
    OptionKey.rotation => _rotation,
    OptionKey.drawActiveElementsOnTop => _drawActiveElementsOnTop,
    OptionKey.hoverBorderWidth => _hoverBorderWidth,
    OptionKey.hoverBorderColor => _hoverBorderColor,
    OptionKey.hoverBackgroundColor => _hoverBackgroundColor,
    OptionKey.hoverRadius => _hoverRadius,
    OptionKey.xAxisID => _xAxisID,
    OptionKey.yAxisID => _yAxisID,
    OptionKey.tooltip => _tooltip,
    OptionKey.type => _type,
    OptionKey.data => _data,
    OptionKey.animation => _animation,
    OptionKey.animations => _animations,
    OptionKey.transitions => _transitions,
    OptionKey.rAxisID => _rAxisID,
    OptionKey.fill => _fill,
    OptionKey.elements => _elements,
    OptionKey.datasetElementType => _datasetElementType,
    OptionKey.dataElementType => _dataElementType,
    OptionKey.descData => _descData,
    OptionKey.descDecimated => _descDecimated,
    _ => null,
  };

  @override
  void setCell(OptionKey key, Opt<Object?>? cell) {
    switch (key) {
      case OptionKey.parsing:
        _parsing = fitCell(cell, (raw) => classifyUnion(raw, 34));
      case OptionKey.normalized:
        _normalized = fitCell(cell, classifyBool);
      case OptionKey.indexAxis:
        _indexAxis = fitCell(cell, classifyString);
      case OptionKey.clip:
        _clip = fitCell(cell, (raw) => classifyUnion(raw, 35));
      case OptionKey.label:
        _label = fitCell(cell, classifyString);
      case OptionKey.order:
        _order = fitCell(cell, classifyNumber);
      case OptionKey.stack:
        _stack = fitCell(cell, classifyString);
      case OptionKey.hidden:
        _hidden = fitCell(cell, classifyBool);
      case OptionKey.borderWidth:
        _borderWidth = fitCell(cell, classifyNumber);
      case OptionKey.borderColor:
        _borderColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.backgroundColor:
        _backgroundColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.radius:
        _radius = fitCell(cell, classifyNumber);
      case OptionKey.hitRadius:
        _hitRadius = fitCell(cell, classifyNumber);
      case OptionKey.pointStyle:
        _pointStyle = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.rotation:
        _rotation = fitCell(cell, classifyNumber);
      case OptionKey.drawActiveElementsOnTop:
        _drawActiveElementsOnTop = fitCell(cell, classifyBool);
      case OptionKey.hoverBorderWidth:
        _hoverBorderWidth = fitCell(cell, classifyNumber);
      case OptionKey.hoverBorderColor:
        _hoverBorderColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.hoverBackgroundColor:
        _hoverBackgroundColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.hoverRadius:
        _hoverRadius = fitCell(cell, classifyNumber);
      case OptionKey.xAxisID:
        _xAxisID = fitCell(cell, classifyString);
      case OptionKey.yAxisID:
        _yAxisID = fitCell(cell, classifyString);
      case OptionKey.tooltip:
        _tooltip = fitCell(cell, classifyScope<TooltipDatasetOptionsScope>);
      case OptionKey.type:
        _type = fitCell(cell, classifyString);
      case OptionKey.data:
        _data = fitCell(cell, (raw) => classifyUnion(raw, 16));
      case OptionKey.animation:
        _animation = fitCell(cell, (raw) => classifyUnion(raw, 34));
      case OptionKey.animations:
        _animations = fitCell(cell, (raw) => classifyUnion(raw, 34));
      case OptionKey.transitions:
        _transitions = fitCell(cell, classifyScope<TransitionsSpecScope>);
      case OptionKey.rAxisID:
        _rAxisID = fitCell(cell, classifyString);
      case OptionKey.fill:
        _fill = fitCell(cell, (raw) => classifyUnion(raw, 39));
      case OptionKey.elements:
        _elements = fitCell(cell, classifyScope<ElementOptionsByTypeScope>);
      case OptionKey.datasetElementType:
        _datasetElementType = fitCell(cell, (raw) => classifyUnion(raw, 6));
      case OptionKey.dataElementType:
        _dataElementType = fitCell(cell, (raw) => classifyUnion(raw, 6));
      case OptionKey.descData:
        _descData = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.descDecimated:
        _descDecimated = fitCell(cell, (raw) => classifyUnion(raw, 64));
      default:
        throw ArgumentError.value(
          key,
          'key',
          'Not a key of BubbleControllerDatasetOptions',
        );
    }
  }

  @override
  bool hasField(OptionKey key) => switch (key) {
    OptionKey.parsing ||
    OptionKey.normalized ||
    OptionKey.indexAxis ||
    OptionKey.clip ||
    OptionKey.label ||
    OptionKey.order ||
    OptionKey.stack ||
    OptionKey.hidden ||
    OptionKey.borderWidth ||
    OptionKey.borderColor ||
    OptionKey.backgroundColor ||
    OptionKey.radius ||
    OptionKey.hitRadius ||
    OptionKey.pointStyle ||
    OptionKey.rotation ||
    OptionKey.drawActiveElementsOnTop ||
    OptionKey.hoverBorderWidth ||
    OptionKey.hoverBorderColor ||
    OptionKey.hoverBackgroundColor ||
    OptionKey.hoverRadius ||
    OptionKey.xAxisID ||
    OptionKey.yAxisID ||
    OptionKey.tooltip ||
    OptionKey.type ||
    OptionKey.data ||
    OptionKey.animation ||
    OptionKey.animations ||
    OptionKey.transitions ||
    OptionKey.rAxisID ||
    OptionKey.fill ||
    OptionKey.elements ||
    OptionKey.datasetElementType ||
    OptionKey.dataElementType ||
    OptionKey.descData ||
    OptionKey.descDecimated => true,
    _ => false,
  };

  @override
  Opt<Object?> classify(OptionKey key, Object? raw) => switch (key) {
    OptionKey.parsing => classifyUnion(raw, 34),
    OptionKey.normalized => classifyBool(raw),
    OptionKey.indexAxis => classifyString(raw),
    OptionKey.clip => classifyUnion(raw, 35),
    OptionKey.label => classifyString(raw),
    OptionKey.order => classifyNumber(raw),
    OptionKey.stack => classifyString(raw),
    OptionKey.hidden => classifyBool(raw),
    OptionKey.borderWidth => classifyNumber(raw),
    OptionKey.borderColor => classifyUnion(raw, 64),
    OptionKey.backgroundColor => classifyUnion(raw, 64),
    OptionKey.radius => classifyNumber(raw),
    OptionKey.hitRadius => classifyNumber(raw),
    OptionKey.pointStyle => classifyUnion(raw, 64),
    OptionKey.rotation => classifyNumber(raw),
    OptionKey.drawActiveElementsOnTop => classifyBool(raw),
    OptionKey.hoverBorderWidth => classifyNumber(raw),
    OptionKey.hoverBorderColor => classifyUnion(raw, 64),
    OptionKey.hoverBackgroundColor => classifyUnion(raw, 64),
    OptionKey.hoverRadius => classifyNumber(raw),
    OptionKey.xAxisID => classifyString(raw),
    OptionKey.yAxisID => classifyString(raw),
    OptionKey.tooltip => classifyScope<TooltipDatasetOptionsScope>(raw),
    OptionKey.type => classifyString(raw),
    OptionKey.data => classifyUnion(raw, 16),
    OptionKey.animation => classifyUnion(raw, 34),
    OptionKey.animations => classifyUnion(raw, 34),
    OptionKey.transitions => classifyScope<TransitionsSpecScope>(raw),
    OptionKey.rAxisID => classifyString(raw),
    OptionKey.fill => classifyUnion(raw, 39),
    OptionKey.elements => classifyScope<ElementOptionsByTypeScope>(raw),
    OptionKey.datasetElementType => classifyUnion(raw, 6),
    OptionKey.dataElementType => classifyUnion(raw, 6),
    OptionKey.descData => classifyUnion(raw, 64),
    OptionKey.descDecimated => classifyUnion(raw, 64),
    _ => kind.classifyOther(raw),
  };
}

/// index.d.ts:247 DoughnutControllerDatasetOptions (index.d.ts:66
/// ControllerDatasetOptions, ArcOptions, ArcHoverOptions, AnimationOptions)
/// with index.d.ts:307 DoughnutControllerChartOptions, a doughnut or pie
/// dataset and `datasets.doughnut`, `datasets.pie`.
base class DoughnutControllerDatasetOptionsScope extends OptionScope {
  /// An empty scope.
  DoughnutControllerDatasetOptionsScope();

  @override
  ScopeKind get kind => ScopeKind.doughnutControllerDatasetOptions;

  Opt<Object>? _parsing;

  /// The cell of `parsing`, or Dart `null` when absent.
  Opt<Object>? get parsingCell => _parsing;

  /// Stores the cell of `parsing`. Dart `null` deletes the key.
  set parsingCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.parsing);
    } else {
      store(OptionKey.parsing, cell);
    }
  }

  /// Stores the plain value [value] of `parsing`.
  set parsing(Object value) =>
      store(OptionKey.parsing, classify(OptionKey.parsing, value));

  Opt<bool>? _normalized;

  /// The cell of `normalized`, or Dart `null` when absent.
  Opt<bool>? get normalizedCell => _normalized;

  /// Stores the cell of `normalized`. Dart `null` deletes the key.
  set normalizedCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.normalized);
    } else {
      store(OptionKey.normalized, cell);
    }
  }

  /// Stores the plain value [value] of `normalized`.
  set normalized(bool value) =>
      store(OptionKey.normalized, OptValue<bool>(value));

  Opt<String>? _indexAxis;

  /// The cell of `indexAxis`, or Dart `null` when absent.
  Opt<String>? get indexAxisCell => _indexAxis;

  /// Stores the cell of `indexAxis`. Dart `null` deletes the key.
  set indexAxisCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.indexAxis);
    } else {
      store(OptionKey.indexAxis, cell);
    }
  }

  /// Stores the plain value [value] of `indexAxis`.
  set indexAxis(String value) =>
      store(OptionKey.indexAxis, OptValue<String>(value));

  Opt<Object>? _clip;

  /// The cell of `clip`, or Dart `null` when absent.
  Opt<Object>? get clipCell => _clip;

  /// Stores the cell of `clip`. Dart `null` deletes the key.
  set clipCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.clip);
    } else {
      store(OptionKey.clip, cell);
    }
  }

  /// Stores the plain value [value] of `clip`.
  set clip(Object value) =>
      store(OptionKey.clip, classify(OptionKey.clip, value));

  Opt<String>? _label;

  /// The cell of `label`, or Dart `null` when absent.
  Opt<String>? get labelCell => _label;

  /// Stores the cell of `label`. Dart `null` deletes the key.
  set labelCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.label);
    } else {
      store(OptionKey.label, cell);
    }
  }

  /// Stores the plain value [value] of `label`.
  set label(String value) => store(OptionKey.label, OptValue<String>(value));

  Opt<double>? _order;

  /// The cell of `order`, or Dart `null` when absent.
  Opt<double>? get orderCell => _order;

  /// Stores the cell of `order`. Dart `null` deletes the key.
  set orderCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.order);
    } else {
      store(OptionKey.order, cell);
    }
  }

  /// Stores the plain value [value] of `order`.
  set order(double value) => store(OptionKey.order, OptValue<double>(value));

  Opt<String>? _stack;

  /// The cell of `stack`, or Dart `null` when absent.
  Opt<String>? get stackCell => _stack;

  /// Stores the cell of `stack`. Dart `null` deletes the key.
  set stackCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.stack);
    } else {
      store(OptionKey.stack, cell);
    }
  }

  /// Stores the plain value [value] of `stack`.
  set stack(String value) => store(OptionKey.stack, OptValue<String>(value));

  Opt<bool>? _hidden;

  /// The cell of `hidden`, or Dart `null` when absent.
  Opt<bool>? get hiddenCell => _hidden;

  /// Stores the cell of `hidden`. Dart `null` deletes the key.
  set hiddenCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.hidden);
    } else {
      store(OptionKey.hidden, cell);
    }
  }

  /// Stores the plain value [value] of `hidden`.
  set hidden(bool value) => store(OptionKey.hidden, OptValue<bool>(value));

  Opt<double>? _borderWidth;

  /// The cell of `borderWidth`, or Dart `null` when absent.
  Opt<double>? get borderWidthCell => _borderWidth;

  /// Stores the cell of `borderWidth`. Dart `null` deletes the key.
  set borderWidthCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.borderWidth);
    } else {
      store(OptionKey.borderWidth, cell);
    }
  }

  /// Stores the plain value [value] of `borderWidth`.
  set borderWidth(double value) =>
      store(OptionKey.borderWidth, OptValue<double>(value));

  Opt<Object>? _borderColor;

  /// The cell of `borderColor`, or Dart `null` when absent.
  Opt<Object>? get borderColorCell => _borderColor;

  /// Stores the cell of `borderColor`. Dart `null` deletes the key.
  set borderColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.borderColor);
    } else {
      store(OptionKey.borderColor, cell);
    }
  }

  /// Stores the plain value [value] of `borderColor`.
  set borderColor(Object value) =>
      store(OptionKey.borderColor, classify(OptionKey.borderColor, value));

  Opt<Object>? _backgroundColor;

  /// The cell of `backgroundColor`, or Dart `null` when absent.
  Opt<Object>? get backgroundColorCell => _backgroundColor;

  /// Stores the cell of `backgroundColor`. Dart `null` deletes the key.
  set backgroundColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.backgroundColor);
    } else {
      store(OptionKey.backgroundColor, cell);
    }
  }

  /// Stores the plain value [value] of `backgroundColor`.
  set backgroundColor(Object value) => store(
    OptionKey.backgroundColor,
    classify(OptionKey.backgroundColor, value),
  );

  Opt<bool>? _selfJoin;

  /// The cell of `selfJoin`, or Dart `null` when absent.
  Opt<bool>? get selfJoinCell => _selfJoin;

  /// Stores the cell of `selfJoin`. Dart `null` deletes the key.
  set selfJoinCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.selfJoin);
    } else {
      store(OptionKey.selfJoin, cell);
    }
  }

  /// Stores the plain value [value] of `selfJoin`.
  set selfJoin(bool value) => store(OptionKey.selfJoin, OptValue<bool>(value));

  Opt<String>? _borderAlign;

  /// The cell of `borderAlign`, or Dart `null` when absent.
  Opt<String>? get borderAlignCell => _borderAlign;

  /// Stores the cell of `borderAlign`. Dart `null` deletes the key.
  set borderAlignCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.borderAlign);
    } else {
      store(OptionKey.borderAlign, cell);
    }
  }

  /// Stores the plain value [value] of `borderAlign`.
  set borderAlign(String value) =>
      store(OptionKey.borderAlign, OptValue<String>(value));

  Opt<Object>? _borderDash;

  /// The cell of `borderDash`, or Dart `null` when absent.
  Opt<Object>? get borderDashCell => _borderDash;

  /// Stores the cell of `borderDash`. Dart `null` deletes the key.
  set borderDashCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.borderDash);
    } else {
      store(OptionKey.borderDash, cell);
    }
  }

  /// Stores the plain value [value] of `borderDash`.
  set borderDash(Object value) =>
      store(OptionKey.borderDash, classify(OptionKey.borderDash, value));

  Opt<double>? _borderDashOffset;

  /// The cell of `borderDashOffset`, or Dart `null` when absent.
  Opt<double>? get borderDashOffsetCell => _borderDashOffset;

  /// Stores the cell of `borderDashOffset`. Dart `null` deletes the key.
  set borderDashOffsetCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.borderDashOffset);
    } else {
      store(OptionKey.borderDashOffset, cell);
    }
  }

  /// Stores the plain value [value] of `borderDashOffset`.
  set borderDashOffset(double value) =>
      store(OptionKey.borderDashOffset, OptValue<double>(value));

  Opt<String>? _borderJoinStyle;

  /// The cell of `borderJoinStyle`, or Dart `null` when absent.
  Opt<String>? get borderJoinStyleCell => _borderJoinStyle;

  /// Stores the cell of `borderJoinStyle`. Dart `null` deletes the key.
  set borderJoinStyleCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.borderJoinStyle);
    } else {
      store(OptionKey.borderJoinStyle, cell);
    }
  }

  /// Stores the plain value [value] of `borderJoinStyle`.
  set borderJoinStyle(String value) =>
      store(OptionKey.borderJoinStyle, OptValue<String>(value));

  Opt<Object>? _borderRadius;

  /// The cell of `borderRadius`, or Dart `null` when absent.
  Opt<Object>? get borderRadiusCell => _borderRadius;

  /// Stores the cell of `borderRadius`. Dart `null` deletes the key.
  set borderRadiusCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.borderRadius);
    } else {
      store(OptionKey.borderRadius, cell);
    }
  }

  /// Stores the plain value [value] of `borderRadius`.
  set borderRadius(Object value) =>
      store(OptionKey.borderRadius, classify(OptionKey.borderRadius, value));

  Opt<double>? _offset;

  /// The cell of `offset`, or Dart `null` when absent.
  Opt<double>? get offsetCell => _offset;

  /// Stores the cell of `offset`. Dart `null` deletes the key.
  set offsetCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.offset);
    } else {
      store(OptionKey.offset, cell);
    }
  }

  /// Stores the plain value [value] of `offset`.
  set offset(double value) => store(OptionKey.offset, OptValue<double>(value));

  Opt<bool>? _circular;

  /// The cell of `circular`, or Dart `null` when absent.
  Opt<bool>? get circularCell => _circular;

  /// Stores the cell of `circular`. Dart `null` deletes the key.
  set circularCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.circular);
    } else {
      store(OptionKey.circular, cell);
    }
  }

  /// Stores the plain value [value] of `circular`.
  set circular(bool value) => store(OptionKey.circular, OptValue<bool>(value));

  Opt<double>? _spacing;

  /// The cell of `spacing`, or Dart `null` when absent.
  Opt<double>? get spacingCell => _spacing;

  /// Stores the cell of `spacing`. Dart `null` deletes the key.
  set spacingCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.spacing);
    } else {
      store(OptionKey.spacing, cell);
    }
  }

  /// Stores the plain value [value] of `spacing`.
  set spacing(double value) =>
      store(OptionKey.spacing, OptValue<double>(value));

  Opt<String>? _spacingMode;

  /// The cell of `spacingMode`, or Dart `null` when absent.
  Opt<String>? get spacingModeCell => _spacingMode;

  /// Stores the cell of `spacingMode`. Dart `null` deletes the key.
  set spacingModeCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.spacingMode);
    } else {
      store(OptionKey.spacingMode, cell);
    }
  }

  /// Stores the plain value [value] of `spacingMode`.
  set spacingMode(String value) =>
      store(OptionKey.spacingMode, OptValue<String>(value));

  Opt<double>? _hoverBorderWidth;

  /// The cell of `hoverBorderWidth`, or Dart `null` when absent.
  Opt<double>? get hoverBorderWidthCell => _hoverBorderWidth;

  /// Stores the cell of `hoverBorderWidth`. Dart `null` deletes the key.
  set hoverBorderWidthCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBorderWidth);
    } else {
      store(OptionKey.hoverBorderWidth, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBorderWidth`.
  set hoverBorderWidth(double value) =>
      store(OptionKey.hoverBorderWidth, OptValue<double>(value));

  Opt<Object>? _hoverBorderColor;

  /// The cell of `hoverBorderColor`, or Dart `null` when absent.
  Opt<Object>? get hoverBorderColorCell => _hoverBorderColor;

  /// Stores the cell of `hoverBorderColor`. Dart `null` deletes the key.
  set hoverBorderColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBorderColor);
    } else {
      store(OptionKey.hoverBorderColor, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBorderColor`.
  set hoverBorderColor(Object value) => store(
    OptionKey.hoverBorderColor,
    classify(OptionKey.hoverBorderColor, value),
  );

  Opt<Object>? _hoverBackgroundColor;

  /// The cell of `hoverBackgroundColor`, or Dart `null` when absent.
  Opt<Object>? get hoverBackgroundColorCell => _hoverBackgroundColor;

  /// Stores the cell of `hoverBackgroundColor`. Dart `null` deletes the key.
  set hoverBackgroundColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBackgroundColor);
    } else {
      store(OptionKey.hoverBackgroundColor, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBackgroundColor`.
  set hoverBackgroundColor(Object value) => store(
    OptionKey.hoverBackgroundColor,
    classify(OptionKey.hoverBackgroundColor, value),
  );

  Opt<Object>? _hoverBorderDash;

  /// The cell of `hoverBorderDash`, or Dart `null` when absent.
  Opt<Object>? get hoverBorderDashCell => _hoverBorderDash;

  /// Stores the cell of `hoverBorderDash`. Dart `null` deletes the key.
  set hoverBorderDashCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBorderDash);
    } else {
      store(OptionKey.hoverBorderDash, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBorderDash`.
  set hoverBorderDash(Object value) => store(
    OptionKey.hoverBorderDash,
    classify(OptionKey.hoverBorderDash, value),
  );

  Opt<double>? _hoverBorderDashOffset;

  /// The cell of `hoverBorderDashOffset`, or Dart `null` when absent.
  Opt<double>? get hoverBorderDashOffsetCell => _hoverBorderDashOffset;

  /// Stores the cell of `hoverBorderDashOffset`. Dart `null` deletes the key.
  set hoverBorderDashOffsetCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBorderDashOffset);
    } else {
      store(OptionKey.hoverBorderDashOffset, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBorderDashOffset`.
  set hoverBorderDashOffset(double value) =>
      store(OptionKey.hoverBorderDashOffset, OptValue<double>(value));

  Opt<double>? _hoverOffset;

  /// The cell of `hoverOffset`, or Dart `null` when absent.
  Opt<double>? get hoverOffsetCell => _hoverOffset;

  /// Stores the cell of `hoverOffset`. Dart `null` deletes the key.
  set hoverOffsetCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverOffset);
    } else {
      store(OptionKey.hoverOffset, cell);
    }
  }

  /// Stores the plain value [value] of `hoverOffset`.
  set hoverOffset(double value) =>
      store(OptionKey.hoverOffset, OptValue<double>(value));

  Opt<Object>? _animation;

  /// The cell of `animation`, or Dart `null` when absent.
  Opt<Object>? get animationCell => _animation;

  /// Stores the cell of `animation`. Dart `null` deletes the key.
  set animationCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.animation);
    } else {
      store(OptionKey.animation, cell);
    }
  }

  /// Stores the plain value [value] of `animation`.
  set animation(Object value) =>
      store(OptionKey.animation, classify(OptionKey.animation, value));

  Opt<Object>? _animations;

  /// The cell of `animations`, or Dart `null` when absent.
  Opt<Object>? get animationsCell => _animations;

  /// Stores the cell of `animations`. Dart `null` deletes the key.
  set animationsCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.animations);
    } else {
      store(OptionKey.animations, cell);
    }
  }

  /// Stores the plain value [value] of `animations`.
  set animations(Object value) =>
      store(OptionKey.animations, classify(OptionKey.animations, value));

  Opt<TransitionsSpecScope>? _transitions;

  /// The cell of `transitions`, or Dart `null` when absent.
  Opt<TransitionsSpecScope>? get transitionsCell => _transitions;

  /// Stores the cell of `transitions`. Dart `null` deletes the key.
  set transitionsCell(Opt<TransitionsSpecScope>? cell) {
    if (cell == null) {
      delete(OptionKey.transitions);
    } else {
      store(OptionKey.transitions, cell);
    }
  }

  /// Stores the plain value [value] of `transitions`.
  set transitions(TransitionsSpecScope value) =>
      store(OptionKey.transitions, OptScope<TransitionsSpecScope>(value));

  Opt<double>? _circumference;

  /// The cell of `circumference`, or Dart `null` when absent.
  Opt<double>? get circumferenceCell => _circumference;

  /// Stores the cell of `circumference`. Dart `null` deletes the key.
  set circumferenceCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.circumference);
    } else {
      store(OptionKey.circumference, cell);
    }
  }

  /// Stores the plain value [value] of `circumference`.
  set circumference(double value) =>
      store(OptionKey.circumference, OptValue<double>(value));

  Opt<double>? _rotation;

  /// The cell of `rotation`, or Dart `null` when absent.
  Opt<double>? get rotationCell => _rotation;

  /// Stores the cell of `rotation`. Dart `null` deletes the key.
  set rotationCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.rotation);
    } else {
      store(OptionKey.rotation, cell);
    }
  }

  /// Stores the plain value [value] of `rotation`.
  set rotation(double value) =>
      store(OptionKey.rotation, OptValue<double>(value));

  Opt<double>? _weight;

  /// The cell of `weight`, or Dart `null` when absent.
  Opt<double>? get weightCell => _weight;

  /// Stores the cell of `weight`. Dart `null` deletes the key.
  set weightCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.weight);
    } else {
      store(OptionKey.weight, cell);
    }
  }

  /// Stores the plain value [value] of `weight`.
  set weight(double value) => store(OptionKey.weight, OptValue<double>(value));

  Opt<TooltipDatasetOptionsScope>? _tooltip;

  /// The cell of `tooltip`, or Dart `null` when absent.
  Opt<TooltipDatasetOptionsScope>? get tooltipCell => _tooltip;

  /// Stores the cell of `tooltip`. Dart `null` deletes the key.
  set tooltipCell(Opt<TooltipDatasetOptionsScope>? cell) {
    if (cell == null) {
      delete(OptionKey.tooltip);
    } else {
      store(OptionKey.tooltip, cell);
    }
  }

  /// Stores the plain value [value] of `tooltip`.
  set tooltip(TooltipDatasetOptionsScope value) =>
      store(OptionKey.tooltip, OptScope<TooltipDatasetOptionsScope>(value));

  Opt<String>? _type;

  /// The cell of `type`, or Dart `null` when absent.
  Opt<String>? get typeCell => _type;

  /// Stores the cell of `type`. Dart `null` deletes the key.
  set typeCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.type);
    } else {
      store(OptionKey.type, cell);
    }
  }

  /// Stores the plain value [value] of `type`.
  set type(String value) => store(OptionKey.type, OptValue<String>(value));

  Opt<Object>? _data;

  /// The cell of `data`, or Dart `null` when absent.
  Opt<Object>? get dataCell => _data;

  /// Stores the cell of `data`. Dart `null` deletes the key.
  set dataCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.data);
    } else {
      store(OptionKey.data, cell);
    }
  }

  /// Stores the plain value [value] of `data`.
  set data(Object value) =>
      store(OptionKey.data, classify(OptionKey.data, value));

  Opt<Object>? _cutout;

  /// The cell of `cutout`, or Dart `null` when absent.
  Opt<Object>? get cutoutCell => _cutout;

  /// Stores the cell of `cutout`. Dart `null` deletes the key.
  set cutoutCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.cutout);
    } else {
      store(OptionKey.cutout, cell);
    }
  }

  /// Stores the plain value [value] of `cutout`.
  set cutout(Object value) =>
      store(OptionKey.cutout, classify(OptionKey.cutout, value));

  Opt<Object>? _radius;

  /// The cell of `radius`, or Dart `null` when absent.
  Opt<Object>? get radiusCell => _radius;

  /// Stores the cell of `radius`. Dart `null` deletes the key.
  set radiusCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.radius);
    } else {
      store(OptionKey.radius, cell);
    }
  }

  /// Stores the plain value [value] of `radius`.
  set radius(Object value) =>
      store(OptionKey.radius, classify(OptionKey.radius, value));

  Opt<String>? _xAxisID;

  /// The cell of `xAxisID`, or Dart `null` when absent.
  Opt<String>? get xAxisIDCell => _xAxisID;

  /// Stores the cell of `xAxisID`. Dart `null` deletes the key.
  set xAxisIDCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.xAxisID);
    } else {
      store(OptionKey.xAxisID, cell);
    }
  }

  /// Stores the plain value [value] of `xAxisID`.
  set xAxisID(String value) =>
      store(OptionKey.xAxisID, OptValue<String>(value));

  Opt<String>? _yAxisID;

  /// The cell of `yAxisID`, or Dart `null` when absent.
  Opt<String>? get yAxisIDCell => _yAxisID;

  /// Stores the cell of `yAxisID`. Dart `null` deletes the key.
  set yAxisIDCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.yAxisID);
    } else {
      store(OptionKey.yAxisID, cell);
    }
  }

  /// Stores the plain value [value] of `yAxisID`.
  set yAxisID(String value) =>
      store(OptionKey.yAxisID, OptValue<String>(value));

  Opt<String>? _rAxisID;

  /// The cell of `rAxisID`, or Dart `null` when absent.
  Opt<String>? get rAxisIDCell => _rAxisID;

  /// Stores the cell of `rAxisID`. Dart `null` deletes the key.
  set rAxisIDCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.rAxisID);
    } else {
      store(OptionKey.rAxisID, cell);
    }
  }

  /// Stores the plain value [value] of `rAxisID`.
  set rAxisID(String value) =>
      store(OptionKey.rAxisID, OptValue<String>(value));

  Opt<Object>? _fill;

  /// The cell of `fill`, or Dart `null` when absent.
  Opt<Object>? get fillCell => _fill;

  /// Stores the cell of `fill`. Dart `null` deletes the key.
  set fillCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.fill);
    } else {
      store(OptionKey.fill, cell);
    }
  }

  /// Stores the plain value [value] of `fill`.
  set fill(Object value) =>
      store(OptionKey.fill, classify(OptionKey.fill, value));

  Opt<bool>? _drawActiveElementsOnTop;

  /// The cell of `drawActiveElementsOnTop`, or Dart `null` when absent.
  Opt<bool>? get drawActiveElementsOnTopCell => _drawActiveElementsOnTop;

  /// Stores the cell of `drawActiveElementsOnTop`. Dart `null` deletes the key.
  set drawActiveElementsOnTopCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.drawActiveElementsOnTop);
    } else {
      store(OptionKey.drawActiveElementsOnTop, cell);
    }
  }

  /// Stores the plain value [value] of `drawActiveElementsOnTop`.
  set drawActiveElementsOnTop(bool value) =>
      store(OptionKey.drawActiveElementsOnTop, OptValue<bool>(value));

  Opt<ElementOptionsByTypeScope>? _elements;

  /// The cell of `elements`, or Dart `null` when absent.
  Opt<ElementOptionsByTypeScope>? get elementsCell => _elements;

  /// Stores the cell of `elements`. Dart `null` deletes the key.
  set elementsCell(Opt<ElementOptionsByTypeScope>? cell) {
    if (cell == null) {
      delete(OptionKey.elements);
    } else {
      store(OptionKey.elements, cell);
    }
  }

  /// Stores the plain value [value] of `elements`.
  set elements(ElementOptionsByTypeScope value) =>
      store(OptionKey.elements, OptScope<ElementOptionsByTypeScope>(value));

  Opt<Object>? _datasetElementType;

  /// The cell of `datasetElementType`, or Dart `null` when absent.
  Opt<Object>? get datasetElementTypeCell => _datasetElementType;

  /// Stores the cell of `datasetElementType`. Dart `null` deletes the key.
  set datasetElementTypeCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.datasetElementType);
    } else {
      store(OptionKey.datasetElementType, cell);
    }
  }

  /// Stores the plain value [value] of `datasetElementType`.
  set datasetElementType(Object value) => store(
    OptionKey.datasetElementType,
    classify(OptionKey.datasetElementType, value),
  );

  Opt<Object>? _dataElementType;

  /// The cell of `dataElementType`, or Dart `null` when absent.
  Opt<Object>? get dataElementTypeCell => _dataElementType;

  /// Stores the cell of `dataElementType`. Dart `null` deletes the key.
  set dataElementTypeCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.dataElementType);
    } else {
      store(OptionKey.dataElementType, cell);
    }
  }

  /// Stores the plain value [value] of `dataElementType`.
  set dataElementType(Object value) => store(
    OptionKey.dataElementType,
    classify(OptionKey.dataElementType, value),
  );

  Opt<Object>? _descData;

  /// The cell of `_data`, or Dart `null` when absent.
  Opt<Object>? get descDataCell => _descData;

  /// Stores the cell of `_data`. Dart `null` deletes the key.
  set descDataCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.descData);
    } else {
      store(OptionKey.descData, cell);
    }
  }

  /// Stores the plain value [value] of `_data`.
  set descData(Object value) =>
      store(OptionKey.descData, classify(OptionKey.descData, value));

  Opt<Object>? _descDecimated;

  /// The cell of `_decimated`, or Dart `null` when absent.
  Opt<Object>? get descDecimatedCell => _descDecimated;

  /// Stores the cell of `_decimated`. Dart `null` deletes the key.
  set descDecimatedCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.descDecimated);
    } else {
      store(OptionKey.descDecimated, cell);
    }
  }

  /// Stores the plain value [value] of `_decimated`.
  set descDecimated(Object value) =>
      store(OptionKey.descDecimated, classify(OptionKey.descDecimated, value));

  @override
  Opt<Object?>? cellOf(OptionKey key) => switch (key) {
    OptionKey.parsing => _parsing,
    OptionKey.normalized => _normalized,
    OptionKey.indexAxis => _indexAxis,
    OptionKey.clip => _clip,
    OptionKey.label => _label,
    OptionKey.order => _order,
    OptionKey.stack => _stack,
    OptionKey.hidden => _hidden,
    OptionKey.borderWidth => _borderWidth,
    OptionKey.borderColor => _borderColor,
    OptionKey.backgroundColor => _backgroundColor,
    OptionKey.selfJoin => _selfJoin,
    OptionKey.borderAlign => _borderAlign,
    OptionKey.borderDash => _borderDash,
    OptionKey.borderDashOffset => _borderDashOffset,
    OptionKey.borderJoinStyle => _borderJoinStyle,
    OptionKey.borderRadius => _borderRadius,
    OptionKey.offset => _offset,
    OptionKey.circular => _circular,
    OptionKey.spacing => _spacing,
    OptionKey.spacingMode => _spacingMode,
    OptionKey.hoverBorderWidth => _hoverBorderWidth,
    OptionKey.hoverBorderColor => _hoverBorderColor,
    OptionKey.hoverBackgroundColor => _hoverBackgroundColor,
    OptionKey.hoverBorderDash => _hoverBorderDash,
    OptionKey.hoverBorderDashOffset => _hoverBorderDashOffset,
    OptionKey.hoverOffset => _hoverOffset,
    OptionKey.animation => _animation,
    OptionKey.animations => _animations,
    OptionKey.transitions => _transitions,
    OptionKey.circumference => _circumference,
    OptionKey.rotation => _rotation,
    OptionKey.weight => _weight,
    OptionKey.tooltip => _tooltip,
    OptionKey.type => _type,
    OptionKey.data => _data,
    OptionKey.cutout => _cutout,
    OptionKey.radius => _radius,
    OptionKey.xAxisID => _xAxisID,
    OptionKey.yAxisID => _yAxisID,
    OptionKey.rAxisID => _rAxisID,
    OptionKey.fill => _fill,
    OptionKey.drawActiveElementsOnTop => _drawActiveElementsOnTop,
    OptionKey.elements => _elements,
    OptionKey.datasetElementType => _datasetElementType,
    OptionKey.dataElementType => _dataElementType,
    OptionKey.descData => _descData,
    OptionKey.descDecimated => _descDecimated,
    _ => null,
  };

  @override
  void setCell(OptionKey key, Opt<Object?>? cell) {
    switch (key) {
      case OptionKey.parsing:
        _parsing = fitCell(cell, (raw) => classifyUnion(raw, 34));
      case OptionKey.normalized:
        _normalized = fitCell(cell, classifyBool);
      case OptionKey.indexAxis:
        _indexAxis = fitCell(cell, classifyString);
      case OptionKey.clip:
        _clip = fitCell(cell, (raw) => classifyUnion(raw, 35));
      case OptionKey.label:
        _label = fitCell(cell, classifyString);
      case OptionKey.order:
        _order = fitCell(cell, classifyNumber);
      case OptionKey.stack:
        _stack = fitCell(cell, classifyString);
      case OptionKey.hidden:
        _hidden = fitCell(cell, classifyBool);
      case OptionKey.borderWidth:
        _borderWidth = fitCell(cell, classifyNumber);
      case OptionKey.borderColor:
        _borderColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.backgroundColor:
        _backgroundColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.selfJoin:
        _selfJoin = fitCell(cell, classifyBool);
      case OptionKey.borderAlign:
        _borderAlign = fitCell(cell, classifyString);
      case OptionKey.borderDash:
        _borderDash = fitCell(cell, (raw) => classifyUnion(raw, 16));
      case OptionKey.borderDashOffset:
        _borderDashOffset = fitCell(cell, classifyNumber);
      case OptionKey.borderJoinStyle:
        _borderJoinStyle = fitCell(cell, classifyString);
      case OptionKey.borderRadius:
        _borderRadius = fitCell(cell, (raw) => classifyUnion(raw, 33));
      case OptionKey.offset:
        _offset = fitCell(cell, classifyNumber);
      case OptionKey.circular:
        _circular = fitCell(cell, classifyBool);
      case OptionKey.spacing:
        _spacing = fitCell(cell, classifyNumber);
      case OptionKey.spacingMode:
        _spacingMode = fitCell(cell, classifyString);
      case OptionKey.hoverBorderWidth:
        _hoverBorderWidth = fitCell(cell, classifyNumber);
      case OptionKey.hoverBorderColor:
        _hoverBorderColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.hoverBackgroundColor:
        _hoverBackgroundColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.hoverBorderDash:
        _hoverBorderDash = fitCell(cell, (raw) => classifyUnion(raw, 16));
      case OptionKey.hoverBorderDashOffset:
        _hoverBorderDashOffset = fitCell(cell, classifyNumber);
      case OptionKey.hoverOffset:
        _hoverOffset = fitCell(cell, classifyNumber);
      case OptionKey.animation:
        _animation = fitCell(cell, (raw) => classifyUnion(raw, 34));
      case OptionKey.animations:
        _animations = fitCell(cell, (raw) => classifyUnion(raw, 34));
      case OptionKey.transitions:
        _transitions = fitCell(cell, classifyScope<TransitionsSpecScope>);
      case OptionKey.circumference:
        _circumference = fitCell(cell, classifyNumber);
      case OptionKey.rotation:
        _rotation = fitCell(cell, classifyNumber);
      case OptionKey.weight:
        _weight = fitCell(cell, classifyNumber);
      case OptionKey.tooltip:
        _tooltip = fitCell(cell, classifyScope<TooltipDatasetOptionsScope>);
      case OptionKey.type:
        _type = fitCell(cell, classifyString);
      case OptionKey.data:
        _data = fitCell(cell, (raw) => classifyUnion(raw, 16));
      case OptionKey.cutout:
        _cutout = fitCell(cell, (raw) => classifyUnion(raw, 5));
      case OptionKey.radius:
        _radius = fitCell(cell, (raw) => classifyUnion(raw, 5));
      case OptionKey.xAxisID:
        _xAxisID = fitCell(cell, classifyString);
      case OptionKey.yAxisID:
        _yAxisID = fitCell(cell, classifyString);
      case OptionKey.rAxisID:
        _rAxisID = fitCell(cell, classifyString);
      case OptionKey.fill:
        _fill = fitCell(cell, (raw) => classifyUnion(raw, 39));
      case OptionKey.drawActiveElementsOnTop:
        _drawActiveElementsOnTop = fitCell(cell, classifyBool);
      case OptionKey.elements:
        _elements = fitCell(cell, classifyScope<ElementOptionsByTypeScope>);
      case OptionKey.datasetElementType:
        _datasetElementType = fitCell(cell, (raw) => classifyUnion(raw, 6));
      case OptionKey.dataElementType:
        _dataElementType = fitCell(cell, (raw) => classifyUnion(raw, 6));
      case OptionKey.descData:
        _descData = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.descDecimated:
        _descDecimated = fitCell(cell, (raw) => classifyUnion(raw, 64));
      default:
        throw ArgumentError.value(
          key,
          'key',
          'Not a key of DoughnutControllerDatasetOptions',
        );
    }
  }

  @override
  bool hasField(OptionKey key) => switch (key) {
    OptionKey.parsing ||
    OptionKey.normalized ||
    OptionKey.indexAxis ||
    OptionKey.clip ||
    OptionKey.label ||
    OptionKey.order ||
    OptionKey.stack ||
    OptionKey.hidden ||
    OptionKey.borderWidth ||
    OptionKey.borderColor ||
    OptionKey.backgroundColor ||
    OptionKey.selfJoin ||
    OptionKey.borderAlign ||
    OptionKey.borderDash ||
    OptionKey.borderDashOffset ||
    OptionKey.borderJoinStyle ||
    OptionKey.borderRadius ||
    OptionKey.offset ||
    OptionKey.circular ||
    OptionKey.spacing ||
    OptionKey.spacingMode ||
    OptionKey.hoverBorderWidth ||
    OptionKey.hoverBorderColor ||
    OptionKey.hoverBackgroundColor ||
    OptionKey.hoverBorderDash ||
    OptionKey.hoverBorderDashOffset ||
    OptionKey.hoverOffset ||
    OptionKey.animation ||
    OptionKey.animations ||
    OptionKey.transitions ||
    OptionKey.circumference ||
    OptionKey.rotation ||
    OptionKey.weight ||
    OptionKey.tooltip ||
    OptionKey.type ||
    OptionKey.data ||
    OptionKey.cutout ||
    OptionKey.radius ||
    OptionKey.xAxisID ||
    OptionKey.yAxisID ||
    OptionKey.rAxisID ||
    OptionKey.fill ||
    OptionKey.drawActiveElementsOnTop ||
    OptionKey.elements ||
    OptionKey.datasetElementType ||
    OptionKey.dataElementType ||
    OptionKey.descData ||
    OptionKey.descDecimated => true,
    _ => false,
  };

  @override
  Opt<Object?> classify(OptionKey key, Object? raw) => switch (key) {
    OptionKey.parsing => classifyUnion(raw, 34),
    OptionKey.normalized => classifyBool(raw),
    OptionKey.indexAxis => classifyString(raw),
    OptionKey.clip => classifyUnion(raw, 35),
    OptionKey.label => classifyString(raw),
    OptionKey.order => classifyNumber(raw),
    OptionKey.stack => classifyString(raw),
    OptionKey.hidden => classifyBool(raw),
    OptionKey.borderWidth => classifyNumber(raw),
    OptionKey.borderColor => classifyUnion(raw, 64),
    OptionKey.backgroundColor => classifyUnion(raw, 64),
    OptionKey.selfJoin => classifyBool(raw),
    OptionKey.borderAlign => classifyString(raw),
    OptionKey.borderDash => classifyUnion(raw, 16),
    OptionKey.borderDashOffset => classifyNumber(raw),
    OptionKey.borderJoinStyle => classifyString(raw),
    OptionKey.borderRadius => classifyUnion(raw, 33),
    OptionKey.offset => classifyNumber(raw),
    OptionKey.circular => classifyBool(raw),
    OptionKey.spacing => classifyNumber(raw),
    OptionKey.spacingMode => classifyString(raw),
    OptionKey.hoverBorderWidth => classifyNumber(raw),
    OptionKey.hoverBorderColor => classifyUnion(raw, 64),
    OptionKey.hoverBackgroundColor => classifyUnion(raw, 64),
    OptionKey.hoverBorderDash => classifyUnion(raw, 16),
    OptionKey.hoverBorderDashOffset => classifyNumber(raw),
    OptionKey.hoverOffset => classifyNumber(raw),
    OptionKey.animation => classifyUnion(raw, 34),
    OptionKey.animations => classifyUnion(raw, 34),
    OptionKey.transitions => classifyScope<TransitionsSpecScope>(raw),
    OptionKey.circumference => classifyNumber(raw),
    OptionKey.rotation => classifyNumber(raw),
    OptionKey.weight => classifyNumber(raw),
    OptionKey.tooltip => classifyScope<TooltipDatasetOptionsScope>(raw),
    OptionKey.type => classifyString(raw),
    OptionKey.data => classifyUnion(raw, 16),
    OptionKey.cutout => classifyUnion(raw, 5),
    OptionKey.radius => classifyUnion(raw, 5),
    OptionKey.xAxisID => classifyString(raw),
    OptionKey.yAxisID => classifyString(raw),
    OptionKey.rAxisID => classifyString(raw),
    OptionKey.fill => classifyUnion(raw, 39),
    OptionKey.drawActiveElementsOnTop => classifyBool(raw),
    OptionKey.elements => classifyScope<ElementOptionsByTypeScope>(raw),
    OptionKey.datasetElementType => classifyUnion(raw, 6),
    OptionKey.dataElementType => classifyUnion(raw, 6),
    OptionKey.descData => classifyUnion(raw, 64),
    OptionKey.descDecimated => classifyUnion(raw, 64),
    _ => kind.classifyOther(raw),
  };
}

/// index.d.ts:390 PolarAreaControllerDatasetOptions (index.d.ts:247
/// DoughnutControllerDatasetOptions and `angle`) with index.d.ts:400
/// PolarAreaControllerChartOptions, a polar area dataset and
/// `datasets.polarArea`.
base class PolarAreaControllerDatasetOptionsScope extends OptionScope {
  /// An empty scope.
  PolarAreaControllerDatasetOptionsScope();

  @override
  ScopeKind get kind => ScopeKind.polarAreaControllerDatasetOptions;

  Opt<Object>? _parsing;

  /// The cell of `parsing`, or Dart `null` when absent.
  Opt<Object>? get parsingCell => _parsing;

  /// Stores the cell of `parsing`. Dart `null` deletes the key.
  set parsingCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.parsing);
    } else {
      store(OptionKey.parsing, cell);
    }
  }

  /// Stores the plain value [value] of `parsing`.
  set parsing(Object value) =>
      store(OptionKey.parsing, classify(OptionKey.parsing, value));

  Opt<bool>? _normalized;

  /// The cell of `normalized`, or Dart `null` when absent.
  Opt<bool>? get normalizedCell => _normalized;

  /// Stores the cell of `normalized`. Dart `null` deletes the key.
  set normalizedCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.normalized);
    } else {
      store(OptionKey.normalized, cell);
    }
  }

  /// Stores the plain value [value] of `normalized`.
  set normalized(bool value) =>
      store(OptionKey.normalized, OptValue<bool>(value));

  Opt<String>? _indexAxis;

  /// The cell of `indexAxis`, or Dart `null` when absent.
  Opt<String>? get indexAxisCell => _indexAxis;

  /// Stores the cell of `indexAxis`. Dart `null` deletes the key.
  set indexAxisCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.indexAxis);
    } else {
      store(OptionKey.indexAxis, cell);
    }
  }

  /// Stores the plain value [value] of `indexAxis`.
  set indexAxis(String value) =>
      store(OptionKey.indexAxis, OptValue<String>(value));

  Opt<Object>? _clip;

  /// The cell of `clip`, or Dart `null` when absent.
  Opt<Object>? get clipCell => _clip;

  /// Stores the cell of `clip`. Dart `null` deletes the key.
  set clipCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.clip);
    } else {
      store(OptionKey.clip, cell);
    }
  }

  /// Stores the plain value [value] of `clip`.
  set clip(Object value) =>
      store(OptionKey.clip, classify(OptionKey.clip, value));

  Opt<String>? _label;

  /// The cell of `label`, or Dart `null` when absent.
  Opt<String>? get labelCell => _label;

  /// Stores the cell of `label`. Dart `null` deletes the key.
  set labelCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.label);
    } else {
      store(OptionKey.label, cell);
    }
  }

  /// Stores the plain value [value] of `label`.
  set label(String value) => store(OptionKey.label, OptValue<String>(value));

  Opt<double>? _order;

  /// The cell of `order`, or Dart `null` when absent.
  Opt<double>? get orderCell => _order;

  /// Stores the cell of `order`. Dart `null` deletes the key.
  set orderCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.order);
    } else {
      store(OptionKey.order, cell);
    }
  }

  /// Stores the plain value [value] of `order`.
  set order(double value) => store(OptionKey.order, OptValue<double>(value));

  Opt<String>? _stack;

  /// The cell of `stack`, or Dart `null` when absent.
  Opt<String>? get stackCell => _stack;

  /// Stores the cell of `stack`. Dart `null` deletes the key.
  set stackCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.stack);
    } else {
      store(OptionKey.stack, cell);
    }
  }

  /// Stores the plain value [value] of `stack`.
  set stack(String value) => store(OptionKey.stack, OptValue<String>(value));

  Opt<bool>? _hidden;

  /// The cell of `hidden`, or Dart `null` when absent.
  Opt<bool>? get hiddenCell => _hidden;

  /// Stores the cell of `hidden`. Dart `null` deletes the key.
  set hiddenCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.hidden);
    } else {
      store(OptionKey.hidden, cell);
    }
  }

  /// Stores the plain value [value] of `hidden`.
  set hidden(bool value) => store(OptionKey.hidden, OptValue<bool>(value));

  Opt<double>? _borderWidth;

  /// The cell of `borderWidth`, or Dart `null` when absent.
  Opt<double>? get borderWidthCell => _borderWidth;

  /// Stores the cell of `borderWidth`. Dart `null` deletes the key.
  set borderWidthCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.borderWidth);
    } else {
      store(OptionKey.borderWidth, cell);
    }
  }

  /// Stores the plain value [value] of `borderWidth`.
  set borderWidth(double value) =>
      store(OptionKey.borderWidth, OptValue<double>(value));

  Opt<Object>? _borderColor;

  /// The cell of `borderColor`, or Dart `null` when absent.
  Opt<Object>? get borderColorCell => _borderColor;

  /// Stores the cell of `borderColor`. Dart `null` deletes the key.
  set borderColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.borderColor);
    } else {
      store(OptionKey.borderColor, cell);
    }
  }

  /// Stores the plain value [value] of `borderColor`.
  set borderColor(Object value) =>
      store(OptionKey.borderColor, classify(OptionKey.borderColor, value));

  Opt<Object>? _backgroundColor;

  /// The cell of `backgroundColor`, or Dart `null` when absent.
  Opt<Object>? get backgroundColorCell => _backgroundColor;

  /// Stores the cell of `backgroundColor`. Dart `null` deletes the key.
  set backgroundColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.backgroundColor);
    } else {
      store(OptionKey.backgroundColor, cell);
    }
  }

  /// Stores the plain value [value] of `backgroundColor`.
  set backgroundColor(Object value) => store(
    OptionKey.backgroundColor,
    classify(OptionKey.backgroundColor, value),
  );

  Opt<bool>? _selfJoin;

  /// The cell of `selfJoin`, or Dart `null` when absent.
  Opt<bool>? get selfJoinCell => _selfJoin;

  /// Stores the cell of `selfJoin`. Dart `null` deletes the key.
  set selfJoinCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.selfJoin);
    } else {
      store(OptionKey.selfJoin, cell);
    }
  }

  /// Stores the plain value [value] of `selfJoin`.
  set selfJoin(bool value) => store(OptionKey.selfJoin, OptValue<bool>(value));

  Opt<String>? _borderAlign;

  /// The cell of `borderAlign`, or Dart `null` when absent.
  Opt<String>? get borderAlignCell => _borderAlign;

  /// Stores the cell of `borderAlign`. Dart `null` deletes the key.
  set borderAlignCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.borderAlign);
    } else {
      store(OptionKey.borderAlign, cell);
    }
  }

  /// Stores the plain value [value] of `borderAlign`.
  set borderAlign(String value) =>
      store(OptionKey.borderAlign, OptValue<String>(value));

  Opt<Object>? _borderDash;

  /// The cell of `borderDash`, or Dart `null` when absent.
  Opt<Object>? get borderDashCell => _borderDash;

  /// Stores the cell of `borderDash`. Dart `null` deletes the key.
  set borderDashCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.borderDash);
    } else {
      store(OptionKey.borderDash, cell);
    }
  }

  /// Stores the plain value [value] of `borderDash`.
  set borderDash(Object value) =>
      store(OptionKey.borderDash, classify(OptionKey.borderDash, value));

  Opt<double>? _borderDashOffset;

  /// The cell of `borderDashOffset`, or Dart `null` when absent.
  Opt<double>? get borderDashOffsetCell => _borderDashOffset;

  /// Stores the cell of `borderDashOffset`. Dart `null` deletes the key.
  set borderDashOffsetCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.borderDashOffset);
    } else {
      store(OptionKey.borderDashOffset, cell);
    }
  }

  /// Stores the plain value [value] of `borderDashOffset`.
  set borderDashOffset(double value) =>
      store(OptionKey.borderDashOffset, OptValue<double>(value));

  Opt<String>? _borderJoinStyle;

  /// The cell of `borderJoinStyle`, or Dart `null` when absent.
  Opt<String>? get borderJoinStyleCell => _borderJoinStyle;

  /// Stores the cell of `borderJoinStyle`. Dart `null` deletes the key.
  set borderJoinStyleCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.borderJoinStyle);
    } else {
      store(OptionKey.borderJoinStyle, cell);
    }
  }

  /// Stores the plain value [value] of `borderJoinStyle`.
  set borderJoinStyle(String value) =>
      store(OptionKey.borderJoinStyle, OptValue<String>(value));

  Opt<Object>? _borderRadius;

  /// The cell of `borderRadius`, or Dart `null` when absent.
  Opt<Object>? get borderRadiusCell => _borderRadius;

  /// Stores the cell of `borderRadius`. Dart `null` deletes the key.
  set borderRadiusCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.borderRadius);
    } else {
      store(OptionKey.borderRadius, cell);
    }
  }

  /// Stores the plain value [value] of `borderRadius`.
  set borderRadius(Object value) =>
      store(OptionKey.borderRadius, classify(OptionKey.borderRadius, value));

  Opt<double>? _offset;

  /// The cell of `offset`, or Dart `null` when absent.
  Opt<double>? get offsetCell => _offset;

  /// Stores the cell of `offset`. Dart `null` deletes the key.
  set offsetCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.offset);
    } else {
      store(OptionKey.offset, cell);
    }
  }

  /// Stores the plain value [value] of `offset`.
  set offset(double value) => store(OptionKey.offset, OptValue<double>(value));

  Opt<bool>? _circular;

  /// The cell of `circular`, or Dart `null` when absent.
  Opt<bool>? get circularCell => _circular;

  /// Stores the cell of `circular`. Dart `null` deletes the key.
  set circularCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.circular);
    } else {
      store(OptionKey.circular, cell);
    }
  }

  /// Stores the plain value [value] of `circular`.
  set circular(bool value) => store(OptionKey.circular, OptValue<bool>(value));

  Opt<double>? _spacing;

  /// The cell of `spacing`, or Dart `null` when absent.
  Opt<double>? get spacingCell => _spacing;

  /// Stores the cell of `spacing`. Dart `null` deletes the key.
  set spacingCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.spacing);
    } else {
      store(OptionKey.spacing, cell);
    }
  }

  /// Stores the plain value [value] of `spacing`.
  set spacing(double value) =>
      store(OptionKey.spacing, OptValue<double>(value));

  Opt<String>? _spacingMode;

  /// The cell of `spacingMode`, or Dart `null` when absent.
  Opt<String>? get spacingModeCell => _spacingMode;

  /// Stores the cell of `spacingMode`. Dart `null` deletes the key.
  set spacingModeCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.spacingMode);
    } else {
      store(OptionKey.spacingMode, cell);
    }
  }

  /// Stores the plain value [value] of `spacingMode`.
  set spacingMode(String value) =>
      store(OptionKey.spacingMode, OptValue<String>(value));

  Opt<double>? _hoverBorderWidth;

  /// The cell of `hoverBorderWidth`, or Dart `null` when absent.
  Opt<double>? get hoverBorderWidthCell => _hoverBorderWidth;

  /// Stores the cell of `hoverBorderWidth`. Dart `null` deletes the key.
  set hoverBorderWidthCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBorderWidth);
    } else {
      store(OptionKey.hoverBorderWidth, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBorderWidth`.
  set hoverBorderWidth(double value) =>
      store(OptionKey.hoverBorderWidth, OptValue<double>(value));

  Opt<Object>? _hoverBorderColor;

  /// The cell of `hoverBorderColor`, or Dart `null` when absent.
  Opt<Object>? get hoverBorderColorCell => _hoverBorderColor;

  /// Stores the cell of `hoverBorderColor`. Dart `null` deletes the key.
  set hoverBorderColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBorderColor);
    } else {
      store(OptionKey.hoverBorderColor, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBorderColor`.
  set hoverBorderColor(Object value) => store(
    OptionKey.hoverBorderColor,
    classify(OptionKey.hoverBorderColor, value),
  );

  Opt<Object>? _hoverBackgroundColor;

  /// The cell of `hoverBackgroundColor`, or Dart `null` when absent.
  Opt<Object>? get hoverBackgroundColorCell => _hoverBackgroundColor;

  /// Stores the cell of `hoverBackgroundColor`. Dart `null` deletes the key.
  set hoverBackgroundColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBackgroundColor);
    } else {
      store(OptionKey.hoverBackgroundColor, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBackgroundColor`.
  set hoverBackgroundColor(Object value) => store(
    OptionKey.hoverBackgroundColor,
    classify(OptionKey.hoverBackgroundColor, value),
  );

  Opt<Object>? _hoverBorderDash;

  /// The cell of `hoverBorderDash`, or Dart `null` when absent.
  Opt<Object>? get hoverBorderDashCell => _hoverBorderDash;

  /// Stores the cell of `hoverBorderDash`. Dart `null` deletes the key.
  set hoverBorderDashCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBorderDash);
    } else {
      store(OptionKey.hoverBorderDash, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBorderDash`.
  set hoverBorderDash(Object value) => store(
    OptionKey.hoverBorderDash,
    classify(OptionKey.hoverBorderDash, value),
  );

  Opt<double>? _hoverBorderDashOffset;

  /// The cell of `hoverBorderDashOffset`, or Dart `null` when absent.
  Opt<double>? get hoverBorderDashOffsetCell => _hoverBorderDashOffset;

  /// Stores the cell of `hoverBorderDashOffset`. Dart `null` deletes the key.
  set hoverBorderDashOffsetCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBorderDashOffset);
    } else {
      store(OptionKey.hoverBorderDashOffset, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBorderDashOffset`.
  set hoverBorderDashOffset(double value) =>
      store(OptionKey.hoverBorderDashOffset, OptValue<double>(value));

  Opt<double>? _hoverOffset;

  /// The cell of `hoverOffset`, or Dart `null` when absent.
  Opt<double>? get hoverOffsetCell => _hoverOffset;

  /// Stores the cell of `hoverOffset`. Dart `null` deletes the key.
  set hoverOffsetCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverOffset);
    } else {
      store(OptionKey.hoverOffset, cell);
    }
  }

  /// Stores the plain value [value] of `hoverOffset`.
  set hoverOffset(double value) =>
      store(OptionKey.hoverOffset, OptValue<double>(value));

  Opt<Object>? _animation;

  /// The cell of `animation`, or Dart `null` when absent.
  Opt<Object>? get animationCell => _animation;

  /// Stores the cell of `animation`. Dart `null` deletes the key.
  set animationCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.animation);
    } else {
      store(OptionKey.animation, cell);
    }
  }

  /// Stores the plain value [value] of `animation`.
  set animation(Object value) =>
      store(OptionKey.animation, classify(OptionKey.animation, value));

  Opt<Object>? _animations;

  /// The cell of `animations`, or Dart `null` when absent.
  Opt<Object>? get animationsCell => _animations;

  /// Stores the cell of `animations`. Dart `null` deletes the key.
  set animationsCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.animations);
    } else {
      store(OptionKey.animations, cell);
    }
  }

  /// Stores the plain value [value] of `animations`.
  set animations(Object value) =>
      store(OptionKey.animations, classify(OptionKey.animations, value));

  Opt<TransitionsSpecScope>? _transitions;

  /// The cell of `transitions`, or Dart `null` when absent.
  Opt<TransitionsSpecScope>? get transitionsCell => _transitions;

  /// Stores the cell of `transitions`. Dart `null` deletes the key.
  set transitionsCell(Opt<TransitionsSpecScope>? cell) {
    if (cell == null) {
      delete(OptionKey.transitions);
    } else {
      store(OptionKey.transitions, cell);
    }
  }

  /// Stores the plain value [value] of `transitions`.
  set transitions(TransitionsSpecScope value) =>
      store(OptionKey.transitions, OptScope<TransitionsSpecScope>(value));

  Opt<double>? _circumference;

  /// The cell of `circumference`, or Dart `null` when absent.
  Opt<double>? get circumferenceCell => _circumference;

  /// Stores the cell of `circumference`. Dart `null` deletes the key.
  set circumferenceCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.circumference);
    } else {
      store(OptionKey.circumference, cell);
    }
  }

  /// Stores the plain value [value] of `circumference`.
  set circumference(double value) =>
      store(OptionKey.circumference, OptValue<double>(value));

  Opt<double>? _rotation;

  /// The cell of `rotation`, or Dart `null` when absent.
  Opt<double>? get rotationCell => _rotation;

  /// Stores the cell of `rotation`. Dart `null` deletes the key.
  set rotationCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.rotation);
    } else {
      store(OptionKey.rotation, cell);
    }
  }

  /// Stores the plain value [value] of `rotation`.
  set rotation(double value) =>
      store(OptionKey.rotation, OptValue<double>(value));

  Opt<double>? _weight;

  /// The cell of `weight`, or Dart `null` when absent.
  Opt<double>? get weightCell => _weight;

  /// Stores the cell of `weight`. Dart `null` deletes the key.
  set weightCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.weight);
    } else {
      store(OptionKey.weight, cell);
    }
  }

  /// Stores the plain value [value] of `weight`.
  set weight(double value) => store(OptionKey.weight, OptValue<double>(value));

  Opt<double>? _angle;

  /// The cell of `angle`, or Dart `null` when absent.
  Opt<double>? get angleCell => _angle;

  /// Stores the cell of `angle`. Dart `null` deletes the key.
  set angleCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.angle);
    } else {
      store(OptionKey.angle, cell);
    }
  }

  /// Stores the plain value [value] of `angle`.
  set angle(double value) => store(OptionKey.angle, OptValue<double>(value));

  Opt<TooltipDatasetOptionsScope>? _tooltip;

  /// The cell of `tooltip`, or Dart `null` when absent.
  Opt<TooltipDatasetOptionsScope>? get tooltipCell => _tooltip;

  /// Stores the cell of `tooltip`. Dart `null` deletes the key.
  set tooltipCell(Opt<TooltipDatasetOptionsScope>? cell) {
    if (cell == null) {
      delete(OptionKey.tooltip);
    } else {
      store(OptionKey.tooltip, cell);
    }
  }

  /// Stores the plain value [value] of `tooltip`.
  set tooltip(TooltipDatasetOptionsScope value) =>
      store(OptionKey.tooltip, OptScope<TooltipDatasetOptionsScope>(value));

  Opt<String>? _type;

  /// The cell of `type`, or Dart `null` when absent.
  Opt<String>? get typeCell => _type;

  /// Stores the cell of `type`. Dart `null` deletes the key.
  set typeCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.type);
    } else {
      store(OptionKey.type, cell);
    }
  }

  /// Stores the plain value [value] of `type`.
  set type(String value) => store(OptionKey.type, OptValue<String>(value));

  Opt<Object>? _data;

  /// The cell of `data`, or Dart `null` when absent.
  Opt<Object>? get dataCell => _data;

  /// Stores the cell of `data`. Dart `null` deletes the key.
  set dataCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.data);
    } else {
      store(OptionKey.data, cell);
    }
  }

  /// Stores the plain value [value] of `data`.
  set data(Object value) =>
      store(OptionKey.data, classify(OptionKey.data, value));

  Opt<double>? _startAngle;

  /// The cell of `startAngle`, or Dart `null` when absent.
  Opt<double>? get startAngleCell => _startAngle;

  /// Stores the cell of `startAngle`. Dart `null` deletes the key.
  set startAngleCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.startAngle);
    } else {
      store(OptionKey.startAngle, cell);
    }
  }

  /// Stores the plain value [value] of `startAngle`.
  set startAngle(double value) =>
      store(OptionKey.startAngle, OptValue<double>(value));

  Opt<double>? _cutoutPercentage;

  /// The cell of `cutoutPercentage`, or Dart `null` when absent.
  Opt<double>? get cutoutPercentageCell => _cutoutPercentage;

  /// Stores the cell of `cutoutPercentage`. Dart `null` deletes the key.
  set cutoutPercentageCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.cutoutPercentage);
    } else {
      store(OptionKey.cutoutPercentage, cell);
    }
  }

  /// Stores the plain value [value] of `cutoutPercentage`.
  set cutoutPercentage(double value) =>
      store(OptionKey.cutoutPercentage, OptValue<double>(value));

  Opt<String>? _xAxisID;

  /// The cell of `xAxisID`, or Dart `null` when absent.
  Opt<String>? get xAxisIDCell => _xAxisID;

  /// Stores the cell of `xAxisID`. Dart `null` deletes the key.
  set xAxisIDCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.xAxisID);
    } else {
      store(OptionKey.xAxisID, cell);
    }
  }

  /// Stores the plain value [value] of `xAxisID`.
  set xAxisID(String value) =>
      store(OptionKey.xAxisID, OptValue<String>(value));

  Opt<String>? _yAxisID;

  /// The cell of `yAxisID`, or Dart `null` when absent.
  Opt<String>? get yAxisIDCell => _yAxisID;

  /// Stores the cell of `yAxisID`. Dart `null` deletes the key.
  set yAxisIDCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.yAxisID);
    } else {
      store(OptionKey.yAxisID, cell);
    }
  }

  /// Stores the plain value [value] of `yAxisID`.
  set yAxisID(String value) =>
      store(OptionKey.yAxisID, OptValue<String>(value));

  Opt<String>? _rAxisID;

  /// The cell of `rAxisID`, or Dart `null` when absent.
  Opt<String>? get rAxisIDCell => _rAxisID;

  /// Stores the cell of `rAxisID`. Dart `null` deletes the key.
  set rAxisIDCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.rAxisID);
    } else {
      store(OptionKey.rAxisID, cell);
    }
  }

  /// Stores the plain value [value] of `rAxisID`.
  set rAxisID(String value) =>
      store(OptionKey.rAxisID, OptValue<String>(value));

  Opt<Object>? _fill;

  /// The cell of `fill`, or Dart `null` when absent.
  Opt<Object>? get fillCell => _fill;

  /// Stores the cell of `fill`. Dart `null` deletes the key.
  set fillCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.fill);
    } else {
      store(OptionKey.fill, cell);
    }
  }

  /// Stores the plain value [value] of `fill`.
  set fill(Object value) =>
      store(OptionKey.fill, classify(OptionKey.fill, value));

  Opt<bool>? _drawActiveElementsOnTop;

  /// The cell of `drawActiveElementsOnTop`, or Dart `null` when absent.
  Opt<bool>? get drawActiveElementsOnTopCell => _drawActiveElementsOnTop;

  /// Stores the cell of `drawActiveElementsOnTop`. Dart `null` deletes the key.
  set drawActiveElementsOnTopCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.drawActiveElementsOnTop);
    } else {
      store(OptionKey.drawActiveElementsOnTop, cell);
    }
  }

  /// Stores the plain value [value] of `drawActiveElementsOnTop`.
  set drawActiveElementsOnTop(bool value) =>
      store(OptionKey.drawActiveElementsOnTop, OptValue<bool>(value));

  Opt<ElementOptionsByTypeScope>? _elements;

  /// The cell of `elements`, or Dart `null` when absent.
  Opt<ElementOptionsByTypeScope>? get elementsCell => _elements;

  /// Stores the cell of `elements`. Dart `null` deletes the key.
  set elementsCell(Opt<ElementOptionsByTypeScope>? cell) {
    if (cell == null) {
      delete(OptionKey.elements);
    } else {
      store(OptionKey.elements, cell);
    }
  }

  /// Stores the plain value [value] of `elements`.
  set elements(ElementOptionsByTypeScope value) =>
      store(OptionKey.elements, OptScope<ElementOptionsByTypeScope>(value));

  Opt<Object>? _datasetElementType;

  /// The cell of `datasetElementType`, or Dart `null` when absent.
  Opt<Object>? get datasetElementTypeCell => _datasetElementType;

  /// Stores the cell of `datasetElementType`. Dart `null` deletes the key.
  set datasetElementTypeCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.datasetElementType);
    } else {
      store(OptionKey.datasetElementType, cell);
    }
  }

  /// Stores the plain value [value] of `datasetElementType`.
  set datasetElementType(Object value) => store(
    OptionKey.datasetElementType,
    classify(OptionKey.datasetElementType, value),
  );

  Opt<Object>? _dataElementType;

  /// The cell of `dataElementType`, or Dart `null` when absent.
  Opt<Object>? get dataElementTypeCell => _dataElementType;

  /// Stores the cell of `dataElementType`. Dart `null` deletes the key.
  set dataElementTypeCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.dataElementType);
    } else {
      store(OptionKey.dataElementType, cell);
    }
  }

  /// Stores the plain value [value] of `dataElementType`.
  set dataElementType(Object value) => store(
    OptionKey.dataElementType,
    classify(OptionKey.dataElementType, value),
  );

  Opt<Object>? _descData;

  /// The cell of `_data`, or Dart `null` when absent.
  Opt<Object>? get descDataCell => _descData;

  /// Stores the cell of `_data`. Dart `null` deletes the key.
  set descDataCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.descData);
    } else {
      store(OptionKey.descData, cell);
    }
  }

  /// Stores the plain value [value] of `_data`.
  set descData(Object value) =>
      store(OptionKey.descData, classify(OptionKey.descData, value));

  Opt<Object>? _descDecimated;

  /// The cell of `_decimated`, or Dart `null` when absent.
  Opt<Object>? get descDecimatedCell => _descDecimated;

  /// Stores the cell of `_decimated`. Dart `null` deletes the key.
  set descDecimatedCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.descDecimated);
    } else {
      store(OptionKey.descDecimated, cell);
    }
  }

  /// Stores the plain value [value] of `_decimated`.
  set descDecimated(Object value) =>
      store(OptionKey.descDecimated, classify(OptionKey.descDecimated, value));

  @override
  Opt<Object?>? cellOf(OptionKey key) => switch (key) {
    OptionKey.parsing => _parsing,
    OptionKey.normalized => _normalized,
    OptionKey.indexAxis => _indexAxis,
    OptionKey.clip => _clip,
    OptionKey.label => _label,
    OptionKey.order => _order,
    OptionKey.stack => _stack,
    OptionKey.hidden => _hidden,
    OptionKey.borderWidth => _borderWidth,
    OptionKey.borderColor => _borderColor,
    OptionKey.backgroundColor => _backgroundColor,
    OptionKey.selfJoin => _selfJoin,
    OptionKey.borderAlign => _borderAlign,
    OptionKey.borderDash => _borderDash,
    OptionKey.borderDashOffset => _borderDashOffset,
    OptionKey.borderJoinStyle => _borderJoinStyle,
    OptionKey.borderRadius => _borderRadius,
    OptionKey.offset => _offset,
    OptionKey.circular => _circular,
    OptionKey.spacing => _spacing,
    OptionKey.spacingMode => _spacingMode,
    OptionKey.hoverBorderWidth => _hoverBorderWidth,
    OptionKey.hoverBorderColor => _hoverBorderColor,
    OptionKey.hoverBackgroundColor => _hoverBackgroundColor,
    OptionKey.hoverBorderDash => _hoverBorderDash,
    OptionKey.hoverBorderDashOffset => _hoverBorderDashOffset,
    OptionKey.hoverOffset => _hoverOffset,
    OptionKey.animation => _animation,
    OptionKey.animations => _animations,
    OptionKey.transitions => _transitions,
    OptionKey.circumference => _circumference,
    OptionKey.rotation => _rotation,
    OptionKey.weight => _weight,
    OptionKey.angle => _angle,
    OptionKey.tooltip => _tooltip,
    OptionKey.type => _type,
    OptionKey.data => _data,
    OptionKey.startAngle => _startAngle,
    OptionKey.cutoutPercentage => _cutoutPercentage,
    OptionKey.xAxisID => _xAxisID,
    OptionKey.yAxisID => _yAxisID,
    OptionKey.rAxisID => _rAxisID,
    OptionKey.fill => _fill,
    OptionKey.drawActiveElementsOnTop => _drawActiveElementsOnTop,
    OptionKey.elements => _elements,
    OptionKey.datasetElementType => _datasetElementType,
    OptionKey.dataElementType => _dataElementType,
    OptionKey.descData => _descData,
    OptionKey.descDecimated => _descDecimated,
    _ => null,
  };

  @override
  void setCell(OptionKey key, Opt<Object?>? cell) {
    switch (key) {
      case OptionKey.parsing:
        _parsing = fitCell(cell, (raw) => classifyUnion(raw, 34));
      case OptionKey.normalized:
        _normalized = fitCell(cell, classifyBool);
      case OptionKey.indexAxis:
        _indexAxis = fitCell(cell, classifyString);
      case OptionKey.clip:
        _clip = fitCell(cell, (raw) => classifyUnion(raw, 35));
      case OptionKey.label:
        _label = fitCell(cell, classifyString);
      case OptionKey.order:
        _order = fitCell(cell, classifyNumber);
      case OptionKey.stack:
        _stack = fitCell(cell, classifyString);
      case OptionKey.hidden:
        _hidden = fitCell(cell, classifyBool);
      case OptionKey.borderWidth:
        _borderWidth = fitCell(cell, classifyNumber);
      case OptionKey.borderColor:
        _borderColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.backgroundColor:
        _backgroundColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.selfJoin:
        _selfJoin = fitCell(cell, classifyBool);
      case OptionKey.borderAlign:
        _borderAlign = fitCell(cell, classifyString);
      case OptionKey.borderDash:
        _borderDash = fitCell(cell, (raw) => classifyUnion(raw, 16));
      case OptionKey.borderDashOffset:
        _borderDashOffset = fitCell(cell, classifyNumber);
      case OptionKey.borderJoinStyle:
        _borderJoinStyle = fitCell(cell, classifyString);
      case OptionKey.borderRadius:
        _borderRadius = fitCell(cell, (raw) => classifyUnion(raw, 33));
      case OptionKey.offset:
        _offset = fitCell(cell, classifyNumber);
      case OptionKey.circular:
        _circular = fitCell(cell, classifyBool);
      case OptionKey.spacing:
        _spacing = fitCell(cell, classifyNumber);
      case OptionKey.spacingMode:
        _spacingMode = fitCell(cell, classifyString);
      case OptionKey.hoverBorderWidth:
        _hoverBorderWidth = fitCell(cell, classifyNumber);
      case OptionKey.hoverBorderColor:
        _hoverBorderColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.hoverBackgroundColor:
        _hoverBackgroundColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.hoverBorderDash:
        _hoverBorderDash = fitCell(cell, (raw) => classifyUnion(raw, 16));
      case OptionKey.hoverBorderDashOffset:
        _hoverBorderDashOffset = fitCell(cell, classifyNumber);
      case OptionKey.hoverOffset:
        _hoverOffset = fitCell(cell, classifyNumber);
      case OptionKey.animation:
        _animation = fitCell(cell, (raw) => classifyUnion(raw, 34));
      case OptionKey.animations:
        _animations = fitCell(cell, (raw) => classifyUnion(raw, 34));
      case OptionKey.transitions:
        _transitions = fitCell(cell, classifyScope<TransitionsSpecScope>);
      case OptionKey.circumference:
        _circumference = fitCell(cell, classifyNumber);
      case OptionKey.rotation:
        _rotation = fitCell(cell, classifyNumber);
      case OptionKey.weight:
        _weight = fitCell(cell, classifyNumber);
      case OptionKey.angle:
        _angle = fitCell(cell, classifyNumber);
      case OptionKey.tooltip:
        _tooltip = fitCell(cell, classifyScope<TooltipDatasetOptionsScope>);
      case OptionKey.type:
        _type = fitCell(cell, classifyString);
      case OptionKey.data:
        _data = fitCell(cell, (raw) => classifyUnion(raw, 16));
      case OptionKey.startAngle:
        _startAngle = fitCell(cell, classifyNumber);
      case OptionKey.cutoutPercentage:
        _cutoutPercentage = fitCell(cell, classifyNumber);
      case OptionKey.xAxisID:
        _xAxisID = fitCell(cell, classifyString);
      case OptionKey.yAxisID:
        _yAxisID = fitCell(cell, classifyString);
      case OptionKey.rAxisID:
        _rAxisID = fitCell(cell, classifyString);
      case OptionKey.fill:
        _fill = fitCell(cell, (raw) => classifyUnion(raw, 39));
      case OptionKey.drawActiveElementsOnTop:
        _drawActiveElementsOnTop = fitCell(cell, classifyBool);
      case OptionKey.elements:
        _elements = fitCell(cell, classifyScope<ElementOptionsByTypeScope>);
      case OptionKey.datasetElementType:
        _datasetElementType = fitCell(cell, (raw) => classifyUnion(raw, 6));
      case OptionKey.dataElementType:
        _dataElementType = fitCell(cell, (raw) => classifyUnion(raw, 6));
      case OptionKey.descData:
        _descData = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.descDecimated:
        _descDecimated = fitCell(cell, (raw) => classifyUnion(raw, 64));
      default:
        throw ArgumentError.value(
          key,
          'key',
          'Not a key of PolarAreaControllerDatasetOptions',
        );
    }
  }

  @override
  bool hasField(OptionKey key) => switch (key) {
    OptionKey.parsing ||
    OptionKey.normalized ||
    OptionKey.indexAxis ||
    OptionKey.clip ||
    OptionKey.label ||
    OptionKey.order ||
    OptionKey.stack ||
    OptionKey.hidden ||
    OptionKey.borderWidth ||
    OptionKey.borderColor ||
    OptionKey.backgroundColor ||
    OptionKey.selfJoin ||
    OptionKey.borderAlign ||
    OptionKey.borderDash ||
    OptionKey.borderDashOffset ||
    OptionKey.borderJoinStyle ||
    OptionKey.borderRadius ||
    OptionKey.offset ||
    OptionKey.circular ||
    OptionKey.spacing ||
    OptionKey.spacingMode ||
    OptionKey.hoverBorderWidth ||
    OptionKey.hoverBorderColor ||
    OptionKey.hoverBackgroundColor ||
    OptionKey.hoverBorderDash ||
    OptionKey.hoverBorderDashOffset ||
    OptionKey.hoverOffset ||
    OptionKey.animation ||
    OptionKey.animations ||
    OptionKey.transitions ||
    OptionKey.circumference ||
    OptionKey.rotation ||
    OptionKey.weight ||
    OptionKey.angle ||
    OptionKey.tooltip ||
    OptionKey.type ||
    OptionKey.data ||
    OptionKey.startAngle ||
    OptionKey.cutoutPercentage ||
    OptionKey.xAxisID ||
    OptionKey.yAxisID ||
    OptionKey.rAxisID ||
    OptionKey.fill ||
    OptionKey.drawActiveElementsOnTop ||
    OptionKey.elements ||
    OptionKey.datasetElementType ||
    OptionKey.dataElementType ||
    OptionKey.descData ||
    OptionKey.descDecimated => true,
    _ => false,
  };

  @override
  Opt<Object?> classify(OptionKey key, Object? raw) => switch (key) {
    OptionKey.parsing => classifyUnion(raw, 34),
    OptionKey.normalized => classifyBool(raw),
    OptionKey.indexAxis => classifyString(raw),
    OptionKey.clip => classifyUnion(raw, 35),
    OptionKey.label => classifyString(raw),
    OptionKey.order => classifyNumber(raw),
    OptionKey.stack => classifyString(raw),
    OptionKey.hidden => classifyBool(raw),
    OptionKey.borderWidth => classifyNumber(raw),
    OptionKey.borderColor => classifyUnion(raw, 64),
    OptionKey.backgroundColor => classifyUnion(raw, 64),
    OptionKey.selfJoin => classifyBool(raw),
    OptionKey.borderAlign => classifyString(raw),
    OptionKey.borderDash => classifyUnion(raw, 16),
    OptionKey.borderDashOffset => classifyNumber(raw),
    OptionKey.borderJoinStyle => classifyString(raw),
    OptionKey.borderRadius => classifyUnion(raw, 33),
    OptionKey.offset => classifyNumber(raw),
    OptionKey.circular => classifyBool(raw),
    OptionKey.spacing => classifyNumber(raw),
    OptionKey.spacingMode => classifyString(raw),
    OptionKey.hoverBorderWidth => classifyNumber(raw),
    OptionKey.hoverBorderColor => classifyUnion(raw, 64),
    OptionKey.hoverBackgroundColor => classifyUnion(raw, 64),
    OptionKey.hoverBorderDash => classifyUnion(raw, 16),
    OptionKey.hoverBorderDashOffset => classifyNumber(raw),
    OptionKey.hoverOffset => classifyNumber(raw),
    OptionKey.animation => classifyUnion(raw, 34),
    OptionKey.animations => classifyUnion(raw, 34),
    OptionKey.transitions => classifyScope<TransitionsSpecScope>(raw),
    OptionKey.circumference => classifyNumber(raw),
    OptionKey.rotation => classifyNumber(raw),
    OptionKey.weight => classifyNumber(raw),
    OptionKey.angle => classifyNumber(raw),
    OptionKey.tooltip => classifyScope<TooltipDatasetOptionsScope>(raw),
    OptionKey.type => classifyString(raw),
    OptionKey.data => classifyUnion(raw, 16),
    OptionKey.startAngle => classifyNumber(raw),
    OptionKey.cutoutPercentage => classifyNumber(raw),
    OptionKey.xAxisID => classifyString(raw),
    OptionKey.yAxisID => classifyString(raw),
    OptionKey.rAxisID => classifyString(raw),
    OptionKey.fill => classifyUnion(raw, 39),
    OptionKey.drawActiveElementsOnTop => classifyBool(raw),
    OptionKey.elements => classifyScope<ElementOptionsByTypeScope>(raw),
    OptionKey.datasetElementType => classifyUnion(raw, 6),
    OptionKey.dataElementType => classifyUnion(raw, 6),
    OptionKey.descData => classifyUnion(raw, 64),
    OptionKey.descDecimated => classifyUnion(raw, 64),
    _ => kind.classifyOther(raw),
  };
}

/// index.d.ts:430 RadarControllerDatasetOptions (index.d.ts:66
/// ControllerDatasetOptions, the point options with the prefixed and hover
/// ones, LineOptions, LineHoverOptions, AnimationOptions) with index.d.ts:2317
/// FillerControllerDatasetOptions, a radar dataset and `datasets.radar`.
base class RadarControllerDatasetOptionsScope extends OptionScope {
  /// An empty scope.
  RadarControllerDatasetOptionsScope();

  @override
  ScopeKind get kind => ScopeKind.radarControllerDatasetOptions;

  Opt<Object>? _parsing;

  /// The cell of `parsing`, or Dart `null` when absent.
  Opt<Object>? get parsingCell => _parsing;

  /// Stores the cell of `parsing`. Dart `null` deletes the key.
  set parsingCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.parsing);
    } else {
      store(OptionKey.parsing, cell);
    }
  }

  /// Stores the plain value [value] of `parsing`.
  set parsing(Object value) =>
      store(OptionKey.parsing, classify(OptionKey.parsing, value));

  Opt<bool>? _normalized;

  /// The cell of `normalized`, or Dart `null` when absent.
  Opt<bool>? get normalizedCell => _normalized;

  /// Stores the cell of `normalized`. Dart `null` deletes the key.
  set normalizedCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.normalized);
    } else {
      store(OptionKey.normalized, cell);
    }
  }

  /// Stores the plain value [value] of `normalized`.
  set normalized(bool value) =>
      store(OptionKey.normalized, OptValue<bool>(value));

  Opt<String>? _indexAxis;

  /// The cell of `indexAxis`, or Dart `null` when absent.
  Opt<String>? get indexAxisCell => _indexAxis;

  /// Stores the cell of `indexAxis`. Dart `null` deletes the key.
  set indexAxisCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.indexAxis);
    } else {
      store(OptionKey.indexAxis, cell);
    }
  }

  /// Stores the plain value [value] of `indexAxis`.
  set indexAxis(String value) =>
      store(OptionKey.indexAxis, OptValue<String>(value));

  Opt<Object>? _clip;

  /// The cell of `clip`, or Dart `null` when absent.
  Opt<Object>? get clipCell => _clip;

  /// Stores the cell of `clip`. Dart `null` deletes the key.
  set clipCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.clip);
    } else {
      store(OptionKey.clip, cell);
    }
  }

  /// Stores the plain value [value] of `clip`.
  set clip(Object value) =>
      store(OptionKey.clip, classify(OptionKey.clip, value));

  Opt<String>? _label;

  /// The cell of `label`, or Dart `null` when absent.
  Opt<String>? get labelCell => _label;

  /// Stores the cell of `label`. Dart `null` deletes the key.
  set labelCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.label);
    } else {
      store(OptionKey.label, cell);
    }
  }

  /// Stores the plain value [value] of `label`.
  set label(String value) => store(OptionKey.label, OptValue<String>(value));

  Opt<double>? _order;

  /// The cell of `order`, or Dart `null` when absent.
  Opt<double>? get orderCell => _order;

  /// Stores the cell of `order`. Dart `null` deletes the key.
  set orderCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.order);
    } else {
      store(OptionKey.order, cell);
    }
  }

  /// Stores the plain value [value] of `order`.
  set order(double value) => store(OptionKey.order, OptValue<double>(value));

  Opt<String>? _stack;

  /// The cell of `stack`, or Dart `null` when absent.
  Opt<String>? get stackCell => _stack;

  /// Stores the cell of `stack`. Dart `null` deletes the key.
  set stackCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.stack);
    } else {
      store(OptionKey.stack, cell);
    }
  }

  /// Stores the plain value [value] of `stack`.
  set stack(String value) => store(OptionKey.stack, OptValue<String>(value));

  Opt<bool>? _hidden;

  /// The cell of `hidden`, or Dart `null` when absent.
  Opt<bool>? get hiddenCell => _hidden;

  /// Stores the cell of `hidden`. Dart `null` deletes the key.
  set hiddenCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.hidden);
    } else {
      store(OptionKey.hidden, cell);
    }
  }

  /// Stores the plain value [value] of `hidden`.
  set hidden(bool value) => store(OptionKey.hidden, OptValue<bool>(value));

  Opt<double>? _borderWidth;

  /// The cell of `borderWidth`, or Dart `null` when absent.
  Opt<double>? get borderWidthCell => _borderWidth;

  /// Stores the cell of `borderWidth`. Dart `null` deletes the key.
  set borderWidthCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.borderWidth);
    } else {
      store(OptionKey.borderWidth, cell);
    }
  }

  /// Stores the plain value [value] of `borderWidth`.
  set borderWidth(double value) =>
      store(OptionKey.borderWidth, OptValue<double>(value));

  Opt<Object>? _borderColor;

  /// The cell of `borderColor`, or Dart `null` when absent.
  Opt<Object>? get borderColorCell => _borderColor;

  /// Stores the cell of `borderColor`. Dart `null` deletes the key.
  set borderColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.borderColor);
    } else {
      store(OptionKey.borderColor, cell);
    }
  }

  /// Stores the plain value [value] of `borderColor`.
  set borderColor(Object value) =>
      store(OptionKey.borderColor, classify(OptionKey.borderColor, value));

  Opt<Object>? _backgroundColor;

  /// The cell of `backgroundColor`, or Dart `null` when absent.
  Opt<Object>? get backgroundColorCell => _backgroundColor;

  /// Stores the cell of `backgroundColor`. Dart `null` deletes the key.
  set backgroundColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.backgroundColor);
    } else {
      store(OptionKey.backgroundColor, cell);
    }
  }

  /// Stores the plain value [value] of `backgroundColor`.
  set backgroundColor(Object value) => store(
    OptionKey.backgroundColor,
    classify(OptionKey.backgroundColor, value),
  );

  Opt<double>? _radius;

  /// The cell of `radius`, or Dart `null` when absent.
  Opt<double>? get radiusCell => _radius;

  /// Stores the cell of `radius`. Dart `null` deletes the key.
  set radiusCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.radius);
    } else {
      store(OptionKey.radius, cell);
    }
  }

  /// Stores the plain value [value] of `radius`.
  set radius(double value) => store(OptionKey.radius, OptValue<double>(value));

  Opt<double>? _hitRadius;

  /// The cell of `hitRadius`, or Dart `null` when absent.
  Opt<double>? get hitRadiusCell => _hitRadius;

  /// Stores the cell of `hitRadius`. Dart `null` deletes the key.
  set hitRadiusCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.hitRadius);
    } else {
      store(OptionKey.hitRadius, cell);
    }
  }

  /// Stores the plain value [value] of `hitRadius`.
  set hitRadius(double value) =>
      store(OptionKey.hitRadius, OptValue<double>(value));

  Opt<Object>? _pointStyle;

  /// The cell of `pointStyle`, or Dart `null` when absent.
  Opt<Object>? get pointStyleCell => _pointStyle;

  /// Stores the cell of `pointStyle`. Dart `null` deletes the key.
  set pointStyleCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.pointStyle);
    } else {
      store(OptionKey.pointStyle, cell);
    }
  }

  /// Stores the plain value [value] of `pointStyle`.
  set pointStyle(Object value) =>
      store(OptionKey.pointStyle, classify(OptionKey.pointStyle, value));

  Opt<double>? _rotation;

  /// The cell of `rotation`, or Dart `null` when absent.
  Opt<double>? get rotationCell => _rotation;

  /// Stores the cell of `rotation`. Dart `null` deletes the key.
  set rotationCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.rotation);
    } else {
      store(OptionKey.rotation, cell);
    }
  }

  /// Stores the plain value [value] of `rotation`.
  set rotation(double value) =>
      store(OptionKey.rotation, OptValue<double>(value));

  Opt<bool>? _drawActiveElementsOnTop;

  /// The cell of `drawActiveElementsOnTop`, or Dart `null` when absent.
  Opt<bool>? get drawActiveElementsOnTopCell => _drawActiveElementsOnTop;

  /// Stores the cell of `drawActiveElementsOnTop`. Dart `null` deletes the key.
  set drawActiveElementsOnTopCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.drawActiveElementsOnTop);
    } else {
      store(OptionKey.drawActiveElementsOnTop, cell);
    }
  }

  /// Stores the plain value [value] of `drawActiveElementsOnTop`.
  set drawActiveElementsOnTop(bool value) =>
      store(OptionKey.drawActiveElementsOnTop, OptValue<bool>(value));

  Opt<double>? _hoverBorderWidth;

  /// The cell of `hoverBorderWidth`, or Dart `null` when absent.
  Opt<double>? get hoverBorderWidthCell => _hoverBorderWidth;

  /// Stores the cell of `hoverBorderWidth`. Dart `null` deletes the key.
  set hoverBorderWidthCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBorderWidth);
    } else {
      store(OptionKey.hoverBorderWidth, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBorderWidth`.
  set hoverBorderWidth(double value) =>
      store(OptionKey.hoverBorderWidth, OptValue<double>(value));

  Opt<Object>? _hoverBorderColor;

  /// The cell of `hoverBorderColor`, or Dart `null` when absent.
  Opt<Object>? get hoverBorderColorCell => _hoverBorderColor;

  /// Stores the cell of `hoverBorderColor`. Dart `null` deletes the key.
  set hoverBorderColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBorderColor);
    } else {
      store(OptionKey.hoverBorderColor, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBorderColor`.
  set hoverBorderColor(Object value) => store(
    OptionKey.hoverBorderColor,
    classify(OptionKey.hoverBorderColor, value),
  );

  Opt<Object>? _hoverBackgroundColor;

  /// The cell of `hoverBackgroundColor`, or Dart `null` when absent.
  Opt<Object>? get hoverBackgroundColorCell => _hoverBackgroundColor;

  /// Stores the cell of `hoverBackgroundColor`. Dart `null` deletes the key.
  set hoverBackgroundColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBackgroundColor);
    } else {
      store(OptionKey.hoverBackgroundColor, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBackgroundColor`.
  set hoverBackgroundColor(Object value) => store(
    OptionKey.hoverBackgroundColor,
    classify(OptionKey.hoverBackgroundColor, value),
  );

  Opt<double>? _hoverRadius;

  /// The cell of `hoverRadius`, or Dart `null` when absent.
  Opt<double>? get hoverRadiusCell => _hoverRadius;

  /// Stores the cell of `hoverRadius`. Dart `null` deletes the key.
  set hoverRadiusCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverRadius);
    } else {
      store(OptionKey.hoverRadius, cell);
    }
  }

  /// Stores the plain value [value] of `hoverRadius`.
  set hoverRadius(double value) =>
      store(OptionKey.hoverRadius, OptValue<double>(value));

  Opt<Object>? _pointBackgroundColor;

  /// The cell of `pointBackgroundColor`, or Dart `null` when absent.
  Opt<Object>? get pointBackgroundColorCell => _pointBackgroundColor;

  /// Stores the cell of `pointBackgroundColor`. Dart `null` deletes the key.
  set pointBackgroundColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.pointBackgroundColor);
    } else {
      store(OptionKey.pointBackgroundColor, cell);
    }
  }

  /// Stores the plain value [value] of `pointBackgroundColor`.
  set pointBackgroundColor(Object value) => store(
    OptionKey.pointBackgroundColor,
    classify(OptionKey.pointBackgroundColor, value),
  );

  Opt<Object>? _pointBorderColor;

  /// The cell of `pointBorderColor`, or Dart `null` when absent.
  Opt<Object>? get pointBorderColorCell => _pointBorderColor;

  /// Stores the cell of `pointBorderColor`. Dart `null` deletes the key.
  set pointBorderColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.pointBorderColor);
    } else {
      store(OptionKey.pointBorderColor, cell);
    }
  }

  /// Stores the plain value [value] of `pointBorderColor`.
  set pointBorderColor(Object value) => store(
    OptionKey.pointBorderColor,
    classify(OptionKey.pointBorderColor, value),
  );

  Opt<double>? _pointBorderWidth;

  /// The cell of `pointBorderWidth`, or Dart `null` when absent.
  Opt<double>? get pointBorderWidthCell => _pointBorderWidth;

  /// Stores the cell of `pointBorderWidth`. Dart `null` deletes the key.
  set pointBorderWidthCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.pointBorderWidth);
    } else {
      store(OptionKey.pointBorderWidth, cell);
    }
  }

  /// Stores the plain value [value] of `pointBorderWidth`.
  set pointBorderWidth(double value) =>
      store(OptionKey.pointBorderWidth, OptValue<double>(value));

  Opt<double>? _pointHitRadius;

  /// The cell of `pointHitRadius`, or Dart `null` when absent.
  Opt<double>? get pointHitRadiusCell => _pointHitRadius;

  /// Stores the cell of `pointHitRadius`. Dart `null` deletes the key.
  set pointHitRadiusCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.pointHitRadius);
    } else {
      store(OptionKey.pointHitRadius, cell);
    }
  }

  /// Stores the plain value [value] of `pointHitRadius`.
  set pointHitRadius(double value) =>
      store(OptionKey.pointHitRadius, OptValue<double>(value));

  Opt<double>? _pointRadius;

  /// The cell of `pointRadius`, or Dart `null` when absent.
  Opt<double>? get pointRadiusCell => _pointRadius;

  /// Stores the cell of `pointRadius`. Dart `null` deletes the key.
  set pointRadiusCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.pointRadius);
    } else {
      store(OptionKey.pointRadius, cell);
    }
  }

  /// Stores the plain value [value] of `pointRadius`.
  set pointRadius(double value) =>
      store(OptionKey.pointRadius, OptValue<double>(value));

  Opt<double>? _pointRotation;

  /// The cell of `pointRotation`, or Dart `null` when absent.
  Opt<double>? get pointRotationCell => _pointRotation;

  /// Stores the cell of `pointRotation`. Dart `null` deletes the key.
  set pointRotationCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.pointRotation);
    } else {
      store(OptionKey.pointRotation, cell);
    }
  }

  /// Stores the plain value [value] of `pointRotation`.
  set pointRotation(double value) =>
      store(OptionKey.pointRotation, OptValue<double>(value));

  Opt<Object>? _pointHoverBackgroundColor;

  /// The cell of `pointHoverBackgroundColor`, or Dart `null` when absent.
  Opt<Object>? get pointHoverBackgroundColorCell => _pointHoverBackgroundColor;

  /// Stores the cell of `pointHoverBackgroundColor`. Dart `null` deletes the key.
  set pointHoverBackgroundColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.pointHoverBackgroundColor);
    } else {
      store(OptionKey.pointHoverBackgroundColor, cell);
    }
  }

  /// Stores the plain value [value] of `pointHoverBackgroundColor`.
  set pointHoverBackgroundColor(Object value) => store(
    OptionKey.pointHoverBackgroundColor,
    classify(OptionKey.pointHoverBackgroundColor, value),
  );

  Opt<Object>? _pointHoverBorderColor;

  /// The cell of `pointHoverBorderColor`, or Dart `null` when absent.
  Opt<Object>? get pointHoverBorderColorCell => _pointHoverBorderColor;

  /// Stores the cell of `pointHoverBorderColor`. Dart `null` deletes the key.
  set pointHoverBorderColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.pointHoverBorderColor);
    } else {
      store(OptionKey.pointHoverBorderColor, cell);
    }
  }

  /// Stores the plain value [value] of `pointHoverBorderColor`.
  set pointHoverBorderColor(Object value) => store(
    OptionKey.pointHoverBorderColor,
    classify(OptionKey.pointHoverBorderColor, value),
  );

  Opt<double>? _pointHoverBorderWidth;

  /// The cell of `pointHoverBorderWidth`, or Dart `null` when absent.
  Opt<double>? get pointHoverBorderWidthCell => _pointHoverBorderWidth;

  /// Stores the cell of `pointHoverBorderWidth`. Dart `null` deletes the key.
  set pointHoverBorderWidthCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.pointHoverBorderWidth);
    } else {
      store(OptionKey.pointHoverBorderWidth, cell);
    }
  }

  /// Stores the plain value [value] of `pointHoverBorderWidth`.
  set pointHoverBorderWidth(double value) =>
      store(OptionKey.pointHoverBorderWidth, OptValue<double>(value));

  Opt<double>? _pointHoverRadius;

  /// The cell of `pointHoverRadius`, or Dart `null` when absent.
  Opt<double>? get pointHoverRadiusCell => _pointHoverRadius;

  /// Stores the cell of `pointHoverRadius`. Dart `null` deletes the key.
  set pointHoverRadiusCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.pointHoverRadius);
    } else {
      store(OptionKey.pointHoverRadius, cell);
    }
  }

  /// Stores the plain value [value] of `pointHoverRadius`.
  set pointHoverRadius(double value) =>
      store(OptionKey.pointHoverRadius, OptValue<double>(value));

  Opt<String>? _borderCapStyle;

  /// The cell of `borderCapStyle`, or Dart `null` when absent.
  Opt<String>? get borderCapStyleCell => _borderCapStyle;

  /// Stores the cell of `borderCapStyle`. Dart `null` deletes the key.
  set borderCapStyleCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.borderCapStyle);
    } else {
      store(OptionKey.borderCapStyle, cell);
    }
  }

  /// Stores the plain value [value] of `borderCapStyle`.
  set borderCapStyle(String value) =>
      store(OptionKey.borderCapStyle, OptValue<String>(value));

  Opt<Object>? _borderDash;

  /// The cell of `borderDash`, or Dart `null` when absent.
  Opt<Object>? get borderDashCell => _borderDash;

  /// Stores the cell of `borderDash`. Dart `null` deletes the key.
  set borderDashCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.borderDash);
    } else {
      store(OptionKey.borderDash, cell);
    }
  }

  /// Stores the plain value [value] of `borderDash`.
  set borderDash(Object value) =>
      store(OptionKey.borderDash, classify(OptionKey.borderDash, value));

  Opt<double>? _borderDashOffset;

  /// The cell of `borderDashOffset`, or Dart `null` when absent.
  Opt<double>? get borderDashOffsetCell => _borderDashOffset;

  /// Stores the cell of `borderDashOffset`. Dart `null` deletes the key.
  set borderDashOffsetCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.borderDashOffset);
    } else {
      store(OptionKey.borderDashOffset, cell);
    }
  }

  /// Stores the plain value [value] of `borderDashOffset`.
  set borderDashOffset(double value) =>
      store(OptionKey.borderDashOffset, OptValue<double>(value));

  Opt<String>? _borderJoinStyle;

  /// The cell of `borderJoinStyle`, or Dart `null` when absent.
  Opt<String>? get borderJoinStyleCell => _borderJoinStyle;

  /// Stores the cell of `borderJoinStyle`. Dart `null` deletes the key.
  set borderJoinStyleCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.borderJoinStyle);
    } else {
      store(OptionKey.borderJoinStyle, cell);
    }
  }

  /// Stores the plain value [value] of `borderJoinStyle`.
  set borderJoinStyle(String value) =>
      store(OptionKey.borderJoinStyle, OptValue<String>(value));

  Opt<bool>? _capBezierPoints;

  /// The cell of `capBezierPoints`, or Dart `null` when absent.
  Opt<bool>? get capBezierPointsCell => _capBezierPoints;

  /// Stores the cell of `capBezierPoints`. Dart `null` deletes the key.
  set capBezierPointsCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.capBezierPoints);
    } else {
      store(OptionKey.capBezierPoints, cell);
    }
  }

  /// Stores the plain value [value] of `capBezierPoints`.
  set capBezierPoints(bool value) =>
      store(OptionKey.capBezierPoints, OptValue<bool>(value));

  Opt<String>? _cubicInterpolationMode;

  /// The cell of `cubicInterpolationMode`, or Dart `null` when absent.
  Opt<String>? get cubicInterpolationModeCell => _cubicInterpolationMode;

  /// Stores the cell of `cubicInterpolationMode`. Dart `null` deletes the key.
  set cubicInterpolationModeCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.cubicInterpolationMode);
    } else {
      store(OptionKey.cubicInterpolationMode, cell);
    }
  }

  /// Stores the plain value [value] of `cubicInterpolationMode`.
  set cubicInterpolationMode(String value) =>
      store(OptionKey.cubicInterpolationMode, OptValue<String>(value));

  Opt<double>? _tension;

  /// The cell of `tension`, or Dart `null` when absent.
  Opt<double>? get tensionCell => _tension;

  /// Stores the cell of `tension`. Dart `null` deletes the key.
  set tensionCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.tension);
    } else {
      store(OptionKey.tension, cell);
    }
  }

  /// Stores the plain value [value] of `tension`.
  set tension(double value) =>
      store(OptionKey.tension, OptValue<double>(value));

  Opt<Object>? _stepped;

  /// The cell of `stepped`, or Dart `null` when absent.
  Opt<Object>? get steppedCell => _stepped;

  /// Stores the cell of `stepped`. Dart `null` deletes the key.
  set steppedCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.stepped);
    } else {
      store(OptionKey.stepped, cell);
    }
  }

  /// Stores the plain value [value] of `stepped`.
  set stepped(Object value) =>
      store(OptionKey.stepped, classify(OptionKey.stepped, value));

  Opt<Object>? _fill;

  /// The cell of `fill`, or Dart `null` when absent.
  Opt<Object>? get fillCell => _fill;

  /// Stores the cell of `fill`. Dart `null` deletes the key.
  set fillCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.fill);
    } else {
      store(OptionKey.fill, cell);
    }
  }

  /// Stores the plain value [value] of `fill`.
  set fill(Object value) =>
      store(OptionKey.fill, classify(OptionKey.fill, value));

  Opt<Object>? _spanGaps;

  /// The cell of `spanGaps`, or Dart `null` when absent.
  Opt<Object>? get spanGapsCell => _spanGaps;

  /// Stores the cell of `spanGaps`. Dart `null` deletes the key.
  set spanGapsCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.spanGaps);
    } else {
      store(OptionKey.spanGaps, cell);
    }
  }

  /// Stores the plain value [value] of `spanGaps`.
  set spanGaps(Object value) =>
      store(OptionKey.spanGaps, classify(OptionKey.spanGaps, value));

  Opt<SegmentOptionsScope>? _segment;

  /// The cell of `segment`, or Dart `null` when absent.
  Opt<SegmentOptionsScope>? get segmentCell => _segment;

  /// Stores the cell of `segment`. Dart `null` deletes the key.
  set segmentCell(Opt<SegmentOptionsScope>? cell) {
    if (cell == null) {
      delete(OptionKey.segment);
    } else {
      store(OptionKey.segment, cell);
    }
  }

  /// Stores the plain value [value] of `segment`.
  set segment(SegmentOptionsScope value) =>
      store(OptionKey.segment, OptScope<SegmentOptionsScope>(value));

  Opt<String>? _hoverBorderCapStyle;

  /// The cell of `hoverBorderCapStyle`, or Dart `null` when absent.
  Opt<String>? get hoverBorderCapStyleCell => _hoverBorderCapStyle;

  /// Stores the cell of `hoverBorderCapStyle`. Dart `null` deletes the key.
  set hoverBorderCapStyleCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBorderCapStyle);
    } else {
      store(OptionKey.hoverBorderCapStyle, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBorderCapStyle`.
  set hoverBorderCapStyle(String value) =>
      store(OptionKey.hoverBorderCapStyle, OptValue<String>(value));

  Opt<Object>? _hoverBorderDash;

  /// The cell of `hoverBorderDash`, or Dart `null` when absent.
  Opt<Object>? get hoverBorderDashCell => _hoverBorderDash;

  /// Stores the cell of `hoverBorderDash`. Dart `null` deletes the key.
  set hoverBorderDashCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBorderDash);
    } else {
      store(OptionKey.hoverBorderDash, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBorderDash`.
  set hoverBorderDash(Object value) => store(
    OptionKey.hoverBorderDash,
    classify(OptionKey.hoverBorderDash, value),
  );

  Opt<double>? _hoverBorderDashOffset;

  /// The cell of `hoverBorderDashOffset`, or Dart `null` when absent.
  Opt<double>? get hoverBorderDashOffsetCell => _hoverBorderDashOffset;

  /// Stores the cell of `hoverBorderDashOffset`. Dart `null` deletes the key.
  set hoverBorderDashOffsetCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBorderDashOffset);
    } else {
      store(OptionKey.hoverBorderDashOffset, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBorderDashOffset`.
  set hoverBorderDashOffset(double value) =>
      store(OptionKey.hoverBorderDashOffset, OptValue<double>(value));

  Opt<String>? _hoverBorderJoinStyle;

  /// The cell of `hoverBorderJoinStyle`, or Dart `null` when absent.
  Opt<String>? get hoverBorderJoinStyleCell => _hoverBorderJoinStyle;

  /// Stores the cell of `hoverBorderJoinStyle`. Dart `null` deletes the key.
  set hoverBorderJoinStyleCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.hoverBorderJoinStyle);
    } else {
      store(OptionKey.hoverBorderJoinStyle, cell);
    }
  }

  /// Stores the plain value [value] of `hoverBorderJoinStyle`.
  set hoverBorderJoinStyle(String value) =>
      store(OptionKey.hoverBorderJoinStyle, OptValue<String>(value));

  Opt<Object>? _animation;

  /// The cell of `animation`, or Dart `null` when absent.
  Opt<Object>? get animationCell => _animation;

  /// Stores the cell of `animation`. Dart `null` deletes the key.
  set animationCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.animation);
    } else {
      store(OptionKey.animation, cell);
    }
  }

  /// Stores the plain value [value] of `animation`.
  set animation(Object value) =>
      store(OptionKey.animation, classify(OptionKey.animation, value));

  Opt<Object>? _animations;

  /// The cell of `animations`, or Dart `null` when absent.
  Opt<Object>? get animationsCell => _animations;

  /// Stores the cell of `animations`. Dart `null` deletes the key.
  set animationsCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.animations);
    } else {
      store(OptionKey.animations, cell);
    }
  }

  /// Stores the plain value [value] of `animations`.
  set animations(Object value) =>
      store(OptionKey.animations, classify(OptionKey.animations, value));

  Opt<TransitionsSpecScope>? _transitions;

  /// The cell of `transitions`, or Dart `null` when absent.
  Opt<TransitionsSpecScope>? get transitionsCell => _transitions;

  /// Stores the cell of `transitions`. Dart `null` deletes the key.
  set transitionsCell(Opt<TransitionsSpecScope>? cell) {
    if (cell == null) {
      delete(OptionKey.transitions);
    } else {
      store(OptionKey.transitions, cell);
    }
  }

  /// Stores the plain value [value] of `transitions`.
  set transitions(TransitionsSpecScope value) =>
      store(OptionKey.transitions, OptScope<TransitionsSpecScope>(value));

  Opt<String>? _xAxisID;

  /// The cell of `xAxisID`, or Dart `null` when absent.
  Opt<String>? get xAxisIDCell => _xAxisID;

  /// Stores the cell of `xAxisID`. Dart `null` deletes the key.
  set xAxisIDCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.xAxisID);
    } else {
      store(OptionKey.xAxisID, cell);
    }
  }

  /// Stores the plain value [value] of `xAxisID`.
  set xAxisID(String value) =>
      store(OptionKey.xAxisID, OptValue<String>(value));

  Opt<String>? _yAxisID;

  /// The cell of `yAxisID`, or Dart `null` when absent.
  Opt<String>? get yAxisIDCell => _yAxisID;

  /// Stores the cell of `yAxisID`. Dart `null` deletes the key.
  set yAxisIDCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.yAxisID);
    } else {
      store(OptionKey.yAxisID, cell);
    }
  }

  /// Stores the plain value [value] of `yAxisID`.
  set yAxisID(String value) =>
      store(OptionKey.yAxisID, OptValue<String>(value));

  Opt<bool>? _showLine;

  /// The cell of `showLine`, or Dart `null` when absent.
  Opt<bool>? get showLineCell => _showLine;

  /// Stores the cell of `showLine`. Dart `null` deletes the key.
  set showLineCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.showLine);
    } else {
      store(OptionKey.showLine, cell);
    }
  }

  /// Stores the plain value [value] of `showLine`.
  set showLine(bool value) => store(OptionKey.showLine, OptValue<bool>(value));

  Opt<TooltipDatasetOptionsScope>? _tooltip;

  /// The cell of `tooltip`, or Dart `null` when absent.
  Opt<TooltipDatasetOptionsScope>? get tooltipCell => _tooltip;

  /// Stores the cell of `tooltip`. Dart `null` deletes the key.
  set tooltipCell(Opt<TooltipDatasetOptionsScope>? cell) {
    if (cell == null) {
      delete(OptionKey.tooltip);
    } else {
      store(OptionKey.tooltip, cell);
    }
  }

  /// Stores the plain value [value] of `tooltip`.
  set tooltip(TooltipDatasetOptionsScope value) =>
      store(OptionKey.tooltip, OptScope<TooltipDatasetOptionsScope>(value));

  Opt<String>? _type;

  /// The cell of `type`, or Dart `null` when absent.
  Opt<String>? get typeCell => _type;

  /// Stores the cell of `type`. Dart `null` deletes the key.
  set typeCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.type);
    } else {
      store(OptionKey.type, cell);
    }
  }

  /// Stores the plain value [value] of `type`.
  set type(String value) => store(OptionKey.type, OptValue<String>(value));

  Opt<Object>? _data;

  /// The cell of `data`, or Dart `null` when absent.
  Opt<Object>? get dataCell => _data;

  /// Stores the cell of `data`. Dart `null` deletes the key.
  set dataCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.data);
    } else {
      store(OptionKey.data, cell);
    }
  }

  /// Stores the plain value [value] of `data`.
  set data(Object value) =>
      store(OptionKey.data, classify(OptionKey.data, value));

  Opt<String>? _rAxisID;

  /// The cell of `rAxisID`, or Dart `null` when absent.
  Opt<String>? get rAxisIDCell => _rAxisID;

  /// Stores the cell of `rAxisID`. Dart `null` deletes the key.
  set rAxisIDCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.rAxisID);
    } else {
      store(OptionKey.rAxisID, cell);
    }
  }

  /// Stores the plain value [value] of `rAxisID`.
  set rAxisID(String value) =>
      store(OptionKey.rAxisID, OptValue<String>(value));

  Opt<ElementOptionsByTypeScope>? _elements;

  /// The cell of `elements`, or Dart `null` when absent.
  Opt<ElementOptionsByTypeScope>? get elementsCell => _elements;

  /// Stores the cell of `elements`. Dart `null` deletes the key.
  set elementsCell(Opt<ElementOptionsByTypeScope>? cell) {
    if (cell == null) {
      delete(OptionKey.elements);
    } else {
      store(OptionKey.elements, cell);
    }
  }

  /// Stores the plain value [value] of `elements`.
  set elements(ElementOptionsByTypeScope value) =>
      store(OptionKey.elements, OptScope<ElementOptionsByTypeScope>(value));

  Opt<Object>? _datasetElementType;

  /// The cell of `datasetElementType`, or Dart `null` when absent.
  Opt<Object>? get datasetElementTypeCell => _datasetElementType;

  /// Stores the cell of `datasetElementType`. Dart `null` deletes the key.
  set datasetElementTypeCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.datasetElementType);
    } else {
      store(OptionKey.datasetElementType, cell);
    }
  }

  /// Stores the plain value [value] of `datasetElementType`.
  set datasetElementType(Object value) => store(
    OptionKey.datasetElementType,
    classify(OptionKey.datasetElementType, value),
  );

  Opt<Object>? _dataElementType;

  /// The cell of `dataElementType`, or Dart `null` when absent.
  Opt<Object>? get dataElementTypeCell => _dataElementType;

  /// Stores the cell of `dataElementType`. Dart `null` deletes the key.
  set dataElementTypeCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.dataElementType);
    } else {
      store(OptionKey.dataElementType, cell);
    }
  }

  /// Stores the plain value [value] of `dataElementType`.
  set dataElementType(Object value) => store(
    OptionKey.dataElementType,
    classify(OptionKey.dataElementType, value),
  );

  Opt<Object>? _descData;

  /// The cell of `_data`, or Dart `null` when absent.
  Opt<Object>? get descDataCell => _descData;

  /// Stores the cell of `_data`. Dart `null` deletes the key.
  set descDataCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.descData);
    } else {
      store(OptionKey.descData, cell);
    }
  }

  /// Stores the plain value [value] of `_data`.
  set descData(Object value) =>
      store(OptionKey.descData, classify(OptionKey.descData, value));

  Opt<Object>? _descDecimated;

  /// The cell of `_decimated`, or Dart `null` when absent.
  Opt<Object>? get descDecimatedCell => _descDecimated;

  /// Stores the cell of `_decimated`. Dart `null` deletes the key.
  set descDecimatedCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.descDecimated);
    } else {
      store(OptionKey.descDecimated, cell);
    }
  }

  /// Stores the plain value [value] of `_decimated`.
  set descDecimated(Object value) =>
      store(OptionKey.descDecimated, classify(OptionKey.descDecimated, value));

  @override
  Opt<Object?>? cellOf(OptionKey key) => switch (key) {
    OptionKey.parsing => _parsing,
    OptionKey.normalized => _normalized,
    OptionKey.indexAxis => _indexAxis,
    OptionKey.clip => _clip,
    OptionKey.label => _label,
    OptionKey.order => _order,
    OptionKey.stack => _stack,
    OptionKey.hidden => _hidden,
    OptionKey.borderWidth => _borderWidth,
    OptionKey.borderColor => _borderColor,
    OptionKey.backgroundColor => _backgroundColor,
    OptionKey.radius => _radius,
    OptionKey.hitRadius => _hitRadius,
    OptionKey.pointStyle => _pointStyle,
    OptionKey.rotation => _rotation,
    OptionKey.drawActiveElementsOnTop => _drawActiveElementsOnTop,
    OptionKey.hoverBorderWidth => _hoverBorderWidth,
    OptionKey.hoverBorderColor => _hoverBorderColor,
    OptionKey.hoverBackgroundColor => _hoverBackgroundColor,
    OptionKey.hoverRadius => _hoverRadius,
    OptionKey.pointBackgroundColor => _pointBackgroundColor,
    OptionKey.pointBorderColor => _pointBorderColor,
    OptionKey.pointBorderWidth => _pointBorderWidth,
    OptionKey.pointHitRadius => _pointHitRadius,
    OptionKey.pointRadius => _pointRadius,
    OptionKey.pointRotation => _pointRotation,
    OptionKey.pointHoverBackgroundColor => _pointHoverBackgroundColor,
    OptionKey.pointHoverBorderColor => _pointHoverBorderColor,
    OptionKey.pointHoverBorderWidth => _pointHoverBorderWidth,
    OptionKey.pointHoverRadius => _pointHoverRadius,
    OptionKey.borderCapStyle => _borderCapStyle,
    OptionKey.borderDash => _borderDash,
    OptionKey.borderDashOffset => _borderDashOffset,
    OptionKey.borderJoinStyle => _borderJoinStyle,
    OptionKey.capBezierPoints => _capBezierPoints,
    OptionKey.cubicInterpolationMode => _cubicInterpolationMode,
    OptionKey.tension => _tension,
    OptionKey.stepped => _stepped,
    OptionKey.fill => _fill,
    OptionKey.spanGaps => _spanGaps,
    OptionKey.segment => _segment,
    OptionKey.hoverBorderCapStyle => _hoverBorderCapStyle,
    OptionKey.hoverBorderDash => _hoverBorderDash,
    OptionKey.hoverBorderDashOffset => _hoverBorderDashOffset,
    OptionKey.hoverBorderJoinStyle => _hoverBorderJoinStyle,
    OptionKey.animation => _animation,
    OptionKey.animations => _animations,
    OptionKey.transitions => _transitions,
    OptionKey.xAxisID => _xAxisID,
    OptionKey.yAxisID => _yAxisID,
    OptionKey.showLine => _showLine,
    OptionKey.tooltip => _tooltip,
    OptionKey.type => _type,
    OptionKey.data => _data,
    OptionKey.rAxisID => _rAxisID,
    OptionKey.elements => _elements,
    OptionKey.datasetElementType => _datasetElementType,
    OptionKey.dataElementType => _dataElementType,
    OptionKey.descData => _descData,
    OptionKey.descDecimated => _descDecimated,
    _ => null,
  };

  @override
  void setCell(OptionKey key, Opt<Object?>? cell) {
    switch (key) {
      case OptionKey.parsing:
        _parsing = fitCell(cell, (raw) => classifyUnion(raw, 34));
      case OptionKey.normalized:
        _normalized = fitCell(cell, classifyBool);
      case OptionKey.indexAxis:
        _indexAxis = fitCell(cell, classifyString);
      case OptionKey.clip:
        _clip = fitCell(cell, (raw) => classifyUnion(raw, 35));
      case OptionKey.label:
        _label = fitCell(cell, classifyString);
      case OptionKey.order:
        _order = fitCell(cell, classifyNumber);
      case OptionKey.stack:
        _stack = fitCell(cell, classifyString);
      case OptionKey.hidden:
        _hidden = fitCell(cell, classifyBool);
      case OptionKey.borderWidth:
        _borderWidth = fitCell(cell, classifyNumber);
      case OptionKey.borderColor:
        _borderColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.backgroundColor:
        _backgroundColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.radius:
        _radius = fitCell(cell, classifyNumber);
      case OptionKey.hitRadius:
        _hitRadius = fitCell(cell, classifyNumber);
      case OptionKey.pointStyle:
        _pointStyle = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.rotation:
        _rotation = fitCell(cell, classifyNumber);
      case OptionKey.drawActiveElementsOnTop:
        _drawActiveElementsOnTop = fitCell(cell, classifyBool);
      case OptionKey.hoverBorderWidth:
        _hoverBorderWidth = fitCell(cell, classifyNumber);
      case OptionKey.hoverBorderColor:
        _hoverBorderColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.hoverBackgroundColor:
        _hoverBackgroundColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.hoverRadius:
        _hoverRadius = fitCell(cell, classifyNumber);
      case OptionKey.pointBackgroundColor:
        _pointBackgroundColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.pointBorderColor:
        _pointBorderColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.pointBorderWidth:
        _pointBorderWidth = fitCell(cell, classifyNumber);
      case OptionKey.pointHitRadius:
        _pointHitRadius = fitCell(cell, classifyNumber);
      case OptionKey.pointRadius:
        _pointRadius = fitCell(cell, classifyNumber);
      case OptionKey.pointRotation:
        _pointRotation = fitCell(cell, classifyNumber);
      case OptionKey.pointHoverBackgroundColor:
        _pointHoverBackgroundColor = fitCell(
          cell,
          (raw) => classifyUnion(raw, 64),
        );
      case OptionKey.pointHoverBorderColor:
        _pointHoverBorderColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.pointHoverBorderWidth:
        _pointHoverBorderWidth = fitCell(cell, classifyNumber);
      case OptionKey.pointHoverRadius:
        _pointHoverRadius = fitCell(cell, classifyNumber);
      case OptionKey.borderCapStyle:
        _borderCapStyle = fitCell(cell, classifyString);
      case OptionKey.borderDash:
        _borderDash = fitCell(cell, (raw) => classifyUnion(raw, 16));
      case OptionKey.borderDashOffset:
        _borderDashOffset = fitCell(cell, classifyNumber);
      case OptionKey.borderJoinStyle:
        _borderJoinStyle = fitCell(cell, classifyString);
      case OptionKey.capBezierPoints:
        _capBezierPoints = fitCell(cell, classifyBool);
      case OptionKey.cubicInterpolationMode:
        _cubicInterpolationMode = fitCell(cell, classifyString);
      case OptionKey.tension:
        _tension = fitCell(cell, classifyNumber);
      case OptionKey.stepped:
        _stepped = fitCell(cell, (raw) => classifyUnion(raw, 6));
      case OptionKey.fill:
        _fill = fitCell(cell, (raw) => classifyUnion(raw, 39));
      case OptionKey.spanGaps:
        _spanGaps = fitCell(cell, (raw) => classifyUnion(raw, 3));
      case OptionKey.segment:
        _segment = fitCell(cell, classifyScope<SegmentOptionsScope>);
      case OptionKey.hoverBorderCapStyle:
        _hoverBorderCapStyle = fitCell(cell, classifyString);
      case OptionKey.hoverBorderDash:
        _hoverBorderDash = fitCell(cell, (raw) => classifyUnion(raw, 16));
      case OptionKey.hoverBorderDashOffset:
        _hoverBorderDashOffset = fitCell(cell, classifyNumber);
      case OptionKey.hoverBorderJoinStyle:
        _hoverBorderJoinStyle = fitCell(cell, classifyString);
      case OptionKey.animation:
        _animation = fitCell(cell, (raw) => classifyUnion(raw, 34));
      case OptionKey.animations:
        _animations = fitCell(cell, (raw) => classifyUnion(raw, 34));
      case OptionKey.transitions:
        _transitions = fitCell(cell, classifyScope<TransitionsSpecScope>);
      case OptionKey.xAxisID:
        _xAxisID = fitCell(cell, classifyString);
      case OptionKey.yAxisID:
        _yAxisID = fitCell(cell, classifyString);
      case OptionKey.showLine:
        _showLine = fitCell(cell, classifyBool);
      case OptionKey.tooltip:
        _tooltip = fitCell(cell, classifyScope<TooltipDatasetOptionsScope>);
      case OptionKey.type:
        _type = fitCell(cell, classifyString);
      case OptionKey.data:
        _data = fitCell(cell, (raw) => classifyUnion(raw, 16));
      case OptionKey.rAxisID:
        _rAxisID = fitCell(cell, classifyString);
      case OptionKey.elements:
        _elements = fitCell(cell, classifyScope<ElementOptionsByTypeScope>);
      case OptionKey.datasetElementType:
        _datasetElementType = fitCell(cell, (raw) => classifyUnion(raw, 6));
      case OptionKey.dataElementType:
        _dataElementType = fitCell(cell, (raw) => classifyUnion(raw, 6));
      case OptionKey.descData:
        _descData = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.descDecimated:
        _descDecimated = fitCell(cell, (raw) => classifyUnion(raw, 64));
      default:
        throw ArgumentError.value(
          key,
          'key',
          'Not a key of RadarControllerDatasetOptions',
        );
    }
  }

  @override
  bool hasField(OptionKey key) => switch (key) {
    OptionKey.parsing ||
    OptionKey.normalized ||
    OptionKey.indexAxis ||
    OptionKey.clip ||
    OptionKey.label ||
    OptionKey.order ||
    OptionKey.stack ||
    OptionKey.hidden ||
    OptionKey.borderWidth ||
    OptionKey.borderColor ||
    OptionKey.backgroundColor ||
    OptionKey.radius ||
    OptionKey.hitRadius ||
    OptionKey.pointStyle ||
    OptionKey.rotation ||
    OptionKey.drawActiveElementsOnTop ||
    OptionKey.hoverBorderWidth ||
    OptionKey.hoverBorderColor ||
    OptionKey.hoverBackgroundColor ||
    OptionKey.hoverRadius ||
    OptionKey.pointBackgroundColor ||
    OptionKey.pointBorderColor ||
    OptionKey.pointBorderWidth ||
    OptionKey.pointHitRadius ||
    OptionKey.pointRadius ||
    OptionKey.pointRotation ||
    OptionKey.pointHoverBackgroundColor ||
    OptionKey.pointHoverBorderColor ||
    OptionKey.pointHoverBorderWidth ||
    OptionKey.pointHoverRadius ||
    OptionKey.borderCapStyle ||
    OptionKey.borderDash ||
    OptionKey.borderDashOffset ||
    OptionKey.borderJoinStyle ||
    OptionKey.capBezierPoints ||
    OptionKey.cubicInterpolationMode ||
    OptionKey.tension ||
    OptionKey.stepped ||
    OptionKey.fill ||
    OptionKey.spanGaps ||
    OptionKey.segment ||
    OptionKey.hoverBorderCapStyle ||
    OptionKey.hoverBorderDash ||
    OptionKey.hoverBorderDashOffset ||
    OptionKey.hoverBorderJoinStyle ||
    OptionKey.animation ||
    OptionKey.animations ||
    OptionKey.transitions ||
    OptionKey.xAxisID ||
    OptionKey.yAxisID ||
    OptionKey.showLine ||
    OptionKey.tooltip ||
    OptionKey.type ||
    OptionKey.data ||
    OptionKey.rAxisID ||
    OptionKey.elements ||
    OptionKey.datasetElementType ||
    OptionKey.dataElementType ||
    OptionKey.descData ||
    OptionKey.descDecimated => true,
    _ => false,
  };

  @override
  Opt<Object?> classify(OptionKey key, Object? raw) => switch (key) {
    OptionKey.parsing => classifyUnion(raw, 34),
    OptionKey.normalized => classifyBool(raw),
    OptionKey.indexAxis => classifyString(raw),
    OptionKey.clip => classifyUnion(raw, 35),
    OptionKey.label => classifyString(raw),
    OptionKey.order => classifyNumber(raw),
    OptionKey.stack => classifyString(raw),
    OptionKey.hidden => classifyBool(raw),
    OptionKey.borderWidth => classifyNumber(raw),
    OptionKey.borderColor => classifyUnion(raw, 64),
    OptionKey.backgroundColor => classifyUnion(raw, 64),
    OptionKey.radius => classifyNumber(raw),
    OptionKey.hitRadius => classifyNumber(raw),
    OptionKey.pointStyle => classifyUnion(raw, 64),
    OptionKey.rotation => classifyNumber(raw),
    OptionKey.drawActiveElementsOnTop => classifyBool(raw),
    OptionKey.hoverBorderWidth => classifyNumber(raw),
    OptionKey.hoverBorderColor => classifyUnion(raw, 64),
    OptionKey.hoverBackgroundColor => classifyUnion(raw, 64),
    OptionKey.hoverRadius => classifyNumber(raw),
    OptionKey.pointBackgroundColor => classifyUnion(raw, 64),
    OptionKey.pointBorderColor => classifyUnion(raw, 64),
    OptionKey.pointBorderWidth => classifyNumber(raw),
    OptionKey.pointHitRadius => classifyNumber(raw),
    OptionKey.pointRadius => classifyNumber(raw),
    OptionKey.pointRotation => classifyNumber(raw),
    OptionKey.pointHoverBackgroundColor => classifyUnion(raw, 64),
    OptionKey.pointHoverBorderColor => classifyUnion(raw, 64),
    OptionKey.pointHoverBorderWidth => classifyNumber(raw),
    OptionKey.pointHoverRadius => classifyNumber(raw),
    OptionKey.borderCapStyle => classifyString(raw),
    OptionKey.borderDash => classifyUnion(raw, 16),
    OptionKey.borderDashOffset => classifyNumber(raw),
    OptionKey.borderJoinStyle => classifyString(raw),
    OptionKey.capBezierPoints => classifyBool(raw),
    OptionKey.cubicInterpolationMode => classifyString(raw),
    OptionKey.tension => classifyNumber(raw),
    OptionKey.stepped => classifyUnion(raw, 6),
    OptionKey.fill => classifyUnion(raw, 39),
    OptionKey.spanGaps => classifyUnion(raw, 3),
    OptionKey.segment => classifyScope<SegmentOptionsScope>(raw),
    OptionKey.hoverBorderCapStyle => classifyString(raw),
    OptionKey.hoverBorderDash => classifyUnion(raw, 16),
    OptionKey.hoverBorderDashOffset => classifyNumber(raw),
    OptionKey.hoverBorderJoinStyle => classifyString(raw),
    OptionKey.animation => classifyUnion(raw, 34),
    OptionKey.animations => classifyUnion(raw, 34),
    OptionKey.transitions => classifyScope<TransitionsSpecScope>(raw),
    OptionKey.xAxisID => classifyString(raw),
    OptionKey.yAxisID => classifyString(raw),
    OptionKey.showLine => classifyBool(raw),
    OptionKey.tooltip => classifyScope<TooltipDatasetOptionsScope>(raw),
    OptionKey.type => classifyString(raw),
    OptionKey.data => classifyUnion(raw, 16),
    OptionKey.rAxisID => classifyString(raw),
    OptionKey.elements => classifyScope<ElementOptionsByTypeScope>(raw),
    OptionKey.datasetElementType => classifyUnion(raw, 6),
    OptionKey.dataElementType => classifyUnion(raw, 6),
    OptionKey.descData => classifyUnion(raw, 64),
    OptionKey.descDecimated => classifyUnion(raw, 64),
    _ => kind.classifyOther(raw),
  };
}

/// index.d.ts:66 ControllerDatasetOptions with index.d.ts:3859
/// ChartDatasetProperties and the keys that core code reads for each dataset, a
/// dataset of a chart type without a dataset kind and `datasets.<custom type>`.
base class GenericDatasetOptionsScope extends OptionScope {
  /// An empty scope.
  GenericDatasetOptionsScope();

  @override
  ScopeKind get kind => ScopeKind.genericDatasetOptions;

  Opt<Object>? _parsing;

  /// The cell of `parsing`, or Dart `null` when absent.
  Opt<Object>? get parsingCell => _parsing;

  /// Stores the cell of `parsing`. Dart `null` deletes the key.
  set parsingCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.parsing);
    } else {
      store(OptionKey.parsing, cell);
    }
  }

  /// Stores the plain value [value] of `parsing`.
  set parsing(Object value) =>
      store(OptionKey.parsing, classify(OptionKey.parsing, value));

  Opt<bool>? _normalized;

  /// The cell of `normalized`, or Dart `null` when absent.
  Opt<bool>? get normalizedCell => _normalized;

  /// Stores the cell of `normalized`. Dart `null` deletes the key.
  set normalizedCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.normalized);
    } else {
      store(OptionKey.normalized, cell);
    }
  }

  /// Stores the plain value [value] of `normalized`.
  set normalized(bool value) =>
      store(OptionKey.normalized, OptValue<bool>(value));

  Opt<String>? _indexAxis;

  /// The cell of `indexAxis`, or Dart `null` when absent.
  Opt<String>? get indexAxisCell => _indexAxis;

  /// Stores the cell of `indexAxis`. Dart `null` deletes the key.
  set indexAxisCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.indexAxis);
    } else {
      store(OptionKey.indexAxis, cell);
    }
  }

  /// Stores the plain value [value] of `indexAxis`.
  set indexAxis(String value) =>
      store(OptionKey.indexAxis, OptValue<String>(value));

  Opt<Object>? _clip;

  /// The cell of `clip`, or Dart `null` when absent.
  Opt<Object>? get clipCell => _clip;

  /// Stores the cell of `clip`. Dart `null` deletes the key.
  set clipCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.clip);
    } else {
      store(OptionKey.clip, cell);
    }
  }

  /// Stores the plain value [value] of `clip`.
  set clip(Object value) =>
      store(OptionKey.clip, classify(OptionKey.clip, value));

  Opt<String>? _label;

  /// The cell of `label`, or Dart `null` when absent.
  Opt<String>? get labelCell => _label;

  /// Stores the cell of `label`. Dart `null` deletes the key.
  set labelCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.label);
    } else {
      store(OptionKey.label, cell);
    }
  }

  /// Stores the plain value [value] of `label`.
  set label(String value) => store(OptionKey.label, OptValue<String>(value));

  Opt<double>? _order;

  /// The cell of `order`, or Dart `null` when absent.
  Opt<double>? get orderCell => _order;

  /// Stores the cell of `order`. Dart `null` deletes the key.
  set orderCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.order);
    } else {
      store(OptionKey.order, cell);
    }
  }

  /// Stores the plain value [value] of `order`.
  set order(double value) => store(OptionKey.order, OptValue<double>(value));

  Opt<String>? _stack;

  /// The cell of `stack`, or Dart `null` when absent.
  Opt<String>? get stackCell => _stack;

  /// Stores the cell of `stack`. Dart `null` deletes the key.
  set stackCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.stack);
    } else {
      store(OptionKey.stack, cell);
    }
  }

  /// Stores the plain value [value] of `stack`.
  set stack(String value) => store(OptionKey.stack, OptValue<String>(value));

  Opt<bool>? _hidden;

  /// The cell of `hidden`, or Dart `null` when absent.
  Opt<bool>? get hiddenCell => _hidden;

  /// Stores the cell of `hidden`. Dart `null` deletes the key.
  set hiddenCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.hidden);
    } else {
      store(OptionKey.hidden, cell);
    }
  }

  /// Stores the plain value [value] of `hidden`.
  set hidden(bool value) => store(OptionKey.hidden, OptValue<bool>(value));

  Opt<TooltipDatasetOptionsScope>? _tooltip;

  /// The cell of `tooltip`, or Dart `null` when absent.
  Opt<TooltipDatasetOptionsScope>? get tooltipCell => _tooltip;

  /// Stores the cell of `tooltip`. Dart `null` deletes the key.
  set tooltipCell(Opt<TooltipDatasetOptionsScope>? cell) {
    if (cell == null) {
      delete(OptionKey.tooltip);
    } else {
      store(OptionKey.tooltip, cell);
    }
  }

  /// Stores the plain value [value] of `tooltip`.
  set tooltip(TooltipDatasetOptionsScope value) =>
      store(OptionKey.tooltip, OptScope<TooltipDatasetOptionsScope>(value));

  Opt<String>? _type;

  /// The cell of `type`, or Dart `null` when absent.
  Opt<String>? get typeCell => _type;

  /// Stores the cell of `type`. Dart `null` deletes the key.
  set typeCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.type);
    } else {
      store(OptionKey.type, cell);
    }
  }

  /// Stores the plain value [value] of `type`.
  set type(String value) => store(OptionKey.type, OptValue<String>(value));

  Opt<Object>? _data;

  /// The cell of `data`, or Dart `null` when absent.
  Opt<Object>? get dataCell => _data;

  /// Stores the cell of `data`. Dart `null` deletes the key.
  set dataCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.data);
    } else {
      store(OptionKey.data, cell);
    }
  }

  /// Stores the plain value [value] of `data`.
  set data(Object value) =>
      store(OptionKey.data, classify(OptionKey.data, value));

  Opt<String>? _xAxisID;

  /// The cell of `xAxisID`, or Dart `null` when absent.
  Opt<String>? get xAxisIDCell => _xAxisID;

  /// Stores the cell of `xAxisID`. Dart `null` deletes the key.
  set xAxisIDCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.xAxisID);
    } else {
      store(OptionKey.xAxisID, cell);
    }
  }

  /// Stores the plain value [value] of `xAxisID`.
  set xAxisID(String value) =>
      store(OptionKey.xAxisID, OptValue<String>(value));

  Opt<String>? _yAxisID;

  /// The cell of `yAxisID`, or Dart `null` when absent.
  Opt<String>? get yAxisIDCell => _yAxisID;

  /// Stores the cell of `yAxisID`. Dart `null` deletes the key.
  set yAxisIDCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.yAxisID);
    } else {
      store(OptionKey.yAxisID, cell);
    }
  }

  /// Stores the plain value [value] of `yAxisID`.
  set yAxisID(String value) =>
      store(OptionKey.yAxisID, OptValue<String>(value));

  Opt<String>? _rAxisID;

  /// The cell of `rAxisID`, or Dart `null` when absent.
  Opt<String>? get rAxisIDCell => _rAxisID;

  /// Stores the cell of `rAxisID`. Dart `null` deletes the key.
  set rAxisIDCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.rAxisID);
    } else {
      store(OptionKey.rAxisID, cell);
    }
  }

  /// Stores the plain value [value] of `rAxisID`.
  set rAxisID(String value) =>
      store(OptionKey.rAxisID, OptValue<String>(value));

  Opt<Object>? _fill;

  /// The cell of `fill`, or Dart `null` when absent.
  Opt<Object>? get fillCell => _fill;

  /// Stores the cell of `fill`. Dart `null` deletes the key.
  set fillCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.fill);
    } else {
      store(OptionKey.fill, cell);
    }
  }

  /// Stores the plain value [value] of `fill`.
  set fill(Object value) =>
      store(OptionKey.fill, classify(OptionKey.fill, value));

  Opt<bool>? _drawActiveElementsOnTop;

  /// The cell of `drawActiveElementsOnTop`, or Dart `null` when absent.
  Opt<bool>? get drawActiveElementsOnTopCell => _drawActiveElementsOnTop;

  /// Stores the cell of `drawActiveElementsOnTop`. Dart `null` deletes the key.
  set drawActiveElementsOnTopCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.drawActiveElementsOnTop);
    } else {
      store(OptionKey.drawActiveElementsOnTop, cell);
    }
  }

  /// Stores the plain value [value] of `drawActiveElementsOnTop`.
  set drawActiveElementsOnTop(bool value) =>
      store(OptionKey.drawActiveElementsOnTop, OptValue<bool>(value));

  Opt<Object>? _animation;

  /// The cell of `animation`, or Dart `null` when absent.
  Opt<Object>? get animationCell => _animation;

  /// Stores the cell of `animation`. Dart `null` deletes the key.
  set animationCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.animation);
    } else {
      store(OptionKey.animation, cell);
    }
  }

  /// Stores the plain value [value] of `animation`.
  set animation(Object value) =>
      store(OptionKey.animation, classify(OptionKey.animation, value));

  Opt<Object>? _animations;

  /// The cell of `animations`, or Dart `null` when absent.
  Opt<Object>? get animationsCell => _animations;

  /// Stores the cell of `animations`. Dart `null` deletes the key.
  set animationsCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.animations);
    } else {
      store(OptionKey.animations, cell);
    }
  }

  /// Stores the plain value [value] of `animations`.
  set animations(Object value) =>
      store(OptionKey.animations, classify(OptionKey.animations, value));

  Opt<TransitionsSpecScope>? _transitions;

  /// The cell of `transitions`, or Dart `null` when absent.
  Opt<TransitionsSpecScope>? get transitionsCell => _transitions;

  /// Stores the cell of `transitions`. Dart `null` deletes the key.
  set transitionsCell(Opt<TransitionsSpecScope>? cell) {
    if (cell == null) {
      delete(OptionKey.transitions);
    } else {
      store(OptionKey.transitions, cell);
    }
  }

  /// Stores the plain value [value] of `transitions`.
  set transitions(TransitionsSpecScope value) =>
      store(OptionKey.transitions, OptScope<TransitionsSpecScope>(value));

  Opt<ElementOptionsByTypeScope>? _elements;

  /// The cell of `elements`, or Dart `null` when absent.
  Opt<ElementOptionsByTypeScope>? get elementsCell => _elements;

  /// Stores the cell of `elements`. Dart `null` deletes the key.
  set elementsCell(Opt<ElementOptionsByTypeScope>? cell) {
    if (cell == null) {
      delete(OptionKey.elements);
    } else {
      store(OptionKey.elements, cell);
    }
  }

  /// Stores the plain value [value] of `elements`.
  set elements(ElementOptionsByTypeScope value) =>
      store(OptionKey.elements, OptScope<ElementOptionsByTypeScope>(value));

  Opt<Object>? _datasetElementType;

  /// The cell of `datasetElementType`, or Dart `null` when absent.
  Opt<Object>? get datasetElementTypeCell => _datasetElementType;

  /// Stores the cell of `datasetElementType`. Dart `null` deletes the key.
  set datasetElementTypeCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.datasetElementType);
    } else {
      store(OptionKey.datasetElementType, cell);
    }
  }

  /// Stores the plain value [value] of `datasetElementType`.
  set datasetElementType(Object value) => store(
    OptionKey.datasetElementType,
    classify(OptionKey.datasetElementType, value),
  );

  Opt<Object>? _dataElementType;

  /// The cell of `dataElementType`, or Dart `null` when absent.
  Opt<Object>? get dataElementTypeCell => _dataElementType;

  /// Stores the cell of `dataElementType`. Dart `null` deletes the key.
  set dataElementTypeCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.dataElementType);
    } else {
      store(OptionKey.dataElementType, cell);
    }
  }

  /// Stores the plain value [value] of `dataElementType`.
  set dataElementType(Object value) => store(
    OptionKey.dataElementType,
    classify(OptionKey.dataElementType, value),
  );

  Opt<Object>? _descData;

  /// The cell of `_data`, or Dart `null` when absent.
  Opt<Object>? get descDataCell => _descData;

  /// Stores the cell of `_data`. Dart `null` deletes the key.
  set descDataCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.descData);
    } else {
      store(OptionKey.descData, cell);
    }
  }

  /// Stores the plain value [value] of `_data`.
  set descData(Object value) =>
      store(OptionKey.descData, classify(OptionKey.descData, value));

  Opt<Object>? _descDecimated;

  /// The cell of `_decimated`, or Dart `null` when absent.
  Opt<Object>? get descDecimatedCell => _descDecimated;

  /// Stores the cell of `_decimated`. Dart `null` deletes the key.
  set descDecimatedCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.descDecimated);
    } else {
      store(OptionKey.descDecimated, cell);
    }
  }

  /// Stores the plain value [value] of `_decimated`.
  set descDecimated(Object value) =>
      store(OptionKey.descDecimated, classify(OptionKey.descDecimated, value));

  @override
  Opt<Object?>? cellOf(OptionKey key) => switch (key) {
    OptionKey.parsing => _parsing,
    OptionKey.normalized => _normalized,
    OptionKey.indexAxis => _indexAxis,
    OptionKey.clip => _clip,
    OptionKey.label => _label,
    OptionKey.order => _order,
    OptionKey.stack => _stack,
    OptionKey.hidden => _hidden,
    OptionKey.tooltip => _tooltip,
    OptionKey.type => _type,
    OptionKey.data => _data,
    OptionKey.xAxisID => _xAxisID,
    OptionKey.yAxisID => _yAxisID,
    OptionKey.rAxisID => _rAxisID,
    OptionKey.fill => _fill,
    OptionKey.drawActiveElementsOnTop => _drawActiveElementsOnTop,
    OptionKey.animation => _animation,
    OptionKey.animations => _animations,
    OptionKey.transitions => _transitions,
    OptionKey.elements => _elements,
    OptionKey.datasetElementType => _datasetElementType,
    OptionKey.dataElementType => _dataElementType,
    OptionKey.descData => _descData,
    OptionKey.descDecimated => _descDecimated,
    _ => null,
  };

  @override
  void setCell(OptionKey key, Opt<Object?>? cell) {
    switch (key) {
      case OptionKey.parsing:
        _parsing = fitCell(cell, (raw) => classifyUnion(raw, 34));
      case OptionKey.normalized:
        _normalized = fitCell(cell, classifyBool);
      case OptionKey.indexAxis:
        _indexAxis = fitCell(cell, classifyString);
      case OptionKey.clip:
        _clip = fitCell(cell, (raw) => classifyUnion(raw, 35));
      case OptionKey.label:
        _label = fitCell(cell, classifyString);
      case OptionKey.order:
        _order = fitCell(cell, classifyNumber);
      case OptionKey.stack:
        _stack = fitCell(cell, classifyString);
      case OptionKey.hidden:
        _hidden = fitCell(cell, classifyBool);
      case OptionKey.tooltip:
        _tooltip = fitCell(cell, classifyScope<TooltipDatasetOptionsScope>);
      case OptionKey.type:
        _type = fitCell(cell, classifyString);
      case OptionKey.data:
        _data = fitCell(cell, (raw) => classifyUnion(raw, 16));
      case OptionKey.xAxisID:
        _xAxisID = fitCell(cell, classifyString);
      case OptionKey.yAxisID:
        _yAxisID = fitCell(cell, classifyString);
      case OptionKey.rAxisID:
        _rAxisID = fitCell(cell, classifyString);
      case OptionKey.fill:
        _fill = fitCell(cell, (raw) => classifyUnion(raw, 39));
      case OptionKey.drawActiveElementsOnTop:
        _drawActiveElementsOnTop = fitCell(cell, classifyBool);
      case OptionKey.animation:
        _animation = fitCell(cell, (raw) => classifyUnion(raw, 34));
      case OptionKey.animations:
        _animations = fitCell(cell, (raw) => classifyUnion(raw, 34));
      case OptionKey.transitions:
        _transitions = fitCell(cell, classifyScope<TransitionsSpecScope>);
      case OptionKey.elements:
        _elements = fitCell(cell, classifyScope<ElementOptionsByTypeScope>);
      case OptionKey.datasetElementType:
        _datasetElementType = fitCell(cell, (raw) => classifyUnion(raw, 6));
      case OptionKey.dataElementType:
        _dataElementType = fitCell(cell, (raw) => classifyUnion(raw, 6));
      case OptionKey.descData:
        _descData = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.descDecimated:
        _descDecimated = fitCell(cell, (raw) => classifyUnion(raw, 64));
      default:
        throw ArgumentError.value(
          key,
          'key',
          'Not a key of GenericDatasetOptions',
        );
    }
  }

  @override
  bool hasField(OptionKey key) => switch (key) {
    OptionKey.parsing ||
    OptionKey.normalized ||
    OptionKey.indexAxis ||
    OptionKey.clip ||
    OptionKey.label ||
    OptionKey.order ||
    OptionKey.stack ||
    OptionKey.hidden ||
    OptionKey.tooltip ||
    OptionKey.type ||
    OptionKey.data ||
    OptionKey.xAxisID ||
    OptionKey.yAxisID ||
    OptionKey.rAxisID ||
    OptionKey.fill ||
    OptionKey.drawActiveElementsOnTop ||
    OptionKey.animation ||
    OptionKey.animations ||
    OptionKey.transitions ||
    OptionKey.elements ||
    OptionKey.datasetElementType ||
    OptionKey.dataElementType ||
    OptionKey.descData ||
    OptionKey.descDecimated => true,
    _ => false,
  };

  @override
  Opt<Object?> classify(OptionKey key, Object? raw) => switch (key) {
    OptionKey.parsing => classifyUnion(raw, 34),
    OptionKey.normalized => classifyBool(raw),
    OptionKey.indexAxis => classifyString(raw),
    OptionKey.clip => classifyUnion(raw, 35),
    OptionKey.label => classifyString(raw),
    OptionKey.order => classifyNumber(raw),
    OptionKey.stack => classifyString(raw),
    OptionKey.hidden => classifyBool(raw),
    OptionKey.tooltip => classifyScope<TooltipDatasetOptionsScope>(raw),
    OptionKey.type => classifyString(raw),
    OptionKey.data => classifyUnion(raw, 16),
    OptionKey.xAxisID => classifyString(raw),
    OptionKey.yAxisID => classifyString(raw),
    OptionKey.rAxisID => classifyString(raw),
    OptionKey.fill => classifyUnion(raw, 39),
    OptionKey.drawActiveElementsOnTop => classifyBool(raw),
    OptionKey.animation => classifyUnion(raw, 34),
    OptionKey.animations => classifyUnion(raw, 34),
    OptionKey.transitions => classifyScope<TransitionsSpecScope>(raw),
    OptionKey.elements => classifyScope<ElementOptionsByTypeScope>(raw),
    OptionKey.datasetElementType => classifyUnion(raw, 6),
    OptionKey.dataElementType => classifyUnion(raw, 6),
    OptionKey.descData => classifyUnion(raw, 64),
    OptionKey.descDecimated => classifyUnion(raw, 64),
    _ => kind.classifyOther(raw),
  };
}

/// index.d.ts:3829 ScaleOptions, the union of index.d.ts:1200 CoreScaleOptions,
/// :3257 CartesianScaleOptions, :3344 CategoryScaleOptions, :3356
/// LinearScaleOptions, :3405 LogarithmicScaleOptions, :3484 TimeScaleOptions
/// and :3563 RadialLinearScaleOptions, one scale and Chart.defaults.scale.
base class ScaleOptionsScope extends OptionScope {
  /// An empty scope.
  ScaleOptionsScope();

  @override
  ScopeKind get kind => ScopeKind.scaleOptions;

  Opt<Object>? _display;

  /// The cell of `display`, or Dart `null` when absent.
  Opt<Object>? get displayCell => _display;

  /// Stores the cell of `display`. Dart `null` deletes the key.
  set displayCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.display);
    } else {
      store(OptionKey.display, cell);
    }
  }

  /// Stores the plain value [value] of `display`.
  set display(Object value) =>
      store(OptionKey.display, classify(OptionKey.display, value));

  Opt<bool>? _alignToPixels;

  /// The cell of `alignToPixels`, or Dart `null` when absent.
  Opt<bool>? get alignToPixelsCell => _alignToPixels;

  /// Stores the cell of `alignToPixels`. Dart `null` deletes the key.
  set alignToPixelsCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.alignToPixels);
    } else {
      store(OptionKey.alignToPixels, cell);
    }
  }

  /// Stores the plain value [value] of `alignToPixels`.
  set alignToPixels(bool value) =>
      store(OptionKey.alignToPixels, OptValue<bool>(value));

  Opt<Object>? _backgroundColor;

  /// The cell of `backgroundColor`, or Dart `null` when absent.
  Opt<Object>? get backgroundColorCell => _backgroundColor;

  /// Stores the cell of `backgroundColor`. Dart `null` deletes the key.
  set backgroundColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.backgroundColor);
    } else {
      store(OptionKey.backgroundColor, cell);
    }
  }

  /// Stores the plain value [value] of `backgroundColor`.
  set backgroundColor(Object value) => store(
    OptionKey.backgroundColor,
    classify(OptionKey.backgroundColor, value),
  );

  Opt<bool>? _reverse;

  /// The cell of `reverse`, or Dart `null` when absent.
  Opt<bool>? get reverseCell => _reverse;

  /// Stores the cell of `reverse`. Dart `null` deletes the key.
  set reverseCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.reverse);
    } else {
      store(OptionKey.reverse, cell);
    }
  }

  /// Stores the plain value [value] of `reverse`.
  set reverse(bool value) => store(OptionKey.reverse, OptValue<bool>(value));

  Opt<bool>? _clip;

  /// The cell of `clip`, or Dart `null` when absent.
  Opt<bool>? get clipCell => _clip;

  /// Stores the cell of `clip`. Dart `null` deletes the key.
  set clipCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.clip);
    } else {
      store(OptionKey.clip, cell);
    }
  }

  /// Stores the plain value [value] of `clip`.
  set clip(bool value) => store(OptionKey.clip, OptValue<bool>(value));

  Opt<double>? _weight;

  /// The cell of `weight`, or Dart `null` when absent.
  Opt<double>? get weightCell => _weight;

  /// Stores the cell of `weight`. Dart `null` deletes the key.
  set weightCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.weight);
    } else {
      store(OptionKey.weight, cell);
    }
  }

  /// Stores the plain value [value] of `weight`.
  set weight(double value) => store(OptionKey.weight, OptValue<double>(value));

  Opt<Object>? _min;

  /// The cell of `min`, or Dart `null` when absent.
  Opt<Object>? get minCell => _min;

  /// Stores the cell of `min`. Dart `null` deletes the key.
  set minCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.min);
    } else {
      store(OptionKey.min, cell);
    }
  }

  /// Stores the plain value [value] of `min`.
  set min(Object value) => store(OptionKey.min, classify(OptionKey.min, value));

  Opt<Object>? _max;

  /// The cell of `max`, or Dart `null` when absent.
  Opt<Object>? get maxCell => _max;

  /// Stores the cell of `max`. Dart `null` deletes the key.
  set maxCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.max);
    } else {
      store(OptionKey.max, cell);
    }
  }

  /// Stores the plain value [value] of `max`.
  set max(Object value) => store(OptionKey.max, classify(OptionKey.max, value));

  Opt<Object>? _suggestedMin;

  /// The cell of `suggestedMin`, or Dart `null` when absent.
  Opt<Object>? get suggestedMinCell => _suggestedMin;

  /// Stores the cell of `suggestedMin`. Dart `null` deletes the key.
  set suggestedMinCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.suggestedMin);
    } else {
      store(OptionKey.suggestedMin, cell);
    }
  }

  /// Stores the plain value [value] of `suggestedMin`.
  set suggestedMin(Object value) =>
      store(OptionKey.suggestedMin, classify(OptionKey.suggestedMin, value));

  Opt<Object>? _suggestedMax;

  /// The cell of `suggestedMax`, or Dart `null` when absent.
  Opt<Object>? get suggestedMaxCell => _suggestedMax;

  /// Stores the cell of `suggestedMax`. Dart `null` deletes the key.
  set suggestedMaxCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.suggestedMax);
    } else {
      store(OptionKey.suggestedMax, cell);
    }
  }

  /// Stores the plain value [value] of `suggestedMax`.
  set suggestedMax(Object value) =>
      store(OptionKey.suggestedMax, classify(OptionKey.suggestedMax, value));

  Opt<Object>? _beforeUpdate;

  /// The cell of `beforeUpdate`, or Dart `null` when absent.
  Opt<Object>? get beforeUpdateCell => _beforeUpdate;

  /// Stores the cell of `beforeUpdate`. Dart `null` deletes the key.
  set beforeUpdateCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.beforeUpdate);
    } else {
      store(OptionKey.beforeUpdate, cell);
    }
  }

  /// Stores the plain value [value] of `beforeUpdate`.
  set beforeUpdate(Object value) =>
      store(OptionKey.beforeUpdate, classify(OptionKey.beforeUpdate, value));

  Opt<Object>? _beforeSetDimensions;

  /// The cell of `beforeSetDimensions`, or Dart `null` when absent.
  Opt<Object>? get beforeSetDimensionsCell => _beforeSetDimensions;

  /// Stores the cell of `beforeSetDimensions`. Dart `null` deletes the key.
  set beforeSetDimensionsCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.beforeSetDimensions);
    } else {
      store(OptionKey.beforeSetDimensions, cell);
    }
  }

  /// Stores the plain value [value] of `beforeSetDimensions`.
  set beforeSetDimensions(Object value) => store(
    OptionKey.beforeSetDimensions,
    classify(OptionKey.beforeSetDimensions, value),
  );

  Opt<Object>? _afterSetDimensions;

  /// The cell of `afterSetDimensions`, or Dart `null` when absent.
  Opt<Object>? get afterSetDimensionsCell => _afterSetDimensions;

  /// Stores the cell of `afterSetDimensions`. Dart `null` deletes the key.
  set afterSetDimensionsCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.afterSetDimensions);
    } else {
      store(OptionKey.afterSetDimensions, cell);
    }
  }

  /// Stores the plain value [value] of `afterSetDimensions`.
  set afterSetDimensions(Object value) => store(
    OptionKey.afterSetDimensions,
    classify(OptionKey.afterSetDimensions, value),
  );

  Opt<Object>? _beforeDataLimits;

  /// The cell of `beforeDataLimits`, or Dart `null` when absent.
  Opt<Object>? get beforeDataLimitsCell => _beforeDataLimits;

  /// Stores the cell of `beforeDataLimits`. Dart `null` deletes the key.
  set beforeDataLimitsCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.beforeDataLimits);
    } else {
      store(OptionKey.beforeDataLimits, cell);
    }
  }

  /// Stores the plain value [value] of `beforeDataLimits`.
  set beforeDataLimits(Object value) => store(
    OptionKey.beforeDataLimits,
    classify(OptionKey.beforeDataLimits, value),
  );

  Opt<Object>? _afterDataLimits;

  /// The cell of `afterDataLimits`, or Dart `null` when absent.
  Opt<Object>? get afterDataLimitsCell => _afterDataLimits;

  /// Stores the cell of `afterDataLimits`. Dart `null` deletes the key.
  set afterDataLimitsCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.afterDataLimits);
    } else {
      store(OptionKey.afterDataLimits, cell);
    }
  }

  /// Stores the plain value [value] of `afterDataLimits`.
  set afterDataLimits(Object value) => store(
    OptionKey.afterDataLimits,
    classify(OptionKey.afterDataLimits, value),
  );

  Opt<Object>? _beforeBuildTicks;

  /// The cell of `beforeBuildTicks`, or Dart `null` when absent.
  Opt<Object>? get beforeBuildTicksCell => _beforeBuildTicks;

  /// Stores the cell of `beforeBuildTicks`. Dart `null` deletes the key.
  set beforeBuildTicksCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.beforeBuildTicks);
    } else {
      store(OptionKey.beforeBuildTicks, cell);
    }
  }

  /// Stores the plain value [value] of `beforeBuildTicks`.
  set beforeBuildTicks(Object value) => store(
    OptionKey.beforeBuildTicks,
    classify(OptionKey.beforeBuildTicks, value),
  );

  Opt<Object>? _afterBuildTicks;

  /// The cell of `afterBuildTicks`, or Dart `null` when absent.
  Opt<Object>? get afterBuildTicksCell => _afterBuildTicks;

  /// Stores the cell of `afterBuildTicks`. Dart `null` deletes the key.
  set afterBuildTicksCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.afterBuildTicks);
    } else {
      store(OptionKey.afterBuildTicks, cell);
    }
  }

  /// Stores the plain value [value] of `afterBuildTicks`.
  set afterBuildTicks(Object value) => store(
    OptionKey.afterBuildTicks,
    classify(OptionKey.afterBuildTicks, value),
  );

  Opt<Object>? _beforeTickToLabelConversion;

  /// The cell of `beforeTickToLabelConversion`, or Dart `null` when absent.
  Opt<Object>? get beforeTickToLabelConversionCell =>
      _beforeTickToLabelConversion;

  /// Stores the cell of `beforeTickToLabelConversion`. Dart `null` deletes the key.
  set beforeTickToLabelConversionCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.beforeTickToLabelConversion);
    } else {
      store(OptionKey.beforeTickToLabelConversion, cell);
    }
  }

  /// Stores the plain value [value] of `beforeTickToLabelConversion`.
  set beforeTickToLabelConversion(Object value) => store(
    OptionKey.beforeTickToLabelConversion,
    classify(OptionKey.beforeTickToLabelConversion, value),
  );

  Opt<Object>? _afterTickToLabelConversion;

  /// The cell of `afterTickToLabelConversion`, or Dart `null` when absent.
  Opt<Object>? get afterTickToLabelConversionCell =>
      _afterTickToLabelConversion;

  /// Stores the cell of `afterTickToLabelConversion`. Dart `null` deletes the key.
  set afterTickToLabelConversionCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.afterTickToLabelConversion);
    } else {
      store(OptionKey.afterTickToLabelConversion, cell);
    }
  }

  /// Stores the plain value [value] of `afterTickToLabelConversion`.
  set afterTickToLabelConversion(Object value) => store(
    OptionKey.afterTickToLabelConversion,
    classify(OptionKey.afterTickToLabelConversion, value),
  );

  Opt<Object>? _beforeCalculateLabelRotation;

  /// The cell of `beforeCalculateLabelRotation`, or Dart `null` when absent.
  Opt<Object>? get beforeCalculateLabelRotationCell =>
      _beforeCalculateLabelRotation;

  /// Stores the cell of `beforeCalculateLabelRotation`. Dart `null` deletes the key.
  set beforeCalculateLabelRotationCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.beforeCalculateLabelRotation);
    } else {
      store(OptionKey.beforeCalculateLabelRotation, cell);
    }
  }

  /// Stores the plain value [value] of `beforeCalculateLabelRotation`.
  set beforeCalculateLabelRotation(Object value) => store(
    OptionKey.beforeCalculateLabelRotation,
    classify(OptionKey.beforeCalculateLabelRotation, value),
  );

  Opt<Object>? _afterCalculateLabelRotation;

  /// The cell of `afterCalculateLabelRotation`, or Dart `null` when absent.
  Opt<Object>? get afterCalculateLabelRotationCell =>
      _afterCalculateLabelRotation;

  /// Stores the cell of `afterCalculateLabelRotation`. Dart `null` deletes the key.
  set afterCalculateLabelRotationCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.afterCalculateLabelRotation);
    } else {
      store(OptionKey.afterCalculateLabelRotation, cell);
    }
  }

  /// Stores the plain value [value] of `afterCalculateLabelRotation`.
  set afterCalculateLabelRotation(Object value) => store(
    OptionKey.afterCalculateLabelRotation,
    classify(OptionKey.afterCalculateLabelRotation, value),
  );

  Opt<Object>? _beforeFit;

  /// The cell of `beforeFit`, or Dart `null` when absent.
  Opt<Object>? get beforeFitCell => _beforeFit;

  /// Stores the cell of `beforeFit`. Dart `null` deletes the key.
  set beforeFitCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.beforeFit);
    } else {
      store(OptionKey.beforeFit, cell);
    }
  }

  /// Stores the plain value [value] of `beforeFit`.
  set beforeFit(Object value) =>
      store(OptionKey.beforeFit, classify(OptionKey.beforeFit, value));

  Opt<Object>? _afterFit;

  /// The cell of `afterFit`, or Dart `null` when absent.
  Opt<Object>? get afterFitCell => _afterFit;

  /// Stores the cell of `afterFit`. Dart `null` deletes the key.
  set afterFitCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.afterFit);
    } else {
      store(OptionKey.afterFit, cell);
    }
  }

  /// Stores the plain value [value] of `afterFit`.
  set afterFit(Object value) =>
      store(OptionKey.afterFit, classify(OptionKey.afterFit, value));

  Opt<Object>? _afterUpdate;

  /// The cell of `afterUpdate`, or Dart `null` when absent.
  Opt<Object>? get afterUpdateCell => _afterUpdate;

  /// Stores the cell of `afterUpdate`. Dart `null` deletes the key.
  set afterUpdateCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.afterUpdate);
    } else {
      store(OptionKey.afterUpdate, cell);
    }
  }

  /// Stores the plain value [value] of `afterUpdate`.
  set afterUpdate(Object value) =>
      store(OptionKey.afterUpdate, classify(OptionKey.afterUpdate, value));

  Opt<String>? _bounds;

  /// The cell of `bounds`, or Dart `null` when absent.
  Opt<String>? get boundsCell => _bounds;

  /// Stores the cell of `bounds`. Dart `null` deletes the key.
  set boundsCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.bounds);
    } else {
      store(OptionKey.bounds, cell);
    }
  }

  /// Stores the plain value [value] of `bounds`.
  set bounds(String value) => store(OptionKey.bounds, OptValue<String>(value));

  Opt<Object>? _position;

  /// The cell of `position`, or Dart `null` when absent.
  Opt<Object>? get positionCell => _position;

  /// Stores the cell of `position`. Dart `null` deletes the key.
  set positionCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.position);
    } else {
      store(OptionKey.position, cell);
    }
  }

  /// Stores the plain value [value] of `position`.
  set position(Object value) =>
      store(OptionKey.position, classify(OptionKey.position, value));

  Opt<String>? _stack;

  /// The cell of `stack`, or Dart `null` when absent.
  Opt<String>? get stackCell => _stack;

  /// Stores the cell of `stack`. Dart `null` deletes the key.
  set stackCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.stack);
    } else {
      store(OptionKey.stack, cell);
    }
  }

  /// Stores the plain value [value] of `stack`.
  set stack(String value) => store(OptionKey.stack, OptValue<String>(value));

  Opt<double>? _stackWeight;

  /// The cell of `stackWeight`, or Dart `null` when absent.
  Opt<double>? get stackWeightCell => _stackWeight;

  /// Stores the cell of `stackWeight`. Dart `null` deletes the key.
  set stackWeightCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.stackWeight);
    } else {
      store(OptionKey.stackWeight, cell);
    }
  }

  /// Stores the plain value [value] of `stackWeight`.
  set stackWeight(double value) =>
      store(OptionKey.stackWeight, OptValue<double>(value));

  Opt<String>? _axis;

  /// The cell of `axis`, or Dart `null` when absent.
  Opt<String>? get axisCell => _axis;

  /// Stores the cell of `axis`. Dart `null` deletes the key.
  set axisCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.axis);
    } else {
      store(OptionKey.axis, cell);
    }
  }

  /// Stores the plain value [value] of `axis`.
  set axis(String value) => store(OptionKey.axis, OptValue<String>(value));

  Opt<bool>? _offset;

  /// The cell of `offset`, or Dart `null` when absent.
  Opt<bool>? get offsetCell => _offset;

  /// Stores the cell of `offset`. Dart `null` deletes the key.
  set offsetCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.offset);
    } else {
      store(OptionKey.offset, cell);
    }
  }

  /// Stores the plain value [value] of `offset`.
  set offset(bool value) => store(OptionKey.offset, OptValue<bool>(value));

  Opt<GridLineOptionsScope>? _grid;

  /// The cell of `grid`, or Dart `null` when absent.
  Opt<GridLineOptionsScope>? get gridCell => _grid;

  /// Stores the cell of `grid`. Dart `null` deletes the key.
  set gridCell(Opt<GridLineOptionsScope>? cell) {
    if (cell == null) {
      delete(OptionKey.grid);
    } else {
      store(OptionKey.grid, cell);
    }
  }

  /// Stores the plain value [value] of `grid`.
  set grid(GridLineOptionsScope value) =>
      store(OptionKey.grid, OptScope<GridLineOptionsScope>(value));

  Opt<BorderOptionsScope>? _border;

  /// The cell of `border`, or Dart `null` when absent.
  Opt<BorderOptionsScope>? get borderCell => _border;

  /// Stores the cell of `border`. Dart `null` deletes the key.
  set borderCell(Opt<BorderOptionsScope>? cell) {
    if (cell == null) {
      delete(OptionKey.border);
    } else {
      store(OptionKey.border, cell);
    }
  }

  /// Stores the plain value [value] of `border`.
  set border(BorderOptionsScope value) =>
      store(OptionKey.border, OptScope<BorderOptionsScope>(value));

  Opt<ScaleTitleOptionsScope>? _title;

  /// The cell of `title`, or Dart `null` when absent.
  Opt<ScaleTitleOptionsScope>? get titleCell => _title;

  /// Stores the cell of `title`. Dart `null` deletes the key.
  set titleCell(Opt<ScaleTitleOptionsScope>? cell) {
    if (cell == null) {
      delete(OptionKey.title);
    } else {
      store(OptionKey.title, cell);
    }
  }

  /// Stores the plain value [value] of `title`.
  set title(ScaleTitleOptionsScope value) =>
      store(OptionKey.title, OptScope<ScaleTitleOptionsScope>(value));

  Opt<Object>? _stacked;

  /// The cell of `stacked`, or Dart `null` when absent.
  Opt<Object>? get stackedCell => _stacked;

  /// Stores the cell of `stacked`. Dart `null` deletes the key.
  set stackedCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.stacked);
    } else {
      store(OptionKey.stacked, cell);
    }
  }

  /// Stores the plain value [value] of `stacked`.
  set stacked(Object value) =>
      store(OptionKey.stacked, classify(OptionKey.stacked, value));

  Opt<TickOptionsScope>? _ticks;

  /// The cell of `ticks`, or Dart `null` when absent.
  Opt<TickOptionsScope>? get ticksCell => _ticks;

  /// Stores the cell of `ticks`. Dart `null` deletes the key.
  set ticksCell(Opt<TickOptionsScope>? cell) {
    if (cell == null) {
      delete(OptionKey.ticks);
    } else {
      store(OptionKey.ticks, cell);
    }
  }

  /// Stores the plain value [value] of `ticks`.
  set ticks(TickOptionsScope value) =>
      store(OptionKey.ticks, OptScope<TickOptionsScope>(value));

  Opt<Object>? _labels;

  /// The cell of `labels`, or Dart `null` when absent.
  Opt<Object>? get labelsCell => _labels;

  /// Stores the cell of `labels`. Dart `null` deletes the key.
  set labelsCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.labels);
    } else {
      store(OptionKey.labels, cell);
    }
  }

  /// Stores the plain value [value] of `labels`.
  set labels(Object value) =>
      store(OptionKey.labels, classify(OptionKey.labels, value));

  Opt<bool>? _beginAtZero;

  /// The cell of `beginAtZero`, or Dart `null` when absent.
  Opt<bool>? get beginAtZeroCell => _beginAtZero;

  /// Stores the cell of `beginAtZero`. Dart `null` deletes the key.
  set beginAtZeroCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.beginAtZero);
    } else {
      store(OptionKey.beginAtZero, cell);
    }
  }

  /// Stores the plain value [value] of `beginAtZero`.
  set beginAtZero(bool value) =>
      store(OptionKey.beginAtZero, OptValue<bool>(value));

  Opt<Object>? _grace;

  /// The cell of `grace`, or Dart `null` when absent.
  Opt<Object>? get graceCell => _grace;

  /// Stores the cell of `grace`. Dart `null` deletes the key.
  set graceCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.grace);
    } else {
      store(OptionKey.grace, cell);
    }
  }

  /// Stores the plain value [value] of `grace`.
  set grace(Object value) =>
      store(OptionKey.grace, classify(OptionKey.grace, value));

  Opt<bool>? _offsetAfterAutoskip;

  /// The cell of `offsetAfterAutoskip`, or Dart `null` when absent.
  Opt<bool>? get offsetAfterAutoskipCell => _offsetAfterAutoskip;

  /// Stores the cell of `offsetAfterAutoskip`. Dart `null` deletes the key.
  set offsetAfterAutoskipCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.offsetAfterAutoskip);
    } else {
      store(OptionKey.offsetAfterAutoskip, cell);
    }
  }

  /// Stores the plain value [value] of `offsetAfterAutoskip`.
  set offsetAfterAutoskip(bool value) =>
      store(OptionKey.offsetAfterAutoskip, OptValue<bool>(value));

  Opt<Object>? _adapters;

  /// The cell of `adapters`, or Dart `null` when absent.
  Opt<Object>? get adaptersCell => _adapters;

  /// Stores the cell of `adapters`. Dart `null` deletes the key.
  set adaptersCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.adapters);
    } else {
      store(OptionKey.adapters, cell);
    }
  }

  /// Stores the plain value [value] of `adapters`.
  set adapters(Object value) =>
      store(OptionKey.adapters, classify(OptionKey.adapters, value));

  Opt<TimeScaleTimeOptionsScope>? _time;

  /// The cell of `time`, or Dart `null` when absent.
  Opt<TimeScaleTimeOptionsScope>? get timeCell => _time;

  /// Stores the cell of `time`. Dart `null` deletes the key.
  set timeCell(Opt<TimeScaleTimeOptionsScope>? cell) {
    if (cell == null) {
      delete(OptionKey.time);
    } else {
      store(OptionKey.time, cell);
    }
  }

  /// Stores the plain value [value] of `time`.
  set time(TimeScaleTimeOptionsScope value) =>
      store(OptionKey.time, OptScope<TimeScaleTimeOptionsScope>(value));

  Opt<bool>? _animate;

  /// The cell of `animate`, or Dart `null` when absent.
  Opt<bool>? get animateCell => _animate;

  /// Stores the cell of `animate`. Dart `null` deletes the key.
  set animateCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.animate);
    } else {
      store(OptionKey.animate, cell);
    }
  }

  /// Stores the plain value [value] of `animate`.
  set animate(bool value) => store(OptionKey.animate, OptValue<bool>(value));

  Opt<double>? _startAngle;

  /// The cell of `startAngle`, or Dart `null` when absent.
  Opt<double>? get startAngleCell => _startAngle;

  /// Stores the cell of `startAngle`. Dart `null` deletes the key.
  set startAngleCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.startAngle);
    } else {
      store(OptionKey.startAngle, cell);
    }
  }

  /// Stores the plain value [value] of `startAngle`.
  set startAngle(double value) =>
      store(OptionKey.startAngle, OptValue<double>(value));

  Opt<AngleLineOptionsScope>? _angleLines;

  /// The cell of `angleLines`, or Dart `null` when absent.
  Opt<AngleLineOptionsScope>? get angleLinesCell => _angleLines;

  /// Stores the cell of `angleLines`. Dart `null` deletes the key.
  set angleLinesCell(Opt<AngleLineOptionsScope>? cell) {
    if (cell == null) {
      delete(OptionKey.angleLines);
    } else {
      store(OptionKey.angleLines, cell);
    }
  }

  /// Stores the plain value [value] of `angleLines`.
  set angleLines(AngleLineOptionsScope value) =>
      store(OptionKey.angleLines, OptScope<AngleLineOptionsScope>(value));

  Opt<PointLabelOptionsScope>? _pointLabels;

  /// The cell of `pointLabels`, or Dart `null` when absent.
  Opt<PointLabelOptionsScope>? get pointLabelsCell => _pointLabels;

  /// Stores the cell of `pointLabels`. Dart `null` deletes the key.
  set pointLabelsCell(Opt<PointLabelOptionsScope>? cell) {
    if (cell == null) {
      delete(OptionKey.pointLabels);
    } else {
      store(OptionKey.pointLabels, cell);
    }
  }

  /// Stores the plain value [value] of `pointLabels`.
  set pointLabels(PointLabelOptionsScope value) =>
      store(OptionKey.pointLabels, OptScope<PointLabelOptionsScope>(value));

  Opt<String>? _type;

  /// The cell of `type`, or Dart `null` when absent.
  Opt<String>? get typeCell => _type;

  /// Stores the cell of `type`. Dart `null` deletes the key.
  set typeCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.type);
    } else {
      store(OptionKey.type, cell);
    }
  }

  /// Stores the plain value [value] of `type`.
  set type(String value) => store(OptionKey.type, OptValue<String>(value));

  Opt<String>? _id;

  /// The cell of `id`, or Dart `null` when absent.
  Opt<String>? get idCell => _id;

  /// Stores the cell of `id`. Dart `null` deletes the key.
  set idCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.id);
    } else {
      store(OptionKey.id, cell);
    }
  }

  /// Stores the plain value [value] of `id`.
  set id(String value) => store(OptionKey.id, OptValue<String>(value));

  Opt<bool>? _fullSize;

  /// The cell of `fullSize`, or Dart `null` when absent.
  Opt<bool>? get fullSizeCell => _fullSize;

  /// Stores the cell of `fullSize`. Dart `null` deletes the key.
  set fullSizeCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.fullSize);
    } else {
      store(OptionKey.fullSize, cell);
    }
  }

  /// Stores the plain value [value] of `fullSize`.
  set fullSize(bool value) => store(OptionKey.fullSize, OptValue<bool>(value));

  @override
  Opt<Object?>? cellOf(OptionKey key) => switch (key) {
    OptionKey.display => _display,
    OptionKey.alignToPixels => _alignToPixels,
    OptionKey.backgroundColor => _backgroundColor,
    OptionKey.reverse => _reverse,
    OptionKey.clip => _clip,
    OptionKey.weight => _weight,
    OptionKey.min => _min,
    OptionKey.max => _max,
    OptionKey.suggestedMin => _suggestedMin,
    OptionKey.suggestedMax => _suggestedMax,
    OptionKey.beforeUpdate => _beforeUpdate,
    OptionKey.beforeSetDimensions => _beforeSetDimensions,
    OptionKey.afterSetDimensions => _afterSetDimensions,
    OptionKey.beforeDataLimits => _beforeDataLimits,
    OptionKey.afterDataLimits => _afterDataLimits,
    OptionKey.beforeBuildTicks => _beforeBuildTicks,
    OptionKey.afterBuildTicks => _afterBuildTicks,
    OptionKey.beforeTickToLabelConversion => _beforeTickToLabelConversion,
    OptionKey.afterTickToLabelConversion => _afterTickToLabelConversion,
    OptionKey.beforeCalculateLabelRotation => _beforeCalculateLabelRotation,
    OptionKey.afterCalculateLabelRotation => _afterCalculateLabelRotation,
    OptionKey.beforeFit => _beforeFit,
    OptionKey.afterFit => _afterFit,
    OptionKey.afterUpdate => _afterUpdate,
    OptionKey.bounds => _bounds,
    OptionKey.position => _position,
    OptionKey.stack => _stack,
    OptionKey.stackWeight => _stackWeight,
    OptionKey.axis => _axis,
    OptionKey.offset => _offset,
    OptionKey.grid => _grid,
    OptionKey.border => _border,
    OptionKey.title => _title,
    OptionKey.stacked => _stacked,
    OptionKey.ticks => _ticks,
    OptionKey.labels => _labels,
    OptionKey.beginAtZero => _beginAtZero,
    OptionKey.grace => _grace,
    OptionKey.offsetAfterAutoskip => _offsetAfterAutoskip,
    OptionKey.adapters => _adapters,
    OptionKey.time => _time,
    OptionKey.animate => _animate,
    OptionKey.startAngle => _startAngle,
    OptionKey.angleLines => _angleLines,
    OptionKey.pointLabels => _pointLabels,
    OptionKey.type => _type,
    OptionKey.id => _id,
    OptionKey.fullSize => _fullSize,
    _ => null,
  };

  @override
  void setCell(OptionKey key, Opt<Object?>? cell) {
    switch (key) {
      case OptionKey.display:
        _display = fitCell(cell, (raw) => classifyUnion(raw, 6));
      case OptionKey.alignToPixels:
        _alignToPixels = fitCell(cell, classifyBool);
      case OptionKey.backgroundColor:
        _backgroundColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.reverse:
        _reverse = fitCell(cell, classifyBool);
      case OptionKey.clip:
        _clip = fitCell(cell, classifyBool);
      case OptionKey.weight:
        _weight = fitCell(cell, classifyNumber);
      case OptionKey.min:
        _min = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.max:
        _max = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.suggestedMin:
        _suggestedMin = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.suggestedMax:
        _suggestedMax = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.beforeUpdate:
        _beforeUpdate = fitCell(cell, (raw) => classifyUnion(raw, 8));
      case OptionKey.beforeSetDimensions:
        _beforeSetDimensions = fitCell(cell, (raw) => classifyUnion(raw, 8));
      case OptionKey.afterSetDimensions:
        _afterSetDimensions = fitCell(cell, (raw) => classifyUnion(raw, 8));
      case OptionKey.beforeDataLimits:
        _beforeDataLimits = fitCell(cell, (raw) => classifyUnion(raw, 8));
      case OptionKey.afterDataLimits:
        _afterDataLimits = fitCell(cell, (raw) => classifyUnion(raw, 8));
      case OptionKey.beforeBuildTicks:
        _beforeBuildTicks = fitCell(cell, (raw) => classifyUnion(raw, 8));
      case OptionKey.afterBuildTicks:
        _afterBuildTicks = fitCell(cell, (raw) => classifyUnion(raw, 8));
      case OptionKey.beforeTickToLabelConversion:
        _beforeTickToLabelConversion = fitCell(
          cell,
          (raw) => classifyUnion(raw, 8),
        );
      case OptionKey.afterTickToLabelConversion:
        _afterTickToLabelConversion = fitCell(
          cell,
          (raw) => classifyUnion(raw, 8),
        );
      case OptionKey.beforeCalculateLabelRotation:
        _beforeCalculateLabelRotation = fitCell(
          cell,
          (raw) => classifyUnion(raw, 8),
        );
      case OptionKey.afterCalculateLabelRotation:
        _afterCalculateLabelRotation = fitCell(
          cell,
          (raw) => classifyUnion(raw, 8),
        );
      case OptionKey.beforeFit:
        _beforeFit = fitCell(cell, (raw) => classifyUnion(raw, 8));
      case OptionKey.afterFit:
        _afterFit = fitCell(cell, (raw) => classifyUnion(raw, 8));
      case OptionKey.afterUpdate:
        _afterUpdate = fitCell(cell, (raw) => classifyUnion(raw, 8));
      case OptionKey.bounds:
        _bounds = fitCell(cell, classifyString);
      case OptionKey.position:
        _position = fitCell(cell, (raw) => classifyUnion(raw, 36));
      case OptionKey.stack:
        _stack = fitCell(cell, classifyString);
      case OptionKey.stackWeight:
        _stackWeight = fitCell(cell, classifyNumber);
      case OptionKey.axis:
        _axis = fitCell(cell, classifyString);
      case OptionKey.offset:
        _offset = fitCell(cell, classifyBool);
      case OptionKey.grid:
        _grid = fitCell(cell, classifyScope<GridLineOptionsScope>);
      case OptionKey.border:
        _border = fitCell(cell, classifyScope<BorderOptionsScope>);
      case OptionKey.title:
        _title = fitCell(cell, classifyScope<ScaleTitleOptionsScope>);
      case OptionKey.stacked:
        _stacked = fitCell(cell, (raw) => classifyUnion(raw, 6));
      case OptionKey.ticks:
        _ticks = fitCell(cell, classifyScope<TickOptionsScope>);
      case OptionKey.labels:
        _labels = fitCell(cell, (raw) => classifyUnion(raw, 16));
      case OptionKey.beginAtZero:
        _beginAtZero = fitCell(cell, classifyBool);
      case OptionKey.grace:
        _grace = fitCell(cell, (raw) => classifyUnion(raw, 5));
      case OptionKey.offsetAfterAutoskip:
        _offsetAfterAutoskip = fitCell(cell, classifyBool);
      case OptionKey.adapters:
        _adapters = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.time:
        _time = fitCell(cell, classifyScope<TimeScaleTimeOptionsScope>);
      case OptionKey.animate:
        _animate = fitCell(cell, classifyBool);
      case OptionKey.startAngle:
        _startAngle = fitCell(cell, classifyNumber);
      case OptionKey.angleLines:
        _angleLines = fitCell(cell, classifyScope<AngleLineOptionsScope>);
      case OptionKey.pointLabels:
        _pointLabels = fitCell(cell, classifyScope<PointLabelOptionsScope>);
      case OptionKey.type:
        _type = fitCell(cell, classifyString);
      case OptionKey.id:
        _id = fitCell(cell, classifyString);
      case OptionKey.fullSize:
        _fullSize = fitCell(cell, classifyBool);
      default:
        throw ArgumentError.value(key, 'key', 'Not a key of ScaleOptions');
    }
  }

  @override
  bool hasField(OptionKey key) => switch (key) {
    OptionKey.display ||
    OptionKey.alignToPixels ||
    OptionKey.backgroundColor ||
    OptionKey.reverse ||
    OptionKey.clip ||
    OptionKey.weight ||
    OptionKey.min ||
    OptionKey.max ||
    OptionKey.suggestedMin ||
    OptionKey.suggestedMax ||
    OptionKey.beforeUpdate ||
    OptionKey.beforeSetDimensions ||
    OptionKey.afterSetDimensions ||
    OptionKey.beforeDataLimits ||
    OptionKey.afterDataLimits ||
    OptionKey.beforeBuildTicks ||
    OptionKey.afterBuildTicks ||
    OptionKey.beforeTickToLabelConversion ||
    OptionKey.afterTickToLabelConversion ||
    OptionKey.beforeCalculateLabelRotation ||
    OptionKey.afterCalculateLabelRotation ||
    OptionKey.beforeFit ||
    OptionKey.afterFit ||
    OptionKey.afterUpdate ||
    OptionKey.bounds ||
    OptionKey.position ||
    OptionKey.stack ||
    OptionKey.stackWeight ||
    OptionKey.axis ||
    OptionKey.offset ||
    OptionKey.grid ||
    OptionKey.border ||
    OptionKey.title ||
    OptionKey.stacked ||
    OptionKey.ticks ||
    OptionKey.labels ||
    OptionKey.beginAtZero ||
    OptionKey.grace ||
    OptionKey.offsetAfterAutoskip ||
    OptionKey.adapters ||
    OptionKey.time ||
    OptionKey.animate ||
    OptionKey.startAngle ||
    OptionKey.angleLines ||
    OptionKey.pointLabels ||
    OptionKey.type ||
    OptionKey.id ||
    OptionKey.fullSize => true,
    _ => false,
  };

  @override
  Opt<Object?> classify(OptionKey key, Object? raw) => switch (key) {
    OptionKey.display => classifyUnion(raw, 6),
    OptionKey.alignToPixels => classifyBool(raw),
    OptionKey.backgroundColor => classifyUnion(raw, 64),
    OptionKey.reverse => classifyBool(raw),
    OptionKey.clip => classifyBool(raw),
    OptionKey.weight => classifyNumber(raw),
    OptionKey.min => classifyUnion(raw, 64),
    OptionKey.max => classifyUnion(raw, 64),
    OptionKey.suggestedMin => classifyUnion(raw, 64),
    OptionKey.suggestedMax => classifyUnion(raw, 64),
    OptionKey.beforeUpdate => classifyUnion(raw, 8),
    OptionKey.beforeSetDimensions => classifyUnion(raw, 8),
    OptionKey.afterSetDimensions => classifyUnion(raw, 8),
    OptionKey.beforeDataLimits => classifyUnion(raw, 8),
    OptionKey.afterDataLimits => classifyUnion(raw, 8),
    OptionKey.beforeBuildTicks => classifyUnion(raw, 8),
    OptionKey.afterBuildTicks => classifyUnion(raw, 8),
    OptionKey.beforeTickToLabelConversion => classifyUnion(raw, 8),
    OptionKey.afterTickToLabelConversion => classifyUnion(raw, 8),
    OptionKey.beforeCalculateLabelRotation => classifyUnion(raw, 8),
    OptionKey.afterCalculateLabelRotation => classifyUnion(raw, 8),
    OptionKey.beforeFit => classifyUnion(raw, 8),
    OptionKey.afterFit => classifyUnion(raw, 8),
    OptionKey.afterUpdate => classifyUnion(raw, 8),
    OptionKey.bounds => classifyString(raw),
    OptionKey.position => classifyUnion(raw, 36),
    OptionKey.stack => classifyString(raw),
    OptionKey.stackWeight => classifyNumber(raw),
    OptionKey.axis => classifyString(raw),
    OptionKey.offset => classifyBool(raw),
    OptionKey.grid => classifyScope<GridLineOptionsScope>(raw),
    OptionKey.border => classifyScope<BorderOptionsScope>(raw),
    OptionKey.title => classifyScope<ScaleTitleOptionsScope>(raw),
    OptionKey.stacked => classifyUnion(raw, 6),
    OptionKey.ticks => classifyScope<TickOptionsScope>(raw),
    OptionKey.labels => classifyUnion(raw, 16),
    OptionKey.beginAtZero => classifyBool(raw),
    OptionKey.grace => classifyUnion(raw, 5),
    OptionKey.offsetAfterAutoskip => classifyBool(raw),
    OptionKey.adapters => classifyUnion(raw, 64),
    OptionKey.time => classifyScope<TimeScaleTimeOptionsScope>(raw),
    OptionKey.animate => classifyBool(raw),
    OptionKey.startAngle => classifyNumber(raw),
    OptionKey.angleLines => classifyScope<AngleLineOptionsScope>(raw),
    OptionKey.pointLabels => classifyScope<PointLabelOptionsScope>(raw),
    OptionKey.type => classifyString(raw),
    OptionKey.id => classifyString(raw),
    OptionKey.fullSize => classifyBool(raw),
    _ => kind.classifyOther(raw),
  };
}

/// Port-only kind for the object form of index.d.ts:3270 CartesianScaleOptions
/// `position` (layout.d.ts LayoutPosition), the value on the scale of each id.
base class ScalePositionScope extends OptionScope {
  /// An empty scope.
  ScalePositionScope();

  @override
  ScopeKind get kind => ScopeKind.scalePosition;

  @override
  Opt<Object?>? cellOf(OptionKey key) => null;

  @override
  void setCell(OptionKey key, Opt<Object?>? cell) {
    throw ArgumentError.value(key, 'key', 'Not a key of ScalePosition');
  }

  @override
  bool hasField(OptionKey key) => false;

  @override
  Opt<Object?> classify(OptionKey key, Object? raw) => kind.classifyOther(raw);
}

/// The union of index.d.ts:3115 TickOptions, :3179 CartesianTickOptions, the
/// linear ticks of :3376, the logarithmic ticks of :3415, :3466
/// TimeScaleTickOptions and :3535 RadialTickOptions, the scope `ticks` of a
/// scale.
base class TickOptionsScope extends OptionScope {
  /// An empty scope.
  TickOptionsScope();

  @override
  ScopeKind get kind => ScopeKind.tickOptions;

  Opt<Object>? _backdropColor;

  /// The cell of `backdropColor`, or Dart `null` when absent.
  Opt<Object>? get backdropColorCell => _backdropColor;

  /// Stores the cell of `backdropColor`. Dart `null` deletes the key.
  set backdropColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.backdropColor);
    } else {
      store(OptionKey.backdropColor, cell);
    }
  }

  /// Stores the plain value [value] of `backdropColor`.
  set backdropColor(Object value) =>
      store(OptionKey.backdropColor, classify(OptionKey.backdropColor, value));

  Opt<Object>? _backdropPadding;

  /// The cell of `backdropPadding`, or Dart `null` when absent.
  Opt<Object>? get backdropPaddingCell => _backdropPadding;

  /// Stores the cell of `backdropPadding`. Dart `null` deletes the key.
  set backdropPaddingCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.backdropPadding);
    } else {
      store(OptionKey.backdropPadding, cell);
    }
  }

  /// Stores the plain value [value] of `backdropPadding`.
  set backdropPadding(Object value) => store(
    OptionKey.backdropPadding,
    classify(OptionKey.backdropPadding, value),
  );

  Opt<Object>? _callback;

  /// The cell of `callback`, or Dart `null` when absent.
  Opt<Object>? get callbackCell => _callback;

  /// Stores the cell of `callback`. Dart `null` deletes the key.
  set callbackCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.callback);
    } else {
      store(OptionKey.callback, cell);
    }
  }

  /// Stores the plain value [value] of `callback`.
  set callback(Object value) =>
      store(OptionKey.callback, classify(OptionKey.callback, value));

  Opt<bool>? _display;

  /// The cell of `display`, or Dart `null` when absent.
  Opt<bool>? get displayCell => _display;

  /// Stores the cell of `display`. Dart `null` deletes the key.
  set displayCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.display);
    } else {
      store(OptionKey.display, cell);
    }
  }

  /// Stores the plain value [value] of `display`.
  set display(bool value) => store(OptionKey.display, OptValue<bool>(value));

  Opt<Object>? _color;

  /// The cell of `color`, or Dart `null` when absent.
  Opt<Object>? get colorCell => _color;

  /// Stores the cell of `color`. Dart `null` deletes the key.
  set colorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.color);
    } else {
      store(OptionKey.color, cell);
    }
  }

  /// Stores the plain value [value] of `color`.
  set color(Object value) =>
      store(OptionKey.color, classify(OptionKey.color, value));

  Opt<FontSpecScope>? _font;

  /// The cell of `font`, or Dart `null` when absent.
  Opt<FontSpecScope>? get fontCell => _font;

  /// Stores the cell of `font`. Dart `null` deletes the key.
  set fontCell(Opt<FontSpecScope>? cell) {
    if (cell == null) {
      delete(OptionKey.font);
    } else {
      store(OptionKey.font, cell);
    }
  }

  /// Stores the plain value [value] of `font`.
  set font(FontSpecScope value) =>
      store(OptionKey.font, OptScope<FontSpecScope>(value));

  Opt<double>? _padding;

  /// The cell of `padding`, or Dart `null` when absent.
  Opt<double>? get paddingCell => _padding;

  /// Stores the cell of `padding`. Dart `null` deletes the key.
  set paddingCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.padding);
    } else {
      store(OptionKey.padding, cell);
    }
  }

  /// Stores the plain value [value] of `padding`.
  set padding(double value) =>
      store(OptionKey.padding, OptValue<double>(value));

  Opt<bool>? _showLabelBackdrop;

  /// The cell of `showLabelBackdrop`, or Dart `null` when absent.
  Opt<bool>? get showLabelBackdropCell => _showLabelBackdrop;

  /// Stores the cell of `showLabelBackdrop`. Dart `null` deletes the key.
  set showLabelBackdropCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.showLabelBackdrop);
    } else {
      store(OptionKey.showLabelBackdrop, cell);
    }
  }

  /// Stores the plain value [value] of `showLabelBackdrop`.
  set showLabelBackdrop(bool value) =>
      store(OptionKey.showLabelBackdrop, OptValue<bool>(value));

  Opt<Object>? _textStrokeColor;

  /// The cell of `textStrokeColor`, or Dart `null` when absent.
  Opt<Object>? get textStrokeColorCell => _textStrokeColor;

  /// Stores the cell of `textStrokeColor`. Dart `null` deletes the key.
  set textStrokeColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.textStrokeColor);
    } else {
      store(OptionKey.textStrokeColor, cell);
    }
  }

  /// Stores the plain value [value] of `textStrokeColor`.
  set textStrokeColor(Object value) => store(
    OptionKey.textStrokeColor,
    classify(OptionKey.textStrokeColor, value),
  );

  Opt<double>? _textStrokeWidth;

  /// The cell of `textStrokeWidth`, or Dart `null` when absent.
  Opt<double>? get textStrokeWidthCell => _textStrokeWidth;

  /// Stores the cell of `textStrokeWidth`. Dart `null` deletes the key.
  set textStrokeWidthCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.textStrokeWidth);
    } else {
      store(OptionKey.textStrokeWidth, cell);
    }
  }

  /// Stores the plain value [value] of `textStrokeWidth`.
  set textStrokeWidth(double value) =>
      store(OptionKey.textStrokeWidth, OptValue<double>(value));

  Opt<double>? _z;

  /// The cell of `z`, or Dart `null` when absent.
  Opt<double>? get zCell => _z;

  /// Stores the cell of `z`. Dart `null` deletes the key.
  set zCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.z);
    } else {
      store(OptionKey.z, cell);
    }
  }

  /// Stores the plain value [value] of `z`.
  set z(double value) => store(OptionKey.z, OptValue<double>(value));

  Opt<MajorTickOptionsScope>? _major;

  /// The cell of `major`, or Dart `null` when absent.
  Opt<MajorTickOptionsScope>? get majorCell => _major;

  /// Stores the cell of `major`. Dart `null` deletes the key.
  set majorCell(Opt<MajorTickOptionsScope>? cell) {
    if (cell == null) {
      delete(OptionKey.major);
    } else {
      store(OptionKey.major, cell);
    }
  }

  /// Stores the plain value [value] of `major`.
  set major(MajorTickOptionsScope value) =>
      store(OptionKey.major, OptScope<MajorTickOptionsScope>(value));

  Opt<double>? _sampleSize;

  /// The cell of `sampleSize`, or Dart `null` when absent.
  Opt<double>? get sampleSizeCell => _sampleSize;

  /// Stores the cell of `sampleSize`. Dart `null` deletes the key.
  set sampleSizeCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.sampleSize);
    } else {
      store(OptionKey.sampleSize, cell);
    }
  }

  /// Stores the plain value [value] of `sampleSize`.
  set sampleSize(double value) =>
      store(OptionKey.sampleSize, OptValue<double>(value));

  Opt<String>? _align;

  /// The cell of `align`, or Dart `null` when absent.
  Opt<String>? get alignCell => _align;

  /// Stores the cell of `align`. Dart `null` deletes the key.
  set alignCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.align);
    } else {
      store(OptionKey.align, cell);
    }
  }

  /// Stores the plain value [value] of `align`.
  set align(String value) => store(OptionKey.align, OptValue<String>(value));

  Opt<bool>? _autoSkip;

  /// The cell of `autoSkip`, or Dart `null` when absent.
  Opt<bool>? get autoSkipCell => _autoSkip;

  /// Stores the cell of `autoSkip`. Dart `null` deletes the key.
  set autoSkipCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.autoSkip);
    } else {
      store(OptionKey.autoSkip, cell);
    }
  }

  /// Stores the plain value [value] of `autoSkip`.
  set autoSkip(bool value) => store(OptionKey.autoSkip, OptValue<bool>(value));

  Opt<double>? _autoSkipPadding;

  /// The cell of `autoSkipPadding`, or Dart `null` when absent.
  Opt<double>? get autoSkipPaddingCell => _autoSkipPadding;

  /// Stores the cell of `autoSkipPadding`. Dart `null` deletes the key.
  set autoSkipPaddingCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.autoSkipPadding);
    } else {
      store(OptionKey.autoSkipPadding, cell);
    }
  }

  /// Stores the plain value [value] of `autoSkipPadding`.
  set autoSkipPadding(double value) =>
      store(OptionKey.autoSkipPadding, OptValue<double>(value));

  Opt<String>? _crossAlign;

  /// The cell of `crossAlign`, or Dart `null` when absent.
  Opt<String>? get crossAlignCell => _crossAlign;

  /// Stores the cell of `crossAlign`. Dart `null` deletes the key.
  set crossAlignCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.crossAlign);
    } else {
      store(OptionKey.crossAlign, cell);
    }
  }

  /// Stores the plain value [value] of `crossAlign`.
  set crossAlign(String value) =>
      store(OptionKey.crossAlign, OptValue<String>(value));

  Opt<bool>? _includeBounds;

  /// The cell of `includeBounds`, or Dart `null` when absent.
  Opt<bool>? get includeBoundsCell => _includeBounds;

  /// Stores the cell of `includeBounds`. Dart `null` deletes the key.
  set includeBoundsCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.includeBounds);
    } else {
      store(OptionKey.includeBounds, cell);
    }
  }

  /// Stores the plain value [value] of `includeBounds`.
  set includeBounds(bool value) =>
      store(OptionKey.includeBounds, OptValue<bool>(value));

  Opt<double>? _labelOffset;

  /// The cell of `labelOffset`, or Dart `null` when absent.
  Opt<double>? get labelOffsetCell => _labelOffset;

  /// Stores the cell of `labelOffset`. Dart `null` deletes the key.
  set labelOffsetCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.labelOffset);
    } else {
      store(OptionKey.labelOffset, cell);
    }
  }

  /// Stores the plain value [value] of `labelOffset`.
  set labelOffset(double value) =>
      store(OptionKey.labelOffset, OptValue<double>(value));

  Opt<double>? _minRotation;

  /// The cell of `minRotation`, or Dart `null` when absent.
  Opt<double>? get minRotationCell => _minRotation;

  /// Stores the cell of `minRotation`. Dart `null` deletes the key.
  set minRotationCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.minRotation);
    } else {
      store(OptionKey.minRotation, cell);
    }
  }

  /// Stores the plain value [value] of `minRotation`.
  set minRotation(double value) =>
      store(OptionKey.minRotation, OptValue<double>(value));

  Opt<double>? _maxRotation;

  /// The cell of `maxRotation`, or Dart `null` when absent.
  Opt<double>? get maxRotationCell => _maxRotation;

  /// Stores the cell of `maxRotation`. Dart `null` deletes the key.
  set maxRotationCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.maxRotation);
    } else {
      store(OptionKey.maxRotation, cell);
    }
  }

  /// Stores the plain value [value] of `maxRotation`.
  set maxRotation(double value) =>
      store(OptionKey.maxRotation, OptValue<double>(value));

  Opt<bool>? _mirror;

  /// The cell of `mirror`, or Dart `null` when absent.
  Opt<bool>? get mirrorCell => _mirror;

  /// Stores the cell of `mirror`. Dart `null` deletes the key.
  set mirrorCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.mirror);
    } else {
      store(OptionKey.mirror, cell);
    }
  }

  /// Stores the plain value [value] of `mirror`.
  set mirror(bool value) => store(OptionKey.mirror, OptValue<bool>(value));

  Opt<double>? _maxTicksLimit;

  /// The cell of `maxTicksLimit`, or Dart `null` when absent.
  Opt<double>? get maxTicksLimitCell => _maxTicksLimit;

  /// Stores the cell of `maxTicksLimit`. Dart `null` deletes the key.
  set maxTicksLimitCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.maxTicksLimit);
    } else {
      store(OptionKey.maxTicksLimit, cell);
    }
  }

  /// Stores the plain value [value] of `maxTicksLimit`.
  set maxTicksLimit(double value) =>
      store(OptionKey.maxTicksLimit, OptValue<double>(value));

  Opt<Object>? _format;

  /// The cell of `format`, or Dart `null` when absent.
  Opt<Object>? get formatCell => _format;

  /// Stores the cell of `format`. Dart `null` deletes the key.
  set formatCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.format);
    } else {
      store(OptionKey.format, cell);
    }
  }

  /// Stores the plain value [value] of `format`.
  set format(Object value) =>
      store(OptionKey.format, classify(OptionKey.format, value));

  Opt<double>? _precision;

  /// The cell of `precision`, or Dart `null` when absent.
  Opt<double>? get precisionCell => _precision;

  /// Stores the cell of `precision`. Dart `null` deletes the key.
  set precisionCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.precision);
    } else {
      store(OptionKey.precision, cell);
    }
  }

  /// Stores the plain value [value] of `precision`.
  set precision(double value) =>
      store(OptionKey.precision, OptValue<double>(value));

  Opt<double>? _stepSize;

  /// The cell of `stepSize`, or Dart `null` when absent.
  Opt<double>? get stepSizeCell => _stepSize;

  /// Stores the cell of `stepSize`. Dart `null` deletes the key.
  set stepSizeCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.stepSize);
    } else {
      store(OptionKey.stepSize, cell);
    }
  }

  /// Stores the plain value [value] of `stepSize`.
  set stepSize(double value) =>
      store(OptionKey.stepSize, OptValue<double>(value));

  Opt<double>? _count;

  /// The cell of `count`, or Dart `null` when absent.
  Opt<double>? get countCell => _count;

  /// Stores the cell of `count`. Dart `null` deletes the key.
  set countCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.count);
    } else {
      store(OptionKey.count, cell);
    }
  }

  /// Stores the plain value [value] of `count`.
  set count(double value) => store(OptionKey.count, OptValue<double>(value));

  Opt<String>? _source;

  /// The cell of `source`, or Dart `null` when absent.
  Opt<String>? get sourceCell => _source;

  /// Stores the cell of `source`. Dart `null` deletes the key.
  set sourceCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.source);
    } else {
      store(OptionKey.source, cell);
    }
  }

  /// Stores the plain value [value] of `source`.
  set source(String value) => store(OptionKey.source, OptValue<String>(value));

  Opt<MinorTickOptionsScope>? _minor;

  /// The cell of `minor`, or Dart `null` when absent.
  Opt<MinorTickOptionsScope>? get minorCell => _minor;

  /// Stores the cell of `minor`. Dart `null` deletes the key.
  set minorCell(Opt<MinorTickOptionsScope>? cell) {
    if (cell == null) {
      delete(OptionKey.minor);
    } else {
      store(OptionKey.minor, cell);
    }
  }

  /// Stores the plain value [value] of `minor`.
  set minor(MinorTickOptionsScope value) =>
      store(OptionKey.minor, OptScope<MinorTickOptionsScope>(value));

  @override
  Opt<Object?>? cellOf(OptionKey key) => switch (key) {
    OptionKey.backdropColor => _backdropColor,
    OptionKey.backdropPadding => _backdropPadding,
    OptionKey.callback => _callback,
    OptionKey.display => _display,
    OptionKey.color => _color,
    OptionKey.font => _font,
    OptionKey.padding => _padding,
    OptionKey.showLabelBackdrop => _showLabelBackdrop,
    OptionKey.textStrokeColor => _textStrokeColor,
    OptionKey.textStrokeWidth => _textStrokeWidth,
    OptionKey.z => _z,
    OptionKey.major => _major,
    OptionKey.sampleSize => _sampleSize,
    OptionKey.align => _align,
    OptionKey.autoSkip => _autoSkip,
    OptionKey.autoSkipPadding => _autoSkipPadding,
    OptionKey.crossAlign => _crossAlign,
    OptionKey.includeBounds => _includeBounds,
    OptionKey.labelOffset => _labelOffset,
    OptionKey.minRotation => _minRotation,
    OptionKey.maxRotation => _maxRotation,
    OptionKey.mirror => _mirror,
    OptionKey.maxTicksLimit => _maxTicksLimit,
    OptionKey.format => _format,
    OptionKey.precision => _precision,
    OptionKey.stepSize => _stepSize,
    OptionKey.count => _count,
    OptionKey.source => _source,
    OptionKey.minor => _minor,
    _ => null,
  };

  @override
  void setCell(OptionKey key, Opt<Object?>? cell) {
    switch (key) {
      case OptionKey.backdropColor:
        _backdropColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.backdropPadding:
        _backdropPadding = fitCell(cell, (raw) => classifyUnion(raw, 33));
      case OptionKey.callback:
        _callback = fitCell(cell, (raw) => classifyUnion(raw, 10));
      case OptionKey.display:
        _display = fitCell(cell, classifyBool);
      case OptionKey.color:
        _color = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.font:
        _font = fitCell(cell, classifyScope<FontSpecScope>);
      case OptionKey.padding:
        _padding = fitCell(cell, classifyNumber);
      case OptionKey.showLabelBackdrop:
        _showLabelBackdrop = fitCell(cell, classifyBool);
      case OptionKey.textStrokeColor:
        _textStrokeColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.textStrokeWidth:
        _textStrokeWidth = fitCell(cell, classifyNumber);
      case OptionKey.z:
        _z = fitCell(cell, classifyNumber);
      case OptionKey.major:
        _major = fitCell(cell, classifyScope<MajorTickOptionsScope>);
      case OptionKey.sampleSize:
        _sampleSize = fitCell(cell, classifyNumber);
      case OptionKey.align:
        _align = fitCell(cell, classifyString);
      case OptionKey.autoSkip:
        _autoSkip = fitCell(cell, classifyBool);
      case OptionKey.autoSkipPadding:
        _autoSkipPadding = fitCell(cell, classifyNumber);
      case OptionKey.crossAlign:
        _crossAlign = fitCell(cell, classifyString);
      case OptionKey.includeBounds:
        _includeBounds = fitCell(cell, classifyBool);
      case OptionKey.labelOffset:
        _labelOffset = fitCell(cell, classifyNumber);
      case OptionKey.minRotation:
        _minRotation = fitCell(cell, classifyNumber);
      case OptionKey.maxRotation:
        _maxRotation = fitCell(cell, classifyNumber);
      case OptionKey.mirror:
        _mirror = fitCell(cell, classifyBool);
      case OptionKey.maxTicksLimit:
        _maxTicksLimit = fitCell(cell, classifyNumber);
      case OptionKey.format:
        _format = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.precision:
        _precision = fitCell(cell, classifyNumber);
      case OptionKey.stepSize:
        _stepSize = fitCell(cell, classifyNumber);
      case OptionKey.count:
        _count = fitCell(cell, classifyNumber);
      case OptionKey.source:
        _source = fitCell(cell, classifyString);
      case OptionKey.minor:
        _minor = fitCell(cell, classifyScope<MinorTickOptionsScope>);
      default:
        throw ArgumentError.value(key, 'key', 'Not a key of TickOptions');
    }
  }

  @override
  bool hasField(OptionKey key) => switch (key) {
    OptionKey.backdropColor ||
    OptionKey.backdropPadding ||
    OptionKey.callback ||
    OptionKey.display ||
    OptionKey.color ||
    OptionKey.font ||
    OptionKey.padding ||
    OptionKey.showLabelBackdrop ||
    OptionKey.textStrokeColor ||
    OptionKey.textStrokeWidth ||
    OptionKey.z ||
    OptionKey.major ||
    OptionKey.sampleSize ||
    OptionKey.align ||
    OptionKey.autoSkip ||
    OptionKey.autoSkipPadding ||
    OptionKey.crossAlign ||
    OptionKey.includeBounds ||
    OptionKey.labelOffset ||
    OptionKey.minRotation ||
    OptionKey.maxRotation ||
    OptionKey.mirror ||
    OptionKey.maxTicksLimit ||
    OptionKey.format ||
    OptionKey.precision ||
    OptionKey.stepSize ||
    OptionKey.count ||
    OptionKey.source ||
    OptionKey.minor => true,
    _ => false,
  };

  @override
  Opt<Object?> classify(OptionKey key, Object? raw) => switch (key) {
    OptionKey.backdropColor => classifyUnion(raw, 64),
    OptionKey.backdropPadding => classifyUnion(raw, 33),
    OptionKey.callback => classifyUnion(raw, 10),
    OptionKey.display => classifyBool(raw),
    OptionKey.color => classifyUnion(raw, 64),
    OptionKey.font => classifyScope<FontSpecScope>(raw),
    OptionKey.padding => classifyNumber(raw),
    OptionKey.showLabelBackdrop => classifyBool(raw),
    OptionKey.textStrokeColor => classifyUnion(raw, 64),
    OptionKey.textStrokeWidth => classifyNumber(raw),
    OptionKey.z => classifyNumber(raw),
    OptionKey.major => classifyScope<MajorTickOptionsScope>(raw),
    OptionKey.sampleSize => classifyNumber(raw),
    OptionKey.align => classifyString(raw),
    OptionKey.autoSkip => classifyBool(raw),
    OptionKey.autoSkipPadding => classifyNumber(raw),
    OptionKey.crossAlign => classifyString(raw),
    OptionKey.includeBounds => classifyBool(raw),
    OptionKey.labelOffset => classifyNumber(raw),
    OptionKey.minRotation => classifyNumber(raw),
    OptionKey.maxRotation => classifyNumber(raw),
    OptionKey.mirror => classifyBool(raw),
    OptionKey.maxTicksLimit => classifyNumber(raw),
    OptionKey.format => classifyUnion(raw, 64),
    OptionKey.precision => classifyNumber(raw),
    OptionKey.stepSize => classifyNumber(raw),
    OptionKey.count => classifyNumber(raw),
    OptionKey.source => classifyString(raw),
    OptionKey.minor => classifyScope<MinorTickOptionsScope>(raw),
    _ => kind.classifyOther(raw),
  };
}

/// Port-only name for index.d.ts:3170 TickOptions `major`, the major ticks
/// (read at core.scale.autoskip.js:21 and scale.time.js).
base class MajorTickOptionsScope extends OptionScope {
  /// An empty scope.
  MajorTickOptionsScope();

  @override
  ScopeKind get kind => ScopeKind.majorTickOptions;

  Opt<bool>? _enabled;

  /// The cell of `enabled`, or Dart `null` when absent.
  Opt<bool>? get enabledCell => _enabled;

  /// Stores the cell of `enabled`. Dart `null` deletes the key.
  set enabledCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.enabled);
    } else {
      store(OptionKey.enabled, cell);
    }
  }

  /// Stores the plain value [value] of `enabled`.
  set enabled(bool value) => store(OptionKey.enabled, OptValue<bool>(value));

  @override
  Opt<Object?>? cellOf(OptionKey key) => switch (key) {
    OptionKey.enabled => _enabled,
    _ => null,
  };

  @override
  void setCell(OptionKey key, Opt<Object?>? cell) {
    switch (key) {
      case OptionKey.enabled:
        _enabled = fitCell(cell, classifyBool);
      default:
        throw ArgumentError.value(key, 'key', 'Not a key of MajorTickOptions');
    }
  }

  @override
  bool hasField(OptionKey key) => switch (key) {
    OptionKey.enabled => true,
    _ => false,
  };

  @override
  Opt<Object?> classify(OptionKey key, Object? raw) => switch (key) {
    OptionKey.enabled => classifyBool(raw),
    _ => kind.classifyOther(raw),
  };
}

/// Port-only kind for core.scale.defaults.js:75 `ticks.minor`, an empty object
/// that no upstream code reads.
base class MinorTickOptionsScope extends OptionScope {
  /// An empty scope.
  MinorTickOptionsScope();

  @override
  ScopeKind get kind => ScopeKind.minorTickOptions;

  @override
  Opt<Object?>? cellOf(OptionKey key) => null;

  @override
  void setCell(OptionKey key, Opt<Object?>? cell) {
    throw ArgumentError.value(key, 'key', 'Not a key of MinorTickOptions');
  }

  @override
  bool hasField(OptionKey key) => false;

  @override
  Opt<Object?> classify(OptionKey key, Object? raw) => kind.classifyOther(raw);
}

/// index.d.ts:3060 GridLineOptions, the scope `grid` of a scale.
base class GridLineOptionsScope extends OptionScope {
  /// An empty scope.
  GridLineOptionsScope();

  @override
  ScopeKind get kind => ScopeKind.gridLineOptions;

  Opt<bool>? _display;

  /// The cell of `display`, or Dart `null` when absent.
  Opt<bool>? get displayCell => _display;

  /// Stores the cell of `display`. Dart `null` deletes the key.
  set displayCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.display);
    } else {
      store(OptionKey.display, cell);
    }
  }

  /// Stores the plain value [value] of `display`.
  set display(bool value) => store(OptionKey.display, OptValue<bool>(value));

  Opt<bool>? _circular;

  /// The cell of `circular`, or Dart `null` when absent.
  Opt<bool>? get circularCell => _circular;

  /// Stores the cell of `circular`. Dart `null` deletes the key.
  set circularCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.circular);
    } else {
      store(OptionKey.circular, cell);
    }
  }

  /// Stores the plain value [value] of `circular`.
  set circular(bool value) => store(OptionKey.circular, OptValue<bool>(value));

  Opt<Object>? _color;

  /// The cell of `color`, or Dart `null` when absent.
  Opt<Object>? get colorCell => _color;

  /// Stores the cell of `color`. Dart `null` deletes the key.
  set colorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.color);
    } else {
      store(OptionKey.color, cell);
    }
  }

  /// Stores the plain value [value] of `color`.
  set color(Object value) =>
      store(OptionKey.color, classify(OptionKey.color, value));

  Opt<double>? _lineWidth;

  /// The cell of `lineWidth`, or Dart `null` when absent.
  Opt<double>? get lineWidthCell => _lineWidth;

  /// Stores the cell of `lineWidth`. Dart `null` deletes the key.
  set lineWidthCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.lineWidth);
    } else {
      store(OptionKey.lineWidth, cell);
    }
  }

  /// Stores the plain value [value] of `lineWidth`.
  set lineWidth(double value) =>
      store(OptionKey.lineWidth, OptValue<double>(value));

  Opt<bool>? _drawOnChartArea;

  /// The cell of `drawOnChartArea`, or Dart `null` when absent.
  Opt<bool>? get drawOnChartAreaCell => _drawOnChartArea;

  /// Stores the cell of `drawOnChartArea`. Dart `null` deletes the key.
  set drawOnChartAreaCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.drawOnChartArea);
    } else {
      store(OptionKey.drawOnChartArea, cell);
    }
  }

  /// Stores the plain value [value] of `drawOnChartArea`.
  set drawOnChartArea(bool value) =>
      store(OptionKey.drawOnChartArea, OptValue<bool>(value));

  Opt<bool>? _drawTicks;

  /// The cell of `drawTicks`, or Dart `null` when absent.
  Opt<bool>? get drawTicksCell => _drawTicks;

  /// Stores the cell of `drawTicks`. Dart `null` deletes the key.
  set drawTicksCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.drawTicks);
    } else {
      store(OptionKey.drawTicks, cell);
    }
  }

  /// Stores the plain value [value] of `drawTicks`.
  set drawTicks(bool value) =>
      store(OptionKey.drawTicks, OptValue<bool>(value));

  Opt<Object>? _tickBorderDash;

  /// The cell of `tickBorderDash`, or Dart `null` when absent.
  Opt<Object>? get tickBorderDashCell => _tickBorderDash;

  /// Stores the cell of `tickBorderDash`. Dart `null` deletes the key.
  set tickBorderDashCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.tickBorderDash);
    } else {
      store(OptionKey.tickBorderDash, cell);
    }
  }

  /// Stores the plain value [value] of `tickBorderDash`.
  set tickBorderDash(Object value) => store(
    OptionKey.tickBorderDash,
    classify(OptionKey.tickBorderDash, value),
  );

  Opt<double>? _tickBorderDashOffset;

  /// The cell of `tickBorderDashOffset`, or Dart `null` when absent.
  Opt<double>? get tickBorderDashOffsetCell => _tickBorderDashOffset;

  /// Stores the cell of `tickBorderDashOffset`. Dart `null` deletes the key.
  set tickBorderDashOffsetCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.tickBorderDashOffset);
    } else {
      store(OptionKey.tickBorderDashOffset, cell);
    }
  }

  /// Stores the plain value [value] of `tickBorderDashOffset`.
  set tickBorderDashOffset(double value) =>
      store(OptionKey.tickBorderDashOffset, OptValue<double>(value));

  Opt<Object>? _tickColor;

  /// The cell of `tickColor`, or Dart `null` when absent.
  Opt<Object>? get tickColorCell => _tickColor;

  /// Stores the cell of `tickColor`. Dart `null` deletes the key.
  set tickColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.tickColor);
    } else {
      store(OptionKey.tickColor, cell);
    }
  }

  /// Stores the plain value [value] of `tickColor`.
  set tickColor(Object value) =>
      store(OptionKey.tickColor, classify(OptionKey.tickColor, value));

  Opt<double>? _tickLength;

  /// The cell of `tickLength`, or Dart `null` when absent.
  Opt<double>? get tickLengthCell => _tickLength;

  /// Stores the cell of `tickLength`. Dart `null` deletes the key.
  set tickLengthCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.tickLength);
    } else {
      store(OptionKey.tickLength, cell);
    }
  }

  /// Stores the plain value [value] of `tickLength`.
  set tickLength(double value) =>
      store(OptionKey.tickLength, OptValue<double>(value));

  Opt<double>? _tickWidth;

  /// The cell of `tickWidth`, or Dart `null` when absent.
  Opt<double>? get tickWidthCell => _tickWidth;

  /// Stores the cell of `tickWidth`. Dart `null` deletes the key.
  set tickWidthCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.tickWidth);
    } else {
      store(OptionKey.tickWidth, cell);
    }
  }

  /// Stores the plain value [value] of `tickWidth`.
  set tickWidth(double value) =>
      store(OptionKey.tickWidth, OptValue<double>(value));

  Opt<bool>? _offset;

  /// The cell of `offset`, or Dart `null` when absent.
  Opt<bool>? get offsetCell => _offset;

  /// Stores the cell of `offset`. Dart `null` deletes the key.
  set offsetCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.offset);
    } else {
      store(OptionKey.offset, cell);
    }
  }

  /// Stores the plain value [value] of `offset`.
  set offset(bool value) => store(OptionKey.offset, OptValue<bool>(value));

  Opt<double>? _z;

  /// The cell of `z`, or Dart `null` when absent.
  Opt<double>? get zCell => _z;

  /// Stores the cell of `z`. Dart `null` deletes the key.
  set zCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.z);
    } else {
      store(OptionKey.z, cell);
    }
  }

  /// Stores the plain value [value] of `z`.
  set z(double value) => store(OptionKey.z, OptValue<double>(value));

  @override
  Opt<Object?>? cellOf(OptionKey key) => switch (key) {
    OptionKey.display => _display,
    OptionKey.circular => _circular,
    OptionKey.color => _color,
    OptionKey.lineWidth => _lineWidth,
    OptionKey.drawOnChartArea => _drawOnChartArea,
    OptionKey.drawTicks => _drawTicks,
    OptionKey.tickBorderDash => _tickBorderDash,
    OptionKey.tickBorderDashOffset => _tickBorderDashOffset,
    OptionKey.tickColor => _tickColor,
    OptionKey.tickLength => _tickLength,
    OptionKey.tickWidth => _tickWidth,
    OptionKey.offset => _offset,
    OptionKey.z => _z,
    _ => null,
  };

  @override
  void setCell(OptionKey key, Opt<Object?>? cell) {
    switch (key) {
      case OptionKey.display:
        _display = fitCell(cell, classifyBool);
      case OptionKey.circular:
        _circular = fitCell(cell, classifyBool);
      case OptionKey.color:
        _color = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.lineWidth:
        _lineWidth = fitCell(cell, classifyNumber);
      case OptionKey.drawOnChartArea:
        _drawOnChartArea = fitCell(cell, classifyBool);
      case OptionKey.drawTicks:
        _drawTicks = fitCell(cell, classifyBool);
      case OptionKey.tickBorderDash:
        _tickBorderDash = fitCell(cell, (raw) => classifyUnion(raw, 16));
      case OptionKey.tickBorderDashOffset:
        _tickBorderDashOffset = fitCell(cell, classifyNumber);
      case OptionKey.tickColor:
        _tickColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.tickLength:
        _tickLength = fitCell(cell, classifyNumber);
      case OptionKey.tickWidth:
        _tickWidth = fitCell(cell, classifyNumber);
      case OptionKey.offset:
        _offset = fitCell(cell, classifyBool);
      case OptionKey.z:
        _z = fitCell(cell, classifyNumber);
      default:
        throw ArgumentError.value(key, 'key', 'Not a key of GridLineOptions');
    }
  }

  @override
  bool hasField(OptionKey key) => switch (key) {
    OptionKey.display ||
    OptionKey.circular ||
    OptionKey.color ||
    OptionKey.lineWidth ||
    OptionKey.drawOnChartArea ||
    OptionKey.drawTicks ||
    OptionKey.tickBorderDash ||
    OptionKey.tickBorderDashOffset ||
    OptionKey.tickColor ||
    OptionKey.tickLength ||
    OptionKey.tickWidth ||
    OptionKey.offset ||
    OptionKey.z => true,
    _ => false,
  };

  @override
  Opt<Object?> classify(OptionKey key, Object? raw) => switch (key) {
    OptionKey.display => classifyBool(raw),
    OptionKey.circular => classifyBool(raw),
    OptionKey.color => classifyUnion(raw, 64),
    OptionKey.lineWidth => classifyNumber(raw),
    OptionKey.drawOnChartArea => classifyBool(raw),
    OptionKey.drawTicks => classifyBool(raw),
    OptionKey.tickBorderDash => classifyUnion(raw, 16),
    OptionKey.tickBorderDashOffset => classifyNumber(raw),
    OptionKey.tickColor => classifyUnion(raw, 64),
    OptionKey.tickLength => classifyNumber(raw),
    OptionKey.tickWidth => classifyNumber(raw),
    OptionKey.offset => classifyBool(raw),
    OptionKey.z => classifyNumber(raw),
    _ => kind.classifyOther(raw),
  };
}

/// index.d.ts:3042 BorderOptions, the scope `border` of a scale.
base class BorderOptionsScope extends OptionScope {
  /// An empty scope.
  BorderOptionsScope();

  @override
  ScopeKind get kind => ScopeKind.borderOptions;

  Opt<bool>? _display;

  /// The cell of `display`, or Dart `null` when absent.
  Opt<bool>? get displayCell => _display;

  /// Stores the cell of `display`. Dart `null` deletes the key.
  set displayCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.display);
    } else {
      store(OptionKey.display, cell);
    }
  }

  /// Stores the plain value [value] of `display`.
  set display(bool value) => store(OptionKey.display, OptValue<bool>(value));

  Opt<Object>? _dash;

  /// The cell of `dash`, or Dart `null` when absent.
  Opt<Object>? get dashCell => _dash;

  /// Stores the cell of `dash`. Dart `null` deletes the key.
  set dashCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.dash);
    } else {
      store(OptionKey.dash, cell);
    }
  }

  /// Stores the plain value [value] of `dash`.
  set dash(Object value) =>
      store(OptionKey.dash, classify(OptionKey.dash, value));

  Opt<double>? _dashOffset;

  /// The cell of `dashOffset`, or Dart `null` when absent.
  Opt<double>? get dashOffsetCell => _dashOffset;

  /// Stores the cell of `dashOffset`. Dart `null` deletes the key.
  set dashOffsetCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.dashOffset);
    } else {
      store(OptionKey.dashOffset, cell);
    }
  }

  /// Stores the plain value [value] of `dashOffset`.
  set dashOffset(double value) =>
      store(OptionKey.dashOffset, OptValue<double>(value));

  Opt<Object>? _color;

  /// The cell of `color`, or Dart `null` when absent.
  Opt<Object>? get colorCell => _color;

  /// Stores the cell of `color`. Dart `null` deletes the key.
  set colorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.color);
    } else {
      store(OptionKey.color, cell);
    }
  }

  /// Stores the plain value [value] of `color`.
  set color(Object value) =>
      store(OptionKey.color, classify(OptionKey.color, value));

  Opt<double>? _width;

  /// The cell of `width`, or Dart `null` when absent.
  Opt<double>? get widthCell => _width;

  /// Stores the cell of `width`. Dart `null` deletes the key.
  set widthCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.width);
    } else {
      store(OptionKey.width, cell);
    }
  }

  /// Stores the plain value [value] of `width`.
  set width(double value) => store(OptionKey.width, OptValue<double>(value));

  Opt<double>? _z;

  /// The cell of `z`, or Dart `null` when absent.
  Opt<double>? get zCell => _z;

  /// Stores the cell of `z`. Dart `null` deletes the key.
  set zCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.z);
    } else {
      store(OptionKey.z, cell);
    }
  }

  /// Stores the plain value [value] of `z`.
  set z(double value) => store(OptionKey.z, OptValue<double>(value));

  @override
  Opt<Object?>? cellOf(OptionKey key) => switch (key) {
    OptionKey.display => _display,
    OptionKey.dash => _dash,
    OptionKey.dashOffset => _dashOffset,
    OptionKey.color => _color,
    OptionKey.width => _width,
    OptionKey.z => _z,
    _ => null,
  };

  @override
  void setCell(OptionKey key, Opt<Object?>? cell) {
    switch (key) {
      case OptionKey.display:
        _display = fitCell(cell, classifyBool);
      case OptionKey.dash:
        _dash = fitCell(cell, (raw) => classifyUnion(raw, 16));
      case OptionKey.dashOffset:
        _dashOffset = fitCell(cell, classifyNumber);
      case OptionKey.color:
        _color = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.width:
        _width = fitCell(cell, classifyNumber);
      case OptionKey.z:
        _z = fitCell(cell, classifyNumber);
      default:
        throw ArgumentError.value(key, 'key', 'Not a key of BorderOptions');
    }
  }

  @override
  bool hasField(OptionKey key) => switch (key) {
    OptionKey.display ||
    OptionKey.dash ||
    OptionKey.dashOffset ||
    OptionKey.color ||
    OptionKey.width ||
    OptionKey.z => true,
    _ => false,
  };

  @override
  Opt<Object?> classify(OptionKey key, Object? raw) => switch (key) {
    OptionKey.display => classifyBool(raw),
    OptionKey.dash => classifyUnion(raw, 16),
    OptionKey.dashOffset => classifyNumber(raw),
    OptionKey.color => classifyUnion(raw, 64),
    OptionKey.width => classifyNumber(raw),
    OptionKey.z => classifyNumber(raw),
    _ => kind.classifyOther(raw),
  };
}

/// Port-only name for index.d.ts:3309 CartesianScaleOptions `title`, the title
/// of a scale.
base class ScaleTitleOptionsScope extends OptionScope {
  /// An empty scope.
  ScaleTitleOptionsScope();

  @override
  ScopeKind get kind => ScopeKind.scaleTitleOptions;

  Opt<bool>? _display;

  /// The cell of `display`, or Dart `null` when absent.
  Opt<bool>? get displayCell => _display;

  /// Stores the cell of `display`. Dart `null` deletes the key.
  set displayCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.display);
    } else {
      store(OptionKey.display, cell);
    }
  }

  /// Stores the plain value [value] of `display`.
  set display(bool value) => store(OptionKey.display, OptValue<bool>(value));

  Opt<String>? _align;

  /// The cell of `align`, or Dart `null` when absent.
  Opt<String>? get alignCell => _align;

  /// Stores the cell of `align`. Dart `null` deletes the key.
  set alignCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.align);
    } else {
      store(OptionKey.align, cell);
    }
  }

  /// Stores the plain value [value] of `align`.
  set align(String value) => store(OptionKey.align, OptValue<String>(value));

  Opt<Object>? _text;

  /// The cell of `text`, or Dart `null` when absent.
  Opt<Object>? get textCell => _text;

  /// Stores the cell of `text`. Dart `null` deletes the key.
  set textCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.text);
    } else {
      store(OptionKey.text, cell);
    }
  }

  /// Stores the plain value [value] of `text`.
  set text(Object value) =>
      store(OptionKey.text, classify(OptionKey.text, value));

  Opt<Object>? _color;

  /// The cell of `color`, or Dart `null` when absent.
  Opt<Object>? get colorCell => _color;

  /// Stores the cell of `color`. Dart `null` deletes the key.
  set colorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.color);
    } else {
      store(OptionKey.color, cell);
    }
  }

  /// Stores the plain value [value] of `color`.
  set color(Object value) =>
      store(OptionKey.color, classify(OptionKey.color, value));

  Opt<Object>? _strokeColor;

  /// The cell of `strokeColor`, or Dart `null` when absent.
  Opt<Object>? get strokeColorCell => _strokeColor;

  /// Stores the cell of `strokeColor`. Dart `null` deletes the key.
  set strokeColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.strokeColor);
    } else {
      store(OptionKey.strokeColor, cell);
    }
  }

  /// Stores the plain value [value] of `strokeColor`.
  set strokeColor(Object value) =>
      store(OptionKey.strokeColor, classify(OptionKey.strokeColor, value));

  Opt<double>? _strokeWidth;

  /// The cell of `strokeWidth`, or Dart `null` when absent.
  Opt<double>? get strokeWidthCell => _strokeWidth;

  /// Stores the cell of `strokeWidth`. Dart `null` deletes the key.
  set strokeWidthCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.strokeWidth);
    } else {
      store(OptionKey.strokeWidth, cell);
    }
  }

  /// Stores the plain value [value] of `strokeWidth`.
  set strokeWidth(double value) =>
      store(OptionKey.strokeWidth, OptValue<double>(value));

  Opt<FontSpecScope>? _font;

  /// The cell of `font`, or Dart `null` when absent.
  Opt<FontSpecScope>? get fontCell => _font;

  /// Stores the cell of `font`. Dart `null` deletes the key.
  set fontCell(Opt<FontSpecScope>? cell) {
    if (cell == null) {
      delete(OptionKey.font);
    } else {
      store(OptionKey.font, cell);
    }
  }

  /// Stores the plain value [value] of `font`.
  set font(FontSpecScope value) =>
      store(OptionKey.font, OptScope<FontSpecScope>(value));

  Opt<Object>? _padding;

  /// The cell of `padding`, or Dart `null` when absent.
  Opt<Object>? get paddingCell => _padding;

  /// Stores the cell of `padding`. Dart `null` deletes the key.
  set paddingCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.padding);
    } else {
      store(OptionKey.padding, cell);
    }
  }

  /// Stores the plain value [value] of `padding`.
  set padding(Object value) =>
      store(OptionKey.padding, classify(OptionKey.padding, value));

  @override
  Opt<Object?>? cellOf(OptionKey key) => switch (key) {
    OptionKey.display => _display,
    OptionKey.align => _align,
    OptionKey.text => _text,
    OptionKey.color => _color,
    OptionKey.strokeColor => _strokeColor,
    OptionKey.strokeWidth => _strokeWidth,
    OptionKey.font => _font,
    OptionKey.padding => _padding,
    _ => null,
  };

  @override
  void setCell(OptionKey key, Opt<Object?>? cell) {
    switch (key) {
      case OptionKey.display:
        _display = fitCell(cell, classifyBool);
      case OptionKey.align:
        _align = fitCell(cell, classifyString);
      case OptionKey.text:
        _text = fitCell(cell, (raw) => classifyUnion(raw, 20));
      case OptionKey.color:
        _color = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.strokeColor:
        _strokeColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.strokeWidth:
        _strokeWidth = fitCell(cell, classifyNumber);
      case OptionKey.font:
        _font = fitCell(cell, classifyScope<FontSpecScope>);
      case OptionKey.padding:
        _padding = fitCell(cell, (raw) => classifyUnion(raw, 33));
      default:
        throw ArgumentError.value(key, 'key', 'Not a key of ScaleTitleOptions');
    }
  }

  @override
  bool hasField(OptionKey key) => switch (key) {
    OptionKey.display ||
    OptionKey.align ||
    OptionKey.text ||
    OptionKey.color ||
    OptionKey.strokeColor ||
    OptionKey.strokeWidth ||
    OptionKey.font ||
    OptionKey.padding => true,
    _ => false,
  };

  @override
  Opt<Object?> classify(OptionKey key, Object? raw) => switch (key) {
    OptionKey.display => classifyBool(raw),
    OptionKey.align => classifyString(raw),
    OptionKey.text => classifyUnion(raw, 20),
    OptionKey.color => classifyUnion(raw, 64),
    OptionKey.strokeColor => classifyUnion(raw, 64),
    OptionKey.strokeWidth => classifyNumber(raw),
    OptionKey.font => classifyScope<FontSpecScope>(raw),
    OptionKey.padding => classifyUnion(raw, 33),
    _ => kind.classifyOther(raw),
  };
}

/// index.d.ts:3429 TimeScaleTimeOptions, the scope `time` of a time scale.
base class TimeScaleTimeOptionsScope extends OptionScope {
  /// An empty scope.
  TimeScaleTimeOptionsScope();

  @override
  ScopeKind get kind => ScopeKind.timeScaleTimeOptions;

  Opt<Object>? _parser;

  /// The cell of `parser`, or Dart `null` when absent.
  Opt<Object>? get parserCell => _parser;

  /// Stores the cell of `parser`. Dart `null` deletes the key.
  set parserCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.parser);
    } else {
      store(OptionKey.parser, cell);
    }
  }

  /// Stores the plain value [value] of `parser`.
  set parser(Object value) =>
      store(OptionKey.parser, classify(OptionKey.parser, value));

  Opt<Object>? _round;

  /// The cell of `round`, or Dart `null` when absent.
  Opt<Object>? get roundCell => _round;

  /// Stores the cell of `round`. Dart `null` deletes the key.
  set roundCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.round);
    } else {
      store(OptionKey.round, cell);
    }
  }

  /// Stores the plain value [value] of `round`.
  set round(Object value) =>
      store(OptionKey.round, classify(OptionKey.round, value));

  Opt<Object>? _isoWeekday;

  /// The cell of `isoWeekday`, or Dart `null` when absent.
  Opt<Object>? get isoWeekdayCell => _isoWeekday;

  /// Stores the cell of `isoWeekday`. Dart `null` deletes the key.
  set isoWeekdayCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.isoWeekday);
    } else {
      store(OptionKey.isoWeekday, cell);
    }
  }

  /// Stores the plain value [value] of `isoWeekday`.
  set isoWeekday(Object value) =>
      store(OptionKey.isoWeekday, classify(OptionKey.isoWeekday, value));

  Opt<DisplayFormatsScope>? _displayFormats;

  /// The cell of `displayFormats`, or Dart `null` when absent.
  Opt<DisplayFormatsScope>? get displayFormatsCell => _displayFormats;

  /// Stores the cell of `displayFormats`. Dart `null` deletes the key.
  set displayFormatsCell(Opt<DisplayFormatsScope>? cell) {
    if (cell == null) {
      delete(OptionKey.displayFormats);
    } else {
      store(OptionKey.displayFormats, cell);
    }
  }

  /// Stores the plain value [value] of `displayFormats`.
  set displayFormats(DisplayFormatsScope value) =>
      store(OptionKey.displayFormats, OptScope<DisplayFormatsScope>(value));

  Opt<String>? _tooltipFormat;

  /// The cell of `tooltipFormat`, or Dart `null` when absent.
  Opt<String>? get tooltipFormatCell => _tooltipFormat;

  /// Stores the cell of `tooltipFormat`. Dart `null` deletes the key.
  set tooltipFormatCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.tooltipFormat);
    } else {
      store(OptionKey.tooltipFormat, cell);
    }
  }

  /// Stores the plain value [value] of `tooltipFormat`.
  set tooltipFormat(String value) =>
      store(OptionKey.tooltipFormat, OptValue<String>(value));

  Opt<Object>? _unit;

  /// The cell of `unit`, or Dart `null` when absent.
  Opt<Object>? get unitCell => _unit;

  /// Stores the cell of `unit`. Dart `null` deletes the key.
  set unitCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.unit);
    } else {
      store(OptionKey.unit, cell);
    }
  }

  /// Stores the plain value [value] of `unit`.
  set unit(Object value) =>
      store(OptionKey.unit, classify(OptionKey.unit, value));

  Opt<String>? _minUnit;

  /// The cell of `minUnit`, or Dart `null` when absent.
  Opt<String>? get minUnitCell => _minUnit;

  /// Stores the cell of `minUnit`. Dart `null` deletes the key.
  set minUnitCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.minUnit);
    } else {
      store(OptionKey.minUnit, cell);
    }
  }

  /// Stores the plain value [value] of `minUnit`.
  set minUnit(String value) =>
      store(OptionKey.minUnit, OptValue<String>(value));

  @override
  Opt<Object?>? cellOf(OptionKey key) => switch (key) {
    OptionKey.parser => _parser,
    OptionKey.round => _round,
    OptionKey.isoWeekday => _isoWeekday,
    OptionKey.displayFormats => _displayFormats,
    OptionKey.tooltipFormat => _tooltipFormat,
    OptionKey.unit => _unit,
    OptionKey.minUnit => _minUnit,
    _ => null,
  };

  @override
  void setCell(OptionKey key, Opt<Object?>? cell) {
    switch (key) {
      case OptionKey.parser:
        _parser = fitCell(cell, (raw) => classifyUnion(raw, 14));
      case OptionKey.round:
        _round = fitCell(cell, (raw) => classifyUnion(raw, 6));
      case OptionKey.isoWeekday:
        _isoWeekday = fitCell(cell, (raw) => classifyUnion(raw, 3));
      case OptionKey.displayFormats:
        _displayFormats = fitCell(cell, classifyScope<DisplayFormatsScope>);
      case OptionKey.tooltipFormat:
        _tooltipFormat = fitCell(cell, classifyString);
      case OptionKey.unit:
        _unit = fitCell(cell, (raw) => classifyUnion(raw, 6));
      case OptionKey.minUnit:
        _minUnit = fitCell(cell, classifyString);
      default:
        throw ArgumentError.value(
          key,
          'key',
          'Not a key of TimeScaleTimeOptions',
        );
    }
  }

  @override
  bool hasField(OptionKey key) => switch (key) {
    OptionKey.parser ||
    OptionKey.round ||
    OptionKey.isoWeekday ||
    OptionKey.displayFormats ||
    OptionKey.tooltipFormat ||
    OptionKey.unit ||
    OptionKey.minUnit => true,
    _ => false,
  };

  @override
  Opt<Object?> classify(OptionKey key, Object? raw) => switch (key) {
    OptionKey.parser => classifyUnion(raw, 14),
    OptionKey.round => classifyUnion(raw, 6),
    OptionKey.isoWeekday => classifyUnion(raw, 3),
    OptionKey.displayFormats => classifyScope<DisplayFormatsScope>(raw),
    OptionKey.tooltipFormat => classifyString(raw),
    OptionKey.unit => classifyUnion(raw, 6),
    OptionKey.minUnit => classifyString(raw),
    _ => kind.classifyOther(raw),
  };
}

/// Port-only name for index.d.ts:3447 TimeScaleTimeOptions `displayFormats`,
/// the format of each time unit (the keys of core.adapters.ts:22 formats).
base class DisplayFormatsScope extends OptionScope {
  /// An empty scope.
  DisplayFormatsScope();

  @override
  ScopeKind get kind => ScopeKind.displayFormats;

  Opt<String>? _datetime;

  /// The cell of `datetime`, or Dart `null` when absent.
  Opt<String>? get datetimeCell => _datetime;

  /// Stores the cell of `datetime`. Dart `null` deletes the key.
  set datetimeCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.datetime);
    } else {
      store(OptionKey.datetime, cell);
    }
  }

  /// Stores the plain value [value] of `datetime`.
  set datetime(String value) =>
      store(OptionKey.datetime, OptValue<String>(value));

  Opt<String>? _millisecond;

  /// The cell of `millisecond`, or Dart `null` when absent.
  Opt<String>? get millisecondCell => _millisecond;

  /// Stores the cell of `millisecond`. Dart `null` deletes the key.
  set millisecondCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.millisecond);
    } else {
      store(OptionKey.millisecond, cell);
    }
  }

  /// Stores the plain value [value] of `millisecond`.
  set millisecond(String value) =>
      store(OptionKey.millisecond, OptValue<String>(value));

  Opt<String>? _second;

  /// The cell of `second`, or Dart `null` when absent.
  Opt<String>? get secondCell => _second;

  /// Stores the cell of `second`. Dart `null` deletes the key.
  set secondCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.second);
    } else {
      store(OptionKey.second, cell);
    }
  }

  /// Stores the plain value [value] of `second`.
  set second(String value) => store(OptionKey.second, OptValue<String>(value));

  Opt<String>? _minute;

  /// The cell of `minute`, or Dart `null` when absent.
  Opt<String>? get minuteCell => _minute;

  /// Stores the cell of `minute`. Dart `null` deletes the key.
  set minuteCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.minute);
    } else {
      store(OptionKey.minute, cell);
    }
  }

  /// Stores the plain value [value] of `minute`.
  set minute(String value) => store(OptionKey.minute, OptValue<String>(value));

  Opt<String>? _hour;

  /// The cell of `hour`, or Dart `null` when absent.
  Opt<String>? get hourCell => _hour;

  /// Stores the cell of `hour`. Dart `null` deletes the key.
  set hourCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.hour);
    } else {
      store(OptionKey.hour, cell);
    }
  }

  /// Stores the plain value [value] of `hour`.
  set hour(String value) => store(OptionKey.hour, OptValue<String>(value));

  Opt<String>? _day;

  /// The cell of `day`, or Dart `null` when absent.
  Opt<String>? get dayCell => _day;

  /// Stores the cell of `day`. Dart `null` deletes the key.
  set dayCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.day);
    } else {
      store(OptionKey.day, cell);
    }
  }

  /// Stores the plain value [value] of `day`.
  set day(String value) => store(OptionKey.day, OptValue<String>(value));

  Opt<String>? _week;

  /// The cell of `week`, or Dart `null` when absent.
  Opt<String>? get weekCell => _week;

  /// Stores the cell of `week`. Dart `null` deletes the key.
  set weekCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.week);
    } else {
      store(OptionKey.week, cell);
    }
  }

  /// Stores the plain value [value] of `week`.
  set week(String value) => store(OptionKey.week, OptValue<String>(value));

  Opt<String>? _month;

  /// The cell of `month`, or Dart `null` when absent.
  Opt<String>? get monthCell => _month;

  /// Stores the cell of `month`. Dart `null` deletes the key.
  set monthCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.month);
    } else {
      store(OptionKey.month, cell);
    }
  }

  /// Stores the plain value [value] of `month`.
  set month(String value) => store(OptionKey.month, OptValue<String>(value));

  Opt<String>? _quarter;

  /// The cell of `quarter`, or Dart `null` when absent.
  Opt<String>? get quarterCell => _quarter;

  /// Stores the cell of `quarter`. Dart `null` deletes the key.
  set quarterCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.quarter);
    } else {
      store(OptionKey.quarter, cell);
    }
  }

  /// Stores the plain value [value] of `quarter`.
  set quarter(String value) =>
      store(OptionKey.quarter, OptValue<String>(value));

  Opt<String>? _year;

  /// The cell of `year`, or Dart `null` when absent.
  Opt<String>? get yearCell => _year;

  /// Stores the cell of `year`. Dart `null` deletes the key.
  set yearCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.year);
    } else {
      store(OptionKey.year, cell);
    }
  }

  /// Stores the plain value [value] of `year`.
  set year(String value) => store(OptionKey.year, OptValue<String>(value));

  @override
  Opt<Object?>? cellOf(OptionKey key) => switch (key) {
    OptionKey.datetime => _datetime,
    OptionKey.millisecond => _millisecond,
    OptionKey.second => _second,
    OptionKey.minute => _minute,
    OptionKey.hour => _hour,
    OptionKey.day => _day,
    OptionKey.week => _week,
    OptionKey.month => _month,
    OptionKey.quarter => _quarter,
    OptionKey.year => _year,
    _ => null,
  };

  @override
  void setCell(OptionKey key, Opt<Object?>? cell) {
    switch (key) {
      case OptionKey.datetime:
        _datetime = fitCell(cell, classifyString);
      case OptionKey.millisecond:
        _millisecond = fitCell(cell, classifyString);
      case OptionKey.second:
        _second = fitCell(cell, classifyString);
      case OptionKey.minute:
        _minute = fitCell(cell, classifyString);
      case OptionKey.hour:
        _hour = fitCell(cell, classifyString);
      case OptionKey.day:
        _day = fitCell(cell, classifyString);
      case OptionKey.week:
        _week = fitCell(cell, classifyString);
      case OptionKey.month:
        _month = fitCell(cell, classifyString);
      case OptionKey.quarter:
        _quarter = fitCell(cell, classifyString);
      case OptionKey.year:
        _year = fitCell(cell, classifyString);
      default:
        throw ArgumentError.value(key, 'key', 'Not a key of DisplayFormats');
    }
  }

  @override
  bool hasField(OptionKey key) => switch (key) {
    OptionKey.datetime ||
    OptionKey.millisecond ||
    OptionKey.second ||
    OptionKey.minute ||
    OptionKey.hour ||
    OptionKey.day ||
    OptionKey.week ||
    OptionKey.month ||
    OptionKey.quarter ||
    OptionKey.year => true,
    _ => false,
  };

  @override
  Opt<Object?> classify(OptionKey key, Object? raw) => switch (key) {
    OptionKey.datetime => classifyString(raw),
    OptionKey.millisecond => classifyString(raw),
    OptionKey.second => classifyString(raw),
    OptionKey.minute => classifyString(raw),
    OptionKey.hour => classifyString(raw),
    OptionKey.day => classifyString(raw),
    OptionKey.week => classifyString(raw),
    OptionKey.month => classifyString(raw),
    OptionKey.quarter => classifyString(raw),
    OptionKey.year => classifyString(raw),
    _ => kind.classifyOther(raw),
  };
}

/// Port-only name for index.d.ts:3568 RadialLinearScaleOptions `angleLines`,
/// the angle lines of a radial scale.
base class AngleLineOptionsScope extends OptionScope {
  /// An empty scope.
  AngleLineOptionsScope();

  @override
  ScopeKind get kind => ScopeKind.angleLineOptions;

  Opt<bool>? _display;

  /// The cell of `display`, or Dart `null` when absent.
  Opt<bool>? get displayCell => _display;

  /// Stores the cell of `display`. Dart `null` deletes the key.
  set displayCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.display);
    } else {
      store(OptionKey.display, cell);
    }
  }

  /// Stores the plain value [value] of `display`.
  set display(bool value) => store(OptionKey.display, OptValue<bool>(value));

  Opt<Object>? _color;

  /// The cell of `color`, or Dart `null` when absent.
  Opt<Object>? get colorCell => _color;

  /// Stores the cell of `color`. Dart `null` deletes the key.
  set colorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.color);
    } else {
      store(OptionKey.color, cell);
    }
  }

  /// Stores the plain value [value] of `color`.
  set color(Object value) =>
      store(OptionKey.color, classify(OptionKey.color, value));

  Opt<double>? _lineWidth;

  /// The cell of `lineWidth`, or Dart `null` when absent.
  Opt<double>? get lineWidthCell => _lineWidth;

  /// Stores the cell of `lineWidth`. Dart `null` deletes the key.
  set lineWidthCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.lineWidth);
    } else {
      store(OptionKey.lineWidth, cell);
    }
  }

  /// Stores the plain value [value] of `lineWidth`.
  set lineWidth(double value) =>
      store(OptionKey.lineWidth, OptValue<double>(value));

  Opt<Object>? _borderDash;

  /// The cell of `borderDash`, or Dart `null` when absent.
  Opt<Object>? get borderDashCell => _borderDash;

  /// Stores the cell of `borderDash`. Dart `null` deletes the key.
  set borderDashCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.borderDash);
    } else {
      store(OptionKey.borderDash, cell);
    }
  }

  /// Stores the plain value [value] of `borderDash`.
  set borderDash(Object value) =>
      store(OptionKey.borderDash, classify(OptionKey.borderDash, value));

  Opt<double>? _borderDashOffset;

  /// The cell of `borderDashOffset`, or Dart `null` when absent.
  Opt<double>? get borderDashOffsetCell => _borderDashOffset;

  /// Stores the cell of `borderDashOffset`. Dart `null` deletes the key.
  set borderDashOffsetCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.borderDashOffset);
    } else {
      store(OptionKey.borderDashOffset, cell);
    }
  }

  /// Stores the plain value [value] of `borderDashOffset`.
  set borderDashOffset(double value) =>
      store(OptionKey.borderDashOffset, OptValue<double>(value));

  @override
  Opt<Object?>? cellOf(OptionKey key) => switch (key) {
    OptionKey.display => _display,
    OptionKey.color => _color,
    OptionKey.lineWidth => _lineWidth,
    OptionKey.borderDash => _borderDash,
    OptionKey.borderDashOffset => _borderDashOffset,
    _ => null,
  };

  @override
  void setCell(OptionKey key, Opt<Object?>? cell) {
    switch (key) {
      case OptionKey.display:
        _display = fitCell(cell, classifyBool);
      case OptionKey.color:
        _color = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.lineWidth:
        _lineWidth = fitCell(cell, classifyNumber);
      case OptionKey.borderDash:
        _borderDash = fitCell(cell, (raw) => classifyUnion(raw, 16));
      case OptionKey.borderDashOffset:
        _borderDashOffset = fitCell(cell, classifyNumber);
      default:
        throw ArgumentError.value(key, 'key', 'Not a key of AngleLineOptions');
    }
  }

  @override
  bool hasField(OptionKey key) => switch (key) {
    OptionKey.display ||
    OptionKey.color ||
    OptionKey.lineWidth ||
    OptionKey.borderDash ||
    OptionKey.borderDashOffset => true,
    _ => false,
  };

  @override
  Opt<Object?> classify(OptionKey key, Object? raw) => switch (key) {
    OptionKey.display => classifyBool(raw),
    OptionKey.color => classifyUnion(raw, 64),
    OptionKey.lineWidth => classifyNumber(raw),
    OptionKey.borderDash => classifyUnion(raw, 16),
    OptionKey.borderDashOffset => classifyNumber(raw),
    _ => kind.classifyOther(raw),
  };
}

/// Port-only name for index.d.ts:3613 RadialLinearScaleOptions `pointLabels`,
/// the point labels of a radial scale.
base class PointLabelOptionsScope extends OptionScope {
  /// An empty scope.
  PointLabelOptionsScope();

  @override
  ScopeKind get kind => ScopeKind.pointLabelOptions;

  Opt<Object>? _backdropColor;

  /// The cell of `backdropColor`, or Dart `null` when absent.
  Opt<Object>? get backdropColorCell => _backdropColor;

  /// Stores the cell of `backdropColor`. Dart `null` deletes the key.
  set backdropColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.backdropColor);
    } else {
      store(OptionKey.backdropColor, cell);
    }
  }

  /// Stores the plain value [value] of `backdropColor`.
  set backdropColor(Object value) =>
      store(OptionKey.backdropColor, classify(OptionKey.backdropColor, value));

  Opt<Object>? _backdropPadding;

  /// The cell of `backdropPadding`, or Dart `null` when absent.
  Opt<Object>? get backdropPaddingCell => _backdropPadding;

  /// Stores the cell of `backdropPadding`. Dart `null` deletes the key.
  set backdropPaddingCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.backdropPadding);
    } else {
      store(OptionKey.backdropPadding, cell);
    }
  }

  /// Stores the plain value [value] of `backdropPadding`.
  set backdropPadding(Object value) => store(
    OptionKey.backdropPadding,
    classify(OptionKey.backdropPadding, value),
  );

  Opt<Object>? _borderRadius;

  /// The cell of `borderRadius`, or Dart `null` when absent.
  Opt<Object>? get borderRadiusCell => _borderRadius;

  /// Stores the cell of `borderRadius`. Dart `null` deletes the key.
  set borderRadiusCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.borderRadius);
    } else {
      store(OptionKey.borderRadius, cell);
    }
  }

  /// Stores the plain value [value] of `borderRadius`.
  set borderRadius(Object value) =>
      store(OptionKey.borderRadius, classify(OptionKey.borderRadius, value));

  Opt<Object>? _display;

  /// The cell of `display`, or Dart `null` when absent.
  Opt<Object>? get displayCell => _display;

  /// Stores the cell of `display`. Dart `null` deletes the key.
  set displayCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.display);
    } else {
      store(OptionKey.display, cell);
    }
  }

  /// Stores the plain value [value] of `display`.
  set display(Object value) =>
      store(OptionKey.display, classify(OptionKey.display, value));

  Opt<Object>? _color;

  /// The cell of `color`, or Dart `null` when absent.
  Opt<Object>? get colorCell => _color;

  /// Stores the cell of `color`. Dart `null` deletes the key.
  set colorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.color);
    } else {
      store(OptionKey.color, cell);
    }
  }

  /// Stores the plain value [value] of `color`.
  set color(Object value) =>
      store(OptionKey.color, classify(OptionKey.color, value));

  Opt<FontSpecScope>? _font;

  /// The cell of `font`, or Dart `null` when absent.
  Opt<FontSpecScope>? get fontCell => _font;

  /// Stores the cell of `font`. Dart `null` deletes the key.
  set fontCell(Opt<FontSpecScope>? cell) {
    if (cell == null) {
      delete(OptionKey.font);
    } else {
      store(OptionKey.font, cell);
    }
  }

  /// Stores the plain value [value] of `font`.
  set font(FontSpecScope value) =>
      store(OptionKey.font, OptScope<FontSpecScope>(value));

  Opt<Object>? _callback;

  /// The cell of `callback`, or Dart `null` when absent.
  Opt<Object>? get callbackCell => _callback;

  /// Stores the cell of `callback`. Dart `null` deletes the key.
  set callbackCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.callback);
    } else {
      store(OptionKey.callback, cell);
    }
  }

  /// Stores the plain value [value] of `callback`.
  set callback(Object value) =>
      store(OptionKey.callback, classify(OptionKey.callback, value));

  Opt<double>? _padding;

  /// The cell of `padding`, or Dart `null` when absent.
  Opt<double>? get paddingCell => _padding;

  /// Stores the cell of `padding`. Dart `null` deletes the key.
  set paddingCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.padding);
    } else {
      store(OptionKey.padding, cell);
    }
  }

  /// Stores the plain value [value] of `padding`.
  set padding(double value) =>
      store(OptionKey.padding, OptValue<double>(value));

  Opt<bool>? _centerPointLabels;

  /// The cell of `centerPointLabels`, or Dart `null` when absent.
  Opt<bool>? get centerPointLabelsCell => _centerPointLabels;

  /// Stores the cell of `centerPointLabels`. Dart `null` deletes the key.
  set centerPointLabelsCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.centerPointLabels);
    } else {
      store(OptionKey.centerPointLabels, cell);
    }
  }

  /// Stores the plain value [value] of `centerPointLabels`.
  set centerPointLabels(bool value) =>
      store(OptionKey.centerPointLabels, OptValue<bool>(value));

  @override
  Opt<Object?>? cellOf(OptionKey key) => switch (key) {
    OptionKey.backdropColor => _backdropColor,
    OptionKey.backdropPadding => _backdropPadding,
    OptionKey.borderRadius => _borderRadius,
    OptionKey.display => _display,
    OptionKey.color => _color,
    OptionKey.font => _font,
    OptionKey.callback => _callback,
    OptionKey.padding => _padding,
    OptionKey.centerPointLabels => _centerPointLabels,
    _ => null,
  };

  @override
  void setCell(OptionKey key, Opt<Object?>? cell) {
    switch (key) {
      case OptionKey.backdropColor:
        _backdropColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.backdropPadding:
        _backdropPadding = fitCell(cell, (raw) => classifyUnion(raw, 33));
      case OptionKey.borderRadius:
        _borderRadius = fitCell(cell, (raw) => classifyUnion(raw, 33));
      case OptionKey.display:
        _display = fitCell(cell, (raw) => classifyUnion(raw, 6));
      case OptionKey.color:
        _color = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.font:
        _font = fitCell(cell, classifyScope<FontSpecScope>);
      case OptionKey.callback:
        _callback = fitCell(cell, (raw) => classifyUnion(raw, 8));
      case OptionKey.padding:
        _padding = fitCell(cell, classifyNumber);
      case OptionKey.centerPointLabels:
        _centerPointLabels = fitCell(cell, classifyBool);
      default:
        throw ArgumentError.value(key, 'key', 'Not a key of PointLabelOptions');
    }
  }

  @override
  bool hasField(OptionKey key) => switch (key) {
    OptionKey.backdropColor ||
    OptionKey.backdropPadding ||
    OptionKey.borderRadius ||
    OptionKey.display ||
    OptionKey.color ||
    OptionKey.font ||
    OptionKey.callback ||
    OptionKey.padding ||
    OptionKey.centerPointLabels => true,
    _ => false,
  };

  @override
  Opt<Object?> classify(OptionKey key, Object? raw) => switch (key) {
    OptionKey.backdropColor => classifyUnion(raw, 64),
    OptionKey.backdropPadding => classifyUnion(raw, 33),
    OptionKey.borderRadius => classifyUnion(raw, 33),
    OptionKey.display => classifyUnion(raw, 6),
    OptionKey.color => classifyUnion(raw, 64),
    OptionKey.font => classifyScope<FontSpecScope>(raw),
    OptionKey.callback => classifyUnion(raw, 8),
    OptionKey.padding => classifyNumber(raw),
    OptionKey.centerPointLabels => classifyBool(raw),
    _ => kind.classifyOther(raw),
  };
}

/// index.d.ts:2422 LegendOptions, the scope `plugins.legend`.
base class LegendOptionsScope extends OptionScope {
  /// An empty scope.
  LegendOptionsScope();

  @override
  ScopeKind get kind => ScopeKind.legendOptions;

  Opt<bool>? _display;

  /// The cell of `display`, or Dart `null` when absent.
  Opt<bool>? get displayCell => _display;

  /// Stores the cell of `display`. Dart `null` deletes the key.
  set displayCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.display);
    } else {
      store(OptionKey.display, cell);
    }
  }

  /// Stores the plain value [value] of `display`.
  set display(bool value) => store(OptionKey.display, OptValue<bool>(value));

  Opt<Object>? _position;

  /// The cell of `position`, or Dart `null` when absent.
  Opt<Object>? get positionCell => _position;

  /// Stores the cell of `position`. Dart `null` deletes the key.
  set positionCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.position);
    } else {
      store(OptionKey.position, cell);
    }
  }

  /// Stores the plain value [value] of `position`.
  set position(Object value) =>
      store(OptionKey.position, classify(OptionKey.position, value));

  Opt<String>? _align;

  /// The cell of `align`, or Dart `null` when absent.
  Opt<String>? get alignCell => _align;

  /// Stores the cell of `align`. Dart `null` deletes the key.
  set alignCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.align);
    } else {
      store(OptionKey.align, cell);
    }
  }

  /// Stores the plain value [value] of `align`.
  set align(String value) => store(OptionKey.align, OptValue<String>(value));

  Opt<double>? _maxHeight;

  /// The cell of `maxHeight`, or Dart `null` when absent.
  Opt<double>? get maxHeightCell => _maxHeight;

  /// Stores the cell of `maxHeight`. Dart `null` deletes the key.
  set maxHeightCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.maxHeight);
    } else {
      store(OptionKey.maxHeight, cell);
    }
  }

  /// Stores the plain value [value] of `maxHeight`.
  set maxHeight(double value) =>
      store(OptionKey.maxHeight, OptValue<double>(value));

  Opt<double>? _maxWidth;

  /// The cell of `maxWidth`, or Dart `null` when absent.
  Opt<double>? get maxWidthCell => _maxWidth;

  /// Stores the cell of `maxWidth`. Dart `null` deletes the key.
  set maxWidthCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.maxWidth);
    } else {
      store(OptionKey.maxWidth, cell);
    }
  }

  /// Stores the plain value [value] of `maxWidth`.
  set maxWidth(double value) =>
      store(OptionKey.maxWidth, OptValue<double>(value));

  Opt<bool>? _fullSize;

  /// The cell of `fullSize`, or Dart `null` when absent.
  Opt<bool>? get fullSizeCell => _fullSize;

  /// Stores the cell of `fullSize`. Dart `null` deletes the key.
  set fullSizeCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.fullSize);
    } else {
      store(OptionKey.fullSize, cell);
    }
  }

  /// Stores the plain value [value] of `fullSize`.
  set fullSize(bool value) => store(OptionKey.fullSize, OptValue<bool>(value));

  Opt<bool>? _reverse;

  /// The cell of `reverse`, or Dart `null` when absent.
  Opt<bool>? get reverseCell => _reverse;

  /// Stores the cell of `reverse`. Dart `null` deletes the key.
  set reverseCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.reverse);
    } else {
      store(OptionKey.reverse, cell);
    }
  }

  /// Stores the plain value [value] of `reverse`.
  set reverse(bool value) => store(OptionKey.reverse, OptValue<bool>(value));

  Opt<Object>? _onClick;

  /// The cell of `onClick`, or Dart `null` when absent.
  Opt<Object>? get onClickCell => _onClick;

  /// Stores the cell of `onClick`. Dart `null` deletes the key.
  set onClickCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.onClick);
    } else {
      store(OptionKey.onClick, cell);
    }
  }

  /// Stores the plain value [value] of `onClick`.
  set onClick(Object value) =>
      store(OptionKey.onClick, classify(OptionKey.onClick, value));

  Opt<Object>? _onHover;

  /// The cell of `onHover`, or Dart `null` when absent.
  Opt<Object>? get onHoverCell => _onHover;

  /// Stores the cell of `onHover`. Dart `null` deletes the key.
  set onHoverCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.onHover);
    } else {
      store(OptionKey.onHover, cell);
    }
  }

  /// Stores the plain value [value] of `onHover`.
  set onHover(Object value) =>
      store(OptionKey.onHover, classify(OptionKey.onHover, value));

  Opt<Object>? _onLeave;

  /// The cell of `onLeave`, or Dart `null` when absent.
  Opt<Object>? get onLeaveCell => _onLeave;

  /// Stores the cell of `onLeave`. Dart `null` deletes the key.
  set onLeaveCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.onLeave);
    } else {
      store(OptionKey.onLeave, cell);
    }
  }

  /// Stores the plain value [value] of `onLeave`.
  set onLeave(Object value) =>
      store(OptionKey.onLeave, classify(OptionKey.onLeave, value));

  Opt<LegendLabelOptionsScope>? _labels;

  /// The cell of `labels`, or Dart `null` when absent.
  Opt<LegendLabelOptionsScope>? get labelsCell => _labels;

  /// Stores the cell of `labels`. Dart `null` deletes the key.
  set labelsCell(Opt<LegendLabelOptionsScope>? cell) {
    if (cell == null) {
      delete(OptionKey.labels);
    } else {
      store(OptionKey.labels, cell);
    }
  }

  /// Stores the plain value [value] of `labels`.
  set labels(LegendLabelOptionsScope value) =>
      store(OptionKey.labels, OptScope<LegendLabelOptionsScope>(value));

  Opt<bool>? _rtl;

  /// The cell of `rtl`, or Dart `null` when absent.
  Opt<bool>? get rtlCell => _rtl;

  /// Stores the cell of `rtl`. Dart `null` deletes the key.
  set rtlCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.rtl);
    } else {
      store(OptionKey.rtl, cell);
    }
  }

  /// Stores the plain value [value] of `rtl`.
  set rtl(bool value) => store(OptionKey.rtl, OptValue<bool>(value));

  Opt<String>? _textDirection;

  /// The cell of `textDirection`, or Dart `null` when absent.
  Opt<String>? get textDirectionCell => _textDirection;

  /// Stores the cell of `textDirection`. Dart `null` deletes the key.
  set textDirectionCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.textDirection);
    } else {
      store(OptionKey.textDirection, cell);
    }
  }

  /// Stores the plain value [value] of `textDirection`.
  set textDirection(String value) =>
      store(OptionKey.textDirection, OptValue<String>(value));

  Opt<LegendTitleOptionsScope>? _title;

  /// The cell of `title`, or Dart `null` when absent.
  Opt<LegendTitleOptionsScope>? get titleCell => _title;

  /// Stores the cell of `title`. Dart `null` deletes the key.
  set titleCell(Opt<LegendTitleOptionsScope>? cell) {
    if (cell == null) {
      delete(OptionKey.title);
    } else {
      store(OptionKey.title, cell);
    }
  }

  /// Stores the plain value [value] of `title`.
  set title(LegendTitleOptionsScope value) =>
      store(OptionKey.title, OptScope<LegendTitleOptionsScope>(value));

  Opt<double>? _weight;

  /// The cell of `weight`, or Dart `null` when absent.
  Opt<double>? get weightCell => _weight;

  /// Stores the cell of `weight`. Dart `null` deletes the key.
  set weightCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.weight);
    } else {
      store(OptionKey.weight, cell);
    }
  }

  /// Stores the plain value [value] of `weight`.
  set weight(double value) => store(OptionKey.weight, OptValue<double>(value));

  Opt<Object>? _events;

  /// The cell of `events`, or Dart `null` when absent.
  Opt<Object>? get eventsCell => _events;

  /// Stores the cell of `events`. Dart `null` deletes the key.
  set eventsCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.events);
    } else {
      store(OptionKey.events, cell);
    }
  }

  /// Stores the plain value [value] of `events`.
  set events(Object value) =>
      store(OptionKey.events, classify(OptionKey.events, value));

  @override
  Opt<Object?>? cellOf(OptionKey key) => switch (key) {
    OptionKey.display => _display,
    OptionKey.position => _position,
    OptionKey.align => _align,
    OptionKey.maxHeight => _maxHeight,
    OptionKey.maxWidth => _maxWidth,
    OptionKey.fullSize => _fullSize,
    OptionKey.reverse => _reverse,
    OptionKey.onClick => _onClick,
    OptionKey.onHover => _onHover,
    OptionKey.onLeave => _onLeave,
    OptionKey.labels => _labels,
    OptionKey.rtl => _rtl,
    OptionKey.textDirection => _textDirection,
    OptionKey.title => _title,
    OptionKey.weight => _weight,
    OptionKey.events => _events,
    _ => null,
  };

  @override
  void setCell(OptionKey key, Opt<Object?>? cell) {
    switch (key) {
      case OptionKey.display:
        _display = fitCell(cell, classifyBool);
      case OptionKey.position:
        _position = fitCell(cell, (raw) => classifyUnion(raw, 36));
      case OptionKey.align:
        _align = fitCell(cell, classifyString);
      case OptionKey.maxHeight:
        _maxHeight = fitCell(cell, classifyNumber);
      case OptionKey.maxWidth:
        _maxWidth = fitCell(cell, classifyNumber);
      case OptionKey.fullSize:
        _fullSize = fitCell(cell, classifyBool);
      case OptionKey.reverse:
        _reverse = fitCell(cell, classifyBool);
      case OptionKey.onClick:
        _onClick = fitCell(cell, (raw) => classifyUnion(raw, 8));
      case OptionKey.onHover:
        _onHover = fitCell(cell, (raw) => classifyUnion(raw, 8));
      case OptionKey.onLeave:
        _onLeave = fitCell(cell, (raw) => classifyUnion(raw, 8));
      case OptionKey.labels:
        _labels = fitCell(cell, classifyScope<LegendLabelOptionsScope>);
      case OptionKey.rtl:
        _rtl = fitCell(cell, classifyBool);
      case OptionKey.textDirection:
        _textDirection = fitCell(cell, classifyString);
      case OptionKey.title:
        _title = fitCell(cell, classifyScope<LegendTitleOptionsScope>);
      case OptionKey.weight:
        _weight = fitCell(cell, classifyNumber);
      case OptionKey.events:
        _events = fitCell(cell, (raw) => classifyUnion(raw, 16));
      default:
        throw ArgumentError.value(key, 'key', 'Not a key of LegendOptions');
    }
  }

  @override
  bool hasField(OptionKey key) => switch (key) {
    OptionKey.display ||
    OptionKey.position ||
    OptionKey.align ||
    OptionKey.maxHeight ||
    OptionKey.maxWidth ||
    OptionKey.fullSize ||
    OptionKey.reverse ||
    OptionKey.onClick ||
    OptionKey.onHover ||
    OptionKey.onLeave ||
    OptionKey.labels ||
    OptionKey.rtl ||
    OptionKey.textDirection ||
    OptionKey.title ||
    OptionKey.weight ||
    OptionKey.events => true,
    _ => false,
  };

  @override
  Opt<Object?> classify(OptionKey key, Object? raw) => switch (key) {
    OptionKey.display => classifyBool(raw),
    OptionKey.position => classifyUnion(raw, 36),
    OptionKey.align => classifyString(raw),
    OptionKey.maxHeight => classifyNumber(raw),
    OptionKey.maxWidth => classifyNumber(raw),
    OptionKey.fullSize => classifyBool(raw),
    OptionKey.reverse => classifyBool(raw),
    OptionKey.onClick => classifyUnion(raw, 8),
    OptionKey.onHover => classifyUnion(raw, 8),
    OptionKey.onLeave => classifyUnion(raw, 8),
    OptionKey.labels => classifyScope<LegendLabelOptionsScope>(raw),
    OptionKey.rtl => classifyBool(raw),
    OptionKey.textDirection => classifyString(raw),
    OptionKey.title => classifyScope<LegendTitleOptionsScope>(raw),
    OptionKey.weight => classifyNumber(raw),
    OptionKey.events => classifyUnion(raw, 16),
    _ => kind.classifyOther(raw),
  };
}

/// Port-only name for index.d.ts:2469 LegendOptions `labels`, the labels of the
/// legend.
base class LegendLabelOptionsScope extends OptionScope {
  /// An empty scope.
  LegendLabelOptionsScope();

  @override
  ScopeKind get kind => ScopeKind.legendLabelOptions;

  Opt<double>? _boxWidth;

  /// The cell of `boxWidth`, or Dart `null` when absent.
  Opt<double>? get boxWidthCell => _boxWidth;

  /// Stores the cell of `boxWidth`. Dart `null` deletes the key.
  set boxWidthCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.boxWidth);
    } else {
      store(OptionKey.boxWidth, cell);
    }
  }

  /// Stores the plain value [value] of `boxWidth`.
  set boxWidth(double value) =>
      store(OptionKey.boxWidth, OptValue<double>(value));

  Opt<double>? _boxHeight;

  /// The cell of `boxHeight`, or Dart `null` when absent.
  Opt<double>? get boxHeightCell => _boxHeight;

  /// Stores the cell of `boxHeight`. Dart `null` deletes the key.
  set boxHeightCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.boxHeight);
    } else {
      store(OptionKey.boxHeight, cell);
    }
  }

  /// Stores the plain value [value] of `boxHeight`.
  set boxHeight(double value) =>
      store(OptionKey.boxHeight, OptValue<double>(value));

  Opt<Object>? _color;

  /// The cell of `color`, or Dart `null` when absent.
  Opt<Object>? get colorCell => _color;

  /// Stores the cell of `color`. Dart `null` deletes the key.
  set colorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.color);
    } else {
      store(OptionKey.color, cell);
    }
  }

  /// Stores the plain value [value] of `color`.
  set color(Object value) =>
      store(OptionKey.color, classify(OptionKey.color, value));

  Opt<FontSpecScope>? _font;

  /// The cell of `font`, or Dart `null` when absent.
  Opt<FontSpecScope>? get fontCell => _font;

  /// Stores the cell of `font`. Dart `null` deletes the key.
  set fontCell(Opt<FontSpecScope>? cell) {
    if (cell == null) {
      delete(OptionKey.font);
    } else {
      store(OptionKey.font, cell);
    }
  }

  /// Stores the plain value [value] of `font`.
  set font(FontSpecScope value) =>
      store(OptionKey.font, OptScope<FontSpecScope>(value));

  Opt<double>? _padding;

  /// The cell of `padding`, or Dart `null` when absent.
  Opt<double>? get paddingCell => _padding;

  /// Stores the cell of `padding`. Dart `null` deletes the key.
  set paddingCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.padding);
    } else {
      store(OptionKey.padding, cell);
    }
  }

  /// Stores the plain value [value] of `padding`.
  set padding(double value) =>
      store(OptionKey.padding, OptValue<double>(value));

  Opt<double>? _pointStyleWidth;

  /// The cell of `pointStyleWidth`, or Dart `null` when absent.
  Opt<double>? get pointStyleWidthCell => _pointStyleWidth;

  /// Stores the cell of `pointStyleWidth`. Dart `null` deletes the key.
  set pointStyleWidthCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.pointStyleWidth);
    } else {
      store(OptionKey.pointStyleWidth, cell);
    }
  }

  /// Stores the plain value [value] of `pointStyleWidth`.
  set pointStyleWidth(double value) =>
      store(OptionKey.pointStyleWidth, OptValue<double>(value));

  Opt<Object>? _generateLabels;

  /// The cell of `generateLabels`, or Dart `null` when absent.
  Opt<Object>? get generateLabelsCell => _generateLabels;

  /// Stores the cell of `generateLabels`. Dart `null` deletes the key.
  set generateLabelsCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.generateLabels);
    } else {
      store(OptionKey.generateLabels, cell);
    }
  }

  /// Stores the plain value [value] of `generateLabels`.
  set generateLabels(Object value) => store(
    OptionKey.generateLabels,
    classify(OptionKey.generateLabels, value),
  );

  Opt<Object>? _filter;

  /// The cell of `filter`, or Dart `null` when absent.
  Opt<Object>? get filterCell => _filter;

  /// Stores the cell of `filter`. Dart `null` deletes the key.
  set filterCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.filter);
    } else {
      store(OptionKey.filter, cell);
    }
  }

  /// Stores the plain value [value] of `filter`.
  set filter(Object value) =>
      store(OptionKey.filter, classify(OptionKey.filter, value));

  Opt<Object>? _sort;

  /// The cell of `sort`, or Dart `null` when absent.
  Opt<Object>? get sortCell => _sort;

  /// Stores the cell of `sort`. Dart `null` deletes the key.
  set sortCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.sort);
    } else {
      store(OptionKey.sort, cell);
    }
  }

  /// Stores the plain value [value] of `sort`.
  set sort(Object value) =>
      store(OptionKey.sort, classify(OptionKey.sort, value));

  Opt<Object>? _pointStyle;

  /// The cell of `pointStyle`, or Dart `null` when absent.
  Opt<Object>? get pointStyleCell => _pointStyle;

  /// Stores the cell of `pointStyle`. Dart `null` deletes the key.
  set pointStyleCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.pointStyle);
    } else {
      store(OptionKey.pointStyle, cell);
    }
  }

  /// Stores the plain value [value] of `pointStyle`.
  set pointStyle(Object value) =>
      store(OptionKey.pointStyle, classify(OptionKey.pointStyle, value));

  Opt<String>? _textAlign;

  /// The cell of `textAlign`, or Dart `null` when absent.
  Opt<String>? get textAlignCell => _textAlign;

  /// Stores the cell of `textAlign`. Dart `null` deletes the key.
  set textAlignCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.textAlign);
    } else {
      store(OptionKey.textAlign, cell);
    }
  }

  /// Stores the plain value [value] of `textAlign`.
  set textAlign(String value) =>
      store(OptionKey.textAlign, OptValue<String>(value));

  Opt<bool>? _usePointStyle;

  /// The cell of `usePointStyle`, or Dart `null` when absent.
  Opt<bool>? get usePointStyleCell => _usePointStyle;

  /// Stores the cell of `usePointStyle`. Dart `null` deletes the key.
  set usePointStyleCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.usePointStyle);
    } else {
      store(OptionKey.usePointStyle, cell);
    }
  }

  /// Stores the plain value [value] of `usePointStyle`.
  set usePointStyle(bool value) =>
      store(OptionKey.usePointStyle, OptValue<bool>(value));

  Opt<bool>? _useBorderRadius;

  /// The cell of `useBorderRadius`, or Dart `null` when absent.
  Opt<bool>? get useBorderRadiusCell => _useBorderRadius;

  /// Stores the cell of `useBorderRadius`. Dart `null` deletes the key.
  set useBorderRadiusCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.useBorderRadius);
    } else {
      store(OptionKey.useBorderRadius, cell);
    }
  }

  /// Stores the plain value [value] of `useBorderRadius`.
  set useBorderRadius(bool value) =>
      store(OptionKey.useBorderRadius, OptValue<bool>(value));

  Opt<double>? _borderRadius;

  /// The cell of `borderRadius`, or Dart `null` when absent.
  Opt<double>? get borderRadiusCell => _borderRadius;

  /// Stores the cell of `borderRadius`. Dart `null` deletes the key.
  set borderRadiusCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.borderRadius);
    } else {
      store(OptionKey.borderRadius, cell);
    }
  }

  /// Stores the plain value [value] of `borderRadius`.
  set borderRadius(double value) =>
      store(OptionKey.borderRadius, OptValue<double>(value));

  @override
  Opt<Object?>? cellOf(OptionKey key) => switch (key) {
    OptionKey.boxWidth => _boxWidth,
    OptionKey.boxHeight => _boxHeight,
    OptionKey.color => _color,
    OptionKey.font => _font,
    OptionKey.padding => _padding,
    OptionKey.pointStyleWidth => _pointStyleWidth,
    OptionKey.generateLabels => _generateLabels,
    OptionKey.filter => _filter,
    OptionKey.sort => _sort,
    OptionKey.pointStyle => _pointStyle,
    OptionKey.textAlign => _textAlign,
    OptionKey.usePointStyle => _usePointStyle,
    OptionKey.useBorderRadius => _useBorderRadius,
    OptionKey.borderRadius => _borderRadius,
    _ => null,
  };

  @override
  void setCell(OptionKey key, Opt<Object?>? cell) {
    switch (key) {
      case OptionKey.boxWidth:
        _boxWidth = fitCell(cell, classifyNumber);
      case OptionKey.boxHeight:
        _boxHeight = fitCell(cell, classifyNumber);
      case OptionKey.color:
        _color = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.font:
        _font = fitCell(cell, classifyScope<FontSpecScope>);
      case OptionKey.padding:
        _padding = fitCell(cell, classifyNumber);
      case OptionKey.pointStyleWidth:
        _pointStyleWidth = fitCell(cell, classifyNumber);
      case OptionKey.generateLabels:
        _generateLabels = fitCell(cell, (raw) => classifyUnion(raw, 8));
      case OptionKey.filter:
        _filter = fitCell(cell, (raw) => classifyUnion(raw, 8));
      case OptionKey.sort:
        _sort = fitCell(cell, (raw) => classifyUnion(raw, 8));
      case OptionKey.pointStyle:
        _pointStyle = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.textAlign:
        _textAlign = fitCell(cell, classifyString);
      case OptionKey.usePointStyle:
        _usePointStyle = fitCell(cell, classifyBool);
      case OptionKey.useBorderRadius:
        _useBorderRadius = fitCell(cell, classifyBool);
      case OptionKey.borderRadius:
        _borderRadius = fitCell(cell, classifyNumber);
      default:
        throw ArgumentError.value(
          key,
          'key',
          'Not a key of LegendLabelOptions',
        );
    }
  }

  @override
  bool hasField(OptionKey key) => switch (key) {
    OptionKey.boxWidth ||
    OptionKey.boxHeight ||
    OptionKey.color ||
    OptionKey.font ||
    OptionKey.padding ||
    OptionKey.pointStyleWidth ||
    OptionKey.generateLabels ||
    OptionKey.filter ||
    OptionKey.sort ||
    OptionKey.pointStyle ||
    OptionKey.textAlign ||
    OptionKey.usePointStyle ||
    OptionKey.useBorderRadius ||
    OptionKey.borderRadius => true,
    _ => false,
  };

  @override
  Opt<Object?> classify(OptionKey key, Object? raw) => switch (key) {
    OptionKey.boxWidth => classifyNumber(raw),
    OptionKey.boxHeight => classifyNumber(raw),
    OptionKey.color => classifyUnion(raw, 64),
    OptionKey.font => classifyScope<FontSpecScope>(raw),
    OptionKey.padding => classifyNumber(raw),
    OptionKey.pointStyleWidth => classifyNumber(raw),
    OptionKey.generateLabels => classifyUnion(raw, 8),
    OptionKey.filter => classifyUnion(raw, 8),
    OptionKey.sort => classifyUnion(raw, 8),
    OptionKey.pointStyle => classifyUnion(raw, 64),
    OptionKey.textAlign => classifyString(raw),
    OptionKey.usePointStyle => classifyBool(raw),
    OptionKey.useBorderRadius => classifyBool(raw),
    OptionKey.borderRadius => classifyNumber(raw),
    _ => kind.classifyOther(raw),
  };
}

/// Port-only name for index.d.ts:2552 LegendOptions `title`, the title of the
/// legend.
base class LegendTitleOptionsScope extends OptionScope {
  /// An empty scope.
  LegendTitleOptionsScope();

  @override
  ScopeKind get kind => ScopeKind.legendTitleOptions;

  Opt<bool>? _display;

  /// The cell of `display`, or Dart `null` when absent.
  Opt<bool>? get displayCell => _display;

  /// Stores the cell of `display`. Dart `null` deletes the key.
  set displayCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.display);
    } else {
      store(OptionKey.display, cell);
    }
  }

  /// Stores the plain value [value] of `display`.
  set display(bool value) => store(OptionKey.display, OptValue<bool>(value));

  Opt<Object>? _color;

  /// The cell of `color`, or Dart `null` when absent.
  Opt<Object>? get colorCell => _color;

  /// Stores the cell of `color`. Dart `null` deletes the key.
  set colorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.color);
    } else {
      store(OptionKey.color, cell);
    }
  }

  /// Stores the plain value [value] of `color`.
  set color(Object value) =>
      store(OptionKey.color, classify(OptionKey.color, value));

  Opt<FontSpecScope>? _font;

  /// The cell of `font`, or Dart `null` when absent.
  Opt<FontSpecScope>? get fontCell => _font;

  /// Stores the cell of `font`. Dart `null` deletes the key.
  set fontCell(Opt<FontSpecScope>? cell) {
    if (cell == null) {
      delete(OptionKey.font);
    } else {
      store(OptionKey.font, cell);
    }
  }

  /// Stores the plain value [value] of `font`.
  set font(FontSpecScope value) =>
      store(OptionKey.font, OptScope<FontSpecScope>(value));

  Opt<String>? _position;

  /// The cell of `position`, or Dart `null` when absent.
  Opt<String>? get positionCell => _position;

  /// Stores the cell of `position`. Dart `null` deletes the key.
  set positionCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.position);
    } else {
      store(OptionKey.position, cell);
    }
  }

  /// Stores the plain value [value] of `position`.
  set position(String value) =>
      store(OptionKey.position, OptValue<String>(value));

  Opt<Object>? _padding;

  /// The cell of `padding`, or Dart `null` when absent.
  Opt<Object>? get paddingCell => _padding;

  /// Stores the cell of `padding`. Dart `null` deletes the key.
  set paddingCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.padding);
    } else {
      store(OptionKey.padding, cell);
    }
  }

  /// Stores the plain value [value] of `padding`.
  set padding(Object value) =>
      store(OptionKey.padding, classify(OptionKey.padding, value));

  Opt<String>? _text;

  /// The cell of `text`, or Dart `null` when absent.
  Opt<String>? get textCell => _text;

  /// Stores the cell of `text`. Dart `null` deletes the key.
  set textCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.text);
    } else {
      store(OptionKey.text, cell);
    }
  }

  /// Stores the plain value [value] of `text`.
  set text(String value) => store(OptionKey.text, OptValue<String>(value));

  @override
  Opt<Object?>? cellOf(OptionKey key) => switch (key) {
    OptionKey.display => _display,
    OptionKey.color => _color,
    OptionKey.font => _font,
    OptionKey.position => _position,
    OptionKey.padding => _padding,
    OptionKey.text => _text,
    _ => null,
  };

  @override
  void setCell(OptionKey key, Opt<Object?>? cell) {
    switch (key) {
      case OptionKey.display:
        _display = fitCell(cell, classifyBool);
      case OptionKey.color:
        _color = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.font:
        _font = fitCell(cell, classifyScope<FontSpecScope>);
      case OptionKey.position:
        _position = fitCell(cell, classifyString);
      case OptionKey.padding:
        _padding = fitCell(cell, (raw) => classifyUnion(raw, 33));
      case OptionKey.text:
        _text = fitCell(cell, classifyString);
      default:
        throw ArgumentError.value(
          key,
          'key',
          'Not a key of LegendTitleOptions',
        );
    }
  }

  @override
  bool hasField(OptionKey key) => switch (key) {
    OptionKey.display ||
    OptionKey.color ||
    OptionKey.font ||
    OptionKey.position ||
    OptionKey.padding ||
    OptionKey.text => true,
    _ => false,
  };

  @override
  Opt<Object?> classify(OptionKey key, Object? raw) => switch (key) {
    OptionKey.display => classifyBool(raw),
    OptionKey.color => classifyUnion(raw, 64),
    OptionKey.font => classifyScope<FontSpecScope>(raw),
    OptionKey.position => classifyString(raw),
    OptionKey.padding => classifyUnion(raw, 33),
    OptionKey.text => classifyString(raw),
    _ => kind.classifyOther(raw),
  };
}

/// index.d.ts:2579 TitleOptions, the scopes `plugins.title` and
/// `plugins.subtitle`.
base class TitleOptionsScope extends OptionScope {
  /// An empty scope.
  TitleOptionsScope();

  @override
  ScopeKind get kind => ScopeKind.titleOptions;

  Opt<String>? _align;

  /// The cell of `align`, or Dart `null` when absent.
  Opt<String>? get alignCell => _align;

  /// Stores the cell of `align`. Dart `null` deletes the key.
  set alignCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.align);
    } else {
      store(OptionKey.align, cell);
    }
  }

  /// Stores the plain value [value] of `align`.
  set align(String value) => store(OptionKey.align, OptValue<String>(value));

  Opt<bool>? _display;

  /// The cell of `display`, or Dart `null` when absent.
  Opt<bool>? get displayCell => _display;

  /// Stores the cell of `display`. Dart `null` deletes the key.
  set displayCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.display);
    } else {
      store(OptionKey.display, cell);
    }
  }

  /// Stores the plain value [value] of `display`.
  set display(bool value) => store(OptionKey.display, OptValue<bool>(value));

  Opt<String>? _position;

  /// The cell of `position`, or Dart `null` when absent.
  Opt<String>? get positionCell => _position;

  /// Stores the cell of `position`. Dart `null` deletes the key.
  set positionCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.position);
    } else {
      store(OptionKey.position, cell);
    }
  }

  /// Stores the plain value [value] of `position`.
  set position(String value) =>
      store(OptionKey.position, OptValue<String>(value));

  Opt<Object>? _color;

  /// The cell of `color`, or Dart `null` when absent.
  Opt<Object>? get colorCell => _color;

  /// Stores the cell of `color`. Dart `null` deletes the key.
  set colorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.color);
    } else {
      store(OptionKey.color, cell);
    }
  }

  /// Stores the plain value [value] of `color`.
  set color(Object value) =>
      store(OptionKey.color, classify(OptionKey.color, value));

  Opt<FontSpecScope>? _font;

  /// The cell of `font`, or Dart `null` when absent.
  Opt<FontSpecScope>? get fontCell => _font;

  /// Stores the cell of `font`. Dart `null` deletes the key.
  set fontCell(Opt<FontSpecScope>? cell) {
    if (cell == null) {
      delete(OptionKey.font);
    } else {
      store(OptionKey.font, cell);
    }
  }

  /// Stores the plain value [value] of `font`.
  set font(FontSpecScope value) =>
      store(OptionKey.font, OptScope<FontSpecScope>(value));

  Opt<bool>? _fullSize;

  /// The cell of `fullSize`, or Dart `null` when absent.
  Opt<bool>? get fullSizeCell => _fullSize;

  /// Stores the cell of `fullSize`. Dart `null` deletes the key.
  set fullSizeCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.fullSize);
    } else {
      store(OptionKey.fullSize, cell);
    }
  }

  /// Stores the plain value [value] of `fullSize`.
  set fullSize(bool value) => store(OptionKey.fullSize, OptValue<bool>(value));

  Opt<Object>? _padding;

  /// The cell of `padding`, or Dart `null` when absent.
  Opt<Object>? get paddingCell => _padding;

  /// Stores the cell of `padding`. Dart `null` deletes the key.
  set paddingCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.padding);
    } else {
      store(OptionKey.padding, cell);
    }
  }

  /// Stores the plain value [value] of `padding`.
  set padding(Object value) =>
      store(OptionKey.padding, classify(OptionKey.padding, value));

  Opt<Object>? _text;

  /// The cell of `text`, or Dart `null` when absent.
  Opt<Object>? get textCell => _text;

  /// Stores the cell of `text`. Dart `null` deletes the key.
  set textCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.text);
    } else {
      store(OptionKey.text, cell);
    }
  }

  /// Stores the plain value [value] of `text`.
  set text(Object value) =>
      store(OptionKey.text, classify(OptionKey.text, value));

  Opt<double>? _weight;

  /// The cell of `weight`, or Dart `null` when absent.
  Opt<double>? get weightCell => _weight;

  /// Stores the cell of `weight`. Dart `null` deletes the key.
  set weightCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.weight);
    } else {
      store(OptionKey.weight, cell);
    }
  }

  /// Stores the plain value [value] of `weight`.
  set weight(double value) => store(OptionKey.weight, OptValue<double>(value));

  Opt<Object>? _events;

  /// The cell of `events`, or Dart `null` when absent.
  Opt<Object>? get eventsCell => _events;

  /// Stores the cell of `events`. Dart `null` deletes the key.
  set eventsCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.events);
    } else {
      store(OptionKey.events, cell);
    }
  }

  /// Stores the plain value [value] of `events`.
  set events(Object value) =>
      store(OptionKey.events, classify(OptionKey.events, value));

  @override
  Opt<Object?>? cellOf(OptionKey key) => switch (key) {
    OptionKey.align => _align,
    OptionKey.display => _display,
    OptionKey.position => _position,
    OptionKey.color => _color,
    OptionKey.font => _font,
    OptionKey.fullSize => _fullSize,
    OptionKey.padding => _padding,
    OptionKey.text => _text,
    OptionKey.weight => _weight,
    OptionKey.events => _events,
    _ => null,
  };

  @override
  void setCell(OptionKey key, Opt<Object?>? cell) {
    switch (key) {
      case OptionKey.align:
        _align = fitCell(cell, classifyString);
      case OptionKey.display:
        _display = fitCell(cell, classifyBool);
      case OptionKey.position:
        _position = fitCell(cell, classifyString);
      case OptionKey.color:
        _color = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.font:
        _font = fitCell(cell, classifyScope<FontSpecScope>);
      case OptionKey.fullSize:
        _fullSize = fitCell(cell, classifyBool);
      case OptionKey.padding:
        _padding = fitCell(cell, (raw) => classifyUnion(raw, 33));
      case OptionKey.text:
        _text = fitCell(cell, (raw) => classifyUnion(raw, 20));
      case OptionKey.weight:
        _weight = fitCell(cell, classifyNumber);
      case OptionKey.events:
        _events = fitCell(cell, (raw) => classifyUnion(raw, 16));
      default:
        throw ArgumentError.value(key, 'key', 'Not a key of TitleOptions');
    }
  }

  @override
  bool hasField(OptionKey key) => switch (key) {
    OptionKey.align ||
    OptionKey.display ||
    OptionKey.position ||
    OptionKey.color ||
    OptionKey.font ||
    OptionKey.fullSize ||
    OptionKey.padding ||
    OptionKey.text ||
    OptionKey.weight ||
    OptionKey.events => true,
    _ => false,
  };

  @override
  Opt<Object?> classify(OptionKey key, Object? raw) => switch (key) {
    OptionKey.align => classifyString(raw),
    OptionKey.display => classifyBool(raw),
    OptionKey.position => classifyString(raw),
    OptionKey.color => classifyUnion(raw, 64),
    OptionKey.font => classifyScope<FontSpecScope>(raw),
    OptionKey.fullSize => classifyBool(raw),
    OptionKey.padding => classifyUnion(raw, 33),
    OptionKey.text => classifyUnion(raw, 20),
    OptionKey.weight => classifyNumber(raw),
    OptionKey.events => classifyUnion(raw, 16),
    _ => kind.classifyOther(raw),
  };
}

/// index.d.ts:2795 TooltipOptions (index.d.ts:1605 CoreInteractionOptions), the
/// scope `plugins.tooltip`.
base class TooltipOptionsScope extends OptionScope {
  /// An empty scope.
  TooltipOptionsScope();

  @override
  ScopeKind get kind => ScopeKind.tooltipOptions;

  Opt<String>? _mode;

  /// The cell of `mode`, or Dart `null` when absent.
  Opt<String>? get modeCell => _mode;

  /// Stores the cell of `mode`. Dart `null` deletes the key.
  set modeCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.mode);
    } else {
      store(OptionKey.mode, cell);
    }
  }

  /// Stores the plain value [value] of `mode`.
  set mode(String value) => store(OptionKey.mode, OptValue<String>(value));

  Opt<bool>? _intersect;

  /// The cell of `intersect`, or Dart `null` when absent.
  Opt<bool>? get intersectCell => _intersect;

  /// Stores the cell of `intersect`. Dart `null` deletes the key.
  set intersectCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.intersect);
    } else {
      store(OptionKey.intersect, cell);
    }
  }

  /// Stores the plain value [value] of `intersect`.
  set intersect(bool value) =>
      store(OptionKey.intersect, OptValue<bool>(value));

  Opt<String>? _axis;

  /// The cell of `axis`, or Dart `null` when absent.
  Opt<String>? get axisCell => _axis;

  /// Stores the cell of `axis`. Dart `null` deletes the key.
  set axisCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.axis);
    } else {
      store(OptionKey.axis, cell);
    }
  }

  /// Stores the plain value [value] of `axis`.
  set axis(String value) => store(OptionKey.axis, OptValue<String>(value));

  Opt<bool>? _includeInvisible;

  /// The cell of `includeInvisible`, or Dart `null` when absent.
  Opt<bool>? get includeInvisibleCell => _includeInvisible;

  /// Stores the cell of `includeInvisible`. Dart `null` deletes the key.
  set includeInvisibleCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.includeInvisible);
    } else {
      store(OptionKey.includeInvisible, cell);
    }
  }

  /// Stores the plain value [value] of `includeInvisible`.
  set includeInvisible(bool value) =>
      store(OptionKey.includeInvisible, OptValue<bool>(value));

  Opt<bool>? _enabled;

  /// The cell of `enabled`, or Dart `null` when absent.
  Opt<bool>? get enabledCell => _enabled;

  /// Stores the cell of `enabled`. Dart `null` deletes the key.
  set enabledCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.enabled);
    } else {
      store(OptionKey.enabled, cell);
    }
  }

  /// Stores the plain value [value] of `enabled`.
  set enabled(bool value) => store(OptionKey.enabled, OptValue<bool>(value));

  Opt<Object>? _external;

  /// The cell of `external`, or Dart `null` when absent.
  Opt<Object>? get externalCell => _external;

  /// Stores the cell of `external`. Dart `null` deletes the key.
  set externalCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.external);
    } else {
      store(OptionKey.external, cell);
    }
  }

  /// Stores the plain value [value] of `external`.
  set external(Object value) =>
      store(OptionKey.external, classify(OptionKey.external, value));

  Opt<String>? _position;

  /// The cell of `position`, or Dart `null` when absent.
  Opt<String>? get positionCell => _position;

  /// Stores the cell of `position`. Dart `null` deletes the key.
  set positionCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.position);
    } else {
      store(OptionKey.position, cell);
    }
  }

  /// Stores the plain value [value] of `position`.
  set position(String value) =>
      store(OptionKey.position, OptValue<String>(value));

  Opt<String>? _xAlign;

  /// The cell of `xAlign`, or Dart `null` when absent.
  Opt<String>? get xAlignCell => _xAlign;

  /// Stores the cell of `xAlign`. Dart `null` deletes the key.
  set xAlignCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.xAlign);
    } else {
      store(OptionKey.xAlign, cell);
    }
  }

  /// Stores the plain value [value] of `xAlign`.
  set xAlign(String value) => store(OptionKey.xAlign, OptValue<String>(value));

  Opt<String>? _yAlign;

  /// The cell of `yAlign`, or Dart `null` when absent.
  Opt<String>? get yAlignCell => _yAlign;

  /// Stores the cell of `yAlign`. Dart `null` deletes the key.
  set yAlignCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.yAlign);
    } else {
      store(OptionKey.yAlign, cell);
    }
  }

  /// Stores the plain value [value] of `yAlign`.
  set yAlign(String value) => store(OptionKey.yAlign, OptValue<String>(value));

  Opt<Object>? _itemSort;

  /// The cell of `itemSort`, or Dart `null` when absent.
  Opt<Object>? get itemSortCell => _itemSort;

  /// Stores the cell of `itemSort`. Dart `null` deletes the key.
  set itemSortCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.itemSort);
    } else {
      store(OptionKey.itemSort, cell);
    }
  }

  /// Stores the plain value [value] of `itemSort`.
  set itemSort(Object value) =>
      store(OptionKey.itemSort, classify(OptionKey.itemSort, value));

  Opt<Object>? _filter;

  /// The cell of `filter`, or Dart `null` when absent.
  Opt<Object>? get filterCell => _filter;

  /// Stores the cell of `filter`. Dart `null` deletes the key.
  set filterCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.filter);
    } else {
      store(OptionKey.filter, cell);
    }
  }

  /// Stores the plain value [value] of `filter`.
  set filter(Object value) =>
      store(OptionKey.filter, classify(OptionKey.filter, value));

  Opt<Object>? _backgroundColor;

  /// The cell of `backgroundColor`, or Dart `null` when absent.
  Opt<Object>? get backgroundColorCell => _backgroundColor;

  /// Stores the cell of `backgroundColor`. Dart `null` deletes the key.
  set backgroundColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.backgroundColor);
    } else {
      store(OptionKey.backgroundColor, cell);
    }
  }

  /// Stores the plain value [value] of `backgroundColor`.
  set backgroundColor(Object value) => store(
    OptionKey.backgroundColor,
    classify(OptionKey.backgroundColor, value),
  );

  Opt<double>? _boxPadding;

  /// The cell of `boxPadding`, or Dart `null` when absent.
  Opt<double>? get boxPaddingCell => _boxPadding;

  /// Stores the cell of `boxPadding`. Dart `null` deletes the key.
  set boxPaddingCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.boxPadding);
    } else {
      store(OptionKey.boxPadding, cell);
    }
  }

  /// Stores the plain value [value] of `boxPadding`.
  set boxPadding(double value) =>
      store(OptionKey.boxPadding, OptValue<double>(value));

  Opt<Object>? _titleColor;

  /// The cell of `titleColor`, or Dart `null` when absent.
  Opt<Object>? get titleColorCell => _titleColor;

  /// Stores the cell of `titleColor`. Dart `null` deletes the key.
  set titleColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.titleColor);
    } else {
      store(OptionKey.titleColor, cell);
    }
  }

  /// Stores the plain value [value] of `titleColor`.
  set titleColor(Object value) =>
      store(OptionKey.titleColor, classify(OptionKey.titleColor, value));

  Opt<FontSpecScope>? _titleFont;

  /// The cell of `titleFont`, or Dart `null` when absent.
  Opt<FontSpecScope>? get titleFontCell => _titleFont;

  /// Stores the cell of `titleFont`. Dart `null` deletes the key.
  set titleFontCell(Opt<FontSpecScope>? cell) {
    if (cell == null) {
      delete(OptionKey.titleFont);
    } else {
      store(OptionKey.titleFont, cell);
    }
  }

  /// Stores the plain value [value] of `titleFont`.
  set titleFont(FontSpecScope value) =>
      store(OptionKey.titleFont, OptScope<FontSpecScope>(value));

  Opt<double>? _titleSpacing;

  /// The cell of `titleSpacing`, or Dart `null` when absent.
  Opt<double>? get titleSpacingCell => _titleSpacing;

  /// Stores the cell of `titleSpacing`. Dart `null` deletes the key.
  set titleSpacingCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.titleSpacing);
    } else {
      store(OptionKey.titleSpacing, cell);
    }
  }

  /// Stores the plain value [value] of `titleSpacing`.
  set titleSpacing(double value) =>
      store(OptionKey.titleSpacing, OptValue<double>(value));

  Opt<double>? _titleMarginBottom;

  /// The cell of `titleMarginBottom`, or Dart `null` when absent.
  Opt<double>? get titleMarginBottomCell => _titleMarginBottom;

  /// Stores the cell of `titleMarginBottom`. Dart `null` deletes the key.
  set titleMarginBottomCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.titleMarginBottom);
    } else {
      store(OptionKey.titleMarginBottom, cell);
    }
  }

  /// Stores the plain value [value] of `titleMarginBottom`.
  set titleMarginBottom(double value) =>
      store(OptionKey.titleMarginBottom, OptValue<double>(value));

  Opt<String>? _titleAlign;

  /// The cell of `titleAlign`, or Dart `null` when absent.
  Opt<String>? get titleAlignCell => _titleAlign;

  /// Stores the cell of `titleAlign`. Dart `null` deletes the key.
  set titleAlignCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.titleAlign);
    } else {
      store(OptionKey.titleAlign, cell);
    }
  }

  /// Stores the plain value [value] of `titleAlign`.
  set titleAlign(String value) =>
      store(OptionKey.titleAlign, OptValue<String>(value));

  Opt<double>? _bodySpacing;

  /// The cell of `bodySpacing`, or Dart `null` when absent.
  Opt<double>? get bodySpacingCell => _bodySpacing;

  /// Stores the cell of `bodySpacing`. Dart `null` deletes the key.
  set bodySpacingCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.bodySpacing);
    } else {
      store(OptionKey.bodySpacing, cell);
    }
  }

  /// Stores the plain value [value] of `bodySpacing`.
  set bodySpacing(double value) =>
      store(OptionKey.bodySpacing, OptValue<double>(value));

  Opt<Object>? _bodyColor;

  /// The cell of `bodyColor`, or Dart `null` when absent.
  Opt<Object>? get bodyColorCell => _bodyColor;

  /// Stores the cell of `bodyColor`. Dart `null` deletes the key.
  set bodyColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.bodyColor);
    } else {
      store(OptionKey.bodyColor, cell);
    }
  }

  /// Stores the plain value [value] of `bodyColor`.
  set bodyColor(Object value) =>
      store(OptionKey.bodyColor, classify(OptionKey.bodyColor, value));

  Opt<FontSpecScope>? _bodyFont;

  /// The cell of `bodyFont`, or Dart `null` when absent.
  Opt<FontSpecScope>? get bodyFontCell => _bodyFont;

  /// Stores the cell of `bodyFont`. Dart `null` deletes the key.
  set bodyFontCell(Opt<FontSpecScope>? cell) {
    if (cell == null) {
      delete(OptionKey.bodyFont);
    } else {
      store(OptionKey.bodyFont, cell);
    }
  }

  /// Stores the plain value [value] of `bodyFont`.
  set bodyFont(FontSpecScope value) =>
      store(OptionKey.bodyFont, OptScope<FontSpecScope>(value));

  Opt<String>? _bodyAlign;

  /// The cell of `bodyAlign`, or Dart `null` when absent.
  Opt<String>? get bodyAlignCell => _bodyAlign;

  /// Stores the cell of `bodyAlign`. Dart `null` deletes the key.
  set bodyAlignCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.bodyAlign);
    } else {
      store(OptionKey.bodyAlign, cell);
    }
  }

  /// Stores the plain value [value] of `bodyAlign`.
  set bodyAlign(String value) =>
      store(OptionKey.bodyAlign, OptValue<String>(value));

  Opt<double>? _footerSpacing;

  /// The cell of `footerSpacing`, or Dart `null` when absent.
  Opt<double>? get footerSpacingCell => _footerSpacing;

  /// Stores the cell of `footerSpacing`. Dart `null` deletes the key.
  set footerSpacingCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.footerSpacing);
    } else {
      store(OptionKey.footerSpacing, cell);
    }
  }

  /// Stores the plain value [value] of `footerSpacing`.
  set footerSpacing(double value) =>
      store(OptionKey.footerSpacing, OptValue<double>(value));

  Opt<double>? _footerMarginTop;

  /// The cell of `footerMarginTop`, or Dart `null` when absent.
  Opt<double>? get footerMarginTopCell => _footerMarginTop;

  /// Stores the cell of `footerMarginTop`. Dart `null` deletes the key.
  set footerMarginTopCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.footerMarginTop);
    } else {
      store(OptionKey.footerMarginTop, cell);
    }
  }

  /// Stores the plain value [value] of `footerMarginTop`.
  set footerMarginTop(double value) =>
      store(OptionKey.footerMarginTop, OptValue<double>(value));

  Opt<Object>? _footerColor;

  /// The cell of `footerColor`, or Dart `null` when absent.
  Opt<Object>? get footerColorCell => _footerColor;

  /// Stores the cell of `footerColor`. Dart `null` deletes the key.
  set footerColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.footerColor);
    } else {
      store(OptionKey.footerColor, cell);
    }
  }

  /// Stores the plain value [value] of `footerColor`.
  set footerColor(Object value) =>
      store(OptionKey.footerColor, classify(OptionKey.footerColor, value));

  Opt<FontSpecScope>? _footerFont;

  /// The cell of `footerFont`, or Dart `null` when absent.
  Opt<FontSpecScope>? get footerFontCell => _footerFont;

  /// Stores the cell of `footerFont`. Dart `null` deletes the key.
  set footerFontCell(Opt<FontSpecScope>? cell) {
    if (cell == null) {
      delete(OptionKey.footerFont);
    } else {
      store(OptionKey.footerFont, cell);
    }
  }

  /// Stores the plain value [value] of `footerFont`.
  set footerFont(FontSpecScope value) =>
      store(OptionKey.footerFont, OptScope<FontSpecScope>(value));

  Opt<String>? _footerAlign;

  /// The cell of `footerAlign`, or Dart `null` when absent.
  Opt<String>? get footerAlignCell => _footerAlign;

  /// Stores the cell of `footerAlign`. Dart `null` deletes the key.
  set footerAlignCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.footerAlign);
    } else {
      store(OptionKey.footerAlign, cell);
    }
  }

  /// Stores the plain value [value] of `footerAlign`.
  set footerAlign(String value) =>
      store(OptionKey.footerAlign, OptValue<String>(value));

  Opt<Object>? _padding;

  /// The cell of `padding`, or Dart `null` when absent.
  Opt<Object>? get paddingCell => _padding;

  /// Stores the cell of `padding`. Dart `null` deletes the key.
  set paddingCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.padding);
    } else {
      store(OptionKey.padding, cell);
    }
  }

  /// Stores the plain value [value] of `padding`.
  set padding(Object value) =>
      store(OptionKey.padding, classify(OptionKey.padding, value));

  Opt<double>? _caretPadding;

  /// The cell of `caretPadding`, or Dart `null` when absent.
  Opt<double>? get caretPaddingCell => _caretPadding;

  /// Stores the cell of `caretPadding`. Dart `null` deletes the key.
  set caretPaddingCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.caretPadding);
    } else {
      store(OptionKey.caretPadding, cell);
    }
  }

  /// Stores the plain value [value] of `caretPadding`.
  set caretPadding(double value) =>
      store(OptionKey.caretPadding, OptValue<double>(value));

  Opt<double>? _caretSize;

  /// The cell of `caretSize`, or Dart `null` when absent.
  Opt<double>? get caretSizeCell => _caretSize;

  /// Stores the cell of `caretSize`. Dart `null` deletes the key.
  set caretSizeCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.caretSize);
    } else {
      store(OptionKey.caretSize, cell);
    }
  }

  /// Stores the plain value [value] of `caretSize`.
  set caretSize(double value) =>
      store(OptionKey.caretSize, OptValue<double>(value));

  Opt<Object>? _cornerRadius;

  /// The cell of `cornerRadius`, or Dart `null` when absent.
  Opt<Object>? get cornerRadiusCell => _cornerRadius;

  /// Stores the cell of `cornerRadius`. Dart `null` deletes the key.
  set cornerRadiusCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.cornerRadius);
    } else {
      store(OptionKey.cornerRadius, cell);
    }
  }

  /// Stores the plain value [value] of `cornerRadius`.
  set cornerRadius(Object value) =>
      store(OptionKey.cornerRadius, classify(OptionKey.cornerRadius, value));

  Opt<Object>? _multiKeyBackground;

  /// The cell of `multiKeyBackground`, or Dart `null` when absent.
  Opt<Object>? get multiKeyBackgroundCell => _multiKeyBackground;

  /// Stores the cell of `multiKeyBackground`. Dart `null` deletes the key.
  set multiKeyBackgroundCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.multiKeyBackground);
    } else {
      store(OptionKey.multiKeyBackground, cell);
    }
  }

  /// Stores the plain value [value] of `multiKeyBackground`.
  set multiKeyBackground(Object value) => store(
    OptionKey.multiKeyBackground,
    classify(OptionKey.multiKeyBackground, value),
  );

  Opt<bool>? _displayColors;

  /// The cell of `displayColors`, or Dart `null` when absent.
  Opt<bool>? get displayColorsCell => _displayColors;

  /// Stores the cell of `displayColors`. Dart `null` deletes the key.
  set displayColorsCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.displayColors);
    } else {
      store(OptionKey.displayColors, cell);
    }
  }

  /// Stores the plain value [value] of `displayColors`.
  set displayColors(bool value) =>
      store(OptionKey.displayColors, OptValue<bool>(value));

  Opt<double>? _boxWidth;

  /// The cell of `boxWidth`, or Dart `null` when absent.
  Opt<double>? get boxWidthCell => _boxWidth;

  /// Stores the cell of `boxWidth`. Dart `null` deletes the key.
  set boxWidthCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.boxWidth);
    } else {
      store(OptionKey.boxWidth, cell);
    }
  }

  /// Stores the plain value [value] of `boxWidth`.
  set boxWidth(double value) =>
      store(OptionKey.boxWidth, OptValue<double>(value));

  Opt<double>? _boxHeight;

  /// The cell of `boxHeight`, or Dart `null` when absent.
  Opt<double>? get boxHeightCell => _boxHeight;

  /// Stores the cell of `boxHeight`. Dart `null` deletes the key.
  set boxHeightCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.boxHeight);
    } else {
      store(OptionKey.boxHeight, cell);
    }
  }

  /// Stores the plain value [value] of `boxHeight`.
  set boxHeight(double value) =>
      store(OptionKey.boxHeight, OptValue<double>(value));

  Opt<bool>? _usePointStyle;

  /// The cell of `usePointStyle`, or Dart `null` when absent.
  Opt<bool>? get usePointStyleCell => _usePointStyle;

  /// Stores the cell of `usePointStyle`. Dart `null` deletes the key.
  set usePointStyleCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.usePointStyle);
    } else {
      store(OptionKey.usePointStyle, cell);
    }
  }

  /// Stores the plain value [value] of `usePointStyle`.
  set usePointStyle(bool value) =>
      store(OptionKey.usePointStyle, OptValue<bool>(value));

  Opt<Object>? _borderColor;

  /// The cell of `borderColor`, or Dart `null` when absent.
  Opt<Object>? get borderColorCell => _borderColor;

  /// Stores the cell of `borderColor`. Dart `null` deletes the key.
  set borderColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.borderColor);
    } else {
      store(OptionKey.borderColor, cell);
    }
  }

  /// Stores the plain value [value] of `borderColor`.
  set borderColor(Object value) =>
      store(OptionKey.borderColor, classify(OptionKey.borderColor, value));

  Opt<double>? _borderWidth;

  /// The cell of `borderWidth`, or Dart `null` when absent.
  Opt<double>? get borderWidthCell => _borderWidth;

  /// Stores the cell of `borderWidth`. Dart `null` deletes the key.
  set borderWidthCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.borderWidth);
    } else {
      store(OptionKey.borderWidth, cell);
    }
  }

  /// Stores the plain value [value] of `borderWidth`.
  set borderWidth(double value) =>
      store(OptionKey.borderWidth, OptValue<double>(value));

  Opt<bool>? _rtl;

  /// The cell of `rtl`, or Dart `null` when absent.
  Opt<bool>? get rtlCell => _rtl;

  /// Stores the cell of `rtl`. Dart `null` deletes the key.
  set rtlCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.rtl);
    } else {
      store(OptionKey.rtl, cell);
    }
  }

  /// Stores the plain value [value] of `rtl`.
  set rtl(bool value) => store(OptionKey.rtl, OptValue<bool>(value));

  Opt<String>? _textDirection;

  /// The cell of `textDirection`, or Dart `null` when absent.
  Opt<String>? get textDirectionCell => _textDirection;

  /// Stores the cell of `textDirection`. Dart `null` deletes the key.
  set textDirectionCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.textDirection);
    } else {
      store(OptionKey.textDirection, cell);
    }
  }

  /// Stores the plain value [value] of `textDirection`.
  set textDirection(String value) =>
      store(OptionKey.textDirection, OptValue<String>(value));

  Opt<Object>? _animation;

  /// The cell of `animation`, or Dart `null` when absent.
  Opt<Object>? get animationCell => _animation;

  /// Stores the cell of `animation`. Dart `null` deletes the key.
  set animationCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.animation);
    } else {
      store(OptionKey.animation, cell);
    }
  }

  /// Stores the plain value [value] of `animation`.
  set animation(Object value) =>
      store(OptionKey.animation, classify(OptionKey.animation, value));

  Opt<Object>? _animations;

  /// The cell of `animations`, or Dart `null` when absent.
  Opt<Object>? get animationsCell => _animations;

  /// Stores the cell of `animations`. Dart `null` deletes the key.
  set animationsCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.animations);
    } else {
      store(OptionKey.animations, cell);
    }
  }

  /// Stores the plain value [value] of `animations`.
  set animations(Object value) =>
      store(OptionKey.animations, classify(OptionKey.animations, value));

  Opt<TooltipCallbacksScope>? _callbacks;

  /// The cell of `callbacks`, or Dart `null` when absent.
  Opt<TooltipCallbacksScope>? get callbacksCell => _callbacks;

  /// Stores the cell of `callbacks`. Dart `null` deletes the key.
  set callbacksCell(Opt<TooltipCallbacksScope>? cell) {
    if (cell == null) {
      delete(OptionKey.callbacks);
    } else {
      store(OptionKey.callbacks, cell);
    }
  }

  /// Stores the plain value [value] of `callbacks`.
  set callbacks(TooltipCallbacksScope value) =>
      store(OptionKey.callbacks, OptScope<TooltipCallbacksScope>(value));

  Opt<bool>? _reverse;

  /// The cell of `reverse`, or Dart `null` when absent.
  Opt<bool>? get reverseCell => _reverse;

  /// Stores the cell of `reverse`. Dart `null` deletes the key.
  set reverseCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.reverse);
    } else {
      store(OptionKey.reverse, cell);
    }
  }

  /// Stores the plain value [value] of `reverse`.
  set reverse(bool value) => store(OptionKey.reverse, OptValue<bool>(value));

  Opt<Object>? _events;

  /// The cell of `events`, or Dart `null` when absent.
  Opt<Object>? get eventsCell => _events;

  /// Stores the cell of `events`. Dart `null` deletes the key.
  set eventsCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.events);
    } else {
      store(OptionKey.events, cell);
    }
  }

  /// Stores the plain value [value] of `events`.
  set events(Object value) =>
      store(OptionKey.events, classify(OptionKey.events, value));

  @override
  Opt<Object?>? cellOf(OptionKey key) => switch (key) {
    OptionKey.mode => _mode,
    OptionKey.intersect => _intersect,
    OptionKey.axis => _axis,
    OptionKey.includeInvisible => _includeInvisible,
    OptionKey.enabled => _enabled,
    OptionKey.external => _external,
    OptionKey.position => _position,
    OptionKey.xAlign => _xAlign,
    OptionKey.yAlign => _yAlign,
    OptionKey.itemSort => _itemSort,
    OptionKey.filter => _filter,
    OptionKey.backgroundColor => _backgroundColor,
    OptionKey.boxPadding => _boxPadding,
    OptionKey.titleColor => _titleColor,
    OptionKey.titleFont => _titleFont,
    OptionKey.titleSpacing => _titleSpacing,
    OptionKey.titleMarginBottom => _titleMarginBottom,
    OptionKey.titleAlign => _titleAlign,
    OptionKey.bodySpacing => _bodySpacing,
    OptionKey.bodyColor => _bodyColor,
    OptionKey.bodyFont => _bodyFont,
    OptionKey.bodyAlign => _bodyAlign,
    OptionKey.footerSpacing => _footerSpacing,
    OptionKey.footerMarginTop => _footerMarginTop,
    OptionKey.footerColor => _footerColor,
    OptionKey.footerFont => _footerFont,
    OptionKey.footerAlign => _footerAlign,
    OptionKey.padding => _padding,
    OptionKey.caretPadding => _caretPadding,
    OptionKey.caretSize => _caretSize,
    OptionKey.cornerRadius => _cornerRadius,
    OptionKey.multiKeyBackground => _multiKeyBackground,
    OptionKey.displayColors => _displayColors,
    OptionKey.boxWidth => _boxWidth,
    OptionKey.boxHeight => _boxHeight,
    OptionKey.usePointStyle => _usePointStyle,
    OptionKey.borderColor => _borderColor,
    OptionKey.borderWidth => _borderWidth,
    OptionKey.rtl => _rtl,
    OptionKey.textDirection => _textDirection,
    OptionKey.animation => _animation,
    OptionKey.animations => _animations,
    OptionKey.callbacks => _callbacks,
    OptionKey.reverse => _reverse,
    OptionKey.events => _events,
    _ => null,
  };

  @override
  void setCell(OptionKey key, Opt<Object?>? cell) {
    switch (key) {
      case OptionKey.mode:
        _mode = fitCell(cell, classifyString);
      case OptionKey.intersect:
        _intersect = fitCell(cell, classifyBool);
      case OptionKey.axis:
        _axis = fitCell(cell, classifyString);
      case OptionKey.includeInvisible:
        _includeInvisible = fitCell(cell, classifyBool);
      case OptionKey.enabled:
        _enabled = fitCell(cell, classifyBool);
      case OptionKey.external:
        _external = fitCell(cell, (raw) => classifyUnion(raw, 8));
      case OptionKey.position:
        _position = fitCell(cell, classifyString);
      case OptionKey.xAlign:
        _xAlign = fitCell(cell, classifyString);
      case OptionKey.yAlign:
        _yAlign = fitCell(cell, classifyString);
      case OptionKey.itemSort:
        _itemSort = fitCell(cell, (raw) => classifyUnion(raw, 8));
      case OptionKey.filter:
        _filter = fitCell(cell, (raw) => classifyUnion(raw, 8));
      case OptionKey.backgroundColor:
        _backgroundColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.boxPadding:
        _boxPadding = fitCell(cell, classifyNumber);
      case OptionKey.titleColor:
        _titleColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.titleFont:
        _titleFont = fitCell(cell, classifyScope<FontSpecScope>);
      case OptionKey.titleSpacing:
        _titleSpacing = fitCell(cell, classifyNumber);
      case OptionKey.titleMarginBottom:
        _titleMarginBottom = fitCell(cell, classifyNumber);
      case OptionKey.titleAlign:
        _titleAlign = fitCell(cell, classifyString);
      case OptionKey.bodySpacing:
        _bodySpacing = fitCell(cell, classifyNumber);
      case OptionKey.bodyColor:
        _bodyColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.bodyFont:
        _bodyFont = fitCell(cell, classifyScope<FontSpecScope>);
      case OptionKey.bodyAlign:
        _bodyAlign = fitCell(cell, classifyString);
      case OptionKey.footerSpacing:
        _footerSpacing = fitCell(cell, classifyNumber);
      case OptionKey.footerMarginTop:
        _footerMarginTop = fitCell(cell, classifyNumber);
      case OptionKey.footerColor:
        _footerColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.footerFont:
        _footerFont = fitCell(cell, classifyScope<FontSpecScope>);
      case OptionKey.footerAlign:
        _footerAlign = fitCell(cell, classifyString);
      case OptionKey.padding:
        _padding = fitCell(cell, (raw) => classifyUnion(raw, 33));
      case OptionKey.caretPadding:
        _caretPadding = fitCell(cell, classifyNumber);
      case OptionKey.caretSize:
        _caretSize = fitCell(cell, classifyNumber);
      case OptionKey.cornerRadius:
        _cornerRadius = fitCell(cell, (raw) => classifyUnion(raw, 33));
      case OptionKey.multiKeyBackground:
        _multiKeyBackground = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.displayColors:
        _displayColors = fitCell(cell, classifyBool);
      case OptionKey.boxWidth:
        _boxWidth = fitCell(cell, classifyNumber);
      case OptionKey.boxHeight:
        _boxHeight = fitCell(cell, classifyNumber);
      case OptionKey.usePointStyle:
        _usePointStyle = fitCell(cell, classifyBool);
      case OptionKey.borderColor:
        _borderColor = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.borderWidth:
        _borderWidth = fitCell(cell, classifyNumber);
      case OptionKey.rtl:
        _rtl = fitCell(cell, classifyBool);
      case OptionKey.textDirection:
        _textDirection = fitCell(cell, classifyString);
      case OptionKey.animation:
        _animation = fitCell(cell, (raw) => classifyUnion(raw, 34));
      case OptionKey.animations:
        _animations = fitCell(cell, (raw) => classifyUnion(raw, 34));
      case OptionKey.callbacks:
        _callbacks = fitCell(cell, classifyScope<TooltipCallbacksScope>);
      case OptionKey.reverse:
        _reverse = fitCell(cell, classifyBool);
      case OptionKey.events:
        _events = fitCell(cell, (raw) => classifyUnion(raw, 16));
      default:
        throw ArgumentError.value(key, 'key', 'Not a key of TooltipOptions');
    }
  }

  @override
  bool hasField(OptionKey key) => switch (key) {
    OptionKey.mode ||
    OptionKey.intersect ||
    OptionKey.axis ||
    OptionKey.includeInvisible ||
    OptionKey.enabled ||
    OptionKey.external ||
    OptionKey.position ||
    OptionKey.xAlign ||
    OptionKey.yAlign ||
    OptionKey.itemSort ||
    OptionKey.filter ||
    OptionKey.backgroundColor ||
    OptionKey.boxPadding ||
    OptionKey.titleColor ||
    OptionKey.titleFont ||
    OptionKey.titleSpacing ||
    OptionKey.titleMarginBottom ||
    OptionKey.titleAlign ||
    OptionKey.bodySpacing ||
    OptionKey.bodyColor ||
    OptionKey.bodyFont ||
    OptionKey.bodyAlign ||
    OptionKey.footerSpacing ||
    OptionKey.footerMarginTop ||
    OptionKey.footerColor ||
    OptionKey.footerFont ||
    OptionKey.footerAlign ||
    OptionKey.padding ||
    OptionKey.caretPadding ||
    OptionKey.caretSize ||
    OptionKey.cornerRadius ||
    OptionKey.multiKeyBackground ||
    OptionKey.displayColors ||
    OptionKey.boxWidth ||
    OptionKey.boxHeight ||
    OptionKey.usePointStyle ||
    OptionKey.borderColor ||
    OptionKey.borderWidth ||
    OptionKey.rtl ||
    OptionKey.textDirection ||
    OptionKey.animation ||
    OptionKey.animations ||
    OptionKey.callbacks ||
    OptionKey.reverse ||
    OptionKey.events => true,
    _ => false,
  };

  @override
  Opt<Object?> classify(OptionKey key, Object? raw) => switch (key) {
    OptionKey.mode => classifyString(raw),
    OptionKey.intersect => classifyBool(raw),
    OptionKey.axis => classifyString(raw),
    OptionKey.includeInvisible => classifyBool(raw),
    OptionKey.enabled => classifyBool(raw),
    OptionKey.external => classifyUnion(raw, 8),
    OptionKey.position => classifyString(raw),
    OptionKey.xAlign => classifyString(raw),
    OptionKey.yAlign => classifyString(raw),
    OptionKey.itemSort => classifyUnion(raw, 8),
    OptionKey.filter => classifyUnion(raw, 8),
    OptionKey.backgroundColor => classifyUnion(raw, 64),
    OptionKey.boxPadding => classifyNumber(raw),
    OptionKey.titleColor => classifyUnion(raw, 64),
    OptionKey.titleFont => classifyScope<FontSpecScope>(raw),
    OptionKey.titleSpacing => classifyNumber(raw),
    OptionKey.titleMarginBottom => classifyNumber(raw),
    OptionKey.titleAlign => classifyString(raw),
    OptionKey.bodySpacing => classifyNumber(raw),
    OptionKey.bodyColor => classifyUnion(raw, 64),
    OptionKey.bodyFont => classifyScope<FontSpecScope>(raw),
    OptionKey.bodyAlign => classifyString(raw),
    OptionKey.footerSpacing => classifyNumber(raw),
    OptionKey.footerMarginTop => classifyNumber(raw),
    OptionKey.footerColor => classifyUnion(raw, 64),
    OptionKey.footerFont => classifyScope<FontSpecScope>(raw),
    OptionKey.footerAlign => classifyString(raw),
    OptionKey.padding => classifyUnion(raw, 33),
    OptionKey.caretPadding => classifyNumber(raw),
    OptionKey.caretSize => classifyNumber(raw),
    OptionKey.cornerRadius => classifyUnion(raw, 33),
    OptionKey.multiKeyBackground => classifyUnion(raw, 64),
    OptionKey.displayColors => classifyBool(raw),
    OptionKey.boxWidth => classifyNumber(raw),
    OptionKey.boxHeight => classifyNumber(raw),
    OptionKey.usePointStyle => classifyBool(raw),
    OptionKey.borderColor => classifyUnion(raw, 64),
    OptionKey.borderWidth => classifyNumber(raw),
    OptionKey.rtl => classifyBool(raw),
    OptionKey.textDirection => classifyString(raw),
    OptionKey.animation => classifyUnion(raw, 34),
    OptionKey.animations => classifyUnion(raw, 34),
    OptionKey.callbacks => classifyScope<TooltipCallbacksScope>(raw),
    OptionKey.reverse => classifyBool(raw),
    OptionKey.events => classifyUnion(raw, 16),
    _ => kind.classifyOther(raw),
  };
}

/// index.d.ts:2739 TooltipCallbacks (index.d.ts:2726 TooltipDatasetCallbacks),
/// the scope `callbacks` of the tooltip and of a dataset tooltip.
base class TooltipCallbacksScope extends OptionScope {
  /// An empty scope.
  TooltipCallbacksScope();

  @override
  ScopeKind get kind => ScopeKind.tooltipCallbacks;

  Opt<Object>? _beforeLabel;

  /// The cell of `beforeLabel`, or Dart `null` when absent.
  Opt<Object>? get beforeLabelCell => _beforeLabel;

  /// Stores the cell of `beforeLabel`. Dart `null` deletes the key.
  set beforeLabelCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.beforeLabel);
    } else {
      store(OptionKey.beforeLabel, cell);
    }
  }

  /// Stores the plain value [value] of `beforeLabel`.
  set beforeLabel(Object value) =>
      store(OptionKey.beforeLabel, classify(OptionKey.beforeLabel, value));

  Opt<Object>? _label;

  /// The cell of `label`, or Dart `null` when absent.
  Opt<Object>? get labelCell => _label;

  /// Stores the cell of `label`. Dart `null` deletes the key.
  set labelCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.label);
    } else {
      store(OptionKey.label, cell);
    }
  }

  /// Stores the plain value [value] of `label`.
  set label(Object value) =>
      store(OptionKey.label, classify(OptionKey.label, value));

  Opt<Object>? _afterLabel;

  /// The cell of `afterLabel`, or Dart `null` when absent.
  Opt<Object>? get afterLabelCell => _afterLabel;

  /// Stores the cell of `afterLabel`. Dart `null` deletes the key.
  set afterLabelCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.afterLabel);
    } else {
      store(OptionKey.afterLabel, cell);
    }
  }

  /// Stores the plain value [value] of `afterLabel`.
  set afterLabel(Object value) =>
      store(OptionKey.afterLabel, classify(OptionKey.afterLabel, value));

  Opt<Object>? _labelColor;

  /// The cell of `labelColor`, or Dart `null` when absent.
  Opt<Object>? get labelColorCell => _labelColor;

  /// Stores the cell of `labelColor`. Dart `null` deletes the key.
  set labelColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.labelColor);
    } else {
      store(OptionKey.labelColor, cell);
    }
  }

  /// Stores the plain value [value] of `labelColor`.
  set labelColor(Object value) =>
      store(OptionKey.labelColor, classify(OptionKey.labelColor, value));

  Opt<Object>? _labelTextColor;

  /// The cell of `labelTextColor`, or Dart `null` when absent.
  Opt<Object>? get labelTextColorCell => _labelTextColor;

  /// Stores the cell of `labelTextColor`. Dart `null` deletes the key.
  set labelTextColorCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.labelTextColor);
    } else {
      store(OptionKey.labelTextColor, cell);
    }
  }

  /// Stores the plain value [value] of `labelTextColor`.
  set labelTextColor(Object value) => store(
    OptionKey.labelTextColor,
    classify(OptionKey.labelTextColor, value),
  );

  Opt<Object>? _labelPointStyle;

  /// The cell of `labelPointStyle`, or Dart `null` when absent.
  Opt<Object>? get labelPointStyleCell => _labelPointStyle;

  /// Stores the cell of `labelPointStyle`. Dart `null` deletes the key.
  set labelPointStyleCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.labelPointStyle);
    } else {
      store(OptionKey.labelPointStyle, cell);
    }
  }

  /// Stores the plain value [value] of `labelPointStyle`.
  set labelPointStyle(Object value) => store(
    OptionKey.labelPointStyle,
    classify(OptionKey.labelPointStyle, value),
  );

  Opt<Object>? _beforeTitle;

  /// The cell of `beforeTitle`, or Dart `null` when absent.
  Opt<Object>? get beforeTitleCell => _beforeTitle;

  /// Stores the cell of `beforeTitle`. Dart `null` deletes the key.
  set beforeTitleCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.beforeTitle);
    } else {
      store(OptionKey.beforeTitle, cell);
    }
  }

  /// Stores the plain value [value] of `beforeTitle`.
  set beforeTitle(Object value) =>
      store(OptionKey.beforeTitle, classify(OptionKey.beforeTitle, value));

  Opt<Object>? _title;

  /// The cell of `title`, or Dart `null` when absent.
  Opt<Object>? get titleCell => _title;

  /// Stores the cell of `title`. Dart `null` deletes the key.
  set titleCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.title);
    } else {
      store(OptionKey.title, cell);
    }
  }

  /// Stores the plain value [value] of `title`.
  set title(Object value) =>
      store(OptionKey.title, classify(OptionKey.title, value));

  Opt<Object>? _afterTitle;

  /// The cell of `afterTitle`, or Dart `null` when absent.
  Opt<Object>? get afterTitleCell => _afterTitle;

  /// Stores the cell of `afterTitle`. Dart `null` deletes the key.
  set afterTitleCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.afterTitle);
    } else {
      store(OptionKey.afterTitle, cell);
    }
  }

  /// Stores the plain value [value] of `afterTitle`.
  set afterTitle(Object value) =>
      store(OptionKey.afterTitle, classify(OptionKey.afterTitle, value));

  Opt<Object>? _beforeBody;

  /// The cell of `beforeBody`, or Dart `null` when absent.
  Opt<Object>? get beforeBodyCell => _beforeBody;

  /// Stores the cell of `beforeBody`. Dart `null` deletes the key.
  set beforeBodyCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.beforeBody);
    } else {
      store(OptionKey.beforeBody, cell);
    }
  }

  /// Stores the plain value [value] of `beforeBody`.
  set beforeBody(Object value) =>
      store(OptionKey.beforeBody, classify(OptionKey.beforeBody, value));

  Opt<Object>? _afterBody;

  /// The cell of `afterBody`, or Dart `null` when absent.
  Opt<Object>? get afterBodyCell => _afterBody;

  /// Stores the cell of `afterBody`. Dart `null` deletes the key.
  set afterBodyCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.afterBody);
    } else {
      store(OptionKey.afterBody, cell);
    }
  }

  /// Stores the plain value [value] of `afterBody`.
  set afterBody(Object value) =>
      store(OptionKey.afterBody, classify(OptionKey.afterBody, value));

  Opt<Object>? _beforeFooter;

  /// The cell of `beforeFooter`, or Dart `null` when absent.
  Opt<Object>? get beforeFooterCell => _beforeFooter;

  /// Stores the cell of `beforeFooter`. Dart `null` deletes the key.
  set beforeFooterCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.beforeFooter);
    } else {
      store(OptionKey.beforeFooter, cell);
    }
  }

  /// Stores the plain value [value] of `beforeFooter`.
  set beforeFooter(Object value) =>
      store(OptionKey.beforeFooter, classify(OptionKey.beforeFooter, value));

  Opt<Object>? _footer;

  /// The cell of `footer`, or Dart `null` when absent.
  Opt<Object>? get footerCell => _footer;

  /// Stores the cell of `footer`. Dart `null` deletes the key.
  set footerCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.footer);
    } else {
      store(OptionKey.footer, cell);
    }
  }

  /// Stores the plain value [value] of `footer`.
  set footer(Object value) =>
      store(OptionKey.footer, classify(OptionKey.footer, value));

  Opt<Object>? _afterFooter;

  /// The cell of `afterFooter`, or Dart `null` when absent.
  Opt<Object>? get afterFooterCell => _afterFooter;

  /// Stores the cell of `afterFooter`. Dart `null` deletes the key.
  set afterFooterCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.afterFooter);
    } else {
      store(OptionKey.afterFooter, cell);
    }
  }

  /// Stores the plain value [value] of `afterFooter`.
  set afterFooter(Object value) =>
      store(OptionKey.afterFooter, classify(OptionKey.afterFooter, value));

  @override
  Opt<Object?>? cellOf(OptionKey key) => switch (key) {
    OptionKey.beforeLabel => _beforeLabel,
    OptionKey.label => _label,
    OptionKey.afterLabel => _afterLabel,
    OptionKey.labelColor => _labelColor,
    OptionKey.labelTextColor => _labelTextColor,
    OptionKey.labelPointStyle => _labelPointStyle,
    OptionKey.beforeTitle => _beforeTitle,
    OptionKey.title => _title,
    OptionKey.afterTitle => _afterTitle,
    OptionKey.beforeBody => _beforeBody,
    OptionKey.afterBody => _afterBody,
    OptionKey.beforeFooter => _beforeFooter,
    OptionKey.footer => _footer,
    OptionKey.afterFooter => _afterFooter,
    _ => null,
  };

  @override
  void setCell(OptionKey key, Opt<Object?>? cell) {
    switch (key) {
      case OptionKey.beforeLabel:
        _beforeLabel = fitCell(cell, (raw) => classifyUnion(raw, 8));
      case OptionKey.label:
        _label = fitCell(cell, (raw) => classifyUnion(raw, 8));
      case OptionKey.afterLabel:
        _afterLabel = fitCell(cell, (raw) => classifyUnion(raw, 8));
      case OptionKey.labelColor:
        _labelColor = fitCell(cell, (raw) => classifyUnion(raw, 8));
      case OptionKey.labelTextColor:
        _labelTextColor = fitCell(cell, (raw) => classifyUnion(raw, 8));
      case OptionKey.labelPointStyle:
        _labelPointStyle = fitCell(cell, (raw) => classifyUnion(raw, 8));
      case OptionKey.beforeTitle:
        _beforeTitle = fitCell(cell, (raw) => classifyUnion(raw, 8));
      case OptionKey.title:
        _title = fitCell(cell, (raw) => classifyUnion(raw, 8));
      case OptionKey.afterTitle:
        _afterTitle = fitCell(cell, (raw) => classifyUnion(raw, 8));
      case OptionKey.beforeBody:
        _beforeBody = fitCell(cell, (raw) => classifyUnion(raw, 8));
      case OptionKey.afterBody:
        _afterBody = fitCell(cell, (raw) => classifyUnion(raw, 8));
      case OptionKey.beforeFooter:
        _beforeFooter = fitCell(cell, (raw) => classifyUnion(raw, 8));
      case OptionKey.footer:
        _footer = fitCell(cell, (raw) => classifyUnion(raw, 8));
      case OptionKey.afterFooter:
        _afterFooter = fitCell(cell, (raw) => classifyUnion(raw, 8));
      default:
        throw ArgumentError.value(key, 'key', 'Not a key of TooltipCallbacks');
    }
  }

  @override
  bool hasField(OptionKey key) => switch (key) {
    OptionKey.beforeLabel ||
    OptionKey.label ||
    OptionKey.afterLabel ||
    OptionKey.labelColor ||
    OptionKey.labelTextColor ||
    OptionKey.labelPointStyle ||
    OptionKey.beforeTitle ||
    OptionKey.title ||
    OptionKey.afterTitle ||
    OptionKey.beforeBody ||
    OptionKey.afterBody ||
    OptionKey.beforeFooter ||
    OptionKey.footer ||
    OptionKey.afterFooter => true,
    _ => false,
  };

  @override
  Opt<Object?> classify(OptionKey key, Object? raw) => switch (key) {
    OptionKey.beforeLabel => classifyUnion(raw, 8),
    OptionKey.label => classifyUnion(raw, 8),
    OptionKey.afterLabel => classifyUnion(raw, 8),
    OptionKey.labelColor => classifyUnion(raw, 8),
    OptionKey.labelTextColor => classifyUnion(raw, 8),
    OptionKey.labelPointStyle => classifyUnion(raw, 8),
    OptionKey.beforeTitle => classifyUnion(raw, 8),
    OptionKey.title => classifyUnion(raw, 8),
    OptionKey.afterTitle => classifyUnion(raw, 8),
    OptionKey.beforeBody => classifyUnion(raw, 8),
    OptionKey.afterBody => classifyUnion(raw, 8),
    OptionKey.beforeFooter => classifyUnion(raw, 8),
    OptionKey.footer => classifyUnion(raw, 8),
    OptionKey.afterFooter => classifyUnion(raw, 8),
    _ => kind.classifyOther(raw),
  };
}

/// index.d.ts:2974 TooltipDatasetOptions, the `tooltip` object of a dataset
/// (read at plugin.tooltip.js:357).
base class TooltipDatasetOptionsScope extends OptionScope {
  /// An empty scope.
  TooltipDatasetOptionsScope();

  @override
  ScopeKind get kind => ScopeKind.tooltipDatasetOptions;

  Opt<TooltipCallbacksScope>? _callbacks;

  /// The cell of `callbacks`, or Dart `null` when absent.
  Opt<TooltipCallbacksScope>? get callbacksCell => _callbacks;

  /// Stores the cell of `callbacks`. Dart `null` deletes the key.
  set callbacksCell(Opt<TooltipCallbacksScope>? cell) {
    if (cell == null) {
      delete(OptionKey.callbacks);
    } else {
      store(OptionKey.callbacks, cell);
    }
  }

  /// Stores the plain value [value] of `callbacks`.
  set callbacks(TooltipCallbacksScope value) =>
      store(OptionKey.callbacks, OptScope<TooltipCallbacksScope>(value));

  @override
  Opt<Object?>? cellOf(OptionKey key) => switch (key) {
    OptionKey.callbacks => _callbacks,
    _ => null,
  };

  @override
  void setCell(OptionKey key, Opt<Object?>? cell) {
    switch (key) {
      case OptionKey.callbacks:
        _callbacks = fitCell(cell, classifyScope<TooltipCallbacksScope>);
      default:
        throw ArgumentError.value(
          key,
          'key',
          'Not a key of TooltipDatasetOptions',
        );
    }
  }

  @override
  bool hasField(OptionKey key) => switch (key) {
    OptionKey.callbacks => true,
    _ => false,
  };

  @override
  Opt<Object?> classify(OptionKey key, Object? raw) => switch (key) {
    OptionKey.callbacks => classifyScope<TooltipCallbacksScope>(raw),
    _ => kind.classifyOther(raw),
  };
}

/// index.d.ts:2295 FillerOptions, the scope `plugins.filler`.
base class FillerOptionsScope extends OptionScope {
  /// An empty scope.
  FillerOptionsScope();

  @override
  ScopeKind get kind => ScopeKind.fillerOptions;

  Opt<String>? _drawTime;

  /// The cell of `drawTime`, or Dart `null` when absent.
  Opt<String>? get drawTimeCell => _drawTime;

  /// Stores the cell of `drawTime`. Dart `null` deletes the key.
  set drawTimeCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.drawTime);
    } else {
      store(OptionKey.drawTime, cell);
    }
  }

  /// Stores the plain value [value] of `drawTime`.
  set drawTime(String value) =>
      store(OptionKey.drawTime, OptValue<String>(value));

  Opt<bool>? _propagate;

  /// The cell of `propagate`, or Dart `null` when absent.
  Opt<bool>? get propagateCell => _propagate;

  /// Stores the cell of `propagate`. Dart `null` deletes the key.
  set propagateCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.propagate);
    } else {
      store(OptionKey.propagate, cell);
    }
  }

  /// Stores the plain value [value] of `propagate`.
  set propagate(bool value) =>
      store(OptionKey.propagate, OptValue<bool>(value));

  Opt<Object>? _events;

  /// The cell of `events`, or Dart `null` when absent.
  Opt<Object>? get eventsCell => _events;

  /// Stores the cell of `events`. Dart `null` deletes the key.
  set eventsCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.events);
    } else {
      store(OptionKey.events, cell);
    }
  }

  /// Stores the plain value [value] of `events`.
  set events(Object value) =>
      store(OptionKey.events, classify(OptionKey.events, value));

  @override
  Opt<Object?>? cellOf(OptionKey key) => switch (key) {
    OptionKey.drawTime => _drawTime,
    OptionKey.propagate => _propagate,
    OptionKey.events => _events,
    _ => null,
  };

  @override
  void setCell(OptionKey key, Opt<Object?>? cell) {
    switch (key) {
      case OptionKey.drawTime:
        _drawTime = fitCell(cell, classifyString);
      case OptionKey.propagate:
        _propagate = fitCell(cell, classifyBool);
      case OptionKey.events:
        _events = fitCell(cell, (raw) => classifyUnion(raw, 16));
      default:
        throw ArgumentError.value(key, 'key', 'Not a key of FillerOptions');
    }
  }

  @override
  bool hasField(OptionKey key) => switch (key) {
    OptionKey.drawTime || OptionKey.propagate || OptionKey.events => true,
    _ => false,
  };

  @override
  Opt<Object?> classify(OptionKey key, Object? raw) => switch (key) {
    OptionKey.drawTime => classifyString(raw),
    OptionKey.propagate => classifyBool(raw),
    OptionKey.events => classifyUnion(raw, 16),
    _ => kind.classifyOther(raw),
  };
}

/// index.d.ts:2292 DecimationOptions (the union of index.d.ts:2283
/// LttbDecimationOptions and :2288 MinMaxDecimationOptions), the scope
/// `plugins.decimation`.
base class DecimationOptionsScope extends OptionScope {
  /// An empty scope.
  DecimationOptionsScope();

  @override
  ScopeKind get kind => ScopeKind.decimationOptions;

  Opt<bool>? _enabled;

  /// The cell of `enabled`, or Dart `null` when absent.
  Opt<bool>? get enabledCell => _enabled;

  /// Stores the cell of `enabled`. Dart `null` deletes the key.
  set enabledCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.enabled);
    } else {
      store(OptionKey.enabled, cell);
    }
  }

  /// Stores the plain value [value] of `enabled`.
  set enabled(bool value) => store(OptionKey.enabled, OptValue<bool>(value));

  Opt<double>? _threshold;

  /// The cell of `threshold`, or Dart `null` when absent.
  Opt<double>? get thresholdCell => _threshold;

  /// Stores the cell of `threshold`. Dart `null` deletes the key.
  set thresholdCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.threshold);
    } else {
      store(OptionKey.threshold, cell);
    }
  }

  /// Stores the plain value [value] of `threshold`.
  set threshold(double value) =>
      store(OptionKey.threshold, OptValue<double>(value));

  Opt<String>? _algorithm;

  /// The cell of `algorithm`, or Dart `null` when absent.
  Opt<String>? get algorithmCell => _algorithm;

  /// Stores the cell of `algorithm`. Dart `null` deletes the key.
  set algorithmCell(Opt<String>? cell) {
    if (cell == null) {
      delete(OptionKey.algorithm);
    } else {
      store(OptionKey.algorithm, cell);
    }
  }

  /// Stores the plain value [value] of `algorithm`.
  set algorithm(String value) =>
      store(OptionKey.algorithm, OptValue<String>(value));

  Opt<double>? _samples;

  /// The cell of `samples`, or Dart `null` when absent.
  Opt<double>? get samplesCell => _samples;

  /// Stores the cell of `samples`. Dart `null` deletes the key.
  set samplesCell(Opt<double>? cell) {
    if (cell == null) {
      delete(OptionKey.samples);
    } else {
      store(OptionKey.samples, cell);
    }
  }

  /// Stores the plain value [value] of `samples`.
  set samples(double value) =>
      store(OptionKey.samples, OptValue<double>(value));

  Opt<Object>? _events;

  /// The cell of `events`, or Dart `null` when absent.
  Opt<Object>? get eventsCell => _events;

  /// Stores the cell of `events`. Dart `null` deletes the key.
  set eventsCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.events);
    } else {
      store(OptionKey.events, cell);
    }
  }

  /// Stores the plain value [value] of `events`.
  set events(Object value) =>
      store(OptionKey.events, classify(OptionKey.events, value));

  @override
  Opt<Object?>? cellOf(OptionKey key) => switch (key) {
    OptionKey.enabled => _enabled,
    OptionKey.threshold => _threshold,
    OptionKey.algorithm => _algorithm,
    OptionKey.samples => _samples,
    OptionKey.events => _events,
    _ => null,
  };

  @override
  void setCell(OptionKey key, Opt<Object?>? cell) {
    switch (key) {
      case OptionKey.enabled:
        _enabled = fitCell(cell, classifyBool);
      case OptionKey.threshold:
        _threshold = fitCell(cell, classifyNumber);
      case OptionKey.algorithm:
        _algorithm = fitCell(cell, classifyString);
      case OptionKey.samples:
        _samples = fitCell(cell, classifyNumber);
      case OptionKey.events:
        _events = fitCell(cell, (raw) => classifyUnion(raw, 16));
      default:
        throw ArgumentError.value(key, 'key', 'Not a key of DecimationOptions');
    }
  }

  @override
  bool hasField(OptionKey key) => switch (key) {
    OptionKey.enabled ||
    OptionKey.threshold ||
    OptionKey.algorithm ||
    OptionKey.samples ||
    OptionKey.events => true,
    _ => false,
  };

  @override
  Opt<Object?> classify(OptionKey key, Object? raw) => switch (key) {
    OptionKey.enabled => classifyBool(raw),
    OptionKey.threshold => classifyNumber(raw),
    OptionKey.algorithm => classifyString(raw),
    OptionKey.samples => classifyNumber(raw),
    OptionKey.events => classifyUnion(raw, 16),
    _ => kind.classifyOther(raw),
  };
}

/// plugin.colors.ts:4 ColorsPluginOptions, the scope `plugins.colors`.
base class ColorsOptionsScope extends OptionScope {
  /// An empty scope.
  ColorsOptionsScope();

  @override
  ScopeKind get kind => ScopeKind.colorsOptions;

  Opt<bool>? _enabled;

  /// The cell of `enabled`, or Dart `null` when absent.
  Opt<bool>? get enabledCell => _enabled;

  /// Stores the cell of `enabled`. Dart `null` deletes the key.
  set enabledCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.enabled);
    } else {
      store(OptionKey.enabled, cell);
    }
  }

  /// Stores the plain value [value] of `enabled`.
  set enabled(bool value) => store(OptionKey.enabled, OptValue<bool>(value));

  Opt<bool>? _forceOverride;

  /// The cell of `forceOverride`, or Dart `null` when absent.
  Opt<bool>? get forceOverrideCell => _forceOverride;

  /// Stores the cell of `forceOverride`. Dart `null` deletes the key.
  set forceOverrideCell(Opt<bool>? cell) {
    if (cell == null) {
      delete(OptionKey.forceOverride);
    } else {
      store(OptionKey.forceOverride, cell);
    }
  }

  /// Stores the plain value [value] of `forceOverride`.
  set forceOverride(bool value) =>
      store(OptionKey.forceOverride, OptValue<bool>(value));

  Opt<Object>? _events;

  /// The cell of `events`, or Dart `null` when absent.
  Opt<Object>? get eventsCell => _events;

  /// Stores the cell of `events`. Dart `null` deletes the key.
  set eventsCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.events);
    } else {
      store(OptionKey.events, cell);
    }
  }

  /// Stores the plain value [value] of `events`.
  set events(Object value) =>
      store(OptionKey.events, classify(OptionKey.events, value));

  Opt<Object>? _dollarBorderColors;

  /// The cell of `$borderColors`, or Dart `null` when absent.
  Opt<Object>? get dollarBorderColorsCell => _dollarBorderColors;

  /// Stores the cell of `$borderColors`. Dart `null` deletes the key.
  set dollarBorderColorsCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.dollarBorderColors);
    } else {
      store(OptionKey.dollarBorderColors, cell);
    }
  }

  /// Stores the plain value [value] of `$borderColors`.
  set dollarBorderColors(Object value) => store(
    OptionKey.dollarBorderColors,
    classify(OptionKey.dollarBorderColors, value),
  );

  Opt<Object>? _dollarBackgroundColors;

  /// The cell of `$backgroundColors`, or Dart `null` when absent.
  Opt<Object>? get dollarBackgroundColorsCell => _dollarBackgroundColors;

  /// Stores the cell of `$backgroundColors`. Dart `null` deletes the key.
  set dollarBackgroundColorsCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.dollarBackgroundColors);
    } else {
      store(OptionKey.dollarBackgroundColors, cell);
    }
  }

  /// Stores the plain value [value] of `$backgroundColors`.
  set dollarBackgroundColors(Object value) => store(
    OptionKey.dollarBackgroundColors,
    classify(OptionKey.dollarBackgroundColors, value),
  );

  @override
  Opt<Object?>? cellOf(OptionKey key) => switch (key) {
    OptionKey.enabled => _enabled,
    OptionKey.forceOverride => _forceOverride,
    OptionKey.events => _events,
    OptionKey.dollarBorderColors => _dollarBorderColors,
    OptionKey.dollarBackgroundColors => _dollarBackgroundColors,
    _ => null,
  };

  @override
  void setCell(OptionKey key, Opt<Object?>? cell) {
    switch (key) {
      case OptionKey.enabled:
        _enabled = fitCell(cell, classifyBool);
      case OptionKey.forceOverride:
        _forceOverride = fitCell(cell, classifyBool);
      case OptionKey.events:
        _events = fitCell(cell, (raw) => classifyUnion(raw, 16));
      case OptionKey.dollarBorderColors:
        _dollarBorderColors = fitCell(cell, (raw) => classifyUnion(raw, 16));
      case OptionKey.dollarBackgroundColors:
        _dollarBackgroundColors = fitCell(
          cell,
          (raw) => classifyUnion(raw, 16),
        );
      default:
        throw ArgumentError.value(key, 'key', 'Not a key of ColorsOptions');
    }
  }

  @override
  bool hasField(OptionKey key) => switch (key) {
    OptionKey.enabled ||
    OptionKey.forceOverride ||
    OptionKey.events ||
    OptionKey.dollarBorderColors ||
    OptionKey.dollarBackgroundColors => true,
    _ => false,
  };

  @override
  Opt<Object?> classify(OptionKey key, Object? raw) => switch (key) {
    OptionKey.enabled => classifyBool(raw),
    OptionKey.forceOverride => classifyBool(raw),
    OptionKey.events => classifyUnion(raw, 16),
    OptionKey.dollarBorderColors => classifyUnion(raw, 16),
    OptionKey.dollarBackgroundColors => classifyUnion(raw, 16),
    _ => kind.classifyOther(raw),
  };
}

/// Port-only kind, the options of a plugin without a plugin kind (an inline or
/// a registered user plugin).
base class GenericPluginOptionsScope extends OptionScope {
  /// An empty scope.
  GenericPluginOptionsScope();

  @override
  ScopeKind get kind => ScopeKind.genericPluginOptions;

  Opt<Object>? _events;

  /// The cell of `events`, or Dart `null` when absent.
  Opt<Object>? get eventsCell => _events;

  /// Stores the cell of `events`. Dart `null` deletes the key.
  set eventsCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.events);
    } else {
      store(OptionKey.events, cell);
    }
  }

  /// Stores the plain value [value] of `events`.
  set events(Object value) =>
      store(OptionKey.events, classify(OptionKey.events, value));

  @override
  Opt<Object?>? cellOf(OptionKey key) => switch (key) {
    OptionKey.events => _events,
    _ => null,
  };

  @override
  void setCell(OptionKey key, Opt<Object?>? cell) {
    switch (key) {
      case OptionKey.events:
        _events = fitCell(cell, (raw) => classifyUnion(raw, 16));
      default:
        throw ArgumentError.value(
          key,
          'key',
          'Not a key of GenericPluginOptions',
        );
    }
  }

  @override
  bool hasField(OptionKey key) => switch (key) {
    OptionKey.events => true,
    _ => false,
  };

  @override
  Opt<Object?> classify(OptionKey key, Object? raw) => switch (key) {
    OptionKey.events => classifyUnion(raw, 16),
    _ => kind.classifyOther(raw),
  };
}

/// Port-only kind for the descriptor tree of Chart.defaults.describe
/// (core.defaults.js:165-175) and the `descriptors` statics, by option scope
/// path.
base class DescriptorsScope extends OptionScope {
  /// An empty scope.
  DescriptorsScope();

  @override
  ScopeKind get kind => ScopeKind.descriptors;

  Opt<Object>? _descScriptable;

  /// The cell of `_scriptable`, or Dart `null` when absent.
  Opt<Object>? get descScriptableCell => _descScriptable;

  /// Stores the cell of `_scriptable`. Dart `null` deletes the key.
  set descScriptableCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.descScriptable);
    } else {
      store(OptionKey.descScriptable, cell);
    }
  }

  /// Stores the plain value [value] of `_scriptable`.
  set descScriptable(Object value) => store(
    OptionKey.descScriptable,
    classify(OptionKey.descScriptable, value),
  );

  Opt<Object>? _descIndexable;

  /// The cell of `_indexable`, or Dart `null` when absent.
  Opt<Object>? get descIndexableCell => _descIndexable;

  /// Stores the cell of `_indexable`. Dart `null` deletes the key.
  set descIndexableCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.descIndexable);
    } else {
      store(OptionKey.descIndexable, cell);
    }
  }

  /// Stores the plain value [value] of `_indexable`.
  set descIndexable(Object value) =>
      store(OptionKey.descIndexable, classify(OptionKey.descIndexable, value));

  Opt<Object>? _descFallback;

  /// The cell of `_fallback`, or Dart `null` when absent.
  Opt<Object>? get descFallbackCell => _descFallback;

  /// Stores the cell of `_fallback`. Dart `null` deletes the key.
  set descFallbackCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.descFallback);
    } else {
      store(OptionKey.descFallback, cell);
    }
  }

  /// Stores the plain value [value] of `_fallback`.
  set descFallback(Object value) =>
      store(OptionKey.descFallback, classify(OptionKey.descFallback, value));

  Opt<Object>? _descAllKeys;

  /// The cell of `_allKeys`, or Dart `null` when absent.
  Opt<Object>? get descAllKeysCell => _descAllKeys;

  /// Stores the cell of `_allKeys`. Dart `null` deletes the key.
  set descAllKeysCell(Opt<Object>? cell) {
    if (cell == null) {
      delete(OptionKey.descAllKeys);
    } else {
      store(OptionKey.descAllKeys, cell);
    }
  }

  /// Stores the plain value [value] of `_allKeys`.
  set descAllKeys(Object value) =>
      store(OptionKey.descAllKeys, classify(OptionKey.descAllKeys, value));

  @override
  Opt<Object?>? cellOf(OptionKey key) => switch (key) {
    OptionKey.descScriptable => _descScriptable,
    OptionKey.descIndexable => _descIndexable,
    OptionKey.descFallback => _descFallback,
    OptionKey.descAllKeys => _descAllKeys,
    _ => null,
  };

  @override
  void setCell(OptionKey key, Opt<Object?>? cell) {
    switch (key) {
      case OptionKey.descScriptable:
        _descScriptable = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.descIndexable:
        _descIndexable = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.descFallback:
        _descFallback = fitCell(cell, (raw) => classifyUnion(raw, 64));
      case OptionKey.descAllKeys:
        _descAllKeys = fitCell(cell, (raw) => classifyUnion(raw, 64));
      default:
        throw ArgumentError.value(key, 'key', 'Not a key of Descriptors');
    }
  }

  @override
  bool hasField(OptionKey key) => switch (key) {
    OptionKey.descScriptable ||
    OptionKey.descIndexable ||
    OptionKey.descFallback ||
    OptionKey.descAllKeys => true,
    _ => false,
  };

  @override
  Opt<Object?> classify(OptionKey key, Object? raw) => switch (key) {
    OptionKey.descScriptable => classifyUnion(raw, 64),
    OptionKey.descIndexable => classifyUnion(raw, 64),
    OptionKey.descFallback => classifyUnion(raw, 64),
    OptionKey.descAllKeys => classifyUnion(raw, 64),
    _ => kind.classifyOther(raw),
  };
}
