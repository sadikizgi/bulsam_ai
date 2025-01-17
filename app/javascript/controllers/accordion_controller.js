import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "icon"]

  connect() {
    this.contentTarget.style.display = "none"
  }

  toggle() {
    const isExpanded = this.contentTarget.style.display === "block"
    
    this.contentTarget.style.display = isExpanded ? "none" : "block"
    this.iconTarget.style.transform = isExpanded ? "rotate(0deg)" : "rotate(180deg)"
  }
} 