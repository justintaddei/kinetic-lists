// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  modules: [
    "@nuxt/fonts",
    "@nuxt/image",
    "@nuxtjs/supabase",
    "@vueuse/nuxt/module",
  ],
  compatibilityDate: "2025-07-15",
  devtools: { enabled: true },
  supabase: {
    redirect: false,
    // Set to true after running `supabase gen types typescript --project-id <ref> > app/types/database.types.ts`
    types: false,
  },
});
