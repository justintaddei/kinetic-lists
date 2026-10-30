<script setup lang="ts">
/**
 * PROTOTYPE ONLY — wayfinder #13, round 2, variant F "the Store owns its Tags".
 * The header picks the Active Store with a plain Select (no sheet), the Kinetic
 * rows are read-only, and Tags are authored from the Store's own screen: a
 * Store lists the Items you buy there, and the Remove Tag act lives beside the
 * Store, not beside the row. Capture is minimal: three fields and one "Buy at"
 * control.
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
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
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
  tagItem,
  untagItem,
  addLocation,
  setGeofence,
} = usePrototypeHousehold();

const tabs = [
  { key: "kinetic", label: "Kinetic View" },
  { key: "stores", label: "Stores" },
  { key: "basket", label: "Basket" },
  { key: "household", label: "Household" },
];
const tab = ref("kinetic");
const openStoreId = ref<string | null>(null);

const captureOpen = ref(false);
const captureTags = ref<string[]>([]);
const pickerOpen = ref(false);
const pickerIntent = ref<"tag" | "buy">("tag");
const buyStoreId = ref("s_walmart");
const buyLocationId = ref("l_walmart_main");
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
const newLocation = ref<{ label: string; lat: number | null; lng: number | null } | null>(null);
const toTagItemId = ref("i_spinach");
const lastBuy = ref<{ lines: number; untagged: string[]; store: string; place: string } | null>(null);
const toast = ref("");

const active = computed(() => storeById(state.value.pickedStoreId));
const kinetic = computed(() => (active.value ? kineticView(active.value.id) : []));
const openStore = computed(
  () => state.value.stores.find((s) => s.id === openStoreId.value) ?? null
);
const rows = computed(() => basket());
const invisibleAtBuy = computed(() =>
  rows.value.filter((r) => !r.item.storeTags.includes(buyStoreId.value))
);
const grouped = computed(() =>
  state.value.stores.map((store) => ({
    store,
    tagged: state.value.items.filter((i) => i.storeTags.includes(store.id)),
    untaggedInBasket: rows.value.filter((r) => !r.item.storeTags.includes(store.id)),
  }))
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

function openPicker(intent: "tag" | "buy") {
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
    buyStoreId.value = storeId;
    buyLocationId.value = store?.locations[0]?.id ?? "none";
    pick(storeId);
    say(`Buying at ${store?.name}`);
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
  else {
    buyStoreId.value = store.id;
    pick(store.id);
  }
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
    else {
      buyStoreId.value = store.id;
      pick(store.id);
    }
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
  say(
    `Captured "${item.name}" (${joined ? "joined the existing Item" : "new Item"})${
      payload.tags.length
        ? ` · ${payload.tags.length} Store Tag(s)`
        : " · no Store Tag"
    }`
  );
}

function tagHere(storeId: string) {
  tagItem(toTagItemId.value, storeId);
  const name = state.value.items.find((i) => i.id === toTagItemId.value)?.name;
  say(`Tagged "${name}" at ${storeById(storeId)?.name} — from the Store's screen`);
}

function addLocationHere() {
  if (!openStore.value || !newLocation.value) return;
  addLocation(
    openStore.value.id,
    newLocation.value.label || "New place",
    newLocation.value.lat ?? 42.10154,
    newLocation.value.lng ?? -72.5811
  );
  newLocation.value = null;
  say("Location added from your Position");
}

function doBuy() {
  const store = storeById(buyStoreId.value);
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
    capture-label="+ Capture"
    @update:active="tab = $event"
    @capture="captureOpen = true"
  >
    <template #header>
      <div class="flex items-center gap-2">
        <div class="flex-1">
          <p class="text-[11px] uppercase text-muted-foreground">
            Where are you? Pick the Active Store
          </p>
          <Select
            :model-value="state.pickedStoreId ?? ''"
            @update:model-value="
              (v: string) => {
                pick(v);
                const store = storeById(v);
                if (store)
                  buyLocationId = store.locations[0]?.id ?? 'none';
              }
            "
          >
            <SelectTrigger>
              <SelectValue placeholder="Pick a Store" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem v-for="s in state.stores" :key="s.id" :value="s.id">
                {{ s.name }}
                {{ s.locations.length ? `${s.locations.length} place(s)` : "bare Store" }}
              </SelectItem>
            </SelectContent>
          </Select>
        </div>
      </div>
      <p
        v-if="arrival"
        class="mt-2 rounded-md bg-muted px-3 py-2 text-xs"
      >
        {{ arrival.member }} is at {{ arrival.store.name }} ·
        {{ arrival.place.label }} ({{ arrival.at }})
        <button
          class="font-medium text-primary"
          @click="
            pick(arrival.store.id);
            buyLocationId = arrival.place.id;
          "
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

    <!-- Kinetic View: read-only rows, authoring lives on the Store screen -->
    <section v-if="tab === 'kinetic'" class="space-y-3">
      <h3 class="text-sm font-semibold">
        Kinetic View · Needed at {{ active?.name ?? "—" }}, cross-List
      </h3>

      <Empty v-if="!kinetic.length">
        <EmptyHeader>
          <EmptyTitle>Nothing Needed here</EmptyTitle>
          <EmptyDescription>
            Only Needed rows carrying this Store's Tag appear. Tag them from a
            Store screen.
          </EmptyDescription>
        </EmptyHeader>
        <EmptyContent>
          <Button size="sm" variant="outline" @click="tab = 'stores'">
            Go to Stores
          </Button>
        </EmptyContent>
      </Empty>

      <ul v-else class="space-y-2">
        <li
          v-for="row in kinetic"
          :key="row.item.id + row.listName"
          class="flex items-center justify-between gap-3 rounded-lg border p-3"
        >
          <button class="text-left" @click="openedItemId = row.item.id">
            <span class="block text-sm font-medium">{{ row.item.name }}</span>
            <span class="block text-xs text-muted-foreground">
              {{ row.item.quantity }} · {{ row.listName }}
            </span>
          </button>
          <button
            class="shrink-0 text-xs font-medium text-muted-foreground"
            @click="tab = 'stores'"
          >
            manage Tags
          </button>
        </li>
      </ul>

      <p
        v-if="arrival && active && arrival.store.id !== active.id"
        class="text-xs text-muted-foreground"
      >
        Nothing here says where you are standing — the Kinetic View is the
        Store's list, not a map of your Position.
      </p>
    </section>

    <!-- Stores: the Tag namespace, authored from the Store side -->
    <section v-if="tab === 'stores'" class="space-y-3">
      <template v-if="!openStore">
        <Card
          v-for="store in state.stores"
          :key="store.id"
          class="cursor-pointer"
          @click="openStoreId = store.id"
        >
          <CardHeader>
            <CardTitle class="text-base">{{ store.name }}</CardTitle>
          </CardHeader>
          <CardContent class="text-xs text-muted-foreground">
            {{
              store.locations.length
                ? `${store.locations.length} Location(s)`
                : "bare Store — nothing suggests it, Pick it by name"
            }}
            · {{ state.items.filter((i) => i.storeTags.includes(store.id)).length }}
            Item(s) tagged here
          </CardContent>
        </Card>
        <p class="text-xs text-muted-foreground">
          Tap a Store: its Locations, its Geofences, and the Items you buy
          there.
        </p>
      </template>

      <template v-else>
        <Button size="sm" variant="outline" @click="openStoreId = null">
          ‹ Stores
        </Button>

        <p
          v-if="!openStore.locations.length"
          class="rounded-md bg-muted px-3 py-2 text-xs text-muted-foreground"
        >
          A bare Store: taggable, Pickable, and no Position will ever suggest
          it. Buy at it by naming it.
        </p>

        <div class="space-y-2">
          <p class="text-xs font-medium uppercase text-muted-foreground">
            Locations · Geofence is one shared judgement
          </p>
          <div
            v-for="location in openStore.locations"
            :key="location.id"
            class="flex items-center justify-between gap-2 text-sm"
          >
            <span>
              {{ location.label }}
              <span class="block text-xs text-muted-foreground">
                {{ location.lat.toFixed(5) }}, {{ location.lng.toFixed(5) }}
              </span>
            </span>
            <Label class="flex items-center gap-2 text-xs text-muted-foreground">
              <Input
                type="number"
                class="h-8 w-20"
                :model-value="String(location.geofence)"
                @update:model-value="setGeofence(location.id, Number($event))"
              />
              m
            </Label>
          </div>
          <Button
            size="sm"
            variant="outline"
            @click="newLocation = { label: '', lat: null, lng: null }"
          >
            + Location from where I am
          </Button>
        </div>

        <div class="space-y-2">
          <p class="text-xs font-medium uppercase text-muted-foreground">
            Items you buy here
          </p>
          <p
            v-if="!openStore.locations.length && !grouped.find((g) => g.store.id === openStore?.id)?.tagged.length"
            class="text-xs text-muted-foreground"
          >
            Nothing is tagged here yet.
          </p>
          <div
            v-for="item in grouped.find((g) => g.store.id === openStore?.id)?.tagged ?? []"
            :key="item.id"
            class="flex items-center justify-between gap-2 text-sm"
          >
            <span>{{ item.name }}</span>
            <button
              class="text-xs font-medium text-destructive"
              @click="untagItem(item.id, openStore!.id)"
            >
              Remove Tag
            </button>
          </div>
        </div>

        <div class="space-y-2 rounded-lg border p-3">
          <p class="text-xs font-medium uppercase text-muted-foreground">
            Tag an Item with {{ openStore.name }}
          </p>
          <Select v-model="toTagItemId">
            <SelectTrigger>
              <SelectValue placeholder="Which Item?" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem
                v-for="item in state.items.filter(
                  (i) => !i.storeTags.includes(openStore!.id)
                )"
                :key="item.id"
                :value="item.id"
              >
                {{ item.name }}
              </SelectItem>
            </SelectContent>
          </Select>
          <Button size="sm" class="w-full" @click="tagHere(openStore.id)">
            Tag it at {{ openStore.name }}
          </Button>
        </div>

        <Card v-if="newLocation">
          <CardHeader>
            <CardTitle class="text-base">New Location</CardTitle>
          </CardHeader>
          <CardContent class="space-y-3">
            <Input
              :model-value="newLocation.label"
              placeholder="Broker Rd"
              @update:model-value="newLocation && (newLocation.label = String($event))"
            />
            <PrototypePositionRow
              :lat="newLocation.lat"
              :lng="newLocation.lng"
              @update:lat="newLocation && (newLocation.lat = $event)"
              @update:lng="newLocation && (newLocation.lng = $event)"
            />
            <div class="flex gap-2">
              <Button class="flex-1" @click="addLocationHere">Add Location</Button>
              <Button variant="outline" @click="newLocation = null">
                Cancel
              </Button>
            </div>
          </CardContent>
        </Card>
      </template>
    </section>

    <!-- Basket -->
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
            class="shrink-0 text-xs font-medium text-primary"
            @click="tab = 'stores'"
          >
            Tag at a Store
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
              v-for="location in storeById(buyStoreId)?.locations ?? []"
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
        {{ invisibleAtBuy.length }} of {{ rows.length }} carry no Tag for
        {{ storeById(buyStoreId)?.name }}:
        {{ invisibleAtBuy.map((r) => r.item.name).join(", ") }}
      </p>

      <Button class="w-full" :disabled="!rows.length" @click="doBuy">
        Buy {{ rows.length }} at {{ storeById(buyStoreId)?.name ?? "—" }}
      </Button>

      <Card v-if="lastBuy">
        <CardHeader>
          <CardTitle class="text-base">Purchase recorded</CardTitle>
        </CardHeader>
        <CardContent class="space-y-2 text-sm">
          <p class="text-xs text-muted-foreground">
            {{ lastBuy.lines }} line(s) at {{ lastBuy.store }} ({{ lastBuy.place
            }}) · every line is now Stocked. Buy writes no Tag, and asks for
            none.
          </p>
          <p v-if="lastBuy.untagged.length" class="text-xs text-muted-foreground">
            No Tag for {{ lastBuy.store }}: {{ lastBuy.untagged.join(", ") }}.
          </p>
        </CardContent>
      </Card>

      <div v-for="group in grouped" :key="group.store.id" class="text-xs text-muted-foreground">
        {{ group.store.name }}: {{ group.tagged.length }} Item(s) tagged ·
        {{ group.untaggedInBasket.length }} Basket Item(s) invisible there
      </div>
    </section>

    <PrototypeHouseholdPanel v-if="tab === 'household'" />

    <PrototypeCaptureSheet
      v-model:open="captureOpen"
      v-model:tags="captureTags"
      mode="picker"
      :inherit="null"
      :list-name="state.lists[0].name"
      @submit="onCapture"
      @open-picker="openPicker('tag')"
    />

    <PrototypeStorePickerSheet
      v-model:open="pickerOpen"
      title="Tag with a Store"
      subtitle="A Store with no Location is legal here — taggable and Pickable, and nothing suggests it."
      :ask-place="pickerIntent === 'buy'"
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
