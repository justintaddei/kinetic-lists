<script setup lang="ts">
const supabase = useSupabaseClient();
const session = useSupabaseSession();
const redirect = useSupabaseCookieRedirect();

definePageMeta({ title: "Signing in…" });

// OAuth lands here with ?code=…&state=… . supabase-js exchanges that code for a
// session inside the browser client (this route is forced to ssr: false), so the
// job here is to wait for it and then hand the user to their destination.
const intended = redirect.path.value ?? "/app";
// Only follow in-app relative targets — never an absolute URL from the query string.
const target =
  intended.startsWith("/") && !intended.startsWith("//") ? intended : "/app";

const message = ref("Completing sign-in…");

async function completeSignIn() {
  for (let attempt = 0; attempt < 15; attempt++) {
    const { data, error } = await supabase.auth.getSession();

    if (error) {
      message.value = error.message;
      return;
    }

    if (data.session) {
      session.value = data.session;
      redirect.pluck();
      await navigateTo(target, { replace: true });
      return;
    }

    await new Promise((resolve) => setTimeout(resolve, 200));
  }

  message.value =
    "Sign-in did not complete. Head back to the login page and try again.";
}

await completeSignIn();
</script>

<template>
  <main class="confirm">
    <p>{{ message }}</p>
    <p v-if="message.includes('login page')">
      <NuxtLink class="link" to="/login">Back to sign in</NuxtLink>
    </p>
  </main>
</template>

<style scoped>
.confirm {
  max-width: 26rem;
  margin: 0 auto;
  padding: 6rem 1.5rem;
  text-align: center;
  color: #6b7280;
}

.link {
  color: #111827;
}
</style>
