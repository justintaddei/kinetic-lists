# Kinetic View + arrival: four throwaway variants

Wayfinder [#11](https://github.com/justintaddei/kinetic-lists/issues/11). Throwaway code on
`prototype/kinetic-view`, built on the settled chrome of ADR-0024 plus the Store-picker chrome of
#21. Nothing here is spec. It exists to make Four Questions answerable by thumbs
(prototype skill: *the answer is a decision, not an artefact*).

Run it: `pnpm dev`, then `http://localhost:3000/prototype/kinetic-view`. The whole state is in the URL,
so every screenshot below is a link:

| param | values |
| --- | --- |
| `variant` | `flat` · `category` · `hybrid` · `shelf` (ArrowLeft/ArrowRight cycles) |
| `scenario` | `full` (Household, Active Store, Standing Location) · `wall` (25 Stores) · `fresh` (no Store, 4 untagged rows) |
| `arrival` | `silent` · `line` · `toast` — the form of an Arrival's report |
| `tab` | `kinetic` · `lists` · `basket` · `household` |
| `sheet` | `store-picker` · `store-screen` · `mint` · `capture` · `item` · `cascade` (+ `item=Milk`, `store=walmart`) |
| `panel` | `1` — opens the switcher |

The dev-only switcher carries the controls no v1 screen has: **Alex checks a row**, **Alex Buys**,
**Alex Deletes a Store** (the three live-moments #11 asked for), the scenario switch, the arrival-form
switch, an arrive-as-me control per Location, and the fact panel (Active Store, Standing Location,
Gate counts, Household counts) plus the event log.

## The four groupings

| shot | variant | the read |
| --- | --- | --- |
| `01-flat-full.png`, `01-flat-tall.png` | **A · Flat column** — ADR-0024 exactly: header, filter at six rows, flat rows, gate copy as the last quiet line | Scans fast. The name is the row, one quiet line each. No sense of *where* a row lives. |
| `02-category-full.png` | **B · Category headings** — quiet label headings, one flat store-scope | Cheapest chrome. Reads like a shopping list; Categories are values (ADR-0012) and the headings carry no behaviour. |
| `03-hybrid-full.png`, `19-hybrid-fresh.png` | **C · Hybrid** — Category headings with a Store picked; the Store-shelf and a `Needs a Tag` group with none | The only variant that shows the Gate. Its no-Store state contradicts ADR-0024's `UiEmpty` page (a deliberate spike). |
| `04-shelf-full.png`, `07-shelf-fresh.png` | **D · Store-shelf keyed on Standing Locations** — heading is the Location, `Stand here` performs the Arrival in place | Ties the view to the Kinetic spine. A row appears under every Location its Tags name, so a row repeats. Costs the most vertical space. |

Tabs, sheets, and the first run: `08-basket-full.png` (Buy verb carries the Arrival:
`Buy at Walmart · Midtown`), `09-lists-full.png`, `10-household-full.png`,
`06-flat-fresh.png` (the emptiness, `UiEmpty` + Mint), `11-store-picker.png`, `12-mint-header.png`,
`13-capture.png`, `14-item-sheet.png` (Tag pills, live-edit), `15-store-screen.png` (Locations,
`Stand here`, presence), `22-store-screen-bare.png` (the Bare Store's copy), `16-cascade.png`
(the Cascade's counts), `17-mint-buy.png` (Mint from the Buy verb), `05-flat-wall.png` (the
25-Store wall, flat), `18-scenario-panel.png` and `21-shelf-panel.png` (the switcher panel open
on flat and on shelf), `24-capture-notag.png` (Capture with no Tag written),
`23-item-untagged.png` (the Item sheet on an untagged row: empty pills, the gate copy).

## What the prototype answers

1. **Which grouping earns its keep?** Flat (A) is the fastest read and the only one with no
   structure to maintain — the rows are the whole screen. Category (B) is decoration: the headings
   are values with no verb on them. The Store-shelf (D) is the one that *moves* when a co-Member
   Buys — the basket group empties under a named Store — which is what Kinetic means; its cost is
   that a row appears N times (once per Tagged Store) and the column doubles. Hybrid (C) is the
   compromise: one grouping in each state, the Gate visible only when there is no Active Store.
2. **The form of an Arrival's report.** `silent` (no report), `line` (a one-line quiet `You're at
   Walmart Midtown — Needed at Walmart` above the rows), `toast` (top-centre, the write's own
   report per #21). All three are one `arrive()` with a copy string; the toast and the line are
   the same fact in two mounts.
3. **The Gate's visibility.** The gate copy (`N Needed · M In Basket · K with no Tag at this Store`)
   is cheap chrome, and only the Hybrid/shelf groupings make the unTagged rows *legible as a
   problem* — `Needs a Tag`, `invisible in every Store's view`. Flat A never shows them as a
   set; the count in the last quiet line is the strongest signal there.
4. **Live movement under a co-Member's Writes.** `Alex checks a row` moves it under the named
   Store, in place, while you are editing (the row flashes; the Item sheet stays open).
   `Alex Buys` empties the basket group. `Alex Deletes Walmart` (the Cascade) erases 6 rows from
   the middle of a 29-row column while the Cascade dialog from the same Store is open elsewhere,
   strips 34 Tags, and leaves the gate copy naming `4 with no Tag`. Vocab stays intact in every
   case — Check/Buy/Tag/Pick/Arrival on the verb slots, and the Cascade confirmation naming only
   Household-visible counts.
5. **#11's amendments from #8/ADR-0025.** No last-Bought line (`Purchased` is out of the v1
   vocabulary); the Buy toast reports the write, never per-row history; co-Member Buy writes **no
   toast** in v1, so a co-Member's Buy is visible as moved rows only.

## Where it points

- **A and D are the two answers**: the flat column (fastest, and ADR-0024's settled chrome) vs
  the Store-shelf keyed on Standing Locations (the Kinetic view, ties the Arrival to grouping,
  accepts repetition). For #12.
- **Arrival `line` + `toast`**, not `silent`: the Arrival must be visible on the Kinetic View,
  and a Standing Location with no Arrival is stale. For #26 (Standing Location expiry) and #30.
- **A row's visibility is a Tag fact, not a status fact** — the sharpest finding. Every grouping
  except the unTagged group makes a Needed row with no Tag invisible, and ADR-0015 makes that
  the steady state: `Arrival does not create Items, Tags, or the Active Store` (#4). A first-time
  Household has rows and a Gate that shows nothing. For #36, and it deserves an ADR.
- **The Buy verb carrying the Arrival is a strong keeper** (ADR-0016's Store named on every
  Purchase, ADR-0021's Active Store picked only as an Act's subject). For #13, with the Mint door.
- Drop: `UiSonner` bottom-centre as a second mount (two mounts is chrome v1 has no use for),
  List *counts* on the Kinetic View (the List Home is their surface), and the switcher.

## Notes for the spec (what survives)

- The tab-bar spine, header, FAB, filter placement, Data rows, sheets, `UiEmpty`, the Mint doors,
  the two Cascade paths, the Item sheet's live-edit and Tag pills, and the 44px component lifts
  (button `h-11`, icon `size-11`, input `h-11`, drawer `max-h-[86vh]`) all transfer unchanged.
- The Buy verb's label is the one screen's copy that names the Arrival: `Buy at Walmart · Midtown`,
  `Buy at Walmart` (no Location), `Buy — name this shop` (no Active Store).
- The Cascade copy that reads well: `34 Store Tags come off. 6 Items left with no Tag lose their 7
  standing rows — invisible to every Member, in every List. 2 Locations go with the Store. Lists
  keep their names, and Purchases keep what they recorded.`
