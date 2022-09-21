import * as Turbo from '@hotwired/turbo';
import ApexCharts from 'apexcharts';

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
addEventListener('turbo:before-fetch-request', (event) => {
  // Turbo Drive does not send a referrer like turbolinks used to, so let's simulate it here
  event.detail.fetchOptions.headers['Turbo-Referrer'] = window.location.href
  event.detail.fetchOptions.headers['X-Turbo-Nonce'] = $("meta[name='csp-nonce']").prop('content')
});
addEventListener("turbo:before-cache", function() {
  let scriptTagsToAddNonces = document.querySelectorAll("script[nonce]");
  for (var element of scriptTagsToAddNonces) {
    element.setAttribute('nonce', element.nonce);
  }
});
