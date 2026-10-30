import tailwindcss from "@tailwindcss/vite";

// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  modules: [
    "@nuxt/fonts",
    "@nuxt/image",
    "@nuxtjs/supabase",
    "@vueuse/nuxt/module",
    "shadcn-nuxt",
  ],
  // Tailwind v4 has no tailwind.config.js: tokens live in the CSS entry (@theme)
  css: ["~/assets/css/main.css"],
  vite: {
    plugins: [tailwindcss()],
  },
  shadcn: {
    componentDir: "~/components/ui",
  },
  compatibilityDate: "2025-07-15",
  devtools: { enabled: true },
  supabase: {
    // Global middleware sends signed-out visitors to `login` for the routes in `include`
    redirect: true,
    redirectOptions: {
      login: "/login",
      // OAuth/email callback target — the module forces `ssr: false` here so the
      // PKCE code is exchanged in the browser, where the cookies can be written
      callback: "/confirm",
      // Only guard the app area; landing + auth pages stay public.
      // `/app` is listed separately because the `**` pattern needs a slash.
      include: ["/app", "/app/**"],
      // Remember the attempted URL so `/confirm` can send users back to it
      saveRedirectToCookie: true,
    },
    // Path (not a boolean) to the generated row types — regenerate with `pnpm db:types`
    types: "~/types/database.types.ts",
  },
});
