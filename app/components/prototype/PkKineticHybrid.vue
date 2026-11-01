<script setup lang="ts">
/**
 * PROTOTYPE ONLY — wayfinder #11, variant C: *the Hybrid — Active Store and the
 * Store-shelf beyond it*.
 *
 * With a Store Picked, this is Category headers (variant B). With no Store Picked
 * it refuses the emptiness: it groups the whole Household's Needed rows by Store
 * Tag — the cross-Store overview Ticket 2 named as a possible second reading —
 * with one unTagged group named for what it is, since an unTagged Item is invisible
 * in every Store-scoped view on purpose.
 *
 * The deliberate contrast with the settled design: ADR-0024's Kinetic View with no
 * Active Store is `UiEmpty` and an Add Store control. This variant says the view's
 * reason for existing survives a missing Store, because the rows know their Tags.
 */
import { MapPinnedIcon } from '@lucide/vue'
import PkDataRow from './PkDataRow.vue'

const { state, activeStore, shelfByStore, byCategory, gate, listsWithCounts, filterMatches, check, open } = usePrototypeKinetic()

const untaggedCount = computed(() => shelfByStore.value.untagged.length)
const storeWithRows = computed(() => shelfByStore.value.stores.filter((g) => g.rows.length > 0).length)
const grouped = computed(() => byCategory.value.map(([c, r]) => [c, r.filter((row) => filterMatches(row.item.name))] as const).filter(([, r]) => r.length > 0))
const shelf = computed(() =>
  shelfByStore.value.stores
    .map((g) => ({ ...g, rows: g.rows.filter((row) => filterMatches(row.item.name)) }))
    .filter((g) => g.rows.length > 0),
)
const counts = computed(() => listsWithCounts.value.reduce((sum, l) => sum + l.needed, 0))
void untaggedCount
void storeWithRows
void counts
</script>

<template>
  <section aria-label="Kinetic View, Active Store with the Store-shelf beyond it" data-variant="hybrid">
    <template v-if="activeStore">
      <header class="py-3" data-grouping-headline>
        <p class="font-medium">{{ activeStore.name }} · Needed</p>
        <p class="text-sm text-muted-foreground">
          {{ gate.needed }} Needed at {{ activeStore.name }} · {{ gate.basket }} In Basket<template v-if="gate.untaggedAtStore"> · {{ gate.untaggedAtStore }} with no Tag here</template>
        </p>
      </header>

      <UiInputGroup v-if="gate.needed >= 6" class="w-full pb-2" data-filter>
        <UiInput id="filter-items" v-model="state.filter" type="search" placeholder="Filter Items" class="w-full" />
      </UiInputGroup>

      <section v-for="[category, rows] in grouped" :key="category" class="pb-1">
        <h2 class="text-sm text-muted-foreground pt-3 pb-1" :aria-label="`Category ${category}`">{{ category }}</h2>
        <ul>
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
    </template>

    <template v-else>
      <header class="py-3" data-grouping-headline>
        <p class="font-medium">No Store picked</p>
        <p class="text-sm text-muted-foreground">
          {{ gate.needed }} Needed across {{ shelf.length }} Stores · {{ gate.basket }} In Basket
          <template v-if="untaggedCount"> · {{ untaggedCount }} with no Tag</template>
        </p>
        <UiButton variant="outline" class="mt-2" data-open="mint" @click="open('mint', { door: 'header' })">Add Store from where I am</UiButton>
      </header>

      <UiInputGroup v-if="gate.needed >= 6" class="w-full pb-2" data-filter>
        <UiInput id="filter-items" v-model="state.filter" type="search" placeholder="Filter Items" class="w-full" />
      </UiInputGroup>

      <section v-for="group in shelf" :key="group.store.id" class="pb-1">
        <h2 class="text-sm text-muted-foreground pt-3 pb-1 flex items-center gap-2" :aria-label="`Store ${group.store.name}`">
          <MapPinnedIcon v-if="group.store.locations.length" class="size-4" aria-hidden="true" />
          {{ group.store.name }}
          <span class="text-xs">{{ group.rows.length }}</span>
        </h2>
        <ul :aria-label="`${group.store.name} rows`">
          <template v-for="row in group.rows" :key="`${group.store.id}-${row.key}`">
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

      <section v-if="shelfByStore.untagged.length" class="pb-1">
        <h2 class="text-sm text-muted-foreground pt-3 pb-1" aria-label="Category Needs a Tag">Needs a Tag</h2>
        <ul>
          <template v-for="row in shelfByStore.untagged.filter((r) => filterMatches(r.item.name))" :key="`untagged-${row.key}`">
            <li>
              <PkDataRow
                :name="row.item.name"
                :quiet="`${row.item.quantity} · ${row.lists.map((l) => l.name).join(', ')} · no Store Tag — Tag it in the Item sheet`"
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
    </template>
  </section>
</template>
