<script setup lang="ts">
import { computed } from 'vue'
import Message from 'primevue/message'
import type { HubRequestError } from '../../api/hub'

const props = defineProps<{error: string | HubRequestError}>()
const failure = computed(() => typeof props.error === 'string' ? {message: props.error} : props.error)
</script>

<template>
  <Message severity="error" :closable="false" class="mt-2">
    <span v-if="failure.code">{{ failure.code }}: </span>{{ failure.message }}
    <slot />
    <details v-if="failure.details != null">
      <summary>Error details</summary>
      <pre class="whitespace-pre-wrap break-words text-[11px]">{{ JSON.stringify(failure.details, null, 2) }}</pre>
    </details>
  </Message>
</template>
