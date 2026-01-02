#!/usr/bin/env node
import { mkdir, readdir } from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';
import sharp from 'sharp';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, '..', '..');

const searchRoots = [path.join(repoRoot, 'shared', 'design-system', 'assets', 'favicons')];
const splashRoot = path.join(repoRoot, 'shared', 'design-system', 'assets', 'splash');

const ensureDir = (targetPath) => mkdir(path.dirname(targetPath), { recursive: true });

async function findPngs(dir) {
  const files = [];
  try {
    const entries = await readdir(dir, { withFileTypes: true });
    for (const entry of entries) {
      const resolved = path.join(dir, entry.name);
      if (entry.isDirectory()) {
        files.push(...(await findPngs(resolved)));
        continue;
      }
      if (entry.isFile() && entry.name.toLowerCase().endsWith('.png')) {
        files.push(resolved);
      }
    }
  } catch (error) {
    // ignore missing directories
  }
  return files;
}

async function findSource() {
  let candidates = [];
  for (const root of searchRoots) {
    candidates = candidates.concat(await findPngs(root));
  }

  if (candidates.length === 0) {
    throw new Error(
      'Unable to locate any PNG assets in the favicon pack. Make sure favicons have been synced.'
    );
  }

  const scored = [];
  for (const file of candidates) {
    try {
      const metadata = await sharp(file).metadata();
      const width = metadata.width ?? 0;
      const height = metadata.height ?? 0;
      const score = Math.min(width, height);
      scored.push({ file, score });
    } catch (error) {
      console.warn(`[generate:app-icon] Skipping unreadable file ${file}: ${error.message}`);
    }
  }

  if (scored.length === 0) {
    throw new Error('Unable to read any PNG metadata from the favicon pack.');
  }

  scored.sort((a, b) => b.score - a.score);

  const preferredNames = ['favicon-96x96.png'];
  let preferred =
    preferredNames
      .map((name) => scored.find((candidate) => path.basename(candidate.file) === name))
      .find(Boolean) ?? null;

  if (!preferred) {
    preferred = scored.find((candidate) => candidate.score >= 512) ?? scored[0];
  }

  if (!preferred || preferred.score === 0) {
    throw new Error('No suitable PNG found to generate Expo icons.');
  }

  return preferred;
}

async function writePng(source, size, target) {
  await ensureDir(target);
  await sharp(source)
    .resize(size, size, { fit: 'cover', withoutEnlargement: false })
    .png()
    .toFile(target);
  console.log(`  • ${path.relative(repoRoot, target)} (${size}x${size})`);
}

const ANDROID_ADAPTIVE_SAFE_RATIO = 2 / 3; // Android launcher safe zone (72/108dp)
const FALLBACK_ADAPTIVE_BACKGROUND = { r: 255, g: 255, b: 255, alpha: 1 };
const DEV_BADGE_LABEL = 'DEV';
const DEV_BADGE_FILL = '#ffffff';
const DEV_BADGE_OPACITY = 0.95;
const DEV_BADGE_WIDTH_RATIO = 0.6;
const DEV_BADGE_HEIGHT_RATIO = 0.18;
const DEV_BADGE_BOTTOM_MARGIN_RATIO = 0.08;

const clampChannel = (value) => Math.max(0, Math.min(255, Math.round(value ?? 0)));
const toHex = (value) => clampChannel(value).toString(16).padStart(2, '0');
const formatColor = ({ r, g, b }) => `#${toHex(r)}${toHex(g)}${toHex(b)}`;

async function detectBackgroundColor(source) {
  try {
    const { width = 0, height = 0 } = await sharp(source).metadata();
    if (!width || !height) {
      return null;
    }

    const samplePoints = [
      { left: 0, top: 0 },
      { left: Math.max(width - 1, 0), top: 0 },
      { left: 0, top: Math.max(height - 1, 0) },
      { left: Math.max(width - 1, 0), top: Math.max(height - 1, 0) }
    ];

    for (const point of samplePoints) {
      const buffer = await sharp(source)
        .extract({ ...point, width: 1, height: 1 })
        .ensureAlpha()
        .raw()
        .toBuffer();
      const [r, g, b, a] = buffer;
      if (a >= 250) {
        return { r, g, b, alpha: 1 };
      }
    }
  } catch (error) {
    console.warn(`[generate:app-icon] Unable to detect favicon background color: ${error.message}`);
  }
  return null;
}

async function buildDevBadgeOverlay(size, textColor) {
  const badgeWidth = Math.max(1, Math.round(size * DEV_BADGE_WIDTH_RATIO));
  const badgeHeight = Math.max(1, Math.round(size * DEV_BADGE_HEIGHT_RATIO));
  const badgeBottomMargin = Math.round(size * DEV_BADGE_BOTTOM_MARGIN_RATIO);
  const badgeLeft = Math.round((size - badgeWidth) / 2);
  const badgeTop = Math.max(0, size - badgeHeight - badgeBottomMargin);
  const badgeRadius = Math.round(badgeHeight / 2);
  const fontSize = Math.max(10, Math.round(badgeHeight * 0.58));

  const svg = `
    <svg width="${badgeWidth}" height="${badgeHeight}" viewBox="0 0 ${badgeWidth} ${badgeHeight}" xmlns="http://www.w3.org/2000/svg">
      <rect width="100%" height="100%" rx="${badgeRadius}" fill="${DEV_BADGE_FILL}" fill-opacity="${DEV_BADGE_OPACITY}"/>
      <text x="50%" y="52%" text-anchor="middle" dominant-baseline="middle" font-family="'Inter','SF Pro Display','Segoe UI','Helvetica','Arial',sans-serif" font-weight="700" font-size="${fontSize}" fill="${textColor}">
        ${DEV_BADGE_LABEL}
      </text>
    </svg>
  `;

  const badgeBuffer = Buffer.from(svg);
  const pngBuffer = await sharp(badgeBuffer).png().toBuffer();

  return { input: pngBuffer, left: badgeLeft, top: badgeTop };
}

async function writeAdaptiveIcon(
  source,
  size,
  target,
  safeRatio = ANDROID_ADAPTIVE_SAFE_RATIO,
  backgroundColor = FALLBACK_ADAPTIVE_BACKGROUND,
  badgeOptions = null
) {
  await ensureDir(target);
  const innerSize = Math.floor(size * safeRatio);
  const inset = Math.floor((size - innerSize) / 2);

  const foreground = await sharp(source)
    .resize(innerSize, innerSize, {
      fit: 'contain',
      background: { r: 0, g: 0, b: 0, alpha: 0 },
      withoutEnlargement: false
    })
    .png()
    .toBuffer();

  const base = sharp({
    create: {
      width: size,
      height: size,
      channels: 4,
      background: {
        r: clampChannel(backgroundColor.r),
        g: clampChannel(backgroundColor.g),
        b: clampChannel(backgroundColor.b),
        alpha: 1
      }
    }
  });

  const overlays = [{ input: foreground, left: inset, top: inset }];

  if (badgeOptions?.enabled) {
    const badge = await buildDevBadgeOverlay(size, badgeOptions.textColor);
    overlays.push(badge);
  }

  await base
    .composite(overlays)
    .png()
    .toFile(target);

  console.log(
    `  • ${path.relative(repoRoot, target)} (${size}x${size}, inset ~${Math.round(
      safeRatio * 100
    )}% of canvas, bg ${formatColor(backgroundColor)}${badgeOptions?.enabled ? ', DEV badge' : ''})`
  );
}

async function writeDevIcon(source, size, target, textColor) {
  await ensureDir(target);
  const base = await sharp(source)
    .resize(size, size, { fit: 'cover', withoutEnlargement: false })
    .png()
    .toBuffer();

  const badge = await buildDevBadgeOverlay(size, textColor);

  await sharp(base)
    .composite([badge])
    .png()
    .toFile(target);

  console.log(
    `  • ${path.relative(repoRoot, target)} (${size}x${size}, DEV badge overlay)`
  );
}

async function findSplashSource() {
  try {
    const entries = await readdir(splashRoot, { withFileTypes: true });
    const files = entries.filter((entry) => entry.isFile());
    if (files.length === 0) {
      throw new Error(`No splash asset found in ${path.relative(repoRoot, splashRoot)}`);
    }
    const preferred = ['splash.png', 'splash.jpg', 'splash.jpeg', 'splash.webp'];
    for (const candidate of preferred) {
      const match = files.find((entry) => entry.name.toLowerCase() === candidate);
      if (match) {
        return path.join(splashRoot, match.name);
      }
    }
    return path.join(splashRoot, files[0].name);
  } catch (error) {
    throw new Error(`Unable to read splash assets: ${error.message}`);
  }
}

async function writeSplashAssets(source) {
  console.log(
    `Updating splash assets from ${path.relative(repoRoot, source)}`
  );

  const mobileSplashTarget = path.join(repoRoot, 'mobile', 'assets', 'splash-icon.png');
  await ensureDir(mobileSplashTarget);
  await sharp(source).png().toFile(mobileSplashTarget);
  console.log(`  • ${path.relative(repoRoot, mobileSplashTarget)} (Expo splash)`);

  const vuePublicDir = path.join(repoRoot, 'vue', 'public');
  const vueJpg = path.join(vuePublicDir, 'splash-loading.jpg');
  const vueWebp = path.join(vuePublicDir, 'splash-loading.webp');

  await ensureDir(vueJpg);
  const resized = sharp(source).resize(1600, null, {
    fit: 'inside',
    withoutEnlargement: true
  });
  await resized.clone().jpeg({ quality: 70, progressive: true }).toFile(vueJpg);
  console.log(`  • ${path.relative(repoRoot, vueJpg)} (Vue splash jpg)`);
  await resized.clone().webp({ quality: 70 }).toFile(vueWebp);
  console.log(`  • ${path.relative(repoRoot, vueWebp)} (Vue splash webp)`);
}

async function main() {
  const { file: source, score } = await findSource();
  console.log(
    `Generating Expo icons from ${path.relative(repoRoot, source)} (detected size ~${score}px)…`
  );

  const detectedBackground = (await detectBackgroundColor(source)) ?? FALLBACK_ADAPTIVE_BACKGROUND;
  await writePng(source, 1024, path.join(repoRoot, 'mobile', 'assets', 'icon.png'));
  await writeAdaptiveIcon(
    source,
    1024,
    path.join(repoRoot, 'mobile', 'assets', 'adaptive-icon.png'),
    ANDROID_ADAPTIVE_SAFE_RATIO,
    detectedBackground
  );
  await writeDevIcon(
    source,
    1024,
    path.join(repoRoot, 'mobile', 'assets', 'dev-icon.png'),
    formatColor(detectedBackground)
  );
  await writeAdaptiveIcon(
    source,
    1024,
    path.join(repoRoot, 'mobile', 'assets', 'dev-adaptive-icon.png'),
    ANDROID_ADAPTIVE_SAFE_RATIO,
    detectedBackground,
    { enabled: true, textColor: formatColor(detectedBackground) }
  );
  await writePng(source, 96, path.join(repoRoot, 'mobile', 'assets', 'favicon.png'));

  try {
    const splashSource = await findSplashSource();
    await writeSplashAssets(splashSource);
  } catch (error) {
    console.warn(`[generate:app-icon] ${error.message}`);
  }

  console.log('✅ Expo icon & splash assets updated from shared packs.');
}

main().catch((error) => {
  console.error('[generate:app-icon] Failed to update Expo icons');
  console.error(error.message || error);
  process.exitCode = 1;
});
