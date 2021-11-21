import { Application } from '@hotwired/stimulus';
import controllers, { filenames } from '../../../components/**/*.js';

const application = Application.start();

filenames.forEach((filename, index) => {
  const identifier = filename
    .split('/')
    .slice(4, -1)
    .join('--')
    .replace(/_/g, '-');

  application.register(identifier, controllers[index].default);
});
