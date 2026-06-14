import { Controller } from "@hotwired/stimulus"

// Toggles spoiler text visibility on click or keyboard activation.
// Connects automatically to any element with data-controller="spoiler".
//
// Spoilers with a hint ([hint]||secret|| or ||secret||[hint]) have three states
// on touch devices: hidden → hint showing → revealed → hidden.
// On hover-capable devices a single click reveals directly (the hint is shown
// via CSS :hover instead).
export default class extends Controller {
  toggle(event) {
    if (event.target.closest(".details-close")) {
      const details = event.target.closest("details")
      if (details) {
        details.removeAttribute("open")
        details.querySelector(":scope > summary")?.focus()
      }
      return
    }

    const span = event.target.closest(".spoiler")
    if (!span) return

    // If this spoiler is inside a link, don't intercept — let the click navigate.
    // Revealing in-place risks an accidental reveal when the user expects link navigation.
    if (span.closest("a")) return

    if (span.closest("label")) event.preventDefault()

    const hasHint = span.classList.contains("spoiler--with-hint")
    // Use both (hover: none) and (pointer: coarse) to identify touch-primary
    // devices. Checking only (hover: none) causes false positives in headless
    // Chrome (used by the CI test runner), which reports no hover capability
    // but does not have a coarse pointer.
    const isTouchDevice = window.matchMedia("(hover: none) and (pointer: coarse)").matches

    if (hasHint && isTouchDevice && !hintShowing && !span.classList.contains("spoiler--revealed")) {
      // First tap on a touch device: show the hint, do not reveal yet.
      span.classList.add("spoiler--hint-showing")
      return
    }

    // Second tap (touch) or single click (desktop): reveal or hide.
    span.classList.remove("spoiler--hint-showing")
    const revealed = span.classList.toggle("spoiler--revealed")
    span.setAttribute("aria-expanded", String(revealed))

    if (revealed) {
      span.removeAttribute("aria-label")
    } else {
      const hint = span.dataset.spoilerHint
      span.setAttribute("aria-label",
        hint ? `Hidden content: ${hint}, click to reveal` : "Hidden content, click to reveal"
      )
    }
  }

  keydown(event) {
    if (event.key !== "Enter" && event.key !== " ") return
    const span = event.target.closest(".spoiler")
    if (!span) return

    // If the spoiler is inside a link, activate the link so keyboard users
    // get the same navigation behaviour as a mouse click.
    const link = span.closest("a")
    if (link) {
      event.preventDefault()
      link.click()
      return
    }

    event.preventDefault()
    this.toggle(event)
  }
}
