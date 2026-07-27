# Plan: In-Chat Commands (rough)

## Status

Rough sketch only — captures direction from a user conversation. Not ready to implement; command list and semantics are a starting point, not final. Revisit before building.

## Background

Users want to adjust chat-relevant settings (brackets first; more over time) without leaving the chat UI and losing their place in a conversation. The users are already familiar with Tupperbox's Discord bot commands (`tul!register`, `tul!remove`, `tul!list`, `tul!avatar`, `tul!rename`, `tul!brackets`, `tul!dash`), typed directly into the message box with a prefix. A `pp!` prefix was proposed and liked.

**Key divergence from Tupperbox:** Tupperbox addresses commands by `<name>` because tuppers have unique names per account. Plural-profiles deliberately does **not** enforce unique profile/group names — duplication is a first-class feature — so name-based addressing doesn't transplant. Instead, commands act on **whichever profile/group is currently selected in the "posting as" picker** (something Tupperbox has no equivalent of, since Discord has no per-message identity selector outside the bot itself). This sidesteps the naming problem entirely for single-target commands.

## Direction agreed so far

- **Prefix: `pp!`**
- Single-target commands act on the current posting-as identity, no name argument:
  - `pp!brackets <before> [after]` / `pp!brackets clear` / `pp!brackets` (show) — the core original ask: set brackets without leaving chat.
  - `pp!rename <new name>` — safe now that names aren't used for addressing.
  - `pp!avatar` (show) / `pp!avatar <url> [crop:direction]` (set) / `pp!avatar clear`.
  - `pp!edit` — escape hatch to the full profile/group edit page (equivalent of `tul!dash`).
- Commands needing to reference a *different* profile/group than the current one avoid name lookup by using position in your own list instead:
  - `pp!list` — numbered list of your postables available in this server, showing brackets if set, marking the current one.
  - `pp!switch <n>` — change posting-as to list item `n`.
- **Architecture: intercepted server-side before message creation**, as a sibling to the existing `Chat::ProxyResolver` bracket-matching step already in `Chat::Message#resolve_postable` — `pp!`-prefixed input never becomes a stored `Chat::Message`. No new bot/service needed; this is in-process, same as the rest of chat.
- **Feedback should be ephemeral/sender-only**, not posted as a visible channel message — so channels don't fill with command noise other members have to scroll past.

## Open questions

- **Which layer does `pp!switch` change** — the channel-level override (`Chat::ChannelDefaultPostable`) or the server-level membership default (`Chat::Membership#default_postable`)? Leaning channel-level, since "posting as" in the composer is already channel-scoped, but not settled.
- **Attachment-based avatar upload** (`pp!avatar` + a dragged/pasted image) vs. URL-only to start — Discord bots receive attachments natively; a web composer would need new plumbing for this. May start URL-only.
- **`pp!avatar-shape`** — only becomes relevant if `plan-chat-avatar-shapes.md`'s "allow variation" server setting ships and profiles get a chat-specific shape override to set. Not designed yet.
- **Mini-profile toggle/edit** — `plan-chat-mini-profiles.md` will likely want its own command(s) (e.g. visibility toggle, editing mini-profile content) once that feature exists; not sketched yet.
- **Discoverability** — unlike a Discord bot (which has its own external docs/help command convention users seek out), this lives inside the app's own chat UI. Needs a `pp!help` command and/or in-UI hinting so people learn commands exist at all.
- **Destructive-ish actions** (`pp!avatar clear`, `pp!rename`) — any confirmation step, or just allow + rely on being easily re-set?
- Full command list is intentionally not finalized — starter set above, expected to grow as other chat settings features land.

## Depends on / relates to

- `plan-chat-servers.md` — `Chat::ProxyResolver`, `Chat::Membership`/`Chat::ChannelDefaultPostable`, the existing "posting as" picker this reuses.
- `plan-chat-avatar-shapes.md` — possible future command surface.
- `plan-chat-mini-profiles.md` — possible future command surface.
