import { Controller } from "@hotwired/stimulus"

// Manages the avatar editor <dialog> on profile/group edit forms.
//
// The dialog lives inside the <form>, so all its inputs (file, alt text,
// shape, remove) participate in the normal form submission.
//
// Usage: data-controller="avatar-editor" on a wrapper inside the form.
export default class extends Controller {
  static targets = [
    "dialog",
    "fileInput",
    "dialogPreview",      // <img> inside the dialog (always present, may be hidden)
    "dialogPlaceholder",  // placeholder div inside the dialog (always present, may be hidden)
    "mainPreview",        // <img> on the main form (always present, may be hidden)
    "mainPlaceholder",    // placeholder div on the main form (always present, may be hidden)
    "removeCheckbox",
    "shapeInput",
    "altTextField"
  ]

  connect() {
    this._snapshot = null
    this._objectUrl = null

    // When JS is active, start with the dialog closed (it has `open` in the HTML
    // for no-JS users so they can still access the form fields inline).
    if (this.dialogTarget.open) this.dialogTarget.close()

    // Close dialog on Escape — native behaviour fires `cancel` event on <dialog>
    this.dialogTarget.addEventListener("cancel", (e) => {
      e.preventDefault()
      this.cancel()
    })
  }

  disconnect() {
    this._revokeObjectUrl()
  }

  // ── Open ──────────────────────────────────────────────────────────────────

  open() {
    this._snapshot = {
      altText: this.altTextFieldTarget.value,
      shape: this._currentShape(),
      removeChecked: this.hasRemoveCheckboxTarget && this.removeCheckboxTarget.checked,
      dialogPreviewSrc: this.dialogPreviewTarget.src,
      dialogPreviewHidden: this.dialogPreviewTarget.hidden,
      dialogPreviewClass: this.dialogPreviewTarget.className,
      dialogPlaceholderHidden: this.hasDialogPlaceholderTarget ? this.dialogPlaceholderTarget.hidden : true,
      mainPreviewSrc: this.mainPreviewTarget.src,
      mainPreviewHidden: this.mainPreviewTarget.hidden,
      mainPreviewClass: this.mainPreviewTarget.className,
      mainPlaceholderHidden: this.hasMainPlaceholderTarget ? this.mainPlaceholderTarget.hidden : true
    }
    this.dialogTarget.showModal()
  }

  // ── Close (Done) ──────────────────────────────────────────────────────────

  close() {
    if (this.hasRemoveCheckboxTarget && this.removeCheckboxTarget.checked) {
      this._showMainPlaceholder()
      this._showDialogPlaceholder()
    } else if (!this.dialogPreviewTarget.hidden) {
      this._showMainImage(this.dialogPreviewTarget.src)
    }
    this._applyShapeToElement(this.mainPreviewTarget)
    this.dialogTarget.close()

    // Lets listeners (e.g. the chat-identity settings page's live preview)
    // reflect a picked-but-unsaved file without re-uploading it anywhere —
    // this is the same object URL already used for the in-dialog preview.
    this.dispatch("changed", {
      detail: {
        src: this.mainPreviewTarget.hidden ? null : this.mainPreviewTarget.src,
        shape: this._currentShape()
      }
    })
  }

  // ── Cancel ────────────────────────────────────────────────────────────────

  cancel() {
    if (!this._snapshot) { this.dialogTarget.close(); return }

    this.altTextFieldTarget.value = this._snapshot.altText

    this.shapeInputTargets.forEach(input => {
      input.checked = (input.value === this._snapshot.shape)
    })

    if (this.hasRemoveCheckboxTarget) {
      this.removeCheckboxTarget.checked = this._snapshot.removeChecked
    }

    try { this.fileInputTarget.value = "" } catch (_e) {}
    this._revokeObjectUrl()

    this.dialogPreviewTarget.src = this._snapshot.dialogPreviewSrc
    this.dialogPreviewTarget.hidden = this._snapshot.dialogPreviewHidden
    this.dialogPreviewTarget.className = this._snapshot.dialogPreviewClass
    if (this.hasDialogPlaceholderTarget) {
      this.dialogPlaceholderTarget.hidden = this._snapshot.dialogPlaceholderHidden
    }

    this.mainPreviewTarget.src = this._snapshot.mainPreviewSrc
    this.mainPreviewTarget.hidden = this._snapshot.mainPreviewHidden
    this.mainPreviewTarget.className = this._snapshot.mainPreviewClass
    if (this.hasMainPlaceholderTarget) {
      this.mainPlaceholderTarget.hidden = this._snapshot.mainPlaceholderHidden
    }

    this.dialogTarget.close()
  }

  // ── File selection ────────────────────────────────────────────────────────

  onFileChange() {
    const file = this.fileInputTarget.files[0]
    if (!file) return
    this._revokeObjectUrl()
    this._objectUrl = URL.createObjectURL(file)
    if (this.hasRemoveCheckboxTarget) this.removeCheckboxTarget.checked = false
    this._showDialogImage(this._objectUrl)
  }

  // ── Shape selection ───────────────────────────────────────────────────────

  onShapeChange() {
    this._applyShapeToElement(this.dialogPreviewTarget)
  }

  // ── Remove checkbox ───────────────────────────────────────────────────────

  onRemoveChange() {
    if (!this.hasRemoveCheckboxTarget) return
    if (this.removeCheckboxTarget.checked) {
      try { this.fileInputTarget.value = "" } catch (_e) {}
      this._revokeObjectUrl()
      this._showDialogPlaceholder()
    } else if (this._snapshot && this._snapshot.dialogPreviewSrc) {
      this._showDialogImage(this._snapshot.dialogPreviewSrc)
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  _currentShape() {
    const checked = this.shapeInputTargets.find(i => i.checked)
    return checked ? checked.value : "rounded"
  }

  _applyShapeToElement(el) {
    el.classList.remove("avatar--circle", "avatar--square")
    const shape = this._currentShape()
    if (shape === "circle") el.classList.add("avatar--circle")
    if (shape === "square") el.classList.add("avatar--square")
    // "rounded" is the default .avatar style — no extra class needed
  }

  _showDialogImage(src) {
    this.dialogPreviewTarget.src = src
    this.dialogPreviewTarget.hidden = false
    this._applyShapeToElement(this.dialogPreviewTarget)
    if (this.hasDialogPlaceholderTarget) this.dialogPlaceholderTarget.hidden = true
  }

  _showDialogPlaceholder() {
    this.dialogPreviewTarget.hidden = true
    if (this.hasDialogPlaceholderTarget) this.dialogPlaceholderTarget.hidden = false
  }

  _showMainImage(src) {
    this.mainPreviewTarget.src = src
    this.mainPreviewTarget.hidden = false
    if (this.hasMainPlaceholderTarget) this.mainPlaceholderTarget.hidden = true
  }

  _showMainPlaceholder() {
    this.mainPreviewTarget.hidden = true
    if (this.hasMainPlaceholderTarget) this.mainPlaceholderTarget.hidden = false
  }

  _revokeObjectUrl() {
    if (this._objectUrl) {
      URL.revokeObjectURL(this._objectUrl)
      this._objectUrl = null
    }
  }
}
