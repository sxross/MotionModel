Motion::Project::App.setup do |app|
  Dir.glob(File.expand_path('../../../motion/adapters/array/*.rb', __FILE__)).each do |file|
    app.files.unshift(file)
  end
end
