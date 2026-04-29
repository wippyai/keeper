import type { DataflowNode } from '../../api/dataflows'
import { statusColor } from '../../api/dataflows'

export function nodeIcon(node: DataflowNode): string {
  if ((node.metadata as any)?.icon) {
    const icon = (node.metadata as any).icon
    return icon.startsWith('tabler:') ? icon : 'tabler:circle'
  }
  if (node.type.includes('agent')) return 'tabler:brain'
  if (node.type.includes('parallel')) return 'tabler:arrows-split'
  if (node.type.includes('cycle')) return 'tabler:refresh'
  if (node.type.includes('func')) return 'tabler:function'
  if (node.type.includes('state')) return 'tabler:database'
  return 'tabler:circle-dot'
}

export function nodeTitle(node: DataflowNode): string {
  if ((node.metadata as any)?.title) return (node.metadata as any).title
  const type = node.type.split(':').pop() || node.type
  return type.charAt(0).toUpperCase() + type.slice(1).replace(/_/g, ' ')
}

export function isAgentNode(node: DataflowNode): boolean {
  return node.type.includes('agent')
}

export function isParallelNode(node: DataflowNode): boolean {
  return node.type.includes('parallel')
}

export function isCycleNode(node: DataflowNode): boolean {
  return node.type.includes('cycle')
}

export interface NodeTokens {
  prompt: number
  completion: number
  thinking: number
  cache_read: number
  cache_write: number
  total: number
}

export function getNodeTokens(node: DataflowNode): NodeTokens | null {
  const state = (node.metadata as any)?.state?.total_tokens
  if (state) {
    return {
      prompt: state.prompt_tokens || 0,
      completion: state.completion_tokens || 0,
      thinking: state.thinking_tokens || 0,
      cache_read: state.cache_read_tokens || 0,
      cache_write: state.cache_write_tokens || 0,
      total: state.total_tokens || 0,
    }
  }
  const tokens = (node.metadata as any)?.tokens || (node.metadata as any)?.token_usage
  if (tokens) {
    return {
      prompt: tokens.prompt_tokens || 0,
      completion: tokens.completion_tokens || 0,
      thinking: tokens.thinking_tokens || 0,
      cache_read: tokens.cache_read_tokens || 0,
      cache_write: tokens.cache_write_tokens || 0,
      total: tokens.total_tokens || (tokens.prompt_tokens || 0) + (tokens.completion_tokens || 0),
    }
  }
  return null
}

export function getToolCalls(node: DataflowNode): number {
  return (node.metadata as any)?.state?.tool_calls || (node.metadata as any)?.tool_invocations || 0
}

export function getStatusMessage(node: DataflowNode): string | null {
  return (node.metadata as any)?.status_message || null
}

export function getParallelProgress(node: DataflowNode, children: DataflowNode[]): { completed: number; total: number } {
  const progress = (node.metadata as any)?.parallel_progress
  if (progress) return { completed: progress.items_completed || 0, total: progress.items_total || 0 }
  if (children.length === 0) return { completed: 0, total: 0 }
  const completed = children.filter(c => c.status === 'completed').length
  return { completed, total: children.length }
}

export function getIteration(node: DataflowNode): number {
  return (node.metadata as any)?.iteration || (node.metadata as any)?.created_in_iteration || 0
}

export function groupByIteration(nodes: DataflowNode[]): Map<number, DataflowNode[]> {
  const groups = new Map<number, DataflowNode[]>()
  for (const n of nodes) {
    const iter = getIteration(n)
    if (!groups.has(iter)) groups.set(iter, [])
    groups.get(iter)!.push(n)
  }
  return new Map([...groups.entries()].sort((a, b) => a[0] - b[0]))
}

export function getInputOutputSizes(node: DataflowNode): { input?: number; output?: number } | null {
  const meta = node.metadata as any
  if (!meta) return null
  const input = meta.input_size_bytes
  const output = meta.output_size_bytes
  if ((input === undefined || input < 2048) && (output === undefined || output < 2048)) return null
  return { input: input >= 2048 ? input : undefined, output: output >= 2048 ? output : undefined }
}

export function formatBytes(bytes: number): string {
  if (bytes === 0) return '0B'
  if (bytes < 1024) return `${bytes}B`
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)}K`
  return `${(bytes / (1024 * 1024)).toFixed(1)}M`
}

export function fmtTokens(n: number): string {
  if (n >= 1_000_000) return (n / 1_000_000).toFixed(1) + 'M'
  if (n >= 1000) return (n / 1000).toFixed(1) + 'K'
  return n.toString()
}
