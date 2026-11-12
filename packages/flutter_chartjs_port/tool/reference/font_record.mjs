// Original code, not ported from Chart.js: the fonts of the reference data.
//
// The port holds a font as a ChartTextStyle, a Flutter TextStyle (Chart.js
// ADR 0116, row adapt-text-style-fonts). The generators read the upstream
// values here:
// - fontRecord gives the record of a CSS font text of toFontString, for a
//   setFont call: {font: {family, fallback, size, weight, style}}. The Dart
//   harness compares these values with the fields of the recorded TextStyle.
// - dartFont gives the Dart literal of an upstream font object of a config,
//   a ChartTextStyle with the same fields.
// A family list is the first family (fontFamily) and the other families
// (fontFamilyFallback, an empty list for one family): a TextStyle merges
// the two fields one by one, and the upstream family list is one value.

/** The CSS style keywords of toFontString (helpers.options.ts:8). */
const STYLES = new Set(['normal', 'italic', 'initial', 'inherit', 'unset']);

/** The families of a CSS family list, without quotes. */
export function families(text) {
  return String(text)
    .split(',')
    .map((name) => name.trim().replace(/^(['"])(.*)\1$/, '$2'))
    .filter((name) => name !== '');
}

/** The weight value of a CSS weight: a number, or null. */
function weightValue(weight) {
  if (weight === undefined || weight === null) return null;
  if (weight === 'bold' || weight === 'bolder') return 700;
  if (weight === 'normal') return 400;
  if (weight === 'lighter') return 100;
  const n = Number(weight);
  if (!Number.isFinite(n)) throw new Error(`No font weight for ${String(weight)}`);
  return n;
}

/**
 * The FontStyle name of a CSS style: 'normal', 'italic' (also for
 * 'oblique'), or null (also for 'initial', 'inherit' and 'unset').
 */
function styleName(style) {
  if (style === 'normal') return 'normal';
  if (style === 'italic' || String(style).startsWith('oblique')) return 'italic';
  return null;
}

/**
 * The record of the CSS font text [css] of toFontString, or null for a null
 * text: {font: {family, fallback, size, weight, style}}.
 */
export function fontRecord(css) {
  if (css === null || css === undefined) return null;
  const tokens = String(css).split(' ');
  const sizeAt = tokens.findIndex((t) => /^-?\d+(\.\d+)?(e[+-]?\d+)?px$/.test(t));
  if (sizeAt < 0) throw new Error(`No size in the font ${css}`);
  const before = tokens.slice(0, sizeAt);
  let style = null;
  let weight = null;
  if (before.length > 0 && (STYLES.has(before[0]) || before[0] === 'oblique')) {
    style = before[0];
    weight = before.slice(1).filter((t) => !/deg$/.test(t)).join(' ') || null;
  } else if (before.length > 0) {
    weight = before.join(' ');
  }
  const list = families(tokens.slice(sizeAt + 1).join(' '));
  return {
    font: {
      family: list[0] ?? null,
      fallback: list.slice(1),
      size: Number(tokens[sizeAt].slice(0, -2)),
      weight: weightValue(weight),
      style: styleName(style),
    },
  };
}

/** A number as a Dart literal: an int for a whole number. */
function num(v) {
  return Number.isInteger(v) && !Object.is(v, -0) ? String(v) : String(v);
}

/** A string as a Dart literal. */
function str(v) {
  return v.includes("'") && !v.includes('"') ? `"${v}"` : `'${v.replace(/[\\$']/g, '\\$&')}'`;
}

/**
 * The Dart literal of the upstream font object [font]: a ChartTextStyle with
 * its fields. A line height in pixels, in em or in percent, and a size as
 * text, have no form: the generator stops on them.
 */
export function dartFont(font) {
  const fields = [];
  if (font.family !== undefined && font.family !== null) {
    const list = families(font.family);
    fields.push(`fontFamily: ${str(list[0])}`);
    fields.push(`fontFamilyFallback: [${list.slice(1).map(str).join(', ')}]`);
  }
  if (font.size !== undefined && font.size !== null) {
    if (typeof font.size !== 'number') throw new Error(`A font size as text: ${String(font.size)}`);
    fields.push(`fontSize: ${num(font.size)}`);
  }
  if (styleName(font.style) !== null) {
    fields.push(`fontStyle: FontStyle.${styleName(font.style)}`);
  }
  if (font.weight !== undefined && font.weight !== null) {
    fields.push(`fontWeight: ${weightLiteral(weightValue(font.weight))}`);
  }
  if (font.lineHeight !== undefined && font.lineHeight !== null && font.lineHeight !== 'normal') {
    if (typeof font.lineHeight !== 'number') {
      throw new Error(`A line height as text: ${String(font.lineHeight)}`);
    }
    fields.push(`height: ${num(font.lineHeight)}`);
  }
  for (const key of Object.keys(font)) {
    if (!['family', 'size', 'style', 'weight', 'lineHeight'].includes(key)) {
      throw new Error(`An unknown font key: ${key}`);
    }
  }
  return `ChartTextStyle(${fields.join(', ')})`;
}

/** A line height of a font object: a number, or null for 'normal'. */
function heightValue(lineHeight) {
  if (lineHeight === undefined || lineHeight === null || lineHeight === 'normal') return null;
  if (typeof lineHeight !== 'number') throw new Error(`A line height as text: ${String(lineHeight)}`);
  return lineHeight;
}

/** The family and the fallback families of a font object. */
function familyFields(font) {
  if (font.family === undefined || font.family === null) return {family: null, fallback: []};
  const list = families(font.family);
  return {family: list[0] ?? null, fallback: list.slice(1)};
}

/**
 * The record of the upstream font object [font] of an option: {family,
 * fallback, size, weight, style, height}. height is the lineHeight, a
 * multiple of the size. The Dart side is fontObjectRecordOf of
 * test/support/font_record.dart.
 */
export function fontObjectRecord(font) {
  if (typeof font.size === 'string') throw new Error(`A font size as text: ${font.size}`);
  return {
    ...familyFields(font),
    size: font.size ?? null,
    weight: weightValue(font.weight),
    style: styleName(font.style),
    height: heightValue(font.lineHeight),
  };
}

/**
 * The record of the result [font] of toFont, without string: {family,
 * fallback, size, weight, style, lineHeight}. lineHeight is in pixels. The
 * Dart side is resolvedFontRecordOf of test/support/font_record.dart.
 */
export function resolvedFontRecord(font) {
  return {
    ...familyFields(font),
    size: font.size ?? null,
    weight: weightValue(font.weight),
    style: styleName(font.style),
    lineHeight: font.lineHeight ?? null,
  };
}

/** The option keys whose value is a font. */
export const FONT_OPTION_KEYS = new Set(['font', 'titleFont', 'bodyFont', 'footerFont']);

/** The Dart literal of a font weight value: an int from 1 to 1000. */
function weightLiteral(weight) {
  if (weight === 700) return 'FontWeight.bold';
  if (weight === 400) return 'FontWeight.normal';
  if (!Number.isInteger(weight) || weight < 1 || weight > 1000) {
    throw new Error(`No FontWeight for ${weight}`);
  }
  // The named constants w100 to w900 (the lint use_named_constants).
  if (weight % 100 === 0 && weight <= 900) return `FontWeight.w${weight}`;
  return `FontWeight(${weight})`;
}

/**
 * The Dart literal of the CSS font text [css] of toFontString: a
 * ChartTextStyle with the fields of fontRecord. The widths of the reference
 * data hold it: a test writes it into a canvas and measures each text.
 */
export function dartCanvasFont(css) {
  const {font} = fontRecord(css);
  const fields = [];
  if (font.family !== null) {
    fields.push(`fontFamily: ${str(font.family)}`);
    fields.push(`fontFamilyFallback: [${font.fallback.map(str).join(', ')}]`);
  }
  fields.push(`fontSize: ${num(font.size)}`);
  if (font.weight !== null) fields.push(`fontWeight: ${weightLiteral(font.weight)}`);
  if (font.style !== null) fields.push(`fontStyle: FontStyle.${font.style}`);
  return `ChartTextStyle(${fields.join(', ')})`;
}
