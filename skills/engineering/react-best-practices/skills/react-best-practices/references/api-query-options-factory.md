---
title: Share Queries With queryOptions()
impact: MEDIUM-HIGH
impactDescription: one definition, typed, reusable imperatively
tags: api, tanstack-query, queryOptions, reuse, typing
---

## Share Queries With queryOptions()

When more than one component — or a component *and* an event handler — needs the same query, define it once with `queryOptions()`. The helper keeps key and `queryFn` types tied together, and the result is accepted by `useQuery`, `prefetchQuery`, `ensureQueryData`, and `setQueryData` alike.

**Incorrect (the same query re-declared, drifting options):**

```tsx
// ShareCard.tsx
useQuery({ queryKey: ['config'], queryFn: () => api.getConfig(), staleTime: 60_000 })

// RetrieveEntry.tsx — different key, second network request
useQuery({ queryKey: ['app-config'], queryFn: () => api.getConfig() })
```

**Correct (single definition, reused everywhere):**

```typescript
// lib/queries.ts
import { queryOptions } from '@tanstack/react-query'

export const configQueryOptions = queryOptions({
  queryKey: ['app-config'],
  queryFn: () => api.getConfig(),
  staleTime: 60_000,
})
```

```tsx
// in render
const { data: config } = useQuery(configQueryOptions)

// in an event handler / mutationFn — resolves from cache when fresh,
// fetches once and shares the in-flight promise when not
const config = await queryClient.ensureQueryData(configQueryOptions)
```

`ensureQueryData` is the correct imperative read: unlike `fetchQuery` it respects `staleTime`, so a hot path does not re-request data another component already loaded. Reach for it when a click handler needs data that may or may not be cached yet.
