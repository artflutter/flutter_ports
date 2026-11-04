# Chart.js ADR 0081: Native option setup and owned results

- Date: 2026-11-04
- Status: implemented; measurement and validation scope recorded with evidence.
- Related: ADRs 0054, 0076, 0078, 0080.

## Decision

Reduce repeated setup and temporary options allocation while retaining the
ordinary reads of configuration, scopes and values. This is an additional pass
over ADR 0080, not a replacement for its guards or a universal 60 FPS promise.

### Immutable key snapshots

OptionScope exposes an internal immutable snapshot of its JS own-key order.
Adding/removing an own key and restoring saved state invalidate the snapshot.
Value-only writes retain it; adding a route invalidates it if that adds a key.
Numeric extras retain Object.keys ordering. Existing ownKeys/jsOwnKeys/jsKeys
continue returning their ordinary independent lists.

DatasetController uses snapshots only after its existing producer classification
has observed an exact PointOptionsScope or BarOptionsScope, and only with an
exact Config. The first observation and all custom key producers keep virtual
jsOwnKeys calls and their original order. Custom Config subclasses keep the
existing virtual resolution method and fresh input prefix/key lists.

The native plan's immutableKeys proof allows a previously validated immutable
key list to match by identity. Mutable callers keep per-key comparisons before
and after context creation. A callback that changes default keys affects the
next resolution; it does not mutate the snapshot of the current resolution.

### Prefix and scope-key metadata

Controllers retain their private native prefix list while element type and
active/default prefix selection remain the same. No custom Config sees that
reused list. Config retains the last joined dataset/element scope-key string;
both JS string conversions and the original global key-cache lookup still run,
including joined-string collisions and mutations of returned scope-key lists.

Scope reads, scope-list lookup, descriptor checks, raw resolver invalidation and
context refresh remain live. This change does not cache a whole arbitrary user
configuration or omit custom getters.

### Allocate the final result

A new internal owned-result entry accepts the point/bar result kind instead of
a freshly allocated result. Private frozen PointOptions/BarOptions instances
serve only as type tokens. They are never written, returned or passed to user
code. The prepared path returns its normal fresh template clone. A declined
probe allocates a fresh ordinary result and reuses any context already created,
so context factories and callbacks are not invoked twice.

Existing caller-supplied-result and virtual method signatures are unchanged.
Only exact Config instances and string point/bar ids use the new controller
entry. Static results, unsupported options, hover resolution, custom Configs,
foreign values and context-time invalidation retain ordinary behavior. Nested
resolution cannot corrupt a shared token because the tokens are read-only.

## Evidence

[Estimates, production comparisons and validation](../benchmarks/option-setup/README.md).
The experiment measures setup-only, allocation-only and combined variants, plus
a clean baseline and the instrumented baseline. Production contains no experiment
switches. Gains are assessed on combined CPU cost and actual frames; a small
standalone allocation estimate is not presented as a measured allocation count.

Tests cover snapshot identity/invalidation, integer-key ordering, routes,
restoration, frozen scopes, native point/bar results, empty/nested/foreign
fallbacks, key and resolver changes inside callbacks, reentrant resolution,
context counts, custom Config virtual dispatch, custom key producers and live
string conversions/collisions. Existing resolver, controller and upstream tests
remain the compatibility oracle.
