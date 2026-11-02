# A write's report names its act and the state it fell back to; Buy's answers ride the verb, and a refused name opens a sheet, not a report

> **Records the answer to [#32](https://github.com/justintaddei/kinetic-lists/issues/32)** — the copy
> ADR-0025 left unstrung when it fixed the mechanism ("*A write's failure **is** the report, and the
> optimistic row flips back*", "*its copy strings are #32's*"). **Amends
> [ADR-0024](0024-the-shell-is-a-tab-bar-spine-of-six-tabbed-routes-plus-sheets-with-the-44px-floor-in-the-copied-components.md)'s
> Toaster sentence** (its two named clients are dead, its mounts are not) **and
> [ADR-0016](0016-buy-takes-the-whole-basket-and-claims-rows-on-the-servers-clock.md)'s report of a
> claimed Buy** (the copy, at last). Extends
> [ADR-0018](0018-store-and-item-names-are-household-unique-by-index.md)'s "*opens that as #13's join
> sheet, not as an error toast*" from a `23505` to every refusal a surface can answer.

Every affordance is an **online act** (ADR-0025), so v1 has exactly one announcement: the actor's own
failed write. **Every failed write reports.** The flip-back is not a report of its own — it is the
visible half of the line the tap's failure carries, and a row that flips back with no line is a state
nobody can read (ADR-0026's rule against an unreported state, applied to failure).

**The shape is `the act didn't land · the state it fell back to`** — one line, the verb naming the tap,
the second clause naming what the rows are now, joined by `·` in the quiet-line form (ADR-0015's copy
rule, ADR-0022's counts, ADR-0024's `·`). `Check didn't land · Milk is back in Needed`. Tests assert
the whole string (ADR-0024 asserts the toast regions by copy, with no `data-testid`).

**Two voices, because a refusal and a non-answer are different facts.** A **refusal** is the database
answering, and its answer is the Household's state, so the line speaks plainly: `Nothing is In Basket
at Walmart`. A **non-answer** is the request dying short of the database, and the app knows only its
own tap, so the line speaks in the shape. The app maps each SQLSTATE it expects to written copy —
`23514`, `42501`, `28000` — and prints the server's own message **as fallback** for a code it did not
expect, so a failure is never silent and PostgREST's raw text (`duplicate key value violates unique
constraint "items_name_key"`) never appears as designed copy.

**Buy's answers all ride the bottom-center mount, at the verb, and Buy is that mount's only client**
(the bottom-center mount's named clients in ADR-0024 were the Buy report and the Undo; ADR-0022 killed
the Undo, so one client remains, and it speaks in every one of Buy's outcomes).

| Buy's answer | The line |
| --- | --- |
| It Bought | `Bought 5 at Walmart · Midtown` (ADR-0026) |
| A co-Member claimed some lines (the reply's `skipped[]`) | `Bought 5 at Walmart · Alex Bought Milk and Eggs at Big Y` |
| A co-Member claimed every line (`Nothing is In Basket at this Store`) | `Nothing is In Basket at Walmart` |
| The request never reached the RPC | `Buy didn't land · Nothing was Bought` |
| The Standing Location it named no longer exists (`23514`) | **No report** — the Store picker opens, the Standing Location clears |

The middle row is ADR-0016's designed report — naming the co-Member and their Store, **a report that
writes nothing** — drawn from `buy_basket`'s own reply (ADR-0023: the payload is the `skipped` array),
and it names the half the tap Won as well as the half it lost, because the Buy it reports is one verb.

**Every other report rides the top-center mount** (offset under the header, ADR-0024) **with the
Arrival** (ADR-0026):

| Act | The report |
| --- | --- |
| Check | `Check didn't land · Milk is back in Needed` |
| Need | `Need didn't land · Milk is still Stocked` |
| Check/Need on a row a co-Member erased mid-flight | `Check didn't land · Milk is gone` |
| Capture (the nested insert lands nothing) | `Capture didn't land · Milk is not in the List` |
| A field edit (Category, Quantity, Display Name, Geofence, coordinates, a List and Household rename) | `Category didn't land · Milk is still Dairy` |
| A Store Tag toggle | `Tag didn't land · Milk has no Tag at Walmart` / `Tag didn't land · Milk is tagged at Walmart` |
| A Cascade delete, refused by a dead socket | `Delete didn't land · Walmart is still here` |
| An Arrival whose journal `insert` fails | `Arrival didn't land · Walmart is the Active Store` |

The vanished variant exists because a co-Member's cascade lands live (ADR-0017, ADR-0025) and *is back
in Needed* would be a lie: when the row is gone, the report says the thing is gone.

**A refused name opens a sheet, never a report.** This is ADR-0018's `23505` rule and ADR-0022's
`Milk already exists` generalized: a failure the Member can resolve in a surface is answered *in that
surface* — the Store name-join sheet, the Item sheet's refusal, the Store picker for a Standing
Location that a cascade erased — and the Toaster carries only the failures with nothing to open.
**Join's refusals ride no Toaster for the same reason**: `preview_invitation` and `join_household`
answer `/join/[token]` inline with their own sentences (`This invitation has already been used`, `You
already belong to The Fridges` with the hint `Ask a Member of "The Fridges" to invite you instead`),
and only Join's non-answer speaks in the shape: `Join didn't land · You are not a Member of The Fridges`.

**Co-Members stay silent, and reports are never stacked.** A report is always the actor's own tap, so
#27's assertion holds unchanged: a co-Member watching a row move sees **zero toasts** (ADR-0022,
ADR-0025). Reports take sonner's defaults — no per-call `duration`, no sticky report, dismissible by
swipe/tap, in the copy's two mounts, no third — which is ADR-0024's rule for components (the copy
writes no size, and now no timing).

**Consequences.** The copy-assertion list is handed to [#27](https://github.com/justintaddei/kinetic-lists/issues/27)
(one string per verb, assertable on mount): the six top-center lines above and the four Buy lines, the
`Nothing is In Basket at Walmart` refusal, the vanished variant, the `Milk already exists` sheet line,
the name-join sheet on a Store clash (a *sheet*, asserted not to be a toast), the picker opening on a
stale Standing Location, and zero toasts on the watching Member. [#31](https://github.com/justintaddei/kinetic-lists/issues/31)'s
shell copy edits now name every mount's clients: top-center for a write's report **and the Arrival**,
bottom-center for **Buy's answers**, and the sentence's dead clients (the claim toast, the Undo) stay
deleted. [#30](https://github.com/justintaddei/kinetic-lists/issues/30)'s live layer owns the flip-back the lines
describe, [#6](https://github.com/justintaddei/kinetic-lists/issues/6) fires the Arrival's line, and
[#7](https://github.com/justintaddei/kinetic-lists/issues/7) fires Capture's copy. A ticket that plans a
generic `Something went wrong`, a co-Member announcement, an Undo, connection language (`Offline`,
`Reconnecting`, `Synced`), a sticky report or a toast stack, a `duration` at a call site, a third
mount, PostgREST's raw constraint text as copy, a Toaster line for a name clash or a stale Standing
Location, a report naming a cause the app cannot know, or a failure that reports nothing, breaks this
decision rather than extending it.
