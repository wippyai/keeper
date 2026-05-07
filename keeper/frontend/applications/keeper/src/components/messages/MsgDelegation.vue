<script setup lang="ts">
import { ref } from 'vue'
import { Icon } from '@iconify/vue'
import { useRouter } from 'vue-router'
import type { Message } from '../../api/sessions'
import { truncate } from './msg-utils'
import MsgHeader from './MsgHeader.vue'
import MarkdownContent from '../shared/MarkdownContent.vue'

const props = defineProps<{ msg: Message }>()
const router = useRouter()
const expanded = ref(false)
const meta = props.msg.metadata as any
const result = meta?.result
const dataflowId = result?.dataflow_id || meta?.dataflow_id
const resultData = typeof result?.data === 'string' ? result.data : null
</script>

<template>
  <div>
    <MsgHeader :msg="msg" />

    <div v-if="dataflowId" class="mb-2 text-[10px]">
      <button class="font-mono flex items-center gap-1" style="color: var(--p-primary-color)" @click.stop="router.push('/dataflow/' + dataflowId)">
        <Icon icon="tabler:git-merge" class="w-3 h-3" />
        {{ dataflowId }}
      </button>
    </div>

    <MarkdownContent v-if="resultData" :content="expanded ? resultData : truncate(resultData, 500)" :max-height="expanded ? 'none' : '240px'" />

    <button v-if="(resultData?.length || 0) > 500" class="text-[11px] mt-1.5 flex items-center gap-1" style="color: var(--p-primary-color)" @click="expanded = !expanded">
      <Icon :icon="expanded ? 'tabler:chevron-up' : 'tabler:chevron-down'" class="w-3 h-3" />
      {{ expanded ? 'Collapse' : `Expand (${(resultData!.length / 1000).toFixed(1)}K)` }}
    </button>
  </div>
</template>
