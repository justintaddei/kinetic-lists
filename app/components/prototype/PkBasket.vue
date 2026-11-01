<script setup lang="ts">
/**
 * PROTOTYPE ONLY — wayfinder #11. The Basket, and the question of where the app's
 * reason for existing lives: the Basket is the verb's home, so Buy sits as the
 * one full-width verb under a hairline (Ticket 6's footer), and the unTagged rows
 * sit after the Store's own, named as the Gate's subject.
 */
import { ShoppingBasketIcon } from '@lucide/vue'
import PkDataRow from './PkDataRow.vue'

const { state, inBasket, activeStore, standingLocation, gate, check, open, buy } = usePrototypeKinetic()

const atStore = computed(() => inBasket.value.filter((r) => r.atStore))
const noTag = computed(() => inBasket.value.filter((r) => !r.atStore))
const verb = computed(() => (activeStore.value ? `Buy at ${activeStore.value.name}${standingLocation.value ? ` · ${standingLocation.value.label}` : ''}` : 'Buy — name this shop'))
</script>

<template>
  <section aria-label="Basket" data-screen="basket">
    <header class="py-3">
      <p class="font-medium">In Basket</p>
      <p class="text-sm text-muted-foreground">
        {{ gate.basket }} lines
        <template v-if="activeStore"> at {{ activeStore.name }}<template v-if="gate.untaggedAtStore"> · {{ gate.untaggedAtStore }} with no Tag here</template></template>
        <template v-else>, and no Store is picked</template>
      </p>
    </header>

    <UiEmpty v-if="inBasket.length === 0" class="py-12" data-basket-empty>
      <UiEmptyHeader>
        <UiEmptyMedia variant="icon"><ShoppingBasketIcon aria-hidden="true" /></UiEmptyMedia>
        <UiEmptyTitle>The Basket is standing empty</UiEmptyTitle>
        <UiEmptyDescription>
          Buy Claims every row in it and leaves every List whole. {{ state.purchases.length ? `Your last Buy: ${state.purchases.length} purchase${state.purchases.length > 1 ? 's' : ''}.` : 'Nothing Bought yet.' }}
        </UiEmptyDescription>
      </UiEmptyHeader>
    </UiEmpty>

    <template v-else>
      <ul data-basket-rows>
        <template v-for="row in atStore" :key="row.key">
          <li>
            <PkDataRow
              :name="row.item.name"
              :quiet="`${row.item.quantity} · ${row.item.category} · ${row.lists.map((l) => l.name).join(', ')}`"
              :pressed="true"
              :flash="state.live.includes(row.key)"
              :open-aria="`Open ${row.item.name}`"
              @check="check(row.key)"
              @open="open('item', { itemId: row.key })"
            />
          </li>
          <UiSeparator />
        </template>
      </ul>

      <section v-if="noTag.length" class="pt-2" data-untagged-group>
        <h2 class="text-sm text-muted-foreground pb-1">With no Tag at {{ activeStore?.name ?? 'any Store' }}</h2>
        <ul>
          <template v-for="row in noTag" :key="row.key">
            <li>
              <PkDataRow
                :name="row.item.name"
                :quiet="`no Store Tag — Buy Claims it, no Store's view will show it`"
                :pressed="true"
                :flash="state.live.includes(row.key)"
                :open-aria="`Open ${row.item.name}`"
                @check="check(row.key)"
                @open="open('item', { itemId: row.key })"
              />
            </li>
            <UiSeparator />
          </template>
        </ul>
      </section>

      <footer class="pt-4">
        <UiSeparator class="mb-3" />
        <UiButton class="w-full" data-buy @click="buy()">
          {{ verb }}
        </UiButton>
        <p v-if="state.purchases.length" class="text-sm text-muted-foreground pt-2">
          Last Buy {{ state.purchases[0].at }} · {{ state.purchases[0].lines.length }} lines
          <template v-if="state.purchases[0].locationId"> · Location named</template>
          <template v-else> · no Location recorded</template>
        </p>
      </footer>
    </template>
  </section>
</template>
