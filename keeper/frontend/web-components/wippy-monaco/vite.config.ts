import { resolve } from 'node:path'
import vue from '@vitejs/plugin-vue'
import { defineConfig } from 'vite'

export default defineConfig({
  plugins: [vue()],
  build: {
    target: 'esnext',
    lib: {
      entry: resolve(__dirname, 'src/index.ts'),
      name: 'WippyMonaco',
      fileName: 'index',
      formats: ['es'],
    },
    rollupOptions: {
      input: {
        index: resolve(__dirname, 'src/index.ts'),
      },
      external: [
        'vue',
        '@wippy-fe/proxy',
      ],
      output: {
        entryFileNames: '[name].js',
        chunkFileNames: '[name]-[hash].js',
        assetFileNames: '[name]-[hash][extname]',
      },
      // The entry's `define(import.meta.url, ...)` reads `?declare-tag=` off
      // the entry URL the autoload script appends. Letting Rollup emit a
      // facade that re-exports from a sub-chunk would move that statement
      // into the sub-chunk and break custom-element registration. Same as
      // the mermaid WC.
      preserveEntrySignatures: false,
    },
    sourcemap: true,
  },
})
