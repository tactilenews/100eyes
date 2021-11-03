import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['activeItem', 'sidebar'];

  connect() {
    if (this.hasActiveItemTarget && !this.isActiveItemVisible()) {
      this.scrollActiveItemIntoView();
    }
  }

  isActiveItemVisible() {
    if (!this.hasActiveItemTarget) {
      return;
    }

    const sidebar = this.sidebarTarget;
    const sidebarBounds = sidebar.getBoundingClientRect();

    const item = this.activeItemTarget;
    const itemBounds = item.getBoundingClientRect();

    // Calculate item bounds relative to sidebar
    const itemTop = itemBounds.top - sidebarBounds.top - sidebar.scrollTop;
    const itemBottom = itemTop + item.offsetHeight;

    // Check if item is at least partially visible
    return itemTop < sidebar.offsetHeight && itemBottom > 0;
  }

  scrollActiveItemIntoView() {
    const item = this.activeItemTarget;
    const sidebar = this.sidebarTarget;

    const { top: itemTop } = item.getBoundingClientRect();
    const { top: sidebarTop } = sidebar.getBoundingClientRect();

    sidebar.scrollTop = itemTop - sidebarTop;
  }
}
