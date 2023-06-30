import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['filterSection', 'filterActiveText'];

  connect() {
    const searchParams = new URL(document.location).searchParams;
    const tagList = searchParams.get('tag_list[]');
    console.log('connected', tagList);
    const showFilter = !(tagList && tagList.length > 0);
    this.filterSectionTarget.hidden = showFilter;
    if (this.hasFilterActiveText)
      this.filterActiveTextTarget.hidden = showFilter;
  }

  toggleFilterSection() {
    this.filterSectionTarget.hidden = !this.filterSectionTarget.hidden;
  }
}
