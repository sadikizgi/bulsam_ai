import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar"]

  connect() {
    this.handleResize = this.handleResize.bind(this)
    window.addEventListener('resize', this.handleResize)
    this.handleResize()
  }

  disconnect() {
    window.removeEventListener('resize', this.handleResize)
  }

  toggleSidebar() {
    this.sidebarTarget.classList.toggle('active')
  }

  handleResize() {
    if (window.innerWidth > 1024) {
      this.sidebarTarget.classList.remove('active')
    }
  }
} 