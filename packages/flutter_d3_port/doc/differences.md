# D3 port differences

This file lists the hunks of ported code that do not translate the upstream lines
([porting-flow.md](porting-flow.md) §4). Each hunk carries the line comment
`// DIVERGES(d3): <ID>, <reason>`. From phase 1, tool 2 pairs each marker with a row of this file
([ADR 0008](../../../docs/adr/0008-shared-js-runtime-and-port-tools.md)). A port-only file is not
a row. A hunk of a port-only file that gives the difference of a row carries the marker of that
row.

The ID starts with its category: `adapt`, `platform`, `js-semantics`, `harness` or
`not-followed`. A skip reason `'diverges: <ID>'` names a row. The upstream column names the
repository, the path, the tag and the lines, for example `d3-array src/ticks.js@v3.2.4:7`.

Phase 0 ports no code. Thus the table has no rows.

| ID | Dart file and symbol | Upstream file@version:lines | Category | Reason | Upstream reference | Pinning test | Re-check on bump |
|---|---|---|---|---|---|---|---|
