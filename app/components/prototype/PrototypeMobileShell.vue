<script setup lang="ts">
/**
 * PROTOTYPE ONLY — wayfinder #13, round 2. The mobile frame Justin picked:
 * a phone column, a bottom tab bar as the spine, a FAB that launches capture,
 * drill-down for detail. Shared by the three v2 variants.
 */
const props = defineProps<{
  tabs: { key: string; label: string }[];
  active: string;
  captureLabel?: string;
}>();

const emit = defineEmits<{
  (e: "update:active", key: string): void;
  (e: "capture"): void;
}>();
</script>

<template>
  <div
    class="relative mx-auto flex h-[812px] max-w-[420px] flex-col overflow-hidden rounded-[28px] border bg-background shadow-xl"
  >
    <header class="border-b bg-background px-4 pb-2 pt-3">
      <slot name="header" />
    </header>

    <main class="flex-1 space-y-4 overflow-y-auto px-4 py-4">
      <slot />
    </main>

    <button
      class="absolute bottom-[72px] right-4 z-20 rounded-full bg-primary px-4 py-3 text-sm font-semibold text-primary-foreground shadow-lg"
      @click="emit('capture')"
    >
      {{ props.captureLabel ?? "+ Capture" }}
    </button>

    <nav
      class="flex border-t bg-background pb-[env(safe-area-inset-bottom)]"
      aria-label="Prototype tabs"
    >
      <button
        v-for="tab in props.tabs"
        :key="tab.key"
        class="flex-1 px-1 py-3 text-[11px] font-medium leading-tight"
        :class="
          props.active === tab.key
            ? 'text-primary'
            : 'text-muted-foreground'
        "
        @click="emit('update:active', tab.key)"
      >
        {{ tab.label }}
      </button>
    </nav>
  </div>
</template>
