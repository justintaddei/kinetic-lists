<script setup lang="ts">
/**
 * PROTOTYPE ONLY — wayfinder #11. The Capture FAB opens the short path: name,
 * List, Tags written at capture. The standing Store's pill arrives pre-ticked —
 * Ticket 19's Tag authoring, the mechanism Ticket 15 puts at capture.
 */
import { CheckIcon } from '@lucide/vue'

const { state, activeStore, listsWithCounts, storeRoster, capture, close, toggleTag, itemByName } = usePrototypeKinetic()

const name = ref('')
const listId = ref('standing')
const tags = ref<string[]>([])

watch(
  () => state.sheet,
  () => {
    if (state.sheet !== 'capture') return
    name.value = ''
    tags.value = activeStore.value ? [activeStore.value.id] : []
  },
  { immediate: true },
)

const existing = computed(() => itemByName(name.value.trim()))
</script>

<template>
  <UiDrawer :open="state.sheet === 'capture'" @update:open="(v: boolean) => !v && close()">
    <UiDrawerContent :dir="'down'" class="mx-auto w-full max-w-md">
      <UiDrawerHeader class="text-start">
        <UiDrawerTitle>Capture</UiDrawerTitle>
        <UiDrawerDescription>Name the thing, pick the List, write the Tags that tell you where it stands.</UiDrawerDescription>
      </UiDrawerHeader>

      <div class="space-y-3 px-4">
        <div>
          <UiLabel for="capture-name">Item</UiLabel>
          <UiInput id="capture-name" v-model="name" class="mt-1 w-full" placeholder="Milk" data-capture-name />
          <p v-if="existing" class="text-sm text-muted-foreground pt-1">
            {{ existing.name }} already stands in this Household on {{ existing.storeTags.length }} Store Tag{{ existing.storeTags.length === 1 ? '' : 's' }} — Capture adds a row, not a second name.
          </p>
        </div>
        <div>
          <UiLabel for="capture-list">List</UiLabel>
          <!-- A native select: ADR-0020 ships native affordances (datalist, input type=time), not reka chrome. -->
          <select
            id="capture-list"
            v-model="listId"
            class="border-input bg-background mt-1 h-11 w-full rounded-md border px-3 text-base"
            data-capture-list
          >
            <option v-for="entry in listsWithCounts" :key="entry.list.id" :value="entry.list.id">{{ entry.list.name }}</option>
          </select>
        </div>
        <div>
          <UiLabel>Store Tags</UiLabel>
          <div class="flex flex-wrap gap-1 pt-1" data-tag-pills>
            <button
              v-for="entry in storeRoster"
              :key="entry.store.id"
              type="button"
              class="border-border text-muted-foreground hover:text-foreground h-11 rounded-full border px-3 text-sm"
              :class="tags.includes(entry.store.id) && 'text-foreground border-foreground font-medium'"
              :aria-pressed="tags.includes(entry.store.id)"
              :aria-label="`Tag ${entry.store.name}`"
              @click="tags = tags.includes(entry.store.id) ? tags.filter((t) => t !== entry.store.id) : [...tags, entry.store.id]"
            >
              <CheckIcon v-if="tags.includes(entry.store.id)" class="size-4 me-1 inline" aria-hidden="true" />
              {{ entry.store.name }}
            </button>
          </div>
          <p v-if="!tags.length" class="text-sm text-muted-foreground pt-1">
            No Tag: the Basket and the Gate will name it, and no Store's Kinetic View will ever show it.
          </p>
        </div>
      </div>

      <footer class="px-4 pt-4 pb-4">
        <UiButton class="w-full" data-capture-save @click="capture(name, listId, tags); tags = []">Capture</UiButton>
        <UiButton variant="outline" class="mt-2 w-full" data-close-capture @click="close()">Close</UiButton>
      </footer>
    </UiDrawerContent>
  </UiDrawer>
</template>
