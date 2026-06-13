# Plan: Rich Text in All Fields — Spoiler Hints, Hearts, HTML, and Spoilers Everywhere

## Summary

Four related features that share the same underlying infrastructure. Rather than descriptions being the only "rich" field, every user-facing text field (name, subtitle, pronouns, tag line, and description) gains full spoiler support, heart image replacement, and limited inline HTML. A new optional hover-hint syntax is also added to spoilers.

**Agreed implementation order:**

1. Spoiler hover popover (descriptions only, builds on existing infrastructure)
2. New `formatted_inline` / `plain_field` helpers + layout-level Stimulus controller scope
3. Apply rich formatting to all inline fields throughout all views
4. (Hearts and inline HTML are included as part of `formatted_inline` — no separate phase needed)

**Key decisions from discussion:**

- Hover hint uses a CSS-only `::after` pseudo-element tooltip — no JS.
- On desktop/hover devices, the hint shows on `:hover` or `:focus-visible` (CSS only); a single click reveals the spoiler.
- On touch devices, tapping cycles through three states: **hidden → hint showing → revealed → hidden**. The hint is shown only after the first tap, not permanently.
- Once a spoiler is revealed, the hint is never visible regardless of device.
- Page `<title>` tags and og: meta tags use plain text (`plain_field`) — markup stripped but spoiler *content* preserved.
- Tree labels and sidebar labels **must** use `formatted_inline` — spoilers must be respected everywhere without exception. A spoiler exists to prevent triggering; revealing it anywhere would defeat the purpose.
- Pronouns keep their CSS italic default; users can override individual words with `<b>` etc.
- Inline fields allow: `<b>`, `<strong>`, `<i>`, `<em>`, `<u>`, `<s>`, `<del>`, `<span>`, `<sup>`, `<sub>`.

---

## Feature 1: Spoiler Hover Popover

### Syntax

Both orderings are valid — the hint can go before or after the spoiler:

```
||spoiler text||[hover hint]
[hover hint]||spoiler text||
```

If somehow both positions carry text, the first one found wins.

### Regex

Replace the current `SPOILER_PATTERN` with a hint-aware version:

```ruby
SPOILER_WITH_HINT_PATTERN = /
  (?:\[(?<pre_hint>[^\]]+)\]\s*)?   # optional [hint] before
  \|\|(?<content>.+?)\|\|           # ||spoiler content||
  (?:\s*\[(?<post_hint>[^\]]+)\])?  # optional [hint] after
/mx
```

The hint text is `pre_hint || post_hint` (whichever is present).

### HTML output — no hint (unchanged behaviour)

```html
<span class="spoiler" role="button" tabindex="0"
      aria-expanded="false" aria-label="Hidden content, click to reveal">
  spoiler content
</span>
```

### HTML output — with hint

```html
<span class="spoiler spoiler--with-hint" role="button" tabindex="0"
      aria-expanded="false"
      aria-label="Hidden content: [hint text], click to reveal"
      data-spoiler-hint="[hint text]">
  spoiler content
</span>
```

The hint is HTML-escaped before insertion. The `aria-label` incorporates the hint so screen readers announce it before the user clicks.

### CSS

The tooltip uses `::after`. Desktop behaviour is CSS-only (show on `:hover`/`:focus-visible`). Touch behaviour requires a JS-added class `spoiler--hint-showing` (see Stimulus changes below).

```css
/* Base: position context */
.spoiler--with-hint {
  position: relative;
}

/* Tooltip bubble — shared layout */
.spoiler--with-hint[aria-expanded="false"]::after {
  content: attr(data-spoiler-hint);
  position: absolute;
  bottom: calc(100% + 5px);
  left: 50%;
  transform: translateX(-50%);
  background: var(--pane-bg);
  border: 1px solid var(--pane-border);
  color: var(--text);
  border-radius: 4px;
  padding: 2px 8px;
  font-size: 0.8em;
  white-space: nowrap;
  pointer-events: none;
  z-index: 10;
  /* hidden by default; shown via :hover (desktop) or .spoiler--hint-showing (touch) */
  visibility: hidden;
  opacity: 0;
  transition: opacity 0.15s ease;
}

/* Desktop: show on hover or focus */
.spoiler--with-hint[aria-expanded="false"]:hover::after,
.spoiler--with-hint[aria-expanded="false"]:focus-visible::after {
  visibility: visible;
  opacity: 1;
}

/* Touch state 2: hint explicitly shown by JS after first tap */
.spoiler--with-hint.spoiler--hint-showing::after {
  visibility: visible;
  opacity: 1;
}

/* Forced colours */
@media (forced-colors: active) {
  .spoiler--with-hint[aria-expanded="false"]::after {
    forced-color-adjust: none;
    background: Canvas;
    color: CanvasText;
    border-color: CanvasText;
  }
}
```

### Changes to `application_helper.rb`

- Replace `SPOILER_PATTERN` and `SPOILER_REPLACEMENT` constants with the new hint-aware pattern and a conversion method that branches on whether a hint was found.
- `convert_spoilers_outside_code` calls the new method.
- No change to `formatted_description` signature or call sites.

### Stimulus controller changes

The controller gains three-state logic for hint spoilers on touch devices. Device detection uses `window.matchMedia("(hover: none)").matches` — consistent with the CSS media query.

Touch cycle for `spoiler--with-hint`:
1. First tap (state: hidden, no hint showing) → add `spoiler--hint-showing`, do NOT reveal. Return early.
2. Second tap (state: hint showing) → remove `spoiler--hint-showing`, reveal as normal.
3. Third tap (state: revealed) → reset as normal (existing toggle logic).

Desktop click on `spoiler--with-hint` behaves identically to a plain spoiler — single click reveals, since the hint is already visible via hover.

The `aria-label` must be restored correctly on hide. When restoring, check `dataset.spoilerHint` to rebuild the hint-aware label string.

```javascript
toggle(event) {
  // ... existing details-close handling ...

  const span = event.target.closest(".spoiler");
  if (!span) return;

  const hasHint = span.classList.contains("spoiler--with-hint");
  const hintShowing = span.classList.contains("spoiler--hint-showing");
  const isTouchDevice = window.matchMedia("(hover: none)").matches;

  if (hasHint && isTouchDevice && !hintShowing && !span.classList.contains("spoiler--revealed")) {
    // First touch: show hint, don't reveal yet
    span.classList.add("spoiler--hint-showing");
    return;
  }

  // Second touch or desktop click: proceed with reveal/hide
  span.classList.remove("spoiler--hint-showing");
  const revealed = span.classList.toggle("spoiler--revealed");
  span.setAttribute("aria-expanded", String(revealed));

  if (revealed) {
    span.removeAttribute("aria-label");
  } else {
    const hint = span.dataset.spoilerHint;
    span.setAttribute("aria-label",
      hint ? `Hidden content: ${hint}, click to reveal` : "Hidden content, click to reveal"
    );
  }
}
```

### Tests to add

- Helper: hint before spoiler produces `spoiler--with-hint` and `data-spoiler-hint`
- Helper: hint after spoiler also works
- Helper: both orderings produce the same output
- Helper: hint text is HTML-escaped
- Helper: spoiler without hint is unchanged
- Helper: `aria-label` incorporates hint text
- System: tooltip appears on hover (desktop)
- System: tooltip absent after reveal
- System: first tap shows hint but does not reveal (touch device simulation)
- System: second tap reveals (touch device simulation)
- System: third tap hides and hint is gone (touch device simulation)

---

## Feature 2: Infrastructure — `formatted_inline` and `plain_field`

### The problem

Currently `formatted_description` uses `simple_format` which wraps everything in `<p>` tags and handles block-level HTML. That is wrong for single-line fields like name or pronouns.

A new `formatted_inline(text)` helper processes text for inline display:

- Applies spoiler conversion (including hints)
- Applies heart emoji replacement
- Sanitizes allowed inline HTML tags only
- Does NOT use `simple_format` or insert paragraphs
- Does NOT process block-level tags
- Returns an `html_safe` string

A new `plain_field(text)` helper returns sanitised plain text for contexts where HTML cannot render (page title, og: meta, ARIA labels, tree node labels if desired):

- Strips spoiler delimiters but keeps the content text (reveals the text)
- Strips heart emoji codes (`:cadbury_heart:` → removed, or kept as text — TBD)
- Strips any remaining HTML tags via `strip_tags`

### `formatted_inline` implementation sketch

```ruby
INLINE_EXTRA_TAGS = %w[b strong i em u s del span sup sub].to_set.freeze
INLINE_EXTRA_ATTRS = %w[class role tabindex aria-expanded aria-label
                        data-spoiler-hint src alt width height loading title].to_set.freeze

def formatted_inline(text)
  return "".html_safe if text.blank?
  safe_list_class = self.class.safe_list_sanitizer.class
  tags  = safe_list_class.allowed_tags  + INLINE_EXTRA_TAGS
  attrs = safe_list_class.allowed_attributes + INLINE_EXTRA_ATTRS
  html = convert_spoilers_outside_code(text)   # reuse existing method
  html = sanitize(html, tags: tags, attributes: attrs)
  html = replace_heart_emojis(html)             # reuse existing method
  html.html_safe
end
```

Note: `img` is not in the tag list because `replace_heart_emojis` inserts trusted `<img>` elements *after* sanitisation. The sanitise step would strip them if they were user-supplied.

### `plain_field` implementation sketch

```ruby
SPOILER_PLAIN_PATTERN = /(?:\[[^\]]+\]\s*)?\|\|(.+?)\|\|(?:\s*\[[^\]]+\])?/m

def plain_field(text)
  return "" if text.blank?
  text = text.gsub(SPOILER_PLAIN_PATTERN, '\1')    # keep spoiler content
  text = text.gsub(HEART_EMOJI_PATTERN, "")         # drop heart codes
  strip_tags(text)
end
```

### Stimulus controller scope

Currently the spoiler Stimulus controller (`data-controller="spoiler"`) is attached to `.profile-description` and `.group-description` containers. With spoilers in names and subtitles those are outside any description container.

**Change**: Move `data-controller="spoiler"` to the `<main>` element in the shared layout (or to the page body). The controller already uses `event.target.closest(".spoiler")` so it handles delegation correctly regardless of where it is mounted. No logic change needed in the controller.

The `data-action` listeners (`click->spoiler#toggle keydown->spoiler#keydown`) move to `<main>` and are removed from the individual description divs.

---

## Feature 3: Apply Rich Formatting to All Inline Fields

Once `formatted_inline` and `plain_field` exist, this is a mechanical sweep through every view that outputs profile/group text fields.

### Fields affected

| Record  | Field      | Current              | New                                    |
| ------- | ---------- | -------------------- | -------------------------------------- |
| Profile | `name`     | `= profile.name`     | `= formatted_inline(profile.name)`     |
| Profile | `subtitle` | `= profile.subtitle` | `= formatted_inline(profile.subtitle)` |
| Profile | `pronouns` | `= profile.pronouns` | `= formatted_inline(profile.pronouns)` |
| Profile | `tag_line` | `= profile.tag_line` | `= formatted_inline(profile.tag_line)` |
| Group   | `name`     | `= group.name`       | `= formatted_inline(group.name)`       |
| Group   | `subtitle` | `= group.subtitle`   | `= formatted_inline(group.subtitle)`   |
| Group   | `tag_line` | `= group.tag_line`   | `= formatted_inline(group.tag_line)`   |

### Fields that must stay plain

These contexts can't render HTML or the spoiler effect makes no sense:

| Context                             | Helper to use      |
| ----------------------------------- | ------------------ |
| `content_for(:title)` (browser tab) | `plain_field(...)` |
| `og:title` meta tag content         | `plain_field(...)` |
| `og:description` meta content       | `plain_field(...)` |
| `turbo_confirm:` strings            | `plain_field(...)` |
| `link_to ... title:` attributes     | `plain_field(...)` |
| `aria-label` attributes             | `plain_field(...)` |

Tree labels, sidebar profile names, and tree node subtitles all use `formatted_inline`. Spoilers must be hidden everywhere — revealing a name in the sidebar while hiding it on the card would be a safety failure.

### Views to touch

- `app/views/profiles/show.html.haml`
- `app/views/group_profiles/show.html.haml`
- `app/views/groups/_profile_content.html.haml`
- `app/views/groups/_profile_card.html.haml`
- `app/views/groups/show.html.haml` (tree labels)
- `app/views/groups/_tree_node.html.haml`
- `app/views/groups/_group_content.html.haml`
- `app/views/our/profiles/show.html.haml`
- `app/views/our/profiles/_profile_card.html.haml`
- `app/views/our/groups/show.html.haml`
- `app/views/our/groups/_group_card.html.haml`
- `app/views/our/_sidebar.html.haml`
- `app/views/our/groups/manage_groups.html.haml`
- `app/views/our/groups/_manage_groups_node.html.haml`
- `app/views/our/groups/_manage_groups_profile_node.html.haml`
- `app/views/our/groups/duplicate.html.haml` and preview nodes

### Pronouns and `link_to`

`%span= profile.pronouns` becomes `%span= formatted_inline(profile.pronouns)`. The CSS `font-style: italic` on `.pronouns span` continues to apply via the cascade — HTML inside the span inherits it and can be overridden locally with `<b>` or `<span style="...">`.

For names used as link text:

```haml
-# before
%h3= link_to profile.name, our_profile_path(profile)

-# after
%h3= link_to our_profile_path(profile) do
  = formatted_inline(profile.name)
```

HAML's block form of `link_to` accepts HTML content naturally.

---

## Feature 4: Inline HTML (part of `formatted_inline`)

This is automatically included once `formatted_inline` is in use. The allowed tag set (`<b>`, `<strong>`, `<i>`, `<em>`, `<u>`, `<s>`, `<del>`, `<span>`, `<sup>`, `<sub>`) covers all agreed use cases.

No additional changes beyond what is described in Feature 2.

---

## Edge Cases and Gotchas

### XSS surface
`formatted_inline` sanitises before returning `html_safe`. Hearts are inserted by our own code after sanitisation — they are not user-controllable. Spoiler spans are also produced by our regex, not passed through from user input. The only user-controlled HTML is in the inline tags list, which is intentionally limited.

### Spoiler inside a link text
If a name contains a spoiler and the name is used as `link_to` text, the `.spoiler` span will be a clickable role-button inside a clickable `<a>`. This creates nested interactive elements. Mitigation: intercept the click in the Stimulus controller and call `event.stopPropagation()` when toggling a spoiler, so the link navigation doesn't fire.

### Multiline content in inline fields
`formatted_inline` does not call `simple_format`, so `\n` in a name would appear as a space in the browser (normal inline text behaviour). This is fine — the fields are semantically single-line.

### Hearts in `plain_field`
The current decision strips heart codes in `plain_field`. An alternative is to replace them with their display name (e.g. `:cadbury_heart:` → "cadbury heart"). That might be friendlier in og:description. Decide during implementation.

### CSS tooltip overflow
The `::after` tooltip uses `position: absolute` and `white-space: nowrap`. If the spoiler is near the left or right edge of the viewport, the tooltip may clip. A future improvement could add `@media` or JS-based repositioning, but this is out of scope for now.

### `<title>` tag and `plain_field` for spoiler names
`plain_field` strips the `||` delimiters and keeps the inner text. So a profile named `||Lia||` will appear in the browser tab as "Lia — Plural Profiles". This is intentional — the tab title is not a spoiler-safe context.

---

## Testing Plan

### Unit (helper tests)

- `formatted_inline`: spoiler in name, hint in name, heart in pronoun, bold in subtitle
- `formatted_inline`: dangerous HTML is stripped
- `formatted_inline`: allowed HTML passes through
- `plain_field`: spoiler syntax stripped, content kept
- `plain_field`: hint brackets stripped
- `plain_field`: heart codes stripped
- `plain_field`: HTML tags stripped

### System tests

- Spoiler with hint: tooltip visible on hover, disappears after reveal
- Spoiler in profile name: hidden on page load, revealed on click (both public and our/)
- Spoiler in group name: same
- Heart in subtitle: image displayed
- Bold in pronoun: `<strong>` renders inside italic field
- Page `<title>`: spoiler content shown without delimiters

---

## Files to Create or Modify

| File                                               | Change                                                                                   |
| -------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| `app/helpers/application_helper.rb`                | New pattern, `formatted_inline`, `plain_field`, updated `convert_spoilers_outside_code`  |
| `app/assets/stylesheets/application.css`           | `.spoiler--with-hint` styles and tooltip                                                 |
| `app/javascript/controllers/spoiler_controller.js` | Three-state touch logic for hint spoilers; `stopPropagation` when toggling inside a link |
| `app/views/layouts/application.html.haml`          | Move `data-controller="spoiler"` to `<main>`                                             |
| All profile/group view files listed above          | Replace raw field output with `formatted_inline` / `plain_field`                         |
| `test/helpers/application_helper_test.rb`          | New helper tests                                                                         |
| `test/system/spoiler_test.rb`                      | New system tests for hints and inline spoilers                                           |
