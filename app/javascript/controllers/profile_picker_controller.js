import { Controller } from "@hotwired/stimulus"

// The "post as" profile picker for plain forms (creating/joining a server) —
// clicking an option fills in a hidden field and updates the trigger, rather
// than firing an immediate PATCH like the composer's picker does. Controller
// root is the <details> itself (search filtering is a separate profile-filter
// controller instance scoped to the inner menu).
export default class extends Controller {
  static targets = [ "hiddenField", "triggerAvatar", "triggerName", "option" ]

  select(event) {
    const option = event.currentTarget

    this.hiddenFieldTarget.value = option.dataset.profileId

    const avatar = option.querySelector(".avatar")
    if (avatar && this.hasTriggerAvatarTarget) this.triggerAvatarTarget.replaceChildren(avatar.cloneNode(true))

    const name = option.querySelector(".profile-picker__option-name")
    if (name && this.hasTriggerNameTarget) this.triggerNameTarget.innerHTML = name.innerHTML

    this.element.open = false
  }
}
