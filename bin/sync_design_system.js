#!/usr/bin/env node
/**
 * Generates runtime-friendly theme artifacts for Vue, Rails, and Expo,
 * then syncs favicons into each surface.
 *
 * Usage:
 *   node bin/sync_design_system.js
 */

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

const ROOT = path.resolve(__dirname, '..');
const CONFIG_PATH = path.join(ROOT, 'shared', 'design-system', 'themes.json');

if (!fs.existsSync(CONFIG_PATH)) {
  console.error(`Theme config not found at ${CONFIG_PATH}`);
  process.exit(1);
}

const config = JSON.parse(fs.readFileSync(CONFIG_PATH, 'utf8'));
const { defaultTheme, themes } = config;

if (!defaultTheme || !themes[defaultTheme]) {
  console.error(
    `defaultTheme "${defaultTheme}" is missing or not defined inside shared/design-system/themes.json`
  );
  process.exit(1);
}

const ensureDir = (targetPath) => {
  fs.mkdirSync(path.dirname(targetPath), { recursive: true });
};

const toCssVar = (tokenKey) =>
  `--${tokenKey
    .replace(/([a-z])([A-Z])/g, '$1-$2')
    .replace(/_/g, '-')
    .toLowerCase()}`;

const renderThemeCss = (id, themeConfig) => {
  const selectors = [`:root[data-theme="${id}"]`, `[data-theme="${id}"]`];
  if (id === defaultTheme) {
    selectors.unshift(':root');
  }

  const lines = [
    `  color-scheme: ${themeConfig.mode === 'dark' ? 'dark' : 'light'};`,
    `  ${toCssVar('themeId')}: "${id}";`,
    ...Object.entries(themeConfig.tokens).map(
      ([key, value]) => `  ${toCssVar(key)}: ${value};`
    )
  ];

  return `${selectors.join(', ')} {\n${lines.join('\n')}\n}\n`;
};

const cssHeader =
  '/* Auto-generated via bin/sync_design_system.js. Do not edit directly. */\n\n';

const cssBody = Object.entries(themes)
  .map(([id, themeConfig]) => renderThemeCss(id, themeConfig))
  .join('\n');

const cssTargets = [
  path.join(ROOT, 'vue', 'src', 'styles', 'tokens.css'),
  path.join(ROOT, 'rails', 'app', 'stylesheets', 'shared', '_tokens.scss'),
  path.join(ROOT, 'rails', 'showcase_ui', 'styles', '_tokens.scss'),
  path.join(ROOT, 'rails', 'public', 'assets', 'theme-tokens.css')
];

cssTargets.forEach((target) => {
  ensureDir(target);
  fs.writeFileSync(target, `${cssHeader}${cssBody}`, 'utf8');
  console.log(`Wrote ${path.relative(ROOT, target)}`);
});

const jsHeader = `/**
 * Auto-generated via bin/sync_design_system.js
 * Reflects shared/design-system/themes.json
 */
`;

const jsExports = `${jsHeader}
export const defaultThemeId = '${defaultTheme}';

export const themes = ${JSON.stringify(
  Object.entries(themes).reduce((acc, [id, theme]) => {
    acc[id] = { id, ...theme };
    return acc;
  }, {}),
  null,
  2
)};

export const themeList = Object.values(themes);

export function getTheme(themeId = defaultThemeId) {
  return themes[themeId] ?? themes[defaultThemeId];
}
`;

const jsTargets = [
  path.join(ROOT, 'vue', 'src', 'theme', 'themes.js'),
  path.join(ROOT, 'mobile', 'theme', 'tokens.js')
];

jsTargets.forEach((target) => {
  ensureDir(target);
  fs.writeFileSync(target, jsExports, 'utf8');
  console.log(`Wrote ${path.relative(ROOT, target)}`);
});

const faviconScript = path.join(ROOT, 'ops', 'scripts', 'sync-favicons.mjs');
if (fs.existsSync(faviconScript)) {
  console.log('Syncing favicons across surfaces…');
  const result = spawnSync('node', [faviconScript], { stdio: 'inherit' });
  if (result.status !== 0) {
    console.error('Sync favicons script failed. See logs above.');
    process.exit(result.status || 1);
  }
} else {
  console.warn(`Skipping favicon sync. Script missing at ${faviconScript}`);
}

const appIconScript = path.join(ROOT, 'ops', 'scripts', 'generate-app-icon.mjs');
if (fs.existsSync(appIconScript)) {
  console.log('Updating Expo icons from favicon pack…');
  const result = spawnSync('node', [appIconScript], { stdio: 'inherit' });
  if (result.status !== 0) {
    console.error('Expo icon generation failed. See logs above.');
    process.exit(result.status || 1);
  }
} else {
  console.warn(`Skipping Expo icon generation. Script missing at ${appIconScript}`);
}
