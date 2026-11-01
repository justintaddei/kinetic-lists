<script setup lang="ts">
/**
 * PROTOTYPE ONLY — wayfinder #11. Lists: the row a List owns, the Set editor
 * behind it, and the Gate copy in the editor's emptiness — the one place the
 * unTagged rows are named, so they never become a group in the Kinetic View.
 */
import { ChevronLeftIcon, ListTodoIcon } from '@lucide/vue'
import PkDataRow from './PkDataRow.vue'

const { state, listsWithCounts, open, itemById, storeById, filterMatches, check } = usePrototypeKinetic()

const opened = ref<string | null>('standing')
const rows = computed(() => {
  if (!opened.value) return []
  return state.listItems
    .filter((li) => li.listId === opened.value)
    .map((li) => ({ ...li, item: itemById(li.itemId)! }))
    .sort((a, b) => a.item.name.localeCompare(b.item.name))
})
const counts = computed(() => {
  const set = (status: string) => new Set(rows.value.filter((r) => r.status === status).map((r) => r.itemId)).size
  return { needed: set('needed'), basket: set('in_basket'), stocked: set('stocked') }
})
const list = computed(() => listsWithCounts.value.find((l) => l.list.id === opened.value) ?? null)
</script>

<template>
  <section aria-label="Lists" data-screen="lists">
    <header v-if="!list" class="py-3">
      <p class="font-medium">Lists</p>
      <p class="text-sm text-muted-foreground">{{ listsWithCounts.length }} Lists in {{ state.household }}</p>
    </header>

    <ul v-if="!list" data-list-roster>
      <template v-for="entry in listsWithCounts" :key="entry.list.id">
        <li>
          <button type="button" class="flex min-h-12 w-full items-center gap-3 text-start" :aria-label="`Open ${entry.list.name}`" @click="opened = entry.list.id">
            <span class="min-w-0 flex-1">
              <span class="block text-base font-medium">{{ entry.list.name }}</span>
              <span class="text-sm text-muted-foreground block">{{ entry.needed }} Needed · {{ entry.basket }} In Basket · {{ entry.stocked }} Stocked</span>
            </span>
          </button>
        </li>
        <UiSeparator />
      </template>
    </ul>

    <template v-else>
      <header class="py-3">
        <UiButton variant="ghost" class="-ml-2 px-2" :aria-label="`Back to Lists`" @click="opened = null">
          <ChevronLeftIcon class="size-5" aria-hidden="true" />
          <span class="sr-only">Lists</span>
        </UiButton>
        <p class="text-base font-medium">{{ list.list.name }}</p>
        <p class="text-sm text-muted-foreground">
          {{ counts.needed }} Needed · {{ counts.basket }} In Basket · {{ counts.stocked }} Stocked
        </p>
      </header>

      <ul data-list-rows>
        <template v-for="row in rows.filter((r) => filterMatches(r.item.name))" :key="row.id">
          <li>
            <PkDataRow
              :name="row.item.name"
              :quiet="`${row.item.quantity} · ${row.item.category} · ${row.item.storeTags.length ? row.item.storeTags.map((t) => storeById(t)?.name).join(', ') : 'no Store Tag'}`"
              :pressed="row.status === 'in_basket'"
              :flash="state.live.includes(row.itemId)"
              :open-aria="`Open ${row.item.name}`"
              @check="check(row.itemId)"
              @open="open('item', { itemId: row.itemId })"
            />
          </li>
          <UiSeparator />
        </template>
      </ul>

      <UiEmpty v-if="rows.length === 0" class="py-10">
        <UiEmptyHeader>
          <UiEmptyMedia variant="icon"><ListTodoIcon aria-hidden="true" /></UiEmptyMedia>
          <UiEmptyTitle>This List is empty</UiEmptyTitle>
          <UiEmptyDescription>Capture puts an Item in here. A List is the shelf your Household stands by.</UiEmptyDescription>
          <UiEmptyContent>
            <UiButton data-open="capture" @click="open('capture')">Capture</UiButton>
          </UiEmptyContent>
        </UiEmptyHeader>
      </UiEmpty>

      <UiInputGroup v-if="rows.length >= 6" class="w-full pt-2" data-filter>
        <UiInput id="filter-list" v-model="state.filter" type="search" placeholder="Filter Items" class="w-full" />
      </UiInputGroup>
    </template>
  </section>
</template>
