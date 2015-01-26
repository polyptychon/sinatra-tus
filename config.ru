# First set the RACK environment
ENV['RACK_ENV'] = "production"

# And THEN require the App, so that the configuration happens correctly
require_relative 'poly_tusd'

# generate a new class so that we can change the settings
MyApp = PolyTusd.generate_app do
  set :app_path, '/files'
  set :upload_folder,  File.expand_path('uploads',File.dirname(__FILE__))
end

run MyApp
