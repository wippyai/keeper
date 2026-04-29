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

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { useApi } from '../composables/useWippy'

const api = useApi()

const entries = ref([])
const eventTypeFilter = ref('')
const sinceFilter = ref('')
const eventTypes = ref([])
let eventSource = null

const formatTime = (ts) => {
  return new Date(ts).toLocaleString()
}

const loadEntries = async () => {
  const params = new URLSearchParams()
  if (eventTypeFilter.value) params.set('event_type', eventTypeFilter.value)
  if (sinceFilter.value) params.set('since_ts', new Date(sinceFilter.value).toISOString())
  params.set('limit', '100')

  const { data } = await api.get(`/api/v1/keeper/audit?${params}`)
  if (data.success && data.entries) {
    entries.value = data.entries
    extractEventTypes(data.entries)
  }
}

const extractEventTypes = (rows) => {
  const types = new Set()
  rows.forEach(r => types.add(r.event_type))
  eventTypes.value = Array.from(types).sort()
}

const connectSSE = () => {
  eventSource = new EventSource('/api/v1/keeper/audit/stream')
  eventSource.addEventListener('audit.created', (e) => {
    const newEntry = JSON.parse(e.data)
    entries.value.unshift(newEntry)
  })
  eventSource.onerror = () => {
    setTimeout(connectSSE, 2000)
  }
}

onMounted(() => {
  loadEntries()
  connectSSE()
})

onUnmounted(() => {
  if (eventSource) eventSource.close()
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
