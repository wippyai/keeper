<script setup lang="ts">
import { computed } from 'vue'

const props = defineProps<{ content: string; maxHeight?: string }>()

function renderMarkdown(text: string): string {
  if (!text) return ''
  let html = text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')

  // Code blocks
  html = html.replace(/```(\w*)\n([\s\S]*?)```/g, '<pre class="md-pre"><code>$2</code></pre>')
  // Inline code
  html = html.replace(/`([^`]+)`/g, '<code class="md-code">$1</code>')
  // Headers
  html = html.replace(/^#### (.+)$/gm, '<div class="md-h4">$1</div>')
  html = html.replace(/^### (.+)$/gm, '<div class="md-h3">$1</div>')
  html = html.replace(/^## (.+)$/gm, '<div class="md-h2">$1</div>')
  html = html.replace(/^# (.+)$/gm, '<div class="md-h1">$1</div>')
  // Bold + italic
  html = html.replace(/\*\*\*(.+?)\*\*\*/g, '<strong><em>$1</em></strong>')
  html = html.replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
  html = html.replace(/(?<!\*)\*([^*]+)\*(?!\*)/g, '<em>$1</em>')

  // Tables
  html = html.replace(/^(\|.+\|)\n(\|[-| :]+\|)\n((?:\|.+\|\n?)*)/gm, (_, header, sep, body) => {
    const hCells = header.split('|').filter((c: string) => c.trim())
    const bRows = body.trim().split('\n').filter((r: string) => r.trim())
    let table = '<table class="md-table"><thead><tr>'
    for (const c of hCells) table += `<th>${c.trim()}</th>`
    table += '</tr></thead><tbody>'
    for (const row of bRows) {
      const cells = row.split('|').filter((c: string) => c.trim())
      table += '<tr>'
      for (const c of cells) table += `<td>${c.trim()}</td>`
      table += '</tr>'
    }
    table += '</tbody></table>'
    return table
  })

  // Lists - wrap consecutive li items in ul
  html = html.replace(/^(\d+)\. (.+)$/gm, '<li class="md-ol">$2</li>')
  html = html.replace(/^- (.+)$/gm, '<li class="md-ul">$1</li>')
  // Wrap consecutive li elements
  html = html.replace(/((?:<li class="md-ul">.*<\/li>\n?)+)/g, '<ul class="md-list">$1</ul>')
  html = html.replace(/((?:<li class="md-ol">.*<\/li>\n?)+)/g, '<ol class="md-list">$1</ol>')

  // Paragraph + soft-break handling (but not inside pre blocks).
  // Blank line separates paragraphs; a single newline inside a paragraph is
  // a soft line break (rendered with a small gap, not a full empty line).
  // Lines that are already block-level HTML (ul/ol/li/h*/pre/table/tr/td/th)
  // stay bare to avoid wrapping them in <p>.
  const BLOCK_RE = /^\s*<\/?(?:ul|ol|li|h[1-6]|pre|table|thead|tbody|tr|td|th|div class="md-h[1-6]")/i
  const parts = html.split(/(<pre class="md-pre">[\s\S]*?<\/pre>)/)
  html = parts.map((part, i) => {
    if (i % 2 === 1) return part // pre block, leave as is
    const paras = part.split(/\n{2,}/) // blank line = paragraph break
    return paras.map(p => {
      if (!p) return ''
      if (BLOCK_RE.test(p)) return p
      return '<p>' + p.replace(/\n/g, '<br>') + '</p>'
    }).join('')
  }).join('')

  return html
}

const rendered = computed(() => renderMarkdown(props.content))
</script>

<template>
  <div class="md" :style="{ maxHeight: maxHeight || 'none', overflowY: maxHeight ? 'auto' : 'visible' }" v-html="rendered" />
</template>

<style scoped>
.md { font-size: 12px; line-height: 1.55; color: var(--p-text-color); word-break: break-word; }
.md :deep(p) { margin: 0 0 0.7em; }
.md :deep(p:last-child) { margin-bottom: 0; }
.md :deep(br) { line-height: 1; }
.md :deep(.md-h1) { font-size: 14px; font-weight: 700; margin: 1em 0 0.45em; line-height: 1.3; }
.md :deep(.md-h2) { font-size: 13px;   font-weight: 700; margin: 0.9em 0 0.4em; line-height: 1.3; }
.md :deep(.md-h3) { font-size: 12.5px; font-weight: 600; margin: 0.75em 0 0.35em; line-height: 1.3; }
.md :deep(.md-h4) { font-size: 12px;   font-weight: 600; margin: 0.65em 0 0.3em; line-height: 1.3; color: var(--p-text-muted-color); }
.md :deep(.md-h1:first-child),
.md :deep(.md-h2:first-child),
.md :deep(.md-h3:first-child),
.md :deep(.md-h4:first-child) { margin-top: 0; }
.md :deep(strong) { font-weight: 600; }
.md :deep(em) { font-style: italic; }
.md :deep(.md-list) { margin: 0.4em 0 0.7em; padding-left: 20px; }
.md :deep(li.md-ul) { list-style: disc; margin: 0.15em 0; line-height: 1.5; }
.md :deep(li.md-ol) { list-style: decimal; margin: 0.15em 0; line-height: 1.5; }
.md :deep(.md-code) { background: var(--p-surface-100); padding: 1px 5px; border-radius: 3px; font-size: 11px; font-family: monospace; }
.md :deep(.md-pre) { background: var(--p-surface-100); padding: 10px 12px; border-radius: 4px; overflow-x: auto; margin: 0.7em 0; font-size: 11px; line-height: 1.5; }
.md :deep(.md-pre code) { background: none; padding: 0; font-family: monospace; white-space: pre-wrap; font-size: 11px; }
.md :deep(.md-table) { width: 100%; border-collapse: collapse; margin: 0.7em 0; font-size: 11px; }
.md :deep(.md-table th) { text-align: left; padding: 5px 9px; font-weight: 600; border-bottom: 2px solid var(--p-surface-200); color: var(--p-text-muted-color); }
.md :deep(.md-table td) { padding: 4px 9px; border-bottom: 1px solid var(--p-surface-100); vertical-align: top; }
.md :deep(.md-table tr:hover td) { background: var(--p-surface-50); }
</style>
