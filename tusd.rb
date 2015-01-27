require 'rubygems'
require 'sinatra/base'
require 'securerandom'

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
  end

  before do
    response.headers['Access-Control-Allow-Methods'] = 'HEAD,GET,PUT,POST,PATCH,DELETE'
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Expose-Headers'] = 'Location, Range, Content-Disposition, Offset, Checksum'
    response.headers['Access-Control-Allow-Headers'] = 'Origin, X-Requested-With, Content-Type, Accept, Content-Disposition, Final-Length, file-type, file-path, file-checksum, Offset'
  end

  # Handle OPTIONS-request (JQuery cross-domain limitation. For some reason always sends options if it is not the same domain)
  options route_path("/?") do
    if request.env['Access-Control-Request-Method']=='POST'
      status 200
    elsif request.env['Access-Control-Request-Method']=='PATCH'
      status 405
    end
  end
  # Handle OPTIONS-request (JQuery cross-domain limitation. For some reason always sends options if it is not the same domain)
  options route_path("/:name") do
    temp_file_name = params[:name]
    path = temp_file_path(temp_file_name)
    puts "Searching for #{path}"

    if File.file?(path)
      response.headers['Offset'] = File.size(path).to_s
      status 200
    else
      status 404
    end
  end

  # Handle HEAD-request (Check if temporary file exists and return offset)
  head route_path("/:name") do
    temp_file_name = params[:name]
    path = temp_file_path(temp_file_name)
    puts "Searching for #{path}"

    if File.file?(path)
      response.headers['Offset'] = File.size(path).to_s
      status 200
    else
      status 404
    end
  end

  # Handle PATCH-request (Receive and save the uploaded file in chunks)
  patch route_path("/:name") do
    temp_file_name = params[:name]
    path = temp_file_path(temp_file_name)
    offset = request.env['HTTP_OFFSET'].to_i

    # Guard : If file not found return 404
    return status 404 unless File.file?(path)

    begin
      f = File.open(path, 'r+b')
      f.sync = true
      f.seek(offset) unless offset.nil?
      f.write(request.body.read)
      f.close
    rescue SystemCallError => e
      raise("My #{e.message}") if e.class.name.start_with?('Errno::')
    end
    if File.file?(path)
      status 200
    else
      status 404
    end
  end

  ## Tus Extension : Create File
  # Handle POST-request (Create temporary File)
  post route_path("/?") do
    unique_filename = "#{SecureRandom.hex}"
    path = temp_file_path(unique_filename)

    File.write(path, '')
    # response.headers['Location'] = request.url + unique_filename
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
