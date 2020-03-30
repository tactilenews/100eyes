import { Application } from '@stimulus/core';
import { identifierForContextKey } from 'stimulus/webpack-helpers';

import '../global/index.js';

const application = Application.start();

// Import all component styles
const styles = require.context('../../app/components', true, /\.css$/);

// Import and register all component controllers
const controllers = require.context('../../app/components', true, /\.js$/);

for(const key of controllers.keys()) {
    const identifier = key.match(/([^-\/\.]+)\.js$/)[1];
    const controller = controllers(key).default;
    application.register(identifier, controller);
}
