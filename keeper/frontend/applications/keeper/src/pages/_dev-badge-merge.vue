<script setup lang="ts">
import { Icon } from '@iconify/vue'
import Tag from 'primevue/tag'

// Companion to _dev-badge-gallery.vue — shows MERGE CANDIDATE pairs.
// Each row: hand-rolled A | hand-rolled B | proposed unified.
// Use to decide whether two near-identical variants are worth a single
// `.k-tag-*` class (sacrificing 1-2 px of metric drift) vs two dedicated
// classes (preserving byte-identity at the cost of API clutter).
// REMOVE in BD-B5 cleanup.
</script>

<template>
  <div class="p-4 flex flex-col gap-4" style="background: var(--p-content-background); min-height: 100vh">
    <header>
      <h1 class="text-base font-bold" style="color: var(--p-danger-500)">
        TEMP — Badge merge-candidate visual review
      </h1>
      <p class="text-xs mt-1" style="color: var(--p-text-muted-color)">
        Each row shows two near-identical hand-rolled variants and a proposed unified form.
        Sacrifice = the small metric drift from merging. Eye-check whether the unification reads
        as "the same control" or as "lost identity."
      </p>
    </header>

    <!-- Candidate A — count-md (ns-count 10px rounded-8) vs count-pill (hdr-count 10px rounded-12) -->
    <section class="cand">
      <div class="cand-head">
        <code>A · count-md ↔ count-pill</code>
        <span class="cand-sub">Both 10px muted-text counter pills. Only bg + radius differ.</span>
      </div>
      <div class="cand-grid">
        <div class="cand-cell">
          <div class="cand-lbl">A1 · .ns-count (surface-200, 8px radius)</div>
          <div class="flex items-center gap-2"><span class="text-xs">Namespace</span><span class="ns-count">8</span></div>
          <div class="flex items-center gap-2 mt-1"><span class="text-xs">Sessions</span><span class="ns-count">42</span></div>
          <div class="metrics">10px · 0 5px · r8 · surface-200 · muted</div>
        </div>
        <div class="cand-cell">
          <div class="cand-lbl">A2 · .hdr-count (surface-100, 12px radius, weight 500)</div>
          <div class="flex items-center gap-2"><span class="text-xs">Tasks</span><span class="hdr-count">47</span></div>
          <div class="flex items-center gap-2 mt-1"><span class="text-xs">Endpoints</span><span class="hdr-count">140</span></div>
          <div class="metrics">10px · 2px 8px · r12 · surface-100 · muted · 500</div>
        </div>
        <div class="cand-cell cand-proposed">
          <div class="cand-lbl">A* · proposed merged (.k-tag-count)</div>
          <div class="flex items-center gap-2"><span class="text-xs">Namespace</span><Tag class="merged-count">8</Tag></div>
          <div class="flex items-center gap-2 mt-1"><span class="text-xs">Sessions</span><Tag class="merged-count">42</Tag></div>
          <div class="flex items-center gap-2 mt-1"><span class="text-xs">Tasks</span><Tag class="merged-count">47</Tag></div>
          <div class="flex items-center gap-2 mt-1"><span class="text-xs">Endpoints</span><Tag class="merged-count">140</Tag></div>
          <div class="metrics">10px · 2px 7px · r10 · surface-100 · muted · 500 (compromise)</div>
        </div>
      </div>
    </section>

    <!-- Candidate B — count-sm (8px tab-cnt) vs count-md (10px ns-count) -->
    <section class="cand">
      <div class="cand-head">
        <code>B · count-sm ↔ count-md</code>
        <span class="cand-sub">tab-cnt is 8px (tiny); ns-count is 10px. Both surface-200 neutral. Merging means tab-cnt grows ~2px.</span>
      </div>
      <div class="cand-grid">
        <div class="cand-cell">
          <div class="cand-lbl">B1 · .tab-cnt (8px, surface-200, r6, text-color)</div>
          <div class="flex items-center gap-2"><span class="text-xs">Delegates</span><span class="tab-cnt">3</span></div>
          <div class="flex items-center gap-2 mt-1"><span class="text-xs">Traits</span><span class="tab-cnt">9</span></div>
          <div class="flex items-center gap-2 mt-1"><span class="text-xs">Tools</span><span class="tab-cnt">12</span></div>
          <div class="metrics">8px · 0 4px · r6 · surface-200 · text-color</div>
        </div>
        <div class="cand-cell">
          <div class="cand-lbl">B2 · .ns-count (10px, surface-200, r8, muted)</div>
          <div class="flex items-center gap-2"><span class="text-xs">Namespace</span><span class="ns-count">8</span></div>
          <div class="metrics">10px · 0 5px · r8 · surface-200 · muted</div>
        </div>
        <div class="cand-cell cand-proposed">
          <div class="cand-lbl">B* · merged at 10px (tab-cnt loses 2px of "tiny")</div>
          <div class="flex items-center gap-2"><span class="text-xs">Delegates</span><Tag class="merged-count-md">3</Tag></div>
          <div class="flex items-center gap-2 mt-1"><span class="text-xs">Traits</span><Tag class="merged-count-md">9</Tag></div>
          <div class="flex items-center gap-2 mt-1"><span class="text-xs">Tools</span><Tag class="merged-count-md">12</Tag></div>
          <div class="flex items-center gap-2 mt-1"><span class="text-xs">Namespace</span><Tag class="merged-count-md">8</Tag></div>
          <div class="metrics">10px · 0 5px · r8 · surface-200 · muted</div>
        </div>
      </div>
    </section>

    <!-- Candidate C — count-sm at 8px vs proposed at 9px (smaller compromise) -->
    <section class="cand">
      <div class="cand-head">
        <code>C · same as B but 9px compromise</code>
        <span class="cand-sub">If 10px is too big for tab-cnt context, try 9px (saves the "denser than ns-count" feel).</span>
      </div>
      <div class="cand-grid">
        <div class="cand-cell">
          <div class="cand-lbl">C1 · .tab-cnt original 8px</div>
          <div class="flex items-center gap-2"><span class="text-xs">Delegates</span><span class="tab-cnt">3</span></div>
          <div class="flex items-center gap-2 mt-1"><span class="text-xs">Traits</span><span class="tab-cnt">9</span></div>
          <div class="metrics">8px · 0 4px · r6</div>
        </div>
        <div class="cand-cell cand-proposed">
          <div class="cand-lbl">C* · merged at 9px</div>
          <div class="flex items-center gap-2"><span class="text-xs">Delegates</span><Tag class="merged-count-9">3</Tag></div>
          <div class="flex items-center gap-2 mt-1"><span class="text-xs">Traits</span><Tag class="merged-count-9">9</Tag></div>
          <div class="flex items-center gap-2 mt-1"><span class="text-xs">Namespace</span><Tag class="merged-count-9">8</Tag></div>
          <div class="metrics">9px · 0 5px · r7 · surface-200 · muted</div>
        </div>
        <div class="cand-cell">
          <div class="cand-lbl">C2 · ns-count original 10px</div>
          <div class="flex items-center gap-2"><span class="text-xs">Namespace</span><span class="ns-count">8</span></div>
          <div class="metrics">10px · 0 5px · r8</div>
        </div>
      </div>
    </section>

    <!-- Candidate D — tint-10 (status-tinted) vs tint-15 (hero-pill) -->
    <section class="cand">
      <div class="cand-head">
        <code>D · tint-10 ↔ tint-15</code>
        <span class="cand-sub">Both severity-tinted pills. status-tinted is 10% bg / 10px / 2px 6px; hero-pill is 15% bg / 11px / 3px 9px. Both no border.</span>
      </div>
      <div class="cand-grid">
        <div class="cand-cell">
          <div class="cand-lbl">D1 · .badge-st (10%, 10px)</div>
          <div class="flex flex-wrap items-center gap-2">
            <span class="badge-st" style="background: color-mix(in srgb, var(--p-success-500) 10%, transparent); color: var(--p-success-500)"><Icon icon="tabler:check" class="w-3 h-3" /> ok</span>
            <span class="badge-st" style="background: color-mix(in srgb, var(--p-warn-500) 10%, transparent); color: var(--p-warn-500)"><Icon icon="tabler:alert-triangle" class="w-3 h-3" /> warn</span>
            <span class="badge-st" style="background: color-mix(in srgb, var(--p-danger-500) 10%, transparent); color: var(--p-danger-500)"><Icon icon="tabler:x" class="w-3 h-3" /> error</span>
          </div>
          <div class="metrics">10px · 2px 6px · 10% bg</div>
        </div>
        <div class="cand-cell">
          <div class="cand-lbl">D2 · .hero-pill (15%, 11px)</div>
          <div class="flex flex-wrap items-center gap-2">
            <span class="hero-pill" style="background: color-mix(in srgb, var(--p-warn-500) 15%, transparent); color: var(--p-warn-500)">3 blocked</span>
            <span class="hero-pill" style="background: color-mix(in srgb, var(--p-success-500) 15%, transparent); color: var(--p-success-500)">31 ✓</span>
            <span class="hero-pill" style="background: color-mix(in srgb, var(--p-info-500) 15%, transparent); color: var(--p-info-500)">→ 4.2k</span>
          </div>
          <div class="metrics">11px · 3px 9px · 15% bg · 500</div>
        </div>
        <div class="cand-cell cand-proposed">
          <div class="cand-lbl">D* · merged at 12% / 11px / 2px 7px</div>
          <div class="flex flex-wrap items-center gap-2">
            <Tag severity="success" class="merged-tint"><Icon icon="tabler:check" class="w-3 h-3" /> ok</Tag>
            <Tag severity="warn" class="merged-tint"><Icon icon="tabler:alert-triangle" class="w-3 h-3" /> warn</Tag>
            <Tag severity="danger" class="merged-tint"><Icon icon="tabler:x" class="w-3 h-3" /> error</Tag>
          </div>
          <div class="flex flex-wrap items-center gap-2 mt-2">
            <Tag severity="warn" class="merged-tint">3 blocked</Tag>
            <Tag severity="success" class="merged-tint">31 ✓</Tag>
            <Tag severity="info" class="merged-tint">→ 4.2k</Tag>
          </div>
          <div class="metrics">11px · 2px 7px · 12% bg (compromise)</div>
        </div>
      </div>
    </section>

    <!-- Candidate E — kind-badge bordered vs spec-pill bordered -->
    <section class="cand">
      <div class="cand-head">
        <code>E · kind-badge ↔ spec-pill (both bordered surface-100)</code>
        <span class="cand-sub">Both are bordered surface-100 pills. kind-badge is mono 10px 3px-radius; spec-pill is sans 9px 3px-radius with FIXED 17px height. Different fonts make merging awkward.</span>
      </div>
      <div class="cand-grid">
        <div class="cand-cell">
          <div class="cand-lbl">E1 · .kind-badge (mono, 10px, no fixed height)</div>
          <div class="flex flex-wrap items-center gap-2">
            <span class="kind-badge">agent.gen1</span>
            <span class="kind-badge">function.lua</span>
          </div>
          <div class="metrics">10px mono · 1px 8px · r3 · bordered</div>
        </div>
        <div class="cand-cell">
          <div class="cand-lbl">E2 · .spec-pill (sans, 9px, FIXED 17px h, two-tone inner)</div>
          <div class="flex flex-wrap items-center gap-2">
            <span class="spec-pill"><span class="spec-val">128</span><span class="spec-lbl">tools</span></span>
            <span class="spec-pill"><span class="spec-val">12</span><span class="spec-lbl">traits</span></span>
          </div>
          <div class="metrics">9px sans · 0 5px · r3 · h17 fixed · bordered</div>
        </div>
        <div class="cand-cell">
          <div class="cand-lbl" style="color: var(--p-danger-500)">verdict: keep separate</div>
          <div class="text-[10px]" style="color: var(--p-text-muted-color)">
            Different fonts (mono vs sans) and the spec-pill's two-tone inner content (`.spec-val` bold + `.spec-lbl` muted) make these intrinsically different. Merging would force one to lose its identity.
          </div>
        </div>
      </div>
    </section>

    <!-- Candidate F — op-letter as .k-tag-letter standalone vs .k-tag-tint with size overrides -->
    <section class="cand">
      <div class="cand-head">
        <code>F · op-letter standalone class vs reusing .k-tag-tint</code>
        <span class="cand-sub">op-letter is a tinted 18×18 single-char square. Could it just be `.k-tag-tint` with `!w-[18px] !h-[18px] !p-0` overrides?</span>
      </div>
      <div class="cand-grid">
        <div class="cand-cell">
          <div class="cand-lbl">F1 · .k-tag-letter dedicated class</div>
          <div class="flex flex-wrap items-center gap-2">
            <Tag severity="success" class="k-tag-letter">A</Tag>
            <Tag severity="info" class="k-tag-letter">M</Tag>
            <Tag severity="danger" class="k-tag-letter">D</Tag>
          </div>
          <div class="metrics">9px mono · 18×18 · centered</div>
        </div>
        <div class="cand-cell">
          <div class="cand-lbl">F2 · .k-tag-tint + Tailwind ! overrides</div>
          <div class="flex flex-wrap items-center gap-2">
            <Tag severity="success" class="k-tag-tint !w-[18px] !h-[18px] !p-0 !text-[9px] !font-semibold !rounded-[3px] !font-mono">A</Tag>
            <Tag severity="info" class="k-tag-tint !w-[18px] !h-[18px] !p-0 !text-[9px] !font-semibold !rounded-[3px] !font-mono">M</Tag>
            <Tag severity="danger" class="k-tag-tint !w-[18px] !h-[18px] !p-0 !text-[9px] !font-semibold !rounded-[3px] !font-mono">D</Tag>
          </div>
          <div class="metrics">7 !-prefix Tailwind utilities per call site</div>
        </div>
        <div class="cand-cell">
          <div class="cand-lbl" style="color: var(--p-warn-500)">verdict: keep .k-tag-letter</div>
          <div class="text-[10px]" style="color: var(--p-text-muted-color)">
            5-7 !-prefix utilities per call site is uglier than a 7-line CSS class. The dedicated class is cleaner ergonomics for ~3-5 call sites (changes.vue op-letter).
          </div>
        </div>
      </div>
    </section>

  </div>
</template>

<style scoped>
.cand {
  background: var(--p-content-background);
  border: 1px solid var(--p-content-border-color);
  border-radius: 6px;
  padding: 12px;
}
.cand-head { display: flex; flex-direction: column; gap: 4px; margin-bottom: 12px; }
.cand-head code { font-size: 12px; font-weight: 700; color: var(--p-text-color); }
.cand-sub { font-size: 11px; color: var(--p-text-muted-color); }
.cand-grid {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
  gap: 12px;
}
.cand-cell {
  padding: 10px;
  background: var(--p-surface-50);
  border-radius: 4px;
  border: 1px dashed var(--p-content-border-color);
}
.cand-proposed {
  background: color-mix(in srgb, var(--p-primary-color) 5%, var(--p-surface-50));
  border-color: var(--p-primary-color);
  border-style: solid;
}
.cand-lbl {
  font-size: 10px;
  font-weight: 600;
  color: var(--p-text-color);
  margin-bottom: 6px;
}
.cand-proposed .cand-lbl { color: var(--p-primary-color); }
.metrics {
  margin-top: 8px;
  font-size: 9px;
  font-family: ui-monospace, monospace;
  color: var(--p-text-muted-color);
  opacity: 0.8;
}

/* Reference styles (verbatim from gallery) */
.badge-st { display: inline-flex; align-items: center; gap: 4px; font-size: 10px; padding: 2px 6px; border-radius: 4px; }
.tab-cnt { font-size: 8px; padding: 0 4px; border-radius: 6px; background: var(--p-surface-200); color: var(--p-text-color); }
.hdr-count { font-size: 10px; font-weight: 500; padding: 2px 8px; border-radius: 12px; background: var(--p-surface-100); color: var(--p-text-muted-color); }
.ns-count { padding: 0 5px; border-radius: 8px; background: var(--p-surface-200); color: var(--p-text-muted-color); font-size: 10px; }
.kind-badge { display: inline-block; padding: 1px 8px; border-radius: 3px; font-size: 10px; font-family: 'JetBrains Mono', ui-monospace, monospace; background: var(--p-surface-100); color: var(--p-text-color); border: 1px solid var(--p-content-border-color); }
.spec-pill { display: inline-flex; align-items: center; gap: 4px; height: 17px; padding: 0 5px; border-radius: 3px; font-size: 9px; background: var(--p-surface-100); border: 1px solid var(--p-content-border-color); }
.spec-val { color: var(--p-text-color); font-weight: 700; font-variant-numeric: tabular-nums; }
.spec-lbl { color: var(--p-text-muted-color); }
.hero-pill { display: inline-flex; align-items: center; font-size: 11px; font-weight: 500; padding: 3px 9px; border-radius: 4px; }

/* Proposed merged styles */
.p-tag.merged-count {
  font-size: 10px;
  font-weight: 500;
  padding: 2px 7px;
  border-radius: 10px;
  background: var(--p-surface-100);
  color: var(--p-text-muted-color);
  border: 0;
  gap: 0;
}
.p-tag.merged-count-md {
  font-size: 10px;
  font-weight: 400;
  padding: 0 5px;
  border-radius: 8px;
  background: var(--p-surface-200);
  color: var(--p-text-muted-color);
  border: 0;
  gap: 0;
}
.p-tag.merged-count-9 {
  font-size: 9px;
  font-weight: 400;
  padding: 0 5px;
  border-radius: 7px;
  background: var(--p-surface-200);
  color: var(--p-text-muted-color);
  border: 0;
  gap: 0;
}
.p-tag.merged-tint {
  font-size: 11px;
  font-weight: 500;
  padding: 2px 7px;
  border-radius: 4px;
  border: 0;
  gap: 4px;
}
.p-tag.merged-tint.p-tag-success { background: color-mix(in srgb, var(--p-success-500) 12%, transparent); color: var(--p-success-500); }
.p-tag.merged-tint.p-tag-warn    { background: color-mix(in srgb, var(--p-warn-500) 12%, transparent); color: var(--p-warn-500); }
.p-tag.merged-tint.p-tag-danger  { background: color-mix(in srgb, var(--p-danger-500) 12%, transparent); color: var(--p-danger-500); }
.p-tag.merged-tint.p-tag-info    { background: color-mix(in srgb, var(--p-info-500) 12%, transparent); color: var(--p-info-500); }
</style>
