#
# Be sure to run `pod lib lint JPBlurView.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'JPBlurView'
  s.version          = '0.1.0'
  s.summary          = 'JPBlurView is a UIView with a blur effect and customizable blur intensity.'

  s.description      = <<-DESC
  JPBlurView is a UIView with a blur effect and customizable blur intensity. JPBlurAnimationView inherits from JPBlurView, allows for animated modifications of the blur intensity.
                       DESC

  s.homepage         = 'https://github.com/Rogue24/JPBlurView'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Rogue24' => 'zhoujianping24@hotmail.com' }
  s.source           = { :git => 'https://github.com/Rogue24/JPBlurView.git', :tag => s.version.to_s }
  
  s.ios.deployment_target = '13.0'
  s.swift_version = '5.5'
  
  s.subspec 'Base' do |b|
    b.source_files = 'JPBlurView/Base/*'
  end

  s.subspec 'Animable' do |a|
    a.source_files = 'JPBlurView/Animable/*'
    a.dependency 'JPBlurView/Base'
    a.dependency 'pop'
  end
  
end
