// @vitest-environment happy-dom
import { mount, flushPromises } from '@vue/test-utils'
import { nextTick } from 'vue'
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
    document.body.innerHTML = ''
    mocks.listEntries.mockResolvedValue({
      entries: [
        { id: 'app:api', kind: 'http.router', meta: { title: 'App API', type: 'http.router' } },
        { id: 'admin:gateway', kind: 'http.router', meta: { title: 'Admin Gateway', type: 'http.router' } },
      ],
    })
  })

  afterEach(() => {
    document.body.innerHTML = ''
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

    const option = Array.from(document.body.querySelectorAll<HTMLButtonElement>('button.req-value-option'))
      .find(button => button.textContent?.includes('app:api'))
    expect(option).toBeDefined()
    option!.dispatchEvent(new MouseEvent('mousedown', { bubbles: true, cancelable: true, button: 0 }))
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
})
