import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "icon"]

  connect() {
    const currentPath = window.location.pathname;
  
    // Mevcut açık accordion ID'lerini al
    const openAccordions = this.getStoredAccordions();
    const accordionId = this.getAccordionId();
  
    if (currentPath === '/notifications') {
      // Bildirimler sayfasında, accordion durumunu kontrol et
      if (openAccordions.includes(accordionId)) {
        this.open(); // Eğer zaten açıksa açık bırak
      } else {
        this.close(); // Kapalı değilse kapat
      }
    } else {
      // Diğer sayfalarda da aynı kontrol geçerli
      if (openAccordions.includes(accordionId)) {
        this.open(); // Eğer açık durumdaysa açık bırak
      } else {
        this.close(); // Kapalı durumdaysa kapalı bırak
      }
    }
  }
  
  getStoredAccordions() {
    // localStorage'dan açık accordion'ları al
    return JSON.parse(localStorage.getItem('openAccordions') || '[]');
  }
  
  storeAccordion(accordionId) {
    // localStorage'da accordion ID'sini sakla
    const openAccordions = this.getStoredAccordions();
    if (!openAccordions.includes(accordionId)) {
      openAccordions.push(accordionId);
      localStorage.setItem('openAccordions', JSON.stringify(openAccordions));
    }
  }
  
  removeAccordion(accordionId) {
    // localStorage'dan accordion ID'sini kaldır
    const openAccordions = this.getStoredAccordions().filter(id => id !== accordionId);
    localStorage.setItem('openAccordions', JSON.stringify(openAccordions));
  }
  
  open() {
    // Accordion'u aç
    this.element.classList.add('is-open');
    this.storeAccordion(this.getAccordionId()); // Açık durumunu kaydet
  }
  
  close() {
    // Accordion'u kapat
    this.element.classList.remove('is-open');
    this.removeAccordion(this.getAccordionId()); // Kapalı durumunu kaydet
  }
  
  getAccordionId() {
    // Her accordion'a özel bir ID döndür (örneğin data-attribute)
    return this.element.getAttribute('data-accordion-id');
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
    const page = 1 // İlk sayfa için
    
    this.fetchSortedResults(sortValue, trackingId, page)
  }

  fetchSortedResults(sortValue, trackingId, page) {
    fetch(`/cars/${trackingId}/sort_scrapes?sort=${sortValue}&page=${page}`, {
      headers: {
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest'
      }
    })
    .then(response => response.json())
    .then(data => {
      const resultsList = this.element.querySelector('.scrape-results .scrape-results-list')
      if (!resultsList) {
        console.error('Results list element not found in:', this.element)
        return
      }
      
      // Araç listesini güncelle
      const carsHtml = this.formatScrapes(data.scrapes)
      
      // Pagination'ı oluştur
      const paginationHtml = this.formatPagination(data.pagination, trackingId, sortValue)
      
      // Her ikisini de ekle
      resultsList.innerHTML = carsHtml + paginationHtml
      
      // Pagination linklerine click event listener'ları ekle
      this.setupPaginationListeners(resultsList, trackingId, sortValue)

      // Accordion'un başına scroll yap
      this.element.scrollIntoView({ behavior: 'smooth', block: 'start' })
    })
    .catch(error => {
      console.error('Error:', error)
    })
  }

  formatScrapes(scrapes) {
    return scrapes.map(scrape => {
      // Eğer is_new false ise (24 saat geçmiş veya yeni değil), badge gösterme
      let badgeHtml = '';
      
      if (scrape.is_new) {
        const publicDate = new Date(scrape.public_date);
        const addDate = new Date(scrape.add_date);
        const isSameDay = publicDate.toDateString() === addDate.toDateString();
        badgeHtml = `<div class="new-badge ${isSameDay ? '' : 'republished'}">${isSameDay ? 'Yeni!' : 'Yeniden Yayında!'}</div>`;
      }

      return `
        <div class="scraped-car ${scrape.is_new ? 'new-car' : ''}">
          <div class="car-image">
            <img src="${scrape.image_url}" alt="${scrape.title}">
            ${badgeHtml}
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
      `;
    }).join('');
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

  formatPagination(pagination, trackingId, sortValue) {
    if (pagination.total_items <= 5) return ''

    let html = `
      <div class="pagination">
        <div class="pagination-info">
          Toplam ${pagination.total_items} sonuç, 
          Sayfa ${pagination.current_page} / ${pagination.total_pages}
        </div>
        <div class="pagination-links">`

    // Önceki sayfa linki
    if (pagination.has_previous) {
      html += `
        <a href="#" class="pagination-link" data-page="${pagination.current_page - 1}">
          ← Önceki
        </a>`
    }

    // Sayfa numaraları
    for (let p = 1; p <= pagination.total_pages; p++) {
      if (p <= 3 || p === pagination.total_pages || Math.abs(p - pagination.current_page) <= 1) {
        if (p === pagination.current_page) {
          html += `<span class="pagination-link active">${p}</span>`
        } else {
          html += `<a href="#" class="pagination-link" data-page="${p}">${p}</a>`
        }
      } else if (p === 4 && pagination.total_pages > 5) {
        html += `<span class="pagination-ellipsis">...</span>`
      }
    }

    // Sonraki sayfa linki
    if (pagination.has_next) {
      html += `
        <a href="#" class="pagination-link" data-page="${pagination.current_page + 1}">
          Sonraki →
        </a>`
    }

    html += `
        </div>
      </div>`

    return html
  }

  setupPaginationListeners(container, trackingId, sortValue) {
    const links = container.querySelectorAll('.pagination-link[data-page]')
    links.forEach(link => {
      link.addEventListener('click', (e) => {
        e.preventDefault()
        const page = e.target.dataset.page
        this.fetchSortedResults(sortValue, trackingId, page)
      })
    })
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