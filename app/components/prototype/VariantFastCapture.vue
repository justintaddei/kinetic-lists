<script setup lang="ts">
/**
 * PROTOTYPE ONLY (wayfinder #13) — Variant B: "Fast capture, one bulk Tag at Buy".
 * Capture has NO Store fields at all. Tags live on a per-Item drawer, and the
 * Tag offer is a single bulk prompt naming every untagged Item after the Buy.
 */
const {
  state,
  storesNamed,
  categoriesInUse,
  storeById,
  itemById,
  captureItem,
  tagItem,
  untagItem,
  createStore,
  joinStoreLocation,
  addLocation,
  setGeofence,
  basket,
  buy,
  kineticView,
} = usePrototypeHousehold();
const position = usePrototypePosition();

// ---- capture: one row, three fields, no stores --------------------------
const name = ref("");
const category = ref("");
const quantity = ref("");
const last = ref("");

function capture() {
  const r = captureItem({
    name: name.value,
    category: category.value,
    quantity: quantity.value,
  });
  last.value = r.joined
    ? `"${r.item.name}" joined the catalogue (no tags added)`
    : `Captured "${r.item.name}" — 0 Store Tags`;
  name.value = "";
  category.value = "";
  quantity.value = "";
}

// ---- per-Item drawer ---------------------------------------------------
const drawerItemId = ref<string | null>(null);
const drawer = computed(() => (drawerItemId.value ? itemById(drawerItemId.value) : null));
const addStoreName = ref("");
const addStoreLat = ref("");
const addStoreLng = ref("");
const addLabel = ref("");

const joinTargets = computed(() => storesNamed(addStoreName.value));
const coords = computed(() => {
  const lat = Number(addStoreLat.value);
  const lng = Number(addStoreLng.value);
  const ok = addStoreLat.value !== "" && addStoreLng.value !== "" && !Number.isNaN(lat) && !Number.isNaN(lng);
  return { lat, lng, ok };
});

function usePosition() {
  position.read();
}
watch(
  () => position.coords.value,
  (c) => {
    if (!c || !drawerItemId.value) return;
    addStoreLat.value = c.lat.toFixed(5);
    addStoreLng.value = c.lng.toFixed(5);
  }
);

function confirmAdd(storeId: string) {
  if (drawerItemId.value) tagItem(drawerItemId.value, storeId);
  addStoreName.value = "";
  addStoreLat.value = "";
  addStoreLng.value = "";
  addLabel.value = "";
}

function joinStore(storeId: string) {
  joinStoreLocation(storeId, addLabel.value, coords.value.lat, coords.value.lng);
  confirmAdd(storeId);
}

function newStore() {
  const s = createStore(addStoreName.value, coords.value.lat, coords.value.lng);
  confirmAdd(s.id);
}

// ---- Buy: choose the Location you're standing at, then one bulk prompt --
const buyStoreId = ref("s_walmart");
const standingAt = ref<string | null>("l_walmart_main");
const rows = computed(() => basket());
const offer = ref<null | {
  storeId: string;
  storeName: string;
  locationLabel: string;
  lines: number;
  items: { itemId: string; itemName: string; picked: boolean }[];
}>(null);
const checked = ref<Set<string>>(new Set());

function chooseLocation(id: string | null) {
  standingAt.value = id;
}

function doBuy() {
  const r = buy(buyStoreId.value, standingAt.value);
  if (!r) return;
  offer.value = {
    storeId: r.purchase.storeId,
    storeName: storeById(r.purchase.storeId)?.name ?? "",
    locationLabel: r.purchase.lines[0]?.locationLabel ?? "(no Location)",
    lines: r.purchase.lines.length,
    items: r.untagged.map((u) => ({
      itemId: u.item.id,
      itemName: u.item.name,
      picked: true,
    })),
  };
  checked.value = new Set(offer.value.items.map((i) => i.itemId));
}

function toggle(itemId: string) {
  const s = new Set(checked.value);
  if (s.has(itemId)) s.delete(itemId);
  else s.add(itemId);
  checked.value = s;
}

function applyBulkTag() {
  if (!offer.value) return;
  for (const itemId of checked.value) tagItem(itemId, offer.value.storeId);
  offer.value = { ...offer.value, items: [] };
}

const tagsOf = (itemId: string) =>
  (itemById(itemId)?.storeTags ?? []).map((s) => storeById(s)?.name ?? s);
</script>

<template>
  <div class="variant">
    <header class="head">
      <div>
        <h2>{{ state.household.name }}</h2>
        <p class="sub">Members {{ state.household.members.join(", ") }}</p>
      </div>
      <p class="kinetic">
        Kinetic View at {{ storeById(buyStoreId)?.name }}:
        {{ kineticView(buyStoreId).map((r) => r.item.name).join(", ") || "empty" }}
      </p>
    </header>

    <div class="cols">
      <!-- ============ left: fast capture + catalogue ============ -->
      <section>
        <form class="fast" @submit.prevent="capture">
          <input v-model="name" placeholder="Add an Item by name…" />
          <input v-model="category" list="cats" placeholder="Category" />
          <datalist id="cats">
            <option v-for="c in categoriesInUse()" :key="c" :value="c" />
          </datalist>
          <input v-model="quantity" placeholder='"2 L"' />
          <button class="primary" type="submit">Capture</button>
        </form>
        <p v-if="last" class="last">{{ last }}</p>
        <p class="note">
          Capture carries no Store at all. Tags arrive at <b>Buy</b>, or later
          from the Item.
        </p>

        <table class="catalogue">
          <thead>
            <tr>
              <th>Item</th>
              <th>Category</th>
              <th>Qty</th>
              <th>Stores</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="i in state.items" :key="i.id">
              <td>
                <button class="link" @click="drawerItemId = i.id">
                  {{ i.name }}
                </button>
              </td>
              <td>{{ i.category }}</td>
              <td>{{ i.quantity }}</td>
              <td>
                <span v-if="i.storeTags.length" class="counts">
                  {{ i.storeTags.length }} · {{ tagsOf(i.id).join(" / ") }}
                </span>
                <span v-else class="zero">0</span>
              </td>
            </tr>
          </tbody>
        </table>
      </section>

      <!-- ============ right: basket + Buy + bulk Tag ============ -->
      <section>
        <h3 class="colhead">Basket · {{ rows.length }}</h3>
        <ul class="basket">
          <li v-for="r in rows" :key="r.listItemId">
            <span>{{ r.item.name }}</span>
            <span class="muted">{{ r.listName }}</span>
          </li>
          <li v-if="!rows.length" class="muted">Basket is empty</li>
        </ul>

        <div class="atbar">
          <p class="label">Buying at</p>
          <div class="rowchips">
            <button
              v-for="s in state.stores"
              :key="s.id"
              :class="['chipbtn', { on: buyStoreId === s.id }]"
              @click="buyStoreId = s.id; standingAt = s.locations[0]?.id ?? null"
            >
              {{ s.name }}
            </button>
          </div>
          <p class="label">Standing at (this Store's Locations)</p>
          <div class="rowchips">
            <button
              v-for="l in storeById(buyStoreId)?.locations ?? []"
              :key="l.id"
              :class="['chipbtn', { on: standingAt === l.id }]"
              @click="chooseLocation(l.id)"
            >
              {{ l.label }}
            </button>
            <button :class="['chipbtn', { on: standingAt === null }]" @click="chooseLocation(null)">
              Somewhere new
            </button>
          </div>
          <div v-if="standingAt === null" class="newloc">
            <p class="label">
              A new Location for <b>{{ storeById(buyStoreId)?.name }}</b>
            </p>
            <div class="inline">
              <input v-model="addLabel" placeholder="place label" />
              <input v-model="addStoreLat" placeholder="lat" />
              <input v-model="addStoreLng" placeholder="lng" />
              <button @click="usePosition">
                {{ position.status === "reading" ? "reading…" : "Where I am" }}
              </button>
              <button
                class="primary"
                :disabled="!coords.ok"
                @click="
                  addLocation(buyStoreId, addLabel, coords.lat, coords.lng);
                  standingAt = state.stores.find((s) => s.id === buyStoreId)?.locations.slice(-1)[0]?.id ?? null;
                  addLabel = '';
                "
              >
                Add Location
              </button>
            </div>
            <p class="muted tiny">
              {{ position.label }} — typed lat/lng is the hatch for a place you
              have not visited.
            </p>
          </div>
          <button class="primary big" :disabled="!rows.length" @click="doBuy">
            Buy {{ rows.length }} at {{ storeById(buyStoreId)?.name }}
          </button>
        </div>

        <!-- one bulk prompt naming every untagged Item -->
        <div v-if="offer" class="bulk">
          <p class="bulkhead" v-if="offer.items.length">
            <b>{{ offer.items.length }}</b> of the {{ offer.lines }} bought
            Item(s) have no tag for <b>{{ offer.storeName }}</b>
            ({{ offer.locationLabel }}). Tag them?
          </p>
          <p v-else class="muted">Nothing to Tag — every bought Item was already tagged here.</p>
          <ul v-if="offer.items.length" class="bulklist">
            <li v-for="u in offer.items" :key="u.itemId">
              <label>
                <input
                  type="checkbox"
                  :checked="checked.has(u.itemId)"
                  @change="toggle(u.itemId)"
                />
                {{ u.itemName }}
              </label>
              <span class="muted existing">
                keeps {{ tagsOf(u.itemId).join(" / ") || "no tags" }}
              </span>
            </li>
          </ul>
          <button
            v-if="offer.items.length"
            class="primary"
            :disabled="!checked.size"
            @click="applyBulkTag"
          >
            Tag {{ checked.size }} at {{ offer.storeName }}
          </button>
        </div>

        <div v-if="state.purchases.length" class="history">
          <p class="label">Purchases (append-only)</p>
          <p v-for="p in state.purchases" :key="p.id" class="pur">
            {{ p.at }} · {{ p.lines.length }} line(s) ·
            {{ storeById(p.storeId)?.name }}
            <span class="muted">{{ p.lines[0]?.locationLabel }}</span>
          </p>
        </div>
      </section>
    </div>

    <!-- ============ per-Item drawer ============ -->
    <div v-if="drawer" class="scrim" @click.self="drawerItemId = null">
      <div class="drawer">
        <h3>{{ drawer.name }}</h3>
        <p class="muted">
          {{ drawer.category }} · {{ drawer.quantity }} · Item #{{ drawer.id }}
        </p>
        <p class="label">Store Tags</p>
        <ul class="taglist">
          <li v-for="t in drawer.storeTags" :key="t">
            <span>{{ storeById(t)?.name }}</span>
            <button @click="untagItem(drawer!.id, t)">Remove</button>
          </li>
          <li v-if="!drawer.storeTags.length" class="muted">
            none — this Item is invisible to every store's Kinetic View
          </li>
        </ul>
        <p class="label">Add a Store Tag</p>
        <div class="rowchips">
          <button
            v-for="s in state.stores"
            :key="s.id"
            class="chipbtn"
            :disabled="drawer.storeTags.includes(s.id)"
            @click="confirmAdd(s.id)"
          >
            {{ s.name }}
          </button>
        </div>
        <div class="newstore">
          <input v-model="addStoreName" placeholder="new store name" />
          <input v-model="addLabel" placeholder="place label" />
          <div class="inline">
            <input v-model="addStoreLat" placeholder="lat" />
            <input v-model="addStoreLng" placeholder="lng" />
            <button @click="usePosition">Where I am</button>
          </div>
          <p v-if="coords.ok && joinTargets.length" class="offer">
            <b>{{ joinTargets[0].name }}</b> exists with
            {{ joinTargets[0].locations.length }} Location(s).
            <button class="primary" @click="joinStore(joinTargets[0].id)">
              Add as a Location of {{ joinTargets[0].name }}
            </button>
            <button @click="newStore">Name it "{{ addStoreName }}" (separate)</button>
          </p>
          <button v-else-if="coords.ok" class="primary" @click="newStore">
            Create "{{ addStoreName || 'Unnamed store' }}"
          </button>
        </div>
        <button class="close" @click="drawerItemId = null">Close</button>
      </div>
    </div>

    <!-- ============ Location hygiene ============ -->
    <section class="hygiene">
      <p class="label">Where you shop · Geofence is one shared judgement per Location</p>
      <div class="hygienerows">
        <div v-for="s in state.stores" :key="s.id" class="hyg">
          <p class="sname">{{ s.name }}</p>
          <p v-for="l in s.locations" :key="l.id" class="lrow">
            {{ l.label }} ·
            <input
              type="number"
              :value="l.geofence"
              @change="setGeofence(l.id, Number(($event.target as HTMLInputElement).value))"
            />
            m
          </p>
          <p v-if="!s.locations.length" class="muted tiny">no Locations</p>
        </div>
      </div>
    </section>
  </div>
</template>

<style scoped>
.variant {
  max-width: 62rem;
  margin: 0 auto;
  padding: 1rem 1.25rem 7rem;
  font: 14px/1.4 system-ui, sans-serif;
  color: #111827;
}
.head {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  gap: 1rem;
  border-bottom: 2px solid #111827;
  padding-bottom: 0.5rem;
}
.head h2 {
  margin: 0;
  font-size: 1.15rem;
}
.sub,
.muted {
  color: #6b7280;
}
.kinetic {
  background: #eff6ff;
  border: 1px solid #bfdbfe;
  border-radius: 0.5rem;
  padding: 0.4rem 0.6rem;
  font-size: 0.8rem;
  margin: 0;
  max-width: 24rem;
}
.cols {
  display: grid;
  grid-template-columns: 1.15fr 1fr;
  gap: 1.5rem;
  margin-top: 1rem;
}
.colhead {
  margin: 0 0 0.5rem;
  font-size: 0.95rem;
}
.fast {
  display: grid;
  grid-template-columns: 2fr 1fr 1fr auto;
  gap: 0.35rem;
}
.fast input,
.inline input {
  padding: 0.4rem 0.5rem;
  border: 1px solid #d1d5db;
  border-radius: 0.35rem;
  font: inherit;
  width: 100%;
}
.last {
  font-size: 0.78rem;
  color: #1d4ed8;
  margin: 0.4rem 0 0;
}
.note {
  font-size: 0.78rem;
  color: #6b7280;
  margin: 0.4rem 0 0.8rem;
}
.catalogue {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.82rem;
}
.catalogue th {
  text-align: left;
  color: #6b7280;
  font-weight: 600;
  border-bottom: 1px solid #e5e7eb;
  padding: 0.3rem 0.3rem;
}
.catalogue td {
  border-bottom: 1px solid #f3f4f6;
  padding: 0.35rem 0.3rem;
}
.link {
  border: 0;
  background: none;
  padding: 0;
  font: inherit;
  font-weight: 600;
  color: #1d4ed8;
  cursor: pointer;
}
.counts {
  font-size: 0.75rem;
  color: #374151;
}
.zero {
  color: #b91c1c;
  font-weight: 700;
}
.basket {
  list-style: none;
  margin: 0 0 0.8rem;
  padding: 0;
  font-size: 0.85rem;
}
.basket li {
  display: flex;
  justify-content: space-between;
  border-bottom: 1px solid #f3f4f6;
  padding: 0.3rem 0;
}
.atbar {
  border: 1px solid #e5e7eb;
  border-radius: 0.6rem;
  padding: 0.7rem;
  background: #fafafa;
}
.label {
  font-size: 0.72rem;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  color: #6b7280;
  font-weight: 700;
  margin: 0.6rem 0 0.3rem;
}
.rowchips {
  display: flex;
  gap: 0.3rem;
  flex-wrap: wrap;
}
.chipbtn {
  border: 1px solid #d1d5db;
  background: #fff;
  border-radius: 999px;
  padding: 0.25rem 0.7rem;
  font: 500 12px/1.4 system-ui, sans-serif;
  cursor: pointer;
}
.chipbtn.on {
  background: #111827;
  border-color: #111827;
  color: #fff;
}
.chipbtn:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}
.newloc,
.newstore {
  border: 1px dashed #d1d5db;
  border-radius: 0.5rem;
  padding: 0.5rem;
  margin-top: 0.5rem;
  background: #fff;
}
.newstore input {
  padding: 0.35rem 0.5rem;
  border: 1px solid #d1d5db;
  border-radius: 0.35rem;
  font: inherit;
  width: 100%;
  margin-bottom: 0.3rem;
}
.inline {
  display: grid;
  grid-template-columns: 1fr 1fr auto;
  gap: 0.3rem;
}
button {
  border: 1px solid #d1d5db;
  background: #fff;
  border-radius: 0.4rem;
  padding: 0.35rem 0.6rem;
  font: inherit;
  cursor: pointer;
}
button.primary {
  background: #111827;
  border-color: #111827;
  color: #fff;
}
button.big {
  width: 100%;
  margin-top: 0.7rem;
  padding: 0.6rem;
  font-weight: 600;
}
button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}
.bulk {
  margin-top: 1rem;
  border: 1px solid #fcd34d;
  background: #fffbeb;
  border-radius: 0.6rem;
  padding: 0.7rem;
}
.bulkhead {
  margin: 0 0 0.5rem;
  font-size: 0.85rem;
}
.bulklist {
  list-style: none;
  margin: 0 0 0.5rem;
  padding: 0;
  font-size: 0.83rem;
}
.bulklist li {
  display: flex;
  justify-content: space-between;
  gap: 0.5rem;
  border-top: 1px solid #fde68a;
  padding: 0.3rem 0;
}
.bulklist label {
  display: flex;
  gap: 0.4rem;
  align-items: center;
}
.existing {
  font-size: 0.72rem;
}
.history {
  margin-top: 1rem;
}
.pur {
  font-size: 0.78rem;
  margin: 0.15rem 0;
}
.tiny {
  font-size: 0.72rem;
}
.scrim {
  position: fixed;
  inset: 0;
  background: rgba(17, 24, 39, 0.35);
  display: flex;
  justify-content: flex-end;
  z-index: 50;
}
.drawer {
  width: min(24rem, 92vw);
  background: #fff;
  padding: 1rem;
  overflow: auto;
  box-shadow: 0 10px 40px rgba(0, 0, 0, 0.25);
}
.drawer h3 {
  margin: 0;
}
.taglist {
  list-style: none;
  margin: 0;
  padding: 0;
  font-size: 0.85rem;
}
.taglist li {
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-bottom: 1px solid #f3f4f6;
  padding: 0.35rem 0;
}
.offer {
  font-size: 0.78rem;
  background: #fffbeb;
  border: 1px solid #fcd34d;
  border-radius: 0.4rem;
  padding: 0.4rem;
}
.close {
  margin-top: 0.8rem;
  width: 100%;
}
.hygiene {
  margin-top: 1.5rem;
  border-top: 1px solid #e5e7eb;
  padding-top: 0.8rem;
}
.hygienerows {
  display: flex;
  gap: 1rem;
  flex-wrap: wrap;
}
.hyg {
  border: 1px solid #e5e7eb;
  border-radius: 0.5rem;
  padding: 0.5rem 0.7rem;
  min-width: 12rem;
  font-size: 0.78rem;
}
.sname {
  font-weight: 700;
  margin: 0 0 0.3rem;
  font-size: 0.85rem;
}
.lrow {
  margin: 0.2rem 0;
}
.lrow input {
  width: 3.5rem;
  padding: 0.15rem 0.3rem;
  border: 1px solid #d1d5db;
  border-radius: 0.3rem;
  font: inherit;
}
</style>
