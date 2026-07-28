# UI Page Design Checklist

Paste this at the start of any new page conversation:

> **Checklist for this page:**
> See `.claude/UI_PAGE_CHECKLIST.md` — apply every item.

---

## 0. Design Inspiration (applied automatically)

Reference patterns from **UberEats** and **Too Good To Go** without needing to ask:

- **UberEats:** large hero sections, prominent green CTA buttons, horizontal pill chips for categories, clean white cards with subtle shadows, bottom-sheet modals for details
- **Too Good To Go:** bold primary-color actions, circular status/countdown badges, compact store cards, strong icon usage, warm secondary tones
- Both: generous padding, rounded corners everywhere, micro-animations on taps, clear visual hierarchy (title → subtitle → action)

---

## 1. Design System

- [ ] All colors from `AppColors` — zero hardcoded hex values
- [ ] Typography sizes consistent with existing screens (12 caption / 13–14 body / 17 AppBar / 22 hero)
- [ ] `AppColors.background` as Scaffold background
- [ ] Shadows use `AppColors.black.withValues(alpha: 0.05–0.08)`
- [ ] Border radius: 12–14 for cards, 20–24 for pills/chips, 18–20 for large cards

## 2. AppBar

- [ ] Use `SupportScaffold` (support screens) or consistent manual AppBar pattern
- [ ] Back button: `Icons.arrow_back_ios_new_rounded`, size 20, `AppColors.white`
- [ ] No elevation, `surfaceTintColor: Colors.transparent`
- [ ] AppBar color matches the page's accent color

## 3. Safe Area (Notch / Home Bar)

- [ ] `final safe = MediaQuery.of(context).padding;`
- [ ] Left/right content padding: `safe.left + 16` / `safe.right + 16`
- [ ] ListView/Column bottom padding: `safe.bottom + 24` (or 32)
- [ ] Hero header: manually adds `notch.left/right` to its own padding in landscape so gradient bleeds full-width but content is safe
- [ ] **Never** wrap the whole body in `SafeArea` when using this pattern — double-counts insets

## 4. Keyboard / Input Fields

- [ ] `resizeToAvoidBottomInset: true` (Scaffold default — do not disable)
- [ ] Input bar padding: **never** add `MediaQuery.of(context).viewInsets.bottom` — the Scaffold already shrinks the body
- [ ] Use `safe.bottom + 8` only on the input bar (for home indicator when keyboard is closed)
- [ ] `GestureDetector(onTap: () => FocusScope.of(context).unfocus())` wrapping scrollable body

## 5. Landscape Responsiveness

- [ ] `final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;`
- [ ] Landscape: two-column `Row(Expanded(...), SizedBox(14), Expanded(...))` layout
- [ ] Hero header: compact horizontal layout in landscape (`SupportHeroHeader` handles this automatically)
- [ ] Live Chat pattern: hide header in landscape, move key info to AppBar title
- [ ] Landscape padding applied to the outer `Padding` widget, not per-child

## 6. Translation / i18n

- [ ] All user-visible strings use `CustomerProfileStrings.xxx` (or the relevant `*Strings` class)
- [ ] New strings added to `lib/strings/customer_profile_strings.dart` as `static String get xxx => 'key'.tr;`
- [ ] Keys added to both `_en` and `_fa` maps in `lib/l10n/app_translations.dart`
- [ ] Persian (FA) translation provided for every key
- [ ] No `const` on any list/widget that contains `.tr` strings

## 7. RTL Support

- [ ] Text that must stay LTR (phone numbers, emails, URLs) wrapped in `Directionality(textDirection: TextDirection.ltr, child: ...)`
- [ ] Icons with directional meaning use `Icons.*_rounded` variants that auto-mirror, or explicitly handle RTL
- [ ] `Row` children order works in both LTR and RTL

## 8. Reusable Widgets

**Rules (apply before writing any widget code):**
- [ ] Search the registry below — use an existing widget rather than rebuilding it
- [ ] If building something that could appear on ≥2 screens, create it in `lib/widgets/common/` and add it to this registry
- [ ] Extract private `_WidgetName` classes for anything used more than once in the same file
- [ ] No duplicate AppBar/header code across files

### Widget Registry

#### `lib/widgets/common/` — General UI
| Widget | File | Purpose |
|---|---|---|
| `AppSearchField` | `common/app_search_field.dart` | Styled search input |
| `AppButton`, `AppTextField`, `PrimaryButton`, `SocialButton`, `SheetHandle`, `LabeledDivider`, `ErrorBanner`, `ErrorRetryWidget` | `common/shared_widgets.dart` | Core primitives |
| `ConfirmDialog` | `common/confirm_dialog.dart` | Two-button confirm modal |
| `DismissBackgroundWidget` | `common/dismiss_background_widget.dart` | Swipe-to-delete red background |
| `EmptyStateWidget` | `common/empty_state_widget.dart` | Icon + message for empty lists |
| `FilterChipWidget` | `common/filter_chip_widget.dart` | Horizontal pill filter chips |
| `GreenPageHeader` | `common/green_page_header.dart` | Green gradient page header |
| `IconActionButton` | `common/icon_action_button.dart` | Tappable icon with tint pill |
| `IconListTile` | `common/icon_list_tile.dart` | List row with leading icon pill |
| `InfoRowWidget` | `common/info_row_widget.dart` | Label + value row |
| `LanguageSelectorWidget` | `common/language_selector_widget.dart` | EN/FA two-button language picker (RTL-safe) |
| `LegalDocumentScaffold` | `common/legal_document_scaffold.dart` | Scaffold for terms/privacy pages |
| `MarketCategoryBadge` | `common/market_category_badge.dart` | Icon+label pill for a market key, via `marketAccent`/`marketIcon`/`marketLabel` |
| `MenuChipWidget<T>` | `common/menu_chip_widget.dart` | Generic segmented-control chip |
| `MerchantListItem` | `common/merchant_list_item.dart` | Compact tappable business/store row (avatar, badge, subtitle, footer chips) |
| `NotificationBell` | `common/notification_bell.dart` | Bell icon + unread-count badge, opens NotificationsScreen |
| `OfferCategoryFilterBar` | `common/offer_category_filter_bar.dart` | Horizontal category filter row |
| `PickupWindowPicker` / `PickupWindowField` | `common/pickup_window_picker.dart` | Time-window picker |
| `PrimaryActionFab` | `common/primary_action_fab.dart` | Branded floating action button |
| `QtyStepButton` | `common/qty_step_button.dart` | +/− quantity stepper |
| `SearchFilterBar` | `common/search_filter_bar.dart` | Search + filter bar combo |
| `SectionLabel` | `common/section_label.dart` | ALL-CAPS section header label |
| `StaleBanner` | `common/stale_banner.dart` | "Data may be outdated" warning banner |
| `StatusPill` | `common/status_pill.dart` | Dot + label status indicator (colour from `StatusHelper.getStatusColor`) |
| `SupportHeroHeader` | `common/support_hero_header.dart` | Gradient hero header, portrait + landscape |
| `SupportScaffold` | `common/support_scaffold.dart` | Shared AppBar scaffold for support screens |
| `ToggleTile` | `common/toggle_tile.dart` | List row with trailing switch |

#### Cards (moved out of `lib/widgets/cards/` during an earlier reorg — now market-scoped)
| Widget | File | Purpose |
|---|---|---|
| `BusinessSummaryCard` | `src/markets/food/business/views/business_summary_card.dart` | Business dashboard summary hero card |
| `OfferCard` | `src/markets/food/customer/views/offer_card.dart` | Full-size food offer card |
| `OfferCardCompact` | `src/markets/food/customer/views/offer_card_compact.dart` | Compact offer card for lists |

#### `lib/widgets/dialog/` — Sheets & Dialogs
| Widget | File | Purpose |
|---|---|---|
| `AddCardSheet` | `dialog/add_card_sheet.dart` | Add payment card bottom sheet |
| `AddressFormSheet` | `dialog/address_form_sheet.dart` | Add/edit address bottom sheet |
| `ChangePasswordSheet` | `dialog/change_password_sheet.dart` | Change password bottom sheet |
| `ForgotPasswordSheet` | `dialog/forgot_password_sheet.dart` | Forgot password bottom sheet |
| `InfoDialog` | `dialog/info_dialog.dart` | Simple info alert dialog |

#### `lib/widgets/notification/` — Notification history
| Widget | File | Purpose |
|---|---|---|
| `NotificationCard` | `notification/notification_card.dart` | Notification history row (icon, title/body, relative time, unread accent) |

#### `lib/widgets/order/` — Order detail sections
| Widget | File | Purpose |
|---|---|---|
| `BusinessOrderCard` | `src/markets/food/business/views/business_order_card.dart` | Order row for business view |
| `BusinessEmptyOrders` | `order/business_empty_orders.dart` | Empty state for orders list |
| `OrderDetailScreen` | `order/order_detail_screen.dart` | Full order detail screen |
| `OrderHeaderSection` | `order/order_header_section.dart` | Order header (status, date) |
| `OrderItemsSection` | `order/order_items_section.dart` | Order line items list |
| `OrderActionsSection` | `order/order_action_section.dart` | Accept/reject action buttons |
| `DeliverySection` | `order/delivery_section.dart` | Delivery info row |
| `RestaurantSection` | `order/restaurant_section.dart` | Restaurant info row |
| `PaymentSummarySection` | `order/payment_summery_section.dart` | Price breakdown |

#### `lib/widgets/order_checkout/` — Checkout flow
| Widget | File | Purpose |
|---|---|---|
| `OrderCheckoutScreen` | `order_checkout/order_checkout_screen.dart` | Full checkout screen |
| `BuildAddressPickerWidget` | `order_checkout/build_address_picker_widget.dart` | Delivery address picker |
| `BuildConfirmButtonWidget` | `order_checkout/build_confirm_button_widget.dart` | Place order CTA button |
| `BuildNotesFieldWidget` | `order_checkout/build_notes_field_widget.dart` | Order notes input |
| `BuildOfferInfoWidget` | `order_checkout/build_offer_info_widget.dart` | Offer summary header |
| `BuildPriceBreakDownrWidget` | `order_checkout/build_price_breakdown_widget.dart` | Price breakdown rows |
| `BuildQuantitySelectorWidget` | `order_checkout/build_quantity_selector_widget.dart` | Qty selector for checkout |

#### `lib/widgets/profile/` — Profile sections
| Widget | File | Purpose |
|---|---|---|
| `ProfileHeaderWidget` | `profile/profile_header_widget.dart` | Avatar + name header |
| `ProfileMenuWidget` | `profile/profile_menu_widget.dart` | Profile menu list |
| `ProfileStatsWidget` | `profile/profile_state_widget.dart` | Stats row (orders, etc.) |
| `ProfileSupportWidget` | `profile/profile_support_widget.dart` | Support links section |

#### `lib/widgets/` — Top-level shared
| Widget | File | Purpose |
|---|---|---|
| `AppDrawer` + `DrawerItem` / `DrawerSection` | `app_drawer.dart` | Slide-in nav drawer |
| `UploadableAvatar` | `uploadable_avatar.dart` | Avatar with upload tap |
| `LanguageFlagSwitcher` | `language_flag_switcher.dart` | Compact flag pill for AppBar actions |
| `EmailVerificationBannerWidget` | `email_verification_banner.dart` | Email verification prompt banner |
| `LogoutWidget` | `logout_widget.dart` | Logout button row |
| `MenuTileWidget` | `menu_tile_widget.dart` | Generic drawer menu tile |
| `NetworkImageWidget` | `images/network_image_widget.dart` | Cached network image with fallback |
| `AddressFormField` / `AddressLabelSelector` | `address_widgets.dart` | Address form inputs |

## 9. Code Quality

- [ ] `dart analyze` passes with **no issues** on all changed files
- [ ] No `const` on widgets/lists that use `.tr` getters
- [ ] No hardcoded English strings directly in widget trees
- [ ] `dispose()` called for every `TextEditingController` / `ScrollController`
- [ ] Lists initialized in `initState()` (not as field initializers) when they use `.tr`

## 10. Scrollability

- [ ] Page body is a `ListView` (not `Column`) when content may overflow
- [ ] `ListView` has `padding: EdgeInsets.only(bottom: safe.bottom + 24)`
- [ ] No `Expanded` inside a `ListView` — use `SizedBox` with fixed height instead
- [ ] Long content in landscape uses `SingleChildScrollView` or `ListView` per column

---

**Quick paste for new page request:**

```
Apply all items from .claude/UI_PAGE_CHECKLIST.md:
- AppColors only, no hardcoded colors
- SafeArea: MediaQuery.padding (left/right/bottom), no SafeArea widget
- Landscape: two-column layout, compact header
- Keyboard: no viewInsets.bottom added manually
- i18n: all strings via *Strings class + EN/FA translations
- RTL: LTR wrapper for numbers/emails
- dart analyze: no issues
```
