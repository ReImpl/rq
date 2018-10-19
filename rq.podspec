
Pod::Spec.new do |s|
  s.name             = 'rq'
  s.version          = '0.1.0'
  s.ios.deployment_target = '11.4'

  s.homepage         = 'https://github.com/ReImpl/rq'
  s.source           = { :git => 'https://github.com/ReImpl/rq.git', :tag => s.version.to_s }

  s.license          = { :type => 'The Unlicense', :file => 'LICENSE' }
  s.author           = { 'kernel' => 'kernel@reimplement.mobi' }

  s.summary          = 'Private pod in public repository.'
  s.description      = <<-DESC
Nothing interesting yet.
Private pod in public repository.
                       DESC

  s.source_files = 'Classes/**/*'
  
  s.swift_version = '4.2'
  s.requires_arc = true

end
