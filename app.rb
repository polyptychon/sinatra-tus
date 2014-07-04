require 'rubygems'
require 'sinatra'
require 'haml'

before do
  response.headers["Access-Control-Allow-Methods"] = "HEAD,GET,PUT,POST,PATCH,DELETE"
  response.headers["Access-Control-Allow-Origin"] = "*"
  response.headers["Access-Control-Expose-Headers"] = "Location, Range, Content-Disposition, Offset"
  response.headers["Access-Control-Allow-Headers"] = "Origin, X-Requested-With, Content-Type, Accept, Content-Disposition, Final-Length, Offset"
  response.headers["Content-Type"] = "text/plain; charset=utf-8"
end


# Handle GET-request (Show the upload form)
get "/files/" do
  haml :upload
end

# Handle OPTION-request (Check if we can upload files)
options "/files/" do
  if request.env["Access-Control-Request-Method"]=="POST"
    response.headers["Content-Length"] = "0"
    status 200
  elsif request.env["Access-Control-Request-Method"]=="PATCH"
    response.headers["Content-Length"] = "0"
    status 200
  end
end

# Handle POST-request (Create File)
post "/files/" do
  response.headers["Location"] = "http://localhost:1080/files/24e533e02ec3bc40c387f1a0e460e216"
  status "201 Created"
end

# Handle OPTIONS-request (Check if file exists)
options "/files/*.*" do |path, ext|
  file_name = "#{path}.#{ext}"
  path = 'uploads/'+file_name
  if File.file?(path)
    status 200
  elsif
    status 403
  end
end
# Handle PATCH-request (Receive and save the uploaded file)
patch "/files/*.*" do |path, ext|
  file_name = "#{path}.#{ext}"
  path = 'uploads/'+file_name
  data_bytes = params['myfile'][:tempfile] || request.body
  File.open(path, "w") do |f|
    f.write(data_bytes.read)
  end
  status 200
  response.headers["Location"] = "http://localhost:1080/files/24e533e02ec3bc40c387f1a0e460e216"
  status "200"
end
