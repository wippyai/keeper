import type { ProxyApiInstance } from '../types'

export interface Namespace {
  name: string
  count: number
}

export interface RegistryEntry {
  id: string
  kind: string
  meta: Record<string, any>
  data?: Record<string, any>
}

export interface NamespacesResponse {
  success: boolean
  count: number
  namespaces: Namespace[]
}

export interface EntriesResponse {
  success: boolean
  count: number
  total: number
  offset: number
  limit: number
  has_more: boolean
  entries: RegistryEntry[]
}

export interface EntryDetailResponse {
  success: boolean
  entry: RegistryEntry
  version?: { id: number; previous: number | null; string: string }
}

export async function listNamespaces(api: ProxyApiInstance['api']): Promise<NamespacesResponse> {
  const { data } = await api.get<NamespacesResponse>('/api/v1/keeper/registry/namespaces')
  return data
}

export async function listEntries(
  api: ProxyApiInstance['api'],
  opts: { namespace?: string; kind?: string; metaType?: string; query?: string; limit?: number; offset?: number } = {},
): Promise<EntriesResponse> {
  const params: any = { limit: opts.limit || 200, offset: opts.offset || 0 }
  if (opts.namespace) params.namespace = opts.namespace
  if (opts.kind) params.kind = opts.kind
  if (opts.metaType) params['meta.type'] = opts.metaType
  if (opts.query) params.q = opts.query
  const { data } = await api.get<EntriesResponse>('/api/v1/keeper/registry/entries', { params })
  return data
}

export async function getEntry(api: ProxyApiInstance['api'], id: string): Promise<EntryDetailResponse> {
  const { data } = await api.get<EntryDetailResponse>('/api/v1/keeper/registry/entry', { params: { id } })
  return data
}

export async function updateEntry(
  api: ProxyApiInstance['api'],
  id: string,
  updates: { kind?: string; meta?: Record<string, any>; data?: Record<string, any>; merge?: boolean },
): Promise<any> {
  const { data } = await api.put('/api/v1/keeper/registry/entry', updates, { params: { id } })
  return data
}

export interface GraphResponse {
  success: boolean
  nodes: Array<{ id: string; kind: string }>
  edges: Array<{ source: string; target: string; type: string }>
  count: { nodes: number; edges: number }
}

export async function fetchGraph(
  api: ProxyApiInstance['api'],
  namespace?: string,
): Promise<GraphResponse> {
  const params: any = {}
  if (namespace) params.namespace = namespace
  const { data } = await api.get<GraphResponse>('/api/v1/keeper/state/graph', { params })
  return data
}

export interface EnvVariable {
  id: string
  env_var?: string
  has_value: boolean
  value?: string
  readonly?: boolean
  description?: string
  icon?: string
  meta?: Record<string, any>
}

export interface EnvListResponse {
  success: boolean
  count: number
  variables: EnvVariable[]
}

export async function listEnvVariables(api: ProxyApiInstance['api']): Promise<EnvListResponse> {
  const { data } = await api.get<EnvListResponse>('/api/v1/keeper/env/list')
  return data
}

export async function setEnvVariable(api: ProxyApiInstance['api'], key: string, value: string): Promise<any> {
  const { data } = await api.post('/api/v1/keeper/env/set', { key, value })
  return data
}

export interface SyncState {
  success: boolean
  registry?: { current_version: number; timestamp: number; has_changes: boolean }
  syncer?: { status: string; has_changes?: boolean }
}

export interface GovernanceConfig {
  success: boolean
  message?: string
  managed_namespaces: string[]
  linter_level?: number
  source_fs_id?: string
  process_host?: string
  env_ids?: Record<string, string>
}

export async function getSyncState(api: ProxyApiInstance['api']): Promise<SyncState> {
  const { data } = await api.get<SyncState>('/api/v1/keeper/sync/state')
  return data
}

export async function getGovernanceConfig(api: ProxyApiInstance['api']): Promise<GovernanceConfig> {
  const { data } = await api.get<GovernanceConfig>('/api/v1/keeper/sync/config')
  return data
}

export async function updateGovernanceConfig(
  api: ProxyApiInstance['api'],
  managedNamespaces: string[],
): Promise<GovernanceConfig> {
  const { data } = await api.put<GovernanceConfig>('/api/v1/keeper/sync/config', {
    managed_namespaces: managedNamespaces,
  })
  return data
}

export async function syncDownload(api: ProxyApiInstance['api']): Promise<any> {
  const { data } = await api.post('/api/v1/keeper/sync/download')
  return data
}

export async function syncUpload(api: ProxyApiInstance['api']): Promise<any> {
  const { data } = await api.post('/api/v1/keeper/sync/upload')
  return data
}

export async function syncUndo(api: ProxyApiInstance['api']): Promise<any> {
  const { data } = await api.post('/api/v1/keeper/sync/undo')
  return data
}

export async function syncRedo(api: ProxyApiInstance['api']): Promise<any> {
  const { data } = await api.post('/api/v1/keeper/sync/redo')
  return data
}

const colorMap: Record<string, string> = {
  'ns.definition':   'var(--p-info-500)',
  'ns.requirement':  'var(--p-warn-500)',
  'ns.dependency':   'var(--p-accent-400)',
  'http.service':    'var(--p-success-500)',
  'http.router':     'var(--p-success-500)',
  'http.endpoint':   'var(--p-info-500)',
  'http.static':     'var(--p-info-500)',
  'function.lua':    'var(--p-warn-500)',
  'library.lua':     'var(--p-warn-500)',
  'process.lua':     'var(--p-warn-500)',
  'registry.entry':  'var(--p-accent-500)',
  'db.sql.sqlite':   'var(--p-accent-500)',
  'fs.directory':    'var(--p-text-muted-color)',
  'fs.embed':        'var(--p-text-muted-color)',
  'process.host':    'var(--p-info-500)',
  'store.memory':    'var(--p-accent-500)',
  'store.sql':       'var(--p-accent-500)',
  'env.variable':    'var(--p-text-muted-color)',
  'env.composite':   'var(--p-text-muted-color)',
  'env.file':        'var(--p-text-muted-color)',
  'env.os':          'var(--p-text-muted-color)',
  'env.memory':      'var(--p-text-muted-color)',
  'security.policy': 'var(--p-danger-500)',
  'view.page':       'var(--p-info-500)',
  'view.component':  'var(--p-info-500)',
  'queue.memory':    'var(--p-accent-500)',
  'queue.consumer':  'var(--p-accent-500)',
  'template.set':    'var(--p-warn-500)',
  'contract':        'var(--p-accent-400)',
  'agent.gen1':      'var(--p-warn-500)',
  'agent.trait':     'var(--p-warn-500)',
  'llm.model':       'var(--p-accent-500)',
  'tool':            'var(--p-info-500)',
}

const iconMap: Record<string, string> = {
  'ns.definition': 'tabler:package',
  'ns.requirement': 'tabler:plug',
  'ns.dependency': 'tabler:link',
  'http.service': 'tabler:server',
  'http.router': 'tabler:route',
  'http.endpoint': 'tabler:api',
  'http.static': 'tabler:file',
  'function.lua': 'tabler:code',
  'library.lua': 'tabler:book',
  'process.lua': 'tabler:code',
  'registry.entry': 'tabler:database',
  'db.sql.sqlite': 'tabler:database',
  'fs.directory': 'tabler:folder',
  'fs.embed': 'tabler:folder',
  'process.host': 'tabler:cpu',
  'store.memory': 'tabler:database',
  'store.sql': 'tabler:database',
  'env.variable': 'tabler:variable',
  'env.composite': 'tabler:variable',
  'env.file': 'tabler:variable',
  'env.os': 'tabler:variable',
  'env.memory': 'tabler:variable',
  'security.policy': 'tabler:shield-check',
  'view.page': 'tabler:browser',
  'view.component': 'tabler:components',
  'queue.memory': 'tabler:list',
  'queue.consumer': 'tabler:player-play',
  'template.set': 'tabler:template',
  'contract': 'tabler:file-certificate',
  'agent.gen1': 'tabler:robot',
  'agent.trait': 'tabler:sparkles',
  'llm.model': 'tabler:brain',
  'tool': 'tabler:tool',
}

export function entryType(entry: RegistryEntry): string {
  return entry.meta?.type || entry.kind
}

export function kindColor(kind: string, metaType?: string): string {
  if (metaType && colorMap[metaType]) return colorMap[metaType]
  return colorMap[kind] || 'var(--p-text-muted-color)'
}

export function kindIcon(kind: string, metaType?: string): string {
  if (metaType && iconMap[metaType]) return iconMap[metaType]
  return iconMap[kind] || 'tabler:circle'
}
