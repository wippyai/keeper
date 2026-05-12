import type { Router, RouteRecordRaw } from 'vue-router'
import { createMemoryHistory, createRouter } from 'vue-router'
import type { HostApi, ProxyApiInstance } from '../types'

const routes: RouteRecordRaw[] = [
  { path: '/', name: 'git', component: () => import('../pages/git.vue') },
  { path: '/:pathMatch(.*)*', name: 'not-found', redirect: '/' },
]

export function createAppRouter(host: HostApi, instance: ProxyApiInstance | null, initialPath: string = '/'): Router {
  const history = createMemoryHistory()
  if (initialPath && initialPath !== '/') history.replace(initialPath)
  const router = createRouter({ history, routes })

  router.afterEach((to) => {
    host.onRouteChanged(to.fullPath)
  })

  if (instance) {
    instance.on('@history', (raw: unknown) => {
      const evt = raw as { path?: string }
      const path = evt?.path
      if (!path) return
      const normalized = path.startsWith('/') ? path : '/' + path
      if (router.currentRoute.value.fullPath !== normalized) {
        router.push(normalized).catch(() => {})
      }
    })
  }
  return router
}
