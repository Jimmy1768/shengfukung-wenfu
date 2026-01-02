const devMarketingOrigin = "http://localhost:5173/marketing";
const devAdminOrigin = "http://localhost:3001/marketing/admin";

const prodMarketingFallback = "/marketing";
const prodAdminFallback = "/marketing/admin";

const resolveOrigin = (envValue, devDefault, prodDefault) => {
  if (envValue && envValue.trim().length) {
    return envValue.trim().replace(/\/+$/, "");
  }
  if (import.meta.env.DEV) {
    return devDefault.replace(/\/+$/, "");
  }
  return prodDefault.replace(/\/+$/, "");
};

const marketingOrigin = resolveOrigin(
  import.meta.env.VITE_MARKETING_ORIGIN,
  devMarketingOrigin,
  prodMarketingFallback
);

const adminOrigin = resolveOrigin(
  import.meta.env.VITE_MARKETING_ADMIN_ORIGIN,
  devAdminOrigin,
  prodAdminFallback
);

const buildUrl = (origin, path = "/", ensureTrailingSlash = false) => {
  const base = origin.replace(/\/+$/, "");
  if (!path || path === "/") {
    return ensureTrailingSlash ? `${base}/` : base;
  }
  if (path.startsWith("?") || path.startsWith("#")) {
    return `${base}${path}`;
  }
  return `${base}/${path.replace(/^\/+/, "")}`;
};

export const marketingUrl = (path = "/") => buildUrl(marketingOrigin, path, true);
export const adminUrl = (path = "/") => buildUrl(adminOrigin, path);
