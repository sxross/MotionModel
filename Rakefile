# -*- coding: utf-8 -*-
require "bundler/gem_tasks"
$:.unshift("/Library/RubyMotion/lib")
require 'motion/project'
require 'bundler'
Bundler.require

Motion::Project::App.setup do |app|
  # Use `rake config' to see complete project settings.
  app.delegate_class = 'FakeDelegate'
  app.files = Dir.glob('./lib/motion_model/**/*.rb') + app.files
  app.files = (app.files + Dir.glob('./app/**/*.rb')).uniq
end
