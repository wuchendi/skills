---
title: Invalidate Every Key a Mutation Affects
impact: HIGH
impactDescription: eliminates stale UI after writes
tags: api, tanstack-query, useMutation, invalidation, cache
---

## Invalidate Every Key a Mutation Affects

A write changes more than the list it came from. Deleting a link also changes the total count and every aggregate that counted it. Invalidate by prefix so all windows and param combinations drop together.

**Incorrect (only the obvious list is refreshed):**

```tsx
const remove = useMutation({
  mutationFn: (id: string) => linkApi.remove(id),
  onSuccess: () => {
    void queryClient.invalidateQueries({ queryKey: ['links'] })
    // the count card and the analytics charts still show the deleted link
  },
})
```

**Correct (the full blast radius, by prefix):**

```tsx
const remove = useMutation({
  mutationFn: (id: string) => linkApi.remove(id),
  onSuccess: () => {
    toast.success(t('delete.success'))
    setToDelete(null)
    void queryClient.invalidateQueries({ queryKey: ['links'] })
    // Deleting a link changes the total count and the overview/analytics
    // stats — invalidate those key groups by prefix so every window drops.
    void queryClient.invalidateQueries({ queryKey: queryKeys.linkCount() })
    void queryClient.invalidateQueries({ queryKey: ['stats', 'counters'] })
    void queryClient.invalidateQueries({ queryKey: ['stats', 'metrics'] })
  },
  onError: (e: Error) => toast.error(e.message),
})
```

Notes:

- `invalidateQueries` matches by key **prefix**, so `['links']` covers `['links', { page: 0, sort: 'new' }]` and every other filter combination.
- `void` the call unless the UI must wait — awaiting inside `onSuccess` keeps `isPending` true until the refetch settles, which is occasionally what you want (a drawer that should stay open until the list is fresh) and usually is not.
- Always attach `onError`. A mutation that fails silently reads to the user as a UI that ignored the click.
- Only the mutation's *own* cleanup belongs in `onSuccess`. Navigation (`router.push`) belongs there too, after invalidation is queued.
