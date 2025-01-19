import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "icon"]

  connect() {
    const accordionId = this.getAccordionId()
    const openAccordions = this.getOpenAccordions()
    
    if (openAccordions.includes(accordionId)) {
      this.contentTarget.style.display = "block"
      this.iconTarget.style.transform = "rotate(180deg)"
    } else {
      this.contentTarget.style.display = "none"
      this.iconTarget.style.transform = "rotate(0deg)"
    }
  }

  toggle() {
    const isExpanded = this.contentTarget.style.display === "block"
    const accordionId = this.getAccordionId()
    
    if (!isExpanded) {
      this.contentTarget.style.display = "block"
      this.iconTarget.style.transform = "rotate(180deg)"
      this.addToOpenAccordions(accordionId)
    } else {
      this.contentTarget.style.display = "none"
      this.iconTarget.style.transform = "rotate(0deg)"
      this.removeFromOpenAccordions(accordionId)
    }
  }

  getAccordionId() {
    // Önce data-accordion-id'yi kontrol et
    const accordionId = this.element.dataset.accordionId
    if (accordionId) return accordionId

    // Eğer yoksa, element sınıfından bir ID oluştur
    const elementClasses = this.element.className.split(' ')
    if (elementClasses.includes('tracked-item')) {
      const header = this.element.querySelector('.item-header h3')
      return `category-${header.textContent.toLowerCase().replace(/\s+/g, '-')}`
    }
    if (elementClasses.includes('source-group')) {
      const sourceHeader = this.element.querySelector('.source-header h5')
      return `source-${sourceHeader.textContent.toLowerCase().replace(/\s+/g, '-')}`
    }
    if (elementClasses.includes('tracking-group')) {
      const trackingHeader = this.element.querySelector('.tracking-header h6')
      return `tracking-${trackingHeader.textContent.toLowerCase().replace(/\s+/g, '-')}`
    }
    
    return `accordion-${Math.random().toString(36).substr(2, 9)}`
  }

  getOpenAccordions() {
    const stored = sessionStorage.getItem('openAccordions')
    return stored ? JSON.parse(stored) : []
  }

  addToOpenAccordions(id) {
    const openAccordions = this.getOpenAccordions()
    if (!openAccordions.includes(id)) {
      openAccordions.push(id)
      sessionStorage.setItem('openAccordions', JSON.stringify(openAccordions))
    }
  }

  removeFromOpenAccordions(id) {
    const openAccordions = this.getOpenAccordions()
    const index = openAccordions.indexOf(id)
    if (index > -1) {
      openAccordions.splice(index, 1)
      sessionStorage.setItem('openAccordions', JSON.stringify(openAccordions))
    }
  }
} 