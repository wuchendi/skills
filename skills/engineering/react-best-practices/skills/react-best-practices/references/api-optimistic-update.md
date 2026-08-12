---
title: Optimistic Updates Need Cancel, Snapshot, Rollback
impact: MEDIUM
impactDescription: instant feedback without corrupting the cache
tags: api, tanstack-query, useMutation, optimistic, cache
---

## Optimistic Updates Need Cancel, Snapshot, Rollback

Reserve optimistic updates for high-frequency, low-risk toggles (disable a link, star a row) where a round trip of latency is felt. Everything else should just invalidate on success — it is simpler and cannot desync.

When you do go optimistic, all four steps are mandatory. Skipping `cancelQueries` lets an in-flight refetch land *after* your optimistic write and clobber it.

**Incorrect (write without snapshot — nothing to roll back to):**

```tsx
const toggle = useMutation({
  mutationFn: (link: LinkRow) =>
    linkApi.edit({ id: link.id, config: { ...link.config, disabled: !link.config.disabled } }),
  onMutate: (link) => {
    queryClient.setQueryData(['links'], (old: LinkList) => patch(old, link))
    // request fails → UI keeps showing the wrong state
  },
})
```

**Correct (cancel → snapshot → patch → roll back → settle):**

```tsx
const toggle = useMutation({
  mutationFn: (link: LinkRow) =>
    linkApi.edit({ id: link.id, config: { ...link.config, disabled: !link.config.disabled } }),

  onMutate: async (link) => {
    // Stop in-flight refetches from overwriting the optimistic value.
    await queryClient.cancelQueries({ queryKey: ['links'] })
    const previous = queryClient.getQueriesData({ queryKey: ['links'] })

    queryClient.setQueriesData({ queryKey: ['links'] }, (old: LinkList | undefined) =>
      old
        ? {
            ...old,
            links: old.links.map((l) =>
              l.id === link.id
                ? { ...l, config: { ...l.config, disabled: !l.config.disabled } }
                : l,
            ),
          }
        : old,
    )

    return { previous }
  },

  onError: (e: Error, _link, context) => {
    for (const [key, data] of context?.previous ?? []) {
      queryClient.setQueryData(key, data)
    }
    toast.error(e.message)
  },

  // Reconcile with the server either way.
  onSettled: () => {
    void queryClient.invalidateQueries({ queryKey: ['links'] })
  },
})
```

The plain alternative — correct for most writes — is a straight `onSuccess` invalidation (`api-mutation-invalidate`). Choose optimism deliberately, not by default.
