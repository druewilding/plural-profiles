# Plan: Accessible multi-field date/time picker for `created_at`

## Context

Profiles and groups have a "Created at" override field (used to backdate/postdate a record). Today it's a bare `datetime_local_field`, which the browser renders as its native segmented widget — the exact UI shown in the reported screenshot (`June` dropdown, single fused box for day/year, `13 : 14` for time). A user reported real accessibility/usability problems with this native control:

- Everything lives in one fused input, so keyboard/screen-reader users can't address one part at a time.
- The month segment shows raw digits on most browsers (Chrome does; this app happened to be tested in Firefox, which shows names) — bad for dyscalculia and unclear generally.
- Clicking or tabbing into a segment force-selects the whole 2-digit chunk; you can't place a cursor mid-value and edit a single digit.
- Because it's one fused value, the segment order is dictated by OS/browser locale (`MM/DD/YYYY` vs `DD/MM/YYYY`), which is a guaranteed source of confusion for international users and something we can't control from the app.

The user pointed to Dreamwidth's date/time entry UI as a better reference: genuinely separate form fields (month name dropdown, plain day/year/hour/minute boxes) rather than one native fused control. This plan replaces the native widget with our own small multi-field picker built from ordinary, individually-labeled form elements, which resolves all four complaints by construction (separate real inputs, month spelled out, normal text-cursor editing, and explicit per-field labels that make ordering unambiguous regardless of locale).

This only touches the "Created at" override on `our/profiles/_form.html.haml` and `our/groups/_form.html.haml` — the two places `datetime_local_field` is used (confirmed via repo-wide search; nothing else in the codebase does date/time entry).

## Approach

Build a small Stimulus-backed widget: five plain, individually-labeled fields (Month `<select>` with month names, Day/Year/Hour/Minute `<input type="number">`) that a JS controller combines into the existing hidden `YYYY-MM-DDTHH:MM` string on every change — so the value that actually gets submitted, and the controller-side parsing/validation, don't change at all. Ship it as one shared partial so both forms use the same markup and behavior.

Why this shape:
- **Reuses existing backend logic untouched.** `profiles_controller.rb#profile_params` / `groups_controller.rb#group_params` already validate the submitted string against `\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}\z` and diff it against the current value to decide whether to touch the record at all. Keeping the submitted field name/format identical means zero controller changes and zero risk to the timezone-parsing behavior documented in `docs/plan-timezones.md`.
- **Real inputs, not a custom widget.** `<input type="number">` gives native cursor placement/editing (fixes the "can't edit one digit" complaint) and a `<select>` gives keyboard/screen-reader users a normal, familiar control (fixes the "digits not names" complaint) — no custom keyboard handling to write or get wrong.
- **One partial, two call sites.** The profile and group forms have byte-for-byte identical markup for this field today; a shared partial keeps them in sync going forward instead of duplicating the picker markup and JS wiring twice.

## Implementation

**1. New Stimulus controller — `app/javascript/controllers/datetime_picker_controller.js`**

Targets: `month`, `day`, `year`, `hour`, `minute`, `hidden`. On `change`/`input` of any visible field, recompute the hidden field:

```js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["month", "day", "year", "hour", "minute", "hidden"]

  combine() {
    const fields = [this.monthTarget, this.dayTarget, this.yearTarget, this.hourTarget, this.minuteTarget]
    if (fields.some((field) => field.value === "")) return

    const pad = (value) => value.padStart(2, "0")
    this.hiddenTarget.value =
      `${this.yearTarget.value}-${this.monthTarget.value}-${pad(this.dayTarget.value)}` +
      `T${pad(this.hourTarget.value)}:${pad(this.minuteTarget.value)}`
  }
}
```

No manual registration needed — `app/javascript/controllers/index.js` eager-loads everything under `controllers/**/*_controller`, same as every other Stimulus controller in this app (`heart_picker_controller.js`, `avatar_editor_controller.js`, etc.).

**2. New shared partial — `app/views/shared/_datetime_picker.html.haml`**

Locals: `form` (the `form_with` builder), `field` (symbol, e.g. `:created_at`), `value` (a zone-aware `Time`, already converted to the viewer's `Time.zone` the same way the current `.strftime` call is). Follows the documented-locals comment convention used in `_avatar_editor_dialog.html.haml`.

```haml
-# Locals:
-#   form  — the form_with builder object
-#   field — the attribute symbol (e.g. :created_at)
-#   value — a Time/ActiveSupport::TimeWithZone already in the viewer's time zone

.datetime-picker{data: {controller: "datetime-picker"}}
  = form.hidden_field field, value: value.strftime("%Y-%m-%dT%H:%M"), data: {"datetime-picker-target": "hidden"}

  .datetime-picker__field
    %label.visually-hidden{for: "#{field}_month"} Month
    %select#{"#{field}_month"}{data: {"datetime-picker-target": "month", action: "change->datetime-picker#combine"}}
      = options_for_select(Date::MONTHNAMES.compact.map.with_index(1) { |name, i| [name, format("%02d", i)] }, format("%02d", value.month))

  .datetime-picker__field
    %label.visually-hidden{for: "#{field}_day"} Day
    %input#{"#{field}_day"}{type: "number", min: 1, max: 31, value: value.day, data: {"datetime-picker-target": "day", action: "input->datetime-picker#combine"}}

  .datetime-picker__field
    %label.visually-hidden{for: "#{field}_year"} Year
    %input#{"#{field}_year"}{type: "number", min: 1, max: 9999, value: value.year, data: {"datetime-picker-target": "year", action: "input->datetime-picker#combine"}}

  .datetime-picker__field
    %label.visually-hidden{for: "#{field}_hour"} Hour
    %input#{"#{field}_hour"}{type: "number", min: 0, max: 23, value: value.hour, data: {"datetime-picker-target": "hour", action: "input->datetime-picker#combine"}}

  .datetime-picker__separator :
  .datetime-picker__field
    %label.visually-hidden{for: "#{field}_minute"} Minute
    %input#{"#{field}_minute"}{type: "number", min: 0, max: 59, value: value.min, data: {"datetime-picker-target": "minute", action: "input->datetime-picker#combine"}}

  %span.form-hint (24 hour time)
```

(Exact id-interpolation syntax to confirm against Haml conventions already in the codebase when implementing — the above is the intended structure, not copy-paste-final Haml.)

**3. Update call sites**

`app/views/our/profiles/_form.html.haml:66-69` and `app/views/our/groups/_form.html.haml:36-39` — replace the `form.datetime_local_field` line with:

```haml
- if profile.persisted?
  .form-group
    = form.label :created_at
    = render "shared/datetime_picker", form: form, field: :created_at, value: profile.created_at
```

(same pattern for groups, using `group.created_at`). No other lines in these files change.

**4. CSS — `app/assets/stylesheets/application.css`**

Add a `.datetime-picker` block near the existing `/* Forms */` section: flexbox row, small gap, each `.datetime-picker__field` sized to content (month `<select>` wider, day/hour/minute narrow, year slightly wider), wrapping on narrow viewports. Scope the number-input width override to `.datetime-picker input[type="number"]` specifically — there are no other number inputs in the app today, but scoping avoids ever accidentally affecting one.

**5. No controller/model changes.** `profile_params`/`group_params` keep validating/comparing the exact same `YYYY-MM-DDTHH:MM` string format — the hidden field guarantees that shape whenever all five sub-fields have a value. Existing tests that submit `created_at` directly via `patch` (bypassing the view) are unaffected. The one view-rendering assertion (`profiles_controller_test.rb:173-182`, `assert_match "2026-01-16T08:30", response.body`) still passes because the hidden field's `value` attribute still contains that exact string.

## Known minor limitation (accepted, not newly introduced)

A user could type a 3-digit year or an out-of-range day/hour into the plain number inputs. `min`/`max` attributes give a soft native nudge, but since these fields aren't the ones submitted (the hidden field is), the browser won't block submission on them. If the resulting hidden value doesn't match the controller's regex, the existing code already silently drops the param and leaves `created_at` unchanged (covered by the existing "update with malformed created_at does not raise" test) — same silent-ignore behavior as today, just reachable through a different UI. Not worth extra server validation for this pass.

## Verification

1. `bin/rails test test/controllers/our/profiles_controller_test.rb test/controllers/our/groups_controller_test.rb` — confirm nothing regresses, especially the timezone-related `created_at` tests.
2. `bin/rubocop` if any Ruby files change (partial/view only, but run it anyway per repo convention).
3. Manual, in-browser (via the `run` skill): open a persisted profile's edit page, confirm the five fields render pre-filled with the current `created_at` in the viewer's time zone, matching what `docs/plan-timezones.md` established. Tab through the fields to confirm each is independently focusable/editable with normal cursor placement. Change each field individually and submit; confirm the record's `created_at` updates correctly. Leave the fields untouched and submit; confirm `created_at`/`updated_at` don't change (the "unchanged" delete-param path still works). Repeat for a group.
4. Quick screen-reader spot check (VoiceOver) that each field announces its label ("Month", "Day", "Year", "Hour", "Minute") rather than reading a fused value.
