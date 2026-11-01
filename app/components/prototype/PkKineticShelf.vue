<script setup lang="ts">
/**
 * PROTOTYPE ONLY — wayfinder #11, variant D: *Store-shelf keyed on the Standing
 * Location* — Ticket 12's "Where I stand, and where they stand".
 *
 * Each group names the Location the Household stands at, not the Store: the
 * heading is the Arrival, and each Store with a Location carries a quiet
 * `Stand here` control that performs the Arrival in place. The unTagged group is
 * named the Gate's subject.
 */
import PkDataRow from './PkDataRow.vue'

const { state, shelfByStore, gate, standingLocation, filterMatches, check, open, arrive, activeStore } = usePrototypeKinetic()

const shelf = computed(() =>
  shelfByStore.value.stores
    .map((g) => ({ ...g, rows: g.rows.filter((r) => filterMatches(r.item.name)) }))
    .filter((g) => g.rows.length > 0),
)

/** The Location a group stands at: this Member's Standing Location, else the Store's own first. */
function standingFor(storeId: string) {
  const store = shelfByStore.value.stores.find((g) => g.store.id === storeId)?.store
  if (!store) return null
  if (activeStore.value?.id === storeId && standingLocation.value) return standingLocation.value
  return store.locations[0] ?? null
}
</script>

<template>
  <section aria-label="Kinetic View as a shelf keyed on Standing Locations" data-variant="shelf">
    <header class="py-3" data-grouping-headline>
      <p class="font-medium">
        {{ activeStore ? `Standing at ${activeStore.name}${standingLocation ? ` ${standingLocation.label}` : ''}` : 'Nobody is standing anywhere' }}
      </p>
      <p class="text-sm text-muted-foreground">
        {{ shelf.length }} Stores carry Needed rows · {{ gate.basket }} In Basket
        <template v-if="shelfByStore.untagged.length"> · {{ shelfByStore.untagged.length }} with no Tag — the Gate keeps them out of every Store</template>
      </p>
    </header>

    <UiInputGroup v-if="gate.needed >= 6" class="w-full pb-2" data-filter>
      <UiInput id="filter-items" v-model="state.filter" type="search" placeholder="Filter Items" class="w-full" />
    </UiInputGroup>

    <section v-for="group in shelf" :key="group.store.id" class="pb-1">
      <h2 class="text-sm text-muted-foreground pt-3 pb-1 flex items-center gap-2" :aria-label="`Standing at ${group.store.name}`">
        <span class="truncate">
          {{ standingFor(group.store.id) ? `${group.store.name} ${standingFor(group.store.id)?.label}` : `${group.store.name} · no Position` }}
        </span>
        <button
          v-if="standingFor(group.store.id)"
          type="button"
          class="text-xs underline-offset-2 hover:underline"
          :aria-pressed="activeStore?.id === group.store.id && !!standingLocation"
          :aria-label="`Stand at ${group.store.name} ${standingFor(group.store.id)?.label}`"
          @click="arrive(standingFor(group.store.id)!.id)"
        >
          Stand here
        </button>
      </h2>
      <ul :aria-label="`${group.store.name} rows`">
        <template v-for="row in group.rows" :key="row.key">
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
      <h2 class="text-sm text-muted-foreground pt-3 pb-1" aria-label="Gate subject">
        Need a Tag — the Gate names them
      </h2>
      <ul>
        <template v-for="row in shelfByStore.untagged.filter((r) => filterMatches(r.item.name))" :key="`un-${row.key}`">
          <li>
            <PkDataRow
              :name="row.item.name"
              :quiet="`${row.item.quantity} · ${row.lists.map((l) => l.name).join(', ')} · invisible in every Store's view`"
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
  </section>
</template>
