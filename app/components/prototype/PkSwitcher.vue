<script setup lang="ts">
/**
 * PROTOTYPE ONLY — wayfinder #11. The bar a reader drives the throwaway with:
 * the Kinetic View variant, the scenario drive (Arrival, the Arrival report form,
 * co-Member acts, the 25-Store wall, the fresh run), and the whole simulated
 * Household — Active Store, Standing Location, the Gate's numbers, the event log
 * — so the state behind a judgement is always on screen. Dev-only.
 */
const props = defineProps<{
  variants: { key: string; name: string }[]
  current: string
  panel: boolean
}>()

const emit = defineEmits<{
  (e: 'cycle', delta: number): void
  (e: 'variant', key: string): void
  (e: 'arrive', locationId: string): void
  (e: 'note', text: string): void
  (e: 'scenario', scenario: 'full' | 'wall' | 'fresh'): void
  (e: 'form', form: 'silent' | 'line' | 'toast'): void
  (e: 'update:panel', value: boolean): void
}>()

const isDev = import.meta.dev

const isDevMode = isDev
void isDevMode
const { state, activeStore, standingLocation, kineticRows, gate, allLocations, coMemberCheck, coMemberBuy, coMemberCascade, reset, open } = usePrototypeKinetic()

const facts = computed(() => [
  `Active Store: ${activeStore.value?.name ?? 'none'}`,
  `Standing Location: ${standingLocation.value ? `${activeStore.value?.name} ${standingLocation.value.label}` : 'none'}`,
  `Gate: ${gate.value.needed} Needed · ${gate.value.basket} In Basket · ${gate.value.untaggedAtStore} unTagged at Store`,
  `Household: ${state.stores.length} Stores · ${state.items.length} Items · ${state.listItems.length} List Items · ${state.purchases.length} Purchases · ${kineticRows.value.length} Kinetic rows`,
])

const arrivalPlaces = computed(() => allLocations.value.slice(0, 4).map((l) => ({ id: l.id, name: `${l.storeName} ${l.label}` })))

const variantName = computed(() => props.variants.find((v) => v.key === props.current)?.name ?? props.current)

const FORMS = ['silent', 'line', 'toast'] as const

onMounted(() => {
  const onKey = (e: KeyboardEvent) => {
    const target = e.target as HTMLElement | null
    if (target && ['INPUT', 'TEXTAREA', 'SELECT'].includes(target.tagName)) return
    if (e.key === 'ArrowLeft') emit('cycle', -1)
    if (e.key === 'ArrowRight') emit('cycle', 1)
  }
  window.addEventListener('keydown', onKey)
  onUnmounted(() => window.removeEventListener('keydown', onKey))
})
</script>

<template>
  <nav v-if="isDev" class="fixed inset-x-0 bottom-[104px] z-[60] mx-auto w-full max-w-md px-3" aria-label="Prototype controls">
    <div class="bg-primary text-primary-foreground shadow-lg mx-auto w-fit max-w-full rounded-2xl px-2 py-1.5 flex items-center gap-1">
      <button class="hover:bg-primary/85 h-9 rounded-xl px-2 text-sm" aria-label="Previous variant" @click="emit('cycle', -1)">←</button>
      <select
        class="bg-primary/20 h-9 rounded-xl px-1 text-xs font-medium outline-none"
        :value="current"
        aria-label="Kinetic View variant"
        @change="emit('variant', ($event.target as HTMLSelectElement).value)"
      >
        <option v-for="variant in props.variants" :key="variant.key" :value="variant.key">{{ variant.key }}</option>
      </select>
      <button class="hover:bg-primary/85 h-9 rounded-xl px-2 text-sm" aria-label="Next variant" @click="emit('cycle', 1)">→</button>
      <span class="bg-primary/25 h-4 w-px" />
      <button class="hover:bg-primary/85 h-9 rounded-xl px-2 text-xs" :aria-expanded="panel" data-scenario-bar @click="emit('update:panel', !panel)">
        {{ panel ? 'Hide' : 'Scenarios' }}
      </button>
    </div>

    <div v-if="panel" class="bg-popover text-popover-foreground border-border mt-2 mx-auto w-full max-w-full rounded-2xl border p-3 text-xs" data-scenario-panel>
      <p class="font-medium">{{ variantName }}</p>

      <p class="text-muted-foreground mt-2">Arrival — an Arrival selects the Active Store, names the Standing Location, moves no List Item</p>
      <div class="mt-1 flex flex-wrap gap-1">
        <UiButton v-for="place in arrivalPlaces" :key="place.id" size="xs" variant="outline" data-arrival @click="emit('arrive', place.id)">
          {{ place.name }}
        </UiButton>
        <UiButton size="xs" variant="outline" @click="open('store-picker')">Pick a Store (no Location)</UiButton>
        <UiButton size="xs" variant="outline" data-open="mint" @click="open('mint', { door: 'header' })">No Location matches — Add Store here</UiButton>
      </div>

      <p class="text-muted-foreground mt-3">How an Arrival reports — the ticket's own question</p>
      <div class="mt-1 flex flex-wrap gap-1">
        <UiButton v-for="form in FORMS" :key="form" size="xs" :variant="state.arrivalForm === form ? 'default' : 'outline'" @click="emit('form', form)">
          {{ form }}
        </UiButton>
      </div>

      <p class="text-muted-foreground mt-3">co-Member on the household channel · scale · the first run</p>
      <div class="mt-1 flex flex-wrap gap-1">
        <UiButton size="xs" variant="outline" data-co-check @click="coMemberCheck()">co-Member Check</UiButton>
        <UiButton size="xs" variant="outline" data-co-buy @click="coMemberBuy()">co-Member Buy</UiButton>
        <UiButton size="xs" variant="outline" data-co-cascade @click="coMemberCascade()">co-Member deletes Walmart</UiButton>
        <UiButton size="xs" variant="outline" :disabled="state.scenario === 'wall'" @click="emit('scenario', 'wall')">25-Store wall</UiButton>
        <UiButton size="xs" variant="outline" :disabled="state.scenario === 'fresh'" @click="emit('scenario', 'fresh')">Fresh run</UiButton>
        <UiButton size="xs" variant="outline" :disabled="state.scenario === 'full'" @click="emit('scenario', 'full')">Full Household</UiButton>
        <UiButton size="xs" variant="outline" @click="reset()">Reset rows</UiButton>
      </div>

      <p class="text-muted-foreground mt-3">The simulated state</p>
      <ul class="mt-1 space-y-0.5">
        <li v-for="line in facts" :key="line">{{ line }}</li>
      </ul>

      <p class="text-muted-foreground mt-3">Event log — your acts, the co-Member's, the refusals</p>
      <ul class="mt-1 max-h-36 space-y-0.5 overflow-y-auto" data-event-log>
        <li v-for="(entry, i) in state.log" :key="`${entry.at}-${i}`" :class="entry.who === 'Alex' ? 'text-primary' : 'text-foreground/80'">
          {{ new Date(entry.at).toLocaleTimeString([], { hour: 'numeric', minute: '2-digit', second: 'numeric' }) }} · {{ entry.text }}
        </li>
      </ul>
    </div>
  </nav>
</template>
