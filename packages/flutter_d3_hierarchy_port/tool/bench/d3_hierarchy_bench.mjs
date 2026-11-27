// Original code, not ported from d3-hierarchy: upstream Node.js benchmark.

import {performance} from "node:perf_hooks";
import {fileURLToPath, pathToFileURL} from "node:url";
import path from "node:path";

const here = path.dirname(fileURLToPath(import.meta.url));
const repo = path.resolve(here, "../../../..");

const d3 = await import(
  pathToFileURL(path.join(repo, "third_party/d3-hierarchy/src/index.js")).href
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

function generateTree(count, seed) {
  const r = new Lcg(seed);
  const childLists = Array.from({length: count}, () => []);
  const parentIds = new Int32Array(count).fill(-1);
  const paths = new Array(count);
  const sizes = new Float64Array(count);

  paths[0] = "/n0";
  for (let i = 1; i < count; i++) {
    const pool = Math.floor(i * 0.35);
    const p = pool > 0 ? Math.floor(r.nextDouble() * (pool + 1)) : 0;
    parentIds[i] = p;
    paths[i] = `${paths[p]}/n${i}`;
  }
  const isParent = new Uint8Array(count);
  for (let i = 1; i < count; i++) isParent[parentIds[i]] = 1;
  for (let i = 0; i < count; i++) {
    sizes[i] = isParent[i] ? 0.0 : 10.0 + Math.floor(r.nextDouble() * 5000.0);
  }
  let nested = null;
  for (let i = count - 1; i >= 0; i--) {
    const kids = childLists[i];
    const node = {id: i, size: sizes[i], children: kids.length ? kids : null};
    if (i > 0) childLists[parentIds[i]].push(node);
    else nested = node;
  }
  const rows = Array.from({length: count}, (_, i) => ({
    id: `n${i}`,
    parentId: i === 0 ? null : `n${parentIds[i]}`,
    path: paths[i],
    size: sizes[i],
  }));
  const leafPaths = [];
  for (let i = 0; i < count; i++) {
    if (!isParent[i]) leafPaths.push(paths[i]);
  }
  return {nested, rows, leafPaths};
}

const t252 = generateTree(252, 42);
const t1000 = generateTree(1000, 1337);

const h1000 = d3.hierarchy(t1000.nested)
  .sum((d) => d.size)
  .sort((a, b) => b.value - a.value);
const h1000Unsorted = d3.hierarchy(t1000.nested).sum((d) => d.size);

const h252 = d3.hierarchy(t252.nested)
  .sum((d) => d.size)
  .sort((a, b) => b.value - a.value);

const rect252Squarify = h252.copy();
const rect252Binary = h252.copy();
const rect252Resquarify = h252.copy();
const rect252Partition = h252.copy();
const circ252Pack = h252.copy();
const point252Tree = h252.copy();
const point252Cluster = h252.copy();

const stratId = d3.stratify();
const stratPath = d3.stratify().path((d) => d);

const tmSquarify = d3.treemap().size([960, 500]).paddingInner(1).paddingTop(12);
const tmBinary = d3.treemap().tile(d3.treemapBinary).size([960, 500]).paddingInner(1);
const tmResquarify = d3.treemap().tile(d3.treemapResquarify).size([960, 500]);
const partLayout = d3.partition().size([960, 500]).padding(1);
const packLayout = d3.pack().size([960, 960]).padding(3);
const treeLayout = d3.tree().size([960, 500]);
const clusterLayout = d3.cluster().size([960, 500]);

const rng = new Lcg(999);
const radii64 = Array.from({length: 64}, () => 2.0 + rng.nextDouble() * 48.0);
const sibCircles = radii64.map((r) => ({r}));

let sink = 0;

const cases = {
  "hierarchy.build_252": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) s += d3.hierarchy(t252.nested).height;
    sink += s;
  },
  "stratify.id_252": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) s += stratId(t252.rows).height;
    sink += s;
  },
  "stratify.path_252": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) s += stratPath(t252.leafPaths).height;
    sink += s;
  },
  "traverse.eachBefore_1k": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) h1000.eachBefore((node) => { s += node.depth; });
    sink += s;
  },
  "traverse.eachAfter_1k": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) h1000.eachAfter((node) => { s += node.height; });
    sink += s;
  },
  "traverse.bfs_each_1k": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) h1000.each((node) => { s += node.depth; });
    sink += s;
  },
  "traverse.desc_leaves_1k": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) s += h1000.descendants().length + h1000.leaves().length;
    sink += s;
  },
  "aggregate.sum_count_1k": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      h1000.sum((d) => d.size);
      s += h1000.value;
      h1000.count();
      s += h1000.value;
    }
    sink += s;
  },
  "aggregate.sort_1k": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      h1000Unsorted.sort((a, b) => b.value - a.value);
      h1000Unsorted.sort((a, b) => a.value - b.value);
      s += h1000Unsorted.children[0].value;
    }
    sink += s;
  },
  "treemap.squarify_252": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      const r = tmSquarify(rect252Squarify);
      s += r.x1 + r.y1;
    }
    sink += s;
  },
  "treemap.binary_252": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      const r = tmBinary(rect252Binary);
      s += r.x1 + r.y1;
    }
    sink += s;
  },
  "treemap.resquarify_252": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      delete rect252Resquarify._squarify;
      tmResquarify.size([960, 500])(rect252Resquarify);
      tmResquarify.size([800, 600])(rect252Resquarify);
      tmResquarify.size([600, 800])(rect252Resquarify);
      tmResquarify.size([500, 960])(rect252Resquarify);
      s += rect252Resquarify.x1;
    }
    sink += s;
  },
  "partition.252": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      const r = partLayout(rect252Partition);
      s += r.x1 + r.y1;
    }
    sink += s;
  },
  "pack.252": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      const r = packLayout(circ252Pack);
      s += r.r;
    }
    sink += s;
  },
  "packSiblings.64": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < 64; j++) sibCircles[j].r = radii64[j];
      d3.packSiblings(sibCircles);
      const enc = d3.packEnclose(sibCircles);
      s += enc.r;
    }
    sink += s;
  },
  "tree.252": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      const r = treeLayout(point252Tree);
      s += r.x + r.y;
    }
    sink += s;
  },
  "cluster.252": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      const r = clusterLayout(point252Cluster);
      s += r.x + r.y;
    }
    sink += s;
  },
};

const args = process.argv.slice(2);
let filter = "";
for (let i = 0; i < args.length; i++) {
  if (args[i] === "--filter" && i + 1 < args.length) filter = args[++i];
}

const batches = 9;
const batchMs = 60;
const warmMs = 250;

for (const [name, fn] of Object.entries(cases)) {
  if (filter && !name.includes(filter)) continue;
  let iters = 1;
  const w0 = performance.now();
  while (performance.now() - w0 < warmMs) {
    fn(iters);
    if (performance.now() - w0 < 20) iters *= 2;
  }
  let probe = 1;
  while (true) {
    const t0 = performance.now();
    fn(probe);
    const dt = performance.now() - t0;
    if (dt >= batchMs || probe >= 1 << 24) break;
    probe = dt === 0 ? probe * 8 : Math.min(probe * 8, Math.max(probe + 1, Math.ceil((probe * batchMs) / dt)));
  }
  const samples = [];
  for (let b = 0; b < batches; b++) {
    const t0 = performance.now();
    fn(probe);
    const dt = performance.now() - t0;
    samples.push((dt * 1e6) / probe);
  }
  samples.sort((a, b) => a - b);
  const median = samples[samples.length >> 1];
  console.log(
    `BENCH ${JSON.stringify({target: "node", case: name, ns_op: Number(median.toFixed(1)), iters: probe})}`,
  );
}
if (sink === -1.23456789) console.log(sink);
