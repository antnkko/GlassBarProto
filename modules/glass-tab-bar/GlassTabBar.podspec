Pod::Spec.new do |s|
  s.name           = 'GlassTabBar'
  s.version        = '1.0.0'
  s.summary        = 'Liquid Glass morphing tab bar + toolbar (iOS 26, Fabric)'
  s.description    = 'Native SwiftUI Liquid Glass tab bar and toolbar exposed as bare Fabric components.'
  s.author         = 'Numo'
  s.homepage       = 'https://numo.app'
  s.platforms      = { :ios => '26.0' }
  s.source         = { git: '' }
  s.swift_version  = '5.0'
  s.license        = { :type => 'MIT' }

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES'
  }

  # RN CLI autolinking requires the podspec at the package root; sources live
  # under ios/.
  s.source_files = 'ios/**/*.{h,m,mm,swift}'
  # The ComponentView headers import C++-contaminated Fabric headers; keeping
  # them out of the module umbrella lets the pod's own Swift half compile its
  # underlying clang module without a C++ stdlib.
  s.private_header_files = 'ios/**/*.h'

  # Wires all Fabric/codegen dependencies and flags (React-RCTFabric,
  # ReactCodegen, folly flags, RCT_NEW_ARCH_ENABLED) — RN >= 0.71 helper.
  install_modules_dependencies(s)
end
