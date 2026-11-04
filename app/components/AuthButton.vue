<script setup lang="ts">
const supabase = useSupabaseClient()
const user = useSupabaseUser()

const displayName = computed(() => {
  const meta = user.value?.user_metadata as
    | { user_name?: string, login?: string, name?: string }
    | undefined
  return (
    meta?.user_name
    ?? meta?.login
    ?? meta?.name
    ?? user.value?.email
    ?? 'GitHub user'
  )
})

const avatarSrc = computed(() => {
  const meta = user.value?.user_metadata as { avatar_url?: string } | undefined
  return meta?.avatar_url
})

async function signOut() {
  const { error } = await supabase.auth.signOut()
  if (error) return
  // The module's client plugin clears `useSupabaseUser()` / `useSupabaseSession()`
  // on `onAuthStateChange`, so the header reacts without a full reload.
  await navigateTo('/')
}
</script>

<template>
  <UDropdownMenu
    v-if="user"
    :items="[
      [{ label: displayName, disabled: true }],
      [{ label: 'My lists', to: '/todos', icon: 'i-lucide-list-checks' }],
      [{ label: 'Sign out', icon: 'i-lucide-log-out', onSelect: signOut }]
    ]"
    :content="{ align: 'end' }"
  >
    <UButton
      color="neutral"
      variant="ghost"
      size="xs"
      :aria-label="`Account menu for ${displayName}`"
    >
      <UAvatar
        :src="avatarSrc"
        :alt="displayName"
        size="xs"
      />
      <span class="hidden sm:inline ms-1 text-sm">{{ displayName }}</span>
    </UButton>
  </UDropdownMenu>

  <UButton
    v-else
    color="neutral"
    variant="ghost"
    size="xs"
    icon="i-simple-icons-github"
    label="Sign in"
    to="/login"
  />
</template>
