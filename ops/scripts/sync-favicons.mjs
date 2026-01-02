#!/usr/bin/env node
import { cp, mkdir, readdir, rm, stat } from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, '..', '..');
const sourceDir = path.join(repoRoot, 'shared', 'design-system', 'assets', 'favicons');

const directTargets = [
  { label: 'Vue (vite) public assets', dir: path.join(repoRoot, 'vue', 'public') },
  { label: 'Rails public assets', dir: path.join(repoRoot, 'rails', 'public') }
];

async function assertSourceExists() {
  try {
    await stat(sourceDir);
  } catch (error) {
    console.error(`[sync:favicons] Missing source package at ${sourceDir}`);
    throw error;
  }
}

async function syncDirectTargets(entries) {
  for (const target of directTargets) {
    await mkdir(target.dir, { recursive: true });
    for (const entry of entries) {
      const from = path.join(sourceDir, entry);
      const to = path.join(target.dir, entry);
      await rm(to, { recursive: true, force: true });
      await cp(from, to, { recursive: true });
    }
    console.log(`✔ Synced ${target.label}`);
  }
}

async function main() {
  await assertSourceExists();
  const entries = (await readdir(sourceDir)).filter((entry) => !entry.startsWith('.'));

  await syncDirectTargets(entries);

  console.log('✨ Favicons synced from Sourcegrid Labs package.');
}

main().catch((error) => {
  console.error('[sync:favicons] Failed to sync favicons');
  console.error(error);
  process.exitCode = 1;
});
