<script setup lang="ts">
/**
 * PROTOTYPE ONLY — wayfinder #13. The name-join confirmation step: a typed
 * Store name that hits an existing Store (case-insensitive) is an OFFER, never
 * a forced normalize. Both paths are legal, and so is a bare Store.
 */
import { Button } from "@/components/ui/button";
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
  typed: string;
  store: { name: string; locations: { label: string }[] } | null;
  hasCoords: boolean;
}>();

const emit = defineEmits<{
  (e: "update:open", open: boolean): void;
  (e: "asLocation"): void;
  (e: "asStore"): void;
}>();
</script>

<template>
  <Sheet :open="props.open" @update:open="emit('update:open', $event)">
    <SheetContent side="bottom" class="gap-0 p-0">
      <SheetHeader class="border-b px-5 py-4 text-left">
        <SheetTitle>
          "{{ props.typed }}" is already a Store in The Fridges
        </SheetTitle>
        <SheetDescription>
          One Walmart, many Locations: a Location is the place, the Store is the
          tag. What do you mean?
        </SheetDescription>
      </SheetHeader>

      <div class="space-y-2 px-5 py-4 text-sm">
        <p class="text-muted-foreground">
          {{ props.store?.name }} has
          {{ props.store?.locations.length ?? 0 }} Location(s):
          {{ (props.store?.locations ?? []).map((l) => l.label).join(", ") ||
            "none" }}
        </p>
      </div>

      <SheetFooter class="gap-2 px-5 py-4 sm:grid sm:grid-cols-1">
        <Button class="w-full" @click="emit('asLocation')">
          Add a Location to {{ props.store?.name }}
          <span v-if="props.hasCoords">from these coordinates</span>
        </Button>
        <Button class="w-full" variant="outline" @click="emit('asStore')">
          Name it "{{ props.typed }}" as its own Store
          <span v-if="!props.hasCoords">(bare, no Location)</span>
        </Button>
        <p class="text-xs text-muted-foreground">
          Tagging alone never moves a Location, and never replaces a Tag.
        </p>
      </SheetFooter>
    </SheetContent>
  </Sheet>
</template>
