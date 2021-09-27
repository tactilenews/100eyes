import { Application } from '@stimulus/core';
import controllers, { filenames } from '../../../components/**/*.js';

const application = Application.start();

filenames.forEach((filename, index) => {
  const identifier = filename
    .split('/')
    .slice(-1)[0]
    .replace('.js', '')
    .replace(/_/g, '-');

  application.register(identifier, controllers[index].default);
});
