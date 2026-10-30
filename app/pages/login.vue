<script setup lang="ts">
const supabase = useSupabaseClient();
const session = useSupabaseSession();

definePageMeta({ title: "Sign in" });

// Signed in already? Skip the picker.
if (session.value) {
  await navigateTo("/app", { replace: true });
}

const loading = ref(false);
const message = ref<string | null>(null);

async function signInWithGitHub() {
  loading.value = true;
  message.value = null;

  const { data, error } = await supabase.auth.signInWithOAuth({
    provider: "github",
    options: {
      // Must be listed in Supabase → Authentication → URL Configuration → Redirect URLs
      redirectTo: `${window.location.origin}/confirm`,
    },
  });

  if (error) {
    message.value = error.message;
    loading.value = false;
    return;
  }

  if (data.url) {
    // Assign (not replace) so GitHub keeps the app as the OAuth referrer
    window.location.assign(data.url);
    return;
  }

  loading.value = false;
  message.value =
    "Supabase returned no authorization URL. Is the GitHub provider enabled?";
}
</script>

<template>
  <main class="login">
    <h1>Sign in</h1>
    <p class="hint">Kinetic Lists uses GitHub to sign you in.</p>

    <button class="button" :disabled="loading" @click="signInWithGitHub">
      {{ loading ? "Redirecting to GitHub…" : "Continue with GitHub" }}
    </button>

    <p v-if="message" class="error">{{ message }}</p>

    <p class="hint">
      <NuxtLink to="/">Back home</NuxtLink>
    </p>
  </main>
</template>

<style scoped>
.login {
  max-width: 26rem;
  margin: 0 auto;
  padding: 6rem 1.5rem;
  text-align: center;
}

h1 {
  font-size: 1.75rem;
  margin: 0 0 0.5rem;
}

.hint {
  color: #6b7280;
  margin: 0 0 2rem;
}

.button {
  padding: 0.65rem 1.5rem;
  border-radius: 0.5rem;
  border: 1px solid #111827;
  background: #111827;
  color: #fff;
  font: inherit;
  cursor: pointer;
}

.button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.error {
  color: #b91c1c;
  margin-top: 1rem;
}
</style>
