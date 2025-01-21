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
    const isOpen = this.isOpen()
    
    if (isOpen) {
      this.close()
      this.removeFromStorage()
    } else {
      this.open()
      this.addToStorage()
    }
  }

  sort(event) {
    const sortValue = event.target.value
    const trackingId = event.target.dataset.trackingId
    
    console.log('Sorting:', { sortValue, trackingId })
    
    // AJAX isteği gönder
    fetch(`/cars/${trackingId}/sort_scrapes?sort=${sortValue}`, {
      headers: {
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest'
      }
    })
    .then(response => {
      console.log('Response status:', response.status)
      return response.json()
    })
    .then(data => {
      console.log('Received data:', data)
      // Sıralanmış araçları göster
      const resultsList = this.element.querySelector('.scrape-results .scrape-results-list')
      if (!resultsList) {
        console.error('Results list element not found in:', this.element)
        return
      }
      resultsList.innerHTML = this.formatScrapes(data.scrapes)
    })
    .catch(error => {
      console.error('Error:', error)
    })
  }

  formatScrapes(scrapes) {
    return scrapes.map(scrape => `
      <div class="scraped-car ${scrape.is_new ? 'new-car' : ''}">
        <div class="car-image">
          <img src="${scrape.image_url}" alt="${scrape.title}">
          ${scrape.is_new ? '<div class="new-badge">Yeni!</div>' : ''}
        </div>
        <div class="car-details">
          <h5>${scrape.title}</h5>
          <div class="car-specs">
            <span><i class="fas fa-tachometer-alt"></i> ${this.formatNumber(scrape.km)} km</span>
            <span><i class="fas fa-calendar"></i> ${scrape.year}</span>
            <span><i class="fas fa-palette"></i> ${scrape.color}</span>
            <span><i class="fas fa-map-marker-alt"></i> ${scrape.city}</span>
          </div>
          <div class="car-dates">
            <span class="listing-date">
              <i class="fas fa-calendar-alt"></i> İlan Tarihi: ${scrape.public_date}
            </span>
            <span class="added-date">
              <i class="fas fa-clock"></i> Eklenme: ${scrape.created_at_ago} önce
            </span>
          </div>
          <div class="car-price">
            <span class="price">${this.formatCurrency(scrape.price)}</span>
            <a href="${scrape.product_url}" class="btn-view" target="_blank">İlana Git <i class="fas fa-external-link-alt"></i></a>
          </div>
        </div>
      </div>
    `).join('')
  }

  formatNumber(number) {
    // Sayıyı nokta ile formatlama (1234567 -> 1.234.567)
    return number.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ".");
  }

  formatCurrency(price) {
    // Fiyatı formatlama (₺ işareti sonda)
    const formattedPrice = new Intl.NumberFormat('tr-TR', { 
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    }).format(price);
    return `${formattedPrice} ₺`;
  }

  open() {
    this.contentTargets.forEach(target => {
      target.style.display = 'block'
    })
    this.iconTargets.forEach(target => {
      target.style.transform = 'rotate(180deg)'
    })
  }

  close() {
    this.contentTargets.forEach(target => {
      target.style.display = 'none'
    })
    this.iconTargets.forEach(target => {
      target.style.transform = 'rotate(0deg)'
    })
  }

  isOpen() {
    return this.contentTargets[0].style.display === 'block'
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
    const accordionId = this.element.dataset.accordionId
    const openAccordions = this.getStoredAccordions()
    
    if (!openAccordions.includes(accordionId)) {
      openAccordions.push(accordionId)
      localStorage.setItem('openAccordions', JSON.stringify(openAccordions))
    }
  }

  removeFromStorage() {
    const accordionId = this.element.dataset.accordionId
    const openAccordions = this.getStoredAccordions()
    
    const index = openAccordions.indexOf(accordionId)
    if (index > -1) {
      openAccordions.splice(index, 1)
      localStorage.setItem('openAccordions', JSON.stringify(openAccordions))
    }
  }
} 