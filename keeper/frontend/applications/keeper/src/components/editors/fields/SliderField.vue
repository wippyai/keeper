<script setup lang="ts">
const model = defineModel<number>({ default: 0 })
const props = defineProps<{
  min: number
  max: number
  step?: number
  formatValue?: (v: number) => string
}>()

function display(): string {
  if (props.formatValue) return props.formatValue(model.value)
  return String(model.value)
}
</script>

<template>
  <div class="sl">
    <input type="range" :value="model" @input="model = Number(($event.target as HTMLInputElement).value)" :min="min" :max="max" :step="step || 1" class="sl-range" />
    <span class="sl-val">{{ display() }}</span>
  </div>
</template>

<style scoped>
.sl { display: flex; align-items: center; gap: 6px; }
.sl-range {
  flex: 1; -webkit-appearance: none; appearance: none;
  height: 3px; border-radius: 2px; background: var(--p-surface-300); outline: none;
}
.sl-range::-webkit-slider-thumb {
  -webkit-appearance: none; width: 10px; height: 10px; border-radius: 50%;
  background: var(--p-primary-color); cursor: pointer;
}
.sl-range::-moz-range-thumb {
  width: 10px; height: 10px; border-radius: 50%;
  background: var(--p-primary-color); cursor: pointer; border: none;
}
.sl-val {
  font-size: 10px; font-family: monospace; color: var(--p-primary-color);
  min-width: 32px; text-align: right; padding: 1px 4px; border-radius: 3px;
  background: rgba(245,158,11,0.1);
}
</style>
