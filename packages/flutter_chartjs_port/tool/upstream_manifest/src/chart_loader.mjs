// Original code, not ported from Chart.js: loads the Chart.js sources of a checkout for the upstream manifest.
//
// The spec files read Chart.helpers, Chart.registry and Chart.platforms when
// their describe bodies run. For example helpers.easing.tests.js makes one case
// for each key of Chart.helpers.easingEffects. So the manifest needs the real
// Chart object. It does not build Chart.js: Node.js strips the TypeScript
// types of src/**/*.ts when it loads them (Node.js 22.18 or later), and the
// hooks below only resolve names. Nothing is written into the checkout
// (Chart.js ADR 0035).
//
// - A `./x.js` import of a file that exists only as `./x.ts` loads the `.ts`
//   file, as the bundler of Chart.js does.
// - `../../package.json` (core.controller.js reads `version`) becomes a
//   module that exports its `version`.
// - `@kurkle/color` becomes a module with an empty `Color` class. The
//   manifest never calls helpers.color, and the checkout has no
//   node_modules.

import {existsSync, readFileSync} from 'node:fs';
import {registerHooks} from 'node:module';
import {fileURLToPath, pathToFileURL} from 'node:url';

/** The module that replaces `@kurkle/color`. */
const COLOR_STUB =
  'data:text/javascript,export class Color {}; export default Color;';

let registeredRoot = null;

/** Registers the resolve and load hooks for the checkout at `root`. */
function register(root) {
  if (registeredRoot !== null) {
    if (registeredRoot !== root) {
      throw new Error(`hooks already registered for ${registeredRoot}`);
    }
    return;
  }
  registeredRoot = root;
  const rootUrl = pathToFileURL(`${root}/`).href;
  registerHooks({
    resolve(specifier, context, nextResolve) {
      const parent = context.parentURL ?? '';
      if (specifier === '@kurkle/color' && parent.startsWith(rootUrl)) {
        return {url: COLOR_STUB, shortCircuit: true};
      }
      if (specifier.startsWith('.') && specifier.endsWith('.js') &&
          parent.startsWith(rootUrl)) {
        const url = new URL(specifier, parent);
        const path = fileURLToPath(url);
        if (!existsSync(path) && existsSync(`${path.slice(0, -3)}.ts`)) {
          return {
            url: `${url.href.slice(0, -3)}.ts`,
            format: 'module-typescript',
            shortCircuit: true,
          };
        }
      }
      return nextResolve(specifier, context);
    },
    load(url, context, nextLoad) {
      if (url.startsWith(rootUrl) && url.endsWith('/package.json')) {
        const {version} = JSON.parse(readFileSync(fileURLToPath(url), 'utf8'));
        const source = `export const version = ${JSON.stringify(version)};`;
        return {format: 'module', source, shortCircuit: true};
      }
      return nextLoad(url, context);
    },
  });
}

/**
 * Loads `src/index.umd.ts` (the Chart object of the Karma bundle) and
 * `src/core/core.defaults.js` of the checkout at `root`. Returns `{Chart,
 * defaults, overrides, descriptors}`.
 */
export async function loadChart(root) {
  if (!process.features.typescript) {
    throw new Error(
      'This Node.js cannot strip TypeScript types. Use Node.js 22.18 or later.',
    );
  }
  register(root);
  const load = (path) => import(pathToFileURL(`${root}/src/${path}`).href);
  const umd = await load('index.umd.ts');
  const core = await load('core/core.defaults.js');
  // index.umd.ts registers the module namespaces of the four index files.
  // Rollup makes plain objects of them, but a Node.js namespace object is a
  // "[object Module]", which helpers.core `each` does not loop over. So the
  // register call runs again with plain copies. Their keys are in code-unit
  // order, not in export order. The manifest sorts the defaults keys.
  const namespaces = await Promise.all([
    'controllers/index.js',
    'scales/index.js',
    'elements/index.js',
    'plugins/index.js',
  ].map(load));
  umd.default.register(...namespaces.map((namespace) => ({...namespace})));
  return {
    Chart: umd.default,
    defaults: core.default,
    overrides: core.overrides,
    descriptors: core.descriptors,
  };
}
