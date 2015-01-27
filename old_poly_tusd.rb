require_relative 'poly_tusd'

class OldPolyTusd < PolyTusd

  # TODO: REMOVE THIS FROM HERE AND CLIENT
  # Handle PUT-request (Move and rename temporary file)
  put route_path("/:name") do

    # Collect input
    temp_file_name = params[:name]
    file_path = request.env['HTTP_FILE_PATH'].to_s

    # Perform Work and Return result
    move_and_return_url(temp_file_name, file_path)

    # temp_file_name = params[:name]
    # file_path = request.env['HTTP_FILE_PATH'].to_s

    # begin
    #   file_path = move_file(file_path, temp_file_name)
    # rescue
    #   tmp_path = file_path(temp_file_name)
    #   FileUtils.rm(tmp_path)
    #   halt 404
    # end
    # response.headers['Checksum'] = Digest::MD5.file(file_path).hexdigest.to_s
    # response.headers['Location'] = '/files/'+file_path
    # status 200
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
    path = temp_file_path(temp_file_name)
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
    path = temp_file_path(file_path)

    if File.file?(path)
      status 200
    else
      status 404
    end
  end

end

OldPolyTusd.run! if __FILE__ == $0
