# -*- coding: utf-8 -*-
$:.unshift("/Library/RubyMotion/lib")
require 'motion/project/template/ios'

begin
  require 'bundler'
  Bundler.require
rescue LoadError
end

require 'motion-cocoapods'

$: << File.expand_path('/lib', __FILE__)

require 'motion_model'

Motion::Project::App.setup do |app|
  # Use `rake config' to see complete project settings.
  app.name = 'MotionModel'
  app.delegate_class = 'FakeDelegate'

  app.pods do
    pod 'FMDB', '2.0'
  end
end
