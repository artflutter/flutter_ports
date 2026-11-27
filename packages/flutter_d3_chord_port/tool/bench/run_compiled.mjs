// Original code, not ported from d3-chord: runner for dart2js/dart2wasm benchmark binaries.

import {readFileSync} from "node:fs";
import {createRequire} from "node:module";
import path from "node:path";
import {pathToFileURL} from "node:url";

const [mode, file, ...rest] = process.argv.slice(2);
const abs = path.resolve(file);

if (mode === "js") {
  globalThis.self = globalThis;
  globalThis.window = globalThis;
  globalThis.dartMainRunner = (main) => main(rest);
  const require = createRequire(import.meta.url);
  require(abs);
} else if (mode === "wasm") {
  const mjs = abs.replace(/\.wasm$/, ".mjs");
  const mod = await import(pathToFileURL(mjs).href);
  const app = await (await mod.compile(readFileSync(abs))).instantiate({});
  app.invokeMain(...rest);
} else {
  console.error("Usage: node run_compiled.mjs <js|wasm> <file> [args...]");
  process.exit(2);
}
