// Original code, not ported from d3-delaunay: upstream Node.js benchmark.

import { mkdirSync, rmSync, cpSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { pathToFileURL } from 'node:url';
import { performance } from 'node:perf_hooks';

const repoRoot = resolve(import.meta.dirname, '../../../..');

const stage = join(tmpdir(), `d3_delaunay_bench_${process.pid}`);
rmSync(stage, { recursive: true, force: true });
mkdirSync(join(stage, 'node_modules/robust-predicates/esm'), { recursive: true });
mkdirSync(join(stage, 'node_modules/delaunator'), { recursive: true });
mkdirSync(join(stage, 'd3-delaunay'), { recursive: true });

const rpRoot = join(repoRoot, 'third_party/robust-predicates');
cpSync(join(rpRoot, 'src'), join(stage, 'node_modules/robust-predicates/src'), { recursive: true });
cpSync(join(rpRoot, 'index.js'), join(stage, 'node_modules/robust-predicates/index.js'));
cpSync(join(rpRoot, 'package.json'), join(stage, 'node_modules/robust-predicates/package.json'));
cpSync(join(rpRoot, 'compile.js'), join(stage, 'node_modules/robust-predicates/compile.js'));

const prevCwd = process.cwd();
process.chdir(join(stage, 'node_modules/robust-predicates'));
await import(pathToFileURL(join(stage, 'node_modules/robust-predicates/compile.js')).href);
process.chdir(prevCwd);

cpSync(join(repoRoot, 'third_party/delaunator/index.js'), join(stage, 'node_modules/delaunator/index.js'));
cpSync(join(repoRoot, 'third_party/delaunator/package.json'), join(stage, 'node_modules/delaunator/package.json'));
cpSync(join(repoRoot, 'third_party/d3-delaunay/src'), join(stage, 'd3-delaunay/src'), { recursive: true });
cpSync(join(repoRoot, 'third_party/d3-delaunay/package.json'), join(stage, 'd3-delaunay/package.json'));

const { Delaunay } = await import(pathToFileURL(join(stage, 'd3-delaunay/src/index.js')).href);
const { default: Delaunator } = await import(pathToFileURL(join(stage, 'node_modules/delaunator/index.js')).href);
const { orient2d } = await import(pathToFileURL(join(stage, 'node_modules/robust-predicates/index.js')).href);

function makeLcg(seed) {
  let s = seed;
  return () => {
    s = (s * 48271) % 2147483647;
    return s / 2147483647.0;
  };
}

class CountingCanvasPath {
  constructor() { this.acc = 0; }
  moveTo(x, y) { this.acc += x + y; }
  lineTo(x, y) { this.acc += x + y; }
  closePath() { this.acc += 1; }
  arc(x, y, r) { this.acc += x + y + r; }
  rect(x, y, w, h) { this.acc += x + y + w + h; }
}

const r = makeLcg(42);
function makeUniform(n) {
  const out = new Float64Array(n * 2);
  for (let i = 0; i < n; ++i) {
    out[2 * i] = r() * 1000.0;
    out[2 * i + 1] = r() * 1000.0;
  }
  return out;
}

const uniform1000 = makeUniform(1000);
const uniform1000Pairs = Array.from({ length: 1000 }, (_, i) => [uniform1000[2 * i], uniform1000[2 * i + 1]]);
const uniform5000 = makeUniform(5000);

const centers = [[200, 220], [780, 240], [500, 500], [260, 760], [760, 780]];
const clustered2000 = new Float64Array(4000);
for (let i = 0; i < 2000; ++i) {
  const [cx, cy] = centers[i % centers.length];
  const u1 = Math.max(1e-9, r());
  const u2 = r();
  const mag = Math.sqrt(-2.0 * Math.log(u1)) * 55.0;
  const ang = 2.0 * Math.PI * u2;
  clustered2000[2 * i] = cx + mag * Math.cos(ang);
  clustered2000[2 * i + 1] = cy + mag * Math.sin(ang);
}

const findQueries512 = makeUniform(512);

const orientCoords = new Float64Array(10000 * 6);
const tiny = Math.pow(2, -43);
for (let i = 0; i < 10000; ++i) {
  const base = i * 6;
  if (i % 10 === 0) {
    orientCoords[base] = 0.95 + tiny * (i % 128) / 128.0;
    orientCoords[base + 1] = 0.95 + tiny * ((i * 7) % 128) / 128.0;
    orientCoords[base + 2] = 18.0;
    orientCoords[base + 3] = 18.0;
    orientCoords[base + 4] = 16.8;
    orientCoords[base + 5] = 16.8;
  } else {
    orientCoords[base] = r() * 1000.0;
    orientCoords[base + 1] = r() * 1000.0;
    orientCoords[base + 2] = r() * 1000.0;
    orientCoords[base + 3] = r() * 1000.0;
    orientCoords[base + 4] = r() * 1000.0;
    orientCoords[base + 5] = r() * 1000.0;
  }
}

const d1000 = new Delaunay(Float64Array.from(uniform1000));
const d5000 = new Delaunay(Float64Array.from(uniform5000));
const v1000 = d1000.voronoi([0, 0, 1000, 1000]);

const updDelaunator = new Delaunator(Float64Array.from(uniform1000));
const updDelaunay = new Delaunay(Float64Array.from(uniform1000));
const updVoronoi = new Delaunay(Float64Array.from(uniform1000)).voronoi([0, 0, 1000, 1000]);

let sink = 0;
const cases = {
  'orient2d.exact_10k': (n) => {
    let s = 0;
    const c = orientCoords;
    for (let k = 0; k < n; ++k) {
      for (let i = 0; i < 60000; i += 6) {
        s += orient2d(c[i], c[i + 1], c[i + 2], c[i + 3], c[i + 4], c[i + 5]);
      }
    }
    sink += s;
  },
  'delaunator.uniform_1000': (n) => {
    let s = 0;
    for (let k = 0; k < n; ++k) {
      const d = new Delaunator(uniform1000);
      s += d.trianglesLen;
    }
    sink += s;
  },
  'delaunator.uniform_5000': (n) => {
    let s = 0;
    for (let k = 0; k < n; ++k) {
      const d = new Delaunator(uniform5000);
      s += d.trianglesLen;
    }
    sink += s;
  },
  'delaunator.clustered_2000': (n) => {
    let s = 0;
    for (let k = 0; k < n; ++k) {
      const d = new Delaunator(clustered2000);
      s += d.trianglesLen;
    }
    sink += s;
  },
  'delaunator.update_1000': (n) => {
    let s = 0;
    const coords = updDelaunator.coords;
    for (let k = 0; k < n; ++k) {
      const delta = (k & 1) === 0 ? 0.25 : -0.25;
      for (let i = 0; i < 200; i += 2) coords[i] += delta;
      updDelaunator.update();
      s += updDelaunator.trianglesLen;
    }
    sink += s;
  },
  'delaunay.from_1000': (n) => {
    let s = 0;
    for (let k = 0; k < n; ++k) {
      const d = Delaunay.from(uniform1000Pairs);
      s += d.triangles.length;
    }
    sink += s;
  },
  'delaunay.update_1000': (n) => {
    let s = 0;
    const pts = updDelaunay.points;
    for (let k = 0; k < n; ++k) {
      const delta = (k & 1) === 0 ? 0.25 : -0.25;
      for (let i = 0; i < 200; i += 2) pts[i] += delta;
      updDelaunay.update();
      s += updDelaunay.triangles.length;
    }
    sink += s;
  },
  'delaunay.find_512': (n) => {
    let s = 0;
    const q = findQueries512;
    for (let k = 0; k < n; ++k) {
      let last = 0;
      for (let i = 0; i < 1024; i += 2) {
        last = d5000.find(q[i], q[i + 1], last);
        s += last;
      }
    }
    sink += s;
  },
  'delaunay.neighbors_1000': (n) => {
    let s = 0;
    for (let k = 0; k < n; ++k) {
      for (let i = 0; i < 1000; ++i) {
        for (const nb of d1000.neighbors(i)) s += nb;
      }
    }
    sink += s;
  },
  'voronoi.build_1000': (n) => {
    let s = 0;
    for (let k = 0; k < n; ++k) {
      const v = d1000.voronoi([0, 0, 1000, 1000]);
      s += v.circumcenters[0];
    }
    sink += s;
  },
  'voronoi.update_1000': (n) => {
    let s = 0;
    const pts = updVoronoi.delaunay.points;
    for (let k = 0; k < n; ++k) {
      const delta = (k & 1) === 0 ? 0.25 : -0.25;
      for (let i = 0; i < 200; i += 2) pts[i] += delta;
      updVoronoi.update();
      s += updVoronoi.circumcenters[0];
    }
    sink += s;
  },
  'voronoi.cellPolygons_1000': (n) => {
    let s = 0;
    for (let k = 0; k < n; ++k) {
      for (let i = 0; i < 1000; ++i) {
        const poly = v1000.cellPolygon(i);
        if (poly) s += poly.length;
      }
    }
    sink += s;
  },
  'voronoi.renderSvg_1000': (n) => {
    let s = 0;
    for (let k = 0; k < n; ++k) {
      const svg = v1000.render();
      if (svg) s += svg.length;
    }
    sink += s;
  },
  'voronoi.renderCanvas_1000': (n) => {
    const ctx = new CountingCanvasPath();
    for (let k = 0; k < n; ++k) {
      v1000.render(ctx);
      d1000.render(ctx);
    }
    sink += ctx.acc;
  },
};

let target = 'node';
let filter = '';
let batches = 9;
let batchMs = 60;
let warmMs = 300;
for (const arg of process.argv.slice(2)) {
  if (arg.startsWith('--target=')) target = arg.slice('--target='.length);
  else if (arg.startsWith('--filter=')) filter = arg.slice('--filter='.length);
  else if (arg.startsWith('--batches=')) batches = Number(arg.slice('--batches='.length));
  else if (arg.startsWith('--batch-ms=')) batchMs = Number(arg.slice('--batch-ms='.length));
  else if (arg.startsWith('--warm-ms=')) warmMs = Number(arg.slice('--warm-ms='.length));
}

const targetMs = batchMs * 0.25;
for (const [name, fn] of Object.entries(cases)) {
  if (filter && !name.includes(filter)) continue;
  let ops = 1;
  const warmEnd = performance.now() + warmMs;
  while (performance.now() < warmEnd) {
    const t0 = performance.now();
    fn(ops);
    const dt = performance.now() - t0;
    if (dt < targetMs) ops *= 2;
  }
  const samples = [];
  for (let b = 0; b < batches; b++) {
    const t0 = performance.now();
    fn(ops);
    const dt = performance.now() - t0;
    samples.push((dt * 1e6) / ops);
  }
  samples.sort((a, b) => a - b);
  const median = samples[samples.length >> 1];
  console.log(`BENCH {"target":"${target}","case":"${name}","ns":${median.toFixed(2)},"ops":${ops}}`);
}
if (sink === -123456789) console.log(sink);
rmSync(stage, { recursive: true, force: true });
