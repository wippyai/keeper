import type { AxiosInstance } from 'axios'

export interface Task {
  task_id: string
  title: string
  description?: string
  spec?: string
  acceptance?: string
  phase: string
  blocked_from?: string
  status: string
  iteration: number
  actor_id?: string
  archived?: number
  created_at: string
  updated_at: string
  completed_at?: string
}

export interface TaskStats {
  total_nodes: number
  research_count: number
  review_count: number
  feedback_count: number
  changeset_count: number
  max_iteration: number
}

export async function listTasks(api: AxiosInstance, params?: Record<string, string>) {
  const { data } = await api.get('/api/v1/keeper/tasks', { params })
  return data as { tasks: Task[]; count: number }
}

export async function getTask(api: AxiosInstance, id: string) {
  const { data } = await api.get(`/api/v1/keeper/tasks/${id}`)
  return data as { task: Task; stats: TaskStats }
}

export async function createTask(api: AxiosInstance, body: { title: string; spec?: string; acceptance?: string; description?: string }) {
  const { data } = await api.post('/api/v1/keeper/tasks', body)
  return data
}

export async function updateTask(api: AxiosInstance, id: string, body: Record<string, unknown>) {
  const { data } = await api.put(`/api/v1/keeper/tasks/${id}`, body)
  return data
}

export async function archiveTask(api: AxiosInstance, id: string, archived = true) {
  const { data } = await api.post(`/api/v1/keeper/tasks/${id}/archive`, { archived })
  return data as { success: boolean; task_id: string; archived: boolean }
}

export async function syncResearch(api: AxiosInstance, id: string) {
  const { data } = await api.post(`/api/v1/keeper/tasks/${id}/sync`)
  return data as { success: boolean; synced: number }
}

export async function startCycle(api: AxiosInstance, id: string, opts?: { max_iterations?: number; auto_approve?: boolean }) {
  const { data } = await api.post(`/api/v1/keeper/tasks/${id}/start`, {
    max_iterations: opts?.max_iterations || 50,
    auto_approve: opts?.auto_approve || false,
  })
  return data as { success: boolean; dataflow_id: string; changeset_id: string; task_id: string; branch: string }
}

// Unified task_nodes stream (audit rows + payload nodes in one typed hierarchy).
export interface TaskNode {
  node_id: string
  task_id: string
  parent_node_id: string | null
  path: string
  depth: number
  position: number
  type: string                 // phase_started | phase_exited | tool_call | spec | finding | integrate_stage | ...
  discriminator: string | null // secondary key (revision, key, tool, stage)
  title: string
  content: string | null
  content_type: string
  status: string | null        // running | passed | failed | active | superseded
  visibility: 'user' | 'debug' | 'internal'
  agent_id: string | null
  dataflow_id: string | null
  changeset_id: string | null
  execution_ms: number | null
  error_message: string | null
  result_summary: string | null
  metadata: Record<string, any>
  seq: number
  created_at: number
  updated_at: number
}

export type LogNode = TaskNode

export async function listTaskNodes(api: AxiosInstance, id: string, params?: Record<string, string | number>) {
  const { data } = await api.get(`/api/v1/keeper/tasks/${id}/nodes`, { params })
  return data as { success: boolean; nodes: TaskNode[]; count: number; max_seq: number }
}

export async function addLog(api: AxiosInstance, id: string, body: Record<string, unknown>) {
  const { data } = await api.post(`/api/v1/keeper/tasks/${id}/log`, body)
  return data
}

export async function startResearch(api: AxiosInstance, id: string, prompt?: string) {
  const { data } = await api.post(`/api/v1/keeper/tasks/${id}/research`, { prompt })
  return data as { success: boolean; dataflow_id: string; task_id: string; title: string }
}

export async function searchTasks(api: AxiosInstance, q: string, params?: Record<string, string>) {
  const { data } = await api.get('/api/v1/keeper/tasks/search', { params: { q, ...params } })
  return data as { results: LogNode[]; count: number }
}

export const phaseColors: Record<string, string> = {
  spec:      'var(--p-text-muted-color)',
  research:  'var(--p-info-500)',
  design:    'var(--p-accent-500)',
  review:    'var(--p-warn-500)',
  implement: 'var(--p-warn-500)',
  test:      'var(--p-success-500)',
  integrate: 'var(--p-info-500)',
  done:      'var(--p-success-500)',
  blocked:   'var(--p-danger-500)',
}

export const phaseIcons: Record<string, string> = {
  spec: 'tabler:file-text', research: 'tabler:search', design: 'tabler:pencil', review: 'tabler:eye-check',
  implement: 'tabler:code', test: 'tabler:test-pipe', integrate: 'tabler:plug', done: 'tabler:check',
  finish: 'tabler:check', debug: 'tabler:bug', blocked: 'tabler:alert-circle',
  waiting_for_user: 'tabler:message-question', error: 'tabler:alert-triangle',
}

export const PHASES = ['spec', 'research', 'design', 'review', 'implement', 'test', 'integrate', 'done']
