import { define, WippyVueElement } from '@wippy-fe/webcomponent-vue'
import type { WippyElementConfig, WippyPropsSchema } from '@wippy-fe/webcomponent-vue'
import type { ComponentProps } from './types.ts'
import type { Events } from './constants.ts'
import MonacoHost from './app/monaco-host.vue'
import stylesText from './styles.css?inline'
import pkg from '../package.json'

class WippyMonacoElement extends WippyVueElement<ComponentProps, Events> {
  static get wippyConfig(): WippyElementConfig<ComponentProps> {
    return {
      propsSchema: pkg.wippy.props as WippyPropsSchema,
      hostCssKeys: ['themeConfigUrl'] as const,
      inlineCss: stylesText,
    }
  }

  static get vueConfig() {
    return {
      rootComponent: MonacoHost,
    }
  }
}

export async function webComponent() {
  return WippyMonacoElement
}

// `define(import.meta.url, ...)` reads the `?declare-tag=` query the
// host's autoload script appends to the entry URL. The vite config sets
// `preserveEntrySignatures: false` so this statement stays in the entry
// chunk and `import.meta.url` resolves to the URL with the query intact.
define(import.meta.url, WippyMonacoElement)
