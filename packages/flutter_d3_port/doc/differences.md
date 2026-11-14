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

Each ported D3 module is a package of its own ([D3 ADR 0008](adr/0008-module-packages.md)), with
its own `doc/differences.md`, for example
[the d3-color rows](../../flutter_d3_color_port/doc/differences.md). This table has the rows of the
files of `packages/flutter_d3_port`. It has no rows yet.

| ID | Dart file and symbol | Upstream file@version:lines | Category | Reason | Upstream reference | Pinning test | Re-check on bump |
|---|---|---|---|---|---|---|---|
