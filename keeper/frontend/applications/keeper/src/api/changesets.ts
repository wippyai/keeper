import type { AxiosInstance } from 'axios'

export interface Changeset {
  changeset_id: string
  kind: string
  title: string
  description?: string
  actor_id?: string
  session_id?: string
  parent_changeset?: string
  task_id?: string
  state: string
  state_reason?: string
  created_at: string
  updated_at: string
  closed_at?: string
}

export type ChangePart = 'definition' | 'content'

export interface ChangeEntry {
  category: 'registry' | 'filesystem'
  op: 'create' | 'update' | 'delete'
  target: string
  part?: ChangePart | null
  baseline_hash?: string
  current_hash?: string
}

export interface JournalRow {
  change_id: string
  changeset_id: string
  sequence: number
  category: string
  op: string
  target: string
  source: string
  status: string
  conflict_with?: string
  created_at: string
}

export interface ChangesResponse {
  computed: {
    registry: ChangeEntry[]
    filesystem: ChangeEntry[]
  }
  journal: JournalRow[]
}

export async function listChangesets(api: AxiosInstance, params?: Record<string, string>) {
  const { data } = await api.get('/api/v1/keeper/changesets', { params })
  return data as { changesets: Changeset[]; count: number }
}

export async function getChangeset(api: AxiosInstance, id: string) {
  const { data } = await api.get(`/api/v1/keeper/changesets/${id}`)
  return data as { changeset: Changeset }
}

export async function createChangeset(api: AxiosInstance, body: { title: string; kind?: string; description?: string }) {
  const { data } = await api.post('/api/v1/keeper/changesets', body)
  return data as { changeset: Changeset }
}

export async function editChangeset(api: AxiosInstance, id: string, body: Record<string, unknown>) {
  const { data } = await api.post(`/api/v1/keeper/changesets/${id}/edits`, body)
  return data
}

export async function listChanges(api: AxiosInstance, id: string) {
  const { data } = await api.get(`/api/v1/keeper/changesets/${id}/changes`)
  return data as ChangesResponse & { success: boolean }
}

export async function dropChangeset(api: AxiosInstance, id: string, reason?: string) {
  const { data } = await api.delete(`/api/v1/keeper/changesets/${id}`, { data: { reason } })
  return data
}

export interface DiffContent {
  target: string
  category: string
  part?: ChangePart | null
  language: string
  baseline: string
  current: string
}

export async function getChangeDiff(
  api: AxiosInstance,
  id: string,
  target: string,
  category: string,
  part?: ChangePart | null,
) {
  const params: Record<string, string> = { target, category }
  if (part) params.part = part
  const { data } = await api.get(`/api/v1/keeper/changesets/${id}/diff`, { params })
  return data as { success: boolean } & DiffContent
}

export const stateColors: Record<string, string> = {
  open:     'var(--p-info-500)',
  editing:  'var(--p-accent-500)',
  review:   'var(--p-warn-500)',
  accepted: 'var(--p-success-500)',
  rejected: 'var(--p-danger-500)',
  merged:   'var(--p-success-400)',
  dropped:  'var(--p-text-muted-color)',
}

export const stateIcons: Record<string, string> = {
  open: 'tabler:folder-open',
  editing: 'tabler:pencil',
  review: 'tabler:eye-check',
  accepted: 'tabler:check',
  rejected: 'tabler:x',
  merged: 'tabler:git-merge',
  dropped: 'tabler:trash',
}

export const opColors: Record<string, string> = {
  create: 'var(--p-success-500)',
  update: 'var(--p-info-500)',
  delete: 'var(--p-danger-500)',
}
