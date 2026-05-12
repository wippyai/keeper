<script setup lang="ts">
defineProps<{
  baseline: string
  current: string
  language?: string
}>()
</script>

<template>
  <wippy-monaco
    mode="diff"
    :baseline="baseline"
    :current="current"
    :language="language || 'plaintext'"
    class="monaco-wrap"
  />
</template>

<style scoped>
.monaco-wrap {
  display: block;
  width: 100%;
  height: 100%;
  min-height: 200px;
}
</style>
