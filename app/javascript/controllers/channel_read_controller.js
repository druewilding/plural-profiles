import { Controller } from "@hotwired/stimulus"

// Marks the channel as read once this page has actually mounted into the
// DOM. Deliberately not a side effect of the channel's own GET request --
// Turbo 8 prefetches links on hover, and a GET that marks the channel read
// would silently clear the unread dot the moment a pointer passed over the
// sidebar link, before the reader ever opened it. connect() only fires on a
// genuine Turbo visit (prefetch caches the response but never inserts it
// into the document, so Stimulus never connects to it).
export default class extends Controller {
  static values = { url: String }

  connect() {
    fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content,
        "Accept": "text/plain"
      }
    })
  }
}
