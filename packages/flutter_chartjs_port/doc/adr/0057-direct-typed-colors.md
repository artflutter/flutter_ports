# Chart.js ADR 0057: Color-only inputs

- Status: implemented; explicitly requested on 2026-11-01.
- Related: ADRs 0050, 0052 and 0054; `performance.md` §§20–22.
- Supersedes the CSS-string color input/serialization portions of those ADRs.
  Their theme isolation, typed model and pure-layer requirements remain in force.

## Decision

Solid color inputs are Flutter `Color` values, including `ChartView.raw` and
`Chart` configuration maps. CSS names, hex strings and rgb/hsl strings throw an
`ArgumentError`. Indexable colors are lists of colors; callbacks return colors.
Null/undefined retain their existing optional-value handling. Existing gradient
and pattern paint objects remain supported, but gradient stops require `Color`.

This is an intentional API break, not a compatibility switch. Callers loading
Chart.js JSON must translate its colors before calling the port. Neither chart
rendering nor hover/animation performs CSS parsing, formatting or string-cache
lookups. The numerical color constructor also rejects strings. Low-level parser
functions remain available to the test-only decoder for frozen upstream data;
no chart color path calls them.

Typed lowering passes the original `Color` through unchanged. Normal lists and
callbacks replace the provisional compatibility adapters; callback answers are
not memoized. The native canvas retains the supplied color, including alpha and
color space. Invalid colors fail without changing the previous canvas style.
Static raw configuration colors are checked before a constructor acquires its
canvas. The validator does not inspect dataset data/labels, execute callbacks,
or mistake animation-group dictionaries for solid colors.

## Pure numerical layers

Built-in defaults, theme tokens and the default palette use numerical
`PreparedColor` values in pure Dart. The Flutter boundary installs the native
reader/writer; resolution materializes native colors before element drawing.
The numerical value is immutable and has no string cache. Public Flutter color
helpers and chart/canvas construction establish the same bridge.

Hover and animation use numerical RGBA channels and produce native colors.
Native alpha is not round-tripped through CSS. The numerical constructor accepts
byte-alpha channels without premature rounding; the existing interpolation
algorithm and per-animation endpoint cache remain. Theme compilation keeps its
existing sRGB normalization but emits color values rather than CSS strings.

## Migration and verification

Use `const Color(0xFF36A2EB)` instead of `'#36A2EB'`, and
`const Color.fromRGBO(54, 162, 235, 0.5)` instead of an rgba string. This applies to
raw maps, defaults, lists, callbacks and gradient stops. UI examples now use
native colors, including the color/mixing demo.

The new contract tests cover native identity/precision, static raw rejection,
callbacks/lists, defaults, hover, animation, animation-group dictionaries,
constructor rejection and gradient stops. Existing tests migrate color literals
and compare native colors by value. Frozen reference observations compare color
channels; frozen fixture inputs are translated by an explicit test-only adapter
before invoking the strict production API. Geometry, ordering and non-color
behavior continue to use their existing checks.

The compatibility prototype and its historical results remain in performance.md
§§20–21. They are not measurements of this stricter implementation. Section 22
records the final limited comparison, including the newly connected iOS device.
