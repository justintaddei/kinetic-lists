<script setup lang="ts">
/** PROTOTYPE ONLY — floating variant switcher for wayfinder #13. Hidden in production. */
const props = defineProps<{
  variants: { key: string; name: string }[];
  current: string;
}>();

const isDev = import.meta.dev;
const route = useRoute();
const router = useRouter();

const cycle = (delta: number) => {
  const keys = props.variants.map((v) => v.key);
  const i = Math.max(0, keys.indexOf(props.current));
  const next = keys[(i + delta + keys.length) % keys.length];
  router.replace({
    path: route.path,
    query: { ...route.query, variant: next },
  });
};

const active = computed(
  () => props.variants.find((v) => v.key === props.current) ?? props.variants[0]
);

onMounted(() => {
  const onKey = (e: KeyboardEvent) => {
    const t = e.target as HTMLElement | null;
    if (
      t &&
      (t.tagName === "INPUT" ||
        t.tagName === "TEXTAREA" ||
        t.isContentEditable)
    )
      return;
    if (e.key === "ArrowRight") cycle(1);
    if (e.key === "ArrowLeft") cycle(-1);
  };
  window.addEventListener("keydown", onKey);
  onUnmounted(() => window.removeEventListener("keydown", onKey));
});
</script>

<template>
  <nav v-if="isDev" class="switcher" aria-label="Prototype variant switcher">
    <button @click="cycle(-1)" title="Previous variant (←)">←</button>
    <span class="label">
      <b>{{ active?.key }}</b> {{ active?.name }}
    </span>
    <button @click="cycle(1)" title="Next variant (→)">→</button>
  </nav>
</template>

<style scoped>
.switcher {
  position: fixed;
  bottom: 12px;
  left: 50%;
  transform: translateX(-50%);
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.35rem 0.5rem;
  background: #111827;
  color: #fff;
  border-radius: 999px;
  box-shadow: 0 6px 20px rgba(0, 0, 0, 0.35);
  font: 500 13px/1.2 system-ui, sans-serif;
  z-index: 9999;
}

.switcher button {
  border: 0;
  border-radius: 999px;
  background: #374151;
  color: #fff;
  width: 26px;
  height: 26px;
  cursor: pointer;
  font: inherit;
}

.switcher button:hover {
  background: #4b5563;
}

.label {
  min-width: 12rem;
  text-align: center;
  white-space: nowrap;
}
</style>
