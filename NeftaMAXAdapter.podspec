Pod::Spec.new do |s|
  s.name         = 'NeftaMAXAdapter'
  s.version      = '1.0.6'
  s.summary      = 'Custom mediation adapter for Applovin MAX SDK.'
  s.homepage     = 'https://docs-adnetwork.nefta.io/docs/max-ios'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { 'Tomaz Treven' => 'treven@nefta.io' }
  s.source       = { :git => 'https://github.com/Nefta-io/NeftaMAXAdapter.git', :tag => '1.0.6' }

  s.ios.deployment_target = '10.0'

  s.dependency 'NeftaSDK', '~> 3.1.13'
  s.source_files = 'NeftaMAXAdapter/NeftaMAXAdapter/*.{h,m}'
end
