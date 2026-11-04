<script setup lang="ts">
// GitHub redirects here with `?code=...`. The @supabase/ssr client exchanges that
// code for a session (PKCE verifier lives in a cookie), then we send the user on.
const redirect = useSupabaseCookieRedirect()
const target = redirect.pluck() || '/todos'

await navigateTo(target, { replace: true })
</script>

<template>
  <div class="flex min-h-[60vh] items-center justify-center">
    <UIcon
      name="i-lucide-loader-circle"
      class="size-8 animate-spin text-muted"
      aria-label="Finishing sign-in"
    />
  </div>
</template>
