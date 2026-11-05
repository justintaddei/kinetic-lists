<script setup lang="ts">
const user = useUser()
</script>

<template>
  <nav
    aria-label="Primary navigation"
    class="fixed bottom-[calc(1rem+env(safe-area-inset-bottom))] left-1/2 z-50 flex -translate-x-1/2 items-center gap-1 rounded-full border border-default/70 bg-default/80 p-1.5 shadow-lg backdrop-blur-xl"
  >
    <NuxtLink
      to="/"
      aria-label="Home"
      exact-active-class="text-highlighted!"
      class="flex size-11 items-center justify-center rounded-full text-muted transition-colors hover:bg-accented hover:text-default focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
    >
      <UIcon class="size-5" name="lucide:notebook-text" />
    </NuxtLink>
    <NuxtLink
      to="/edit"
      aria-label="Edit lists"
      exact-active-class="text-highlighted!"
      class="flex size-11 items-center justify-center rounded-full text-muted transition-colors hover:bg-accented hover:text-default focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
    >
      <UIcon class="size-5" name="lucide:notebook-pen" />
    </NuxtLink>
    <NuxtLink
      to="/profile"
      aria-label="Profile"
      exact-active-class="text-highlighted!"
      class="flex size-11 items-center justify-center rounded-full text-muted transition-colors hover:bg-accented hover:text-default focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
    >
      <UUser v-if="user" :avatar="user.avatar" />
      <UIcon v-else class="size-5" name="lucide:circle-user-round" />
    </NuxtLink>
  </nav>
</template>
