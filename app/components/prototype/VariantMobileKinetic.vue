<script setup lang="ts">
/**
 * PROTOTYPE ONLY — wayfinder #13, round 2, variant D "The Store is the home
 * screen". Kinetic View is the front tab, the Active Store is the header, the
 * capture sheet pre-ticks the Store you are standing at, Store Tags are
 * removable chips on the Kinetic and Basket rows, Buy lives on the Basket.
 *
 * No Tag prompt at Buy (Justin, round 1): the Tag act is the chip, the sheet,
 * the Store screen. Gate copy at capture + a count in the Basket.
 */
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import {
  Empty,
  EmptyContent,
  EmptyDescription,
  EmptyHeader,
  EmptyTitle,
} from "@/components/ui/empty";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";

const {
  state,
  basket,
  kineticView,
  buy,
  pick,
  storeById,
  locationById,
  captureItem,
  createStore,
  joinStoreLocation,
  storesNamed,
  untagItem,
} = usePrototypeHousehold();

const tabs = [
  { key: "kinetic", label: "Kinetic View" },
  { key: "lists", label: "Lists" },
  { key: "basket", label: "Basket" },
  { key: "household", label: "Household" },
];
const tab = ref("kinetic");

const captureOpen = ref(false);
const captureTags = ref<string[]>([]);
const pickerOpen = ref(false);
const pickerIntent = ref<"active" | "tag">("active");
const openedItemId = ref<string | null>(null);
const itemSheetOpen = computed({
  get: () => openedItemId.value !== null,
  set: (open: boolean) => {
    if (!open) openedItemId.value = null;
  },
});
const join = ref<{
  name: string;
  label: string;
  lat: number | null;
  lng: number | null;
  storeId: string;
} | null>(null);
const lastBuy = ref<{
  lines: number;
  untagged: string[];
  store: string;
  place: string;
} | null>(null);
const toast = ref("");
const standingAt = ref("l_walmart_main");

const active = computed(() => storeById(state.value.pickedStoreId));
const kinetic = computed(() =>
  active.value ? kineticView(active.value.id) : []
);
const rows = computed(() => basket());
const invisible = computed(() =>
  active.value
    ? rows.value.filter((r) => !r.item.storeTags.includes(active.value!.id))
    : []
);
const arrival = computed(() => {
  const a = state.value.arrivals[0];
  const place = a ? locationById(a.locationId) : null;
  const store = place ? storeById(place.storeId) : null;
  return a && place && store ? { member: a.memberId, store, place, at: a.at } : null;
});

function say(msg: string) {
  toast.value = msg;
  setTimeout(() => (toast.value = ""), 5000);
}

function openPicker(intent: "active" | "tag") {
  pickerIntent.value = intent;
  pickerOpen.value = true;
}

function onPick(storeId: string) {
  const store = storeById(storeId);
  if (pickerIntent.value === "tag") {
    if (!captureTags.value.includes(storeId))
      captureTags.value = [...captureTags.value, storeId];
    captureOpen.value = true;
    say(`Tagged with ${store?.name}`);
  } else {
    pick(storeId);
    standingAt.value = store?.locations[0]?.id ?? "none";
    say(`Picked ${store?.name}`);
  }
  pickerOpen.value = false;
}

function onCreate(draft: {
  name: string;
  label: string;
  lat: number | null;
  lng: number | null;
}) {
  const hit = storesNamed(draft.name)[0] ?? null;
  pickerOpen.value = false;
  if (hit) {
    join.value = { ...draft, storeId: hit.id };
    return;
  }
  const store = createStore(draft.name, draft.lat, draft.lng);
  if (pickerIntent.value === "active") pick(store.id);
  else captureTags.value = [...captureTags.value, store.id];
  say(
    `Created "${store.name}"${
      draft.lat !== null
        ? " with a Location from your Position"
        : " as a bare Store — nothing will suggest it"
    }`
  );
}

function onJoin(kind: "location" | "store") {
  const draft = join.value;
  if (!draft) return;
  if (kind === "location") {
    const location = joinStoreLocation(
      draft.storeId,
      draft.label || "New place",
      draft.lat ?? 42.10154,
      draft.lng ?? -72.5811
    );
    if (pickerIntent.value === "tag")
      captureTags.value = [...captureTags.value, draft.storeId];
    say(
      `Added Location "${location?.label}" to ${storeById(draft.storeId)?.name}`
    );
  } else {
    const store = createStore(draft.name, draft.lat, draft.lng);
    if (pickerIntent.value === "active") pick(store.id);
    else captureTags.value = [...captureTags.value, store.id];
    say(
      `Named "${store.name}" its own Store${
        draft.lat === null ? " (bare, no Location)" : ""
      }`
    );
  }
  join.value = null;
}

function onCapture(payload: {
  name: string;
  category: string;
  quantity: string;
  tags: string[];
}) {
  const { item, joined } = captureItem(payload);
  captureOpen.value = false;
  captureTags.value = [];
  openedItemId.value = item.id;
  say(
    `Captured "${item.name}" (${joined ? "joined the existing Item" : "new Item"})${
      payload.tags.length
        ? ` · ${payload.tags.length} Store Tag(s)`
        : " · no Store Tag"
    }`
  );
}

function doBuy() {
  const store = active.value;
  if (!store) return;
  const locationId = standingAt.value === "none" ? null : standingAt.value;
  const result = buy(store.id, locationId);
  if (!result) return;
  lastBuy.value = {
    lines: result.purchase.lines.length,
    untagged: result.untagged.map((r) => r.item.name),
    store: store.name,
    place: result.purchase.locationId
      ? locationById(result.purchase.locationId)?.label ?? "(no Location)"
      : "(no Location)",
  };
}
</script>

<template>
  <PrototypeMobileShell
    :tabs="tabs"
    :active="tab"
    @update:active="tab = $event"
    @capture="captureOpen = true"
  >
    <template #header>
      <button
        class="flex w-full items-center justify-between gap-2 text-left"
        @click="openPicker('active')"
      >
        <span>
          <span class="block text-[11px] uppercase text-muted-foreground">
            Active Store — tap to change
          </span>
          <span class="block text-lg font-semibold leading-tight">
            {{ active?.name ?? "No Store picked" }}
          </span>
          <span class="block text-xs text-muted-foreground">
            {{
              active
                ? standingAt === "none"
                  ? "standing at no Location"
                  : `standing at ${locationById(standingAt)?.label}`
                : "the Kinetic View is empty until you Pick a Store"
            }}
          </span>
        </span>
        <span class="text-xs text-muted-foreground">
          {{ active?.locations.length ?? 0 }} Location(s)
        </span>
      </button>
      <p
        v-if="arrival && tab === 'kinetic'"
        class="mt-2 rounded-md bg-muted px-3 py-2 text-xs"
      >
        {{ arrival.member }} is at {{ arrival.store.name }} ·
        {{ arrival.place.label }} ({{ arrival.at }}) — an Arrival only suggests
        Picking.
        <button
          class="font-medium text-primary"
          @click="pick(arrival.store.id); standingAt = arrival.place.id"
        >
          Pick it
        </button>
      </p>
      <p
        v-if="toast"
        class="mt-2 rounded-md bg-primary/10 px-3 py-2 text-xs font-medium"
      >
        {{ toast }}
      </p>
    </template>

    <!-- Kinetic View: Needed at the Active Store, cross-List -->
    <section v-if="tab === 'kinetic'" class="space-y-3">
      <h3 class="text-sm font-semibold">
        Kinetic View · Needed at {{ active?.name ?? "—" }}, cross-List
      </h3>

      <Empty v-if="!kinetic.length">
        <EmptyHeader>
          <EmptyTitle>Nothing Needed here</EmptyTitle>
          <EmptyDescription>
            An Item shows up only when it is Needed *and* carries this Store's
            Tag.
          </EmptyDescription>
        </EmptyHeader>
        <EmptyContent>
          <Button size="sm" variant="outline" @click="captureOpen = true">
            Capture an Item
          </Button>
        </EmptyContent>
      </Empty>

      <ul v-else class="space-y-2">
        <li
          v-for="row in kinetic"
          :key="row.item.id + row.listName"
          class="rounded-lg border p-3"
        >
          <button class="block w-full text-left" @click="openedItemId = row.item.id">
            <span class="block text-sm font-medium">{{ row.item.name }}</span>
            <span class="block text-xs text-muted-foreground">
              {{ row.item.quantity }} · {{ row.listName }}
            </span>
          </button>
          <div class="mt-2 flex flex-wrap gap-1.5">
            <button
              v-for="id in row.item.storeTags"
              :key="id"
              class="rounded-full bg-secondary px-2.5 py-1 text-[11px] font-medium"
              @click.stop="untagItem(row.item.id, id)"
            >
              {{ storeById(id)?.name }} ×
            </button>
            <button
              class="rounded-full border px-2.5 py-1 text-[11px] text-muted-foreground"
              @click.stop="openPicker('tag')"
            >
              + Tag
            </button>
          </div>
        </li>
      </ul>

      <p
        v-if="invisible.length"
        class="rounded-md bg-destructive/10 px-3 py-2 text-xs font-medium text-destructive"
      >
        {{ invisible.length }} Item(s) in the Basket have no Tag for
        {{ active?.name }} — invisible on this Kinetic View:
        {{ invisible.map((r) => r.item.name).join(", ") }}
      </p>
    </section>

    <!-- Lists -->
    <section v-if="tab === 'lists'" class="space-y-3">
      <Card v-for="list in state.lists" :key="list.id">
        <CardHeader>
          <CardTitle class="text-base">{{ list.name }}</CardTitle>
        </CardHeader>
        <CardContent class="space-y-1.5">
          <button
            v-for="li in list.items"
            :key="li.id"
            class="flex w-full items-center justify-between gap-2 text-left text-sm"
            @click="openedItemId = li.itemId"
          >
            <span>{{
              state.items.find((i) => i.id === li.itemId)?.name
            }}</span>
            <span class="text-xs text-muted-foreground">{{ li.status }}</span>
          </button>
        </CardContent>
      </Card>
    </section>

    <!-- Basket: the whole-Household view, Buy happens here -->
    <section v-if="tab === 'basket'" class="space-y-3">
      <h3 class="text-sm font-semibold">
        Basket · {{ rows.length }} · whole Household
      </h3>

      <div class="space-y-1.5">
        <p class="text-xs font-medium uppercase text-muted-foreground">
          Standing at this Store's Location
        </p>
        <Select v-model="standingAt">
          <SelectTrigger>
            <SelectValue placeholder="Standing at…" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="none">(no Location)</SelectItem>
            <SelectItem
              v-for="location in active?.locations ?? []"
              :key="location.id"
              :value="location.id"
            >
              {{ location.label }}
            </SelectItem>
          </SelectContent>
        </Select>
      </div>

      <ul class="space-y-2">
        <li
          v-for="row in rows"
          :key="row.listItemId"
          class="rounded-lg border p-3"
        >
          <button
            class="block w-full text-left"
            @click="openedItemId = row.item.id"
          >
            <span class="block text-sm font-medium">{{ row.item.name }}</span>
            <span class="block text-xs text-muted-foreground">
              {{ row.item.quantity }} · {{ row.listName }}
            </span>
          </button>
          <div class="mt-2 flex flex-wrap gap-1.5">
            <button
              v-for="id in row.item.storeTags"
              :key="id"
              class="rounded-full bg-secondary px-2.5 py-1 text-[11px] font-medium"
              @click.stop="untagItem(row.item.id, id)"
            >
              {{ storeById(id)?.name }} ×
            </button>
            <span
              v-if="active && !row.item.storeTags.includes(active.id)"
              class="rounded-full bg-destructive/15 px-2.5 py-1 text-[11px] font-medium text-destructive"
            >
              invisible at {{ active.name }}
            </span>
          </div>
        </li>
      </ul>

      <Button class="w-full" :disabled="!rows.length || !active" @click="doBuy">
        Buy {{ rows.length }} at {{ active?.name ?? "—" }}
      </Button>

      <Card v-if="lastBuy">
        <CardHeader>
          <CardTitle class="text-base">Purchase recorded</CardTitle>
        </CardHeader>
        <CardContent class="space-y-2 text-sm">
          <p class="text-xs text-muted-foreground">
            {{ lastBuy.lines }} line(s) at {{ lastBuy.store }} ({{ lastBuy.place
            }}) — every line is now Stocked. A Purchase is append-only: no Tag
            is written by Buy.
          </p>
          <p v-if="lastBuy.untagged.length" class="text-xs text-muted-foreground">
            Bought with no Tag for {{ lastBuy.store }}:
            {{ lastBuy.untagged.join(", ") }}. Tag them from the Item, the row,
            or the Store screen — the tag arriving at Buy is a habit, not a
            prompt.
          </p>
        </CardContent>
      </Card>
    </section>

    <PrototypeHouseholdPanel v-if="tab === 'household'" />

    <PrototypeCaptureSheet
      v-model:open="captureOpen"
      v-model:tags="captureTags"
      mode="chips"
      :inherit="tab === 'kinetic' ? active?.id ?? null : null"
      :list-name="state.lists[0].name"
      @submit="onCapture"
      @open-picker="openPicker('tag')"
    />

    <PrototypeStorePickerSheet
      v-model:open="pickerOpen"
      :title="pickerIntent === 'active' ? 'Pick the Active Store' : 'Tag with a Store'"
      subtitle="A Store with no Location is legal here — it is taggable and Pickable, and nothing will suggest it."
      :ask-place="pickerIntent === 'active'"
      @pick="onPick"
      @create="onCreate"
    />

    <PrototypeItemSheet
      v-model:open="itemSheetOpen"
      :item-id="openedItemId"
    />

    <PrototypeNameJoinSheet
      :open="join !== null"
      :typed="join?.name ?? ''"
      :store="join ? storeById(join.storeId) : null"
      :has-coords="join ? join.lat !== null : false"
      @update:open="
        (open) => {
          if (!open) join = null;
        }
      "
      @as-location="onJoin('location')"
      @as-store="onJoin('store')"
    />
  </PrototypeMobileShell>
</template>
