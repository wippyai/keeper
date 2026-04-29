import { describe, it, expect } from 'vitest'

function extractNamespace(entryId: string): string {
  return entryId.split(':')[0] || ''
}

function extractName(entryId: string): string {
  const idx = entryId.indexOf(':')
  return idx >= 0 ? entryId.slice(idx + 1) : entryId
}

describe('navigation helpers', () => {
  it('extracts namespace from entry ID', () => {
    expect(extractNamespace('app.functions:my_func')).toBe('app.functions')
    expect(extractNamespace('keeper.gov:processes')).toBe('keeper.gov')
    expect(extractNamespace('simple')).toBe('simple')
  })

  it('extracts name from entry ID', () => {
    expect(extractName('app.functions:my_func')).toBe('my_func')
    expect(extractName('keeper.gov:processes')).toBe('processes')
    expect(extractName('simple')).toBe('simple')
  })

  it('handles empty strings', () => {
    expect(extractNamespace('')).toBe('')
    expect(extractName('')).toBe('')
  })

  it('handles IDs with multiple colons', () => {
    expect(extractNamespace('app:ns:extra')).toBe('app')
    expect(extractName('app:ns:extra')).toBe('ns:extra')
  })
})
