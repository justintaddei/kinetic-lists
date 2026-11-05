// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  modules: [
    '@nuxt/eslint',
    '@nuxt/ui',
    '@nuxt/image',
    '@vueuse/nuxt/module',
    '@nuxtjs/supabase'
  ],

  devtools: {
    enabled: false
  },

  css: ['~/assets/css/main.css'],

  routeRules: {
    '/': { prerender: true }
  },

  compatibilityDate: '2026-06-30',

  eslint: {
    config: {
      stylistic: {
        commaDangle: 'never',
        braceStyle: '1tbs'
      }
    }
  },

  supabase: {
    // Global route middleware: unauthenticated visits to `include` go to `login`.
    redirect: true,
    redirectOptions: {
      login: '/login',
      // Must also appear in auth.additional_redirect_urls (supabase/config.toml).
      callback: '/auth/callback',
      exclude: ['/login'],
      // Remember the attempted URL in a cookie so the callback page can send the
      // user back to it. (Requires `cookiePrefix`; the cookie name is
      // `${cookiePrefix}-redirect-path`.)
      saveRedirectToCookie: true
    },
    // Name prefix for the sb-* auth cookies.
    cookiePrefix: 'sb',
    types: '~/types/database.types.ts',
    // Secure cookies need https; localhost dev runs over http.
    cookieOptions: { secure: process.env.NODE_ENV === 'production' }
  }
})
