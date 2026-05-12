import { useEvents, useProps } from '@wippy-fe/webcomponent-vue'
import type { ComponentProps } from './types.ts'

export interface Events {
  load: undefined
  unload: undefined
  error: { message: string, error: unknown }
  invalid: { message: string }
  // Editor mode only — fired on every content change with the full buffer.
  change: { value: string }
}

export const useComponentProps = () => useProps<ComponentProps>()
export const useComponentEvents = () => useEvents<Events>()
