import { Controller } from "@hotwired/stimulus"

const PREVIEW_DEBOUNCE_MS = 400

export default class extends Controller {
  static targets = ["preview", "form"]
  static values = { previewUrl: String }

  connect() {
    // Set only by an actual avatar-editor:changed event this session — a
    // freshly picked file ({src, shape}), or an explicit removal (null).
    // Left `undefined` when the user hasn't touched the dialog at all, so
    // "Set for chat" with a pre-existing saved mini_profile_avatar can still
    // defer to the server's own render of it (see applyAvatarCard).
    this.pickedAvatar = undefined

    this.element.querySelectorAll(".chat-identity-toggle").forEach(toggle => {
      this.syncCard(toggle.closest(".card"))
    })
    this.applyAvatarCard(this.avatarCard())
  }

  disconnect() {
    clearTimeout(this.previewTimeout)
  }

  change(event) {
    const target = event.target
    if (target.classList.contains("chat-identity-toggle__input")) {
      const card = target.closest(".card")
      this.syncCard(card)
      if (target.matches('[value="false"]:checked')) this.focusOverrideField(card)
      if (card === this.avatarCard()) this.applyAvatarCard(card)
    }
    this.schedulePreview()
  }

  // The avatar file itself is never sent to the preview endpoint (see
  // updatePreview) — a picked-but-unsaved file can't be reflected by a
  // server round-trip without either re-uploading it on every keystroke or
  // actually attaching it early (has_one_attached persists immediately,
  // even without a record save). So this patches the already-rendered
  // preview images directly from the object URL the avatar-editor dialog
  // already created for its own local preview, no server involved.
  avatarChanged(event) {
    const { src, shape } = event.detail
    this.pickedAvatar = src ? { src, shape } : null
    this.applyAvatarCard(this.avatarCard())
    this.schedulePreview()
  }

  avatarCard() {
    return this.element.querySelector(".chat-identity-field__override .avatar-editor")?.closest(".card") ?? null
  }

  // Decides what the preview should show for the avatar, independent of
  // whatever the last server-rendered preview_panel happened to contain:
  //  - "Follow profile" selected → always the main avatar (or its
  //    placeholder), matching what saving with that mode would purge to.
  //  - "Set for chat" selected, and a file was picked/removed this session
  //    → that pick wins, since it hasn't round-tripped through the server.
  //  - "Set for chat" selected, untouched this session → defer to the
  //    server's own render (there may already be a saved mini_profile_avatar
  //    for it to show, which this controller has no other way to know).
  applyAvatarCard(card) {
    if (!card) return
    const overriding = card.querySelector('.chat-identity-toggle__input[value="false"]')?.checked

    if (overriding && this.pickedAvatar === undefined) {
      this.pendingAvatar = null // defer to the server-rendered preview
    } else if (overriding && this.pickedAvatar) {
      this.pendingAvatar = this.pickedAvatar
    } else {
      this.pendingAvatar = this.fallbackAvatar(card) // inherit mode, or an explicit removal
    }
    this.applyPendingAvatar()
  }

  // Reads the main avatar already shown in this same card's "Currently on
  // your profile" panel — server-rendered, so no separate data source to
  // keep in sync with — either an <img> (src + shape class) or the
  // placeholder logo (nothing attached).
  fallbackAvatar(card) {
    const inherited = card.querySelector(".chat-identity-field__inherited")
    const img = inherited?.querySelector("img.avatar")
    if (img) {
      const shape = img.className.includes("avatar--circle") ? "circle"
        : img.className.includes("avatar--square") ? "square" : "rounded"
      return { src: img.src, shape }
    }
    const placeholder = inherited?.querySelector(".avatar--placeholder")
    return placeholder ? { placeholderHtml: placeholder.innerHTML } : null
  }

  applyPendingAvatar() {
    if (!this.hasPreviewTarget || !this.pendingAvatar) return

    const messageSlot = this.previewTarget.querySelector(".chat-message__avatar")
    if (messageSlot) this.setAvatarImage(messageSlot, this.pendingAvatar, "circle", 34)

    const popoverSlot = this.previewTarget.querySelector(".mini-profile__header")
    if (popoverSlot) this.setAvatarImage(popoverSlot, this.pendingAvatar, this.pendingAvatar.shape ?? "rounded", 64, "avatar--large")
  }

  setAvatarImage(slot, { src, placeholderHtml }, shape, size, extraClass) {
    const existing = slot.querySelector(".avatar")
    const shapeClass = shape === "circle" ? "avatar--circle" : shape === "square" ? "avatar--square" : null

    const el = document.createElement(placeholderHtml ? "div" : "img")
    el.className = ["avatar", extraClass, placeholderHtml ? "avatar--placeholder" : shapeClass].filter(Boolean).join(" ")
    if (placeholderHtml) {
      el.innerHTML = placeholderHtml
    } else {
      el.src = src
      el.width = size
      el.height = size
      el.alt = ""
    }
    if (existing) existing.replaceWith(el)
    else slot.prepend(el)
  }

  syncCard(card) {
    if (!card) return

    const overrideRadio = card.querySelector('.chat-identity-toggle__input[value="false"]')
    if (!overrideRadio) return

    const overriding = overrideRadio.checked
    const inherited = card.querySelector(".chat-identity-field__inherited")
    const override = card.querySelector(".chat-identity-field__override")
    if (inherited) inherited.hidden = overriding
    if (override) override.hidden = !overriding
  }

  focusOverrideField(card) {
    if (!card) return
    // The avatar card's override block is the avatar-editor dialog, which
    // manages its own open/focus state (via its own trigger button) — auto-
    // focusing into it here would reach into a dialog that isn't open yet.
    const fields = card.querySelectorAll(".chat-identity-field__override input:not([type='hidden']), .chat-identity-field__override textarea")
    const field = [...fields].find(el => !el.closest(".avatar-editor"))
    field?.focus()
  }

  schedulePreview() {
    clearTimeout(this.previewTimeout)
    this.previewTimeout = setTimeout(() => this.updatePreview(), PREVIEW_DEBOUNCE_MS)
  }

  async updatePreview() {
    const formData = new FormData(this.formTarget)
    formData.delete("chat_identity[mini_profile_avatar]")
    // The form's own method is PATCH (spoofed via a hidden `_method` field,
    // since browsers can't submit PATCH natively). Left in place, Rack's
    // method-override middleware rewrites this fetch's real POST into a
    // PATCH before routing sees it — and only POST matches the preview
    // route — so it must be stripped here.
    formData.delete("_method")

    const response = await fetch(this.previewUrlValue, {
      method: "POST",
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content,
        "Accept": "text/html"
      },
      body: formData
    })

    if (!response.ok) return
    this.previewTarget.innerHTML = await response.text()
    this.applyPendingAvatar()
  }
}
