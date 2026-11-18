# Chart.js ADR 0179: No parity generator and no port-order tool

- Status: accepted (2026-11-18): the tools are removed, and the port checks pass.
- Date: 2026-11-18
- Supersedes: of [Chart.js ADR 0029](0029-fixture-smoke-runner.md), in §10 tool 6 of item 3, and item 5.
- Related: [Chart.js ADR 0178](0178-no-js-semantics-check.md)

## Context

Tool 6, `parity`, wrote `doc/parity.md` from `doc/status.yaml`, the headers, the spec results and
`doc/differences.md`. Each change edited a long status text in `status.yaml` and ran the generator, and `parity:check`
ran the spec tests in the job `port-checks`. Tool 8, `port:next`, listed the Chart.js modules that were ready to port.
On 2026-11-18 it reported 90 of 90 modules done, 0 in progress, 0 ready and 0 blocked.

## Decision

1. **A person writes `parity.md`.** `tool/parity.dart`, `tool/src/parity.dart`, `test/tool/parity_test.dart` and
   `doc/status.yaml` are removed, with the melos scripts `parity` and `parity:check`. `parity.md` keeps its last
   generated text. A change edits the row of its file in the same commit, as the zoom and sankey ports do.
2. **The port has no port-order tool.** `tool/port_order.dart`, `tool/src/port_order.dart`,
   `test/tool/port_order_test.dart` and the melos scripts `port:next` and `port:next:check` are removed.
3. **`check:port` runs five checks:** `check:lib-imports`, `check:headers`, `check:typed-reads`,
   `options:gen:check` and `adr:index:check`.
4. **`test:cases` still reads the status column of `parity.md`.** A missing case of a `ported` module and a stale
   `blocked: <module>` skip still fail.

## Rejected

- Keep the generator for the counts of the spec cases: `test:cases` prints them.

## Consequences

- The case counts and the counts of the `differences.md` rows in `parity.md` do not update by themselves.
- The D3 and ECharts plans that name tools 6 and 8 get their own tools when they need them.

## Tests

- `dart run melos run check:port` and `dart run melos run test:cases`.
