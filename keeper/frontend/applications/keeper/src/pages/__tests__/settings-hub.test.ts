// @vitest-environment happy-dom
import { mount, flushPromises, config } from '@vue/test-utils'
import PrimeVue from 'primevue/config'
import { describe, expect, it, vi } from 'vitest'
import SettingsHub from '../settings-hub.vue'

config.global.plugins = [PrimeVue]

const mocks = vi.hoisted(() => ({
  listHubDependencies: vi.fn(),
  listHubMigrations: vi.fn(),
  browseHubModules: vi.fn(),
}))

vi.mock('@iconify/vue', () => ({ Icon: { name: 'Icon', template: '<i />' } }))
vi.mock('vue-router', () => ({ useRouter: () => ({ push: vi.fn() }) }))
vi.mock('../../composables/useWippy', () => ({ useApi: () => ({ get: vi.fn(), post: vi.fn() }) }))
vi.mock('../../api/hub', () => ({
  listHubDependencies: mocks.listHubDependencies,
  listHubMigrations: mocks.listHubMigrations,
  runHubMigrations: vi.fn(),
  browseHubModules: mocks.browseHubModules,
  listHubVersions: vi.fn(),
  getHubReadme: vi.fn(),
}))

async function mountInstalled(dependency: Record<string, unknown>) {
  mocks.listHubDependencies.mockResolvedValue({ success: true, dependencies: [dependency], modules: [] })
  mocks.listHubMigrations.mockResolvedValue({ success: true, migrations: [] })
  mocks.browseHubModules.mockResolvedValue({ success: true, modules: [] })
  const wrapper = mount(SettingsHub, {
    global: { stubs: { PageHeader: true, HubInstallDialog: true, HubUninstallDialog: true } },
  })
  await flushPromises()
  const tab = wrapper.findAll('button.tab-btn').find(b => b.text().includes('Installed'))
  await tab!.trigger('click')
  return wrapper
}

describe('installed hub dependencies', () => {
  it('shows the installed release and keeps the declared range visible', async () => {
    const wrapper = await mountInstalled({
      id: 'app.deps:facade', component: 'wippy/facade', version: '>=0.6.0', installed_version: '0.6.45',
    })
    const card = wrapper.find('.inst-card')
    expect(card.find('.mod-version').text()).toBe('0.6.45')
    expect(card.text()).toContain('>=0.6.0')
  })

  it('shows one version when the declaration names the installed release', async () => {
    const wrapper = await mountInstalled({
      id: 'app.deps:facade', component: 'wippy/facade', version: '0.6.0', installed_version: '0.6.0',
    })
    const card = wrapper.find('.inst-card')
    expect(card.find('.mod-version').text()).toBe('0.6.0')
    expect(card.text().match(/0\.6\.0/g)).toHaveLength(1)
  })

  it('hides an exact pin that names the installed release', async () => {
    const wrapper = await mountInstalled({
      id: 'app.deps:facade', component: 'wippy/facade', version: '=0.6.0', installed_version: '0.6.0',
    })
    const card = wrapper.find('.inst-card')
    expect(card.find('.mod-version').text()).toBe('0.6.0')
    expect(card.text()).not.toContain('=0.6.0')
  })

  it('falls back to the declared range when the installed release is unknown', async () => {
    const wrapper = await mountInstalled({ id: 'app.deps:facade', component: 'wippy/facade', version: '>=0.6.0' })
    expect(wrapper.find('.inst-card .mod-version').text()).toBe('>=0.6.0')
  })
})
