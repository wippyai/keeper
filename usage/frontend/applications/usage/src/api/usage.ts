import type { ProxyApiInstance } from '../types'

export interface TokenTotals {
  total_tokens: number
  prompt_tokens: number
  completion_tokens: number
  thinking_tokens: number
  cache_read_tokens: number
  cache_write_tokens: number
  request_count: number
}

export interface TimeRange {
  start_time: number
  end_time: number
  period: string
  interval?: string
  start_formatted: string
  end_formatted: string
}

export interface SummaryResponse {
  success: boolean
  time_range: TimeRange
  summary: TokenTotals
}

export interface TimePeriod extends TokenTotals {
  time_period: string
}

export interface ByTimeResponse {
  success: boolean
  time_range: TimeRange
  periods: TimePeriod[]
  totals: TokenTotals
}

export interface ModelUsage extends TokenTotals {
  model_id: string
  percentage: number
}

export interface ByModelResponse {
  success: boolean
  time_range: TimeRange
  models: ModelUsage[]
  totals: TokenTotals
}

export interface UserUsage extends TokenTotals {
  user_id: string
  percentage: number
}

export interface ByUserResponse {
  success: boolean
  time_range: TimeRange
  users: UserUsage[]
  totals: TokenTotals
}

type Api = ProxyApiInstance['api']

function periodParams(period: string, startTime?: number, endTime?: number) {
  const params: Record<string, any> = { period }
  if (period === 'custom' && startTime && endTime) {
    params.start_time = startTime
    params.end_time = endTime
  }
  return params
}

export async function getUsageSummary(api: Api, period = 'today', startTime?: number, endTime?: number): Promise<SummaryResponse> {
  const { data } = await api.get<SummaryResponse>('/api/v1/keeper/usage/summary', { params: periodParams(period, startTime, endTime) })
  return data
}

export async function getUsageByTime(api: Api, period = 'today', interval?: string, startTime?: number, endTime?: number): Promise<ByTimeResponse> {
  const params: Record<string, any> = periodParams(period, startTime, endTime)
  if (interval) params.interval = interval
  const { data } = await api.get<ByTimeResponse>('/api/v1/keeper/usage/by-time', { params })
  return data
}

export async function getUsageByModel(api: Api, period = 'today', startTime?: number, endTime?: number): Promise<ByModelResponse> {
  const { data } = await api.get<ByModelResponse>('/api/v1/keeper/usage/by-model', { params: periodParams(period, startTime, endTime) })
  return data
}

export async function getUsageByUser(api: Api, period = 'today', startTime?: number, endTime?: number): Promise<ByUserResponse> {
  const { data } = await api.get<ByUserResponse>('/api/v1/keeper/usage/by-user', { params: periodParams(period, startTime, endTime) })
  return data
}
