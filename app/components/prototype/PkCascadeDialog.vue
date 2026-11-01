<script setup lang="ts">
/**
 * PROTOTYPE ONLY — wayfinder #11. The Cascade confirmation, naming only what the
 * Household can see — Tags, standing rows, Members — and never the cascade's
 * arithmetic the glossary forbids as copy.
 */
const { state, storeById, itemsAtStore, close, deleteStore } = usePrototypeKinetic()

const store = computed(() => storeById(state.cascadeStoreId ?? state.activeStoreId) ?? state.stores[0] ?? null)
const tagged = computed(() => (store.value ? itemsAtStore(store.value.id) : []))
const doomed = computed(() =>
  store.value ? tagged.value.filter((i) => i.storeTags.filter((t) => t !== store.value!.id).length === 0) : [],
)
const rows = computed(() => {
  const ids = new Set(doomed.value.map((i) => i.id))
  return state.listItems.filter((r) => ids.has(r.itemId)).length
})
</script>

<template>
  <UiAlertDialog :open="state.sheet === 'cascade'" @update:open="(v: boolean) => !v && close()">
    <UiAlertDialogContent v-if="store" class="max-w-md">
      <UiAlertDialogHeader>
        <UiAlertDialogTitle>Delete {{ store.name }}?</UiAlertDialogTitle>
        <UiAlertDialogDescription data-cascade-copy>
          {{ tagged.length }} Store Tag{{ tagged.length === 1 ? '' : 's' }} come off. {{ doomed.length }} Item{{ doomed.length === 1 ? '' : 's' }} left
          with no Tag lose{{ doomed.length === 1 ? 's' : '' }} their {{ rows }} standing row{{ rows === 1 ? '' : 's' }} — invisible to every Member, in every
          List. {{ store.locations.length }} Location{{ store.locations.length === 1 ? '' : 's' }} go{{ store.locations.length === 1 ? 'es' : '' }} with the Store.
          Lists keep their names, and Purchases keep what they recorded.
        </UiAlertDialogDescription>
      </UiAlertDialogHeader>
      <UiAlertDialogFooter>
        <UiAlertDialogCancel data-cascade-cancel>Keep it</UiAlertDialogCancel>
        <UiAlertDialogAction data-cascade-confirm class="border-border text-destructive" @click="deleteStore(store.id)">
          Delete {{ store.name }}
        </UiAlertDialogAction>
      </UiAlertDialogFooter>
    </UiAlertDialogContent>
  </UiAlertDialog>
</template>
