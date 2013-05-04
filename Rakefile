# -*- coding: utf-8 -*-
require "bundler/gem_tasks"
$:.unshift("/Library/RubyMotion/lib")
require 'motion/project'
require 'rubygems'
require 'bundler'
Bundler.require(:default)

require 'motion-cocoapods'
require 'motion-support'

$:.unshift(File.expand_path('../lib', __FILE__))
require 'motion_model'
require 'motion_model/array'
require 'motion_model/sql'
require 'motion_model/fmdb'

Motion::Project::App.setup do |app|
  # Use `rake config' to see complete project settings.
  app.name = 'MotionModel'
  app.delegate_class = 'FakeDelegate'
  app.files << './app/app_delegate.rb'
end
