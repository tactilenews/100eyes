import { Controller } from 'stimulus';

export default class extends Controller {
    setDirty() {
        this.element.classList.add('UserProfile--dirty');
    }
}
