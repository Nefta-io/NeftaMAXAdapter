use_frameworks!
inhibit_all_warnings!
platform :ios, '11.0'

target 'AppLovin MAX Demo App - Swift' do
  project 'AppLovin MAX Demo App - Swift/AppLovin MAX Demo App - Swift.xcodeproj'
  pod 'AppLovinSDK'
  pod 'Adjust'
  pod 'NeftaMAXAdapter', :path => '.'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    if target.name == 'NeftaMAXAdapter'
      framework_ref = installer.pods_project.frameworks_group.new_reference('AppLovinSDK/applovin-ios-sdk-11.11.4/AppLovinSDK.xcframework')
      target.frameworks_build_phase.add_file_reference(framework_ref, true)
    end
  end
end