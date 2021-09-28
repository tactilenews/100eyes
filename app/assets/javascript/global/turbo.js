import * as Turbo from '@hotwired/turbo';

Turbo.setProgressBarDelay(100);

const PRESERVE_SCROLL_SELECTOR = '[data-turbo-preserve-scroll-position]';
let scrollPositions = {};

const storeScrollPositions = () => {
  scrollPositions = {};
  const containers = document.querySelectorAll(PRESERVE_SCROLL_SELECTOR);

  containers.forEach(container => {
    scrollPositions[container.id] = container.scrollTop;
  });
};

const restoreScrollPositions = () => {
  const containers = document.querySelectorAll(PRESERVE_SCROLL_SELECTOR);

  containers.forEach(container => {
    const scrollPosition = scrollPositions[container.id];

    if (scrollPosition && scrollPosition !== container.scrollTop) {
      container.scrollTop = scrollPosition;
    }
  });
};

addEventListener('turbo:click', () => storeScrollPositions());
addEventListener('turbo:render', () => restoreScrollPositions());
