import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    openAccordions: { type: Array, default: [] }
  }

  connect() {
    // Sayfa yüklendiğinde localStorage'dan açık accordion'ları al ve uygula
    const openAccordions = this.getStoredAccordions()
    if (openAccordions.length > 0) {
      this.restoreOpenAccordions(openAccordions)
    }
  }

  paginate(event) {
    event.preventDefault()
    
    // Açık accordion'ları localStorage'a kaydet
    const openAccordions = this.getOpenAccordions()
    this.storeAccordions(openAccordions)
    
    // Yeni sayfaya git
    window.location.href = event.currentTarget.href
  }
  
  getOpenAccordions() {
    const openAccordions = []
    document.querySelectorAll('[data-controller="accordion"]').forEach(accordion => {
      const content = accordion.querySelector('[data-accordion-target="content"]')
      if (content && window.getComputedStyle(content).display === 'block') {
        openAccordions.push(accordion.dataset.accordionId)
      }
    })
    return openAccordions
  }
  
  restoreOpenAccordions(accordionIds) {
    accordionIds.forEach(id => {
      const accordion = document.querySelector(`[data-accordion-id="${id}"]`)
      if (accordion) {
        const content = accordion.querySelector('[data-accordion-target="content"]')
        const icon = accordion.querySelector('[data-accordion-target="icon"]')
        if (content) {
          content.style.display = 'block'
          content.classList.add('open')
        }
        if (icon) {
          icon.classList.add('open')
        }
      }
    })
  }

  // localStorage'a accordion durumlarını kaydet
  storeAccordions(accordionIds) {
    localStorage.setItem('openAccordions', JSON.stringify(accordionIds))
  }

  // localStorage'dan accordion durumlarını al
  getStoredAccordions() {
    const stored = localStorage.getItem('openAccordions')
    return stored ? JSON.parse(stored) : []
  }
} 