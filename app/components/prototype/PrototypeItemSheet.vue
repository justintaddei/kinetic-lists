<script setup lang="ts">
/**
 * PROTOTYPE ONLY — wayfinder #13. The Item drill-down: the private screen of an
 * Item, where its Store Tags live (Tag is additive, Tags are never replaced),
 * where a Member removes one, and where its Status lives.
 */
import { Button } from "@/components/ui/button";
import { Separator } from "@/components/ui/separator";
import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetFooter,
  SheetHeader,
  SheetTitle,
} from "@/components/ui/sheet";

const props = defineProps<{ open: boolean; itemId: string | null }>();

const emit = defineEmits<{ (e: "update:open", open: boolean): void }>();

const { state, itemById, tagItem, untagItem } = usePrototypeHousehold();

/** The sheet animates closed; the header must not blank out mid-animation. */
const lastItemId = ref<string | null>(null);
watch(
  () => props.itemId,
  (id) => {
    if (id) lastItemId.value = id;
  },
  { immediate: true }
);
const shownId = computed(() => props.itemId ?? lastItemId.value);
const item = computed(() => (shownId.value ? itemById(shownId.value) : null));

const rows = computed(() => {
  if (!item.value) return [];
  const out: { listName: string; status: string; listItemId: string }[] = [];
  for (const list of state.value.lists)
    for (const li of list.items)
      if (li.itemId === item.value.id)
        out.push({
          listName: list.name,
          status: li.status,
          listItemId: li.id,
        });
  return out;
});

const statuses = ["Needed", "In Basket", "Stocked"] as const;

function setStatus(listItemId: string, status: string) {
  for (const list of state.value.lists) {
    const li = list.items.find((x) => x.id === listItemId);
    if (li) li.status = status as (typeof statuses)[number];
  }
}
</script>

<template>
  <Sheet :open="props.open" @update:open="emit('update:open', $event)">
    <SheetContent
      side="bottom"
      class="max-h-[86vh] gap-0 overflow-y-auto p-0 sm:max-h-[86vh]"
    >
      <SheetHeader class="border-b px-5 py-4 text-left">
        <SheetTitle>{{ item?.name ?? "Item" }}</SheetTitle>
        <SheetDescription>
          {{ item?.category || "no Category" }} · {{ item?.quantity || "no Quantity" }} ·
          Item {{ item?.id }}
        </SheetDescription>
      </SheetHeader>

      <div class="space-y-4 px-5 py-4">
        <div class="space-y-2">
          <p class="text-xs font-medium uppercase text-muted-foreground">
            Store Tags
          </p>
          <ul v-if="item?.storeTags.length" class="space-y-1.5">
            <li
              v-for="id in item.storeTags"
              :key="id"
              class="flex items-center justify-between gap-3 text-sm"
            >
              <span>{{ state.stores.find((s) => s.id === id)?.name }}</span>
              <button
                class="text-xs font-medium text-destructive"
                @click="item && untagItem(item.id, id)"
              >
                Remove Tag
              </button>
            </li>
          </ul>
          <p v-else class="text-sm text-destructive">
            No Store Tag — invisible on every Kinetic View.
          </p>
        </div>

        <div class="space-y-2">
          <p class="text-xs font-medium uppercase text-muted-foreground">
            Add a Store Tag
          </p>
          <div class="flex flex-wrap gap-2">
            <button
              v-for="store in state.stores.filter(
                (s) => !item?.storeTags.includes(s.id)
              )"
              :key="store.id"
              class="rounded-full border px-3 py-2 text-xs font-medium text-muted-foreground"
              @click="item && tagItem(item.id, store.id)"
            >
              {{ store.name }}
            </button>
          </div>
        </div>

        <Separator />

        <div class="space-y-2">
          <p class="text-xs font-medium uppercase text-muted-foreground">
            On the Lists
          </p>
          <div
            v-for="row in rows"
            :key="row.listItemId"
            class="flex items-center justify-between gap-2 text-sm"
          >
            <span class="text-muted-foreground">{{ row.listName }}</span>
            <span class="flex gap-1">
              <button
                v-for="s in statuses"
                :key="s"
                class="rounded-md border px-2.5 py-1.5 text-xs"
                :class="
                  row.status === s
                    ? 'border-primary bg-primary text-primary-foreground'
                    : 'text-muted-foreground'
                "
                @click="setStatus(row.listItemId, s)"
              >
                {{ s }}
              </button>
            </span>
          </div>
        </div>
      </div>

      <SheetFooter class="px-5 py-4">
        <Button class="w-full" variant="outline" @click="emit('update:open', false)">
          Done
        </Button>
      </SheetFooter>
    </SheetContent>
  </Sheet>
</template>
