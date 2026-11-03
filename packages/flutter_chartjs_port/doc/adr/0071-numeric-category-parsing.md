# Chart.js ADR 0071: Guarded numeric category parsing

- Status: implemented; macOS performance and VM/browser behavior validated.
- Date: 2026-11-03
- Related: ADRs 0054, 0064, 0069, 0070; performance.md §38.

## Decision

Share a primitive parse shortcut between the base dataset controller and bars.
Keep the initial ordinary `getLabels()` read. The category scale qualifies only
when it is the exact built-in class and its cached label-source options identify
the same native label list through the existing chart/config/container guards.
The numeric scale must have the exact built-in linear parse behavior. Unknown
scale subclasses do not inherit eligibility; their parse methods remain live.

Preflight the complete requested range of a native data list before creating
records. Accept numeric, null and undefined values, and string/null/undefined
labels (including duplicate strings and missing labels beyond the list length).
Floating bars, objects, coercible strings, custom lists and unusual labels keep
ordinary parsing. Range bounds must be integral and within the data array.
Qualification resolves no additional options and is not cached across calls.

Within the proven callback-free loop, a present string label parses to its
current index; null/undefined/missing labels parse to null. A finite number
converts to double with its signed zero preserved; nonfinite, null and undefined
values parse to null. Each item is a fresh `ParsedItem.of` with index-axis then
value-axis insertion order, including normal overwrite behavior for equal keys.
No parsed object, stack object, data value or label is retained between calls.
The caller's sorted check and stack updates remain unchanged.

This avoids repeated category label retrieval, generic indexed reads and parse
dispatch. It applies to ordinary bar and line primitive data and any other base
primitive parser using this scale combination. It does not accelerate arbitrary
object data, radial scales or animation frames that do not reparse data.

## Evidence and validation

The protocol and all measurements are retained in `benchmarks/primitive-parse/`.
The baseline is 65fc68f, including ADR 0070. The full-update comparison includes
drawing and recording completion; foreground FPS is measured separately.

Activation and reference twins cover both chart types/orientations, fresh
records, key order, signed zero, null/nonfinite values, partial ranges, duplicate
and missing labels, source precedence, live mutations and stacked datasets.
Fallback tests cover custom scale interception, custom label/data containers,
floating bars and coercible values. The same tests execute on both browser
backends through a temporary probe; no golden files are rewritten.

Both 20k pairs pass the 8% full-call gate: 11.3% and 8.2%, 9.7% overall.
Full updates fall 21.697 → 19.582ms; foreground FPS rises 34.92 → 39.73 with
all activity checks true. No control exceeds the regression threshold. Workspace
and browser tests, fixtures, analysis, formatting, parity and port checks pass.
