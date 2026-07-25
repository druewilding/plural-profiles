import { Controller } from "@hotwired/stimulus"

// A lightweight dropdown powered by <details>/<summary>.
// Closes on outside click, Escape key, and when a menu item is clicked.
//
// Usage:
//   %details.action-dropdown{data: { controller: "dropdown" }}
//     %summary.action-dropdown__trigger Options
//     .action-dropdown__menu
//       = link_to "Edit", ..., class: "action-dropdown__item"
export default class extends Controller {
  connect() {
    this.close = this.close.bind(this)
    this.onDocumentClick = this.onDocumentClick.bind(this)
    this.onKeydown = this.onKeydown.bind(this)

    document.addEventListener("click", this.onDocumentClick, true)
    document.addEventListener("keydown", this.onKeydown)
  }

  disconnect() {
    document.removeEventListener("click", this.onDocumentClick, true)
    document.removeEventListener("keydown", this.onKeydown)
  }

  onDocumentClick(event) {
    if (!this.element.open) return
    if (this.element.contains(event.target)) {
      // If they clicked an actual menu item (link), let it navigate then
      // close. Deliberately narrower than "clicked anywhere in the menu" —
      // some menus (e.g. the profile picker) contain a search input that
      // must stay open while it's being typed into.
      if (event.target.closest(".action-dropdown__item")) {
        // Use requestAnimationFrame so the click action fires first
        requestAnimationFrame(() => this.close())
      }
      return
    }
    this.close()
  }

  onKeydown(event) {
    if (event.key === "Escape" && this.element.open) {
      this.close()
      this.element.querySelector("summary")?.focus()
    }
  }

  close() {
    this.element.open = false
  }
}
