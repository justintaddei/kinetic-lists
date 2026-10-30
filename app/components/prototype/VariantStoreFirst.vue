<script setup lang="ts">
/**
 * PROTOTYPE ONLY (wayfinder #13) — Variant C: "Store-first".
 * The Active Store is the frame of the screen. The Kinetic View is the home
 * surface; the capture composer inherits the Active Store as a pre-applied tag;
 * untagged Items are surfaced as a count, with one bulk Tag at Buy.
 */
const {
  state,
  storesNamed,
  categoriesInUse,
  storeById,
  locationById,
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
  pick,
  untaggedAt,
} = usePrototypeHousehold();
const position = usePrototypePosition();

const active = computed(() => storeById(state.value.pickedStoreId));
const rows = computed(() => basket());
const view = computed(() => kineticView(state.value.pickedStoreId));

// ---- capture composer, docked, store context pre-applied ----------------
const name = ref("");
const category = ref("");
const quantity = ref("");
const inherits = ref(true);
const extraTagIds = ref<string[]>([]);
const composerStore = ref("");
const joinPick = ref<"join" | "separate" | null>(null);
const last = ref("");

const composerTargets = computed(() => storesNamed(composerStore.value));
const standing = computed(() => {
  const l = active.value?.locations[0];
  return l ? `${l.label}` : "no Location";
});

function resetComposer() {
  name.value = "";
  category.value = "";
  quantity.value = "";
  composerStore.value = "";
  extraTagIds.value = [];
  inherits.value = true;
  joinPick.value = null;
}

function submitCapture() {
  const tags = new Set<string>(extraTagIds.value);
  if (inherits.value && active.value) tags.add(active.value.id);
  const r = captureItem({
    name: name.value,
    category: category.value,
    quantity: quantity.value,
    storeTags: [...tags],
  });
  last.value = `${r.joined ? `Joined "${r.item.name}"` : `Captured "${r.item.name}"`} · ${
    r.item.storeTags.length
  } Store Tag(s)${r.item.storeTags.length ? "" : " — invisible at every store"}`;
  resetComposer();
}

function toggleExtra(storeId: string) {
  extraTagIds.value = extraTagIds.value.includes(storeId)
    ? extraTagIds.value.filter((s) => s !== storeId)
    : [...extraTagIds.value, storeId];
}

function useComposerName(typed: string) {
  const hits = storesNamed(typed);
  if (hits.length) {
    composerStore.value = hits[0].name;
    extraTagIds.value = [...extraTagIds.value, hits[0].id];
    joinPick.value = "join";
    return;
  }
  composerStore.value = typed;
  joinPick.value = null;
}

function confirmSeparate() {
  if (!active.value) return;
  const s = createStore(composerStore.value, null, null);
  extraTagIds.value = [...extraTagIds.value, s.id];
  joinPick.value = "separate";
}

// ---- Location authoring under the Active Store -------------------------
const newLabel = ref("");
const newLat = ref("");
const newLng = ref("");

watch(
  () => position.coords.value,
  (c) => {
    if (!c) return;
    newLat.value = c.lat.toFixed(5);
    newLng.value = c.lng.toFixed(5);
  }
);

const typed = computed(() => {
  const lat = Number(newLat.value);
  const lng = Number(newLng.value);
  return {
    lat,
    lng,
    ok: newLat.value !== "" && newLng.value !== "" && !Number.isNaN(lat) && !Number.isNaN(lng),
  };
});
const showLocationForm = ref(false);

function saveNewLocation() {
  if (!active.value || !typed.value.ok) return;
  addLocation(active.value.id, "", typed.value.lat, typed.value.lng);
  newLabel.value = "";
  newLat.value = "";
  newLng.value = "";
  showLocationForm.value = false;
}

function addLocationFromCurrentStore(storeId: string) {
  if (!typed.value.ok) return;
  joinStoreLocation(storeId, newLabel.value, typed.value.lat, typed.value.lng);
  newLabel.value = "";
  newLat.value = "";
  newLng.value = "";
  showLocationForm.value = false;
}

// ---- Buy + Tag offer ---------------------------------------------------
const offer = ref<null | { count: number; lines: number; names: string[] }>(null);
const expanded = ref(false);

function doBuy() {
  if (!active.value) return;
  const untagged = untaggedAt(rows.value, active.value.id);
  const r = buy(active.value.id, active.value.locations[0]?.id ?? null);
  if (!r) return;
  offer.value = {
    count: untagged.length,
    lines: r.purchase.lines.length,
    names: untagged.map((u) => u.item.name),
  };
  expanded.value = untagged.length > 0;
}

function tagAll() {
  if (!active.value) return;
  for (const r of rows.value) {
    // Tag is additive: it adds the Bought Store, keeps every other tag.
    if (!r.item.storeTags.includes(active.value.id))
      tagItem(r.item.id, active.value.id);
  }
  offer.value = null;
}
</script>

<template>
  <div class="variant">
    <!-- ============ Active Store bar ============ -->
    <header class="storebar">
      <div class="picker">
        <span class="kicker">Active Store</span>
        <select
          :value="state.pickedStoreId ?? ''"
          @change="pick(($event.target as HTMLSelectElement).value)"
        >
          <option v-for="s in state.stores" :key="s.id" :value="s.id">
            {{ s.name }}
          </option>
        </select>
      </div>
      <p class="frame">
        {{ active?.locations.length ? `${active.locations.length} Location(s)` : "bare Store — no Locations, nothing suggests it" }}
        · <button class="link" @click="showLocationForm = !showLocationForm">
          {{ showLocationForm ? "close" : "+ Location" }}
        </button>
      </p>
    </header>

    <div
      v-if="showLocationForm"
      class="locform"
    >
      <input v-model="newLabel" placeholder="place label (optional)" />
      <input v-model="newLat" placeholder="lat" />
      <input v-model="newLng" placeholder="lng" />
      <button @click="position.read()">
        {{ position.status === "reading" ? "reading…" : "Where I am now" }}
      </button>
      <button
        class="primary"
        :disabled="!typed.ok"
        @click="addLocationFromCurrentStore(active?.id ?? '')"
      >
        Add to {{ active?.name }}
      </button>
      <div class="locform2">
        <p class="posline">{{ position.label }}</p>
        <p class="tiny muted">
          Or name a Store you have not visited:
          <input
            class="newname"
            placeholder="new store name"
            @keyup.enter="useComposerName(($event.target as HTMLInputElement).value); showLocationForm = false"
          />
          <span v-if="typed.ok && composerTargets.length" class="tiny">
            "{{ composerTargets[0].name }}" exists with
            {{ composerTargets[0].locations.length }} Location(s) — use the
            capture composer's offer to add a Location to it.
          </span>
        </p>
      </div>
    </div>

    <!-- ============ Arrival suggestion (suggests Pick, never Picks) ============ -->
    <p
      v-for="a in state.arrivals"
      :key="a.id"
      class="arrival"
    >
      <template v-if="locationById(a.locationId)">
        {{ a.memberId }} is at
        {{ storeById(locationById(a.locationId)!.storeId)?.name }} ·
        {{ locationById(a.locationId)!.label }} ({{ a.at }})
        <button
          @click="pick(locationById(a.locationId)!.storeId)"
        >
          Pick it
        </button>
      </template>
    </p>

    <div class="grid">
      <!-- ============ Kinetic View ============ -->
      <section>
        <h3>
          Kinetic View · Needed at {{ active?.name ?? "no store" }}
          <span class="tiny muted">cross-List</span>
        </h3>
        <ul class="kinetic">
          <li v-for="(r, i) in view" :key="i">
            <span class="nm">{{ r.item.name }}</span>
            <span class="tiny muted">{{ r.listName }} · {{ r.item.quantity }}</span>
            <span class="rail">
              <button
                v-for="t in r.item.storeTags"
                :key="t"
                class="tag"
                :title="`remove ${storeById(t)?.name}`"
                @click="untagItem(r.item.id, t)"
              >
                {{ storeById(t)?.name }} ×
              </button>
            </span>
          </li>
          <li v-if="!view.length" class="tiny muted">
            Nothing Needed at {{ active?.name ?? "this store" }}.
          </li>
        </ul>

        <div class="loose">
          <h3>
            Basket · {{ rows.length }}
            <span class="tiny muted">
              {{ rows.length - untaggedAt(rows, active?.id ?? "").length }} tagged
              at {{ active?.name }},
              <b class="warn">
                {{ untaggedAt(rows, active?.id ?? "").length }} invisible here
              </b>
            </span>
          </h3>
          <ul class="loose__list">
            <li v-for="r in rows" :key="r.listItemId">
              <span class="nm">{{ r.item.name }}</span>
              <span class="rail">
                <button
                  v-for="t in r.item.storeTags"
                  :key="t"
                  class="tag"
                  @click="untagItem(r.item.id, t)"
                >
                  {{ storeById(t)?.name }} ×
                </button>
                <select
                  @change="
                    tagItem(r.item.id, ($event.target as HTMLSelectElement).value)
                  "
                >
                  <option value="">+ store</option>
                  <option
                    v-for="s in state.stores.filter((x) => !r.item.storeTags.includes(x.id))"
                    :key="s.id"
                    :value="s.id"
                  >
                    {{ s.name }}
                  </option>
                </select>
              </span>
            </li>
          </ul>
          <button class="primary big" :disabled="!rows.length" @click="doBuy">
            Buy {{ rows.length }} at {{ active?.name }}
          </button>
          <div v-if="offer" class="offer">
            <p v-if="offer.count" class="offerhead">
              <button class="link" @click="expanded = !expanded">
                {{ expanded ? "▾" : "▸" }}
              </button>
              <b>{{ offer.count }}</b> of {{ offer.lines }} bought Item(s) have no
              tag for {{ active?.name }} — Tag adds it, never replaces what they
              have.
            </p>
            <p v-else class="tiny muted">Nothing to Tag at {{ active?.name }}.</p>
            <ul v-if="expanded && offer.count" class="offernames">
              <li v-for="n in offer.names" :key="n">{{ n }}</li>
            </ul>
            <button v-if="offer.count" class="primary" @click="tagAll">
              Tag all {{ offer.count }} at {{ active?.name }}
            </button>
          </div>
        </div>
      </section>

      <!-- ============ capture composer ============ -->
      <section class="composer">
        <h3>Add an Item</h3>
        <p v-if="last" class="flash">{{ last }}</p>
        <label>
          Name
          <input v-model="name" placeholder="Spinach" />
        </label>
        <div class="two">
          <label>
            Category
            <input v-model="category" list="catsC" placeholder="Produce" />
            <datalist id="catsC">
              <option v-for="c in categoriesInUse()" :key="c" :value="c" />
            </datalist>
          </label>
          <label>
            Quantity
            <input v-model="quantity" placeholder='"1 bag"' />
          </label>
        </div>

        <label class="inherit">
          <input type="checkbox" v-model="inherits" />
          <span>
            Tag it <b>{{ active?.name ?? "—" }}</b>
            <span class="tiny muted">(standing at {{ standing }})</span>
          </span>
        </label>

        <p class="tiny kicker">also bought at</p>
        <div class="rail">
          <button
            v-for="s in state.stores"
            :key="s.id"
            :class="['tag', { on: extraTagIds.includes(s.id) }]"
            @click="toggleExtra(s.id)"
          >
            {{ s.name }}
          </button>
          <input
            class="newname"
            v-model="composerStore"
            placeholder="+ name a store"
          />
        </div>
        <button v-if="composerStore && !composerTargets.length" class="create" @click="confirmSeparate">
          Create "{{ composerStore }}" (bare Store, tags only)
        </button>
        <div v-if="composerTargets.length && composerTargets[0].id !== active?.id" class="joinsel">
          <p class="tiny">
            "{{ composerTargets[0].name }}" exists ({{ composerTargets[0].locations.length }}
            Location(s)).
          </p>
          <button
            class="primary"
            @click="extraTagIds = [...new Set([...extraTagIds, composerTargets[0].id])]"
          >
            Tag it {{ composerTargets[0].name }}
          </button>
          <button @click="showLocationForm = true">
            Add a Location to {{ composerTargets[0].name }}
          </button>
        </div>

        <p v-if="inherits ? false : extraTagIds.length === 0" class="gate">
          Zero Store Tags: nobody in {{ state.household.name }} will ever see
          this Item at a store.
        </p>

        <button class="primary big" @click="submitCapture">Capture</button>

        <p class="tiny muted where">
          {{ state.household.name }} · Members {{ state.household.members.join(", ") }}
        </p>
      </section>
    </div>

    <!-- Geofence per Location, one shared judgement -->
    <section class="fences">
      <p class="tiny kicker">Geofence (shared by every Member)</p>
      <div class="fences__row">
        <div v-for="s in state.stores" :key="s.id" class="fence">
          <p class="fname">{{ s.name }}</p>
          <p v-for="l in s.locations" :key="l.id" class="frow">
            {{ l.label }}
            <input
              type="number"
              :value="l.geofence"
              @change="setGeofence(l.id, Number(($event.target as HTMLInputElement).value))"
            />
            m
          </p>
          <p v-if="!s.locations.length" class="tiny muted">no Locations</p>
        </div>
      </div>
    </section>
  </div>
</template>

<style scoped>
.variant {
  max-width: 58rem;
  margin: 0 auto;
  padding: 0 1.25rem 7rem;
  font: 14px/1.45 system-ui, sans-serif;
  color: #111827;
}
.storebar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 1rem;
  background: #111827;
  color: #fff;
  border-radius: 0 0 0.75rem 0.75rem;
  padding: 0.7rem 1rem;
  margin: 0 -1.25rem;
}
.kicker {
  font-size: 0.65rem;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  color: #9ca3af;
  display: block;
}
.picker select {
  background: #1f2937;
  color: #fff;
  border: 1px solid #374151;
  border-radius: 0.4rem;
  padding: 0.35rem 0.5rem;
  font: 600 15px/1.2 system-ui, sans-serif;
}
.frame {
  margin: 0;
  font-size: 0.78rem;
  color: #d1d5db;
}
.locform {
  display: flex;
  gap: 0.4rem;
  flex-wrap: wrap;
  align-items: center;
  background: #f3f4f6;
  border-radius: 0.5rem;
  padding: 0.6rem;
  margin-top: 0.6rem;
}
.locform2 {
  width: 100%;
}
.locform input,
.composer input,
.frow input {
  padding: 0.35rem 0.5rem;
  border: 1px solid #d1d5db;
  border-radius: 0.35rem;
  font: inherit;
}
.locform input:not(.newname) {
  width: 8rem;
}
.posline {
  font-size: 0.75rem;
  color: #1d4ed8;
  margin: 0;
}
.arrival {
  background: #eff6ff;
  border: 1px solid #bfdbfe;
  color: #1e3a8a;
  border-radius: 0.5rem;
  padding: 0.45rem 0.6rem;
  font-size: 0.82rem;
  margin: 0.7rem 0 0;
}
.grid {
  display: grid;
  grid-template-columns: 1.3fr 1fr;
  gap: 1.25rem;
  margin-top: 1rem;
}
h3 {
  font-size: 0.95rem;
  margin: 0 0 0.5rem;
}
.kinetic,
.loose__list,
.offernames {
  list-style: none;
  margin: 0 0 1.2rem;
  padding: 0;
}
.kinetic li,
.loose__list li {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  flex-wrap: wrap;
  border-bottom: 1px solid #e5e7eb;
  padding: 0.45rem 0;
}
.nm {
  font-weight: 600;
  min-width: 6rem;
}
.rail {
  display: flex;
  gap: 0.25rem;
  flex-wrap: wrap;
  align-items: center;
  margin-left: auto;
}
.tag {
  border: 1px solid #c7d2fe;
  background: #eef2ff;
  border-radius: 999px;
  padding: 0.15rem 0.55rem;
  font: 500 12px/1.4 system-ui, sans-serif;
  cursor: pointer;
}
.tag.on {
  background: #111827;
  border-color: #111827;
  color: #fff;
}
.rail select {
  border: 1px dashed #9ca3af;
  background: transparent;
  border-radius: 999px;
  padding: 0.12rem 0.4rem;
  font: 12px/1.4 system-ui, sans-serif;
}
.warn {
  color: #b91c1c;
}
.composer {
  border: 1px solid #e5e7eb;
  border-radius: 0.7rem;
  padding: 0.9rem;
  background: #fff;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.08);
}
.two {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 0.5rem;
}
label {
  display: block;
  font-size: 0.72rem;
  font-weight: 700;
  color: #374151;
  margin: 0.5rem 0;
}
label input {
  width: 100%;
  margin-top: 0.2rem;
  font-weight: 400;
}
.inherit {
  display: flex;
  gap: 0.5rem;
  align-items: center;
  font-weight: 400;
  font-size: 0.85rem;
  background: #f0fdf4;
  border: 1px solid #bbf7d0;
  border-radius: 0.45rem;
  padding: 0.45rem;
}
.inherit input {
  width: auto;
  margin: 0;
}
.newname {
  border: 1px dashed #9ca3af;
  border-radius: 999px;
  padding: 0.15rem 0.6rem;
  font: 12px/1.4 system-ui, sans-serif;
  width: 9rem;
}
.create,
.joinsel button,
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
  margin-top: 0.8rem;
  padding: 0.65rem;
  font-weight: 600;
}
button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}
.joinsel {
  border: 1px solid #fcd34d;
  background: #fffbeb;
  border-radius: 0.45rem;
  padding: 0.5rem;
  margin-top: 0.4rem;
}
.joinsel p {
  margin: 0 0 0.4rem;
}
.gate {
  background: #fef2f2;
  border: 1px solid #fecaca;
  color: #b91c1c;
  border-radius: 0.45rem;
  padding: 0.45rem;
  font-size: 0.78rem;
}
.flash {
  background: #ecfdf5;
  border: 1px solid #a7f3d0;
  border-radius: 0.45rem;
  padding: 0.4rem;
  font-size: 0.78rem;
  margin: 0 0 0.6rem;
}
.where {
  margin: 0.8rem 0 0;
}
.offer {
  border: 1px solid #fcd34d;
  background: #fffbeb;
  border-radius: 0.5rem;
  padding: 0.6rem;
  margin-top: 0.6rem;
}
.offerhead {
  margin: 0 0 0.4rem;
  font-size: 0.83rem;
}
.offernames li {
  font-size: 0.8rem;
  border-bottom: 1px solid #fde68a;
  padding: 0.2rem 0;
}
.link {
  border: 0;
  background: none;
  color: inherit;
  padding: 0 0.2rem;
  font: inherit;
  cursor: pointer;
  text-decoration: underline;
}
.frame .link,
.picker + .frame .link {
  color: #93c5fd;
}
.fences {
  margin-top: 1.5rem;
  border-top: 1px solid #e5e7eb;
  padding-top: 0.7rem;
}
.fences__row {
  display: flex;
  gap: 0.8rem;
  flex-wrap: wrap;
}
.fence {
  border: 1px solid #e5e7eb;
  border-radius: 0.5rem;
  padding: 0.5rem 0.6rem;
  font-size: 0.75rem;
  min-width: 11rem;
}
.fname {
  margin: 0 0 0.25rem;
  font-weight: 700;
  font-size: 0.82rem;
}
.frow {
  margin: 0.2rem 0;
  display: flex;
  gap: 0.3rem;
  align-items: center;
}
.frow input {
  width: 3.5rem;
}
.tiny {
  font-size: 0.72rem;
}
.muted {
  color: #6b7280;
}
</style>
