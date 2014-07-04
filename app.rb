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

options "/files/" do
  if request.env["Access-Control-Request-Method"]=="POST"
    response.headers["Content-Length"] = "0"
    status 200
  elsif request.env["Access-Control-Request-Method"]=="PATCH"
    response.headers["Content-Length"] = "0"
    status 200
  end
end

post "/files/" do
  response.headers["Location"] = "http://localhost:1080/files/24e533e02ec3bc40c387f1a0e460e216"
  status "201 Created"
end
post "/files/:filename" do
  response.headers["Location"] = "http://localhost:1080/files/24e533e02ec3bc40c387f1a0e460e216"
  status "200"
end
# Handle POST-request (Receive and save the uploaded file)
post "/files" do
  file_name = params['myfile'][:filename] || env['HTTP_X_FILENAME']
  path = 'uploads/'+file_name
  data_bytes = params['myfile'][:tempfile] || request.body
  headers['Offset'] if request.env["Final-Length"]
  File.open(path, "w") do |f|
    f.write(data_bytes.read)
  end
  status 200
end

# Handle PATCH-request (Receive and save the uploaded file chunks)
patch "/files/" do
  file_name = params['myfile'][:filename] || env['HTTP_X_FILENAME']
  path = 'uploads/'+file_name
  data_bytes = params['myfile'][:tempfile] || request.body
  offset = request.env['Offset']

  File.open(path, "w") do |f|
    f.seek(offset)
    f.write(data_bytes.read)
    headers['Offset'] = f.size.to_s
  end
  status 200
end

# Handle HEAD-request (Check if file exists)
head "/files/" do
  file_name = params['myfile'][:filename] || env['HTTP_X_FILENAME']
  path = 'uploads/'+file_name
  if File.file?(path)
    File.open(path, "r") do |f|
      headers['Offset'] = f.size.to_s
    end
    status 200
  else
    status 404
  end
end