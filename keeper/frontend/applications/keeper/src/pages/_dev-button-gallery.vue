<script setup lang="ts">
// TEMP D2 — remove in chunk B5.
// Reference gallery of the 17 CURRENT hand-rolled button variants.
// Pure static showcase: no API calls, no new deps, no external data.
// Each variant is reproduced verbatim — classes/markup copied from the cited
// source file, with required scoped CSS ported into this page's <style> block
// so every variant renders identically standalone.
import { Icon } from '@iconify/vue'
import Button from 'primevue/button'

// B2 inspection — default PrimeVue 4 Button rendered with each severity /
// variant / size axis, so B3 can byte-diff against the hand-rolled reference
// above.
interface PvDefault {
  id: string
  name: string
  props: Record<string, any>
  label?: string
}
interface PvExt {
  id: string
  name: string
  cls: string
  label: string
}
const pvExtensions: PvExt[] = [
  { id: 'pv-ext-dashed',     name: 'k-btn-dashed (`.add-btn`)',     cls: 'k-btn-dashed',                          label: '+ Add Delegate' },
  { id: 'pv-ext-nav',        name: 'k-btn-nav (`.keeper-nav-btn`)',  cls: 'k-btn-nav',                             label: 'Dashboard' },
  { id: 'pv-ext-nav-active', name: 'k-btn-nav + active',            cls: 'k-btn-nav k-btn-active',                label: 'Agents' },
  { id: 'pv-ext-graph',      name: 'k-btn-graph-ctrl',               cls: 'k-btn-graph-ctrl',                      label: '+' },
  { id: 'pv-ext-tint-accent',name: 'k-btn-tinted-accent (`bg-accent-500/10`)', cls: 'k-btn-tinted k-btn-tinted-accent', label: 'Explain' },
  { id: 'pv-ext-tint-info',  name: 'k-btn-tinted-info',              cls: 'k-btn-tinted k-btn-tinted-info',        label: 'Acknowledge' },
  { id: 'pv-ext-tint-success',name:'k-btn-tinted-success',           cls: 'k-btn-tinted k-btn-tinted-success',     label: 'Mark fixed' },
  { id: 'pv-ext-tint-danger',name: 'k-btn-tinted-danger',            cls: 'k-btn-tinted k-btn-tinted-danger',      label: 'Reject' },
  { id: 'pv-ext-save',       name: 'k-btn-save — dirty (enabled) + clean (disabled)', cls: 'k-btn-save',            label: 'Save' },
]

const pvDefaults: PvDefault[] = [
  { id: 'pv-primary',  name: 'severity: (none = primary)', props: {}, label: 'Primary' },
  { id: 'pv-secondary',name: 'severity="secondary"',       props: { severity: 'secondary' }, label: 'Secondary' },
  { id: 'pv-success',  name: 'severity="success"',         props: { severity: 'success' },   label: 'Success' },
  { id: 'pv-info',     name: 'severity="info"',            props: { severity: 'info' },      label: 'Info' },
  { id: 'pv-warn',     name: 'severity="warn"',            props: { severity: 'warn' },      label: 'Warn' },
  { id: 'pv-help',     name: 'severity="help"',            props: { severity: 'help' },      label: 'Help' },
  { id: 'pv-danger',   name: 'severity="danger"',          props: { severity: 'danger' },    label: 'Danger' },
  { id: 'pv-contrast', name: 'severity="contrast"',        props: { severity: 'contrast' },  label: 'Contrast' },
  { id: 'pv-outlined', name: 'variant="outlined"',         props: { variant: 'outlined' },   label: 'Outlined' },
  { id: 'pv-text',     name: 'variant="text"',             props: { variant: 'text' },       label: 'Text' },
  { id: 'pv-link',     name: 'variant="link"',             props: { variant: 'link' },       label: 'Link' },
  { id: 'pv-small',    name: 'size="small"',               props: { size: 'small' },         label: 'Small' },
  { id: 'pv-large',    name: 'size="large"',               props: { size: 'large' },         label: 'Large' },
]

interface Variant {
  id: string
  name: string
  source: string
}

// 17 Button variants — order matches 00-consolidated-census.md / buttons.md.
const variants: Variant[] = [
  { id: 'btn-primary-filled', name: '1 — Primary filled', source: 'sessions.vue:232 (.primary-btn)' },
  { id: 'btn-danger-filled', name: '2 — Danger filled', source: 'task-detail.vue:682-687' },
  { id: 'btn-success-filled', name: '3 — Success filled', source: 'GitHeader.vue:67 / GitClusterDetail.vue:151' },
  { id: 'btn-secondary-bordered', name: '4 — Secondary bordered', source: 'sessions.vue:221 (.header-btn) + .footer-btn / .ghost-btn / .mini-btn' },
  { id: 'btn-icon-only', name: '5 — Icon only', source: 'PageHeader.vue:24 / mcp.vue:603 (.icon-btn) / settings-hub.vue:1501 (.row-btn)' },
  { id: 'btn-icon-danger', name: '6 — Icon danger-hover', source: 'mcp.vue:613 (.icon-btn.danger) / logger.vue:289 (.clear-btn)' },
  { id: 'btn-add-dashed', name: '7 — Add dashed', source: 'AgentEditor.vue:327 (.add-btn)' },
  { id: 'btn-text-link', name: '8 — Text link', source: 'MsgArtifact.vue:17 / task-detail.vue:630' },
  { id: 'btn-toggle-text', name: '9 — Toggle text', source: 'MsgText.vue:39 / GitClusterDetail.vue:67' },
  { id: 'btn-brand-logo', name: '10 — Brand wordmark', source: 'app.vue:374' },
  { id: 'btn-nav-keeper', name: '11 — Nav keeper', source: 'app.vue:380 + styles.css:93 (.keeper-nav-btn)' },
  { id: 'btn-graph-ctrl', name: '12 — Graph control', source: 'ForceGraph.vue:362 (.g-ctrl button)' },
  { id: 'btn-tinted-action', name: '13 — Tinted action', source: 'GitClusterDetail.vue:83-96' },
  { id: 'btn-row-reveal', name: '14 — Row reveal (hover parent)', source: 'session-detail.vue:271 (.copy-btn)' },
  { id: 'btn-file-upload', name: '15 — File upload (label)', source: 'sessions.vue:200' },
  { id: 'btn-period-preset', name: '16 — Period preset', source: 'usage.vue:178 (.period-btn)' },
  { id: 'btn-save-editor', name: '17 — Save editor (dirty/clean)', source: 'EditorWrapper.vue:91 (.ed-save-btn)' },
]
</script>

<template>
  <div class="gallery-root">
    <h1 class="gallery-title">TEMP — D2 button-migration reference gallery — remove in chunk B5</h1>
    <p class="gallery-sub">
      17 current hand-rolled Button variants, reproduced verbatim. Each cell shows a normal and a
      disabled instance. Use this to byte-match PrimeVue replacements in later D2 chunks.
    </p>

    <div class="grid">
      <section v-for="v in variants" :key="v.id" class="cell">
        <div class="cell-head">
          <span class="cell-id">{{ v.id }}</span>
          <span class="cell-name">{{ v.name }}</span>
        </div>
        <div class="cell-src">{{ v.source }}</div>
        <div class="cell-demo">

          <!-- 1 — btn-primary-filled (.primary-btn, sessions.vue) -->
          <template v-if="v.id === 'btn-primary-filled'">
            <button class="primary-btn">Render</button>
            <button class="primary-btn" disabled>Render</button>
            <!-- inline twin: changes.vue:494 -->
            <button class="px-3 py-1.5 rounded text-xs font-medium"
              :style="{ background: 'var(--p-primary-color)', color: 'white' }">Create</button>
            <button class="px-3 py-1.5 rounded text-xs font-medium"
              :style="{ background: 'var(--p-primary-color)', color: 'white', opacity: 0.4 }">Create</button>
          </template>

          <!-- 2 — btn-danger-filled (task-detail.vue:682-687) -->
          <template v-else-if="v.id === 'btn-danger-filled'">
            <button class="w-full text-[11px] py-1.5 rounded font-medium flex items-center justify-center gap-1 bg-danger-500 text-white">
              <Icon icon="tabler:ban" class="w-3.5 h-3.5" /> Cancel task
            </button>
            <button disabled
              class="w-full text-[11px] py-1.5 rounded font-medium flex items-center justify-center gap-1 bg-danger-500 text-white">
              <Icon icon="tabler:ban" class="w-3.5 h-3.5" /> Cancel task
            </button>
          </template>

          <!-- 3 — btn-success-filled (GitHeader.vue / GitClusterDetail.vue) -->
          <template v-else-if="v.id === 'btn-success-filled'">
            <button class="px-3 py-1 rounded text-[11px] font-semibold flex items-center gap-1.5 bg-success-500 text-white">
              <Icon icon="tabler:upload" class="w-3.5 h-3.5" /> Push 3 ready
            </button>
            <button class="px-4 py-2 rounded-lg text-[12px] font-medium flex items-center gap-1.5 disabled:opacity-40 disabled:cursor-not-allowed bg-success-500 text-white"
              disabled>
              <Icon icon="tabler:check" class="w-3.5 h-3.5" /> Mark ready
            </button>
          </template>

          <!-- 4 — btn-secondary-bordered (.header-btn / .footer-btn / .ghost-btn / .mini-btn + git inline) -->
          <template v-else-if="v.id === 'btn-secondary-bordered'">
            <button class="header-btn">
              <Icon icon="tabler:upload" class="w-3.5 h-3.5" /> Import
            </button>
            <button class="header-btn" disabled>
              <Icon icon="tabler:upload" class="w-3.5 h-3.5" /> Import
            </button>
            <button class="footer-btn">
              <Icon icon="tabler:copy" class="w-3 h-3" /> Copy ID
            </button>
            <button class="footer-btn" disabled>
              <Icon icon="tabler:braces" class="w-3 h-3" /> Copy JSON
            </button>
            <button class="ghost-btn">
              <Icon icon="tabler:brand-github" class="w-3.5 h-3.5" /> repo
            </button>
            <button class="ghost-btn" disabled>
              <Icon icon="tabler:home" class="w-3.5 h-3.5" /> homepage
            </button>
            <button class="mini-btn">
              <Icon icon="tabler:list" class="w-3 h-3" /> mini-btn
            </button>
            <button class="mini-btn" disabled>
              <Icon icon="tabler:list" class="w-3 h-3" /> mini-btn
            </button>
            <!-- git inline (no border, --kp-btn-secondary-bg) -->
            <button class="text-[11px] px-2 py-0.5 rounded font-medium flex items-center gap-1"
              style="background: var(--kp-btn-secondary-bg)">
              <Icon icon="tabler:list" class="w-3 h-3" /> Manual
            </button>
            <button class="px-4 py-2 rounded-lg text-[12px] flex items-center gap-1.5"
              style="background: var(--kp-btn-secondary-bg)" disabled>
              <Icon icon="tabler:archive" class="w-3.5 h-3.5" /> Hide
            </button>
          </template>

          <!-- 5 — btn-icon-only (PageHeader p-1 / .icon-btn / .row-btn / AppUserChip) -->
          <template v-else-if="v.id === 'btn-icon-only'">
            <button class="p-1 rounded" style="color: var(--p-text-muted-color)">
              <Icon icon="tabler:refresh" class="w-3.5 h-3.5" />
            </button>
            <button class="p-1 rounded" style="color: var(--p-text-muted-color)" disabled>
              <Icon icon="tabler:refresh" class="w-3.5 h-3.5" />
            </button>
            <button class="icon-btn">
              <Icon icon="tabler:x" class="w-3.5 h-3.5" />
            </button>
            <button class="icon-btn" disabled>
              <Icon icon="tabler:x" class="w-3.5 h-3.5" />
            </button>
            <button class="row-btn">
              <Icon icon="tabler:dots" class="w-3.5 h-3.5" />
            </button>
            <button class="row-btn" disabled>
              <Icon icon="tabler:dots" class="w-3.5 h-3.5" />
            </button>
            <button class="w-6 h-6 inline-flex items-center justify-center rounded-full border-none bg-transparent cursor-pointer transition-colors hover:bg-surface-100 dark:hover:bg-surface-700"
              style="color: var(--p-text-muted-color)">
              <Icon icon="tabler:logout" class="w-3 h-3" />
            </button>
            <button class="w-6 h-6 inline-flex items-center justify-center rounded-full border-none bg-transparent cursor-pointer transition-colors hover:bg-surface-100 dark:hover:bg-surface-700"
              style="color: var(--p-text-muted-color)" disabled>
              <Icon icon="tabler:logout" class="w-3 h-3" />
            </button>
          </template>

          <!-- 6 — btn-icon-danger (.icon-btn.danger / .clear-btn) -->
          <template v-else-if="v.id === 'btn-icon-danger'">
            <button class="icon-btn danger">
              <Icon icon="tabler:trash" class="w-3.5 h-3.5" />
            </button>
            <button class="icon-btn danger" disabled>
              <Icon icon="tabler:trash" class="w-3.5 h-3.5" />
            </button>
            <button class="clear-btn">
              <Icon icon="tabler:trash" class="w-3 h-3" />
            </button>
            <button class="clear-btn" disabled>
              <Icon icon="tabler:trash" class="w-3 h-3" />
            </button>
          </template>

          <!-- 7 — btn-add-dashed (.add-btn, AgentEditor) -->
          <template v-else-if="v.id === 'btn-add-dashed'">
            <button class="add-btn">
              <Icon icon="tabler:plus" class="w-3 h-3" /> Add Delegate
            </button>
            <button class="add-btn" disabled>
              <Icon icon="tabler:plus" class="w-3 h-3" /> Add Group
            </button>
          </template>

          <!-- 8 — btn-text-link (MsgArtifact plain / task-detail underlined) -->
          <template v-else-if="v.id === 'btn-text-link'">
            <button class="flex items-center gap-1" style="color: var(--p-primary-color)">
              <Icon icon="tabler:external-link" class="w-3 h-3" /> View
            </button>
            <button class="flex items-center gap-1" style="color: var(--p-primary-color)" disabled>
              <Icon icon="tabler:external-link" class="w-3 h-3" /> View
            </button>
            <button class="text-[10px] flex items-center gap-1 underline hover:opacity-80"
              :style="{ color: 'var(--p-primary-color)' }">
              <Icon icon="tabler:circuit-diode" class="w-3 h-3" /> open latest dataflow
            </button>
            <button class="text-[10px] flex items-center gap-1 underline hover:opacity-80"
              :style="{ color: 'var(--p-primary-color)' }" disabled>
              <Icon icon="tabler:circuit-diode" class="w-3 h-3" /> open latest dataflow
            </button>
          </template>

          <!-- 9 — btn-toggle-text (MsgText primary / GitClusterDetail muted) -->
          <template v-else-if="v.id === 'btn-toggle-text'">
            <button class="text-[11px] flex items-center gap-1" style="color: var(--p-primary-color)">
              <Icon icon="tabler:chevron-down" class="w-3 h-3" /> Show all (2.4K)
            </button>
            <button class="text-[11px] flex items-center gap-1" style="color: var(--p-primary-color)" disabled>
              <Icon icon="tabler:chevron-up" class="w-3 h-3" /> Collapse
            </button>
            <button class="text-[10px] opacity-60 hover:opacity-100">Expand</button>
            <button class="text-[10px] opacity-60 hover:opacity-100" disabled>Collapse</button>
          </template>

          <!-- 10 — btn-brand-logo (app.vue:374) -->
          <template v-else-if="v.id === 'btn-brand-logo'">
            <button class="flex items-center gap-1.5 shrink-0 cursor-pointer"
              style="color: var(--p-primary-color); background: none; border: none;">
              <Icon icon="tabler:shield-code" class="w-4 h-4" />
              <span class="text-xs font-bold tracking-wider font-mono">KEEPER</span>
            </button>
            <button class="flex items-center gap-1.5 shrink-0 cursor-pointer"
              style="color: var(--p-primary-color); background: none; border: none;" disabled>
              <Icon icon="tabler:shield-code" class="w-4 h-4" />
              <span class="text-xs font-bold tracking-wider font-mono">KEEPER</span>
            </button>
          </template>

          <!-- 11 — btn-nav-keeper (.keeper-nav-btn, app.vue:380) -->
          <template v-else-if="v.id === 'btn-nav-keeper'">
            <button class="keeper-nav-btn flex items-center gap-1.5 px-2.5 py-1 rounded text-xs transition-colors relative">
              <Icon icon="tabler:layout-dashboard" class="w-3.5 h-3.5" /> Dashboard
            </button>
            <button class="keeper-nav-btn active flex items-center gap-1.5 px-2.5 py-1 rounded text-xs transition-colors relative">
              <Icon icon="tabler:robot" class="w-3.5 h-3.5" /> Agents
            </button>
            <button class="keeper-nav-btn flex items-center gap-1.5 px-2.5 py-1 rounded text-xs transition-colors relative"
              disabled>
              <Icon icon="tabler:layout-dashboard" class="w-3.5 h-3.5" /> Dashboard
            </button>
          </template>

          <!-- 12 — btn-graph-ctrl (.g-ctrl button, ForceGraph) -->
          <template v-else-if="v.id === 'btn-graph-ctrl'">
            <div class="g-ctrl-demo">
              <button>+</button>
              <button>-</button>
              <button>FIT</button>
            </div>
            <div class="g-ctrl-demo">
              <button disabled>+</button>
              <button disabled>FIT</button>
            </div>
          </template>

          <!-- 13 — btn-tinted-action (GitClusterDetail bg-X-500/10 text-X-500) -->
          <template v-else-if="v.id === 'btn-tinted-action'">
            <button class="text-[10px] px-2 py-0.5 rounded flex items-center gap-1 disabled:opacity-60 bg-accent-500/10 text-accent-500">
              <Icon icon="tabler:sparkles" class="w-3 h-3" /> Explain
            </button>
            <button class="text-[10px] px-2 py-0.5 rounded flex items-center gap-1 bg-info-500/10 text-info-500">
              <Icon icon="tabler:eye-check" class="w-3 h-3" /> Acknowledge
            </button>
            <button class="text-[10px] px-2 py-0.5 rounded flex items-center gap-1 bg-success-500/10 text-success-500">
              <Icon icon="tabler:check" class="w-3 h-3" /> Mark fixed
            </button>
            <button class="text-[10px] px-2 py-0.5 rounded flex items-center gap-1 disabled:opacity-60 bg-accent-500/10 text-accent-500"
              disabled>
              <Icon icon="tabler:sparkles" class="w-3 h-3" /> Explain
            </button>
          </template>

          <!-- 14 — btn-row-reveal (.copy-btn, opacity-0 group-hover:opacity-100) -->
          <template v-else-if="v.id === 'btn-row-reveal'">
            <div class="reveal-row group">
              <span class="text-[11px]" style="color: var(--p-text-muted-color)">Hover this row →</span>
              <button class="copy-btn opacity-0 group-hover:opacity-100">
                <Icon icon="tabler:copy" class="w-3 h-3" />
              </button>
            </div>
            <div class="reveal-row group">
              <span class="text-[11px]" style="color: var(--p-text-muted-color)">Hover (disabled btn) →</span>
              <button class="copy-btn opacity-0 group-hover:opacity-100" disabled>
                <Icon icon="tabler:copy" class="w-3 h-3" />
              </button>
            </div>
          </template>

          <!-- 15 — btn-file-upload (<label> styled as .header-btn wrapping hidden input) -->
          <template v-else-if="v.id === 'btn-file-upload'">
            <label class="header-btn cursor-pointer">
              <Icon icon="tabler:file-upload" class="w-3.5 h-3.5" /> Open file…
              <input type="file" accept=".json,application/json" class="hidden" />
            </label>
            <label class="header-btn cursor-pointer is-disabled">
              <Icon icon="tabler:file-upload" class="w-3.5 h-3.5" /> Open file…
              <input type="file" accept=".json,application/json" class="hidden" disabled />
            </label>
          </template>

          <!-- 16 — btn-period-preset (.period-btn, usage.vue) -->
          <template v-else-if="v.id === 'btn-period-preset'">
            <button class="period-btn">7d</button>
            <button class="period-btn active">30d</button>
            <button class="period-btn" disabled>90d</button>
            <button class="period-btn active" disabled>Custom</button>
          </template>

          <!-- 17 — btn-save-editor (.ed-save-btn clean / --active dirty) -->
          <template v-else-if="v.id === 'btn-save-editor'">
            <!-- clean state: disabled in source (!dirty) -->
            <button class="ed-save-btn" disabled>
              <Icon icon="tabler:device-floppy" class="w-3 h-3" /> Save
            </button>
            <!-- dirty state -->
            <button class="ed-save-btn ed-save-btn--active">
              <Icon icon="tabler:device-floppy" class="w-3 h-3" /> Save
            </button>
            <!-- saving state (spinner) -->
            <button class="ed-save-btn ed-save-btn--active" disabled>
              <Icon icon="tabler:loader-2" class="w-3 h-3 animate-spin" /> Save
            </button>
          </template>

        </div>
      </section>
    </div>

    <!-- B2 — PrimeVue defaults for inspection -->
    <h2 class="gallery-title" style="margin-top:32px">PrimeVue defaults (B2 inspection)</h2>
    <p class="gallery-sub">
      Stock PrimeVue 4 Button as the Wippy host injects it — for B3 reference. Each cell shows a normal and a disabled instance.
    </p>
    <div class="grid">
      <section v-for="pv in pvDefaults" :key="pv.id" class="cell">
        <div class="cell-head">
          <span class="cell-id">{{ pv.id }}</span>
          <span class="cell-name">{{ pv.name }}</span>
        </div>
        <div class="cell-demo">
          <Button v-bind="pv.props" :label="pv.label" />
          <Button v-bind="pv.props" :label="pv.label" disabled />
        </div>
      </section>
    </div>

    <!-- B3 iter 3 — keeper-specific .k-btn-* extensions -->
    <h2 class="gallery-title" style="margin-top:32px">PrimeVue + keeper extensions (B3 iter 3)</h2>
    <p class="gallery-sub">
      <code>.k-btn-*</code> classes layered on <code>&lt;Button&gt;</code> for the
      keeper-specific looks PrimeVue's stock variants don't cover (dashed-add,
      nav-tab, graph control, tinted-severity).
    </p>
    <div class="grid">
      <section v-for="ext in pvExtensions" :key="ext.id" class="cell">
        <div class="cell-head">
          <span class="cell-id">{{ ext.id }}</span>
          <span class="cell-name">{{ ext.name }}</span>
        </div>
        <div class="cell-demo">
          <Button :class="ext.cls" :label="ext.label" />
          <Button :class="ext.cls" :label="ext.label" disabled />
        </div>
      </section>

      <!-- File-upload verification: <label> styled with PrimeVue Button classes.
           Should render byte-identical to variant 4 (`.header-btn`) — verifies
           the B3 claim that CSS targets by class, not tag. -->
      <section class="cell">
        <div class="cell-head">
          <span class="cell-id">pv-ext-label-button</span>
          <span class="cell-name">&lt;label class="p-button p-button-secondary"&gt; → variant 15</span>
        </div>
        <div class="cell-demo">
          <label class="p-button p-button-secondary">
            <Icon icon="tabler:file-upload" class="w-3.5 h-3.5" /> Open file…
            <input type="file" accept=".json,application/json" class="hidden" />
          </label>
        </div>
      </section>
    </div>
  </div>
</template>

<style scoped>
/* ---------- gallery layout (gallery-only, not from any source) ---------- */
.gallery-root {
  height: 100%;
  overflow-y: auto;
  padding: 16px;
  background: var(--p-content-background);
}
.gallery-title {
  font-size: 14px;
  font-weight: 700;
  color: var(--p-danger-500);
  margin-bottom: 4px;
}
.gallery-sub {
  font-size: 11px;
  color: var(--p-text-muted-color);
  margin-bottom: 16px;
  max-width: 720px;
  line-height: 1.5;
}
.grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 12px;
}
.cell {
  border: 1px solid var(--p-content-border-color);
  border-radius: 6px;
  background: var(--p-surface-50);
  padding: 10px;
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.cell-head { display: flex; flex-direction: column; gap: 1px; }
.cell-id {
  font-size: 11px;
  font-weight: 700;
  font-family: 'JetBrains Mono', monospace;
  color: var(--p-text-color);
}
.cell-name { font-size: 10px; color: var(--p-text-muted-color); }
.cell-src {
  font-size: 9px;
  font-family: 'JetBrains Mono', monospace;
  color: var(--p-text-muted-color);
  opacity: 0.7;
}
.cell-demo {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 8px;
  padding: 10px;
  border-radius: 4px;
  background: var(--p-content-background);
  border: 1px solid var(--p-content-border-color);
  min-height: 48px;
}

/* ---------- ported verbatim from sessions.vue (Variant 1 + 4) ---------- */
.primary-btn {
  display: inline-flex; align-items: center; gap: 5px;
  padding: 4px 12px; border-radius: 4px;
  font-size: 11px; font-weight: 600;
  background: var(--p-primary-color);
  color: var(--p-primary-contrast-color);
  border: 1px solid var(--p-primary-color);
  cursor: pointer;
}
.primary-btn:disabled { opacity: 0.5; cursor: not-allowed; }
.primary-btn:not(:disabled):hover { opacity: 0.9; }

.header-btn {
  display: inline-flex; align-items: center; gap: 5px;
  padding: 4px 10px; border-radius: 4px;
  font-size: 11px; font-weight: 500;
  background: var(--p-surface-100);
  color: var(--p-text-color);
  border: 1px solid var(--p-content-border-color);
  cursor: pointer;
  transition: background 0.1s, border-color 0.1s;
}
.header-btn:hover { background: var(--p-surface-200); border-color: var(--p-primary-color); }
/* file-upload (Variant 15): label reuses .header-btn — disabled mimic */
.header-btn.is-disabled { opacity: 0.5; cursor: not-allowed; }

/* ---------- ported verbatim from EntryDetailPanel.vue (Variant 4) ---------- */
.footer-btn {
  display: inline-flex; align-items: center; gap: 4px;
  padding: 3px 8px; border-radius: 4px;
  font-size: 10px;
  background: var(--p-surface-100); color: var(--p-text-color);
  border: 1px solid var(--p-content-border-color);
  cursor: pointer;
}
.footer-btn:hover:not(:disabled) { background: var(--p-surface-200); }
.footer-btn:disabled { opacity: 0.5; cursor: not-allowed; }
.footer-btn.primary {
  background: var(--p-primary-color);
  color: var(--p-primary-contrast-color);
  border-color: var(--p-primary-color);
}
.footer-btn.primary:hover { opacity: 0.9; }

/* ---------- ported verbatim from settings-hub.vue (Variant 4 + 5) ---------- */
.ghost-btn {
  display: inline-flex; align-items: center; gap: 4px;
  padding: 6px 12px;
  font-size: 11px;
  background: var(--p-surface-100);
  color: var(--p-text-color);
  border: 1px solid var(--p-content-border-color);
  border-radius: 8px;
  cursor: pointer;
}
.ghost-btn:hover { background: var(--p-surface-200); }
.row-btn {
  display: inline-flex; align-items: center; justify-content: center;
  width: 26px; height: 26px;
  border-radius: 6px;
  background: transparent;
  border: 0; cursor: pointer;
}
.row-btn:hover { background: var(--p-surface-200); }

/* ---------- ported verbatim from mcp.vue (Variant 4 + 5 + 6) ---------- */
.icon-btn {
  padding: 4px;
  background: transparent;
  border: 0;
  cursor: pointer;
  color: var(--p-text-muted-color);
  border-radius: 3px;
  flex-shrink: 0;
}
.icon-btn:hover { background: var(--p-surface-200); color: var(--p-text-color); }
.icon-btn.danger:hover { background: color-mix(in srgb, var(--p-danger-500) 15%, transparent); color: var(--p-danger-500); }
.mini-btn {
  display: inline-flex; align-items: center; gap: 4px;
  padding: 4px 10px;
  font-size: 10px; font-weight: 600;
  background: var(--p-surface-100);
  border: 1px solid var(--p-content-border-color);
  color: var(--p-text-color);
  border-radius: 3px;
  cursor: pointer;
  line-height: 1.3;
}
.mini-btn:hover { background: var(--p-surface-200); }

/* ---------- ported verbatim from logger.vue (Variant 6) ---------- */
.clear-btn {
  padding: 3px; border-radius: 3px; color: var(--p-text-muted-color);
  background: transparent; border: 0; cursor: pointer;
}
.clear-btn:hover { background: color-mix(in srgb, var(--p-danger-500) 15%, transparent); color: var(--p-danger-500); }

/* ---------- ported verbatim from AgentEditor.vue (Variant 7) ---------- */
.add-btn {
  display: inline-flex; align-items: center; gap: 4px;
  padding: 4px 10px; border-radius: 4px; font-size: 11px;
  background: var(--p-surface-0); color: var(--p-text-color);
  border: 1px dashed var(--p-surface-300); cursor: pointer;
}
.add-btn:hover { border-color: var(--p-primary-color); }

/* ---------- ported verbatim from styles.css (Variant 11) ---------- */
.keeper-nav-btn {
  color: var(--p-text-color);
  font-weight: 500;
  background: transparent;
  border: 1px solid transparent;
  cursor: pointer;
}
.keeper-nav-btn:hover {
  background: var(--p-surface-100);
}
.keeper-nav-btn.active {
  background: var(--p-surface-100);
  color: var(--p-primary-color);
}

/* ---------- ported verbatim from ForceGraph.vue (Variant 12) ---------- */
.g-ctrl-demo { display: flex; flex-direction: column; gap: 2px; }
.g-ctrl-demo button {
  width: 28px; height: 28px;
  display: flex; align-items: center; justify-content: center;
  background: color-mix(in srgb, var(--p-surface-100) 80%, transparent);
  border: none; border-radius: 4px;
  color: var(--p-text-color);
  font-size: 14px; font-family: monospace;
  cursor: pointer;
}
.g-ctrl-demo button:hover { background: color-mix(in srgb, var(--p-content-border-color) 90%, transparent); color: var(--p-text-color); }

/* ---------- ported verbatim from session-detail.vue (Variant 14) ---------- */
.copy-btn {
  display: flex; align-items: center; justify-content: center;
  width: 22px; height: 22px;
  background: var(--p-surface-50);
  color: var(--p-text-muted-color);
  border: 1px solid var(--p-content-border-color);
  border-radius: 4px;
  cursor: pointer;
}
.copy-btn:hover { background: var(--p-surface-100); color: var(--p-text-color); }
/* gallery-only wrapper to demo the parent-hover reveal */
.reveal-row {
  display: flex; align-items: center; gap: 8px;
  padding: 6px 8px; border-radius: 4px;
  border: 1px dashed var(--p-content-border-color);
}

/* ---------- ported verbatim from usage.vue (Variant 16) ---------- */
/* --usage-elevated is a usage-app-local token; resolve it here so the
   gallery renders identically standalone (usage/src/styles.css:22). */
.period-btn {
  --usage-elevated: color-mix(in srgb, var(--p-content-background) 92%, var(--p-text-color) 8%);
  padding: 4px 12px; border-radius: 4px; font-size: 11px;
  background: var(--usage-elevated); color: var(--p-text-muted-color);
  border: 1px solid transparent;
  cursor: pointer;
}
.period-btn:hover { background: var(--p-content-hover-background); }
.period-btn.active {
  background: var(--p-primary-color); color: var(--p-primary-contrast-color); font-weight: 600;
}

/* ---------- ported verbatim from EditorWrapper.vue (Variant 17) ---------- */
.ed-save-btn {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 4px 12px;
  border-radius: 4px;
  font-size: 11px;
  background: var(--p-surface-200);
  color: var(--p-text-muted-color);
  border: none;
  cursor: not-allowed;
}
.ed-save-btn--active {
  background: var(--p-primary-color);
  color: var(--p-primary-contrast-color);
  cursor: pointer;
  font-weight: 600;
}
.ed-save-btn--active:hover {
  opacity: 0.9;
}
</style>
