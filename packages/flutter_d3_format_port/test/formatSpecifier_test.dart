// Ported from d3-format v3.1.2 test/formatSpecifier-test.js (ISC, Mike Bostock).
// ignore_for_file: file_names

import 'package:flutter_d3_format_port/d3_format.dart';
import 'package:test/test.dart';

void main() {
  test('formatSpecifier(specifier) throws an error for invalid formats', () {
    expect(
      () => formatSpecifier('foo'),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('invalid format: foo'),
        ),
      ),
    );
    expect(
      () => formatSpecifier('.-2s'),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('invalid format: .-2s'),
        ),
      ),
    );
    expect(
      () => formatSpecifier('.f'),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('invalid format: .f'),
        ),
      ),
    );
  });

  test('formatSpecifier(specifier) returns an instanceof formatSpecifier', () {
    final s = formatSpecifier('');
    expect(s, isA<FormatSpecifier>());
  });

  test('formatSpecifier("") has the expected defaults', () {
    final s = formatSpecifier('');
    expect(s.fill, ' ');
    expect(s.align, '>');
    expect(s.sign, '-');
    expect(s.symbol, '');
    expect(s.zero, isFalse);
    expect(s.width, isNull);
    expect(s.comma, isFalse);
    expect(s.precision, isNull);
    expect(s.trim, isFalse);
    expect(s.type, '');
  });

  test('formatSpecifier(specifier) preserves unknown types', () {
    final s = formatSpecifier('q');
    expect(s.trim, isFalse);
    expect(s.type, 'q');
  });

  test('formatSpecifier(specifier) preserves shorthand', () {
    final s = formatSpecifier('');
    expect(s.trim, isFalse);
    expect(s.type, '');
  });

  test(
    'formatSpecifier(specifier).toString() reflects current field values',
    () {
      final s = formatSpecifier('');
      expect((s..fill = '_').toString(), '_>-');
      expect((s..align = '^').toString(), '_^-');
      expect((s..sign = '+').toString(), '_^+');
      expect((s..symbol = r'$').toString(), r'_^+$');
      expect((s..zero = true).toString(), r'_^+$0');
      expect((s..width = 12).toString(), r'_^+$012');
      expect((s..comma = true).toString(), r'_^+$012,');
      expect((s..precision = 2).toString(), r'_^+$012,.2');
      expect((s..type = 'f').toString(), r'_^+$012,.2f');
      expect((s..trim = true).toString(), r'_^+$012,.2~f');
      expect(formatFromSpecifier(s)(42), r'+$0,000,000,042');
      expect(format(s.toString())(42), r'+$0,000,000,042');
    },
  );

  test('formatSpecifier(specifier).toString() clamps precision to zero', () {
    final s = formatSpecifier('');
    expect((s..precision = -1).toString(), ' >-.0');
  });

  test('formatSpecifier(specifier).toString() clamps width to one', () {
    final s = formatSpecifier('');
    expect((s..width = -1).toString(), ' >-1');
  });

  test('new FormatSpecifier({}) has the expected defaults', () {
    final s = FormatSpecifier();
    expect(s.fill, ' ');
    expect(s.align, '>');
    expect(s.sign, '-');
    expect(s.symbol, '');
    expect(s.zero, isFalse);
    expect(s.width, isNull);
    expect(s.comma, isFalse);
    expect(s.precision, isNull);
    expect(s.trim, isFalse);
    expect(s.type, '');
  });

  // DIVERGES(d3-format): adapt-format-typed-api, typed FormatSpecifier args
  test(
    'new FormatSpecifier({…}) coerces all inputs to the expected types',
    () {},
    skip: 'diverges: adapt-format-typed-api',
  );
}
