require 'sinatra/base'

class TusdCORS < Sinatra::Base

  before do
    response.headers['Access-Control-Allow-Methods'] = 'HEAD,GET,PUT,POST,PATCH,DELETE'
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Expose-Headers'] = 'Location, Range, Content-Disposition, Offset, Checksum'
    response.headers['Access-Control-Allow-Headers'] = 'Origin, X-Requested-With, Content-Type, Accept, Content-Disposition, Entity-Length, file-type, file-path, file-checksum, Offset'
  end

  options "/*" do
    pass { status 200 }
  end
end
