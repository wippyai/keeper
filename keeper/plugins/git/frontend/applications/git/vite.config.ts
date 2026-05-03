import { resolve } from 'node:path'
import vue from '@vitejs/plugin-vue'
import { defineConfig, type Plugin } from 'vite'

function inlineCssPlugin(): Plugin {
  return {
    name: 'inline-css-to-html',
    enforce: 'post',
    generateBundle(_, bundle) {
      let cssCode = ''
      const cssFiles: string[] = []
      for (const [name, chunk] of Object.entries(bundle)) {
        if (name.endsWith('.css') && chunk.type === 'asset') {
          cssCode += chunk.source
          cssFiles.push(name)
        }
      }
      if (!cssCode) return
      for (const name of cssFiles) {
        delete bundle[name]
      }
      for (const [name, chunk] of Object.entries(bundle)) {
        if (name.endsWith('.html') && chunk.type === 'asset') {
          const html = typeof chunk.source === 'string' ? chunk.source : ''
          chunk.source = html
            .replace(/<link[^>]*rel="stylesheet"[^>]*>/g, '')
            .replace('</head>', `<style>${cssCode}</style>\n</head>`)
        }
      }
    },
  }
}

export default defineConfig({
  plugins: [vue(), inlineCssPlugin()],
  base: '/app/keeper-git/',
  define: { 'process.env.NODE_ENV': JSON.stringify('production') },
  resolve: {
    alias: {
      '@': resolve(__dirname, './src'),
    },
  },
  build: {
    target: 'esnext',
    cssCodeSplit: false,
    cssMinify: true,
    sourcemap: true,
    assetsInlineLimit: 1000000,
    rollupOptions: {
      input: { app: resolve(__dirname, 'app.html') },
      external: [
        'vue',
        'vue-router',
        '@iconify/vue',
        '@wippy-fe/proxy',
        'axios',
      ],
      output: {
        entryFileNames: '[name].js',
        assetFileNames: '[name]-[hash][extname]',
      },
    },
  },
})
