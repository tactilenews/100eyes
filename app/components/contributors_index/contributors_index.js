import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['filterSection'];

  connect() {
    const searchParams = new URL(document.location).searchParams;
    const tagList = searchParams.get('tag_list[]');
    const showFilter = !(tagList && tagList.length > 0);
    this.filterSectionTarget.hidden = showFilter;
  }

  toggleFilterSection() {
    this.filterSectionTarget.hidden = !this.filterSectionTarget.hidden;
  }

  clearTags() {
    this.dispatch('clearTags', { bubbles: true });
  }
}
