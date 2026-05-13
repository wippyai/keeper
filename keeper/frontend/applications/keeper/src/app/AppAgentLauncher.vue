<script setup lang="ts">
import { Icon } from '@iconify/vue'

export interface AgentInfo {
  id: string
  title: string
  icon: string
  comment: string
  model: string
  class: string[]
  public?: boolean
  start_token: string
}

defineProps<{
  agents: AgentInfo[]
  open: boolean
}>()

const emit = defineEmits<{
  (e: 'toggle'): void
  (e: 'start', token: string): void
}>()
</script>

<template>
  <template v-if="agents.length === 1">
    <button class="ask-btn" @click="emit('start', agents[0].start_token)">
      <Icon :icon="agents[0].icon || 'tabler:message-bolt'" class="w-3.5 h-3.5" />
      <span class="truncate" style="max-width: 80px">{{ agents[0].title || 'Ask' }}</span>
    </button>
  </template>
  <div v-else-if="agents.length > 1" class="relative agent-dropdown-wrap">
    <button class="ask-btn" @click="emit('toggle')">
      <Icon icon="tabler:message-bolt" class="w-3.5 h-3.5" />
      Ask
      <Icon icon="tabler:chevron-down" class="w-2.5 h-2.5" style="opacity: 0.6" />
    </button>
    <div v-if="open" class="agent-dropdown">
      <button v-for="a in agents" :key="a.id" class="agent-item" @click="emit('start', a.start_token)">
        <Icon :icon="a.icon || 'tabler:robot'" class="agent-item-icon" />
        <span class="agent-item-copy">
          <span class="agent-item-title">{{ a.title || a.id }}</span>
          <span v-if="a.comment" class="agent-item-comment">{{ a.comment }}</span>
        </span>
      </button>
    </div>
  </div>
</template>

<style scoped>
.ask-btn {
  height: 28px;
  min-width: 0;
  max-width: 160px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  padding: 0 10px;
  border: 1px solid var(--p-content-border-color);
  border-radius: 6px;
  background: var(--p-surface-100);
  color: var(--p-text-color);
  font-size: 12px;
  line-height: 1;
  cursor: pointer;
  white-space: nowrap;
}
.ask-btn:hover {
  background: var(--p-surface-200);
  color: var(--p-primary-color);
}

.agent-dropdown {
  position: absolute;
  top: calc(100% + 4px);
  left: auto;
  right: 0;
  width: min(360px, calc(100vw - 24px));
  max-width: 320px;
  max-height: min(420px, calc(100vh - 80px));
  overflow-y: auto;
  background: var(--p-content-background);
  border: 1px solid var(--p-content-border-color);
  border-radius: 6px;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.12);
  padding: 4px;
  z-index: 1000;
  display: flex;
  flex-direction: column;
  gap: 1px;
}
.agent-item {
  display: grid;
  grid-template-columns: 18px minmax(0, 1fr);
  align-items: start;
  gap: 8px;
  width: 100%;
  padding: 8px 10px;
  text-align: left;
  border: none;
  border-radius: 4px;
  background: transparent;
  color: var(--p-text-color);
  cursor: pointer;
}
.agent-item:hover {
  background: var(--p-surface-100);
}
.agent-item-icon {
  width: 15px;
  height: 15px;
  margin-top: 1px;
  color: var(--p-text-muted-color);
}
.agent-item-copy {
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 2px;
}
.agent-item-title {
  font-size: 12px;
  font-weight: 600;
  line-height: 1.2;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.agent-item-comment {
  font-size: 10px;
  line-height: 1.25;
  color: var(--p-text-muted-color);
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
</style>
