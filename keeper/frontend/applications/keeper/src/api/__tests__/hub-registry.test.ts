import { describe, expect, it, vi } from 'vitest'
import { DEFAULT_HUB_URL, getHubRegistry, hubSiteLabel, hubSiteUrl } from '../hub'

describe('hub registry', () => {
  it('uses the registry that the runtime reports', async () => {
    const api = { get: vi.fn().mockResolvedValue({ data: { success: true, registry: 'https://hub.stage.wippy.ai' } }) } as any

    await expect(getHubRegistry(api)).resolves.toBe('https://hub.stage.wippy.ai/')
    expect(api.get).toHaveBeenCalledWith('/api/v1/keeper/hub/registry')
  })

  it('falls back to the public hub when the request fails', async () => {
    const api = { get: vi.fn().mockRejectedValue(new Error('403')) } as any

    await expect(getHubRegistry(api)).resolves.toBe(DEFAULT_HUB_URL)
  })

  it('falls back to the public hub for an empty or invalid registry', () => {
    expect(hubSiteUrl('')).toBe(DEFAULT_HUB_URL)
    expect(hubSiteUrl(undefined)).toBe(DEFAULT_HUB_URL)
    expect(hubSiteUrl('javascript:alert(1)')).toBe(DEFAULT_HUB_URL)
    expect(hubSiteUrl('https://hub.example.com/')).toBe('https://hub.example.com/')
  })

  it('labels the link with the registry host', () => {
    expect(hubSiteLabel('https://hub.stage.wippy.ai/')).toBe('hub.stage.wippy.ai')
    expect(hubSiteLabel(DEFAULT_HUB_URL)).toBe('hub.wippy.ai')
  })
})
