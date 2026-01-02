import en from './en.json';
import zhTW from './zh-TW.json';
import ja from './ja.json';

export const FALLBACK_LOCALE_KEY = 'en';

const translations = {
  en,
  'zh-TW': zhTW,
  ja
};

export default translations;
