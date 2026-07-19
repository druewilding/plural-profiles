# Plan: Accessible multi-field date/time picker for `created_at`

## Context

Profiles and groups have a "Created at" override field (used to backdate/postdate a record). Today it's a bare `datetime_local_field`, which the browser renders as its native segmented widget — the exact UI shown in the reported screenshot (`June` dropdown, single fused box for day/year, `13 : 14` for time). A user reported real accessibility/usability problems with this native control:

- Everything lives in one fused input, so keyboard/screen-reader users can't address one part at a time.
- The month segment shows raw digits on most browsers (Chrome does; this app happened to be tested in Firefox, which shows names) — bad for dyscalculia and unclear generally.
- Clicking or tabbing into a segment force-selects the whole 2-digit chunk; you can't place a cursor mid-value and edit a single digit.
- Because it's one fused value, the segment order is dictated by OS/browser locale (`MM/DD/YYYY` vs `DD/MM/YYYY`), which is a guaranteed source of confusion for international users and something we can't control from the app.

The user pointed to Dreamwidth's date/time entry UI as a better reference: genuinely separate form fields rather than one native fused control.

This only touches the "Created at" override on `our/profiles/_form.html.haml` and `our/groups/_form.html.haml` — the two places `datetime_local_field` is used (confirmed via repo-wide search; nothing else in the codebase does date/time entry).

## Approach (revised after discussion)

An earlier draft of this plan combined five plain fields into a hidden field via a Stimulus controller. Two follow-up questions changed the design:

1. **"How does this work with no JS?"** — it didn't. The visible fields had no `name`, so with JS disabled, edits never reached the server.
2. **"Can we get dropdown suggestions?"** — yes, and solving this solves problem 1 for free.

The final approach: five real, individually-labeled `<input type="text">` fields (Month, Day, Year, Hour, Minute), each paired with an HTML `<datalist>` of suggested values via the `list=` attribute. This is a native browser combobox — the browser filters suggestions as you type, entirely without JS, and degrades to a plain text field if `<datalist>` isn't supported. Month's datalist offers full names ("January"…"December"); Day/Hour/Minute offer their valid numeric ranges; Year offers the last 10 years as a starting point but accepts any typed value (unbounded, since `created_at` can be set arbitrarily far in the past or future — see PR #252).

Each field submits its own param (`profile[created_at_parts][month]`, `[day]`, `[year]`, `[hour]`, `[minute]`) rather than being combined client-side. The server combines and validates them — this moves the "is this a valid date" work to a place that works identically with or without JS, and lets the month field accept either a typed name ("June") or a number ("6").

Why this shape:
- **No JS dependency, by construction.** `<datalist>` filtering is native browser behavior. There is no Stimulus controller in this feature at all.
- **Real inputs, not a custom widget.** Plain `<input type="text">` gives native cursor placement/editing (fixes "can't edit one digit") and typing a month name is naturally supported without extra markup (fixes "digits not names").
- **Explicit per-field labels resolve the locale-ordering complaint** regardless of which order the fields are laid out in.
- **One partial, two call sites.** The profile and group forms had byte-for-byte identical markup for this field; a shared partial keeps them in sync.
- **Server-side parsing gets free validation.** Range-checking (month 1–12, day 1–31, hour 0–23, minute 0–59) now happens explicitly, rather than relying on the browser's native `datetime-local` widget to prevent invalid values.

## Implementation

**1. Shared partial — `app/views/shared/_datetime_picker.html.haml`**

Locals: `form` (the `form_with` builder), `field` (symbol, e.g. `:created_at`), `value` (a zone-aware `Time`, already converted to the viewer's `Time.zone`, same as the old `.strftime` call). Renders five `.datetime-picker__field` blocks (Month/Day/Year/Hour/Minute), each a visually-hidden `<label>` + `<input type="text" list="...">` + a `<datalist>` of suggestions. Fields submit as `#{form.object_name}[#{field}_parts][month|day|year|hour|minute]` — not the real `created_at` attribute name, since the server needs to combine and validate them first.

**2. Server-side parsing — `app/controllers/concerns/created_at_parts_parsing.rb`**

New shared concern, `include`d in both `Our::ProfilesController` and `Our::GroupsController`:

```ruby
module CreatedAtPartsParsing
  extend ActiveSupport::Concern

  private

  def parse_created_at_parts(parts)
    return nil if parts.blank?

    month = Date::MONTHNAMES.index { |name| name&.casecmp?(parts[:month].to_s.strip) }
    month ||= Integer(parts[:month], exception: false)
    day = Integer(parts[:day], exception: false)
    year = Integer(parts[:year], exception: false)
    hour = Integer(parts[:hour], exception: false)
    minute = Integer(parts[:minute], exception: false)
    return nil if [month, day, year, hour, minute].any?(&:nil?)
    return nil unless (1..12).cover?(month) && (1..31).cover?(day) && (0..23).cover?(hour) && (0..59).cover?(minute)

    format("%04d-%02d-%02dT%02d:%02d", year, month, day, hour, minute)
  end
end
```

**3. Controller call sites**

`profile_params`/`group_params` now `permit(created_at_parts: [:month, :day, :year, :hour, :minute], ...)` instead of `:created_at`, then:

```ruby
created_at = parse_created_at_parts(p.delete(:created_at_parts))
if created_at && (@profile&.created_at.nil? || created_at != @profile.created_at.strftime("%Y-%m-%dT%H:%M"))
  p[:created_at] = created_at
end
```

Same shape as the old blank/malformed/unchanged check, just restructured as "add the key when valid and changed" instead of "delete the key when invalid or unchanged" — same net effect (invalid or no-op edits leave `created_at` untouched, matching the existing "malformed does not raise" behavior, now extended to out-of-range values too, e.g. day 40).

**4. View call sites**

`app/views/our/profiles/_form.html.haml` and `app/views/our/groups/_form.html.haml` — replace `form.datetime_local_field :created_at, ...` with `render "shared/datetime_picker", form: form, field: :created_at, value: profile.created_at` (`group.created_at` for groups).

**5. CSS** — `.datetime-picker` flexbox row in `app/assets/stylesheets/application.css`, sized per field (month wider for full names, day/hour/minute narrow, year medium), wrapping on narrow viewports.

## Verification

1. `bin/rails test test/controllers/our/profiles_controller_test.rb test/controllers/our/groups_controller_test.rb` — covers past/future/malformed/out-of-range/month-as-number and the timezone-aware round trip.
2. `bin/rubocop`.
3. Manual, in-browser: open a persisted profile's edit page, confirm all five fields render pre-filled in the viewer's time zone. Tab through with keyboard; confirm cursor placement works normally in each field. Type a partial month name and confirm the `<datalist>` suggestions filter. Submit unchanged and confirm `created_at`/`updated_at` don't move. Disable JS and repeat the edit — it should work identically. Repeat for a group.
4. Screen-reader spot check that each field announces its label.
