import type { Message } from '../../api/sessions'

export function msgColor(type: string): string {
  return ({
    user: 'var(--p-info-500)', assistant: 'var(--p-success-500)', system: 'var(--p-warn-500)',
    function: 'var(--p-accent-400)', delegation: 'var(--p-accent-400)', artifact: 'var(--p-info-500)',
    developer: 'var(--p-accent-500)', agent_change: 'var(--p-warn-500)', model_change: 'var(--p-info-500)',
  } as Record<string, string>)[type] || 'var(--p-text-muted-color)'
}

export function msgIcon(type: string): string {
  return ({
    user: 'tabler:user', assistant: 'tabler:robot', system: 'tabler:settings',
    function: 'tabler:code', delegation: 'tabler:arrow-fork', artifact: 'tabler:file-code',
    developer: 'tabler:terminal', agent_change: 'tabler:replace',
    model_change: 'tabler:switch-horizontal',
  } as Record<string, string>)[type] || 'tabler:message'
}

export function isSystemAction(msg: Message): boolean {
  return msg.type === 'system' && !!msg.metadata?.system_action
}

export function systemActionText(msg: Message): string {
  const a = msg.metadata?.system_action
  if (a === 'model_change') return `Model: ${msg.metadata?.from_model || '?'} -> ${msg.metadata?.to_model || '?'}`
  if (a === 'agent_change') return `Agent: ${msg.metadata?.from_agent || ''} -> ${msg.metadata?.to_agent || '?'}`
  if (a === 'title_generated') return `Title: ${(msg.metadata as any)?.title || msg.data}`
  if (a === 'session_init') return msg.data || 'Session initialized'
  return msg.data || a || ''
}

export function systemActionIcon(msg: Message): string {
  return ({
    model_change: 'tabler:switch-horizontal', agent_change: 'tabler:robot',
    title_generated: 'tabler:tag', session_init: 'tabler:rocket',
  } as Record<string, string>)[msg.metadata?.system_action || ''] || 'tabler:info-circle'
}

export function prettyJson(obj: any): string {
  if (obj === null || obj === undefined) return ''
  if (typeof obj === 'string') { try { return JSON.stringify(JSON.parse(obj), null, 2) } catch { return obj } }
  return JSON.stringify(obj, null, 2)
}

export function truncate(text: string, len: number): string {
  if (!text) return ''
  return text.length > len ? text.slice(0, len) + '...' : text
}

export function getThinking(msg: Message): string | null {
  const meta = msg.metadata as any
  if (meta?.thinking && meta.thinking.length > 0) return meta.thinking
  if (meta?.thinking_blocks?.length) {
    return meta.thinking_blocks
      .filter((b: any) => b.type === 'thinking' && b.thinking)
      .map((b: any) => b.thinking)
      .join('\n\n')
  }
  return null
}

export function isDeveloper(msg: Message): boolean {
  return msg.type === 'developer'
}

export function isArtifact(msg: Message): boolean {
  return msg.type === 'artifact'
}
