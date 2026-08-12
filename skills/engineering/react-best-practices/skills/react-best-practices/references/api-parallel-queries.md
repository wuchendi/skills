---
title: Fetch Independent Data in Parallel
impact: CRITICAL
impactDescription: turns N sequential round trips into one
tags: api, tanstack-query, parallel, waterfalls, useQueries
---

## Fetch Independent Data in Parallel

Separate `useQuery` calls in the same component run concurrently — that is the point. A waterfall only appears when you make one query wait for another, or when you serialize requests inside a single `queryFn`.

**Incorrect (one queryFn awaiting in sequence):**

```tsx
const { data } = useQuery({
  queryKey: ['overview'],
  queryFn: async () => {
    const count = await linkApi.count()
    const counters = await statsApi.counters({ startAt })
    const views = await statsApi.views({ startAt })
    return { count, counters, views }
  },
})
```

Three full round trips, one shared cache entry, one shared loading state — the whole card grid blocks on the slowest call.

**Correct (independent queries, independent keys, independent skeletons):**

```tsx
const countQuery = useQuery({
  queryKey: queryKeys.linkCount(),
  queryFn: () => linkApi.count(),
})
const countersQuery = useQuery({
  queryKey: queryKeys.counters({ startAt }),
  queryFn: () => statsApi.counters({ startAt }),
})
const viewsQuery = useQuery({
  queryKey: queryKeys.views({ startAt }),
  queryFn: () => statsApi.views({ startAt }),
})
```

Each card renders as its own data lands, and each key is independently cacheable and invalidatable.

**For a dynamic-length list of queries**, use `useQueries` — you cannot loop `useQuery`:

```tsx
const results = useQueries({
  queries: ids.map((id) => ({
    queryKey: ['launchpad', id],
    queryFn: () => api.get(id),
  })),
})
```

If the server can answer in one call, prefer that over N queries: fetch click counts for all visible rows in one batched metrics request grouped by slug, rather than one request per row. Batching beats parallelism.

When several independent requests genuinely belong to one cache entry, parallelize *inside* the `queryFn` with `Promise.all` — see `async-parallel`.
