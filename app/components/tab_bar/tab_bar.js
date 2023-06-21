import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['filterSection'];

  connect() {
    const searchParams = new URL(document.location).searchParams;
    const tagList = searchParams.get('tag_list[]');
    this.filterSectionTarget.hidden = !(tagList && tagList.length > 0);
  }

  toggleFilterSection() {
    this.filterSectionTarget.hidden = !this.filterSectionTarget.hidden;
  }
}
