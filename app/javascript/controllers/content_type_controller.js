import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ["link", "image"]

  update(event) {
    const contentType = event.target.value

    // Masquer ou afficher les champs en fonction du type de contenu
    this.linkTarget.style.display = contentType === 'link' ? 'block' : 'none'
    this.imageTarget.style.display = contentType === 'image' ? 'block' : 'none'
  }
}
