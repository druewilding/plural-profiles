# Plan: Avatar Editor Popup + Shape Options

## Overview

Replace the current inline avatar section on profile and group edit forms with a dedicated popup editor. Move all avatar-specific controls (file upload, alt text, remove option, and a new shape picker) inside a `<dialog>` element that opens when the user clicks a button. The main form shows only the current avatar preview and the open-dialog button. When the dialog is dismissed, the preview updates to reflect any pending changes before the main form is saved.

Additionally, add a new `avatar_shape` field (stored on both `profiles` and `groups`) with three options: **circle**, **rounded** (the current default), and **square**.

---

## Current problems

1. **Preview lag** — uploading a new file populates the filename input but does not update the current-avatar preview. The user writes an alt text description about an image they can't yet see.
2. **Alt text is disconnected** — the "Avatar description" field sits below the entire avatar section, separated from the image it describes.
3. **Remove is inline** — the "Remove avatar" checkbox sits inside the main form flow, which feels awkward — you might accidentally check it.
4. **No shape control** — all avatars are `border-radius: 25%` ("rounded square"). Some users want a circle; some want a true square.

---

## Data model changes

### Migration: `add_avatar_shape_to_profiles_and_groups`

Add a `avatar_shape` string column to both tables:

```ruby
add_column :profiles, :avatar_shape, :string, default: "rounded", null: false
add_column :groups,   :avatar_shape, :string, default: "rounded", null: false
```

- Default `"rounded"` matches the current visual behaviour for all existing avatars.
- Valid values: `"circle"`, `"rounded"`, `"square"`.

### `HasAvatar` concern

Add a validation:

```ruby
AVATAR_SHAPES = %w[circle rounded square].freeze

validates :avatar_shape, inclusion: { in: AVATAR_SHAPES }
```

---

## Controller changes

### `Our::ProfilesController` — `profile_params`

Add `:avatar_shape` to the permitted parameter list.

### `Our::GroupsController` — `group_params`

Add `:avatar_shape` to the permitted parameter list.

No other controller logic changes required — the dialog inputs live inside the main form and submit with it normally.

---

## View changes

### Main form (profiles and groups)

Replace the current avatar `.form-group` block with two things:

1. **Avatar preview area** — shows the current avatar (with correct shape class) or a placeholder. This is read-only, updated by JS when the dialog is confirmed.
2. **"Edit avatar" button** — opens the dialog. Labelled "Add avatar" when no avatar is attached.

The file input, alt text field, remove checkbox, shape picker, and related hidden inputs move out of the main form body and into the dialog (but still inside the `<form>` element so they submit normally).

```
┌─ main form ───────────────────────────────────────────────┐
│  [Avatar preview / placeholder]  [Edit avatar ▸]          │
│                                                            │
│  ... rest of form (name, pronouns, description, etc.) ...  │
│                                                            │
│  ┌─ <dialog> (hidden until opened) ──────────────────────┐ │
│  │  ┌─ preview area ─────────────────────────────────┐   │ │
│  │  │  [live preview of selected file OR current img] │   │ │
│  │  └────────────────────────────────────────────────┘   │ │
│  │  [Choose file input]                                   │ │
│  │                                                        │ │
│  │  Shape:  ○ Circle  ● Rounded  ○ Square                 │ │
│  │  (each option shown as a small preview of the avatar   │ │
│  │   with that shape applied)                             │ │
│  │                                                        │ │
│  │  [Avatar description text field]                       │ │
│  │                                                        │ │
│  │  [✗ Remove avatar]  (only shown when avatar exists)    │ │
│  │                                                        │ │
│  │  [Done]  [Cancel]                                      │ │
│  └────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────┘
```

The `<dialog>` element is inside the `<form>`, so all its inputs participate in form submission. The "Done" and "Cancel" buttons are `type="button"` (not submit) — they only control dialog open/close state.

### Shared partial

Extract the dialog markup into a shared partial so profiles and groups reuse it:

```
app/views/shared/_avatar_editor_dialog.html.haml
```

Called with locals: `record`, `form` (the `form_with` builder), and `param_prefix` (`"profile"` or `"group"`).

### Public-facing avatar renders

All places that render avatars (profile show, group show, profile cards, sidebar tree nodes, etc.) need to apply the appropriate shape modifier class. A helper method handles this:

```ruby
# app/helpers/avatar_helper.rb (or ApplicationHelper)
def avatar_shape_class(record)
  case record.avatar_shape
  when "circle"  then "avatar--circle"
  when "square"  then "avatar--square"
  else                "" # "rounded" is the default .avatar style
  end
end
```

Usage at each render site:

```haml
= image_tag record.avatar.variant(...),
    class: "avatar avatar--large #{avatar_shape_class(record)}".strip,
    ...
```

Affected files:
- `app/views/profiles/show.html.haml`
- `app/views/groups/show.html.haml`
- `app/views/groups/_group_content.html.haml`
- `app/views/groups/_group_content_fallback.html.haml`
- `app/views/groups/_profile_content.html.haml`
- `app/views/groups/_profile_card.html.haml`
- `app/views/group_profiles/show.html.haml`
- `app/views/our/profiles/show.html.haml`
- `app/views/our/groups/show.html.haml`
- `app/views/our/groups/_group_card.html.haml`
- `app/views/our/_sidebar_tree_node.html.haml` (24px sidebar thumbnails also respect shape)
- `app/views/our/groups/duplicate_resolve.html.haml`

---

## JavaScript: `avatar-editor` Stimulus controller

New file: `app/javascript/controllers/avatar_editor_controller.js`

### Targets

| Target | Purpose |
|---|---|
| `dialog` | The `<dialog>` element |
| `fileInput` | The `<input type="file">` |
| `preview` | The `<img>` or placeholder div inside the dialog |
| `mainPreview` | The avatar preview on the main form (outside the dialog) |
| `removeCheckbox` | The "Remove avatar" checkbox |
| `shapeInputs` | All three shape radio buttons |
| `altTextField` | The avatar description text input |

### Actions

**`open()`** — called by the "Edit avatar" button
- Records the current state (original file input value can't be read, but track: shape value, alt text value, remove checked state) as a snapshot for Cancel
- Calls `dialog.showModal()`

**`close(event)`** — called by "Done" button  
- If a new file was selected, update `mainPreview` with the object URL
- If "Remove avatar" is checked, replace `mainPreview` with the placeholder
- If neither, leave `mainPreview` as the current avatar (possibly with updated shape class)
- Apply the selected shape class to `mainPreview`
- Calls `dialog.close()`

**`cancel()`** — called by "Cancel" button
- Restore snapshot values (alt text, shape selection, remove checkbox)
- Clear the file input (replace it with a clone to reset the value)
- Restore `mainPreview` to its original state
- Calls `dialog.close()`

**`onFileChange()`** — triggered by `change` on the file input
- If a file is selected: use `URL.createObjectURL` to show a live preview in the dialog `preview` target
- Also uncheck the "Remove avatar" checkbox automatically (can't remove and add simultaneously)
- Updates the preview with the current shape class

**`onShapeChange()`** — triggered by `change` on any shape radio
- Apply the selected shape class to the dialog `preview` target (so the user sees the effect immediately)

**`onRemoveChange()`** — triggered by `change` on the remove checkbox
- If checked: show placeholder in dialog preview, clear file input
- If unchecked: show current avatar in dialog preview (or new file preview if selected)

### Accessibility

- `dialog.showModal()` traps focus within the dialog automatically
- Pressing Escape closes the dialog (native browser behaviour for `<dialog>`) — wire this to the cancel action (restore snapshot)
- "Done" / "Cancel" are accessible button labels
- The shape picker labels wrap the radio + a visual example for each shape

---

## CSS changes

### New `.avatar` shape modifiers

```css
/* .avatar--rounded is already the default style (border-radius: 25%) */

.avatar--circle {
  border-radius: 50%;
}

.avatar--square {
  border-radius: 0;
}
```

### Avatar editor dialog

```css
.avatar-editor-dialog { ... }
.avatar-editor-dialog::backdrop { ... }
.avatar-editor-dialog__preview { ... }
.avatar-shape-picker { ... }
.avatar-shape-picker__option { ... }
.avatar-shape-picker__option input[type="radio"] { ... }
.avatar-shape-picker__sample { ... }
```

The dialog uses `forced-colors: active` overrides as appropriate (backdrop won't be visible in forced-colors mode; rely on the native dialog border).

---

## Decisions confirmed

1. **"Square" border-radius** — `border-radius: 0`. No softening — truly square corners so no content is clipped.

2. **Small sidebar thumbnails** — All avatar sizes (including 24px sidebar thumbnails) respect `avatar_shape`.

3. **Shape picker when no avatar yet** — The dialog preview shows the standard placeholder logo (as used elsewhere on the site) until a file is selected. The shape picker is visible immediately so shape can be chosen before uploading.

4. **Existing avatars default** — Migration defaults all existing `avatar_shape` values to `"rounded"`, matching current behaviour.
