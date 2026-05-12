<template>
  <span :style="dotStyle"></span>
</template>

<script setup lang="ts">
import { computed } from 'vue'

const props = withDefaults(defineProps<{
  color: string
  size?: number
}>(), {
  size: 8,
})

const dotStyle = computed(() => ({
  display: 'inline-block',
  width: `${props.size}px`,
  height: `${props.size}px`,
  borderRadius: '50%',
  backgroundColor: props.color,
}))
</script>
