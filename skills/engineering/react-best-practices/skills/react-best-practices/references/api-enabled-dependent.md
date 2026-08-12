---
title: Gate Queries With enabled, Not Conditional Hooks
impact: HIGH
impactDescription: avoids wasted requests and hook-order crashes
tags: api, tanstack-query, enabled, dependent-queries, hooks
---

## Gate Queries With enabled, Not Conditional Hooks

Hooks cannot be called conditionally. When a query depends on a value that is not ready yet — a route param on a "new" page, an id from a previous query — express that with `enabled`, not with an early return or a wrapper component.

**Incorrect (conditional hook / wasted request):**

```tsx
function LaunchpadEditor({ id }: { id?: string }) {
  if (id) {
    // Rendered conditionally → hook order changes between renders
    const { data } = useQuery({ queryKey: ['launchpad', id], queryFn: () => api.get(id) })
  }
}
```

```tsx
// Also wrong: fires with an undefined id and 404s on the "new" route
const { data } = useQuery({
  queryKey: ['launchpad', id],
  queryFn: () => api.get(id!),
})
```

**Correct (always called, conditionally enabled):**

```tsx
const existing = useQuery({
  queryKey: ['launchpad', id],
  queryFn: () => api.get(id!),
  enabled: !isNew,
})

const stats = useQuery({
  queryKey: ['launchpad-stats', statsIds],
  queryFn: () => statsApi.forIds(statsIds),
  enabled: statsIds.length > 0,
})

const track = useQuery({
  queryKey: ['track', launchpadId, startAt],
  queryFn: () => statsApi.track(launchpadId!, startAt!),
  enabled: Boolean(launchpadId && startAt),
})
```

A disabled query stays in `isPending` with `fetchStatus: 'idle'` — check `isLoading` (which accounts for both) rather than `isPending` when rendering a spinner, or a permanently-disabled query spins forever.

Chaining `enabled` off a previous query's data creates a deliberate waterfall. Accept it only when the second request genuinely cannot be formed without the first; otherwise see `api-parallel-queries`.
