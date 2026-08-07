// @vitest-environment happy-dom
import { flushPromises, mount } from '@vue/test-utils'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import ComponentsPage from '../components.vue'

const mocks = vi.hoisted(() => ({
  api: {},
  on: vi.fn(),
  subscriptions: [] as Array<{ topic: string; callback: (event: any) => void; off: ReturnType<typeof vi.fn> }>,
  listComponents: vi.fn(),
  getDoc: vi.fn(),
  startBuild: vi.fn(),
  listBuilds: vi.fn(),
  getBuild: vi.fn(),
  captureScreenshot: vi.fn(),
}))

vi.mock('../../composables/useWippy', () => ({
  useApi: () => mocks.api,
  useWippy: () => ({ on: mocks.on }),
}))

vi.mock('vue-router', () => ({
  useRoute: () => ({ fullPath: '/components' }),
}))

vi.mock('@iconify/vue', () => ({
  Icon: { name: 'Icon', template: '<i />' },
}))

vi.mock('../../components/shared/MarkdownContent.vue', () => ({
  default: { name: 'MarkdownContent', template: '<div />' },
}))

vi.mock('../../components/shared/JsonBlock.vue', () => ({
  default: { name: 'JsonBlock', template: '<div />' },
}))

vi.mock('../../api/components', () => ({
  listComponents: mocks.listComponents,
  getDoc: mocks.getDoc,
  startBuild: mocks.startBuild,
  listBuilds: mocks.listBuilds,
  getBuild: mocks.getBuild,
  captureScreenshot: mocks.captureScreenshot,
  formatBytes: (value: number) => String(value),
  formatMtime: (value: number) => String(value),
}))

const component = {
  id: '@wippy/example',
  kind: 'app',
  path: '/apps/example',
  title: 'Example',
  description: '',
  toolchain: 'node',
  scripts: { build: 'npm run build' },
  out_dir: 'dist',
  built: true,
  size_bytes: 100,
  last_built: 1,
  source_bytes: 200,
  source_mtime: 1,
  docs: [],
  editable: true,
  link_kind: 'local',
  is_main_app: false,
  thumbnail_url: '',
}

function build(buildId: string, status: 'running' | 'success') {
  return {
    build_id: buildId,
    component_id: component.id,
    component_path: component.path,
    trigger: 'user',
    triggered_by: 'test',
    status,
    command: 'npm run build',
    image: 'node:test',
    toolchain: 'node',
    started_at: 1,
    lines: [],
  }
}

function rebuildButton(wrapper: ReturnType<typeof mount>) {
  const button = wrapper.findAll('button').find(candidate => candidate.text().trim() === 'Rebuild')
  if (!button) throw new Error('Rebuild button not found')
  return button
}

describe('component build subscriptions', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.subscriptions.length = 0
    mocks.on.mockImplementation((topic: string, callback: (event: any) => void) => {
      const off = vi.fn()
      mocks.subscriptions.push({ topic, callback, off })
      return off
    })
    mocks.listComponents.mockResolvedValue({
      success: true,
      applications: [component],
      widgets: [],
      kit_docs: [],
    })
    mocks.listBuilds.mockResolvedValue({ success: true, builds: [] })
    mocks.captureScreenshot.mockResolvedValue({ success: true })
  })

  it('unsubscribes a build listener at terminal status', async () => {
    mocks.startBuild.mockResolvedValue({ success: true, build_id: 'build-1' })
    mocks.getBuild.mockResolvedValueOnce({ success: true, build: build('build-1', 'running') })

    const wrapper = mount(ComponentsPage)
    await flushPromises()
    await rebuildButton(wrapper).trigger('click')
    await flushPromises()

    const subscription = mocks.subscriptions.find(item => item.topic === 'keeper.builds')
    expect(subscription).toBeDefined()
    expect(subscription!.off).not.toHaveBeenCalled()

    mocks.getBuild.mockResolvedValueOnce({ success: true, build: build('build-1', 'success') })
    subscription!.callback({ data: { build_id: 'build-1' } })
    await flushPromises()

    expect(subscription!.off).toHaveBeenCalledOnce()
    wrapper.unmount()
    expect(subscription!.off).toHaveBeenCalledOnce()
  })

  it('unsubscribes an active build listener when the page unmounts', async () => {
    mocks.startBuild.mockResolvedValue({ success: true, build_id: 'build-2' })
    mocks.getBuild.mockResolvedValueOnce({ success: true, build: build('build-2', 'running') })

    const wrapper = mount(ComponentsPage)
    await flushPromises()
    await rebuildButton(wrapper).trigger('click')
    await flushPromises()

    const subscription = mocks.subscriptions.find(item => item.topic === 'keeper.builds')
    expect(subscription).toBeDefined()
    wrapper.unmount()

    expect(subscription!.off).toHaveBeenCalledOnce()
  })
})
