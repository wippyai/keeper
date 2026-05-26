import { resolve } from 'node:path'
import vue from '@vitejs/plugin-vue'
import { wippyPagePlugin } from '@wippy-fe/vite-plugin'
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
          isCustomElement: (tag) => tag.startsWith('keeper-') || tag.startsWith('wc-') || tag.startsWith('wippy-') || tag === 'w-artifact' || tag === 'w-iframe',
        },
      },
    }),
    wippyPagePlugin(),
    inlineCssPlugin(),
  ],
  base: '',
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
        // NOTE: @wippy-fe/router is intentionally NOT external — the host's
        // importmap doesn't ship a mapping for it (only @wippy-fe/proxy +
        // standard libs). Externalizing it makes the bundle throw
        // `Failed to resolve module specifier "@wippy-fe/router"` at runtime.
        // The factory is small (~3 kB) so inlining is acceptable.
      ],
      output: {
        entryFileNames: '[name].js',
        assetFileNames: '[name]-[hash][extname]',
      },
    },
  },
})
