import type { AxiosInstance } from 'axios'

export interface GitClusterSummary {
  cluster_id: string
  title: string
  decision: string
  verdict?: string
  importance?: string
  source?: string
  pushable?: boolean
  change_count?: number
  rec_open?: number
  stats?: {
    total?: number
    added?: number
    removed?: number
    namespaces?: string[]
  }
}

export interface GitSnapshot {
  run_id?: string
  stale?: boolean
  summary?: Record<string, unknown>
  clusters?: GitClusterSummary[]
  cluster_order?: string[]
  counts?: Record<string, number>
}

export interface PullRequestCommand {
  label: string
  command: string
  mutates: boolean
}

export interface PullRequestStatus {
  cwd: string
  current_branch: string
  protected_branch: boolean
  dirty: boolean
  status: string
  remotes: Record<string, string>
  gh_available: boolean
  gh_authenticated: boolean
  gh_status?: string
}

export interface PullRequestResult {
  ok?: boolean
  dry_run?: boolean
  action?: string
  cwd?: string
  remote?: string
  base_branch?: string
  head_branch?: string
  title?: string
  body?: string
  draft?: boolean
  commit_message?: string
  paths?: string[]
  commands?: PullRequestCommand[]
  blockers?: unknown[]
  status?: PullRequestStatus
  results?: Array<{ label: string; command: string; exit_code?: number; stdout?: string; stderr?: string }>
  pr_url?: string
  failed_step?: string
  error?: string
}

export interface PullRequestRequest {
  action?: 'status' | 'plan' | 'create' | 'full'
  dry_run?: boolean
  confirm?: boolean
  remote?: string
  base_branch?: string
  head_branch?: string
  title?: string
  body?: string
  draft?: boolean
  commit_message?: string
  paths?: string[]
}

export async function rebuildGit(api: AxiosInstance, body: Record<string, unknown> = {}) {
  const { data } = await api.post('/api/v1/keeper/git/rebuild', body)
  return data as { success: boolean; result?: GitSnapshot; started?: boolean; request_id?: string; error?: string }
}

export async function listGitClusters(api: AxiosInstance) {
  const { data } = await api.get('/api/v1/keeper/git/clusters')
  return data as { success: boolean } & GitSnapshot
}

export async function setGitClusterDecision(api: AxiosInstance, clusterId: string, decision: string) {
  const { data } = await api.patch(`/api/v1/keeper/git/clusters/${clusterId}/decision`, { decision })
  return data
}

export async function pushGitClusters(api: AxiosInstance, clusterIds: string[], message?: string, dryRun = true) {
  const { data } = await api.post('/api/v1/keeper/git/push', { cluster_ids: clusterIds, message, dry_run: dryRun })
  return data as { success: boolean; ok?: boolean; dry_run?: boolean; results?: unknown[]; pushed?: number; failed?: number }
}

export async function pullRequest(api: AxiosInstance, body: PullRequestRequest) {
  const { data } = await api.post('/api/v1/keeper/git/pull-request', body)
  return data as { success: boolean; result: PullRequestResult; error?: string }
}
