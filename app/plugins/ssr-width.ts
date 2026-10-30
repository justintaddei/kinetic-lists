import { provideSSRWidth } from "@vueuse/core";

/**
 * PROTOTYPE ONLY — shadcn-vue (reka-ui) sheets read the viewport width during
 * SSR; without a fixed value every sheet hydration mismatches on a phone frame.
 */
export default defineNuxtPlugin({
  name: "prototype-ssr-width",
  setup() {
    provideSSRWidth(430);
  },
});
