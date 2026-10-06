<script setup lang="ts">
import type { HubPlanRequirement } from '../../api/hub'

defineProps<{requirement: Pick<HubPlanRequirement, 'choice_reason' | 'resolution_error'>}>()
</script>

<template>
  <p v-if="requirement.choice_reason" class="mt-1 text-[10px]" style="color: var(--p-text-muted-color)">
    Model suggestion: {{ requirement.choice_reason }}
  </p>
  <p v-if="requirement.resolution_error" class="mt-1 text-[10px]" style="color: var(--p-danger-500)">
    {{ requirement.resolution_error.code }}: {{ requirement.resolution_error.message }}
  </p>
</template>
