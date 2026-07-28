# Modular Architecture Plan

**Status:** Proposal — not yet implemented
**Scope:** Flutter client only. Backend (Symfony/API Platform monolith) stays a single service for now; module boundaries below are drawn so each Flutter module maps cleanly onto that API's resource groups, but splitting the backend is out of scope here.
**Drivers:** team growing from 1–3 to 5–15 developers over the next 6–12 months; current pain is merge conflicts on shared files and slow onboarding.

---

## 0. Current state (as found in the repo)

The app is a single GetX binary, ~280 Dart files, three markets (Food fully built, Cosmetic partially built, Clothes planned) plus a business-partner side and an admin side, all in one app with role-based dashboards (`DashboardShell`). Everything lives flat under `lib/`:

| Directory | Files | What's actually in it |
|---|---|---|
| `lib/controllers/` | 28 | GetX controllers, mixed flat + `food_controllers/{business,customer}` subfolders |
| `lib/models/` | 21 | Same mix, partially organized under `food_models/`, `product_models/` |
| `lib/services/` | 22 | API-calling services, same partial split |
| `lib/screens/` | 99 | UI, split by market (`food_teil/`, `cosmetic_teil/`) and by shared customer/business screens |
| `lib/profile_and_orders/` | 62 | Orders + profile, already feature-folder shaped (`controllers/models/services/views`) — the best-organized corner of the app today |
| `lib/widgets/` | 42 | Shared UI |
| `lib/network/api_service.dart` | 1 | **Single Dio wrapper for every API call in the app** |
| `lib/routes/app_routes.dart`, `app_pages.dart` | 2 | **Single route table for every screen** |
| `lib/bindings/initial_binding.dart` | 1 | **Single DI binding for every controller** |

Three findings that matter more than anything else in this plan:

1. **`api_service.dart`, `app_pages.dart`, `app_routes.dart`, and `initial_binding.dart` are the actual source of your merge conflicts.** Every feature, on every PR, touches at least one of these four files. Splitting screens into folders doesn't fix that — decentralizing these four files does. This is priority #1, independent of everything else below.
2. **`lib/app/{customer_app,seller_app,admin_app}`, `lib/packages/{core,design_system,models}`, and `lib/features/` already exist in your tree — and are empty.** They're leftovers from the original scaffold commits (`TASK-01-01`/`TASK-01-02`, a riverpod+go_router skeleton that was abandoned in favor of the GetX app you actually built). They're dead weight and — inconveniently — they already claim the exact names this plan wants to use. They need to be deleted before migration starts, not repurposed blindly.
3. **None of the real app code is committed to git yet.** `git log` shows only the abandoned scaffold (4 commits, 2 authors). Everything under `lib/screens`, `lib/controllers`, `lib/models`, `lib/services`, `lib/profile_and_orders`, etc. is untracked. This is unusual and it's a gift: you can do the physical restructuring **before** the first real commit, so there's no history to rewrite and no risk of a disruptive history-losing move. Land the new structure, then make Phase 1's commit the actual project baseline.

A Payment module already exists (`profile_and_orders/orders/controllers/payment_controller.dart`, `psp_gateway_selector.dart`) with a `PspProvider` enum for Iranian PSPs. Discount, Commission, Delivery-as-a-domain, and Inventory-as-a-domain from your original brief are **not built yet** — they're addressed below as slots to grow into, not code to migrate.

---

## 1. High-level architecture

### Apps (separate binaries, per your decision to split)

```
customer_app   — browsing, cart, checkout, orders, reviews, notifications (customer side)
seller_app     — business-partner dashboard: offers/products, inventory, orders, earnings, analytics
admin_app      — platform admin: sellers, customers, categories, commissions, moderation
```

Each app is a thin shell: routing entry point + DI wiring + navigation chrome. It contains **no business logic** — that lives in feature packages. This is the rule that keeps three teams from stepping on each other: an app team can restyle their shell or reorder navigation without ever opening a feature package, and a feature team can ship a change that appears in one, two, or all three apps without touching app code beyond a version bump.

Practically, this means `DashboardShell` as it exists today (one shell handling customer + business + admin views via role-switching) gets retired in favor of three real shells. That's the biggest single behavior change in this plan — see Phase 3.

### Core packages (own no business logic, owned by a platform team)

```
core            — Dio client + interceptors (replaces api_service.dart), auth/token storage,
                  Hive/DataCacheService, Mercure/SSE client, error types, env config
design_system   — AppColors, theme, Nunito/typography, shared low-level widgets
                  (buttons, chips, inputs — the FilterChip/MenuChip/AppSearchField family)
models          — DTOs/entities shared across ≥2 feature packages (User, Address, Money,
                  Market enum) — NOT a dumping ground; a model stays feature-local unless
                  two+ features genuinely need it
i18n            — AppTranslations, locale controller, string files
```

### Feature packages (one per business capability, each independently ownable)

```
auth            — login/register/session (screens/auth, controllers: auth/login/register)
catalog         — product/offer browsing (food_offer + product controllers/models/services,
                  merges today's food/product split under one Product-domain interface)
cart            — cart_controller, cart_item, add_to_cart screens
order           — checkout, order history, order detail (profile_and_orders/orders)
payment         — payment_controller, PspGatewaySelector, PSP integrations
review          — review_controller/model/service, review widgets
notification    — notification_controller/service, push_notification_service,
                  mercure_controller/service (real-time transport lives here, other
                  features subscribe through it rather than owning SSE directly)
location        — address_controller/model/service, location_controller/service
seller_mgmt     — business_partner_controller/model/service, bank account, email/notif
                  prefs, business address, business profile
inventory       — business_offer_controller, business_product_controller (today merged
                  into seller-side catalog code; split out once it grows past "just CRUD")
admin_platform  — admin_controller, admin_stats_model, admin_service, admin screens
```

### Communication rules

- Apps depend on features + core. Features never depend on apps.
- A feature package may depend on `core`, `design_system`, `models`, `i18n` freely.
- A feature package may depend on **another feature's public API only** (e.g. `order` depends on `cart`'s public `CartSnapshot`, not on `cart`'s internal controller) — never on another feature's `src/` internals. Enforce with `export` in each package's single public `lib/<package>.dart` file; nothing outside that file is importable from other packages.
- Cross-cutting real-time events (order status, favorites restock, new notification) flow through `notification`'s Mercure client as a typed stream; features subscribe, they don't each open their own SSE connection — this is already how Mercure works in the app today, just not yet packaged as a boundary.
- No feature imports another feature's screens directly for navigation — apps own route tables that wire features together; a feature exposes route *names* (constants), not route *widgets*, to other features.

---

## 2. Flutter project restructuring

Recommended tool: **Melos** (multi-package Dart/Flutter monorepo manager — handles versioning, bootstrapping, and running scripts across packages; the de facto standard for this exact structure, e.g. used by Flutter itself and by Very Good Ventures' templates).

```
food_app/                          # monorepo root
├── melos.yaml
├── apps/
│   ├── customer_app/
│   │   ├── lib/main.dart          # was lib/main.dart
│   │   ├── lib/routes/            # was lib/routes/ (customer routes only)
│   │   └── lib/bindings/          # was lib/bindings/ (customer bindings only)
│   ├── seller_app/
│   │   └── ...                    # was screens/food_teil/business_views,
│   │                               #     screens/cosmetic_teil/business_views,
│   │                               #     shared_customer_business_screens/business_dashboard
│   └── admin_app/
│       └── ...                    # was lib/screens/admin/**
│
├── packages/
│   ├── core/
│   ├── design_system/             # was lib/theme/, parts of lib/widgets/common
│   ├── models/
│   └── i18n/                      # was lib/l10n/, lib/strings/
│
└── features/
    ├── auth/                      # was lib/screens/auth, controllers/{auth,login,register}_controller.dart
    ├── catalog/                   # was food_controllers + prodcuct_controllers + food/product models+services
    ├── cart/                      # was controllers/cart_controller.dart, models/cart_item.dart, screens/add_to_cart
    ├── order/                     # was lib/profile_and_orders/orders/**  (already shaped correctly — least work)
    ├── payment/                   # was lib/profile_and_orders/orders/{controllers/payment_controller.dart, views/psp_*}
    ├── review/                    # was controllers/review_controller.dart, models/review_model.dart, widgets/review
    ├── notification/              # was controllers/{notification,mercure}_controller.dart, services/*
    ├── location/                  # was controllers/location_controller.dart, services/address_service.dart
    ├── seller_mgmt/                # was food_business_controllers minus offer/product CRUD
    ├── inventory/                  # was business_offer_controller.dart, business_product_controller.dart
    └── admin_platform/             # was controllers/admin_controller.dart, screens/admin/**
```

Each `features/*` and `packages/*` directory is its own Dart package (own `pubspec.yaml`, own `test/`), not just a folder — that's what makes ownership enforceable (see §3) and what makes "a team can't accidentally import another team's internals" a compiler error instead of a code-review hope.

`lib/profile_and_orders/orders/` is already structured almost exactly like a target feature package (`controllers/models/services/views`) — start the migration there; it validates the pattern with the least risk before you touch the messier `food_teil`/`cosmetic_teil` split.

---

## 3. Team ownership model

Sized for the 5–15 developer target, not the current 1–3 — start with fewer, wider-scoped teams and split further as headcount actually arrives. Don't pre-create 6 teams for 3 people.

| Team | Owns (packages/features) | Allowed changes | Forbidden changes | APIs owned |
|---|---|---|---|---|
| **Platform** | `core`, `design_system`, `models`, `i18n`, Melos/CI config | Anything inside owned packages; adding new shared widgets/utilities after a feature team requests one | Adding feature-specific logic into `core`/`models` "just this once" | `ApiClient` interface, `AppTheme`, `DataCacheService`, i18n string contract |
| **Customer Experience** | `customer_app`, `catalog`, `cart`, `order`, `review` | Anything inside owned features; checkout flow UX | `payment` internals (PSP logic), `seller_mgmt`/`inventory` | `CartSnapshot`, `OrderSummary` public models |
| **Seller Platform** | `seller_app`, `seller_mgmt`, `inventory`, seller-side `catalog` write paths | Offer/product CRUD, business dashboard, earnings/analytics | `customer_app` UI, `payment` PSP integrations | `OfferPublished`/`InventoryChanged` events |
| **Trust & Ops** | `admin_app`, `admin_platform`, `payment`, `notification`, `location` | Admin tooling, PSP integration, notification delivery | Catalog/cart business rules | `PaymentResult`, `NotificationEvent` |

Cross-cutting rule for all teams: a PR that touches `packages/core` or `packages/models` requires a Platform-team review (enforced via CODEOWNERS, §5), because those two packages are shared surface area — this replaces "everyone edits `api_service.dart`" with "one team gates the shared client, everyone else consumes it."

---

## 4. Module boundaries

Format: Purpose / Responsibilities / Data ownership / APIs exposed / Depends on / Must not depend on.

**auth**
- Purpose: authentication and session lifecycle.
- Responsibilities: login, register, Firebase Auth wiring, session/token persistence.
- Data ownership: `User` identity + auth token (not the full profile — that's customer/seller profile screens, which live in their respective apps).
- APIs exposed: `AuthState` stream, `currentUser`, `signIn/signOut`.
- Depends on: `core`, `models`.
- Must not depend on: `cart`, `order`, `catalog`.

**catalog**
- Purpose: product/offer discovery and detail.
- Responsibilities: browsing, search, offer/product detail, favorites list rendering (today split across `food_offer_controller` and `product_controller` — unify behind one `Offer` interface with a market discriminator, don't keep two parallel controller families).
- Data ownership: Product/Offer read models, category taxonomy.
- APIs exposed: `CatalogRepository.search/getById`, `FavoritesOfferController` public surface.
- Depends on: `core`, `models`, `location` (for distance/availability).
- Must not depend on: `cart`, `order`, `payment`.

**cart**
- Purpose: pre-checkout basket state, per business.
- Responsibilities: add/remove/update items, availability revalidation (existing `ProductService.checkCartAvailability` market-agnostic checker), cart persistence.
- Data ownership: `CartItem`/cart state (client-side; not an order until checkout).
- APIs exposed: `CartSnapshot`, `CartController` public surface (must stay `permanent: true` in GetX — a known lifecycle gotcha, see below).
- Depends on: `core`, `models`, `catalog` (read-only, for price/availability).
- Must not depend on: `order`, `payment`.

**order**
- Purpose: checkout execution, order history, order status tracking.
- Responsibilities: place order, edit order, order detail, status polling/Mercure subscription.
- Data ownership: `Order`, `OrderItem`.
- APIs exposed: `OrderRepository.place/getHistory/getDetail`, `OrderStatusStream`.
- Depends on: `core`, `models`, `cart` (reads `CartSnapshot` at checkout), `payment` (public result type only), `notification` (subscribes to status events).
- Must not depend on: `catalog` internals, `seller_mgmt`.

**payment**
- Purpose: PSP integration and payment execution.
- Responsibilities: PSP selection (`PspGatewaySelector`), transaction initiation, result handling. No real gateway API wired yet per current state — this module owns filling that in.
- Data ownership: transaction/payment records.
- APIs exposed: `PaymentResult`, `initiatePayment(orderId, psp)`.
- Depends on: `core`, `models`.
- Must not depend on: `order` internals (order calls payment, not the reverse), `cart`.

**review**
- Purpose: post-order ratings, per business (not per order, per existing decision).
- Data ownership: `Review`.
- APIs exposed: `ReviewRepository.submit/getForBusiness`.
- Depends on: `core`, `models`, `order` (public "eligible to review" check only).
- Must not depend on: `catalog`, `payment`.

**notification**
- Purpose: notification center + real-time transport (Mercure/SSE) + push (FCM).
- Responsibilities: unread bell, notification history, broadcast (admin), typed event bus other features subscribe to.
- Data ownership: `Notification`.
- APIs exposed: `NotificationEvent` stream (typed per topic), `NotificationCenterController`.
- Depends on: `core`.
- Must not depend on: any feature — other features depend on it, not vice versa. This is the one module every other module is allowed to import.

**location**
- Purpose: address management, geolocation, distance calc.
- Data ownership: `Address`.
- APIs exposed: `AddressRepository`, `LocationService.currentPosition`.
- Depends on: `core`, `models`.
- Must not depend on: `catalog`, `order`.

**seller_mgmt**
- Purpose: business-partner identity and settings (not product/offer content — that's `inventory`).
- Responsibilities: business registration, bank account, email/notification preferences, business profile, business address.
- Data ownership: `BusinessPartner`.
- APIs exposed: `BusinessPartnerRepository`.
- Depends on: `core`, `models`, `location`.
- Must not depend on: `catalog`, `order`, `payment`.

**inventory**
- Purpose: seller-side product/offer CRUD and stock.
- Responsibilities: create/edit offers, weight-based product support, stock restore on order changes.
- Data ownership: Offer/Product *write* path (catalog owns the read path — same underlying resource, split by direction, mirroring how the API already separates business vs. customer offer endpoints).
- APIs exposed: `InventoryRepository.create/update/adjustStock`.
- Depends on: `core`, `models`, `seller_mgmt`.
- Must not depend on: `cart`, `order`, `payment`.

**admin_platform**
- Purpose: platform administration.
- Responsibilities: manage sellers/customers, view orders, stats dashboard. Category management, commission management are **not built yet** — this is where they'd plug in.
- Data ownership: nothing new — reads across other modules' data plus admin-only actions (suspend, broadcast).
- APIs exposed: admin-scoped queries; no other module should call *into* admin_platform.
- Depends on: `core`, and read-only public APIs of every other feature.
- Must not depend on: nothing forbidden by design — but nothing should depend on *it*.

Not yet built, called out so the boundary is pre-drawn rather than improvised later: **discount/promotions** (would sit between `catalog` and `cart`, owning price adjustment rules), **commission** (would sit inside `admin_platform` + a backend concern, computing seller payout deductions), **delivery-as-a-domain** (today delivery is just an address on an order; a real delivery/logistics module would own courier assignment and would depend on `order` + `location`).

---

## 5. Git repository strategy

**Monorepo with Melos**, not multi-repo. At 5–15 developers with three thin apps sharing ~10 feature packages, multi-repo would mean either publishing internal packages to a private registry (real infra cost) or `path:` git dependencies pinned across repos (version-skew pain, exactly the kind of cross-repo coordination overhead that slows a small team down). A Melos monorepo gets you the same import-boundary enforcement with `flutter pub get`/`melos bootstrap` and no publishing step. Revisit multi-repo only if a specific team needs an independent release cadence or external open-sourcing — neither applies here yet.

**Branch strategy:** trunk-based, short-lived feature branches off `main`, PR required to merge, no long-lived per-team branches (those recreate the merge-conflict problem this whole plan exists to fix, just delayed to merge time).

**Code ownership:** `CODEOWNERS` mapped to the folder structure in §2:
```
/packages/core/            @platform-team
/packages/design_system/   @platform-team
/packages/models/          @platform-team
/features/payment/         @trust-ops-team
/features/admin_platform/  @trust-ops-team
/features/notification/    @trust-ops-team
/features/location/        @trust-ops-team
/features/cart/            @customer-exp-team
/features/order/           @customer-exp-team
/features/review/          @customer-exp-team
/features/catalog/         @customer-exp-team @seller-platform-team   # dual, see below
/features/seller_mgmt/     @seller-platform-team
/features/inventory/       @seller-platform-team
/apps/customer_app/        @customer-exp-team
/apps/seller_app/          @seller-platform-team
/apps/admin_app/           @trust-ops-team
```
`catalog` is dual-owned because both customer read paths and seller write paths live there today — either team can merge, but a change touching the other team's direction needs their review too. Revisit once/if `inventory` fully absorbs the write side.

**PR workflow:** required review from the owning team (GitHub branch protection using CODEOWNERS), CI must pass `melos run analyze` + `melos run test` scoped to changed packages only (Melos supports `--diff` filtering — this keeps CI fast as package count grows), no direct pushes to `main`.

---

## 6. Migration plan

Because nothing is committed yet (§0, finding 3), this is a **reorganize-then-commit** plan, not a live incremental migration with a working `main` the whole time. That's simpler and lower-risk than a typical brownfield migration — take the opportunity.

**Phase 1 — Extract core components — ✅ done (2026-07-28)**
1. ✅ Deleted the dead `lib/app/`, `lib/packages/`, `lib/features/` scaffold folders.
2. ✅ Set up a Dart-native pub workspace (root `pubspec.yaml` `workspace:` + `melos:` sections — Melos 8 reads config from `pubspec.yaml`, not a standalone `melos.yaml`) with `packages/{core,design_system,models,i18n}` as real Flutter packages. `melos bootstrap` / `melos run analyze` both verified working.
3. ✅ Moved `network/api_service.dart`, `auth_interceptor.dart`, `keycloak_auth_service.dart`, `app_routes.dart` (route *name* constants only — the real `app_pages.dart` GetPage table stays in the app), `api_constants.dart`, `api_endpoints.dart`, `app_storage.dart`, `data_cache_service.dart`, `app_logger.dart` → `packages/core`.
   - Added a `packages/models` package (not originally called out for Phase 1, but needed once `market_colors.dart` and 33+ call sites turned out to depend on the `Market`/`app_enums` enums) holding `app_enums.dart` + `market_enums.dart`.
   - `AuthInterceptor` directly called `Get.offAllNamed(...)` and showed an `AppSnackbar` on session-expiry/403 — real UI/navigation side effects that can't live in a package with no navigation stack. Decoupled via `onSessionExpired`/`onPermissionDenied` callbacks on `AuthInterceptor`/`ApiService`, wired up in `lib/bindings/initial_binding.dart` where `ApiService` is constructed. This is the one non-mechanical change in Phase 1 — everything else was a pure move + import rewrite.
   - `cache_service.dart` stayed in the app (not moved) — it mixes core concerns (AppStorage, AppLogger) with app-only ones (a feature-specific strings file, `AppSnackbar`), so it wasn't cleanly separable without moving those too. Update its imports and leave the file in place until Phase 2 sorts out where feature-specific strings live.
4. ✅ Moved `theme/*` → `packages/design_system`; `l10n/`, `strings/`, `controllers/locale_controller.dart`, `utils/currency_formatter.dart` → `packages/i18n`.
5. ✅ Verified: `flutter pub get` (workspace-wide), `flutter analyze` (0 errors — 28 pre-existing info/warning lints, none introduced by the move), and `flutter build apk --debug` all succeed. Safety commit `e016f5b` created before starting (see repo history) as the pre-migration checkpoint.

Deliberately **not** done in Phase 1, despite the original draft above: moving `main.dart` + `android/`/`ios/`/etc. platform folders into `apps/customer_app/`. Platform-folder moves are fragile (Xcode project references, Gradle paths, Firebase config) — doing that move once, as part of the real 3-way app split in Phase 3, is safer than doing it twice. The app currently still lives at the repo root and depends on the 4 new packages via the workspace; `apps/{customer_app,seller_app,admin_app}` do not exist yet.

**Phase 2 — Separate features**
1. Move one feature at a time, starting with `order` (already shaped right, lowest risk) to validate the package template, then `cart`, `catalog`, `payment`, `review`, `notification`, `location`.
2. For each: create the package, move files, fix imports, add the single `lib/<feature>.dart` export barrel, delete the old location, run `flutter analyze`.
3. Split `catalog` out of the current food/product controller duplication as part of this phase — this is the one non-mechanical move; budget more time for it.

**Phase 3 — Create independent apps**
1. Split the current `DashboardShell` role-switching into three real app entry points: `apps/customer_app`, `apps/seller_app`, `apps/admin_app`.
2. Move `screens/admin/**` → `admin_app`; business-side screens (`food_teil/business_views`, `cosmetic_teil/business_views`, `shared_customer_business_screens/business_dashboard`) → `seller_app`; the rest → `customer_app`.
3. Each app gets its own `main.dart`, route table, and binding — this is what finally kills the single-file `app_routes.dart`/`initial_binding.dart` bottleneck from finding #1.
4. Stand up seller_mgmt and inventory as their own packages, splitting the current `food_business_controllers` group.

**Phase 4 — Assign ownership to teams**
1. Land CODEOWNERS from §5 once package boundaries are stable — not before, or it just generates review-assignment noise on churning paths.
2. Stand up per-team CI checks scoped by Melos diff-filtering.
3. First real `main` commit happens at the *end* of Phase 3 / start of Phase 4, structured as the new architecture from day one — no "initial commit is the old mess, then rewrite history" step needed.
4. As headcount grows past ~8–10, split Customer Experience or Seller Platform teams further (e.g. peel `review` + `notification` into a dedicated Engagement team) — the package boundaries already support this; only the CODEOWNERS mapping needs to change.

Do not attempt Phases 2–4 in one pass. Each phase should be its own set of PRs with `flutter analyze` (and eventually tests) green at every step — the fact that nothing is committed yet removes git-history risk, but compile/runtime risk from a big-bang move is still real.
