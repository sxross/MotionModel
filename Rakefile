# -*- coding: utf-8 -*-
require "bundler/gem_tasks"
$:.unshift("/Library/RubyMotion/lib")
require 'motion/project'

MOTION_MODEL_FMDB = true if ENV['MOTION_MODEL_FMDB']

require 'motion-cocoapods' if defined?(MOTION_MODEL_FMDB)

Motion::Project::App.setup do |app|
  # Use `rake config' to see complete project settings.
  app.delegate_class = 'FakeDelegate'
  app.files = Dir.glob('./lib/motion_model/**/*.rb')
  app.files = (app.files + Dir.glob('./app/**/*.rb')).uniq
  if defined?(MOTION_MODEL_FMDB)
    app.files += Dir.glob('./lib/fmdb.rb')
    app.pods do
      # Note: v2.0 podspec is not up to date with master branch at https://github.com/ccgus/fmdb
      # For now, do "git submodule --update -init" to get a local install
      #pod 'FMDB'
      pod 'FMDB', local: File.expand_path('../vendor/fmdb', __FILE__)
    end
  end
end
