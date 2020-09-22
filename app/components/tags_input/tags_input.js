import { Controller } from 'stimulus';
import Tagify from '@yaireo/tagify';

export default class extends Controller {
  static targets = ['input'];

  connect() {
    new Tagify(this.inputTarget, {
      originalInputValueFormat: tags => tags.map(tag => tag.value).join(','),
      whitelist: JSON.parse(this.data.get('options')),
      dropdown: {
        classname: 'TagsInput-dropdown',
        enabled: 0,
        closeOnSelect: false,
      },
    });
  }
}
