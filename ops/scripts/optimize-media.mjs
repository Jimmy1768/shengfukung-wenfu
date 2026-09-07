#!/usr/bin/env node
// ops/scripts/optimize-media.mjs
//
// Converts demo/showcase photography under vue/src/assets/media from PNG to
// WebP. These are photographs, not UI chrome, so PNG buys nothing but bytes:
// every client clone deploys the full media set, and the template ships it in
// git forever.
//
// Icons, favicons and splash assets are deliberately NOT touched -- those need
// PNG/ICO for platform reasons and live under shared/design-system + mobile/assets.
//
// Usage:
//   node ops/scripts/optimize-media.mjs [--dry-run] [--keep] [--quality N]

import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const sharp = require('sharp');

const ROOT = path.resolve(path.dirname(new URL(import.meta.url).pathname), '..', '..');
const MEDIA_DIR = path.join(ROOT, 'vue', 'src', 'assets', 'media');

const args = process.argv.slice(2);
const dryRun = args.includes('--dry-run');
const keepOriginals = args.includes('--keep');
const qualityArg = args.indexOf('--quality');
const QUALITY = qualityArg !== -1 ? Number(args[qualityArg + 1]) : 82;

const walk = dir =>
  fs.readdirSync(dir, { withFileTypes: true }).flatMap(entry => {
    const full = path.join(dir, entry.name);
    return entry.isDirectory() ? walk(full) : [full];
  });

const mb = bytes => (bytes / 1024 / 1024).toFixed(1);

if (!fs.existsSync(MEDIA_DIR)) {
  console.log(`No media directory at ${MEDIA_DIR} -- nothing to optimize.`);
  process.exit(0);
}

const pngs = walk(MEDIA_DIR).filter(f => f.toLowerCase().endsWith('.png'));

if (pngs.length === 0) {
  console.log('No PNGs left to convert.');
  process.exit(0);
}

console.log(
  `${dryRun ? '[dry run] ' : ''}Converting ${pngs.length} PNG(s) to WebP q${QUALITY}` +
    `${keepOriginals ? ' (keeping originals)' : ''}\n`
);

let before = 0;
let after = 0;
let failed = 0;

for (const src of pngs) {
  const dest = src.replace(/\.png$/i, '.webp');
  const rel = path.relative(ROOT, src);
  const srcSize = fs.statSync(src).size;
  before += srcSize;

  if (dryRun) {
    after += srcSize;
    console.log(`  would convert  ${rel}`);
    continue;
  }

  try {
    await sharp(src).webp({ quality: QUALITY }).toFile(dest);
    const destSize = fs.statSync(dest).size;
    after += destSize;

    if (!keepOriginals) {
      fs.unlinkSync(src);
    }

    const saved = Math.round((1 - destSize / srcSize) * 100);
    console.log(`  ${String(saved).padStart(3)}%  ${mb(srcSize)}MB -> ${mb(destSize)}MB  ${rel}`);
  } catch (error) {
    failed += 1;
    after += srcSize;
    console.error(`  FAILED ${rel}: ${error.message}`);
  }
}

console.log(
  `\nTotal: ${mb(before)}MB -> ${mb(after)}MB ` +
    `(${Math.round((1 - after / before) * 100)}% smaller)` +
    `${failed ? `, ${failed} failed` : ''}`
);

if (failed) process.exit(1);
