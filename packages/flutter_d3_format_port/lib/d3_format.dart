// Original code, not ported from d3-format: the pure library of the package.

/// d3-format 3.1.2 in native Dart, with no Flutter import (ADR 0011, D3 ADR
/// 0016).
///
/// Exports every pure file of the port without `show`/`hide` combinators so it
/// compiles for the Dart VM, AOT, JavaScript, and WebAssembly with zero
/// runtime dependencies.
library;

export 'package:flutter_d3_format_port/src/defaultLocale.dart';
export 'package:flutter_d3_format_port/src/exponent.dart';
export 'package:flutter_d3_format_port/src/formatDecimal.dart';
export 'package:flutter_d3_format_port/src/formatGroup.dart';
export 'package:flutter_d3_format_port/src/formatNumerals.dart';
export 'package:flutter_d3_format_port/src/formatPrefixAuto.dart';
export 'package:flutter_d3_format_port/src/formatRounded.dart';
export 'package:flutter_d3_format_port/src/formatSpecifier.dart';
export 'package:flutter_d3_format_port/src/formatTrim.dart';
export 'package:flutter_d3_format_port/src/formatTypes.dart';
export 'package:flutter_d3_format_port/src/identity.dart';
export 'package:flutter_d3_format_port/src/index.dart';
export 'package:flutter_d3_format_port/src/locale.dart';
export 'package:flutter_d3_format_port/src/locales.dart';
export 'package:flutter_d3_format_port/src/precisionFixed.dart';
export 'package:flutter_d3_format_port/src/precisionPrefix.dart';
export 'package:flutter_d3_format_port/src/precisionRound.dart';
export 'package:flutter_d3_format_port/src/upstream.dart';
