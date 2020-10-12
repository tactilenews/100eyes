import { Controller } from 'stimulus';

export default class extends Controller {
  static targets = ['channel', 'instructions'];

  connect() {
    window.addEventListener('hashchange', () => this.handleHashChange());
    this.handleHashChange();
  }

  switchChannelInstructions() {
    location.hash = selectedChannelName;

    const selectedChannel = Array.from(this.channelTargets).find(
      channel => channel.checked
    );

    const { value: selectedChannelName } = selectedChannel || {};
    location.hash = selectedChannelName;
  }

  handleHashChange() {
    const channelName = location.hash.slice(1);
    const target = this.channelTargets.find(
      channel => channel.value == channelName
    );

    if (!target) {
      this.channelTargets.forEach(target => (target.checked = false));
      return;
    }

    target.checked = true;
  }
}
