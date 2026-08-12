---
title: Keep Server State Out of the Client Store
impact: MEDIUM-HIGH
impactDescription: removes an entire class of stale-data bugs
tags: api, tanstack-query, zustand, state-management, architecture
---

## Keep Server State Out of the Client Store

TanStack Query owns server state. Zustand / `useState` own client state — filters, selection, drafts, dialog flags. Copying query results into a store creates a second source of truth that no invalidation can reach.

**Incorrect (query data mirrored into a store):**

```tsx
const setLinks = useLinksStore((s) => s.setLinks)

const { data } = useQuery({ queryKey: ['links'], queryFn: () => linkApi.list() })

useEffect(() => {
  if (data) setLinks(data.links) // now two copies, and the store one goes stale
}, [data, setLinks])
```

**Correct (store holds inputs; query holds the result):**

```tsx
// Store: only what the user chose.
const { search, sort, status, tags, tagMatch, untagged } = useLinksFilterStore()

// Query: derived server state, keyed by those choices.
const query = useQuery({
  queryKey: ['links', { search, sort, page, status, tags, tagMatch, untagged }],
  queryFn: () => linkApi.list({ search, sort, offset: page * PAGE_SIZE, status, tags }),
})

const rows = query.data?.links ?? []
const total = query.data?.total ?? 0
```

Selection and dialog state stay local because they are about *this* view, not about the server:

```tsx
const [selected, setSelected] = useState<Set<string>>(new Set())
const [drawerOpen, setDrawerOpen] = useState(false)
```

The one legitimate write into the cache is `queryClient.setQueryData` — updating the cache in place (optimistic updates, a WebSocket push). That keeps a single source of truth; a parallel store does not.

Read query data directly with `??` defaults rather than syncing it into state. `data?.links ?? []` is not worth an effect.
