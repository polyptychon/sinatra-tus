require 'rubygems'
require 'sinatra'
require 'haml'
require 'fileutils'
require 'securerandom'
require 'rickshaw'

before do
  response.headers["Access-Control-Allow-Methods"] = "HEAD,GET,PUT,POST,PATCH,DELETE"
  response.headers["Access-Control-Allow-Origin"] = "*"
  response.headers["Access-Control-Expose-Headers"] = "Location, Range, Content-Disposition, Offset"
  response.headers["Access-Control-Allow-Headers"] = "Origin, X-Requested-With, Content-Type, Accept, Content-Disposition, Final-Length, file-type, file-path, file-checksum, Offset"
end


# Handle OPTION-request (Check if we can upload files)
# todo: add security
options "/files/" do
  if request.env["Access-Control-Request-Method"]=="POST"
    status 200
  elsif request.env["Access-Control-Request-Method"]=="PATCH"
    status 404
  end
end

# Handle POST-request (Create temporary File)
# todo: check avaliable drive space
post "/files/" do
  unique_filename = "#{SecureRandom.hex}.tmp"
  path = 'uploads/'+unique_filename

  File.write(path, "")
  response.headers["Location"] = request.url+unique_filename
  status 201
end

# Handle OPTIONS-request (Check if temporary file exists)
options "/files/:name" do
  file_name = params[:name]
  path = 'uploads/'+file_name
  if File.file?(path)
    status 200
  else
    status 404
  end
end

# Handle PATCH-request (Receive and save the uploaded file in chunks)
patch "/files/:name" do
  file_name = params[:name]
  path = 'uploads/'+file_name
  offset = request.env['HTTP_OFFSET'].to_i
  begin
    f = File.open(path, "r+b")
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

# Handle OPTIONS-request (Check if temporary file exists and return offset)
head "/files/:name" do
  file_name = params[:name]
  path = 'uploads/'+file_name

  if File.file?(path)
    response.headers["Offset"] = File.size(path).to_s
    status 200
  else
    status 404
  end
end

# Handle OPTIONS-request (Check if file exists)
head "/files/" do
  file_path = request.env['HTTP_FILE_PATH'].to_s
  path = 'uploads/'+file_path

  if File.file?(path)
    status 200
  else
    status 404
  end
end

# Handle PUT-request (Move and rename temporary file)
put "/files/:name" do
  file_name = params[:name]
  file_path = request.env['HTTP_FILE_PATH'].to_s

  begin
    create_path_folders(file_path, 'uploads', file_name)
  rescue
    halt 404
  end

  status 200
end

def create_path_folders(path, upload_path, file_name)
  unless path.nil?
    folders = path.split("/")
    folders.pop
    if folders.size>0
      FileUtils.makedirs upload_path+'/'+folders.join('/')
    end
    FileUtils.mv(upload_path+'/'+file_name, upload_path+'/'+path)
  end
end