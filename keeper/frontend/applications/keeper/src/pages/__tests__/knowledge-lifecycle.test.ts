// @vitest-environment happy-dom
import { flushPromises, mount } from '@vue/test-utils'
import { nextTick } from 'vue'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import KnowledgePage from '../knowledge.vue'

const mocks = vi.hoisted(() => ({
  api: {},
  host: { confirm: vi.fn() },
  router: { push: vi.fn() },
  on: vi.fn(),
  subscriptions: [] as Array<{ topic: string; callback: (event: any) => void; off: ReturnType<typeof vi.fn> }>,
  listKBs: vi.fn(),
  createKB: vi.fn(),
  deleteKB: vi.fn(),
  listNodes: vi.fn(),
  createNode: vi.fn(),
  updateNode: vi.fn(),
  deleteNode: vi.fn(),
  searchNodes: vi.fn(),
  semanticSearch: vi.fn(),
  startResearch: vi.fn(),
  startBatchResearch: vi.fn(),
  learnProject: vi.fn(),
  getStats: vi.fn(),
}))

vi.mock('../../composables/useWippy', () => ({
  useApi: () => mocks.api,
  useHost: () => mocks.host,
  useWippy: () => ({ on: mocks.on }),
}))

vi.mock('vue-router', () => ({
  useRouter: () => mocks.router,
}))

vi.mock('@iconify/vue', () => ({
  Icon: { name: 'Icon', template: '<i />' },
}))

vi.mock('primevue/button', () => ({
  default: { name: 'Button', template: '<button><slot /></button>' },
}))

vi.mock('../../components/shared/MarkdownContent.vue', () => ({
  default: { name: 'MarkdownContent', template: '<div />' },
}))

vi.mock('../../api/knowledge', () => ({
  listKBs: mocks.listKBs,
  createKB: mocks.createKB,
  deleteKB: mocks.deleteKB,
  listNodes: mocks.listNodes,
  createNode: mocks.createNode,
  updateNode: mocks.updateNode,
  deleteNode: mocks.deleteNode,
  searchNodes: mocks.searchNodes,
  semanticSearch: mocks.semanticSearch,
  startResearch: mocks.startResearch,
  startBatchResearch: mocks.startBatchResearch,
  learnProject: mocks.learnProject,
  getStats: mocks.getStats,
  NODE_TYPES: [],
  nodeTypeInfo: () => ({ label: 'Unknown', icon: '', text: '', bg: '', border: '' }),
}))

function button(label: string): HTMLButtonElement {
  const result = Array.from(document.body.querySelectorAll('button'))
    .find(candidate => candidate.textContent?.trim() === label)
  if (!result) throw new Error(`Button ${label} not found`)
  return result
}

async function startResearch(prompt: string) {
  button('Research').click()
  await nextTick()
  const input = document.body.querySelector<HTMLTextAreaElement>('textarea[placeholder="Additional research topic..."]')
  if (!input) throw new Error('Research prompt not found')
  input.value = prompt
  input.dispatchEvent(new Event('input', { bubbles: true }))
  await nextTick()
  button('Start').click()
  await flushPromises()
}

describe('knowledge page subscription lifecycle', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    document.body.innerHTML = ''
    mocks.subscriptions.length = 0
    mocks.on.mockImplementation((topic: string, callback: (event: any) => void) => {
      const off = vi.fn()
      mocks.subscriptions.push({ topic, callback, off })
      return off
    })
    mocks.listKBs.mockResolvedValue({ kbs: [] })
    mocks.listNodes.mockResolvedValue({ nodes: [] })
    mocks.getStats.mockResolvedValue({ stats: { total: 0, embedded: 0, by_type: {} } })
    mocks.searchNodes.mockResolvedValue({ nodes: [] })
    mocks.semanticSearch.mockResolvedValue({ nodes: [] })
  })

  afterEach(() => {
    vi.useRealTimers()
    document.body.innerHTML = ''
  })

  it('replaces the prior research listener and tears down the active listener on unmount', async () => {
    mocks.startResearch
      .mockResolvedValueOnce({ dataflow_id: 'research-1' })
      .mockResolvedValueOnce({ dataflow_id: 'research-2' })

    const wrapper = mount(KnowledgePage, { attachTo: document.body })
    await flushPromises()
    await startResearch('first topic')
    const first = mocks.subscriptions.find(item => item.topic === 'dataflow:research-1')
    expect(first).toBeDefined()

    await startResearch('replacement topic')
    const second = mocks.subscriptions.find(item => item.topic === 'dataflow:research-2')
    expect(second).toBeDefined()
    expect(first!.off).toHaveBeenCalledOnce()

    const knowledge = mocks.subscriptions.find(item => item.topic === 'keeper.knowledge')
    wrapper.unmount()

    expect(second!.off).toHaveBeenCalledOnce()
    expect(knowledge!.off).toHaveBeenCalledOnce()
  })

  it('unsubscribes at terminal status and clears the delayed banner', async () => {
    mocks.startResearch.mockResolvedValue({ dataflow_id: 'research-terminal' })
    const wrapper = mount(KnowledgePage, { attachTo: document.body })
    await flushPromises()
    await startResearch('terminal topic')

    const subscription = mocks.subscriptions.find(item => item.topic === 'dataflow:research-terminal')
    expect(subscription).toBeDefined()
    vi.useFakeTimers()
    subscription!.callback({ data: { status: 'completed_success' } })
    await flushPromises()

    expect(subscription!.off).toHaveBeenCalledOnce()
    expect(document.body.textContent).toContain('Research complete')
    await vi.advanceTimersByTimeAsync(5000)
    await nextTick()
    expect(document.body.textContent).not.toContain('Research complete')
    wrapper.unmount()
  })

  it('cancels a pending search debounce on unmount', async () => {
    vi.useFakeTimers()
    const wrapper = mount(KnowledgePage, { attachTo: document.body })
    await flushPromises()
    const search = wrapper.find('input[placeholder="Search knowledge..."]')
    await search.setValue('never execute')
    wrapper.unmount()

    await vi.advanceTimersByTimeAsync(300)
    expect(mocks.searchNodes).not.toHaveBeenCalled()
  })

  it('cancels the terminal-status dismissal timer on unmount', async () => {
    mocks.startResearch.mockResolvedValue({ dataflow_id: 'research-unmount' })
    const wrapper = mount(KnowledgePage, { attachTo: document.body })
    await flushPromises()
    await startResearch('unmount topic')

    const subscription = mocks.subscriptions.find(item => item.topic === 'dataflow:research-unmount')
    vi.useFakeTimers()
    subscription!.callback({ data: { status: 'completed_success' } })
    await flushPromises()
    expect(vi.getTimerCount()).toBe(1)

    wrapper.unmount()
    expect(vi.getTimerCount()).toBe(0)
  })
})
