Pod::Spec.new do |s|
  s.name         = 'NeftaMAXAdapter'
  s.version      = '1.1.4'
  s.summary      = 'Custom mediation adapter for Applovin MAX SDK.'
  s.homepage     = 'https://docs-adnetwork.nefta.io/docs/max-ios'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { 'Tomaz Treven' => 'treven@nefta.io' }
  s.source       = { :git => 'https://github.com/Nefta-io/NeftaMAXAdapter.git', :tag => '1.1.4' }

  s.ios.deployment_target = '10.0'

  s.dependency 'NeftaSDK', '~> 3.2.2'
  s.source_files = 'NeftaMAXAdapter/NeftaMAXAdapter/*.{h,m}'
end
