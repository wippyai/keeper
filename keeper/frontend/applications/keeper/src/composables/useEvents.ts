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
// app-shell mount and on every ws (re)connect. The relay user hub is recreated
// on each reconnect and does not retain group membership, so a fresh subscribe
// must run each time the hub comes up. Pass force=true from the connect handler
// to re-join even when a stale `subscribed` flag is still set. The server returns
// subscribed=false with "no active realtime connection" if the hub is not yet
// registered; we treat that as not-subscribed so the next connect retries.
async function ensureSubscribed(api: Api, force = false): Promise<void> {
  if (muted.value || pending.value) return
  if (subscribed.value && !force) return
  pending.value = true
  try {
    const res = await subscribeEvents(api)
    subscribed.value = res.subscribed === true
    error.value = null
  } catch (e: any) {
    subscribed.value = false
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
  await ensureSubscribed(api, true)
}

export function useEvents() {
  return { subscribed, muted, pending, error, ensureSubscribed, mute, unmute }
}
