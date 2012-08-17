Motion::Project::App.setup do |app|
  Dir.glob(File.join(File.dirname(__FILE__), "motion_model/**/*.rb")).each do |file|
    app.files.unshift(file)
  end
end

# Dir[File.join(File.dirname(__FILE__), 'nitron/data/model/**/*.rb')].each { |file| app.files.unshift(file) }
# Dir[File.join(File.dirname(__FILE__), 'nitron/data/relation/**/*.rb')].each { |file| app.files.unshift(file) }
# 
# app.files.unshift(File.join(File.dirname(__FILE__), 'nitron/view_controller.rb'))
# app.files.unshift(File.join(File.dirname(__FILE__), 'nitron/ui/data_binding_support.rb'))
# app.files.unshift(File.join(File.dirname(__FILE__), 'nitron/ui/outlet_support.rb'))
# app.files.unshift(File.join(File.dirname(__FILE__), 'nitron/ui/action_support.rb'))
# 
# 
# 
# %w(ext model validatable input_helpers).each{|file| require File.join(File.dirname(__FILE__), "app/lib/#{file}.rb")}
