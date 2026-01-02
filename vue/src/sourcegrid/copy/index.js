import parseCopyYaml from './loader';
import enRaw from './en.yml?raw';
import zhTWRaw from './zh-TW.yml?raw';
import jaJPRaw from './ja-JP.yml?raw';
import koKRRaw from './ko-KR.yml?raw';

const brandCopyCatalog = {
  'en-US': parseCopyYaml(enRaw),
  'zh-TW': parseCopyYaml(zhTWRaw),
  'ja-JP': parseCopyYaml(jaJPRaw),
  'ko-KR': parseCopyYaml(koKRRaw)
};

export default brandCopyCatalog;
