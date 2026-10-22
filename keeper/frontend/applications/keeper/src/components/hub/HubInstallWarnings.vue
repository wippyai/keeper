<script setup lang="ts">
import { Icon } from '@iconify/vue'
import type { HubApplyWarning } from '../../api/hub'

defineProps<{ component: string, warnings: HubApplyWarning[] }>()
const emit = defineEmits<{ dismiss: [] }>()
</script>

<template>
  <div class="install-warnings mx-4 mt-2 px-3 py-2 rounded text-[11px] flex items-start gap-2 bg-warn-500/15" role="alert" style="color: var(--p-text-color)">
    <Icon icon="tabler:alert-triangle" class="w-3.5 h-3.5 shrink-0 mt-px" />
    <div class="flex-1">
      <div>Installed {{ component }}, but a post-install step failed. Permissions or other derived state may be out of date.</div>
      <ul class="mt-1 list-disc pl-4">
        <li v-for="(w, i) in warnings" :key="i"><span v-if="w.observer" class="font-mono">{{ w.observer }}: </span>{{ w.message }}</li>
      </ul>
    </div>
    <button aria-label="Dismiss" @click="emit('dismiss')" style="color: var(--p-text-muted-color)"><Icon icon="tabler:x" class="w-3 h-3" /></button>
  </div>
</template>
