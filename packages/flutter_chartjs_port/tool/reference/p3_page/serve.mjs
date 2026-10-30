// Original code, not ported from Chart.js: the server of the upstream page of the P3 comparison.
//
// Serves the upstream page of the P3 comparison (README.md of this folder)
// on a local port, with the headers of cross-origin isolation (COOP and
// COEP), so that performance.now() has its fine resolution. It also takes
// the lines of the page at POST /log?run=<tag> and appends each line to
// <log dir>/<tag>.txt.
//
// Usage, from packages/flutter_chartjs_port:
//
//   CHARTJS_DIST=<build>/dist/chart.js node tool/reference/p3_page/serve.mjs \
//     [--port 8123] [--field <field.json>] [--log-dir <dir>]
//
// The defaults: port 8123, the field tool/reference/p3_page/field.json and the
// log folder tool/reference/p3_page/logs/ (both in .gitignore). The page is
// http://127.0.0.1:<port>/bench.html.
//
// The server stops unless the build is a clean git checkout at the commit of
// the Chart.js entry of tool/port_sources.yaml and its package.json gives the
// release of the pin, as loadChartJs of tool/reference/scale_chart_common.mjs
// checks (a copy of its checks). It prints the SHA-256 of dist/chart.js and
// of each chunk, and serves them as /build.json. The page writes them into
// its ENV line, so that a night kit can check them before each run.

import {createHash} from 'node:crypto';
import {execFileSync} from 'node:child_process';
import {appendFileSync, existsSync, mkdirSync, readFileSync, readdirSync, realpathSync} from 'node:fs';
import {createServer} from 'node:http';
import {dirname, extname, join, normalize, resolve, sep} from 'node:path';
import {fileURLToPath} from 'node:url';

const PAGE = fileURLToPath(new URL('./', import.meta.url));
const PORT_SOURCES = fileURLToPath(new URL('../../port_sources.yaml', import.meta.url));

/** Writes [message] to stderr and stops the process. */
function stop(message) {
  console.error(message);
  process.exit(1);
}

/** The value of the option --[name] of the command line, or [fallback]. */
function option(name, fallback) {
  const i = process.argv.indexOf(`--${name}`);
  return i >= 0 && i + 1 < process.argv.length ? process.argv[i + 1] : fallback;
}

/** readPin of scale_chart_common.mjs: the Chart.js pin of tool/port_sources.yaml. */
function readPin() {
  const entry = readFileSync(PORT_SOURCES, 'utf8')
    .split(/^ {2}- header: /m)
    .find((e) => e.startsWith('Chart.js\n'));
  const version = entry?.match(/^ {4}version: "?v([^"\s]+)"?\s*$/m)?.[1];
  const commit = entry?.match(/^ {6}commit: "?([0-9a-f]{40})"?\s*$/m)?.[1];
  if (!version || !commit) stop(`${PORT_SOURCES} has no version and commit for Chart.js.`);
  const [release] = version.split('+');
  return {version, release, commit};
}

/** checkBuildCommit of scale_chart_common.mjs. */
function checkBuildCommit(root, pin) {
  const git = (...args) =>
    execFileSync('git', ['-C', root, ...args], {encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe']}).trim();
  const build = `Build Chart.js in a clone at the commit ${pin.commit} (see README.md).`;
  let top = null;
  try {
    top = git('rev-parse', '--show-toplevel');
  } catch {
    stop(`${root} is not a git checkout. ${build}`);
  }
  if (realpathSync(top) !== realpathSync(root)) stop(`${root} is not the top folder of the git checkout ${top}. ${build}`);
  const head = git('rev-parse', 'HEAD');
  if (head !== pin.commit) stop(`The build is at the commit ${head}; the pin is ${pin.commit}. ${build}`);
  const changes = git('status', '--porcelain', '--untracked-files=no');
  if (changes) stop(`The checkout ${root} has changes to tracked files:\n${changes}`);
  return head;
}

const sha256 = (path) => createHash('sha256').update(readFileSync(path)).digest('hex');

const dist = process.env.CHARTJS_DIST;
if (!dist || !existsSync(dist)) stop('Set CHARTJS_DIST to the path of dist/chart.js of the build.');
const distDir = dirname(resolve(dist));
const root = dirname(distDir);
const pin = readPin();
const packageJson = JSON.parse(readFileSync(join(root, 'package.json'), 'utf8'));
if (packageJson.name !== 'chart.js') stop(`${root}/package.json gives the package ${packageJson.name}, not chart.js.`);
if (packageJson.version !== pin.release) stop(`The build is chart.js ${packageJson.version}; the pin is ${pin.version}.`);
const commit = checkBuildCommit(root, pin);
const kurkle = join(root, 'node_modules', '@kurkle', 'color', 'dist', 'color.esm.js');
if (!existsSync(kurkle)) stop(`${kurkle} is missing: run the install of the build.`);

const files = {'dist/chart.js': sha256(join(distDir, 'chart.js')), 'dist/helpers.js': sha256(join(distDir, 'helpers.js'))};
for (const name of readdirSync(join(distDir, 'chunks')).filter((f) => f.endsWith('.js')).sort()) {
  files[`dist/chunks/${name}`] = sha256(join(distDir, 'chunks', name));
}
const buildInfo = {name: 'chart.js', version: `v${packageJson.version}`, commit, sha256: files};

const port = +option('port', '8123');
const field = resolve(option('field', join(PAGE, 'field.json')));
const logDir = resolve(option('log-dir', join(PAGE, 'logs')));
if (!existsSync(field)) stop(`${field} is missing: run field_gen.dart first (README.md).`);
mkdirSync(logDir, {recursive: true});

const TYPES = {'.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.json': 'application/json', '.map': 'application/json'};

/** The file of a request path, or null. Only the page files, the dist, @kurkle/color and the field. */
function fileOf(path) {
  if (path === '/' || path === '/bench.html') return join(PAGE, 'bench.html');
  if (path === '/bench.js' || path === '/cases.js') return join(PAGE, path.slice(1));
  if (path === '/field.json') return field;
  if (path === '/kurkle/color.esm.js') return kurkle;
  if (path.startsWith('/dist/')) {
    const file = normalize(join(distDir, path.slice('/dist/'.length)));
    return file.startsWith(distDir + sep) ? file : null;
  }
  return null;
}

const headers = {
  'Cross-Origin-Opener-Policy': 'same-origin',
  'Cross-Origin-Embedder-Policy': 'require-corp',
  'Cross-Origin-Resource-Policy': 'same-origin',
  'Cache-Control': 'no-store',
};

const server = createServer((req, res) => {
  const url = new URL(req.url, `http://${req.headers.host}`);
  if (req.method === 'POST' && url.pathname === '/log') {
    const run = (url.searchParams.get('run') || 'manual').replace(/[^A-Za-z0-9._-]/g, '_');
    const chunks = [];
    req.on('data', (c) => chunks.push(c));
    req.on('end', () => {
      appendFileSync(join(logDir, `${run}.txt`), `${Buffer.concat(chunks).toString('utf8')}\n`);
      res.writeHead(204, headers);
      res.end();
    });
    return;
  }
  if (req.method === 'GET' && url.pathname === '/build.json') {
    res.writeHead(200, {...headers, 'Content-Type': TYPES['.json']});
    res.end(JSON.stringify(buildInfo));
    return;
  }
  const file = req.method === 'GET' ? fileOf(url.pathname) : null;
  if (!file || !existsSync(file)) {
    res.writeHead(404, headers);
    res.end();
    return;
  }
  res.writeHead(200, {...headers, 'Content-Type': TYPES[extname(file)] || 'application/octet-stream'});
  res.end(readFileSync(file));
});

server.listen(port, '127.0.0.1', () => {
  console.log(`P3 page: http://127.0.0.1:${port}/bench.html`);
  console.log(`build: ${JSON.stringify(buildInfo)}`);
  console.log(`field: ${field} (SHA-256 ${sha256(field)})`);
  console.log(`logs: ${logDir}`);
});
