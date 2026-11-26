// Ported from d3-format v3.1.2 src/defaultLocale.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/defaultLocale.js` of d3-format 3.1.2.
library;

import 'package:flutter_d3_format_port/src/formatSpecifier.dart';
import 'package:flutter_d3_format_port/src/locale.dart';

// DIVERGES(d3-format): adapt-format-typed-api, top-level delegating functions

FormatLocale _defaultLocale = formatLocale(
  const FormatLocaleDefinition(
    thousands: ',',
    grouping: [3],
    currency: (r'$', ''),
  ),
);

/// The current default [FormatLocale].
FormatLocale get defaultLocale => _defaultLocale;

/// Alias for [defaultLocale]`.format`: returns a [NumberFormat] for
/// [specifier] using the current default locale.
NumberFormat format(
  String specifier, {
  String prefix = '',
  String suffix = '',
}) => _defaultLocale.format(specifier, prefix: prefix, suffix: suffix);

/// Alias for [defaultLocale]`.formatFromSpecifier`: returns a [NumberFormat]
/// for a pre-parsed [FormatSpecifier] using the current default locale.
NumberFormat formatFromSpecifier(
  FormatSpecifier specifier, {
  String prefix = '',
  String suffix = '',
}) => _defaultLocale.formatFromSpecifier(
  specifier,
  prefix: prefix,
  suffix: suffix,
);

/// Alias for [defaultLocale]`.formatPrefix`: returns a [NumberFormat] scaled
/// to the SI prefix appropriate for [value] using the current default locale.
NumberFormat formatPrefix(String specifier, num value) =>
    _defaultLocale.formatPrefix(specifier, value);

/// Alias for [defaultLocale]`.formatPrefixFromSpecifier`: returns a
/// [NumberFormat] for a pre-parsed [FormatSpecifier] scaled to [value] using
/// the current default locale.
NumberFormat formatPrefixFromSpecifier(FormatSpecifier specifier, num value) =>
    _defaultLocale.formatPrefixFromSpecifier(specifier, value);

/// Sets the default locale to [definition], updating [format] and
/// [formatPrefix], and returns the new [FormatLocale].
FormatLocale formatDefaultLocale(FormatLocaleDefinition definition) =>
    _defaultLocale = formatLocale(definition);
