import { Controller } from "@hotwired/stimulus"

const VIEWPORT_MARGIN = 8

export default class extends Controller {
  static targets = ["frame", "panel"]
  static values = { url: String }

  open(event) {
    this.lastTrigger = event.currentTarget
    if (!this.frameTarget.getAttribute("src")) this.frameTarget.src = this.urlValue
    this.panelTarget.showPopover()
    this.position(this.lastTrigger)
  }

  // The frame is still empty (or showing whatever it last held) at the
  // moment open() positions it — the fetched content swaps in later,
  // asynchronously, and can be much taller once it does (more so with a
  // long description or a larger font size). Without repositioning once
  // that actually happens, the bottom-of-viewport clamp in position() was
  // computed against the wrong height and the popover could still run off
  // the bottom of the window. Wired via turbo:frame-load on the frame
  // itself (see the message partial).
  reposition() {
    if (!this.lastTrigger || !this.panelTarget.matches(":popover-open")) return
    this.position(this.lastTrigger)
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
