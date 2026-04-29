import { defineAsyncComponent, type Component } from 'vue'
import type { RegistryEntry } from '../../api/registry'

interface EditorMapping {
  component: Component
  match: (entry: RegistryEntry) => boolean
}

function metaOrKind(entry: RegistryEntry): string {
  return entry.meta?.type || entry.kind
}

const LuaEditor = defineAsyncComponent(() => import('./kinds/LuaEditor.vue'))
const HttpEndpointEditor = defineAsyncComponent(() => import('./kinds/HttpEndpointEditor.vue'))
const HttpRouterEditor = defineAsyncComponent(() => import('./kinds/HttpRouterEditor.vue'))
const AgentEditor = defineAsyncComponent(() => import('./kinds/AgentEditor.vue'))
const LlmModelEditor = defineAsyncComponent(() => import('./kinds/LlmModelEditor.vue'))
const ToolEditor = defineAsyncComponent(() => import('./kinds/ToolEditor.vue'))
const TraitEditor = defineAsyncComponent(() => import('./kinds/TraitEditor.vue'))
const SecurityPolicyEditor = defineAsyncComponent(() => import('./kinds/SecurityPolicyEditor.vue'))
const EnvVariableEditor = defineAsyncComponent(() => import('./kinds/EnvVariableEditor.vue'))
const ProcessServiceEditor = defineAsyncComponent(() => import('./kinds/ProcessServiceEditor.vue'))
const ViewPageEditor = defineAsyncComponent(() => import('./kinds/ViewPageEditor.vue'))
const ViewComponentEditor = defineAsyncComponent(() => import('./kinds/ViewComponentEditor.vue'))
const NamespaceEditor = defineAsyncComponent(() => import('./kinds/NamespaceEditor.vue'))
const ContractEditor = defineAsyncComponent(() => import('./kinds/ContractEditor.vue'))
const ContractBindingEditor = defineAsyncComponent(() => import('./kinds/ContractBindingEditor.vue'))
const StorageEditor = defineAsyncComponent(() => import('./kinds/StorageEditor.vue'))

const editors: EditorMapping[] = [
  // Agents
  {
    match: (e) => metaOrKind(e) === 'agent.gen1',
    component: AgentEditor,
  },
  {
    match: (e) => metaOrKind(e) === 'agent.trait',
    component: TraitEditor,
  },

  // LLM
  {
    match: (e) => metaOrKind(e) === 'llm.model',
    component: LlmModelEditor,
  },

  // Tools
  {
    match: (e) => metaOrKind(e) === 'tool',
    component: ToolEditor,
  },

  // Security
  {
    match: (e) => metaOrKind(e) === 'security.policy',
    component: SecurityPolicyEditor,
  },

  // Environment
  {
    match: (e) => metaOrKind(e) === 'env.variable' || e.kind === 'env.variable',
    component: EnvVariableEditor,
  },

  // Lua
  {
    match: (e) => {
      const t = metaOrKind(e)
      return ['function.lua', 'library.lua', 'process.lua'].includes(t)
    },
    component: LuaEditor,
  },

  // HTTP
  {
    match: (e) => metaOrKind(e) === 'http.endpoint',
    component: HttpEndpointEditor,
  },
  {
    match: (e) => metaOrKind(e) === 'http.router',
    component: HttpRouterEditor,
  },

  // Process
  {
    match: (e) => metaOrKind(e) === 'process.host' || e.kind === 'process.host',
    component: ProcessServiceEditor,
  },

  // Views
  {
    match: (e) => metaOrKind(e) === 'view.page',
    component: ViewPageEditor,
  },
  {
    match: (e) => metaOrKind(e) === 'view.component',
    component: ViewComponentEditor,
  },

  // Namespace
  {
    match: (e) => {
      const t = metaOrKind(e)
      return ['ns.definition', 'ns.dependency', 'ns.requirement'].includes(t)
    },
    component: NamespaceEditor,
  },

  // Contract
  {
    match: (e) => e.kind === 'contract.binding',
    component: ContractBindingEditor,
  },
  {
    match: (e) => e.kind === 'contract.definition' || metaOrKind(e) === 'contract',
    component: ContractEditor,
  },

  // Storage (by kind prefix)
  {
    match: (e) => e.kind.startsWith('store.') || e.kind.startsWith('db.') || e.kind.startsWith('fs.'),
    component: StorageEditor,
  },
]

const GenericEditor = defineAsyncComponent(() => import('./kinds/GenericEditor.vue'))

export function resolveEditor(entry: RegistryEntry): Component {
  // First pass: match with meta.type (if present)
  for (const mapping of editors) {
    if (mapping.match(entry)) return mapping.component
  }

  // Second pass: if meta.type didn't match anything, try with kind only
  if (entry.meta?.type && entry.meta.type !== entry.kind) {
    const kindOnly = { ...entry, meta: { ...entry.meta, type: undefined } } as RegistryEntry
    for (const mapping of editors) {
      if (mapping.match(kindOnly)) return mapping.component
    }
  }

  return GenericEditor
}
