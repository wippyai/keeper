// @vitest-environment happy-dom
import { describe, expect, it } from 'vitest'
import { renderHubMarkdown } from '../hubMarkdown'

function renderedBody(source: string): HTMLElement {
  const body = document.createElement('div')
  body.innerHTML = renderHubMarkdown(source)
  return body
}

describe('renderHubMarkdown', () => {
  it('does not turn raw HTML or unquoted event handlers into active DOM', () => {
    const body = renderedBody('<img src=x onerror=alert(1)>')

    expect(body.querySelector('img')).toBeNull()
    expect(body.querySelector('[onerror]')).toBeNull()
  })

  it('removes scriptable link and image schemes', () => {
    const body = renderedBody([
      '[bad link](javascript:alert(1))',
      '![bad image](data:image/svg+xml;base64,PHN2Zy8+)',
    ].join('\n\n'))

    expect(body.querySelector('a[href^="javascript:"]')).toBeNull()
    expect(body.querySelector('img[src^="data:"]')).toBeNull()
  })

  it('keeps malformed tags inert', () => {
    const body = renderedBody('<scr<script>ipt>alert(1)</scr</script>ipt>')

    expect(body.querySelector('script')).toBeNull()
    expect(body.querySelector('[onclick], [onload], [onerror]')).toBeNull()
  })

  it('renders legitimate README Markdown with safe links, images, tables, and code', () => {
    const body = renderedBody([
      '# Example module',
      '',
      'A **useful** README with [documentation](https://docs.example.test/guide).',
      '',
      '![Architecture](./architecture.png "Diagram")',
      '',
      '| Name | Value |',
      '| --- | --- |',
      '| mode | safe |',
      '',
      '```lua',
      'return { ok = true }',
      '```',
    ].join('\n'))

    expect(body.querySelector('h1')?.textContent).toBe('Example module')
    expect(body.querySelector('strong')?.textContent).toBe('useful')
    expect(body.querySelector('table td')?.textContent).toBe('mode')
    expect(body.querySelector('code.language-lua')?.textContent).toContain('return { ok = true }')

    const link = body.querySelector('a')
    expect(link?.getAttribute('href')).toBe('https://docs.example.test/guide')
    expect(link?.getAttribute('target')).toBe('_blank')
    expect(link?.getAttribute('rel')).toBe('noopener noreferrer')

    const image = body.querySelector('img')
    expect(image?.getAttribute('src')).toBe('./architecture.png')
    expect(image?.getAttribute('loading')).toBe('lazy')
    expect(image?.getAttribute('referrerpolicy')).toBe('no-referrer')
  })
})
