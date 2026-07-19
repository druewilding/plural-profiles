import { Controller } from "@hotwired/stimulus"

// Detects the browser's IANA time zone and stashes it in a cookie so the
// server can render timestamps in the viewer's local time. Only takes
// effect from the next request onward, since the current page has already
// been rendered server-side by the time this runs.
export default class extends Controller {
  static COOKIE_NAME = "browser_time_zone"

  connect() {
    const detected = Intl.DateTimeFormat().resolvedOptions().timeZone
    if (!detected) return

    if (this.currentCookieValue() !== detected) {
      const oneYear = 365 * 24 * 60 * 60
      document.cookie = `${this.constructor.COOKIE_NAME}=${encodeURIComponent(detected)}; path=/; max-age=${oneYear}; SameSite=Lax`
    }
  }

  currentCookieValue() {
    const match = document.cookie
      .split("; ")
      .find(row => row.startsWith(`${this.constructor.COOKIE_NAME}=`))
    if (!match) return null

    const rawValue = match.split("=").slice(1).join("=")
    try {
      return decodeURIComponent(rawValue)
    } catch {
      return null
    }
  }
}
