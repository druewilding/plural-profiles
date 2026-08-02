import { Controller } from "@hotwired/stimulus"

const PREVIEW_DEBOUNCE_MS = 400

export default class extends Controller {
  static targets = ["preview", "form"]
  static values = { previewUrl: String }

  connect() {
    this.element.querySelectorAll(".chat-identity-toggle").forEach(toggle => {
      this.syncCard(toggle.closest(".card"))
    })
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
    this.pendingAvatar = src ? { src, shape } : null
    this.applyPendingAvatar()
    this.schedulePreview()
  }

  applyPendingAvatar() {
    if (!this.pendingAvatar || !this.hasPreviewTarget) return
    const { src, shape } = this.pendingAvatar

    const messageSlot = this.previewTarget.querySelector(".chat-message__avatar")
    if (messageSlot) this.setAvatarImage(messageSlot, src, "circle", 34)

    const popoverSlot = this.previewTarget.querySelector(".mini-profile__header")
    if (popoverSlot) this.setAvatarImage(popoverSlot, src, shape, 64, "avatar--large")
  }

  setAvatarImage(slot, src, shape, size, extraClass) {
    const existing = slot.querySelector(".avatar")
    const img = document.createElement("img")
    img.src = src
    img.width = size
    img.height = size
    img.alt = ""
    img.className = ["avatar", extraClass, shape === "circle" ? "avatar--circle" : shape === "square" ? "avatar--square" : null]
      .filter(Boolean).join(" ")
    if (existing) existing.replaceWith(img)
    else slot.prepend(img)
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
