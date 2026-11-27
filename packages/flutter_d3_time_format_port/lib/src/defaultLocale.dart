// Ported from d3-time-format v4.1.0 src/defaultLocale.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/defaultLocale.js` of d3-time-format 4.1.0.
library;

import 'package:flutter_d3_time_format_port/src/locale.dart';
import 'package:flutter_d3_time_format_port/src/locales.dart';

// DIVERGES(d3-time-format): adapt-time-format-typed-api, top-level delegating
// functions and defaultTimeLocale getter over typed TimeLocale.

TimeLocale _defaultTimeLocale = timeFormatLocale(timeLocaleEnUS);

/// The current default [TimeLocale].
TimeLocale get defaultTimeLocale => _defaultTimeLocale;

/// Alias for [defaultTimeLocale]`.format`: returns a local [TimeFormat] for
/// [specifier] using the current default locale.
TimeFormat timeFormat(String specifier) => _defaultTimeLocale.format(specifier);

/// Alias for [defaultTimeLocale]`.parse`: returns a local [TimeParse] for
/// [specifier] using the current default locale.
TimeParse timeParse(String specifier) => _defaultTimeLocale.parse(specifier);

/// Alias for [defaultTimeLocale]`.utcFormat`: returns a UTC [TimeFormat] for
/// [specifier] using the current default locale.
TimeFormat utcFormat(String specifier) =>
    _defaultTimeLocale.utcFormat(specifier);

/// Alias for [defaultTimeLocale]`.utcParse`: returns a UTC [TimeParse] for
/// [specifier] using the current default locale.
TimeParse utcParse(String specifier) => _defaultTimeLocale.utcParse(specifier);

/// Sets the default time locale to [definition], updating [timeFormat],
/// [timeParse], [utcFormat], and [utcParse], and returns the new [TimeLocale].
TimeLocale timeFormatDefaultLocale(TimeLocaleDefinition definition) =>
    _defaultTimeLocale = timeFormatLocale(definition);
