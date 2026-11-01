<script setup lang="ts">
/**
 * PROTOTYPE ONLY — wayfinder #11. Household: the rosters the settled design puts
 * under this tab (Members, Stores, Items), the 25-Store wall a Household can grow
 * into, and the Cascade confirmation naming only what the Household can see.
 */
const { state, storeRoster, filterMatches, open, deleteStore } = usePrototypeKinetic()

const rosterOpen = ref(true)
const wall = computed(() => state.stores.length >= 20)
</script>

<template>
  <section aria-label="Household" data-screen="household">
    <header class="py-3">
      <p class="font-medium">{{ state.household }}</p>
      <p class="text-sm text-muted-foreground">
        {{ state.members.length }} Members · {{ state.stores.length }} Stores · {{ state.items.length }} Items
        <template v-if="wall"> · the wall</template>
      </p>
    </header>

    <section data-member-roster>
      <h2 class="text-sm text-muted-foreground py-2">Members</h2>
      <ul>
        <template v-for="member in state.members" :key="member">
          <li>
            <div class="flex min-h-12 items-center gap-3">
              <span class="min-w-0 flex-1">
                <span class="block text-base font-medium">{{ member }}<span v-if="member === state.you" class="text-sm text-muted-foreground"> · you</span></span>
                <span class="text-sm text-muted-foreground block">Joins by invitation · equal owner, never a role</span>
              </span>
            </div>
          </li>
          <UiSeparator />
        </template>
      </ul>
    </section>

    <section class="pt-2" data-store-roster>
      <h2 class="text-sm text-muted-foreground py-2 flex items-center gap-2">
        Stores
        <UiButton variant="ghost" class="-my-2 text-sm" :aria-expanded="true" @click="rosterOpen = !rosterOpen">{{ rosterOpen ? 'Collapse' : 'Open' }}</UiButton>
      </h2>
      <ul v-if="rosterOpen">
        <template v-for="entry in storeRoster.filter((e) => filterMatches(e.store.name))" :key="entry.store.id">
          <li>
            <button
              type="button"
              class="flex min-h-12 w-full items-center gap-3 text-start"
              :aria-pressed="state.activeStoreId === entry.store.id"
              :aria-label="`Open ${entry.store.name}`"
              @click="open('store-screen', { storeId: entry.store.id })"
            >
              <span class="min-w-0 flex-1">
                <span class="block text-base font-medium">{{ entry.store.name }}</span>
                <span class="text-sm text-muted-foreground block">
                  {{ entry.store.locations.length ? `${entry.store.locations.length} Location${entry.store.locations.length > 1 ? 's' : ''}` : 'No Locations — a bare Store' }}
                  · {{ entry.items.length }} Item{{ entry.items.length === 1 ? '' : 's' }}
                  · {{ entry.counts.needed }} Needed
                  <template v-if="state.activeStoreId === entry.store.id"> · Active</template>
                </span>
              </span>
            </button>
          </li>
          <UiSeparator />
        </template>
      </ul>
    </section>

    <section class="pt-2" data-item-roster>
      <h2 class="text-sm text-muted-foreground py-2">Items</h2>
      <ul>
        <template v-for="item in state.items.filter((i) => filterMatches(i.name))" :key="item.id">
          <li>
            <button type="button" class="flex min-h-12 w-full items-center gap-3 text-start" :aria-label="`Open ${item.name}`" @click="open('item', { itemId: item.id })">
              <span class="min-w-0 flex-1">
                <span class="block text-base font-medium">{{ item.name }}</span>
                <span class="text-sm text-muted-foreground block">
                  {{ item.quantity }} · {{ item.category }} · {{ item.storeTags.length ? item.storeTags.map((t) => storeRoster.find((e) => e.store.id === t)?.store.name).join(', ') : 'no Store Tag' }}
                </span>
              </span>
            </button>
          </li>
          <UiSeparator />
        </template>
      </ul>
    </section>

    <section class="pt-4" data-purchase-log>
      <h2 class="text-sm text-muted-foreground py-2">Purchases</h2>
      <p v-if="state.purchases.length === 0" class="text-sm text-muted-foreground">Nothing Bought yet — a Purchase is append-only, and never the Kinetic View.</p>
      <ul v-else>
        <template v-for="purchase in state.purchases" :key="purchase.id">
          <li>
            <div class="flex min-h-12 items-center gap-3">
              <span class="min-w-0 flex-1">
                <span class="block text-base font-medium">{{ storeRoster.find((e) => e.store.id === purchase.storeId)?.store.name ?? purchase.storeId }}</span>
                <span class="text-sm text-muted-foreground block">{{ purchase.at }} · {{ purchase.lines.length }} lines · {{ purchase.member }} · Location {{ purchase.locationId ? 'named' : 'none' }}</span>
              </span>
            </div>
          </li>
          <UiSeparator />
        </template>
      </ul>
    </section>

    <section class="pt-4" data-cascade-demo>
      <UiButton variant="outline" class="border-border text-destructive w-full" data-open="cascade" @click="open('cascade', { storeId: state.activeStoreId ?? 'walmart' })">
        Delete Store — the Cascade
      </UiButton>
    </section>
  </section>
</template>
