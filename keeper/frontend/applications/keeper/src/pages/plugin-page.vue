<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import PluginHost from '../components/PluginHost.vue'

const route = useRoute()
const pluginId = computed(() => String(route.params.id || ''))
const url = computed(() => pluginId.value ? `/c/${pluginId.value}` : '')
</script>

<template>
  <div class="h-full">
    <PluginHost v-if="url" :url="url" :title="pluginId" />
  </div>
</template>
