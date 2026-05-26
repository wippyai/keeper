<script setup lang="ts">
// Canonical primitive: <w-artifact type="page" :id="..."> (gen-2-chat 1.0.33+).
// See app-template-raw/frontend/docs/proxy-api.md § "<w-artifact> Web Component"
// + fe-compliance-checklist.md § 15.7 (REJECT 57a) for the SUPER ANTI-PATTERN
// this replaces: raw <iframe src="/c/<id>"> would have nested ANOTHER full
// Wippy host runtime inside this iframe.
defineProps<{
  pageId: string
  title?: string
}>()
</script>

<template>
  <div class="relative w-full h-full" style="min-height: 100px">
    <w-artifact
      type="page"
      :id="pageId"
      :title="title || pageId"
      auto-height
      class="block w-full h-full"
    />
  </div>
</template>

<style scoped>
w-artifact { display: block; }
w-artifact::part(frame) { border: 0; width: 100%; height: 100%; }
</style>
