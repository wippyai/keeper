import type { AxiosInstance } from 'axios'

export interface KeeperPlugin {
  id: string
  name: string
  title: string
  description?: string
  url: string
  icon?: string
  slot: string
  props?: Record<string, unknown>
}

export async function listPlugins(api: AxiosInstance): Promise<KeeperPlugin[]> {
  try {
    const { data } = await api.get('/api/v1/registry/entries', {
      params: { kind: 'registry.entry', 'meta.type': 'keeper.plugin' }
    })
    const entries = data.entries || []
    return entries.map((e: any) => ({
      id: e.id,
      name: e.meta?.name || e.id.split(':').pop(),
      title: e.meta?.title || e.meta?.name || e.id,
      description: e.meta?.description,
      url: e.meta?.url || '',
      icon: e.meta?.icon,
      slot: e.meta?.slot || 'generic',
      props: e.meta?.props,
    }))
  } catch {
    return []
  }
}
