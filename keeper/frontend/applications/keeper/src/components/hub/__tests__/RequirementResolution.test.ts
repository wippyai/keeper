// @vitest-environment happy-dom
import { mount } from '@vue/test-utils'
import { describe, expect, it } from 'vitest'
import RequirementResolution from '../RequirementResolution.vue'

describe('Requirement resolution review', () => {
  it('shows the model reason before the plan is applied', () => {
    const wrapper = mount(RequirementResolution, {props: {requirement: {
      choice_reason: 'The primary database owns account data.',
    }}})
    expect(wrapper.text()).toContain('Model suggestion')
    expect(wrapper.text()).toContain('The primary database owns account data.')
  })
  it('shows an unavailable automatic choice with its typed error', () => {
    const wrapper = mount(RequirementResolution, {props: {requirement: {
      resolution_error: {code: 'UNAVAILABLE', kind: 'Unavailable', message: 'No model is available.'},
    }}})
    expect(wrapper.text()).toContain('UNAVAILABLE')
    expect(wrapper.text()).toContain('No model is available.')
  })
  it('leaves an existing or declared-default binding unchanged', () => {
    const wrapper = mount(RequirementResolution, {props: {requirement: {}}})
    expect(wrapper.text()).toBe('')
    expect(wrapper.emitted()).toEqual({})
  })
})
