export function useUser() {
  const route = useRoute()

  const user = useSupabaseUser()

  if (!user.value) {
    if (route.path !== '/login') {
      navigateTo('/login')
    }
    return null
  }

  return user
}
