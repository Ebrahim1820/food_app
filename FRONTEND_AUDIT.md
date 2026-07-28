# Missing Features Backlog — vs. Too Good To Go / Uber Eats

Method: read the actual Flutter codebase (`lib/`) screen-by-screen, checked each feature against what Too Good To Go and Uber Eats actually ship (verified via current app-store/marketplace descriptions, not assumption), and listed only real gaps. Grouped by priority so you can work top-down.

Sources: [Too Good To Go — How It Works](https://www.toogoodtogo.com/en-us/how-does-the-app-work), [TGTG App Store listing](https://apps.apple.com/us/app/too-good-to-go-save-good-food/id1060683933), [Uber Eats live tracking](https://help.leafly.com/hc/en-us/articles/30302343116051-Uber-Eats-Live-Order-Tracking-Uber-Driver-App), [Uber Eats Google Play listing](https://play.google.com/store/apps/details?id=com.ubercab.eats&hl=en_US)

---

## P0 — Blocking real usage (money & trust)

| # | Missing feature | Reference app does this | Current state in our app |
|---|---|---|---|
| 1 | **Real payment processing** | Both — card charged at checkout | Checkout only stores `card`/`cash` as a string; card entry writes to an in-memory mock list (`payment_controller.dart`, comment literally says "demo/mock — replace with API in production"). No PSP (ZarinPal/IDPay/Saman/etc.) integrated. **No money actually moves.** |
| 2 | ~~**Post-order rating/review submission**~~ | TGTG: photo + detailed review prompts after pickup. Uber Eats: star rating + review, drives repeat orders | **Done (2026-07-19).** Star (1-5) + comment submission from the order detail screen once `completed`/`delivered` (`SubmitReviewSheet`), one review per customer per business (backend-enforced). Customer-facing "Ratings & Reviews" list reachable from the product detail rating row, business owner "Reviews" dashboard tab. No photo attachment (backend `Review` entity has no image field) — scope decision, not an oversight. |
| 3 | **Business earnings dashboard is fake** | Both show partners real sales data | Our `BusinessAnalyticsController`/`BusinessEarningsController` are 100% hardcoded mock data — shipping this as-is shows partners fabricated numbers. |
| 4 | **Account deletion does nothing** | App-store requirement for both | "Delete account" button exists in settings with an empty `onTap: () {}`. No confirmation, no API call. This is a Play Store/App Store compliance risk. |

## P1 — Core UX identity of these apps

| # | Missing feature | Reference app does this | Current state in our app |
|---|---|---|---|
| 5 | **Map view of offers** | TGTG: map is the primary browse surface — pins sortable by distance/price/rating/relevance | Doesn't exist. `google_maps_flutter` is in `pubspec.yaml` but never referenced anywhere in `lib/` — dead dependency. |
| 6 | **Impact tracker** ("meals rescued", CO2/water/land saved) | TGTG: shown on Profile, their #1 retention hook | Doesn't exist at all — no screen, no field, not even stubbed. |
| 7 | **Live delivery tracking with driver/rider position on map** | Uber Eats: tracks courier from pickup to door in real time | No rider/courier concept exists anywhere in the codebase (zero matches for "rider"/"courier"/"driver"). Delivery is assumed to be self-fulfilled by the business. This is a scope decision, not just a missing screen — decide if delivery-with-dispatch is even in v1. |
| 8 | **Favorite-item availability alerts** | TGTG: push notification when a favorited spot's bag becomes available | Favorites screen exists and lists saved items, but there's no "notify me when available" trigger — it's a static list, not an alert subscription. |
| 9 | **Offer countdown timer** | TGTG: live countdown to pickup-window close drives urgency | Pickup window is a static formatted string, computed once. No ticking timer, no auto-flip to "expired" while the screen is open. |
| 10 | **Address autocomplete / geocoding** | Both: type-ahead address search, pin-drop on map | Address entry is pure free-text fields (street/city/postal/etc.), no Places/geocoding API wired despite the maps package being present. |

## P2 — Trust, growth, and partner-side gaps

| # | Missing feature | Reference app does this | Current state in our app |
|---|---|---|---|
| 11 | **Dispute/refund request flow** | Both: in-order "something wrong?" flow tied to the specific order | Only a generic "Contact us" email form, and even that is mocked (`Future.delayed`, no real API call, no backend endpoint declared). |
| 12 | **Recurring/template offers for businesses** | TGTG: partners can repeat a daily bag without re-entering it | Every offer must be created from scratch daily. No template/duplicate concept in UI or backend. |
| 13 | **Payout history tied to bank account** | Both: partners see settlement history | Bank account CRUD is real and wired to the API, but there's no payout ledger connected to it — "transactions" list in earnings is separate mock data. |
| 14 | **KYC gating** | Both: unverified partners can't go live | KYC status shows as a badge only — pending/rejected partners can still create offers, appear in discovery, and take orders. No gating logic anywhere. |
| 15 | **Referral / promo code system** | Both: growth-loop mechanism | No entry point anywhere (checkout, profile, home). |
| 16 | **Order status as a visual stepper** | Both: pending → confirmed → preparing → ready → delivered shown as progress steps | We do have real-time status via Mercure (this part is solid), but it renders as a flat status chip instead of a stepper/progress UI. |
| 17 | **Granular notification preferences (consumer side)** | Both: separate toggles for order updates, promos, etc. | Consumer settings only have 3 toggles (Push/Email/Promotional). The business-partner side already has 9 granular categories — same pattern needs to come to the consumer app. |
| 18 | **Saved/reusable payment method** | Both: tokenized card saved for one-tap reorder | Two fake demo cards reseed every session; nothing persists. Depends on #1 (real payment gateway) being solved first. |

---

## Suggested build order

1. **#1 Payment gateway** — nothing else on the money side matters until this is real (unblocks #18 too).
2. **#3 Real earnings data** — stop showing partners fake numbers; wire existing bank-account/order data into real aggregates.
3. **#2 Rating/review submission** + **#11 Dispute/refund** — trust loop, relatively contained UI + a couple endpoints.
4. **#5 Map view** + **#9 Countdown timer** — highest visual impact for "feels like TGTG," and the map dependency is already installed.
5. **#6 Impact tracker** — mostly a display feature once order-history data is available; strong retention ROI for the effort.
6. **#4 Account deletion**, **#14 KYC gating** — compliance/trust cleanup, small scope.
7. **#12 Recurring offers**, **#13 Payout history**, **#8 Favorite alerts**, **#17 Notification granularity**, **#15 Referral** — partner-experience and growth polish once the core loop is solid.
8. **#7 Rider/courier live tracking**, **#10 Address autocomplete** — biggest scope items; treat as a separate decision on whether delivery-with-dispatch is even in v1, since it implies a whole new actor (courier) and possibly a new app surface.
