// https://nuxt.com/docs/api/configuration/nuxt-config
import tailwindcss from "@tailwindcss/vite"

export default defineNuxtConfig({
  modules: [
    "@nuxt/fonts",
    "@nuxt/image",
    "@nuxtjs/supabase",
    "@vueuse/nuxt/module",
    "shadcn-nuxt",
  ],
  // UI foundation: shadcn-vue on Tailwind v4 (ADR-0020). The entry is the CLI's target.
  css: ["~/assets/css/tailwind.css"],
  vite: {
    plugins: [tailwindcss()],
  },
  shadcn: {
    componentDir: "~/components/ui",
  },
  app: {
    head: {
      meta: [
        // viewport-fit=cover is what makes the safe-area insets real on a phone.
        {
          name: "viewport",
          content: "width=device-width, initial-scale=1, viewport-fit=cover",
        },
        // Phone chrome follows the system theme, matching the --background token.
        { name: "theme-color", media: "(prefers-color-scheme: light)", content: "#fafafa" },
        { name: "theme-color", media: "(prefers-color-scheme: dark)", content: "#0a0a0a" },
      ],
    },
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
