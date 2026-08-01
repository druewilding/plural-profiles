# Plan: Chat Mini-Profiles / Privacy

## Status

Implementation-ready. Direction and edge cases are settled (see below), and a concrete, ordered implementation plan follows. Not yet built.

## Background

Today, clicking a name in chat (`chat_postable_url`, in `app/views/chat/messages/_message.html.haml` and the posting-as picker) always navigates to the postable's full profile/group page. There is no visibility/privacy flag on `Profile`/`Group` at all — access is "unguessable UUID," not public/private (confirmed: no such column exists today).

The motivating case: someone's full profile page might be "an enormous sprawling mess of half-finished html," not something they want surfaced just because they said something in chat — but they may still want people who see them in chat to know a few specific things, without maintaining a second full profile just for that purpose.

## Direction agreed so far

- **One mini-profile per Profile/Group, not per-server.** Explicitly rejected: a different mini-profile per server they're in. A single shared lightweight alternate view, reused everywhere in chat regardless of which server.
- **Clicking a name/avatar in chat always opens the mini-profile popover now.** This supersedes the earlier "full profile vs. mini-profile" framing — there is no mode where a click still does a full-page navigation. The popover is the universal click target for names/avatars on chat messages.
  - **Scoped to messages only.** The "posting as" identity picker in the composer keeps its current full-page-link behavior; this work doesn't touch it.
- **Content shown in the popover**: name, subtitle, pronouns, hearts (`heart_emojis`), tagline, plus a new **mini-profile description** field — rendered with the same hearts/spoilers formatting as the full `description` field (`formatted_description`), no length cap.
  - If the mini-profile description is blank, its section is omitted entirely from the popover (no heading, no placeholder).
- **Avatar inside the popover uses the profile's own configured avatar shape** (as seen on the full profile page), not the forced-circle rule used for message avatars.
- **Link at the bottom of the popover, gated by a new opt-in boolean** (default `false` — off unless the owner turns it on):
  - Owner viewing their own postable: always shows **"Edit profile"** / **"Edit group"** (links to `edit_our_profile_path`/`edit_our_group_path`), regardless of the boolean — the boolean only affects what other viewers see.
  - Other viewers, boolean **on**: shows **"View full profile"**, opens in a new tab, links to the public `profile_path`/`group_path` (uuid).
  - Other viewers, boolean **off**: no link at all — the rest of the popover (name/subtitle/pronouns/hearts/tagline/description) still shows.
  - "Other viewers" in this app always means another logged-in plural-profiles user — there is no anonymous/logged-out viewer concept anywhere in the app today (confirmed: public share pages still require auth).
- **Ownership check reuses existing logic**: `postable.user_id == Current.user&.id`, same as `chat_postable_url` today. No multi-owner/group-membership complexity — Groups and Profiles are both strictly single-owner (`belongs_to :user`).
- **Deleted/missing postable**: if the profile/group a message references no longer exists, the name/avatar renders as a disabled, non-clickable element instead of a popover trigger. This is already the app's current behavior (`message.postable_name` fallback, see Frontend section) — no change needed there.
- **Editing surface**: a new **"Chat settings"** section in the profile/group edit form, grouping the existing "chat proxy brackets" field together with the new mini-profile description field and the opt-in visibility boolean. Today brackets are a lone inline `.form-group`; this introduces the fieldset grouping for the first time.
- **Loading**: fetched on demand when the popover opens (lazy), not preloaded per-message — avoids extra payload/queries on chats with hundreds of messages. Implemented as a **Turbo Frame**, matching Rails/Hotwire conventions already used elsewhere in the app, rather than a Stimulus-driven JSON fetch.
- **Groups confirmed**: a Group's chat mini-profile/privacy works identically to a Profile's, consistent with `Group` already paralleling `Profile` in every other chat-relevant concern (`ChatProxyable`, `HasAvatar`). Same single-owner (`user_id`) check for the Edit-vs-View branch.

## Implementation plan

### Data model

Both `Profile` and `Group` get two new columns (single-owner models, no concern needed — same pattern as `subtitle`/`tag_line`, no extra validation or normalization required):

- `mini_profile_description` (`text`, nullable) — free text, rendered with `formatted_description`, no length cap.
- `mini_profile_link_enabled` (`boolean`, `default: false, null: false`) — opt-in, off by default.

One migration touching both tables (no per-table divergence like the chat-bracket migrations had, which needed separate partial unique indexes — that complexity doesn't apply here):

```ruby
class AddMiniProfileFieldsToProfilesAndGroups < ActiveRecord::Migration[8.1]
  def change
    add_column :profiles, :mini_profile_description, :text
    add_column :profiles, :mini_profile_link_enabled, :boolean, default: false, null: false
    add_column :groups, :mini_profile_description, :text
    add_column :groups, :mini_profile_link_enabled, :boolean, default: false, null: false
  end
end
```

No model code changes needed — Rails' auto-generated `mini_profile_link_enabled?` predicate is enough, same as every other plain attribute on these models.

### Backend

- **Permitted params**: add `:mini_profile_description, :mini_profile_link_enabled` to `profile_params` in `app/controllers/our/profiles_controller.rb` and `group_params` in `app/controllers/our/groups_controller.rb`.
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
- **New partial** `app/views/chat/mini_profiles/_mini_profile.html.haml`, rendering (reusing the exact markup/classes already established in `app/views/profiles/show.html.haml` for avatar/name/pronouns/hearts/tagline, since that's the app's existing pattern for this content):
  - Avatar using the postable's own configured shape: `avatar_shape_class(postable)` (no shape override — this differs from the message row's forced-circle avatar, which uses `avatar_shape_class(postable, shape: "circle")`).
  - Name (`formatted_inline`), subtitle if present.
  - Pronouns and hearts, guarded by `postable.respond_to?(:pronouns)` / `respond_to?(:heart_emojis)` (same technique already used in `_message.html.haml:14`) since `Group` has neither column. Hearts rendered as `.heart-display__grid` / `.heart-display__heart` exactly as in `profiles/show.html.haml`.
  - Tagline if present.
  - Mini-profile description, `formatted_description(postable.mini_profile_description)`, section omitted entirely when blank.
  - Link at the bottom:
    - `@own` → `"Edit profile"` / `"Edit group"` linking to `edit_our_profile_path`/`edit_our_group_path` (branch on `postable.is_a?(Group)`).
    - not `@own` and `postable.mini_profile_link_enabled?` → `"View full profile"`, `target: "_blank", rel: "noopener"`, linking to `profile_path(postable.uuid)`/`group_path(postable.uuid)`.
    - not `@own` and link disabled → no link rendered at all (rest of the popover is unaffected).

### Frontend

- **`_message.html.haml`** (`app/views/chat/messages/_message.html.haml:11-18`): replace the `link_to chat_postable_url(...)` wrapper around the name (and extend it to the avatar) with a click trigger controlled by a new Stimulus controller. The existing `- else` branch (postable deleted → plain `"#{message.postable_name} (deleted)"` text, no link) is already exactly the "disabled state" behavior wanted for deleted postables — **no change needed there**.
- **New Stimulus controller** `app/javascript/controllers/mini_profile_popover_controller.js`:
  - Values: `{ url: String }` (the `chat_mini_profile_path(...)` route for this message's postable).
  - Targets: `trigger` (avatar + name wrapper), `frame` (the empty `turbo-frame` placeholder, `src` unset initially so it never fetches until asked), `panel` (a wrapper element using the native `popover` attribute — see below).
  - On trigger click: if `frame.src` isn't set yet, set it to the `url` value (fires the Turbo fetch exactly once per message, matching the "fetch on click, not preloaded" decision); position `panel` near the trigger's `getBoundingClientRect()`; call `panel.showPopover()`.
  - Uses the HTML **Popover API** (`popover="auto"` attribute) rather than the `<dialog>` pattern used by `avatar_editor_controller.js` — this is a deliberate difference, not an inconsistency: `popover="auto"` gets outside-click/Escape light-dismiss for free, which is exactly the toolbar-less "light" behavior a popover needs and a `<dialog>` doesn't give you without extra JS. This is the first use of the Popover API in the codebase, and the first on-demand-fetch UI pattern anywhere in the app, so allow some extra care/review time here.
- **New partial-backed styles**: `.mini-profile-popover` styling (positioned via inline styles set by the controller, visually similar to the existing `.card`/`.profile-card` treatment) — left to implementation, not pinned down further here.

### Edit form

In both `app/views/our/profiles/_form.html.haml` and `app/views/our/groups/_form.html.haml`, replace the existing lone `.form-group` for "Chat proxy brackets" with a `%fieldset.form-group` + `%legend Chat settings` (same grouping pattern already used for "Groups" and "Heart emojis" in the profile form), containing, in order:

1. The existing bracket fields, unchanged.
2. `form.text_area :mini_profile_description` (placeholder along the lines of "Shown in the mini-profile popover when someone clicks your name in chat...").
3. `form.check_box :mini_profile_link_enabled` with a label/hint explaining it controls whether other viewers get a "View full profile"/"Edit ..." link from the mini-profile popover — off by default.

### Order of implementation

1. Migration: add the two columns to `profiles` and `groups`; run `bin/rails db:migrate`.
2. Permit the two new params in `Our::ProfilesController#profile_params` and `Our::GroupsController#group_params`.
3. Add the "Chat settings" fieldset (brackets + description + checkbox) to both edit form partials.
4. Add the new route under the `chat` subdomain constraint.
5. Add `Chat::MiniProfilesController#show` + its view + the `_mini_profile` partial + the `mini_profile_frame_id` helper.
6. Update `_message.html.haml` to wrap avatar+name in the new trigger markup + empty `turbo-frame` placeholder.
7. Add `mini_profile_popover_controller.js` (Stimulus) and register it in `app/javascript/controllers/index.js`.
8. Add popover CSS.
9. Tests (see below).
10. Manual verification in a running dev server.

### Tests

- `test/controllers/our/profiles_controller_test.rb` / `our/groups_controller_test.rb`: extend `update` coverage to assert `mini_profile_description`/`mini_profile_link_enabled` persist, and that a fresh profile/group defaults `mini_profile_link_enabled` to `false`.
- New `test/controllers/chat/mini_profiles_controller_test.rb`: covers both Profile and Group postables —
  - owner viewing their own postable always gets the edit link regardless of the boolean;
  - non-owner gets the "View full profile" link only when `mini_profile_link_enabled? == true`;
  - non-owner gets no link when the flag is off, but the rest of the content still renders;
  - blank `mini_profile_description` omits that section;
  - unauthenticated request redirects to sign-in (inherited `require_authentication`);
  - unknown `postable_uuid` / invalid `postable_type` → 404.
- Extend `test/system/chat_messaging_test.rb` (or a new `test/system/chat_mini_profile_test.rb`): click a message's name/avatar opens the popover with expected fields; a deleted postable's message renders inert text with no popover trigger.

### Verification

- `bin/rails db:migrate`, `bin/rails test`, `bin/rails test:system` (targeted at the new/updated files).
- Manual: run the dev server, open a chat channel as two different users. Confirm: clicking your own message's name shows "Edit profile"/"Edit group"; clicking another user's message shows no link by default; toggling the checkbox on in their edit form makes "View full profile" (new tab) appear for the other viewer; a blank mini-profile description shows no empty section; a message from a deleted profile/group still renders as inert "(deleted)" text with no popover.

### Explicitly out of scope for this pass

- The "posting as" composer picker keeps its current full-page-link behavior (confirmed with user).
- No `pp!` chat-command surface for toggling/editing this (per `docs/plan-chat-commands.md`, still just an idea).
- No per-server override of the visibility setting — it's profile/group-level only, everywhere.

## Depends on / relates to

- `plan-chat-servers.md` — `chat_postable_url`, message rendering, postable resolution.
- `plan-chat-commands.md` — possible future command(s) for toggling visibility / editing mini-profile content (out of scope for this pass).
