'use client'

import { Button } from '@cdlab/ui/components/button'
import { useTranslations } from 'next-intl'

export default function Error({ reset }: { reset: () => void }) {
  const t = useTranslations('error')

  return (
    <div className="min-h-screen flex items-center justify-center p-6">
      <div className="text-center space-y-4">
        <h1 className="text-2xl font-bold">{t('title')}</h1>
        <p className="text-sm text-muted-foreground">{t('description')}</p>
        <Button onClick={() => reset()} size="lg">
          {t('tryAgain')}
        </Button>
      </div>
    </div>
  )
}
