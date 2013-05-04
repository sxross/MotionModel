Motion::Project::App.setup do |app|
  Dir.glob(File.join(File.expand_path('../../motion/**/*.rb', __FILE__))).each do |file|
    app.files.unshift(file)
  end
end
