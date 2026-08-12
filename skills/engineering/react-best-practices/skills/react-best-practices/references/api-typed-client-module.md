---
title: Centralize Requests in a Typed API Module
impact: HIGH
impactDescription: one place for headers, errors, and response types
tags: api, tanstack-query, fetch, typing, error-handling
---

## Centralize Requests in a Typed API Module

`queryFn` should call a named function from an API module, not inline `fetch`. One `request<T>()` wrapper owns headers, error parsing, and the JSON cast; every endpoint above it is a one-liner with a real return type.

**Incorrect (inline fetch, untyped, error handling per call site):**

```tsx
const { data } = useQuery({
  queryKey: ['links', page],
  queryFn: async () => {
    const res = await fetch(`/api/link/list?offset=${page * 20}`)
    if (!res.ok) throw new Error('failed')
    return res.json() // any
  },
})
```

**Correct (typed module, one error path):**

```typescript
// lib/api.ts
export class ApiClientError extends Error {
  readonly status: number
  constructor(message: string, status: number) {
    super(message)
    this.name = 'ApiClientError'
    this.status = status
  }
}

async function parseError(res: Response): Promise<ApiClientError> {
  const body = (await res.json().catch(() => ({}))) as { error?: string }
  return new ApiClientError(body.error || res.statusText, res.status)
}

async function request<T>(path: string, init?: RequestInit): Promise<T> {
  const res = await fetch(path, {
    ...init,
    headers: { 'content-type': 'application/json', ...init?.headers },
  })
  if (!res.ok) throw await parseError(res)
  return res.json() as Promise<T>
}

export const linkApi = {
  list: (params: ListParams) =>
    request<{ links: LinkRow[]; total: number }>(`/api/link/list?${toQuery(params)}`),
  count: () => request<{ total: number }>('/api/link/count'),
  remove: (id: string) =>
    request<{ ok: true }>('/api/link/delete', {
      method: 'POST',
      body: JSON.stringify({ id }),
    }),
}
```

```tsx
const { data } = useQuery({
  queryKey: ['links', { page }],
  queryFn: () => linkApi.list({ limit: 20, offset: page * 20 }),
})
```

A typed error class lets UI branch on `status` (401 → sign-in, 404 → empty state) instead of string-matching messages. Keep error messages in English — they surface in logs.

Add a timeout via `AbortController` in the wrapper when the API talks to a third party that can hang.
