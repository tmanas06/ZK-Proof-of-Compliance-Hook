// This file is served from /public and can be loaded even earlier
// Suppress browser extension errors immediately
(function() {
  'use strict';
  
  // Store original methods IMMEDIATELY
  const originalError = console.error;
  const originalWarn = console.warn;
  const originalLog = console.log;
  
  // Patterns to suppress
  const suppressPatterns = [
    'runtime.lastError',
    'Receiving end does not exist',
    'Could not establish connection',
    'Extension context invalidated',
    'message port closed',
    'channel closed'
  ];
  
  // Check if message should be suppressed
  function shouldSuppress(msg) {
    if (!msg) return false;
    const str = String(msg);
    return suppressPatterns.some(pattern => str.toLowerCase().includes(pattern.toLowerCase()));
  }
  
  // Override console.error
  Object.defineProperty(console, 'error', {
    value: function(...args) {
      if (args.length > 0 && shouldSuppress(args[0])) {
        return; // Suppress
      }
      originalError.apply(console, args);
    },
    writable: true,
    configurable: true
  });
  
  // Override console.warn
  Object.defineProperty(console, 'warn', {
    value: function(...args) {
      if (args.length > 0 && shouldSuppress(args[0])) {
        return; // Suppress
      }
      originalWarn.apply(console, args);
    },
    writable: true,
    configurable: true
  });
  
  // Override console.log
  Object.defineProperty(console, 'log', {
    value: function(...args) {
      if (args.length > 0 && shouldSuppress(args[0])) {
        return; // Suppress
      }
      originalLog.apply(console, args);
    },
    writable: true,
    configurable: true
  });
  
  // Suppress unhandled promise rejections
  window.addEventListener('unhandledrejection', function(e) {
    const reason = e.reason?.message || e.reason?.toString() || String(e.reason || '');
    if (shouldSuppress(reason)) {
      e.preventDefault();
      e.stopPropagation();
      return false;
    }
  }, true);
  
  // Suppress error events
  window.addEventListener('error', function(e) {
    const msg = e.message || String(e.error || '');
    if (shouldSuppress(msg)) {
      e.preventDefault();
      e.stopPropagation();
      return false;
    }
  }, true);
})();

