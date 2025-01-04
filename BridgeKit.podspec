#
# Be sure to run `pod lib lint BridgeKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'BridgeKit'
  s.version          = '0.1.0'
  s.summary          = 'Simplifying Communication Between Your App and Webviews'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.swift_versions = ['5.0']
  s.description      = <<-DESC
  
  **What is BridgeKit?**

  BridgeKit is a lightweight Swift library designed to simplify communication between your native iOS app and JavaScript code running within a `WKWebView`. It provides a clean and intuitive API for sending and receiving messages, enabling seamless interaction between your native and web content.

  **Why use BridgeKit?**

  *   **Simplified Message Handling:** BridgeKit abstracts away the complexities of `WKWebView` communication, providing a streamlined approach to sending and receiving messages.
  *   **Flexible Data Exchange:** Send and receive complex data structures (using `Codable` objects) between your app and the webview.
  *   **Improved Maintainability:** Separate message handling logic from your view code for better organization and easier maintenance.
  
                       DESC

  s.homepage         = 'https://github.com/aybarska/BridgeKit'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Ayberk Mogol' => 'ayberk.m@yandex.com' }
  s.source           = { :git => 'https://github.com/aybarska/BridgeKit.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '13.0'

  s.source_files = 'BridgeKit/Classes/**/*'
  
  # s.resource_bundles = {
  #   'BridgeKit' => ['BridgeKit/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
