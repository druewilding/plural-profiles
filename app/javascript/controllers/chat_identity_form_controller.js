import { Controller } from "@hotwired/stimulus"

const PREVIEW_DEBOUNCE_MS = 400

export default class extends Controller {
  static targets = ["preview"]
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
    if (event.target.classList.contains("chat-identity-toggle__input")) {
      this.syncCard(event.target.closest(".card"))
    }
    this.schedulePreview()
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

  schedulePreview() {
    clearTimeout(this.previewTimeout)
    this.previewTimeout = setTimeout(() => this.updatePreview(), PREVIEW_DEBOUNCE_MS)
  }

  async updatePreview() {
    const formData = new FormData(this.element)
    formData.delete("chat_identity[mini_profile_avatar]")

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
  }
}
