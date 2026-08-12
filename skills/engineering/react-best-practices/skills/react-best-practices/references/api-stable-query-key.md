---
title: Keep Query Keys Stable and Debounced
impact: MEDIUM-HIGH
impactDescription: cuts request volume on every keystroke
tags: api, tanstack-query, query-keys, debounce, re-renders
---

## Keep Query Keys Stable and Debounced

Every key change is a cache lookup and, on a miss, a request. Two things blow that up: raw input bound straight into the key, and unstable derived values.

**Incorrect (a request per keystroke, key churns on unrelated changes):**

```tsx
const [input, setInput] = useState('')

const query = useQuery({
  queryKey: ['links', input],          // fires on every character
  queryFn: () => linkApi.search(input),
})

const popular = useQuery({
  queryKey: ['popular', tags],          // new array identity each render
  queryFn: () => api.popular(tags),
})
```

**Correct (debounced input, key derived to a primitive):**

```tsx
const [input, setInput] = useState(search)

// Debounce the search box into the store that feeds the key.
useEffect(() => {
  const id = setTimeout(() => setSearch(input.trim()), 300)
  return () => clearTimeout(id)
}, [input, setSearch])

const query = useQuery({
  queryKey: ['links', { search, sort, page, status, tags, tagMatch }],
  queryFn: () => linkApi.list({ search, sort, offset: page * PAGE_SIZE, ... }),
})
```

```tsx
// Resolve to a stable string so unrelated `tags` reference changes
// don't cause an unnecessary re-fetch.
const tagValue = tags.find((t) => t.id === selectedTag)?.value || 'popular'

useInfiniteQuery({
  queryKey: ['popularMovies', contentType, tagValue],
  ...
})
```

Related: anchor time windows once, not per render. `Date.now()` in a key produces a new key on every render and refetches forever:

```tsx
// Fixed at first render — the 30d window is anchored to page load.
const startAt = useMemo(() => Date.now() - THIRTY_DAYS, [])
```

Reset pagination when a filter changes, or page 3 of the old filter is requested against the new one:

```tsx
useEffect(() => {
  setPage(0)
}, [search, sort, status, startAt, endAt, tags, tagMatch, untagged])
```

To keep the previous page visible while the next loads instead of flashing a skeleton, add `placeholderData: keepPreviousData`.
