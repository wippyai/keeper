import { describe, it, expect } from 'vitest'
import { resolveEditor } from '../EditorRegistry'
import type { RegistryEntry } from '../../../api/registry'

function makeEntry(kind: string, metaType?: string): RegistryEntry {
  return {
    id: `test:${kind.replace('.', '_')}`,
    kind,
    meta: metaType ? { type: metaType } : {},
  }
}

describe('EditorRegistry', () => {
  describe('resolveEditor', () => {
    it('resolves meta.type agent.gen1 to AgentEditor', () => {
      const editor = resolveEditor(makeEntry('registry.entry', 'agent.gen1'))
      expect(editor).toBeDefined()
      expect(editor).not.toBe(resolveEditor(makeEntry('unknown.kind')))
    })

    it('resolves meta.type llm.model to LlmModelEditor', () => {
      const editor = resolveEditor(makeEntry('registry.entry', 'llm.model'))
      expect(editor).toBeDefined()
    })

    it('resolves meta.type tool to ToolEditor', () => {
      const editor = resolveEditor(makeEntry('registry.entry', 'tool'))
      expect(editor).toBeDefined()
    })

    it('resolves meta.type agent.trait to TraitEditor', () => {
      const editor = resolveEditor(makeEntry('registry.entry', 'agent.trait'))
      expect(editor).toBeDefined()
    })

    it('resolves meta.type security.policy to SecurityPolicyEditor', () => {
      const editor = resolveEditor(makeEntry('registry.entry', 'security.policy'))
      expect(editor).toBeDefined()
    })

    it('resolves meta.type env.variable to EnvVariableEditor', () => {
      const editor = resolveEditor(makeEntry('registry.entry', 'env.variable'))
      expect(editor).toBeDefined()
    })

    it('resolves meta.type view.page on registry.entry kind', () => {
      const byMeta = resolveEditor(makeEntry('registry.entry', 'view.page'))
      const byKind = resolveEditor(makeEntry('view.page'))
      expect(byMeta).toBe(byKind)
    })

    it('resolves meta.type view.component on registry.entry kind', () => {
      const byMeta = resolveEditor(makeEntry('registry.entry', 'view.component'))
      const byKind = resolveEditor(makeEntry('view.component'))
      expect(byMeta).toBe(byKind)
    })

    it('resolves meta.type http.endpoint on registry.entry kind', () => {
      const byMeta = resolveEditor(makeEntry('registry.entry', 'http.endpoint'))
      const byKind = resolveEditor(makeEntry('http.endpoint'))
      expect(byMeta).toBe(byKind)
    })

    it('resolves meta.type http.router on registry.entry kind', () => {
      const byMeta = resolveEditor(makeEntry('registry.entry', 'http.router'))
      const byKind = resolveEditor(makeEntry('http.router'))
      expect(byMeta).toBe(byKind)
    })

    it('resolves meta.type function.lua on registry.entry kind', () => {
      const byMeta = resolveEditor(makeEntry('registry.entry', 'function.lua'))
      const byKind = resolveEditor(makeEntry('function.lua'))
      expect(byMeta).toBe(byKind)
    })

    it('resolves kind function.lua to LuaEditor', () => {
      const editor = resolveEditor(makeEntry('function.lua'))
      expect(editor).toBeDefined()
    })

    it('resolves kind library.lua to LuaEditor', () => {
      const a = resolveEditor(makeEntry('function.lua'))
      const b = resolveEditor(makeEntry('library.lua'))
      expect(a).toBe(b)
    })

    it('resolves kind process.lua to LuaEditor', () => {
      const a = resolveEditor(makeEntry('function.lua'))
      const b = resolveEditor(makeEntry('process.lua'))
      expect(a).toBe(b)
    })

    it('resolves kind http.endpoint to HttpEndpointEditor', () => {
      const editor = resolveEditor(makeEntry('http.endpoint'))
      expect(editor).toBeDefined()
    })

    it('resolves kind http.router to HttpRouterEditor', () => {
      const editor = resolveEditor(makeEntry('http.router'))
      expect(editor).toBeDefined()
    })

    it('resolves kind process.host to ProcessServiceEditor', () => {
      const editor = resolveEditor(makeEntry('process.host'))
      expect(editor).toBeDefined()
    })

    it('resolves kind view.page to ViewPageEditor', () => {
      const editor = resolveEditor(makeEntry('view.page'))
      expect(editor).toBeDefined()
    })

    it('resolves kind view.component to ViewComponentEditor', () => {
      const editor = resolveEditor(makeEntry('view.component'))
      expect(editor).toBeDefined()
    })

    it('resolves kind env.variable to EnvVariableEditor', () => {
      const editor = resolveEditor(makeEntry('env.variable'))
      expect(editor).toBeDefined()
    })

    it('resolves namespace kinds to NamespaceEditor', () => {
      const a = resolveEditor(makeEntry('ns.definition'))
      const b = resolveEditor(makeEntry('ns.dependency'))
      const c = resolveEditor(makeEntry('ns.requirement'))
      expect(a).toBe(b)
      expect(b).toBe(c)
    })

    it('resolves storage kinds to StorageEditor', () => {
      const a = resolveEditor(makeEntry('store.memory'))
      const b = resolveEditor(makeEntry('db.sql.sqlite'))
      const c = resolveEditor(makeEntry('fs.directory'))
      expect(a).toBe(b)
      expect(b).toBe(c)
    })

    it('resolves contract to ContractEditor', () => {
      const editor = resolveEditor(makeEntry('contract'))
      expect(editor).toBeDefined()
    })

    it('resolves unknown kinds to GenericEditor', () => {
      const a = resolveEditor(makeEntry('completely.unknown'))
      const b = resolveEditor(makeEntry('another.unknown'))
      expect(a).toBe(b)
    })

    it('meta.type takes priority over kind for different types', () => {
      const byMeta = resolveEditor(makeEntry('function.lua', 'agent.gen1'))
      const byKind = resolveEditor(makeEntry('function.lua'))
      expect(byMeta).not.toBe(byKind)
    })
  })
})
