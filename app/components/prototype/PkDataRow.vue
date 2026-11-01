<script setup lang="ts">
/**
 * PROTOTYPE ONLY — wayfinder #11. The settled Data row of ADR-0024: `min-h-12`, the
 * row-leading 44px icon control that Checks the row, the name at `text-base`, one
 * quiet line joined by `·`, a hairline under each row, zero chips / badges /
 * chevrons, and no row buttons. `flash` marks a row that moved on the stream.
 */
import { CheckIcon } from '@lucide/vue'

const props = defineProps<{
  name: string
  quiet?: string
  pressed?: boolean
  flash?: boolean
  openAria?: string
}>()

const emit = defineEmits<{ (e: 'check'): void; (e: 'open'): void }>()
</script>

<template>
  <div class="flex items-center gap-1" :class="flash && 'animate-in fade-50 slide-in-from-left-2 duration-300'">
    <UiButton
      variant="ghost"
      size="icon"
      class="size-11 shrink-0"
      :class="pressed ? 'text-primary' : 'text-muted-foreground'"
      :aria-pressed="!!pressed"
      :aria-label="`Check ${name}`"
      @click="emit('check')"
    >
      <CheckIcon class="size-5" aria-hidden="true" />
    </UiButton>
    <button type="button" class="min-w-0 flex-1 py-3 text-start" :aria-label="openAria ?? `Open ${name}`" @click="emit('open')">
      <span class="block text-base font-medium truncate">{{ name }}</span>
      <span v-if="quiet" class="text-sm text-muted-foreground block truncate">{{ quiet }}</span>
    </button>
  </div>
</template>
