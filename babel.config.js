module.exports = {
  presets: ['module:@react-native/babel-preset'],
  // Reanimated 4: the worklets Babel plugin (moved out of the reanimated
  // package). Must stay LAST in the plugin list.
  plugins: ['react-native-worklets/plugin'],
};
