import { describe, it, expect, vi } from 'vitest'
import { getGovernanceConfig, kindColor, kindIcon, updateGovernanceConfig } from '../registry'

describe('kindColor', () => {
  it('returns mapped colors for known kinds', () => {
    expect(kindColor('function.lua')).toBe('var(--p-warn-500)')
    expect(kindColor('http.endpoint')).toBe('var(--p-info-500)')
    expect(kindColor('registry.entry')).toBe('var(--p-accent-500)')
    expect(kindColor('db.sql.sqlite')).toBe('var(--p-accent-500)')
  })

  it('returns default color for unknown kinds', () => {
    expect(kindColor('unknown.kind')).toBe('var(--p-text-muted-color)')
    expect(kindColor('')).toBe('var(--p-text-muted-color)')
  })

  it('uses metaType when provided', () => {
    expect(kindColor('registry.entry', 'agent.gen1')).toBe('var(--p-warn-500)')
    expect(kindColor('registry.entry', 'llm.model')).toBe('var(--p-accent-500)')
    expect(kindColor('registry.entry', 'tool')).toBe('var(--p-info-500)')
  })

  it('falls back to kind when metaType has no mapping', () => {
    expect(kindColor('function.lua', 'unknown.meta')).toBe('var(--p-warn-500)')
  })
})

describe('kindIcon', () => {
  it('returns mapped icons for known kinds', () => {
    expect(kindIcon('function.lua')).toBe('tabler:code')
    expect(kindIcon('http.endpoint')).toBe('tabler:api')
    expect(kindIcon('ns.definition')).toBe('tabler:package')
    expect(kindIcon('env.variable')).toBe('tabler:variable')
  })

  it('returns default icon for unknown kinds', () => {
    expect(kindIcon('unknown.kind')).toBe('tabler:circle')
    expect(kindIcon('')).toBe('tabler:circle')
  })

  it('uses metaType when provided', () => {
    expect(kindIcon('registry.entry', 'agent.gen1')).toBe('tabler:robot')
    expect(kindIcon('registry.entry', 'llm.model')).toBe('tabler:brain')
    expect(kindIcon('registry.entry', 'tool')).toBe('tabler:tool')
    expect(kindIcon('registry.entry', 'view.page')).toBe('tabler:browser')
  })

  it('falls back to kind when metaType has no mapping', () => {
    expect(kindIcon('function.lua', 'unknown.meta')).toBe('tabler:code')
  })
})

describe('governance config API', () => {
  it('fetches managed namespace config from the sync config endpoint', async () => {
    const response = { success: true, managed_namespaces: ['app', 'keeper'] }
    const api = { get: vi.fn().mockResolvedValue({ data: response }) } as any

    await expect(getGovernanceConfig(api)).resolves.toBe(response)
    expect(api.get).toHaveBeenCalledWith('/api/v1/keeper/sync/config')
  })

  it('updates managed namespaces through the sync config endpoint', async () => {
    const response = { success: true, managed_namespaces: ['app', 'keeper', 'userspace'] }
    const api = { put: vi.fn().mockResolvedValue({ data: response }) } as any

    await expect(updateGovernanceConfig(api, ['app', 'keeper', 'userspace'])).resolves.toBe(response)
    expect(api.put).toHaveBeenCalledWith('/api/v1/keeper/sync/config', {
      managed_namespaces: ['app', 'keeper', 'userspace'],
    })
  })
})
