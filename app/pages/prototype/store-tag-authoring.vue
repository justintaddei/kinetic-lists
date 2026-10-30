<script setup lang="ts">
/**
 * PROTOTYPE ONLY — wayfinder ticket "Prototype Store Tag authoring: the capture
 * form and the Tag offer at Buy" (#13). Throwaway route, delete with the branch.
 *
 * Round 2, on the mobile frame Justin picked in round 1 (bottom tab bar +
 * drill-down + bottom sheet + FAB capture + chip input + modal confirm sheet),
 * built on shadcn-vue. Round 1's desktop shapes are in git history
 * (`proto(store-tag): round 1 …`); the settled answers ride every variant:
 * no Tag prompt at Buy, gate copy at capture + a count in the Basket, both
 * name-join paths, Location authoring, a bare Store is legal everywhere.
 *
 *   D — Store-home: the Kinetic View is the front tab, the capture sheet
 *       pre-ticks the Store you are standing at, Tags are removable chips on
 *       the Kinetic and Basket rows.
 *   E — List-home: the List is the drill-down with a Store filter chip row;
 *       rows stay clean and Tags live only on the Item sheet.
 *   F — Store-owns-Tags: the header picks the Active Store with a Select, the
 *       Kinetic rows are read-only, Tags are authored on the Store's own screen.
 *
 * No DB, no geocoder, no Realtime, no seams committed (#14/#4 own the seams, #3
 * owns the tables). In-memory state only.
 */
const route = useRoute();
const variants = [
  { key: "D", name: "Store-home" },
  { key: "E", name: "List-home" },
  { key: "F", name: "Store-owns-Tags" },
];
const current = computed(() => {
  const v = String(route.query.variant ?? "D").toUpperCase();
  return variants.some((x) => x.key === v) ? v : "D";
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

    <PrototypeVariantMobileKinetic v-if="current === 'D'" />
    <PrototypeVariantMobileLists v-if="current === 'E'" />
    <PrototypeVariantMobileStore v-if="current === 'F'" />

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
