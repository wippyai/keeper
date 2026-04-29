import type { AxiosInstance } from 'axios'

export interface ChangelogEntry {
  id: number
  version: number
  timestamp: string
  user_id: string
  request_id: string
  op_type: string
  entry_id: string
  entry_kind: string
  entry_meta_type: string
  namespace: string
  summary: Record<string, unknown>
  created_at: string
}

export interface VersionSummary {
  version: number
  timestamp: string
  user_id: string
  request_id: string
  change_count: number
  creates: number
  updates: number
  deletes: number
  namespaces: string[]
}

export function opColor(op: string): string {
  switch (op) {
    case 'create': return 'var(--p-success-500)'
    case 'update': return 'var(--p-info-500)'
    case 'delete': return 'var(--p-danger-500)'
    default: return 'var(--p-text-muted-color)'
  }
}

export function opIcon(op: string): string {
  switch (op) {
    case 'create': return 'tabler:plus'
    case 'update': return 'tabler:pencil'
    case 'delete': return 'tabler:trash'
    default: return 'tabler:point'
  }
}

export async function listChangelog(api: AxiosInstance, params?: { namespace?: string; entry_id?: string; op_type?: string; limit?: number; offset?: number }) {
  const { data } = await api.get('/api/v1/keeper/changelog/list', { params })
  return data
}

export async function listVersions(api: AxiosInstance, limit = 50) {
  const { data } = await api.get('/api/v1/keeper/changelog/versions', { params: { limit } })
  return data
}
