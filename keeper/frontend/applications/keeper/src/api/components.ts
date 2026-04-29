import type { AxiosInstance } from 'axios'

export interface ComponentScripts {
  build?: string
  test?: string
  dev?: string
}

export interface ComponentOrigin {
  name?: string
  source_path?: string
  source_repo?: string
  upstream_name?: string
  built_at?: number
  built_from_sha?: string
}

export type LinkKind = 'local' | 'manifest' | 'none'

export interface ComponentDescriptor {
  id: string
  kind: 'app' | 'widget'
  path: string
  title: string
  description: string
  version?: string
  tag_name?: string
  props_schema?: any
  toolchain: string
  scripts: ComponentScripts
  out_dir: string
  built: boolean
  size_bytes: number
  last_built: number
  source_bytes: number
  source_mtime: number
  docs: string[]
  readme_path?: string
  peer_deps?: Record<string, string>
  dependencies?: Record<string, string>
  editable: boolean
  link_kind: LinkKind
  is_main_app: boolean
  thumbnail_url: string
  origin?: ComponentOrigin | null
}

export interface ComponentListResponse {
  success: boolean
  applications: ComponentDescriptor[]
  widgets: ComponentDescriptor[]
  kit_docs: string[]
  scanned_at: number
}

export interface ComponentGetResponse {
  success: boolean
  component: ComponentDescriptor
}

export interface DocResponse {
  success: boolean
  path: string
  content: string
}

export async function listComponents(api: AxiosInstance): Promise<ComponentListResponse> {
  const { data } = await api.get<ComponentListResponse>('/api/v1/keeper/components')
  return data
}

export async function getComponent(api: AxiosInstance, id: string): Promise<ComponentGetResponse> {
  const { data } = await api.get<ComponentGetResponse>('/api/v1/keeper/components/component', { params: { id } })
  return data
}

export async function getDoc(api: AxiosInstance, path: string): Promise<DocResponse> {
  const { data } = await api.get<DocResponse>('/api/v1/keeper/components/doc', { params: { path } })
  return data
}

// -------------- Builds --------------

export type BuildStatus = 'queued' | 'running' | 'success' | 'failed' | 'cancelled'
export type BuildStream = 'stdout' | 'stderr' | 'system'

export interface BuildLine {
  seq: number
  stream: BuildStream
  at: number
  text: string
}

export interface BuildRun {
  build_id: string
  component_id: string
  component_path: string
  session_id?: string | null
  trigger: 'user' | 'agent' | 'session'
  triggered_by: string
  status: BuildStatus
  command: string
  image: string
  toolchain: string
  exit_code?: number | null
  duration_ms?: number | null
  error?: string | null
  started_at: number
  finished_at?: number | null
  lines?: BuildLine[]
}

export async function startBuild(api: AxiosInstance, component_id: string, trigger: 'user' | 'agent' | 'session' = 'user') {
  const { data } = await api.post<{ success: boolean; build_id?: string; error?: string }>(
    '/api/v1/keeper/components/builds',
    { component_id, trigger },
  )
  return data
}

export async function listBuilds(api: AxiosInstance, component_id?: string, limit = 50) {
  const { data } = await api.get<{ success: boolean; builds: BuildRun[] }>(
    '/api/v1/keeper/components/builds',
    { params: { component_id, limit } },
  )
  return data
}

export async function getBuild(api: AxiosInstance, build_id: string, since = 0) {
  const { data } = await api.get<{ success: boolean; build: BuildRun }>(
    '/api/v1/keeper/components/build',
    { params: { id: build_id, since } },
  )
  return data
}

export interface ScreenshotResult {
  success: boolean
  screenshot_url?: string
  filename?: string
  thumbnail?: boolean
  captured_at?: number
  error?: string
}

export async function captureScreenshot(
  api: AxiosInstance,
  component_id: string,
  opts: {
    route?: string
    full?: boolean
    wait?: string
    wait_for?: string
    name?: string
    filename?: string
    thumbnail?: boolean
    color_scheme?: 'dark' | 'light' | 'no-preference'
  } = {},
) {
  const { data } = await api.post<ScreenshotResult>(
    '/api/v1/keeper/components/screenshot',
    { component_id, ...opts },
  )
  return data
}

export function formatBytes(bytes: number): string {
  if (!bytes) return '-'
  if (bytes < 1024) return bytes + 'B'
  if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + 'K'
  if (bytes < 1024 * 1024 * 1024) return (bytes / (1024 * 1024)).toFixed(1) + 'M'
  return (bytes / (1024 * 1024 * 1024)).toFixed(1) + 'G'
}

export function formatMtime(ts: number): string {
  if (!ts) return 'never'
  const d = new Date(ts * 1000)
  if (!Number.isFinite(d.getTime())) return 'never'
  const now = Date.now()
  const ageMs = now - d.getTime()
  if (ageMs < 60_000) return 'just now'
  if (ageMs < 3600_000) return Math.floor(ageMs / 60_000) + 'm ago'
  if (ageMs < 86400_000) return Math.floor(ageMs / 3600_000) + 'h ago'
  if (ageMs < 30 * 86400_000) return Math.floor(ageMs / 86400_000) + 'd ago'
  return d.toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' })
}

export function componentDisplayName(c: ComponentDescriptor): string {
  return c.title || c.id
}

export function shortPath(path: string): string {
  const parts = path.split('/')
  return parts.slice(Math.max(0, parts.length - 2)).join('/')
}
