import type { AxiosInstance } from 'axios'

export interface KB {
  id: string
  name: string
  description: string
  node_count: number
  created_at: string
  updated_at: string
}

export interface KBNode {
  id: string
  kb_id?: string
  parent_id?: string
  workspace_id?: string
  node_type: string
  title: string
  summary?: string
  content: string
  source: string
  confidence: number
  embedded: boolean
  scope_namespace?: string
  scope_kind?: string
  scope_meta_type?: string
  refs: string[]
  metadata: Record<string, unknown>
  distance?: number
  created_at: string
  updated_at: string
}

export interface KBStats {
  total: number
  embedded: number
  by_type: Record<string, number>
}

/**
 * Node type metadata. Severity tokens are deliberately mapped to each
 * category's semantic intent (see theming.md §"Semantic vs decorative" —
 * use severity ONLY when the category carries the severity's meaning):
 *
 *   anti_pattern → danger  — genuinely cautionary "avoid this"
 *   learning     → success — positive insight / completed lesson
 *   convention   → info    — factual reference / how-things-are-done
 *   pattern      → help    — lore / pedagogical "consider this approach"
 *
 * If the category set grows to include purely-decorative types (a kind
 * picker with no semantic meaning), switch the decorative entries to a
 * `--k-knowledge-N` palette per theming.md §"Decorative palette options".
 */
export const NODE_TYPES = [
  { value: 'pattern',      label: 'Pattern',      icon: 'tabler:template',        text: 'text-help-400',    bg: 'bg-help-500/10',    border: 'border-help-500/20' },
  { value: 'convention',   label: 'Convention',   icon: 'tabler:ruler-2',         text: 'text-info-400',    bg: 'bg-info-500/10',    border: 'border-info-500/20' },
  { value: 'learning',     label: 'Learning',     icon: 'tabler:bulb',            text: 'text-success-400', bg: 'bg-success-500/10', border: 'border-success-500/20' },
  { value: 'anti_pattern', label: 'Anti-pattern', icon: 'tabler:alert-triangle',  text: 'text-danger-400',  bg: 'bg-danger-500/10',  border: 'border-danger-500/20' },
] as const

export type NodeTypeMeta = typeof NODE_TYPES[number]

const FALLBACK_TYPE: NodeTypeMeta = {
  value: 'unknown', label: 'Unknown', icon: 'tabler:file',
  text: 'text-surface-400', bg: 'bg-surface-500/10', border: 'border-surface-500/20',
} as unknown as NodeTypeMeta

export function nodeTypeInfo(type: string): NodeTypeMeta {
  return NODE_TYPES.find(t => t.value === type) || FALLBACK_TYPE
}

// Knowledge base management

export async function listKBs(api: AxiosInstance) {
  const { data } = await api.get('/api/v1/keeper/knowledge/kbs')
  return data
}

export async function createKB(api: AxiosInstance, kb: { name: string; description?: string }) {
  const { data } = await api.post('/api/v1/keeper/knowledge/kbs', kb)
  return data
}

export async function deleteKB(api: AxiosInstance, id: string) {
  const { data } = await api.delete(`/api/v1/keeper/knowledge/kbs/${id}`)
  return data
}

// Nodes (scoped to a KB via kb query parameter)

export async function listNodes(api: AxiosInstance, params?: { kb?: string; type?: string; source?: string; limit?: number }) {
  const { data } = await api.get('/api/v1/keeper/knowledge/nodes', { params })
  return data
}

export async function getNode(api: AxiosInstance, id: string) {
  const { data } = await api.get(`/api/v1/keeper/knowledge/nodes/${id}`)
  return data
}

export async function createNode(api: AxiosInstance, node: Partial<KBNode>) {
  const { data } = await api.post('/api/v1/keeper/knowledge/nodes', node)
  return data
}

export async function updateNode(api: AxiosInstance, id: string, updates: Partial<KBNode>) {
  const { data } = await api.put(`/api/v1/keeper/knowledge/nodes/${id}`, updates)
  return data
}

export async function deleteNode(api: AxiosInstance, id: string) {
  const { data } = await api.delete(`/api/v1/keeper/knowledge/nodes/${id}`)
  return data
}

export async function searchNodes(api: AxiosInstance, query: string, opts?: { kb?: string; limit?: number }) {
  const { data } = await api.get('/api/v1/keeper/knowledge/search', {
    params: { q: query, kb: opts?.kb, limit: opts?.limit ?? 20 },
  })
  return data
}

export async function startResearch(api: AxiosInstance, prompt: string, opts?: { kb?: string; maxIterations?: number }) {
  const { data } = await api.post('/api/v1/keeper/knowledge/research', {
    prompt,
    kb: opts?.kb,
    max_iterations: opts?.maxIterations ?? 15,
  })
  return data
}

export async function startBatchResearch(api: AxiosInstance, prompts: string[], opts?: { kb?: string; batchSize?: number }) {
  const { data } = await api.post('/api/v1/keeper/knowledge/research', {
    prompts,
    kb: opts?.kb,
    batch_size: opts?.batchSize ?? 5,
  })
  return data
}

export async function seedStandards(api: AxiosInstance) {
  const { data } = await api.post('/api/v1/keeper/knowledge/seed')
  return data
}

export async function embedNode(api: AxiosInstance, nodeId: string, model?: string) {
  const { data } = await api.post('/api/v1/keeper/knowledge/embed', { node_id: nodeId, model })
  return data
}

export async function embedAll(api: AxiosInstance, model?: string) {
  const { data } = await api.post('/api/v1/keeper/knowledge/embed', { model })
  return data
}

export async function semanticSearch(api: AxiosInstance, query: string, opts?: { kb?: string; limit?: number }) {
  const { data } = await api.get('/api/v1/keeper/knowledge/semantic-search', {
    params: { q: query, kb: opts?.kb, limit: opts?.limit ?? 10 },
  })
  return data
}

export async function learnProject(api: AxiosInstance, kb?: string) {
  const { data } = await api.post('/api/v1/keeper/knowledge/learn', { kb })
  return data
}

export async function getStats(api: AxiosInstance, kb?: string) {
  const { data } = await api.get('/api/v1/keeper/knowledge/stats', { params: { kb } })
  return data
}
