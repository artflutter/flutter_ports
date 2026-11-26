// Ported from d3-format v3.1.2 test/arabicLocale-test.js (ISC, Mike Bostock).
// ignore_for_file: file_names

import 'package:flutter_d3_format_port/d3_format.dart';
import 'package:test/test.dart';

FormatLocale _locale(String tag) => formatLocale(formatLocales[tag]!);

void main() {
  test('formatLocale() can format numbers using ar-001 locale', () {
    expect(_locale('ar-001').format(r'$,.2f')(-1234.56), '−١٬٢٣٤٫٥٦');
  });

  test('formatLocale() can format numbers using ar-AE locale', () {
    expect(_locale('ar-AE').format(r'$,.2f')(1234.56), '١٬٢٣٤٫٥٦ د.إ.');
  });

  test('formatLocale() can format numbers using ar-BH locale', () {
    expect(_locale('ar-BH').format(r'$,.2f')(1234.56), '١٬٢٣٤٫٥٦ د.ب.');
  });

  test('formatLocale() can format numbers using ar-DJ locale', () {
    expect(_locale('ar-DJ').format(r'$,.2f')(1234.56), '\u200fFdj ١٬٢٣٤٫٥٦');
  });

  test('formatLocale() can format numbers using ar-DZ locale', () {
    expect(_locale('ar-DZ').format(r'$,.2f')(1234.56), 'د.ج. 1.234,56');
  });

  test('formatLocale() can format numbers using ar-EG locale', () {
    expect(_locale('ar-EG').format(r'$,.2f')(1234.56), '١٬٢٣٤٫٥٦ ج.م.');
  });

  test('formatLocale() can format numbers using ar-EH locale', () {
    expect(_locale('ar-EH').format(r'$,.2f')(1234.56), 'د.م. 1,234.56');
  });

  test('formatLocale() can format numbers using ar-ER locale', () {
    expect(_locale('ar-ER').format(r'$,.2f')(1234.56), 'Nfk ١٬٢٣٤٫٥٦');
  });

  test('formatLocale() can format numbers using ar-IL locale', () {
    expect(_locale('ar-IL').format(r'$,.2f')(1234.56), '₪ ١٬٢٣٤٫٥٦');
  });

  test('formatLocale() can format numbers using ar-IQ locale', () {
    expect(_locale('ar-IQ').format(r'$,.2f')(1234.56), '١٬٢٣٤٫٥٦ د.ع.');
  });

  test('formatLocale() can format numbers using ar-JO locale', () {
    expect(_locale('ar-JO').format(r'$,.2f')(1234.56), '١٬٢٣٤٫٥٦ د.أ.');
  });

  test('formatLocale() can format numbers using ar-KM locale', () {
    expect(_locale('ar-KM').format(r'$,.2f')(1234.56), '١٬٢٣٤٫٥٦ ف.ج.ق.');
  });

  test('formatLocale() can format numbers using ar-KW locale', () {
    expect(_locale('ar-KW').format(r'$,.2f')(1234.56), '١٬٢٣٤٫٥٦ د.ك.');
  });

  test('formatLocale() can format numbers using ar-LB locale', () {
    expect(_locale('ar-LB').format(r'$,.2f')(1234.56), '١٬٢٣٤٫٥٦ ل.ل.');
  });

  test('formatLocale() can format numbers using ar-MA locale', () {
    expect(_locale('ar-MA').format(r'$,.2f')(1234.56), 'د.م. 1.234,56');
  });

  test('formatLocale() can format numbers using ar-MR locale', () {
    expect(_locale('ar-MR').format(r'$,.2f')(1234.56), '١٬٢٣٤٫٥٦ أ.م.');
  });

  test('formatLocale() can format numbers using ar-OM locale', () {
    expect(_locale('ar-OM').format(r'$,.2f')(1234.56), '١٬٢٣٤٫٥٦ ر.ع.');
  });

  test('formatLocale() can format numbers using ar-PS locale', () {
    expect(_locale('ar-PS').format(r'$,.2f')(1234.56), '₪ ١٬٢٣٤٫٥٦');
  });

  test('formatLocale() can format numbers using ar-QA locale', () {
    expect(_locale('ar-QA').format(r'$,.2f')(1234.56), '١٬٢٣٤٫٥٦ ر.ق.');
  });

  test('formatLocale() can format numbers using ar-SA locale', () {
    expect(_locale('ar-SA').format(r'$,.2f')(1234.56), '١٬٢٣٤٫٥٦ ر.س.');
  });

  test('formatLocale() can format numbers using ar-SD locale', () {
    expect(_locale('ar-SD').format(r'$,.2f')(1234.56), '١٬٢٣٤٫٥٦ ج.س.');
  });

  test('formatLocale() can format numbers using ar-SO locale', () {
    expect(_locale('ar-SO').format(r'$,.2f')(1234.56), '\u200fS ١٬٢٣٤٫٥٦');
  });

  test('formatLocale() can format numbers using ar-SS locale', () {
    expect(_locale('ar-SS').format(r'$,.2f')(1234.56), '£ ١٬٢٣٤٫٥٦');
  });

  test('formatLocale() can format numbers using ar-SY locale', () {
    expect(_locale('ar-SY').format(r'$,.2f')(1234.56), '١٬٢٣٤٫٥٦ ل.س.');
  });

  test('formatLocale() can format numbers using ar-TD locale', () {
    expect(_locale('ar-TD').format(r'$,.2f')(1234.56), '\u200fFCFA ١٬٢٣٤٫٥٦');
  });

  test('formatLocale() can format numbers using ar-TN locale', () {
    expect(_locale('ar-TN').format(r'$,.2f')(1234.56), 'د.ت. 1.234,56');
  });

  test('formatLocale() can format numbers using ar-YE locale', () {
    expect(_locale('ar-YE').format(r'$,.2f')(1234.56), '١٬٢٣٤٫٥٦ ر.ى.');
  });
}
