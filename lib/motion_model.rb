# Motion::Require.all(Dir.glob(File.expand_path("../../motion/#{path}", __FILE__)))
# %w[*.rb model/*.rb adapters/*.rb adapters/array/*.rb adapters/sql/sql_db_adapter.rb adapters/sql/sqlite3_adapter.rb adapters/sql/*.rb].each do |path|
#   Motion::Require.all(Dir.glob(File.expand_path("../../motion/#{path}", __FILE__)))
# end


require 'motion-require'
require 'motion-support'

%w(*.rb model/*.rb adapters/*.rb).each do |path|
  Motion::Require.all(Dir.glob(File.expand_path("../../motion/#{path}", __FILE__)))
end