'use client'

import { Button } from '@cdlab/ui/components/button'

export default function Error({ reset }: { reset: () => void }) {
  return (
    <div className="min-h-screen flex items-center justify-center p-6">
      <div className="text-center space-y-4">
        <h1 className="text-2xl font-bold">Oh no!</h1>
        <p className="text-sm text-muted-foreground">
          There was an issue. This could be a temporary problem, please try
          your action again.
        </p>
        <Button onClick={() => reset()} size="lg">
          Try Again
        </Button>
      </div>
    </div>
  )
}
