import { createApp } from 'vue'
import { PrimeVuePlugin } from '@wippy-fe/theme/primevue-plugin'
import wippy from '@wippy-fe/proxy'

import App from './app/App.vue'
import { AXIOS_INSTANCE, HOST_API, WIPPY_INSTANCE, WIPPY_CONFIG } from './constants'
import { createAppRouter } from './router'
import './styles.css'
import './tailwind.css'

export async function createGitApp() {
  const config = wippy.config
  const hostApi = wippy.host
  const axios = wippy.api
  const instance = wippy

  // 401 → auth-expired. See keeper-main src/app.ts for rationale.
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

  const initialPath: string = config.context?.route || '/'

  const app = createApp(App)
  app.use(PrimeVuePlugin)
  app.provide(HOST_API, hostApi)
  app.provide(AXIOS_INSTANCE, axios)
  app.provide(WIPPY_INSTANCE, instance)
  app.provide(WIPPY_CONFIG, config)

  app.use(createAppRouter(hostApi, instance, initialPath))
  return app
}

export async function mountApp(elementId: string = '#app') {
  const app = await createGitApp()
  app.mount(elementId)
  return app
}

mountApp()
