import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay", "stepDot", "stepContent", "prevButton", "nextButton", "summary"]

  connect() {
    this.currentStep = 1;
    this.totalSteps = 5;
    this.selections = {
      websites: [],
      cities: [],
      type: '',
      brand: '',
      model: ''
    };

    // Araç verileri
    this.vehicleData = {
      otomobil: {
        volkswagen: ['Polo', 'Golf', 'Passat', 'Arteon'],
        bmw: ['1 Serisi', '3 Serisi', '5 Serisi', '7 Serisi'],
        mercedes: ['A Serisi', 'C Serisi', 'E Serisi', 'S Serisi']
      },
      suv: {
        volkswagen: ['T-Roc', 'Tiguan', 'Touareg'],
        bmw: ['X1', 'X3', 'X5', 'X7'],
        mercedes: ['GLA', 'GLC', 'GLE', 'GLS']
      }
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
    
    card.closest('.step-content').querySelectorAll('.option-card').forEach(c => {
      c.classList.remove('selected');
    });
    
    card.classList.add('selected');
    
    switch(step) {
      case '3':
        this.selections.type = value;
        this.updateBrandOptions(value);
        break;
      case '4':
        this.selections.brand = value;
        this.updateModelOptions(this.selections.type, value);
        break;
      case '5':
        this.selections.model = value;
        break;
    }
    
    this.updateSummary();
  }

  next() {
    const currentContent = this.stepContentTargets[this.currentStep - 1];
    
    if (this.currentStep === 1 && this.selections.websites.length === 0) {
      alert('Lütfen en az bir web sitesi seçin');
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
      console.log('Final selections:', this.selections);
      this.close();
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

  updateBrandOptions(type) {
    const brandContainer = this.element.querySelector('.brand-options');
    brandContainer.innerHTML = '';
    
    const brands = Object.keys(this.vehicleData[type] || {});
    brands.forEach(brand => {
      const card = document.createElement('div');
      card.className = 'option-card';
      card.dataset.value = brand;
      card.dataset.action = 'click->popup#handleSingleSelect';
      card.innerHTML = `
        <i class="fas fa-car"></i>
        <span>${brand.charAt(0).toUpperCase() + brand.slice(1)}</span>
      `;
      brandContainer.appendChild(card);
    });
  }

  updateModelOptions(type, brand) {
    const modelContainer = this.element.querySelector('.model-options');
    modelContainer.innerHTML = '';
    
    const models = this.vehicleData[type]?.[brand] || [];
    models.forEach(model => {
      const card = document.createElement('div');
      card.className = 'option-card';
      card.dataset.value = model;
      card.dataset.action = 'click->popup#handleSingleSelect';
      card.innerHTML = `
        <i class="fas fa-car"></i>
        <span>${model}</span>
      `;
      modelContainer.appendChild(card);
    });
  }

  updateSummary() {
    const hasSelections = this.selections.websites.length > 0 || 
                         this.selections.cities.length > 0 || 
                         this.selections.type || 
                         this.selections.brand || 
                         this.selections.model;
    
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
      if (this.selections.type) this.element.querySelector('.type-selection').textContent = `Araç Tipi: ${this.selections.type}`;
      if (this.selections.brand) this.element.querySelector('.brand-selection').textContent = `Marka: ${this.selections.brand}`;
      if (this.selections.model) this.element.querySelector('.model-selection').textContent = `Model: ${this.selections.model}`;
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
      brand: '',
      model: ''
    };
    
    this.element.querySelectorAll('.option-card').forEach(card => {
      card.classList.remove('selected');
    });
    
    this.updateStepDisplay();
    this.summaryTarget.style.display = 'none';
  }
} 