export type Mode = 'editor' | 'diff'
export type ThemeName = 'auto' | 'keeper-dark' | 'keeper-light'

export interface ComponentProps {
  mode?: Mode
  language?: string
  value?: string
  baseline?: string
  current?: string
  readonly?: boolean
  theme?: ThemeName
  'min-height'?: number
}
