// Original code, not ported from d3-format: all 59 upstream locales.

/// All 59 built-in `d3-format` v3.1.2 locale definitions as `const`
/// [FormatLocaleDefinition] objects.
library;

import 'package:flutter_d3_format_port/src/locale.dart';

const List<int> _group3 = [3];
const List<String> _arabicNumerals = [
  '٠',
  '١',
  '٢',
  '٣',
  '٤',
  '٥',
  '٦',
  '٧',
  '٨',
  '٩',
];

/// Locale definition for `ar-001`.
const FormatLocaleDefinition localeAr001 = FormatLocaleDefinition(
  decimal: '٫',
  thousands: '٬',
  grouping: _group3,
  currency: ('', ''),
  numerals: _arabicNumerals,
);

/// Locale definition for `ar-AE`.
const FormatLocaleDefinition localeArAE = FormatLocaleDefinition(
  decimal: '٫',
  thousands: '٬',
  grouping: _group3,
  currency: ('', ' د.إ.'),
  numerals: _arabicNumerals,
);

/// Locale definition for `ar-BH`.
const FormatLocaleDefinition localeArBH = FormatLocaleDefinition(
  decimal: '٫',
  thousands: '٬',
  grouping: _group3,
  currency: ('', ' د.ب.'),
  numerals: _arabicNumerals,
);

/// Locale definition for `ar-DJ`.
const FormatLocaleDefinition localeArDJ = FormatLocaleDefinition(
  decimal: '٫',
  thousands: '٬',
  grouping: _group3,
  currency: ('\u200fFdj ', ''),
  numerals: _arabicNumerals,
);

/// Locale definition for `ar-DZ`.
const FormatLocaleDefinition localeArDZ = FormatLocaleDefinition(
  decimal: ',',
  thousands: '.',
  grouping: _group3,
  currency: ('د.ج. ', ''),
);

/// Locale definition for `ar-EG`.
const FormatLocaleDefinition localeArEG = FormatLocaleDefinition(
  decimal: '٫',
  thousands: '٬',
  grouping: _group3,
  currency: ('', ' ج.م.'),
  numerals: _arabicNumerals,
);

/// Locale definition for `ar-EH`.
const FormatLocaleDefinition localeArEH = FormatLocaleDefinition(
  thousands: ',',
  grouping: _group3,
  currency: ('د.م. ', ''),
);

/// Locale definition for `ar-ER`.
const FormatLocaleDefinition localeArER = FormatLocaleDefinition(
  decimal: '٫',
  thousands: '٬',
  grouping: _group3,
  currency: ('Nfk ', ''),
  numerals: _arabicNumerals,
);

/// Locale definition for `ar-IL`.
const FormatLocaleDefinition localeArIL = FormatLocaleDefinition(
  decimal: '٫',
  thousands: '٬',
  grouping: _group3,
  currency: ('₪ ', ''),
  numerals: _arabicNumerals,
);

/// Locale definition for `ar-IQ`.
const FormatLocaleDefinition localeArIQ = FormatLocaleDefinition(
  decimal: '٫',
  thousands: '٬',
  grouping: _group3,
  currency: ('', ' د.ع.'),
  numerals: _arabicNumerals,
);

/// Locale definition for `ar-JO`.
const FormatLocaleDefinition localeArJO = FormatLocaleDefinition(
  decimal: '٫',
  thousands: '٬',
  grouping: _group3,
  currency: ('', ' د.أ.'),
  numerals: _arabicNumerals,
);

/// Locale definition for `ar-KM`.
const FormatLocaleDefinition localeArKM = FormatLocaleDefinition(
  decimal: '٫',
  thousands: '٬',
  grouping: _group3,
  currency: ('', ' ف.ج.ق.'),
  numerals: _arabicNumerals,
);

/// Locale definition for `ar-KW`.
const FormatLocaleDefinition localeArKW = FormatLocaleDefinition(
  decimal: '٫',
  thousands: '٬',
  grouping: _group3,
  currency: ('', ' د.ك.'),
  numerals: _arabicNumerals,
);

/// Locale definition for `ar-LB`.
const FormatLocaleDefinition localeArLB = FormatLocaleDefinition(
  decimal: '٫',
  thousands: '٬',
  grouping: _group3,
  currency: ('', ' ل.ل.'),
  numerals: _arabicNumerals,
);

/// Locale definition for `ar-LY`.
const FormatLocaleDefinition localeArLY = FormatLocaleDefinition(
  decimal: ',',
  thousands: '.',
  grouping: _group3,
  currency: ('د.ل. ', ''),
);

/// Locale definition for `ar-MA`.
const FormatLocaleDefinition localeArMA = FormatLocaleDefinition(
  decimal: ',',
  thousands: '.',
  grouping: _group3,
  currency: ('د.م. ', ''),
);

/// Locale definition for `ar-MR`.
const FormatLocaleDefinition localeArMR = FormatLocaleDefinition(
  decimal: '٫',
  thousands: '٬',
  grouping: _group3,
  currency: ('', ' أ.م.'),
  numerals: _arabicNumerals,
);

/// Locale definition for `ar-OM`.
const FormatLocaleDefinition localeArOM = FormatLocaleDefinition(
  decimal: '٫',
  thousands: '٬',
  grouping: _group3,
  currency: ('', ' ر.ع.'),
  numerals: _arabicNumerals,
);

/// Locale definition for `ar-PS`.
const FormatLocaleDefinition localeArPS = FormatLocaleDefinition(
  decimal: '٫',
  thousands: '٬',
  grouping: _group3,
  currency: ('₪ ', ''),
  numerals: _arabicNumerals,
);

/// Locale definition for `ar-QA`.
const FormatLocaleDefinition localeArQA = FormatLocaleDefinition(
  decimal: '٫',
  thousands: '٬',
  grouping: _group3,
  currency: ('', ' ر.ق.'),
  numerals: _arabicNumerals,
);

/// Locale definition for `ar-SA`.
const FormatLocaleDefinition localeArSA = FormatLocaleDefinition(
  decimal: '٫',
  thousands: '٬',
  grouping: _group3,
  currency: ('', ' ر.س.'),
  numerals: _arabicNumerals,
);

/// Locale definition for `ar-SD`.
const FormatLocaleDefinition localeArSD = FormatLocaleDefinition(
  decimal: '٫',
  thousands: '٬',
  grouping: _group3,
  currency: ('', ' ج.س.'),
  numerals: _arabicNumerals,
);

/// Locale definition for `ar-SO`.
const FormatLocaleDefinition localeArSO = FormatLocaleDefinition(
  decimal: '٫',
  thousands: '٬',
  grouping: _group3,
  currency: ('\u200fS ', ''),
  numerals: _arabicNumerals,
);

/// Locale definition for `ar-SS`.
const FormatLocaleDefinition localeArSS = FormatLocaleDefinition(
  decimal: '٫',
  thousands: '٬',
  grouping: _group3,
  currency: ('£ ', ''),
  numerals: _arabicNumerals,
);

/// Locale definition for `ar-SY`.
const FormatLocaleDefinition localeArSY = FormatLocaleDefinition(
  decimal: '٫',
  thousands: '٬',
  grouping: _group3,
  currency: ('', ' ل.س.'),
  numerals: _arabicNumerals,
);

/// Locale definition for `ar-TD`.
const FormatLocaleDefinition localeArTD = FormatLocaleDefinition(
  decimal: '٫',
  thousands: '٬',
  grouping: _group3,
  currency: ('\u200fFCFA ', ''),
  numerals: _arabicNumerals,
);

/// Locale definition for `ar-TN`.
const FormatLocaleDefinition localeArTN = FormatLocaleDefinition(
  decimal: ',',
  thousands: '.',
  grouping: _group3,
  currency: ('د.ت. ', ''),
);

/// Locale definition for `ar-YE`.
const FormatLocaleDefinition localeArYE = FormatLocaleDefinition(
  decimal: '٫',
  thousands: '٬',
  grouping: _group3,
  currency: ('', ' ر.ى.'),
  numerals: _arabicNumerals,
);

/// Locale definition for `ca-ES`.
const FormatLocaleDefinition localeCaES = FormatLocaleDefinition(
  decimal: ',',
  thousands: '.',
  grouping: _group3,
  currency: ('', '\u00a0€'),
);

/// Locale definition for `cs-CZ`.
const FormatLocaleDefinition localeCsCZ = FormatLocaleDefinition(
  decimal: ',',
  thousands: '\u00a0',
  grouping: _group3,
  currency: ('', '\u00a0Kč'),
);

/// Locale definition for `da-DK`.
const FormatLocaleDefinition localeDaDK = FormatLocaleDefinition(
  decimal: ',',
  thousands: '.',
  grouping: _group3,
  currency: ('', ' kr'),
);

/// Locale definition for `de-CH`.
const FormatLocaleDefinition localeDeCH = FormatLocaleDefinition(
  decimal: ',',
  thousands: "'",
  grouping: _group3,
  currency: ('', '\u00a0CHF'),
);

/// Locale definition for `de-DE`.
const FormatLocaleDefinition localeDeDE = FormatLocaleDefinition(
  decimal: ',',
  thousands: '.',
  grouping: _group3,
  currency: ('', '\u00a0€'),
);

/// Locale definition for `en-CA`.
const FormatLocaleDefinition localeEnCA = FormatLocaleDefinition(
  thousands: ',',
  grouping: _group3,
  currency: (r'$', ''),
);

/// Locale definition for `en-GB`.
const FormatLocaleDefinition localeEnGB = FormatLocaleDefinition(
  thousands: ',',
  grouping: _group3,
  currency: ('£', ''),
);

/// Locale definition for `en-IE`.
const FormatLocaleDefinition localeEnIE = FormatLocaleDefinition(
  thousands: ',',
  grouping: _group3,
  currency: ('€', ''),
);

/// Locale definition for `en-IN`.
const FormatLocaleDefinition localeEnIN = FormatLocaleDefinition(
  thousands: ',',
  grouping: [3, 2, 2, 2, 2, 2, 2, 2, 2, 2],
  currency: ('₹', ''),
);

/// Locale definition for `en-US`.
const FormatLocaleDefinition localeEnUS = FormatLocaleDefinition(
  thousands: ',',
  grouping: _group3,
  currency: (r'$', ''),
);

/// Locale definition for `es-BO`.
const FormatLocaleDefinition localeEsBO = FormatLocaleDefinition(
  decimal: ',',
  thousands: '.',
  grouping: _group3,
  currency: ('Bs\u00a0', ''),
  percent: '\u202f%',
);

/// Locale definition for `es-ES`.
const FormatLocaleDefinition localeEsES = FormatLocaleDefinition(
  decimal: ',',
  thousands: '.',
  grouping: _group3,
  currency: ('', '\u00a0€'),
);

/// Locale definition for `es-MX`.
const FormatLocaleDefinition localeEsMX = FormatLocaleDefinition(
  thousands: ',',
  grouping: _group3,
  currency: (r'$', ''),
);

/// Locale definition for `fi-FI`.
const FormatLocaleDefinition localeFiFI = FormatLocaleDefinition(
  decimal: ',',
  thousands: '\u00a0',
  grouping: _group3,
  currency: ('', '\u00a0€'),
);

/// Locale definition for `fr-CA`.
const FormatLocaleDefinition localeFrCA = FormatLocaleDefinition(
  decimal: ',',
  thousands: '\u00a0',
  grouping: _group3,
  currency: ('', r'$'),
);

/// Locale definition for `fr-FR`.
const FormatLocaleDefinition localeFrFR = FormatLocaleDefinition(
  decimal: ',',
  thousands: '\u00a0',
  grouping: _group3,
  currency: ('', '\u00a0€'),
  percent: '\u202f%',
);

/// Locale definition for `he-IL`.
const FormatLocaleDefinition localeHeIL = FormatLocaleDefinition(
  thousands: ',',
  grouping: _group3,
  currency: ('₪', ''),
);

/// Locale definition for `hu-HU`.
const FormatLocaleDefinition localeHuHU = FormatLocaleDefinition(
  decimal: ',',
  thousands: '\u00a0',
  grouping: _group3,
  currency: ('', '\u00a0Ft'),
);

/// Locale definition for `it-IT`.
const FormatLocaleDefinition localeItIT = FormatLocaleDefinition(
  decimal: ',',
  thousands: '.',
  grouping: _group3,
  currency: ('€', ''),
);

/// Locale definition for `ja-JP`.
const FormatLocaleDefinition localeJaJP = FormatLocaleDefinition(
  thousands: ',',
  grouping: _group3,
  currency: ('', '円'),
);

/// Locale definition for `ko-KR`.
const FormatLocaleDefinition localeKoKR = FormatLocaleDefinition(
  thousands: ',',
  grouping: _group3,
  currency: ('₩', ''),
);

/// Locale definition for `mk-MK`.
const FormatLocaleDefinition localeMkMK = FormatLocaleDefinition(
  decimal: ',',
  thousands: '.',
  grouping: _group3,
  currency: ('', '\u00a0ден.'),
);

/// Locale definition for `nl-NL`.
const FormatLocaleDefinition localeNlNL = FormatLocaleDefinition(
  decimal: ',',
  thousands: '.',
  grouping: _group3,
  currency: ('€\u00a0', ''),
);

/// Locale definition for `pl-PL`.
const FormatLocaleDefinition localePlPL = FormatLocaleDefinition(
  decimal: ',',
  thousands: '.',
  grouping: _group3,
  currency: ('', 'zł'),
);

/// Locale definition for `pt-BR`.
const FormatLocaleDefinition localePtBR = FormatLocaleDefinition(
  decimal: ',',
  thousands: '.',
  grouping: _group3,
  currency: (r'R$', ''),
);

/// Locale definition for `pt-PT`.
const FormatLocaleDefinition localePtPT = FormatLocaleDefinition(
  decimal: ',',
  thousands: '\u00a0',
  grouping: _group3,
  currency: ('', '\u00a0€'),
);

/// Locale definition for `ru-RU`.
const FormatLocaleDefinition localeRuRU = FormatLocaleDefinition(
  decimal: ',',
  thousands: '\u00a0',
  grouping: _group3,
  currency: ('', '\u00a0₽'),
);

/// Locale definition for `sl-SI`.
const FormatLocaleDefinition localeSlSI = FormatLocaleDefinition(
  decimal: ',',
  thousands: '.',
  grouping: _group3,
  currency: ('', '\u00a0€'),
);

/// Locale definition for `sv-SE`.
const FormatLocaleDefinition localeSvSE = FormatLocaleDefinition(
  decimal: ',',
  thousands: '\u00a0',
  grouping: _group3,
  currency: ('', ' kr'),
);

/// Locale definition for `uk-UA`.
const FormatLocaleDefinition localeUkUA = FormatLocaleDefinition(
  decimal: ',',
  thousands: '\u00a0',
  grouping: _group3,
  currency: ('', '\u00a0₴.'),
);

/// Locale definition for `zh-CN`.
const FormatLocaleDefinition localeZhCN = FormatLocaleDefinition(
  thousands: ',',
  grouping: _group3,
  currency: ('¥', ''),
);

/// All 59 built-in `d3-format` v3.1.2 locales keyed by BCP-47 tag.
const Map<String, FormatLocaleDefinition> formatLocales = {
  'ar-001': localeAr001,
  'ar-AE': localeArAE,
  'ar-BH': localeArBH,
  'ar-DJ': localeArDJ,
  'ar-DZ': localeArDZ,
  'ar-EG': localeArEG,
  'ar-EH': localeArEH,
  'ar-ER': localeArER,
  'ar-IL': localeArIL,
  'ar-IQ': localeArIQ,
  'ar-JO': localeArJO,
  'ar-KM': localeArKM,
  'ar-KW': localeArKW,
  'ar-LB': localeArLB,
  'ar-LY': localeArLY,
  'ar-MA': localeArMA,
  'ar-MR': localeArMR,
  'ar-OM': localeArOM,
  'ar-PS': localeArPS,
  'ar-QA': localeArQA,
  'ar-SA': localeArSA,
  'ar-SD': localeArSD,
  'ar-SO': localeArSO,
  'ar-SS': localeArSS,
  'ar-SY': localeArSY,
  'ar-TD': localeArTD,
  'ar-TN': localeArTN,
  'ar-YE': localeArYE,
  'ca-ES': localeCaES,
  'cs-CZ': localeCsCZ,
  'da-DK': localeDaDK,
  'de-CH': localeDeCH,
  'de-DE': localeDeDE,
  'en-CA': localeEnCA,
  'en-GB': localeEnGB,
  'en-IE': localeEnIE,
  'en-IN': localeEnIN,
  'en-US': localeEnUS,
  'es-BO': localeEsBO,
  'es-ES': localeEsES,
  'es-MX': localeEsMX,
  'fi-FI': localeFiFI,
  'fr-CA': localeFrCA,
  'fr-FR': localeFrFR,
  'he-IL': localeHeIL,
  'hu-HU': localeHuHU,
  'it-IT': localeItIT,
  'ja-JP': localeJaJP,
  'ko-KR': localeKoKR,
  'mk-MK': localeMkMK,
  'nl-NL': localeNlNL,
  'pl-PL': localePlPL,
  'pt-BR': localePtBR,
  'pt-PT': localePtPT,
  'ru-RU': localeRuRU,
  'sl-SI': localeSlSI,
  'sv-SE': localeSvSE,
  'uk-UA': localeUkUA,
  'zh-CN': localeZhCN,
};
