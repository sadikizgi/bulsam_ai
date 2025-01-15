import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("Features controller connected");
    // Sayfa yüklendiğinde popup'ı kapat
    const popup = document.querySelector('.features-popup');
    if (popup) {
      popup.classList.remove('active');
    }
  }

  open(event) {
    event.preventDefault();
    console.log("Opening features popup", event.currentTarget.dataset.trackingId);
    
    const trackingId = event.currentTarget.dataset.trackingId;
    const popup = document.querySelector('.features-popup');
    
    if (popup) {
      this.currentTrackingId = trackingId;
      popup.classList.add('active');
      this.loadCurrentFeatures();
    } else {
      console.error("Features popup element not found");
    }
  }

  close(event) {
    if (event) {
      event.preventDefault();
    }
    console.log("Closing features popup");
    const popup = document.querySelector('.features-popup');
    if (popup) {
      popup.classList.remove('active');
      this.currentTrackingId = null;
    }
  }

  closeIfOverlay(event) {
    if (event.target === event.currentTarget) {
      this.close();
    }
  }

  async loadCurrentFeatures() {
    if (!this.currentTrackingId) {
      console.error("No tracking ID available");
      return;
    }

    try {
      console.log("Loading features for tracking ID:", this.currentTrackingId);
      const response = await fetch(`/cars/${this.currentTrackingId}/features`);
      const features = await response.json();
      this.populateFeatures(features);
    } catch (error) {
      console.error('Error loading features:', error);
    }
  }

  populateFeatures(features) {
    console.log("Populating features:", features);
    // Renk seçimlerini doldur
    if (features.colors) {
      features.colors.forEach(color => {
        const checkbox = document.querySelector(`input[name="colors[]"][value="${color}"]`);
        if (checkbox) checkbox.checked = true;
      });
    }

    // Kilometre aralığını doldur
    if (features.kilometer) {
      const [minKm, maxKm] = document.querySelectorAll('.range-inputs input');
      if (minKm) minKm.value = features.kilometer.min || '';
      if (maxKm) maxKm.value = features.kilometer.max || '';
    }

    // Fiyat aralığını doldur
    if (features.price) {
      const [minPrice, maxPrice] = document.querySelectorAll('.feature-group:nth-child(3) .range-inputs input');
      if (minPrice) minPrice.value = features.price.min || '';
      if (maxPrice) maxPrice.value = features.price.max || '';
    }

    // Satıcı tiplerini doldur
    if (features.seller_types) {
      features.seller_types.forEach(type => {
        const checkbox = document.querySelector(`input[name="seller_type[]"][value="${type}"]`);
        if (checkbox) checkbox.checked = true;
      });
    }

    // Vites tiplerini doldur
    if (features.transmission_types) {
      features.transmission_types.forEach(type => {
        const checkbox = document.querySelector(`input[name="transmission[]"][value="${type}"]`);
        if (checkbox) checkbox.checked = true;
      });
    }
  }

  async save() {
    if (!this.currentTrackingId) {
      console.error("No tracking ID available");
      return;
    }

    const features = this.collectFeatures();
    console.log("Saving features:", features);
    
    try {
      const response = await fetch(`/cars/${this.currentTrackingId}/features`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ features })
      });

      if (response.ok) {
        this.close();
        // Sayfayı yenile
        window.location.reload();
      } else {
        const errorData = await response.json();
        alert('Özellikler kaydedilirken bir hata oluştu: ' + errorData.errors.join(', '));
      }
    } catch (error) {
      console.error('Error saving features:', error);
      alert('Özellikler kaydedilirken bir hata oluştu. Lütfen tekrar deneyin.');
    }
  }

  collectFeatures() {
    return {
      colors: Array.from(document.querySelectorAll('input[name="colors[]"]:checked')).map(input => input.value),
      kilometer: {
        min: document.querySelector('.feature-group:nth-child(2) .range-inputs input:first-child').value,
        max: document.querySelector('.feature-group:nth-child(2) .range-inputs input:last-child').value
      },
      price: {
        min: document.querySelector('.feature-group:nth-child(3) .range-inputs input:first-child').value,
        max: document.querySelector('.feature-group:nth-child(3) .range-inputs input:last-child').value
      },
      seller_types: Array.from(document.querySelectorAll('input[name="seller_type[]"]:checked')).map(input => input.value),
      transmission_types: Array.from(document.querySelectorAll('input[name="transmission[]"]:checked')).map(input => input.value)
    };
  }
} 