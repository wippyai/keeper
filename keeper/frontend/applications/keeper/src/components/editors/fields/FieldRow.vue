<script setup lang="ts">
defineProps<{
  label: string
  description?: string
  vertical?: boolean
}>()
</script>

<template>
  <div class="field-row" :class="{ 'field-row--vertical': vertical }">
    <div class="field-row__label">
      <span class="text-[11px]" style="color: var(--p-text-muted-color)">{{ label }}</span>
      <span v-if="description" class="text-[9px] block mt-0.5" style="color: var(--p-text-muted-color); opacity: 0.6">{{ description }}</span>
    </div>
    <div class="field-row__value">
      <slot />
    </div>
  </div>
</template>

<style scoped>
.field-row {
  display: flex;
  align-items: flex-start;
  gap: 8px;
  padding: 4px 0;
}
.field-row__label {
  flex-shrink: 0;
  width: 100px;
  padding-top: 4px;
}
.field-row__value {
  flex: 1;
  min-width: 0;
}
.field-row--vertical {
  flex-direction: column;
}
.field-row--vertical .field-row__label {
  width: auto;
  padding-top: 0;
}
</style>
