<script setup lang="ts">
import { Icon } from '@iconify/vue'

// Reference gallery for the D2 Badge/Chip family migration (B1-equivalent).
// 12 variants from .local/2026-05-19-d2-inventory/00-consolidated-census.md.
// REMOVE in the cleanup chunk equivalent to B5.
// All CSS inlined here is source-of-truth lifted verbatim from the call-site
// scoped <style> blocks — adjusting any value here MUST be tracked back to
// the original location.

const variants = [
  { id: 'badge-status-tinted', name: '1 — Status tinted', source: 'MsgHeader.vue:20-24, StatusBadge.vue, GitClusterList.vue:82-89' },
  { id: 'badge-kind-colored', name: '2 — Kind colored', source: 'EntryDetailPanel.vue:115 (.kind-badge), MsgHeader.vue:13 (colored text), changes.vue:647 (op-letter)' },
  { id: 'badge-count-pill', name: '3 — Count pill', source: 'PageHeader.vue:19, AgentEditor.vue:106 (.tab-cnt), tasks.vue:230 (.hdr-count), agents.vue:386 (.ns-count)' },
  { id: 'badge-data-neutral', name: '4 — Data neutral', source: 'agents.vue:517 (.chip), MsgHeader.vue:15 (model pill), models.vue (.meta-pill), agents.vue:457 (.spec-pill)' },
  { id: 'badge-stat-pill', name: '5 — Stat pill', source: 'agents.vue:340-354 (.stat-pill+variants), dashboard.vue:320-374 (.hero-pill)' },
  { id: 'badge-filter-chip', name: '6 — Filter chip (interactive)', source: 'agents.vue:171 (.class-chip), models.vue (.cap-chip), policies.vue (.e-chip), logger.vue (.m-chip)' },
  { id: 'badge-dot', name: '7 — Dot', source: 'DotBadge.vue (whole), dashboard.vue:258 (.health-dot), GitClusterList.vue:72 (importance dot)' },
  { id: 'badge-icon-bubble', name: '8 — Icon bubble', source: 'DataTimeline.vue:302 (.icon-bubble), agents.vue:412 (.agent-icon)' },
  { id: 'badge-kbd', name: '9 — Keyboard hint', source: 'settings-registry.vue:524 (.kbd), AppGlobalSearch.vue:54 (bare <kbd>)' },
  { id: 'badge-percentage-chip', name: '10 — Percentage chip', source: 'usage.vue:266,290, AppGlobalSearch.vue:63' },
  { id: 'badge-removable-chip', name: '11 — Removable chip', source: 'TagsField.vue:33 (.tag), settings-registry.vue:473 (.managed-chip)' },
  { id: 'badge-awaiting-pulse', name: '12 — Awaiting pulse (animated)', source: 'tasks.vue:229 (.awaiting-pulse)' },
]
</script>

<template>
  <div class="p-4 flex flex-col gap-4" style="background: var(--p-content-background); min-height: 100vh">
    <header class="mb-2">
      <h1 class="text-base font-bold" style="color: var(--p-danger-500)">
        TEMP — D2 badge-migration reference gallery — remove in badge-family cleanup chunk
      </h1>
      <p class="text-xs mt-1" style="color: var(--p-text-muted-color)">
        12 current hand-rolled Badge/Chip/Tag/Pill/Dot variants, reproduced verbatim.
        Use this to byte-match PrimeVue (Tag/Chip/Badge/Avatar) replacements in later chunks.
      </p>
    </header>

    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
      <div v-for="v in variants" :key="v.id" class="cell" :data-id="v.id">
        <div class="cell-head">
          <code>{{ v.id }}</code>
          <span class="cell-name">{{ v.name }}</span>
        </div>
        <div class="cell-src">{{ v.source }}</div>
        <div class="cell-body">
          <!-- 1 — badge-status-tinted -->
          <template v-if="v.id === 'badge-status-tinted'">
            <!-- MsgHeader.vue:20-24 tinted-pill flavour (icon + label) -->
            <div class="flex flex-wrap items-center gap-2">
              <span class="badge-st" style="background: color-mix(in srgb, var(--p-success-500) 10%, transparent); color: var(--p-success-500)">
                <Icon icon="tabler:check" class="w-3 h-3" /> ok
              </span>
              <span class="badge-st" style="background: color-mix(in srgb, var(--p-danger-500) 10%, transparent); color: var(--p-danger-500)">
                <Icon icon="tabler:x" class="w-3 h-3" /> error
              </span>
              <span class="badge-st" style="background: color-mix(in srgb, var(--p-warn-500) 10%, transparent); color: var(--p-warn-500)">
                <Icon icon="tabler:alert-triangle" class="w-3 h-3" /> warn
              </span>
              <span class="badge-st" style="background: color-mix(in srgb, var(--p-info-500) 10%, transparent); color: var(--p-info-500)">
                <Icon icon="tabler:info-circle" class="w-3 h-3" /> info
              </span>
            </div>
            <!-- StatusBadge.vue — dot + label, no bg -->
            <div class="flex flex-wrap items-center gap-2 mt-2">
              <span class="status-badge"><span class="w-1.5 h-1.5 rounded-full" style="background: var(--p-success-500)"></span><span>OK</span></span>
              <span class="status-badge"><span class="w-1.5 h-1.5 rounded-full" style="background: var(--p-warn-500)"></span><span>warn</span></span>
              <span class="status-badge"><span class="w-1.5 h-1.5 rounded-full" style="background: var(--p-danger-500)"></span><span>error</span></span>
            </div>
          </template>

          <!-- 2 — badge-kind-colored -->
          <template v-else-if="v.id === 'badge-kind-colored'">
            <!-- .kind-badge (EntryDetailPanel.vue:115) — neutral monospace -->
            <div class="flex flex-wrap items-center gap-2">
              <span class="kind-badge">agent.gen1</span>
              <span class="kind-badge">function.lua</span>
              <span class="kind-badge">http.endpoint</span>
            </div>
            <!-- colored kind label (MsgHeader.vue:13) — no bg, just colored text -->
            <div class="flex flex-wrap items-center gap-2 mt-2">
              <span class="text-xs font-semibold" style="color: var(--p-info-500)">user</span>
              <span class="text-xs font-semibold" style="color: var(--p-success-500)">assistant</span>
              <span class="text-xs font-semibold" style="color: var(--p-danger-500)">delegation</span>
              <span class="text-xs font-semibold" style="color: var(--p-accent-400)">function</span>
            </div>
            <!-- op-letter (changes.vue:647) — tinted single-letter -->
            <div class="flex flex-wrap items-center gap-2 mt-2">
              <span class="op-letter" style="background: color-mix(in srgb, var(--p-success-500) 10%, transparent); color: var(--p-success-500)">A</span>
              <span class="op-letter" style="background: color-mix(in srgb, var(--p-info-500) 10%, transparent); color: var(--p-info-500)">M</span>
              <span class="op-letter" style="background: color-mix(in srgb, var(--p-danger-500) 10%, transparent); color: var(--p-danger-500)">D</span>
            </div>
          </template>

          <!-- 3 — badge-count-pill -->
          <template v-else-if="v.id === 'badge-count-pill'">
            <!-- PageHeader.vue:19 — bare text count (NO bg) -->
            <div class="flex items-center gap-2">
              <span class="text-xs">Header label</span>
              <span class="text-[10px]" style="color: var(--p-text-muted-color)">12</span>
            </div>
            <!-- .tab-cnt (AgentEditor.vue:106) — 8px tiny -->
            <div class="mt-2 flex items-center gap-2">
              <span class="text-xs">Tab name</span>
              <span class="tab-cnt">3</span>
            </div>
            <!-- .hdr-count (tasks.vue:230) — 10px rounded-12 -->
            <div class="mt-2 flex items-center gap-2">
              <span class="text-xs">Tasks</span>
              <span class="hdr-count">47</span>
            </div>
            <!-- .ns-count (agents.vue:386) — 10px rounded-8 -->
            <div class="mt-2 flex items-center gap-2">
              <span class="text-xs">Namespace</span>
              <span class="ns-count">8</span>
            </div>
          </template>

          <!-- 4 — badge-data-neutral -->
          <template v-else-if="v.id === 'badge-data-neutral'">
            <!-- .chip (agents.vue:517) — 9px no border -->
            <div class="flex flex-wrap items-center gap-2">
              <span class="chip-neutral">claude-4-5-sonnet</span>
              <span class="chip-neutral">v1.2.0</span>
              <span class="chip-neutral">8k</span>
            </div>
            <!-- model pill (MsgHeader.vue:15) — 10px no border, muted -->
            <div class="flex flex-wrap items-center gap-2 mt-2">
              <span class="model-pill">gpt-4.1-mini</span>
              <span class="model-pill">claude-haiku</span>
            </div>
            <!-- .meta-pill — 11px bordered -->
            <div class="flex flex-wrap items-center gap-2 mt-2">
              <span class="meta-pill"><Icon icon="tabler:cpu" class="w-3 h-3" />temp <strong>0.3</strong></span>
              <span class="meta-pill"><Icon icon="tabler:hash" class="w-3 h-3" />ctx <strong>8k</strong></span>
            </div>
            <!-- .spec-pill — 9px bordered fixed-height -->
            <div class="flex flex-wrap items-center gap-2 mt-2">
              <span class="spec-pill"><span class="spec-val">128</span><span class="spec-lbl">tools</span></span>
              <span class="spec-pill"><span class="spec-val">12</span><span class="spec-lbl">traits</span></span>
            </div>
          </template>

          <!-- 5 — badge-stat-pill -->
          <template v-else-if="v.id === 'badge-stat-pill'">
            <!-- .stat-pill — neutral bg + bordered, text recolored -->
            <div class="flex flex-wrap items-center gap-2">
              <span class="stat-pill"><span class="stat-num">42</span><span class="stat-lbl">total</span></span>
              <span class="stat-pill" style="color: var(--p-accent-500)"><span class="stat-num">128</span><span class="stat-lbl">tokens</span></span>
              <span class="stat-pill" style="color: var(--p-info-500)"><span class="stat-num">7</span><span class="stat-lbl">active</span></span>
              <span class="stat-pill" style="color: var(--p-warn-500)"><span class="stat-num">3</span><span class="stat-lbl">blocked</span></span>
              <span class="stat-pill" style="color: var(--p-success-500)"><span class="stat-num">31</span><span class="stat-lbl">done</span></span>
            </div>
            <!-- .hero-pill — 15% tinted bg + colored text, no border -->
            <div class="flex flex-wrap items-center gap-2 mt-2">
              <span class="hero-pill" style="background: color-mix(in srgb, var(--p-warn-500) 15%, transparent); color: var(--p-warn-500)">3 blocked</span>
              <span class="hero-pill" style="background: color-mix(in srgb, var(--p-success-500) 15%, transparent); color: var(--p-success-500)">31 ✓</span>
              <span class="hero-pill" style="background: color-mix(in srgb, var(--p-info-500) 15%, transparent); color: var(--p-info-500)">→ 4.2k</span>
            </div>
          </template>

          <!-- 6 — badge-filter-chip (interactive toggle) -->
          <template v-else-if="v.id === 'badge-filter-chip'">
            <!-- .class-chip — idle / hover / active states -->
            <div class="flex flex-wrap items-center gap-2">
              <button class="class-chip">idle</button>
              <button class="class-chip" data-hover>hover-approx</button>
              <button class="class-chip class-chip--active">active</button>
              <button class="class-chip class-chip--active" style="--cc: var(--p-success-500)">success-tinted</button>
              <button class="class-chip class-chip--active" style="--cc: var(--p-danger-500)">danger-tinted</button>
            </div>
          </template>

          <!-- 7 — badge-dot -->
          <template v-else-if="v.id === 'badge-dot'">
            <!-- DotBadge — sizes 4/6/8/12 px × multiple colors -->
            <div class="flex flex-wrap items-center gap-3">
              <span class="dot" style="width: 4px; height: 4px; background: var(--p-success-500)"></span>
              <span class="dot" style="width: 6px; height: 6px; background: var(--p-success-500)"></span>
              <span class="dot" style="width: 8px; height: 8px; background: var(--p-success-500)"></span>
              <span class="dot" style="width: 12px; height: 12px; background: var(--p-success-500)"></span>
              <span class="dot" style="width: 8px; height: 8px; background: var(--p-warn-500)"></span>
              <span class="dot" style="width: 8px; height: 8px; background: var(--p-danger-500)"></span>
              <span class="dot" style="width: 8px; height: 8px; background: var(--p-info-500)"></span>
              <span class="dot" style="width: 8px; height: 8px; background: var(--p-accent-500)"></span>
            </div>
            <!-- pulsed dot (sessions.vue:147 inline) -->
            <div class="flex flex-wrap items-center gap-3 mt-2">
              <span class="dot animate-pulse" style="width: 6px; height: 6px; background: var(--p-success-500)"></span>
              <span class="text-xs" style="color: var(--p-text-muted-color)">animate-pulse running indicator</span>
            </div>
          </template>

          <!-- 8 — badge-icon-bubble -->
          <template v-else-if="v.id === 'badge-icon-bubble'">
            <!-- .icon-bubble — 20px circle -->
            <div class="flex flex-wrap items-center gap-3">
              <span class="icon-bubble" style="background: color-mix(in srgb, var(--p-info-500) 12%, transparent); color: var(--p-info-500)">
                <Icon icon="tabler:user" class="w-3.5 h-3.5" />
              </span>
              <span class="icon-bubble" style="background: color-mix(in srgb, var(--p-success-500) 12%, transparent); color: var(--p-success-500)">
                <Icon icon="tabler:check" class="w-3.5 h-3.5" />
              </span>
              <span class="icon-bubble" style="background: color-mix(in srgb, var(--p-warn-500) 12%, transparent); color: var(--p-warn-500)">
                <Icon icon="tabler:bell" class="w-3.5 h-3.5" />
              </span>
            </div>
            <!-- .agent-icon — 22px rounded-rect -->
            <div class="flex flex-wrap items-center gap-3 mt-2">
              <span class="agent-icon"><Icon icon="tabler:robot" class="w-3.5 h-3.5" /></span>
              <span class="agent-icon"><Icon icon="tabler:cpu" class="w-3.5 h-3.5" /></span>
              <span class="agent-icon"><Icon icon="tabler:brain" class="w-3.5 h-3.5" /></span>
            </div>
          </template>

          <!-- 9 — badge-kbd -->
          <template v-else-if="v.id === 'badge-kbd'">
            <!-- .kbd (settings-registry) -->
            <div class="flex flex-wrap items-center gap-2">
              <kbd class="kbd">Esc</kbd>
              <kbd class="kbd">⌘</kbd>
              <kbd class="kbd">K</kbd>
              <kbd class="kbd">Enter</kbd>
            </div>
            <!-- bare <kbd> — AppGlobalSearch (.search-kbd has no scoped CSS so falls back to user-agent style) -->
            <div class="flex flex-wrap items-center gap-2 mt-2">
              <kbd>Esc</kbd>
              <kbd>⌘K</kbd>
              <span class="text-[10px]" style="color: var(--p-text-muted-color)">(bare browser default — note AppGlobalSearch has no .search-kbd rule)</span>
            </div>
          </template>

          <!-- 10 — badge-percentage-chip -->
          <template v-else-if="v.id === 'badge-percentage-chip'">
            <div class="flex flex-wrap items-center gap-2">
              <span class="pct-chip">42%</span>
              <span class="pct-chip">100%</span>
              <span class="pct-chip">3%</span>
              <span class="pct-chip">99.9%</span>
            </div>
          </template>

          <!-- 11 — badge-removable-chip -->
          <template v-else-if="v.id === 'badge-removable-chip'">
            <!-- .tag (TagsField) -->
            <div class="flex flex-wrap items-center gap-2">
              <span class="tag-rm">development<button class="tag-x"><Icon icon="tabler:x" class="w-2.5 h-2.5" /></button></span>
              <span class="tag-rm">implementation<button class="tag-x"><Icon icon="tabler:x" class="w-2.5 h-2.5" /></button></span>
              <span class="tag-rm">coding<button class="tag-x"><Icon icon="tabler:x" class="w-2.5 h-2.5" /></button></span>
            </div>
            <!-- .managed-chip (settings-registry) — success-tinted, clickable -->
            <div class="flex flex-wrap items-center gap-2 mt-2">
              <span class="managed-chip">keeper.agents:coder<button class="managed-chip-x"><Icon icon="tabler:x" class="w-2.5 h-2.5" /></button></span>
              <span class="managed-chip">keeper.tools:fetch<button class="managed-chip-x"><Icon icon="tabler:x" class="w-2.5 h-2.5" /></button></span>
            </div>
          </template>

          <!-- 12 — badge-awaiting-pulse -->
          <template v-else-if="v.id === 'badge-awaiting-pulse'">
            <div class="flex flex-wrap items-center gap-2">
              <span class="awaiting-pulse">3 awaiting</span>
              <span class="awaiting-pulse">reply →</span>
            </div>
          </template>

        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.cell {
  background: var(--p-content-background);
  border: 1px solid var(--p-content-border-color);
  border-radius: 6px;
  padding: 12px;
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.cell-head { display: flex; align-items: baseline; gap: 8px; }
.cell-head code { font-size: 11px; color: var(--p-text-color); font-weight: 600; }
.cell-name { font-size: 11px; color: var(--p-text-muted-color); }
.cell-src { font-size: 9px; color: var(--p-text-muted-color); font-family: ui-monospace, monospace; opacity: 0.7; }
.cell-body { margin-top: 8px; padding: 8px; background: var(--p-surface-50); border-radius: 4px; min-height: 64px; }

/* 1 — badge-status-tinted (MsgHeader.vue:20-24 — verbatim) */
.badge-st {
  display: inline-flex; align-items: center; gap: 4px;
  font-size: 10px;
  padding: 2px 6px;
  border-radius: 4px;
}
/* StatusBadge.vue verbatim */
.status-badge {
  display: inline-flex; align-items: center;
  column-gap: 8px;
  padding: 4px 8px;
  border-radius: 6px;
}

/* 2 — badge-kind-colored (.kind-badge from EntryDetailPanel.vue:176-182) */
.kind-badge {
  display: inline-block;
  padding: 1px 8px;
  border-radius: 3px;
  font-size: 10px;
  font-family: 'JetBrains Mono', ui-monospace, monospace;
  background: var(--p-surface-100);
  color: var(--p-text-color);
  border: 1px solid var(--p-content-border-color);
}
.op-letter {
  display: inline-flex; align-items: center; justify-content: center;
  width: 18px; height: 18px;
  font-size: 9px; font-weight: 600;
  font-family: ui-monospace, monospace;
  border-radius: 3px;
}

/* 3 — badge-count-pill */
.tab-cnt {
  font-size: 8px;
  padding: 0 4px;
  border-radius: 6px;
  background: var(--p-surface-200);
}
.hdr-count {
  font-size: 10px; font-weight: 500;
  padding: 2px 8px;
  border-radius: 12px;
  background: var(--p-surface-100);
  color: var(--p-text-muted-color);
}
.ns-count {
  padding: 0 5px;
  border-radius: 8px;
  background: var(--p-surface-200);
  color: var(--p-text-muted-color);
  font-size: 10px;
}

/* 4 — badge-data-neutral */
.chip-neutral {
  display: inline-block;
  background: var(--p-surface-200);
  color: var(--p-text-color);
  font-size: 9px;
  padding: 1px 6px;
  border-radius: 3px;
}
.model-pill {
  display: inline-block;
  font-size: 10px;
  padding: 2px 6px;
  border-radius: 4px;
  background: var(--p-surface-100);
  color: var(--p-text-muted-color);
}
.meta-pill {
  display: inline-flex; align-items: center; gap: 4px;
  font-size: 11px;
  padding: 2px 8px;
  border-radius: 4px;
  background: var(--p-surface-100);
  border: 1px solid var(--p-content-border-color);
  color: var(--p-text-muted-color);
}
.meta-pill strong { color: var(--p-text-color); font-weight: 600; }
.spec-pill {
  display: inline-flex; align-items: center; gap: 4px;
  height: 17px;
  padding: 0 5px;
  border-radius: 3px;
  font-size: 9px;
  background: var(--p-surface-100);
  border: 1px solid var(--p-content-border-color);
}
.spec-val { color: var(--p-text-color); font-weight: 700; font-variant-numeric: tabular-nums; }
.spec-lbl { color: var(--p-text-muted-color); }

/* 5 — badge-stat-pill (agents.vue:340-354 verbatim) */
.stat-pill {
  display: inline-flex; align-items: baseline; gap: 5px;
  padding: 3px 9px;
  border-radius: 4px;
  background: var(--p-surface-100);
  border: 1px solid var(--p-content-border-color);
  font-size: 11px;
  color: var(--p-text-color);
}
.stat-num { font-weight: 700; font-variant-numeric: tabular-nums; }
.stat-lbl { font-size: 10px; color: var(--p-text-muted-color); }
.hero-pill {
  display: inline-flex; align-items: center;
  font-size: 11px; font-weight: 500;
  padding: 3px 9px;
  border-radius: 4px;
}

/* 6 — badge-filter-chip (.class-chip verbatim) */
.class-chip {
  padding: 2px 8px;
  border-radius: 4px;
  font-size: 10px;
  font-weight: 500;
  background: transparent;
  color: var(--p-text-muted-color);
  border: 1px solid var(--p-content-border-color);
  cursor: pointer;
  transition: background-color 100ms, color 100ms, border-color 100ms;
}
.class-chip:hover, .class-chip[data-hover] {
  color: var(--p-text-color);
  border-color: var(--p-surface-300);
}
.class-chip--active {
  background: color-mix(in srgb, var(--cc, var(--p-primary-color)) 15%, transparent);
  color: var(--cc, var(--p-primary-color));
  border-color: color-mix(in srgb, var(--cc, var(--p-primary-color)) 40%, transparent);
}

/* 7 — badge-dot (DotBadge.vue verbatim) */
.dot { display: inline-block; border-radius: 50%; }

/* 8 — badge-icon-bubble */
.icon-bubble {
  display: inline-flex; align-items: center; justify-content: center;
  width: 20px; height: 20px;
  border-radius: 50%;
  flex-shrink: 0;
}
.agent-icon {
  display: inline-flex; align-items: center; justify-content: center;
  width: 22px; height: 22px;
  border-radius: 4px;
  background: color-mix(in srgb, var(--p-primary-color) 12%, transparent);
  color: var(--p-primary-color);
}

/* 9 — badge-kbd (.kbd from settings-registry.vue:774-783) */
.kbd {
  display: inline-block;
  padding: 0 4px;
  font-family: ui-monospace, SFMono-Regular, monospace;
  font-size: 9px;
  border: 1px solid var(--p-content-border-color);
  background: var(--p-surface-100);
  border-radius: 3px;
  color: var(--p-text-color);
}

/* 10 — badge-percentage-chip (usage.vue:266 inline-style verbatim) */
.pct-chip {
  font-size: 9px;
  padding: 2px 6px;
  border-radius: 4px;
  background: color-mix(in srgb, var(--p-text-color) 10%, transparent);
  color: var(--p-text-muted-color);
}

/* 11 — badge-removable-chip (.tag from TagsField.vue:62-82) */
.tag-rm {
  display: inline-flex; align-items: center; gap: 2px;
  padding: 1px 6px;
  border-radius: 3px;
  font-size: 10px;
  background: var(--p-surface-200);
  color: var(--p-text-color);
}
.tag-x {
  background: transparent; border: none; cursor: pointer;
  padding: 0; display: inline-flex; align-items: center;
  color: var(--p-text-muted-color);
}
.tag-x:hover { color: var(--p-danger-500); }
/* .managed-chip from settings-registry.vue:763+ */
.managed-chip {
  display: inline-flex; align-items: center; gap: 4px;
  padding: 2px 6px 2px 8px;
  border-radius: 4px;
  border: 1px solid color-mix(in srgb, var(--p-success-500) 30%, transparent);
  background: color-mix(in srgb, var(--p-success-500) 12%, transparent);
  color: var(--p-text-color);
  font-family: ui-monospace, monospace;
  font-size: 11px;
}
.managed-chip-x {
  background: transparent; border: none; cursor: pointer;
  padding: 0; display: inline-flex; align-items: center;
  color: var(--p-text-muted-color);
}
.managed-chip-x:hover { color: var(--p-danger-500); }

/* 12 — badge-awaiting-pulse (tasks.vue:503-513 verbatim) */
.awaiting-pulse {
  display: inline-flex; align-items: center;
  font-size: 10px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  padding: 2px 8px;
  border-radius: 12px;
  background: var(--p-warn-500);
  color: white;
  animation: awaiting-pulse 1.6s ease-in-out infinite;
}
@keyframes awaiting-pulse {
  0%, 100% { box-shadow: 0 0 0 0 color-mix(in srgb, var(--p-warn-500) 70%, transparent); }
  50%      { box-shadow: 0 0 0 5px color-mix(in srgb, var(--p-warn-500) 0%, transparent); }
}
</style>
