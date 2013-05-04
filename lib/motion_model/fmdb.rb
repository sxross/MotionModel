Motion::Project::App.setup do |app|
  app.pods do
    # Note: As of 2013-05-03 the v2.0 podspec is not up to date with master branch at https://github.com/ccgus/fmdb
    pod 'FMDB', podspec: File.expand_path('../../../FMDB.podspec', __FILE__)
  end
end
