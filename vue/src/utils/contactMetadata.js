const getLocalTimestamp = () => {
  try {
    return new Date().toLocaleString();
  } catch {
    return null;
  }
};

const getTimezone = () => {
  try {
    return Intl.DateTimeFormat().resolvedOptions().timeZone;
  } catch {
    return null;
  }
};

const normalizeValue = (value) => {
  if (value === undefined || value === null || value === '') {
    return null;
  }
  return value;
};

export const collectContactMetadata = ({
  locale,
  theme,
  brandId,
  templateId
} = {}) => {
  const client = {
    timestamp_local: getLocalTimestamp(),
    timezone: getTimezone(),
    locale: normalizeValue(locale),
    theme: normalizeValue(theme),
    brand_id: normalizeValue(brandId),
    template_id: normalizeValue(templateId)
  };

  const server = {
    remote_ip: null,
    geo_country: null,
    geo_region: null,
    request_id: null,
    referer: null,
    user_agent: null
  };

  return { client, server };
};

const formatLine = (label, value) => `${label}: ${value ?? '—'}`;

export const formatContactMetadata = ({ client } = {}) => {
  if (!client) return '';
  const lines = [
    '---',
    'Client context',
    formatLine('Local time', client.timestamp_local),
    formatLine('Timezone', client.timezone),
    formatLine('Locale', client.locale),
    formatLine('Theme', client.theme),
    formatLine('Brand ID', client.brand_id),
    formatLine('Template ID', client.template_id)
  ];
  return lines.join('\n');
};
