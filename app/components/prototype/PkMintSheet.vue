<script setup lang="ts">
/**
 * PROTOTYPE ONLY — wayfinder #11. Mint: the Store name, the Place label, and the
 * Position. Denied Position mints a bare Store, which is a deliberate trade — it
 * carries Tags and no Arrival will ever suggest it. The name joins on collision,
 * it never collides. The Buy gate, the header's Add Store, and a Bare Store's
 * cure all ride this one sheet.
 */
import { CheckIcon } from '@lucide/vue'

const { state, mint, close, storeById } = usePrototypeKinetic()

const name = ref('')
const place = ref('Home Main')
const usePosition = ref(true)
const lat = ref(42.1092)
const lng = ref(-72.509)
const fix = computed(() => (state.mintFixStoreId ? storeById(state.mintFixStoreId) : null))
const door = computed(() => state.mintDoor)
const title = computed(() => (fix.value ? `Add a Location to ${fix.value.name}` : door.value === 'buy' ? 'Name this shop' : 'Add Store'))
const copy = computed(() => {
  if (fix.value) return 'A bare Store is cured by a saved Location. This Position arrives at you.'
  if (door.value === 'buy') return 'Buy needs a Store to name. This Position becomes the shop\'s first Location, and the Basket is Bought there.'
  return 'Name the shop, name the place, keep the Position. Deny the Position and the Store is bare: Tags, no Location, no Arrival.'
})
function confirm() {
  mint(name.value, place.value, usePosition.value ? { lat: lat.value, lng: lng.value } : null, { fixStoreId: state.mintFixStoreId })
  name.value = ''
}
</script>

<template>
  <UiDrawer :open="state.sheet === 'mint'" @update:open="(v: boolean) => !v && close()">
    <UiDrawerContent :dir="'down'" class="mx-auto w-full max-w-md">
      <UiDrawerHeader class="text-start">
        <UiDrawerTitle>{{ title }}</UiDrawerTitle>
        <UiDrawerDescription>{{ copy }}</UiDrawerDescription>
      </UiDrawerHeader>

      <div class="space-y-3 px-4">
        <div>
          <UiLabel for="mint-store">Store</UiLabel>
          <UiInput id="mint-store" v-model="name" :disabled="!!fix" class="mt-1 w-full" placeholder="Walmart" />
        </div>
        <div>
          <UiLabel for="mint-place">Place</UiLabel>
          <UiInput id="mint-place" v-model="place" class="mt-1 w-full" placeholder="Home Main" />
        </div>
        <div>
          <UiLabel for="mint-lat">Position</UiLabel>
          <div class="mt-1 flex items-center gap-2">
            <UiInput id="mint-lat" v-model.number="lat" type="number" :disabled="!usePosition" class="w-28" />
            <UiInput id="mint-lng" v-model.number="lng" type="number" :disabled="!usePosition" class="w-28" />
            <UiButton
              variant="outline"
              class="h-11 flex-1"
              :aria-pressed="usePosition"
              data-position
              @click="usePosition = !usePosition"
            >
              <CheckIcon v-if="usePosition" class="size-5" aria-hidden="true" />
              Where I am now
            </UiButton>
          </div>
          <p class="text-sm text-muted-foreground pt-1">
            {{ usePosition ? `A Location at ${lat}, ${lng} · 150 m` : 'No Position — a bare Store. Pickable, and no Arrival will suggest it.' }}
          </p>
        </div>
      </div>

      <footer class="px-4 pt-4">
        <UiButton class="w-full" data-mint-confirm @click="confirm()">
          {{ fix ? 'Add Location' : 'Mint' }}
        </UiButton>
        <UiButton variant="outline" class="mt-2 w-full" data-close-mint @click="close()">Close</UiButton>
      </footer>
    </UiDrawerContent>
  </UiDrawer>
</template>
