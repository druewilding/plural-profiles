# Plan: Chat Mini-Profiles / Privacy

## Status

In progress. Direction and edge cases are settled (see below), and a concrete, ordered implementation plan follows. See "Order of implementation" for exactly what's built so far vs. still pending — steps are marked inline as they land, rather than tracked separately here.

## Background

Today, clicking a name in chat (`chat_postable_url`, in `app/views/chat/messages/_message.html.haml` and the posting-as picker) always navigates to the postable's full profile/group page. There is no visibility/privacy flag on `Profile`/`Group` at all — access is "unguessable UUID," not public/private (confirmed: no such column exists today).

The motivating case: someone's full profile page might be "an enormous sprawling mess of half-finished html," not something they want surfaced just because they said something in chat — but they may still want people who see them in chat to know a few specific things, without maintaining a second full profile just for that purpose.

**User feedback round 1 (incorporated below):** the full profile isn't just too much detail for chat — it's the wrong *kind* of content for chat, because it was written for a different trust decision. What someone is willing to show the specific people they've chosen to share their full profile with, and what they're willing for any random chatter to see without asking, are two different things. Fear that something you didn't consent to show might surface in chat is exactly what stops people from participating in chat at all — so the chat identity needs to be fully independent and safe-by-default, not a leaner view of the full profile.

**User feedback round 2 (also incorporated below):** editing this shouldn't live on the already-busy create/edit-profile page — not everyone uses chat at all, and cramming chat options into profile creation overwhelms people who don't care about it. It gets its own dedicated page instead. On that page, *every* field — including the name — should be individually choosable as "inherit from my main profile" or "set independently for chat," with a live preview of what the chat identity will actually look like. And chat should surface a way back into that page: a settings cog next to the "Posting as" pill in the composer.

**User feedback round 3 (also incorporated below, and it changes the defaults from earlier drafts):** every field should default to **inherited**, not independent-and-blank — "by default, people's chat profiles should follow their main profiles, unless they want something different." The one exception is `mini_profile_link_enabled`, which has no full-profile equivalent to inherit and stays off by default. Description is the one field this is in tension with — it's literally the field the motivating anecdote at the top of this doc was about ("an enormous sprawling mess of half-finished html") — but the call, made explicitly, is to default it to inherited too, and handle long descriptions in the popover with truncation or a scrollable area rather than by hiding them by default.

**User feedback round 4 (visual, once the settings page existed to react to):** the built-but-unstyled settings page from step 5 didn't match the interactive mockup's spirit closely enough — every field needed to read as its own card with a title, the inherit/override radios needed to look like the mockup's segmented "Follow profile / Set for chat" pill toggle rather than plain radio buttons, and the live preview needed to sit in a column on the right, not below the form. Getting that column enough room meant dropping this page's sidebar entirely (`Our::ChatIdentitiesController` doesn't `include OurSidebar`) — `application.html.haml` only renders the sidebar grid when `@sidebar_trees` is set, so simply not setting it was enough; no layout changes needed elsewhere.

## Direction agreed so far

- **Core privacy principle:** the chat identity is a **separate, independently maintained set of content**, not a filtered/reused view of the full profile — every field's value is under the owner's explicit, individual control, and changes to one context (chat vs. full profile) never silently affect the other. This is a different guarantee than "safe by default": round 3 (below) deliberately moves the *defaults* toward convenience, but the *mechanism* — full independence, per-field, always visible and reviewable on the settings page's live preview — is what actually delivers "no exposure you didn't choose," not the starting values.
- **Every field is independently overridable, including name — via an explicit per-field inherit/override choice, not just a blank/filled column.** Each chat-identity field (name, subtitle, pronouns, hearts, tagline, description) has its own "inherit from my main profile" vs. "set independently for chat" toggle. This is a deliberate two-mode design, not three: there's no separate "hidden" mode, because choosing "set independently" and simply leaving the override blank *is* hidden — one less concept for the owner to learn, and it composes with "omit the section if blank" (below) for free.
  - **Every field defaults to inherited (`true`), except `mini_profile_link_enabled` (`false`)** — per round 3. This replaces the round-1-derived "independent and blank unless opted in" default from earlier drafts of this plan. The reasoning: most people are fine with their chat identity matching their profile, and forcing everyone through an empty-by-default settings page before chat shows anything about them is more friction than the privacy problem warrants once the *real* mechanism for control — per-field override plus a live preview that shows exactly what's exposed — exists. Nothing is hidden from the owner's control; the settings page is where they go to see and adjust it, whenever they want, not only once at signup.
  - **Description is the deliberate exception worth flagging, not resolving away:** it defaults to inherited too, which means it's possible to ship this feature and have the exact "sprawling mess" scenario from the top of this doc show up in chat by default, for anyone who hasn't visited the settings page. The mitigation isn't a different default — it's a **UI treatment for long descriptions in the popover**: a `max-height` with `overflow-y: auto` (a scroll area, not hard truncation — nothing is cut off or silently dropped, it's just contained) on `.pop-description`/`.mini-profile-popover__description`. Chosen over truncate-with-"show more" because it needs no JS and never loses content; revisit if a scroll area inside a small popover turns out to be awkward in practice.
  - Sections are omitted entirely (no heading, no placeholder) whenever the *resolved* value (after applying inherit-or-override) is blank — same rule as before, now applied uniformly through the resolver methods described in Data model.
- **The always-visible chat message row is in scope too, not just the popover.** Today `_message.html.haml` reads `postable.name`/`postable.pronouns`/`postable.subtitle` straight off the full profile on *every* message (`app/views/chat/messages/_message.html.haml:11-19`). This plan switches those to the resolved chat-identity values (`chat_name`, `chat_pronouns`, `chat_subtitle` — see Data model) — and because every field now defaults to inherited, **this is a no-op for existing users on ship day**: `chat_pronouns`/`chat_subtitle` resolve to exactly what `pronouns`/`subtitle` already showed, until someone visits the new settings page and changes something. The round-1/round-2 drafts of this plan had an open "rollout note" here about existing users' chat identity silently going blank on ship day — that concern no longer applies with inherit-by-default, and no backfill migration is needed either (see Data model).
- **One mini-profile per Profile/Group, not per-server.** Explicitly rejected: a different mini-profile per server they're in. A single shared lightweight alternate identity, reused everywhere in chat regardless of which server.
- **Clicking a name/avatar in chat always opens the mini-profile popover now.** This supersedes the earlier "full profile vs. mini-profile" framing — there is no mode where a click still does a full-page navigation. The popover is the universal click target for names/avatars on chat messages.
  - **Scoped to messages only.** The "posting as" identity picker in the composer keeps its current full-page-link behavior for its dropdown *options* (see the composer bullet below for what does change there — the new settings cog).
- **Avatar: a separate, independently-uploadable mini-profile avatar image, with its own shape and alt text** — corrected from an earlier draft of this plan, which shared shape with the main avatar and only let the image itself be independent. It's not just the image: the whole visual presentation is independently choosable, using the same inherit-or-override shape as everything else, just expressed structurally rather than via a boolean column:
  - Stored as its own attachment (`mini_profile_avatar`), with its own alt text (`mini_profile_avatar_alt_text`) **and its own shape (`mini_profile_avatar_shape`)** — `circle`/`rounded`/`square`, same as `avatar_shape`, defaulting to `"rounded"`. Same content-type/size validation as the main avatar.
  - **Falls back to (i.e. "inherits") the full profile's avatar — image, shape, and alt text together — when no mini-profile-specific image has been uploaded.** Attachment presence *is* the inherit/override flag here, so there's no separate `mini_profile_avatar_inherited` column; uploading is "override" (bringing its own shape/alt text with it), removing is "back to inherit."
  - **The message row and the popover treat shape differently, and that's deliberate, not an inconsistency:** the message row *always* forces circle for every avatar, chat-specific or not, to keep the channel's message list visually consistent — it never looks at `mini_profile_avatar_shape` or `avatar_shape` at all. The **popover** is where "the chosen shape" actually shows: whichever avatar is in effect (overridden or inherited) renders in *its own* shape — `mini_profile_avatar_shape` if the mini-profile avatar is the one showing, `avatar_shape` if it fell back to the main one.
  - Both the popover and the always-visible message-row avatar resolve *which image* through the same fallback (one shared helper); a second helper resolves *which shape* the same way, but the message row deliberately never calls it.
- **Link at the bottom of the popover, gated by a new opt-in boolean** (default `false` — off unless the owner turns it on). This one has no full-profile equivalent to inherit from, so it stays a plain boolean, not part of the inherit/override system:
  - Owner viewing their own postable: always shows **"Edit profile"** / **"Edit group"** (links to `edit_our_profile_path`/`edit_our_group_path`), regardless of the boolean — the boolean only affects what other viewers see.
  - Other viewers, boolean **on**: shows **"View full profile"**, opens in a new tab, links to the public `profile_path`/`group_path` (uuid).
  - Other viewers, boolean **off**: no link at all — the rest of the popover still shows.
  - "Other viewers" in this app always means another logged-in plural-profiles user — there is no anonymous/logged-out viewer concept anywhere in the app today (confirmed: public share pages still require auth).
- **Ownership check reuses existing logic**: `postable.user_id == Current.user&.id`, same as `chat_postable_url` today. No multi-owner/group-membership complexity — Groups and Profiles are both strictly single-owner (`belongs_to :user`).
- **Deleted/missing postable**: if the profile/group a message references no longer exists, the name/avatar renders as a disabled, non-clickable element instead of a popover trigger. This is already the app's current behavior (`message.postable_name` fallback) — no change needed there.
- **Editing surface is a dedicated page, not a fieldset on the profile/group form.** Per round-2 feedback: a new **"Edit chat settings"** page (`Our::ChatIdentitiesController`), separate from `Our::ProfilesController`/`Our::GroupsController`, covering *all* chat-related configuration for a given postable: the existing chat proxy brackets, every mini-profile field with its inherit/override toggle, the mini-profile avatar, and the link-visibility checkbox.
  - **The chat proxy brackets field moves here too**, out of `_form.html.haml` — it's chat configuration like everything else on this page, and consolidating avoids having two different edit surfaces for chat-related settings.
  - The main profile/group edit form goes back to having no chat-related fields at all (reverting the fieldset the earlier version of this plan added there). Discoverability comes from an **"Edit chat settings" button on the profile/group *show* page**, next to the existing "Edit" button — **deliberately not on the edit form**: a link on the edit form is a way to click away from unsaved changes to that form without saving them, which is exactly the kind of accidental-data-loss trap this plan should avoid, not introduce.
- **Live preview on the settings page.** As the owner edits (typing into an override field, flipping an inherit/override toggle, picking a new avatar), a preview panel updates to show what the chat popover will actually look like — reusing the *exact same partial* the real popover renders (`chat/mini_profiles/_mini_profile`), fed with the in-progress, unsaved form state. This guarantees the preview can't drift from reality, and directly serves the "eliminate fear of unwanted exposure" goal: the owner sees precisely what a chatter will see before committing to it.
- **A settings cog next to the "Posting as" pill in the composer**, linking straight to this postable's "Edit chat settings" page (opens in a new tab, so it doesn't discard whatever the user has mid-typed in the message box — same reasoning already applied to the popover's "View full profile" link). This is the discovery path for "I'm about to post as this identity — let me check/adjust what that shows people" in the moment it's actually relevant, not just from the profile management area.
- **Reversed from an earlier draft of this plan, per direct feedback: the "Posting as" pill and every profile/group picker's option rows show the *resolved chat identity* (avatar, name, pronouns), not the real full-profile ones.** "No surprises — what you see is what you're going to share." Concretely:
  - **Avatar, name, and pronouns** switch to `chat_avatar_for`/`chat_name`/`chat_pronouns` in: the composer's "Posting as" pill and its dropdown (`_posting_as_picker.html.haml`, `_posting_as_option.html.haml`), and the generic default-postable picker reused on the server-join and per-server "default identity" settings pages (`chat/shared/_profile_picker.html.haml`, `chat/shared/_profile_picker_option.html.haml`) — same principle, same "you're choosing what chat will show" situation, just persisted as a default rather than per-message.
  - This isn't only about the picker being honest at a glance: `composer_controller.js#detectProxy` (the Tupperbox-style bracket-typing preview) and `profile_picker_controller.js#select` both work by **cloning the avatar/name/pronouns markup straight out of the matched option row** into the trigger pill. If the option rows show the real profile identity, typing chat-proxy brackets would preview the wrong (non-chat) identity in the pill — updating the option rows is what makes the *existing* JS swap mechanism correct, not just the initial page render.
  - **Subtitle and labels in the dropdown option rows are the one thing left showing the real full-profile values.** They're not shown in the trigger pill at all today, not part of the JS clone-swap above, and exist purely to help the owner tell their own profiles apart while picking — not a preview of chat output — so there's no "surprise" risk in leaving them as-is. Worth a second look if that reasoning turns out to be wrong in practice.
  - Search-by-typing in these pickers should match on **both** the real name/pronouns and the resolved chat name/pronouns (whichever the owner happens to remember), not just one.
- **Groups confirmed**: a Group's chat mini-profile/privacy works identically to a Profile's (minus pronouns/hearts, which Groups don't have anywhere, on the full profile or the mini one), consistent with `Group` already paralleling `Profile` in every other chat-relevant concern (`ChatProxyable`, `HasAvatar`). Same single-owner (`user_id`) check throughout.
- **Loading of the popover** (unchanged from the original plan): fetched on demand when it opens (lazy), not preloaded per-message. Implemented as a **Turbo Frame**, matching Rails/Hotwire conventions already used elsewhere in the app.

## Implementation plan

### Data model

Both `Profile` and `Group` get a "chat identity" column set: one override column plus one `_inherited` boolean per invertible field, matching the full-profile field it stands in for:

- `mini_profile_name` (`string`, nullable) + `mini_profile_name_inherited` (`boolean`, `default: true, null: false`).
- `mini_profile_subtitle` (`string`, nullable) + `mini_profile_subtitle_inherited` (`boolean`, `default: true, null: false`).
- `mini_profile_tag_line` (`string`, nullable) + `mini_profile_tag_line_inherited` (`boolean`, `default: true, null: false`).
- `mini_profile_description` (`text`, nullable) + `mini_profile_description_inherited` (`boolean`, `default: true, null: false`) — rendered with `formatted_description`; the popover contains it in a scrollable area rather than capping its length (see Direction).
- `mini_profile_pronouns` (`string`, nullable) + `mini_profile_pronouns_inherited` (`boolean`, `default: true, null: false`) — **Profile only**.
- `mini_profile_heart_emojis` (`jsonb`, `default: [], null: false`) + `mini_profile_heart_emojis_inherited` (`boolean`, `default: true, null: false`) — **Profile only**; the override array is normalized/validated the same way as `heart_emojis`.
- `mini_profile_avatar_alt_text` (`string`, nullable) + `mini_profile_avatar_shape` (`string`, `default: "rounded", null: false`) — both pair with the `mini_profile_avatar` attachment, both independent of `avatar_alt_text`/`avatar_shape`. No `_inherited` column for any of the three (attachment presence is the inherit/override flag, defaulting to "inherit" since nothing is attached until the owner uploads something) — image, shape, and alt text all switch together as a unit when an override is uploaded or removed.
- `mini_profile_link_enabled` (`boolean`, `default: false, null: false`) — not part of the inherit/override system (no full-profile equivalent), and the one field that stays off by default per round 3.

One migration touching both tables — **built** (see `db/migrate/*_add_chat_identity_fields_to_profiles_and_groups.rb`):

```ruby
class AddChatIdentityFieldsToProfilesAndGroups < ActiveRecord::Migration[8.1]
  def change
    add_column :profiles, :mini_profile_name, :string
    add_column :profiles, :mini_profile_name_inherited, :boolean, default: true, null: false
    add_column :profiles, :mini_profile_subtitle, :string
    add_column :profiles, :mini_profile_subtitle_inherited, :boolean, default: true, null: false
    add_column :profiles, :mini_profile_tag_line, :string
    add_column :profiles, :mini_profile_tag_line_inherited, :boolean, default: true, null: false
    add_column :profiles, :mini_profile_description, :text
    add_column :profiles, :mini_profile_description_inherited, :boolean, default: true, null: false
    add_column :profiles, :mini_profile_pronouns, :string
    add_column :profiles, :mini_profile_pronouns_inherited, :boolean, default: true, null: false
    add_column :profiles, :mini_profile_heart_emojis, :jsonb, default: [], null: false
    add_column :profiles, :mini_profile_heart_emojis_inherited, :boolean, default: true, null: false
    add_column :profiles, :mini_profile_avatar_alt_text, :string
    add_column :profiles, :mini_profile_avatar_shape, :string, default: "rounded", null: false
    add_column :profiles, :mini_profile_link_enabled, :boolean, default: false, null: false

    add_column :groups, :mini_profile_name, :string
    add_column :groups, :mini_profile_name_inherited, :boolean, default: true, null: false
    add_column :groups, :mini_profile_subtitle, :string
    add_column :groups, :mini_profile_subtitle_inherited, :boolean, default: true, null: false
    add_column :groups, :mini_profile_tag_line, :string
    add_column :groups, :mini_profile_tag_line_inherited, :boolean, default: true, null: false
    add_column :groups, :mini_profile_description, :text
    add_column :groups, :mini_profile_description_inherited, :boolean, default: true, null: false
    add_column :groups, :mini_profile_avatar_alt_text, :string
    add_column :groups, :mini_profile_avatar_shape, :string, default: "rounded", null: false
    add_column :groups, :mini_profile_link_enabled, :boolean, default: false, null: false
  end
end
```

No backfill needed — every `_inherited` flag defaults to `true` (except `mini_profile_link_enabled`), so every existing profile/group's chat identity resolves to exactly its current full-profile fields immediately, with no separate data migration required to get there.

#### Model changes

- **New concern `app/models/concerns/chat_identity.rb`**, included by both `Profile` and `Group`, providing the inherit/override resolution as `chat_<field>` reader methods, the mini-profile avatar attachment, and the two validations that go with them. **Built** — including one correction along the way, noted below:
  ```ruby
  module ChatIdentity
    extend ActiveSupport::Concern

    included do
      validate :mini_profile_name_present_when_not_inherited

      has_one_attached :mini_profile_avatar
      validate :mini_profile_avatar_is_valid
      validates :mini_profile_avatar_shape, inclusion: { in: HasAvatar::AVATAR_SHAPES }
    end

    class_methods do
      def chat_identity_field(field)
        define_method("chat_#{field}") do
          if public_send("mini_profile_#{field}_inherited?")
            public_send(field)
          else
            public_send("mini_profile_#{field}")
          end
        end
      end
    end

    private

    def mini_profile_name_present_when_not_inherited
      return if mini_profile_name_inherited?
      errors.add(:mini_profile_name, "can't be blank when not inheriting the main name") if mini_profile_name.blank?
    end

    def mini_profile_avatar_is_valid
      return unless mini_profile_avatar.attached?
      unless mini_profile_avatar.blob.content_type.in?(HasAvatar::AVATAR_CONTENT_TYPES)
        errors.add(:mini_profile_avatar, "must be a JPG/JPEG, PNG, or WebP image")
      end
      if mini_profile_avatar.blob.byte_size > HasAvatar::AVATAR_MAX_SIZE
        errors.add(:mini_profile_avatar, "must be 2 MB or less")
      end
    end
  end
  ```
  `Profile` then declares `include ChatIdentity` plus `chat_identity_field :name`, `:subtitle`, `:tag_line`, `:description`, `:pronouns`, `:heart_emojis`. `Group` declares the same minus `:pronouns`/`:heart_emojis` (it has neither the main nor the mini column). The macro works unmodified for the `heart_emojis` array case — `blank?` on `[]` is `true`, so "omit if blank" downstream needs no special-casing.
  - Because the default is `mini_profile_name_inherited: true`, this validation never fires for existing records or for saves coming from the main profile/group form — it only matters once an owner explicitly switches name to "set independently" on the new chat settings page and leaves it blank.
  - **Correction made while building this**: `mini_profile_avatar` was originally put in `HasAvatar` instead (generalizing its validations to run against both `avatar` and `mini_profile_avatar`). That broke `Chat::Server`, which also includes `HasAvatar` but isn't a postable and was never meant to have a chat identity or a `mini_profile_avatar_shape` column — every server-related test failed with a missing-method error the moment that shipped. Moving the mini-profile-avatar bits into `ChatIdentity` (Profile/Group only) fixed it. **`HasAvatar` itself ended up completely unchanged by this feature** — still just `avatar`/`avatar_shape`, exactly as it was before this plan.
- **`Profile`**: mirror the existing `heart_emojis=` normalization and `heart_emojis_are_valid` validation for `mini_profile_heart_emojis` — same `resolve_heart_emoji` logic, same "contains invalid hearts" error, since it's the same free-form array-of-strings shape.
- **New helpers** (`app/helpers/application_helper.rb`, next to `avatar_shape_class`) — the avatar's inherit/override resolution, split into "which image" and "which shape" so callers that force a shape (the message row) can use the first without the second:
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

  # Only the popover should call this — the message row always forces circle
  # instead, regardless of either shape column (see Direction).
  def chat_avatar_shape_for(postable)
    postable.mini_profile_avatar.attached? ? postable.mini_profile_avatar_shape : postable.avatar_shape
  end
  ```

### Backend

- **`Our::ProfilesController`/`Our::GroupsController` lose the chat fields entirely. Built** (step 3): removed `:chat_bracket_before, :chat_bracket_after` from `profile_params`/`group_params` — nothing else about these controllers changed.
- **New route block. Built** (step 5), alongside the existing `our_profiles`/`our_groups` resources in `config/routes.rb`:
  ```ruby
  get "our/chat_identity/:postable_type/:postable_uuid/edit", to: "our/chat_identities#edit",
    as: :edit_our_chat_identity, constraints: { postable_type: /Profile|Group/ }
  patch "our/chat_identity/:postable_type/:postable_uuid", to: "our/chat_identities#update",
    as: :our_chat_identity, constraints: { postable_type: /Profile|Group/ }
  post "our/chat_identity/:postable_type/:postable_uuid/preview", to: "our/chat_identities#preview",
    as: :preview_our_chat_identity, constraints: { postable_type: /Profile|Group/ }
  ```
  Same `postable_type` + `postable_uuid` shape as the chat-subdomain mini-profile route, for the same reason (uuid uniqueness is only per-table).
- **New controller `app/controllers/our/chat_identities_controller.rb`. Built** (step 5), mirroring `Chat::MiniProfilesController`'s `POSTABLE_TYPES` pattern but scoping through `Current.user` (like `Our::ProfilesController`/`Our::GroupsController` do) rather than an unscoped `find_by!`, since this is a private editing surface, not a shareable link. `include OurSidebar` for the same nav chrome as `Our::ProfilesController`/`Our::GroupsController`; nothing else the original plan didn't already have, beyond the `update`/failed-validation avatar cleanup already established by `Our::ProfilesController#update` and `mini_profile_avatar_shape` joining the permitted list alongside `mini_profile_avatar_alt_text`:
  ```ruby
  class Our::ChatIdentitiesController < ApplicationController
    include OurSidebar

    POSTABLE_TYPES = { "Profile" => :profiles, "Group" => :groups }.freeze

    before_action :set_postable

    def edit
    end

    def update
      @postable.mini_profile_avatar.purge if params[:chat_identity][:remove_mini_profile_avatar] == "1"
      if @postable.update(chat_identity_params)
        redirect_to edit_our_chat_identity_path(@postable.class.name, @postable.uuid), notice: "Chat settings updated."
      else
        if params.dig(:chat_identity, :mini_profile_avatar).present?
          @postable.mini_profile_avatar.blob&.persisted? ? @postable.mini_profile_avatar.purge_later : @postable.mini_profile_avatar.detach
        end
        render :edit, status: :unprocessable_entity
      end
    end

    # Renders the same preview-panel partial the edit page's initial render
    # uses (message-row mockup + the real popover partial), against an
    # unsaved in-memory copy of the postable with the current form's
    # values applied — never persisted, purely for the live preview panel.
    def preview
      @postable.assign_attributes(chat_identity_params)
      render partial: "our/chat_identities/preview_panel", locals: { postable: @postable }, layout: false
    end

    private

    def set_postable
      association = POSTABLE_TYPES.fetch(params[:postable_type]) { raise ActiveRecord::RecordNotFound }
      @postable = Current.user.public_send(association).find_by!(uuid: params[:postable_uuid])
    end

    def chat_identity_params
      shared = %i[chat_bracket_before chat_bracket_after
                  mini_profile_name mini_profile_name_inherited
                  mini_profile_subtitle mini_profile_subtitle_inherited
                  mini_profile_tag_line mini_profile_tag_line_inherited
                  mini_profile_description mini_profile_description_inherited
                  mini_profile_avatar mini_profile_avatar_alt_text mini_profile_avatar_shape
                  mini_profile_link_enabled]
      profile_only = %i[mini_profile_pronouns mini_profile_pronouns_inherited
                         mini_profile_heart_emojis_inherited]
      permitted = @postable.is_a?(Profile) ? shared + profile_only : shared
      params.require(:chat_identity).permit(*permitted, mini_profile_heart_emojis: []).tap do |p|
        p[:mini_profile_heart_emojis] = p[:mini_profile_heart_emojis].reject(&:blank?) if p.key?(:mini_profile_heart_emojis)
      end
    end
  end
  ```
  `preview` deliberately reuses `chat_identity_params` (the same permitted list as `update`) rather than a separate whitelist, so the preview can never reflect a field the form isn't allowed to change anyway. The `reject(&:blank?)` mirrors `Our::ProfilesController#profile_params`'s handling of `heart_emojis` — needed because the hearts checkbox grid submits a `hidden_field_tag "...[]", ""` sentinel so the param key exists even when nothing's checked.
- **Views. Built** (step 5): `app/views/our/chat_identities/edit.html.haml` (the new page — see Frontend), no `show`/`new`/`destroy`, this is a single always-existing settings surface per postable (a `Profile`/`Group` always has these columns, just possibly all-default).
- **Chat popover controller/route — still not built.** `Chat::MiniProfilesController#show` at the existing `constraints subdomain: "chat"` route, `@postable`/`@own` resolution unchanged (step 7).
- **Popover partial `app/views/chat/mini_profiles/_mini_profile.html.haml`. Built** (pulled forward into step 5 — see Order of implementation), reading exclusively through the `chat_*` resolver methods (this is what makes it safely reusable for both the real popover and the settings-page preview, since both just need "a postable" and don't care whether it's persisted):
  - Avatar via `chat_avatar_for(postable)` / `chat_avatar_alt_text_for(postable)`, in **the chosen shape**: `avatar_shape_class(postable, shape: chat_avatar_shape_for(postable))` — whichever avatar is actually showing (overridden or inherited) renders in its own shape, not a forced one. This is the one place in chat that shows a non-circle shape at all (the message row keeps forcing `shape: "circle"`, this partial deliberately doesn't).
  - Name (`formatted_inline(postable.chat_name)`), `postable.chat_subtitle` if present.
  - `postable.chat_pronouns` and `postable.chat_heart_emojis`, guarded by `postable.respond_to?(:chat_pronouns)` / `respond_to?(:chat_heart_emojis)` (same technique already used in `_message.html.haml`) since `Group` doesn't define them. Hearts rendered as `.heart-display__grid` / `.heart-display__heart` as in `profiles/show.html.haml`.
  - `postable.chat_tag_line` if present.
  - `postable.chat_description`, via `formatted_description(...)`, wrapped in `.profile-description` (not just a bespoke class — needed so the existing spoiler/table/floated-image formatting rules that `formatted_description` output depends on actually apply here too) plus `.mini-profile__description` for the scroll-cap. Section omitted entirely when blank, otherwise **built**: `.mini-profile__description { max-height: 12rem; overflow-y: auto; }` rather than length-capped — see Direction on why a long inherited description shouldn't be silently truncated.
  - Link at the bottom (unchanged from the original plan): `@own`/`local_assigns[:own]` → edit link; not own and `mini_profile_link_enabled?` → "View full profile"; otherwise no link. (The `own:` local passed as `true` from the settings-page preview always renders the edit-link branch, which is correct — you're always looking at your own preview there.)

### Frontend

- **`_message.html.haml`** (`app/views/chat/messages/_message.html.haml`):
  - Avatar block: `chat_avatar_for(message.postable)` / `chat_avatar_alt_text_for(message.postable)` instead of `message.postable.avatar`, keeping the forced-circle shape (`avatar_shape_class(message.postable, shape: "circle")`, unchanged) — deliberately **not** `chat_avatar_shape_for`, so every message in the channel stays visually consistent regardless of what shape either avatar is configured with.
  - Name: `formatted_inline(message.postable.chat_name)` instead of `.name`.
  - Pronouns: `message.postable.respond_to?(:chat_pronouns) && message.postable.chat_pronouns.present?`, rendering `chat_pronouns`.
  - Subtitle: `message.postable&.chat_subtitle&.present?`, rendering `chat_subtitle`.
  - Replace the `link_to chat_postable_url(...)` wrapper around the name (and extend it to the avatar) with a click trigger controlled by a new Stimulus controller (below). The existing `- else` branch (postable deleted → plain `"#{message.postable_name} (deleted)"` text, no link) is already exactly the "disabled state" wanted for deleted postables — **no change needed there**.
- **New Stimulus controller** `app/javascript/controllers/mini_profile_popover_controller.js`:
  - Values: `{ url: String }` (the `chat_mini_profile_path(...)` route for this message's postable).
  - Targets: `trigger` (avatar + name wrapper), `frame` (the empty `turbo-frame` placeholder, `src` unset initially so it never fetches until asked), `panel` (a wrapper element using the native `popover` attribute).
  - On trigger click: if `frame.src` isn't set yet, set it to the `url` value (fires the Turbo fetch exactly once per message); position `panel` near the trigger's `getBoundingClientRect()`; call `panel.showPopover()`.
  - Uses the HTML **Popover API** (`popover="auto"`) rather than the `<dialog>` pattern used by `avatar_editor_controller.js` — deliberate, not an inconsistency: `popover="auto"` gets outside-click/Escape light-dismiss for free. First use of the Popover API in the codebase, and the first on-demand-fetch UI pattern anywhere in the app, so allow some extra care/review time.
- **New partial-backed styles**: `.mini-profile-popover` styling (positioned via inline styles set by the controller, visually similar to the existing `.card`/`.profile-card` treatment) — still left to implementation (needs step 9's controller to position it). The *content* styling it'll wrap — `.mini-profile`, `.mini-profile__header`, `.mini-profile__name`, `.mini-profile__description` (with the scroll-cap treatment from Direction: `max-height` + `overflow-y: auto`), `.mini-profile__link` — **is built** (see the settings-page preview below, which renders the exact same `_mini_profile` partial and needed this styling regardless of whether the popover itself exists yet).
- **Avatar editor needs to support editing a second, independent avatar — shape picker included. Built** (`app/views/shared/_avatar_editor_dialog.html.haml`). To be clear about *why*: the main avatar dialog (`attribute: "avatar"`, default) and the chat avatar dialog (`attribute: "mini_profile_avatar"`) never appear together — the main one stays on the profile/group edit form, the chat one lives only on the new, separate "Edit chat settings" page (per round 2). They don't share a page or a form. The reason the partial still needed parameterizing is simpler: it's the *same reusable partial*, rendered once per page, and each rendering now needs to point at a different attachment/shape/alt-text trio depending on which page it's on — not because two instances coexist anywhere.
  - Took a new optional `attribute:` local (default `"avatar"`), and every hardcoded `avatar`/`avatar_shape`/`avatar_alt_text` reference in the partial now derives from it (`record.public_send(attribute)`, `"#{attribute}_shape"`, `"#{attribute}_alt_text"`), including the remove checkbox's param name (`"#{param_prefix}[remove_#{attribute}]"`). All three existing callers (profile/group/chat-server forms) needed no changes — the new local defaults to the old hardcoded behavior.
  - **`avatar_editor_controller.js` needed zero changes**, which wasn't obvious going in: it never references an attribute name anywhere, only Stimulus targets and CSS classes. That also means the "two instances would be scoped independently" reasoning from the original draft of this plan was correct but moot in practice — it was never exercised, since the two dialogs are one-per-page, not two-per-page. The plan originally expected the JS to need updating too; it didn't.
  - **Built as `fallback_attachment`/`fallback_shape`/`fallback_alt_text` locals** (renamed from the "effective avatar" framing above, for symmetry with the caller's existing `chat_avatar_for`/`chat_avatar_shape_for`/`chat_avatar_alt_text_for` helper names): the mini-profile instance's "current" and dialog preview both show the fallback image/shape/alt-text when `mini_profile_avatar` itself isn't attached, so the form doesn't show an empty state for someone whose main avatar will be used anyway — but "Remove" only appears once an actual `mini_profile_avatar` is attached (removing it reverts to inheriting the main avatar, doesn't touch the main avatar itself), and the "Add"/"Edit" button copy is likewise always about `mini_profile_avatar` itself, never the fallback.
- **New "Edit chat settings" page. Built** (`app/views/our/chat_identities/edit.html.haml`, step 5, restyled per round 4): one `form_with model: @postable, scope: :chat_identity, url: our_chat_identity_path(...)` (see Backend for why `scope:` is needed alongside `model:`), no sidebar (see round 4), laid out as `.chat-identity-layout` — a two-column grid (`1fr 380px`), form on the left, sticky preview on the right, stacking to one column under 900px — containing:
  - Chat proxy brackets and the chat avatar editor, each its own `.card` (moved here unchanged from `_form.html.haml`, plus the mini-profile avatar editor with the `fallback_*` locals above).
  - For each of name/subtitle/pronouns(Profile)/tagline/description: its own `.card.chat-identity-field`, title + a segmented **"Follow profile" / "Set for chat" pill toggle** in the card header (`.chat-identity-toggle`, styled with the same visually-hidden-radio-plus-adjacent-label `:checked +` pattern already used by `.avatar-shape-picker` elsewhere in this codebase — not a new technique, just reapplied), with the live full-profile value shown in a tinted `.chat-identity-field__inherited` panel below so the owner can see what they're inheriting without leaving the page. Factored into `_field_toggle.html.haml`, using `role="group"`/`aria-labelledby` rather than `<fieldset>`/`<legend>` — a real `<legend>` can't sit inline next to the toggle the card-header layout needs, but this keeps equivalent "these radios belong to this label" semantics for assistive tech. **Still not conditionally shown/hidden** — that's step 6; both the "currently on your profile" and override blocks render unconditionally for now, so the page stays fully usable (if busier-looking than the mockup) before the JS lands.
  - Hearts, same card treatment, hand-written rather than routed through `_field_toggle` since it's a checkbox grid (the existing `heart-picker` Stimulus component, parameterized to `chat_identity[mini_profile_heart_emojis][]`), not a single input.
  - `mini_profile_link_enabled` checkbox, its own `.card`, with a hint explaining it controls whether other viewers get a "View full profile"/"Edit ..." link from the popover — off by default.
  - A live preview column with **two stacked blocks**, matching the mockup: "In a message" (a hand-built, illustrative chat-message-row mockup — not tied to any real `Chat::Message`, just `chat_name`/`chat_pronouns`/`chat_subtitle`/`chat_avatar_for` dressed in the real `.chat-message*` CSS classes so it looks exactly like a real one, forcing circle shape same as the real message row does) and "In the popover" (the real `_mini_profile` partial, `chosen` shape and all). Both blocks live in one new partial, `our/chat_identities/_preview_panel.html.haml`, rendered both by this page (initial state) and by `Our::ChatIdentitiesController#preview` (unsaved form state) — one source of truth, so step 6's live-preview fetch will already return markup matching what's on the page. **Currently a static server-rendered snapshot**, correct as of page load, not yet reactive — that's step 6, which the panel is already wired for via `data: {"chat-identity-form-target": "preview"}` (Stimulus silently no-ops on an unregistered controller name, so this was safe to add ahead of the JS existing).
  - A one-line explanation at the top of the page, now inside a `.chat-identity-intro` card with an icon: "This is what people see in chat when [name] posts — independent from the full profile page. Nothing here is filled in automatically except the name." (kept name-and-pronoun-neutral so the identical copy reads correctly for both a Profile and a Group.)
  - A small breadcrumb (`← name`) and an uppercase "Profile · chat settings" / "Group · chat settings" eyebrow badge above the `<h1>`, matching the mockup.
  - New CSS custom properties `--chat-accent-bg`/`--chat-accent-border`/`--chat-accent-text` in `:root` — same hex values as `--warning-*` (a deliberate choice, not a coincidence: the warm rose reads well for "you changed this from the default," and matches the app's existing palette), but under their own name. Aliasing directly to `--warning-*` would have tied a neutral settings badge and an active toggle state to the app's actual warning/flash semantics, which isn't what either of them means.
- **New Stimulus controller** `app/javascript/controllers/chat_identity_form_controller.js` — **not yet built (step 6)**. The form already has `data: {controller: "chat-identity-form", "chat-identity-form-preview-url-value": preview_our_chat_identity_path(...)}` on it, and the preview panel already carries the `preview` target — Stimulus silently no-ops on an unregistered controller name, so this was safe to wire up in the HTML ahead of the JS existing. Scoped to the whole edit form:
  - Handles the inherit/override radio pairs: toggling one shows/hides (and enables/disables, so hidden inputs don't submit stale values into the wrong mode) the corresponding override field.
  - Debounced (e.g. ~350ms) live preview: on any `input`/`change` inside the form, `fetch(previewUrlValue, { method: "POST", body: new FormData(formTarget) })` including the Rails CSRF header, then swap the preview panel's contents with the returned HTML (a plain partial render, not a Turbo Stream/Frame — this is unsaved, repeatedly-changing form state being posted on every keystroke, which doesn't fit the GET-based, cacheable-URL model Turbo Frames are for; a direct Stimulus fetch is the right tool here, unlike the popover above).
  - This is the second new client-side pattern this plan introduces (after the popover's `popover="auto"`), so also worth a little extra review care — in particular, re-submitting a `<input type="file">`'s selected file on every unrelated keystroke (because it's all one `FormData`) is wasteful; consider only including the file in the preview request when the file input itself last changed, or accept the (small, localhost, in-memory) cost since avatar files are capped at 2MB.
- **Main profile/group edit form. Built** (step 3): `_form.html.haml`/`_form.html.haml` (groups) dropped the "Chat proxy brackets" `.form-group`, full stop — no replacement link on the edit form itself (see below for where the entry point actually went).
- **Discoverability corrected after the fact: an "Edit chat settings" button on the *show* page, not a link on the edit form. Built** (step 4a, revised): `app/views/our/profiles/show.html.haml` and `app/views/our/groups/show.html.haml` each gained `link_to "Edit chat settings", edit_our_chat_identity_path(@profile.class.name, @profile.uuid), class: "btn btn--secondary"` in `.profile-actions`, right next to the existing "Edit" button. The original plan put this link on the *edit form* instead — wrong on reflection: a link on a form you might have unsaved changes in is an invitation to click away and lose them, which is precisely the kind of accidental loss this whole feature is trying to protect people from elsewhere (the composer cog opens in a new tab for exactly this reason). The show page has no such risk — it's read-only — so that's where the entry point belongs.
- **Composer cog** (`app/views/chat/channels/_posting_as_picker.html.haml` + `show.html.haml`):
  - The turbo-stream-replace target id (`posting-as-picker`) moves from the `%details` element up to a new wrapping element that contains both the existing `%details.action-dropdown...` (now without the id) and a new cog link, so `Chat::ChannelDefaultPostablesController#update`'s existing `turbo_stream.replace("posting-as-picker", ...)` keeps working unmodified and the cog's target postable stays in sync whenever the picker switches identity:
    ```haml
    .composer-posting-as-row#posting-as-picker
      %details.action-dropdown.profile-picker.composer-posting-as{data: {controller: "dropdown"}}
        ...  -# unchanged internals
      = link_to edit_our_chat_identity_path(current_postable.class.name, current_postable.uuid),
                class: "posting-as-settings-cog", target: "_blank", rel: "noopener",
                "aria-label": "Edit chat settings for #{plain_field(current_postable.name)}", title: "Chat settings" do
        = render "shared/icons/cog"
    ```
  - New `shared/icons/cog` partial (inline SVG) if one doesn't already exist — left to implementation.
- **Every "which of my profiles/groups do I post as" picker shows the resolved chat identity, not the real one** (see Direction — this reverses what an earlier draft of this plan had marked "deliberately unchanged"). Four view files, all narrow, mechanical edits:
  - `app/views/chat/channels/_posting_as_picker.html.haml`: `current_pronouns = current_postable.respond_to?(:chat_pronouns) ? current_postable.chat_pronouns : nil`; trigger name becomes `formatted_inline(current_postable.chat_name)`.
  - `app/views/chat/channels/_posting_as_option.html.haml`: `pronouns = postable.respond_to?(:chat_pronouns) ? postable.chat_pronouns : nil`; option name becomes `formatted_inline(postable.chat_name)`; `search_text` indexes **both** forms so typing either the real name or the chat name filters correctly: `[postable.name, postable.chat_name, pronouns, postable.respond_to?(:pronouns) ? postable.pronouns : nil, postable.subtitle, postable.labels.join(" ")].compact.join(" ")`.
  - `app/views/chat/shared/_profile_picker.html.haml` and `app/views/chat/shared/_profile_picker_option.html.haml` — the generic default-postable picker reused on the server-join and per-server default-identity settings pages — get the identical name/pronouns/search_text treatment. Same principle applies: picking a default identity there is still "choosing what chat will show," just persisted rather than per-message.
  - **Subtitle and labels in the option rows are left showing the real full-profile values, deliberately** — they're not shown in the trigger pill and aren't part of the JS clone-swap below, so they're pure picker metadata for the owner's own recognition, not a preview of chat output.
  - **Avatar doesn't need per-file changes**: all four files already render the avatar via `render "chat/shared/avatar", record: postable, ...`. Update that one shared partial (`app/views/chat/shared/_avatar.html.haml`) instead, guarded so it only affects postables, not the `Chat::Server` records it's also used for (`_invite_card.html.haml`, `servers/index.html.haml`):
    ```haml
    - is_postable = record.respond_to?(:mini_profile_avatar)
    - avatar = is_postable ? chat_avatar_for(record) : record.avatar
    - shape = shape_override || (is_postable ? chat_avatar_shape_for(record) : record.avatar_shape)
    - if avatar.attached?
      = image_tag avatar.variant(resize_to_fill: [size, size]), class: "avatar #{avatar_shape_class(record, shape: shape)}".strip, width: size, height: size, alt: "", loading: "lazy"
    - else
      ...  -# placeholder branch unchanged
    ```
    `is_postable` is `true` for `Profile`/`Group` (once `HasAvatar` gets the new attachment) and `false` for `Chat::Server`, so this one guarded change fixes the composer pill, both option-row partials, and the generic picker's trigger all at once — no other avatar call site needs touching. Every current caller here passes `shape: "circle"` explicitly (`shape_override` is always set), so `chat_avatar_shape_for` is never actually reached in practice today — it's included for correctness in case a future caller doesn't force a shape, not because it changes current behavior.
  - **Why this matters beyond the picker looking right**: `app/javascript/controllers/composer_controller.js#detectProxy` (the live bracket-typing preview) and `app/javascript/controllers/profile_picker_controller.js#select` both work by cloning the `.avatar`/`.profile-picker__option-name`/`.profile-picker__option-pronouns` elements straight out of the matched option row into the trigger — no JS changes needed there, but it's *why* fixing the option-row partials is what actually makes those existing swap mechanisms show the right identity, not just the initial page render.

### Order of implementation

1. **Built.** Migration: add the new columns to `profiles` and `groups`; run `bin/rails db:migrate`.
2. **Built.** `ChatIdentity` concern (resolver methods, name-presence validation, and — corrected from the original plan — the `mini_profile_avatar` attachment + its validations, which belong here rather than in `HasAvatar` since `Chat::Server` also includes `HasAvatar` and isn't a postable); `Profile`'s `mini_profile_heart_emojis` normalization/validation; `chat_avatar_for`/`chat_avatar_alt_text_for`/`chat_avatar_shape_for` helpers.
3. **Built.** Remove chat-bracket fields from `Our::ProfilesController#profile_params`/`Our::GroupsController#group_params` and from `_form.html.haml`.
4. **Built.** Parameterize `shared/avatar_editor_dialog` to support rendering it once per page against either `avatar` or `mini_profile_avatar` (the two never appear on the same page — see Direction). `avatar_editor_controller.js` needed no changes.
4a. **Built** (once step 5's route existed to link to) — **and relocated after an initial mistake**: an "Edit chat settings" button next to "Edit" on `our/profiles/show.html.haml`/`our/groups/show.html.haml`, not a link on the edit form (see Frontend for why: a link on a form invites clicking away from unsaved changes without saving).
5. **Built**, with one thing pulled forward from step 7 and one enhancement beyond the original spec — both noted below. New route block + `Our::ChatIdentitiesController` (`edit`/`update`/`preview`) + `edit.html.haml`.
   - **Pulled forward from step 7**: the `chat/mini_profiles/_mini_profile.html.haml` partial. `preview` genuinely can't work without it — it's what preview renders — so building it as a standalone step 7 deliverable *after* step 5 was never actually orderable; it had to come with step 5. `Chat::MiniProfilesController` itself, its route, the Turbo Frame view, and `mini_profile_frame_id` (i.e. the rest of step 7 — wiring the partial up to the real chat popover) are still not built.
   - **`form_with model: @postable, scope: :chat_identity, url: ...`**: `scope:` overrides the param key Rails would otherwise derive from the model class (`profile`/`group`) without needing a fake unpersisted model — field values/errors still come from `@postable`, but everything submits under `chat_identity[...]`, matching `chat_identity_params`.
   - **Enhancement beyond the original spec, needed to make the plan's own "shows the effective avatar... so the form doesn't show an empty state" requirement actually true**: `shared/avatar_editor_dialog` gained three more optional locals — `fallback_attachment`/`fallback_shape`/`fallback_alt_text` — shown in place of the empty placeholder when `attribute` itself isn't attached. The chat-settings page passes `chat_avatar_for(@postable)`/`chat_avatar_shape_for(@postable)`/`chat_avatar_alt_text_for(@postable)` for these, so the dialog previews the *actual effective* chat avatar (inherited main avatar, until overridden) rather than a blank state — while the "Edit"/"Add" button copy and the "Remove" checkbox still key off `attribute` itself, not the fallback, so they're never wrong about what would actually be removed. The other three callers (profile/group/chat-server forms) don't pass these locals and are unaffected.
   - **The inherit/override radio toggles don't yet show/hide their corresponding content** — that's step 6's job. Rather than hide the override input behind a `hidden` attribute with no JS yet to reveal it (which would make switching modes literally impossible until step 6 shipped), both the "currently on your profile" and "set independently" blocks are unconditionally visible for now. Less tidy, but fully functional end to end — switching a radio and typing into the override field, then saving, already works correctly; step 6 makes it show/hide instead of both-at-once.
   - `_field_toggle.html.haml` (new, `app/views/our/chat_identities/`) factors the repeated inherit/override structure out of the five text-ish fields (name/subtitle/pronouns/tag_line/description); hearts, being a checkbox grid rather than a single input, is hand-written inline instead of forced through it.
6. `chat_identity_form_controller.js` (inherit/override toggling + debounced preview fetch). This app auto-registers every `*_controller.js` file in `app/javascript/controllers/` via `eagerLoadControllersFrom` (see `app/javascript/controllers/index.js`) — there's no manual registration step here or in step 9, unlike what earlier drafts of this plan assumed.
7. `Chat::MiniProfilesController` + its route + `show.html.haml`'s Turbo Frame wrapper + the `mini_profile_frame_id` helper (the `_mini_profile` partial itself already exists, see step 5).
8. Update `_message.html.haml`: switch avatar/name/pronouns/subtitle to the `chat_*` resolvers, and wrap avatar+name in the new trigger markup + empty `turbo-frame` placeholder.
9. `mini_profile_popover_controller.js` (auto-registered, same as step 6).
10. Composer cog: restructure `_posting_as_picker.html.haml`'s wrapper id, add the cog link + icon partial.
11. Switch every profile/group picker to the resolved chat identity: guard `chat/shared/_avatar.html.haml` on `respond_to?(:mini_profile_avatar)`; update name/pronouns/search_text in `_posting_as_picker.html.haml`, `_posting_as_option.html.haml`, `chat/shared/_profile_picker.html.haml`, `chat/shared/_profile_picker_option.html.haml`.
12. **Settings-page half built out of order, prompted by round-4 feedback once the page existed to react to** — toggle pairs, field cards, two-column layout, preview panel/`.mini-profile` styling, new `--chat-accent-*` tokens. Still pending: the actual chat popover's positioning CSS (needs step 9's controller) and the composer cog icon (step 10).
13. Tests (see below).
14. Manual verification in a running dev server.

### Tests

- `test/models/profile_test.rb` / `group_test.rb`: `chat_name`/`chat_subtitle`/etc. resolve to the main field when `_inherited` is true and to the mini field when false; `mini_profile_name` presence is required (and validated) only when `mini_profile_name_inherited` is false; invalid `mini_profile_heart_emojis` entries fail validation the same way invalid `heart_emojis` entries do.
- **Built**: `test/controllers/our/chat_identities_controller_test.rb` (15 tests):
  - `edit`/`update` are scoped to `Current.user`'s own profiles/groups — another user's uuid 404s; unauthenticated `edit` redirects to sign-in; an invalid `postable_type` 404s (tested by hand-building the URL, since the route's own `constraints:` makes the path *helper* raise `UrlGenerationError` for that case instead — the constraint itself is what's actually under test, not the controller's redundant `POSTABLE_TYPES.fetch` fallback);
  - `update` persists `mini_profile_subtitle`/`chat_bracket_before`/pronouns/`mini_profile_heart_emojis` independently of the corresponding full-profile fields (updating one doesn't touch the other), rejects a blank name once set to not-inherited, and silently ignores pronouns/hearts params posted for a Group;
  - `mini_profile_avatar` upload/remove: uploading attaches it without touching `avatar`; `remove_mini_profile_avatar=1` purges it without touching `avatar`;
  - `preview` renders the mini-profile partial reflecting unsaved form values without persisting anything, and always shows the owner's edit link (since the settings-page preview is always your own).
  - (A fresh profile/group's defaults — `mini_profile_name_inherited: true` and every other `_inherited` flag also `true` except `mini_profile_link_enabled` — are covered in `test/models/profile_test.rb`/`group_test.rb`, not here; see Direction/Data model for why every field defaults to inherited.)
- Extend/replace the earlier plan's controller test for the popover (`test/controllers/chat/mini_profiles_controller_test.rb`), now asserting content comes from the resolved `chat_*` values — e.g. a profile with a full-profile `pronouns` set, `mini_profile_pronouns_inherited: false`, and a blank `mini_profile_pronouns` override shows no pronouns in the popover even though the full profile has some; the same profile with `mini_profile_pronouns_inherited: true` shows the full-profile value. Same coverage as the original plan otherwise (owner-vs-viewer link behavior, blank sections omitted, avatar fallback, 404s, auth) — plus: the popover renders `mini_profile_avatar_shape` when a `mini_profile_avatar` is attached, and `avatar_shape` when it isn't, even when the two shapes differ from each other.
- `test/models/profile_test.rb`/`group_test.rb`/`test/helpers/application_helper_test.rb` — already covered as part of step 2's model/concern work: `chat_avatar_shape_for` resolves independently of `chat_avatar_for`'s image (a `mini_profile_avatar_shape` of `"circle"` shows even when the fallback `avatar_shape` is `"square"`, and vice versa once an override is attached), and `mini_profile_avatar_shape` is validated against `AVATAR_SHAPES` the same way `avatar_shape` is.
- Extend `test/system/chat_messaging_test.rb` (or a new `test/system/chat_mini_profile_test.rb`):
  - click a message's name/avatar opens the popover with expected resolved fields;
  - a message row shows resolved `chat_pronouns`/`chat_subtitle` (not the full-profile values when overridden) and shows nothing when the resolved value is blank;
  - **the "Posting as" pill and its dropdown show the resolved chat identity**: a profile with `mini_profile_name_inherited: false` and a custom `mini_profile_name`/`mini_profile_pronouns` shows those (not the real name/pronouns) in both the trigger pill and its own row in the dropdown; picking that profile in the dropdown swaps the trigger to the chat identity, not the real one; typing a matching chat-proxy bracket prefix (`composer_controller.js#detectProxy`) previews the chat identity in the pill too;
  - the generic default-postable picker (server join / per-server default identity settings) shows the same resolved values;
  - searching the picker by either the real name or the chat name finds the right option;
  - a deleted postable's message renders inert text with no popover trigger.
- New `test/system/chat_identity_settings_test.rb`: visiting "Edit chat settings," toggling a field from inherit to independent reveals its input and updates the live preview; saving persists; the composer's settings cog navigates to the right postable's page.

### Verification

- `bin/rails db:migrate`, `bin/rails test`, `bin/rails test:system` (targeted at the new/updated files).
- Manual: run the dev server, open a chat channel as two different users. Confirm:
  - clicking your own message's name shows "Edit profile"/"Edit group"; clicking another user's message shows no link by default; toggling the checkbox on in "Edit chat settings" makes "View full profile" (new tab) appear for the other viewer;
  - a profile with full-profile pronouns/subtitle/hearts/tagline/description set, and every mini-profile field left at its default, shows **all of that in chat, matching the full profile exactly** — inherit-by-default means nothing needs to be set up before chat looks right;
  - switching a field to "Set independently" and leaving it blank hides that field from chat, without touching the full profile; typing something into it shows only that in chat, regardless of what the full profile says; switching back to "Inherit from my profile" makes it track the full profile live again (edit the full profile's subtitle, watch it update in chat without touching the chat settings page);
  - a long inherited description shows in full inside a scrolling area in the popover, rather than being cut off;
  - the live preview on the settings page updates as fields are edited, before saving;
  - uploading a mini-profile-specific avatar changes the chat avatar (message row + popover + preview) without changing the full profile's avatar; removing it reverts chat to inheriting the main avatar;
  - giving the mini-profile avatar a different shape than the main avatar shows that shape in the popover, but the message row still renders every avatar as a circle regardless;
  - the settings cog next to "Posting as" opens the correct postable's settings page in a new tab, and updates which postable it points to when the picker switches identity;
  - overriding a profile's name/pronouns for chat changes what the "Posting as" pill and its dropdown show for that profile too — not just the message row and popover — including the live bracket-typing preview while composing;
  - a blank resolved description/subtitle/tagline each show no empty section;
  - a message from a deleted profile/group still renders as inert "(deleted)" text with no popover.

### Explicitly out of scope for this pass

- Subtitle and labels shown in the picker option rows stay as the real full-profile values — not part of the "no surprises" resolved-identity treatment, since they're not shown in the trigger pill or posted messages (see Direction).
- No `pp!` chat-command surface for toggling/editing this (per `docs/plan-chat-commands.md`, still just an idea).
- No per-server override of any chat-identity field — it's profile/group-level only, everywhere.
- No bulk "reset everything to inherit" / "hide everything" shortcut on the settings page — each field's toggle is set individually. Worth revisiting if the per-field toggling turns out to be tedious in practice, but not scoped now.
- No hard character cap or "show more" truncation for a long inherited description in the popover — a scroll area was chosen instead (see Direction); revisit only if that reads badly in practice.

## Depends on / relates to

- `plan-chat-servers.md` — `chat_postable_url`, message rendering, postable resolution.
- `plan-chat-commands.md` — possible future command(s) for toggling visibility / editing mini-profile content (out of scope for this pass).
- `plan-avatar-editor-popup.md` — the existing avatar editor dialog/Stimulus controller this plan needs to parameterize for a second, independent avatar.

## Mockup

[Edit chat settings — mockup](https://claude.ai/code/artifact/d36411ea-1c13-4479-9ff7-2b13a8ca0406) — interactive mockup of the settings page: per-field inherit/override toggles (name/subtitle/pronouns/hearts/tagline/description), avatar upload with fallback, and a live preview of both the chat message row and the popover. Static colors for now — the real implementation should follow the app's theme.
