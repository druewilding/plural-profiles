# Plan: Chat Avatar Shapes (rough)

## Status

Rough sketch only — captures decisions made in a user conversation so far. Not ready to implement; no schema/code decided yet. Revisit before building.

## Background

Today `avatar_shape` (`circle`/`rounded`/`square`, see `docs/plan-avatar-editor-popup.md`) is one column per `Profile`/`Group`/`Chat::Server`, rendered identically everywhere via `avatar_shape_class`. Users chatting want a way to appear differently in the busy chat window than they do on their own profile page/card, but always forcing per-profile choice risks a visually inconsistent chat window if left unconstrained.

## Decisions so far

1. **First cut: force all chat avatars circle, full stop.** No new setting yet — chat rendering ignores each record's own `avatar_shape` and always applies circle. Gives every server visual consistency immediately with no new schema. This is purely a rendering-context change (chat views stop calling the record's stored `avatar_shape` and hardcode circle), not a data model change.
2. **Later: a server-level toggle, inheriting like theme does.** `Chat::Server` gets a setting — "Always circle" (default) vs. "Allow variation" (respect each profile's own preferred shape) — and `Chat::Channel` can inherit or override it, mirroring the existing `channel.theme_id || server.theme_id` fallback chain (`ThemeHelper#active_theme_style`). Only accessible to server owners for now — there is no moderator role yet (`Chat::Membership::ROLES = %w[owner member]`), so this is owner-gated until Phase 4 moderation work (see `plan-chat-servers.md`) introduces one.
3. **Only if a server ever turns on "allow variation":** profiles/groups need a chat-specific shape override, separate from their normal `avatar_shape` — because the shape someone wants on their own profile page isn't necessarily what they want in a small, busy chat avatar. This would be a new nullable column (e.g. `chat_avatar_shape`), falling back to the profile's ordinary `avatar_shape` when unset.
4. **Explicitly not in the avatar upload dialog.** A second shape picker at upload time (`_avatar_editor_dialog`) would be confusing — that's about "what does my avatar image look like," not "how should I appear in this chat context." Wherever the chat-specific override setting lives, it belongs with other chat-specific settings (see `plan-chat-commands.md` / `plan-chat-mini-profiles.md`), not bundled into image upload.
5. **No-surprises rule for pickers.** The "posting as" selector and any profile/identity picker inside chat must always render the avatar exactly as it will actually appear when posting — i.e. it needs to resolve the same effective-shape logic (server forced-circle vs. profile override) live, never showing a shape that then changes on send.

## Open questions

- Exact UI/location for the future per-profile chat shape override (likely slots into whatever in-chat settings surface comes out of `plan-chat-commands.md`).
- Whether "allow variation" ever becomes a per-channel-only override without a server-wide toggle, or always requires the server to opt in first.
- Interaction with moderator roles once those exist — should moderators (not just owners) be able to flip this?

## Depends on / relates to

- `plan-chat-servers.md` — theme inheritance chain this mirrors; `Chat::Membership` roles.
- `plan-chat-commands.md` — likely home for a future `pp!avatar-shape`-style command, contingent on decision 3 above ever shipping.
