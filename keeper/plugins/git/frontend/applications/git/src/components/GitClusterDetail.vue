<script setup lang="ts">
import { Icon } from '@iconify/vue'
import type { ClusterSummary, ClusterFull, ClusterChange, Decision, Importance, Verdict, Severity, RecState } from '../composables/useGit'
import { importanceTone, verdictTone, sevTone, recStateTone, fmtChanges } from '../tones'

export type SelectedCluster = ClusterSummary & Partial<Pick<ClusterFull, 'change_ids' | 'changes' | 'changeset_ids' | 'primary_changeset_id' | 'is_suspect' | 'recommendations'>>

defineProps<{
  cluster: SelectedCluster
  changes: ClusterChange[]
  blocking: boolean
  pushableReady: number
  expandedRecs: boolean
  explaining: string | null
  explanations: Record<string, string>
}>()

const emit = defineEmits<{
  (e: 'decide', id: string, decision: Decision): void
  (e: 'ack-rec', recId: string, state: RecState): void
  (e: 'explain-rec', recId: string): void
  (e: 'open-split'): void
  (e: 'open-diff', path: string): void
  (e: 'push-confirm'): void
  (e: 'update:expandedRecs', v: boolean): void
}>()
</script>

<template>
  <section class="overflow-y-auto" style="background: var(--p-surface-0)">
    <article class="p-6">
      <div class="flex items-center gap-2 mb-2">
        <span class="w-2 h-2 rounded-full"
          :style="{ background: importanceTone[cluster.importance as Importance].dot }" />
        <span class="text-[11px] opacity-70">{{ importanceTone[cluster.importance as Importance].word }}</span>
        <span class="text-[11px] opacity-50">·</span>
        <span class="text-[11px] opacity-70">{{ fmtChanges(cluster.change_count) }}</span>
        <span v-if="cluster.stats" class="text-[11px] opacity-50">·</span>
        <span v-if="cluster.stats" class="text-[11px] opacity-70">
          {{ cluster.stats.namespaces?.length || 0 }} namespace{{ (cluster.stats.namespaces?.length || 0) === 1 ? '' : 's' }}
        </span>
        <span class="ml-auto text-[10px] opacity-50 font-mono">{{ cluster.id }}</span>
      </div>
      <h2 class="text-[20px] font-semibold mb-2">{{ cluster.title }}</h2>
      <p class="text-[13px] opacity-85 leading-relaxed mb-4">{{ cluster.plain_summary }}</p>

      <!-- verdict band -->
      <div class="rounded-lg p-3 mb-4 flex items-center gap-3"
        :style="{ background: verdictTone[cluster.verdict as Verdict].bg,
                  border: '1px solid ' + verdictTone[cluster.verdict as Verdict].border }">
        <Icon :icon="verdictTone[cluster.verdict as Verdict].icon" class="w-5 h-5"
          :style="{ color: verdictTone[cluster.verdict as Verdict].color }" />
        <div>
          <div class="text-[12px] font-semibold"
            :style="{ color: verdictTone[cluster.verdict as Verdict].color }">
            {{ verdictTone[cluster.verdict as Verdict].phrase }}
          </div>
          <div class="text-[11px] opacity-80">{{ cluster.verdict_text }}</div>
        </div>
      </div>

      <!-- recommendations -->
      <div v-if="cluster.recommendations" class="mb-5">
        <h3 class="text-[10px] font-semibold uppercase tracking-wide opacity-60 mb-2 flex items-center gap-1.5">
          <Icon icon="tabler:sparkles" class="w-3 h-3" />
          AI recommendations
          <button @click="emit('update:expandedRecs', !expandedRecs)"
            class="ml-auto text-[10px] opacity-60 hover:opacity-100">
            {{ expandedRecs ? 'Collapse' : 'Expand' }}
          </button>
        </h3>
        <ul v-if="expandedRecs" class="space-y-1.5">
          <li v-for="r in cluster.recommendations" :key="r.id"
            class="rounded p-2.5 flex items-start gap-2"
            :style="{ background: sevTone[r.severity as Severity].bg,
                      border: '1px solid var(--p-surface-200)' }">
            <Icon :icon="sevTone[r.severity as Severity].icon" class="w-3.5 h-3.5 shrink-0 mt-0.5"
              :style="{ color: sevTone[r.severity as Severity].color }" />
            <div class="flex-1 min-w-0">
              <div class="text-[12px]">{{ r.text }}</div>
              <div v-if="r.fix_hint" class="text-[11px] opacity-70 mt-0.5">↳ {{ r.fix_hint }}</div>
              <div v-if="r.state === 'open'" class="flex gap-1 mt-2 flex-wrap">
                <button @click="emit('explain-rec', r.id)" :disabled="explaining === r.id"
                  class="text-[10px] px-2 py-0.5 rounded flex items-center gap-1 disabled:opacity-60 bg-accent-500/10 text-accent-500">
                  <Icon :icon="explaining === r.id ? 'tabler:loader-2' : 'tabler:sparkles'"
                    :class="explaining === r.id ? 'w-3 h-3 animate-spin' : 'w-3 h-3'" />
                  {{ explaining === r.id ? 'Asking AI…' : 'Explain' }}
                </button>
                <button @click="emit('ack-rec', r.id, 'acknowledged')"
                  class="text-[10px] px-2 py-0.5 rounded flex items-center gap-1 bg-info-500/10 text-info-500">
                  <Icon icon="tabler:eye-check" class="w-3 h-3" /> Acknowledge
                </button>
                <button @click="emit('ack-rec', r.id, 'fixed')"
                  class="text-[10px] px-2 py-0.5 rounded flex items-center gap-1 bg-success-500/10 text-success-500">
                  <Icon icon="tabler:check" class="w-3 h-3" /> Mark fixed
                </button>
              </div>
              <div v-if="r.detail || explanations[r.id]" class="mt-2 p-2.5 rounded text-[11px] leading-relaxed whitespace-pre-wrap border-l-[3px] border-accent-500"
                style="background: var(--p-surface-100)">
                <div class="text-[9px] uppercase tracking-wide opacity-60 mb-1 flex items-center gap-1">
                  <Icon icon="tabler:sparkles" class="w-3 h-3" /> AI explanation
                </div>{{ r.detail || explanations[r.id] }}
              </div>
            </div>
            <span class="text-[9px] font-semibold uppercase px-1 py-0.5 rounded shrink-0"
              :style="{ background: recStateTone[r.state as RecState].bg,
                        color: recStateTone[r.state as RecState].color }">
              {{ recStateTone[r.state as RecState].label }}
            </span>
          </li>
        </ul>
      </div>

      <!-- changes -->
      <div v-if="changes.length > 0" class="mb-5">
        <h3 class="text-[10px] font-semibold uppercase tracking-wide opacity-60 mb-2 flex items-center gap-1.5">
          <Icon icon="tabler:list" class="w-3 h-3" />
          Changes ({{ changes.length }})
          <span class="opacity-50 ml-auto text-[9px]">click a row for diff</span>
        </h3>
        <div class="rounded border" style="border-color: var(--p-content-border-color)">
          <div v-for="c in changes.slice(0, 100)" :key="c.change_id"
            @click="emit('open-diff', c.path)"
            class="px-3 py-1.5 border-b last:border-0 flex items-center gap-2 cursor-pointer hover:bg-[var(--p-surface-100)]"
            style="border-color: var(--p-content-border-color)">
            <span class="text-[9px] font-semibold uppercase px-1 py-0.5 rounded shrink-0"
              :class="{
                'bg-success-500/10 text-success-500': c.op === 'create',
                'bg-danger-500/10 text-danger-500': c.op === 'delete',
                'bg-info-500/10 text-info-500': c.op !== 'create' && c.op !== 'delete',
              }">
              {{ c.op[0].toUpperCase() }}
            </span>
            <Icon :icon="c.category === 'registry' ? 'tabler:database' : 'tabler:file'"
              class="w-3 h-3 opacity-50 shrink-0" />
            <span class="font-mono text-[11px] flex-1 truncate">{{ c.path }}</span>
            <span class="text-[10px] shrink-0 text-success-500" v-if="c.added">+{{ c.added }}</span>
            <span class="text-[10px] shrink-0 text-danger-500" v-if="c.removed">−{{ c.removed }}</span>
          </div>
          <div v-if="changes.length > 100"
            class="px-3 py-1.5 text-[10px] opacity-60">
            + {{ changes.length - 100 }} more
          </div>
        </div>
      </div>

      <!-- action bar -->
      <div class="sticky bottom-0 -mx-6 px-6 py-3 border-t flex items-center gap-2"
        style="border-color: var(--p-content-border-color); background: var(--p-surface-0)">
        <template v-if="cluster.decision === 'pending'">
          <button @click="emit('decide', cluster.id, 'approved')" :disabled="blocking"
            class="px-4 py-2 rounded-lg text-[12px] font-medium flex items-center gap-1.5 disabled:opacity-40 disabled:cursor-not-allowed bg-success-500 text-white">
            <Icon icon="tabler:check" class="w-3.5 h-3.5" /> Mark ready
          </button>
          <button @click="emit('open-split')"
            class="px-4 py-2 rounded-lg text-[12px] font-medium flex items-center gap-1.5"
            style="background: var(--p-surface-200)">
            <Icon icon="tabler:arrow-split" class="w-3.5 h-3.5" /> Split…
          </button>
          <button @click="emit('decide', cluster.id, 'skipped')"
            class="px-4 py-2 rounded-lg text-[12px] flex items-center gap-1.5"
            style="background: var(--p-surface-200)">
            <Icon icon="tabler:archive" class="w-3.5 h-3.5" /> Hide
          </button>
          <span v-if="blocking" class="text-[11px] ml-2 text-danger-500">
            Resolve blocking issue first
          </span>
        </template>
        <template v-else-if="cluster.decision === 'approved'">
          <span class="text-[11px] flex items-center gap-1.5 text-success-500">
            <Icon icon="tabler:circle-check" class="w-3.5 h-3.5" />
            Marked ready — push from header when ready to ship
          </span>
          <button v-if="cluster.pushable" @click="emit('push-confirm')"
            class="ml-auto px-4 py-2 rounded-lg text-[12px] font-medium flex items-center gap-1.5 bg-success-500 text-white">
            <Icon icon="tabler:upload" class="w-3.5 h-3.5" /> Push all {{ pushableReady }}
          </button>
          <span v-else class="ml-auto text-[11px] opacity-60">
            {{ cluster.push_blockers?.[0] || 'Review-only cluster' }}
          </span>
          <button @click="emit('decide', cluster.id, 'pending')"
            class="px-4 py-2 rounded-lg text-[12px]" style="background: var(--p-surface-200)">
            Unmark
          </button>
        </template>
        <template v-else>
          <button @click="emit('decide', cluster.id, 'pending')"
            class="px-4 py-2 rounded-lg text-[12px]" style="background: var(--p-surface-200)">
            Move back to pending
          </button>
        </template>
      </div>
    </article>
  </section>
</template>
