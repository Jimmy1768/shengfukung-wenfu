const AVAILABLE_LOCALES = [
  {
    code: 'en-US',
    name: 'English (US)',
    localeKey: 'en'
  },
  {
    code: 'zh-TW',
    name: '中文（台灣）',
    localeKey: 'zh-TW'
  },
  {
    code: 'ja-JP',
    name: '日本語',
    localeKey: 'ja'
  }
];

const DEFAULT_LOCALE_KEY = 'zh-TW';

module.exports = {
  locales: AVAILABLE_LOCALES,
  defaultLocaleKey: DEFAULT_LOCALE_KEY
};

module.exports.locales = AVAILABLE_LOCALES;
module.exports.defaultLocaleKey = DEFAULT_LOCALE_KEY;
