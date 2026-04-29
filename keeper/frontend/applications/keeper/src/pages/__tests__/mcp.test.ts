// @vitest-environment happy-dom
import { mount, flushPromises } from '@vue/test-utils'
import { nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import MCPPage from '../mcp.vue'

const mocks = vi.hoisted(() => ({
  api: {
    get: vi.fn(),
  },
  listTokens: vi.fn(),
  createToken: vi.fn(),
  revokeToken: vi.fn(),
  listScopes: vi.fn(),
  getAdminToken: vi.fn(),
  setAdminToken: vi.fn(),
}))

vi.mock('../../composables/useWippy', () => ({
  useApi: () => mocks.api,
}))

vi.mock('@iconify/vue', () => ({
  Icon: {
    name: 'Icon',
    props: ['icon'],
    template: '<i />',
  },
}))

vi.mock('../../api/mcp', () => ({
  listTokens: mocks.listTokens,
  createToken: mocks.createToken,
  revokeToken: mocks.revokeToken,
  listScopes: mocks.listScopes,
  getAdminToken: mocks.getAdminToken,
  setAdminToken: mocks.setAdminToken,
}))

function mountPage() {
  return mount(MCPPage, { attachTo: document.body })
}

function dialogButton(label: string) {
  return Array.from(document.body.querySelectorAll<HTMLButtonElement>('.dialog-box button'))
    .find(button => button.textContent?.trim() === label)
}

describe('MCP token creation', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    document.body.innerHTML = ''

    mocks.api.get.mockResolvedValue({
      data: {
        success: true,
        user: {
          id: 'admin@wippy.local',
          user_id: 'admin@wippy.local',
          email: 'admin@wippy.local',
          full_name: 'Default Administrator',
        },
      },
    })
    mocks.listTokens.mockResolvedValue({ tokens: [] })
    mocks.listScopes.mockResolvedValue({
      scopes: [
        { id: 'state.read', label: 'State Read', description: 'Read registry state' },
      ],
      presets: [
        {
          id: 'read',
          label: 'Read',
          description: 'Read-only access',
          icon: 'tabler:eye',
          access_mode: 'any',
          scopes: ['state.read'],
        },
      ],
      config: {
        enabled: true,
        public_enabled: false,
        internal_url: 'http://localhost:9067/',
        public_url: 'http://localhost:8067/keeper-mcp/',
        public_path: '/keeper-mcp/',
      },
    })
    mocks.getAdminToken.mockResolvedValue({ success: true, token: '' })
    mocks.createToken.mockResolvedValue({ success: true, token: { token: 'created-token' } })
  })

  it('binds new scoped tokens to the current signed-in user', async () => {
    const wrapper = mountPage()
    await flushPromises()

    const newTokenButton = wrapper.findAll('button').find(button => button.text().includes('New Token'))
    expect(newTokenButton).toBeDefined()
    await newTokenButton!.trigger('click')
    await flushPromises()
    await nextTick()

    expect(document.body.textContent).toContain('Default Administrator')
    expect(document.body.textContent).toContain('admin@wippy.local')

    const buttonLabels = Array.from(document.body.querySelectorAll<HTMLButtonElement>('.dialog-box button'))
      .map(button => button.textContent?.trim())
    expect(buttonLabels).not.toContain('root')
    expect(buttonLabels).not.toContain('agent')
    expect(buttonLabels).not.toContain('user')

    const labelInput = document.body.querySelector<HTMLInputElement>('.dialog-box input.input')
    expect(labelInput).toBeDefined()
    labelInput!.value = 'remote-dev'
    labelInput!.dispatchEvent(new Event('input', { bubbles: true }))
    await nextTick()

    const readPreset = dialogButton('Read')
    expect(readPreset).toBeDefined()
    readPreset!.click()
    await nextTick()

    const createButton = dialogButton('Create')
    expect(createButton).toBeDefined()
    createButton!.click()
    await flushPromises()

    expect(mocks.createToken).toHaveBeenCalledWith(mocks.api, {
      label: 'remote-dev',
      identity: 'admin@wippy.local',
      preset: 'read',
      scopes: ['state.read'],
      access_mode: 'any',
    })

    wrapper.unmount()
  })

  it('uses the configured public MCP URL in client snippets when public mode is enabled', async () => {
    mocks.listScopes.mockResolvedValueOnce({
      scopes: [],
      presets: [],
      config: {
        enabled: true,
        public_enabled: true,
        internal_url: 'http://localhost:9067/',
        public_url: 'https://ops.example.com/keeper-mcp/',
        public_path: '/keeper-mcp/',
      },
    })

    const wrapper = mountPage()
    await flushPromises()

    const snippets = wrapper.findAll('pre.snippet-code').map(pre => pre.text()).join('\n')
    expect(snippets).toContain('https://ops.example.com/keeper-mcp/')
    expect(snippets).not.toContain('http://localhost:9067/')

    wrapper.unmount()
  })
})
