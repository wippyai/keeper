import type { AxiosInstance } from 'axios'

export interface MCPToken {
  token: string
  token_id: string
  label: string
  identity: string
  access_mode?: 'any' | 'traits' | 'tools_only'
  scopes: string[]
  trait_filter?: Record<string, unknown> | null
  tool_filter?: Record<string, unknown> | null
  default_active?: string[]
  created_at: number
  expires_at?: number | null
  revoked: boolean
}

export interface MCPScope {
  id: string
  label: string
  description: string
}

export interface MCPPreset {
  id: string
  registry_id: string
  label: string
  description: string
  icon: string
  access_mode: 'any' | 'traits' | 'tools_only'
  scopes: string[]
  trait_filter?: Record<string, unknown> | null
  tool_filter?: Record<string, unknown> | null
  default_active?: string[]
}

export interface MCPServerConfig {
  enabled: boolean
  url: string
  path: string
}

export async function listTokens(api: AxiosInstance) {
  const { data } = await api.get('/api/v1/keeper/mcp/tokens')
  return data
}

export async function createToken(api: AxiosInstance, params: {
  label: string
  scopes?: string[]
  preset?: string
  access_mode?: 'any' | 'traits' | 'tools_only'
  trait_filter?: Record<string, unknown> | null
  tool_filter?: Record<string, unknown> | null
  default_active?: string[]
  expires_at?: number | null
}) {
  const { data } = await api.post('/api/v1/keeper/mcp/tokens', params)
  return data
}

export async function revokeToken(api: AxiosInstance, token: string) {
  const { data } = await api.post('/api/v1/keeper/mcp/tokens/revoke', { token })
  return data
}

export async function listScopes(api: AxiosInstance) {
  const { data } = await api.get('/api/v1/keeper/mcp/scopes')
  return data as { success: boolean; scopes: MCPScope[]; presets: MCPPreset[]; config?: MCPServerConfig }
}
