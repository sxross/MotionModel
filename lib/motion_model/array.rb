require 'motion-require'

Motion::Require.all(Dir.glob(File.expand_path('../../../motion/adapters/array/*.rb', __FILE__)))
