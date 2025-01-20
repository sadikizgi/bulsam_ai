import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "icon"]

  connect() {
    // Reset all accordions when entering notifications page
    if (window.location.pathname === '/notifications') {
      localStorage.removeItem('openAccordions')
      this.close()
    } else {
      const accordionId = this.getAccordionId()
      const openAccordions = this.getStoredAccordions()
      
      if (openAccordions.includes(accordionId)) {
        this.open()
      } else {
        this.close()
      }
    }
  }

  toggle() {
    if (this.isOpen()) {
      this.close()
      this.removeFromStorage()
    } else {
      this.open()
      this.addToStorage()
    }
  }

  open() {
    this.contentTarget.style.display = 'block'
    this.contentTarget.classList.add('open')
    this.iconTarget.classList.add('open')
  }

  close() {
    this.contentTarget.style.display = 'none'
    this.contentTarget.classList.remove('open')
    this.iconTarget.classList.remove('open')
  }

  isOpen() {
    return this.contentTarget.style.display === 'block'
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

  getStoredAccordions() {
    const stored = localStorage.getItem('openAccordions')
    return stored ? JSON.parse(stored) : []
  }

  addToStorage() {
    const openAccordions = this.getStoredAccordions()
    const accordionId = this.element.dataset.accordionId
    if (!openAccordions.includes(accordionId)) {
      openAccordions.push(accordionId)
      localStorage.setItem('openAccordions', JSON.stringify(openAccordions))
    }
  }

  removeFromStorage() {
    const openAccordions = this.getStoredAccordions()
    const accordionId = this.element.dataset.accordionId
    const index = openAccordions.indexOf(accordionId)
    if (index > -1) {
      openAccordions.splice(index, 1)
      localStorage.setItem('openAccordions', JSON.stringify(openAccordions))
    }
  }
} 