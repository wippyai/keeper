import type { Importance, Verdict, Severity, RecState } from './composables/useGit'

export const importanceTone: Record<Importance, { dot: string; word: string }> = {
  critical: { dot: 'var(--p-danger-500)', word: 'Important' },
  high:     { dot: 'var(--p-warn-500)', word: 'Worth attention' },
  normal:   { dot: 'var(--p-info-500)', word: 'Routine' },
  cleanup:  { dot: 'var(--p-text-muted-color)', word: 'Cleanup' },
  suspect:  { dot: 'var(--p-text-muted-color)', word: 'Suspect' },
}

export const verdictTone: Record<Verdict, { color: string; bg: string; border: string; icon: string; phrase: string }> = {
  ready: {
    color: 'var(--p-success-500)',
    bg: 'color-mix(in srgb, var(--p-success-500) 7%, transparent)',
    border: 'color-mix(in srgb, var(--p-success-500) 20%, transparent)',
    icon: 'tabler:circle-check',
    phrase: 'Looks ready',
  },
  closer_look: {
    color: 'var(--p-warn-500)',
    bg: 'color-mix(in srgb, var(--p-warn-500) 7%, transparent)',
    border: 'color-mix(in srgb, var(--p-warn-500) 20%, transparent)',
    icon: 'tabler:zoom-question',
    phrase: 'Closer look',
  },
  do_not_push: {
    color: 'var(--p-danger-500)',
    bg: 'color-mix(in srgb, var(--p-danger-500) 7%, transparent)',
    border: 'color-mix(in srgb, var(--p-danger-500) 20%, transparent)',
    icon: 'tabler:hand-stop',
    phrase: "Don't push yet",
  },
}

export const sevTone: Record<Severity, { color: string; icon: string; bg: string; label: string }> = {
  info:  { color: 'var(--p-text-muted-color)', icon: 'tabler:info-circle',    bg: 'transparent',                                                  label: 'fyi' },
  warn:  { color: 'var(--p-warn-500)',         icon: 'tabler:alert-triangle', bg: 'color-mix(in srgb, var(--p-warn-500) 10%, transparent)',       label: 'warn' },
  block: { color: 'var(--p-danger-500)',       icon: 'tabler:hand-stop',      bg: 'color-mix(in srgb, var(--p-danger-500) 10%, transparent)',     label: 'block' },
}

export const recStateTone: Record<RecState, { color: string; bg: string; label: string; icon: string }> = {
  open: {
    color: 'var(--p-warn-500)',
    bg: 'color-mix(in srgb, var(--p-warn-500) 13%, transparent)',
    label: 'open',
    icon: 'tabler:alert-circle',
  },
  acknowledged: {
    color: 'var(--p-info-500)',
    bg: 'color-mix(in srgb, var(--p-info-500) 13%, transparent)',
    label: 'acknowledged',
    icon: 'tabler:eye-check',
  },
  fixed: {
    color: 'var(--p-success-500)',
    bg: 'color-mix(in srgb, var(--p-success-500) 13%, transparent)',
    label: 'fixed',
    icon: 'tabler:check',
  },
  split: {
    color: 'var(--p-text-muted-color)',
    bg: 'color-mix(in srgb, var(--p-text-muted-color) 13%, transparent)',
    label: 'split off',
    icon: 'tabler:arrow-split',
  },
}

export function fmtChanges(n: number): string {
  return n + ' change' + (n === 1 ? '' : 's')
}

export function errorMessage(value: unknown): string {
  return value instanceof Error ? value.message : String(value)
}
