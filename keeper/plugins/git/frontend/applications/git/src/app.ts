import { createApp } from 'vue'

import App from './app/App.vue'
import { AXIOS_INSTANCE, HOST_API, WIPPY_INSTANCE, WIPPY_CONFIG } from './constants'
import { createAppRouter } from './router'
import '@wippy-fe/theme/theme-config.css'
import './styles.css'
import './tailwind.css'

function applyThemeOverride() {
  let theme: string | null = null
  try { theme = new URL(window.location.href).searchParams.get('theme') } catch {}
  if (!theme) {
    try { theme = new URL(window.parent.location.href).searchParams.get('theme') } catch {}
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

type GitAppConfig = {
  context?: { route?: string }
  path?: string
}

export async function createGitApp() {
  const config = await window.$W.config()
  const hostApi = await window.$W.host()
  const axios = await window.$W.api()
  const instance = await window.$W.instance()

  const routeConfig = config as GitAppConfig
  const initialPath: string = routeConfig.context?.route || routeConfig.path || '/'

  const app = createApp(App)
  app.provide(HOST_API, hostApi)
  app.provide(AXIOS_INSTANCE, axios)
  app.provide(WIPPY_INSTANCE, instance)
  app.provide(WIPPY_CONFIG, config)

  app.use(createAppRouter(initialPath))
  return app
}

export async function mountApp(elementId: string = '#app') {
  const app = await createGitApp()
  app.mount(elementId)
  return app
}

mountApp()
