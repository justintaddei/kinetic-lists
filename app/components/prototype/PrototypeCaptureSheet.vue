<script setup lang="ts">
/**
 * PROTOTYPE ONLY — wayfinder #13. The capture form as a bottom sheet, launched
 * by the FAB. Two shapes: `chips` (every Store as a chip you can tick) and
 * `picker` (one "Buy at" control that opens the Store sheet). Both say the
 * Kinetic View gate out loud when the Item carries no Store Tag.
 */
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetFooter,
  SheetHeader,
  SheetTitle,
} from "@/components/ui/sheet";

const props = defineProps<{
  open: boolean;
  mode: "chips" | "picker";
  /** A Store pre-ticked because the screen you captured from is about it. */
  inherit: string | null;
  listName: string;
}>();

const emit = defineEmits<{
  (e: "update:open", open: boolean): void;
  (
    e: "submit",
    payload: { name: string; category: string; quantity: string; tags: string[] }
  ): void;
  (e: "openPicker"): void;
}>();

const { state, storesNamed, itemsNamed, categoriesInUse } = usePrototypeHousehold();

const name = ref("");
const category = ref("");
const quantity = ref("");
/** Two-way so a variant can fill tags from the Store picker sheet. */
const tags = defineModel<string[]>("tags", { default: [] });

const categories = computed(() => categoriesInUse());
const itemJoin = computed(() =>
  name.value.trim() ? itemsNamed(name.value)[0] ?? null : null
);
const storeJoin = computed(() =>
  name.value.trim() ? storesNamed(name.value)[0] ?? null : null
);

watch(
  () => props.open,
  (open) => {
    if (open) tags.value = props.inherit ? [props.inherit] : [];
  },
  { immediate: true }
);

function toggle(storeId: string) {
  tags.value = tags.value.includes(storeId)
    ? tags.value.filter((s) => s !== storeId)
    : [...tags.value, storeId];
}

function submit() {
  emit("submit", {
    name: name.value.trim(),
    category: category.value.trim(),
    quantity: quantity.value.trim(),
    tags: [...tags.value],
  });
  name.value = "";
  category.value = "";
  quantity.value = "";
  tags.value = [];
}
</script>

<template>
  <Sheet :open="props.open" @update:open="emit('update:open', $event)">
    <SheetContent
      side="bottom"
      class="max-h-[88vh] gap-0 overflow-y-auto p-0 sm:max-h-[88vh]"
    >
      <SheetHeader class="border-b px-5 py-4 text-left">
        <SheetTitle>Capture an Item</SheetTitle>
        <SheetDescription>
          Goes into {{ props.listName }}. One Item per name for The Fridges.
        </SheetDescription>
      </SheetHeader>

      <div class="space-y-4 px-5 py-4">
        <div class="space-y-1.5">
          <Label for="pc-name">Name</Label>
          <Input id="pc-name" v-model="name" placeholder="Spinach" />
          <p v-if="itemJoin" class="text-xs text-muted-foreground">
            "{{ itemJoin.name }}" is already in the catalogue — capturing it
            joins that Item and adds it to the List.
          </p>
        </div>

        <div class="grid grid-cols-2 gap-3">
          <div class="space-y-1.5">
            <Label for="pc-category">Category</Label>
            <Input
              id="pc-category"
              v-model="category"
              list="pc-categories"
              placeholder="Produce"
            />
            <datalist id="pc-categories">
              <option v-for="c in categories" :key="c" :value="c" />
            </datalist>
          </div>
          <div class="space-y-1.5">
            <Label for="pc-quantity">Quantity</Label>
            <Input id="pc-quantity" v-model="quantity" placeholder="1 bag" />
          </div>
        </div>

        <div class="space-y-2">
          <Label>Store Tags — where do you buy it?</Label>

          <div v-if="props.mode === 'chips'" class="flex flex-wrap gap-2">
            <button
              v-for="store in state.stores"
              :key="store.id"
              class="rounded-full border px-3 py-2 text-xs font-medium"
              :class="
                tags.includes(store.id)
                  ? 'border-primary bg-primary text-primary-foreground'
                  : 'text-muted-foreground'
              "
              @click="toggle(store.id)"
            >
              {{ store.name }}
              <span class="opacity-70">
                {{ store.locations.length ? `${store.locations.length} place(s)` : "no place" }}
              </span>
            </button>
          </div>

          <button
            v-else
            class="w-full rounded-md border px-4 py-3 text-left text-sm"
            @click="emit('openPicker')"
          >
            <span v-if="!tags.length" class="text-muted-foreground">
              Buy at…
            </span>
            <span v-else>
              {{ tags.map((id) => state.stores.find((s) => s.id === id)?.name).join(", ") }}
            </span>
          </button>

          <div v-if="props.mode === 'picker'" class="flex flex-wrap gap-2">
            <button
              v-for="id in tags"
              :key="id"
              class="rounded-full bg-secondary px-3 py-1.5 text-xs font-medium"
              @click="toggle(id)"
            >
              {{ state.stores.find((s) => s.id === id)?.name }} ×
            </button>
          </div>

          <button
            class="text-xs font-medium text-primary underline underline-offset-2"
            @click="emit('openPicker')"
          >
            + Add a store from where I am now
          </button>

          <p
            v-if="!tags.length"
            class="rounded-md bg-destructive/10 px-3 py-2 text-xs font-medium text-destructive"
          >
            No Store Tag: nobody in The Fridges will see this Item on a Kinetic
            View at any store.
          </p>
          <p v-else-if="storeJoin" class="text-xs text-muted-foreground">
            Tip: a Store named "{{ name }}" exists — the picker will confirm
            before it makes a second one.
          </p>
        </div>
      </div>

      <SheetFooter class="px-5 py-4">
        <Button class="w-full" :disabled="!name.trim()" @click="submit">
          Capture
        </Button>
      </SheetFooter>
    </SheetContent>
  </Sheet>
</template>
