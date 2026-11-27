# flutter_d3_quadtree_port

A native, fully statically typed, pure-Dart port of [d3-quadtree](https://github.com/d3/d3-quadtree)
**3.0.1** for Dart and Flutter: 2D spatial indexing with recursive quadrant subdivision,
nearest-neighbor search (`find` with optional search radius), pre-order and post-order traversal
(`visit` / `visitAfter` with quadrant pruning for rectangular range queries), coincident-point
linked lists, dynamic insertion/removal, and deep tree copying — with **zero `dynamic`**, zero
runtime dependencies, and zero JavaScript runtime.

```dart
import 'package:flutter_d3_quadtree_port/flutter_d3_quadtree_port.dart';

// 1. Default (double, double) quadtree
final tree = quadtree(<(double, double)>[
  (10, 20),
  (80, 35),
  (45, 90),
  (50, 50),
]);

// Nearest-neighbor search (unbounded or with a maximum radius)
final closest = tree.find(48, 52); // (50.0, 50.0)
final within20 = tree.find(48, 52, 20); // (50.0, 50.0)

// 2. Strongly typed quadtree over custom Dart types
typedef City = ({String name, double x, double y});
final cities = quadtreeBy<City>(
  x: (c) => c.x,
  y: (c) => c.y,
  data: const <City>[
    (name: 'Alpha', x: 12, y: 18),
    (name: 'Beta', x: 64, y: 42),
    (name: 'Gamma', x: 90, y: 88),
  ],
);

// 3. Rectangular range query using visit() with quadrant pruning
final found = <City>[];
cities.visit((node, x0, y0, x1, y1) {
  if (x0 >= 70 || y0 >= 60 || x1 < 0 || y1 < 0) return true; // prune
  if (node case QuadtreeLeafNode<City>()) {
    QuadtreeLeafNode<City>? leaf = node;
    while (leaf != null) {
      final c = leaf.data;
      if (c.x >= 0 && c.x < 70 && c.y >= 0 && c.y < 60) found.add(c);
      leaf = leaf.next;
    }
  }
  return false;
});
```

## Installing

```sh
dart pub add flutter_d3_quadtree_port
```

```dart
import 'package:flutter_d3_quadtree_port/flutter_d3_quadtree_port.dart' as d3;
```

`package:flutter_d3_quadtree_port/d3_quadtree.dart` and
`package:flutter_d3_quadtree_port/flutter_d3_quadtree_port.dart` are both pure Dart libraries with
zero Flutter dependency, compiling cleanly for the Dart VM, AOT, JavaScript (`dart2js`), and
WebAssembly (`dart2wasm`).

## API

- **Constructors:** `quadtree([data, x, y])` for `(double, double)` points and
  `quadtreeBy<T>({required x, required y, data})` (or `Quadtree<T>(...)`) for arbitrary typed
  records/models.
- **Sealed node hierarchy:** `sealed class QuadtreeNode<T>` with `QuadtreeInternalNode<T>` (4 typed
  quadrant slots `nw`/`ne`/`sw`/`se` plus `0..3` indexing) and `QuadtreeLeafNode<T>` (`data` and
  `next` linked list for coincident points).
- **Accessors & bounds:** `x` / `y` (`double Function(T)`), `setX` / `setY`, `extent` /
  `setExtent` (`((double, double), (double, double))?`), `cover(x, y)`.
- **Mutation & cloning:** `add(datum)`, `addAll(data)`, `remove(datum)`, `removeAll(data)`,
  `copy()`.
- **Inspection & queries:** `root`, `data()`, `size()`, `find(x, y, [radius])`,
  `visit(bool Function(QuadtreeNode<T>, double, double, double, double))`,
  `visitAfter(void Function(QuadtreeNode<T>, double, double, double, double))`.

## Performance

Benchmarked on Apple M3 Max (Node.js v24.22.1, macOS CLI/Flutter AOT, Chrome 157, Firefox 160,
Safari 27.0.1), iOS 27.2 (`ios-arm64` Flutter AOT release), and Pixel 8a (Android 17 AOT release,
Mobile Chrome 157, Mobile Firefox 160). All values are median **ns/op** (lower is better; see
[doc/performance.md](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_d3_quadtree_port/doc/performance.md)
for the complete 14-case breakdown including baseline vs optimized).

- **Native AOT:** iOS 27.2 AOT beats desktop M3 Max Node.js `d3-quadtree` on **9/14** workloads (up
  to **3.00× faster** on `find.radius_256` and **2.99× faster** on `data_size.5000`); macOS AOT
  beats Node.js on all `find`, `update`, and `data`/`size` workloads (up to **2.43× faster**).
- **Web (`dart2wasm` & `dart2js`):** `dart2wasm` beats Node.js on **10/14** CLI workloads (up to
  **2.86× faster**); in browsers, Dart beats upstream JS on **14/14** workloads in Mobile Chrome
  (up to **4.41× faster**), **12/14** in Desktop Chrome, **11/14** (+ 1 tie, up to **12.16×
  faster**) in Desktop Safari, **11/14** in Mobile Firefox, and **10/14** in Desktop Firefox.

### Native AOT vs Node.js (ns/op)

| Case | Node.js upstream | macOS AOT | iOS 27.2 AOT | Pixel 8a Android AOT |
|---|---:|---:|---:|---:|
| `addAll.uniform_1000` | 43,465 | 46,889 | **33,957** | 90,398 |
| `addAll.uniform_5000` | 328,270 | 428,609 | **321,625** | 712,250 |
| `addAll.clustered_2000` | 98,712 | 143,313 | **96,648** | 235,406 |
| `addAll.custom_1000` | 41,917 | 55,551 | 44,658 | 102,102 |
| `add.incremental_1000` | 68,988 | 80,246 | **58,461** | 112,570 |
| `find.unbounded_256` | 149,483 | **91,523** | **77,477** | 155,266 |
| `find.radius_256` | 166,622 | **68,656** | **55,564** | **119,980** |
| `find.custom_256` | 131,620 | **85,359** | **73,508** | 139,578 |
| `visit.full_5000` | 113,972 | 140,836 | 136,063 | 266,125 |
| `visit.range_64` | 190,716 | 223,641 | 191,547 | 388,406 |
| `visitAfter.full_5000` | 157,041 | 157,234 | 160,523 | 327,281 |
| `copy.tree_2000` | 23,574 | 33,160 | 24,120 | 45,766 |
| `update.remove_add_500` | 91,266 | **85,668** | **63,246** | 129,313 |
| `data_size.5000` | 372,044 | **180,258** | **124,508** | **299,563** |

### Desktop & Mobile Browsers (ns/op, `upstream / dart2js / dart2wasm`)

| Case | Chrome 157 | Firefox 160 | Safari 27.0.1 | Pixel Chrome 157 | Pixel Firefox 160 |
|---|---|---|---|---|---|
| `addAll.uniform_1000` | 38,867 / 38,086 / **26,074** | 82,031 / **66,406** / 78,125 | 42,969 / 29,297 / **28,320** | 124,219 / 106,645 / **48,631** | 164,063 / 132,813 / **101,563** |
| `addAll.uniform_5000` | 320,313 / 326,547 / **160,938** | 625,000 / **531,250** / **531,250** | 343,750 / 265,625 / **179,688** | 859,375 / 762,500 / **531,250** | 1,125,000 / 968,750 / **875,000** |
| `find.unbounded_256` | 122,656 / **78,516** / 113,668 | 218,750 / **101,563** / 187,500 | 105,469 / **58,594** / 97,656 | 518,750 / **174,211** / 197,656 | 406,250 / **195,313** / 328,125 |
| `find.radius_256` | 121,094 / **60,547** / 83,984 | 218,750 / **74,219** / 148,438 | 109,375 / **48,828** / 74,219 | 528,125 / **132,813** / 146,094 | 390,625 / **156,250** / 250,000 |
| `visit.full_5000` | 95,313 / **53,322** / 104,691 | 203,125 / **101,563** / 234,375 | 437,500 / **42,969** / 156,250 | 415,625 / **139,844** / 223,445 | 390,625 / **203,125** / 375,000 |
| `visit.range_64` | 157,813 / **130,469** / 200,000 | 281,250 / **234,375** / 343,750 | 250,000 / **82,031** / 250,000 | 693,750 / **398,438** / 399,984 | 562,500 / **453,125** / 562,500 |
| `visitAfter.full_5000` | 138,281 / **60,547** / 73,043 | 179,688 / **117,188** / 179,688 | 593,750 / **48,828** / 82,031 | 537,500 / 175,781 / **160,930** | 390,625 / **250,000** / **250,000** |
| `copy.tree_2000` | 18,262 / 30,273 / **10,254** | **42,969** / 93,750 / 48,828 | 28,320 / 42,969 / **17,578** | 40,625 / 167,195 / **20,606** | 93,750 / 164,063 / **44,922** |
| `data_size.5000` | 340,625 / **109,762** / 118,355 | 453,125 / **148,438** / 187,500 | 359,375 / **97,656** / 156,250 | 1,000,000 / 342,172 / **226,563** | 843,750 / 406,250 / **375,000** |

## Upstream

- Upstream: [d3/d3-quadtree](https://github.com/d3/d3-quadtree) `v3.0.1` (`d3QuadtreeVersion`).
- Differences from upstream: [doc/differences.md](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_d3_quadtree_port/doc/differences.md).
- Full benchmark report: [doc/performance.md](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_d3_quadtree_port/doc/performance.md).

## License

ISC, matching upstream `d3-quadtree`. See [LICENSE](LICENSE). This project is not affiliated with the D3 project.
