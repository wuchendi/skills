---
name: react-best-practices
description: Performance and data-layer rules for React and Next.js — 86 rules across 9 categories, from eliminating waterfalls and bundle size down to the TanStack Query API layer. Trigger when writing or reviewing React components, Next.js pages, hooks, or client data fetching; when the user asks to "optimize this component", "why does this re-render", "reduce bundle size", "fix this waterfall", "review my React code"; and for anything touching @tanstack/react-query — useQuery, useMutation, query keys, cache invalidation, infinite scroll, SSR prefetch, or polling.
metadata:
  author: wudi
  version: "2026.08.12"
  source: https://github.com/WuChenDi/skills
---

# react-best-practices

Rule-indexed guide for React and Next.js. Each rule is one file under `references/`, named `<prefix>-<slug>.md`, containing a short rationale plus an incorrect/correct pair.

**Read the index below, then load only the rule files relevant to the code at hand.** Do not read the whole `references/` directory.

## When to apply

- Writing new React components, hooks, or Next.js pages
- Implementing client data fetching or a mutation flow
- Reviewing or refactoring existing React code for performance
- Debugging re-renders, waterfalls, stale UI after a write, or bundle size

## Categories by priority

| # | Category | Impact | Prefix |
|---|----------|--------|--------|
| 1 | Eliminating Waterfalls | CRITICAL | `async-` |
| 2 | Bundle Size Optimization | CRITICAL | `bundle-` |
| 3 | API & Data Layer (TanStack Query) | HIGH | `api-` |
| 4 | Server-Side Performance | HIGH | `server-` |
| 5 | Client-Side Data Fetching | MEDIUM-HIGH | `client-` |
| 6 | Re-render Optimization | MEDIUM | `rerender-` |
| 7 | Rendering Performance | MEDIUM | `rendering-` |
| 8 | JavaScript Performance | LOW-MEDIUM | `js-` |
| 9 | Advanced Patterns | LOW | `advanced-` |

## 1. Eliminating Waterfalls (CRITICAL)

- `async-cheap-condition-before-await` — check cheap sync conditions before awaiting
- `async-defer-await` — move await into the branch that uses it
- `async-parallel` — `Promise.all()` for independent operations
- `async-dependencies` — better-all for partial dependencies
- `async-api-routes` — start promises early, await late
- `async-suspense-boundaries` — stream content with Suspense

## 2. Bundle Size Optimization (CRITICAL)

- `bundle-barrel-imports` — import directly, avoid barrel files
- `bundle-analyzable-paths` — statically analyzable imports and FS paths
- `bundle-dynamic-imports` — `next/dynamic` for heavy components
- `bundle-defer-third-party` — load analytics/logging after hydration
- `bundle-conditional` — load a module only when its feature activates
- `bundle-preload` — preload on hover/focus

## 3. API & Data Layer (HIGH) — TanStack Query

The house standard for client-side server state is **`@tanstack/react-query` v5**. Do not introduce SWR or hand-rolled fetch hooks into a project that uses it.

**Setup and structure**

- `api-tanstack-query-baseline` — one `QueryClient` per app in a client component, sane defaults
- `api-typed-client-module` — one `request<T>()` wrapper and a typed API module, never inline fetch
- `api-query-key-factory` — central key factory, hierarchical keys, prefix invalidation
- `api-query-options-factory` — `queryOptions()` for shared queries + `ensureQueryData`
- `api-no-server-state-in-store` — the cache owns server state; Zustand owns filters and selection

**Reading**

- `api-no-fetch-in-effect` — never `useState` + `useEffect` + `fetch`
- `api-parallel-queries` — independent queries run concurrently; `useQueries` for dynamic lists
- `api-enabled-dependent` — gate with `enabled`, not conditional hooks
- `api-stable-query-key` — debounce input into the key, keep derived key parts primitive
- `api-abort-signal` — forward the `queryFn` signal to `fetch`
- `api-select-narrow` — `select` to subscribe to a slice
- `api-infinite-query` — `useInfiniteQuery` for paged feeds
- `api-polling-refetch-interval` — `refetchInterval` per query, paused in background
- `api-ssr-prefetch-hydration` — `prefetchQuery` + `dehydrate` + `HydrationBoundary`

**Writing**

- `api-mutation-invalidate` — invalidate every key group a write affects
- `api-mutation-state` — use `isPending`, not a parallel `useState`
- `api-optimistic-update` — cancel, snapshot, patch, roll back, settle

## 4. Server-Side Performance (HIGH)

- `server-auth-actions` — authenticate server actions like API routes
- `server-cache-react` — `React.cache()` for per-request dedup
- `server-cache-lru` — LRU for cross-request caching
- `server-dedup-props` — avoid duplicate serialization in RSC props
- `server-hoist-static-io` — hoist static I/O to module level
- `server-no-shared-module-state` — no module-level mutable request state
- `server-serialization` — minimize data passed to client components
- `server-parallel-fetching` — restructure components to parallelize fetches
- `server-parallel-nested-fetching` — chain nested fetches per item in `Promise.all`
- `server-after-nonblocking` — `after()` for non-blocking work

## 5. Client-Side Data Fetching (MEDIUM-HIGH)

- `client-event-listeners` — deduplicate global event listeners
- `client-passive-event-listeners` — passive listeners for scroll
- `client-localstorage-schema` — version and minimize localStorage data

## 6. Re-render Optimization (MEDIUM)

- `rerender-defer-reads` — don't subscribe to state only used in callbacks
- `rerender-memo` — extract expensive work into memoized components
- `rerender-memo-with-default-value` — hoist default non-primitive props
- `rerender-dependencies` — primitive dependencies in effects
- `rerender-derived-state` — subscribe to derived booleans, not raw values
- `rerender-derived-state-no-effect` — derive during render, not in effects
- `rerender-functional-setstate` — functional setState for stable callbacks
- `rerender-lazy-state-init` — pass a function to `useState` for expensive values
- `rerender-simple-expression-in-memo` — no memo for simple primitives
- `rerender-split-combined-hooks` — split hooks with independent dependencies
- `rerender-move-effect-to-event` — interaction logic belongs in handlers
- `rerender-transitions` — `startTransition` for non-urgent updates
- `rerender-use-deferred-value` — defer expensive renders
- `rerender-use-ref-transient-values` — refs for transient frequent values
- `rerender-no-inline-components` — don't define components inside components

## 7. Rendering Performance (MEDIUM)

- `rendering-animate-svg-wrapper` — animate the wrapper, not the SVG
- `rendering-content-visibility` — `content-visibility` for long lists
- `rendering-hoist-jsx` — extract static JSX outside components
- `rendering-svg-precision` — reduce SVG coordinate precision
- `rendering-hydration-no-flicker` — inline script for client-only data
- `rendering-hydration-suppress-warning` — suppress expected mismatches
- `rendering-activity` — `Activity` for show/hide
- `rendering-conditional-render` — ternary, not `&&`
- `rendering-usetransition-loading` — `useTransition` for loading state
- `rendering-resource-hints` — React DOM resource hints
- `rendering-script-defer-async` — `defer`/`async` on scripts

## 8. JavaScript Performance (LOW-MEDIUM)

- `js-batch-dom-css` — group CSS changes via classes or `cssText`
- `js-index-maps` — build a Map for repeated lookups
- `js-cache-property-access` — cache object properties in loops
- `js-cache-function-results` — module-level Map for results
- `js-cache-storage` — cache storage reads
- `js-combine-iterations` — one loop instead of chained filter/map
- `js-length-check-first` — check length before expensive comparison
- `js-early-exit` — return early
- `js-hoist-regexp` — hoist `RegExp` out of loops
- `js-min-max-loop` — loop for min/max instead of sort
- `js-set-map-lookups` — Set/Map for O(1) lookups
- `js-tosorted-immutable` — `toSorted()` for immutability
- `js-flatmap-filter` — `flatMap` to map and filter in one pass
- `js-request-idle-callback` — defer non-critical work to idle time

## 9. Advanced Patterns (LOW)

- `advanced-effect-event-deps` — keep `useEffectEvent` results out of effect deps
- `advanced-event-handler-refs` — store event handlers in refs
- `advanced-init-once` — initialize once per app load
- `advanced-use-latest` — `useLatest` for stable callback refs

## How to use

1. Identify which categories the change touches. Data fetching → §3. A slow list → §6/§7. A big first load → §2.
2. Read those rule files from `references/`.
3. Apply the rule, and cite it by id when explaining the change (`api-mutation-invalidate`).

When reviewing, work top-down by priority. A waterfall or a missing invalidation costs more than a `js-` micro-optimization.
