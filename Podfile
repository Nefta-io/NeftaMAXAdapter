source 'https://github.com/CocoaPods/Specs.git'

use_frameworks!
inhibit_all_warnings!
platform :ios, '11.0'

target 'AppLovin MAX Demo App - Swift' do
  project 'AppLovin MAX Demo App - Swift/AppLovin MAX Demo App - Swift.xcodeproj'
  pod 'AppLovinSDK', '12.0.0'
  pod 'Adjust'
  pod 'NeftaMAXAdapter', :path => '.'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    if target.name == 'NeftaMAXAdapter'
      target.build_configurations.each do |config|
        config.build_settings['MACH_O_TYPE'] = 'staticlib'
      end
      framework_ref = installer.pods_project.reference_for_path(File.dirname(__FILE__) + '/Pods/AppLovinSDK/applovin-ios-sdk-12.0.0/AppLovinSDK.xcframework')
      target.frameworks_build_phase.add_file_reference(framework_ref, true)
    end
  end
end
