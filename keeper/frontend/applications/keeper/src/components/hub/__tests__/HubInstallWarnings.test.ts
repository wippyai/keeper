// @vitest-environment happy-dom
import { mount } from '@vue/test-utils'
import { describe, expect, it, vi } from 'vitest'
import HubInstallWarnings from '../HubInstallWarnings.vue'

vi.mock('@iconify/vue', () => ({Icon: {name: 'Icon', template: '<span />'}}))

describe('HubInstallWarnings', () => {
  it('lists each observer warning and dismisses on close', async () => {
    const wrapper = mount(HubInstallWarnings, {props: {component: 'acme/example', warnings: [
      {observer: 'acme.security:observer', message: 'scope projection did not finish'},
      {message: 'registry observers did not run'},
    ]}})
    expect(wrapper.text()).toContain('Installed acme/example')
    const items = wrapper.findAll('li')
    expect(items).toHaveLength(2)
    expect(items[0].text()).toBe('acme.security:observer: scope projection did not finish')
    expect(items[1].text()).toBe('registry observers did not run')
    await wrapper.find('button[aria-label="Dismiss"]').trigger('click')
    expect(wrapper.emitted('dismiss')).toHaveLength(1)
  })
})
