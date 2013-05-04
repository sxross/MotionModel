Motion::Project::App.setup do |app|
  %w(*.rb model/*.rb adapters/*.rb).each do |path|
    Dir.glob(File.expand_path("../../motion/#{path}", __FILE__)).each do |file|
      app.files.unshift(file)
    end
  end
end
