<script setup lang="ts">
/** PROTOTYPE ONLY — surfaces the full simulated state after every act (wayfinder #13). */
const { state } = usePrototypeHousehold();
const open = ref(false);
</script>

<template>
  <section class="state">
    <button class="toggle" @click="open = !open">
      {{ open ? "Hide" : "Show" }} simulated state
    </button>
    <pre v-if="open">{{ state }}</pre>
  </section>
</template>

<style scoped>
.state {
  margin: 1rem 0 5rem;
}

.toggle {
  border: 1px dashed #9ca3af;
  background: transparent;
  color: #4b5563;
  border-radius: 0.5rem;
  padding: 0.35rem 0.7rem;
  font: 500 12px/1.2 system-ui, sans-serif;
  cursor: pointer;
}

pre {
  background: #0b1220;
  color: #d1d5db;
  padding: 0.75rem;
  border-radius: 0.5rem;
  font-size: 11px;
  overflow: auto;
  max-height: 24rem;
  white-space: pre-wrap;
}
</style>
