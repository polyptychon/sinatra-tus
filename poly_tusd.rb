require 'rubygems'
require_relative 'tusd'
# require 'haml'
# require 'fileutils'
# require 'securerandom'
# require 'rickshaw'
# require 'active_support/inflector'


class PolyTusd < Tusd

  before do
    response.headers['Access-Control-Allow-Methods'] = 'HEAD,GET,PUT,POST,PATCH,DELETE'
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Expose-Headers'] = 'Location, Range, Content-Disposition, Offset, Checksum'
    response.headers['Access-Control-Allow-Headers'] = 'Origin, X-Requested-With, Content-Type, Accept, Content-Disposition, Final-Length, file-type, file-path, file-checksum, Offset'
  end

  UPLOAD_FOLDER = 'uploads'

  # Handle OPTION-request (Check if we can upload files)
  # todo: add security
  options route_path("/?") do
    if request.env['Access-Control-Request-Method']=='POST'
      status 200
    elsif request.env['Access-Control-Request-Method']=='PATCH'
      status 405
    end
  end

  # Handle OPTIONS-request (Check if temporary file exists)
  options route_path("/:name") do
    temp_file_name = params[:name]
    path = UPLOAD_FOLDER+'/'+temp_file_name
    if File.file?(path)
      status 200
    else
      status 404
    end
  end

  # Extend TUS Protocol

  # Handle OPTIONS-request (Check if file exists)
  head route_path("/?") do
    file_path = request.env['HTTP_FILE_PATH'].to_s
    file_path = friendly_name(file_path)
    path = UPLOAD_FOLDER+'/'+file_path

    if File.file?(path)
      status 200
    else
      status 404
    end
  end

  # Handle PUT-request (Move and rename temporary file)
  put route_path("/:name") do
    temp_file_name = params[:name]
    file_path = request.env['HTTP_FILE_PATH'].to_s

    begin
      file_path = move_file(file_path, temp_file_name)
    rescue
      FileUtils.rm(UPLOAD_FOLDER+'/'+temp_file_name)
      halt 404
    end
    response.headers['Checksum'] = Digest::MD5.file(file_path).hexdigest.to_s
    response.headers['Location'] = '/files/'+file_path
    status 200
  end

  def move_file(path, temp_file_name)
    unless path.nil?
      path = friendly_name(path)
      folders = path.split('/')
      folders.pop
      if folders.size>0
        FileUtils.makedirs UPLOAD_FOLDER+'/'+folders.join('/')
      end
      FileUtils.mv(UPLOAD_FOLDER+'/'+temp_file_name, UPLOAD_FOLDER+'/'+path)
      UPLOAD_FOLDER+'/'+path
    end
  end

  def friendly_name(path)
    str = path.split('.')
    extension = str.pop
    str.join('.').parameterize+'.'+extension
  end

end

PolyTusd.run! if __FILE__ == $0
