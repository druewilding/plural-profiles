import { Controller } from "@hotwired/stimulus"

// Enter sends the message, Shift+Enter inserts a newline — matches chat-app conventions.
// Usage: form_with(..., data: { controller: "composer" }) around a text_area with
// data: { action: "keydown->composer#submitOnEnter" }
export default class extends Controller {
  submitOnEnter(event) {
    if (event.key !== "Enter" || event.shiftKey) return

    event.preventDefault()
    this.element.requestSubmit()
  }
}
