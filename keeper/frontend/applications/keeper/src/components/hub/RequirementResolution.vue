<script setup lang="ts">
import type { HubPlanRequirement } from '../../api/hub'
import { valueText } from './requirementValue'

defineProps<{
  requirement: Pick<HubPlanRequirement, 'value_source' | 'choice_reason' | 'resolution_error'>
  suggestion?: HubPlanRequirement
}>()
defineEmits<{accept: []; reject: []; edit: []}>()
</script>

<template>
  <div v-if="suggestion" class="mt-1 text-[11px]" style="color: var(--p-text-color)">
    <span class="font-semibold">AI</span> · Pending review: <span class="mono">{{ valueText(suggestion.value) }}</span>
    <p>{{ suggestion.choice_reason }}</p>
    <div class="flex gap-2">
      <button type="button" class="ghost-sm" @click="$emit('accept')">Accept suggestion</button>
      <button type="button" class="ghost-sm" @click="$emit('reject')">Reject suggestion</button>
      <button type="button" class="ghost-sm" @click="$emit('edit')">Edit suggestion</button>
    </div>
  </div>
  <p v-else-if="requirement.choice_reason" class="mt-1 text-[10px]" style="color: var(--p-text-muted-color)">
    <span class="font-semibold">AI</span> · Model suggestion (accepted): {{ requirement.choice_reason }}
  </p>
  <p v-if="requirement.resolution_error" role="alert" class="mt-1 text-[10px]" style="color: var(--p-danger-500)">
    {{ requirement.resolution_error.code }}: {{ requirement.resolution_error.message }} Choose a value manually.
  </p>
</template>
