<script setup lang="ts">
const user = useSupabaseUser();
const supabase = useSupabaseClient();

useSeoMeta({
  title: "Kinetic Lists",
  description: "Lists that keep up with you.",
});

const signingOut = ref(false);

async function signOut() {
  signingOut.value = true;
  await supabase.auth.signOut();
  await navigateTo("/");
}
</script>

<template>
  <main class="landing">
    <h1>Kinetic Lists</h1>
    <p class="tagline">Lists that keep up with you.</p>

    <div v-if="!user" class="actions">
      <NuxtLink class="button primary" to="/login"
        >Sign in with GitHub</NuxtLink
      >
    </div>

    <div v-else class="actions">
      <NuxtLink class="button primary" to="/app">Go to your lists</NuxtLink>
      <button class="button" :disabled="signingOut" @click="signOut">
        Sign out
      </button>
    </div>
  </main>
</template>

<style scoped>
.landing {
  max-width: 34rem;
  margin: 0 auto;
  padding: 6rem 1.5rem;
  text-align: center;
}

h1 {
  font-size: 2.25rem;
  margin: 0;
}

.tagline {
  color: #6b7280;
  margin: 0.5rem 0 2rem;
}

.actions {
  display: flex;
  gap: 0.75rem;
  justify-content: center;
  flex-wrap: wrap;
}

.button {
  display: inline-block;
  padding: 0.65rem 1.25rem;
  border-radius: 0.5rem;
  border: 1px solid #d1d5db;
  background: #fff;
  color: #111827;
  text-decoration: none;
  font: inherit;
  cursor: pointer;
}

.button.primary {
  background: #111827;
  border-color: #111827;
  color: #fff;
}

.button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
</style>
