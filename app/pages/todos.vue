<script setup lang="ts">
import type { Database } from '~/types/database.types'

// Match the columns the query selects (the full `Row` type includes `user_id`).
type Todo = Pick<
  Database['public']['Tables']['todos']['Row'],
  'id' | 'title' | 'is_complete' | 'created_at'
>

definePageMeta({
  title: 'My lists'
})

const user = useSupabaseUser()
const toast = useToast()
// Browser Supabase client from @nuxtjs/supabase: it sends the publishable key plus
// the session cookie (read from the request on SSR, from storage in the browser),
// so Postgres applies the `authenticated` RLS policies on every query.
const supabase = useSupabaseClient<Database>()

const {
  data: todos,
  pending,
  error,
  refresh
} = await useAsyncData('todos', async () => {
  const { data, error: queryError } = await supabase
    .from('todos')
    .select('id, title, is_complete, created_at')
    .order('id', { ascending: false })

  if (queryError) {
    throw createError({ statusCode: 500, statusMessage: queryError.message })
  }
  return data
})

const title = ref('')
const saving = ref(false)

async function addTodo() {
  const value = title.value.trim()
  if (!value || saving.value) return

  saving.value = true
  try {
    // `user_id` is filled by the column default (`auth.uid()`), so a forged
    // payload can never attribute a row to somebody else; the insert policy
    // rejects it.
    const { error: insertError } = await supabase
      .from('todos')
      .insert({ title: value })
    if (insertError) {
      throw createError({
        statusCode: 500,
        statusMessage: insertError.message
      })
    }
    title.value = ''
    await refresh()
  } catch (err) {
    toast.add({
      title: 'Could not add todo',
      description: (err as Error).message,
      color: 'error'
    })
  } finally {
    saving.value = false
  }
}

async function toggleTodo(todo: Todo, isComplete: boolean) {
  try {
    const { error: updateError } = await supabase
      .from('todos')
      .update({ is_complete: isComplete })
      .eq('id', todo.id)
    if (updateError) {
      throw createError({
        statusCode: 500,
        statusMessage: updateError.message
      })
    }
    await refresh()
  } catch (err) {
    toast.add({
      title: 'Could not update todo',
      description: (err as Error).message,
      color: 'error'
    })
  }
}

const remaining = computed(
  () => (todos.value ?? []).filter((todo) => !todo.is_complete).length
)
</script>

<template>
  <UContainer class="max-w-2xl py-12">
    <div class="flex flex-wrap items-center justify-between gap-4">
      <div>
        <h1 class="text-2xl font-semibold">My lists</h1>
        <p class="text-sm text-muted">
          Signed in as {{ user?.email ?? 'you' }} · {{ remaining }} open
        </p>
      </div>

      <form
        class="flex w-full items-center gap-2 sm:w-auto"
        @submit.prevent="addTodo"
      >
        <UInput
          v-model="title"
          placeholder="What needs doing?"
          size="lg"
          class="w-full sm:w-72"
        />
        <UButton
          type="submit"
          size="lg"
          icon="i-lucide-plus"
          label="Add"
          :loading="saving"
          :disabled="!title.trim()"
        />
      </form>
    </div>

    <UAlert
      v-if="error"
      class="mt-6"
      color="error"
      variant="subtle"
      icon="i-lucide-triangle-alert"
      title="Could not load todos"
      :description="
        error.statusMessage || 'Is the local stack running? Try pnpm db:start'
      "
    />

    <div v-else class="mt-6">
      <p v-if="pending && !todos?.length" class="text-sm text-muted">
        Loading…
      </p>

      <p v-else-if="!todos?.length" class="text-sm text-muted">
        Nothing here yet. Add your first todo above — it is owned by your user
        id, so no other account can see it.
      </p>

      <ul v-else class="flex flex-col gap-2">
        <li v-for="todo of todos" :key="todo.id">
          <UCard variant="subtle">
            <div class="flex items-center gap-3">
              <UCheckbox
                :model-value="todo.is_complete"
                :aria-label="`Mark ${todo.title} as done`"
                @update:model-value="toggleTodo(todo, Boolean($event))"
              />
              <span :class="[todo.is_complete && 'text-muted line-through']">{{
                todo.title
              }}</span>
            </div>
          </UCard>
        </li>
      </ul>
    </div>
  </UContainer>
</template>
