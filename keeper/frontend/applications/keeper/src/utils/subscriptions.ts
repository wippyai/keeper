export type Unsubscribe = (() => void) | void

export interface SubscriptionHandle {
  remove(): void
}

interface SubscriptionEntry {
  token: symbol
  unsubscribe: () => void
}

/** Owns replaceable event subscriptions and makes teardown idempotent. */
export class SubscriptionRegistry {
  private readonly subscriptions = new Map<string, SubscriptionEntry>()

  replace(key: string, subscribe: () => Unsubscribe): SubscriptionHandle {
    this.remove(key)
    const token = Symbol(key)
    const unsubscribe = subscribe()
    if (typeof unsubscribe === 'function') this.subscriptions.set(key, { token, unsubscribe })
    return {
      remove: () => {
        if (this.subscriptions.get(key)?.token === token) this.remove(key)
      },
    }
  }

  remove(key: string): void {
    const entry = this.subscriptions.get(key)
    if (!entry) return
    this.subscriptions.delete(key)
    entry.unsubscribe()
  }

  clear(): void {
    for (const key of [...this.subscriptions.keys()]) this.remove(key)
  }
}
