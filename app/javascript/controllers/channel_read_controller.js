import { Controller } from "@hotwired/stimulus"

// Marks the channel as read once this page has actually mounted into the
// DOM, and again every time a new message streams in live while it's still
// open. Deliberately not a side effect of the channel's own GET request --
// Turbo 8 prefetches links on hover, and a GET that marks the channel read
// would silently clear the unread dot the moment a pointer passed over the
// sidebar link, before the reader ever opened it. connect() only fires on a
// genuine Turbo visit (prefetch caches the response but never inserts it
// into the document, so Stimulus never connects to it).
//
// Re-marking on every live message matters for the server-rail dot
// specifically: the server broadcasts an optimistic "unread" the moment
// anyone else posts, with no way to know the recipient is actually looking
// right at that channel. Without this, the rail icon would light up even
// while you're mid-conversation in the very channel that caused it. Chasing
// each new message with a fresh read marker keeps that self-correcting
// (a brief flicker at worst) without needing real presence tracking.
export default class extends Controller {
  static values = { url: String }

  connect() {
    this.markRead()

    const messages = this.element.querySelector("#chat-messages")
    if (messages) {
      this.observer = new MutationObserver(() => this.markRead())
      this.observer.observe(messages, { childList: true })
    }
  }

  disconnect() {
    this.observer?.disconnect()
  }

  markRead() {
    fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content,
        "Accept": "text/plain"
      }
    })
  }
}
