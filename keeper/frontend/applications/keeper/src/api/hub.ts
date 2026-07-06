import type { ProxyApiInstance } from '../types'

type Api = ProxyApiInstance['api']

export interface HubMigration {
  id: string
  module?: string
  module_version?: string
  timestamp?: string | number
  status?: 'applied' | 'pending' | string
  status_error?: string
}

export interface HubEntrySummary {
  id: string
  kind?: string
  type?: string
  module?: string
  module_version?: string
  title?: string
}

export interface HubDependency {
  id: string
  namespace?: string
  name?: string
  component?: string
  version?: string
  source?: string
  installed?: boolean
  installed_entries_count?: number
  entries?: HubEntrySummary[]
  migrations?: HubMigration[]
  installed_at?: string | number
  meta?: Record<string, any>
}

// A dependency the list endpoint reports as an installed root: it appears in
// wippy.lock as a directly requested component, and `used_by` names the other
// installed modules that also reach it.
export interface DependencyRoot extends HubDependency {
  is_root?: boolean
  used_by?: string[]
  used_by_count?: number
}

// Full-inventory entry from `dependencies.modules`: covers roots AND the
// transitive modules pulled in beneath them. `transitive` is the inverse of
// `is_root`; `source` distinguishes hub-published modules from local ones.
export interface ModuleInventoryEntry {
  name: string
  version?: string
  is_root?: boolean
  transitive?: boolean
  source?: 'hub' | 'local' | string
  source_path?: string
  used_by?: string[]
  used_by_count?: number
}

export interface ListDepsResponse {
  success: boolean
  dependencies: DependencyRoot[]
  count: number
  module_count?: number
  modules?: ModuleInventoryEntry[]
}

export interface ListMigrationsResponse {
  success: boolean
  migrations: HubMigration[]
  count: number
}

export interface InstallPayload {
  id?: string
  component: string
  version?: string
  namespace?: string
  name?: string
  branch?: string
  migration_policy?: 'none' | 'up'
  run_migrations?: boolean
  dry_run?: boolean
  source?: string
  parameters?: Record<string, string> | Array<{ name: string; value: string }>
}

export interface HubPlanRequirement extends HubRequirement {
  short_name?: string
  parameter_name: string
  full_id: string
  module?: string
  namespace?: string
  version?: string
  depth?: number
  dependency_path?: string
  expected_kind?: string
  required?: boolean
  missing?: boolean
  value?: string
  value_source?: 'provided' | 'provided_bare' | 'existing' | 'existing_bare' | 'suggested' | 'default' | 'empty' | string
  invalid?: boolean
  invalid_reason?: string
  suggestions?: Array<{ value: string; label?: string; source?: string; kind?: string; preferred?: boolean; dependency_id?: string }>
  transitive?: boolean
}

export interface HubInstallPlanNode {
  module: string
  org?: string
  name?: string
  namespace?: string
  version?: string
  constraint?: string
  depth?: number
  parent?: string
  path?: string
  direct?: boolean
  dependencies?: HubDependencyRef[]
  requirements?: HubRequirement[]
  entry_count?: number
  entry_kinds?: string[]
  lua_modules?: string[]
  size_bytes?: number
  digest?: string
  yanked?: boolean
  protected?: boolean
  // Resolution state relative to the current wippy.lock, filled by the planner.
  // installed: this module is already present in the lock; shared: it is already
  // reached from another installed root, so installing here only reuses it.
  installed?: boolean
  shared?: boolean
}

// Semantic alias for HubInstallPlanNode used by the install tree UI.
export type InstallPlanNode = HubInstallPlanNode

export interface HubInstallPlanResponse {
  success: boolean
  dependency: HubDependency
  graph: HubInstallPlanNode[]
  module_count: number
  requirements: HubPlanRequirement[]
  requirement_count: number
  missing_requirements: string[]
  parameter_values: Record<string, string>
  recommended_parameters: Array<{ name: string; value: string }>
  migration_policy?: 'none' | 'up' | string
  install_payload: InstallPayload
}

export interface UninstallPayload {
  id?: string
  component?: string
  branch?: string
  migration_policy?: 'none' | 'down' | 'leave' | 'block'
  dry_run?: boolean
}

export interface UninstallPreviewEntry {
  name: string
  version?: string
}

// Dry-run uninstall projection. removed = the target plus its exclusive
// subtree; kept = target deps retained because another remaining root still
// needs them; kept_under_uncertainty = deps the planner withholds because the
// graph is incomplete and it cannot prove they are safe to drop.
export interface UninstallPreview {
  removed: UninstallPreviewEntry[]
  kept: UninstallPreviewEntry[]
  kept_under_uncertainty: UninstallPreviewEntry[]
  warnings: string[]
}

export interface UninstallPreviewResponse {
  success: boolean
  preview?: UninstallPreview
  [key: string]: any
}

export type HubScanStatus = 'clean' | 'warnings' | 'critical' | 'error' | string
export type HubScanFindingSeverity = 'info' | 'warning' | 'critical' | string

export interface HubScanFinding {
  severity: HubScanFindingSeverity
  title: string
  detail?: string
  location?: string
  module?: string
  version?: string
}

export interface HubScanModuleResult {
  module: string
  version?: string
  status: HubScanStatus
  summary: string
  findings: HubScanFinding[]
}

export interface HubScanResponse {
  success: boolean
  overall_status: HubScanStatus
  overall_summary: string
  modules: HubScanModuleResult[]
  scanned: number
  total: number
}

function emptyUninstallPreview(): UninstallPreview {
  return { removed: [], kept: [], kept_under_uncertainty: [], warnings: [] }
}

export async function listHubDependencies(api: Api, opts: { component?: string; entries?: boolean; migrations?: boolean; modules?: boolean } = {}): Promise<ListDepsResponse> {
  const params: any = {}
  if (opts.component) params.component = opts.component
  if (opts.entries === false) params.entries = false
  if (opts.migrations === false) params.migrations = false
  if (opts.modules === false) params.modules = false
  const { data } = await api.get<ListDepsResponse>('/api/v1/keeper/hub/dependencies', { params })
  return data
}

export async function installHubDependency(api: Api, payload: InstallPayload): Promise<any> {
  const { data } = await api.post('/api/v1/keeper/hub/dependencies/install', payload)
  return data
}

export async function planHubInstall(api: Api, payload: InstallPayload): Promise<HubInstallPlanResponse> {
  const { data } = await api.post<HubInstallPlanResponse>('/api/v1/keeper/hub/dependencies/plan', payload)
  return data
}

export async function uninstallHubDependency(api: Api, payload: UninstallPayload): Promise<any> {
  const { data } = await api.post('/api/v1/keeper/hub/dependencies/uninstall', payload)
  return data
}

// Dry-run the uninstall to obtain the removed/kept projection before the user
// confirms. Forces dry_run:true regardless of the passed payload.
export async function planHubUninstall(api: Api, payload: UninstallPayload): Promise<UninstallPreview> {
  const { data } = await api.post<UninstallPreviewResponse>('/api/v1/keeper/hub/dependencies/uninstall', { ...payload, dry_run: true })
  const preview = data?.preview
  if (!preview) return emptyUninstallPreview()
  return {
    removed: preview.removed || [],
    kept: preview.kept || [],
    kept_under_uncertainty: preview.kept_under_uncertainty || [],
    warnings: preview.warnings || [],
  }
}

export async function scanHubInstall(api: Api, payload: InstallPayload): Promise<HubScanResponse> {
  const { data } = await api.post<HubScanResponse>('/api/v1/keeper/hub/scan', payload)
  return data
}

export async function listHubMigrations(api: Api, opts: { component?: string; entry_ids?: string[] } = {}): Promise<ListMigrationsResponse> {
  const params: any = {}
  if (opts.component) params.component = opts.component
  if (opts.entry_ids && opts.entry_ids.length) params.entry_ids = opts.entry_ids.join(',')
  const { data } = await api.get<ListMigrationsResponse>('/api/v1/keeper/hub/migrations', { params })
  return data
}

export async function runHubMigrations(api: Api, payload: { operation?: 'up' | 'down'; component?: string; entry_ids?: string[]; dry_run?: boolean; only_pending?: boolean }): Promise<any> {
  const { data } = await api.post('/api/v1/keeper/hub/migrations/run', payload)
  return data
}

export interface HubModule {
  id: string
  name: string
  org: string
  org_id?: string
  full_name?: string
  display_name?: string
  description?: string
  latest_version?: string
  total_downloads?: number
  favorites_count?: number
  create_time?: string
  update_time?: string
  visibility?: string
  deprecated?: boolean
  deprecation_message?: string
  type?: string
  keywords?: string[]
  license?: string
  repository?: string
  homepage?: string
  protected?: boolean
}

export interface BrowseResponse {
  success: boolean
  items: HubModule[]
  total: number
  page: number
  page_size: number
  query: string
}

export async function browseHubModules(api: Api, opts: { query?: string; page?: number; page_size?: number; visibility?: string; type?: string; sort?: string } = {}): Promise<BrowseResponse> {
  const params: any = {}
  if (opts.query) params.q = opts.query
  if (opts.page) params.page = opts.page
  if (opts.page_size) params.page_size = opts.page_size
  if (opts.visibility) params.visibility = opts.visibility
  if (opts.type) params.type = opts.type
  if (opts.sort) params.sort = opts.sort
  const { data } = await api.get<BrowseResponse>('/api/v1/keeper/hub/browse', { params })
  return data
}

export interface HubDependencyRef {
  org?: string
  name?: string
  version_constraint?: string
}

export interface HubRequirement {
  name?: string
  description?: string
  default?: string
  targets?: Array<{ entry?: string; path?: string }>
}

export interface HubVersionFile {
  path?: string
  size_bytes?: number
  digest?: string
}

export interface HubVersion {
  id: string
  module_id?: string
  version: string
  digest?: string
  size_bytes?: number
  yanked?: boolean
  published_by?: string
  create_time?: string
  download_count?: number
  protected?: boolean
  protection_type?: string
  lua_modules?: string[]
  entry_kinds?: string[]
  entry_count?: number
  dependencies?: HubDependencyRef[]
  requirements?: HubRequirement[]
  files?: HubVersionFile[]
  readme?: string
  release_notes?: string
  source?: string
  source_label?: string
  metadata?: Record<string, any>
  is_latest?: boolean
}

export interface VersionsResponse {
  success: boolean
  items: HubVersion[]
  total: number
  page: number
  page_size: number
}

export async function listHubVersions(api: Api, module: string, opts: { page?: number; page_size?: number } = {}): Promise<VersionsResponse> {
  const params: any = { module }
  if (opts.page) params.page = opts.page
  if (opts.page_size) params.page_size = opts.page_size
  const { data } = await api.get<VersionsResponse>('/api/v1/keeper/hub/versions', { params })
  return data
}

export interface ReadmeResponse {
  success: boolean
  content: string
  filename?: string
  version?: string
}

export async function getHubReadme(api: Api, module: string, version?: string): Promise<ReadmeResponse> {
  const params: any = { module }
  if (version) params.version = version
  const { data } = await api.get<ReadmeResponse>('/api/v1/keeper/hub/readme', { params })
  return data
}
