// @vitest-environment happy-dom
import { mount, flushPromises } from '@vue/test-utils'
import { describe, expect, it, vi } from 'vitest'
import HubInstallDialog from '../HubInstallDialog.vue'

vi.mock('@iconify/vue', () => ({Icon: {name: 'Icon', template: '<span />'}}))

const api = vi.hoisted(() => ({post: vi.fn(), get: vi.fn()}))
vi.mock('../../../composables/useWippy', () => ({useApi: () => api}))
vi.mock('../../../api/registry', () => ({listEntries: vi.fn().mockResolvedValue({entries: []}), kindIcon: () => 'tabler:box'}))

function plan(value = '', reason?: string) {
  return {success: true, dependency: {id: 'app.deps:example'},
    graph: [{module: 'acme/example', depth: 0}], missing_requirements: value ? [] : ['acme.example:scope'],
    requirements: [{name: 'scope', parameter_name: 'acme.example:scope', module: 'acme/example',
      expected_kind: 'security.scope', required: true, missing: !value, value,
      value_source: value ? 'llm' : 'empty', choice_reason: reason,
      suggestions: [{value: 'host:primary'}, {value: 'host:secondary'}]}],
    install_payload: {component: 'acme/example', parameters: value ? [{name: 'acme.example:scope', value}] : []}}
}

function transitivePlan(value = '', reason?: string) {
  return {success: true, dependency: {id: 'app.deps:example'},
    graph: [{module: 'acme/example', depth: 0}, {module: 'acme/child', depth: 1, parent: 'acme/example'}],
    missing_requirements: value ? [] : ['acme.child:scope'],
    requirements: [{name: 'scope', parameter_name: 'acme.child:scope', module: 'acme/child',
      transitive: true, expected_kind: 'security.scope', required: true, missing: !value, value,
      value_source: value ? 'llm' : 'empty', choice_reason: reason,
      suggestions: [{value: 'host:primary'}, {value: 'host:secondary'}]}],
    install_payload: {component: 'acme/example',
      requirement_bindings: value ? [{name: 'acme.child:scope', value}] : []}}
}

async function open() {
  api.get.mockImplementation(async (url: string) => ({data: url.includes('/registry/') ? {entries: [], kinds: []} : {dependencies: [], modules: []}}))
  const wrapper = mount(HubInstallDialog, {props: {modelValue: false, component: 'acme/example'},
    global: {stubs: {Teleport: true, Icon: true}}})
  await wrapper.setProps({modelValue: true})
  await flushPromises()
  return wrapper
}

describe('Hub install Fill gaps review', () => {
  it('fills only on click, shows the reason, keeps values editable, and waits for apply', async () => {
    api.post.mockReset().mockImplementation(async (url: string) => ({data:
      url.endsWith('/fill-gaps') ? plan('host:secondary', 'Secondary serves this audience.') : plan()}))
    const wrapper = await open()
    expect(api.post).toHaveBeenCalledTimes(1)
    const fill = wrapper.findAll('button').find(b => b.text() === 'Fill gaps')!
    expect(fill).toBeDefined()
    await fill.trigger('click')
    await flushPromises()
    expect(api.post).toHaveBeenLastCalledWith('/api/v1/keeper/hub/dependencies/fill-gaps', expect.objectContaining({component: 'acme/example'}))
    expect(wrapper.text()).toContain('Secondary serves this audience.')
    const input = wrapper.findComponent({name: 'RequirementValueInput'})
    expect(input.props('modelValue')).toBe('host:secondary')
    input.vm.$emit('update:model-value', 'host:primary')
    await flushPromises()
    expect(wrapper.findComponent({name: 'RequirementValueInput'}).props('modelValue')).toBe('host:primary')
    expect(api.post.mock.calls.some(([url]) => url.endsWith('/install'))).toBe(false)
    wrapper.unmount()
  })

  it('keeps Apply blocked when the model leaves a required gap', async () => {
    api.post.mockReset().mockResolvedValue({data: plan()})
    const wrapper = await open()
    await wrapper.findAll('button').find(b => b.text() === 'Fill gaps')!.trigger('click')
    await flushPromises()
    const install = wrapper.findAll('button').find(b => b.text() === 'Install')!
    expect(install.attributes('disabled')).toBeDefined()
    expect(wrapper.findComponent({name: 'RequirementValueInput'}).props('modelValue')).toBe('')
    wrapper.unmount()
  })

  it('reviews an editable transitive fill, replans it on commit, and includes it only in the reviewed install', async () => {
    api.post.mockReset().mockImplementation(async (url: string, payload?: any) => {
      if (url.endsWith('/fill-gaps')) return {data: transitivePlan('host:secondary', 'Secondary serves this audience.')}
      if (url.endsWith('/plan')) {
        const selected = payload?.requirement_bindings?.[0]?.value || ''
        return {data: transitivePlan(selected)}
      }
      if (url.endsWith('/install')) return {data: {success: true}}
      throw new Error(`Unexpected endpoint ${url}`)
    })
    const wrapper = await open()
    await wrapper.findAll('button').find(b => b.text() === 'Fill gaps')!.trigger('click')
    await flushPromises()

    let input = wrapper.findComponent({name: 'RequirementValueInput'})
    expect(input.props('modelValue')).toBe('host:secondary')
    input.vm.$emit('update:model-value', 'host:primary')
    input.vm.$emit('commit')
    await flushPromises()

    expect(api.post).toHaveBeenLastCalledWith('/api/v1/keeper/hub/dependencies/plan', expect.objectContaining({
      requirement_bindings: [{name: 'acme.child:scope', value: 'host:primary'}],
    }))
    input = wrapper.findComponent({name: 'RequirementValueInput'})
    expect(input.props('modelValue')).toBe('host:primary')

    await wrapper.findAll('button').find(b => b.text() === 'Skip')!.trigger('click')
    await wrapper.findAll('button').find(b => b.text() === 'Install')!.trigger('click')
    await flushPromises()
    expect(api.post).toHaveBeenLastCalledWith('/api/v1/keeper/hub/dependencies/install', expect.objectContaining({
      requirement_bindings: [{name: 'acme.child:scope', value: 'host:primary'}],
    }))
    wrapper.unmount()
  })
})
