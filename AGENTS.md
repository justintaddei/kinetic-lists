# AGENTS.md

## Agent skills

### Issue tracker

Issues live in GitHub Issues on `justintaddei/kinetic-lists`, via the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

Default vocabulary — `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `GLOSSARY.md` at the repo root plus `docs/adr/`. See `docs/agents/domain.md`.

### Supabase schema

`supabase/schemas/*.sql` is the source of truth, applied through migration history. The advisory/lint register, the definer-suppression contract, the grant posture, and the steps only a migration carries live in `docs/agents/advisors.md` — read it before touching `supabase/`.
