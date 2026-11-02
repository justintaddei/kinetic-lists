# The Kinetic View is the flat rows Needed at the Active Store, moved live by a co-Member's Write, with the Arrival reported twice

> **Records the answer to the destination's last fog patch** — *"what should the Kinetic View look
> like?"* — prototyped in [#11](https://github.com/justintaddei/kinetic-lists/issues/11) as four
> throwaway variants, and **amends [ADR-0024](0024-the-shell-is-a-tab-bar-spine-of-six-tabbed-routes-plus-sheets-with-the-44px-floor-in-the-copied-components.md)'s
> Kinetic View column** (a standing line joins the header, the filter field, the rows and the gate
> copy) **and [ADR-0021](0021-the-active-store-picker-lists-stores-only-and-an-arrival-names-the-location.md)'s
> rule that an Arrival's toast owns the eye** (it keeps the mount, and the state gets a line of its
> own). The whole answer is [#11's resolution](https://github.com/justintaddei/kinetic-lists/issues/11#issuecomment-6566060900);
> this names the load-bearing cuts.

The Kinetic View's organising fact is **co-Member movement** — Arrivals, Buys, and rows that move
while you watch — not *"what is needed at this Store"*. The Store and the Standing Location are the
standing sets' **addresses** (ADR-0021), not the screen's subject; the screen's subject is what the
Household's Writes do to the rows.

**The grouping is the flat list of rows Needed at the Active Store, cross-List.** No Store-shelf
keyed on Standing Locations, no Category headings. The prototype built all four and the verdict is
specific: the shelf keyed on Standing Locations **shows movement best** — a co-Member's Buy visibly
empties a named Store's group, and a Location header can perform an Arrival in place — and it loses
because **a row appears under every Store its Tags name** and the column doubles; Category headings
are decoration over values that carry no verb (ADR-0012). The settled chrome of ADR-0024 was winning
on the phone, which is what made the shelf worth building.

**The grouping carries no live affordance.** Rows move under a co-Member's Write — Check, Buy, Need,
Tag, a Cascade's erasure landing in the middle of a column — and that is the live layer
([#30](https://github.com/justintaddei/kinetic-lists/issues/30), ADR-0025), not a header, a per-group
control, or a `Stand here` heading. An affordance in the grouping would make the *grouping* a place
Writes happen, which is ADR-0021's rule about the picker: a Standing Location arrives only as an
Act's subject.

**An Arrival is reported twice.** Its own report toast top-centre, on the mount ADR-0025 left for **a
write's own report** — and a **standing quiet line above the rows** naming where you are, `You're at
Walmart Midtown — Needed at Walmart`. The line is not the toast: the toast leaves and the Standing
Location stays, and a Standing Location nobody reports is a state nobody can see (ADR-0021's per-
device state, with no v1 surface naming it). `silent` is out.

**A Name's visibility is a Tag fact, not a Status fact — and the Gate's copy knows it.** The
prototype's sharpest finding: Capture writes Tags at capture ([#13](https://github.com/justintaddei/kinetic-lists/issues/13),
ADR-0015), so a first-time Household's Capture'd Names carry no Tag, are **invisible in every Store's
Kinetic View**, and the gate copy counts them accurately as `K with no Tag at this Store`. The gate is
not broken: it names rows no screen will show. **The seeding answer is chosen against that trap** —
sign-up seeds the Standing Set with Names, and the Kinetic View's emptiness and gate copy must make
the untagged Needs legible, not hide them ([#36](https://github.com/justintaddei/kinetic-lists/issues/36)).

Two things the prototype confirmed, because they were decisions in search of a screen: **three doors
to one Mint sheet** (the Kinetic View's emptiness, the Store picker's sticky entry, the Buy gate's
ask) with the **Position kept** — the mint that arrives as an Act's subject keeps its Location, a mint
whose Position is denied is a **bare Store** (Tags, no Location, no Arrival). And **the Buy verb
carries the Arrival**: `Buy at Walmart · Midtown`, `Buy at Walmart` when a Store was hand-Picked,
`Buy — name this shop` when none is Active. That is ADR-0016's Store named on every Purchase, legible
at the verb instead of in a sheet a Member must answer (ADR-0021's rule that an **Arrival** names the
Location a Buy records).

**Consequences.** [#12](https://github.com/justintaddei/kinetic-lists/issues/12) is layout and
choreography on top of this shape (430px fit, the standing line, the live move), not a grouping
competition; [#30](https://github.com/justintaddei/kinetic-lists/issues/30)'s live layer is what makes
the screen Kinetic; [#36](https://github.com/justintaddei/kinetic-lists/issues/36)'s seeding is
measured by the invisible-Needs trap; [#32](https://github.com/justintaddei/kinetic-lists/issues/32)'s
copy strings gain the standing line. A ticket that plans a **Store-shelf Kinetic View**, **Category
headings as the grouping**, a **live affordance in the grouping**, an **Arrival with no report**, a
**Kinetic View with no standing line**, a **Kinetic View that hides the untagged Needs**, a **first run
that seeds nothing**, a **Buy verb that does not name its Store**, a **fourth Mint door**, or a
**Kinetic View grouped by co-Member** breaks this decision rather than extending it.
