# Plan: Chat Mini-Profiles / Privacy

## Status

Drilled through edge cases; direction is settled on the questions below. Still needs an implementation pass (new endpoint, Stimulus/Turbo Frame plumbing, migration, form/view changes) before it's built.

## Background

Today, clicking a name in chat (`chat_postable_url`, in `app/views/chat/messages/_message.html.haml` and the posting-as picker) always navigates to the postable's full profile/group page. There is no visibility/privacy flag on `Profile`/`Group` at all — access is "unguessable UUID," not public/private (confirmed: no such column exists today).

The motivating case: someone's full profile page might be "an enormous sprawling mess of half-finished html," not something they want surfaced just because they said something in chat — but they may still want people who see them in chat to know a few specific things, without maintaining a second full profile just for that purpose.

## Direction agreed so far

- **One mini-profile per Profile/Group, not per-server.** Explicitly rejected: a different mini-profile per server they're in. A single shared lightweight alternate view, reused everywhere in chat regardless of which server.
- **Clicking a name/avatar in chat always opens the mini-profile popover now.** This supersedes the earlier "full profile vs. mini-profile" framing — there is no mode where a click still does a full-page navigation. The popover is the universal click target for names/avatars on chat messages.
  - **Scoped to messages only.** The "posting as" identity picker in the composer keeps its current full-page-link behavior; this work doesn't touch it.
- **Content shown in the popover**: name, subtitle, pronouns, hearts (`heart_emojis`), tagline, plus a new **mini-profile description** field — rich text with the same hearts/spoilers formatting as the full `description` field (ActionText), no length cap.
  - If the mini-profile description is blank, its section is omitted entirely from the popover (no heading, no placeholder).
- **Avatar inside the popover uses the profile's own configured avatar shape** (as seen on the full profile page), not the forced-circle rule used for message avatars.
- **Link at the bottom of the popover, gated by a new opt-in boolean** (default `false` — off unless the owner turns it on):
  - Owner viewing their own postable: always shows **"Edit profile"** / **"Edit group"** (links to `edit_our_profile_path`/`edit_our_group_path`), regardless of the boolean — the boolean only affects what other viewers see.
  - Other viewers, boolean **on**: shows **"View full profile"**, opens in a new tab, links to the public `profile_path`/`group_path` (uuid).
  - Other viewers, boolean **off**: no link at all — the rest of the popover (name/subtitle/pronouns/hearts/tagline/description) still shows.
  - "Other viewers" in this app always means another logged-in plural-profiles user — there is no anonymous/logged-out viewer concept anywhere in the app today (confirmed: public share pages still require auth).
- **Ownership check reuses existing logic**: `postable.user_id == Current.user&.id`, same as `chat_postable_url` today. No multi-owner/group-membership complexity — Groups and Profiles are both strictly single-owner (`belongs_to :user`).
- **Deleted/missing postable**: if the profile/group a message references no longer exists (or is otherwise inaccessible), the name/avatar renders as a disabled, non-clickable element (e.g. plain "[deleted]"-style label) instead of a popover trigger.
- **Editing surface**: a new **"Chat settings"** section in the profile/group edit form, grouping the existing "chat proxy brackets" field together with the new mini-profile description field and the opt-in visibility boolean. Today brackets are a lone inline `.form-group`; this introduces the fieldset grouping for the first time.
- **Loading**: fetched on demand when the popover opens (lazy), not preloaded per-message — avoids extra payload/queries on chats with hundreds of messages. Implemented as a **Turbo Frame**, matching Rails/Hotwire conventions already used elsewhere in the app, rather than a Stimulus-driven JSON fetch. This is new infrastructure — no on-demand-fetch UI pattern exists anywhere in the app today (the `<dialog>` and `<details>/<summary>` patterns in use are both statically rendered, no lazy content).
- **Groups confirmed**: a Group's chat mini-profile/privacy works identically to a Profile's, consistent with `Group` already paralleling `Profile` in every other chat-relevant concern (`ChatProxyable`, `HasAvatar`). Same single-owner (`user_id`) check for the Edit-vs-View branch.

## Remaining open questions (not yet decided)

- **Exact endpoint/route shape** for the Turbo Frame fetch (e.g. nested under messages vs. a standalone `mini_profile`/`mini_group` resource keyed by postable id).
- **Command surface**: `plan-chat-commands.md` floats a possible `pp!`-family command for toggling visibility or editing the description without leaving chat. Not designed — this plan currently assumes editing only happens via the form.
- **Server-level override**: could a server ever require full profiles regardless of a member's per-profile setting? Not raised as a requirement; leaning "no, profile-level only, always," consistent with "one mini-profile, not per-server," but not explicitly asked/settled.

## Depends on / relates to

- `plan-chat-servers.md` — `chat_postable_url`, message rendering, postable resolution.
- `plan-chat-commands.md` — possible future command(s) for toggling visibility / editing mini-profile content (out of scope for this pass).
