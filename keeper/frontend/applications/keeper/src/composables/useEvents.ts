import { ref } from 'vue'
import type { ProxyApiInstance } from '../types'
import { subscribeEvents, unsubscribeEvents } from '../api/events'

// Shared admin-event subscription state. Module-level refs make this a singleton
// across the app shell (which subscribes on visit) and the Activity page (which
// renders the feed and the mute toggle). Subscribing instructs the relay hub to
// join the keeper events bus; muting persists across visits via localStorage so a
// muted admin stays muted until they explicitly unmute.
type Api = ProxyApiInstance['api']

const MUTED_KEY = 'keeper.events.muted'

const subscribed = ref(false)
const muted = ref(localStorage.getItem(MUTED_KEY) === '1')
const pending = ref(false)
const error = ref<string | null>(null)

function errMessage(e: any): string {
  return e?.response?.data?.error || e?.message || 'request failed'
}

// Subscribe unless muted or already subscribed. Idempotent; safe to call on every
// app-shell mount. A non-admin caller is rejected server-side and stays unsubscribed.
async function ensureSubscribed(api: Api): Promise<void> {
  if (muted.value || subscribed.value || pending.value) return
  pending.value = true
  try {
    const res = await subscribeEvents(api)
    subscribed.value = res.success !== false
    error.value = null
  } catch (e: any) {
    error.value = errMessage(e)
  } finally {
    pending.value = false
  }
}

async function mute(api: Api): Promise<void> {
  muted.value = true
  localStorage.setItem(MUTED_KEY, '1')
  if (!subscribed.value) return
  try {
    await unsubscribeEvents(api)
    subscribed.value = false
    error.value = null
  } catch (e: any) {
    error.value = errMessage(e)
  }
}

async function unmute(api: Api): Promise<void> {
  muted.value = false
  localStorage.removeItem(MUTED_KEY)
  await ensureSubscribed(api)
}

export function useEvents() {
  return { subscribed, muted, pending, error, ensureSubscribed, mute, unmute }
}
