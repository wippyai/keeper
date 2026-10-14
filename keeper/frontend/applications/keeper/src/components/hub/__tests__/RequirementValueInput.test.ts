// @vitest-environment happy-dom
import { mount, flushPromises, config, enableAutoUnmount } from '@vue/test-utils'
import { nextTick } from 'vue'
import PrimeVue from 'primevue/config'
config.global.plugins = [PrimeVue]

import { describe, expect, it, vi, beforeEach, afterEach } from 'vitest'
import RequirementValueInput from '../RequirementValueInput.vue'
import type { HubPlanRequirement } from '../../../api/hub'

const mocks = vi.hoisted(() => ({
  api: {},
  listEntries: vi.fn(),
}))

vi.mock('../../../composables/useWippy', () => ({
  useApi: () => mocks.api,
}))

vi.mock('../../../api/registry', () => ({
  listEntries: mocks.listEntries,
  kindIcon: (kind: string) => `icon:${kind}`,
}))

vi.mock('@iconify/vue', () => ({
  Icon: {
    name: 'Icon',
    props: ['icon'],
    template: '<i />',
  },
}))

enableAutoUnmount(afterEach)

function requirement(overrides: Partial<HubPlanRequirement> = {}): HubPlanRequirement {
  return {
    name: 'webhook_router',
    parameter_name: 'butschster.telegram:webhook_router',
    full_id: 'butschster.telegram:webhook_router',
    expected_kind: 'http.router',
    required: true,
    missing: true,
    suggestions: [],
    ...overrides,
  }
}

describe('RequirementValueInput', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.listEntries.mockResolvedValue({
      entries: [
        { id: 'app:api', kind: 'http.router', meta: { title: 'App API', type: 'http.router' } },
        { id: 'admin:gateway', kind: 'http.router', meta: { title: 'Admin Gateway', type: 'http.router' } },
      ],
    })
  })

  afterEach(async () => { await flushPromises() })

  it('does not commit an untouched value when focus leaves the field', async () => {
    const wrapper = mount(RequirementValueInput, {
      props: {modelValue: '', requirement: requirement()}, attachTo: document.body,
    })
    await wrapper.find('input').trigger('focus')
    await flushPromises()
    await wrapper.find('input').trigger('blur')
    expect(wrapper.emitted('commit')).toBeUndefined()
  })

  it('commits each edit once across change, Enter and blur events', async () => {
    const wrapper = mount(RequirementValueInput, {
      props: {modelValue: '', requirement: requirement({expected_type: 'string', expected_kind: undefined})},
    })
    await wrapper.find('input').setValue('first')
    await wrapper.find('input').trigger('change')
    await wrapper.find('input').trigger('keydown', {key: 'Enter', code: 'Enter'})
    await wrapper.find('input').trigger('blur')
    expect(wrapper.emitted('commit')).toHaveLength(1)
    await wrapper.find('input').setValue('second')
    expect(wrapper.emitted('commit')).toHaveLength(2)
  })

  it('keeps a local edit pending through its parent echo and treats external values as reviewed', async () => {
    const wrapper = mount(RequirementValueInput, {
      props: {modelValue: '', requirement: requirement()},
    })
    await wrapper.find('input').setValue('host:local')
    await wrapper.setProps({modelValue: 'host:local'})
    await wrapper.find('input').trigger('blur')
    expect(wrapper.emitted('commit')).toHaveLength(1)
    await wrapper.setProps({modelValue: 'host:reviewed'})
    await wrapper.find('input').trigger('blur')
    expect(wrapper.emitted('commit')).toHaveLength(1)
  })

  it('closes the open candidate list with Escape before dismissing its containing dialog', async () => {
    const wrapper = mount(RequirementValueInput, {
      props: {modelValue: '', requirement: requirement()}, attachTo: document.body,
    })
    const dismiss = vi.fn()
    const onKeydown = (event: KeyboardEvent) => { if (event.code === 'Escape') dismiss() }
    document.addEventListener('keydown', onKeydown)
    try {
      const input = wrapper.find('input')
      await input.trigger('focus')
      await flushPromises()
      expect(input.attributes('aria-expanded')).toBe('true')
      await input.trigger('keydown', {key: 'Escape', code: 'Escape'})
      expect(dismiss).not.toHaveBeenCalled()
      await vi.waitFor(() => expect(input.attributes('aria-expanded')).toBe('false'))
      await input.trigger('keydown', {key: 'Escape', code: 'Escape'})
      expect(dismiss).toHaveBeenCalledTimes(1)
    } finally {
      document.removeEventListener('keydown', onKeydown)
    }
  })

  it('searches registry entries while keeping planner suggestions', async () => {
    const wrapper = mount(RequirementValueInput, {
      props: {
        modelValue: '',
        requirement: requirement({
          suggestions: [{ value: 'customer.web:public', label: 'Customer public router', kind: 'http.router', preferred: true }],
        }),
      },
      attachTo: document.body,
    })

    await wrapper.find('input').trigger('focus')
    await flushPromises()

    expect(mocks.listEntries).toHaveBeenCalledWith(mocks.api, { query: undefined, limit: 80 })
    expect(document.body.textContent).toContain('Customer public router')
    expect(document.body.textContent).toContain('app:api')
  })

  it('selects registry ids into the editable field', async () => {
    const wrapper = mount(RequirementValueInput, {
      props: { modelValue: '', requirement: requirement() },
      attachTo: document.body,
    })

    await wrapper.find('input').trigger('focus')
    await flushPromises()

    const option = Array.from(document.body.querySelectorAll<HTMLElement>('.req-value-option'))
      .find(button => button.textContent?.includes('app:api'))
    expect(option).toBeDefined()
    option!.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true, button: 0 }))
    await nextTick()

    expect((wrapper.find('input').element as HTMLInputElement).value).toBe('app:api')
  })

  it('allows free-form values and uses them for registry search', async () => {
    vi.useFakeTimers()
    const wrapper = mount(RequirementValueInput, {
      props: { modelValue: '', requirement: requirement() },
      attachTo: document.body,
    })

    const input = wrapper.find('input')
    ;(input.element as HTMLInputElement).value = 'external.contract:value'
    await input.trigger('input')
    await vi.advanceTimersByTimeAsync(200)

    expect((input.element as HTMLInputElement).value).toBe('external.contract:value')
    expect(mocks.listEntries).toHaveBeenCalledWith(mocks.api, { query: 'external.contract:value', limit: 80 })
    vi.useRealTimers()
  })

  it('round-trips boolean false and zero using declared literal types without registry lookup', async () => {
    for (const [expected_type, modelValue, text] of [['boolean', false, 'false'], ['integer', 0, '0']] as const) {
      mocks.listEntries.mockClear()
      const wrapper = mount(RequirementValueInput, {
        props: {modelValue, requirement: requirement({expected_kind: undefined, expected_type})},
      })
      await wrapper.find('input').trigger('focus')
      await wrapper.find('input').setValue(text)
      await wrapper.find('input').trigger('change')
      expect(wrapper.emitted('update:model-value')?.slice(-1)[0]).toEqual([modelValue])
      expect(mocks.listEntries).not.toHaveBeenCalled()
      wrapper.unmount()
    }
  })

  it('validates typed collections and reports invalid JSON without committing it', async () => {
    const wrapper = mount(RequirementValueInput, {props: {modelValue: {enabled: true},
      requirement: requirement({expected_kind: undefined, expected_type: 'object'})}})
    expect(wrapper.find('input').element.value).toBe('{"enabled":true}')
    ;(wrapper.find('input').element as HTMLInputElement).value = '{bad'
    await wrapper.find('input').trigger('input')
    await wrapper.find('input').trigger('change')
    expect(wrapper.find('[role="alert"]').text()).toContain('object')
    expect(wrapper.emitted('commit')).toBeUndefined()
    ;(wrapper.find('input').element as HTMLInputElement).value = '{"enabled":false}'
    await wrapper.find('input').trigger('input')
    await wrapper.find('input').trigger('change')
    expect(wrapper.emitted('update:model-value')?.slice(-1)[0]).toEqual([{enabled: false}])
    expect(wrapper.emitted('commit')).toHaveLength(1)
    wrapper.unmount()
  })

  it('does not present unrelated registry entries as compatible requirement choices', async () => {
    mocks.listEntries.mockResolvedValue({entries: [{id: 'host:router', kind: 'http.router', meta: {}}]})
    const wrapper = mount(RequirementValueInput, {props: {modelValue: '', requirement: requirement({
      expected_kind: 'security.scope', suggestions: [{value: 'host:scope', kind: 'security.scope'}],
    })}, attachTo: document.body})
    await wrapper.find('input').trigger('focus')
    await flushPromises()
    expect(document.body.textContent).toContain('host:scope')
    expect(document.body.textContent).not.toContain('host:router')
    wrapper.unmount()
  })

})
