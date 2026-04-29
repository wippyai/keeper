import { ref, type Ref } from 'vue'

export interface UserInfo {
  id: string
  name?: string
  email?: string
  avatar?: string
}

export type UserResolver = (userId: string) => Promise<UserInfo | null>

const resolver: Ref<UserResolver | null> = ref(null)
const cache = new Map<string, UserInfo>()

export function setUserResolver(fn: UserResolver) {
  resolver.value = fn
  cache.clear()
}

export async function resolveUser(userId: string): Promise<UserInfo> {
  if (cache.has(userId)) return cache.get(userId)!

  if (resolver.value) {
    try {
      const info = await resolver.value(userId)
      if (info) {
        cache.set(userId, info)
        return info
      }
    } catch {
      // fall through to default
    }
  }

  const fallback: UserInfo = { id: userId, name: userId }
  cache.set(userId, fallback)
  return fallback
}

export function displayName(info: UserInfo): string {
  return info.name || info.email || info.id || 'anonymous'
}
