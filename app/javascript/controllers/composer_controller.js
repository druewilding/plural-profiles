import { Controller } from "@hotwired/stimulus"

// Owns the whole "posting as" + message composer area. Enter sends the
// message, Shift+Enter inserts a newline. It also live-previews Tupperbox-
// style proxying: as you type, if the message matches one of your profiles'
// chat_bracket_before/chat_bracket_after (e.g. "guy:" ... or "{" ... "}"),
// the "Posting as" pill swaps to that profile's avatar/name — purely
// client-side, never touches the stored default. The real match happens
// again server-side on send
// (Profile.resolve_chat_proxy), this is just a preview.
//
// Usage: wrap the whole `.composer` block with data: { controller: "composer" },
// with data-composer-target="form"/"textarea" on the message form/textarea,
// "triggerAvatar"/"triggerName" on the posting-as pill's avatar/name, and
// "option" (plus data-prefix/data-suffix/data-name) on each profile in the
// posting-as picker.
export default class extends Controller {
  static targets = [ "form", "textarea", "triggerAvatar", "triggerName", "option" ]

  connect() {
    if (this.hasTriggerAvatarTarget) this.defaultAvatarHTML = this.triggerAvatarTarget.innerHTML
    if (this.hasTriggerNameTarget) this.defaultNameHTML = this.triggerNameTarget.innerHTML
  }

  submitOnEnter(event) {
    if (event.key !== "Enter" || event.shiftKey) return

    event.preventDefault()
    this.formTarget.requestSubmit()
  }

  detectProxy() {
    if (!this.hasTriggerAvatarTarget || !this.hasTriggerNameTarget) return

    const body = this.textareaTarget.value
    const match = this.matchProxy(body)

    if (match) {
      const avatar = match.option.querySelector(".avatar")
      if (avatar) this.triggerAvatarTarget.replaceChildren(avatar.cloneNode(true))
      const name = match.option.querySelector(".composer-posting-as__option-name")
      if (name) this.triggerNameTarget.innerHTML = name.innerHTML
    } else {
      this.triggerAvatarTarget.innerHTML = this.defaultAvatarHTML
      this.triggerNameTarget.innerHTML = this.defaultNameHTML
    }
  }

  // Mirrors Profile.resolve_chat_proxy (app/models/profile.rb) — case-
  // insensitive prefix/suffix match, longest (most specific) brackets win.
  matchProxy(body) {
    let best = null

    this.optionTargets.forEach((option) => {
      const prefix = option.dataset.prefix || ""
      const suffix = option.dataset.suffix || ""
      if (!prefix && !suffix) return
      if (body.length < prefix.length + suffix.length) return

      const bodyPrefix = body.slice(0, prefix.length).toLowerCase()
      if (bodyPrefix !== prefix.toLowerCase()) return

      if (suffix) {
        const bodySuffix = body.slice(body.length - suffix.length).toLowerCase()
        if (bodySuffix !== suffix.toLowerCase()) return
      }

      // Deliberately not requiring non-blank content here, unlike
      // Profile.resolve_chat_proxy: the preview should switch the instant the
      // brackets themselves match (e.g. right after typing "arki:"), not wait
      // for the first character of the actual message. The real send-time
      // match still requires content, so an empty send falls back to the
      // real default rather than posting a blank message as the wrong profile.
      const specificity = prefix.length + suffix.length
      if (!best || specificity > best.specificity) best = { option, specificity }
    })

    return best
  }
}
