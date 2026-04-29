import type { ProxyApiInstance } from '../types'

export type DataflowStatus = 'template' | 'pending' | 'ready' | 'running' | 'paused' | 'completed' | 'failed' | 'cancelled' | 'skipped' | 'terminated'
export type NodeStatus = 'template' | 'pending' | 'running' | 'completed' | 'failed' | 'cancelled' | 'skipped' | 'terminated'

export interface Dataflow {
  dataflow_id: string
  parent_dataflow_id?: string
  actor_id: string
  type: string
  status: DataflowStatus
  last_commit_id?: string
  metadata?: Record<string, any>
  created_at: number | string
  updated_at: number | string
}

export interface DataflowNode {
  node_id: string
  dataflow_id: string
  parent_node_id?: string
  type: string
  status: NodeStatus
  config?: Record<string, any>
  metadata?: Record<string, any>
  created_at: number | string
  updated_at: number | string
}

export interface DataflowData {
  data_id: string
  dataflow_id: string
  node_id?: string
  type: string
  discriminator?: string
  key?: string
  content: any
  content_type: string
  metadata?: Record<string, any>
  created_at: number | string
}

export interface DataflowListResponse {
  success: boolean
  dataflows: Dataflow[]
  count: number
}

export interface DataflowDetailResponse {
  success: boolean
  dataflow: Dataflow
  nodes: DataflowNode[]
  data: DataflowData[]
}

export interface DataflowNodesResponse {
  success: boolean
  dataflow: Dataflow
  nodes: DataflowNode[]
}

export async function listDataflows(api: ProxyApiInstance['api'], limit = 50, offset = 0, status?: string): Promise<DataflowListResponse> {
  const params: any = { limit, offset }
  if (status) params.status = status
  const { data } = await api.get<DataflowListResponse>('/api/v1/dataflows', { params })
  return data
}

export async function getDataflow(api: ProxyApiInstance['api'], id: string): Promise<DataflowDetailResponse> {
  const { data } = await api.get<DataflowDetailResponse>(`/api/v1/dataflows/${id}`)
  return data
}

export async function getDataflowNodes(api: ProxyApiInstance['api'], id: string): Promise<DataflowNodesResponse> {
  const { data } = await api.get<DataflowNodesResponse>(`/api/v1/dataflows/${id}/nodes`)
  return data
}

export async function cancelDataflow(api: ProxyApiInstance['api'], id: string, timeout = '30s'): Promise<any> {
  const { data } = await api.post(`/api/v1/dataflows/${id}/cancel`, null, { params: { timeout } })
  return data
}

export async function terminateDataflow(api: ProxyApiInstance['api'], id: string): Promise<any> {
  const { data } = await api.post(`/api/v1/dataflows/${id}/terminate`)
  return data
}

export function statusColor(status: string): string {
  const map: Record<string, string> = {
    running:    'var(--p-success-500)',
    completed:  'var(--p-info-500)',
    failed:     'var(--p-danger-500)',
    cancelled:  'var(--p-warn-500)',
    terminated: 'var(--p-danger-500)',
    pending:    'var(--p-text-muted-color)',
    ready:      'var(--p-warn-500)',
    paused:     'var(--p-accent-500)',
    skipped:    'var(--p-text-muted-color)',
    template:   'var(--p-text-muted-color)',
  }
  return map[status] || 'var(--p-text-muted-color)'
}

export function statusIcon(status: string): string {
  const map: Record<string, string> = {
    running: 'tabler:player-play', completed: 'tabler:check', failed: 'tabler:x',
    cancelled: 'tabler:player-stop', terminated: 'tabler:skull', pending: 'tabler:clock',
    ready: 'tabler:bolt', paused: 'tabler:player-pause', skipped: 'tabler:arrow-right',
  }
  return map[status] || 'tabler:circle'
}

export function nodeTypeShort(type: string): string {
  if (type.includes('agent')) return 'agent'
  if (type.includes('func')) return 'func'
  if (type.includes('cycle')) return 'cycle'
  if (type.includes('parallel')) return 'parallel'
  if (type.includes('state')) return 'state'
  return type.split(':').pop() || type
}

export function dataTypeShort(type: string): string {
  return type.replace(/^(node|dataflow|context|artifact|iteration)\./, '')
}
