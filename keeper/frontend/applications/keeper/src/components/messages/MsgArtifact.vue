<script setup lang="ts">
import { Icon } from '@iconify/vue'
import { useRouter } from 'vue-router'
import type { Message } from '../../api/sessions'
import { formatDate } from '../../api/sessions'

const props = defineProps<{ msg: Message }>()
const router = useRouter()
const artifactId = (props.msg.metadata as any)?.artifact_id
</script>

<template>
  <div class="flex items-center gap-2 text-[11px] py-1 px-3 rounded" style="background: color-mix(in srgb, var(--p-info-500) 5%, transparent); border: 1px solid color-mix(in srgb, var(--p-info-500) 10%, transparent)">
    <Icon icon="tabler:file-code" class="w-3.5 h-3.5 shrink-0 text-info-500" />
    <span style="color: var(--p-text-muted-color)">Artifact</span>
    <span v-if="artifactId" class="font-mono text-info-500">{{ artifactId.slice(0, 20) }}...</span>
    <button v-if="artifactId" class="ml-auto flex items-center gap-1" style="color: var(--p-primary)" @click="router.push('/dataflow/' + artifactId)">
      <Icon icon="tabler:external-link" class="w-3 h-3" /> View
    </button>
    <span class="text-[10px] shrink-0" style="color: var(--p-text-muted-color)">{{ formatDate(msg.date) }}</span>
  </div>
</template>
