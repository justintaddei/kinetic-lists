<script setup lang="ts">
/**
 * PROTOTYPE ONLY — wayfinder ticket "Prototype Store Tag authoring: the capture
 * form and the Tag offer at Buy" (#13). Throwaway route, delete with the branch.
 *
 * Plan: three structurally different takes on Store Tag authoring (capture form
 * + the Tag act at Buy), switchable via `?variant=`, on fake Household data.
 *
 *   A — Capture sheet: item-first; Store Tags as capture checkboxes; Tag offer is
 *       one prompt row per untagged Item, after the Purchase.
 *   B — Fast capture: capture carries no Store at all; tags live on a per-Item
 *       drawer; one bulk Tag prompt naming every untagged Item after Buy.
 *   C — Store-first: the Active Store frames the screen; the capture composer
 *       inherits it as a pre-applied tag; untagged Items show as a count.
 *
 * No DB, no geocoder, no Realtime, no seams committed (#14/#4 own the seams, #3
 * owns the tables). In-memory state only.
 */
const route = useRoute();
const variants = [
  { key: "A", name: "Capture sheet" },
  { key: "B", name: "Fast capture + bulk Tag" },
  { key: "C", name: "Store-first" },
];
const current = computed(() => {
  const v = String(route.query.variant ?? "A").toUpperCase();
  return variants.some((x) => x.key === v) ? v : "A";
});

useSeoMeta({
  title: `Prototype · Store Tag authoring (${current.value})`,
  titleTemplate: "%s",
});
</script>

<template>
  <main class="proto">
    <p class="banner">
      PROTOTYPE — wayfinder #13 · Store Tag authoring · in-memory fake data ·
      <span class="keys">← / → cycles</span> ·
      <NuxtLink to="/">back</NuxtLink>
    </p>

    <PrototypeVariantCaptureSheet v-if="current === 'A'" />
    <PrototypeVariantFastCapture v-if="current === 'B'" />
    <PrototypeVariantStoreFirst v-if="current === 'C'" />

    <PrototypeStatePanel />
    <PrototypeSwitcher :variants="variants" :current="current" />
  </main>
</template>

<style scoped>
.proto {
  display: block;
  min-height: 100vh;
  background: #f8fafc;
}

.banner {
  background: #fef3c7;
  border-bottom: 1px solid #fcd34d;
  color: #92400e;
  font: 600 12px/1.5 system-ui, sans-serif;
  padding: 0.4rem 1rem;
  margin: 0;
  text-align: center;
}

.keys {
  color: #b45309;
}
</style>
