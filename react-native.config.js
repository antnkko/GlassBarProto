const path = require('path');

// Local Fabric native module: RN CLI autolinking pods GlassTabBar.podspec and
// codegen picks up its codegenConfig (package.json in the module root).
module.exports = {
  dependencies: {
    'glass-tab-bar': {
      root: path.join(__dirname, 'modules/glass-tab-bar'),
    },
  },
};
