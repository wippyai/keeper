<script setup lang="ts">
import { ref, watch } from 'vue'
import { Icon } from '@iconify/vue'
import { useApi } from '../../composables/useWippy'
import {
  planHubUninstall, uninstallHubDependency,
  type DependencyRoot, type UninstallPreview,
} from '../../api/hub'

const props = defineProps<{
  modelValue: boolean
  target: DependencyRoot | null
}>()

const emit = defineEmits<{
  'update:modelValue': [boolean]
  uninstalled: [component: string]
}>()

const api = useApi()

const policy = ref<'down' | 'leave' | 'block'>('down')
const preview = ref<UninstallPreview | null>(null)
const previewLoading = ref(false)
const previewError = ref<string | null>(null)
const busy = ref(false)
const error = ref<string | null>(null)

const POLICIES: Array<{ value: 'down' | 'leave' | 'block'; label: string; desc: string }> = [
  { value: 'down', label: 'Roll back', desc: 'Run down migrations before removing' },
  { value: 'leave', label: 'Leave applied', desc: 'Keep migrations (data remains)' },
  { value: 'block', label: 'Block', desc: 'Refuse if migrations are still applied' },
]

watch(() => props.modelValue, open => {
  if (open) reset()
})

function reset() {
  policy.value = 'down'
  preview.value = null
  previewError.value = null
  error.value = null
  busy.value = false
  void loadPreview()
}

function close() {
  emit('update:modelValue', false)
}

async function loadPreview() {
  if (!props.target) return
  previewLoading.value = true
  previewError.value = null
  try {
    preview.value = await planHubUninstall(api, {
      id: props.target.id,
      component: props.target.component,
    })
  } catch (e: any) {
    preview.value = null
    previewError.value = e.response?.data?.error || e.response?.data?.message || e.message
  } finally {
    previewLoading.value = false
  }
}

async function confirm() {
  if (!props.target || !preview.value) return
  busy.value = true
  error.value = null
  try {
    await uninstallHubDependency(api, {
      id: props.target.id,
      component: props.target.component,
      migration_policy: policy.value,
    })
    emit('uninstalled', props.target.component || props.target.id)
    close()
  } catch (e: any) {
    error.value = e.response?.data?.error || e.response?.data?.message || e.message
  } finally {
    busy.value = false
  }
}
</script>

<template>
  <Teleport to="body">
    <div v-if="modelValue && target" class="overlay" @click.self="close">
      <div class="dialog">
        <div class="flex items-center gap-2 mb-3">
          <Icon icon="tabler:trash" class="w-5 h-5 text-danger-500" />
          <span class="text-sm font-semibold" style="color: var(--p-text-color)">Uninstall {{ target.component }}</span>
        </div>
        <p class="text-[11px] mb-3 leading-relaxed" style="color: var(--p-text-muted-color)">
          Removes <code class="mono">{{ target.component }}</code>{{ target.version ? '@' + target.version : '' }} and its exclusively-owned dependencies. Review the preview before confirming.
        </p>

        <!-- Preview -->
        <div v-if="previewLoading" class="preview-status">
          <Icon icon="tabler:loader-2" class="w-3.5 h-3.5 animate-spin" /> Computing removal preview…
        </div>
        <div v-else-if="previewError" class="preview-status err">
          <div class="flex items-center gap-1.5"><Icon icon="tabler:alert-triangle" class="w-3.5 h-3.5" /> {{ previewError }}</div>
          <button class="ghost-sm mt-2" @click="loadPreview">Retry</button>
        </div>
        <template v-else-if="preview">
          <!-- Warnings first -->
          <div v-if="preview.warnings.length" class="warn-box">
            <div v-for="(w, i) in preview.warnings" :key="i" class="flex items-start gap-1.5">
              <Icon icon="tabler:alert-triangle" class="w-3.5 h-3.5 shrink-0 mt-px" />
              <span>{{ w }}</span>
            </div>
          </div>

          <div class="sect">
            <div class="sect-label removed">
              <Icon icon="tabler:trash" class="w-3.5 h-3.5" /> Will remove
              <span class="count">{{ preview.removed.length }}</span>
            </div>
            <div v-if="preview.removed.length" class="chips">
              <span v-for="e in preview.removed" :key="e.name" class="chip removed">
                {{ e.name }}<span v-if="e.version" class="chip-ver">{{ e.version }}</span>
              </span>
            </div>
            <div v-else class="sect-empty">Nothing to remove.</div>
          </div>

          <div v-if="preview.kept.length" class="sect">
            <div class="sect-label kept">
              <Icon icon="tabler:lock" class="w-3.5 h-3.5" /> Kept — still needed by other modules
              <span class="count">{{ preview.kept.length }}</span>
            </div>
            <div class="chips">
              <span v-for="e in preview.kept" :key="e.name" class="chip kept">
                {{ e.name }}<span v-if="e.version" class="chip-ver">{{ e.version }}</span>
              </span>
            </div>
          </div>

          <div v-if="preview.kept_under_uncertainty.length" class="sect">
            <div class="sect-label uncertain">
              <Icon icon="tabler:help-circle" class="w-3.5 h-3.5" /> Kept — graph incomplete, not safely removable
              <span class="count">{{ preview.kept_under_uncertainty.length }}</span>
            </div>
            <div class="chips">
              <span v-for="e in preview.kept_under_uncertainty" :key="e.name" class="chip uncertain">
                {{ e.name }}<span v-if="e.version" class="chip-ver">{{ e.version }}</span>
              </span>
            </div>
          </div>
        </template>

        <!-- Migration policy -->
        <div class="mt-3">
          <div class="form-label">Applied migrations</div>
          <label class="radio-row" v-for="opt in POLICIES" :key="opt.value">
            <input type="radio" :value="opt.value" v-model="policy" />
            <span>
              <span class="font-medium" style="color: var(--p-text-color)">{{ opt.label }}</span>
              <span class="block text-[10px]" style="color: var(--p-text-muted-color)">{{ opt.desc }}</span>
            </span>
          </label>
        </div>

        <div v-if="error" class="mt-2 px-2 py-1.5 rounded text-[11px] bg-danger-500/15 text-danger-500">{{ error }}</div>

        <div class="flex justify-end gap-2 mt-4">
          <button class="dialog-btn cancel" @click="close" :disabled="busy">Cancel</button>
          <button class="dialog-btn danger" @click="confirm" :disabled="busy || previewLoading || !preview">
            <Icon v-if="busy" icon="tabler:loader-2" class="w-3 h-3 animate-spin" />
            Uninstall
          </button>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<style scoped>
.mono { font-family: 'JetBrains Mono', monospace; }

.overlay {
  position: fixed; inset: 0; z-index: 9999;
  background: rgba(0, 0, 0, 0.6);
  display: flex; align-items: center; justify-content: center;
  padding: 16px;
  overflow: auto;
}
.dialog {
  background: var(--p-surface-50);
  border: 1px solid var(--p-content-border-color);
  border-radius: 10px;
  padding: 18px;
  width: 460px; max-width: 90vw;
  max-height: calc(100dvh - 32px);
  overflow-y: auto;
  overscroll-behavior: contain;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.4);
}
.form-label {
  display: block;
  font-size: 10px; text-transform: uppercase; letter-spacing: 0.04em; font-weight: 600;
  color: var(--p-text-muted-color);
  margin-bottom: 4px;
}
.preview-status {
  display: flex; flex-direction: column;
  font-size: 11px; color: var(--p-text-muted-color);
  padding: 10px; border: 1px solid var(--p-content-border-color); border-radius: 6px;
}
.preview-status.err { color: var(--p-danger-500); border-color: color-mix(in srgb, var(--p-danger-500) 40%, transparent); }

.warn-box {
  display: flex; flex-direction: column; gap: 4px;
  font-size: 11px; line-height: 1.35;
  color: var(--p-warn-500);
  background: color-mix(in srgb, var(--p-warn-500) 12%, transparent);
  border: 1px solid color-mix(in srgb, var(--p-warn-500) 35%, transparent);
  border-radius: 6px;
  padding: 8px 10px;
  margin-bottom: 10px;
}

.sect { margin-bottom: 10px; }
.sect-label {
  display: flex; align-items: center; gap: 5px;
  font-size: 10px; text-transform: uppercase; letter-spacing: 0.04em; font-weight: 700;
  margin-bottom: 5px;
}
.sect-label.removed { color: var(--p-danger-500); }
.sect-label.kept { color: var(--p-text-color); }
.sect-label.uncertain { color: var(--p-warn-500); }
.sect-label .count {
  font-size: 9px; font-weight: 700;
  background: var(--p-surface-200); color: var(--p-text-muted-color);
  border-radius: 8px; padding: 0 6px;
}
.sect-empty { font-size: 11px; color: var(--p-text-muted-color); }

.chips { display: flex; flex-wrap: wrap; gap: 4px; }
.chip {
  display: inline-flex; align-items: center; gap: 4px;
  font-family: 'JetBrains Mono', monospace;
  font-size: 10px;
  padding: 2px 7px; border-radius: 4px;
  border: 1px solid transparent;
}
.chip-ver { opacity: 0.65; font-size: 9px; }
.chip.removed { background: color-mix(in srgb, var(--p-danger-500) 14%, transparent); color: var(--p-danger-500); }
.chip.kept { background: var(--p-surface-200); color: var(--p-text-color); }
.chip.uncertain {
  background: color-mix(in srgb, var(--p-warn-500) 12%, transparent);
  color: var(--p-warn-500);
  border-color: color-mix(in srgb, var(--p-warn-500) 35%, transparent);
}

.radio-row {
  display: flex; align-items: flex-start; gap: 8px;
  padding: 6px;
  border-radius: 4px;
  cursor: pointer;
  font-size: 11px;
}
.radio-row:hover { background: var(--p-surface-100); }
.radio-row input { margin-top: 2px; }

.ghost-sm {
  padding: 3px 8px; font-size: 10px;
  background: var(--p-surface-100); color: var(--p-text-muted-color);
  border: 1px solid var(--p-content-border-color);
  border-radius: 4px; cursor: pointer; width: fit-content;
}
.ghost-sm:hover { background: var(--p-surface-200); }

.dialog-btn {
  display: inline-flex; align-items: center; gap: 4px;
  padding: 5px 14px;
  font-size: 11px;
  border-radius: 4px;
  cursor: pointer; border: 1px solid transparent;
}
.dialog-btn.cancel {
  background: var(--p-surface-100);
  color: var(--p-text-muted-color);
  border-color: var(--p-content-border-color);
}
.dialog-btn.cancel:hover { background: var(--p-surface-200); }
.dialog-btn.danger {
  background: var(--p-danger-500);
  color: white; font-weight: 600;
}
.dialog-btn.danger:hover:not(:disabled) { opacity: 0.9; }
.dialog-btn:disabled { opacity: 0.5; cursor: not-allowed; }
</style>
