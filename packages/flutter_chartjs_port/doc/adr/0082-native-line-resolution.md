# Chart.js ADR 0082: Loop-local native line resolution and contexts

- Date: 2026-11-04
- Status: implemented; measurements and validation are recorded with the evidence.
- Related: ADRs 0078–0081.

## Decision

After two ordinary point resolutions, a native line mode-none loop may retain
its warmed color resolver, native source references and immutable default-key
snapshot. This reuses lookup work, not callback results or returned options.
Existing indexed-color geometry/drawing behavior is unchanged.

Eligibility requires the exact line controller, a native chart or an explicitly
equivalent wrapper, a native point class value/id, integral ranges, native numeric
projections and the existing no-stack/no-segment loop conditions. This first
implementation supports SDK Map roots/data/datasets and native source lists.
Typed roots and custom containers retain the ordinary path. Only warmed,
unshared point color plans qualify; indexed/scriptable numeric options retain
ordinary resolution.

Before each scriptable resolution, the caller checks class/id, dataset index,
chart config/data identity and the absence of a cached point-none result. The
plan checks root/data/datasets/dataset/source/options references, native default
containers, route absence, immutable key identity and cache generation. Config
clearCache and scope-cache resets advance that generation. A failed check ends
reuse for the rest of that loop. No plan persists across updateElements calls.

The cached resolver is passed into the existing owned-result implementation.
The native descriptor, raw-plan and callback handling remain intact. A context
that invalidates the cache falls through with its already-created context; it
is not invoked twice. Changes to raw cached option values retain upstream cache
semantics. Newly cached controller options from a reentrant call take priority
over a retained loop plan.

## Native context window

The alternative context factory runs only after a native scriptable/indexed
plan has completed its effect-free checks. A generic/custom-descriptor fallback
uses the ordinary context factory. This distinction prevents user code during
fallback setup from invalidating captured data before context refresh.

The reader retains native data/parsed arrays and checks their current identities.
It reads the current metadata element, requires its native capability and an
existing ScriptableContext, then performs the original typed setter sequence:
parsed, raw, dataIndex, index, active, mode. Raw/parsed items remain live, bounds
retain jsGetIndex behavior, and coordinate properties are never evaluated here.
Deleted context keys reinsert in their original order. Missing contexts, custom
points and changed arrays return to ordinary context creation/refresh without
partial writes or speculative custom indexing.

The existing indexed-color loop already proves an effect-free interval between
its guards; it can use the same native context reader there. Its existing guards
still terminate indexed reuse before unknown geometry, active/custom points or
custom callbacks. Scriptable loops revalidate their sources for each point.

## Evidence

See [native line resolution evidence](../benchmarks/line-resolution/README.md).
A fresh CPU/heap profile precedes separate scope-only, context-only and combined
estimation variants. Production contains no experiment switches. Timings are
separate from profiling; allocation snapshots are not presented as per-frame
allocation rates.

Tests compare ordinary-chart twins for live data, replacement sources/options,
cache clear and scope reset, changed default keys/routes, custom parsed lists,
replaced metadata elements, nested cached-result precedence, exceptions and
context-key order. Pure tests cover source guards, context-time invalidation,
immutable snapshot semantics and native context fallback without custom reads.
