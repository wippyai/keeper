import { addCollection } from '@iconify/vue'
import { createPinia } from 'pinia'
import { createApp } from 'vue'

import App from './app/app.vue'
import { AXIOS_INSTANCE, HOST_API, WIPPY_INSTANCE, WIPPY_CONFIG, ON_SUBSCRIPTION } from './constants'
import type { OnSubscription } from './constants'
import { createAppRouter } from './router'
import './styles.css'
import './tailwind.css'

// Honor a `?theme=light|dark` URL parameter (or `KEEPER_THEME` localStorage)
// so QA / users can force a specific theme regardless of OS preference.
// The styles.css applies dark via `[data-theme="dark"]` OR media query when
// `[data-theme="light"]` is NOT set.
function applyThemeOverride() {
  let theme: string | null = null
  // Iframe URL first (where the route + query lives), then parent, then storage.
  try {
    theme = new URL(window.location.href).searchParams.get('theme')
  } catch {}
  if (!theme) {
    try {
      theme = new URL(window.parent.location.href).searchParams.get('theme')
    } catch {}
  }
  if (!theme) {
    try { theme = localStorage.getItem('@keeper/theme') } catch {}
  }
  if (theme === 'light' || theme === 'dark') {
    document.documentElement.setAttribute('data-theme', theme)
    try { localStorage.setItem('@keeper/theme', theme) } catch {}
  }
}
applyThemeOverride()

export async function createKeeperApp() {
  const config = await window.$W.config()
  const hostApi = await window.$W.host()
  const axios = await window.$W.api()
  const instance = await window.$W.instance()

  // 401 → auth-expired. The proxy api swallows non-2xx into rejections
  // without logging the user out. Without this interceptor, an expired
  // session shows stale UI silently. host.handleError('auth-expired', ...)
  // is the canonical signal for the host to clear the token and bounce
  // to /app/login.html.
  axios.interceptors.response.use(
    (response) => response,
    (error: any) => {
      if (error?.response?.status === 401) {
        hostApi.handleError('auth-expired', {
          url: error?.config?.url,
          method: error?.config?.method,
          message: error?.message,
        })
      }
      return Promise.reject(error)
    },
  )

  let on: OnSubscription | null = null
  try { on = await window.$W.on() } catch {}

  // gen-2-chat's loadWebPageByPackageJson passes the URL sub-path (including
  // query string) as config.context.route — verified live across deep links
  // and bare-entry cases. No localStorage / parent-URL fallback needed.
  const initialPath = config.context?.route || '/'

  // 0.0.28 moved iframe-level customization off `config.customization` onto
  // `config.theming.global` (the host's theming snapshot). Read both `icons`
  // and `iconSets.custom` to cover the legacy and current shapes.
  const customIcons = config.theming?.global?.icons
    ?? config.theming?.global?.iconSets?.custom
  if (customIcons) {
    addCollection({
      prefix: 'custom',
      icons: customIcons,
    })
  }

  const app = createApp(App)

  app.use(createPinia())

  app.provide(HOST_API, hostApi)
  app.provide(AXIOS_INSTANCE, axios)
  app.provide(WIPPY_INSTANCE, instance)
  app.provide(WIPPY_CONFIG, config)
  if (on) app.provide(ON_SUBSCRIPTION, on)

  const router = createAppRouter(hostApi, instance.on, initialPath)
  app.use(router)

  return app
}

export async function mountApp(elementId: string = '#app') {
  const app = await createKeeperApp()
  app.mount(elementId)
  return app
}

mountApp()
