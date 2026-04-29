import { addCollection } from '@iconify/vue'
import { createPinia } from 'pinia'
import { createApp } from 'vue'

import App from './app/app.vue'
import { AXIOS_INSTANCE, HOST_API, WIPPY_INSTANCE, WIPPY_CONFIG, ON_SUBSCRIPTION } from './constants'
import type { OnSubscription } from './constants'
import { createAppRouter } from './router'
import '@wippy-fe/theme/theme-config.css'
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

  let on: OnSubscription | null = null
  try { on = await window.$W.on() } catch {}

  // Resolve the initial route in priority order so reloads land on the
  // page the user was on, not the dashboard.
  //
  //  1. config.context.route — the host's hint, when present
  //  2. parent window URL — wippy iframes are same-origin, we can read
  //     the outer /c/<entry>/<inner> path off it
  //  3. localStorage — last route the SPA persisted via afterEach
  //  4. /
  const KEEPER_LAST_ROUTE = '@keeper/last-route'
  let resolvedRoute: string | undefined = (config as any).context?.route || config.path

  let parentSearch = ''
  try { parentSearch = window.parent.location.search || '' } catch {}

  if (!resolvedRoute || resolvedRoute === '/') {
    try {
      const parentPath = window.parent.location.pathname
      const m = parentPath.match(/^\/c\/[^/]+\/(.*)$/)
      if (m && m[1]) resolvedRoute = '/' + m[1]
    } catch {}
  }
  if (resolvedRoute && !resolvedRoute.includes('?') && parentSearch) {
    resolvedRoute = resolvedRoute + parentSearch
  }
  if (!resolvedRoute || resolvedRoute === '/') {
    try {
      const stored = localStorage.getItem(KEEPER_LAST_ROUTE)
      if (stored) resolvedRoute = stored
    } catch {}
  }
  const initialPath = resolvedRoute
    ? (resolvedRoute.startsWith('/') ? resolvedRoute : '/' + resolvedRoute)
    : '/'

  if (config.customization?.icons) {
    addCollection({
      prefix: 'custom',
      icons: config.customization?.icons,
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
