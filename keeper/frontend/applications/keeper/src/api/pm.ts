import type { ProxyApiInstance } from '../types'

export interface HostStats {
  host_id: string
  workers: number
  process_count: number
  executed: number
  stolen: number
  queue_depth: number
  processes: ProcessStats[]
}

export interface ProcessStats {
  pid: string
  host: string
  source: string
  state: string
  steps: number
  started_at: number
  parent?: string
  actor_id?: string
  stats?: Record<string, unknown>
}

export interface ServiceState {
  id: string
  status: string
  desired: string
  retry_count: number
  last_update: number
  started_at: number
  details?: string
}

export interface StatsResponse {
  processes: HostStats[]
  services: ServiceState[]
}

type Api = ProxyApiInstance['api']

export async function fetchPmStats(api: Api): Promise<StatsResponse> {
  const { data } = await api.get<StatsResponse>('/api/v1/keeper/pm/stats')
  return data
}

export async function terminateProcess(api: Api, pid: string): Promise<void> {
  await api.post('/api/v1/keeper/pm/terminate', { pid })
}

export async function fetchSystemInfo(api: Api): Promise<any> {
  const { data } = await api.get('/api/v1/keeper/pm/system')
  return data
}
