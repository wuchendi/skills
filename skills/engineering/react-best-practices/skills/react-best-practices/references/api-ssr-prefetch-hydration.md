---
title: Prefetch on the Server, Hydrate on the Client
impact: HIGH
impactDescription: removes the auth→mount→fetch waterfall
tags: api, tanstack-query, ssr, hydration, next.js, prefetch
---

## Prefetch on the Server, Hydrate on the Client

A client query that runs on mount cannot start until the JS bundle has loaded and the component has hydrated. For above-the-fold data the server already has, prefetch into a per-request `QueryClient` and hand the dehydrated cache to the client.

**Incorrect (client waits for hydration to even start fetching):**

```tsx
// page.tsx (server component)
export default async function Page() {
  return <DashboardOverview /> // every stat card fetches after hydration
}
```

**Correct (server prefetch → hydration boundary):**

```tsx
import { dehydrate, HydrationBoundary, QueryClient } from '@tanstack/react-query'

export default async function DashboardOverviewPage() {
  const queryClient = new QueryClient()

  const user = await getAllowedSession(await headers())
  if (user) {
    await queryClient.prefetchQuery({
      queryKey: queryKeys.linkCount(),
      queryFn: async () => ({ total: await countLinks(env, user.id) }),
    })
  }

  return (
    <HydrationBoundary state={dehydrate(queryClient)}>
      <DashboardOverview />
    </HydrationBoundary>
  )
}
```

The client component keeps using `useQuery` with the *same key* and no special casing — the data is simply already there.

Rules for this to actually work:

- **Create the `QueryClient` inside the request handler.** A module-level client on the server shares one user's cache with the next request.
- **Keys must match exactly.** The factory (`api-query-key-factory`) is what makes that reliable.
- **Only prefetch stable-keyed queries.** A key anchored to a client-mount `Date.now()` window can never hydrate-match, so the server work is wasted and the client refetches anyway. Prefetch the "total links" counter; leave the 30-day analytics window client-fetched.
- `prefetchQuery` never throws — a failed prefetch degrades to a client fetch. Use `fetchQuery` only when the page should error.
- The server may prefetch several queries in parallel: `await Promise.all([...])`, not sequential awaits.
