import { addCollection } from '@iconify/vue'
import { createPinia } from 'pinia'
import { createApp } from 'vue'
import { PrimeVuePlugin } from '@wippy-fe/theme/primevue-plugin'
import wippy from '@wippy-fe/proxy'

import App from './app/app.vue'
import { AXIOS_INSTANCE, HOST_API, WIPPY_INSTANCE, WIPPY_CONFIG, ON_SUBSCRIPTION } from './constants'
import type { OnSubscription } from './constants'
import { createAppRouter } from './router'
import './styles.css'
import './tailwind.css'

export async function createKeeperApp() {
  const config = wippy.config
  const hostApi = wippy.host
  const axios = wippy.api
  const instance = wippy

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

  const on = instance.on as unknown as OnSubscription

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
  app.use(PrimeVuePlugin)

  app.provide(HOST_API, hostApi)
  app.provide(AXIOS_INSTANCE, axios)
  app.provide(WIPPY_INSTANCE, instance)
  app.provide(WIPPY_CONFIG, config)
  app.provide(ON_SUBSCRIPTION, on)

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
