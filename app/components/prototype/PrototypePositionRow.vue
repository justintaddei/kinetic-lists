<script setup lang="ts">
/**
 * PROTOTYPE ONLY — wayfinder #13. A Location's coordinates, entered by hand
 * ("the typed lat/lng hatch") or taken from a one-shot device Position.
 */
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";

const lat = defineModel<number | null>("lat", { default: null });
const lng = defineModel<number | null>("lng", { default: null });

const pos = usePrototypePosition();

function useMine() {
  pos.read();
  setTimeout(() => {
    lat.value = pos.coords.value?.lat ?? null;
    lng.value = pos.coords.value?.lng ?? null;
  }, 150);
}
</script>

<template>
  <div class="space-y-2">
    <div class="grid grid-cols-2 gap-2">
      <Input
        inputmode="decimal"
        placeholder="lat"
        :model-value="lat === null ? '' : String(lat)"
        @update:model-value="lat = $event === '' ? null : Number($event)"
      />
      <Input
        inputmode="decimal"
        placeholder="lng"
        :model-value="lng === null ? '' : String(lng)"
        @update:model-value="lng = $event === '' ? null : Number($event)"
      />
    </div>
    <div class="flex items-center justify-between gap-2">
      <p class="text-xs text-muted-foreground">{{ pos.label.value }}</p>
      <Button size="sm" variant="outline" @click="useMine">Where I am</Button>
    </div>
  </div>
</template>
