# Plan: Theme Index Redesign

## Overview

Redesign the themes index page (`our/themes/index`) and supporting views to be cleaner, more intuitive, and consistent with the card-based design patterns used throughout the rest of the site. Replace the current clunky sectioned layout with a streamlined card-and-list approach, introduce colour swatches for visual identity, and add a compact action dropdown to reduce button sprawl.

---

## Current problems

1. **Index page is cluttered** — each theme is a full stacked card with up to 5–6 visible buttons, metadata, and tags all fighting for attention.
2. **Sections feel disconnected** — "Active theme", "Our themes", and "Shared themes" use `<details>` summaries that look different from the card-header pattern used everywhere else.
3. **No visual identity** — there's no way to tell what a theme looks like without clicking through to preview it.
4. **Action overload** — every theme card shows all possible actions inline (Preview, Edit, Duplicate, Delete, Activate/Deactivate, Make default). This is especially overwhelming when you have several themes.
5. **Edit page sidebar is long** — the left column has ~30 colour pickers plus background options, tags, and sharing settings all in one scrolling panel.
6. **New/Import buttons float** — they sit above the theme list with no visual container, looking disconnected.

---

## Design: Index page

### Page heading card

A single `.card` at the top with a `.card__header` containing the page title, consistent with the profiles and groups index pages. Below the heading, include:

- **Active theme note** — a single line: "Active theme: **forest**" with a small "Deactivate" button (or "No active theme — using site default" if none). This replaces the entire "Active theme" collapsible section.
- **Action buttons** — "New theme" and "Import theme" buttons, right-aligned or below the active theme note.

```
┌──────────────────────────────────────────────────────────┐
│  ░░░░░░░░░░░░░░░ card__header ░░░░░░░░░░░░░░░░░░░░░░░░░  │
│  Themes                                                  │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  Active theme: forest  [Deactivate]                      │
│                                                          │
│  [New theme]  [Import theme]                             │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

### Tag filter card

A separate `.card` below the heading (only shown if any themes exist), matching the label filter pattern from the groups index:

```
┌──────────────────────────────────────────────────────────┐
│  Filter by tags:                                         │
│  [Bright] [Light] [Dark] [Super contrast] ...            │
│                                               Clear ×    │
└──────────────────────────────────────────────────────────┘
```

- Use the existing `.filter-bar` / `.btn--small` pattern from profiles/groups index.
- Only render this card if there are themes to filter.

### Theme sections: "Our themes" and "Shared themes"

Each section is a collapsible `<details>` with a card heading, consistent with the sidebar tree's expand/collapse pattern. Inside, themes are presented as **compact list rows** — not full cards. Each row is a single `.card` with a horizontal layout.

#### Theme list row

Each theme row contains (left to right):

1. **Colour swatch strip** — 5 small circular or rounded-square swatches showing the theme's key colours (see "Colour swatches" section below).
2. **Theme info block** (grows to fill space):
   - **Name** — linked to the preview/show page. Bold.
   - **Credit line** — "Made by **name**" (if present), small/muted text on the same line or line below.
   - **Notes** — if present, shown as a small italic line below the name/credit.
   - **Tags** — small tag pills below the notes (if any).
   - **Status badges** — "Default theme" badge if applicable, inline with tags.
3. **Action dropdown** — a single `⋮` (vertical ellipsis) or `•••` button that opens a disclosure menu (see "Action dropdown" section below).

```
┌──────────────────────────────────────────────────────────┐
│  ⬤⬤⬤⬤⬤   forest                                [⋮]  │
│            Made by gentle beasts                         │
│            [Dark] [Low contrast] [Cool colours]          │
└──────────────────────────────────────────────────────────┘
┌──────────────────────────────────────────────────────────┐
│  ⬤⬤⬤⬤⬤   dawnlight                             [⋮]  │
│            Made by gentle beasts                         │
│            A warm theme inspired by sunrise.             │
│            [Light] [Low contrast] [Warm colours]         │
└──────────────────────────────────────────────────────────┘
```

**Key principle:** The row height varies naturally based on content (name-only rows are compact; rows with notes+credit+tags are taller). This gives a clean list feel while accommodating multi-line content.

#### Active theme indicator

When a theme in the list is the currently active theme, add a subtle visual indicator:
- A left border accent (e.g. `border-left: 3px solid var(--link)`) on that row's card.
- A small "Active" badge/tag next to the theme name.

This replaces the need for a separate "Active theme" section entirely.

#### Empty states

- **Our themes (no themes, no filter):** "You haven't created any themes yet. Create one to customise your colours."
- **Our themes (filter active, no matches):** "No themes match the selected tags."
- **Shared themes (filter active, no matches):** "No shared themes match the selected tags."

---

## Design: Colour swatch strip

Show 5 representative colours for each theme as small circles in a horizontal row. The 5 colours chosen to give the best "feel" for a theme:

| Swatch | Property            | Why                                  |
| ------ | ------------------- | ------------------------------------ |
| 1      | `page_bg`           | Dominant background — sets the mood  |
| 2      | `pane_bg`           | Card/pane fill — second most visible |
| 3      | `heading`           | Heading colour — primary accent      |
| 4      | `link`              | Link colour — interactive accent     |
| 5      | `primary_button_bg` | Button colour — action accent        |

### CSS

```css
.theme-swatches {
  display: flex;
  gap: 0.25rem;
  flex-shrink: 0;
}

.theme-swatches__dot {
  width: 20px;
  height: 20px;
  border-radius: 50%;
  border: 1px solid var(--pane-border);
}
```

In forced-colors mode, hide the swatches (they'd all render as system colours and be meaningless):

```css
@media (forced-colors: active) {
  .theme-swatches {
    display: none;
  }
}
```

### Implementation

Add a helper method to the Theme model:

```ruby
SWATCH_PROPERTIES = %w[page_bg pane_bg heading link primary_button_bg].freeze

def swatch_colors
  SWATCH_PROPERTIES.map { |prop| color_for(prop) }
end
```

In the partial, render each swatch as a `<span>` with an inline `background-color` style.

---

## Design: Action dropdown

A `<details>`/`<summary>` disclosure widget styled as a dropdown menu. This is the key new UI pattern.

### Requirements

- Must **not shift page content** when opened (uses `position: absolute`).
- Opens downward from the trigger button; if near the bottom of the viewport, could open upward (but this is a nice-to-have — absolute positioning with downward opening is fine for v1).
- Closes when clicking outside (native `<details>` behaviour handles this in most browsers; add a lightweight Stimulus controller for reliable outside-click dismissal).
- Trigger is a small icon button (vertical ellipsis `⋮` or horizontal ellipsis `⋯`).

### HTML structure

```haml
.action-dropdown{data: { controller: "dropdown" }}
  %details{data: { "dropdown-target": "details" }}
    %summary.action-dropdown__trigger{aria: { label: "Theme actions" }}
      ⋮
    .action-dropdown__menu
      = link_to "Preview", ..., class: "action-dropdown__item"
      = link_to "Activate", ..., class: "action-dropdown__item"
      = link_to "Edit", ..., class: "action-dropdown__item"
      = link_to "Duplicate", ..., class: "action-dropdown__item"
      %hr.action-dropdown__divider
      = link_to "Delete", ..., class: "action-dropdown__item action-dropdown__item--danger"
```

### Menu items per context

**Our themes (owned by user):**
- Activate / Deactivate (depending on current state)
- Edit
- Duplicate
- Export (copies JSON to clipboard — stretch goal)
- ──────
- Delete

**Shared themes (not owned):**
- Activate / Deactivate
- Preview
- Duplicate

**Shared themes (admin):**
- Activate / Deactivate
- Preview
- Edit
- Duplicate
- Make default / Remove default
- ──────
- Delete

### CSS

```css
.action-dropdown {
  position: relative;
}

.action-dropdown__trigger {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  border-radius: 4px;
  cursor: pointer;
  color: var(--text);
  font-size: 1.25rem;
  line-height: 1;
  list-style: none;      /* remove default disclosure triangle */
  user-select: none;
}

.action-dropdown__trigger:hover {
  background-color: color-mix(in srgb, var(--text) 10%, transparent);
}

.action-dropdown__trigger::-webkit-details-marker,
.action-dropdown__trigger::marker {
  display: none;
}

.action-dropdown__menu {
  position: absolute;
  right: 0;
  top: 100%;
  z-index: 10;
  min-width: 160px;
  background-color: var(--pane-bg);
  border: 1px solid var(--pane-border);
  border-radius: 8px;
  padding: 0.35rem 0;
  box-shadow: 0 4px 12px color-mix(in srgb, black 25%, transparent);
}

.action-dropdown__item {
  display: block;
  padding: 0.5rem 1rem;
  color: var(--text);
  text-decoration: none;
  font-size: 0.9rem;
  white-space: nowrap;
}

.action-dropdown__item:hover {
  background-color: color-mix(in srgb, var(--text) 8%, transparent);
  text-decoration: none;
}

.action-dropdown__item--danger {
  color: var(--danger-button-bg);
}

.action-dropdown__divider {
  border: none;
  border-top: 1px solid var(--pane-border);
  margin: 0.35rem 0;
}

@media (forced-colors: active) {
  .action-dropdown__trigger:hover {
    outline: 1px solid ButtonText;
  }

  .action-dropdown__menu {
    border: 2px solid ButtonText;
  }

  .action-dropdown__item:hover {
    outline: 1px solid Highlight;
  }
}
```

### Stimulus controller (dropdown_controller.js)

A lightweight controller that:
- Closes the `<details>` when clicking outside.
- Closes the `<details>` when an item inside the menu is clicked (for Turbo method links that don't navigate).
- Optionally closes on `Escape` key.

```js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["details"]

  connect() {
    this.closeOnOutsideClick = this.closeOnOutsideClick.bind(this)
    this.closeOnEscape = this.closeOnEscape.bind(this)
  }

  detailsTargetConnected() {
    document.addEventListener("click", this.closeOnOutsideClick)
    document.addEventListener("keydown", this.closeOnEscape)
  }

  detailsTargetDisconnected() {
    document.removeEventListener("click", this.closeOnOutsideClick)
    document.removeEventListener("keydown", this.closeOnEscape)
  }

  closeOnOutsideClick(event) {
    if (this.detailsTarget.open && !this.element.contains(event.target)) {
      this.detailsTarget.open = false
    }
  }

  closeOnEscape(event) {
    if (event.key === "Escape" && this.detailsTarget.open) {
      this.detailsTarget.open = false
    }
  }
}
```

---

## Design: Theme list row partial (`_theme_row.html.haml`)

Replaces the current `_theme_card.html.haml`. Here's the target structure:

```haml
.card.theme-row{ class: ("theme-row--active" if Current.user.active_theme_id == theme.id) }
  .theme-row__swatches
    - theme.swatch_colors.each do |color|
      %span.theme-swatches__dot{style: "background-color: #{color}"}

  .theme-row__info
    .theme-row__name-line
      %h3= link_to theme.name, our_theme_path(theme)
      - if Current.user.active_theme_id == theme.id
        %span.tag Active
    - if theme.credit.present? || theme.credit_url.present?
      %p.theme-row__credit
        Made by
        - if theme.credit.present? && theme.credit_url.present?
          %strong= link_to theme.credit, theme.credit_url, target: "_blank", rel: "noopener noreferrer"
        - elsif theme.credit.present?
          %strong= theme.credit
    - if theme.notes.present?
      %p.theme-row__notes= theme.notes
    - if theme.tags.any? || (theme.shared? && theme.site_default?)
      .theme-row__tags
        - if theme.shared? && theme.site_default?
          %span.tag.tag--default Default theme
        - theme.tags.each do |tag|
          %span.tag.tag--theme= Theme::TAGS[tag] || tag

  .action-dropdown{data: { controller: "dropdown" }}
    -# dropdown content (see action dropdown section)
```

### CSS for theme rows

```css
.theme-row {
  display: flex;
  align-items: flex-start;
  gap: 1rem;
  padding: 1rem 1.25rem;
}

.theme-row--active {
  border-left: 3px solid var(--link);
  padding-left: calc(1.25rem - 3px);  /* compensate for border width */
}

.theme-row__swatches {
  display: flex;
  gap: 0.25rem;
  flex-shrink: 0;
  padding-top: 0.15rem;  /* align with text baseline */
}

.theme-row__info {
  flex: 1;
  min-width: 0;  /* allow text truncation if needed */
}

.theme-row__name-line {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.theme-row__name-line h3 {
  margin: 0;
}

.theme-row__credit {
  font-size: 0.85rem;
  margin: 0.15rem 0 0;
  color: var(--text);
}

.theme-row__notes {
  font-size: 0.85rem;
  font-style: italic;
  margin: 0.2rem 0 0;
  color: var(--text);
}

.theme-row__tags {
  display: flex;
  flex-wrap: wrap;
  gap: 0.3rem;
  margin-top: 0.4rem;
}
```

---

## Design: Show/preview page (minor improvements)

The show page is already decent. Minor improvements:

1. **Add the swatch strip** to the left info card, giving a quick visual reference without needing to look at the full preview.
2. **Tighten the button layout** — use the action dropdown for secondary actions (Duplicate, admin actions) and keep only Activate/Deactivate and Edit as primary visible buttons.
3. **Keep the live preview panel** as-is — it works well.

---

## Design: Edit page (sidebar improvements)

The edit page sidebar has ~30 colour pickers in a single scrolling column. Improvements:

1. **Collapse property groups by default** — wrap each `PROPERTY_GROUPS` section (Base colours, Form controls, Buttons, Flash messages) in a `<details>` element. Open "Base colours" by default since that's the most commonly edited. This dramatically reduces initial visual length.
2. **Keep the existing colour picker UX** — the side-by-side colour swatch + hex input works well, no need to change it.
3. **Move Background image, Tags, and Share theme into a single collapsible "Advanced" section** — or keep them as separate `<details>` but collapse them by default (which they already are).

No structural changes needed — just collapsing property groups.

---

## Implementation plan

### Phase 1: New components (no visual changes yet)

1. Add `Theme#swatch_colors` method to the model.
2. Create the `dropdown` Stimulus controller.
3. Add CSS for `.action-dropdown`, `.theme-swatches`, `.theme-row`.

### Phase 2: Index page redesign

4. Create new `_theme_row.html.haml` partial (replaces `_theme_card.html.haml`).
5. Rewrite `index.html.haml`:
   - Page heading card with title, active theme note, and New/Import buttons.
   - Tag filter card (using `.filter-bar` pattern).
   - "Our themes" collapsible section with theme rows.
   - "Shared themes" collapsible section with theme rows.
6. Update CSS: remove old `.theme-section__summary` styles, add new section heading styles.

### Phase 3: Show page cleanup

7. Add swatch strip to show page info card.
8. Replace inline action buttons with dropdown for secondary actions.

### Phase 4: Edit page cleanup

9. Wrap each property group in `<details>` elements (Base colours open by default).
10. Update CSS for collapsed/expanded property groups.

### Phase 5: Cleanup

11. Remove old `_theme_card.html.haml` partial.
12. Remove unused CSS (`.card--stacked`, `.card__main` if unused elsewhere, old `.theme-section` styles).
13. Update system tests for new DOM structure.
14. Run `bin/rubocop -a` and `bin/rails test` to verify.

---

## Responsive considerations

- **Mobile (< 600px):** Swatch strip can wrap or shrink. Theme row stacks vertically (swatches above info). Action dropdown stays right-aligned.
- **Tablet (600–900px):** Theme rows stay horizontal. No changes needed.
- **Desktop (> 900px):** Full layout as designed.

```css
@media (max-width: 600px) {
  .theme-row {
    flex-wrap: wrap;
  }

  .theme-row__info {
    flex-basis: 100%;
  }
}
```

---

## Accessibility

- Action dropdown trigger has `aria-label` describing its purpose.
- Dropdown menu items are standard `<a>` links — fully keyboard navigable.
- `Escape` key closes the dropdown.
- Colour swatches are decorative (`aria-hidden="true"`) — themes are identified by name, not colour.
- Forced-colors mode: swatches hidden, dropdown gets visible borders and focus indicators.
- Active theme indicator uses border + text badge (not colour alone).

---

## Files to create or modify

| File                                                | Action                                             |
| --------------------------------------------------- | -------------------------------------------------- |
| `app/models/theme.rb`                               | Add `SWATCH_PROPERTIES` and `swatch_colors` method |
| `app/javascript/controllers/dropdown_controller.js` | Create new Stimulus controller                     |
| `app/views/our/themes/index.html.haml`              | Rewrite                                            |
| `app/views/our/themes/_theme_row.html.haml`         | Create (replaces `_theme_card`)                    |
| `app/views/our/themes/_theme_card.html.haml`        | Delete after migration                             |
| `app/views/our/themes/show.html.haml`               | Minor updates                                      |
| `app/views/our/themes/edit.html.haml`               | Minor updates                                      |
| `app/views/our/themes/_form.html.haml`              | Wrap property groups in `<details>`                |
| `app/assets/stylesheets/application.css`            | Add new styles, remove old ones                    |
| `test/system/themes_test.rb`                        | Update for new DOM structure                       |
