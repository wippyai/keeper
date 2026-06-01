<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import PluginHost from '../components/PluginHost.vue'

const route = useRoute()
const pluginId = computed(() => String(route.params.id || ''))
</script>

<template>
  <div class="h-full">
    <PluginHost v-if="pluginId" :page-id="pluginId" :title="pluginId" />
  </div>
</template>
