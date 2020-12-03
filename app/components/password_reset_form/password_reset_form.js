import { Controller } from 'stimulus';

export default class extends Controller {
  static targets = [
    'password',
    'passwordConfirmation',
    'submitButton',
    'passwordMismatch',
  ];

  handleInput(event) {
    event.preventDefault();
    const passwordLength = this.passwordTarget.value.length;
    const passwordConfirmationLength = this.passwordConfirmationTarget.value
      .length;
    const matchingPassword =
      this.passwordTarget.value == this.passwordConfirmationTarget.value;
    const validLength = passwordLength >= 20 && passwordLength <= 128;
    this.passwordMismatchTarget.hidden =
      matchingPassword || passwordConfirmationLength < 1;
    this.submitButtonTarget.disabled = !validLength || !matchingPassword;
  }
}
