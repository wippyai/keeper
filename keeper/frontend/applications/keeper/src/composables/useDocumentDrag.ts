import { onUnmounted } from 'vue'

interface DocumentDragOptions {
  cursor?: string
  onMove: (event: MouseEvent) => void
  onStop?: () => void
}

/**
 * Owns a document-level mouse drag for the lifetime of the current component.
 *
 * Document listeners and temporary body styles must be released even when the
 * component disappears before mouseup (for example, during route navigation).
 */
export function useDocumentDrag() {
  let cleanup: (() => void) | null = null

  function stopDrag() {
    const activeCleanup = cleanup
    cleanup = null
    activeCleanup?.()
  }

  function startDrag(event: MouseEvent, options: DocumentDragOptions) {
    event.preventDefault()
    stopDrag()

    const previousCursor = document.body.style.cursor
    const previousUserSelect = document.body.style.userSelect
    const onMouseMove = (moveEvent: MouseEvent) => options.onMove(moveEvent)
    const onMouseUp = () => stopDrag()

    document.addEventListener('mousemove', onMouseMove)
    document.addEventListener('mouseup', onMouseUp)
    document.body.style.cursor = options.cursor ?? 'col-resize'
    document.body.style.userSelect = 'none'

    cleanup = () => {
      document.removeEventListener('mousemove', onMouseMove)
      document.removeEventListener('mouseup', onMouseUp)
      document.body.style.cursor = previousCursor
      document.body.style.userSelect = previousUserSelect
      options.onStop?.()
    }
  }

  onUnmounted(stopDrag)

  return { startDrag, stopDrag }
}
