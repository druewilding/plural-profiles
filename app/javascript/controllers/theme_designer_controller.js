import { Controller } from "@hotwired/stimulus"

// Maps theme property names (underscore) to CSS custom property names (hyphen)
function cssProp(property) {
  return `--${property.replace(/_/g, "-")}`
}

export default class extends Controller {
  static targets = ["colorInput", "hexInput", "preview", "cssOutput", "copyLabel"]

  connect() {
    this.applyAllToPreview()
  }

  // Called when a colour picker changes
  updatePreview(event) {
    const input = event.currentTarget
    const property = input.dataset.property
    const value = input.value

    // Sync the hex text input
    const hexInput = this.hexInputTargets.find(el => el.dataset.property === property)
    if (hexInput) hexInput.value = value

    this.applyToPreview(property, value)
    this.updateCssOutput()
  }

  // Called when the hex text input changes
  updateFromHex(event) {
    const input = event.currentTarget
    const property = input.dataset.property
    let value = input.value.trim()

    // Auto-add # prefix
    if (value.length && value[0] !== "#") value = `#${value}`

    // Only apply if it looks like a valid hex colour
    if (/^#[0-9a-fA-F]{6}$/.test(value)) {
      const colorInput = this.colorInputTargets.find(el => el.dataset.property === property)
      if (colorInput) colorInput.value = value

      this.applyToPreview(property, value)
      this.updateCssOutput()
    }
  }

  // Apply a single property to the preview container
  applyToPreview(property, value) {
    if (!this.hasPreviewTarget) return
    this.previewTarget.style.setProperty(cssProp(property), value)

    // Also update computed properties that depend on text
    if (property === "text") {
      this.previewTarget.style.setProperty("--tree-guide", `color-mix(in srgb, ${value} 30%, transparent)`)
      this.previewTarget.style.setProperty("--avatar-placeholder-border", `color-mix(in srgb, ${value} 50%, transparent)`)
    }
  }

  // Apply all current colours to the preview
  applyAllToPreview() {
    this.colorInputTargets.forEach(input => {
      this.applyToPreview(input.dataset.property, input.value)
    })
  }

  // Regenerate the CSS output textarea
  updateCssOutput() {
    if (!this.hasCssOutputTarget) return

    const lines = this.colorInputTargets.map(input => {
      const prop = cssProp(input.dataset.property)
      return `  ${prop}: ${input.value};`
    })

    this.cssOutputTarget.value = `:root {\n${lines.join("\n")}\n}`
  }

  // Copy CSS to clipboard
  copyCss() {
    if (!this.hasCssOutputTarget) return

    navigator.clipboard.writeText(this.cssOutputTarget.value).then(() => {
      if (this.hasCopyLabelTarget) {
        const label = this.copyLabelTarget
        const original = label.textContent
        label.textContent = "Copied!"
        setTimeout(() => { label.textContent = original }, 2000)
      }
    })
  }

  // Reset all colours to defaults
  resetDefaults(event) {
    event.preventDefault()

    this.colorInputTargets.forEach(input => {
      const property = input.dataset.property
      const defaultValue = this.defaultFor(property)
      if (defaultValue) {
        input.value = defaultValue
        const hexInput = this.hexInputTargets.find(el => el.dataset.property === property)
        if (hexInput) hexInput.value = defaultValue
        this.applyToPreview(property, defaultValue)
      }
    })

    this.updateCssOutput()
  }

  // Look up the default from the data attribute on the colour input
  defaultFor(property) {
    // Defaults are defined in the Theme model; we embed them as a JSON map
    // on the controller element for client-side access.
    const defaults = {
      page_bg: "#0e2e24",
      pane_bg: "#133b2f",
      pane_border: "#02120e",
      text: "#5ea389",
      link: "#3ab580",
      heading: "#5ea389",
      primary_button_bg: "#11694a",
      primary_button_text: "#58cc9d",
      secondary_button_text: "#58cc9d",
      danger_button_bg: "#a81d49",
      danger_button_text: "#e6c4cf",
      input_bg: "#263a2e",
      input_border: "#5ea389",
      spoiler: "#3A3A3A",
      notice_bg: "#133b2f",
      notice_border: "#5ea389",
      notice_text: "#5ea389",
      alert_bg: "#11694a",
      alert_border: "#58cc9d",
      alert_text: "#58cc9d",
      warning_bg: "#a81d49",
      warning_border: "#e6c4cf",
      warning_text: "#e6c4cf"
    }
    return defaults[property]
  }
}
