import { Controller } from 'stimulus';

export default class extends Controller {
  static targets = [
    'input',
    'toggle',
    'minLength',
    'letters',
    'numbers',
    'special',
  ];
  static values = {
    unmask: String,
    mask: String,
    minLength: Number,
  };

  connect() {
    this.validate();
  }

  toggle() {
    this.inputTarget.type =
      this.inputTarget.type === 'password' ? 'text' : 'password';

    this.toggleTarget.innerHTML =
      this.inputTarget.type === 'password' ? this.unmaskValue : this.maskValue;
  }

  validate() {
    const minLength = this.minLengthValue;

    const validators = {
      minLength: value => value.length >= minLength,
      numbers: value => value.match(/[0-9]/),
      letters: value => value.match(/[a-zA-Z]/),
      special: value => value.match(/[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/),
    };

    const value = this.inputTarget.value;

    Object.entries(validators).forEach(([key, validate]) => {
      const state = validate(value) ? 'valid' : 'invalid';

      if (!this.targets.find(key)) {
        return;
      }

      this.targets.find(key).dataset.state = state;
    });
  }
}
