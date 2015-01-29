require 'json'
require 'active_support/inflector'
require 'rack/parser'
require_relative 'tusd'

class PolyTusd < Tusd

  helpers do
    def file_path(filename)
      File.expand_path("#{filename}",settings.upload_folder)
    end

    def move_file(path, temp_file_name)
      # 2. Perform Work
      # path = friendly_name(path)
      folders = path.split('/')
      folders.pop
      if folders.size>0
        folders_path = file_path(folders.join('/'))
        FileUtils.makedirs folders_path
      end
      tmp_path = temp_file_path(temp_file_name)
      new_path = file_path(path)
      FileUtils.mv(tmp_path, new_path)

      # 3. Return result
      new_path
    end

    def friendly_name(path)
      str = path.split('.')
      extension = str.pop
      str.join('.').parameterize+'.'+extension
    end

    def moved_file_url(path='')
      file_url("final/#{path}")
    end

    def move_and_return_url(temp_file_name, file_path, with_checksum = false)
      # 1. Collect input
      # Guard : If file_path param not found return 400
      halt 400, "'path' param must be sent" unless file_path
      # Guard : If file not found return 404
      return status 404 unless File.file?(temp_file_path(temp_file_name))
      # Remove forward "/" from file path if exists
      file_path.sub!(/^\//, "") if file_path.start_with?("/")

      # 2. Perform Work
      file_path = friendly_name(file_path)
      new_file_path = move_file(file_path, temp_file_name)

      # 3. Return result
      response.headers['Location'] = moved_file_url(file_path)
      response.headers['Checksum'] = Digest::MD5.file(new_file_path).hexdigest.to_s if with_checksum
      status 201
    # 4. Handle Errors
    rescue Exception => exc
      halt 500, exc.to_s
    end

    def check_file(original_path, with_checksum = false)
      path = original_path
      path.sub!(/^\//, "") if path.start_with?("/") # Remove forward "/" from file path if exists
      path = friendly_name(path) # ust check with the friendly name
      system_path = file_path(path)

      file_info = { :name => original_path, :friendly_name => path }
      if File.file?(system_path)
        file_info[:status] = :found
        file_info[:size] = File.size(system_path)
        file_info[:checksum] = Digest::MD5.file(system_path).hexdigest.to_s if with_checksum
      else
        file_info[:status] = :not_found
      end

      file_info
    end
  end

  use Rack::Parser, :content_types => {
    'application/json'  => Proc.new { |body| ::MultiJson.decode body }
  }

  # Handle POST-request (Move and rename temporary file)
  post route_path("/:name/move") do
    # 1. Collect input
    temp_file_name = params[:name]
    file_path = params[:path]
    with_checksum = params[:checksum]

    # 2+3.Perform Work and Return result
    move_and_return_url(temp_file_name, file_path, with_checksum)
  end

  # Handle POST-request (Check if files exist)
  post route_path("/check") do
    # 1. Collect input
    filenames = Array(params[:filenames])
    with_checksum = params[:checksum]

    # 2. Perform work
    result = []
    filenames.each do |path|
      file_info = check_file(path, with_checksum)
      result << file_info
    end

    # 3. Return result
    content_type :json
    { :results => result}.to_json
  end

  # Handle GET-request (return the file)
  get route_path("/final/:name") do
    # 1. Collect input
    file_name = params[:name]
    path = file_path(file_name)
    # Guard : If file not found return 404
    return status 404 unless File.file?(path)

    # 3. Return result
    send_file path
  end
end

PolyTusd.run! if __FILE__ == $0
