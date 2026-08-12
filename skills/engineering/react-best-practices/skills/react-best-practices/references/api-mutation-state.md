---
title: Use Mutation State, Not a Parallel useState
impact: MEDIUM
impactDescription: removes a whole class of stuck-spinner bugs
tags: api, tanstack-query, useMutation, loading-state, forms
---

## Use Mutation State, Not a Parallel useState

`useMutation` already tracks pending/error/success. A hand-rolled `loading` flag drifts on every early return and thrown error, leaving the button disabled forever.

**Incorrect (duplicate state, leaks on throw):**

```tsx
const [saving, setSaving] = useState(false)

async function onSubmit() {
  setSaving(true)
  const res = await linkApi.create(payload) // throws → setSaving(false) never runs
  setSaving(false)
  toast.success('Created')
}
```

**Correct (state owned by the mutation):**

```tsx
const save = useMutation({
  mutationFn: () => (isEdit ? linkApi.edit({ ...payload, id }) : linkApi.create(payload)),
  onSuccess: () => {
    toast.success(isEdit ? t('updated') : t('created'))
    void queryClient.invalidateQueries({ queryKey: ['links'] })
    router.push('/dashboard/links')
  },
  onError: (e: Error) => toast.error(e.message),
})

return (
  <Button onClick={() => save.mutate()} disabled={save.isPending}>
    {save.isPending ? <Spinner /> : t('save')}
  </Button>
)
```

Use `mutate` for fire-and-forget from a handler; use `mutateAsync` only when the caller genuinely needs to await the result — it rejects, so it requires a `try/catch` that `mutate` does not.

Keep validation *outside* the mutation and bail before calling `mutate`, so an invalid form never enters the pending state:

```tsx
const retrieve = () => {
  const c = code.trim().toUpperCase()
  if (c.length < 6 || c.length > 8) return
  retrieveMutation.mutate()
}
```
