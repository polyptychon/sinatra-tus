require 'json'
require 'active_support/inflector'
require_relative 'tusd'

class PolyTusd < Tusd

  helpers do
    def move_file(path, temp_file_name)
      unless path.nil?
        path = friendly_name(path)
        folders = path.split('/')
        folders.pop
        if folders.size>0
          folders_path = file_path(folders.join('/'))
          FileUtils.makedirs folders_path
        end
        tmp_path = file_path(temp_file_name)
        path = file_path(path)
        FileUtils.mv(tmp_path, path)
        path
      end
    end

    def friendly_name(path)
      str = path.split('.')
      extension = str.pop
      str.join('.').parameterize+'.'+extension
    end
  end

  # Handle OPTIONS-request (Check if file exists)
  get route_path("/info") do
    # file_path = request.env['HTTP_FILE_PATH'].to_s
    # file_path = friendly_name(file_path)
    # path = UPLOAD_FOLDER+'/'+file_path

    return params[:filenames].inspect

    result = {}

    filenames = Array(params[:filenames])
    filenames.each do |path|
      system_path = file_path(path)
      if File.file?(path)
        result[path] = File.size(system_path).to_s
      else
        result[path] = :not_found
      end
    end

    content_type :json
    result.to_json
  end

  # TODO: REMOVE THIS FROM HERE AND CLIENT
  # Handle PUT-request (Move and rename temporary file)
  put route_path("/:name") do
    temp_file_name = params[:name]
    file_path = request.env['HTTP_FILE_PATH'].to_s

    begin
      file_path = move_file(file_path, temp_file_name)
    rescue
      tmp_path = file_path(temp_file_name)
      FileUtils.rm(tmp_path)
      halt 404
    end
    response.headers['Checksum'] = Digest::MD5.file(file_path).hexdigest.to_s
    response.headers['Location'] = '/files/'+file_path
    status 200
  end

  # TODO: REMOVE THIS FROM HERE AND CLIENT
  # Handle OPTION-request (Check if we can upload files)
  options route_path("/?") do
    if request.env['Access-Control-Request-Method']=='POST'
      status 200
    elsif request.env['Access-Control-Request-Method']=='PATCH'
      status 405
    end
  end

  # TODO: REMOVE THIS FROM HERE AND CLIENT
  # Handle OPTIONS-request (Check if temporary file exists)
  options route_path("/:name") do
    temp_file_name = params[:name]
    path = file_path(temp_file_name)
    if File.file?(path)
      status 200
    else
      status 404
    end
  end

  # TODO: REMOVE THIS FROM HERE AND CLIENT
  # Handle OPTIONS-request (Check if file exists)
  head route_path("/?") do
    file_path = request.env['HTTP_FILE_PATH'].to_s
    file_path = friendly_name(file_path)
    path = file_path(file_path)

    if File.file?(path)
      status 200
    else
      status 404
    end
  end

end

PolyTusd.run! if __FILE__ == $0
