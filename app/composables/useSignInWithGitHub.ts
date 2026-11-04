import { useSupabaseClient } from '#imports'

/**
 * Starts the GitHub OAuth dance.
 *
 * `useSsrCookies` is on, so supabase-js stores the PKCE code verifier in a cookie
 * and Supabase's Auth server finishes the exchange when it redirects back to
 * `/auth/callback` (see `app/pages/auth/callback.vue`).
 *
 * The `redirectTo` value must be listed in `auth.additional_redirect_urls`
 * inside `supabase/config.toml`, otherwise Auth rejects it with a 400.
 */
export function useSignInWithGitHub() {
  const supabase = useSupabaseClient()
  const toast = useToast()

  async function signInWithGitHub(redirectTo = '/auth/callback') {
    const { error, data } = await supabase.auth.signInWithOAuth({
      provider: 'github',
      options: {
        redirectTo: `${window.location.origin}${redirectTo}`
      }
    })

    if (error) {
      toast.add({
        title: 'GitHub sign-in failed',
        description: error.message,
        color: 'error'
      })
      return
    }

    // supabase-js navigates for you; this only runs if it was prevented.
    if (data.url) {
      window.location.href = data.url
    }
  }

  return { signInWithGitHub }
}
