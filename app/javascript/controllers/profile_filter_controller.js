import { Controller } from "@hotwired/stimulus"

// Live text filter for a (potentially long — hundreds of duplicate profiles)
// list of options inside a dropdown menu. Each option carries its own
// pre-lowercased searchable text in data-search; matching is a plain
// substring test against that, no need for anything fancier.
export default class extends Controller {
  static targets = ["input", "option", "empty"]

  connect() {
    this.onParentToggle = this.onParentToggle.bind(this)
    this.detailsElement = this.element.closest("details")
    this.detailsElement?.addEventListener("toggle", this.onParentToggle)
  }

  disconnect() {
    this.detailsElement?.removeEventListener("toggle", this.onParentToggle)
  }

  // Reset the filter and focus the search box each time the dropdown opens,
  // so switching who you're posting as always starts from a clean slate.
  onParentToggle() {
    if (!this.detailsElement.open) return
    this.inputTarget.value = ""
    this.apply()
    requestAnimationFrame(() => this.inputTarget.focus())
  }

  apply() {
    const query = this.inputTarget.value.trim().toLowerCase()
    let visibleCount = 0

    this.optionTargets.forEach((option) => {
      const matches = !query || option.dataset.search.includes(query)
      option.hidden = !matches
      if (matches) visibleCount++
    })

    if (this.hasEmptyTarget) this.emptyTarget.hidden = visibleCount > 0
  }
}
