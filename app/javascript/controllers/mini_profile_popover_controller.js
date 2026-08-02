import { Controller } from "@hotwired/stimulus"

const VIEWPORT_MARGIN = 8

export default class extends Controller {
  static targets = ["frame", "panel"]
  static values = { url: String }

  open(event) {
    if (!this.frameTarget.getAttribute("src")) this.frameTarget.src = this.urlValue
    this.panelTarget.showPopover()
    this.position(event.currentTarget)
  }

  position(trigger) {
    const anchor = trigger.getBoundingClientRect()
    const panel = this.panelTarget

    const left = Math.min(anchor.left, window.innerWidth - panel.offsetWidth - VIEWPORT_MARGIN)
    const top = Math.min(anchor.bottom + VIEWPORT_MARGIN, window.innerHeight - panel.offsetHeight - VIEWPORT_MARGIN)

    panel.style.left = `${Math.max(left, VIEWPORT_MARGIN)}px`
    panel.style.top = `${Math.max(top, VIEWPORT_MARGIN)}px`
  }
}
