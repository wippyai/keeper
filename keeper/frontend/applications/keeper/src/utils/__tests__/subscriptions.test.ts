import { describe, expect, it, vi } from 'vitest'
import { SubscriptionRegistry } from '../subscriptions'

describe('SubscriptionRegistry', () => {
  it('disposes a previous subscription when a key is replaced', () => {
    const registry = new SubscriptionRegistry()
    const first = vi.fn()
    const second = vi.fn()

    registry.replace('build-1', () => first)
    registry.replace('build-1', () => second)

    expect(first).toHaveBeenCalledOnce()
    expect(second).not.toHaveBeenCalled()

    registry.remove('build-1')
    registry.remove('build-1')
    expect(second).toHaveBeenCalledOnce()
  })

  it('clears all active subscriptions exactly once', () => {
    const registry = new SubscriptionRegistry()
    const first = vi.fn()
    const second = vi.fn()
    registry.replace('first', () => first)
    registry.replace('second', () => second)

    registry.clear()
    registry.clear()

    expect(first).toHaveBeenCalledOnce()
    expect(second).toHaveBeenCalledOnce()
  })

  it('does not let a stale handle remove its replacement', () => {
    const registry = new SubscriptionRegistry()
    const first = vi.fn()
    const second = vi.fn()
    const stale = registry.replace('build-1', () => first)
    const current = registry.replace('build-1', () => second)

    stale.remove()
    expect(second).not.toHaveBeenCalled()

    current.remove()
    expect(second).toHaveBeenCalledOnce()
  })
})
