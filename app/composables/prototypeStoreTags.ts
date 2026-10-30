/**
 * PROTOTYPE ONLY — wayfinder ticket "Prototype Store Tag authoring: the capture
 * form and the Tag offer at Buy" (#13).
 *
 * Fake Household data + in-memory acts, in v1 vocabulary (GLOSSARY.md,
 * ADR-0009..0014). No DB, no geocoder, no Realtime. Delete with the prototype.
 */

export type Status = "Needed" | "In Basket" | "Stocked";

export interface ProtoLocation {
  id: string;
  storeId: string;
  label: string;
  lat: number;
  lng: number;
  geofence: number;
}

export interface ProtoStore {
  id: string;
  name: string;
  /** A bare Store with zero Locations is legal, taggable, Pickable (ADR-0013). */
  locations: ProtoLocation[];
}

export interface ProtoItem {
  id: string;
  name: string;
  category: string;
  quantity: string;
  /** Store Tags: an Item may carry many, and may carry none. */
  storeTags: string[];
}

export interface ProtoList {
  id: string;
  name: string;
  items: { id: string; itemId: string; status: Status }[];
}

export interface ProtoArrival {
  id: string;
  memberId: string;
  locationId: string;
  at: string;
}

export interface ProtoPurchaseLine {
  itemName: string;
  quantity: string;
  storeName: string;
  locationLabel: string;
}

export interface ProtoPurchase {
  id: string;
  storeId: string;
  locationId: string | null;
  memberId: string;
  at: string;
  lines: ProtoPurchaseLine[];
}

let ids = 100;
const nextId = (p: string) => `${p}${++ids}`;

function seed() {
  const stores: ProtoStore[] = [
    {
      id: "s_walmart",
      name: "Walmart",
      locations: [
        {
          id: "l_walmart_main",
          storeId: "s_walmart",
          label: "Central St",
          lat: 42.1015,
          lng: -72.5811,
          geofence: 150,
        },
        {
          id: "l_walmart_broker",
          storeId: "s_walmart",
          label: "Broker Rd",
          lat: 42.1381,
          lng: -72.5212,
          geofence: 150,
        },
      ],
    },
    {
      id: "s_bigy",
      name: "Big Y",
      locations: [
        {
          id: "l_bigy_elm",
          storeId: "s_bigy",
          label: "Elm St",
          lat: 42.0955,
          lng: -72.5889,
          geofence: 150,
        },
      ],
    },
    // A bare Store: taggable, Pickable, no Location, no Geofence.
    { id: "s_tj", name: "Trader Joe's", locations: [] },
  ];

  const items: ProtoItem[] = [
    {
      id: "i_milk",
      name: "Milk",
      category: "Dairy",
      quantity: "1 gallon",
      storeTags: ["s_walmart"],
    },
    {
      id: "i_eggs",
      name: "Eggs",
      category: "Dairy",
      quantity: "a dozen",
      storeTags: ["s_walmart", "s_bigy"],
    },
    {
      id: "i_spinach",
      name: "Spinach",
      category: "Produce",
      quantity: "1 bag",
      storeTags: [],
    },
    {
      id: "i_towels",
      name: "Paper towels",
      category: "Household",
      quantity: "6 pack",
      storeTags: ["s_bigy"],
    },
    {
      id: "i_coffee",
      name: "Coffee",
      category: "Beverages",
      quantity: "12 oz",
      storeTags: ["s_tj"],
    },
    {
      id: "i_chips",
      name: "Tortilla chips",
      category: "Snacks",
      quantity: "2 bags",
      storeTags: [],
    },
  ];

  const lists: ProtoList[] = [
    {
      id: "l_weekly",
      name: "Weekly groceries",
      items: [
        { id: "li_milk", itemId: "i_milk", status: "In Basket" },
        { id: "li_eggs", itemId: "i_eggs", status: "In Basket" },
        { id: "li_spinach", itemId: "i_spinach", status: "In Basket" },
        { id: "li_towels", itemId: "i_towels", status: "Needed" },
        { id: "li_coffee", itemId: "i_coffee", status: "Stocked" },
      ],
    },
    {
      id: "l_party",
      name: "Party",
      items: [
        { id: "li_chips", itemId: "i_chips", status: "In Basket" },
        {
          id: "li_coffee2",
          itemId: "i_coffee",
          status: "Needed",
        },
      ],
    },
  ];

  return {
    household: { name: "The Fridges", members: ["Dana", "Alex"] },
    me: "Dana",
    stores,
    items,
    lists,
    purchases: [] as ProtoPurchase[],
    arrivals: [
      {
        id: "a_1",
        memberId: "Alex",
        locationId: "l_walmart_main",
        at: "10:41",
      },
    ] as ProtoArrival[],
    pickedStoreId: "s_walmart" as string | null,
  };
}

export type PrototypeState = ReturnType<typeof seed>;

export function usePrototypeHousehold() {
  const state = useState<PrototypeState>("prototype-household", seed);

  const storeNameSuggestion = (name: string) =>
    name.trim().toLowerCase();

  /** Case-insensitive name-join lookup: which Stores does this typed name hit? */
  const storesNamed = (typed: string) =>
    state.value.stores.filter(
      (s) => s.name.toLowerCase() === storeNameSuggestion(typed)
    );

  const itemsNamed = (typed: string) =>
    state.value.items.filter(
      (i) => i.name.toLowerCase() === storeNameSuggestion(typed)
    );

  const categoriesInUse = () => [
    ...new Set(state.value.items.map((i) => i.category).filter(Boolean)),
  ];

  const storeById = (id: string | null) =>
    state.value.stores.find((s) => s.id === id) ?? null;

  const itemById = (id: string) =>
    state.value.items.find((i) => i.id === id) ?? null;

  const locationById = (id: string) => {
    for (const s of state.value.stores) {
      const l = s.locations.find((x) => x.id === id);
      if (l) return l;
    }
    return null;
  };

  /** Tag: additive, never replaces (ADR-0013). */
  const tagItem = (itemId: string, storeId: string) => {
    const item = itemById(itemId);
    if (!item || item.storeTags.includes(storeId)) return;
    item.storeTags = [...item.storeTags, storeId];
  };

  const untagItem = (itemId: string, storeId: string) => {
    const item = itemById(itemId);
    if (!item) return;
    item.storeTags = item.storeTags.filter((s) => s !== storeId);
  };

  const addLocation = (
    storeId: string,
    label: string,
    lat: number,
    lng: number,
    geofence = 150
  ) => {
    const store = storeById(storeId);
    if (!store) return null;
    const location: ProtoLocation = {
      id: nextId("l_"),
      storeId,
      label: label || "New place",
      lat,
      lng,
      geofence,
    };
    store.locations.push(location);
    return location;
  };

  /** Name-join branch: an existing name adds a Location, it never mints a second Store. */
  const joinStoreLocation = (
    storeId: string,
    label: string,
    lat: number,
    lng: number
  ) => addLocation(storeId, label, lat, lng);

  const createStore = (
    name: string,
    lat: number | null,
    lng: number | null
  ) => {
    const store: ProtoStore = {
      id: nextId("s_"),
      name: name.trim() || "Unnamed store",
      locations: [],
    };
    state.value.stores.push(store);
    if (lat !== null && lng !== null) addLocation(store.id, "", lat, lng);
    return store;
  };

  const setGeofence = (locationId: string, meters: number) => {
    const l = locationById(locationId);
    if (l) l.geofence = Math.max(10, meters || 0);
  };

  const renameLocation = (locationId: string, label: string) => {
    const l = locationById(locationId);
    if (l) l.label = label || l.label;
  };

  /** Capture: one Item per name per Household, so a repeat name joins the Item. */
  const captureItem = (input: {
    name: string;
    category: string;
    quantity: string;
    storeTags?: string[];
  }) => {
    const existing = itemsNamed(input.name)[0] ?? null;
    const tags = input.storeTags ?? [];
    if (existing) {
      for (const t of tags) tagItem(existing.id, t);
      return { item: existing, joined: true };
    }
    const item: ProtoItem = {
      id: nextId("i_"),
      name: input.name.trim() || "Untitled item",
      category: input.category.trim(),
      quantity: input.quantity.trim(),
      storeTags: [...tags],
    };
    state.value.items.push(item);
    const list = state.value.lists[0];
    list.items.push({ id: nextId("li_"), itemId: item.id, status: "Needed" });
    return { item, joined: false };
  };

  const basket = () => {
    const rows: {
      listId: string;
      listName: string;
      listItemId: string;
      item: ProtoItem;
    }[] = [];
    for (const list of state.value.lists)
      for (const li of list.items) {
        const item = itemById(li.itemId);
        if (li.status === "In Basket" && item)
          rows.push({
            listId: list.id,
            listName: list.name,
            listItemId: li.id,
            item,
          });
      }
    return rows;
  };

  /** The Kinetic View: Needed List Items at the Active Store, cross-List. */
  const kineticView = (storeId: string | null) => {
    if (!storeId) return [];
    const rows: { listName: string; item: ProtoItem }[] = [];
    for (const list of state.value.lists)
      for (const li of list.items) {
        const item = itemById(li.itemId);
        if (
          li.status === "Needed" &&
          item &&
          item.storeTags.includes(storeId)
        )
          rows.push({ listName: list.name, item });
      }
    return rows;
  };

  /** Items in the Basket that carry no tag for this Store — the Tag offer's subjects. */
  const untaggedAt = (rows: ReturnType<typeof basket>, storeId: string) =>
    rows.filter((r) => !r.item.storeTags.includes(storeId));

  /** Buy: append-only Purchase naming Store *and* Location, lines snapshot both. */
  const buy = (storeId: string, locationId: string | null) => {
    const store = storeById(storeId);
    if (!store) return null;
    const rows = basket();
    const location = locationId ? locationById(locationId) : null;
    const purchase: ProtoPurchase = {
      id: nextId("p_"),
      storeId,
      locationId: location?.id ?? null,
      memberId: state.value.me,
      at: new Date().toLocaleTimeString([], {
        hour: "2-digit",
        minute: "2-digit",
      }),
      lines: rows.map((r) => ({
        itemName: r.item.name,
        quantity: r.item.quantity,
        storeName: store.name,
        locationLabel: location?.label ?? "(no Location)",
      })),
    };
    for (const r of rows)
      for (const list of state.value.lists) {
        const li = list.items.find((x) => x.id === r.listItemId);
        if (li) li.status = "Stocked";
      }
    state.value.purchases.unshift(purchase);
    return { purchase, untagged: untaggedAt(rows, storeId) };
  };

  const pick = (storeId: string) => {
    state.value.pickedStoreId = storeId;
  };

  return {
    state,
    storesNamed,
    itemsNamed,
    categoriesInUse,
    storeById,
    itemById,
    locationById,
    tagItem,
    untagItem,
    addLocation,
    joinStoreLocation,
    createStore,
    setGeofence,
    renameLocation,
    captureItem,
    basket,
    kineticView,
    untaggedAt,
    buy,
    pick,
  };
}

/**
 * The seam worth faking (ticket #5): a device Position, read once, never
 * persisted. Falls back to a fake report so the prototype runs headless.
 */
export function usePrototypePosition() {
  const status = ref<"idle" | "reading" | "ok" | "denied">("idle");
  const coords = ref<{ lat: number; lng: number } | null>(null);
  const source = ref<"device" | "fake">("device");
  const label = computed(() => {
    if (status.value !== "ok" || !coords.value) return "no Position read";
    return `${coords.value.lat.toFixed(5)}, ${coords.value.lng.toFixed(
      5
    )} (${source.value})`;
  });

  const read = () => {
    status.value = "reading";
    const fake = () => {
      source.value = "fake";
      coords.value = { lat: 42.10154, lng: -72.5811 };
      status.value = "ok";
    };
    if (!import.meta.client || !navigator.geolocation) {
      fake();
      return;
    }
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        source.value = "device";
        coords.value = { lat: pos.coords.latitude, lng: pos.coords.longitude };
        status.value = "ok";
      },
      () => fake(),
      { enableHighAccuracy: true, timeout: 4000, maximumAge: 0 }
    );
  };

  return { status, coords, source, label, read };
}
