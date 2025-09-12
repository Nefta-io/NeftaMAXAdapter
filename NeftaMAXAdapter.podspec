Pod::Spec.new do |s|
  s.name         = 'NeftaMAXAdapter'
  s.version      = '4.4.0'
  s.summary      = 'Nefta Ad Network SDK for MAX Mediation.'
  s.homepage     = 'https://docs.nefta.io/docs/max-ios'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { 'Tomaz Treven' => 'treven@nefta.io' }
  s.source       = { :git => 'https://github.com/Nefta-io/NeftaMAXAdapter.git', :tag => 'REL_4.4.0' }

  s.ios.deployment_target = '12.0'

  s.swift_version = '5.0'

  s.source_files     = 'NeftaMAXAdapter/**/AL*.{h,m}'

  s.dependency 'NeftaSDK', '= 4.4.0'
  s.dependency 'AppLovinSDK', '>= 12.0.0'
end
