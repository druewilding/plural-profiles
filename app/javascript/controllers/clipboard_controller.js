import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "label"]

  copy() {
    if (!this.hasSourceTarget) return

    const text = this.sourceTarget.value
    const originalLabel = this.hasLabelTarget ? this.labelTarget.textContent : null

    this.writeToClipboard(text).then(() => {
      this.showFeedback("Copied!", originalLabel)
    }).catch(() => {
      this.showFeedback("Copy failed", originalLabel)
    })
  }

  // navigator.clipboard only exists in "secure contexts" — https, or the
  // literal hostnames localhost/127.0.0.1. A dev host like chat.lvh.me
  // merely resolves to 127.0.0.1 via DNS, which doesn't count, so
  // navigator.clipboard is undefined there and calling .writeText on it
  // throws synchronously. Fall back to the older select+execCommand copy,
  // which still works without a secure context.
  writeToClipboard(text) {
    if (navigator.clipboard?.writeText) return navigator.clipboard.writeText(text)

    return new Promise((resolve, reject) => {
      this.sourceTarget.select()
      this.sourceTarget.setSelectionRange(0, text.length)
      const succeeded = document.execCommand("copy")
      this.sourceTarget.blur()
      succeeded ? resolve() : reject()
    })
  }

  showFeedback(message, originalLabel) {
    if (!this.hasLabelTarget) return

    this.labelTarget.textContent = message
    setTimeout(() => {
      this.labelTarget.textContent = originalLabel
    }, 2000)
  }
}
