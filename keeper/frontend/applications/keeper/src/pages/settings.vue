<script setup lang="ts">
import { useRouter } from 'vue-router'
import { Icon } from '@iconify/vue'
import PageHeader from '../components/shared/PageHeader.vue'

const router = useRouter()

const cards = [
  {
    path: '/settings/environment',
    icon: 'tabler:variable',
    title: 'Environment',
    desc: 'Inspect and edit environment variables consumed by services and tools.',
    accent: 'default',
  },
  {
    path: '/settings/registry',
    icon: 'tabler:database',
    title: 'Registry',
    desc: 'Sync the registry with the filesystem, undo or redo recent changes.',
    accent: 'default',
  },
  {
    path: '/settings/hub',
    icon: 'tabler:cloud',
    title: 'Wippy Hub',
    desc: 'Connect to wippy.ai — sign in, search, install, publish modules.',
    accent: 'hub',
  },
]
</script>

<template>
  <div class="h-full flex flex-col">
    <PageHeader icon="tabler:settings" title="Settings" />
    <div class="flex-1 overflow-y-auto p-4">
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
        <button
          v-for="c in cards" :key="c.path"
          class="settings-card"
          :class="{ 'settings-card--hub': c.accent === 'hub' }"
          @click="router.push(c.path)"
        >
          <div class="card-icon">
            <Icon :icon="c.icon" class="w-5 h-5" />
          </div>
          <div class="flex-1 min-w-0 text-left">
            <div class="card-title">{{ c.title }}</div>
            <div class="card-desc">{{ c.desc }}</div>
          </div>
          <Icon icon="tabler:chevron-right" class="w-3.5 h-3.5 chev" />
        </button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.settings-card {
  display: flex; align-items: center; gap: 12px;
  padding: 14px 16px;
  border-radius: 8px;
  background: var(--p-surface-50);
  border: 1px solid var(--p-content-border-color);
  cursor: pointer;
  transition: border-color 0.1s, background 0.1s;
  text-align: left;
}
.settings-card:hover {
  border-color: var(--p-primary-color);
  background: var(--p-surface-100);
}
.card-icon {
  width: 38px; height: 38px;
  display: flex; align-items: center; justify-content: center;
  border-radius: 8px;
  background: color-mix(in srgb, var(--p-primary-color) 12%, transparent);
  color: var(--p-primary-color);
  flex-shrink: 0;
}
.card-title {
  font-size: 13px; font-weight: 600;
  color: var(--p-text-color);
  margin-bottom: 2px;
}
.card-desc {
  font-size: 11px; line-height: 1.45;
  color: var(--p-text-muted-color);
}
.chev {
  color: var(--p-text-muted-color);
  opacity: 0.5;
  flex-shrink: 0;
}

/* Hub card uses info palette so it reads as an external integration */
.settings-card--hub:hover {
  border-color: var(--p-info-500);
}
.settings-card--hub .card-icon {
  background: color-mix(in srgb, var(--p-info-500) 14%, transparent);
  color: var(--p-info-500);
}
</style>
