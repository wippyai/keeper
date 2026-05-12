<script setup lang="ts">
import { ref, watch } from 'vue'
import { Icon } from '@iconify/vue'
import type { RegistryEntry } from '../../../api/registry'
import EditorSection from '../fields/EditorSection.vue'

const props = defineProps<{
  entry: RegistryEntry
  detail: any
}>()

const emit = defineEmits<{
  update: [updates: { meta?: Record<string, any>; data?: Record<string, any> }]
}>()

const meta = ref<Record<string, any>>({})
const data = ref<Record<string, any>>({})

watch(() => props.detail, (d) => {
  const e = d?.entry || props.entry
  meta.value = JSON.parse(JSON.stringify(e.meta || {}))
  data.value = JSON.parse(JSON.stringify(e.data || {}))
  if (!data.value.policy) data.value.policy = { actions: '*', resources: '*', effect: 'allow', conditions: [] }
  if (!data.value.groups) data.value.groups = []
  if (!data.value.policy.conditions) data.value.policy.conditions = []
}, { immediate: true })

function emitMeta(key: string, value: any) {
  meta.value[key] = value
  emit('update', { meta: { [key]: value } })
}

function emitFullData() {
  emit('update', { data: JSON.parse(JSON.stringify(data.value)) })
}

function addGroup() {
  data.value.groups.push('')
  emitFullData()
}

function removeGroup(i: number) {
  data.value.groups.splice(i, 1)
  emitFullData()
}

function updateGroup(i: number, v: string) {
  data.value.groups[i] = v
  emitFullData()
}

function updatePolicyField(key: string, v: any) {
  data.value.policy[key] = v
  emitFullData()
}

function addCondition() {
  data.value.policy.conditions.push({ field: '', operator: '', value: null, value_from: '' })
  emitFullData()
}

function removeCondition(i: number) {
  data.value.policy.conditions.splice(i, 1)
  emitFullData()
}

function updateCondition(i: number, key: string, v: any) {
  data.value.policy.conditions[i][key] = v
  if (key === 'value' && v) data.value.policy.conditions[i].value_from = ''
  if (key === 'value_from' && v) data.value.policy.conditions[i].value = null
  emitFullData()
}

const operators = [
  { value: 'eq', label: 'Equals (eq)' },
  { value: 'ne', label: 'Not Equals (ne)' },
  { value: 'lt', label: 'Less Than (lt)' },
  { value: 'gt', label: 'Greater Than (gt)' },
  { value: 'lte', label: 'Less or Equal (lte)' },
  { value: 'gte', label: 'Greater or Equal (gte)' },
  { value: 'in', label: 'In (list)' },
  { value: 'exists', label: 'Exists' },
  { value: 'contains', label: 'Contains' },
  { value: 'matches', label: 'Matches Regex' },
]
</script>

<template>
  <div class="space-y-3 p-4">
    <!-- Description -->
    <EditorSection icon="tabler:file-description" title="Description" description="Details and purpose of this security policy.">
      <textarea
        :value="meta.comment || ''"
        @input="emitMeta('comment', ($event.target as HTMLTextAreaElement).value)"
        class="ed-textarea"
        rows="3"
        placeholder="Enter policy description..."
      ></textarea>
    </EditorSection>

    <!-- Groups -->
    <EditorSection icon="tabler:users-group" title="Policy Groups" description="List of group IDs this policy applies to.">
      <div class="space-y-1.5">
        <div v-for="(group, i) in data.groups" :key="i" class="flex items-center gap-1.5">
          <input
            :value="group"
            @input="updateGroup(i, ($event.target as HTMLInputElement).value)"
            class="ed-input flex-1 font-mono"
            placeholder="namespace:group_name"
          />
          <button class="ed-icon-btn" @click="removeGroup(i)">
            <Icon icon="tabler:trash" class="w-3 h-3" />
          </button>
        </div>
        <button class="ed-add-btn" @click="addGroup">
          <Icon icon="tabler:plus" class="w-3 h-3" /> Add Group
        </button>
      </div>
    </EditorSection>

    <!-- Policy Rules -->
    <EditorSection icon="tabler:adjustments-alt" title="Policy Rules" description="Define actions, resources, conditions, and effect.">
      <div class="space-y-4">
        <!-- Actions -->
        <div>
          <label class="text-[10px] font-medium" style="color: var(--p-text-muted-color)">Actions</label>
          <p class="text-[9px] mb-1" style="color: var(--p-text-muted-color); opacity: 0.6">Comma-separated list or "*" for all</p>
          <input
            :value="Array.isArray(data.policy.actions) ? data.policy.actions.join(', ') : data.policy.actions"
            @blur="updatePolicyField('actions', ($event.target as HTMLInputElement).value.trim() === '*' ? '*' : ($event.target as HTMLInputElement).value.split(',').map((s: string) => s.trim()).filter(Boolean))"
            class="ed-input"
            placeholder="read, write OR *"
          />
        </div>

        <!-- Resources -->
        <div>
          <label class="text-[10px] font-medium" style="color: var(--p-text-muted-color)">Resources</label>
          <p class="text-[9px] mb-1" style="color: var(--p-text-muted-color); opacity: 0.6">Comma-separated list or "*" for all</p>
          <input
            :value="Array.isArray(data.policy.resources) ? data.policy.resources.join(', ') : data.policy.resources"
            @blur="updatePolicyField('resources', ($event.target as HTMLInputElement).value.trim() === '*' ? '*' : ($event.target as HTMLInputElement).value.split(',').map((s: string) => s.trim()).filter(Boolean))"
            class="ed-input"
            placeholder="user:123, config:* OR *"
          />
        </div>

        <!-- Effect -->
        <div>
          <label class="text-[10px] font-medium" style="color: var(--p-text-muted-color)">Effect</label>
          <select :value="data.policy.effect" @change="updatePolicyField('effect', ($event.target as HTMLSelectElement).value)" class="ed-select mt-1">
            <option value="allow">Allow</option>
            <option value="deny">Deny</option>
          </select>
        </div>

        <!-- Conditions -->
        <div>
          <label class="text-[10px] font-medium" style="color: var(--p-text-muted-color)">Conditions</label>
          <p class="text-[9px] mb-2" style="color: var(--p-text-muted-color); opacity: 0.6">Optional conditions that must be met for the policy to apply.</p>
          <div class="space-y-2">
            <div v-for="(cond, i) in data.policy.conditions" :key="i" class="p-2.5 rounded" style="background: var(--p-surface-0); border: 1px solid var(--p-content-border-color)">
              <div class="flex justify-between items-center mb-2">
                <span class="text-[10px] font-semibold" style="color: var(--p-text-muted-color)">Condition {{ i + 1 }}</span>
                <button class="ed-icon-btn" @click="removeCondition(i)">
                  <Icon icon="tabler:trash" class="w-3 h-3" />
                </button>
              </div>
              <div class="grid grid-cols-2 gap-2 mb-2">
                <div>
                  <label class="text-[9px]" style="color: var(--p-text-muted-color)">Field</label>
                  <input :value="cond.field" @input="updateCondition(i, 'field', ($event.target as HTMLInputElement).value)" class="ed-input text-[10px]" placeholder="actor.meta.role" />
                </div>
                <div>
                  <label class="text-[9px]" style="color: var(--p-text-muted-color)">Operator</label>
                  <select :value="cond.operator" @change="updateCondition(i, 'operator', ($event.target as HTMLSelectElement).value)" class="ed-select text-[10px]">
                    <option value="">Select...</option>
                    <option v-for="op in operators" :key="op.value" :value="op.value">{{ op.label }}</option>
                  </select>
                </div>
              </div>
              <template v-if="cond.operator !== 'exists'">
                <div class="mb-1.5">
                  <label class="text-[9px]" style="color: var(--p-text-muted-color)">Value</label>
                  <input :value="cond.value ?? ''" @input="updateCondition(i, 'value', ($event.target as HTMLInputElement).value)" class="ed-input text-[10px]" placeholder="Static value" :disabled="!!cond.value_from" />
                </div>
                <div class="text-[9px] text-center" style="color: var(--p-text-muted-color)">OR</div>
                <div class="mt-1.5">
                  <label class="text-[9px]" style="color: var(--p-text-muted-color)">Value From (field reference)</label>
                  <input :value="cond.value_from || ''" @input="updateCondition(i, 'value_from', ($event.target as HTMLInputElement).value)" class="ed-input text-[10px]" placeholder="actor.id" :disabled="cond.value != null && cond.value !== ''" />
                </div>
              </template>
            </div>
          </div>
          <button class="ed-add-btn mt-2" @click="addCondition">
            <Icon icon="tabler:plus" class="w-3 h-3" /> Add Condition
          </button>
        </div>
      </div>
    </EditorSection>
  </div>
</template>

<style scoped>
.ed-textarea {
  width: 100%; padding: 6px 8px; border-radius: 4px; font-size: 11px;
  background: var(--p-surface-0); color: var(--p-text-color);
  border: 1px solid var(--p-content-border-color); outline: none; resize: vertical;
  min-height: 50px; line-height: 1.5;
}
.ed-textarea:focus { border-color: var(--p-primary-color); }
.ed-input {
  width: 100%; padding: 4px 8px; border-radius: 4px; font-size: 11px;
  background: var(--p-surface-0); color: var(--p-text-color);
  border: 1px solid var(--p-content-border-color); outline: none;
}
.ed-input:focus { border-color: var(--p-primary-color); }
.ed-input:disabled { opacity: 0.4; cursor: not-allowed; }
.ed-select {
  width: 100%; padding: 4px 8px; border-radius: 4px; font-size: 11px;
  background: var(--p-surface-0); color: var(--p-text-color);
  border: 1px solid var(--p-content-border-color); outline: none; cursor: pointer;
}
.ed-select:focus { border-color: var(--p-primary-color); }
.ed-icon-btn {
  padding: 3px; border-radius: 3px; color: var(--p-text-muted-color);
  background: none; border: none; cursor: pointer;
}
.ed-icon-btn:hover { background: var(--p-surface-200); color: var(--p-danger-500); }
.ed-add-btn {
  display: inline-flex; align-items: center; gap: 4px;
  padding: 4px 10px; border-radius: 4px; font-size: 11px;
  background: var(--p-surface-0); color: var(--p-text-color);
  border: 1px solid var(--p-content-border-color); cursor: pointer;
}
.ed-add-btn:hover { background: var(--p-surface-200); }
</style>
