<script setup lang="ts">
/**
 * PROTOTYPE ONLY — wayfinder #11. The Item sheet: live-edit, the Store Tag row
 * with `aria-pressed` pills, the Lists line, and the Delete verb last. Names are
 * household-unique by a plain index, so a name that is taken refuses and says so.
 */
import { CheckIcon } from '@lucide/vue'

const { state, itemById, storeRoster, listsWithCounts, renameItem, setCategory, setQuantity, toggleTag, addToList, close, itemTagsFor, listById, deleteItem } = usePrototypeKinetic()

const item = computed(() => itemById(state.sheetItemId ?? '') ?? null)
const name = ref('')
watch(item, () => {
  name.value = item.value?.name ?? ''
}, { immediate: true })

const CATEGORIES = ['Dairy', 'Bakery', 'Produce', 'Pantry', 'Beverage', 'Frozen', 'Meat', 'Snacks', 'Household', 'Baby', 'Pets', 'Outdoor']
const QUANTITIES = ['1', '2', '3', '4', '6', '8', '12', '1 gal', '1 dozen', '1 lb', '1 bag', '1 loaf', '2 boxes', '1 pack']
const itemLists = computed(() => (item.value ? [...new Set(state.listItems.filter((li) => li.itemId === item.value!.id).map((li) => li.listId))] : []))
const listsOfNames = (ids: string[]) => ids.map((id) => listById(id)?.name).join(' · ')
</script>

<template>
  <UiDrawer :open="state.sheet === 'item'" @update:open="(v: boolean) => !v && close()">
    <UiDrawerContent v-if="item" :dir="'down'" class="mx-auto w-full max-w-md">
      <UiDrawerHeader class="text-start">
        <UiDrawerTitle>{{ item.name }}</UiDrawerTitle>
        <UiDrawerDescription>Names are household-unique, so this edit lands on every Member's row.</UiDrawerDescription>
      </UiDrawerHeader>

      <div class="space-y-3 px-4">
        <div>
          <UiLabel for="item-name">Name</UiLabel>
          <div class="flex items-center gap-2">
            <UiInput id="item-name" v-model="name" class="mt-1 w-full" data-item-name />
            <UiButton variant="outline" class="h-11 shrink-0" data-rename @click="renameItem(item.id, name)">Rename</UiButton>
          </div>
        </div>
        <div>
          <UiLabel for="item-category">Category</UiLabel>
          <UiInput id="item-category" :value="item.category" list="prototype-categories" class="mt-1 w-full" @update:model-value="(v: string) => setCategory(item.id, v)" />
          <datalist id="prototype-categories">
            <option v-for="category in CATEGORIES" :key="category" :value="category" />
          </datalist>
        </div>
        <div>
          <UiLabel for="item-quantity">Quantity</UiLabel>
          <UiInput id="item-quantity" :value="item.quantity" list="prototype-quantities" class="mt-1 w-full" @update:model-value="(v: string) => setQuantity(item.id, v)" />
          <datalist id="prototype-quantities">
            <option v-for="quantity in QUANTITIES" :key="quantity" :value="quantity" />
          </datalist>
        </div>
        <div>
          <UiLabel>Store Tags</UiLabel>
          <div class="flex flex-wrap gap-1 pt-1" data-tag-pills>
            <button
              v-for="entry in storeRoster"
              :key="entry.store.id"
              type="button"
              class="border-border text-muted-foreground hover:text-foreground h-11 rounded-full border px-3 text-sm"
              :class="itemTagsFor(item).some((t) => t.id === entry.store.id) && 'text-foreground border-foreground font-medium'"
              :aria-pressed="itemTagsFor(item).some((t) => t.id === entry.store.id)"
              :aria-label="`Tag ${entry.store.name}`"
              @click="toggleTag(item.id, entry.store.id)"
            >
              <CheckIcon v-if="itemTagsFor(item).some((t) => t.id === entry.store.id)" class="size-4 me-1 inline" aria-hidden="true" />
              {{ entry.store.name }}
            </button>
          </div>
          <p v-if="itemTagsFor(item).length === 0" class="text-sm text-muted-foreground pt-1" data-gate-copy>
            No Store Tag: every Store's view is blind to this Item, and the Gate names it in the Basket. Tag it, and its rows enter those views.
          </p>
        </div>
        <div>
          <UiLabel>Lists</UiLabel>
          <p class="text-sm text-muted-foreground pt-1">
            {{ itemLists.length ? listsOfNames(itemLists) : 'Stands in no List' }}
          </p>
          <div class="flex flex-wrap gap-1 pt-1">
            <button
              v-for="entry in listsWithCounts.filter((l) => !itemLists.includes(l.list.id))"
              :key="entry.list.id"
              type="button"
              class="border-border text-muted-foreground hover:text-foreground h-11 rounded-full border px-3 text-sm"
              :aria-label="`Add to ${entry.list.name}`"
              data-add-list
              @click="addToList(item.id, entry.list.id)"
            >
              + {{ entry.list.name }}
            </button>
          </div>
        </div>
      </div>

      <footer class="px-4 pt-4 pb-4">
        <UiButton variant="outline" class="border-border text-destructive w-full" data-delete-item @click="deleteItem(item.id)">
          Delete Item
        </UiButton>
        <UiButton variant="outline" class="mt-2 w-full" data-close-item @click="close()">Close</UiButton>
      </footer>
    </UiDrawerContent>
  </UiDrawer>
</template>
