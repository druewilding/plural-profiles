# Plan: Chat Mini-Profiles / Privacy

## Status

Implementation-ready. Direction and edge cases are settled (see below), and a concrete, ordered implementation plan follows. Not yet built.

## Background

Today, clicking a name in chat (`chat_postable_url`, in `app/views/chat/messages/_message.html.haml` and the posting-as picker) always navigates to the postable's full profile/group page. There is no visibility/privacy flag on `Profile`/`Group` at all — access is "unguessable UUID," not public/private (confirmed: no such column exists today).

The motivating case: someone's full profile page might be "an enormous sprawling mess of half-finished html," not something they want surfaced just because they said something in chat — but they may still want people who see them in chat to know a few specific things, without maintaining a second full profile just for that purpose.

**User feedback (incorporated below):** the full profile isn't just too much detail for chat — it's the wrong *kind* of content for chat, because it was written for a different trust decision. What someone is willing to show the specific people they've chosen to share their full profile with, and what they're willing for any random chatter to be able to pull up without asking, are two different things. Sharing a webpage with someone you've chosen is a deliberate act; being visible in a chat room isn't. If the chat identity is just a filtered view of the full profile, then anything added to the full profile silently becomes chat-visible too — and the fear that something you didn't consent to show might surface in chat is exactly what stops people from participating in chat at all. So the chat identity needs to be fully independent and safe-by-default, not a leaner view of the full profile.

## Direction agreed so far

- **Core privacy principle:** the chat identity (name aside — see below) is a **separate, independently maintained set of content**, not a filtered/reused view of the full profile. Nothing on it is inherited from the full profile automatically, and every field starts blank. This is what makes it safe by default: filling out an elaborate full profile never, by itself, exposes anything new in chat.
- **One mini-profile per Profile/Group, not per-server.** Explicitly rejected: a different mini-profile per server they're in. A single shared lightweight alternate identity, reused everywhere in chat regardless of which server.
- **Clicking a name/avatar in chat always opens the mini-profile popover now.** This supersedes the earlier "full profile vs. mini-profile" framing — there is no mode where a click still does a full-page navigation. The popover is the universal click target for names/avatars on chat messages.
  - **Scoped to messages only.** The "posting as" identity picker in the composer keeps its current full-page-link behavior; this work doesn't touch it.
- **Content shown in the popover is entirely independent chat-identity content**, not full-profile fields: a new **mini-profile subtitle**, **pronouns** (Profile only), **hearts** (Profile only), **tagline**, and **description** — each stored as its own column, separate from the full profile's `subtitle`/`pronouns`/`heart_emojis`/`tag_line`/`description`. Description is rendered with the same hearts/spoilers formatting as the full `description` field (`formatted_description`), no length cap.
  - **Name is the one exception** and stays as `postable.name` — a chat message is literally posted *as* that name, so unlike the other fields there's no meaningful way to withhold it without breaking what a chat identity even is.
  - Pronouns and hearts are **Profile only**, matching the existing asymmetry where `Group` has neither `pronouns` nor `heart_emojis` on the full profile either.
  - **Any of these sections is omitted entirely (no heading, no placeholder) when its field is blank** — the same "omit if blank" rule already agreed for the description field, now applied uniformly to subtitle/pronouns/hearts/tagline too.
- **The always-visible chat message row is brought into this too, not just the popover.** Today `_message.html.haml` reads `postable.pronouns` and `postable.subtitle` straight off the full profile on *every* message (`app/views/chat/messages/_message.html.haml:14-19`) — that's an unconditional exposure on every message, a bigger version of the exact problem this plan exists to solve. This plan now switches those two lines to the new mini-profile pronouns/subtitle instead.
  - **Rollout note, deliberately left open rather than resolved here:** this is a visible behavior change for existing users — a message row that already shows pronouns/subtitle today will go blank until the owner sets the mini-profile equivalents, because nothing is backfilled (see Data model). That's the correct outcome under "nothing chat-visible without explicit opt-in," but it means existing users lose something they didn't ask to lose, silently, on ship day. Whether that needs an announcement, a one-time nudge, or nothing at all is a product call, not an engineering one — flagged here, not decided.
- **Avatar: a separate, independently-uploadable mini-profile avatar image**, not a rule that always mirrors the full profile's avatar.
  - Stored as its own attachment (`mini_profile_avatar`), with its own alt text (`mini_profile_avatar_alt_text`). Same content-type/size validation as the main avatar.
  - **Falls back to the full profile's avatar when no mini-profile-specific image has been uploaded**, so someone who's fine reusing their existing picture doesn't have to re-upload it just to have a chat avatar — but anyone who wants a different (or no) image just for chat can set one independently, including removing it back to the fallback.
  - **Shape** (`circle`/`rounded`/`square`) is shared with the existing `avatar_shape` column rather than duplicated — it's cosmetic framing, not identifying content, so there's no privacy reason to keep it separate. Only the *image itself* needs independence.
  - Both the popover and the always-visible message-row avatar resolve through this same fallback (one shared helper), so a chat-specific avatar, once set, applies consistently everywhere in chat.
- **Link at the bottom of the popover, gated by a new opt-in boolean** (default `false` — off unless the owner turns it on):
  - Owner viewing their own postable: always shows **"Edit profile"** / **"Edit group"** (links to `edit_our_profile_path`/`edit_our_group_path`), regardless of the boolean — the boolean only affects what other viewers see.
  - Other viewers, boolean **on**: shows **"View full profile"**, opens in a new tab, links to the public `profile_path`/`group_path` (uuid).
  - Other viewers, boolean **off**: no link at all — the rest of the popover (name/subtitle/pronouns/hearts/tagline/description) still shows.
  - "Other viewers" in this app always means another logged-in plural-profiles user — there is no anonymous/logged-out viewer concept anywhere in the app today (confirmed: public share pages still require auth).
- **Ownership check reuses existing logic**: `postable.user_id == Current.user&.id`, same as `chat_postable_url` today. No multi-owner/group-membership complexity — Groups and Profiles are both strictly single-owner (`belongs_to :user`).
- **Deleted/missing postable**: if the profile/group a message references no longer exists, the name/avatar renders as a disabled, non-clickable element instead of a popover trigger. This is already the app's current behavior (`message.postable_name` fallback, see Frontend section) — no change needed there.
- **Editing surface**: a new **"Chat identity" section** in the profile/group edit form (named deliberately, not "chat settings" — this is a distinct, independently-maintained identity, not a settings tweak on the existing profile), grouping the existing "chat proxy brackets" field together with the mini-profile avatar picker, subtitle, pronouns (Profile only), hearts (Profile only), tagline, description, and the opt-in visibility boolean. Today brackets are a lone inline `.form-group`; this introduces the fieldset grouping for the first time.
- **Loading**: fetched on demand when the popover opens (lazy), not preloaded per-message — avoids extra payload/queries on chats with hundreds of messages. Implemented as a **Turbo Frame**, matching Rails/Hotwire conventions already used elsewhere in the app, rather than a Stimulus-driven JSON fetch.
- **Groups confirmed**: a Group's chat mini-profile/privacy works identically to a Profile's (minus pronouns/hearts, which Groups don't have anywhere), consistent with `Group` already paralleling `Profile` in every other chat-relevant concern (`ChatProxyable`, `HasAvatar`). Same single-owner (`user_id`) check for the Edit-vs-View branch.

## Implementation plan

### Data model

Both `Profile` and `Group` get a new, independent set of "chat identity" columns — one per full-profile field they replace for chat purposes, plus the avatar/link fields:

- `mini_profile_subtitle` (`string`, nullable)
- `mini_profile_tag_line` (`string`, nullable)
- `mini_profile_description` (`text`, nullable) — rendered with `formatted_description`, no length cap.
- `mini_profile_pronouns` (`string`, nullable) — **Profile only**.
- `mini_profile_heart_emojis` (`jsonb`, `default: [], null: false`) — **Profile only**; normalized/validated the same way as `heart_emojis` (see Model changes).
- `mini_profile_avatar_alt_text` (`string`, nullable) — pairs with the new `mini_profile_avatar` attachment below. No `mini_profile_avatar_shape` column — shape is shared with the existing `avatar_shape`.
- `mini_profile_link_enabled` (`boolean`, `default: false, null: false`) — opt-in, off by default. Unchanged from the original plan.

One migration touching both tables:

```ruby
class AddChatIdentityFieldsToProfilesAndGroups < ActiveRecord::Migration[8.1]
  def change
    add_column :profiles, :mini_profile_subtitle, :string
    add_column :profiles, :mini_profile_tag_line, :string
    add_column :profiles, :mini_profile_description, :text
    add_column :profiles, :mini_profile_pronouns, :string
    add_column :profiles, :mini_profile_heart_emojis, :jsonb, default: [], null: false
    add_column :profiles, :mini_profile_avatar_alt_text, :string
    add_column :profiles, :mini_profile_link_enabled, :boolean, default: false, null: false

    add_column :groups, :mini_profile_subtitle, :string
    add_column :groups, :mini_profile_tag_line, :string
    add_column :groups, :mini_profile_description, :text
    add_column :groups, :mini_profile_avatar_alt_text, :string
    add_column :groups, :mini_profile_link_enabled, :boolean, default: false, null: false
  end
end
```

No backfill — every existing profile/group starts with all of these blank (see the rollout note above). No model code changes needed for the plain-attribute columns — Rails' auto-generated `mini_profile_link_enabled?` predicate is enough, same as every other plain attribute on these models.

#### Model changes

- **`HasAvatar`** (`app/models/concerns/has_avatar.rb`): add `has_one_attached :mini_profile_avatar`, and generalize the existing `avatar_content_type_allowed`/`avatar_size_allowed` validations to run against both attachment names instead of duplicating them, e.g.:
  ```ruby
  AVATAR_ATTACHMENTS = %i[avatar mini_profile_avatar].freeze

  included do
    has_one_attached :avatar
    has_one_attached :mini_profile_avatar
    validate :avatar_attachments_are_valid
    validates :avatar_shape, inclusion: { in: AVATAR_SHAPES }
  end

  private

  def avatar_attachments_are_valid
    AVATAR_ATTACHMENTS.each do |name|
      attachment = public_send(name)
      next unless attachment.attached?
      errors.add(name, "must be a JPG/JPEG, PNG, or WebP image") unless attachment.blob.content_type.in?(AVATAR_CONTENT_TYPES)
      errors.add(name, "must be 2 MB or less") if attachment.blob.byte_size > AVATAR_MAX_SIZE
    end
  end
  ```
- **`Profile`**: mirror the existing `heart_emojis=` normalization and `heart_emojis_are_valid` validation for `mini_profile_heart_emojis` — same `resolve_heart_emoji` logic, same "contains invalid hearts" error, since it's the same free-form array-of-strings shape.
- **`Group`**: no changes beyond what `HasAvatar` already adds.
- **New helper** (`app/helpers/application_helper.rb`, next to `avatar_shape_class`): the shared fallback resolution used by both the message row and the popover:
  ```ruby
  def chat_avatar_for(postable)
    postable.mini_profile_avatar.attached? ? postable.mini_profile_avatar : postable.avatar
  end

  def chat_avatar_alt_text_for(postable)
    if postable.mini_profile_avatar.attached?
      postable.mini_profile_avatar_alt_text.presence || ""
    else
      postable.avatar_alt_text.presence || ""
    end
  end
  ```

### Backend

- **Permitted params**: in `Our::ProfilesController#profile_params`, add `:mini_profile_subtitle, :mini_profile_tag_line, :mini_profile_description, :mini_profile_pronouns, :mini_profile_avatar, :mini_profile_avatar_alt_text, :mini_profile_link_enabled, mini_profile_heart_emojis: []`. In `Our::GroupsController#group_params`, add the same list minus `:mini_profile_pronouns` and `mini_profile_heart_emojis: []` (Group has neither).
- **Avatar removal/cleanup**: mirror the existing `avatar`/`remove_avatar` handling for the new attachment (not part of strong params, read directly off `params`, same as today):
  ```ruby
  @profile.avatar.purge if params[:profile][:remove_avatar] == "1"
  @profile.mini_profile_avatar.purge if params[:profile][:remove_mini_profile_avatar] == "1"
  ```
  and the same failed-validation detach/purge_later cleanup already done for `avatar` in `update`, duplicated for `mini_profile_avatar`. Same pattern in `Our::GroupsController`.
- **New route**, inside the existing `constraints subdomain: "chat"` block in `config/routes.rb` (sibling to `resources :servers`, not nested under it — a postable isn't scoped to one server):
  ```ruby
  get "mini_profile/:postable_type/:postable_uuid", to: "mini_profiles#show",
    as: :mini_profile, constraints: { postable_type: /Profile|Group/ }
  ```
  `postable_type` is needed because `uuid` uniqueness (`validates :uuid, uniqueness: true`) is only enforced per-table — a Profile and a Group could coincidentally share a uuid.
- **New controller**: `app/controllers/chat/mini_profiles_controller.rb`, inheriting `Chat::ApplicationController` (consistent with its siblings) with `layout false` (it only ever renders a Turbo Frame fragment, same pattern as `Chat::MessagesController#index`):
  ```ruby
  module Chat
    class MiniProfilesController < ApplicationController
      layout false

      POSTABLE_TYPES = { "Profile" => Profile, "Group" => Group }.freeze

      def show
        klass = POSTABLE_TYPES.fetch(params[:postable_type]) { raise ActiveRecord::RecordNotFound }
        @postable = klass.find_by!(uuid: params[:postable_uuid])
        @own = @postable.user_id == Current.user.id
      end
    end
  end
  ```
  `Chat::ApplicationController#set_server` (`app/controllers/chat/application_controller.rb`) reads `params[:server_uuid] || params[:uuid]`; since this route uses `postable_uuid`, not `uuid`, it no-ops harmlessly — no need to skip it. Authentication is already enforced app-wide via `Authentication#require_authentication`; no extra auth check needed (this mirrors how `profile_path`/`group_path` share pages work today — logged in is the only bar, ownership only changes which link is shown, not access to the panel itself).
- **View** `app/views/chat/mini_profiles/show.html.haml`: wraps the content in `turbo_frame_tag mini_profile_frame_id(@postable)` (a small helper returning `"mini_profile_#{postable.class.name}_#{postable.uuid}"`, used both here and by the trigger frame placeholder in the message partial, so Turbo can match and swap the response in).
- **New partial** `app/views/chat/mini_profiles/_mini_profile.html.haml`, rendering entirely mini-profile fields (not full-profile ones — this is the key change from the earlier version of this plan), reusing the markup/classes already established in `app/views/profiles/show.html.haml` for layout:
  - Avatar via `chat_avatar_for(postable)` / `chat_avatar_alt_text_for(postable)`, using the postable's own configured shape: `avatar_shape_class(postable)` (no shape override — this differs from the message row's forced-circle avatar, which uses `avatar_shape_class(postable, shape: "circle")`).
  - Name (`formatted_inline`), `mini_profile_subtitle` if present.
  - `mini_profile_pronouns` and `mini_profile_heart_emojis`, guarded by `postable.respond_to?(:mini_profile_pronouns)` / `respond_to?(:mini_profile_heart_emojis)` (same technique already used in `_message.html.haml:14`) since `Group` has neither column. Hearts rendered as `.heart-display__grid` / `.heart-display__heart` exactly as in `profiles/show.html.haml`.
  - `mini_profile_tag_line` if present.
  - `mini_profile_description`, via `formatted_description(postable.mini_profile_description)`, section omitted entirely when blank.
  - Link at the bottom (unchanged from the original plan):
    - `@own` → `"Edit profile"` / `"Edit group"` linking to `edit_our_profile_path`/`edit_our_group_path` (branch on `postable.is_a?(Group)`).
    - not `@own` and `postable.mini_profile_link_enabled?` → `"View full profile"`, `target: "_blank", rel: "noopener"`, linking to `profile_path(postable.uuid)`/`group_path(postable.uuid)`.
    - not `@own` and link disabled → no link rendered at all (rest of the popover is unaffected).

### Frontend

- **`_message.html.haml`** (`app/views/chat/messages/_message.html.haml`):
  - Avatar block (lines 2-6): switch from `message.postable&.avatar&.attached?` / `message.postable.avatar.variant(...)` to `chat_avatar_for(message.postable)` / `chat_avatar_alt_text_for(message.postable)`, keeping the forced-circle shape (`avatar_shape_class(message.postable, shape: "circle")`) unchanged.
  - Pronouns (line 14): `message.postable.respond_to?(:mini_profile_pronouns) && message.postable.mini_profile_pronouns.present?`, rendering `mini_profile_pronouns` instead of `pronouns`.
  - Subtitle (line 19): `message.postable&.mini_profile_subtitle&.present?`, rendering `mini_profile_subtitle` instead of `subtitle`.
  - Replace the `link_to chat_postable_url(...)` wrapper around the name (and extend it to the avatar) with a click trigger controlled by a new Stimulus controller. The existing `- else` branch (postable deleted → plain `"#{message.postable_name} (deleted)"` text, no link) is already exactly the "disabled state" behavior wanted for deleted postables — **no change needed there**.
- **New Stimulus controller** `app/javascript/controllers/mini_profile_popover_controller.js`:
  - Values: `{ url: String }` (the `chat_mini_profile_path(...)` route for this message's postable).
  - Targets: `trigger` (avatar + name wrapper), `frame` (the empty `turbo-frame` placeholder, `src` unset initially so it never fetches until asked), `panel` (a wrapper element using the native `popover` attribute — see below).
  - On trigger click: if `frame.src` isn't set yet, set it to the `url` value (fires the Turbo fetch exactly once per message, matching the "fetch on click, not preloaded" decision); position `panel` near the trigger's `getBoundingClientRect()`; call `panel.showPopover()`.
  - Uses the HTML **Popover API** (`popover="auto"` attribute) rather than the `<dialog>` pattern used by `avatar_editor_controller.js` — this is a deliberate difference, not an inconsistency: `popover="auto"` gets outside-click/Escape light-dismiss for free, which is exactly the toolbar-less "light" behavior a popover needs and a `<dialog>` doesn't give you without extra JS. This is the first use of the Popover API in the codebase, and the first on-demand-fetch UI pattern anywhere in the app, so allow some extra care/review time here.
- **New partial-backed styles**: `.mini-profile-popover` styling (positioned via inline styles set by the controller, visually similar to the existing `.card`/`.profile-card` treatment) — left to implementation, not pinned down further here.
- **Avatar editor needs to support a second, independent avatar on the same form.** `app/views/shared/_avatar_editor_dialog.html.haml` and `app/javascript/controllers/avatar_editor_controller.js` currently hardcode the `avatar`/`avatar_shape`/`avatar_alt_text`/`remove_avatar` attribute and param names — they need parameterizing (locals for the attribute name / target-attribute prefix / param key) so the edit form can render the dialog twice: once for `avatar` (existing), once for `mini_profile_avatar` (new). Two `data: {controller: "avatar-editor"}` instances on the same page are already fine as-is — Stimulus scopes targets/values to each controller's own DOM subtree. The mini-profile instance:
  - Has no shape picker (shape is shared with the main avatar — see Direction).
  - Its "current" preview should show the *effective* avatar (`chat_avatar_for`) when no mini-profile-specific image is attached yet, so the form doesn't show an empty state for someone who already has a perfectly good main avatar that'll be used as the fallback — but the "Remove" checkbox/action only appears once an actual `mini_profile_avatar` is attached (removing it reverts to the fallback, it doesn't touch the main avatar).

### Edit form

In both `app/views/our/profiles/_form.html.haml` and `app/views/our/groups/_form.html.haml`, replace the existing lone `.form-group` for "Chat proxy brackets" with a `%fieldset.form-group` + `%legend Chat identity`, containing, in order:

1. The existing bracket fields, unchanged.
2. The mini-profile avatar editor dialog (parameterized instance of `shared/avatar_editor_dialog`, attribute `mini_profile_avatar`), with copy along the lines of "Used in chat instead of your main avatar — leave blank to keep using your main avatar there too."
3. `form.text_area :mini_profile_description` (placeholder along the lines of "Shown in the mini-profile popover when someone clicks your name in chat. Independent from your full profile's description — nothing here is shared unless you write it here.").
4. `form.text_field :mini_profile_subtitle`.
5. `form.text_field :mini_profile_pronouns` (Profile only), placeholder "e.g. they/them, she/her, he/him".
6. `form.text_field :mini_profile_tag_line`.
7. Heart picker for `mini_profile_heart_emojis` (Profile only) — same `heart-picker` Stimulus component and markup as the existing full-profile picker, parameterized to a different field name (`profile[mini_profile_heart_emojis][]`).
8. `form.check_box :mini_profile_link_enabled` with a label/hint explaining it controls whether other viewers get a "View full profile"/"Edit ..." link from the mini-profile popover — off by default.

A one-line hint at the top of the fieldset should state the independence explicitly, e.g. "Chat shows this information instead of your full profile — none of it is filled in automatically, and nothing you add to your full profile appears here unless you add it here too."

### Order of implementation

1. Migration: add the new columns to `profiles` and `groups`; run `bin/rails db:migrate`.
2. `HasAvatar`: add `mini_profile_avatar` attachment + generalized validations; `Profile`: `mini_profile_heart_emojis` normalization/validation; new `chat_avatar_for`/`chat_avatar_alt_text_for` helpers.
3. Permit the new params (including avatar removal handling) in `Our::ProfilesController#profile_params`/`update` and `Our::GroupsController#group_params`/`update`.
4. Parameterize `shared/avatar_editor_dialog` + `avatar_editor_controller.js` to support a second, independently-named avatar instance.
5. Add the "Chat identity" fieldset (brackets + mini avatar + subtitle/pronouns/hearts/tagline/description + checkbox) to both edit form partials.
6. Add the new route under the `chat` subdomain constraint.
7. Add `Chat::MiniProfilesController#show` + its view + the `_mini_profile` partial (mini-profile fields, not full-profile ones) + the `mini_profile_frame_id` helper.
8. Update `_message.html.haml`: switch avatar/pronouns/subtitle to the mini-profile fields, and wrap avatar+name in the new trigger markup + empty `turbo-frame` placeholder.
9. Add `mini_profile_popover_controller.js` (Stimulus) and register it in `app/javascript/controllers/index.js`.
10. Add popover CSS.
11. Tests (see below).
12. Manual verification in a running dev server.

### Tests

- `test/controllers/our/profiles_controller_test.rb` / `our/groups_controller_test.rb`: extend `update` coverage to assert `mini_profile_subtitle`/`mini_profile_tag_line`/`mini_profile_description`/`mini_profile_pronouns`(Profile)/`mini_profile_heart_emojis`(Profile)/`mini_profile_link_enabled` persist independently of the equivalent full-profile fields (updating one doesn't touch the other); that a fresh profile/group defaults all of them to blank/`false`; that an invalid `mini_profile_heart_emojis` entry fails validation the same way an invalid `heart_emojis` entry does; and mini-profile avatar upload/remove/fallback (uploading sets `mini_profile_avatar`, `remove_mini_profile_avatar=1` purges it without touching `avatar`).
- New `test/controllers/chat/mini_profiles_controller_test.rb`: covers both Profile and Group postables —
  - owner viewing their own postable always gets the edit link regardless of the boolean;
  - non-owner gets the "View full profile" link only when `mini_profile_link_enabled? == true`;
  - non-owner gets no link when the flag is off, but the rest of the content still renders;
  - popover content comes from `mini_profile_*` fields, not the full-profile fields — e.g. a profile with a full-profile `pronouns` set but blank `mini_profile_pronouns` shows no pronouns in the popover;
  - blank `mini_profile_description`/`mini_profile_subtitle`/`mini_profile_tag_line` each omit their section;
  - avatar falls back to the main `avatar` when `mini_profile_avatar` isn't attached, and uses `mini_profile_avatar` when it is;
  - unauthenticated request redirects to sign-in (inherited `require_authentication`);
  - unknown `postable_uuid` / invalid `postable_type` → 404.
- Extend `test/system/chat_messaging_test.rb` (or a new `test/system/chat_mini_profile_test.rb`):
  - click a message's name/avatar opens the popover with expected mini-profile fields;
  - a message row shows `mini_profile_pronouns`/`mini_profile_subtitle` (not the full-profile values) and shows nothing when they're blank;
  - a deleted postable's message renders inert text with no popover trigger.

### Verification

- `bin/rails db:migrate`, `bin/rails test`, `bin/rails test:system` (targeted at the new/updated files).
- Manual: run the dev server, open a chat channel as two different users. Confirm:
  - clicking your own message's name shows "Edit profile"/"Edit group"; clicking another user's message shows no link by default; toggling the checkbox on in their edit form makes "View full profile" (new tab) appear for the other viewer;
  - a profile with full-profile pronouns/subtitle/hearts/tagline/description set but nothing in the new mini-profile fields shows **none** of that in chat (message row or popover) — confirming the two are actually decoupled, not just relabeled;
  - filling in the mini-profile fields makes them appear in chat without changing the full profile page at all, and vice versa;
  - uploading a mini-profile-specific avatar changes the chat avatar (message row + popover) without changing the full profile's avatar; removing it reverts chat to the main avatar;
  - a blank mini-profile description/subtitle/tagline each show no empty section;
  - a message from a deleted profile/group still renders as inert "(deleted)" text with no popover.

### Explicitly out of scope for this pass

- The "posting as" composer picker keeps its current full-page-link behavior (confirmed with user).
- No `pp!` chat-command surface for toggling/editing this (per `docs/plan-chat-commands.md`, still just an idea).
- No per-server override of the visibility setting — it's profile/group-level only, everywhere.
- No backfill/migration of existing profiles' or groups' full-profile subtitle/pronouns/hearts/tagline into the new mini-profile fields — everyone starts blank; whether/how to communicate that to existing users is an open rollout question (see Direction), not resolved here.
- No separate mini-profile-specific avatar shape control — shape is shared with the main avatar; only the image itself is independent.

## Depends on / relates to

- `plan-chat-servers.md` — `chat_postable_url`, message rendering, postable resolution.
- `plan-chat-commands.md` — possible future command(s) for toggling visibility / editing mini-profile content (out of scope for this pass).
- `plan-avatar-editor-popup.md` — the existing avatar editor dialog/Stimulus controller this plan needs to parameterize for a second, independent avatar.
