# Plan: Per-User Time Zones

## Summary

A UK user reported that timestamps (profile/group "created at", relative times) appear an hour early. The root cause isn't the server being in France — nothing in the app currently converts stored times to any viewer's local time at all, so authenticated dashboard pages just print raw UTC. During British Summer Time (UTC+1), a UTC timestamp reads exactly one hour behind a UK user's wall clock, matching the report.

This plan adds real per-viewer time zone handling: an optional account-level preference, JS-based auto-detection as a fallback, and a per-request `Time.zone` so every zone-aware timestamp in the app (`created_at`, `updated_at`, `relative_time`) displays correctly without touching a single view.

No data migration is needed. Rails' `default_timezone` (`:utc`) has never been overridden here, so every `datetime` column is already stored in UTC in Postgres — the "assume the DB is already UTC" premise holds today, not just going forward.

## Decisions

| Question                   | Decision                                                                                                                                                                                                                                              |
| -------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Where does zone come from? | `users.time_zone` (explicit, if set) → `browser_time_zone` cookie (auto-detected) → `"UTC"` (fallback)                                                                                                                                                |
| Auto-detect mechanism      | Stimulus controller reads `Intl.DateTimeFormat().resolvedOptions().timeZone` and writes it to a cookie on page load                                                                                                                                   |
| Manual override            | New "Time zone" dropdown on the account page, using Rails' built-in `time_zone_select` helper                                                                                                                                                         |
| Scope                      | Only the authenticated `our/…` dashboard views render timestamps today (public profile/group pages don't) — no public-facing changes needed                                                                                                           |
| Existing data              | Already UTC (`config.active_record.default_timezone` defaults to `:utc` and was never overridden) — no backfill required                                                                                                                              |
| Storage format             | IANA-compatible names throughout (`ActiveSupport::TimeZone` resolves both Rails' friendly names like `"Copenhagen"` and raw IANA names like `"Europe/London"` via `TZInfo`, so the cookie and the dropdown can use different naming without conflict) |

## Background: how the bug actually works

- `config.time_zone` is commented out in [application.rb](config/application.rb#L24) → Rails defaults `Time.zone` to `"UTC"`.
- `config.active_record.default_timezone` is also untouched → Rails defaults to `:utc` for DB storage.
- So `@profile.created_at` is a UTC-valued `ActiveSupport::TimeWithZone`, and [our/profiles/show.html.haml:56](app/views/our/profiles/show.html.haml#L56) / [our/groups/show.html.haml:31](app/views/our/groups/show.html.haml#L31) call `.strftime` directly on it — printing UTC, unconverted, to every viewer regardless of where they are.
- Nothing in the codebase calls plain `Time.now` (which would pull in the OS/system zone) — confirmed via repo-wide grep. So the fix is purely additive: introduce a per-request `Time.zone`, and the existing zone-aware attributes + `strftime`/`relative_time` calls will automatically render correctly. No view changes required.

---

## Phase 1: Migration

Add a nullable time zone column to `users`:

```sh
bin/rails generate migration AddTimeZoneToUsers time_zone:string
```

```ruby
class AddTimeZoneToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :time_zone, :string
  end
end
```

`nil` means "no explicit preference — use the auto-detected cookie, falling back to UTC."

---

## Phase 2: `User` model

```ruby
validates :time_zone, inclusion: { in: ActiveSupport::TimeZone.all.map(&:name) }, allow_blank: true
```

`allow_blank: true` keeps the column optional. `ActiveSupport::TimeZone.all.map(&:name)` is the same list `time_zone_select` renders, so anything the dropdown can submit will validate.

---

## Phase 3: Auto-detect cookie

New Stimulus controller, `app/javascript/controllers/timezone_controller.js`, attached to `<body>` (or another element present on every page):

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const detected = Intl.DateTimeFormat().resolvedOptions().timeZone
    if (!detected) return

    const current = document.cookie
      .split("; ")
      .find(row => row.startsWith("browser_time_zone="))
      ?.split("=")[1]

    if (current !== encodeURIComponent(detected)) {
      const oneYear = 365 * 24 * 60 * 60
      document.cookie = `browser_time_zone=${encodeURIComponent(detected)}; path=/; max-age=${oneYear}; SameSite=Lax`
    }
  }
}
```

This only takes effect on the *next* request (the current page has already been rendered server-side by the time the cookie is set), which is an acceptable, standard limitation of this pattern.

---

## Phase 4: `ApplicationController` — set `Time.zone` per request

```ruby
class ApplicationController < ActionController::Base
  include Authentication
  allow_browser versions: :modern
  stale_when_importmap_changes

  around_action :set_time_zone

  private

  def set_time_zone(&block)
    Time.use_zone(resolved_time_zone, &block)
  end

  def resolved_time_zone
    candidates = [ Current.user&.time_zone, cookies[:browser_time_zone] ]
    candidates.each do |name|
      zone = ActiveSupport::TimeZone[name.to_s] if name.present?
      return zone if zone
    end
    "UTC"
  end
end
```

`ActiveSupport::TimeZone[]` returns `nil` for garbage/unrecognised input (e.g. a tampered cookie) rather than raising, so this safely falls through to UTC. Placing this in `ApplicationController` covers every controller, including public-facing ones, at no extra cost — even though only the `our/…` views currently render timestamps, this makes the whole app correct by default going forward.

---

## Phase 5: Account page — manual override

Extend the existing "Display preferences" card in [our/account/show.html.haml](app/views/our/account/show.html.haml) and reuse the existing `update_preferences` action ([our/account_controller.rb](app/controllers/our/account_controller.rb)):

```haml
.form-group
  = form.label :time_zone, "Time zone"
  = form.time_zone_select :time_zone, nil, { include_blank: "Auto-detect from browser" }
  %p.form-hint
    Leave blank to use your browser's detected time zone. Set this if you want times shown in a specific zone regardless of device.
```

```ruby
def update_preferences
  Current.user.update!(
    override_themes: params[:override_themes] == "1",
    time_zone: params[:user][:time_zone].presence
  )
  redirect_to our_account_path, notice: "Preferences updated."
end
```

(Form field needs to be namespaced under `user[time_zone]` — either wrap the whole "Display preferences" form in `form_with model: Current.user` like the account-name form does, or add a hidden `user` param prefix. Match whichever is cleaner once touching the view.)

---

## Phase 6: Tests

**Model** (`test/models/user_test.rb`):
- valid time zones (e.g. `"Copenhagen"`, `"London"`) pass validation
- garbage string fails validation
- blank/nil is valid

**Controller** (`test/controllers/our/account_controller_test.rb`):
- `update_preferences` with a valid `time_zone` persists it
- `update_preferences` with blank `time_zone` clears it (sets nil)

**Request/integration test** (new, e.g. `test/integration/time_zone_test.rb` or added to an existing controller test):
- signed-in user with `time_zone: "Europe/London"`, no cookie → a page rendering `created_at` shows the London-local hour, not UTC
- signed-out/no-preference request with `browser_time_zone` cookie set → same, cookie wins
- no user preference, no cookie → UTC (today's behavior, unchanged)
- malformed cookie value → falls back to UTC without raising

**System test**: not essential here since there's no interactive JS behavior to click through beyond the existing preferences form — a request test covering the `around_action` is sufficient. Optionally extend `test/system/account_settings_test.rb` to check the new dropdown renders and saves.

---

## Implementation Order

1. Phase 1 — migration
2. Phase 2 — model validation
3. Phase 4 — `ApplicationController` around_action (safe to ship even before the UI exists; defaults to UTC same as today)
4. Phase 3 — auto-detect cookie controller
5. Phase 5 — account page UI
6. Phase 6 — tests

---

## Verification

```sh
bin/rails db:migrate
bin/rails test
bin/rubocop
```

Manual:
1. Set your OS/browser to a non-UTC zone (e.g. `Europe/London` in summer, UTC+1).
2. Visit any `our/…` page with a timestamp — without any account preference set, the auto-detect cookie should make `created_at`/`relative_time` match your local wall clock, not UTC.
3. Set an explicit "Time zone" on the account page to something else (e.g. `Pacific Time`) and confirm timestamps now use that instead, overriding the cookie.
4. Clear the account preference back to "Auto-detect" and confirm it falls back to the cookie value again.

## Risks & Notes

- **Mailers/background jobs run outside the request cycle** — `Time.zone` set via the `around_action` doesn't apply there. None of the current mailers render timestamps, so this isn't an active bug, but if a future email needs to show a time, explicitly use `Current.user&.time_zone || "UTC"` rather than assuming `Time.zone` is set.
- **First request of a session has no cookie yet** — brand-new visitors see UTC until the Stimulus controller's first `connect()` fires and sets the cookie for subsequent requests. Unavoidable with a JS-only detection approach; the explicit account setting is the escape hatch for anyone who cares enough to set it once.
- **`datetime_local_field` overrides stay UTC on purpose** — the "Created at (UTC)" override inputs in [profiles/_form.html.haml](app/views/our/profiles/_form.html.haml#L68-69) and [groups/_form.html.haml](app/views/our/groups/_form.html.haml#L38-39) are an explicit power-user feature for backdating, already labeled "(UTC)" and built around `.utc.strftime`. Leave those as-is — they're a deliberate raw-value input, not a "display time to the viewer" concern.
