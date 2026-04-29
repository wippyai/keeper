import type { InjectionKey } from 'vue'
import type { HostApi, ProxyApiInstance, WippyConfig } from './types'

export type OnSubscription = (
  pattern: string,
  callback: (event: { path?: string; message?: unknown; data?: unknown }) => void,
) => (() => void) | void

export const HOST_API = Symbol('host_api') as InjectionKey<HostApi>
export const AXIOS_INSTANCE = Symbol('axios') as InjectionKey<ProxyApiInstance['api']>
export const WIPPY_INSTANCE = Symbol('proxy') as InjectionKey<ProxyApiInstance>
export const WIPPY_CONFIG = Symbol('config') as InjectionKey<WippyConfig>
export const ON_SUBSCRIPTION = Symbol('on_subscription') as InjectionKey<OnSubscription>
