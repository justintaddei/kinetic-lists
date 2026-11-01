<script setup lang="ts">
/**
 * PROTOTYPE ONLY — wayfinder #11, variant B: *Category headings*.
 *
 * Aisle order over A–Z: the column groups under quiet Category headings, which is
 * how the Shop's own aisles read, and it is the grouping a 40-Item Household
 * needs most. The heading names a Category, never a count — a count would be the
 * second shape competing to be the view's spine.
 */
import { MapPinnedIcon } from '@lucide/vue'
import PkDataRow from './PkDataRow.vue'

const { state, activeStore, standingLocation, byCategory, gate, filterMatches, check, open, arrivalLine } = usePrototypeKinetic()

const filtered = computed(() =>
  byCategory.value
    .map(([category, rows]) => [category, rows.filter((r) => filterMatches(r.item.name))])
    .filter(([, rows]) => rows.length > 0),
)
</script>

<template>
  <section aria-label="Kinetic View grouped by Category" data-variant="category">
    <header v-if="activeStore" class="py-3" data-grouping-headline>
      <p class="font-medium">{{ activeStore.name }} · Needed</p>
      <p v-if="state.arrivalForm === 'line' && standingLocation" class="text-sm text-muted-foreground">{{ arrivalLine() }}</p>
      <p class="text-sm text-muted-foreground">
        {{ gate.needed }} Needed · {{ gate.basket }} In Basket<template v-if="gate.untaggedAtStore"> · {{ gate.untaggedAtStore }} with no Tag at {{ activeStore.name }}</template>
      </p>
    </header>

    <UiInputGroup v-if="gate.needed >= 6" class="w-full pb-2" data-filter>
      <UiInput id="filter-items" v-model="state.filter" type="search" placeholder="Filter Items" class="w-full" />
    </UiInputGroup>

    <section v-for="[category, rows] in filtered" :key="category" class="pb-1">
      <h2 class="text-sm text-muted-foreground pt-3 pb-1" :aria-label="`Category ${category}`">{{ category }}</h2>
      <ul :aria-label="`${category} rows`">
        <template v-for="row in rows" :key="row.key">
          <li>
            <PkDataRow
              :name="row.item.name"
              :quiet="`${row.item.quantity} · ${row.lists.map((l) => l.name).join(', ')}`"
              :flash="state.live.includes(row.key)"
              :open-aria="`Open ${row.item.name}`"
              @check="check(row.key)"
              @open="open('item', { itemId: row.key })"
            />
          </li>
          <UiSeparator />
        </template>
      </ul>
    </section>

    <UiEmpty v-if="!activeStore" class="py-16" data-kinetic-empty>
      <UiEmptyHeader>
        <UiEmptyMedia variant="icon"><MapPinnedIcon aria-hidden="true" /></UiEmptyMedia>
        <UiEmptyTitle>Pick a Store</UiEmptyTitle>
        <UiEmptyDescription>Category headings need a Store's Tags to group. Add a shop from where you are.</UiEmptyDescription>
        <UiEmptyContent>
          <UiButton data-open="mint" @click="open('mint', { door: 'header' })">Add Store</UiButton>
        </UiEmptyContent>
      </UiEmptyHeader>
    </UiEmpty>
  </section>
</template>
