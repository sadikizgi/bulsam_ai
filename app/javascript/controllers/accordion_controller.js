import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "icon"]

  connect() {
    const trackingId = this.element.dataset.trackingId
    const openAccordion = new URLSearchParams(window.location.search).get('open_accordion')
    
    if (openAccordion && openAccordion === trackingId) {
      this.contentTarget.style.display = "block"
      this.iconTarget.style.transform = "rotate(180deg)"
    } else {
      this.contentTarget.style.display = "none"
      this.iconTarget.style.transform = "rotate(0deg)"
    }
  }

  toggle() {
    const isExpanded = this.contentTarget.style.display === "block"
    const trackingId = this.element.dataset.trackingId
    const currentUrl = new URL(window.location.href)
    const params = new URLSearchParams(currentUrl.search)
    
    if (!isExpanded) {
      params.set('open_accordion', trackingId)
      this.contentTarget.style.display = "block"
      this.iconTarget.style.transform = "rotate(180deg)"
    } else {
      params.delete('open_accordion')
      this.contentTarget.style.display = "none"
      this.iconTarget.style.transform = "rotate(0deg)"
    }
    
    // Update URL without reloading the page
    window.history.replaceState({}, '', `${currentUrl.pathname}?${params.toString()}`)
  }
} 