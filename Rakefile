# -*- coding: utf-8 -*-
$:.unshift("/Library/RubyMotion/lib")
require 'motion/project'
# require 'rubygems'
# require 'bundler'
# Bundler.require

Motion::Project::App.setup do |app|
  # Use `rake config' to see complete project settings.
  app.delegate_class = 'FakeDelegate'
  app.files = (app.files.select { |f| f =~ /app\/lib/ } + app.files).uniq
end
