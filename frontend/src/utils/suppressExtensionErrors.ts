/**
 * Suppress harmless browser extension errors in console
 * These errors occur when extensions try to communicate with content scripts
 * that don't exist or have been terminated. They're harmless and don't affect functionality.
 */

// Suppress runtime.lastError messages from browser extensions
if (typeof window !== 'undefined') {
  // Override console.error to filter extension errors
  const originalError = console.error
  const originalWarn = console.warn
  
  console.error = function(...args: any[]) {
    // Filter out harmless extension errors
    const errorMessage = String(args[0] || '')
    if (
      errorMessage.includes('runtime.lastError') ||
      errorMessage.includes('Receiving end does not exist') ||
      errorMessage.includes('Could not establish connection') ||
      errorMessage.includes('Extension context invalidated')
    ) {
      // Silently ignore these harmless extension errors
      return
    }
    // Log other errors normally
    originalError.apply(console, args)
  }

  console.warn = function(...args: any[]) {
    // Also filter warnings about extension errors
    const warningMessage = String(args[0] || '')
    if (
      warningMessage.includes('runtime.lastError') ||
      warningMessage.includes('Receiving end does not exist') ||
      warningMessage.includes('Could not establish connection') ||
      warningMessage.includes('Extension context invalidated')
    ) {
      return
    }
    originalWarn.apply(console, args)
  }

  // Suppress unhandled promise rejections from extensions
  window.addEventListener('unhandledrejection', (event) => {
    const reason = event.reason?.message || event.reason?.toString() || String(event.reason || '')
    if (
      reason.includes('runtime.lastError') ||
      reason.includes('Receiving end does not exist') ||
      reason.includes('Could not establish connection') ||
      reason.includes('Extension context invalidated')
    ) {
      event.preventDefault() // Suppress the error
      event.stopPropagation()
    }
  }, true) // Use capture phase to catch early

  // Also catch errors from error event
  window.addEventListener('error', (event) => {
    const errorMessage = event.message || String(event.error || '')
    if (
      errorMessage.includes('runtime.lastError') ||
      errorMessage.includes('Receiving end does not exist') ||
      errorMessage.includes('Could not establish connection') ||
      errorMessage.includes('Extension context invalidated')
    ) {
      event.preventDefault()
      event.stopPropagation()
      return false
    }
  }, true) // Use capture phase
}

