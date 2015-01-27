# sinatra-tus
Upload using tus protocol and Sinatra as backend

### Starting server

```shell
ruby app.rb
```

## POST /check


### With JSON

```
POST /files/check HTTP/1.1
Host: localhost:1080
Content-Type: application/json

{ "filenames" : [ "img_5451.jpg" ,"unknown.jpg" ] }
```

### With x-www-form-urlencoded

```
POST /files/check HTTP/1.1
Host: localhost:1080
Content-Type: application/x-www-form-urlencoded

filenames%5B%5D=img_5451.jpg&filenames%5B%5D=unknown.jpg
```

### Response (in both cases)

```
HTTP/1.1 200 OK
Access-Control-Allow-Headers: Origin, X-Requested-With, Content-Type, Accept, Content-Disposition, Final-Length, file-type, file-path, file-checksum, Offset
Access-Control-Allow-Methods: HEAD,GET,PUT,POST,PATCH,DELETE
Access-Control-Allow-Origin: *
Access-Control-Expose-Headers: Location, Range, Content-Disposition, Offset, Checksum
Connection: Keep-Alive
Content-Length: 112
Content-Type: application/json
Date: Tue, 27 Jan 2015 18:02:53 GMT
X-Content-Type-Options: nosniff

{"results":[{"name":"img_5451.jpg","status":"found","size":901264},{"name":"unknown.jpg","status":"not_found"}]}
```

The results will be like the following

```json
{
  "results": [
    {
      "name": "img_5451.jpg",
      "status": "found",
      "size": 901264
    },
    {
      "name": "unknown.jpg",
      "status": "not_found"
    }
  ]
}
```
