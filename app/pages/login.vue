<script setup lang="ts">
const { signInWithGitHub } = useSignInWithGitHub()

definePageMeta({
  // Reached by the `redirect` middleware of @nuxtjs/supabase, so it must stay public.
  title: 'Sign in'
})
</script>

<template>
  <UContainer class="flex min-h-[60vh] items-center justify-center py-16">
    <UCard class="w-full max-w-sm">
      <template #header>
        <div class="flex flex-col gap-1">
          <h1 class="text-lg font-semibold">
            Sign in to Kinetic Lists
          </h1>
          <p class="text-sm text-muted">
            Todo lists are private to your account: Postgres row-level security
            scopes every row to your user id.
          </p>
        </div>
      </template>

      <UButton
        block
        size="lg"
        color="neutral"
        variant="subtle"
        icon="i-simple-icons-github"
        label="Continue with GitHub"
        @click="signInWithGitHub()"
      />

      <template #footer>
        <p class="text-xs text-muted">
          Locally this talks to the stack on <code>127.0.0.1:55321</code>. The
          GitHub OAuth app must list
          <code>http://127.0.0.1:55321/auth/v1/callback</code> as its callback
          URL.
        </p>
      </template>
    </UCard>
  </UContainer>
</template>
