<script setup lang="ts">
/**
 * PROTOTYPE ONLY — wayfinder #11. The Store screen, reached from the Kinetic View
 * header's ghost door: its Locations with their Geofences, the Items its Tags
 * carry, the Presence line naming who Arrived here, and the Delete verb whose
 * Cascade confirmation names only what the Household can see.
 */
import { CheckIcon, PlusIcon } from '@lucide/vue'

const { state, storeById, itemsAtStore, open, close, deleteStore, arrive } = usePrototypeKinetic()

const store = computed(() => storeById(state.cascadeStoreId ?? state.activeStoreId) ?? state.stores[0] ?? null)
const items = computed(() => (store.value ? itemsAtStore(store.value.id) : []))
const confirm = ref(false)

const unTaggedDoom = computed(() =>
  store.value ? state.items.filter((i) => i.storeTags.includes(store.value!.id) && i.storeTags.filter((t) => t !== store.value!.id).length === 0) : [],
)
const arrivedHere = computed(() => {
  if (!store.value) return []
  const ids = new Set(store.value.locations.map((l) => l.id))
  return [...new Set(state.arrivals.filter((a) => ids.has(a.locationId)).map((a) => a.member))]
})

watch(() => state.sheet, () => {
  confirm.value = false
})

function destroy() {
  if (!store.value) return
  deleteStore(store.value.id)
  confirm.value = false
}
function addLocation() {
  if (!store.value) return
  state.mintFixStoreId = store.value.id
  open('mint', { door: 'bare' })
}
</script>

<template>
  <UiDrawer :open="state.sheet === 'store-screen'" @update:open="(v: boolean) => !v && close()">
    <UiDrawerContent v-if="store" :dir="'down'" class="mx-auto w-full max-w-md">
      <UiDrawerHeader class="text-start">
        <UiDrawerTitle>{{ store.name }}</UiDrawerTitle>
        <UiDrawerDescription>
          {{ store.locations.length ? `${store.locations.length} Location${store.locations.length > 1 ? 's' : ''}` : 'A bare Store — Tags and no Location, so no Arrival will ever suggest it' }}
          · {{ items.length }} Item{{ items.length === 1 ? '' : 's' }}
        </UiDrawerDescription>
      </UiDrawerHeader>

      <div class="px-4">
        <ul data-location-rows>
          <template v-for="location in store.locations" :key="location.id">
            <li>
              <div class="flex min-h-12 items-center gap-3">
                <span class="min-w-0 flex-1">
                  <span class="block text-base font-medium">{{ location.label }}</span>
                  <span class="text-sm text-muted-foreground block">{{ location.lat }}, {{ location.lng }} · {{ location.geofence }} m Geofence</span>
                </span>
                <UiButton
                  variant="ghost"
                  size="icon"
                  class="size-11"
                  :aria-pressed="state.standingLocationId === location.id"
                  :aria-label="`Stand at ${location.label}`"
                  data-stand
                  @click="arrive(location.id)"
                >
                  <CheckIcon class="size-5" aria-hidden="true" />
                </UiButton>
              </div>
            </li>
            <UiSeparator />
          </template>
        </ul>

        <UiButton variant="outline" class="mt-3 w-full" data-open="mint-fix" @click="addLocation">
          <PlusIcon class="size-5" aria-hidden="true" />
          Add a Location
        </UiButton>

        <p v-if="store.locations.length === 0" class="text-sm text-muted-foreground pt-2" data-bare-copy>
          A Bare Store answers "where is the milk", never "where am I". Its Buy records no Location.
        </p>

        <p v-if="arrivedHere.length" class="text-sm text-muted-foreground pt-2" data-arrival-presence>
          {{ arrivedHere.join(', ') }} arrived here
        </p>

        <ul class="pt-3" data-store-item-rows>
          <template v-for="item in items" :key="item.id">
            <li>
              <button type="button" class="flex min-h-12 w-full items-center gap-3 text-start" :aria-label="`Open ${item.name}`" @click="open('item', { itemId: item.id })">
                <span class="min-w-0 flex-1">
                  <span class="block text-base font-medium">{{ item.name }}</span>
                  <span class="text-sm text-muted-foreground block">{{ item.quantity }} · {{ item.category }}</span>
                </span>
              </button>
            </li>
            <UiSeparator />
          </template>
        </ul>

        <footer class="pt-5 pb-4">
          <template v-if="!confirm">
            <UiButton variant="outline" class="border-border text-destructive w-full" data-open="cascade" @click="confirm = true">
              Delete Store
            </UiButton>
          </template>
          <template v-else>
            <p class="text-sm font-medium" data-cascade-copy>
              Deleting {{ store.name }} deletes its {{ store.locations.length }} Location{{ store.locations.length === 1 ? '' : 's' }}, strips {{ items.length }}
              Store Tag{{ items.length === 1 ? '' : 's' }}, and erases {{ unTaggedDoom.length }} Item{{ unTaggedDoom.length === 1 ? '' : 's' }} left with no Tag — with
              their standing rows, for every Member. Lists and Purchases survive.
            </p>
            <UiButton variant="outline" class="border-border text-destructive mt-3 w-full" data-cascade-confirm @click="destroy()">
              Delete {{ store.name }}
            </UiButton>
            <UiButton variant="outline" class="mt-2 w-full" data-cascade-cancel @click="confirm = false">Keep {{ store.name }}</UiButton>
          </template>
        </footer>
      </div>
    </UiDrawerContent>
  </UiDrawer>
</template>
