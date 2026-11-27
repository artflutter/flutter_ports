// Original code, not ported from d3-geo: upstream Node.js benchmark.

import {performance} from "node:perf_hooks";
import {registerHooks} from "node:module";
import {fileURLToPath, pathToFileURL} from "node:url";
import path from "node:path";

const here = path.dirname(fileURLToPath(import.meta.url));
const repo = path.resolve(here, "../../../..");

const internmapUrl = pathToFileURL(
  path.join(repo, "third_party/internmap/src/index.js"),
).href;
const d3ArrayUrl = pathToFileURL(
  path.join(repo, "third_party/d3-array/src/index.js"),
).href;

registerHooks({
  resolve(specifier, context, nextResolve) {
    if (specifier === "internmap") {
      return {url: internmapUrl, shortCircuit: true};
    }
    if (specifier === "d3-array") {
      return {url: d3ArrayUrl, shortCircuit: true};
    }
    return nextResolve(specifier, context);
  },
});

const d3 = await import(
  pathToFileURL(path.join(repo, "third_party/d3-geo/src/index.js")).href
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

class BenchCanvasSink {
  constructor() {
    this.acc = 0;
  }
  moveTo(x, y) { this.acc += x + y; }
  closePath() { this.acc += 1; }
  lineTo(x, y) { this.acc += x + y; }
  quadraticCurveTo(x1, y1, x, y) { this.acc += x1 + y1 + x + y; }
  bezierCurveTo(x1, y1, x2, y2, x, y) { this.acc += x1 + y1 + x2 + y2 + x + y; }
  arcTo(x1, y1, x2, y2, r) { this.acc += x1 + y1 + x2 + y2 + r; }
  arc(x, y, r, a0, a1) { this.acc += x + y + r + a0 + a1; }
  rect(x, y, w, h) { this.acc += x + y + w + h; }
}

const r = new Lcg(42);
const globalPts = Array.from({length: 1000}, () => [
  -180 + r.nextDouble() * 360,
  -80 + r.nextDouble() * 160,
]);

const usPts = Array.from({length: 1000}, (_, i) => {
  const mod = i % 10;
  if (mod === 0) return [-165 + r.nextDouble() * 25, 58 + r.nextDouble() * 10];
  if (mod === 1) return [-160 + r.nextDouble() * 5, 19 + r.nextDouble() * 3];
  if (mod === 2) return [-10 + r.nextDouble() * 40, 35 + r.nextDouble() * 20];
  return [-124 + r.nextDouble() * 55, 25 + r.nextDouble() * 24];
});

const polys = [];
for (let p = 0; p < 20; p++) {
  const cLon = -160 + (p % 5) * 75.0 + (r.nextDouble() - 0.5) * 15;
  const cLat = -55 + Math.floor(p / 5) * 35.0 + (r.nextDouble() - 0.5) * 10;
  const rx = 10 + r.nextDouble() * 14;
  const ry = 6 + r.nextDouble() * 10;
  const ring = [];
  const verts = 60;
  for (let k = 0; k < verts; k++) {
    const a = (-2 * Math.PI * k) / verts;
    const wobble = 0.8 + 0.35 * Math.sin(3 * a + p) + 0.15 * Math.cos(5 * a);
    const lon = Math.max(-179.5, Math.min(179.5, cLon + rx * wobble * Math.cos(a)));
    const lat = Math.max(-84.0, Math.min(84.0, cLat + ry * wobble * Math.sin(a)));
    ring.push([lon, lat]);
  }
  ring.push(ring[0]);
  polys.push([ring]);
}
const worldPolys = {type: "MultiPolygon", coordinates: polys};
const graticule = d3.geoGraticule10();

const outer = d3.geoCircle().center([10, 20]).radius(35).precision(2)().coordinates[0];
const inner = d3.geoCircle().center([10, 20]).radius(10).precision(6)().coordinates[0].reverse();
const targetPoly = {type: "Polygon", coordinates: [outer, inner]};

const containsPts = Array.from({length: 500}, () => [
  -40 + r.nextDouble() * 100,
  -30 + r.nextDouble() * 100,
]);

const ortho = d3.geoOrthographic().rotate([-10, -25, 5]);
const merc = d3.geoMercator();
const eqEarth = d3.geoEqualEarth();
const natEarth = d3.geoNaturalEarth1();
const albersUsa = d3.geoAlbersUsa();

const canvasSink = new BenchCanvasSink();
const pathOrthoCanvas = d3.geoPath(d3.geoOrthographic().rotate([-10, -25, 0]), canvasSink);
const pathMercCanvas = d3.geoPath(d3.geoMercator(), canvasSink);
const pathNatSvg = d3.geoPath(d3.geoNaturalEarth1());
const pathEqCanvas = d3.geoPath(d3.geoEqualEarth(), canvasSink);

let sink = 0;
const eatText = (s) => (s && s.length ? s.length + s.charCodeAt(s.length - 1) : 0);

const cases = {
  "project.orthographic_1k": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < globalPts.length; j++) {
        const p = ortho(globalPts[j]);
        if (p) s += p[0] + p[1];
      }
    }
    sink += s;
  },
  "project.mercator_1k": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < globalPts.length; j++) {
        const p = merc(globalPts[j]);
        if (p) s += p[0] + p[1];
      }
    }
    sink += s;
  },
  "project.equalEarth_1k": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < globalPts.length; j++) {
        const p = eqEarth(globalPts[j]);
        const inv = eqEarth.invert(p);
        s += p[0] + inv[1];
      }
    }
    sink += s;
  },
  "project.naturalEarth1_1k": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < globalPts.length; j++) {
        const p = natEarth(globalPts[j]);
        const inv = natEarth.invert(p);
        s += p[0] + inv[1];
      }
    }
    sink += s;
  },
  "project.albersUsa_1k": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < usPts.length; j++) {
        const p = albersUsa(usPts[j]);
        if (p) s += p[0] + p[1];
      }
    }
    sink += s;
  },
  "path.ortho_canvas": (n) => {
    canvasSink.acc = 0;
    for (let i = 0; i < n; i++) {
      pathOrthoCanvas(worldPolys);
      pathOrthoCanvas(graticule);
    }
    sink += canvasSink.acc;
  },
  "path.mercator_canvas": (n) => {
    canvasSink.acc = 0;
    for (let i = 0; i < n; i++) {
      pathMercCanvas(worldPolys);
      pathMercCanvas(graticule);
    }
    sink += canvasSink.acc;
  },
  "path.naturalEarth1_svg": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      s += eatText(pathNatSvg(worldPolys));
    }
    sink += s;
  },
  "path.equalEarth_canvas": (n) => {
    canvasSink.acc = 0;
    for (let i = 0; i < n; i++) {
      pathEqCanvas(worldPolys);
      pathEqCanvas(graticule);
    }
    sink += canvasSink.acc;
  },
  "geoArea.world": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      s += d3.geoArea(worldPolys);
    }
    sink += s;
  },
  "geoBounds.world": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      const b = d3.geoBounds(worldPolys);
      s += b[0][0] + b[1][1];
    }
    sink += s;
  },
  "geoContains.500": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < containsPts.length; j++) {
        if (d3.geoContains(targetPoly, containsPts[j])) s++;
      }
    }
    sink += s;
  },
};

function measureCase(fn, {warmupMs = 250, batchMs = 60, batches = 9} = {}) {
  const start = performance.now();
  let batch = 1;
  while (performance.now() - start < warmupMs) {
    const t0 = performance.now();
    fn(batch);
    const dt = performance.now() - t0;
    if (dt < 5) {
      batch *= 2;
    } else if (dt < batchMs / 2) {
      batch = Math.min(10000000, Math.max(1, Math.ceil((batch * batchMs) / dt)));
    }
  }
  const samples = [];
  for (let b = 0; b < batches; b++) {
    const t0 = performance.now();
    fn(batch);
    const dt = performance.now() - t0;
    samples.push((dt * 1e6) / batch);
  }
  samples.sort((a, b) => a - b);
  return samples[Math.floor(samples.length / 2)];
}

const filter = process.argv[2] ?? null;
for (const [name, fn] of Object.entries(cases)) {
  if (filter && !name.includes(filter)) continue;
  const ns = measureCase(fn);
  console.log(`BENCH {"case":"${name}","ns_per_op":${ns.toFixed(1)}}`);
}
if (sink === 1e308) console.log(sink);
