---
title: Never Fetch in useEffect
impact: CRITICAL
impactDescription: removes duplicate requests, races, and missing states
tags: api, tanstack-query, useEffect, data-fetching, race-conditions
---

## Never Fetch in useEffect

The `useState` + `useEffect` + `fetch` triad has no deduplication, no cache, no cancellation, and no error state. Two mounts fire two requests; a fast unmount sets state on a dead component; an out-of-order response overwrites fresh data.

**Incorrect (races, no dedup, hand-rolled states):**

```tsx
function UsersPage() {
  const [users, setUsers] = useState<User[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<Error | null>(null)

  useEffect(() => {
    setLoading(true)
    fetch('/api/users')
      .then((r) => r.json())
      .then(setUsers)
      .catch(setError)
      .finally(() => setLoading(false))
  }, [])
}
```

**Correct (deduped, cached, cancellable):**

```tsx
function UsersPage() {
  const { data, isLoading, error } = useQuery({
    queryKey: ['users'],
    queryFn: () => userApi.list(),
  })

  const users = data ?? []
}
```

This applies to every read of server state, including one-shot config lookups. The only surviving `useEffect` fetches are those driven by a non-React event source (WebSocket subscription, `EventSource`), and even then the payload usually belongs in the query cache via `setQueryData`.

For a fetch that must run from an event handler rather than on render, use the imperative escape hatch — it still hits the cache:

```tsx
const config = await queryClient.ensureQueryData(configQueryOptions)
```
