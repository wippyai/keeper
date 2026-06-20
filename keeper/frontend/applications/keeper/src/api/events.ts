import type { ProxyApiInstance } from '../types'

// Admin realtime event bus. Subscribing joins the caller's relay hub to the
// keeper events pg group server-side (admin-gated); the hub then fans bus
// broadcasts to this browser under their original topics.
type Api = ProxyApiInstance['api']

export interface SubscribeResponse {
  success: boolean
  subscribed?: boolean
  error?: string
}

// Topics carried over the bus. The hub forwards each broadcast under its own
// topic, so these match the strings passed to instance.on(...).
export const EVENT_TOPICS = {
  changeset: 'keeper.changeset',
  git: 'keeper.git',
  version: 'registry:version',
} as const

export async function subscribeEvents(api: Api): Promise<SubscribeResponse> {
  const { data } = await api.post<SubscribeResponse>('/api/v1/keeper/events/subscribe', {})
  return data
}

export async function unsubscribeEvents(api: Api): Promise<SubscribeResponse> {
  const { data } = await api.post<SubscribeResponse>('/api/v1/keeper/events/unsubscribe', {})
  return data
}
