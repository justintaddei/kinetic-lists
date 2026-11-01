<script setup lang="ts">
/**
 * PROTOTYPE ONLY — wayfinder #11, variant A: *the settled column, untouched*.
 *
 * A flat, Store-scoped, A–Z list of Needed rows with no grouping at all; the Gate
 * copy as the column's last quiet line; an Arrival that reports as one in-column
 * line naming the Standing Location and the Store. This is what ADR-0024
 * committed to, so it is the control in the comparison.
 */
import { MapPinnedIcon } from '@lucide/vue'
import PkDataRow from './PkDataRow.vue'

const { state, activeStore, standingLocation, kineticRows, gate, filterMatches, check, open, arrivalLine } = usePrototypeKinetic()
</script>

<template>
  <section aria-label="Kinetic View, flat column" data-variant="flat">
    <p v-if="state.arrivalForm === 'line' && standingLocation" class="text-sm text-muted-foreground py-3" data-arrival-line>
      {{ arrivalLine() }} — Needed at {{ activeStore?.name }}
    </p>

    <template v-if="activeStore">
      <UiInputGroup v-if="kineticRows.length >= 6" class="w-full pb-2" data-filter>
        <UiInput id="filter-items" v-model="state.filter" type="search" placeholder="Filter Items" class="w-full" />
      </UiInputGroup>
      <ul data-kinetic-rows>
        <template v-for="row in kineticRows.filter((r) => filterMatches(r.item.name))" :key="row.key">
          <li>
            <PkDataRow
              :name="row.item.name"
              :quiet="`${row.item.quantity} · ${row.item.category} · ${row.lists.map((l) => l.name).join(', ')}`"
              :flash="state.live.includes(row.key)"
              :open-aria="`Open ${row.item.name}`"
              @check="check(row.key)"
              @open="open('item', { itemId: row.key })"
            />
          </li>
          <UiSeparator />
        </template>
      </ul>

      <p class="text-sm text-muted-foreground py-4" data-gate-copy>
        {{ gate.needed }} Needed · {{ gate.basket }} In Basket<template v-if="gate.untaggedAtStore"> · {{ gate.untaggedAtStore }} with no Tag at {{ activeStore.name }} — Tag them in the Item sheet</template>
      </p>
    </template>

    <UiEmpty v-else class="py-16" data-kinetic-empty>
      <UiEmptyHeader>
        <UiEmptyMedia variant="icon"><MapPinnedIcon aria-hidden="true" /></UiEmptyMedia>
        <UiEmptyTitle>Pick a Store</UiEmptyTitle>
        <UiEmptyDescription>
          The Kinetic View is what your Household Needs at one Store. Add a shop from where you are, and its Items land here.
        </UiEmptyDescription>
        <UiEmptyContent>
          <UiButton data-open="mint" @click="open('mint', { door: 'header' })">Add Store</UiButton>
        </UiEmptyContent>
      </UiEmptyHeader>
    </UiEmpty>
  </section>
</template>
