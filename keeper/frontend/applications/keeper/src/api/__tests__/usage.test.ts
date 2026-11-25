import { describe, expect, it, vi } from 'vitest'
import { getUsageSummary } from '../usage'

describe('Keeper dashboard usage', () => {
  it('returns no usage when the summary endpoint is absent', async () => {
    const get = vi.fn().mockResolvedValue({ data: { success: true, entries: [] } })
    const api = { get } as unknown as Parameters<typeof getUsageSummary>[0]

    await expect(getUsageSummary(api)).resolves.toBeNull()
    expect(get).toHaveBeenCalledTimes(1)
    expect(get).toHaveBeenCalledWith('/api/v1/keeper/registry/entries', {
      params: { limit: 200, offset: 0, namespace: 'keeper.usage.api', kind: 'http.endpoint' },
    })
  })

  it('reads the configured period when the summary endpoint is installed', async () => {
    const response = { success: true, summary: { total_tokens: 123 } }
    const get = vi.fn().mockResolvedValueOnce({
      data: { success: true, entries: [{ id: 'keeper.usage.api:get_summary.endpoint' }] },
    }).mockResolvedValueOnce({ data: response })
    const api = { get } as unknown as Parameters<typeof getUsageSummary>[0]

    await expect(getUsageSummary(api, 'custom', 10, 20)).resolves.toBe(response)
    expect(get).toHaveBeenLastCalledWith('/api/v1/keeper/usage/summary', {
      params: { period: 'custom', start_time: 10, end_time: 20 },
    })
  })
})
