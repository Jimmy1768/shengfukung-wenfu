const fs = require("fs");
const path = require("path");

const ROOT_DIR = path.resolve(__dirname, "..", "..");
const CONFIG_PATH = path.join(ROOT_DIR, "shared", "app_constants", "project.json");

function readRawConfig() {
  const file = fs.readFileSync(CONFIG_PATH, "utf8");
  return JSON.parse(file);
}

function loadProjectConfig(env = process.env) {
  const raw = readRawConfig();

  const slug = env.PROJECT_SLUG || raw.slug || "golden-template";
  const name = env.PROJECT_NAME || raw.name || "Golden Template";
  const marketingRoot =
    env.PROJECT_MARKETING_ROOT ||
    raw.marketingRoot ||
    `/var/www/${slug}-vue`;
  const systemdEnvDir =
    env.PROJECT_SYSTEMD_ENV_DIR ||
    raw.systemdEnvDir ||
    "/etc/default";
  const systemdEnvFile =
    env.PROJECT_SYSTEMD_ENV_FILE ||
    path.join(systemdEnvDir, `${slug}-env`);

  const defaultThemeKey =
    env.PROJECT_DEFAULT_THEME_KEY ||
    raw.defaultThemeKey ||
    raw.defaultTheme ||
    "temple-1";

  return {
    ...raw,
    name,
    slug,
    marketingRoot,
    systemdEnvDir,
    systemdEnvFile,
    defaultThemeKey,
    scheme: raw.scheme || slug,
    bundlePrefix: raw.bundlePrefix || `com.${slug.replace(/-/g, "")}`,
    pumaServiceName: `${slug}.service`,
    sidekiqServiceName: `${slug}-sidekiq.service`,
    nginxConfigFilename: `${slug}.conf`
  };
}

const projectConfig = loadProjectConfig();

module.exports = {
  loadProjectConfig,
  projectConfig
};

module.exports.default = loadProjectConfig;
