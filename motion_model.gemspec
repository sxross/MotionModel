# -*- encoding: utf-8 -*-
require File.expand_path('../motion/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Steve Ross"]
  gem.email         = ["sxross@gmail.com"]
  gem.description   = "Simple model and validation mixins for RubyMotion"
  gem.summary       = "Simple model and validation mixins for RubyMotion"
  gem.homepage      = "https://github.com/sxross/MotionModel"

  gem.files         = `git ls-files`.split($\)
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "motion_model"
  gem.require_paths = ["lib"]
  gem.add_dependency 'bubble-wrap', '>= 1.3.0'
  gem.add_dependency 'motion-support', '>= 0.2.2'
  gem.version       = MotionModel::VERSION
end
