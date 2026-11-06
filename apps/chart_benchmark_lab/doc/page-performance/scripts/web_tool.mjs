// Usage:
//   node web_tool.mjs driver <build dir> <out file> [timeout s] [WxH]
//   node web_tool.mjs load <build dir> <out json> [runs] [WxH]
//   node web_tool.mjs shot <build dir> <png prefix> [WxH]
//   node web_tool.mjs run <chrome|safari|firefox> <build dir> <out file> [timeout s]
// Serves a build with the COOP and COEP headers and gzip, as GitHub Pages does for
// its text and wasm files, and drives one headless Chrome with its own profile.
import { spawn } from 'node:child_process';
import { createServer } from 'node:http';
import { gzipSync } from 'node:zlib';
import { appendFileSync, mkdtempSync, readFileSync, rmSync, statSync, writeFileSync } from 'node:fs';
import { extname, join, resolve } from 'node:path';
import { tmpdir } from 'node:os';

const [mode, dir, out, a3, a4] = process.argv.slice(2);
const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const types = { '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript', '.json': 'application/json', '.wasm': 'application/wasm', '.png': 'image/png', '.otf': 'font/otf', '.ttf': 'font/ttf', '.frag': 'application/octet-stream', '.bin': 'application/octet-stream' };
const gzipCache = new Map();
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

function serve(root, onLine, isolated = true) {
  const server = createServer((req, res) => {
    if (isolated) {
      res.setHeader('Cross-Origin-Opener-Policy', 'same-origin');
      res.setHeader('Cross-Origin-Embedder-Policy', 'require-corp');
    }
    res.setHeader('Cross-Origin-Resource-Policy', 'cross-origin');
    // GitHub Pages sends this cache time. The default stops each cache.
    res.setHeader('Cache-Control', process.env.LAB_CACHE ? 'max-age=600' : 'no-store');
    if (req.method === 'POST') {
      let body = '';
      req.on('data', (c) => (body += c));
      req.on('end', () => { onLine?.(body); res.writeHead(204); res.end(); });
      return;
    }
    let path = decodeURIComponent(new URL(req.url, 'http://x').pathname);
    if (path.endsWith('/')) path += 'index.html';
    const file = join(root, path);
    try {
      if (!statSync(file).isFile()) throw new Error('dir');
    } catch { res.writeHead(404); res.end(); return; }
    const ext = extname(file);
    res.setHeader('Content-Type', types[ext] ?? 'application/octet-stream');
    if (['.html', '.js', '.mjs', '.json', '.wasm', '.otf', '.ttf'].includes(ext)) {
      let body = gzipCache.get(file);
      if (!body) { body = gzipSync(readFileSync(file), { level: 6 }); gzipCache.set(file, body); }
      res.setHeader('Content-Encoding', 'gzip');
      res.writeHead(200);
      res.end(body);
    } else {
      res.writeHead(200);
      res.end(readFileSync(file));
    }
  });
  return new Promise((r) => server.listen(0, '127.0.0.1', () => r({ server, port: server.address().port })));
}

async function chrome(size = '1400,1000') {
  const profile = mkdtempSync(join(tmpdir(), 'lab-chrome-'));
  const port = 9300 + Math.floor(Math.random() * 500);
  const proc = spawn(CHROME, [
    '--headless=new', `--remote-debugging-port=${port}`, `--user-data-dir=${profile}`, '--no-first-run',
    '--no-default-browser-check', `--window-size=${size}`, '--disable-extensions', '--disable-renderer-backgrounding',
    '--disable-background-timer-throttling', '--disable-backgrounding-occluded-windows', '--use-angle=metal',
    '--enable-gpu', '--ignore-gpu-blocklist', '--disable-features=Translate', 'about:blank',
  ], { stdio: 'ignore' });
  let info;
  for (let i = 0; i < 60 && !info; i++) {
    await sleep(250);
    try { info = await (await fetch(`http://127.0.0.1:${port}/json/version`)).json(); } catch { /* wait */ }
  }
  if (!info) throw new Error('no chrome');
  const targets = await (await fetch(`http://127.0.0.1:${port}/json/list`)).json();
  const page = targets.find((t) => t.type === 'page');
  const ws = new WebSocket(page.webSocketDebuggerUrl);
  await new Promise((r) => (ws.onopen = r));
  let id = 0;
  const pending = new Map();
  const listeners = [];
  ws.onmessage = (e) => {
    const m = JSON.parse(e.data);
    if (m.id && pending.has(m.id)) { pending.get(m.id)(m); pending.delete(m.id); } else listeners.forEach((l) => l(m));
  };
  const send = (method, params = {}) => new Promise((r) => { const i = ++id; pending.set(i, r); ws.send(JSON.stringify({ id: i, method, params })); });
  return {
    send, on: (l) => listeners.push(l),
    close: async () => { try { ws.close(); } catch {} proc.kill(); await sleep(500); proc.kill('SIGKILL'); rmSync(profile, { recursive: true, force: true }); },
  };
}

if (mode === 'driver') {
  const timeout = Number(a3 ?? 240) * 1000;
  writeFileSync(out, '');
  let done = false;
  const { server, port } = await serve(resolve(dir), (line) => { appendFileSync(out, line + '\n'); if (line.includes('MATRIX_DONE')) done = true; });
  const c = await chrome((a4 ?? '1400x1000').replace('x', ','));
  await c.send('Page.enable');
  await c.send('Page.navigate', { url: `http://127.0.0.1:${port}/` });
  const t0 = Date.now();
  while (!done && Date.now() - t0 < timeout) await sleep(1000);
  console.log(done ? 'done' : 'timeout', Math.round((Date.now() - t0) / 1000), 's');
  await c.close();
  server.close();
  process.exit(0);
}

if (mode === 'load') {
  const runs = Number(a3 ?? 2);
  const results = [];
  const { server, port } = await serve(resolve(dir));
  for (let run = 0; run < runs; run++) {
    const c = await chrome((a4 ?? '1400x1000').replace('x', ','));
    const requests = new Map();
    const finished = [];
    c.on((m) => {
      if (m.method === 'Network.responseReceived') requests.set(m.params.requestId, { url: m.params.response.url, status: m.params.response.status });
      if (m.method === 'Network.loadingFinished') {
        const r = requests.get(m.params.requestId);
        if (r) finished.push({ ...r, bytes: m.params.encodedDataLength });
      }
    });
    await c.send('Page.enable');
    await c.send('Network.enable');
    await c.send('Performance.enable');
    await c.send('Network.setCacheDisabled', { cacheDisabled: true });
    // A home connection: 20 Mbit/s and 40 ms.
    await c.send('Network.emulateNetworkConditions', { offline: false, latency: 40, downloadThroughput: 20e6 / 8, uploadThroughput: 5e6 / 8 });
    await c.send('Page.addScriptToEvaluateOnNewDocument', { source: `
      window.addEventListener('flutter-first-frame', () => { window.__firstFrame = performance.now(); });
      new PerformanceObserver((l) => { for (const e of l.getEntries()) { window['__' + e.name.replace(/-/g, '')] = e.startTime; } }).observe({ type: 'paint', buffered: true });
    ` });
    await c.send('Page.navigate', { url: `http://127.0.0.1:${port}/` });
    const t0 = Date.now();
    let frame;
    while (Date.now() - t0 < 60000) {
      await sleep(100);
      const r = await c.send('Runtime.evaluate', { expression: 'JSON.stringify({f: window.__firstFrame, fp: window.__firstpaint, fcp: window.__firstcontentfulpaint, iso: window.crossOriginIsolated})', returnByValue: true });
      frame = r.result?.result?.value ? JSON.parse(r.result.result.value) : null;
      if (frame?.f) break;
    }
    await sleep(1500);
    finished.sort((a, b) => b.bytes - a.bytes);
    const total = finished.reduce((s, r) => s + r.bytes, 0);
    results.push({
      run,
      firstPaintMs: Math.round(frame?.fp ?? -1),
      firstContentfulMs: Math.round(frame?.fcp ?? -1),
      firstFlutterFrameMs: Math.round(frame?.f ?? -1),
      isolated: frame?.iso,
      totalKB: Math.round(total / 1024),
      files: finished.slice(0, 14).map((r) => `${Math.round(r.bytes / 1024)} KB ${r.url.replace(`http://127.0.0.1:${port}`, '')}`),
    });
    console.log(JSON.stringify(results.at(-1)));
    await c.close();
  }
  writeFileSync(out, JSON.stringify(results, null, 1));
  server.close();
  process.exit(0);
}

if (mode === 'shot') {
  const { server, port } = await serve(resolve(dir));
  const c = await chrome((a3 ?? '1400x1000').replace('x', ','));
  await c.send('Page.enable');
  await c.send('Network.enable');
  await c.send('Network.emulateNetworkConditions', { offline: false, latency: 40, downloadThroughput: 20e6 / 8, uploadThroughput: 5e6 / 8 });
  await c.send('Page.navigate', { url: `http://127.0.0.1:${port}/` });
  for (const [name, wait] of [['0.5s', 500], ['6s', 5500]]) {
    await sleep(wait);
    const shot = await c.send('Page.captureScreenshot', { format: 'png' });
    writeFileSync(`${out}-${name}.png`, Buffer.from(shot.result.data, 'base64'));
  }
  await c.close();
  server.close();
  process.exit(0);
}

if (mode === 'run') {
  // Each window opens on the built-in display, with no change of focus. A window
  // on another display stops the run.
  const browser = dir;
  const build = out;
  const file = a3;
  const timeout = Number(a4 ?? 300) * 1000;
  const here = new URL('.', import.meta.url).pathname;
  const BUILTIN = { x: 2600, y: 370, w: 1400, h: 1000 };
  const run = (cmd, args) => new Promise((res) => {
    const p = spawn(cmd, args, { stdio: ['ignore', 'pipe', 'pipe'] });
    let text = '';
    p.stdout.on('data', (d) => (text += d));
    p.stderr.on('data', (d) => (text += d));
    p.on('close', () => res(text.trim()));
  });
  const owner = { chrome: 'Google Chrome', safari: 'Safari', firefox: 'Firefox' }[browser];
  const onBuiltIn = async () => {
    const text = await run(join(here, 'windows'), []);
    return text.split('\n').filter((l) => l.startsWith(`window ${owner} `)).filter((l) => Number(/x=(-?\d+)/.exec(l)[1]) >= 2560 && Math.abs(Number(/w=(\d+)/.exec(l)[1]) - BUILTIN.w) <= 10);
  };
  writeFileSync(file, '');
  let done = false;
  const { server, port } = await serve(resolve(build), (line) => { appendFileSync(file, line + '\n'); if (line.includes('MATRIX_DONE')) done = true; }, browser === 'chrome');
  const url = `http://127.0.0.1:${port}/${process.env.LAB_QUERY ?? ''}`;
  const profile = mkdtempSync(join(tmpdir(), `lab-${browser}-`));
  let close = async () => {};
  let startSafariPage = async () => {};
  if (browser === 'chrome') {
    await run('open', ['-g', '-n', '-a', 'Google Chrome', '--args', `--user-data-dir=${profile}`, '--no-first-run', '--no-default-browser-check',
      `--window-position=${BUILTIN.x},${BUILTIN.y}`, `--window-size=${BUILTIN.w},${BUILTIN.h}`, '--disable-backgrounding-occluded-windows', '--disable-renderer-backgrounding',
      '--disable-background-timer-throttling', '--disable-features=CalculateNativeWinOcclusion,Translate', '--disable-extensions', url]);
    close = () => run('pkill', ['-f', `user-data-dir=${profile}`]);
  } else if (browser === 'firefox') {
    writeFileSync(join(profile, 'user.js'), [
      'browser.shell.checkDefaultBrowser|false', 'browser.aboutwelcome.enabled|false', 'datareporting.policy.dataSubmissionEnabled|false',
      'toolkit.telemetry.reportingpolicy.firstRun|false', 'browser.preonboarding.enabled|false', 'datareporting.healthreport.uploadEnabled|false',
      'browser.tabs.warnOnClose|false', 'browser.warnOnQuit|false', 'app.update.auto|false', 'browser.startup.page|0',
      'browser.startup.homepage_override.mstone|"ignore"', 'startup.homepage_welcome_url|""', 'startup.homepage_override_url|""',
    ].map((l) => { const [k, v] = l.split('|'); return `user_pref("${k}", ${v});`; }).join('\n') + '\n');
    writeFileSync(join(profile, 'xulstore.json'), JSON.stringify({ 'chrome://browser/content/browser.xhtml': { 'main-window': { screenX: String(BUILTIN.x), screenY: String(BUILTIN.y), width: String(BUILTIN.w), height: String(BUILTIN.h), sizemode: 'normal' } } }));
    await run('open', ['-g', '-n', '-a', 'Firefox', '--args', '--new-instance', '--profile', profile, url]);
    close = () => run('pkill', ['-f', profile]);
  } else {
    const id = await run('osascript', ['-e', `tell application "Safari"
      set w to make new document
      set bounds of front window to {${BUILTIN.x}, ${BUILTIN.y}, ${BUILTIN.x + BUILTIN.w}, ${BUILTIN.y + BUILTIN.h}}
      return id of front window
    end tell`]);
    if (!/^\d+$/.test(id)) { console.log('safari failed:', id); process.exit(2); }
    startSafariPage = () => run('osascript', ['-e', `tell application "Safari" to set URL of document of (first window whose id is ${id}) to "${url}"`]);
    close = () => run('osascript', ['-e', `tell application "Safari" to close (first window whose id is ${id})`]);
  }
  await sleep(browser === 'safari' ? 700 : 4000);
  const placed = await onBuiltIn();
  console.log('on the built-in display:', placed.join(' | ') || 'NONE');
  if (!placed.length) {
    console.log(await run(join(here, 'windows'), []));
    await close();
    server.close();
    console.log('STOP: the window is not on the built-in display');
    process.exit(3);
  }
  await startSafariPage();
  const t0 = Date.now();
  while (!done && Date.now() - t0 < timeout) {
    await sleep(1000);
    // A page that gives no line in this time does not run.
    if (Date.now() - t0 > 90000 && !readFileSync(file, 'utf8').length) break;
  }
  console.log(browser, done ? 'done' : 'TIMEOUT', Math.round((Date.now() - t0) / 1000), 's, lines', readFileSync(file, 'utf8').split('\n').filter((l) => l.startsWith('PAGE ')).length);
  await close();
  await sleep(1000);
  rmSync(profile, { recursive: true, force: true });
  server.close();
  process.exit(done ? 0 : 1);
}

if (mode === 'sw') {
  // Usage: node web_tool.mjs sw <build dir with the worker turned on for this host> <out json> [visits]
  // A host with no COOP and COEP headers, as GitHub Pages. One profile for all visits.
  const visits = Number(a3 ?? 5);
  const { server, port } = await serve(resolve(dir), null, false);
  const c = await chrome();
  await c.send('Page.enable');
  await c.send('Page.addScriptToEvaluateOnNewDocument', { source: "window.addEventListener('flutter-first-frame', () => { window.__firstFrame = performance.now(); });" });
  const rows = [];
  for (let v = 0; v < visits; v++) {
    await c.send('Page.navigate', { url: `http://127.0.0.1:${port}/` });
    const t0 = Date.now();
    let state;
    while (Date.now() - t0 < 60000) {
      await sleep(100);
      const r = await c.send('Runtime.evaluate', { expression: "JSON.stringify({f: window.__firstFrame, iso: window.crossOriginIsolated, reloaded: sessionStorage.getItem('isolate.reloaded'), worker: !!navigator.serviceWorker.controller, build: !!document.querySelector('flutter-view')})", returnByValue: true });
      state = r.result?.result?.value ? JSON.parse(r.result.result.value) : null;
      if (state?.f) break;
    }
    rows.push({ visit: v + 1, firstFrameMs: Math.round(state?.f ?? -1), isolated: state?.iso, worker: state?.worker, reloadedOnce: state?.reloaded });
    console.log(JSON.stringify(rows.at(-1)));
    // Chrome writes its code cache some time after the run.
    await sleep(4000);
  }
  writeFileSync(out, JSON.stringify(rows, null, 1));
  await c.close();
  server.close();
  process.exit(0);
}

if (mode === 'resizeshots') {
  // Usage: node web_tool.mjs resizeshots <build dir> <png prefix>. Headless. Takes the first load, then each library before and after a resize with no test.
  const { server, port } = await serve(resolve(dir));
  const c = await chrome('1400,1000');
  await c.send('Page.enable');
  await c.send('Network.enable');
  await c.send('Emulation.setDeviceMetricsOverride', { width: 1400, height: 1000, deviceScaleFactor: 1, mobile: false });
  await c.send('Page.navigate', { url: `http://127.0.0.1:${port}/` });
  const shot = async (name) => { const s = await c.send('Page.captureScreenshot', { format: 'png' }); writeFileSync(`${out}-${name}.png`, Buffer.from(s.result.data, 'base64')); };
  await sleep(800);
  await shot('splash');
  await sleep(6000);
  await shot('loaded');
  const click = async (x, y) => {
    await c.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x, y });
    await c.send('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', clickCount: 1 });
    await c.send('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', clickCount: 1 });
  };
  // Close the note of the web mode, if a coordinate is given.
  const [noteX, noteY] = (a3 ?? '0,0').split(',').map(Number);
  if (noteX) { await click(noteX, noteY); await sleep(500); }
  const y = Number(a4 ?? 160);
  const names = ['chartjs', 'flchart', 'graphic', 'syncfusion'];
  for (const [i, name] of names.entries()) {
    await c.send('Emulation.setDeviceMetricsOverride', { width: 1400, height: 1000, deviceScaleFactor: 1, mobile: false });
    await sleep(600);
    await click(336 + 40 + i * (1044 / 4) + 40, y);
    await sleep(1500);
    await shot(`${name}-1400`);
    for (let w = 1390; w >= 1200; w -= 10) {
      await c.send('Emulation.setDeviceMetricsOverride', { width: w, height: 1000, deviceScaleFactor: 1, mobile: false });
      await sleep(30);
    }
    await sleep(800);
    await shot(`${name}-1200`);
  }
  await c.close();
  server.close();
  process.exit(0);
}

if (mode === 'debugload') {
  // Usage: node web_tool.mjs debugload <build dir> <unused> <throttle 0|1> <override 0|1>
  const { server, port } = await serve(resolve(dir));
  const c = await chrome('1400,1000');
  c.on((m) => {
    if (m.method === 'Runtime.exceptionThrown') console.log('EXCEPTION', JSON.stringify(m.params.exceptionDetails).slice(0, 400));
    if (m.method === 'Runtime.consoleAPICalled') console.log('CONSOLE', m.params.type, JSON.stringify(m.params.args.map((a) => a.value ?? a.description)).slice(0, 300));
    if (m.method === 'Network.loadingFailed') console.log('FAILED', JSON.stringify(m.params).slice(0, 300));
  });
  await c.send('Page.enable');
  await c.send('Runtime.enable');
  await c.send('Network.enable');
  if (a3 === '1') await c.send('Network.emulateNetworkConditions', { offline: false, latency: 40, downloadThroughput: 20e6 / 8, uploadThroughput: 5e6 / 8 });
  if (a4 === '1') await c.send('Emulation.setDeviceMetricsOverride', { width: 1400, height: 1000, deviceScaleFactor: 1, mobile: false });
  await c.send('Page.addScriptToEvaluateOnNewDocument', { source: "window.addEventListener('flutter-first-frame', () => { window.__firstFrame = performance.now(); });" });
  await c.send('Page.navigate', { url: `http://127.0.0.1:${port}/` });
  for (let i = 0; i < 12; i++) {
    await sleep(1000);
    const r = await c.send('Runtime.evaluate', { expression: "JSON.stringify({t: Math.round(performance.now()), first: window.__firstFrame, splash: !!document.getElementById('splash'), view: !!document.querySelector('flutter-view'), iso: crossOriginIsolated, bodyKids: [...document.body.children].map(e=>e.tagName+(e.id?'#'+e.id:'')).join(',')})", returnByValue: true });
    console.log(r.result?.result?.value);
  }
  const s = await c.send('Page.captureScreenshot', { format: 'png' });
  writeFileSync(`${out}.png`, Buffer.from(s.result.data, 'base64'));
  await c.close();
  server.close();
  process.exit(0);
}
