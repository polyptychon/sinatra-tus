require_relative 'poly_tusd'

class OldPolyTusd < PolyTusd

  # TODO: REMOVE THIS FROM HERE AND CLIENT
  # NEW VERSION : Use 'POST /:name/move' to move the file
  # Handle PUT-request (Move and rename temporary file)
  put route_path("/:name") do
    # Collect input
    temp_file_name = params[:name]
    file_path = request.env['HTTP_FILE_PATH'].to_s

    # Perform Work and Return result
    move_and_return_url(temp_file_name, file_path)
  end


  # TODO: REMOVE THIS FROM HERE AND CLIENT
  # NEW VERSION : Use 'POST /check' to get the check result
  # Handle OPTIONS-request (Check if file exists)
  head route_path("/?") do
    # Collect input
    temp_file_name = request.env['HTTP_FILE_PATH'].to_s

    # Perform Work
    check_result = check_file(temp_file_name)

    # Return result
    if check_result[:status] == :not_found
      status 404
    else
      status 200
    end
  end

end

OldPolyTusd.run! if __FILE__ == $0
