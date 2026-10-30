<script setup lang="ts">
/**
 * PROTOTYPE ONLY — wayfinder #13, round 2, variant E "Lists are the home
 * screen, the Store is a filter". The List is the drill-down; a Store filter
 * chip row sits at the top of it and decides which rows speak to you. Rows
 * never carry Tag chips — a row shows a count, and the Tags live on the Item's
 * own sheet. Buy picks its Store from the Basket.
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
} = usePrototypeHousehold();

const tabs = [
  { key: "lists", label: "Lists" },
  { key: "kinetic", label: "Kinetic View" },
  { key: "basket", label: "Basket" },
  { key: "household", label: "Household" },
];
const tab = ref("lists");
const openListId = ref<string | null>(null);
const filterStoreId = ref<string>("s_walmart");

const captureOpen = ref(false);
const captureTags = ref<string[]>([]);
const pickerOpen = ref(false);
const pickerIntent = ref<"filter" | "tag" | "buy">("filter");
const buyStoreId = ref("s_walmart");
const buyLocationId = ref("none");
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
const lastBuy = ref<{ lines: number; untagged: string[]; store: string; place: string } | null>(null);
const toast = ref("");

const openList = computed(
  () => state.value.lists.find((l) => l.id === openListId.value) ?? null
);
const filterStore = computed(() => storeById(filterStoreId.value));
const buyStore = computed(() => storeById(buyStoreId.value));

const listRows = computed(() => {
  if (!openList.value) return [];
  return openList.value.items
    .map((li) => ({
      ...li,
      item: state.value.items.find((i) => i.id === li.itemId) ?? null,
    }))
    .filter((r) => r.item);
});
const neededAtFilter = computed(
  () =>
    listRows.value.filter(
      (r) =>
        r.status === "Needed" && r.item!.storeTags.includes(filterStoreId.value)
    ).length
);
const invisibleAtFilter = computed(
  () =>
    listRows.value.filter(
      (r) =>
        r.status === "Needed" && !r.item!.storeTags.includes(filterStoreId.value)
    ).length
);

const byStore = computed(() =>
  state.value.stores.map((store) => ({
    store,
    rows: kineticView(store.id),
  }))
);

const rows = computed(() => basket());
const invisibleAtBuy = computed(() =>
  rows.value.filter((r) => !r.item.storeTags.includes(buyStoreId.value))
);

function say(msg: string) {
  toast.value = msg;
  setTimeout(() => (toast.value = ""), 5000);
}

function openPicker(intent: "filter" | "tag" | "buy") {
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
  } else if (pickerIntent.value === "buy") {
    buyStoreId.value = storeId;
    buyLocationId.value = store?.locations[0]?.id ?? "none";
    pick(storeId);
    say(`Buying at ${store?.name}`);
  } else {
    filterStoreId.value = storeId;
    pick(storeId);
    say(`Filtering at ${store?.name}`);
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
  if (pickerIntent.value === "tag")
    captureTags.value = [...captureTags.value, store.id];
  else if (pickerIntent.value === "buy") buyStoreId.value = store.id;
  else filterStoreId.value = store.id;
  pick(store.id);
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
    if (pickerIntent.value === "tag")
      captureTags.value = [...captureTags.value, store.id];
    else if (pickerIntent.value === "buy") buyStoreId.value = store.id;
    else filterStoreId.value = store.id;
    pick(store.id);
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
  const store = buyStore.value;
  if (!store) return;
  const result = buy(
    store.id,
    buyLocationId.value === "none" ? null : buyLocationId.value
  );
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
    capture-label="+ Capture here"
    @update:active="
      tab = $event;
      if ($event !== 'lists') openListId = null;
    "
    @capture="captureOpen = true"
  >
    <template #header>
      <p class="text-[11px] uppercase text-muted-foreground">The Fridges</p>
      <p class="text-lg font-semibold leading-tight">
        {{ tab === "lists" ? "Lists" : tab === "kinetic" ? "Kinetic View" : tab === "basket" ? "Basket" : "Household" }}
      </p>
      <p v-if="tab === 'lists' && openList" class="text-xs text-muted-foreground">
        {{ openList.name }} · {{ listRows.length }} item(s) · filtering at
        {{ filterStore?.name ?? "no Store" }}
      </p>
      <p v-else class="text-xs text-muted-foreground">
        Dana · Alex · {{ state.stores.length }} Stores · Active Store
        {{ storeById(state.pickedStoreId)?.name }}
      </p>
      <p
        v-if="toast"
        class="mt-2 rounded-md bg-primary/10 px-3 py-2 text-xs font-medium"
      >
        {{ toast }}
      </p>
    </template>

    <!-- Lists: the home, and the drill-down -->
    <section v-if="tab === 'lists'" class="space-y-3">
      <template v-if="!openList">
        <Card
          v-for="list in state.lists"
          :key="list.id"
          class="cursor-pointer"
          @click="openListId = list.id"
        >
          <CardHeader>
            <CardTitle class="text-base">{{ list.name }}</CardTitle>
          </CardHeader>
          <CardContent class="text-xs text-muted-foreground">
            {{ list.items.length }} item(s) ·
            {{ list.items.filter((i) => i.status === "Needed").length }} Needed ·
            {{ list.items.filter((i) => i.status === "In Basket").length }} in
            Basket
          </CardContent>
        </Card>
        <p class="text-xs text-muted-foreground">
          Tap a List to open it. The Store filter lives inside the List.
        </p>
      </template>

      <template v-else>
        <Button size="sm" variant="outline" @click="openListId = null">
          ‹ Lists
        </Button>

        <div class="flex flex-wrap gap-1.5">
          <button
            v-for="store in state.stores"
            :key="store.id"
            class="rounded-full border px-3 py-2 text-xs font-medium"
            :class="
              filterStoreId === store.id
                ? 'border-primary bg-primary text-primary-foreground'
                : 'text-muted-foreground'
            "
            @click="filterStoreId = store.id; pick(store.id)"
          >
            Needs at {{ store.name }}
          </button>
          <button
            class="rounded-full border px-3 py-2 text-xs text-muted-foreground"
            @click="openPicker('filter')"
          >
            + Store
          </button>
        </div>

        <p class="rounded-md bg-muted px-3 py-2 text-xs">
          {{ neededAtFilter }} of {{ listRows.length }} row(s) are Needed
          <b>and</b> carry a Tag for {{ filterStore?.name }} — that is the Kinetic
          View at {{ filterStore?.name }}.
        </p>
        <p
          v-if="invisibleAtFilter"
          class="rounded-md bg-destructive/10 px-3 py-2 text-xs font-medium text-destructive"
        >
          {{ invisibleAtFilter }} Needed row(s) carry no Tag for
          {{ filterStore?.name }}:
          {{
            listRows
              .filter((r) => r.status === "Needed" && !r.item!.storeTags.includes(filterStoreId))
              .map((r) => r.item!.name)
              .join(", ")
          }}
        </p>

        <ul class="space-y-2">
          <li
            v-for="row in listRows"
            :key="row.id"
            class="flex items-center justify-between gap-3 rounded-lg border p-3"
          >
            <button class="text-left" @click="openedItemId = row.itemId">
              <span class="block text-sm font-medium">{{ row.item!.name }}</span>
              <span class="block text-xs text-muted-foreground">
                {{ row.item!.quantity }} · {{ row.status }}
              </span>
            </button>
            <button
              class="shrink-0 rounded-full bg-secondary px-2.5 py-1 text-[11px] font-medium"
              @click="openedItemId = row.itemId"
            >
              {{ row.item!.storeTags.length }} store(s)
            </button>
          </li>
        </ul>
      </template>
    </section>

    <!-- Kinetic View: every Store at once, no chips on the rows -->
    <section v-if="tab === 'kinetic'" class="space-y-4">
      <div v-for="group in byStore" :key="group.store.id" class="space-y-2">
        <h3 class="text-sm font-semibold">
          Needed at {{ group.store.name }}
          <span v-if="!group.store.locations.length" class="text-xs text-muted-foreground">
            · bare Store, nothing suggests it
          </span>
        </h3>
        <Empty v-if="!group.rows.length">
          <EmptyHeader>
            <EmptyTitle>Nothing here</EmptyTitle>
            <EmptyDescription>
              No Needed row carries this Store's Tag.
            </EmptyDescription>
          </EmptyHeader>
        </Empty>
        <ul v-else class="space-y-2">
          <li
            v-for="row in group.rows"
            :key="group.store.id + row.item.id + row.listName"
            class="flex items-center justify-between gap-3 rounded-lg border p-3"
          >
            <button class="text-left" @click="openedItemId = row.item.id">
              <span class="block text-sm font-medium">{{ row.item.name }}</span>
              <span class="block text-xs text-muted-foreground">
                {{ row.item.quantity }} · {{ row.listName }} ·
                {{ row.item.storeTags.length }} store(s)
              </span>
            </button>
          </li>
        </ul>
      </div>
    </section>

    <!-- Basket: clean rows, per-Store counts, Buy picks its Store -->
    <section v-if="tab === 'basket'" class="space-y-3">
      <h3 class="text-sm font-semibold">
        Basket · {{ rows.length }} · whole Household
      </h3>

      <ul class="space-y-2">
        <li
          v-for="row in rows"
          :key="row.listItemId"
          class="flex items-center justify-between gap-3 rounded-lg border p-3"
        >
          <button class="text-left" @click="openedItemId = row.itemId">
            <span class="block text-sm font-medium">{{ row.item.name }}</span>
            <span class="block text-xs text-muted-foreground">
              {{ row.item.quantity }} · {{ row.listName }}
            </span>
          </button>
          <button
            class="shrink-0 rounded-full bg-secondary px-2.5 py-1 text-[11px] font-medium"
            @click="openedItemId = row.itemId"
          >
            {{ row.item.storeTags.length }} store(s)
          </button>
        </li>
      </ul>

      <div class="grid grid-cols-2 gap-2">
        <Select v-model="buyStoreId">
          <SelectTrigger>
            <SelectValue placeholder="Buying at" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem v-for="s in state.stores" :key="s.id" :value="s.id">
              {{ s.name }}
            </SelectItem>
          </SelectContent>
        </Select>
        <Select v-model="buyLocationId">
          <SelectTrigger>
            <SelectValue placeholder="Standing at" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="none">(no Location)</SelectItem>
            <SelectItem
              v-for="location in buyStore?.locations ?? []"
              :key="location.id"
              :value="location.id"
            >
              {{ location.label }}
            </SelectItem>
          </SelectContent>
        </Select>
      </div>

      <p
        v-if="invisibleAtBuy.length"
        class="rounded-md bg-destructive/10 px-3 py-2 text-xs font-medium text-destructive"
      >
        {{ invisibleAtBuy.length }} of them have no Tag for
        {{ buyStore?.name }} — they will never show at this Kinetic View:
        {{ invisibleAtBuy.map((r) => r.item.name).join(", ") }}
      </p>

      <Button class="w-full" :disabled="!rows.length" @click="doBuy">
        Buy {{ rows.length }} at {{ buyStore?.name ?? "—" }}
      </Button>

      <Card v-if="lastBuy">
        <CardHeader>
          <CardTitle class="text-base">Purchase recorded</CardTitle>
        </CardHeader>
        <CardContent class="space-y-2 text-sm">
          <p class="text-xs text-muted-foreground">
            {{ lastBuy.lines }} line(s) at {{ lastBuy.store }} ({{ lastBuy.place
            }}) · every line is now Stocked. Buy writes no Tag.
          </p>
          <p v-if="lastBuy.untagged.length" class="text-xs text-muted-foreground">
            Bought with no Tag for {{ lastBuy.store }}:
            {{ lastBuy.untagged.join(", ") }} — open the Item to Tag them.
          </p>
        </CardContent>
      </Card>
    </section>

    <PrototypeHouseholdPanel v-if="tab === 'household'" />

    <PrototypeCaptureSheet
      v-model:open="captureOpen"
      v-model:tags="captureTags"
      mode="chips"
      :inherit="openList ? filterStoreId : null"
      :list-name="state.lists[0].name"
      @submit="onCapture"
      @open-picker="openPicker('tag')"
    />

    <PrototypeStorePickerSheet
      v-model:open="pickerOpen"
      title="Choose a Store"
      subtitle="A Store with no Location is legal here — taggable and Pickable, and nothing suggests it."
      :ask-place="pickerIntent !== 'tag'"
      @pick="onPick"
      @create="onCreate"
    />

    <PrototypeItemSheet v-model:open="itemSheetOpen" :item-id="openedItemId" />

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
