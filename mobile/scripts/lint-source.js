const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..', 'app');
const forbidden = /\bfetch\b|Stripe|ECPay|checkout|golden-template|\badmin\b/i;
const files = [];
const walk = dir => fs.readdirSync(dir, { withFileTypes: true }).forEach(entry => {
  const target = path.join(dir, entry.name);
  if (entry.isDirectory()) walk(target);
  else if (entry.name.endsWith('.js')) files.push(target);
});
const allowedTransport = path.join(root, 'client', 'transport.js');
const oauthPaths = [path.join(root, 'oauth'), path.join(root, 'client', 'adapter.js'), path.join(root, 'client', 'storage.js'), path.join(root, 'client', 'config.js'), path.join(root, 'client', 'response.js'), path.join(root, 'ui', 'copy.js')];
const sourceFailures = entries => entries.filter(({ file, source }) => {
  // The real adapter's local/test transport is the only permitted fetch seam.
  const checked = file === allowedTransport ? source.replace('globalThis.fetch', '') : source;
  if (forbidden.test(checked)) return true;
  return /OAuth/i.test(checked) && !oauthPaths.some(allowed => file === allowed || file.startsWith(`${allowed}${path.sep}`));
});
const liveOriginFailures = entries => entries.filter(({ file, source }) => {
  const relative = path.relative(root, file);
  if (relative === path.join('client', 'config.js')) return false;
  return /https?:\/\//i.test(source);
});
if (require.main === module) {
  walk(root);
  const entries = files.map(file => ({ file, source: fs.readFileSync(file, 'utf8') }));
  const failures = sourceFailures(entries).concat(liveOriginFailures(entries));
  if (failures.length) {
    console.error(`forbidden client residue in: ${failures.map(({ file }) => path.relative(root, file)).join(', ')}`);
    process.exit(1);
  }
  console.log(`source lint passed for ${files.length} mobile app modules.`);
}
module.exports = { sourceFailures, liveOriginFailures, allowedTransport };
