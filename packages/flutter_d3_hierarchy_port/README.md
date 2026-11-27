# flutter_d3_hierarchy_port

A native, fully statically typed, pure-Dart port of
[d3-hierarchy](https://github.com/d3/d3-hierarchy) **3.1.2** for Dart and Flutter: 2D hierarchical
layouts — squarified/binary/slice/dice/resquarified `treemap`, icicle/sunburst `partition`, circle
`pack` (`packSiblings` & Welzl `packEnclose`), Reingold-Tilford tidy `tree`, dendrogram `cluster`,
tabular `stratify` (by `id`/`parentId` or slash-delimited `path`), and `HierarchyNode<T>`
traversals/aggregations — with **zero `dynamic`**, zero runtime dependencies, and zero JavaScript
runtime.

```dart
import 'package:flutter_d3_hierarchy_port/flutter_d3_hierarchy_port.dart';

class Item implements HierarchyDatum<Item> {
  const Item(this.name, {this.size = 0, this.children});
  final String name;
  final double size;
  @override
  final List<Item>? children;
}

// 1. Build a typed hierarchy, sum leaf sizes, and sort descending
final root = hierarchy(
  const Item('root', children: [
    Item('analytics', children: [Item('cluster', size: 3938), Item('graph', size: 3534)]),
    Item('animate', children: [Item('easing', size: 17010), Item('tween', size: 6006)]),
  ]),
)
  ..sum((d) => d.size)
  ..sort((a, b) => (b.value ?? 0).compareTo(a.value ?? 0));

// 2. Squarified Treemap -> HierarchyRectangularNode<Item> (x0, y0, x1, y1)
final tm = treemap<Item>(size: (960, 500), paddingInner: 2, paddingTop: 16);
final rects = tm(root);
for (final leaf in rects.leaves()) {
  print('${leaf.data.name}: (${leaf.x0}, ${leaf.y0}) -> (${leaf.x1}, ${leaf.y1})');
}

// 3. Circle Packing -> HierarchyCircularNode<Item> (x, y, r)
final packed = pack<Item>(size: (600, 600), padding: 4)(root);
print('root circle: r=${packed.r}');

// 4. Tidy Tree -> HierarchyPointNode<Item> (x, y) & typed links
final tidy = tree<Item>(size: (800, 400))(root);
for (final link in tidy.links()) {
  print('${link.source.data.name} -> ${link.target.data.name}');
}

// 5. Tabular stratify by slash-delimited path (imputed nodes typed as Item?)
final byPath = stratifyPath<String>(
  ['/flare/analytics/cluster', '/flare/animate/easing'],
  (p) => p,
);
print(byPath.leaves().map((n) => n.id).toList());
```

## Installing

```sh
dart pub add flutter_d3_hierarchy_port
```

```dart
import 'package:flutter_d3_hierarchy_port/flutter_d3_hierarchy_port.dart' as d3;
```

`package:flutter_d3_hierarchy_port/d3_hierarchy.dart` and
`package:flutter_d3_hierarchy_port/flutter_d3_hierarchy_port.dart` are both pure Dart libraries
with zero Flutter dependency, compiling cleanly for the Dart VM, AOT, JavaScript (`dart2js`), and
WebAssembly (`dart2wasm`).

## API

- **Nodes & traversals:** `hierarchy`, `HierarchyDatum<T>`, `HierarchyNode<T>`,
  `HierarchyRectangularNode<T>` (`x0, y0, x1, y1`), `HierarchyCircularNode<T>` (`x, y, r`),
  `HierarchyPointNode<T>` (`x, y`), typed `HierarchyLink<T>` records (`HierarchyRectangularLink<T>`,
  `HierarchyCircularLink<T>`, `HierarchyPointLink<T>`), plus `ancestors`, `descendants`, `leaves`,
  `links`, `path`, `find`/`findIndexed`, `each`/`eachIndexed`, `eachBefore`/`eachBeforeIndexed`,
  `eachAfter`/`eachAfterIndexed`, `sum`, `count`, `sort`, `copy`, and `Iterable` iteration.
- **Stratify:** `stratify` (`StratifyOperator<T>`), `StratifyDatum`, `stratifyPath`
  (`HierarchyNode<T?>` for sound null-safe imputed internal nodes).
- **Treemap:** `treemap` (`TreemapLayout<T>`), `TreemapTile<T>`, and all 6 tiling algorithms:
  `treemapBinary`, `treemapDice`, `treemapSlice`, `treemapSliceDice`, `treemapSquarify`
  (`TreemapSquarifyTile` with `.ratio(...)`), and `treemapResquarify` (`TreemapResquarifyTile` with
  `.ratio(...)`).
- **Partition:** `partition` (`PartitionLayout<T>`) for icicle and sunburst diagrams.
- **Circle packing:** `pack` (`PackLayout<T>`), `PackCircle`, `packSiblings`,
  `packSiblingsRandom`, `packEnclose`, and `packEncloseRandom`.
- **Node-link trees:** `tree` (`TreeLayout<T>`, Reingold-Tilford) and `cluster`
  (`ClusterLayout<T>`, dendrogram).

## Performance

Benchmarked on Apple M3 Max (Node.js v24.22.1, macOS CLI/Flutter AOT, Chrome 158, Firefox 161,
Safari 27.0.1), iOS 27.2 (`ios-arm64` Flutter AOT release), and Pixel 8a (Android 17 AOT release,
Mobile Chrome 157, Mobile Firefox 160). All values are median **ns/op** (lower is better; see
[doc/performance.md](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_d3_hierarchy_port/doc/performance.md)
for the complete 17-case breakdown including baseline vs optimized).

- **Native AOT:** beats Node.js `d3-hierarchy` on **15/17** workloads on macOS M3 Max (up to
  **6.55× faster**), **15/17** on iOS 27.2 AOT (up to **6.91× faster**), and **13/17** on Pixel 8a
  Android AOT against desktop M3 Max Node.js.
- **Web (`dart2wasm` & `dart2js`):** `dart2wasm` beats Node.js on **17/17** CLI workloads (up to
  **4.39× faster**); in browsers, Dart beats upstream JS on **17/17** cases in Desktop Chrome,
  Desktop Firefox, and Mobile Chrome, **16/17** in Mobile Firefox, and **14/17** in Desktop Safari.

### Native AOT vs Node.js (ns/op)

| Case | Node.js upstream | macOS AOT | iOS 27.2 AOT | Pixel 8a Android AOT |
|---|---:|---:|---:|---:|
| `hierarchy.build_252` | 5,718 | 7,457 | 5,736 | 8,996 |
| `stratify.id_252` | 20,364 | **17,763** | **15,772** | 24,963 |
| `stratify.path_252` | 42,462 | **29,681** | **24,843** | **41,262** |
| `traverse.eachBefore_1k` | 5,461 | 6,295 | 5,623 | 9,915 |
| `traverse.eachAfter_1k` | 11,555 | **7,058** | **5,834** | **10,255** |
| `traverse.bfs_each_1k` | 17,949 | **8,973** | **10,237** | **16,168** |
| `traverse.desc_leaves_1k` | 52,335 | **16,673** | **16,847** | **26,886** |
| `aggregate.sum_count_1k` | 51,850 | **16,237** | **15,054** | **21,354** |
| `aggregate.sort_1k` | 91,149 | **69,529** | **67,779** | 114,048 |
| `treemap.squarify_252` | 27,683 | **4,225** | **4,008** | **7,478** |
| `treemap.binary_252` | 19,079 | **4,706** | **4,737** | **7,670** |
| `treemap.resquarify_252` | 95,831 | **15,945** | **15,413** | **30,593** |
| `partition.252` | 8,739 | **1,723** | **1,498** | **2,802** |
| `pack.252` | 87,055 | **38,900** | **34,121** | **65,409** |
| `packSiblings.64` | 27,960 | **8,508** | **7,653** | **15,012** |
| `tree.252` | 19,467 | **11,274** | **10,779** | **19,459** |
| `cluster.252` | 12,386 | **4,387** | **4,280** | **7,712** |

### Desktop & Mobile Browsers (ns/op, `upstream / dart2js / dart2wasm`)

| Case | Chrome 158 | Firefox 161 | Safari 27.0.1 | Pixel Chrome 157 | Pixel Firefox 160 |
|---|---|---|---|---|---|
| `stratify.path_252` | 31,620 / **23,750** / 25,313 | 64,769 / **44,510** / 55,606 | **24,530** / 27,790 / 53,734 | 64,309 / 59,625 / **43,236** | 83,333 / **82,031** / 140,625 |
| `traverse.bfs_each_1k` | 15,452 / **3,555** / 4,997 | 24,609 / **7,198** / 10,322 | 10,985 / **6,205** / 7,446 | 34,334 / **7,703** / 7,917 | 41,016 / **13,192** / 17,889 |
| `traverse.desc_leaves_1k` | 37,454 / 10,584 / **7,972** | 41,494 / **13,620** / 15,625 | 18,880 / **9,911** / 12,612 | 48,730 / 23,179 / **13,291** | 72,104 / 25,000 / **24,737** |
| `aggregate.sum_count_1k` | 27,044 / **8,789** / 13,762 | 56,180 / **14,343** / 27,919 | 34,564 / **7,921** / 13,426 | 49,837 / **16,416** / 22,556 | 88,323 / **34,292** / 47,656 |
| `treemap.squarify_252` | 23,385 / 8,021 / **6,205** | 20,067 / 14,592 / **11,099** | 9,521 / **6,307** / 7,324 | 34,453 / 18,746 / **10,458** | 32,813 / 28,246 / **17,188** |
| `treemap.resquarify_252` | 85,836 / 32,854 / **21,840** | 73,406 / 44,107 / **39,063** | 57,915 / **19,195** / 28,805 | 126,283 / 72,104 / **39,909** | 116,505 / 97,289 / **62,500** |
| `partition.252` | 8,489 / 3,052 / **2,314** | 9,032 / 6,137 / **4,162** | 4,395 / 3,879 / **2,930** | 11,144 / 9,537 / **3,997** | 13,921 / 12,205 / **7,177** |
| `pack.252` | 76,770 / 80,191 / **32,083** | 126,953 / 103,215 / **50,448** | 78,125 / 59,570 / **46,083** | 185,449 / 220,949 / **62,916** | 221,818 / 195,440 / **96,875** |
| `packSiblings.64` | 25,909 / 14,030 / **7,556** | 31,250 / 20,211 / **9,977** | 24,530 / 11,666 / **10,981** | 66,890 / 37,058 / **14,100** | 53,715 / 32,813 / **19,857** |
| `tree.252` | 14,070 / 26,328 / **9,111** | 26,837 / 33,978 / **15,105** | 16,016 / 20,766 / **14,136** | 38,724 / 75,207 / **16,485** | 51,814 / 81,967 / **29,785** |
| `cluster.252` | 7,979 / 14,624 / **4,116** | 14,404 / 20,182 / **7,690** | 7,682 / 15,885 / **6,134** | 19,449 / 40,169 / **7,446** | 25,000 / 45,313 / **14,841** |

## Upstream

- Upstream: [d3/d3-hierarchy](https://github.com/d3/d3-hierarchy) `v3.1.2` (`d3HierarchyVersion`).
- Differences from upstream:
  [doc/differences.md](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_d3_hierarchy_port/doc/differences.md).
- Full benchmark report:
  [doc/performance.md](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_d3_hierarchy_port/doc/performance.md).

## License

ISC, matching upstream `d3-hierarchy`. See [LICENSE](LICENSE). This project is not affiliated with
the D3 project.
