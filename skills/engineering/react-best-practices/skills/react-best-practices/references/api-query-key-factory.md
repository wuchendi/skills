---
title: Derive Query Keys From a Central Factory
impact: HIGH
impactDescription: prevents cache misses and stale reads after mutations
tags: api, tanstack-query, query-keys, cache, invalidation
---

## Derive Query Keys From a Central Factory

Keys are the cache identity. Hand-written string arrays scattered across views drift — one view writes `['links', page]`, another `['link-list', page]`, and the same data is fetched twice and invalidated once.

**Incorrect (keys invented at each call site):**

```tsx
// overview.tsx
useQuery({ queryKey: ['count'], queryFn: () => linkApi.count() })

// links-view.tsx
useQuery({ queryKey: ['linkCount'], queryFn: () => linkApi.count() })

// after a delete — only one of the two is refreshed
queryClient.invalidateQueries({ queryKey: ['count'] })
```

**Correct (one factory, hierarchical keys):**

```typescript
// lib/query-keys.ts
export const queryKeys = {
  linkCount: () => ['link-count'] as const,
  counters: (params: StatsParams) => ['stats', 'counters', params] as const,
  views: (params: StatsParams) => ['stats', 'views', params] as const,
  metrics: (type: string, params: StatsParams, limit?: number) =>
    ['stats', 'metrics', type, params, limit ?? null] as const,
}
```

```tsx
useQuery({
  queryKey: queryKeys.counters({ startAt }),
  queryFn: () => statsApi.counters({ startAt }),
})
```

Order keys general → specific (`['stats', 'metrics', type, params]`) so a prefix invalidates a whole group:

```tsx
queryClient.invalidateQueries({ queryKey: ['stats', 'metrics'] })
```

Every value the `queryFn` reads must appear in the key. A param that changes the response but not the key returns stale cached data. Query keys are hashed deterministically, so object key order does not matter — but `undefined` and a missing field hash differently, so normalize optional params (`limit ?? null`).
