<script setup lang="ts">
/**
 * PROTOTYPE ONLY — wayfinder #13. The Store picker as a bottom sheet list:
 * the Household's Stores (a bare Store is listed, taggable, Pickable), plus
 * "add a store from where I am now". A typed name that hits an existing Store
 * hands the join decision to the parent's name-join sheet.
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
  title: string;
  subtitle: string;
  /** Show a Location label field next to the new store's name. */
  askPlace?: boolean;
}>();

const emit = defineEmits<{
  (e: "update:open", open: boolean): void;
  (e: "pick", storeId: string): void;
  (
    e: "create",
    draft: { name: string; label: string; lat: number | null; lng: number | null }
  ): void;
}>();

const { state, storesNamed } = usePrototypeHousehold();
const name = ref("");
const label = ref("");
const lat = ref<number | null>(null);
const lng = ref<number | null>(null);

const hit = computed(() => (name.value.trim() ? storesNamed(name.value)[0] ?? null : null));

function submit() {
  if (!name.value.trim()) return;
  emit("create", {
    name: name.value.trim(),
    label: label.value.trim(),
    lat: lat.value,
    lng: lng.value,
  });
  name.value = "";
  label.value = "";
  lat.value = null;
  lng.value = null;
}
</script>

<template>
  <Sheet :open="props.open" @update:open="emit('update:open', $event)">
    <SheetContent
      side="bottom"
      class="max-h-[86vh] gap-0 overflow-y-auto p-0 sm:max-h-[86vh]"
    >
      <SheetHeader class="border-b px-5 py-4 text-left">
        <SheetTitle>{{ props.title }}</SheetTitle>
        <SheetDescription>{{ props.subtitle }}</SheetDescription>
      </SheetHeader>

      <ul class="divide-y">
        <li v-for="store in state.stores" :key="store.id">
          <button
            class="flex w-full items-center justify-between gap-3 px-5 py-4 text-left text-sm"
            @click="emit('pick', store.id)"
          >
            <span class="font-medium">{{ store.name }}</span>
            <span class="text-xs text-muted-foreground">
              {{
                store.locations.length
                  ? `${store.locations.length} Location${
                      store.locations.length > 1 ? "s" : ""
                    }`
                  : "bare Store — nothing suggests it"
              }}
            </span>
          </button>
        </li>
      </ul>

      <div class="space-y-3 border-t bg-muted/40 px-5 py-4">
        <div class="space-y-1.5">
          <Label for="ps-new-store">Add a store from where I am now</Label>
          <Input id="ps-new-store" v-model="name" placeholder="Trader Joe's" />
        </div>
        <div v-if="props.askPlace" class="space-y-1.5">
          <Label for="ps-new-place">Place label</Label>
          <Input id="ps-new-place" v-model="label" placeholder="Broker Rd" />
        </div>
        <PrototypePositionRow v-model:lat="lat" v-model:lng="lng" />
        <Button class="w-full" :disabled="!name.trim()" @click="submit">
          {{ hit ? `Confirm — "${hit.name}" is already a Store` : "Add store" }}
        </Button>
      </div>

      <SheetFooter class="px-5 py-4">
        <p class="text-xs text-muted-foreground">
          Coordinates are read once and never stored — they land on the new
          Location, not on the device.
        </p>
      </SheetFooter>
    </SheetContent>
  </Sheet>
</template>
