import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["subgroupCheckbox", "profileCheckbox"]

  connect() {
    this.updateSubgroupCheckboxes()
    this.updateProfileCheckboxes()
  }

  change(event) {
    const el = event.target
    if (!el) return
    if (el.name === 'subgroup_inclusion_mode') this.updateSubgroupCheckboxes()
    if (el.name === 'profile_inclusion_mode') this.updateProfileCheckboxes()
  }

  updateSubgroupCheckboxes() {
    const selected = this.element.querySelector('input[name="subgroup_inclusion_mode"]:checked')
    if (!selected) return
    const mode = selected.value
    this.subgroupCheckboxTargets.forEach(cb => {
      if (mode === 'all') { cb.checked = true; cb.disabled = true }
      else if (mode === 'none') { cb.checked = false; cb.disabled = true }
      else if (mode === 'selected') { cb.disabled = false }
    })
  }

  updateProfileCheckboxes() {
    const selected = this.element.querySelector('input[name="profile_inclusion_mode"]:checked')
    if (!selected) return
    const mode = selected.value
    this.profileCheckboxTargets.forEach(cb => {
      if (mode === 'all') { cb.checked = true; cb.disabled = true }
      else if (mode === 'none') { cb.checked = false; cb.disabled = true }
      else if (mode === 'selected') { cb.disabled = false }
    })
  }
}
