# FreshDeal Website — Frontend Implementation Documentation

> **Base API URL:** `https://<your-domain>/api`
> **Auth:** Bearer JWT token in `Authorization` header (except public endpoints marked `🔓 Public`)
> **API Format:** API Platform (Hydra/JSON-LD) — collections are wrapped in `{ "hydra:member": [...], "hydra:totalItems": N }`
> **Content-Type for writes:** `application/json` (POST/PUT), `application/merge-patch+json` (PATCH)

---

## Table of Contents

1. [Navbar — Authentication](#1-navbar--authentication)
2. [Hero Section — Search Bar](#2-hero-section--search-bar)
3. [Trust Strip — Partner Logos](#3-trust-strip--partner-logos)
4. [How It Works — Static](#4-how-it-works--static)
5. [Categories — Browse by Type](#5-categories--browse-by-type)
6. [Featured Offers — Offer Cards](#6-featured-offers--offer-cards)
7. [Impact Stats — Platform Metrics](#7-impact-stats--platform-metrics)
8. [For Businesses — Partner Dashboard](#8-for-businesses--partner-dashboard)
9. [Testimonials — Static](#9-testimonials--static)
10. [App Download — Static](#10-app-download--static)
11. [Footer](#11-footer)
12. [Shared Data Models](#12-shared-data-models)
13. [Auth Flow Summary](#13-auth-flow-summary)

---

## 1. Navbar — Authentication

### What it shows
- Logo + navigation links (Browse Deals, For Business, About)
- **Logged-out state:** "Log in" + "Get started" buttons
- **Logged-in state:** User avatar, first name greeting, "My Orders" link, logout

### API calls

#### Check if user is already logged in
After page load, try to restore a stored JWT token (localStorage) and verify it is still valid.

```
GET /users/me
Authorization: Bearer <token>
```

**Response (200 OK):**
```json
{
  "@id": "/api/users/some-uuid",
  "uuid": "some-uuid",
  "firstName": "Alex",
  "lastName": "Smith",
  "email": "alex@example.com",
  "roles": ["ROLE_MEMBER"],
  "isVerified": true,
  "businessPartner": "/api/business_partners/3"   // IRI string OR full object OR null
}
```

If this returns `401`, the token is expired — clear localStorage and show logged-out navbar.

#### Login
> Authentication is handled via **Keycloak** (OAuth2/OpenID Connect).
> The frontend should redirect the user to the Keycloak login page, not call a custom `/login` endpoint.

```
POST https://<keycloak-domain>/realms/<realm>/protocol/openid-connect/token
Content-Type: application/x-www-form-urlencoded

grant_type=password
&client_id=<client_id>
&username=<email>
&password=<password>
```

**Response:**
```json
{
  "access_token": "eyJ...",
  "refresh_token": "eyJ...",
  "expires_in": 3600
}
```

Store `access_token` in localStorage. Include it in every subsequent request as:
```
Authorization: Bearer <access_token>
```

#### Logout
Clear localStorage (`access_token`, `refresh_token`). Optionally call Keycloak logout endpoint to invalidate the session.

---

### Implementation notes
- If `roles` array contains `"ROLE_BUSINESS_PARTNER"`, redirect the user to the **Business Dashboard** after login.
- If `isVerified` is `false`, show an email-verification warning banner below the navbar.
- On every page refresh, call `GET /users/me` first to restore session state before rendering the navbar.

---

## 2. Hero Section — Search Bar

### What it shows
- Headline, sub-headline, CTA buttons (static copy — no API)
- **Search bar:** typing triggers a live offer search
- Hero stats: number of meals rescued, partner businesses, customer savings (can be static for MVP)

### API call (search bar)

🔓 **Public endpoint — no token required**

```
GET /food_offers
  ?title=<search_text>
  &status=active
  &endTime[after]=<current_ISO_datetime>
  &page=1
  &itemsPerPage=10
```

**Example:**
```
GET /food_offers?title=pizza&status=active&endTime[after]=2026-07-14T10:00:00Z&page=1&itemsPerPage=10
```

**Response:**
```json
{
  "hydra:member": [ ...offer objects... ],
  "hydra:totalItems": 42
}
```

Each item in `hydra:member` is a [FoodOfferModel](#foodoffermodel) — see [Section 12](#12-shared-data-models).

### Behaviour
- **Debounce:** wait 350 ms after the user stops typing before firing the request.
- **Empty query:** do not send a request; show default home content instead.
- **Results:** navigate to `/offers?q=<search_text>` and render the results there (or show a dropdown).

---

## 3. Trust Strip — Partner Logos

### What it shows
A horizontal row of partner business names (e.g. "GreenBakery", "CaféVerde").

### API call (optional — can be static for MVP)

🔓 **Public endpoint**

```
GET /business_partners?isActive=true&itemsPerPage=12
```

**Response:**
```json
{
  "hydra:member": [
    {
      "@id": "/api/business_partners/1",
      "businessName": "Green Bakery",
      "averageRating": 4.8,
      "isActive": true
    }
  ]
}
```

### Implementation notes
- For MVP: render the business names as static text in the HTML mockup.
- For production: fetch the first page of active partners and display `businessName` in a scrolling marquee or grid.
- Filter by `isActive=true` to avoid showing closed or suspended businesses.

---

## 4. How It Works — Static

No API calls needed. This section contains three static cards:

| Step | Title | Description |
|------|-------|-------------|
| 01 | Browse nearby deals | Discover surplus food by category and distance |
| 02 | Reserve & pay online | Pick an offer, choose quantity, checkout in seconds |
| 03 | Pick up & enjoy | Show your confirmation code at the store |

Render from hardcoded content. Copy can be stored in a translations file if multilingual support is needed.

---

## 5. Categories — Browse by Type

### What it shows
A row of interactive pill/chip buttons. Clicking a category filters the offers grid below.

### Category values
These are the exact `category` string values used in the API:

| Display Label | API value |
|---|---|
| All | *(no filter)* |
| Fast food | `fast_food` |
| Pizza | `pizza` |
| Bakery | `bakery` |
| Restaurant | `restaurant` |
| Supermarket | `supermarket` |
| Café | `cafe` |
| Meals | `meals` |
| Groceries | `groceries` |
| Bread & Pastries | `bread_pastries` |
| Fruits & Vegetables | `fruits_vegetables` |
| Hot Drinks | `hot_drinks` |
| Cheese & Dairy | `cheese_dairy` |
| Butcher | `butcher` |
| Fish | `fish` |
| Deli & Catering | `deli_catering` |
| Flowers | `flowers` |
| Salads | `salads` |

### API call (on category click)

🔓 **Public endpoint**

```
GET /food_offers
  ?category=<api_value>
  &status=active
  &endTime[after]=<current_ISO_datetime>
  &page=1
  &itemsPerPage=30
```

**Example:** User clicks "Bakery"
```
GET /food_offers?category=bakery&status=active&endTime[after]=2026-07-14T10:00:00Z&page=1&itemsPerPage=30
```

### Alternative — Sections endpoint (home screen / discovery mode)

🔓 **Public endpoint**  
Returns all non-empty categories in one call — use this to power the home feed.

```
GET /food_offers/sections?limit=10
```

**Response:**
```json
{
  "sections": [
    {
      "category": "bakery",
      "offers": [ ...up to 10 FoodOfferModel objects... ],
      "totalCount": 24,
      "nextPage": 2
    },
    {
      "category": "pizza",
      "offers": [ ... ],
      "totalCount": 8,
      "nextPage": null
    }
  ]
}
```

Use this on the main home/discovery page — one request instead of N. Render one horizontal scroll row per section.

### Load more (horizontal scroll)

When the user scrolls to the end of a category row:

```
GET /food_offers/sections/<category>?page=<nextPage>&limit=10
```

**Response:** same shape as a single section object above.

---

## 6. Featured Offers — Offer Cards

### What it shows
A grid of offer cards. Each card displays:
- Offer image
- Availability badge (Available / Temporarily Closed / Ended)
- Star rating
- Category label
- Title
- Business name
- Distance + city (needs user geolocation)
- Sale price, original price (strikethrough), discount % badge
- Pickup window (start–end time)
- "Order Now" / "Unavailable" CTA button

### API call

🔓 **Public endpoint**

```
GET /food_offers
  ?status=active
  &endTime[after]=<current_ISO_datetime>
  &page=1
  &itemsPerPage=30
```

Optional filters:
```
&category=<value>          // from category pills
&title=<search_text>       // from search bar
&order[createdAt]=desc     // sort newest first
```

**Full example:**
```
GET /food_offers?status=active&endTime[after]=2026-07-14T10:00:00Z&category=bakery&page=1&itemsPerPage=30
```

**Response:**
```json
{
  "hydra:member": [
    {
      "@id": "/api/food_offers/12",
      "title": "Morning Surprise Bag",
      "description": "Fresh pastries from today's batch",
      "category": "bakery",
      "originalPrice": "11.00",
      "salePrice": "3.99",
      "quantityTotal": 10,
      "quantityAvailable": 4,
      "isWeightBased": false,
      "startTime": "2026-07-14T12:00:00+00:00",
      "endTime": "2026-07-14T16:30:00+00:00",
      "status": "active",
      "createdAt": "2026-07-14T08:00:00+00:00",
      "images": [
        { "@id": "/api/images/5", "url": "https://cdn.example.com/img/bag.jpg" }
      ],
      "businessPartner": {
        "@id": "/api/business_partners/3",
        "businessName": "Green Bakery",
        "averageRating": 4.8,
        "isActive": true,
        "deliveryFee": "0.00",
        "addresses": [
          {
            "street": "Bakkerstraat 12",
            "city": "Amsterdam",
            "postalCode": "1012AB",
            "latitude": "52.3731",
            "longitude": "4.8931"
          }
        ]
      }
    }
  ],
  "hydra:totalItems": 42,
  "hydra:view": {
    "hydra:next": "/api/food_offers?page=2&..."
  }
}
```

### Rendering an offer card

| UI element | Data field | Logic |
|---|---|---|
| Offer image | `images[0].url` | Show placeholder if `images` is empty |
| Availability badge | `status` + `endTime` + `businessPartner.isActive` | See table below |
| Star rating | `businessPartner.averageRating` | Round to 1 decimal |
| Category | `category` | Capitalise first letter |
| Title | `title` | Truncate at 2 lines |
| Business name | `businessPartner.businessName` | |
| Distance | Calculate from user coords + `businessPartner.addresses[0].latitude/longitude` | Requires browser Geolocation API |
| City | `businessPartner.addresses[0].city` | |
| Sale price | `salePrice` (piece) or `pricePerKg` (weight) | Prefix with currency symbol |
| Original price | `originalPrice` | Strikethrough style |
| Discount % | `Math.round((1 - salePrice/originalPrice) * 100)` | Show "Save X%" badge |
| Pickup window | `startTime` → `endTime` | Format as "Today · 14:00 – 16:30" |
| Stock count | `quantityAvailable` | Show "X left" warning when ≤ 3 |
| CTA button state | See availability table | |

**Availability badge & CTA logic:**

| Condition | Badge | CTA |
|---|---|---|
| `status != 'active'` OR `now > endTime` | "Ended" | Button disabled, label "Unavailable" |
| `status == 'active'` AND `now < endTime` AND `businessPartner.isActive == true` | "Available" | Button active, label "Order Now" |
| `status == 'active'` AND `now < endTime` AND `businessPartner.isActive == false` | "Temporarily Closed" | Button active, shows info dialog on click |

### Weight-based offers

When `isWeightBased == true`, the price fields change:

| UI element | Field |
|---|---|
| Price per kg | `pricePerKg` |
| Original price per kg | `originalPrice` |
| Available weight | `weightAvailableKg` (show as "X kg available") |
| Minimum order | `minOrderKg` (show "Min. X kg") |

### Pagination

```
GET /food_offers?...&page=2&itemsPerPage=30
```

Check `hydra:view.hydra:next` — if present, a next page exists. Load more on scroll or button click.

---

## 7. Impact Stats — Platform Metrics

### What it shows
Four large numbers: meals rescued, total savings, partner businesses count, CO₂ prevented.

### Option A — Static (MVP)
Hard-code approximate numbers from the team. Update manually each quarter.

### Option B — Admin stats endpoint

> **Requires admin token.** Do not expose this on a public page unless your backend has a public summary endpoint.

```
GET /users          // count of registered users
GET /business_partners?isActive=true   // count active partners
GET /food_offers?status=active         // active offers count
```

For a public impact counter, ask the backend team to expose a dedicated unauthenticated endpoint like `GET /platform/stats` returning:
```json
{
  "mealsRescued": 48000,
  "totalSavingsEur": 2400000,
  "activePartners": 1200,
  "co2PreventedKg": 72000
}
```

---

## 8. For Businesses — Partner Dashboard

### What it shows
A mockup/preview of the business dashboard with:
- Business name, open/closed toggle
- Earnings today, active offers, orders today, customer rating
- Recent orders list

### 8a. Fetch business partner profile

> **Requires auth token** — business user must be logged in.

```
GET /users/me
Authorization: Bearer <token>
```

Extract `businessPartner` field from response. If it's a string IRI, fetch the full object:

```
GET /business_partners/<id>
Authorization: Bearer <token>
```

**Response fields used:**

| UI element | Field |
|---|---|
| Business name | `businessName` |
| Open/Closed badge | `isActive` |
| Average rating | `averageRating` |
| Contact phone | `contactPhone` |
| Contact email | `contactEmail` |

### 8b. Toggle business open/closed

```
PATCH /business_partners/<id>
Authorization: Bearer <token>
Content-Type: application/merge-patch+json

{ "isActive": true }
```

**Response:** updated `BusinessPartnerModel` object (200 OK).

### 8c. Fetch today's orders

```
GET /orders
  ?businessPartner=/api/business_partners/<id>
  &order[createdAt]=desc
Authorization: Bearer <token>
```

**Response:**
```json
{
  "hydra:member": [
    {
      "@id": "/api/orders/55",
      "status": "pending",
      "totalPrice": "7.98",
      "subtotal": "7.98",
      "deliveryFee": "0.00",
      "paymentMethod": "card",
      "paymentStatus": "paid",
      "createdAt": "2026-07-14T13:42:00+00:00",
      "orderItems": [
        {
          "quantity": 2,
          "unitPrice": "3.99",
          "totalPrice": "7.98",
          "titleSnapshot": "Morning Surprise Bag",
          "categorySnapshot": "bakery",
          "foodOffer": { ... }
        }
      ],
      "user": {
        "firstName": "Emma",
        "lastName": "K.",
        "email": "emma@example.com"
      },
      "businessPartner": { ... }
    }
  ]
}
```

### 8d. Update order status

```
PUT /orders/<id>/status
Authorization: Bearer <token>
Content-Type: application/json

{ "status": "accepted" }
```

**Valid status values:**

| Status | Meaning |
|---|---|
| `pending` | Just placed, waiting for business to accept |
| `accepted` | Business confirmed the order |
| `completed` | Customer picked up the order |
| `cancelled` | Order was cancelled (by customer or business) |

### 8e. Create a new food offer (business side)

```
POST /food_offers
Authorization: Bearer <token>
Content-Type: application/json
```

**Body — piece-based offer:**
```json
{
  "title": "Pastry Surprise Bag",
  "description": "Fresh croissants and muffins",
  "category": "bakery",
  "originalPrice": "11.00",
  "salePrice": "3.99",
  "quantityTotal": 10,
  "quantityAvailable": 10,
  "isWeightBased": false,
  "startTime": "2026-07-14T12:00:00Z",
  "endTime": "2026-07-14T16:30:00Z",
  "businessPartner": "/api/business_partners/3"
}
```

**Body — weight-based offer:**
```json
{
  "title": "Bread Rescue",
  "category": "bakery",
  "originalPrice": "8.00",
  "pricePerKg": "3.50",
  "weightTotalKg": "5.00",
  "weightAvailableKg": "5.00",
  "minOrderKg": "0.5",
  "isWeightBased": true,
  "startTime": "2026-07-14T16:00:00Z",
  "endTime": "2026-07-14T20:00:00Z",
  "businessPartner": "/api/business_partners/3"
}
```

**Response:** 201 Created + full `FoodOfferModel` object.

### 8f. Update an offer (partial update)

```
PATCH /food_offers/<id>
Authorization: Bearer <token>
Content-Type: application/merge-patch+json

{ "quantityAvailable": 5 }
```

Only send the fields that changed. All other fields remain unchanged on the server.

### 8g. Delete an offer

```
DELETE /food_offers/<id>
Authorization: Bearer <token>
```

**Response:** 204 No Content.

---

## 9. Testimonials — Static

No API calls. Render three static testimonial cards from hardcoded copy.
For production you can add a reviews/testimonials endpoint, but none exists in the current API.

---

## 10. App Download — Static

No API calls. The two store buttons link to App Store and Google Play URLs.

---

## 11. Footer

### Static links
All footer navigation links are static HTML anchors — no API calls.

### Newsletter signup (optional)
If you want a newsletter form, POST to a mailing service (Mailchimp, etc.) directly from the frontend. The FreshDeal API does not have a newsletter endpoint.

---

## 12. Shared Data Models

### FoodOfferModel

Returned by `GET /food_offers` and `GET /food_offers/{id}`.

```json
{
  "@id": "/api/food_offers/12",
  "title": "Morning Surprise Bag",
  "description": "Fresh pastries",
  "category": "bakery",
  "originalPrice": "11.00",

  // Piece-based fields (isWeightBased = false)
  "salePrice": "3.99",
  "quantityTotal": 10,
  "quantityAvailable": 4,

  // Weight-based fields (isWeightBased = true)
  "isWeightBased": false,
  "pricePerKg": null,
  "weightTotalKg": null,
  "weightAvailableKg": null,
  "minOrderKg": null,

  "startTime": "2026-07-14T12:00:00+00:00",
  "endTime": "2026-07-14T16:30:00+00:00",
  "status": "active",
  "createdAt": "2026-07-14T08:00:00+00:00",
  "images": [
    { "@id": "/api/images/5", "url": "https://cdn.example.com/img.jpg" }
  ],
  "businessPartner": { ...BusinessPartnerModel... }
}
```

> **Note on field names:** The API uses `salePrice` (not `price`) and `originalPrice` (not `originPrice`). Both old names may appear in cached data; your frontend should check both: `salePrice ?? price`.

### BusinessPartnerModel

Embedded inside `FoodOfferModel.businessPartner` or returned standalone from `GET /business_partners/{id}`.

```json
{
  "@id": "/api/business_partners/3",
  "businessName": "Green Bakery",
  "ownerName": "Marco V.",
  "registrationBusinessNumber": "KVK12345678",
  "taxNumber": "NL123456789B01",
  "averageRating": 4.8,
  "deliveryFee": "0.00",
  "isActive": true,
  "acceptsCashPayment": true,
  "contactPhone": "+31612345678",
  "contactEmail": "info@greenbakery.nl",
  "kycStatus": "approved",
  "addresses": [ ...AddressModel... ]
}
```

### AddressModel

```json
{
  "@id": "/api/addresses/7",
  "label": "main",
  "isPrimary": true,
  "street": "Bakkerstraat 12",
  "street2": null,
  "city": "Amsterdam",
  "country": "Netherlands",
  "postalCode": "1012AB",
  "countryCode": "NL",
  "latitude": "52.3731",
  "longitude": "4.8931"
}
```

### UserModel

Returned by `GET /users/me`.

```json
{
  "@id": "/api/users/some-uuid",
  "uuid": "some-uuid",
  "firstName": "Alex",
  "lastName": "Smith",
  "email": "alex@example.com",
  "phone": "+31612345678",
  "isVerified": true,
  "roles": ["ROLE_MEMBER"],
  "businessPartner": "/api/business_partners/3",
  "address": { ...AddressModel... }
}
```

> **Role values:**
> - `ROLE_MEMBER` — regular customer
> - `ROLE_BUSINESS_PARTNER` — restaurant/store owner
> - `ROLE_ADMIN` — platform admin

### OrderModel

```json
{
  "@id": "/api/orders/55",
  "status": "pending",
  "totalPrice": "7.98",
  "subtotal": "7.98",
  "deliveryFee": "0.00",
  "paymentMethod": "card",
  "paymentStatus": "paid",
  "notes": "No onions please",
  "createdAt": "2026-07-14T13:42:00+00:00",
  "updatedAt": "2026-07-14T13:42:00+00:00",
  "completedAt": null,
  "cancelledAt": null,
  "cancellationReason": null,
  "estimatedDeliveryLabel": "14:00 – 16:00",
  "user": { ...UserModel... },
  "businessPartner": { ...BusinessPartnerModel... },
  "orderItems": [ ...OrderItemModel... ]
}
```

### OrderItemModel

```json
{
  "@id": "/api/order_items/88",
  "quantity": 2,
  "unitPrice": "3.99",
  "totalPrice": "7.98",
  "titleSnapshot": "Morning Surprise Bag",
  "categorySnapshot": "bakery",
  "weightKg": null,
  "weightTotalKg": null,
  "foodOffer": { ...FoodOfferModel... }
}
```

> `titleSnapshot` and `categorySnapshot` are safe to display even if the original offer has been deleted.

---

## 13. Auth Flow Summary

```
User visits site
       │
       ▼
Restore token from localStorage
       │
  ┌────┴──────┐
  │ token     │  no token
  │ exists?   ├──────────────────────────────────────────────►  Show logged-out UI
  └────┬──────┘
       │ yes
       ▼
GET /users/me
       │
  ┌────┴────────┐
  │  200 OK     │  401 Unauthorized
  │             ├──────────────────────────────────────────────►  Clear token, show logged-out UI
  └────┬────────┘
       │
  ┌────┴────────────────────────┐
  │ roles includes              │ roles only ROLE_MEMBER
  │ ROLE_BUSINESS_PARTNER?      │
  └────┬────────────────────────┘
       │ yes                    │ no
       ▼                        ▼
Redirect to               Show customer home
Business Dashboard        (browse offers)
```

### Token storage

| Key | Value | When to clear |
|---|---|---|
| `fd_access_token` | JWT access token | On logout or 401 |
| `fd_refresh_token` | Keycloak refresh token | On logout |
| `fd_user_iri` | `/api/users/<uuid>` | On logout |

---

## 14. Quick API Reference

| Endpoint | Method | Auth | Description |
|---|---|---|---|
| `/food_offers` | GET | 🔓 Public | List/search offers |
| `/food_offers/{id}` | GET | 🔓 Public | Single offer detail |
| `/food_offers/sections` | GET | 🔓 Public | All category sections (home feed) |
| `/food_offers/sections/{cat}` | GET | 🔓 Public | One category page |
| `/food_offers` | POST | 🔒 Business | Create new offer |
| `/food_offers/{id}` | PATCH | 🔒 Business | Update offer fields |
| `/food_offers/{id}` | DELETE | 🔒 Business | Delete offer |
| `/favorites` | GET | 🔒 Customer | Get saved offers |
| `/favorites/{offerId}` | POST | 🔒 Customer | Add to favorites |
| `/favorites/{offerId}` | DELETE | 🔒 Customer | Remove from favorites |
| `/orders` | GET | 🔒 Auth | List orders (filter by user or partner) |
| `/orders` | POST | 🔒 Customer | Place a new order |
| `/orders/{id}` | GET | 🔒 Auth | Single order detail |
| `/orders/{id}` | PATCH | 🔒 Auth | Update order (notes, address) |
| `/orders/{id}/status` | PUT | 🔒 Business | Update order status |
| `/business_partners` | GET | 🔓 Public | List business partners |
| `/business_partners/{id}` | GET | 🔓 Public | Single business partner |
| `/business_partners/{id}` | PATCH | 🔒 Business | Update partner (e.g. isActive toggle) |
| `/addresses` | GET | 🔒 Auth | List user addresses |
| `/addresses` | POST | 🔒 Auth | Add new address |
| `/addresses/{id}` | PATCH | 🔒 Auth | Update address |
| `/addresses/{id}` | DELETE | 🔒 Auth | Delete address |
| `/images` | POST | 🔒 Auth | Upload image (multipart/form-data) |
| `/users/me` | GET | 🔒 Auth | Current user profile |
| `/change-password` | POST | 🔒 Auth | Change password |
| `/forgot-password` | POST | 🔓 Public | Request password reset email |
| `/business_bank_accounts` | GET/POST | 🔒 Business | Manage payout bank account |
