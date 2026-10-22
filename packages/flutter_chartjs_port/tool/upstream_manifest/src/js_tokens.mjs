// Original code, not ported from Chart.js: a small JavaScript tokenizer for the upstream manifest.
//
// It splits JavaScript and TypeScript source into names, numbers,
// punctuators, strings, templates and regular expressions, and drops the
// comments. The scans of the upstream manifest (builtin sites, defaults
// sites, the acquireChart closure of the specs) read these tokens, so that a
// name in a comment or a string never counts. It is not a parser: a `/` after
// `)`, `]`, `}`, a name or a number is a division, else a regular expression.

/** Names after which a `/` starts a regular expression. */
const REGEX_AFTER_NAMES = new Set([
  'case', 'delete', 'do', 'else', 'in', 'instanceof', 'new', 'of', 'return',
  'throw', 'typeof', 'void', 'yield', 'await',
]);

/** The punctuators, longest first. */
const PUNCTUATORS = [
  '>>>=', '...', '===', '!==', '**=', '<<=', '>>=', '>>>', '&&=', '||=',
  '??=', '=>', '==', '!=', '<=', '>=', '&&', '||', '??', '?.', '++', '--',
  '+=', '-=', '*=', '/=', '%=', '&=', '|=', '^=', '**', '<<', '>>',
  '{', '}', '(', ')', '[', ']', ';', ',', '<', '>', '+', '-', '*', '/', '%',
  '&', '|', '^', '!', '~', '?', ':', '=', '.', '@', '#',
];

const isIdStart = (c) => /[A-Za-z_$\u0080-￿]/.test(c);
const isIdPart = (c) => /[A-Za-z0-9_$\u0080-￿]/.test(c);

/**
 * The tokens of `source`. Each token is `{type, value, start, end, line,
 * column}`, with a 1-based `line` and `column`. The types are `name`,
 * `number`, `punct`, `string`, `template` (one token for each literal part of
 * a template) and `regex`.
 */
export function tokenize(source) {
  const tokens = [];
  // One entry for each open `{` or `${`: true for a template substitution.
  const braces = [];
  let i = 0;

  const push = (type, start, end, value = source.slice(start, end)) => {
    tokens.push({type, value, start, end, line: lineAt(start), column: columnAt(start)});
  };
  // Line bookkeeping: the start offsets of the lines seen so far.
  const lineStarts = [0];
  const lineAt = (offset) => {
    let lo = 0;
    let hi = lineStarts.length - 1;
    while (lo < hi) {
      const mid = (lo + hi + 1) >> 1;
      if (lineStarts[mid] <= offset) lo = mid; else hi = mid - 1;
    }
    return lo + 1;
  };
  const columnAt = (offset) => offset - lineStarts[lineAt(offset) - 1] + 1;
  const newline = (offset) => lineStarts.push(offset + 1);

  const regexAllowed = () => {
    const last = tokens[tokens.length - 1];
    if (!last) return true;
    if (last.type === 'name') return REGEX_AFTER_NAMES.has(last.value);
    if (last.type === 'punct') return ![')', ']', '}'].includes(last.value);
    return false;
  };

  /** Scans a template part from `i` (after "`" or "}") to "`" or "${". */
  const templatePart = (start) => {
    while (i < source.length) {
      const c = source[i];
      if (c === '\\') {
        if (source[i + 1] === '\n') newline(i + 1);
        i += 2;
      } else if (c === '`') {
        i++;
        push('template', start, i);
        return;
      } else if (c === '$' && source[i + 1] === '{') {
        i += 2;
        push('template', start, i);
        braces.push(true);
        return;
      } else {
        if (c === '\n') newline(i);
        i++;
      }
    }
    push('template', start, i);
  };

  while (i < source.length) {
    const c = source[i];
    if (c === '\n') {
      newline(i);
      i++;
    } else if (/\s/.test(c)) {
      i++;
    } else if (c === '/' && source[i + 1] === '/') {
      while (i < source.length && source[i] !== '\n') i++;
    } else if (c === '/' && source[i + 1] === '*') {
      const end = source.indexOf('*/', i + 2);
      const stop = end < 0 ? source.length : end + 2;
      for (let j = i; j < stop; j++) if (source[j] === '\n') newline(j);
      i = stop;
    } else if (c === '"' || c === "'") {
      const start = i++;
      while (i < source.length && source[i] !== c && source[i] !== '\n') {
        i += source[i] === '\\' ? 2 : 1;
      }
      if (source[i] === c) i++;
      push('string', start, i);
    } else if (c === '`') {
      const start = i++;
      templatePart(start);
    } else if (c === '}' && braces.length && braces[braces.length - 1]) {
      braces.pop();
      const start = i++;
      templatePart(start);
    } else if (isIdStart(c)) {
      const start = i;
      while (i < source.length && isIdPart(source[i])) i++;
      push('name', start, i);
    } else if (/[0-9]/.test(c) || (c === '.' && /[0-9]/.test(source[i + 1] ?? ''))) {
      const start = i;
      while (i < source.length && /[0-9A-Za-z_.]/.test(source[i])) {
        if ((source[i] === 'e' || source[i] === 'E') && /[+-]/.test(source[i + 1] ?? '')) i++;
        i++;
      }
      push('number', start, i);
    } else if (c === '/' && regexAllowed()) {
      const start = i++;
      let inClass = false;
      while (i < source.length && source[i] !== '\n') {
        const d = source[i];
        if (d === '\\') {
          i += 2;
          continue;
        }
        if (d === '[') inClass = true;
        else if (d === ']') inClass = false;
        else if (d === '/' && !inClass) break;
        i++;
      }
      if (source[i] === '/') i++;
      while (i < source.length && isIdPart(source[i])) i++;
      push('regex', start, i);
    } else {
      const op = PUNCTUATORS.find((p) => source.startsWith(p, i));
      const start = i;
      i += op ? op.length : 1;
      if (op === '{') braces.push(false);
      else if (op === '}') braces.pop();
      push('punct', start, i);
    }
  }
  return tokens;
}

/**
 * The index of the token that closes the bracket at `tokens[open]`, or
 * `tokens.length` when it does not close.
 */
export function matchBracket(tokens, open) {
  const pairs = {'(': ')', '[': ']', '{': '}'};
  const opener = tokens[open].value;
  const closer = pairs[opener];
  let depth = 0;
  for (let j = open; j < tokens.length; j++) {
    const t = tokens[j];
    if (t.type !== 'punct') continue;
    if (t.value === opener) depth++;
    else if (t.value === closer && --depth === 0) return j;
  }
  return tokens.length;
}

/** The value of a string token, without its quotes, with its escapes read. */
export function stringValue(token) {
  if (token.type !== 'string') return null;
  const escapes = {n: '\n', r: '\r', t: '\t', b: '\b', f: '\f', v: '\v', 0: '\0'};
  return token.value.slice(1, -1).replace(
    /\\(u\{[0-9a-fA-F]+\}|u[0-9a-fA-F]{4}|x[0-9a-fA-F]{2}|.)/g,
    (_, e) => {
      if (e[0] === 'u' || e[0] === 'x') {
        return String.fromCodePoint(parseInt(e.replace(/[ux{}]/g, ''), 16));
      }
      return escapes[e] ?? e;
    },
  );
}

/**
 * The top-level keys of the object literal whose `{` is `tokens[open]`, in
 * source order: `key:`, `'key':`, shorthand `key,` and methods `key(`.
 */
export function objectKeys(tokens, open) {
  const close = matchBracket(tokens, open);
  const keys = [];
  let expectKey = true;
  for (let j = open + 1; j < close; j++) {
    const t = tokens[j];
    if (t.type === 'punct' && ['(', '[', '{'].includes(t.value)) {
      if (expectKey && t.value === '[') {
        // A computed key.
        const end = matchBracket(tokens, j);
        keys.push(`[${tokens.slice(j + 1, end).map((x) => x.value).join('')}]`);
        j = end;
        expectKey = false;
        continue;
      }
      j = matchBracket(tokens, j);
      continue;
    }
    if (t.type === 'punct' && t.value === ',') {
      expectKey = true;
      continue;
    }
    if (!expectKey) continue;
    if (t.type === 'punct' && t.value === '...') {
      expectKey = false;
      continue;
    }
    if (t.type === 'name' && (t.value === 'get' || t.value === 'set' || t.value === 'async') &&
        tokens[j + 1]?.type === 'name') {
      continue;
    }
    if (t.type === 'name' || t.type === 'string' || t.type === 'number') {
      keys.push(t.type === 'string' ? stringValue(t) : t.value);
      expectKey = false;
    }
  }
  return keys;
}
