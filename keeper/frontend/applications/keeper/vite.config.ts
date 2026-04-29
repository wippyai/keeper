import { resolve } from 'node:path'
import vue from '@vitejs/plugin-vue'
import { defineConfig, type Plugin } from 'vite'

const withSourceMaps = process.env.KEEPER_SOURCEMAP === 'true'

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
  plugins: [
    vue({
      template: {
        compilerOptions: {
          isCustomElement: (tag) => tag.startsWith('keeper-') || tag.startsWith('wc-'),
        },
      },
    }),
    inlineCssPlugin(),
  ],
  base: '/app/keeper/',
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
    sourcemap: withSourceMaps,
    assetsInlineLimit: 1000000,
    rollupOptions: {
      input: { app: resolve(__dirname, 'app.html') },
      external: [
        'vue',
        'pinia',
        'vue-router',
        '@iconify/vue',
        'nanoevents',
        'luxon',
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
