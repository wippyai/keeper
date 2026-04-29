import type { ProxyApiInstance } from '../types'

export interface Session {
  session_id: string
  user_id: string
  title: string
  kind: string
  status?: string
  current_agent: string
  current_model: string
  primary_context_id: string
  start_date: number | string
  last_message_date: number | string
  meta?: {
    tokens?: {
      total_tokens: number
      prompt_tokens: number
      completion_tokens: number
      thinking_tokens: number
      cache_read_tokens: number
      cache_write_tokens: number
    }
  }
  config?: {
    model?: string
  }
  public_meta?: Array<{
    icon?: string
    id: string
    title: string
    url?: string
  }>
}

export interface MessageMetadata {
  agent_id?: string
  model?: string
  files?: string[]
  source?: string
  tokens?: {
    total_tokens: number
    prompt_tokens: number
    completion_tokens: number
    thinking_tokens: number
    cache_read_tokens: number
    cache_write_tokens: number
  }
  function_name?: string
  status?: 'success' | 'error'
  from_agent?: string
  from_model?: string
  to_model?: string
  to_agent?: string
  artifact_id?: string
  file_uuids?: string[]
  system_action?: 'model_change' | 'agent_change' | 'title_generated' | 'session_init'
}

export interface Message {
  message_id: string
  session_id: string
  data: string
  date: string
  type: 'system' | 'user' | 'assistant' | 'function' | 'delegation' | 'agent_change' | 'model_change' | 'artifact' | 'developer'
  metadata?: MessageMetadata
}

export interface SessionsListResponse {
  success: boolean
  count: number
  sessions: Session[]
}

export interface SessionGetResponse {
  success: boolean
  session: Session
  message_count: number
  latest_message?: Message
}

export interface SessionMessagesResponse {
  success: boolean
  session_id: string
  messages: Message[]
  pagination: {
    has_more: boolean
    next_cursor: string
    prev_cursor: string
  }
}

export interface SessionDetailsResponse {
  success: boolean
  session: Session
  messages: Message[]
  artifacts: any[]
  contexts: any[]
  primary_context: any
  stats: {
    message_count: number
    message_counts_by_type: Record<string, number>
    artifact_count: number
    context_count: number
    token_usage: {
      total_tokens: number
      prompt_tokens: number
      completion_tokens: number
      thinking_tokens: number
      cache_read_tokens: number
      cache_write_tokens: number
    }
  }
}

export async function listSessions(api: ProxyApiInstance['api'], limit = 100, offset = 0): Promise<SessionsListResponse> {
  const { data } = await api.get<SessionsListResponse>('/api/v1/sessions', {
    params: { limit, offset },
  })
  return data
}

export async function getSession(api: ProxyApiInstance['api'], sessionId: string): Promise<SessionGetResponse> {
  const { data } = await api.get<SessionGetResponse>('/api/v1/sessions/get', {
    params: { session_id: sessionId },
  })
  return data
}

export async function getSessionMessages(
  api: ProxyApiInstance['api'],
  sessionId: string,
  limit = 50,
  cursor = '',
): Promise<SessionMessagesResponse> {
  const { data } = await api.get<SessionMessagesResponse>('/api/v1/sessions/messages', {
    params: { session_id: sessionId, limit, cursor },
  })
  return data
}

export async function getSessionDetails(
  api: ProxyApiInstance['api'],
  sessionId: string,
): Promise<SessionDetailsResponse> {
  const { data } = await api.get<SessionDetailsResponse>('/api/v1/keeper/sessions/' + sessionId)
  return data
}

export function formatTokens(num: number): string {
  if (!num || num === 0) return '0'
  if (num >= 1_000_000) return (num / 1_000_000).toFixed(1) + 'M'
  if (num >= 1_000) return (num / 1_000).toFixed(1) + 'K'
  return num.toString()
}

export function timeAgo(dateInput: number | string): string {
  if (!dateInput) return ''
  let ms: number
  if (typeof dateInput === 'number') {
    // Detect unit by magnitude: ns (>1e15) → ms; µs (>1e12) → ms; ms (>1e10) → as-is; s (otherwise) → ×1000.
    if (dateInput > 1e15) ms = dateInput / 1e6
    else if (dateInput > 1e12) ms = dateInput / 1e3
    else if (dateInput > 1e10) ms = dateInput
    else ms = dateInput * 1000
  } else {
    ms = new Date(dateInput).getTime()
  }
  const date = new Date(ms)
  if (isNaN(date.getTime())) return ''
  const now = new Date()
  const diffSec = Math.floor((now.getTime() - date.getTime()) / 1000)

  if (diffSec < 60) return 'just now'
  const diffMin = Math.floor(diffSec / 60)
  if (diffMin < 60) return `${diffMin}m ago`
  const diffHour = Math.floor(diffMin / 60)
  if (diffHour < 24) return `${diffHour}h ago`
  const diffDay = Math.floor(diffHour / 24)
  if (diffDay < 30) return `${diffDay}d ago`
  const diffMonth = Math.floor(diffDay / 30)
  if (diffMonth < 12) return `${diffMonth}mo ago`
  return `${Math.floor(diffMonth / 12)}y ago`
}

export function formatDate(dateInput: number | string): string {
  if (!dateInput) return 'N/A'
  const date = new Date(typeof dateInput === 'number' ? dateInput * 1000 : dateInput)
  return date.toLocaleString()
}
