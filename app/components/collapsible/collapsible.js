import { Controller } from 'stimulus';

export default class extends Controller {
    static targets = [ 'title' ];

    connect() {
        this.toggle();
    }

    toggle() {
        if(this.isExpanded()) {
            return this.collapse();
        }

        this.expand();
    }

    isExpanded() {
        return this.titleTarget.getAttribute('aria-expanded') === 'true';
    }

    expand() {
        this.titleTarget.setAttribute('aria-expanded', 'true');
    }

    collapse() {
        this.titleTarget.setAttribute('aria-expanded', 'false');
    }
}
