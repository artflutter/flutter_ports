// Original code, not ported from d3-quadtree: upstream Node.js benchmark.

import {performance} from "node:perf_hooks";
import {fileURLToPath, pathToFileURL} from "node:url";
import path from "node:path";

const here = path.dirname(fileURLToPath(import.meta.url));
const repo = path.resolve(here, "../../../..");
const {quadtree} = await import(
  pathToFileURL(path.join(repo, "third_party/d3-quadtree/src/index.js")).href
);

class Lcg {
  constructor(seed) {
    this.seed = seed;
  }
  nextDouble() {
    this.seed = (this.seed * 48271) % 2147483647;
    return this.seed / 2147483647.0;
  }
}

const r = new Lcg(42);
const makeUniform = (n) =>
  Array.from({length: n}, () => [r.nextDouble() * 1000.0, r.nextDouble() * 1000.0]);

const uniform1000 = makeUniform(1000);
const uniform5000 = makeUniform(5000);

const centers = [
  [200, 220],
  [780, 240],
  [500, 500],
  [260, 760],
  [760, 780],
];
const clustered2000 = Array.from({length: 2000}, (_, i) => {
  const [cx, cy] = centers[i % centers.length];
  const u1 = Math.max(1e-9, r.nextDouble());
  const u2 = r.nextDouble();
  const mag = Math.sqrt(-2.0 * Math.log(u1)) * 55.0;
  const ang = 2.0 * Math.PI * u2;
  return [cx + mag * Math.cos(ang), cy + mag * Math.sin(ang)];
});

const custom1000 = Array.from({length: 1000}, (_, i) => ({
  x: uniform1000[i][0],
  y: uniform1000[i][1],
  id: i,
}));

const updateA = uniform1000.slice(0, 250);
const updateB = Array.from({length: 250}, (_, i) => [
  updateA[i][0] + (r.nextDouble() - 0.5) * 20.0,
  updateA[i][1] + (r.nextDouble() - 0.5) * 20.0,
]);

const findQueries256 = Array.from({length: 256}, () => [
  r.nextDouble() * 1000.0,
  r.nextDouble() * 1000.0,
  10.0 + r.nextDouble() * 45.0,
]);

const rangeBoxes64 = Array.from({length: 64}, () => {
  const x0 = r.nextDouble() * 820.0;
  const y0 = r.nextDouble() * 820.0;
  const w = 40.0 + r.nextDouble() * 140.0;
  const h = 40.0 + r.nextDouble() * 140.0;
  return [x0, y0, x0 + w, y0 + h];
});

const tree5000 = quadtree().extent([[0, 0], [1000, 1000]]).addAll(uniform5000);
const treeClustered = quadtree(clustered2000);
const treeCustom = quadtree(custom1000, (d) => d.x, (d) => d.y);
const treeUpdate = quadtree().extent([[0, 0], [1000, 1000]]).addAll(uniform1000);

let sink = 0;

const cases = {
  "addAll.uniform_1000": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      const q = quadtree().extent([[0, 0], [1000, 1000]]).addAll(uniform1000);
      s += q.extent()[1][0];
    }
    sink += s;
  },
  "addAll.uniform_5000": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      const q = quadtree().extent([[0, 0], [1000, 1000]]).addAll(uniform5000);
      s += q.extent()[1][0];
    }
    sink += s;
  },
  "addAll.clustered_2000": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      const q = quadtree(clustered2000);
      s += q.extent()[1][0];
    }
    sink += s;
  },
  "addAll.custom_1000": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      const q = quadtree(custom1000, (d) => d.x, (d) => d.y);
      s += q.extent()[1][0];
    }
    sink += s;
  },
  "add.incremental_1000": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      const q = quadtree();
      for (let j = 0; j < uniform1000.length; j++) q.add(uniform1000[j]);
      s += q.extent()[1][0];
    }
    sink += s;
  },
  "find.unbounded_256": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < findQueries256.length; j++) {
        const [qx, qy] = findQueries256[j];
        const hit = tree5000.find(qx, qy);
        if (hit !== undefined) s += hit[0] + hit[1];
      }
    }
    sink += s;
  },
  "find.radius_256": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < findQueries256.length; j++) {
        const [qx, qy, rad] = findQueries256[j];
        const hit = tree5000.find(qx, qy, rad);
        if (hit !== undefined) s += hit[0] + hit[1];
      }
    }
    sink += s;
  },
  "find.custom_256": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < findQueries256.length; j++) {
        const [qx, qy] = findQueries256[j];
        const hit = treeCustom.find(qx, qy);
        if (hit !== undefined) s += hit.x + hit.y;
      }
    }
    sink += s;
  },
  "visit.full_5000": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      tree5000.visit((_, x0, y0, x1, y1) => {
        s += x1 - x0 + y1 - y0;
      });
    }
    sink += s;
  },
  "visit.range_64": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < rangeBoxes64.length; j++) {
        const [rx0, ry0, rx1, ry1] = rangeBoxes64[j];
        tree5000.visit((node, x0, y0, x1, y1) => {
          if (!node.length) {
            let leaf = node;
            do {
              const d = leaf.data;
              if (d[0] >= rx0 && d[0] < rx1 && d[1] >= ry0 && d[1] < ry1) {
                s += d[0] + d[1];
              }
            } while ((leaf = leaf.next));
          }
          return x0 >= rx1 || y0 >= ry1 || x1 < rx0 || y1 < ry0;
        });
      }
    }
    sink += s;
  },
  "visitAfter.full_5000": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      tree5000.visitAfter((_, x0, y0, x1, y1) => {
        s += x1 - x0 + y1 - y0;
      });
    }
    sink += s;
  },
  "copy.tree_2000": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      const c = treeClustered.copy();
      s += c.extent()[1][0];
    }
    sink += s;
  },
  "update.remove_add_500": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < updateA.length; j++) {
        treeUpdate.remove(updateA[j]).add(updateB[j]);
      }
      for (let j = 0; j < updateA.length; j++) {
        treeUpdate.remove(updateB[j]).add(updateA[j]);
      }
      s += treeUpdate.extent()[1][0];
    }
    sink += s;
  },
  "data_size.5000": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      const d = tree5000.data();
      s += d.length + tree5000.size();
    }
    sink += s;
  },
};

let target = "node";
let filter = "";
let batches = 9;
let batchMs = 60;
let warmMs = 300;
for (const arg of process.argv.slice(2)) {
  if (arg.startsWith("--target=")) target = arg.slice("--target=".length);
  else if (arg.startsWith("--filter=")) filter = arg.slice("--filter=".length);
  else if (arg.startsWith("--batches=")) batches = Number(arg.slice("--batches=".length));
  else if (arg.startsWith("--batch-ms=")) batchMs = Number(arg.slice("--batch-ms=".length));
  else if (arg.startsWith("--warm-ms=")) warmMs = Number(arg.slice("--warm-ms=".length));
}

const targetMs = batchMs * 0.25;
for (const [name, fn] of Object.entries(cases)) {
  if (filter && !name.includes(filter)) continue;
  let ops = 4;
  const warmEnd = performance.now() + warmMs;
  while (performance.now() < warmEnd) {
    const t0 = performance.now();
    fn(ops);
    if (performance.now() - t0 < targetMs) ops *= 2;
  }
  const samples = [];
  for (let b = 0; b < batches; b++) {
    const t0 = performance.now();
    fn(ops);
    samples.push(((performance.now() - t0) * 1e6) / ops);
  }
  samples.sort((a, b) => a - b);
  const median = samples[samples.length >> 1];
  console.log(
    `BENCH {"target":"${target}","case":"${name}","ns":${median.toFixed(2)},"ops":${ops}}`,
  );
}
if (sink === -123456789) console.log(sink);
