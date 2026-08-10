import { sql } from 'drizzle-orm'
import { integer, sqliteTable, text } from 'drizzle-orm/sqlite-core'

/**
 * Shared tracking fields. Every user-facing table should spread this in.
 * Convention: never hard-delete — always set isDeleted = 1 and filter
 * `eq(table.isDeleted, 0)` on reads. The flag is a plain integer, not a
 * boolean-mode column, to stay compatible with the rest of the fleet.
 */
export const trackingFields = {
  createdAt: integer('created_at', { mode: 'timestamp' })
    .default(sql`(unixepoch())`)
    .notNull(),
  updatedAt: integer('updated_at', { mode: 'timestamp' })
    .default(sql`(unixepoch())`)
    .$onUpdateFn(() => new Date())
    .notNull(),
  isDeleted: integer('is_deleted').notNull().default(0),
}

export const items = sqliteTable('items', {
  id: text('id').primaryKey(),
  name: text('name').notNull(),
  ...trackingFields,
})
