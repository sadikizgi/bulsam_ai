import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay", "stepDot", "stepContent", "prevButton", "nextButton", "trackButton", "summary", "featuresOverlay"]

  connect() {
    this.currentStep = 1;
    this.totalSteps = 6;
    this.selections = {
      websites: [],
      cities: [],
      type: '',
      type_name: '',
      brand: '',
      brand_name: '',
      model: '',
      model_name: '',
      serial: '',
      serial_name: ''
    };
    this.currentTrackingId = null;
  }

  open(event) {
    event.preventDefault();
    console.log('Opening popup...');
    this.overlayTarget.classList.add('active');
    this.updateStepDisplay();
    this.updateSummary();
  }

  close() {
    console.log('Closing popup...');
    this.overlayTarget.classList.remove('active');
    this.resetPopup();
  }

  closeIfOverlay(event) {
    if (event.target === this.overlayTarget) {
      this.close();
    }
  }

  handleMultiSelect(event) {
    const card = event.currentTarget;
    const step = card.closest('.step-content').dataset.step;
    const value = card.dataset.value;
    
    card.classList.toggle('selected');
    
    switch(step) {
      case '1':
        if (card.classList.contains('selected')) {
          this.selections.websites.push(value);
          if (value === 'arabam') {
            this.element.querySelectorAll('.website-options .option-card').forEach(site => {
              if (site !== card) {
                site.classList.remove('selected');
                this.selections.websites = this.selections.websites.filter(w => w !== site.dataset.value);
              }
            });
          } else {
            const arabamCard = this.element.querySelector('.website-options .option-card[data-value="arabam"]');
            if (arabamCard) {
              arabamCard.classList.remove('selected');
              this.selections.websites = this.selections.websites.filter(w => w !== 'arabam');
            }
          }
        } else {
          this.selections.websites = this.selections.websites.filter(w => w !== value);
        }
        break;
      case '2':
        if (value === 'all') {
          if (card.classList.contains('selected')) {
            this.element.querySelectorAll('.city-options .option-card').forEach(city => {
              if (city !== card) {
                city.classList.remove('selected');
              }
            });
            this.selections.cities = ['all'];
          } else {
            this.selections.cities = [];
          }
        } else {
          const allOption = this.element.querySelector('.city-options .special-option');
          allOption.classList.remove('selected');
          this.selections.cities = this.selections.cities.filter(c => c !== 'all');
          
          if (card.classList.contains('selected')) {
            this.selections.cities.push(value);
          } else {
            this.selections.cities = this.selections.cities.filter(c => c !== value);
          }
        }
        break;
    }
    
    this.updateSummary();
    this.updateTrackButton();
  }

  handleSingleSelect(event) {
    const card = event.currentTarget;
    const step = card.closest('.step-content').dataset.step;
    const value = card.dataset.value;
    const name = card.querySelector('span').textContent;
    
    card.closest('.step-content').querySelectorAll('.option-card').forEach(c => {
      c.classList.remove('selected');
    });
    
    card.classList.add('selected');
    
    switch(step) {
      case '3':
        this.selections.type = value;
        this.selections.type_name = name;
        if (this.selections.websites.includes('arabam')) {
          this.loadArabamBrands(value);
        }
        break;
      case '4':
        this.selections.brand = value;
        this.selections.brand_name = name;
        if (this.selections.websites.includes('arabam')) {
          this.loadArabamModels(value);
        }
        break;
      case '5':
        this.selections.model = value;
        this.selections.model_name = name;
        if (this.selections.websites.includes('arabam')) {
          this.loadArabamSerials(value);
        }
        break;
      case '6':
        this.selections.serial = value;
        this.selections.serial_name = name;
        break;
    }
    
    this.updateSummary();
    this.updateTrackButton();
  }

  updateTrackButton() {
    const canTrack = this.currentStep >= 3 && 
                    this.selections.websites.length > 0 && 
                    this.selections.cities.length > 0 && 
                    this.selections.type;

    if (canTrack) {
      this.trackButtonTarget.style.visibility = 'visible';
      this.trackButtonTarget.style.opacity = '1';
    } else {
      this.trackButtonTarget.style.visibility = 'hidden';
      this.trackButtonTarget.style.opacity = '0';
    }
  }

  track() {
    this.createTracking().then(() => {
      this.close();
    });
  }

  async loadArabamBrands(categoryId) {
    try {
      const response = await fetch(`/api/categories/${categoryId}/brands`);
      const brands = await response.json();
      
      const brandContainer = this.element.querySelector('.brand-options');
      brandContainer.innerHTML = '';
      
      brands.forEach(brand => {
        const card = document.createElement('div');
        card.className = 'option-card';
        card.dataset.value = brand.id;
        card.dataset.action = 'click->popup#handleSingleSelect';
        card.innerHTML = `
          <i class="fas fa-car"></i>
          <span>${brand.name}</span>
        `;
        brandContainer.appendChild(card);
      });
    } catch (error) {
      console.error('Error loading brands:', error);
    }
  }

  async loadArabamModels(brandId) {
    try {
      const response = await fetch(`/api/brands/${brandId}/models`);
      const models = await response.json();
      
      const modelContainer = this.element.querySelector('.model-options');
      modelContainer.innerHTML = '';
      
      models.forEach(model => {
        const card = document.createElement('div');
        card.className = 'option-card';
        card.dataset.value = model.id;
        card.dataset.action = 'click->popup#handleSingleSelect';
        card.innerHTML = `
          <i class="fas fa-car"></i>
          <span>${model.name}</span>
        `;
        modelContainer.appendChild(card);
      });
    } catch (error) {
      console.error('Error loading models:', error);
    }
  }

  async loadArabamSerials(modelId) {
    try {
      const response = await fetch(`/api/models/${modelId}/serials`);
      const serials = await response.json();
      
      const serialContainer = this.element.querySelector('.serial-options');
      serialContainer.innerHTML = '';
      
      serials.forEach(serial => {
        const card = document.createElement('div');
        card.className = 'option-card';
        card.dataset.value = serial.id;
        card.dataset.action = 'click->popup#handleSingleSelect';
        card.innerHTML = `
          <i class="fas fa-car"></i>
          <span>${serial.name}</span>
        `;
        serialContainer.appendChild(card);
      });
    } catch (error) {
      console.error('Error loading serials:', error);
    }
  }

  async createTracking() {
    try {
      const trackingData = {
        websites: this.selections.websites,
        cities: this.selections.cities,
        category_id: this.selections.type
      };

      if (this.selections.brand) {
        trackingData.brand_id = this.selections.brand;
      }
      
      if (this.selections.model) {
        trackingData.model_id = this.selections.model;
      }
      
      if (this.selections.serial) {
        trackingData.serial_id = this.selections.serial;
      }

      const response = await fetch('/cars', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({
          tracking: trackingData
        })
      });

      if (response.ok) {
        Turbo.visit(window.location.href, { action: "replace" });
      } else {
        const errorData = await response.json();
        console.error('Error creating tracking:', errorData.errors);
        alert('Takip oluşturulurken bir hata oluştu: ' + errorData.errors.join(', '));
      }
    } catch (error) {
      console.error('Error:', error);
      alert('Takip oluşturulurken bir hata oluştu. Lütfen tekrar deneyin.');
    }
  }

  next() {
    const currentContent = this.stepContentTargets[this.currentStep - 1];
    
    if (this.currentStep === 1 && this.selections.websites.length === 0) {
      alert('Lütfen bir web sitesi seçin');
      return;
    }
    if (this.currentStep === 2 && this.selections.cities.length === 0) {
      alert('Lütfen en az bir şehir seçin');
      return;
    }
    
    if (this.currentStep > 2) {
      const selected = currentContent.querySelector('.option-card.selected');
      if (!selected) {
        alert('Lütfen bir seçim yapın');
        return;
      }
    }
    
    if (this.currentStep < this.totalSteps) {
      this.currentStep++;
      this.updateStepDisplay();
    } else {
      this.createTracking().then(() => {
        this.close();
      });
    }
  }

  prev() {
    if (this.currentStep > 1) {
      this.currentStep--;
      this.updateStepDisplay();
    }
  }

  updateStepDisplay() {
    this.stepDotTargets.forEach((dot, index) => {
      dot.classList.toggle('active', index + 1 <= this.currentStep);
    });
    
    this.stepContentTargets.forEach((content, index) => {
      content.classList.toggle('active', index + 1 === this.currentStep);
    });
    
    this.prevButtonTarget.style.display = this.currentStep > 1 ? 'block' : 'none';
    this.nextButtonTarget.textContent = this.currentStep === this.totalSteps ? 'Tamamla' : 'Devam Et';
    
    this.updateSummary();
    this.updateTrackButton();
  }

  updateSummary() {
    const hasSelections = this.selections.websites.length > 0 || 
                         this.selections.cities.length > 0 || 
                         this.selections.type || 
                         this.selections.brand || 
                         this.selections.model ||
                         this.selections.serial;
    
    if (hasSelections) {
      this.summaryTarget.style.display = 'block';
      if (this.selections.websites.length > 0) {
        this.element.querySelector('.website-selection').textContent = 
          `Web Siteleri: ${this.selections.websites.join(', ')}`;
      }
      if (this.selections.cities.length > 0) {
        this.element.querySelector('.city-selection').textContent = 
          `Şehirler: ${this.selections.cities.includes('all') ? 'Tüm Türkiye' : this.selections.cities.join(', ')}`;
      }
      if (this.selections.type) {
        this.element.querySelector('.type-selection').textContent = 
          `Araç Tipi: ${this.selections.type_name}`;
      }
      if (this.selections.brand) {
        this.element.querySelector('.brand-selection').textContent = 
          `Marka: ${this.selections.brand_name}`;
      }
      if (this.selections.model) {
        this.element.querySelector('.model-selection').textContent = 
          `Model: ${this.selections.model_name}`;
      }
      if (this.selections.serial) {
        this.element.querySelector('.serial-selection').textContent = 
          `Seri: ${this.selections.serial_name}`;
      }
    } else {
      this.summaryTarget.style.display = 'none';
    }
  }

  resetPopup() {
    this.currentStep = 1;
    this.selections = {
      websites: [],
      cities: [],
      type: '',
      type_name: '',
      brand: '',
      brand_name: '',
      model: '',
      model_name: '',
      serial: '',
      serial_name: ''
    };
    
    this.element.querySelectorAll('.option-card').forEach(card => {
      card.classList.remove('selected');
    });
    
    this.updateStepDisplay();
    this.summaryTarget.style.display = 'none';
    this.trackButtonTarget.style.visibility = 'hidden';
    this.trackButtonTarget.style.opacity = '0';
  }

  openFeatures(event) {
    event.preventDefault();
    this.currentTrackingId = event.currentTarget.dataset.trackingId;
    const popup = document.querySelector('.features-popup');
    popup.classList.add('active');
    this.loadCurrentFeatures();
  }

  closeFeatures() {
    const popup = document.querySelector('.features-popup');
    popup.classList.remove('active');
    this.currentTrackingId = null;
  }

  async loadCurrentFeatures() {
    try {
      const response = await fetch(`/cars/${this.currentTrackingId}/features`);
      const features = await response.json();
      this.populateFeatures(features);
    } catch (error) {
      console.error('Error loading features:', error);
    }
  }

  populateFeatures(features) {
    // Renk seçimlerini doldur
    if (features.colors) {
      features.colors.forEach(color => {
        const checkbox = this.element.querySelector(`input[name="colors[]"][value="${color}"]`);
        if (checkbox) checkbox.checked = true;
      });
    }

    // Kilometre aralığını doldur
    if (features.kilometer) {
      const [minKm, maxKm] = this.element.querySelectorAll('.range-inputs input');
      minKm.value = features.kilometer.min || '';
      maxKm.value = features.kilometer.max || '';
    }

    // Fiyat aralığını doldur
    if (features.price) {
      const [minPrice, maxPrice] = this.element.querySelectorAll('.feature-group:nth-child(3) .range-inputs input');
      minPrice.value = features.price.min || '';
      maxPrice.value = features.price.max || '';
    }

    // Satıcı tiplerini doldur
    if (features.seller_types) {
      features.seller_types.forEach(type => {
        const checkbox = this.element.querySelector(`input[name="seller_type[]"][value="${type}"]`);
        if (checkbox) checkbox.checked = true;
      });
    }

    // Vites tiplerini doldur
    if (features.transmission_types) {
      features.transmission_types.forEach(type => {
        const checkbox = this.element.querySelector(`input[name="transmission[]"][value="${type}"]`);
        if (checkbox) checkbox.checked = true;
      });
    }
  }

  async saveFeatures() {
    const features = this.collectFeatures();
    
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
        this.closeFeatures();
        // Sayfayı yenile
        Turbo.visit(window.location.href, { action: "replace" });
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
      colors: Array.from(this.element.querySelectorAll('input[name="colors[]"]:checked')).map(input => input.value),
      kilometer: {
        min: this.element.querySelector('.feature-group:nth-child(2) .range-inputs input:first-child').value,
        max: this.element.querySelector('.feature-group:nth-child(2) .range-inputs input:last-child').value
      },
      price: {
        min: this.element.querySelector('.feature-group:nth-child(3) .range-inputs input:first-child').value,
        max: this.element.querySelector('.feature-group:nth-child(3) .range-inputs input:last-child').value
      },
      seller_types: Array.from(this.element.querySelectorAll('input[name="seller_type[]"]:checked')).map(input => input.value),
      transmission_types: Array.from(this.element.querySelectorAll('input[name="transmission[]"]:checked')).map(input => input.value)
    };
  }
} 