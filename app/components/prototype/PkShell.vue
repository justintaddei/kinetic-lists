<script setup lang="ts">
/**
 * PROTOTYPE ONLY — wayfinder #11. The settled chrome of ADR-0024, so the variants
 * are judged inside the shell they would live in: the header on the Kinetic View
 * only (a ghost Store-name control that ticks when a Standing Location is named,
 * plus the 44px ghost door to the Store screen), the 4-link tab bar as the only
 * spine, the Capture FAB, the two toast mounts (a write's own report at
 * top-center, the Buy report at bottom-center), and the `max-w-md` phone frame.
 *
 * Named layout comes later: #21 resolved a `app/layouts/app.vue`, which master
 * does not ship, so the shell is a component in the throwaway.
 */
import { CheckIcon, HouseIcon, ListTodoIcon, MapPinnedIcon, PlusIcon, ShoppingBasketIcon } from '@lucide/vue'

const props = defineProps<{ tab: 'kinetic' | 'lists' | 'basket' | 'household' }>()

const { activeStore, standingLocation, basketCount, open } = usePrototypeKinetic()

const TABS = [
  { key: 'kinetic', label: 'Kinetic View', icon: MapPinnedIcon },
  { key: 'lists', label: 'Lists', icon: ListTodoIcon },
  { key: 'basket', label: 'Basket', icon: ShoppingBasketIcon },
  { key: 'household', label: 'Household', icon: HouseIcon },
] as const
</script>

<template>
  <div class="bg-background mx-auto min-h-svh w-full max-w-md pb-40">
    <header v-if="props.tab === 'kinetic'" class="flex items-center gap-1 pt-safe-offset-2 px-4">
      <UiButton
        variant="ghost"
        class="min-w-0 font-medium"
        :aria-pressed="!!standingLocation"
        :aria-label="standingLocation ? `Standing at ${activeStore?.name} ${standingLocation?.label}` : 'Pick a Store'"
        data-open="store-picker"
        @click="open('store-picker')"
      >
        <span class="truncate">{{ activeStore?.name ?? 'No Store picked' }}</span>
        <CheckIcon v-if="standingLocation" class="size-4 shrink-0" aria-hidden="true" />
      </UiButton>
      <UiButton
        variant="ghost"
        size="icon"
        class="ml-auto size-11 shrink-0"
        title="Store screen"
        data-open="store-screen"
        @click="open('store-screen')"
      >
        <MapPinnedIcon class="size-5" aria-hidden="true" />
        <span class="sr-only">Store</span>
      </UiButton>
    </header>

    <main class="px-4">
      <slot />
    </main>

    <button
      type="button"
      class="bg-primary text-primary-foreground shadow-lg fixed bottom-24 right-[max(1rem,calc((100vw-28rem)/2+1rem))] z-50 size-11 rounded-full"
      title="Capture"
      data-open="capture"
      @click="open('capture')"
    >
      <PlusIcon class="size-5" />
      <span class="sr-only">Capture</span>
    </button>

    <nav aria-label="Primary" class="bg-background fixed inset-x-0 bottom-0 z-40 mx-auto w-full max-w-md">
      <UiSeparator class="mb-1" />
      <ul class="pt-safe-offset-4 flex items-stretch justify-around px-2 pb-3">
        <li v-for="tab in TABS" :key="tab.key">
          <RouterLink
            :to="{ query: { ...$route.query, tab: tab.key } }"
            class="flex w-16 flex-col items-center gap-0.5 py-1"
            :aria-current="props.tab === tab.key ? 'page' : undefined"
            :data-tab="tab.key"
          >
            <component :is="tab.icon" class="size-5" aria-hidden="true" />
            <span class="text-xs">{{ tab.key === 'basket' && basketCount ? `Basket · ${basketCount}` : tab.label }}</span>
          </RouterLink>
        </li>
      </ul>
    </nav>

    <!-- A write's own report lives at the eye; the Buy report lives by the verb. -->
    <UiToaster position="top-center" :gap="8" :mobile-offset="24" :toaster-id="1" />
    <UiToaster position="bottom-center" :gap="8" :mobile-offset="120" :toaster-id="2" :visible-toasts="2" />
  </div>
</template>
