import { createAppRouter as createAppRouterFactory } from '@wippy-fe/router'
import type { Router } from 'vue-router'
import type { HostApi } from '../types'

type OnSubscription = (
  pattern: string,
  callback: (event: any) => void,
) => void

const routes = [
  {
    path: '/',
    name: 'dashboard',
    component: () => import('../pages/dashboard.vue'),
  },
  {
    path: '/dataflows',
    name: 'workflow',
    component: () => import('../pages/workflow.vue'),
  },
  {
    path: '/sessions',
    name: 'sessions',
    component: () => import('../pages/sessions.vue'),
  },
  {
    path: '/session/:id',
    name: 'session-detail',
    component: () => import('../pages/session-detail.vue'),
  },
  {
    path: '/agents',
    name: 'agents',
    component: () => import('../pages/agents.vue'),
  },
  {
    path: '/models',
    name: 'models',
    component: () => import('../pages/models.vue'),
  },
  {
    path: '/tools',
    name: 'tools',
    component: () => import('../pages/tools-page.vue'),
  },
  {
    path: '/traits',
    name: 'traits',
    component: () => import('../pages/traits.vue'),
  },
  {
    path: '/endpoints',
    name: 'endpoints',
    component: () => import('../pages/endpoints.vue'),
  },
  {
    path: '/policies',
    name: 'policies',
    component: () => import('../pages/policies.vue'),
  },
  {
    path: '/structure',
    name: 'structure',
    component: () => import('../pages/structure.vue'),
  },
  {
    path: '/dataflow/:id',
    name: 'dataflow-detail',
    component: () => import('../pages/dataflow-detail.vue'),
  },
  {
    path: '/plugin/:id',
    name: 'plugin',
    component: () => import('../pages/plugin-page.vue'),
  },
  {
    path: '/logs',
    name: 'logs',
    component: () => import('../pages/logger.vue'),
  },
  {
    path: '/system',
    name: 'system',
    component: () => import('../pages/system.vue'),
  },
  {
    path: '/tests',
    name: 'tests',
    component: () => import('../pages/tests.vue'),
  },
  {
    path: '/settings',
    name: 'settings',
    component: () => import('../pages/settings.vue'),
  },
  {
    path: '/settings/environment',
    name: 'settings-environment',
    component: () => import('../pages/settings-environment.vue'),
  },
  {
    path: '/settings/registry',
    name: 'settings-registry',
    component: () => import('../pages/settings-registry.vue'),
  },
  {
    path: '/settings/hub',
    name: 'settings-hub',
    component: () => import('../pages/settings-hub.vue'),
  },
  {
    path: '/settings/hub/:org/:name',
    name: 'settings-hub-module',
    component: () => import('../pages/settings-hub-module.vue'),
  },
  {
    path: '/knowledge',
    name: 'knowledge',
    component: () => import('../pages/knowledge.vue'),
  },
  {
    path: '/mcp',
    name: 'mcp',
    component: () => import('../pages/mcp.vue'),
  },
  {
    path: '/components',
    name: 'components',
    component: () => import('../pages/components.vue'),
  },
  {
    path: '/tasks',
    name: 'tasks',
    component: () => import('../pages/tasks.vue'),
  },
  {
    path: '/tasks/:id',
    name: 'task-detail',
    component: () => import('../pages/task-detail.vue'),
  },
  {
    path: '/changes',
    name: 'changes',
    component: () => import('../pages/changes.vue'),
  },
  {
    path: '/changes/:id',
    name: 'changes-detail',
    component: () => import('../pages/changes.vue'),
  },
  {
    path: '/audit',
    name: 'audit',
    component: () => import('../pages/audit.vue'),
  },
  // TEMP D2 — remove in B5 / badge-family cleanup
  {
    path: '/button-gallery',
    name: 'button-gallery',
    component: () => import('../pages/_dev-button-gallery.vue'),
  },
  {
    path: '/badge-gallery',
    name: 'badge-gallery',
    component: () => import('../pages/_dev-badge-gallery.vue'),
  },
  {
    path: '/:pathMatch(.*)*',
    name: 'not-found',
    redirect: '/',
  }
]

export function createAppRouter(host: HostApi, on: OnSubscription | null, initialPath: string): Router {
  // Canonical @wippy-fe/router factory: handles createMemoryHistory +
  // initial-path replace + `host.onRouteChanged` afterEach + `@history`
  // listener with built-in navId echo-loop suppression + setLocalRouter
  // registration for fast-path link classification.
  const router = createAppRouterFactory(routes, {
    initialPath,
    host,
    // Caller passes `instance.on` (same source as the factory's default
    // — `@wippy-fe/proxy`'s `on` export — but the factory's type binds
    // to its imported reference, not ours). Structurally identical.
    on: on as Parameters<typeof createAppRouterFactory>[1] extends { on?: infer T } ? T : never,
  })

  // Bespoke cmd-navigate listener — keeper's parent shell can post a
  // programmatic navigation command. Module-scope (app-lifetime) — no
  // cleanup needed.
  window.addEventListener('message', (event) => {
    if (event.source !== window.parent) return
    if (typeof event.data !== 'string') return
    try {
      const msg = JSON.parse(event.data)
      if (msg.action === 'cmd-navigate' && msg.url) {
        const resolved = router.resolve(msg.url)
        if (resolved.matched.length > 0 && resolved.name !== 'not-found') {
          router.push(msg.url)
        }
      }
    } catch { /* malformed message — ignore */ }
  })

  return router
}
