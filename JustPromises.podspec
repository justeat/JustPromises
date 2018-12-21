#
#  Be sure to run `pod spec lint JustPromises.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  s.name         = "JustPromises"
  s.version      = "3.2.0"
  s.summary      = "A lightweight and thread-safe implementation of Promises & Futures in Objective-C for iOS and OS X."

  s.description  = <<-DESC
                   A lightweight and thread-safe implementation of Promises & Futures in Objective-C for iOS and OS X.
                   DESC

  s.homepage     = "http://github.com/justeat/JustPromises"
  s.license      = { :type => "Apache License, Version 2.0", :file => "LICENSE" }

  s.authors             = { "Just Eat iOS team" => "justeat.ios.team@gmail.com", "Marek Rogosz" => "marek.rogosz@just-eat.com", "Ben Chester" => "ben.chester@just-eat.com", "Alberto De Bortoli" => "alberto.debortoli@just-eat.com", "Pavol Polak" => "pavol.polak@just-eat.com", "Keith Moon" => "keith.moon@just-eat.com" }
  s.social_media_url   = "http://twitter.com/justeat_tech"

  s.source       = { :git => "https://github.com/justeat/JustPromises.git", :tag => s.version.to_s }

  s.source_files  = 'JustPromises/Classes/**/*'
  
  s.ios.deployment_target = "10.0"
  s.osx.deployment_target = "10.9"
  s.watchos.deployment_target = "3.0"
  s.tvos.deployment_target = "9.0"

  s.subspec "Objective-C" do |ss|
    ss.source_files = 'JustPromises/Classes/**/*.{h,m}'
  end

  s.swift_version = '4.2'
  s.requires_arc = true

end
