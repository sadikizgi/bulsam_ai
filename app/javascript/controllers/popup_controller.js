import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay", "stepDot", "stepContent", "prevButton", "nextButton", "summary"]

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
  }

  open(event) {
    event.preventDefault();
    console.log('Opening popup...');
    this.overlayTarget.classList.add('active');
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
            // arabam.com seçildiğinde diğer siteleri devre dışı bırak
            this.element.querySelectorAll('.website-options .option-card').forEach(site => {
              if (site !== card) {
                site.classList.remove('selected');
                this.selections.websites = this.selections.websites.filter(w => w !== site.dataset.value);
              }
            });
          } else {
            // başka site seçildiğinde arabam.com'u devre dışı bırak
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
      const response = await fetch('/cars', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({
          tracking: {
            websites: this.selections.websites,
            cities: this.selections.cities,
            category_id: this.selections.type,
            brand_id: this.selections.brand,
            model_id: this.selections.model,
            serial_id: this.selections.serial
          }
        })
      });

      if (response.ok) {
        // Sayfayı yeniden yüklemek yerine Turbo ile güncelleyelim
        Turbo.visit(window.location.href, { action: "replace" });
      } else {
        console.error('Error creating tracking');
      }
    } catch (error) {
      console.error('Error:', error);
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
  }
} 