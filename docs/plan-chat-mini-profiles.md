# Plan: Chat Mini-Profiles / Privacy (rough)

## Status

Rough sketch only — captures direction from a user conversation. Not ready to implement; this is the least-settled of the three related chat-settings plans. Revisit before building.

## Background

Today, clicking a name in chat (`chat_postable_url`, in `app/views/chat/messages/_message.html.haml` and the posting-as picker) always navigates to the postable's full profile/group page. There is no visibility/privacy flag on `Profile`/`Group` at all — access is "unguessable UUID," not public/private (confirmed: no such column exists today).

The motivating case: someone's full profile page might be "an enormous sprawling mess of half-finished html," not something they want surfaced just because they said something in chat — but they may still want people who see them in chat to know a few specific things, without maintaining a second full profile just for that purpose.

## Direction agreed so far

- **One mini-profile per Profile/Group, not per-server.** Explicitly rejected: a different mini-profile per server they're in. A single shared lightweight alternate view, reused everywhere in chat regardless of which server.
- **Two separable concerns:**
  1. A visibility switch: does clicking this name in chat open the full profile page, or the mini-profile instead?
  2. The mini-profile's own content: something smaller than the full profile, but with room for at least one thing the full profile card doesn't already show.
- **Likely content shape**: reuse what `_profile_card`/`_group_card` already render (avatar, name, pronouns, subtitle, labels) as the base, since that's already the app's "smaller than full page" pattern — plus a new free-text field for the "important things they need people who see them in chat to know" that isn't just profile-card data. Not yet decided whether this is a wholly separate set of fields or an overlay on top of the card fields.
- **New UI pattern required**: nothing today fetches profile content on demand (no popover/hover-card, no Turbo Frame endpoint for this) — clicking a name always does a full page navigation. A mini-profile likely means an on-demand popover or modal, fetched via a new endpoint, rather than a full page load. This is new infrastructure, not an extension of an existing pattern — flagged as the biggest unknown of the three related plans.
- **Formatting confirmed**: the free-text field supports the same hearts/spoilers formatting already used elsewhere (`formatted_inline`/`formatted_description`), same as every other user-authored text field in the app.
- **Groups confirmed**: a Group's chat mini-profile/privacy works identically to a Profile's, consistent with `Group` already paralleling `Profile` in every other chat-relevant concern (`ChatProxyable`, `HasAvatar`).

## Open questions

- **Visibility flag values** — just "full profile" vs. "mini-profile," or a third option (no click-through at all, name is inert text)?
- **Exact mini-profile fields** — reuse profile-card fields as-is plus one free-text field, or a fully custom smaller field set independent of the card?
- **Scope of the visibility switch** — profile-level (applies everywhere in chat, across all servers), or could a server ever require full profiles regardless of a member's preference? Leaning profile-level only, consistent with "one mini-profile, not per-server," but not explicitly settled.
- **Avatar shape inside the mini-profile popover** — should follow whatever `plan-chat-avatar-shapes.md` resolves for chat rendering generally (forced circle, or the effective per-profile shape), rather than inventing a separate rule.
- **Editing surface** — likely wants to be reachable from wherever `plan-chat-commands.md`'s command set and/or a broader in-chat settings surface lives, rather than only from the full profile edit page. Not designed yet.

## Depends on / relates to

- `plan-chat-servers.md` — `chat_postable_url`, message rendering, postable resolution.
- `plan-chat-avatar-shapes.md` — avatar rendering inside the mini-profile popover.
- `plan-chat-commands.md` — possible command(s) for toggling visibility / editing mini-profile content.
