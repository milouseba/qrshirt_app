import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["link", "image"]

  connect() {
    this.update()
  }

  update() {
    const type = this.element.querySelector("select").value

    this.linkTarget.classList.toggle("hidden", type !== "link")
    this.imageTarget.classList.toggle("hidden", type !== "image")
  }
}
