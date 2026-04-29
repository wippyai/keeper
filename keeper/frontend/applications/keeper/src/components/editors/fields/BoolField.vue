<script setup lang="ts">
const model = defineModel<boolean>({ default: false })
defineProps<{
  readonly?: boolean
}>()
</script>

<template>
  <button
    v-if="!readonly"
    class="ed-toggle"
    :class="{ 'ed-toggle--on': model }"
    @click="model = !model"
  >
    <span class="ed-toggle__knob"></span>
  </button>
  <span v-else class="text-[11px]" :class="{ 'text-success-500': model }" :style="{ color: model ? undefined : 'var(--p-text-muted-color)' }">{{ model ? 'true' : 'false' }}</span>
</template>

<style scoped>
.ed-toggle {
  position: relative;
  width: 28px;
  height: 16px;
  border-radius: 8px;
  background: var(--p-surface-300);
  border: none;
  cursor: pointer;
  transition: background 0.15s;
}
.ed-toggle--on {
  background: var(--p-primary);
}
.ed-toggle__knob {
  position: absolute;
  top: 2px;
  left: 2px;
  width: 12px;
  height: 12px;
  border-radius: 50%;
  background: white;
  transition: transform 0.15s;
}
.ed-toggle--on .ed-toggle__knob {
  transform: translateX(12px);
}
</style>
