<script setup lang="ts">
/**
 * PROTOTYPE ONLY — wayfinder #13. The Household screen: its Members, and each
 * Store as a tag namespace with its Locations, the Geofence shared by every
 * Member, a Location added from a Position, and the Items that carry its Tag.
 */
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Separator } from "@/components/ui/separator";

const { state, addLocation, setGeofence, untagItem } = usePrototypeHousehold();

const draft = ref<{ storeId: string; label: string } | null>(null);
const lat = ref<number | null>(null);
const lng = ref<number | null>(null);

const itemsTaggedWith = (storeId: string) =>
  state.value.items.filter((i) => i.storeTags.includes(storeId));

function add() {
  if (!draft.value) return;
  addLocation(
    draft.value.storeId,
    draft.value.label || "New place",
    lat.value ?? 42.10154,
    lng.value ?? -72.5811
  );
  draft.value = null;
  lat.value = null;
  lng.value = null;
}
</script>

<template>
  <div class="space-y-4">
    <Card>
      <CardHeader>
        <CardTitle class="text-base">{{ state.household.name }}</CardTitle>
      </CardHeader>
      <CardContent class="text-sm text-muted-foreground">
        Members {{ state.household.members.join(", ") }} — you are
        {{ state.me }}. Members are equal; every Geofence here is one
        shared judgement.
      </CardContent>
    </Card>

    <Card v-for="store in state.stores" :key="store.id">
      <CardHeader>
        <CardTitle class="text-base">{{ store.name }}</CardTitle>
      </CardHeader>
      <CardContent class="space-y-3">
        <p
          v-if="!store.locations.length"
          class="rounded-md bg-muted px-3 py-2 text-xs text-muted-foreground"
        >
          A bare Store: taggable, Pickable, and nothing will ever suggest it —
          it has no Location to be Inside.
        </p>

        <div v-for="location in store.locations" :key="location.id" class="space-y-1">
          <div class="flex items-center justify-between gap-2 text-sm">
            <span>{{ location.label }}</span>
            <Label class="flex items-center gap-2 text-xs text-muted-foreground">
              Geofence
              <Input
                type="number"
                class="h-8 w-20"
                :model-value="String(location.geofence)"
                @update:model-value="setGeofence(location.id, Number($event))"
              />
              m
            </Label>
          </div>
          <p class="text-xs text-muted-foreground">
            {{ location.lat.toFixed(5) }}, {{ location.lng.toFixed(5) }}
          </p>
        </div>

        <Button
          size="sm"
          variant="outline"
          @click="draft = { storeId: store.id, label: '' }"
        >
          + Location from where I am
        </Button>

        <Separator />

        <div class="space-y-1.5">
          <p class="text-xs font-medium uppercase text-muted-foreground">
            Items tagged here
          </p>
          <p
            v-if="!itemsTaggedWith(store.id).length"
            class="text-xs text-muted-foreground"
          >
            Nothing carries this Store's Tag.
          </p>
          <div
            v-for="item in itemsTaggedWith(store.id)"
            :key="item.id"
            class="flex items-center justify-between gap-2 text-sm"
          >
            <span>{{ item.name }}</span>
            <button
              class="text-xs font-medium text-destructive"
              @click="untagItem(item.id, store.id)"
            >
              Remove Tag
            </button>
          </div>
        </div>
      </CardContent>
    </Card>

    <Card v-if="draft">
      <CardHeader>
        <CardTitle class="text-base">New Location</CardTitle>
      </CardHeader>
      <CardContent class="space-y-3">
        <div class="space-y-1.5">
          <Label for="hp-label">Place label</Label>
          <Input id="hp-label" v-model="draft.label" placeholder="Broker Rd" />
        </div>
        <PrototypePositionRow v-model:lat="lat" v-model:lng="lng" />
        <div class="flex gap-2">
          <Button class="flex-1" @click="add">Add Location</Button>
          <Button variant="outline" @click="draft = null">Cancel</Button>
        </div>
      </CardContent>
    </Card>

    <Card>
      <CardHeader>
        <CardTitle class="text-base">Purchases</CardTitle>
      </CardHeader>
      <CardContent class="space-y-2">
        <p
          v-if="!state.purchases.length"
          class="text-xs text-muted-foreground"
        >
          No Purchases yet. A Purchase is append-only: it names a Store and a
          Location and snapshots its lines.
        </p>
        <p
          v-for="purchase in state.purchases"
          :key="purchase.id"
          class="text-xs text-muted-foreground"
        >
          {{ purchase.at }} · {{ purchase.lines.length }} line(s) ·
          {{ state.stores.find((s) => s.id === purchase.storeId)?.name }}
          {{
            purchase.locationId
              ? state.stores
                  .flatMap((s) => s.locations)
                  .find((l) => l.id === purchase.locationId)?.label
              : "(no Location)"
          }}
        </p>
      </CardContent>
    </Card>
  </div>
</template>
