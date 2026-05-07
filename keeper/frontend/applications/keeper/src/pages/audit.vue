<template>
  <div class="audit-log-page">
    <div class="header">
      <h1>Audit Log</h1>
      <div class="filters">
        <select v-model="eventTypeFilter" @change="loadEntries">
          <option value="">All Events</option>
          <option v-for="type in eventTypes" :key="type" :value="type">
            {{ type }}
          </option>
        </select>
        <input
          v-model="sinceFilter"
          type="datetime-local"
          @change="loadEntries"
          placeholder="Since timestamp"
        />
        <button @click="loadEntries">Refresh</button>
      </div>
    </div>

    <table class="audit-table">
      <thead>
        <tr>
          <th>Time</th>
          <th>Actor</th>
          <th>Event Type</th>
          <th>Resource</th>
          <th>Payload</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="entry in entries" :key="entry.entry_id">
          <td>{{ formatTime(entry.created_at) }}</td>
          <td>{{ entry.actor_id }}</td>
          <td>{{ entry.event_type }}</td>
          <td>{{ entry.resource || '-' }}</td>
          <td>
            <details v-if="entry.payload">
              <summary>View</summary>
              <pre>{{ JSON.stringify(JSON.parse(entry.payload), null, 2) }}</pre>
            </details>
            <span v-else>-</span>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { useApi, useWippy } from '../composables/useWippy'

interface AuditEntry {
  entry_id: string
  created_at: string
  actor_id: string
  event_type: string
  resource?: string
  payload?: string
}

const api = useApi()
const instance = useWippy()

const entries = ref<AuditEntry[]>([])
const eventTypeFilter = ref('')
const sinceFilter = ref('')
const eventTypes = ref<string[]>([])
let unsubAudit: (() => void) | null = null

const formatTime = (ts: string): string => new Date(ts).toLocaleString()

const extractEventTypes = (rows: AuditEntry[]) => {
  const types = new Set<string>()
  rows.forEach(r => types.add(r.event_type))
  eventTypes.value = Array.from(types).sort()
}

const loadEntries = async () => {
  const params = new URLSearchParams()
  if (eventTypeFilter.value) params.set('event_type', eventTypeFilter.value)
  if (sinceFilter.value) params.set('since_ts', new Date(sinceFilter.value).toISOString())
  params.set('limit', '100')

  const { data } = await api.get<{ success: boolean; entries?: AuditEntry[] }>(
    `/api/v1/keeper/audit?${params}`,
  )
  if (data.success && data.entries) {
    entries.value = data.entries
    extractEventTypes(data.entries)
  }
}

onMounted(() => {
  loadEntries()
  unsubAudit = instance.on('keeper.audit', (evt: unknown) => {
    const data = (evt as { data?: unknown })?.data ?? evt
    const entry = ((data as { entry?: AuditEntry })?.entry ?? data) as AuditEntry | undefined
    if (entry && entry.entry_id) entries.value.unshift(entry)
  })
})

onUnmounted(() => {
  unsubAudit?.()
})
</script>

<style scoped>
.audit-log-page {
  padding: 1rem;
}
.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
}
.filters {
  display: flex;
  gap: 0.5rem;
}
.audit-table {
  width: 100%;
  border-collapse: collapse;
}
.audit-table th,
.audit-table td {
  border: 1px solid var(--p-content-border-color);
  padding: 0.5rem;
  text-align: left;
}
.audit-table th {
  background-color: var(--p-surface-100);
  font-weight: 600;
}
.audit-table tbody tr:hover {
  background-color: var(--p-surface-50);
}
details summary {
  cursor: pointer;
  color: var(--p-primary-color);
}
pre {
  background: var(--p-surface-100);
  padding: 0.5rem;
  border-radius: 4px;
  font-size: 0.85rem;
  overflow-x: auto;
}
</style>
