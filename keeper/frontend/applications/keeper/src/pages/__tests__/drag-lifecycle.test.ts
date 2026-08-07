// @vitest-environment happy-dom
import { flushPromises, shallowMount, type VueWrapper } from '@vue/test-utils'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import TaskDetail from '../task-detail.vue'
import DataflowDetail from '../dataflow-detail.vue'
import Structure from '../structure.vue'
import SessionDetail from '../session-detail.vue'

const mocks = vi.hoisted(() => ({
  off: vi.fn(),
  getTask: vi.fn(),
  listTaskNodes: vi.fn(),
  syncResearch: vi.fn(),
  getDataflow: vi.fn(),
  getSession: vi.fn(),
  getSessionMessages: vi.fn(),
  listNamespaces: vi.fn(),
  getGovernanceConfig: vi.fn(),
}))

vi.mock('../../composables/useWippy', () => ({
  useApi: () => ({}),
  useHost: () => ({ confirm: vi.fn() }),
  useWippy: () => ({ on: vi.fn(() => mocks.off) }),
}))

vi.mock('vue-router', () => ({
  useRoute: () => ({ params: { id: 'test-id' }, query: {}, fullPath: '/test' }),
  useRouter: () => ({ back: vi.fn(), push: vi.fn() }),
}))

vi.mock('@iconify/vue', () => ({
  Icon: { name: 'Icon', template: '<i />' },
}))

vi.mock('../../api/tasks', () => ({
  getTask: mocks.getTask,
  listTaskNodes: mocks.listTaskNodes,
  syncResearch: mocks.syncResearch,
  startCycle: vi.fn(),
}))

vi.mock('../../api/dataflows', () => ({
  getDataflow: mocks.getDataflow,
  cancelDataflow: vi.fn(),
  terminateDataflow: vi.fn(),
  statusColor: () => 'var(--p-text-color)',
  statusIcon: () => 'tabler:circle',
  nodeTypeShort: (value: string) => value,
}))

vi.mock('../../api/sessions', () => ({
  getSession: mocks.getSession,
  getSessionMessages: mocks.getSessionMessages,
  formatTokens: (value: number) => String(value),
  formatDate: () => '',
  timeAgo: () => '',
}))

vi.mock('../../api/registry', () => ({
  listNamespaces: mocks.listNamespaces,
  listEntries: vi.fn(),
  getEntry: vi.fn(),
  updateEntry: vi.fn(),
  fetchGraph: vi.fn(),
  getGovernanceConfig: mocks.getGovernanceConfig,
  kindColor: () => 'var(--p-text-color)',
  kindIcon: () => 'tabler:circle',
}))

type Listener = EventListenerOrEventListenerObject

async function expectDragCleanup(component: any, selector: string) {
  const added = vi.spyOn(document, 'addEventListener')
  const removed = vi.spyOn(document, 'removeEventListener')
  let wrapper: VueWrapper | null = null

  document.body.style.cursor = 'wait'
  document.body.style.userSelect = 'text'

  try {
    wrapper = shallowMount(component)
    await flushPromises()

    const handle = wrapper.find(selector)
    expect(handle.exists()).toBe(true)
    await handle.trigger('mousedown', { clientX: 100 })

    const moveListener = [...added.mock.calls]
      .reverse()
      .find(([type]) => type === 'mousemove')?.[1] as Listener | undefined
    const upListener = [...added.mock.calls]
      .reverse()
      .find(([type]) => type === 'mouseup')?.[1] as Listener | undefined

    expect(moveListener).toBeDefined()
    expect(upListener).toBeDefined()
    expect(document.body.style.cursor).toBe('col-resize')
    expect(document.body.style.userSelect).toBe('none')

    wrapper.unmount()
    wrapper = null

    expect(removed).toHaveBeenCalledWith('mousemove', moveListener)
    expect(removed).toHaveBeenCalledWith('mouseup', upListener)
    expect(document.body.style.cursor).toBe('wait')
    expect(document.body.style.userSelect).toBe('text')
  } finally {
    wrapper?.unmount()
    added.mockRestore()
    removed.mockRestore()
  }
}

describe('page resize drag lifecycle', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    localStorage.clear()
    mocks.syncResearch.mockResolvedValue({})
    mocks.getTask.mockResolvedValue({
      task: { task_id: 'test-id', title: 'Test task', phase: 'plan', status: 'completed' },
      stats: {},
    })
    mocks.listTaskNodes.mockResolvedValue({ nodes: [] })
    mocks.getDataflow.mockResolvedValue({
      dataflow: { dataflow_id: 'test-id', status: 'completed', kind: 'test' },
      nodes: [],
      data: [],
    })
    mocks.getSession.mockResolvedValue({
      session: { session_id: 'test-id', title: 'Test session', status: 'completed' },
    })
    mocks.getSessionMessages.mockResolvedValue({ messages: [], pagination: {} })
    mocks.listNamespaces.mockResolvedValue({ namespaces: [] })
    mocks.getGovernanceConfig.mockResolvedValue({ managed_namespaces: [] })
  })

  afterEach(() => {
    document.body.style.cursor = ''
    document.body.style.userSelect = ''
  })

  it('cleans up an active task-detail drag on unmount', async () => {
    await expectDragCleanup(TaskDetail, '[data-testid="task-resize-handle"]')
  })

  it('cleans up an active dataflow-detail drag on unmount', async () => {
    await expectDragCleanup(DataflowDetail, '[data-testid="dataflow-resize-handle"]')
  })

  it('cleans up an active structure drag on unmount', async () => {
    await expectDragCleanup(Structure, '[data-testid="structure-resize-handle"]')
  })

  it('cleans up an active session-detail drag on unmount', async () => {
    await expectDragCleanup(SessionDetail, '[data-testid="session-left-resize-handle"]')
  })
})
