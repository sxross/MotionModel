require 'motion-require'

#motion_require File.expand_path('../../../motion/adapters/sql/sqlite3_adapter.rb', __FILE__)
Motion::Require.all(Dir.glob(File.expand_path('../../../motion/adapters/sql/*.rb', __FILE__)))
