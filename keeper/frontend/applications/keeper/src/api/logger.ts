import type { ProxyApiInstance } from '../types'

export interface LogEntry {
  timestamp: number
  path: string
  level: number
  message: string
  logger_name: string
  caller: string
  fields: Record<string, any>
}

export interface LogCounters {
  debug: number
  info: number
  warn: number
  error: number
}

export interface LogStats {
  buffer_size: number
  stored_count: number
  total_received: number
  uptime_ns: number
  counters: LogCounters
}

export interface LogsResponse {
  success: boolean
  logs: LogEntry[]
  total_count: number
  filtered: boolean
  count: number
}

export interface StatsResponse {
  success: boolean
  stats: LogStats
}

type Api = ProxyApiInstance['api']

export async function getLogs(api: Api, count = 500, filter?: string, reverse = true): Promise<LogsResponse> {
  const params: Record<string, any> = { count, reverse: String(reverse) }
  if (filter) params.filter = filter
  const { data } = await api.get<LogsResponse>('/api/v1/keeper/logger/logs', { params })
  return data
}

export async function getLogStats(api: Api): Promise<StatsResponse> {
  const { data } = await api.get<StatsResponse>('/api/v1/keeper/logger/stats')
  return data
}

export async function clearLogs(api: Api): Promise<void> {
  await api.post('/api/v1/keeper/logger/clear')
}

export const LEVEL_NAMES: Record<number, string> = { [-1]: 'DEBUG', 0: 'INFO', 1: 'WARN', 2: 'ERROR' }
export const LEVEL_COLORS: Record<number, string> = {
  [-1]: 'var(--p-text-muted-color)',
  0: 'var(--p-success-500)',
  1: 'var(--p-warn-500)',
  2: 'var(--p-danger-500)',
}
