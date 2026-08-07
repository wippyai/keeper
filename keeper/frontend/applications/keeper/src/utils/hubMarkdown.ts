import MarkdownIt from 'markdown-it'
import sanitizeHtml from 'sanitize-html'

const markdown = new MarkdownIt({
  html: false,
  breaks: true,
  linkify: true,
  typographer: false,
})

const allowedTags = [
  'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
  'blockquote', 'p', 'a', 'ul', 'ol', 'li',
  'strong', 'em', 's', 'code', 'pre', 'hr', 'br',
  'table', 'thead', 'tbody', 'tr', 'th', 'td',
  'img',
]

const allowedAttributes: sanitizeHtml.IOptions['allowedAttributes'] = {
  a: ['href', 'title', 'target', 'rel'],
  img: ['src', 'alt', 'title', 'loading', 'referrerpolicy'],
  code: ['class'],
}

/**
 * Render Hub README Markdown as inert, allowlisted HTML.
 *
 * Hub content is external input. Raw HTML is disabled in the Markdown parser,
 * then the generated HTML is sanitized as a second boundary. Links may use
 * HTTP(S), mailto, or relative URLs; images are restricted to HTTP(S) or
 * relative URLs. Scriptable schemes and arbitrary attributes never reach the
 * DOM.
 */
export function renderHubMarkdown(source: string): string {
  if (!source) return ''

  return sanitizeHtml(markdown.render(source), {
    allowedTags,
    allowedAttributes,
    allowedClasses: {
      code: ['language-*'],
    },
    allowedSchemes: ['http', 'https', 'mailto'],
    allowedSchemesByTag: {
      img: ['http', 'https'],
    },
    allowProtocolRelative: false,
    transformTags: {
      a: (tagName, attribs) => ({
        tagName,
        attribs: {
          ...attribs,
          target: '_blank',
          rel: 'noopener noreferrer',
        },
      }),
      img: (tagName, attribs) => ({
        tagName,
        attribs: {
          ...attribs,
          loading: 'lazy',
          referrerpolicy: 'no-referrer',
        },
      }),
    },
  })
}
