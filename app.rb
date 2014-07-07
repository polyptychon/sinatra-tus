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
  response.headers["Access-Control-Allow-Headers"] = "Origin, X-Requested-With, Content-Type, Accept, Content-Disposition, Final-Length, Offset, Filepath"
  #response.headers["Content-Type"] = "text/plain; charset=utf-8"
  puts "Before #{request.path_info}"
end


# Handle GET-request (Show the upload form)
# todo: add upload client
get "/files/" do
  #return "hello world".to_sha1
  #haml :upload
  haml :tus
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

# Handle POST-request (Create File)
# todo: check avaliable drive space
post "/files/" do
  file_size = request.env["Final-Length"]

  request_file_path = request.env["Filepath"]
  create_path_folders(request_file_path, "uploads")
  unique_filename = request_file_path || SecureRandom.hex
  path = 'uploads/'+unique_filename
  File.write(path, "")
  response.headers["Location"] = request.url+unique_filename
  status 201
end

# Handle OPTIONS-request (Check if file exists)
options "/files/*" do
  file_name = params[:splat].join("").to_s
  path = 'uploads/'+file_name
  if File.file?(path)
    status 200
  elsif
    status 404
  end
end

# Handle PATCH-request (Receive and save the uploaded file)
patch "/files/*" do
  file_name = params[:splat].join("").to_s
  path = 'uploads/'+file_name
  offset = env['Offset']
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
  elsif
    status 404
  end
end

# Handle OPTIONS-request (Check if file exists)
head "/files/*" do
  file_name = params[:splat].join("").to_s
  path = 'uploads/'+file_name
  if File.file?(path)
    response.headers["Offset"] = File.size(path).to_s
    status 200
  elsif
    status 404
  end
end

def create_path_folders(path, root_path)
  if path
    folders = path.split("/")
    folders.pop
    if folders.size>0
      FileUtils.makedirs root_path+"/"+folders.join("/")
    end
  end
end