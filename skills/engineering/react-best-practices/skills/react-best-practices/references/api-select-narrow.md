---
title: Narrow With select to Cut Re-renders
impact: MEDIUM
impactDescription: component re-renders only when its slice changes
tags: api, tanstack-query, select, re-renders, performance
---

## Narrow With select to Cut Re-renders

A component subscribed to a whole query re-renders whenever any part of that response changes. `select` subscribes it to a derived slice instead — and the transform runs only when the underlying data changes, not on every render.

**Incorrect (whole payload subscribed, transform every render):**

```tsx
function LinkCount() {
  const { data } = useQuery({ queryKey: ['links'], queryFn: () => linkApi.list(params) })
  // Re-renders when any link field changes, even though only the total is shown.
  return <span>{data?.total ?? 0}</span>
}
```

**Correct (subscribed to one primitive):**

```tsx
function LinkCount() {
  const { data: total } = useQuery({
    queryKey: ['links', params],
    queryFn: () => linkApi.list(params),
    select: (d) => d.total,
  })
  return <span>{total ?? 0}</span>
}
```

Two caveats:

- **Return a stable reference.** `select: (d) => d.links.filter(...)` produces a new array each time it runs, which re-renders consumers. Prefer selecting primitives, or memoize the selector: `select: useCallback((d) => d.links.filter(f), [f])`.
- **`select` does not change what is fetched or cached** — the full response still lives in the cache under its key, and other components can select different slices from it. That is the point: one request, many narrow subscribers.

Related: `rerender-derived-state` and `rerender-memo` cover the same idea outside the query layer.
