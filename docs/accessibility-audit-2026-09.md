# Suma WCAG 2.2 audit: failed criteria

Source: the audit published 2026-09-25 at https://claude.ai/artifact/Vrc66SPCoyHtp4fJAwFQjg (commit 31b1c124). This file lists every success criterion that fails or partially fails in either app, then every finding. "Partial" counts as a failure for conformance. Paths in findings are relative to `webapp/src/` or `adminapp/src/` unless they start with another top-level directory.

## Level A (18 criteria with a failure)

| Criterion | Member app | Admin app | Findings and notes |
|---|---|---|---|
| 1.1.1 Non-text Content | Fail | Fail | Icon-only controls, image links, loaders, map markers without names (W-2, W-3, W-20, W-22; A-1, A-28) |
| 1.3.1 Info and Relationships | Fail | Fail | Labels and errors not associated, no fieldsets, heading structure, header-less tables (W-8, W-9, W-23, W-24; A-3, A-4, A-12, A-13) |
| 1.3.3 Sensory Characteristics | Pass | Partial | Admin instruction refers to an unnamed icon button (A-28) |
| 1.4.1 Use of Color | Fail | Fail | Current tab by background only (W-17); admin state by colour or opacity (A-11) |
| 2.1.1 Keyboard | Fail | Partial | Press-and-hold, ledger picker, map polygons (W-1, W-15, W-16); admin status menu, invisible file input, scroll container (A-18, A-7) |
| 2.2.1 Timing Adjustable | Fail | Fail | 5 second toasts, carousel (W-12, W-13, A-5) |
| 2.2.2 Pause, Stop, Hide | Fail | Pass | Carousel, blinking alerts, auto-refreshing map (W-13, W-14, W-16) |
| 2.4.1 Bypass Blocks | Fail | Pass | No main, no skip link (W-10); admin has landmarks, skip link recommended (A-31) |
| 2.4.2 Page Titled | Pass | Partial | Three admin pages inherit stale titles, create pages all titled Create (A-14); one English title in Spanish (W-44) |
| 2.4.3 Focus Order | Partial | Partial | No focus management on route change or unmount (W-31, A-17) |
| 2.4.4 Link Purpose (In Context) | Fail | Fail | Empty and icon-only links (W-2, W-3, A-1) |
| 2.5.2 Pointer Cancellation | Fail | Fail | Navigate on pointer-down (W-18); clear on mouse-down (A-27) |
| 2.5.3 Label in Name | Partial | Pass | Agreement checkbox aria-label differs from visible text (W-40) |
| 3.1.1 Language of Page | Fail | Pass | Live: lang stays en in Spanish (W-5) |
| 3.2.2 On Input | Partial | Pass | Focus auto-advances while typing without notice (W-30) |
| 3.3.1 Error Identification | Partial | Partial | Backend field errors discarded (W-34, S-3); admin errors only in a toast (A-5) |
| 3.3.2 Labels or Instructions | Fail | Partial | Placeholder-only labels, no required marker, no format hints (W-8, W-37); admin gaps (A-4) |
| 4.1.2 Name, Role, Value | Fail | Fail | Unnamed controls, class-only disabled, div menu items (W-2, W-15, W-25); unlabelled selects, custom editor, invalid role (A-3, A-9, A-22) |

## Level AA (16 criteria with a failure)

| Criterion | Member app | Admin app | Findings and notes |
|---|---|---|---|
| 1.3.4 Orientation | Fail | Pass | PWA manifest and meta lock portrait (W-11) |
| 1.3.5 Identify Input Purpose | Partial | Fail | Missing tokens on name, state, cardholder fields (W-26); sign-in has none (A-22) |
| 1.4.3 Contrast (Minimum) | Fail | Fail | Brand gold at 2.26:1 on every page (W-4, A-2) |
| 1.4.10 Reflow | Partial | Partial | Live pass at 320px on tested pages; OTP row and card preview exceed 288px in code (W-36); admin header rows do not wrap (A-24) |
| 1.4.11 Non-text Contrast | Fail | Fail | Gold button borders and focus ring below 3:1; see contrast appendix (W-4, W-6, A-7) |
| 1.4.12 Text Spacing | Partial | Manual | Live pass on three pages; fixed-size circle and badges in code (W-36); admin pick list forces ellipsis (A-24) |
| 2.4.6 Headings and Labels | Partial | Partial | Dashboard has no heading; placeholder-only labels (W-8, W-23); admin empty labels (A-4, A-12) |
| 2.4.7 Focus Visible | Fail | Partial | Live: hamburger and tab bar show nothing (W-6); MUI ripple only (A-7) |
| 2.4.11 Focus Not Obscured (Minimum) | Fail | Fail | Live: focus under 108px sticky header (W-7); fixed AppBar and sticky panel (A-8) |
| 2.5.7 Dragging Movements | Fail | Pass | Map panning is drag-only (W-16) |
| 2.5.8 Target Size (Minimum) | Partial | Partial | Gear and chevron rely on spacing exception (W-33); 4px cursor slots (A-20) |
| 3.1.2 Language of Parts | Fail | Fail | Language names, hard-coded English, library defaults (W-28); Spanish fields unmarked (A-21); two untranslated seeds (S-4) |
| 3.2.4 Consistent Identification | Partial | Partial | Back and language switch vary (W-45); add and edit icons vary (A-30) |
| 3.3.3 Error Suggestion | Partial | Partial | Generic This field is not valid (W-34); toast-only (A-5) |
| 3.3.4 Error Prevention (Legal, Financial, Data) | Partial | Fail | Add funds, pay, end trip unconfirmed (W-19); book, funding, refund unconfirmed (A-6) |
| 4.1.3 Status Messages | Partial | Fail | Success and loading silent (W-20); loaders and counters silent (A-10) |

## Level AAA (20 criteria with a failure)

| Criterion | Member app | Admin app | Findings and notes |
|---|---|---|---|
| 1.3.6 Identify Purpose | Fail | Partial | No main landmark, unlabelled navs, decorative icons exposed (W-10, W-22); admin lacks search landmark and aria-current (A-15) |
| 1.4.6 Contrast (Enhanced) | Fail | Fail | Links 4.99:1, help text 6.39:1 (W-4); MUI secondary text 5.74:1 (A-2) |
| 1.4.8 Visual Presentation | Fail | Fail | Paragraph spacing 1x, forced colours, no user colour choice (W-35, A-32) |
| 2.1.3 Keyboard (No Exception) | Fail | Partial | Same as 2.1.1 |
| 2.2.3 No Timing | Fail | Fail | Same as 2.2.1 |
| 2.2.4 Interruptions | Partial | Pass | Map refresh closes the open drawer (W-16) |
| 2.2.5 Re-authenticating | Partial | Partial | Cart survives, form input does not; no 401 handling (W-41, A-25) |
| 2.3.3 Animation from Interactions | Fail | Fail | No prefers-reduced-motion anywhere (W-32, A-19) |
| 2.4.8 Location | Fail | Fail | No aria-current, no breadcrumbs in admin (W-17, A-15) |
| 2.4.9 Link Purpose (Link Only) | Fail | Fail | Learn More, Continue, raw URLs (W-39); id-only links (A-16) |
| 2.4.10 Section Headings | Partial | Partial | Dashboard and menu unsectioned (W-23); admin form sections use labels not headings (A-12) |
| 2.4.12 Focus Not Obscured (Enhanced) | Fail | Fail | Same plus overlays (A-8) |
| 2.4.13 Focus Appearance | Fail | Fail | Ring at about 1.2:1 or absent (W-6, A-7) |
| 2.5.5 Target Size (Enhanced) | Fail | Fail | Many targets under 44px (W-33, A-20) |
| 3.1.3 Unusual Words | Fail | Partial | No glossary for members (S-2); staff glossary exists but off-site (A-29) |
| 3.1.4 Abbreviations | Fail | Fail | SMS, CVC, ID, PGE, EBT, Qty unexpanded (S-2, A-29) |
| 3.1.5 Reading Level | Partial | Fail | UI copy grade 3.9; legal text grade 10 to 15 (S-1); admin helper paragraphs (A-29) |
| 3.2.5 Change on Request | Fail | Partial | New windows without warning, internal link in new tab (W-29, A-26); auto reload script (S-5) |
| 3.3.5 Help | Partial | Partial | Bank help exists; none for card, phone, limits (W-37) |
| 3.3.6 Error Prevention (All) | Fail | Fail | Survey and reserve irreversible (W-19); creates and edits unreviewed (A-6) |

# Findings

Severity: Critical blocks a task for some users, High degrades a core task, Medium degrades a secondary task or affects many pages, Low has a workaround.

## Member app findings (W-)

### W-1 Order claiming is mouse and touch only

- **Severity:** critical
- **Criteria:** 2.1.1 A, 2.1.3 AAA, 2.5.6 AAA
- **Where:**
  - `components/PressAndHold.jsx:50-54`
  - `shared/react/useLongPress.jsx:16-27`
  - `components/OrderDetail.jsx:219 (used by OrderHistoryDetail and UnclaimedOrderList)`
- **What:** The claim control wires `onMouseDown`, `onMouseUp`, `onMouseLeave`, `onTouchStart` and `onTouchEnd` to a two-second hold timer. There is no `onClick` or key handler, so keyboard and switch users cannot claim an order at all.
- **Fix:** Add `onKeyDown` for Space and Enter (ignoring `e.repeat`) that starts the hold, and `onKeyUp` and `onBlur` that cancel it. Better: offer a plain button that opens a confirmation dialog as the accessible equivalent of the hold, keeping press-and-hold as an enhancement.

### W-2 Icon-only controls have no accessible name

- **Severity:** critical
- **Criteria:** 1.1.1 A, 4.1.2 A, 2.4.4 A
- **Where:**
  - `components/Copyable.jsx:21-23 (copy button)`
  - `components/FormSaveCancel.jsx:15-32 (save and cancel)`
  - `components/OrderDetail.jsx:127-136 (edit fulfilment)`
  - `pages/Funding.jsx:207-209 (gear menu, the only route to Unlink account)`
  - `components/CurrencyNumpad.jsx:59-61 (delete key is the glyph U+232B)`
  - `components/NavButton.jsx:26-28 with BackBreadcrumb.jsx:29-42 (chevron-only Back on FoodList.jsx:85 and TripDetail.jsx:39)`
  - `components/CartIconButton.jsx:15-23 with CartIcon.jsx:26-29 (name is the item count)`
- **What:** Bootstrap Icons render as private-use glyphs in a `::before` pseudo-element, so a button containing only an icon has an empty name. Screen readers announce "button". The cart link announces "0" or "3".
- **Live evidence:** axe link-name on the chevron back link at /app/food/1; cart link text measured as "0".
- **Fix:** Add a localised `aria-label` from `t()` and hide the glyph: ``. For the cart use `aria-label={t('food.cart_with_items', {count})}`. Give NavButton an `aria-label` whenever it renders without children.

### W-3 Empty and image-only links

- **Severity:** critical
- **Criteria:** 2.4.4 A, 1.1.1 A
- **Where:**
  - `pages/FoodList.jsx:140 (empty stretched-link)`
  - `pages/Dashboard.jsx:147-155 (image links with alt="")`
  - `components/VendibleCard.jsx:22-24 and pages/FoodCart.jsx:131-133 (name depends on image.caption, which defaults to empty in SumaImage.jsx:57)`
- **What:** Product cards use an empty `a.stretched-link` for the click area, and dashboard and offering thumbnails are wrapped in links whose only content is an image with empty alt. Each is a tab stop that announces nothing.
- **Live evidence:** axe link-name: 4 empty stretched links on each offering page, 2 image links on the dashboard, 2 on the food list.
- **Fix:** Give the stretched link the product name (`aria-label={dt(name)}`) or wrap the heading in it. For duplicate image links next to a text link, add `aria-hidden='true' tabIndex={-1}` so there is one named link per card.

### W-4 Brand gold used for text, links and outlines fails contrast everywhere

- **Severity:** critical
- **Criteria:** 1.4.3 AA, 1.4.6 AAA, 1.4.11 AA
- **Where:**
  - `assets/styles/_theme.scss:15 ($primary #CDA671), :16 ($secondary #848682), :17 ($success #498567), :53 ($link-color darken($primary,16%) = #AF7F3E)`
  - `assets/styles/custom.scss:48-70 (.app-link on rgba(0,0,0,.05))`
  - `components/AppNav.jsx, TopNav.jsx (brand text), all btn-outline-primary buttons`
- **What:** Measured live: gold on white 2.26:1 (outline buttons, brand text on 28 pages), gold tab bar on grey 1.81:1, link colour 3.16 to 3.54:1, secondary text 3.28 to 3.67:1, success text 3.88:1 and white on success 4.34:1, white on the program-card gold 2.56:1. AA needs 4.5:1 (3:1 for large text) and AAA needs 7:1. Gold button borders also fail the 3:1 non-text requirement.
- **Live evidence:** axe color-contrast failed on 44 of 44 member pages, 202 nodes; color-contrast-enhanced on 9 pages.
- **Fix:** Split the palette: keep `#CDA671` as a fill behind dark text (`#0d0d0d` on gold is 8.60:1) and add a text-safe gold, `#725328` (7.04:1 on white, same hue), for text, links and outlines. In `_theme.scss`: restore `$min-contrast-ratio: 4.5` (line 7 sets 2.5, which is why Bootstrap picks white text on the tan fill); `$link-color: #725328`; `$secondary: #575956` (7.07:1); `$success: #35614b` (7.09:1); `$danger: #9e3500` (7.09:1); `$component-active-bg: #725328`; re-declare `.btn-outline-primary` with `button-outline-variant(#725328)`; give `.app-link` text `#604522` (7.09:1 on its grey); switch the navbar to `variant='light'` so the brand reads black on gold (9.29:1). Because the dark gold is only 2.19:1 from body text, keep links underlined (remove the `text-decoration: none` in _theme.scss:110-112 and alerts.scss:24).

### W-5 Document language stays English in the Spanish UI

- **Severity:** high
- **Criteria:** 3.1.1 A
- **Where:**
  - `index.html:2 (lang="en")`
  - `localization/I18nProvider.jsx:77-101 and :104-110`
- **What:** Switching language updates the strings, dayjs locale and page title but never sets `document.documentElement.lang`. Screen readers read Spanish content with English pronunciation rules.
- **Live evidence:** After switching through the menu the title read "Tablero | App de Suma" and `html[lang]` was still `en`.
- **Fix:** In both the mount effect and `changeLanguage`: `document.documentElement.lang = language;`

### W-6 Focus is invisible on the menu button and tab bar, and faint elsewhere

- **Severity:** high
- **Criteria:** 2.4.7 AA, 2.4.13 AAA, 1.4.11 AA
- **Where:**
  - `assets/styles/topnav.scss:28-36 (.navbar-toggler focus box-shadow: none)`
  - `assets/styles/custom.scss:52,69 (.app-link background !important)`
  - `assets/styles/otp.scss:14-21 (border #CDA671, outline none)`
  - `Bootstrap default $focus-ring-color rgba($primary,.25)`
- **What:** The hamburger removes its border and focus shadow. Tab-bar links force their background with `!important`, which cancels Bootstrap's focus background change, and their focus shadow computes to transparent, leaving only a text colour shift from gold to darker gold. Small outline buttons behave the same. Inputs get a 4px ring at 25% gold, about 1.2:1 against white.
- **Live evidence:** Tabbing through the dashboard: hamburger `outline: none; box-shadow: none`; tab links `outline: none`, box-shadow `rgba(0,0,0,0) 0 0 0 0`, background unchanged. See the screenshot reconstruction in the live results.
- **Fix:** In _theme.scss set `$focus-ring-width: .125rem; $focus-ring-opacity: 1; $focus-ring-color: #725328;` and add one rule for buttons, inputs, checks, nav links, close buttons, the toggler, the code fields, dropdown items and links: `outline: 2px solid #725328; outline-offset: 2px; box-shadow: 0 0 0 2px #fff;`. The brown ring measures 7.04:1 on white, 6.29:1 on the light grey and 3.11:1 on the gold fill; the white inner ring carries it over green, red and dark fills. Delete the `box-shadow: none` rule on the toggler and the `outline: none` on the code field, and drop `!important` from the tab background so the focus state can change it.

### W-7 Sticky header hides focused elements

- **Severity:** high
- **Criteria:** 2.4.11 AA, 2.4.12 AAA
- **Where:**
  - `components/PageLayout.jsx:72-76 (div.sticky-top wrapping TopNav, AppNav and the cart addon)`
  - `state/ErrorToastProvider.jsx:37-39 (toast fixed at the nav height)`
  - `no scroll-padding-top in any stylesheet`
- **What:** When Shift+Tab moves focus to an element above the viewport the browser scrolls it to the top edge, where the 108px sticky block covers it. The error toast also sits over content for five seconds.
- **Live evidence:** Measured sticky height 107.75px; focused links landed at top 89px, bottom 109px, three times in twelve Shift+Tab presses.
- **Fix:** Set `html { scroll-padding-top: 120px; }` or drive it from the measured nav height as a CSS custom property. Move the toast to the bottom of the viewport.

### W-8 Shared form control hides the label, uses the placeholder instead, and never marks invalid or required state

- **Severity:** high
- **Criteria:** 1.3.1 A, 3.3.1 A, 3.3.2 A, 4.1.2 A
- **Where:**
  - `components/FormControlGroup.jsx:51 (required destructured), :62-64 (only passed to react-hook-form), :80-95 (control), :91 (placeholder = label), :98-100 (label visually-hidden), :108,113 (Feedback without id), :116 (FormText without id)`
  - `components/FormRadioInputs.jsx:41-60`
- **What:** Every text field in Start, RegainAccountAccess, OnboardingSignup, ContactListAdd, AddCreditCard and FundingLinkBankAccount loses its visible label once a value is typed. react-bootstrap's `isInvalid` only adds a class, so no `aria-invalid` is set; the error and help text have no id, so nothing is in `aria-describedby`; nothing indicates which fields are required.
- **Fix:** Render the label visibly (Bootstrap floating labels work with the current layout). In FormControlGroup generate ids and pass `aria-required`, `aria-invalid={!!message || undefined}` and `aria-describedby` joining the help and error ids. Add a required marker and a once-per-form legend.

### W-9 Radio and checkbox groups have no fieldset and legend

- **Severity:** high
- **Criteria:** 1.3.1 A
- **Where:**
  - `components/FormRadioInputs.jsx:38-63 (payment and fulfilment choices in FoodCheckout.jsx:244-252 and :311-319)`
  - `pages/FundingLinkBankAccount.jsx:199-222 (account type)`
  - `components/WaitingList.jsx:156-172 (survey)`
  - `components/OrderDetail.jsx:165-179`
  - `pages/OneTimePassword.jsx:159-186 (fieldset present, heading is not the legend)`
- **What:** The group question is a heading or an unassociated label, so a screen reader landing on a radio hears only the option text.
- **Fix:** Wrap each group in `{question}…` and style the legend as the current heading.

### W-10 No main landmark, no skip link, unlabelled navigation

- **Severity:** high
- **Criteria:** 2.4.1 A, 1.3.6 AAA, 1.3.1 A
- **Where:**
  - `components/PageLayout.jsx:67-92 (content in div.main-container)`
  - `components/AppNav.jsx:10 (div, not nav)`
  - `components/LinearBreadcrumbs.jsx:13 (nav without aria-label)`
  - `components/TopNav.jsx:212-247 (footer links inside the nav collapse)`
- **What:** Keyboard users pass the brand, menu toggle, four tab links and the cart button before content on every page. Two `nav` elements per page have no distinguishing label.
- **Live evidence:** axe landmark-one-main and region on 44 of 44 pages; landmark-unique on 16.
- **Fix:** In PageLayout add `{t('common.skip_to_content')}` and wrap the page node in ``. Make AppNav a `nav` with `aria-label`; label the breadcrumb nav; move footer links into a `footer`.

### W-11 Installed app is locked to portrait

- **Severity:** high
- **Criteria:** 1.3.4 AA
- **Where:**
  - `public/manifest.json:8 ("orientation": "portrait")`
  - `index.html:22 (meta screen-orientation)`
- **What:** Members who mount a device in landscape (wheelchair mounts, some tablets) cannot use the installed app. Nothing in the layout requires portrait.
- **Fix:** Set `"orientation": "any"` or remove the key, and delete the meta tag.

### W-12 Error messages disappear after five seconds

- **Severity:** high
- **Criteria:** 2.2.1 A, 2.2.3 AAA
- **Where:**
  - `state/ErrorToastProvider.jsx:41-46 (autohide, default delay 5000)`
  - `components/Copyable.jsx:27-33 (2 second toast)`
- **What:** Checkout, cart, claim and preference errors are shown only in a toast that closes itself. react-bootstrap Toast has no pause on hover or focus. Slow readers and screen-reader users lose the message.
- **Fix:** Use `autohide={false}`; a close button already exists. If auto-dismiss is kept, raise the delay to at least 20 seconds and pause on `onMouseEnter` and `onFocus`.

### W-13 Onboarding carousel auto-advances with no pause

- **Severity:** high
- **Criteria:** 2.2.2 A, 2.2.1 A, 2.3.3 AAA
- **Where:**
  - `pages/Onboarding.jsx:13 (Carousel fade), :52 (interval 2200)`
  - `assets/styles/onboarding.scss:26-30 (indicators hidden)`
- **What:** Slides change every 2.2 seconds indefinitely next to the Continue button. react-bootstrap pauses only on hover, which does not exist on touch or keyboard.
- **Fix:** Set `interval={null}` so slides move only on request, or add a visible Pause and Play control and stop automatically when `prefers-reduced-motion` is set.

### W-14 Dashboard alerts blink forever

- **Severity:** high
- **Criteria:** 2.2.2 A, 2.2.4 AAA
- **Where:**
  - `assets/styles/alerts.scss:2-19 (.blinking-alert, infinite, 1s)`
  - `pages/Dashboard.jsx:81,114,125`
- **What:** A border animation runs indefinitely with no way to stop it. It is below the flash threshold (0.5 Hz) but fails the five-second limit for moving content.
- **Fix:** Limit to `animation-iteration-count: 4` and disable under `@media (prefers-reduced-motion: reduce)`.

### W-15 Ledger picker items cannot be reached by keyboard

- **Severity:** high
- **Criteria:** 2.1.1 A, 4.1.2 A
- **Where:**
  - `pages/LedgersOverview.jsx:152-175 (Dropdown.Item as={Stack})`
- **What:** Passing `as={Stack}` renders each menu item as a `div`. The library's arrow-key handling calls `.focus()` on items, which is a no-op on a non-focusable div, and it sets `aria-selected` on an element with no role. Keyboard users can open the menu but cannot choose a ledger.
- **Fix:** Remove `as={Stack}` (the default renders a focusable `role='button'`) or use `as='button' type='button'` and put the Stack inside.

### W-16 Mobility map has no text alternative, unnamed markers, pointer-only zones and drag-only panning

- **Severity:** high
- **Criteria:** 1.1.1 A, 2.1.1 A, 2.5.7 AA, 2.2.2 A, 4.1.2 A
- **Where:**
  - `components/mobilitymap/Map.jsx:238 (map container, no role or label)`
  - `modules/mapBuilder.js:274-288 (markers are role=button with two alt="" images and no title)`
  - `modules/mapBuilder.js:352-359 (restriction polygons with popups, not focusable)`
  - `modules/mapBuilder.js:27-41 (only zoom and locate controls, no pan)`
  - `modules/mapBuilder.js:202-209, 251-262 (auto-refresh closes the selected vehicle drawer)`
- **What:** Leaflet makes markers focusable buttons, but each has an empty name. "Do not park" zones are only discoverable by tapping them. Panning requires a drag; keyboard arrows work but are not a single-pointer alternative. The refresh timer can close the drawer a user is reading.
- **Fix:** Give the container `role='region' aria-label={t('mobility.map')}`; set `title` on each marker (vendor and vehicle type); add a four-way pan control; show restriction text in the drawer when zones intersect the view; add an accessible list of nearby vehicles with a Show on map action; replace the automatic close with an in-drawer message.

### W-17 Current page indicated only by background colour

- **Severity:** high
- **Criteria:** 1.4.1 A, 2.4.8 AAA, 1.3.1 A
- **Where:**
  - `components/AppNav.jsx:26-36 (app-link-active)`
  - `assets/styles/custom.scss:52,69 (rgba(0,0,0,.05) vs white)`
  - `components/TopNav.jsx:189-206 (filled vs outline caret glyph)`
- **What:** The active tab differs from the others only by a white versus light-grey background (1.2:1) and no `aria-current` is set anywhere.
- **Fix:** Add `aria-current={active ? 'page' : undefined}` (react-router NavLink does this) and a non-colour cue such as bold text or an underline.

### W-18 Link navigates on pointer-down

- **Severity:** high
- **Criteria:** 2.5.2 A
- **Where:**
  - `components/ELink.jsx:34-45 (immediate sets onPointerDown to navigate)`
  - `pages/Start.jsx:94 (Message us link)`
- **What:** Navigation fires on the down event, so a user who slides off to cancel is still taken away from the form.
- **Fix:** Remove `immediate`. If it exists to avoid a blur-validation race, use `onMouseDown={(e) => e.preventDefault()}` to keep focus and let the click navigate.

### W-19 Money-moving and irreversible actions submit with one tap

- **Severity:** high
- **Criteria:** 3.3.4 AA, 3.3.6 AAA
- **Where:**
  - `pages/FundingAddFunds.jsx:93-99, 143-151 (charges immediately; button says Add Funds, not the amount, though forms.add_amount exists)`
  - `pages/Funding.jsx:55-64 (Pay)`
  - `components/mobilitymap/Trip.jsx:53-60 (End Trip)`
  - `components/mobilitymap/PreTrip.jsx:71-73 (Reserve)`
  - `components/WaitingList.jsx:32-46, 107-116 (survey submitted without validation and cannot be changed)`
- **What:** Checkout has a review page and unlinking an instrument has a confirm dialog, but adding funds, paying a balance, ending a trip and reserving a vehicle have no review, confirmation or reversal.
- **Fix:** Use `forms.add_amount` so the button states the amount, and add a confirmation step (the existing unlink modal pattern) for add funds, pay and end trip. Let survey answers be reviewed before submit or edited afterwards.

### W-20 Loading and success states are silent

- **Severity:** medium
- **Criteria:** 4.1.3 AA, 1.1.1 A
- **Where:**
  - `components/PageLoader.jsx:43-50, ScreenLoader.jsx:23, CartIcon.jsx:30-37, mobilitymap/DrawerLoading.jsx (img alt="" only)`
  - `components/FormSuccess.jsx:20 (plain p, used for code resent and preferences saved)`
  - `components/CartIcon.jsx:26-29 (count changes silently)`
  - `components/WaitingList.jsx:118-134 (JustFinished)`
  - `components/mobilitymap/Map.jsx:229-231 (location permission error)`
- **What:** Screen readers get no announcement that a page is loading, that a new code was sent, that preferences saved, or that the cart count changed.
- **Fix:** Wrap loaders in `{t('common.loading')}`; give FormSuccess `role='status'`; put the cart count in a polite live region.

### W-21 Offline indicator is icon-only and stays in the accessibility tree

- **Severity:** medium
- **Criteria:** 1.1.1 A, 1.4.1 A, 4.1.3 AA
- **Where:**
  - `components/TopNav.jsx:49-56`
  - `assets/styles/topnav.scss:73-84 (opacity 0 when online)`
- **What:** Being offline is shown as a red circle with an icon and no text, and when online the element is still present at zero opacity.
- **Fix:** Render `` with visually hidden "You are offline" text, and hide the icon.

### W-22 Decorative icons exposed, and a few given wrong or English names

- **Severity:** medium
- **Criteria:** 1.1.1 A, 1.3.6 AAA, 3.1.2 AA
- **Where:**
  - `About 34 <i class="bi …"> without aria-hidden: TopNav.jsx:172,190-193,203,221,227; NavButton.jsx:26,28; SeeAlsoAlert.jsx:23,27; Food.jsx:80; FoodCheckout.jsx:194,203,333,355; FoodCheckoutConfirmation.jsx:83; Funding.jsx:122,155,198; PreTrip.jsx:60; ErrorToastProvider.jsx:48; TranslationToggle.jsx:31; PrivateAccountDetail.jsx:309; UnclaimedOrderList.jsx:85; PrivacyPolicyContent.jsx:342-347; Dashboard.jsx:171`
  - `pages/Dashboard.jsx:97-101 (role=img aria-label="Map Icon" inside a link that already has text)`
  - `pages/PrivateAccountDetail.jsx:112-129 (step number and done state are icon-only)`
  - `components/AnimatedCheckmark.jsx:6-14 (svg without aria-hidden)`
  - `components/CreditCardPreview.jsx:29-86, 94-95 (decorative preview read aloud, hard-coded YOUR NAME HERE and valid thru)`
  - `pages/Trips.jsx:84-89, TripDetail.jsx:45-50 (alt is a raw slug such as lime escooter)`
- **What:** Private-use glyphs may be announced as noise; the step icons carry meaning that is not in text; the card preview duplicates the form in English.
- **Live evidence:** 1 to 5 unhidden icons on every member page.
- **Fix:** Introduce an Icon component that always renders `aria-hidden='true'`; add visually hidden step text; put `aria-hidden='true'` on the card preview and the checkmark; use empty alt for the vehicle image.

### W-23 Heading levels missing, skipped and duplicated

- **Severity:** medium
- **Criteria:** 1.3.1 A, 2.4.6 AA, 2.4.10 AAA
- **Where:**
  - `components/PageHeading.jsx:11-12 (defaults to h2)`
  - `pages/Dashboard.jsx:40-72 (no page heading, only h5 card titles)`
  - `pages/Food.jsx:52,57 (h2 then h4); FoodDetails.jsx:81,125,126 (h1, h5, h4); OrderDetail.jsx:29,115 (h3 then h6); Trips.jsx:37,64; Funding.jsx:31,304`
  - `components/PrivacyPolicyContent.jsx:81,110,150 (three h1 elements)`
  - `data/i18n/seeds/en/terms_of_use_and_sale.json:2 (# then ###)`
- **Live evidence:** 35 of 44 pages without an h1; heading-order failures on 11 pages; the privacy page lists h1 Overview, h1 Community Driven.
- **Fix:** Make PageHeading default to `h1`, give the dashboard a heading, and keep levels sequential. Demote the privacy sections to h2 and h3.

### W-24 Transaction list rendered as a header-less table

- **Severity:** medium
- **Criteria:** 1.3.1 A
- **Where:**
  - `pages/LedgersOverview.jsx:205-241 (Table with single anonymous td per row)`
- **What:** A table with no header cells or caption conveys no structure; the content is a list.
- **Fix:** Render as `ul.list-unstyled`, or add a caption and header cells for date, memo and amount.

### W-25 Disabled state expressed by CSS class only

- **Severity:** medium
- **Criteria:** 4.1.2 A, 1.3.1 A
- **Where:**
  - `components/FoodCartWidget.jsx:118-127 ("disabled" class on the plus button at max quantity)`
  - `components/ForwardBackPagination.jsx:21-32 ("disabled" class instead of the disabled prop)`
- **What:** The controls look disabled but remain focusable, clickable and announced as enabled.
- **Fix:** Use the `disabled` prop, which react-bootstrap turns into a non-interactive element, or `aria-disabled='true'` with a guard in the handler.

### W-26 Autocomplete tokens missing or mismatched

- **Severity:** medium
- **Criteria:** 1.3.5 AA
- **Where:**
  - `pages/ContactListAdd.jsx:84-93 (name field, no autocomplete)`
  - `pages/OnboardingSignup.jsx:135-155 (state select, needs address-level1)`
  - `components/AddCreditCard.jsx:161-176 (cardholder uses name instead of cc-name)`
  - `components/AddCreditCard.jsx:252 (cvc flagged by axe autocomplete-valid)`
- **What:** Browsers and assistive tools cannot auto-fill or identify these fields. The axe hit on the security code is worth verifying: the token is correct but axe rejects the pairing with the surrounding attributes.
- **Live evidence:** Contact-list name field observed with no autocomplete; axe autocomplete-valid on the security code input.
- **Fix:** Add `autoComplete='name'`, `'address-level1'` and `'cc-name'` respectively.

### W-27 Organisation dropdown has no label

- **Severity:** medium
- **Criteria:** 4.1.2 A, 1.3.1 A
- **Where:**
  - `components/OrganizationInputDropdown.jsx:21-29 (FormControlGroup called without a label prop)`
  - `pages/ContactListAdd.jsx:132-138`
- **What:** FormControlGroup renders a label only when given one. The select is announced by its current option text alone.
- **Live evidence:** axe select-name (critical) on /app/contact-list/add.
- **Fix:** Pass `label={t('forms.organization')}` to FormControlGroup.

### W-28 Language of parts not marked; English strings shipped in the Spanish UI

- **Severity:** medium
- **Criteria:** 3.1.2 AA, 4.1.2 A
- **Where:**
  - `components/TranslationToggle.jsx:19,31; TopNav.jsx:112; pages/ContactListHome.jsx:47 (language names without lang)`
  - `components/CreditCardPreview.jsx:94-95; AddCreditCard.jsx:223 (MM / YY), :256 (CVC); pages/PartnerSignup.jsx:104 (title Join …); components/FoodCartWidget.jsx:59,89 (aria-label add-to-cart); TopNav.jsx:74 (Impersonating:)`
  - `react-bootstrap defaults never overridden: Navbar toggle "Toggle navigation" (TopNav.jsx:58, PrivacyPolicyContent.jsx:341), Modal and Alert close labels (Funding.jsx:241, FundingLinkBankAccount.jsx:239, UnclaimedOrderList.jsx:99, PrivateAccountsList.jsx:66, AddToHomescreen.jsx:120, PreferencesAuthed.jsx:27), Carousel Previous, Next, Slide n (Onboarding.jsx:13)`
- **Live evidence:** The Spanish dashboard still exposed the menu toggle as "Toggle navigation" and no element carried a lang attribute.
- **Fix:** Wrap language names in ``; move literals to strings.json; pass `label`, `closeLabel`, `prevLabel`, `nextLabel` and `indicatorLabels` from `t()`.

### W-29 Every external link, and some internal ones, opens a new window without warning

- **Severity:** medium
- **Criteria:** 3.2.5 AAA
- **Where:**
  - `shared/react/SafeExternalLink.jsx:14-17 (always target=_blank)`
  - `components/ContactListTags.jsx:9 (internal /privacy-policy in a new tab)`
  - `components/PrivacyPolicyContent.jsx:374-379 (mailto in a new tab)`
  - `markdown links via MdLink: common.faq, payments.payment_intro.privacy_statement, food.terms_of_use_agreement, mobility.location_permissions_denied_instructions`
- **Fix:** Append visually hidden "(opens in a new window)" and an icon inside SafeExternalLink; use RLink for internal pages; do not force new windows on mailto links.

### W-30 Focus moves automatically while typing without telling the user

- **Severity:** medium
- **Criteria:** 3.2.2 A
- **Where:**
  - `pages/OneTimePassword.jsx:58-65 (next box per digit), :46-50 and :91-94 (jump to Verify)`
  - `components/AddCreditCard.jsx:117-119 (expiry to security code)`
- **Fix:** State the behaviour in the instructions, or replace the six boxes with one `maxLength=6` input, which also simplifies paste and autofill.

### W-31 Focus is not managed on route change, error or success

- **Severity:** medium
- **Criteria:** 2.4.3 A
- **Where:**
  - `App.jsx and components/ScrollToTopOnMount.jsx:8 (scroll only, focus falls to body)`
  - `components/AddCreditCard.jsx:90 (activeElement.blur() after a Stripe error)`
  - `pages/RegainAccountAccess.jsx:88,100 (two autoFocus props; the second wins)`
  - `pages/FundingAddCard.jsx:53-54, FundingLinkBankAccount.jsx:33-34, components/WaitingList.jsx:50-51 (success views replace the form without moving focus)`
- **Fix:** On pathname change focus `main` or the page heading; focus the error alert instead of blurring; remove the duplicate autoFocus; focus the success heading.

### W-32 No reduced-motion support

- **Severity:** medium
- **Criteria:** 2.3.3 AAA
- **Where:**
  - `No prefers-reduced-motion anywhere in webapp/src`
  - `assets/styles/animated-checkmark.scss:15-57; components/PressAndHold.css:12 (2s infinite pulse); topnav.scss:25,54-66; react-credit-card.scss:76,122,427; modules/mapBuilder.js:556-560 (flyTo 1.3s) and :478-488 (animated marker); components/PrivacyPolicyContent.jsx:319-323 (smooth ScrollSpy); food.scss:14-31`
- **Fix:** Add a global reduced-motion rule that zeroes animation and transition durations, and check `matchMedia('(prefers-reduced-motion: reduce)')` before flyTo, smooth scroll and the animated marker.

### W-33 Many targets are smaller than 44px, a few smaller than 24px

- **Severity:** medium
- **Criteria:** 2.5.5 AAA, 2.5.8 AA
- **Where:**
  - `components/NavButton.jsx:19-25 (Back, measured 78×34); chevron-only Back 29×34`
  - `pages/Funding.jsx:208 (gear, about 16×24); OrderDetail.jsx:127-136 (pencil); Copyable.jsx:21`
  - `components/TopNav.jsx:220-245 (footer links 25px tall, social icons 24px)`
  - `components/SignupAgreement.jsx:25 and preferences checkboxes (17×17)`
  - `btn-sm buttons at 42px (Dashboard.jsx:95,163-172; CartIconButton.jsx:18-19; PreTrip, PostTrip, Trip); tab bar links 41px tall; hamburger 53×37`
  - `Leaflet zoom and locate 30×30; cluster badge 36px; modal and toast close 25px`
- **Live evidence:** Measured on 47 page loads; inline text links are exempt and were excluded.
- **Fix:** Set `.btn-sm, .btn-link.p-0 { min-width: 44px; min-height: 44px }`, pad icon buttons, enlarge Leaflet bar controls to 44px, and give checkboxes a 44px hit area through the label.

### W-34 Generic validation messages and discarded backend field errors

- **Severity:** medium
- **Criteria:** 3.3.3 AA, 3.3.1 A
- **Where:**
  - `state/useValidationError.jsx:22 (falls back to forms.invalid_field, "This field is not valid.")`
  - `components/PhoneInput.jsx:16 and pages/OnboardingSignup.jsx:163 (pattern with no errorKeys)`
  - `state/useError.jsx:33-38 (keeps only the error code)`
  - `lib/suma/service.rb:196-201 and lib/suma/service/helpers.rb:117-122 (per-field messages sent as untranslated English under more.errors)`
  - `data/i18n/seeds/en/strings.json:122 (errors.validation_error says fields were left blank)`
- **What:** A badly formatted phone or ZIP shows "This field is not valid." with no format hint. A backend validation error shows "Some fields were left blank" even when nothing was blank, and the field is not identified.
- **Fix:** Add `errorKeys` with format hints for phone and ZIP; return structured per-field codes from the backend and map them to field errors; reword the generic string to "Please check the highlighted fields".

### W-35 Paragraph spacing, line height and forced colours

- **Severity:** medium
- **Criteria:** 1.4.8 AAA
- **Where:**
  - `Bootstrap $paragraph-margin-bottom 1rem not overridden in _theme.scss; many mb-0 paragraphs`
  - `lh-1 on text in FoodCartWidget.jsx:155-156, FoodDetails.jsx:100, FoodCheckout.jsx:474; SumaImage.module.css:19 line-height 100%`
  - `!important colours in alerts.scss:23, onboarding.scss:22, custom.scss:33-69, funding.scss:8-16`
- **Fix:** Set `$paragraph-margin-bottom: 1.5rem`, remove `lh-1` from text, and drop `!important` from colour rules so user style sheets can override them.

### W-36 Fixed-width and fixed-size constructs at 320px

- **Severity:** medium
- **Criteria:** 1.4.10 AA, 1.4.12 AA
- **Where:**
  - `pages/OneTimePassword.jsx:161-184 with otp.scss:3-12 (six 44px boxes plus margins = 312px in a 288px column)`
  - `assets/styles/react-credit-card.scss:2 (290px card preview)`
  - `pages/FoodDetails.jsx:93-120 with FoodCartWidget.jsx:118-137 (text-nowrap in a half-width column)`
  - `components/PressAndHold.jsx:32-58 (fixed 140px circle containing text); mobility.scss:77-92 (36px badge)`
- **Live evidence:** No horizontal scroll and no clipping on the seven signed-in pages and three text-spacing pages tested; the code and card screens could not be reached at 320px in this session.
- **Fix:** Allow the code row to wrap or size boxes with `min(44px, 12vw)`; cap the card preview at 100%; drop `text-nowrap`; use min-height rather than fixed height on the hold button.

### W-37 Amount keypad has no label, no live output and no limits shown up front

- **Severity:** medium
- **Criteria:** 3.3.2 A, 4.1.2 A, 4.1.3 AA, 3.3.5 AAA
- **Where:**
  - `components/CurrencyNumpad.jsx:16-21 (amount in plain divs)`
  - `pages/FundingAddFunds.jsx:56-81 (min and max only after submit)`
- **Fix:** Render the amount as `` and show the allowed range as help text before the user types.

### W-38 Static notices carry role=alert

- **Severity:** medium
- **Criteria:** 4.1.3 AA, 1.3.6 AAA
- **Where:**
  - `pages/Dashboard.jsx:92,107,122`
  - `components/NegativeBalanceAddInstrumentNotice.jsx:17`
  - `components/OrderDetail.jsx:59,215 (contains the claim button)`
  - `pages/FoodCheckout.jsx:416`
- **What:** react-bootstrap Alert always emits `role='alert'`. On-load content marked this way can interrupt screen readers and misdescribes its purpose.
- **Fix:** Use a plain `div.alert` with `role='region'` and a label for static notices; keep `role='alert'` for dynamic errors.

### W-39 Link text that does not describe the destination

- **Severity:** medium
- **Criteria:** 2.4.9 AAA
- **Where:**
  - `pages/Home.jsx:39 (Learn More)`
  - `pages/FoodCheckout.jsx:329-335 (Address, opens Google Maps)`
  - `components/mobilitymap/PreTrip.jsx:46 (Get Started)`
  - `pages/FundingAddCard.jsx:83, FundingLinkBankAccount.jsx:57 (Continue)`
  - `Privacy policy and terms markdown: raw URLs as link text, measured at up to 350px wide`
- **Fix:** "Learn more about suma", "Open pickup address in Google Maps", and human-readable text for URLs in the legal markdown.

### W-40 Agreement checkbox name differs from its visible text

- **Severity:** low
- **Criteria:** 2.5.3 A, 4.1.2 A
- **Where:**
  - `components/SignupAgreement.jsx:22-38 (aria-label "Agree to terms"; visible text in a sibling div toggled by onClick)`
- **Fix:** Use `aria-labelledby='signup-agreement'` or make the text a real label; reference the error from the checkbox.

### W-41 No re-authentication path preserves form input

- **Severity:** low
- **Criteria:** 2.2.5 AAA
- **Where:**
  - `api.js (no 401 interceptor); shared/apilogger.js:60-62; hocs/authRedirects.jsx:35-37`
- **What:** With a 30-day session this is rare, but an expired session mid-form yields a generic toast and the typed data is lost.
- **Fix:** On 401 save a draft to sessionStorage, set the redirect link and navigate to sign in; restore after the code is verified.

### W-42 Invalid input type and deprecated markup

- **Severity:** low
- **Criteria:** 4.1.2 A
- **Where:**
  - `pages/OneTimePassword.jsx:165 (type="numbers")`
  - `components/FoodPrice.jsx:34 and mobilitymap/MicromobilityRate.jsx:11 (strike element)`
- **Fix:** Use `type='text'` with `inputMode='numeric'`; use `del` or `s`.

### W-43 Page title and logo alt details

- **Severity:** low
- **Criteria:** 2.4.2 A, 1.1.1 A
- **Where:**
  - `pages/PartnerSignup.jsx:104 (hard-coded English title Join …)`
  - `OrderHistoryDetail and TripDetail use generic titles`
  - `components/TopNav.jsx:41-47 (long descriptive alt on the logo link that also says suma)`
- **Fix:** Localise the partner title; include the order or trip identifier; use empty alt on the linked logo since the link text already names it.

### W-44 Same functions identified differently

- **Severity:** low
- **Criteria:** 3.2.4 AA
- **Where:**
  - `Back is text on most pages and a bare chevron on FoodList.jsx:85 and TripDetail.jsx:39`
  - `Language switch is a link (TranslationToggle) on public pages and a button group (TopNav.jsx:104-115) elsewhere`
- **Fix:** Keep a visually hidden "Back" in the short variant; use one language-switch control.

### W-45 Press-and-hold completes on a down-initiated timer

- **Severity:** low
- **Criteria:** 2.5.2 A
- **Where:**
  - `shared/react/useLongPress.jsx:22`
- **What:** The action fires when the timer elapses while the pointer is still down. The two-second hold mitigates accidental activation but completion is not on the up event.
- **Fix:** Complete on pointer-up after the hold time has elapsed, keeping the ring as feedback.

### W-46 Placeholders, input borders and checked controls below the non-text threshold

- **Severity:** high
- **Criteria:** 1.4.3 AA, 1.4.11 AA
- **Where:**
  - `assets/styles/_theme.scss:51 ($input-placeholder-color #adb5bd, 2.07:1 in every field) and custom.scss:32-34 (.select-noselection)`
  - `assets/styles/_theme.scss:48-49 ($input-border-color lighten($primary, 20%) = #e8d5bc, 1.43:1; focus border #e6d3b8 is lighter than the resting border)`
  - `assets/styles/otp.scss:9 (code field border #ccc, 1.61:1)`
  - `$component-active-bg = $primary (checked checkbox and radio fill 2.26:1, white glyph on it 2.26:1, active dropdown item white on gold 2.26:1)`
  - `components/PressAndHold.css:13 (progress ring in gold, 2.26:1); pages/PrivateAccountDetail.jsx:342 (info progress bar 1.86:1 against its track); pages/Funding.jsx:191 (warning icon 1.63:1); assets/styles/funding.scss:6-13 (numpad key fill 1.26:1, bottom border 1.92:1); TopNav.jsx:181-199 (menu icons 2.02:1 on light grey)`
- **What:** Because placeholders stand in for labels (W-8), the 2.07:1 placeholder is the only visible field name. Field boundaries and checked states are close to invisible for low-vision users.
- **Fix:** `$input-placeholder-color: #505963` (7.12:1); `$input-border-color: #be8b46` (3.01:1) or `#725328`; code field border `#949494` (3.03:1); `$component-active-bg: #725328` (fixes checks, radios, dropdown active and the progress ring); info bar `#6f87ba` (3.03:1 against its track); warning icon `#bc8d00`; numpad border `2px solid #949494`.

### W-47 Muted text just under 7:1 and content dimmed with opacity

- **Severity:** low
- **Criteria:** 1.4.6 AAA, 1.4.3 AA
- **Where:**
  - `assets/styles/_theme.scss:35 ($text-muted override is a no-op in Bootstrap 5.3; .text-muted and .form-text resolve to rgba(33,37,41,.75), 6.78:1) used in Trip.jsx:47, FoodDetails.jsx:116, OneTimePassword.jsx:189, Funding.jsx:134,140,207, TripDetail.jsx:87-92, components/FormText.jsx:9`
  - `pages/Dashboard.jsx:138,156-160 (body text on the gold program card, 6.82:1)`
  - `assets/styles/mobility.scss:61 (map popup text #6c757d, 4.69:1)`
  - `pages/FoodCheckout.jsx:227 (saved payment rows at opacity .5, effectively 3.12:1)`
- **Fix:** `$body-secondary-color: rgba($body-color, .8)` (8.04:1) or `$gray-700`; add `text-dark` to the gold card; use `$gray-700` for popups; de-emphasise rows with a 7:1 grey or italics instead of opacity.

## Admin app findings (A-)

### A-1 Twenty-two icon-only buttons and links have no accessible name

- **Severity:** critical
- **Criteria:** 1.1.1 A, 4.1.2 A, 2.4.4 A
- **Where:**
  - `components/ResourceDetail.jsx:175-177 (edit link) and :182-184 (delete button) on every detail page`
  - `components/BackTo.jsx:20-22 (in every detail page title) and ForwardTo.jsx:9-11`
  - `components/InlineEditField.jsx:60-77 (edit, busy, save, cancel)`
  - `components/DialogWindowButtons.jsx:23-40 (fullscreen, close)`
  - `components/Programs.jsx:83-85, 122-128`
  - `components/ResourceTable.jsx:167-169 (CSV download on every list page)`
  - `components/Copyable.jsx:30-32 (title only)`
  - `pages/EligibilityRequirementDetailPage.jsx:25-35; MarketingListEditPage.jsx:174-180; BookTransactionCreatePage.jsx:99-101; MemberDetailPage.jsx:306-312, 694-696; OrganizationMembershipVerificationListPage.jsx:290-292, 424-427; OrganizationMembershipVerificationDetailPage.jsx:149-159`
- **What:** MUI SvgIcon renders `aria-hidden='true'`, so a button or link holding only an icon has an empty name. No IconButton in the codebase has an `aria-label` except the menu toggle.
- **Live evidence:** axe link-name on 14 pages (24 nodes) and button-name on 4 pages.
- **Fix:** Add `aria-label` to each ("Edit member", "Delete", "Back to members", "Download CSV") or pass `titleAccess` to the icon. Give BackTo and ForwardTo a required label prop.

### A-2 Gold links and secondary text fail contrast

- **Severity:** critical
- **Criteria:** 1.4.3 AA, 1.4.6 AAA
- **Where:**
  - `theme.js:5 (primary #CDA671 used by every MUI Link)`
  - `theme.js:7 (success #498567 behind white chip text, 4.34:1)`
  - `MUI default text.secondary #666666 on white, 5.74:1, on 53 pages (labels, list subheaders)`
- **Live evidence:** axe color-contrast on 31 pages (163 nodes, links at 2.26:1); color-contrast-enhanced on 57 of 58 pages (501 nodes).
- **Fix:** In theme.js: `primary: { main: '#725328', light: '#CDA671', contrastText: '#fff' }` (links and text buttons 7.04:1, contained buttons white 7.04:1). If the tan AppBar and Fab must stay tan, keep `main` and override `MuiLink`, `MuiButton textPrimary` and `outlinedPrimary`, and the focused `MuiFormLabel` colour to `#725328` instead. Also `secondary: '#575956'`, `success: '#35614b'`, `error: '#9e3500'`, `warning: '#834b01'`, `text.secondary: 'rgba(0,0,0,0.66)'` (7.26:1). Every value was verified by script; see the appendix.

### A-3 Select comboboxes are not labelled by their visible label

- **Severity:** high
- **Criteria:** 1.3.1 A, 4.1.2 A
- **Where:**
  - `components/StateMachineStateSelect.jsx:19-27; VendorServiceCategorySelect.jsx:34-42; VendorServiceCategoryMultiSelect.jsx:55-73`
  - `components/AddressInputs.jsx:95-103`
  - `pages/OfferingForm.jsx:215-220; MarketingSmsBroadcastEditPage.jsx:98-107, 122-129; OrganizationMembershipVerificationListPage.jsx:125-133; OfferingPickListPage.jsx:125-132, 135-142; VendorServiceForm.jsx:103-110`
- **What:** MUI builds `aria-labelledby` from `labelId`. Without it, the combobox is named only by its current value. `InputLabel htmlFor` points at the hidden native input, not the combobox.
- **Live evidence:** axe aria-input-field-name on 6 pages, 9 nodes.
- **Fix:** `const labelId = React.useId(); …`, or use `TextField select`.

### A-4 Controls with no label, empty labels, or unassociated group labels

- **Severity:** high
- **Criteria:** 1.3.1 A, 4.1.2 A, 3.3.2 A, 2.4.6 AA
- **Where:**
  - `pages/OrganizationMembershipVerificationListPage.jsx:507-516 and OrganizationMembershipVerificationDetailPage.jsx:80-89 (EBT account number, no label)`
  - `pages/OrganizationMembershipForm.jsx:224 (disabled field, no label)`
  - `pages/MarketingListEditPage.jsx:160-185 (search with placeholder only)`
  - `pages/MemberDetailPage.jsx:86-94 (unnamed Switch)`
  - `pages/MarketingSmsBroadcastEditPage.jsx:211-222 (checkbox list; ListItemButton exposes no checked state)`
  - `pages/OffPlatformTransactionCreatePage.jsx:42-49 (RadioGroup without a label)`
  - `MultiLingualText with label="" yields "English " and "Spanish ": FundingTransactionCreatePage.jsx:76; VendorConfigurationForm.jsx:50,63,76,90`
  - `Radio groups not named by FormLabel: IcalEventEditor/Ending.jsx:28-39, Frequency.jsx:16-27, Recurrence.jsx:17-23; EligibilityAssignmentForm.jsx:82-93; FundingTransactionRefundPage.jsx:57-63; RoleEditor.jsx:46-72`
  - `OfferingForm.jsx:73,78 and ProgramForm.jsx:88,93 (required shown as " *" in the label text, no required prop); OfferingForm.jsx:205 ("Option 0")`
  - `About 40 FormLabel elements used as section headings (MemberForm.jsx:67,75; OfferingForm.jsx:55-153; ImageFileInput.jsx:31; OneToManyEditor.jsx:30)`
- **Fix:** Give every field a real label or `aria-label`; wrap groups in FormControl with `FormLabel id` and `RadioGroup aria-labelledby`; pass `required` to date pickers; replace heading-style FormLabel with `Typography component='h2'` or fieldset and legend.

### A-5 All errors appear only in a five-second toast

- **Severity:** high
- **Criteria:** 2.2.1 A, 2.2.3 AAA, 3.3.1 A, 3.3.3 AA
- **Where:**
  - `App.jsx:154 (SnackbarProvider with default autoHideDuration 5000)`
  - `hooks/useErrorSnackbar.jsx:11 (every API and validation error)`
  - `components/ResourceForm.jsx:31 (.catch(enqueueErrorSnackbar))`
  - `No field-level error prop is set anywhere in pages or components`
- **What:** Validation errors are never shown next to the field, and the toast that shows them cannot be extended or turned off.
- **Fix:** Set `autoHideDuration={null}` with a Dismiss action for error variants; parse the API error payload and set `error` and `helperText` on the matching field; add an `aria-live` summary at the top of the form.

### A-6 Financial and irreversible submissions have no review or confirmation

- **Severity:** high
- **Criteria:** 3.3.4 AA, 3.3.6 AAA
- **Where:**
  - `pages/BookTransactionCreatePage.jsx:65-78 (moves ledger money)`
  - `pages/FundingTransactionCreatePage.jsx:25-37 (charges a member's instrument)`
  - `pages/FundingTransactionRefundPage.jsx:37-45`
  - `pages/MarketingSmsDispatchDetailPage.jsx:18-26 (cancel dispatch)`
  - `pages/OrganizationMembershipVerificationListPage.jsx:243-251 (approve and reject from a menu)`
- **What:** Deletes are confirmed and the SMS broadcast has a review page, but money movements submit straight to the API.
- **Fix:** Add a confirmation dialog summarising amount, ledgers or instrument and member before the call, reusing the delete dialog pattern, or a two-step review page like the broadcast flow.

### A-7 Weak or absent focus indicators

- **Severity:** high
- **Criteria:** 2.4.7 AA, 2.4.13 AAA, 2.4.3 A
- **Where:**
  - `theme.js (no focus styling); MUI text and outlined buttons, IconButton, Chip, ListItemButton and TableSortLabel rely on the ripple or a 12% tint`
  - `pages/EligibilityRequirementExpressionEditor.jsx:256-260 (outline none; 2px ring at 20% alpha gold)`
  - `components/ImageFileInput.jsx:34-44 (1px, opacity 0 file input is a tab stop with no visible focus)`
- **What:** MUI ButtonBase sets `outline: 0`. Buttons, icon buttons, checkboxes, radios, switches, the Fab and chips show only the pulsating focus ripple (1.25 to 1.46:1). List and menu items get a 12% black tint (1.32:1). Focused inputs turn their border gold (2.26:1). The data grid's cell focus is a 1px gold outline, below both the 2px area and the 3:1 rules of 2.4.13.
- **Live evidence:** Programmatic focus on the 35 nav links produced no computed style change; MUI's keyboard focus adds a faint background tint that needs a manual check.
- **Fix:** Theme override: `MuiButtonBase: { styleOverrides: { root: { '&.Mui-focusVisible': { outline: '2px solid #725328', outlineOffset: 2 } } } }`, which covers Button, IconButton, Fab, Chip, ListItemButton, MenuItem, ToggleButton and the switch bases; the same for `MuiLink`; `MuiOutlinedInput` focused border `#725328`; a 2px outline on `.MuiDataGrid-cell:focus`; replace the editor's outline none; add `tabIndex={-1}` to the hidden file input.

### A-8 Fixed header, sticky panel and overlays hide focused elements

- **Severity:** high
- **Criteria:** 2.4.11 AA, 2.4.12 AAA
- **Where:**
  - `components/TopNav.jsx:44-45 (AppBar position fixed, 64px) with no scroll-padding; RelatedList.jsx:43 hard-codes 80px to compensate`
  - `pages/OrganizationMembershipVerificationListPage.jsx:471-490 (sticky 25vh notes panel over the table)`
  - `components/RelatedList.css:7-14 and pages/MarketingListEditPage.jsx:225-235 (60 to 70px gradient overlays)`
  - `components/FabAdd.jsx:21-27 (56px floating button bottom right)`
- **Fix:** `html { scroll-padding-top: 72px; scroll-padding-bottom: 30vh }` while the notes panel is open; remove or move the gradient overlays.

### A-9 Expression editor is a custom widget with no role, name or state

- **Severity:** high
- **Criteria:** 4.1.2 A, 1.3.1 A
- **Where:**
  - `pages/EligibilityRequirementExpressionEditor.jsx:238-262 (focusable Paper with key handlers, no role or label)`
  - `pages/EligibilityRequirementExpressionEditor.jsx:266-273, 298-304, 325-332 (click-only cursor slots, about 4px wide)`
  - `pages/EligibilityRequirementExpressionEditor.jsx:530-545 (caret shown by colour only)`
- **Fix:** Give the canvas `role='textbox'` or `application` with `aria-label` and `aria-describedby` to the instructions and output; announce cursor moves in a visually hidden polite live region; make cursor slots buttons with names or rely on keyboard caret movement.

### A-10 Loading, counts and saves are not announced

- **Severity:** medium
- **Criteria:** 4.1.3 AA
- **Where:**
  - `18 CircularProgress instances with no name or live region (ResourceDetail.jsx:98,179; ResourceTable.jsx:140-144; RoleEditor.jsx:51; AdminActions.jsx:70-72; FileUploadInput.jsx:52; InlineEditField.jsx:69-71; StaticStringsPage.jsx:17; and others)`
  - `LoadingButton (FormButtons.jsx:19, SupportNoteModal.jsx:55) only toggles disabled`
  - `components/EventSourceChanges.jsx:26-31, 56-60 ("N changes" written with innerText)`
  - `components/AdminActions.jsx:77-81; MarketingListEditPage.jsx:165; MarketingSmsBroadcastEditPage.jsx:178-184 (results and counts update silently)`
  - `InlineEditField.jsx:40-48, Programs.jsx:97-107, RelatedListRemote.jsx:39-65 (silent success)`
- **Fix:** A shared Loading component with `role='status'` and visually hidden text; `aria-busy` on regions being replaced; `role='status'` around counters; a success snackbar on inline saves.

### A-11 State conveyed by colour or opacity alone

- **Severity:** medium
- **Criteria:** 1.4.1 A
- **Where:**
  - `components/RoleEditor.jsx:56-64 (assigned roles by chip colour)`
  - `components/Programs.jsx:133-148`
  - `pages/OrganizationMembershipVerificationListPage.jsx:424-427 and OrganizationMembershipVerificationDetailPage.jsx:183-188 with modules/membershipVerificationDuplicateRiskColor.js (risk level by icon colour)`
  - `pages/StaticStringsNamespacePage.jsx:202-211, 321-328 (deprecated at 30% opacity; needs-text by row tint)`
  - `pages/OfferingDetailPage.jsx:108, 140-144 (closed at 50% opacity)`
  - `pages/PaymentTriggerDetailPage.jsx:66-70 (expired in disabled colour)`
  - `components/OrganizationMembership.jsx:17-35 (verified and removed share one icon, differing by colour)`
  - `components/AuditActivityList.jsx:48`
- **Fix:** Add visible text or a chip label (Assigned, High risk, Deprecated, Closed, Removed), or `titleAccess` plus visually hidden text.

### A-12 No h1, skipped levels, and controls inside headings

- **Severity:** medium
- **Criteria:** 1.3.1 A, 2.4.6 AA, 2.4.10 AAA
- **Where:**
  - `components/ResourceTable.jsx:80 (list title h5); components/DetailGrid.jsx:42 (detail title h6) wrapping ResourceDetail.jsx:114-121 (BackTo link and edit and delete buttons inside the heading); components/FormLayout.jsx:17 (h4); pages/DashboardPage.jsx:11 (h6)`
  - `components/Programs.jsx:80-87, 119-129; LedgerBookTransactionRelatedList.jsx:12-16; OrganizationMembershipVerificationDetailPage.jsx:146-161; StaticStringsNamespacePage.jsx:96-102 (buttons in headings)`
- **Live evidence:** 0 of 58 pages have an h1; heading-order failures on 2 pages.
- **Fix:** Render page titles as `Typography variant='h5' component='h1'`, sections as h2, and move controls into a sibling toolbar.

### A-13 Key-value and data tables lack header semantics; scroll container not focusable

- **Severity:** medium
- **Criteria:** 1.3.1 A, 2.1.1 A
- **Where:**
  - `components/DetailGrid.jsx:46-65 (property labels are td cells; no caption)`
  - `components/SimpleTable.jsx:66-99 (no caption or aria-labelledby; :75 empty spacer th)`
  - `pages/EligibilityRequirementExpressionEditor.jsx:457-466 (data row built in thead)`
  - `MUI TableContainer with horizontal overflow and no focusable content`
- **Live evidence:** axe empty-table-header on 3 pages; scrollable-region-focusable on 2 pages.
- **Fix:** `TableCell component='th' scope='row'` for labels, or a description list; `aria-labelledby` from the card title; `tabIndex={0}` and a label on scrollable containers.

### A-14 Missing, stale and non-unique page titles

- **Severity:** medium
- **Criteria:** 2.4.2 A
- **Where:**
  - `pages/FundingTransactionRefundPage.jsx, MarketingSmsBroadcastSendPage.jsx, OfferingPickListPage.jsx (no HelmetTitle; the previous page's title persists)`
  - `components/ResourceForm.jsx:90-92 (every create page is titled Create)`
- **Live evidence:** Pick list titled "Admin | Suma"; four create pages titled "Create | Suma Admin"; detail titles such as "Suma Admin | Member 1 | Suma Admin".
- **Fix:** Render HelmetTitle from FormLayout with the form title; add titles to the three pages.

### A-15 No location cues in navigation

- **Severity:** medium
- **Criteria:** 2.4.8 AAA, 1.3.6 AAA
- **Where:**
  - `components/TopNav.jsx:133-141 (plain Link, no selected or aria-current)`
  - `No breadcrumb component; BackTo is an unlabelled chevron`
  - `components/ResourceTable.jsx:92-99 (search not in a search landmark)`
- **Fix:** Use NavLink or `selected` plus `aria-current='page'`; add MUI Breadcrumbs on detail and edit pages; wrap search in `role='search'`.

### A-16 Id-only links, unseparated link lists and object tooltips

- **Severity:** medium
- **Criteria:** 2.4.9 AAA, 4.1.2 A
- **Where:**
  - `components/AdminLink.jsx:15 (91 links whose text is a number)`
  - `components/AdminLink.jsx:38-45 (Array joins links with no separator; used at EligibilityRequirementExpressionEditor.jsx:516-518)`
  - `pages/OfferingPickListPage.jsx:178, 212, 240 (title={value} passes an object, rendered as [object Object])`
- **Live evidence:** Links measuring 8×16px with text "1" on 22 pages; a select showing "[object Object]" on the product edit page.
- **Fix:** Add visually hidden resource names to id links; default the separator to ", "; pass `title={value.name}` or remove it.

### A-17 Focus lost when controls unmount; floating button first in DOM

- **Severity:** medium
- **Criteria:** 2.4.3 A, 1.3.2 A
- **Where:**
  - `components/InlineEditField.jsx:56-78; Programs.jsx:83,122,126; OneToManyEditor.jsx:62; ResourceDetail.jsx:146 (rerenderKey remount); ResourceForm.jsx:31 (navigate after submit)`
  - `components/ResourceList.jsx:58-61 (FabAdd rendered before the table but positioned bottom right; StaticStringsNamespacePage.jsx:118 renders it last)`
  - `pages/EligibilityRequirementExpressionEditor.jsx:43-46 (palette buttons steal focus to the canvas)`
- **Fix:** Move focus to the input on edit start and back to the trigger on save or cancel; focus `main` or the h1 on route change; render FabAdd last; only refocus the canvas when the insert came from it.

### A-18 Menu cannot be dismissed by keyboard; Backspace deletes twice; dead close button

- **Severity:** medium
- **Criteria:** 2.1.1 A, 2.4.11 AA
- **Where:**
  - `pages/OrganizationMembershipVerificationListPage.jsx:294-328 (Popper menu with no Escape or Tab handling; stays open over the table)`
  - `pages/EligibilityRequirementExpressionEditor.jsx:308-316 vs :132-134 (chip onDelete on keyup plus canvas Backspace on keydown)`
  - `pages/StaticStringsNamespacePage.jsx:355 (DialogWindowButtons given onClick instead of onExit, so no close button renders)`
- **Fix:** Close the menu on Escape and Tab and return focus to the trigger; ignore canvas key events whose target is a chip; pass `onExit`.

### A-19 No reduced-motion support

- **Severity:** medium
- **Criteria:** 2.3.3 AAA
- **Where:**
  - `No prefers-reduced-motion in adminapp; MUI ripples, Fade, Grow and Slide; components/RelatedList.jsx:44-47 (smooth scrollTo); EligibilityRequirementExpressionEditor.jsx:254, 539, 561 (transitions)`
- **Fix:** Disable ripples and set transitions to none in the theme when `matchMedia('(prefers-reduced-motion: reduce)')` matches; guard the smooth scroll.

### A-20 Targets under 44px, and cursor slots under 24px

- **Severity:** medium
- **Criteria:** 2.5.5 AAA, 2.5.8 AA
- **Where:**
  - `Default IconButtons 40×40 (all of A-1); size="small" IconButtons 32px (MemberDetailPage.jsx:306-308; EligibilityRequirementDetailPage.jsx:25-28)`
  - `components/TopNav.jsx:134-138 (nav items about 36px)`
  - `31 size="small" buttons about 31 to 37px; small chips 24px; Copyable.jsx:26 minWidth 40px`
  - `Table-cell links about 16px tall on every list page; TableSortLabel 24px; pagination select 48×29`
  - `pages/EligibilityRequirementExpressionEditor.jsx:548-554 (cursor slots about 4px wide; no pointer route to the slot before the first token)`
- **Live evidence:** Measured on 58 page loads at 1280px.
- **Fix:** Theme `MuiIconButton` padding 10px, nav `minHeight: 44`, padded inline-block cell links, wider cursor slots.

### A-21 Spanish fields and values are not marked lang=es

- **Severity:** medium
- **Criteria:** 3.1.2 AA
- **Where:**
  - `components/MultiLingualText.jsx:44-52`
  - `pages/StaticStringsNamespacePage.jsx:166, 300-308`
  - `pages/MarketingSmsBroadcastEditPage.jsx:166-183`
  - `pages/OfferingDetailPage.jsx:30-53; OrderDetailPage.jsx:58-61; MarketingSmsBroadcastDetailPage.jsx:34; OrganizationDetailPage.jsx:36-39; components/detailPageImageProperties.jsx:21`
- **Fix:** `inputProps={{ lang: 'es' }}` on Spanish inputs; wrap Spanish values in `span lang='es'`; let DetailGrid properties take a lang.

### A-22 Sign-in form lacks autocomplete and uses an invalid role

- **Severity:** medium
- **Criteria:** 1.3.5 AA, 4.1.2 A, 3.3.8 AA
- **Where:**
  - `pages/SignInPage.jsx:39-56 (email and password without autoComplete)`
  - `pages/SignInPage.jsx:58 (role="submit" on the button, duplicating the form onSubmit)`
- **Live evidence:** axe aria-roles (critical) on /admin/sign-in.
- **Fix:** `autoComplete='username'` and `'current-password'`; `type='submit'` with no role.

### A-23 Unnamed dialog, duplicate ids, stateless toggle chips, nested interactive upload buttons

- **Severity:** medium
- **Criteria:** 4.1.2 A, 1.3.1 A
- **Where:**
  - `pages/OrganizationMembershipVerificationListPage.jsx:470-491 (role=dialog with no name; :313 MenuList id repeated per row)`
  - `components/AdminActions.jsx:83-96 (Dialog without DialogTitle)`
  - `components/StateMachineStateSelect.jsx:19-21; VendorServiceCategorySelect.jsx:34-36; VendorServiceCategoryMultiSelect.jsx:55-57 (hard-coded ids that can collide)`
  - `components/RoleEditor.jsx:56-64; Programs.jsx:133-148 (clickable chips without aria-pressed)`
  - `components/FileUploadInput.jsx:41-44; ImageFileInput.jsx:32-45 (Button component=label with role=button containing a focusable input)`
- **Live evidence:** axe nested-interactive and aria-allowed-role on 6 pages.
- **Fix:** `aria-labelledby` to the panel heading and `role='region'`; add DialogTitle; `React.useId()`; `aria-pressed`; hide the native input and open the picker from the button.

### A-24 Non-wrapping rows and forced truncation

- **Severity:** medium
- **Criteria:** 1.4.10 AA, 1.4.12 AA
- **Where:**
  - `components/ResourceTable.jsx:78-102 and pages/OfferingPickListPage.jsx:123-144 (title, filters and search in a non-wrapping row)`
  - `pages/OrganizationMembershipVerificationListPage.jsx:476-568 (25vh panel with two flex columns)`
  - `pages/OfferingPickListPage.jsx:276-281 (overflow hidden and ellipsis forced on every cell)`
- **Live evidence:** No horizontal page scroll at 320px on four admin pages; tables scroll inside their container, which the reflow exception allows.
- **Fix:** Wrap header rows; stack the notes panel below md; drop the ellipsis override or provide a real title.

### A-25 No re-authentication path preserves form input

- **Severity:** medium
- **Criteria:** 2.2.5 AAA
- **Where:**
  - `shared/apilogger.js:60-62 (401 simply rejected); hooks/user.jsx:17-27 (auth checked only on mount)`
- **Fix:** On 401 open a sign-in dialog inside the page and retry the request after success.

### A-26 New windows opened without warning

- **Severity:** low
- **Criteria:** 3.2.5 AAA
- **Where:**
  - `shared/react/SafeExternalLink.jsx:16; components/TopNav.jsx:151-152 (View Docs); pages/OrganizationMembershipVerificationListPage.jsx:337, 352, 379 (window.open)`
- **Fix:** Visually hidden "(opens in a new tab)" plus an icon inside SafeExternalLink.

### A-27 Clear button fires on mouse-down

- **Severity:** low
- **Criteria:** 2.5.2 A
- **Where:**
  - `pages/MarketingListEditPage.jsx:174-177`
- **Fix:** Remove `onMouseDown` or use it only to prevent default.

### A-28 Emoji booleans, hidden informative icons, empty preview alt, icon-referencing instruction

- **Severity:** low
- **Criteria:** 1.1.1 A, 1.3.3 A
- **Where:**
  - `components/BoolCheckmark.js:3-5 and DetailGrid.jsx:88 (check and cross emoji)`
  - `components/OrganizationMembership.jsx:7-35 (informative icons aria-hidden)`
  - `components/ImageFileInput.jsx:52 (alt is the empty caption)`
  - `pages/OrganizationMembershipVerificationDetailPage.jsx:163-167 ("Press the [icon] button above" where the button has no name)`
- **Fix:** Render Yes and No text; `titleAccess` on informative icons; a default preview alt; name the button and refer to it by name.

### A-29 Jargon, unexpanded abbreviations and long technical helper text

- **Severity:** low
- **Criteria:** 3.1.3 AAA, 3.1.4 AAA, 3.1.5 AAA
- **Where:**
  - `EBT (OrganizationMembershipVerificationListPage.jsx:500), Qty (OfferingPickListPage.jsx:160,192,232), IP (MemberDetailPage.jsx:422), CSV, SMS, RRULE and DTSTART (IcalEventEditor/RecurrenceAdvanced.jsx:28-40, Output.jsx:29-35), GBFS (VendorServiceForm.jsx:126-132)`
  - `Long helper paragraphs: OffPlatformTransactionCreatePage.jsx:31-37; PaymentTriggerForm.jsx:176-185`
  - `Glossary exists at docs/admin-glossary.md but is linked to GitHub only`
- **Fix:** `abbr` with titles on first use; short plain summaries above long helper text; an in-app glossary page.

### A-30 Same function, different icons

- **Severity:** low
- **Criteria:** 3.2.4 AA
- **Where:**
  - `components/RelatedList.jsx:86-89 and RelatedListRemote.jsx:97-100 use ListAltIcon for create actions; OfferingDetailPage.jsx:67-70 uses it for a view link; FabAdd and OneToManyEditor use AddIcon`
  - `pages/StaticStringsNamespacePage.jsx:175 uses FormatColorTextIcon for Edit; everywhere else EditIcon`
- **Fix:** AddIcon for every create action, EditIcon for every edit.

### A-31 No skip link; mobile drawer has no nav landmark

- **Severity:** low
- **Criteria:** 2.4.1 A
- **Where:**
  - `state/withLayout.jsx:15-19 (main exists); components/TopNav.jsx (35 links before main on desktop; SlidingNavDrawer contents in a presentation box)`
- **Fix:** A "Skip to main content" link before the AppBar; wrap drawer contents in `nav`.

### A-32 No colour or spacing controls; wide table rows

- **Severity:** low
- **Criteria:** 1.4.8 AAA
- **Where:**
  - `theme.js (single palette, no theme switch)`
  - `components/ResourceTable.jsx, RelatedList.jsx (rows commonly exceed 80 characters)`
- **Fix:** Offer a high-contrast or dark theme toggle and honour user style sheets; keep prose columns under 80 characters.

### A-33 Stylesheet loaded for print only

- **Severity:** info
- **Criteria:** Not a WCAG failure
- **Where:**
  - `index.html:21 (custom.css with media="print"), so .text-nowrap in shared/react/Money.jsx:25 never applies on screen`
- **Fix:** Load with `media='all'` if the rules are meant for screen.

### A-34 Component boundaries, checked states and status colours below 3:1

- **Severity:** high
- **Criteria:** 1.4.11 AA, 1.4.3 AA
- **Where:**
  - `MUI OutlinedInput border rgba(0,0,0,.23), 1.74:1, on 23 text fields plus selects and autocompletes`
  - `Outlined button borders at 50% alpha: 1.47:1 primary, 1.78:1 secondary, 1.92:1 success, 2.29:1 error, 1.61:1 warning`
  - `Checked Checkbox, Radio and Switch thumb in gold 2.26:1; switch track 1.47:1 checked and 2.68:1 unchecked, thumb 1.04:1`
  - `CircularProgress in gold 2.26:1 (7 uses); ToggleButton border 1.32:1 (IcalEventEditor/FrequencyWeekly.jsx:17, OrganizationMembershipForm.jsx:169)`
  - `theme.js:9 warning #ed8702 as text 2.60:1 (MemberDetailPage.jsx:667, EligibilityRequirementExpressionEditor.jsx:206) and as icons (OneToManyEditor.jsx:63, AddressInputs.jsx:41, OfferingForm.jsx:207); theme.js:18 muted chip #b6b6b6 2.03:1 (Programs.jsx:68)`
  - `MUI text.disabled rgba(0,0,0,.38), 2.68:1, used for readable content in PaymentTriggerDetailPage.jsx:68 and EligibilityRequirementExpressionEditor.jsx:276,433; DialogWindowButtons.jsx:25,35 grey icons 2.68:1; OrganizationMembership.jsx:30 status icon at 1.88:1`
  - `OneToManyEditor.jsx:62, AddressInputs.jsx:40, OfferingForm.jsx:206 use variant="warning", which is not an MUI Button variant and renders unstyled`
- **Fix:** Theme overrides: `MuiOutlinedInput notchedOutline borderColor '#959595'` (3.00:1); outlined buttons `borderColor: 'currentColor'`; toggle borders `rgba(0,0,0,.54)`; primary `#725328` fixes checked controls, progress and icons; switch track black at .54 opacity; `warning: '#834b01'` (7.07:1); `muted: '#595959'`; use `text.secondary` for readable de-emphasised content; grey icons `#616161`; `color='warning'` instead of `variant`.

### A-35 Snackbar colours fail contrast

- **Severity:** medium
- **Criteria:** 1.4.3 AA, 1.4.6 AAA
- **Where:**
  - `App.jsx:154 (notistack 2.0.8 defaults): white on success #43a047 3.30:1 (Copyable.jsx:24, FileUploadInput.jsx:30), warning #ff9800 2.16:1, info #2196f3 3.12:1, error #d32f2f 4.98:1 (hooks/useErrorSnackbar.jsx)`
- **Fix:** Pass styles to SnackbarProvider: success `#1b5e20` (7.87:1), error `#9e3500` (7.09:1), info `#0d47a1` (8.63:1), warning `#834b01` or black text on `#ff9800` (9.74:1).

## Platform and content findings (S-)

### S-1 Legal documents far above lower-secondary reading level, no plain-language summary

- **Severity:** high
- **Criteria:** 3.1.5 AAA
- **Where:**
  - `data/i18n/seeds/en/terms_of_use_and_sale.json:2 (8,745 words, 28 words per sentence, grade 15.2)`
  - `data/i18n/seeds/en/privacy_policy.json (grade 10.0; worst paragraphs at 24.2, 23.2, 22.1, 20.5)`
- **Fix:** Add a short "In plain words" summary at the top of each document (5 to 8 bullets at grade 8 or below) and split sentences over 25 words.

### S-2 Member-facing jargon and unexpanded abbreviations

- **Severity:** medium
- **Criteria:** 3.1.3 AAA, 3.1.4 AAA
- **Where:**
  - `strings.json: ledger (titles.ledgers_overview, payments.ledgers_intro), offering (food.available_offerings), subsidy (food.subsidy_applied), funding (titles.funding), onboarding, unclaimed (food.unclaimed_order_history_title), uncategorized (ledgerusage.unknown), enroll, program`
  - `Abbreviations never expanded: SMS and MMS (auth.sign_up_agreement:14), ID (common.reference_id:45), CVC (errors.card_invalid_cvc; forms.invalid_card_cvc:222 calls it security code), FAQ (common.faq), min (trips.minutes), Zip (forms.zip), CDC (privacy_policy.json:49), PGE and NW (surveys.json:29,31), USD, SNAP, U.S. (terms)`
  - `strings.json:101 errors.invalid_otp says token while every other string says code`
- **Fix:** Rename in the UI (Transactions, Deals, Discount from suma, Add money), expand on first use ("text messages (SMS)", "security code (CVC)", "Portland General Electric (PGE)"), and add a short member glossary linked from the menu.

### S-3 Backend validation errors collapse to one misleading code

- **Severity:** medium
- **Criteria:** 3.3.1 A, 3.3.3 AA
- **Where:**
  - `lib/suma/service.rb:196-201 (ValidationErrors rescued into invalid!)`
  - `lib/suma/service/helpers.rb:117-122 (code validation_error with English messages under more.errors, no field key)`
  - `lib/suma/service/validators.rb:14`
  - `data/i18n/seeds/en/strings.json:122 (errors.validation_error: fields were left blank)`
  - `strings.json errors.disambiguation_required, errors.eligibility_violation, errors.rate_not_found all map to "Sorry, something went wrong"`
- **Fix:** Return per-field codes such as `{fields: [{param: 'phone', code: 'impossible_phone_number'}]}` that the frontend can localise and attach to the field; give eligibility and rate errors specific, actionable strings.

### S-4 Untranslated English inside the Spanish seeds

- **Severity:** medium
- **Criteria:** 3.1.2 AA
- **Where:**
  - `data/i18n/seeds/es/surveys.json:13 ("Join Waiting List")`
  - `data/i18n/seeds/es/backend.json:11 ("Rebalancing uncategorized subsidy")`
  - `data/i18n/seeds/es/backend.json:18 (web_meta.description empty; lib/suma/apps.rb:196-198 injects only the English text)`
- **Fix:** "Unirse a la lista de espera"; "Reequilibrio de subsidio sin categoría"; add a spec that fails when Spanish equals English for strings longer than about 12 characters.

### S-5 Stale-cache recovery message is silent, English-only and reloads without request

- **Severity:** medium
- **Criteria:** 4.1.3 AA, 3.2.5 AAA, 3.1.2 AA
- **Where:**
  - `webapp/index.html:60-71 and adminapp/index.html:42-53`
- **What:** A div appended to body with no role, English text even for Spanish users, and an immediate `window.location` change while the text says the page will refresh.
- **Fix:** `role='alert'` and `lang='en'` on the div, a visible Reload button, and a short delay before the automatic reload.

### S-6 No accessibility statement or feedback route

- **Severity:** medium
- **Criteria:** Policy, not a criterion
- **Where:**
  - `docs/, privacy_policy.json, terms_of_use_and_sale.json and strings.json contain no accessibility statement, conformance target or contact for accessibility issues`
- **Fix:** Add an Accessibility page in both languages (target level, known issues, contact, date) linked from the footer menu and the privacy policy.

### S-7 Short-URL redirect page is malformed HTML

- **Severity:** low
- **Criteria:** 3.1.1 A, 2.4.2 A
- **Where:**
  - `lib/url_shortener/rack_app.rb:16-17 (no doctype, lang, title or content-type; raw URL as link text; seen only if the 302 is not followed)`
- **Fix:** Emit a minimal document with `lang`, a title, readable link text and a text/html content type.

### S-8 Email layouts are not ready for accessibility if the transport is enabled

- **Severity:** low
- **Criteria:** 3.1.1 A, 2.4.2 A, 1.3.1 A, 3.2.5 AAA
- **Where:**
  - `lib/suma/message/transport/email.rb:10,22 (layouts unsupported; send raises NotImplementedError)`
  - `data/messages/layouts/standard.email.liquid:2-5 and blank.email.liquid:2-5 (no lang, title or viewport)`
  - `data/messages/partials/environment_banner.liquid:2-5 (layout table without role=presentation; h5 inside a link; target=_blank)`
- **What:** Contrast in the banner passes (16.5:1 text, 7.4:1 default link). A plain-text part is already generated alongside HTML.
- **Fix:** Set `lang` from the recipient's language, add a title and preheader, mark layout tables presentational, replace the h5 with a paragraph.

### S-9 One-time code lifetime is not communicated

- **Severity:** low
- **Criteria:** 2.2.6 AAA
- **Where:**
  - `lib/suma/member/reset_code.rb:49 (15 minutes); no otp.* string mentions it`
- **Fix:** Add "This code expires in 15 minutes" to the code screen and, if Suma composes its own SMS, to the message.

### S-10 SMS wording and one-time code readability

- **Severity:** low
- **Criteria:** 3.1.4 AAA, 1.3.1 A
- **Where:**
  - `data/i18n/seeds/en/messages.json sms_compliance/optin.sms ("Msg&Data rates"), optout.sms ("SMS"), offerings/2023_07_pilot_confirmation.sms ("claim your vouchers")`
  - `lib/suma/twilio.rb:27-33 (six contiguous digits passed to Twilio Verify; grouping and voice pacing are configured in Twilio)`
- **Fix:** "Message and data rates may apply", "text messages", "pick up your order"; verify the Verify templates read digits individually and repeat them; keep the WebOTP format for autofill.

### S-11 Small content and manifest defects

- **Severity:** low
- **Criteria:** Quality
- **Where:**
  - `webapp/public/manifest.json:49 (384px icon declared as 284x284)`
  - `webapp/index.html (no noscript fallback; adminapp has one)`
  - `data/i18n/seeds/en/backend.json:17 (meta description at grade 19.4, not localised)`
  - `strings.json:290 ("recieve"), :222 ("back fo the card")`
- **Fix:** Correct the icon size, add a localised noscript message, shorten the description, fix the typos.

### S-12 Rate limiting is off by default; verification throttle is tight

- **Severity:** info
- **Criteria:** Security context
- **Where:**
  - `lib/suma/rack_attack.rb:12 (enabled false); lib/suma/api/auth.rb:96-101 (4 code attempts per 2 minutes per IP)`
- **Fix:** Confirm the flag is on in production; consider 6 attempts per 2 minutes so users who mistype are not locked out.


# Level A remediation status (branch `a11y-level-a`, 2026-09-25, uncommitted)

Verified by re-running the same axe-core crawl (47 member-app and 58 admin-app page loads) and scripted probes against the rebuilt apps.

| Check | Before | After |
|---|---|---|
| Member app axe hits tagged A or AA (nodes) | 231 | 203 (all remaining are colour-contrast, viewport and one autocomplete token) |
| Member app pages with an `h1` | 9 of 44 | 44 of 44 |
| Member app pages with a `main` landmark | 0 of 44 | 43 of 44 (styleguide is dev-only) |
| Member app unnamed links (axe link-name) | 27 | 0 |
| Member app unhidden decorative icons | 76 | 0 |
| Member app heading-order violations | 12 | 0 |
| Admin app axe hits tagged A or AA (nodes) | 211 | 167 (all remaining are colour-contrast) |
| Admin app pages with an `h1` | 0 of 58 | 58 of 58 |
| Admin unnamed links and buttons | 30 | 0 |
| Admin selects without a name (aria-input-field-name) | 9 | 0 |
| Admin nested interactive, invalid role, empty header, unfocusable scroll region | 10 | 0 |
| `html[lang]` after switching to Spanish (live) | `en` | `es` (and back to `en`) |
| Focus after route change (live) | body | `main#main` |
| Phone field on Start (live) | placeholder only | visible label, `aria-required`, `aria-invalid` and `aria-describedby` to the error text on submit |

## Fixed

- W-1 press-and-hold is keyboard operable (Space/Enter hold, Escape via blur); W-15 ledger picker items are focusable buttons; W-16 map region label, marker names, keyboard-openable restriction zones, drawer no longer auto-closes.
- W-2, W-3, A-1 every icon-only control and empty link has an accessible name; empty admin links with a null model now render text or nothing.
- W-5 document language follows the UI language.
- W-8, W-9, W-27 visible labels with required markers, `aria-required`/`aria-invalid`/`aria-describedby`, fieldset and legend on every radio and checkbox group, organisation dropdown labelled; A-3, A-4 all MUI selects wired with `labelId`, unlabelled fields, switches, checkbox lists and radio groups labelled.
- W-10, A-31 skip link and `main` in both apps, labelled navs, `aria-current` on the current page (W-17, A-15) with a non-colour cue.
- W-12, W-13, W-14, A-5 toasts no longer auto-dismiss (errors persist with a Dismiss action in admin), carousel does not auto-advance, blinking alerts stop after four cycles.
- W-18, A-27 no action fires on pointer-down.
- W-20, W-21, W-22 loaders and offline state announced, decorative icons hidden, step state in text, card preview hidden, vehicle images decorative.
- W-23, W-24, A-12, A-13 one `h1` per page, sequential levels (including the terms markdown), header-less ledger table given caption and header, admin key-value tables use row headers, related-list tables labelled and focusable.
- W-25 disabled state uses the real `disabled` prop. W-28 language names marked with `lang`, library labels localised. W-30 auto-advance note on the code screen. W-31, A-17 focus managed on route change and inline edits. W-34 phone and ZIP have specific messages. W-40 agreement checkbox labelled by its text. W-42 invalid input type removed. W-43 partner title localised.
- A-9 expression editor has a role, name, description and live cursor announcements; A-18 status menu closes on Escape and Tab, double Backspace fixed; A-22 sign-in uses `type="submit"` and autocomplete; A-23 dialogs titled, duplicate ids replaced with `useId`, toggle chips expose `aria-pressed`, file inputs no longer nest inside buttons; A-28 emoji booleans and status icons have text alternatives; A-11 risk, deprecated, closed and expired states have text; A-14 missing and generic page titles fixed.

## Still open at Level A

- S-3 / W-34: backend validation errors are still collapsed to one generic code; per-field localised errors need an API change.
- W-16: vehicle polling continues (treated as essential real-time data); the drawer now shows a message instead of closing.
- A-9: the expression editor uses `role="textbox"` while still containing chip buttons; consider `role="application"` after screen-reader testing.
- MUI Autocomplete renders its multiline text areas with `role="combobox"` (axe aria-allowed-role, best practice, library behaviour).
- Onboarding carousel indicators stay hidden by `onboarding.scss`; prev and next buttons are present and auto-advance is off.
- Not runtime-tested with assistive technology: press-and-hold with a screen reader or switch, the map with VoiceOver or TalkBack, and checkout and add-funds forms with a linked payment method.
- AA and AAA items (colour palette, focus ring contrast, sticky header scroll padding, target size, reduced motion, confirmations, content reading level) are unchanged.
