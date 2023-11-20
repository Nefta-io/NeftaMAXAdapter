Pod::Spec.new do |s|
  s.name         = 'NeftaMAXAdapter'
  s.version      = '1.0.0'
  s.summary      = 'Custom mediation adapter for Applovin MAX SDK.'
  s.homepage     = 'https://github.com/Nefta-io/NeftaMAXAdapter'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { 'Tomaz Treven' => 'treven@nefta.io' }
  s.source       = { :git => 'https://github.com/Nefta-io/NeftaMAXAdapter.git', :tag => '1.0.0' }

  s.ios.deployment_target = '11.0'

  s.vendored_frameworks = 'NeftaSDK.xcframework'
  s.source_files = 'NeftaMAXAdapter/*.{h,m}'
end
