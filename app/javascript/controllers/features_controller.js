import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["popup", "form", "trackingId"]

  connect() {
    // Popup kapalı olarak başlasın
    this.closePopup()
    this.setupColorHandlers()
  }

  setupColorHandlers() {
    const allColorsCheckbox = this.formTarget.querySelector('input[value="Tüm Renkler"]')
    const otherColorCheckboxes = this.formTarget.querySelectorAll('input[name="colors[]"]:not([value="Tüm Renkler"])')

    if (allColorsCheckbox) {
      allColorsCheckbox.addEventListener('change', (e) => {
        if (e.target.checked) {
          otherColorCheckboxes.forEach(checkbox => {
            checkbox.checked = false
            checkbox.disabled = true
          })
        } else {
          otherColorCheckboxes.forEach(checkbox => {
            checkbox.disabled = false
          })
        }
      })
    }

    otherColorCheckboxes.forEach(checkbox => {
      checkbox.addEventListener('change', () => {
        if (checkbox.checked && allColorsCheckbox) {
          allColorsCheckbox.checked = false
        }
      })
    })
  }

  open(event) {
    const trackingId = event.currentTarget.dataset.trackingId
    this.trackingIdTarget.value = trackingId
    
    // Mevcut özellikleri getir
    fetch(`/cars/${trackingId}/features`)
      .then(response => response.json())
      .then(features => {
        this.populateFeatures(features)
      })
      .catch(error => {
        console.error('Error loading features:', error)
      })

    this.openPopup()
  }

  populateFeatures(features) {
    // Renkleri doldur
    const colorInputs = this.formTarget.querySelectorAll('input[name="colors[]"]')
    const allColorsCheckbox = this.formTarget.querySelector('input[value="Tüm Renkler"]')
    const otherColorCheckboxes = this.formTarget.querySelectorAll('input[name="colors[]"]:not([value="Tüm Renkler"])')

    if (features.colors && features.colors.includes('Tüm Renkler')) {
      allColorsCheckbox.checked = true
      otherColorCheckboxes.forEach(checkbox => {
        checkbox.checked = false
        checkbox.disabled = true
      })
    } else {
      colorInputs.forEach(input => {
        input.checked = features.colors && features.colors.includes(input.value)
      })
    }

    // Yıl aralığını doldur
    this.formTarget.querySelector('input[name="year_min"]').value = features.year_min || ''
    this.formTarget.querySelector('input[name="year_max"]').value = features.year_max || ''

    // Kilometre aralığını doldur
    this.formTarget.querySelector('input[name="kilometer_min"]').value = features.kilometer_min || ''
    this.formTarget.querySelector('input[name="kilometer_max"]').value = features.kilometer_max || ''

    // Fiyat aralığını doldur
    this.formTarget.querySelector('input[name="price_min"]').value = features.price_min || ''
    this.formTarget.querySelector('input[name="price_max"]').value = features.price_max || ''

    // Bildirim sıklığını doldur
    const frequencyInputs = this.formTarget.querySelectorAll('input[name="notification_frequency"]')
    frequencyInputs.forEach(input => {
      input.checked = input.value === features.notification_frequency
    })
  }

  save(event) {
    event.preventDefault()
    
    const trackingId = this.trackingIdTarget.value
    const formData = new FormData()

    // Renkleri topla
    const selectedColors = Array.from(this.formTarget.querySelectorAll('input[name="colors[]"]:checked'))
      .map(input => input.value)
    selectedColors.forEach(color => formData.append('colors[]', color))

    // Yıl aralığını ekle
    formData.append('year_min', this.formTarget.querySelector('input[name="year_min"]').value)
    formData.append('year_max', this.formTarget.querySelector('input[name="year_max"]').value)

    // Kilometre aralığını ekle
    formData.append('kilometer_min', this.formTarget.querySelector('input[name="kilometer_min"]').value)
    formData.append('kilometer_max', this.formTarget.querySelector('input[name="kilometer_max"]').value)

    // Fiyat aralığını ekle
    formData.append('price_min', this.formTarget.querySelector('input[name="price_min"]').value)
    formData.append('price_max', this.formTarget.querySelector('input[name="price_max"]').value)

    // Bildirim sıklığını ekle
    const selectedFrequency = this.formTarget.querySelector('input[name="notification_frequency"]:checked')
    if (selectedFrequency) {
      formData.append('notification_frequency', selectedFrequency.value)
    }

    fetch(`/cars/${trackingId}/features`, {
      method: 'PUT',
      body: formData,
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      }
    })
    .then(response => {
      if (response.ok) {
        window.location.reload()
      } else {
        throw new Error('Network response was not ok')
      }
    })
    .catch(error => {
      console.error('Error saving features:', error)
    })
  }

  close() {
    this.closePopup()
  }

  closeIfOverlay(event) {
    if (event.target === this.popupTarget) {
      this.closePopup()
    }
  }

  openPopup() {
    this.popupTarget.classList.add('active')
    document.body.style.overflow = 'hidden'
  }

  closePopup() {
    this.popupTarget.classList.remove('active')
    document.body.style.overflow = ''
  }
} 