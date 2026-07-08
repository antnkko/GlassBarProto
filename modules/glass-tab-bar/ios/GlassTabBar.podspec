Pod::Spec.new do |s|
  s.name           = 'GlassTabBar'
  s.version        = '1.0.0'
  s.summary        = 'Liquid Glass morphing tab bar (iOS 26 prototype)'
  s.description    = 'Native SwiftUI Liquid Glass tab bar with matched-geometry morph, driven from React Native.'
  s.author         = 'Numo'
  s.homepage       = 'https://numo.app'
  s.platforms      = { :ios => '26.0' }
  s.source         = { git: '' }
  s.static_framework = true
  s.swift_version = '5.0'
  s.dependency 'ExpoModulesCore'
  s.license        = { :type => 'MIT' }

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES'
  }

  s.source_files = '**/*.{h,m,mm,swift,hpp,cpp}'
end
