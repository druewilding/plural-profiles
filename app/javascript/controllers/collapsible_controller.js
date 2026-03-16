import { Controller } from "@hotwired/stimulus"

// Stimulus controller for <details> that persists open/closed state in localStorage
export default class extends Controller {
  static values = { key: String }

  connect() {
    this.details = this.element
    this.key = `collapsible:${this.keyValue}`
    this.restoreState()
    this.details.addEventListener("toggle", this.saveState)
  }

  disconnect() {
    this.details.removeEventListener("toggle", this.saveState)
  }

  restoreState = () => {
    const saved = window.localStorage.getItem(this.key)
    if (saved === "open") {
      this.details.open = true
    } else if (saved === "closed") {
      this.details.open = false
    }
  }

  saveState = () => {
    window.localStorage.setItem(this.key, this.details.open ? "open" : "closed")
  }
}
