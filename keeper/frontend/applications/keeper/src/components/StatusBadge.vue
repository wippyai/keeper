<template>
  <div class="inline-flex items-center space-x-2 px-2 py-1 rounded-md">
    <span 
      class="w-1.5 h-1.5 rounded-full" 
      :style="{ backgroundColor: dotColor }"
    ></span>
    <span>{{ label }}</span>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'

interface Props {
  status: 'ok' | 'warn' | 'error'
  label: string
}

const props = defineProps<Props>()

const dotColor = computed(() => {
  switch (props.status) {
    case 'ok':
      return 'var(--p-success-500)'
    case 'warn':
      return 'var(--p-warn-500)'
    case 'error':
      return 'var(--p-danger-500)'
    default:
      return 'var(--p-success-500)'
  }
})
</script>
