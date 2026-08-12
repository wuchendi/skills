---
title: TanStack Query Is the Client Data Layer
impact: CRITICAL
impactDescription: one cache, one request per key
tags: api, tanstack-query, react-query, setup, data-fetching
---

## TanStack Query Is the Client Data Layer

All client-side server state goes through `@tanstack/react-query` (v5). One `QueryClient` per app, created inside a client component so each SSR request gets its own cache — a module-level client leaks one user's data into another user's render.

**Incorrect (module-level client shared across requests):**

```tsx
// providers.tsx
const queryClient = new QueryClient() // shared by every SSR request

export function ClientProviders({ children }: { children: React.ReactNode }) {
  return <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
}
```

**Correct (one client per app instance, stable across re-renders):**

```tsx
'use client'

import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { useMemo } from 'react'

export function ClientProviders({ children }: { children: React.ReactNode }) {
  const queryClient = useMemo(
    () =>
      new QueryClient({
        defaultOptions: {
          queries: {
            staleTime: 30_000,
            refetchOnWindowFocus: false,
          },
        },
      }),
    [],
  )

  return (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  )
}
```

Set `staleTime` in the defaults, not per call site. The library default of `0` makes every mount refetch, which defeats the cache on tab switches and route changes. `30_000` is a sane baseline; raise it per query for data that rarely changes.

`refetchOnWindowFocus: false` is the default for dashboards and internal tools — background refetch on every alt-tab is noise. Opt back in per query for genuinely live data.

Reference: [https://tanstack.com/query/latest](https://tanstack.com/query/latest)
