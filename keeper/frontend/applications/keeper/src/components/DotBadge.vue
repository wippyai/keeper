<template>
  <span :style="dotStyle"></span>
</template>

<script setup>
import { computed } from 'vue';

const props = defineProps({
  color: {
    type: String,
    required: true
  },
  size: {
    type: Number,
    default: 8
  }
});

const dotStyle = computed(() => ({
  display: 'inline-block',
  width: `${props.size}px`,
  height: `${props.size}px`,
  borderRadius: '50%',
  backgroundColor: props.color
}));
</script>
