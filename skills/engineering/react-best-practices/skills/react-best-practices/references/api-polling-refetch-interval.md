---
title: Poll With refetchInterval, Tuned Per Query
impact: MEDIUM
impactDescription: live data without a request storm
tags: api, tanstack-query, polling, realtime, refetchInterval
---

## Poll With refetchInterval, Tuned Per Query

Live views need polling, not a `setInterval` that races the cache.

**Incorrect (manual timer, no dedup, keeps running in a hidden tab):**

```tsx
useEffect(() => {
  const id = setInterval(() => {
    fetch('/api/events').then((r) => r.json()).then(setEvents)
  }, 5_000)
  return () => clearInterval(id)
}, [])
```

**Correct (per-query interval, paused in the background):**

```tsx
const EVENTS_INTERVAL = 5_000
const CHART_INTERVAL = 15_000
const GLOBE_INTERVAL = 20_000

// refetchIntervalInBackground defaults to false, so polling pauses when the
// tab is hidden — exactly the desired realtime behaviour.
const events = useQuery({
  queryKey: ['rt-events'],
  queryFn: () => statsApi.events({}),
  refetchInterval: EVENTS_INTERVAL,
})
const views = useQuery({
  queryKey: ['rt-views', windowKey],
  queryFn: () => statsApi.views({ startAt: Date.now() - WINDOWS[windowKey] }),
  refetchInterval: CHART_INTERVAL,
})
const location = useQuery({
  queryKey: ['rt-location', windowKey],
  queryFn: () => statsApi.location({ startAt: Date.now() - WINDOWS[windowKey] }),
  refetchInterval: GLOBE_INTERVAL,
})
```

Set the interval to the cost and volatility of the endpoint, not one constant for the page — an event ticker can poll at 5s while a globe aggregate polls at 20s.

`refetchIntervalInBackground` stays `false`: a hidden tab should not bill you for requests. For a poll that must stop on a condition, pass a function: `refetchInterval: (query) => (query.state.data?.done ? false : 3_000)`.

Polling is the fallback. If the backend offers SSE or WebSocket, subscribe and push into the cache with `queryClient.setQueryData` instead.
