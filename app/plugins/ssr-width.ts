// The shadcn-vue Nuxt guide's step 5, verbatim in intent: components that swap chrome at a
// breakpoint (Drawer/Sheet) read the viewport width during SSR. Without a provided width they
// guess, and the guess mismatches on hydration. 430 CSS px is v1's reference phone viewport
// (ADR-0020: phone-first; desktop is the same column in a container, not a layout).
import { provideSSRWidth } from "@vueuse/core";

export default defineNuxtPlugin((nuxtApp) => {
  // `provideSSRWidth(width, app)` is the plugin-shaped form: outside `setup()` the second argument is
  // required, otherwise Vue warns "provide() can only be used inside setup()" and provides nothing.
  provideSSRWidth(430, nuxtApp.vueApp);
});
