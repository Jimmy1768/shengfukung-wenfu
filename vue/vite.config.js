import { defineConfig } from 'vite';
import vue from '@vitejs/plugin-vue';
import path from 'node:path';

const devApiProxy = process.env.VITE_DEV_API_PROXY || 'http://localhost:3001';
const frontendAssetsDir =
  process.env.VITE_FRONTEND_ASSETS_DIR ||
  process.env.VITE_MARKETING_ASSETS_DIR ||
  'frontend/assets';

export default defineConfig({
  plugins: [vue()],
  base: '/',
  resolve: {
    alias: {
      '@': path.resolve(__dirname, 'src'),
      '@shared': path.resolve(__dirname, '..', 'shared')
    }
  },
  build: {
    outDir: 'dist',
    assetsDir: frontendAssetsDir,
    rollupOptions: {
      input: path.resolve(__dirname, 'index.html')
    }
  },
  server: {
    proxy: {
      '/api': {
        target: devApiProxy,
        changeOrigin: true
      }
    }
  }
});
