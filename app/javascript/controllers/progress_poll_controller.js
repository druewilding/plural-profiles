import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["counter"]
  static values = {
    url: String,
    interval: { type: Number, default: 2000 },
    redirectNotice: { type: String, default: "" }
  }

  connect() {
    this.poll()
    this.timer = setInterval(() => this.poll(), this.intervalValue)
  }

  disconnect() {
    clearInterval(this.timer)
  }

  async poll() {
    try {
      const response = await fetch(this.urlValue, {
        headers: { "Accept": "application/json" }
      })
      if (!response.ok) return

      const data = await response.json()
      this.counterTarget.textContent = `Copied ${data.copied} of ${data.total} avatars`

      if (data.redirect_url) {
        clearInterval(this.timer)
        window.Turbo.visit(data.redirect_url)
      }
    } catch {
      // Silently ignore fetch errors — will retry on next interval
    }
  }
}
