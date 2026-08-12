---
title: Use useInfiniteQuery for Paged Feeds
impact: MEDIUM-HIGH
impactDescription: correct page accumulation and cache reuse
tags: api, tanstack-query, useInfiniteQuery, pagination, infinite-scroll
---

## Use useInfiniteQuery for Paged Feeds

Appending pages by hand (`setItems([...items, ...next])`) puts server state in component state: it resets on unmount, breaks on filter change, and double-appends under StrictMode.

**Incorrect (manual accumulation):**

```tsx
const [items, setItems] = useState<Video[]>([])
const [page, setPage] = useState(0)

useEffect(() => {
  fetch(`/api/feed?page=${page}`)
    .then((r) => r.json())
    .then((next) => setItems((prev) => [...prev, ...next]))
}, [page])
```

**Correct (pages owned by the cache):**

```tsx
const PAGE_LIMIT = 20

const { data, isLoading, isFetchingNextPage, fetchNextPage, hasNextPage } =
  useInfiniteQuery({
    queryKey: ['popularMovies', contentType, tagValue],
    queryFn: async ({ pageParam, signal }) => {
      const res = await fetch(
        `/api/recommend?tag=${encodeURIComponent(tagValue)}&limit=${PAGE_LIMIT}&start=${pageParam}`,
        { signal },
      )
      if (!res.ok) throw new Error('Failed to fetch')
      return (await res.json()).items as Video[]
    },
    initialPageParam: 0,
    getNextPageParam: (lastPage, _allPages, lastPageParam) =>
      lastPage.length === PAGE_LIMIT ? lastPageParam + PAGE_LIMIT : undefined,
    staleTime: 5 * 60 * 1000,
  })

// Flatten once per pages change, not per render.
const movies = useMemo(() => data?.pages.flat() ?? [], [data?.pages])
```

Key points:

- `getNextPageParam` returning `undefined` is what sets `hasNextPage: false` — derive it from the page size, not from a separate "hasMore" flag the server may not send.
- Memoize the flatten. `data.pages.flat()` inline allocates a new array every render and defeats downstream memoized children.
- Distinguish `isLoading` (first page) from `isFetchingNextPage` (subsequent) so the initial skeleton and the footer spinner are not the same thing.
- Wrap the hook in a feature hook (`usePopularMovies`) that returns exactly what the view needs; the view should not know about `pages`.
