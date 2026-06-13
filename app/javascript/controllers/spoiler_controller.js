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

    // Prevent link navigation when a spoiler is inside an <a> tag.
    event.stopPropagation()

    const hasHint = span.classList.contains("spoiler--with-hint")
    const hintShowing = span.classList.contains("spoiler--hint-showing")
    const isTouchDevice = window.matchMedia("(hover: none)").matches

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
    if (!event.target.closest(".spoiler")) return

    event.preventDefault()
    this.toggle(event)
  }
}
