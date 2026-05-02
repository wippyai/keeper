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
}))

function mountPage() {
  return mount(MCPPage, { attachTo: document.body })
}

function setTestUrl(url: string) {
  ;(window as unknown as { happyDOM: { setURL: (url: string) => void } }).happyDOM.setURL(url)
}

function dialogButton(label: string) {
  return Array.from(document.body.querySelectorAll<HTMLButtonElement>('.dialog-box button'))
    .find(button => button.textContent?.trim() === label)
}

describe('MCP token creation', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    document.body.innerHTML = ''
    setTestUrl('http://localhost:3000/')

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
        url: 'https://app.example.test/keeper-mcp/',
        path: '/keeper-mcp/',
      },
    })
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

  it('uses the configured MCP URL in client snippets', async () => {
    mocks.listScopes.mockResolvedValueOnce({
      scopes: [],
      presets: [],
      config: {
        enabled: true,
        url: 'https://ops.example.com/keeper-mcp/',
        path: '/keeper-mcp/',
      },
    })

    const wrapper = mountPage()
    await flushPromises()

    const snippets = wrapper.findAll('pre.snippet-code').map(pre => pre.text()).join('\n')
    expect(snippets).toContain('https://ops.example.com/keeper-mcp/')

    wrapper.unmount()
  })

  it('falls back to the browser origin when the backend public URL is not configured', async () => {
    setTestUrl('https://console.example.test/c/keeper:main/settings/mcp')
    mocks.listScopes.mockResolvedValueOnce({
      scopes: [],
      presets: [],
      config: {
        enabled: true,
        url: '',
        path: '/custom-mcp/',
      },
    })

    const wrapper = mountPage()
    await flushPromises()

    const snippets = wrapper.findAll('pre.snippet-code').map(pre => pre.text()).join('\n')
    expect(snippets).toContain('https://console.example.test/custom-mcp/')

    wrapper.unmount()
  })
})
