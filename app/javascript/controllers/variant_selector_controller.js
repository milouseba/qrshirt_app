import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { variants: Object }
  static targets = ["variantId"]

  updateVariantId() {
    const color = this.element.querySelector("[name='order[color]']").value
    const size = this.element.querySelector("[name='order[size]']").value
    console.log(color);
    console.log(size);
    console.log(this.variantsValue);
    console.log(this.variantsValue[color]);
    console.log(this.variantsValue[color][size]);
    if (this.variantsValue[color] && this.variantsValue[color][size]) {
      const variantId = this.variantsValue[color][size]
      this.variantIdTarget.value = variantId
    } else {
      this.variantIdTarget.value = ""
    }
  }
}
