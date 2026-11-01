<script setup lang="ts">
/**
 * PROTOTYPE ONLY — wayfinder #11. The Store picker: the Active Store pinned and
 * ticked, every other Store A–Z with its Location count, and the Mint verb pinned
 * outside the scroll — the 25-Store wall in one scroll.
 */
import { CheckIcon, PlusIcon } from '@lucide/vue'

const { state, storeRoster, pick, open, close, filterMatches } = usePrototypeKinetic()
</script>

<template>
  <UiDrawer :open="state.sheet === 'store-picker'" @update:open="(v: boolean) => !v && close()">
    <UiDrawerContent :dir="'down'" class="mx-auto w-full max-w-md">
      <UiDrawerHeader class="text-start">
        <UiDrawerTitle>Pick a Store</UiDrawerTitle>
        <UiDrawerDescription>It selects the Active Store. It moves no List Item, and it clears the Standing Location.</UiDrawerDescription>
        <UiDrawerClose as-child>
          <UiButton class="mt-2 w-full" data-close-picker>Close</UiButton>
        </UiDrawerClose>
      </UiDrawerHeader>

      <div class="max-h-[52vh] overflow-y-auto px-4">
        <UiButton variant="outline" class="w-full justify-start" data-open="mint" @click="open('mint', { door: 'header' })">
          <PlusIcon class="size-5" aria-hidden="true" />
          Add Store from where I am
        </UiButton>

        <div v-if="storeRoster.length >= 6" class="pt-3">
          <UiLabel for="filter-stores">Filter Stores</UiLabel>
          <UiInput id="filter-stores" v-model="state.filter" type="search" class="mt-1 w-full" placeholder="Walmart" />
        </div>

        <ul class="pt-2" data-store-picker-rows>
          <template v-for="entry in [...storeRoster].sort((a, b) => Number(b.store.id === state.activeStoreId) - Number(a.store.id === state.activeStoreId) || a.store.name.localeCompare(b.store.name)).filter((e) => filterMatches(e.store.name))" :key="entry.store.id">
            <li>
              <button
                type="button"
                class="flex min-h-12 w-full items-center gap-3 text-start"
                :aria-pressed="state.activeStoreId === entry.store.id"
                :aria-label="`Pick ${entry.store.name}`"
                @click="pick(entry.store.id)"
              >
                <CheckIcon v-if="state.activeStoreId === entry.store.id" class="size-5 shrink-0" aria-hidden="true" />
                <span v-else class="size-5 shrink-0" aria-hidden="true" />
                <span class="min-w-0 flex-1">
                  <span class="block text-base font-medium truncate">{{ entry.store.name }}</span>
                  <span class="text-sm text-muted-foreground block truncate">
                    {{ entry.store.locations.length ? `${entry.store.locations.length} Location${entry.store.locations.length > 1 ? 's' : ''}` : 'No Locations — a bare Store' }} · {{ entry.counts.needed }} Needed
                  </span>
                </span>
              </button>
            </li>
            <UiSeparator />
          </template>
        </ul>
      </div>
    </UiDrawerContent>
  </UiDrawer>
</template>
