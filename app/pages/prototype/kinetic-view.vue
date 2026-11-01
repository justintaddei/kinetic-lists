<script setup lang="ts">
/**
 * PROTOTYPE ONLY — wayfinder #11: *Kinetic View + arrival: what should it look
 * like?* Four throwaway readings of the Kinetic View, driven by URL so a shot, a
 * link, and a judgement all point at one state:
 *
 * ```
 * /prototype/kinetic-view?variant=flat&tab=kinetic
 * /prototype/kinetic-view?variant=category
 * /prototype/kinetic-view?variant=hybrid
 * /prototype/kinetic-view?variant=shelf
 * ```
 *
 * Variant keys: `flat` (the settled ADR-0024 column), `category` (Category
 * headings), `hybrid` (Category headers on a Picked Store, the Store-shelf with
 * none), `shelf` (a Store-shelf keyed on Standing Locations). The floating bar
 * drives Arrival, the Arrival report form, co-Member acts, the 25-Store wall, and
 * the first run; every state fact sits in that bar.
 *
 * Public on purpose: `@nuxtjs/supabase` guards `/app` only, and this page never
 * touches the database.
 */
import { toast } from 'vue-sonner'
import PkBasket from '~/components/prototype/PkBasket.vue'
import PkCaptureSheet from '~/components/prototype/PkCaptureSheet.vue'
import PkCascadeDialog from '~/components/prototype/PkCascadeDialog.vue'
import PkHousehold from '~/components/prototype/PkHousehold.vue'
import PkItemSheet from '~/components/prototype/PkItemSheet.vue'
import PkKineticCategory from '~/components/prototype/PkKineticCategory.vue'
import PkKineticFlat from '~/components/prototype/PkKineticFlat.vue'
import PkKineticHybrid from '~/components/prototype/PkKineticHybrid.vue'
import PkKineticShelf from '~/components/prototype/PkKineticShelf.vue'
import PkLists from '~/components/prototype/PkLists.vue'
import PkMintSheet from '~/components/prototype/PkMintSheet.vue'
import PkShell from '~/components/prototype/PkShell.vue'
import PkStorePicker from '~/components/prototype/PkStorePicker.vue'
import PkStoreScreen from '~/components/prototype/PkStoreScreen.vue'
import PkSwitcher from '~/components/prototype/PkSwitcher.vue'

const VARIANTS = [
  { key: 'flat', name: 'A · Flat column, the settled chrome' },
  { key: 'category', name: 'B · Category headings' },
  { key: 'hybrid', name: 'C · Hybrid — Category headers, Store-shelf with no Store' },
  { key: 'shelf', name: 'D · Store-shelf keyed on Standing Locations' },
]

const { state, setScenario, setArrivalForm, arrive, open, itemByName } = usePrototypeKinetic()

const route = useRoute()
const router = useRouter()

const variant = computed(() => (['flat', 'category', 'hybrid', 'shelf'] as const).includes(route.query.variant as never) ? (route.query.variant as string) : 'flat')
const tab = computed(() => (['kinetic', 'lists', 'basket', 'household'] as const).includes(route.query.tab as never) ? (route.query.tab as 'kinetic' | 'lists' | 'basket' | 'household') : 'kinetic')

const bar = ref(route.query.panel === '1')
watch(bar, (value) => router.replace({ query: { ...route.query, panel: value ? '1' : undefined } }))

const VARIANT_COMPONENT = {
  flat: PkKineticFlat,
  category: PkKineticCategory,
  hybrid: PkKineticHybrid,
  shelf: PkKineticShelf,
} as const

function setVariant(key: string) {
  router.replace({ query: { ...route.query, variant: key, tab: 'kinetic' } })
}

function cycle(delta: number) {
  const keys = VARIANTS.map((v) => v.key)
  const next = keys[(keys.indexOf(variant.value) + delta + keys.length) % keys.length]
  setVariant(next)
}

function setTab(next: 'kinetic' | 'lists' | 'basket' | 'household') {
  router.replace({ query: { ...route.query, tab: next } })
}

function chooseScenario(scenario: 'full' | 'wall' | 'fresh') {
  setScenario(scenario)
}

// A shared URL carries the scenario and the report form, not the row state.
watch(
  () => [route.query.scenario, route.query.arrival],
  ([scenario, arrival]) => {
    if (scenario === 'full' || scenario === 'wall' || scenario === 'fresh') setScenario(scenario)
    if (arrival === 'silent' || arrival === 'line' || arrival === 'toast') setArrivalForm(arrival)
  },
  { immediate: true },
)

watch(
  () => [state.scenario, state.arrivalForm],
  ([scenario, arrival]) => {
    router.replace({ query: { ...route.query, scenario, arrival } })
  },
)

// A sheet opens from the URL too, so a screenshot and a shared link are the same state.
const SHEETS = ['store-picker', 'store-screen', 'capture', 'item', 'cascade', 'mint'] as const
watch(
  () => [route.query.sheet, route.query.item, route.query.store],
  ([sheet, item, store]) => {
    if (!SHEETS.includes(sheet as never)) return
    open(sheet as 'store-picker', {
      itemId: item ? itemByName(String(item))?.id : undefined,
      storeId: store ? String(store) : undefined,
      door: 'header',
    })
  },
  { immediate: true },
)
</script>

<template>
  <PkShell :tab="tab" @tab="setTab">
    <component :is="VARIANT_COMPONENT[variant as keyof typeof VARIANT_COMPONENT]" v-if="tab === 'kinetic'" />
    <PkLists v-else-if="tab === 'lists'" />
    <PkBasket v-else-if="tab === 'basket'" />
    <PkHousehold v-else />

    <PkSwitcher
      :variants="VARIANTS"
      :current="variant"
    :panel="bar"
    @cycle="cycle"
    @variant="setVariant"
    @arrive="arrive"
    @note="(text: string) => toast(text, { position: 'top-center' })"
    @scenario="chooseScenario"
    @form="setArrivalForm"
    @update:panel="bar = $event"
    <PkStorePicker />
    <PkMintSheet />
    <PkCaptureSheet />
    <PkItemSheet />
    <PkStoreScreen />
    <PkCascadeDialog />
  </PkShell>
</template>
