import { createMemoryHistory, createRouter } from 'vue-router'

const routes = [
  {
    path: '/',
    name: 'git',
    component: () => import('../pages/git.vue'),
  },
  { path: '/:pathMatch(.*)*', redirect: '/' },
]

export function createAppRouter(initialPath: string = '/') {
  const router = createRouter({
    history: createMemoryHistory(),
    routes,
  })
  if (initialPath && initialPath !== '/') {
    router.push(initialPath).catch(() => {})
  }
  return router
}
