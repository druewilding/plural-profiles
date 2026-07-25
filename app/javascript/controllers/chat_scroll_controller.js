import { Controller } from "@hotwired/stimulus"

// Chat message pane: starts scrolled to the newest message, and follows new
// messages as they arrive via Turbo Stream broadcast — but only while the
// reader is already at (or near) the bottom, so scrolling back to read older
// history (loaded into the turbo-frame at the top as you scroll up) doesn't
// get yanked back down from under them.
export default class extends Controller {
  static targets = ["scrollable", "messages"]

  connect() {
    this.stickToBottom = true
    this.scrollToBottom()

    this.onScroll = this.onScroll.bind(this)
    this.scrollableTarget.addEventListener("scroll", this.onScroll, { passive: true })

    this.observer = new MutationObserver(this.onMessagesChanged.bind(this))
    this.observer.observe(this.messagesTarget, { childList: true })
  }

  disconnect() {
    this.scrollableTarget.removeEventListener("scroll", this.onScroll)
    this.observer?.disconnect()
  }

  onScroll() {
    const el = this.scrollableTarget
    this.stickToBottom = el.scrollHeight - el.scrollTop - el.clientHeight < 150
  }

  onMessagesChanged(mutations) {
    // childList (non-subtree) mutations on #chat-messages only fire for new
    // messages appended at the end — older history loads into the nested
    // turbo-frame's own subtree, not as a direct child here.
    const appendedAtEnd = mutations.some((mutation) =>
      Array.from(mutation.addedNodes).some((node) => node === this.messagesTarget.lastElementChild)
    )
    if (appendedAtEnd && this.stickToBottom) this.scrollToBottom()
  }

  scrollToBottom() {
    this.scrollableTarget.scrollTop = this.scrollableTarget.scrollHeight
  }
}
