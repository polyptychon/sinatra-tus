# sinatra-tus
Upload using tus protocol and Sinatra as backend

## Starting server

```shell
bundle exec ruby poly_tusd.rb
```

## Tus Protocol in a glance

When CREATING a file:

1. POST /files => Returns 201 with 'Location' Header
2. (OPTIONAL) HEAD {Location} => Returns 200 with 'Offset: 0' Header
3. PATCH {Location} with 'Offset: 0' Header => Returns 200

When RESUMING a file:

1. HEAD {Location} => Returns 200 with 'Offset: {int}' Header
2. PATCH {Location} with 'Offset: {int}' Header => Returns 200

Poly EXTENSION : When CHECKING (one or more files)

1. POST /files/check with { "filepaths" => ["img1.jpg", "img2.jpg"]} => Returns 200 with JSON results


Poly EXTENSION : When MOVING (renaming a file)

1. POST {Location}/move with { "path" => "my/file/path/to/move/to"} => Returns 200


## Tus Protocol

### 1. Create File (unique name from server)

Request:
```
POST /files/ HTTP/1.1
Host: localhost:1080
Content-Type: application/json

```

Response:
```
HTTP/1.1 201 Created
Access-Control-Allow-Headers: Origin, X-Requested-With, Content-Type, Accept, Content-Disposition, Final-Length, file-type, file-path, file-checksum, Offset
Access-Control-Allow-Methods: HEAD,GET,PUT,POST,PATCH,DELETE
Access-Control-Allow-Origin: *
Access-Control-Expose-Headers: Location, Range, Content-Disposition, Offset, Checksum
Connection: Keep-Alive
Content-Length: 0
Content-Type: application/json
Date: Wed, 28 Jan 2015 10:36:15 GMT
Location: http://localhost:1080/files/44ff8be6aea80498bbe2c6c7e3d6ba40
Server: WEBrick/1.3.1 (Ruby/2.0.0/2014-05-08)
X-Content-Type-Options: nosniff

```

You use the `Location` header to issue the next HEAD/PATCH request

### 2. Determine the offset

Request:
```
HEAD /files/44ff8be6aea80498bbe2c6c7e3d6ba40 HTTP/1.1
Host: localhost:1080
```

Response:
```
HTTP/1.1 200 Ok
Offset: 70
```

### 3. Upload a chunk

Request:
```
PATCH /files/44ff8be6aea80498bbe2c6c7e3d6ba40 HTTP/1.1
Host: localhost:1080
Content-Type: application/offset+octet-stream
Content-Length: 30
Offset: 70

[remaining 30 bytes]
```

Response:
```
HTTP/1.1 200 Ok
```

## PolyTus Protocol

### POST /check


#### Request With JSON

```
POST /files/check HTTP/1.1
Host: localhost:1080
Content-Type: application/json

{ "filenames" : [ "img_5451.jpg" ,"unknown.jpg" ] }
```

#### Request With x-www-form-urlencoded

```
POST /files/check HTTP/1.1
Host: localhost:1080
Content-Type: application/x-www-form-urlencoded

filenames%5B%5D=img_5451.jpg&filenames%5B%5D=unknown.jpg
```

#### Response (in both cases)

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

### POST /{temp_file_name}/move

#### Request With JSON

Request:
```
POST /files/218fbf7e66ebc8a4eba684ef51d716c5/move HTTP/1.1
Host: localhost:1080
Authorization: Basic ZGFqaWFAcG9seXB0eWNob24uZ3I6RkB0Y0B0MTIz
Content-Type: application/json
Cache-Control: no-cache
Postman-Token: 20a952b1-f70a-f90b-48b0-a024bb774330

{ "path" : "test.img"}
```

#### Request With x-www-form-urlencoded

Request:
```
POST /files/44ff8be6aea80498bbe2c6c7e3d6ba40/move HTTP/1.1
Host: localhost:1080
Content-Type: application/x-www-form-urlencoded

path=test.img
```

#### Response (in both cases)

```
HTTP/1.1 201 Created
Access-Control-Allow-Headers: Origin, X-Requested-With, Content-Type, Accept, Content-Disposition, Final-Length, file-type, file-path, file-checksum, Offset
Access-Control-Allow-Methods: HEAD,GET,PUT,POST,PATCH,DELETE
Access-Control-Allow-Origin: *
Access-Control-Expose-Headers: Location, Range, Content-Disposition, Offset, Checksum
Connection: Keep-Alive
Content-Length: 0
Content-Type: application/json
Date: Tue, 27 Jan 2015 18:02:53 GMT
X-Content-Type-Options: nosniff

```
