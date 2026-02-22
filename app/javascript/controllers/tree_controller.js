import { Controller } from "@hotwired/stimulus"

// Tree explorer controller for navigating nested groups and profiles.
// Handles expand/collapse of folders and swapping the content panel.
export default class extends Controller {
  static targets = ["content", "folder", "groupTemplate", "profileTemplate", "fallback"]

  connect() {
    // Progressive enhancement: show the interactive explorer, hide the flat fallback
    const explorer = this.element.querySelector(".explorer")
    if (explorer) explorer.classList.add("explorer--active")
    if (this.hasFallbackTarget) {
      this.fallbackTarget.hidden = true
    }
  }

  selectRoot(event) {
    const button = event.currentTarget
    this.#clearActive()
    button.classList.add("tree__item--active")

    // Show root group content
    const template = this.groupTemplateTargets[this.groupTemplateTargets.length - 1]
    if (template) {
      this.contentTarget.innerHTML = template.innerHTML
    }
  }

  selectGroup(event) {
    const button = event.currentTarget
    const { groupUuid } = button.dataset

    this.#clearActive()
    button.classList.add("tree__item--active")

    const template = this.groupTemplateTargets.find(
      t => t.dataset.groupUuid === groupUuid
    )
    if (template) {
      this.contentTarget.innerHTML = template.innerHTML
    }
  }

  toggleFolder(event) {
    const button = event.currentTarget
    const folder = button.closest(".tree__folder")
    const children = folder?.querySelector(".tree__children")
    if (!children) return

    const isHidden = children.style.display === "none"
    children.style.display = isHidden ? "" : "none"
    folder.setAttribute("aria-expanded", isHidden)
    const arrow = button.querySelector(".tree__arrow")
    if (arrow) {
      arrow.classList.toggle("tree__arrow--open", isHidden)
    }
  }

  selectProfile(event) {
    const button = event.currentTarget
    const { groupUuid, profileUuid } = button.dataset
    this.#showProfile(groupUuid, profileUuid)
  }

  selectProfileCard(event) {
    const button = event.currentTarget
    const { groupUuid, profileUuid } = button.dataset
    this.#showProfile(groupUuid, profileUuid)
  }

  // --- private ---

  #showProfile(groupUuid, profileUuid) {
    this.#clearActive()

    // Highlight the matching leaf in the tree
    const treeLeaf = this.element.querySelector(
      `.tree button[data-group-uuid="${groupUuid}"][data-profile-uuid="${profileUuid}"]`
    )
    if (treeLeaf) {
      treeLeaf.classList.add("tree__item--active")
      // Ensure parent folders are expanded so the leaf is visible
      let parent = treeLeaf.closest(".tree__children")
      while (parent) {
        parent.style.display = ""
        const folder = parent.closest(".tree__folder")
        if (folder) folder.setAttribute("aria-expanded", "true")
        const arrowBtn = parent.previousElementSibling?.querySelector(".tree__arrow")
        if (arrowBtn) arrowBtn.classList.add("tree__arrow--open")
        parent = parent.parentElement?.closest(".tree__children")
      }
    }

    const template = this.profileTemplateTargets.find(
      t => t.dataset.groupUuid === groupUuid && t.dataset.profileUuid === profileUuid
    )
    if (template) {
      this.contentTarget.innerHTML = template.innerHTML
    }
  }

  #clearActive() {
    this.element.querySelectorAll(".tree__item--active").forEach(el => {
      el.classList.remove("tree__item--active")
    })
  }
}
