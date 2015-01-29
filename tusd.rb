require 'sinatra/base'
require 'securerandom'
require_relative 'tusd_cors'

class Tusd < Sinatra::Base

  configure :development do
    set :upload_folder,  File.expand_path('uploads',File.dirname(__FILE__))
    set :app_path, '/files'
    set :bind, '0.0.0.0'
    set :port, 1080
  end

  def self.route_path(path='')
    app_path = settings.respond_to?(:app_path) ? settings.app_path : ''
    route_path = [app_path, path].join('')
    puts "route_path for '#{path}' : #{route_path}"
    route_path
  end

  helpers do
    def base_url
      base = "http://#{request.host}"
      base = request.port == 80 ? base : base << ":#{request.port}"
      base_url = base + settings.app_path
    end

    def url(path='')
      # path = self.class.route_path(path)
      # [base_url, path].join('')
      [base_url, path].join('/')
    end

    def file_url(path='')
      # path = self.class.route_path(path)
      # [base_url, path].join('')
      [base_url, path].join('/')
    end

    def temp_file_path(filename)
      File.expand_path("#{filename}.tmp",settings.upload_folder)
    end

    def head_and_return_offset(temp_file_name)
      path = temp_file_path(temp_file_name)
      puts "Searching for #{path}"

      if File.file?(path)
        response.headers['Offset'] = File.size(path).to_s
        status 200
      else
        status 404
      end
    end
  end

  use TusdCORS

  # Handle HEAD-request (Check if temporary file exists and return offset)
  head route_path("/:name") do
    # 1. Collect input
    temp_file_name = params[:name]

    # 2. Perform Work - 3. Return result
    head_and_return_offset(temp_file_name)
  end

  # Handle PATCH-request (Receive and save the uploaded file in chunks)
  patch route_path("/:name") do
    begin
      # 1. Collect input
      temp_file_name = params[:name]
      path = temp_file_path(temp_file_name)
      offset = request.env['HTTP_OFFSET'].to_i

      # Guard : If file not found return 404
      return status 404 unless File.file?(path)

      # 2. Perform Work
      f = File.open(path, 'r+b')
      f.sync = true
      f.seek(offset) unless offset.nil?
      f.write(request.body.read)
      f.close

      # 3. Return result
      status 200

    # 4. Handle Errors
    rescue SystemCallError => e
      raise("My #{e.message}") if e.class.name.start_with?('Errno::')
    end
  end

  ## Tus Extension : Create File
  # Handle POST-request (Create temporary File)
  post route_path("/?") do
    # 1. Collect input
    unique_filename = "#{SecureRandom.hex}"
    path = temp_file_path(unique_filename)

    # 2. Perform Work
    File.write(path, '')

    # 3. Return result
    response.headers['Location'] = file_url(unique_filename)
    status 201
  end

  # Generates a new (subclass) Class so that we can change the settings in a block
  def self.generate_app(&block)
    c = Class.new(self)
    c.instance_eval(&block) if block_given?
  end

end

Tusd.run! if __FILE__ == $0
