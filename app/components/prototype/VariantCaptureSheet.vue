<script setup lang="ts">
/**
 * PROTOTYPE ONLY (wayfinder #13) — Variant A: "Capture sheet".
 * Item-first. Every act is its own sheet. Store Tags are checkboxes on the
 * capture sheet; the Tag offer at Buy is one prompt row per untagged Item.
 */
const {
  state,
  storesNamed,
  itemsNamed,
  categoriesInUse,
  storeById,
  captureItem,
  tagItem,
  untagItem,
  createStore,
  joinStoreLocation,
  setGeofence,
  basket,
  buy,
} = usePrototypeHousehold();
const position = usePrototypePosition();

const tab = ref<"capture" | "basket" | "stores">("capture");

// ---- capture sheet -------------------------------------------------------
const name = ref("");
const category = ref("");
const quantity = ref("");
const pickedStoreIds = ref<string[]>([]);
const gate = computed(
  () =>
    pickedStoreIds.value.length === 0 &&
    "No Store Tags — this Item won't appear in anyone's Kinetic View, at any store."
);
const joinedItem = computed(() => (name.value ? itemsNamed(name.value)[0] ?? null : null));

const captured = ref<null | { text: string }>(null);

function capture() {
  const r = captureItem({
    name: name.value,
    category: category.value,
    quantity: quantity.value,
    storeTags: pickedStoreIds.value,
  });
  captured.value = {
    text: r.joined
      ? `"${r.item.name}" was already in the catalogue — capture joined it, now ${r.item.storeTags.length} Store Tag(s).`
      : `Captured "${r.item.name}" into ${state.value.lists[0].name} with ${r.item.storeTags.length} Store Tag(s).`,
  };
  name.value = "";
  category.value = "";
  quantity.value = "";
  pickedStoreIds.value = [];
}

function toggleTag(storeId: string) {
  pickedStoreIds.value = pickedStoreIds.value.includes(storeId)
    ? pickedStoreIds.value.filter((s) => s !== storeId)
    : [...pickedStoreIds.value, storeId];
}

// ---- add store from the capture sheet -----------------------------------
const addingStore = ref(false);
const newStoreName = ref("");
const newStoreLabel = ref("");
const newStoreLat = ref("");
const newStoreLng = ref("");

const nameJoinTargets = computed(() => storesNamed(newStoreName.value));
const typedCoords = computed(() => ({
  lat: Number(newStoreLat.value),
  lng: Number(newStoreLng.value),
  ok:
    newStoreLat.value !== "" &&
    newStoreLng.value !== "" &&
    !Number.isNaN(Number(newStoreLat.value)) &&
    !Number.isNaN(Number(newStoreLng.value)),
}));

function usePositionForNewStore() {
  position.read();
  if (position.coords.value) {
    newStoreLat.value = position.coords.value.lat.toFixed(5);
    newStoreLng.value = position.coords.value.lng.toFixed(5);
  }
}

watch(
  () => position.coords.value,
  (c) => {
    if (!c || !addingStore.value) return;
    newStoreLat.value = c.lat.toFixed(5);
    newStoreLng.value = c.lng.toFixed(5);
  }
);

function createStoreRow() {
  const store = createStore(newStoreName.value, typedCoords.value.lat, typedCoords.value.lng);
  if (newStoreLabel.value) {
    const loc = store.locations[0];
    if (loc) loc.label = newStoreLabel.value;
  }
  pickedStoreIds.value = [...pickedStoreIds.value, store.id];
  addingStore.value = false;
  newStoreName.value = "";
  newStoreLabel.value = "";
  newStoreLat.value = "";
  newStoreLng.value = "";
}

function joinExistingStore(storeId: string) {
  const loc = joinStoreLocation(
    storeId,
    newStoreLabel.value,
    typedCoords.value.lat,
    typedCoords.value.lng
  );
  if (loc) pickedStoreIds.value = [...pickedStoreIds.value, storeId];
  addingStore.value = false;
  newStoreName.value = "";
  newStoreLabel.value = "";
  newStoreLat.value = "";
  newStoreLng.value = "";
}

// ---- basket / Buy ------------------------------------------------------
const buyStoreId = ref("s_walmart");
const buyLocationId = ref("l_walmart_main");
const rows = computed(() => basket());
const result = ref<null | {
  storeName: string;
  locationLabel: string;
  count: number;
  untagged: { itemId: string; itemName: string }[];
}>(null);
const skips = ref<string[]>([]);

function doBuy() {
  const r = buy(buyStoreId.value, buyLocationId.value);
  if (!r) return;
  result.value = {
    storeName: storeById(r.purchase.storeId)?.name ?? "",
    locationLabel: r.purchase.lines[0]?.locationLabel ?? "",
    count: r.purchase.lines.length,
    untagged: r.untagged.map((u) => ({
      itemId: u.item.id,
      itemName: u.item.name,
    })),
  };
  tab.value = "basket";
}

function tagOne(itemId: string) {
  tagItem(itemId, buyStoreId.value);
  if (result.value)
    result.value.untagged = result.value.untagged.filter(
      (u) => u.itemId !== itemId
    );
}

function skipOne(itemId: string) {
  skips.value = [...skips.value, itemId];
  if (result.value)
    result.value.untagged = result.value.untagged.filter(
      (u) => u.itemId !== itemId
    );
}
</script>

<template>
  <div class="variant">
    <header class="head">
      <h2>{{ state.household.name }}</h2>
      <p class="sub">
        Members {{ state.household.members.join(", ") }} · you are
        {{ state.me }}
      </p>
      <nav class="tabs">
        <button :class="{ on: tab === 'capture' }" @click="tab = 'capture'">
          Capture
        </button>
        <button :class="{ on: tab === 'basket' }" @click="tab = 'basket'">
          Basket ({{ rows.length }})
        </button>
        <button :class="{ on: tab === 'stores' }" @click="tab = 'stores'">
          Where you shop
        </button>
      </nav>
    </header>

    <!-- ============ Capture sheet ============ -->
    <section v-if="tab === 'capture'" class="sheet">
      <p class="hint">
        One sheet per act. Store Tags are part of capture, and optional.
      </p>
      <p v-if="captured" class="flash">{{ captured.text }}</p>

      <label>
        Name
        <input v-model="name" placeholder="Spinach" />
        <span v-if="joinedItem" class="join">
          already in the catalogue as "{{ joinedItem.name }}" — capture joins it
        </span>
      </label>

      <label>
        Category
        <input v-model="category" placeholder="Produce" />
        <span class="chips">
          <button
            v-for="c in categoriesInUse()"
            :key="c"
            class="chip"
            @click="category = c"
          >
            {{ c }}
          </button>
        </span>
      </label>

      <label>
        Quantity
        <input v-model="quantity" placeholder="1 bag" />
      </label>

      <div class="tags">
        <p class="tagshead">
          Store Tags
          <span class="optional">optional</span>
        </p>
        <label v-for="s in state.stores" :key="s.id" class="tagrow">
          <input
            type="checkbox"
            :checked="pickedStoreIds.includes(s.id)"
            @change="toggleTag(s.id)"
          />
          <span class="name">{{ s.name }}</span>
          <span class="locs">
            {{ s.locations.length ? `${s.locations.length} Location(s)` : "no Locations" }}
          </span>
        </label>
        <button class="addstore" @click="addingStore = !addingStore">
          {{ addingStore ? "Close" : "+ Add store from where I am now" }}
        </button>

        <div v-if="addingStore" class="newstore">
          <label>
            Store name
            <input v-model="newStoreName" placeholder="walmart" />
          </label>
          <p v-if="position.status === 'ok'" class="posread">
            Position: {{ position.label }}
          </p>
          <label>
            Place label
            <input v-model="newStoreLabel" placeholder="Central St" />
          </label>
          <div class="latlng">
            <label>
              lat
              <input v-model="newStoreLat" placeholder="42.10154" />
            </label>
            <label>
              lng
              <input v-model="newStoreLng" placeholder="-72.5811" />
            </label>
            <button @click="usePositionForNewStore">
              {{ position.status === "reading" ? "reading…" : "Use where I am now" }}
            </button>
          </div>

          <!-- name-join confirmation: an offer, not a forced normalize -->
          <div v-if="nameJoinTargets.length && typedCoords.ok" class="joinoffer">
            <p>
              <b>{{ nameJoinTargets[0].name }}</b> already has
              {{ nameJoinTargets[0].locations.length }} Location(s). What do you
              mean?
            </p>
            <button
              class="primary"
              @click="joinExistingStore(nameJoinTargets[0].id)"
            >
              Add this as a new Location to {{ nameJoinTargets[0].name }}
            </button>
            <button @click="createStoreRow">
              Name it "{{ newStoreName }}" as its own Store
            </button>
          </div>
          <button v-else-if="typedCoords.ok" class="primary" @click="createStoreRow">
            Create "{{ newStoreName || 'Unnamed store' }}"
          </button>
          <p v-else class="hint2">
            Coordinates required: read a Position, or type lat/lng for a place
            you haven't visited.
          </p>
        </div>

        <p v-if="gate" class="gate">{{ gate }}</p>
      </div>

      <button class="primary big" @click="capture">Capture</button>
    </section>

    <!-- ============ Basket / Buy ============ -->
    <section v-if="tab === 'basket'" class="sheet">
      <p class="hint">
        Buy names a Store <i>and</i> a Location. Tag prompts come one per
        untagged Item, after the Purchase is recorded.
      </p>

      <div class="buybar">
        <label>
          Store
          <select v-model="buyStoreId">
            <option v-for="s in state.stores" :key="s.id" :value="s.id">
              {{ s.name }}
            </option>
          </select>
        </label>
        <label>
          Standing at
          <select v-model="buyLocationId">
            <option
              v-for="l in storeById(buyStoreId)?.locations ?? []"
              :key="l.id"
              :value="l.id"
            >
              {{ l.label }}
            </option>
            <option value="">(no Location)</option>
          </select>
        </label>
        <button class="primary" :disabled="!rows.length" @click="doBuy">
          Buy {{ rows.length }}
        </button>
      </div>

      <ul class="basket">
        <li v-for="r in rows" :key="r.listItemId">
          <span class="itemname">{{ r.item.name }}</span>
          <span class="meta">{{ r.listName }} · {{ r.item.quantity }}</span>
          <span class="tagrow2">
            <button
              v-for="t in r.item.storeTags"
              :key="t"
              class="chip removable"
              @click="untagItem(r.item.id, t)"
            >
              {{ storeById(t)?.name }} ×
            </button>
            <span v-if="!r.item.storeTags.length" class="notags">no Store Tags</span>
          </span>
        </li>
      </ul>

      <div v-if="result" class="confirmation">
        <p class="done">
          Purchase recorded · {{ result.count }} line(s) at
          {{ result.storeName }} ({{ result.locationLabel }}) ·
          every line is now Stocked.
        </p>
        <div v-if="result.untagged.length" class="tagoffer">
          <p class="offerhead">
            Tag — these {{ result.untagged.length }} bought Item(s) carry no tag
            for {{ result.storeName }}:
          </p>
          <div v-for="u in result.untagged" :key="u.itemId" class="offerrow">
            <span>{{ u.itemName }}</span>
            <span>
              <button class="primary" @click="tagOne(u.itemId)">
                Tag at {{ storeById(buyStoreId)?.name }}
              </button>
              <button @click="skipOne(u.itemId)">Skip</button>
            </span>
          </div>
        </div>
        <p v-else class="hint2">Nothing to Tag — every bought Item was already tagged here.</p>
        <p v-if="skips.length" class="hint2">
          Skipped {{ skips.length }} — their tags were left exactly as they were.
        </p>
      </div>
    </section>

    <!-- ============ Where you shop ============ -->
    <section v-if="tab === 'stores'" class="sheet">
      <p class="hint">
        A Store is a tag namespace; its Locations carry the coordinates.
      </p>
      <div v-for="s in state.stores" :key="s.id" class="storecard">
        <p class="storename">
          {{ s.name }}
        </p>
        <ul>
          <li v-for="l in s.locations" :key="l.id">
            {{ l.label }} · {{ l.lat.toFixed(4) }}, {{ l.lng.toFixed(4) }} ·
            <label>
              Geofence
              <input
                type="number"
                :value="l.geofence"
                style="width: 4.5rem"
                @change="setGeofence(l.id, Number(($event.target as HTMLInputElement).value))"
              />
              m
            </label>
          </li>
          <li v-if="!s.locations.length" class="bare">
            no Locations — taggable and Pickable, nothing suggests it
          </li>
        </ul>
      </div>
    </section>
  </div>
</template>

<style scoped>
.variant {
  max-width: 30rem;
  margin: 0 auto;
  padding: 1rem 1rem 6rem;
  font: 15px/1.45 system-ui, sans-serif;
  color: #111827;
}
.head h2 {
  margin: 0;
  font-size: 1.3rem;
}
.sub {
  color: #6b7280;
  margin: 0.2rem 0 0.8rem;
  font-size: 0.85rem;
}
.tabs {
  display: flex;
  gap: 0.4rem;
  border-bottom: 1px solid #e5e7eb;
  margin-bottom: 1rem;
}
.tabs button {
  border: 0;
  background: transparent;
  padding: 0.5rem 0.7rem;
  cursor: pointer;
  font: inherit;
  color: #6b7280;
}
.tabs button.on {
  color: #111827;
  border-bottom: 2px solid #111827;
  font-weight: 600;
}
.sheet {
  border: 1px solid #e5e7eb;
  border-radius: 0.75rem;
  padding: 1rem;
  background: #fff;
}
.hint,
.hint2 {
  color: #6b7280;
  font-size: 0.82rem;
  margin: 0 0 0.8rem;
}
.flash {
  background: #ecfdf5;
  border: 1px solid #a7f3d0;
  padding: 0.5rem 0.7rem;
  border-radius: 0.5rem;
  font-size: 0.85rem;
  margin: 0 0 0.8rem;
}
label {
  display: block;
  margin: 0.6rem 0;
  font-size: 0.8rem;
  color: #374151;
  font-weight: 600;
}
input,
select {
  display: block;
  width: 100%;
  margin-top: 0.25rem;
  padding: 0.45rem 0.55rem;
  border: 1px solid #d1d5db;
  border-radius: 0.4rem;
  font: inherit;
  font-weight: 400;
}
.join {
  color: #1d4ed8;
  font-weight: 400;
  font-size: 0.78rem;
}
.chips {
  display: flex;
  gap: 0.3rem;
  flex-wrap: wrap;
  margin-top: 0.35rem;
}
.chip {
  border: 1px solid #d1d5db;
  background: #f9fafb;
  border-radius: 999px;
  padding: 0.2rem 0.6rem;
  font: 500 12px/1.4 system-ui, sans-serif;
  cursor: pointer;
}
.chip.removable {
  background: #eef2ff;
  border-color: #c7d2fe;
}
.tags {
  border-top: 1px dashed #e5e7eb;
  margin-top: 1rem;
  padding-top: 0.6rem;
}
.tagshead {
  font-weight: 700;
  font-size: 0.85rem;
  margin: 0 0 0.4rem;
}
.optional {
  color: #9ca3af;
  font-weight: 400;
  font-size: 0.75rem;
  margin-left: 0.4rem;
}
.tagrow {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-weight: 400;
  font-size: 0.9rem;
  margin: 0.3rem 0;
}
.tagrow input {
  width: auto;
  margin: 0;
}
.tagrow .name {
  font-weight: 600;
}
.tagrow .locs {
  color: #9ca3af;
  font-size: 0.75rem;
}
.gate {
  background: #fef2f2;
  border: 1px solid #fecaca;
  color: #b91c1c;
  border-radius: 0.5rem;
  padding: 0.5rem 0.7rem;
  font-size: 0.8rem;
  margin: 0.8rem 0 0;
}
.addstore,
.newstore button,
button {
  border: 1px solid #d1d5db;
  background: #fff;
  border-radius: 0.45rem;
  padding: 0.4rem 0.7rem;
  font: inherit;
  cursor: pointer;
}
button.primary {
  background: #111827;
  border-color: #111827;
  color: #fff;
}
button.big {
  margin-top: 1rem;
  width: 100%;
  padding: 0.7rem;
  font-weight: 600;
}
.newstore {
  border: 1px solid #e5e7eb;
  background: #f9fafb;
  border-radius: 0.5rem;
  padding: 0.7rem;
  margin-top: 0.5rem;
}
.latlng {
  display: flex;
  gap: 0.5rem;
  align-items: flex-end;
}
.latlng label {
  flex: 1;
}
.posread {
  font-size: 0.78rem;
  color: #1d4ed8;
}
.joinoffer {
  border: 1px solid #fcd34d;
  background: #fffbeb;
  border-radius: 0.5rem;
  padding: 0.6rem;
  margin-top: 0.5rem;
  font-size: 0.82rem;
}
.joinoffer p {
  margin: 0 0 0.5rem;
}
.buybar {
  display: flex;
  gap: 0.5rem;
  align-items: flex-end;
  flex-wrap: wrap;
  margin-bottom: 0.8rem;
}
.buybar label {
  flex: 1;
  margin: 0;
}
.basket {
  list-style: none;
  padding: 0;
  margin: 0;
}
.basket li {
  border-bottom: 1px solid #f3f4f6;
  padding: 0.5rem 0;
}
.itemname {
  font-weight: 600;
}
.meta {
  color: #9ca3af;
  font-size: 0.78rem;
  margin-left: 0.4rem;
}
.tagrow2 {
  display: flex;
  gap: 0.3rem;
  flex-wrap: wrap;
  margin-top: 0.3rem;
}
.notags {
  color: #b91c1c;
  font-size: 0.78rem;
}
.confirmation {
  margin-top: 1rem;
  border: 1px solid #a7f3d0;
  background: #f0fdf4;
  border-radius: 0.6rem;
  padding: 0.7rem;
}
.done {
  margin: 0 0 0.6rem;
  font-size: 0.85rem;
  font-weight: 600;
}
.offerhead {
  font-size: 0.82rem;
  margin: 0 0 0.4rem;
}
.offerrow {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 0.5rem;
  font-size: 0.85rem;
  border-top: 1px solid #d1fae5;
  padding: 0.35rem 0;
}
.storecard {
  border: 1px solid #e5e7eb;
  border-radius: 0.5rem;
  padding: 0.6rem;
  margin-bottom: 0.6rem;
}
.storename {
  font-weight: 700;
  margin: 0 0 0.3rem;
}
.storecard ul {
  margin: 0;
  padding-left: 1rem;
  font-size: 0.82rem;
  color: #374151;
}
.storecard li {
  margin: 0.25rem 0;
}
.bare {
  color: #9ca3af;
}
</style>
