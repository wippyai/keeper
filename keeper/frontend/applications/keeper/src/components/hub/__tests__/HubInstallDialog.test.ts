// @vitest-environment happy-dom
import { mount, flushPromises, config } from '@vue/test-utils'
import PrimeVue from 'primevue/config'
config.global.plugins = [PrimeVue]

import { describe, expect, it, vi } from 'vitest'
import HubInstallDialog from '../HubInstallDialog.vue'

vi.mock('@iconify/vue', () => ({Icon: {name: 'Icon', template: '<span />'}}))

const api = vi.hoisted(() => ({post: vi.fn(), get: vi.fn()}))
vi.mock('../../../composables/useWippy', () => ({useApi: () => api}))
vi.mock('../../../api/registry', () => ({listEntries: vi.fn().mockResolvedValue({entries: []}), kindIcon: () => 'tabler:box'}))

function plan(value = '', reason?: string) {
  return {success: true, dependency: {id: 'app.deps:example'},
    graph: [{module: 'acme/example', depth: 0}], missing_requirements: value ? [] : ['acme.example:scope'],
    requirements: [{name: 'scope', full_id: 'acme.example:scope', parameter_name: 'acme.example:scope', module: 'acme/example',
      expected_kind: 'security.scope', required: true, missing: !value, value,
      value_source: value ? 'llm' : 'empty', choice_reason: reason,
      suggestions: [{value: 'host:primary'}, {value: 'host:secondary'}]}],
    install_payload: {component: 'acme/example', parameters: value ? [{name: 'acme.example:scope', value}] : []}}
}

function transitivePlan(value = '', reason?: string) {
  return {success: true, dependency: {id: 'app.deps:example'},
    graph: [{module: 'acme/example', depth: 0}, {module: 'acme/child', depth: 1, parent: 'acme/example'}],
    missing_requirements: value ? [] : ['acme.child:scope'],
    requirements: [{name: 'scope', full_id: 'acme.child:scope', parameter_name: 'acme.child:scope', module: 'acme/child',
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
  it('blocks dismissal during apply and closes the modal after a successful install', async () => {
    let completeInstall!: (value: any) => void
    api.post.mockReset().mockImplementation(async (url: string) => {
      if (url.endsWith('/install')) return new Promise(resolve => { completeInstall = resolve })
      return {data: plan('host:primary')}
    })
    const wrapper = await open()
    await wrapper.findAll('button').find(b => b.text() === 'Skip')!.trigger('click')
    await wrapper.findAll('button').find(b => b.text() === 'Install')!.trigger('click')
    await flushPromises()
    expect(wrapper.findAll('button').find(b => b.text() === 'Cancel')!.attributes('disabled')).toBeDefined()
    expect(wrapper.emitted('update:modelValue')).toBeUndefined()
    completeInstall({data: {success: true}})
    await flushPromises()
    expect(wrapper.emitted('installed')).toEqual([['acme/example']])
    expect(wrapper.emitted('update:modelValue')).toEqual([[false]])
    wrapper.unmount()
  })
  it('keeps an unchanged reviewed plan current when the requirement input loses focus before AI suggestion', async () => {
    api.post.mockReset().mockImplementation(async (url: string) => ({data:
      url.endsWith('/fill-gaps') ? plan('host:secondary', 'Secondary serves this audience.') : plan()}))
    const wrapper = await open()
    await wrapper.findComponent({name: 'RequirementValueInput'}).find('input').trigger('blur')
    await flushPromises()
    expect(api.post).toHaveBeenCalledTimes(1)
    await wrapper.findAll('button').find(b => b.text() === 'Suggest with AI')!.trigger('click')
    await flushPromises()
    expect(api.post).toHaveBeenLastCalledWith('/api/v1/keeper/hub/dependencies/fill-gaps',
      expect.objectContaining({requirement_ids: ['acme.example:scope']}))
    expect(wrapper.text()).toContain('Secondary serves this audience.')
    wrapper.unmount()
  })
  it('fills only on click, shows the reason, keeps values editable, and waits for apply', async () => {
    api.post.mockReset().mockImplementation(async (url: string) => ({data:
      url.endsWith('/fill-gaps') ? plan('host:secondary', 'Secondary serves this audience.') : plan(api.post.mock.calls.slice(-1)[0]?.[1]?.parameters?.[0]?.value || '')}))
    const wrapper = await open()
    expect(api.post).toHaveBeenCalledTimes(1)
    const fill = wrapper.findAll('button').find(b => b.text() === 'Suggest with AI')!
    expect(fill).toBeDefined()
    await fill.trigger('click')
    await flushPromises()
    expect(api.post).toHaveBeenLastCalledWith('/api/v1/keeper/hub/dependencies/fill-gaps', expect.objectContaining({component: 'acme/example'}))
    expect(wrapper.text()).toContain('Secondary serves this audience.')
    expect(wrapper.findComponent({name: 'RequirementValueInput'}).props('modelValue')).toBe('')
    await wrapper.findAll('button').find(b => b.text() === 'Accept suggestion')!.trigger('click')
    await flushPromises()
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
    await wrapper.findAll('button').find(b => b.text() === 'Suggest with AI')!.trigger('click')
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
    await wrapper.findAll('button').find(b => b.text() === 'Suggest with AI')!.trigger('click')
    await flushPromises()

    expect(wrapper.findComponent({name: 'RequirementValueInput'}).props('modelValue')).toBe('')
    await wrapper.findAll('button').find(b => b.text() === 'Accept all')!.trigger('click')
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

  it('keeps typed false and zero values in the final reviewed payload', async () => {
    api.post.mockReset().mockImplementation(async (url: string) => {
      if (url.endsWith('/install')) return {data: {success: true}}
      return {data: {...plan('host:primary'), requirements: [
        {name: 'enabled', full_id: 'acme.example:enabled', parameter_name: 'acme.example:enabled',
          module: 'acme/example', expected_type: 'boolean', required: true, value: false},
        {name: 'count', full_id: 'acme.example:count', parameter_name: 'acme.example:count',
          module: 'acme/example', expected_type: 'integer', required: true, value: 0},
      ]}}
    })
    const wrapper = await open()
    await wrapper.findAll('button').find(b => b.text() === 'Skip')!.trigger('click')
    await wrapper.findAll('button').find(b => b.text() === 'Install')!.trigger('click')
    await flushPromises()
    expect(api.post).toHaveBeenLastCalledWith('/api/v1/keeper/hub/dependencies/install', expect.objectContaining({
      parameters: [{name: 'acme.example:enabled', value: false}, {name: 'acme.example:count', value: 0}],
    }))
    wrapper.unmount()
  })


  it('hides AI when no gaps remain and shows the final bindings', async () => {
    api.post.mockReset().mockResolvedValue({data: plan('host:primary')})
    const wrapper = await open()
    expect(wrapper.findAll('button').some(b => b.text() === 'Suggest with AI')).toBe(false)
    expect(wrapper.findComponent({name: 'RequirementValueInput'}).props('modelValue')).toBe('host:primary')
    wrapper.unmount()
  })

  it('requests exactly unfilled rows and keeps proposals pending until accepted', async () => {
    api.post.mockReset().mockImplementation(async (url: string) => ({data:
      url.endsWith('/fill-gaps') ? plan('host:secondary', 'A valid candidate.') : plan()}))
    const wrapper = await open()
    await wrapper.findAll('button').find(b => b.text() === 'Suggest with AI')!.trigger('click')
    await flushPromises()
    expect(api.post).toHaveBeenLastCalledWith('/api/v1/keeper/hub/dependencies/fill-gaps', expect.objectContaining({
      requirement_ids: ['acme.example:scope'],
    }))
    expect(wrapper.text()).toContain('AI')
    expect(wrapper.text()).toContain('host:secondary')
    expect(wrapper.findComponent({name: 'RequirementValueInput'}).props('modelValue')).toBe('')
    await wrapper.findAll('button').find(b => b.text() === 'Reject suggestion')!.trigger('click')
    expect(wrapper.text()).not.toContain('A valid candidate.')
    expect(wrapper.findComponent({name: 'RequirementValueInput'}).props('modelValue')).toBe('')
    expect(api.post.mock.calls.some(([url]) => url.endsWith('/install'))).toBe(false)
    wrapper.unmount()
  })

  it('lets the user edit a pending suggestion and validates the edited value', async () => {
    api.post.mockReset().mockImplementation(async (url: string, payload?: any) => ({data:
      url.endsWith('/fill-gaps') ? plan('host:secondary', 'A valid candidate.') : plan(payload?.parameters?.[0]?.value || '')}))
    const wrapper = await open()
    await wrapper.findAll('button').find(b => b.text() === 'Suggest with AI')!.trigger('click')
    await flushPromises()
    await wrapper.findAll('button').find(b => b.text() === 'Edit suggestion')!.trigger('click')
    const input = wrapper.findComponent({name: 'RequirementValueInput'})
    input.vm.$emit('update:model-value', 'host:primary')
    input.vm.$emit('commit')
    await flushPromises()
    expect(input.props('modelValue')).toBe('host:primary')
    expect(wrapper.text()).not.toContain('A valid candidate.')
    expect(api.post).toHaveBeenLastCalledWith('/api/v1/keeper/hub/dependencies/plan', expect.objectContaining({
      parameters: [{name: 'acme.example:scope', value: 'host:primary'}],
    }))
    wrapper.unmount()
  })

  it.each(['UNAVAILABLE', 'INVALID_CHOICE'])('explains %s without disabling manual input', async code => {
    const failed = plan()
    Object.assign(failed.requirements[0], {resolution_error: {code, message: 'Configure a fast model or select a value manually.'}})
    api.post.mockReset().mockResolvedValue({data: failed})
    const wrapper = await open()
    await wrapper.findAll('button').find(b => b.text() === 'Suggest with AI')!.trigger('click')
    await flushPromises()
    expect(wrapper.text()).toContain('Configure a fast model')
    expect(wrapper.findComponent({name: 'RequirementValueInput'}).props('disabled')).not.toBe(true)
    wrapper.unmount()
  })

  it('explains failed requests and preserves the manual plan', async () => {
    api.post.mockReset().mockImplementation(async (url: string) => {
      if (url.endsWith('/fill-gaps')) throw new Error('Model service unavailable')
      return {data: plan()}
    })
    const wrapper = await open()
    await wrapper.findAll('button').find(b => b.text() === 'Suggest with AI')!.trigger('click')
    await flushPromises()
    expect(wrapper.text()).toContain('Model service unavailable')
    expect(wrapper.findComponent({name: 'RequirementValueInput'}).props('modelValue')).toBe('')
    wrapper.unmount()
  })

  it.each(['/plan', '/fill-gaps'])('surfaces typed native failures from %s without applying', async endpoint => {
    const failure = {response: {data: {code: 'Internal', error: 'Failed to expand changeset',
      details: {cause: '<script>unresolved requirement</script>'}}}}
    api.post.mockReset().mockImplementation(async (url: string) => {
      if (url.endsWith(endpoint)) throw failure
      return {data: plan()}
    })
    const wrapper = await open()
    if (endpoint === '/fill-gaps') {
      await wrapper.findAll('button').find(b => b.text() === 'Suggest with AI')!.trigger('click')
      await flushPromises()
    }
    const alert = wrapper.find('[role="alert"]')
    expect(alert.exists()).toBe(true)
    expect(alert.text()).toContain('Internal: Failed to expand changeset')
    expect(alert.find('summary').text()).toBe('Error details')
    expect(alert.find('pre').text()).toContain('<script>unresolved requirement</script>')
    expect(alert.find('script').exists()).toBe(false)
    expect(wrapper.findAll('button').find(b => b.text() === 'Install')!.attributes('disabled')).toBeDefined()
    expect(api.post.mock.calls.some(([url]) => url.endsWith('/install'))).toBe(false)
    if (endpoint === '/fill-gaps') {
      expect(wrapper.findComponent({name: 'RequirementValueInput'}).props('disabled')).not.toBe(true)
    }
    wrapper.unmount()
  })

  it('keeps install disabled after a plan error', async () => {
    api.post.mockReset().mockRejectedValue(new Error('Plan unavailable'))
    const wrapper = await open()
    await wrapper.findAll('button').find(b => b.text() === 'Skip')!.trigger('click')
    expect(wrapper.findAll('button').find(b => b.text() === 'Install')!.attributes('disabled')).toBeDefined()
    wrapper.unmount()
  })

  it('ignores an AI response arriving after a manual edit', async () => {
    let resolve: (value: unknown) => void = () => {}
    api.post.mockReset().mockImplementation(async (url: string) => url.endsWith('/fill-gaps')
      ? new Promise(r => {resolve = r}) : {data: plan()})
    const wrapper = await open()
    await wrapper.findAll('button').find(b => b.text() === 'Suggest with AI')!.trigger('click')
    wrapper.findComponent({name: 'RequirementValueInput'}).vm.$emit('update:model-value', 'host:primary')
    resolve({data: plan('host:secondary', 'Stale suggestion')})
    await flushPromises()
    expect(wrapper.findComponent({name: 'RequirementValueInput'}).props('modelValue')).toBe('host:primary')
    expect(wrapper.text()).not.toContain('Stale suggestion')
    wrapper.unmount()
  })


  it('accepts one row while retaining other pending suggestions', async () => {
    const two = (first = '', second = '', ai = false) => ({...plan(first), requirements: [
      {...plan(first).requirements[0], value_source: ai && first ? 'llm' : 'provided', choice_reason: ai ? 'First reason' : undefined},
      {...plan(second).requirements[0], name: 'other', full_id: 'acme.example:other', parameter_name: 'acme.example:other',
        value_source: ai && second ? 'llm' : 'provided', choice_reason: ai ? 'Second reason' : undefined},
    ]})
    api.post.mockReset().mockImplementation(async (url: string, payload?: any) => ({data: url.endsWith('/fill-gaps')
      ? two('host:primary', 'host:secondary', true)
      : two(payload?.parameters?.find((p: any) => p.name === 'acme.example:scope')?.value,
            payload?.parameters?.find((p: any) => p.name === 'acme.example:other')?.value)}))
    const wrapper = await open()
    await wrapper.findAll('button').find(b => b.text() === 'Suggest with AI')!.trigger('click')
    await flushPromises()
    await wrapper.findAll('button').find(b => b.text() === 'Accept suggestion')!.trigger('click')
    await flushPromises()
    expect(wrapper.findAll('button').filter(b => b.text() === 'Accept suggestion')).toHaveLength(1)
    expect(wrapper.text()).toContain('Second reason')
    wrapper.unmount()
  })

  it('refreshes the plan after changing the migration decision', async () => {
    api.post.mockReset().mockResolvedValue({data: plan('host:primary')})
    const wrapper = await open()
    await wrapper.find('input[type="checkbox"]').setValue(false)
    await flushPromises()
    expect(api.post).toHaveBeenLastCalledWith('/api/v1/keeper/hub/dependencies/plan', expect.objectContaining({
      run_migrations: false, migration_policy: 'none',
    }))
    wrapper.unmount()
  })

  it('ignores an older plan response after a newer plan completes', async () => {
    let resolve: (value: unknown) => void = () => {}
    let count = 0
    api.post.mockReset().mockImplementation(async () => {
      count++
      if (count === 2) return new Promise(r => {resolve = r})
      return {data: plan(count > 2 ? 'host:primary' : '')}
    })
    const wrapper = await open()
    const input = wrapper.findComponent({name: 'RequirementValueInput'})
    input.vm.$emit('update:model-value', 'host:secondary')
    input.vm.$emit('commit')
    await flushPromises()
    input.vm.$emit('update:model-value', 'host:primary')
    input.vm.$emit('commit')
    await flushPromises()
    resolve({data: plan('host:secondary')})
    await flushPromises()
    expect(wrapper.findComponent({name: 'RequirementValueInput'}).props('modelValue')).toBe('host:primary')
    wrapper.unmount()
  })


  it('does not restore pending proposals when a newer manual review supersedes acceptance', async () => {
    let resolve: (value: unknown) => void = () => {}
    let calls = 0
    const two = (value = '', ai = false) => ({...plan(value), requirements: [
      {...plan(value).requirements[0], choice_reason: ai ? 'First proposal' : undefined},
      {...plan().requirements[0], name: 'other', full_id: 'acme.example:other', parameter_name: 'acme.example:other',
        value: ai ? 'host:secondary' : '', value_source: ai ? 'llm' : 'empty', choice_reason: ai ? 'Old other proposal' : undefined},
    ]})
    api.post.mockReset().mockImplementation(async (url: string) => {
      if (url.endsWith('/fill-gaps')) return {data: two('host:secondary', true)}
      calls++
      if (calls === 2) return new Promise(r => {resolve = r})
      return {data: two(calls > 2 ? 'host:primary' : '')}
    })
    const wrapper = await open()
    await wrapper.findAll('button').find(b => b.text() === 'Suggest with AI')!.trigger('click')
    await flushPromises()
    await wrapper.findAll('button').find(b => b.text() === 'Accept suggestion')!.trigger('click')
    const input = wrapper.findAllComponents({name: 'RequirementValueInput'})[0]
    input.vm.$emit('update:model-value', 'host:primary')
    input.vm.$emit('commit')
    await flushPromises()
    resolve({data: two('host:secondary')})
    await flushPromises()
    expect(wrapper.text()).not.toContain('Old other proposal')
    expect(input.props('modelValue')).toBe('host:primary')
    wrapper.unmount()
  })


  it('shows a newly resolved package default after replanning an empty row', async () => {
    let calls = 0
    api.post.mockReset().mockImplementation(async () => ({data: plan(++calls === 1 ? '' : 'host:primary')}))
    const wrapper = await open()
    await wrapper.find('input[placeholder="latest"]').setValue('2.0.0')
    await flushPromises()
    expect(wrapper.findComponent({name: 'RequirementValueInput'}).props('modelValue')).toBe('host:primary')
    wrapper.unmount()
  })

  it('removes obsolete input validity when the new version removes a requirement', async () => {
    let calls = 0
    api.post.mockReset().mockImplementation(async () => ({data: ++calls === 1 ? plan() : {
      ...plan('host:primary'), requirements: [], missing_requirements: [],
    }}))
    const wrapper = await open()
    wrapper.findComponent({name: 'RequirementValueInput'}).vm.$emit('validity', false)
    await wrapper.find('input[placeholder="latest"]').setValue('2.0.0')
    await flushPromises()
    await wrapper.findAll('button').find(b => b.text() === 'Skip')!.trigger('click')
    expect(wrapper.findAll('button').find(b => b.text() === 'Install')!.attributes('disabled')).toBeUndefined()
    wrapper.unmount()
  })

})
