# E2E tests sign in with local email, not GitHub

The local Supabase stack has no `[auth.external github]` block, so Playwright tests log in through the local email flow (`enable_signup = true`, autoconfirm) and the GitHub OAuth path is verified manually against the hosted project. The alternative — keeping real GitHub OAuth credentials in the local stack for tests — was rejected: it puts an OAuth secret in every dev environment and makes CI depend on GitHub.
