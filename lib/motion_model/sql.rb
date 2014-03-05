require 'motion-require'

Motion::Require.all(Dir.glob(File.expand_path('../../../motion/adapters/sql/*.rb', __FILE__)))
