export function entryName(id: string): string {
  const idx = id.indexOf(':')
  return idx >= 0 ? id.slice(idx + 1) : id
}

export function entryNamespace(id: string): string {
  const idx = id.indexOf(':')
  return idx >= 0 ? id.slice(0, idx) : id
}

export function formatTokens(num: number): string {
  if (!num || num === 0) return '0'
  if (num >= 1_000_000) return (num / 1_000_000).toFixed(1) + 'M'
  if (num >= 1_000) return (num / 1_000).toFixed(1) + 'K'
  return num.toString()
}

export function prettyJson(obj: any): string {
  if (obj === null || obj === undefined) return ''
  if (typeof obj === 'string') {
    try { return JSON.stringify(JSON.parse(obj), null, 2) }
    catch { return obj }
  }
  return JSON.stringify(obj, null, 2)
}
