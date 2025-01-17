import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["popup", "form", "trackingId"]

  connect() {
    console.log("Features controller connected");
  }

  open(event) {
    event.preventDefault();
    const trackingId = event.currentTarget.dataset.trackingId;
    console.log("Opening features popup for tracking ID:", trackingId);
    
    if (trackingId) {
      this.trackingIdTarget.value = trackingId;
      this.popupTarget.classList.add('active');
      this.loadCurrentFeatures(trackingId);
    } else {
      console.error("No tracking ID provided");
    }
  }

  close(event) {
    if (event) {
      event.preventDefault();
    }
    console.log("Closing features popup");
    this.popupTarget.classList.remove('active');
    this.resetForm();
  }

  closeIfOverlay(event) {
    if (event.target === event.currentTarget) {
      this.close();
    }
  }

  async loadCurrentFeatures(trackingId) {
    try {
      console.log("Loading features for tracking ID:", trackingId);
      const response = await fetch(`/cars/${trackingId}/features`);
      const features = await response.json();
      this.populateFeatures(features);
    } catch (error) {
      console.error('Error loading features:', error);
    }
  }

  populateFeatures(features) {
    console.log("Populating features:", features);
    this.resetForm();

    // Renk seçimlerini doldur
    if (features.colors && features.colors.length > 0) {
      features.colors.forEach(color => {
        const checkbox = this.formTarget.querySelector(`input[name="colors[]"][value="${color}"]`);
        if (checkbox) checkbox.checked = true;
      });
    }

    // Yıl aralığını doldur
    if (features.year_min) {
      this.formTarget.querySelector('input[name="year_min"]').value = features.year_min;
    }
    if (features.year_max) {
      this.formTarget.querySelector('input[name="year_max"]').value = features.year_max;
    }

    // Kilometre aralığını doldur
    if (features.kilometer_min) {
      this.formTarget.querySelector('input[name="kilometer_min"]').value = features.kilometer_min;
    }
    if (features.kilometer_max) {
      this.formTarget.querySelector('input[name="kilometer_max"]').value = features.kilometer_max;
    }

    // Fiyat aralığını doldur
    if (features.price_min) {
      this.formTarget.querySelector('input[name="price_min"]').value = features.price_min;
    }
    if (features.price_max) {
      this.formTarget.querySelector('input[name="price_max"]').value = features.price_max;
    }
  }

  resetForm() {
    // Renk seçimlerini sıfırla
    this.formTarget.querySelectorAll('input[name="colors[]"]').forEach(checkbox => {
      checkbox.checked = false;
    });

    // Yıl aralığını sıfırla
    this.formTarget.querySelector('input[name="year_min"]').value = '';
    this.formTarget.querySelector('input[name="year_max"]').value = '';

    // Kilometre aralığını sıfırla
    this.formTarget.querySelector('input[name="kilometer_min"]').value = '';
    this.formTarget.querySelector('input[name="kilometer_max"]').value = '';

    // Fiyat aralığını sıfırla
    this.formTarget.querySelector('input[name="price_min"]').value = '';
    this.formTarget.querySelector('input[name="price_max"]').value = '';
  }

  async save(event) {
    event.preventDefault();
    
    const trackingId = this.trackingIdTarget.value;
    if (!trackingId) {
      console.error("No tracking ID available");
      return;
    }

    // Form verilerini topla
    const features = {
      colors: Array.from(this.formTarget.querySelectorAll('input[name="colors[]"]:checked')).map(input => input.value),
      year_min: this.formTarget.querySelector('input[name="year_min"]').value || null,
      year_max: this.formTarget.querySelector('input[name="year_max"]').value || null,
      kilometer_min: this.formTarget.querySelector('input[name="kilometer_min"]').value || null,
      kilometer_max: this.formTarget.querySelector('input[name="kilometer_max"]').value || null,
      price_min: this.formTarget.querySelector('input[name="price_min"]').value || null,
      price_max: this.formTarget.querySelector('input[name="price_max"]').value || null
    };

    // Boş değerleri temizle
    Object.keys(features).forEach(key => {
      if (features[key] === '') {
        features[key] = null;
      }
    });

    console.log("Saving features:", features);

    try {
      const response = await fetch(`/cars/${trackingId}/features`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ features })
      });

      if (response.ok) {
        this.close();
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
} 