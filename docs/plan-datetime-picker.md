# Plan: Accessible multi-field date/time picker for `created_at`

## Context

Profiles and groups have a "Created at" override field (used to backdate/postdate a record). It used to be a bare `datetime_local_field`, which the browser rendered as its native segmented widget — everything fused into one input, month shown as raw digits on most browsers, clicking a segment force-selecting the whole 2-digit chunk instead of allowing cursor placement, and segment order dictated by OS/browser locale. A user reported all of these as real accessibility/usability problems and pointed to Dreamwidth's date/time entry UI (genuinely separate fields) as a better reference.

This touches the "Created at" override on `our/profiles/_form.html.haml` and `our/groups/_form.html.haml`, plus the shared picker partial, parsing concern, CSS, and controller tests.

## Final approach

Five real, individually-labeled fields: Month/Day/Hour/Minute as `<select>` dropdowns, Year as an unbounded numeric input. This went through a few iterations before landing here — worth recording why, since the earlier approaches are exactly the traps to avoid if this gets touched again:

1. **First draft**: five plain fields combined into a hidden field via a Stimulus controller. Rejected — the visible fields had no `name`, so with JS disabled, edits never reached the server at all.
2. **Second draft**: `<input type="text" list="...">` + `<datalist>` combobox for every field (server-side parsing combines them, so no JS is required — this part was fine and is still true today). Rejected specifically for **Year**, because its datalist could only offer a bounded suggestion range, and a bounded year didn't make sense (`created_at` can be set arbitrarily far in the past or future). Year became a plain text field with no datalist.
3. **Arrow problem**: `<input list>` has no reliable persistent visual affordance across browsers — Chrome/Safari only show their built-in indicator on hover/focus, Firefox has no CSS hook to hide its own. Two attempts to layer a custom arrow on top both produced doubled/mismatched indicators (custom arrow + native browser arrow visible simultaneously, differently per engine). There is no cross-browser-safe way to fully control this combination.
4. **Final fix**: Month/Day/Hour/Minute all have small, fixed, bounded ranges (12/31/24/60) — exactly what `<select>` is for. Switching them to real `<select>` elements gets the *exact* same arrow as every other dropdown in the app (e.g. the "Display theme" select) for free, because it's literally the same element using the same shared CSS rule — no custom indicator code to maintain at all. Year, being unbounded, stays a plain text field (no datalist, no arrow).

Trade-off accepted: this loses the "type multiple characters, see a live-filtered list" combobox feel for Month/Day/Hour/Minute in exchange for zero cross-browser inconsistency. Native `<select>` still supports typeahead-by-first-letter/digit.

Why this still resolves the original complaints:
- **Separate real fields**, not one fused input.
- **Month renders as names** ("January"…), not digits.
- **Explicit per-field labels** make ordering unambiguous regardless of locale.
- **No JS dependency.** `<select>` and `<input type="text">` are plain form fields; multipart parsing happens server-side.

## Implementation

**1. Shared partial — `app/views/shared/_datetime_picker.html.haml`**

Locals: `form`, `field` (e.g. `:created_at`), `value` (a zone-aware `Time`). Month/Day/Hour/Minute use `options_for_select` against fixed ranges (`Date::MONTHNAMES.compact`, `1..31`, `0..23`, `0..59`); Year is `form`-independent plain text. All five submit as `#{form.object_name}[#{field}_parts][month|day|year|hour|minute]` — not the real `created_at` attribute name, since the server combines and validates them before assignment.

**2. Server-side parsing — `app/controllers/concerns/created_at_parts_parsing.rb`**

Shared concern, `include`d in `Our::ProfilesController` and `Our::GroupsController`. Accepts month as a name ("January") or a number, range-checks everything, returns `nil` (leaving `created_at` untouched) for blank/malformed/out-of-range input — same permissive behavior the old regex-based check had, now extended to catch out-of-range values (e.g. day 40) that the native `datetime-local` widget used to prevent by construction but a raw HTTP request could always have bypassed anyway.

**3. Controller call sites**

`profile_params`/`group_params` permit `created_at_parts: [:month, :day, :year, :hour, :minute]` instead of `:created_at`, parse it, and only set `p[:created_at]` when the result is valid and actually different from the current value (mirrors the old blank/malformed/unchanged skip logic).

**4. CSS** — `.datetime-picker` flexbox row in `app/assets/stylesheets/application.css`. Widths are set with a selector specific enough to beat the site's generic `select`/`input[type="text"] { width: 100%; }` rules regardless of source order (`.datetime-picker__field.datetime-picker__field--month select`, etc.) — an equal-specificity, later-in-file generic rule was the cause of an earlier "fields render full width" bug. No custom arrow/indicator CSS exists for this feature — the selects use the app's one shared `select` style.

## Verification

1. `bin/rails test test/controllers/our/profiles_controller_test.rb test/controllers/our/groups_controller_test.rb` (and the full suite) — covers past/future/malformed/out-of-range/month-as-number and the timezone-aware round trip, including asserting the rendered `<select>`/`<option selected>` markup.
2. `bin/rubocop`.
3. Manual: confirmed via a real HTTP round trip against the running dev server (login → GET edit page → PATCH with typed `created_at_parts` → verify persisted `created_at`) that both a typed month name and a year like 1999 (well outside any bounded range) save correctly. Confirmed the compiled CSS digest changes and lands on each iteration. Confirmed no leftover custom-arrow CSS remains after the final `<select>` pivot.
