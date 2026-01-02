#!/usr/bin/env node
import { createRequire } from 'module';
import path from 'path';
import process from 'process';

const require = createRequire(import.meta.url);
const { loadProjectConfig } = require('../../shared/app_constants/projectConfig.js');

const config = loadProjectConfig(process.env);

const rows = [
  ['Name', config.name],
  ['Slug', config.slug],
  ['Marketing root', config.marketingRoot],
  ['Systemd env dir', config.systemdEnvDir],
  ['Systemd env file', config.systemdEnvFile],
  ['Puma service', config.pumaServiceName],
  ['Sidekiq service', config.sidekiqServiceName],
  ['Nginx config', config.nginxConfigFilename],
  ['Scheme', config.scheme],
  ['Bundle prefix', config.bundlePrefix]
];

const labelWidth = Math.max(...rows.map(([label]) => label.length));

console.log('Resolved project configuration\n');
rows.forEach(([label, value]) => {
  const padded = label.padEnd(labelWidth, ' ');
  console.log(`${padded} : ${value}`);
});

const overrides = Object.keys(process.env).filter((key) => key.startsWith('PROJECT_'));
if (overrides.length) {
  console.log('\nEnvironment overrides detected:');
  overrides.forEach((key) => {
    console.log(`  ${key}=${process.env[key]}`);
  });
} else {
  console.log('\nNo PROJECT_* overrides detected.');
}
