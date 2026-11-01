/**
 * PROTOTYPE ONLY — wayfinder #11. Not a seam, not a schema, not a plan.
 *
 * An in-memory fake Household that is enough to judge the Kinetic View and an
 * Arrival on real shapes. No database, no Realtime, no geolocation, no geocoder:
 * an Arrival is a button, a Position is a number, and a co-Member's act is a
 * timer. The vocabulary is the GLOSSARY's — Household, Member, Store, Location,
 * Geofence, Item, List, List Item, Status, Store Tag, Active Store, Standing
 * Location, Arrival, Pick, Check, Buy, Mint, Kinetic View.
 *
 * ADR-0021: the Active Store and the Standing Location are per-Member browser
 * state, so they live here in memory and never become a row.
 */

export type Status = 'needed' | 'in_basket' | 'stocked'
export type Scenario = 'full' | 'wall' | 'fresh'
export type ArrivalForm = 'silent' | 'line' | 'toast'
export type Sheet = null | 'store-picker' | 'store-screen' | 'capture' | 'mint' | 'cascade' | 'item'

export interface LocationRow {
  id: string
  storeId: string
  label: string
  lat: number
  lng: number
  geofence: number
}
export interface StoreRow {
  id: string
  name: string
  locations: LocationRow[]
}
export interface ItemRow {
  id: string
  name: string
  category: string
  quantity: string
  storeTags: string[]
}
export interface ListRow {
  id: string
  name: string
}
export interface ListItemRow {
  id: string
  itemId: string
  listId: string
  status: Status
}
export interface PurchaseRow {
  id: string
  storeId: string
  locationId: string | null
  at: string
  member: string
  lines: { name: string, quantity: string }[]
}
/** One Kinetic View row: an Item, with every List of its rows that Needed it. */
export interface KineticRow {
  key: string
  item: ItemRow
  rows: ListItemRow[]
  lists: ListRow[]
  atStore: boolean
}

const WALL = ['Aldi', 'Best Mart', 'Cardello', 'Costco', 'CVS Pharmacy', 'Foodland', 'Giant Eagle', 'H Mart', 'King Soopers', 'Lidl', 'Market Basket', 'Namaste', 'Ocean State', 'PCC Co-op', 'Quick Trim', 'Rite Aid', 'Savers', 'Shaws', 'Stop Shop', 'Target', 'Vons', 'Westside']

const LISTS: ListRow[] = [
  { id: 'standing', name: 'Standing Set' },
  { id: 'everyday', name: 'Everyday' },
  { id: 'weekly', name: 'Weekly' },
  { id: 'trip', name: 'The Trip' },
  { id: 'party', name: 'The Coolers' },
]

interface ItemSeed { name: string, category: string, quantity: string, tags: string[], status: Status, lists: string[] }

const ITEM_SEED: ItemSeed[] = [
  { name: 'Milk', category: 'Dairy', quantity: '1 gal', tags: ['walmart', 'big-y'], status: 'needed', lists: ['standing', 'everyday'] },
  { name: 'Eggs', category: 'Dairy', quantity: '1 dozen', tags: ['walmart', 'big-y'], status: 'in_basket', lists: ['standing'] },
  { name: 'Butter', category: 'Dairy', quantity: '1 lb', tags: ['walmart'], status: 'needed', lists: ['weekly'] },
  { name: 'Yogurt', category: 'Dairy', quantity: '4 cups', tags: ['walmart', 'big-y'], status: 'needed', lists: ['everyday'] },
  { name: 'Cheese', category: 'Dairy', quantity: '8 oz', tags: ['walmart', 'big-y', 'tjs'], status: 'needed', lists: ['party', 'standing'] },
  { name: 'Bread', category: 'Bakery', quantity: '1 loaf', tags: ['walmart', 'big-y'], status: 'stocked', lists: ['standing'] },
  { name: 'Sourdough', category: 'Bakery', quantity: '1 loaf', tags: ['tjs'], status: 'needed', lists: ['weekly'] },
  { name: 'Bagels', category: 'Bakery', quantity: '6', tags: ['tjs', 'walmart'], status: 'needed', lists: ['standing'] },
  { name: 'Bananas', category: 'Produce', quantity: '6', tags: ['walmart', 'big-y'], status: 'in_basket', lists: ['standing', 'everyday'] },
  { name: 'Apples', category: 'Produce', quantity: '8', tags: ['walmart', 'big-y'], status: 'needed', lists: ['everyday', 'party'] },
  { name: 'Spinach', category: 'Produce', quantity: '1 bag', tags: ['big-y', 'tjs'], status: 'needed', lists: ['weekly'] },
  { name: 'Avocados', category: 'Produce', quantity: '4', tags: ['walmart', 'tjs'], status: 'needed', lists: ['party'] },
  { name: 'Tomatoes', category: 'Produce', quantity: '6', tags: ['walmart', 'roadside'], status: 'needed', lists: ['standing'] },
  { name: 'Onions', category: 'Produce', quantity: '3', tags: ['walmart', 'big-y'], status: 'needed', lists: ['weekly'] },
  { name: 'Rice', category: 'Pantry', quantity: '5 lb', tags: ['walmart', 'big-y'], status: 'needed', lists: ['weekly', 'trip'] },
  { name: 'Olive Oil', category: 'Pantry', quantity: '25 oz', tags: ['walmart', 'big-y'], status: 'needed', lists: ['standing'] },
  { name: 'Pasta', category: 'Pantry', quantity: '2 boxes', tags: ['walmart', 'big-y'], status: 'needed', lists: ['weekly'] },
  { name: 'Tomato Sauce', category: 'Pantry', quantity: '2 jars', tags: ['walmart', 'big-y'], status: 'needed', lists: ['weekly'] },
  { name: 'Coffee', category: 'Beverage', quantity: '12 oz', tags: ['walmart', 'tjs'], status: 'in_basket', lists: ['standing', 'everyday'] },
  { name: 'Water Case', category: 'Beverage', quantity: '24', tags: ['walmart'], status: 'needed', lists: ['party', 'trip'] },
  { name: 'Sparkling Water', category: 'Beverage', quantity: '8', tags: ['walmart', 'big-y'], status: 'needed', lists: ['party'] },
  { name: 'Orange Juice', category: 'Beverage', quantity: '64 oz', tags: ['big-y'], status: 'needed', lists: ['standing'] },
  { name: 'Frozen Pizza', category: 'Frozen', quantity: '2', tags: ['walmart'], status: 'needed', lists: ['trip'] },
  { name: 'Berries', category: 'Frozen', quantity: '3 bags', tags: ['tjs', 'big-y'], status: 'needed', lists: ['weekly'] },
  { name: 'Peas', category: 'Frozen', quantity: '2 bags', tags: ['walmart', 'big-y'], status: 'needed', lists: ['standing'] },
  { name: 'Ground Turkey', category: 'Meat', quantity: '1 lb', tags: ['walmart', 'big-y'], status: 'needed', lists: ['weekly'] },
  { name: 'Chicken Thighs', category: 'Meat', quantity: '3 lb', tags: ['walmart', 'big-y'], status: 'needed', lists: ['party', 'trip'] },
  { name: 'Salmon', category: 'Meat', quantity: '2 fillets', tags: ['big-y', 'tjs'], status: 'needed', lists: ['weekly'] },
  { name: 'Chips', category: 'Snacks', quantity: '4 bags', tags: ['walmart', 'big-y'], status: 'needed', lists: ['party'] },
  { name: 'Cookies', category: 'Snacks', quantity: '1 pack', tags: ['walmart', 'tjs'], status: 'needed', lists: ['standing'] },
  { name: 'Trail Mix', category: 'Snacks', quantity: '2 lb', tags: ['roadside', 'walmart'], status: 'needed', lists: ['trip'] },
  { name: 'Paper Towels', category: 'Household', quantity: '6 rolls', tags: ['walmart'], status: 'in_basket', lists: ['standing'] },
  { name: 'Toilet Paper', category: 'Household', quantity: '12 rolls', tags: ['walmart', 'big-y'], status: 'needed', lists: ['standing', 'everyday'] },
  { name: 'Dish Soap', category: 'Household', quantity: '1', tags: ['walmart', 'big-y'], status: 'needed', lists: ['everyday'] },
  { name: 'Laundry Pods', category: 'Household', quantity: '36', tags: ['walmart', 'big-y'], status: 'needed', lists: ['weekly'] },
  { name: 'Trash Bags', category: 'Household', quantity: '30', tags: ['walmart'], status: 'needed', lists: ['everyday'] },
  { name: 'Diapers', category: 'Baby', quantity: '44 ct', tags: ['walmart', 'big-y'], status: 'needed', lists: ['standing', 'everyday'] },
  { name: 'Cat Food', category: 'Pets', quantity: '12 lb', tags: ['walmart', 'big-y'], status: 'needed', lists: ['standing'] },
  { name: 'Cat Litter', category: 'Pets', quantity: '14 lb', tags: ['walmart'], status: 'needed', lists: ['weekly'] },
  // Nothing Tags these, so no Store's view will ever show them: the Basket's unTagged line.
  { name: 'Lantern Batteries', category: 'Outdoor', quantity: '8 ct', tags: [], status: 'needed', lists: ['trip'] },
  { name: 'Sunscreen', category: 'Outdoor', quantity: '1', tags: [], status: 'needed', lists: ['trip'] },
  { name: 'Travel Mug', category: 'Outdoor', quantity: '1', tags: [], status: 'in_basket', lists: ['trip'] },
  { name: 'Umbrella', category: 'Outdoor', quantity: '1', tags: [], status: 'in_basket', lists: ['trip', 'party'] },
]

const FRESH_SEED: ItemSeed[] = [
  { name: 'Milk', category: 'Dairy', quantity: '1 gal', tags: [], status: 'needed', lists: ['standing', 'everyday'] },
  { name: 'Eggs', category: 'Dairy', quantity: '1 dozen', tags: [], status: 'needed', lists: ['standing'] },
  { name: 'Bread', category: 'Bakery', quantity: '1 loaf', tags: [], status: 'needed', lists: ['standing'] },
  { name: 'Dish Soap', category: 'Household', quantity: '1', tags: [], status: 'needed', lists: ['everyday'] },
]

function world(scenario: Scenario) {
  const stores: StoreRow[] = scenario === 'fresh'
    ? []
    : [
        {
          id: 'walmart',
          name: 'Walmart',
          locations: [
            { id: 'walmart-midtown', storeId: 'walmart', label: 'Midtown', lat: 42.2562, lng: -71.7799, geofence: 150 },
            { id: 'walmart-5th', storeId: 'walmart', label: '5th Street', lat: 42.3328, lng: -71.1061, geofence: 150 },
          ],
        },
        { id: 'big-y', name: 'Big Y', locations: [{ id: 'big-y-main', storeId: 'big-y', label: 'Home Main', lat: 42.1148, lng: -72.5152, geofence: 150 }] },
        // A Bare Store: Tags and no Location. Pickable, and no Arrival can suggest it.
        { id: 'tjs', name: 'Trader Joe\'s', locations: [] },
        { id: 'roadside', name: 'Roadside Stand', locations: [] },
      ]
  if (scenario === 'wall') {
    WALL.forEach((name, i) => {
      stores.push({
        id: `wall-${i}`,
        name,
        locations: i % 4 === 0 ? [] : [{ id: `wall-${i}-l`, storeId: `wall-${i}`, label: 'Home Main', lat: 42 + i / 13, lng: -72.4 + i / 20, geofence: 150 }],
      })
    })
  }
  const seeds = scenario === 'fresh' ? FRESH_SEED : ITEM_SEED
  const items: ItemRow[] = []
  const listItems: ListItemRow[] = []
  seeds.forEach((seed, index) => {
    const usable = seed.tags.filter((tag) => stores.some((s) => s.id === tag))
    items.push({ id: `i${index}`, name: seed.name, category: seed.category, quantity: seed.quantity, storeTags: usable })
    seed.lists.forEach((listId, n) => listItems.push({ id: `i${index}-${n}`, itemId: `i${index}`, listId, status: seed.status }))
  })
  return { stores, items, listItems }
}

function base(scenario: Scenario) {
  const { stores, items, listItems } = world(scenario)
  return {
    scenario,
    household: 'The Fridges',
    members: ['Dana', 'Alex'],
    you: 'Dana',
    coMember: 'Alex',
    stores,
    lists: LISTS,
    items,
    listItems,
    purchases: [] as PurchaseRow[],
    arrivals: [] as { member: string, locationId: string, at: number }[],
    // Per-Member browser state (ADR-0021): never a row, never sent to the database.
    activeStoreId: stores.some((s) => s.id === 'walmart') ? 'walmart' : null,
    standingLocationId: 'walmart-midtown',
    arrivalForm: 'line' as ArrivalForm,
    filter: '',
    sheet: null as Sheet,
    sheetItemId: null as string | null,
    cascadeStoreId: null as string | null,
    mintDoor: 'header' as 'header' | 'buy' | 'bare',
    mintFixStoreId: null as string | null,
    live: [] as string[],
    log: [] as { at: number, who: string, text: string }[],
  }
}

const state = reactive(base('full'))

let ids = 0
const nextId = (prefix: string) => `${prefix}-${Date.now()}-${ids++}`
const clock = () => new Date().toLocaleTimeString([], { hour: 'numeric', minute: '2-digit', second: 'numeric' })

function record(who: 'you' | 'co', text: string) {
  state.log.unshift({ at: Date.now(), who: who === 'you' ? 'You' : state.coMember, text })
  state.log = state.log.slice(0, 12)
}

function flash(...keys: string[]) {
  const fresh = [...new Set([...state.live, ...keys])]
  state.live = fresh
  for (const key of keys) {
    setTimeout(() => {
      state.live = state.live.filter((k) => k !== key)
    }, 1500)
  }
}

const storeById = (id: string | null | undefined) => state.stores.find((s) => s.id === id) ?? null
const itemById = (id: string) => state.items.find((i) => i.id === id) ?? null
const listById = (id: string) => state.lists.find((l) => l.id === id) ?? null

/**
 * Rows the Household Needs at one Store — Items carrying that Store's Tag, and
 * nothing a Tag never pinned (ADR-0002: a Store's Kinetic View is Tag-scoped).
 */
function rowsAt(storeId: string | null, status: Status): KineticRow[] {
  const map = new Map<string, ListItemRow[]>()
  for (const row of state.listItems) {
    if (row.status !== status) continue
    const item = itemById(row.itemId)
    if (!item) continue
    if (storeId && !item.storeTags.includes(storeId)) continue
    map.set(row.itemId, [...(map.get(row.itemId) ?? []), row])
  }
  return [...map.entries()]
    .map(([itemId, rows]) => {
      const item = itemById(itemId)!
      return {
        key: itemId,
        item,
        rows,
        lists: [...new Set(rows.map((r) => listById(r.listId)!))],
        atStore: true,
      }
    })
    .sort((a, b) => a.item.name.localeCompare(b.item.name))
}

/** Whole-basket rows (ADR-0016: Buy takes the Basket, which is Store-agnostic). */
function basketRows(): KineticRow[] {
  const rows = rowsAt(null, 'in_basket')
  const active = state.activeStoreId
  return rows
    .map((r) => ({ ...r, atStore: !!active && r.item.storeTags.includes(active) }))
    .sort((a, b) => Number(b.atStore) - Number(a.atStore) || a.item.name.localeCompare(b.item.name))
}

export function usePrototypeKinetic() {
  const activeStore = computed(() => storeById(state.activeStoreId))
  const standingLocation = computed(() => {
    const location = state.stores.flatMap((s) => s.locations).find((l) => l.id === state.standingLocationId) ?? null
    return location && location.storeId === state.activeStoreId ? location : null
  })

  const kineticRows = computed(() => rowsAt(state.activeStoreId, 'needed'))
  const inBasket = computed(() => basketRows())
  const basketCount = computed(() => inBasket.value.length)

  /** The Gate copy's numbers: Needed at this Store, In Basket, and the invisible subject. */
  const gate = computed(() => ({
    needed: kineticRows.value.length,
    basket: basketCount.value,
    untaggedAtStore: inBasket.value.filter((r) => !r.atStore).length,
  }))

  /** Variant B/C grouping. */
  const byCategory = computed(() => {
    const groups = new Map<string, KineticRow[]>()
    kineticRows.value.forEach((r) => groups.set(r.item.category, [...(groups.get(r.item.category) ?? []), r]))
    return [...groups.entries()].sort((a, b) => a[0].localeCompare(b[0]))
  })

  /** No Active Store read: Needed rows grouped by Store Tag, and the unTagged group. */
  const shelfByStore = computed(() => {
    const groups = new Map<string, KineticRow[]>()
    for (const item of state.items) {
      const needed = state.listItems.filter((r) => r.itemId === item.id && r.status === 'needed')
      if (needed.length === 0) continue
      const row: KineticRow = {
        key: item.id,
        item,
        rows: needed,
        lists: [...new Set(needed.map((r) => listById(r.listId)!))],
        atStore: true,
      }
      const keys = item.storeTags.length ? item.storeTags : ['(no Tag)']
      keys.forEach((key) => groups.set(key, [...(groups.get(key) ?? []), row]))
    }
    const stores = [...groups.entries()]
      .filter(([key]) => key !== '(no Tag)')
      .map(([key, rows]) => ({ store: storeById(key)!, rows: rows.sort((a, b) => a.item.name.localeCompare(b.item.name)) }))
      .filter((g) => g.store)
      .sort((a, b) => a.store.name.localeCompare(b.store.name))
    return { stores, untagged: groups.get('(no Tag)') ?? [] }
  })

  const itemTagsFor = (item: ItemRow) => state.stores.filter((s) => item.storeTags.includes(s.id))
  const itemsAtStore = (storeId: string | null) => (storeId ? state.items.filter((i) => i.storeTags.includes(storeId)) : [])

  const storeRoster = computed(() =>
    [...state.stores]
      .sort((a, b) => a.name.localeCompare(b.name))
      .map((store) => ({
        store,
        items: state.items.filter((i) => i.storeTags.includes(store.id)),
        counts: { needed: rowsAt(store.id, 'needed').length, basket: rowsAt(store.id, 'in_basket').length, stocked: rowsAt(store.id, 'stocked').length },
      })),
  )

  const listsWithCounts = computed(() =>
    state.lists.map((list) => {
      const rows = state.listItems.filter((r) => r.listId === list.id)
      return {
        list,
        needed: new Set(rows.filter((r) => r.status === 'needed').map((r) => r.itemId)).size,
        basket: new Set(rows.filter((r) => r.status === 'in_basket').map((r) => r.itemId)).size,
        stocked: new Set(rows.filter((r) => r.status === 'stocked').map((r) => r.itemId)).size,
      }
    }),
  )

  const filterMatches = (name: string) => name.toLowerCase().includes(state.filter.trim().toLowerCase())

  // ------------------------------------------------------------------- acts

  /** Check flips every List Item of that Item at once — a List Item has one Status. */
  function check(key: string, by = state.you) {
    const item = itemById(key)
    const rows = state.listItems.filter((r) => r.itemId === key)
    const to: Status = rows.some((r) => r.status === 'needed') ? 'in_basket' : 'needed'
    rows.forEach((r) => {
      if (r.status === 'needed' || to === 'needed') r.status = to
    })
    flash(key)
    record('you', `${by === state.you ? 'You Checked' : `${by} Checked`} ${item?.name}`)
  }

  /** Pick never moves a List Item, and it clears the Standing Location. */
  function pick(storeId: string) {
    state.activeStoreId = storeId
    state.standingLocationId = null
    state.sheet = null
    record('you', `You Picked ${storeById(storeId)?.name} — Standing Location cleared`)
  }

  function arrivalLine() {
    const location = standingLocation.value
    const store = activeStore.value
    if (!location || !store) return ''
    return `You're at ${store.name} ${location.label}`
  }

  function arrive(locationId: string, by = state.you) {
    const location = state.stores.flatMap((s) => s.locations).find((l) => l.id === locationId)
    if (!location) return
    const store = storeById(location.storeId)!
    state.activeStoreId = location.storeId
    state.standingLocationId = location.id
    state.arrivals.unshift({ member: by, locationId, at: Date.now() })
    const needed = rowsAt(store.id, 'needed').length
    const line = `${by} is at ${store.name} ${location.label} — ${needed} Needed at ${store.name}`
    if (state.arrivalForm === 'toast') toast(line, { position: 'top-center', id: 'arrival' })
    if (state.arrivalForm === 'line') toast(line, { position: 'top-center', id: 'arrival', duration: 2200 })
    record('you', line)
  }

  /** Buy: the whole Basket, on the server's clock. A Store-less Basket asks for a Shop's name first. */
  function buy() {
    const store = activeStore.value
    const rows = inBasket.value
    if (!store) {
      state.mintDoor = 'buy'
      state.sheet = 'mint'
      record('you', `Buy refused — it needs a Store name before lines can be claimed`)
      return
    }
    if (store.locations.length === 0 && state.mintFixStoreId !== store.id) {
      state.mintDoor = 'bare'
      state.mintFixStoreId = store.id
      toast(`A Bare Store's Buy asks: add this place as a Location for ${store.name}?`, { position: 'top-center' })
      record('you', `Buy paused at ${store.name} — a Bare Store has no Position to record`)
      return
    }
    if (rows.length === 0) {
      toast('Buy refused — the Basket is standing empty', { position: 'top-center' })
      return
    }
    const lines = rows.map((r) => ({ name: r.item.name, quantity: r.item.quantity }))
    lines.forEach((l) => {
      state.listItems.filter((r) => itemById(r.itemId)?.name === l.name).forEach((r) => {
        if (r.status === 'in_basket') r.status = 'stocked'
      })
      flash(itemByName(l.name)?.id ?? '')
    })
    state.purchases.unshift({
      id: nextId('p'),
      storeId: store.id,
      locationId: standingLocation.value?.id ?? null,
      at: clock(),
      member: state.you,
      lines,
    })
    state.mintFixStoreId = null
    state.sheet = null
    toast(`Bought ${lines.length} at ${store.name}${standingLocation.value ? ` · ${standingLocation.value.label}` : ''}`, { position: 'bottom-center' })
    record('you', `You Bought ${lines.length} lines at ${store.name} · Location ${standingLocation.value?.label ?? 'none'}`)
  }

  const itemByName = (name: string) => state.items.find((i) => i.name.toLowerCase() === name.toLowerCase()) ?? null

  /** Mint: a bare Store, cured into a real one by a saved Location. Name joins, never collides. */
  function mint(name: string, placeLabel: string, position: { lat: number, lng: number } | null, opts: { fixStoreId?: string | null } = {}) {
    const clean = name.trim()
    const label = placeLabel.trim()
    const fix = opts.fixStoreId ?? null
    if (!clean) return
    const clash = state.stores.find((s) => s.name.toLowerCase() === clean.toLowerCase())
    if (clash) {
      toast(`${clean} already exists — “Add a Location to ${clean}”?`, { position: 'top-center' })
      record('you', `Mint refused — ${clean} already names a Store (it joins, it does not collide)`)
      return
    }
    if (fix) {
      if (!position) {
        toast('A Location needs a Position — a Store alone is not a place', { position: 'top-center' })
        record('you', `Add Location refused — a Location needs a Position`)
        return
      }
      const store = storeById(fix)!
      const location: LocationRow = { id: nextId('l'), storeId: store.id, label, lat: position.lat, lng: position.lng, geofence: 150 }
      store.locations.push(location)
      state.activeStoreId = store.id
      state.standingLocationId = location.id
      state.sheet = null
      state.mintFixStoreId = null
      toast(`${label} is a Location for ${store.name} — the Bare Store is cured`, { position: 'top-center' })
      record('you', `You added Location ${label} to ${store.name}`)
      return
    }
    const store: StoreRow = { id: nextId('s'), name: clean, locations: [] }
    if (position) {
      store.locations.push({ id: nextId('l'), storeId: store.id, label: label || 'Home Main', lat: position.lat, lng: position.lng, geofence: 150 })
    }
    state.stores.push(store)
    state.activeStoreId = store.id
    state.standingLocationId = store.locations[0]?.id ?? null
    state.items.forEach((i) => {
      if (state.mintDoor === 'buy' && inBasket.value.some((r) => r.key === i.id) && i.storeTags.length === 0) {
        i.storeTags.push(store.id)
      }
    })
    state.sheet = null
    toast(`${clean} is the Active Store${store.locations.length ? '' : ' — a bare Store, so no Arrival will ever suggest it'}`, { position: 'top-center' })
    record('you', `You minted ${clean}${store.locations.length ? ` + Location ${store.locations[0].label}` : ' (no Position = a bare Store)'}`)
  }

  /** The cascade: Tags unpin, Items left unTagged lose their standing rows, all for every Member. */
  function deleteStore(storeId: string, by = state.you) {
    const store = storeById(storeId)
    if (!store) return
    const tagged = state.items.filter((i) => i.storeTags.includes(storeId))
    tagged.forEach((i) => {
      i.storeTags = i.storeTags.filter((t) => t !== storeId)
    })
    const doomed = new Set(tagged.filter((i) => i.storeTags.length === 0).map((i) => i.id))
    const erasedRows = state.listItems.filter((r) => doomed.has(r.itemId)).length
    state.listItems = state.listItems.filter((r) => !doomed.has(r.itemId))
    state.items = state.items.filter((i) => !doomed.has(i.id))
    state.stores = state.stores.filter((s) => s.id !== storeId)
    if (state.activeStoreId === storeId) {
      state.activeStoreId = null
      state.standingLocationId = null
    }
    const keys = [...doomed, ...tagged.map((i) => i.id)]
    flash(...keys)
    state.sheet = null
    const who = by === state.you ? 'You' : state.coMember
    toast(`Deleted ${store.name} — ${tagged.length} Tags stripped, ${doomed.size} Items erased`, { position: 'top-center' })
    record('you', `${who} deleted ${store.name} · ${store.locations.length} Locations · ${tagged.length} Items unpinned · ${doomed.size} Items left unTagged erased ${erasedRows} List Items, for every Member`)
  }

  /** A co-Member's act is this simulation's stream: it lands on your screen mid-edit. */
  function coMemberCheck() {
    const row = kineticRows.value.find((r) => r.item.name === 'Coffee') ?? kineticRows.value.find((r) => r.item.name === 'Coffee') ?? kineticRows.value[0]
    if (!row) {
      toast('Nothing for Alex to Check here — this Store has no Needed row', { position: 'top-center' })
      return
    }
    setTimeout(() => {
      check(row.key, state.coMember)
      toast(`${state.coMember} Checked ${row.item.name}`, { position: 'top-center', id: 'co' })
    }, 700)
    record('co', `Alex is Checking ${row.item.name} — watch the row move`)
  }

  function coMemberBuy() {
    const rows = basketRows().filter((r) => r.atStore)
    if (rows.length === 0) {
      toast('Alex has an empty Basket at this Store', { position: 'top-center' })
      return
    }
    setTimeout(() => {
      rows.forEach((r) => {
        state.listItems.filter((x) => x.itemId === r.key && x.status === 'in_basket').forEach((x) => {
          x.status = 'stocked'
        })
        flash(r.key)
      })
      state.purchases.unshift({
        id: nextId('p'),
        storeId: state.activeStoreId ?? '',
        locationId: state.standingLocationId,
        at: clock(),
        member: state.coMember,
        lines: rows.map((r) => ({ name: r.item.name, quantity: r.item.quantity })),
      })
      record('co', `${state.coMember} Bought ${rows.length} lines at ${storeById(state.activeStoreId)?.name ?? 'a Store'}`)
    }, 700)
    record('co', `${state.coMember} is Buying at ${storeById(state.activeStoreId)?.name ?? 'a Store'} — watch your Basket empty from underneath you`)
  }

  function coMemberCascade() {
    record('co', `${state.coMember} is deleting Walmart — the Cascade is coming to your open screens`)
    setTimeout(() => deleteStore('walmart', state.coMember), 700)
  }

  function renameItem(id: string, name: string) {
    const item = itemById(id)
    if (!item) return
    const clean = name.trim();
    const clash = state.items.find((i) => i.id !== id && i.name.toLowerCase() === clean.toLowerCase())
    if (clash) {
      toast(`“${clean}” already exists on a household-shared Item`, { position: 'top-center' })
      record('you', `Rename refused — ${clean} exists on Alex's row too`)
      return
    }
    item.name = clean
    record('you', `You renamed an Item to ${clean} (household-wide)`)
  }

  function deleteItem(id: string) {
    const item = itemById(id)
    if (!item) return
    const rows = state.listItems.filter((r) => r.itemId === id).length
    state.items = state.items.filter((i) => i.id !== id)
    state.listItems = state.listItems.filter((r) => r.itemId !== id)
    state.sheet = null
    toast(`Deleted ${item.name} — ${rows} List Item${rows === 1 ? '' : 's'} gone, every List it stood in kept`, { position: 'top-center' })
    record('you', `You deleted ${item.name} · ${rows} List Items erased, Lists and Store Tags survive`)
  }

  function setCategory(id: string, category: string) {
    const item = itemById(id)
    if (item) item.category = category
  }
  function setQuantity(id: string, quantity: string) {
    const item = itemById(id)
    if (item) item.quantity = quantity
  }
  function toggleTag(id: string, storeId: string) {
    const item = itemById(id)
    if (!item) return
    item.storeTags = item.storeTags.includes(storeId) ? item.storeTags.filter((t) => t !== storeId) : [...item.storeTags, storeId]
    record('you', `You ${item.storeTags.includes(storeId) ? 'Tagged' : 'unTagged'} ${item.name} ${storeById(storeId)?.name}`)
  }
  function addToList(id: string, listId: string) {
    if (state.listItems.some((r) => r.itemId === id && r.listId === listId)) return
    state.listItems.push({ id: nextId('li'), itemId: id, listId, status: 'needed' })
    flash(id)
    record('you', `You added ${itemById(id)?.name} to ${listById(listId)?.name}`)
  }
  function capture(name: string, listId: string, tags: string[]) {
    const clean = name.trim()
    if (!clean) return
    const existing = itemByName(clean)
    const id = existing?.id ?? nextId('i')
    if (!existing) state.items.push({ id, name: clean, category: '', quantity: '', storeTags: [...tags] })
    else tags.forEach((t) => !existing.storeTags.includes(t) && existing.storeTags.push(t))
    state.listItems.push({ id: nextId('li'), itemId: id, listId, status: inBasket.value.some((r) => r.key === id) ? 'in_basket' : 'needed' })
    state.sheet = null
    flash(id)
    toast(`${clean} stands in ${listById(listId)?.name}`, { position: 'top-center' })
    record('you', `You captured ${clean} into ${listById(listId)?.name}`)
  }

  function open(sheet: Sheet, payload: { itemId?: string, storeId?: string, door?: 'header' | 'buy' | 'bare' } = {}) {
    state.sheet = payload.itemId ? 'capture' : sheet
    state.sheetItemId = payload.itemId ?? null
    if (payload.itemId) state.sheet = 'item'
    if (payload.storeId) state.cascadeStoreId = payload.storeId
    if (payload.door) state.mintDoor = payload.door
    if (sheet === 'mint' && payload.door !== 'bare') state.mintFixStoreId = null
  }
  function close() {
    state.sheet = null
    state.sheetItemId = null
  }

  function setScenario(scenario: Scenario) {
    const form = state.arrivalForm
    Object.assign(state, base(scenario))
    state.arrivalForm = form
    record('you', `Scenario ${scenario}`)
  }
  function setArrivalForm(arrivalForm: ArrivalForm) {
    state.arrivalForm = arrivalForm
  }
  function reset() {
    resetScenarios()
    Object.assign(state, base(state.scenario))
  }
  function resetScenarios() {
    toast.dismiss()
  }

  const allLocations = computed(() => state.stores.flatMap((s) => s.locations.map((l) => ({ ...l, storeName: s.name }))))

  return {
    state,
    activeStore,
    standingLocation,
    kineticRows,
    inBasket,
    basketCount,
    gate,
    byCategory,
    shelfByStore,
    storeRoster,
    listsWithCounts,
    allLocations,
    itemTagsFor,
    itemsAtStore,
    itemById,
    itemByName,
    storeById,
    listById,
    deleteItem,
    filterMatches,
    check,
    pick,
    arrive,
    buy,
    mint,
    deleteStore,
    coMemberCheck,
    coMemberBuy,
    coMemberCascade,
    renameItem,
    setCategory,
    setQuantity,
    toggleTag,
    addToList,
    capture,
    open,
    close,
    setScenario,
    setArrivalForm,
    reset,
    arrivalLine,
  }
}
