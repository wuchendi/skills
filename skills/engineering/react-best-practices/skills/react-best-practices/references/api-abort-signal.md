---
title: Forward the Query Signal to fetch
impact: MEDIUM
impactDescription: cancels superseded requests
tags: api, tanstack-query, abort, cancellation, fetch
---

## Forward the Query Signal to fetch

`queryFn` receives an `AbortSignal`. Passing it through lets the library cancel in-flight requests when the key changes or the component unmounts — the difference between a search box that cancels stale requests and one that keeps ten sockets open.

**Incorrect (superseded requests run to completion):**

```tsx
useInfiniteQuery({
  queryKey: ['search', term],
  queryFn: async ({ pageParam }) => {
    const res = await fetch(`/api/search?q=${term}&page=${pageParam}`)
    return res.json()
  },
})
```

**Correct (cancelled on key change / unmount):**

```tsx
useInfiniteQuery({
  queryKey: ['search', term],
  queryFn: async ({ pageParam, signal }) => {
    const res = await fetch(
      `/api/search?q=${encodeURIComponent(term)}&page=${pageParam}`,
      { signal },
    )
    if (!res.ok) throw new Error('Failed to fetch')
    return res.json()
  },
})
```

Thread `signal` through the API module too, so cancellation survives the abstraction:

```typescript
export const searchApi = {
  query: (q: string, signal?: AbortSignal) =>
    request<SearchResult>(`/api/search?q=${encodeURIComponent(q)}`, { signal }),
}
```

An aborted fetch rejects with an `AbortError`; TanStack Query swallows it rather than surfacing it as a query error, so no extra handling is needed. Do not `catch` and re-throw it as a generic error in the wrapper — that turns a cancellation into a visible failure.
