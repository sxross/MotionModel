# -*- coding: utf-8 -*-
require "bundler/gem_tasks"
$:.unshift("/Library/RubyMotion/lib")
require 'motion/project'
require 'bundler'
Bundler.require

$:.unshift(File.expand_path('../lib', __FILE__))
require 'motion_model'

Motion::Project::App.setup do |app|
  # Use `rake config' to see complete project settings.
  app.name = 'MotionModel'
  app.delegate_class = 'FakeDelegate'
  app.files = (app.files + Dir.glob('./app/**/*.rb')).uniq
end
