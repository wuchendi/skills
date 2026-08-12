---
title: Deduplicate Global Event Listeners
impact: LOW
impactDescription: single listener for N components
tags: client, event-listeners, subscription
---

## Deduplicate Global Event Listeners

Attach one module-level listener and fan out to subscribers, instead of one `addEventListener` per hook instance.

**Incorrect (N instances = N listeners):**

```tsx
function useKeyboardShortcut(key: string, callback: () => void) {
  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if (e.metaKey && e.key === key) {
        callback()
      }
    }
    window.addEventListener('keydown', handler)
    return () => window.removeEventListener('keydown', handler)
  }, [key, callback])
}
```

When using the `useKeyboardShortcut` hook multiple times, each instance will register a new listener.

**Correct (N instances = 1 listener):**

```tsx
// Module-level registry: one listener, refcounted by subscriber count.
const keyCallbacks = new Map<string, Set<() => void>>()
let subscribers = 0
let detach: (() => void) | undefined

function attach() {
  const handler = (e: KeyboardEvent) => {
    if (e.metaKey) keyCallbacks.get(e.key)?.forEach((cb) => cb())
  }
  window.addEventListener('keydown', handler)
  return () => window.removeEventListener('keydown', handler)
}

function useKeyboardShortcut(key: string, callback: () => void) {
  // Keep the latest callback without re-subscribing on every render.
  const latest = useRef(callback)
  latest.current = callback

  useEffect(() => {
    const fn = () => latest.current()
    let set = keyCallbacks.get(key)
    if (!set) {
      set = new Set()
      keyCallbacks.set(key, set)
    }
    set.add(fn)
    if (subscribers++ === 0) detach = attach()

    return () => {
      set.delete(fn)
      if (set.size === 0) keyCallbacks.delete(key)
      if (--subscribers === 0) {
        detach?.()
        detach = undefined
      }
    }
  }, [key])
}

function Profile() {
  // Multiple shortcuts will share the same listener
  useKeyboardShortcut('p', () => { /* ... */ }) 
  useKeyboardShortcut('k', () => { /* ... */ })
  // ...
}
```
