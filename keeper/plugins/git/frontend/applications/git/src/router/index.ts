import { createAppRouter as createAppRouterFactory } from '@wippy-fe/router'
import type { Router, RouteRecordRaw } from 'vue-router'
import type { HostApi, ProxyApiInstance } from '../types'

const routes: RouteRecordRaw[] = [
  { path: '/', name: 'git', component: () => import('../pages/git.vue') },
  { path: '/:pathMatch(.*)*', name: 'not-found', redirect: '/' },
]

export function createAppRouter(host: HostApi, instance: ProxyApiInstance | null, initialPath: string = '/'): Router {
  // Canonical @wippy-fe/router factory: memory history + initial-path replace
  // + `host.onRouteChanged` afterEach + `@history` listener with built-in
  // navId echo-loop suppression + setLocalRouter for the link classifier.
  return createAppRouterFactory(routes, {
    initialPath: initialPath && initialPath !== '/' ? initialPath : undefined,
    host,
    on: instance
      ? (instance.on as Parameters<typeof createAppRouterFactory>[1] extends { on?: infer T } ? T : never)
      : null,
  })
}
