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

The `Entity-Length` header indicates the final size of a new entity in bytes. This way a server will implicitly know when a file has completed uploading.
**The value MUST be a non-negative integer.**

Request:
```
POST /files/ HTTP/1.1
Host: localhost:1080
Content-Length: 0
Entity-Length: 100
```

Response:
```
HTTP/1.1 201 Created
Location: http://localhost:1080/files/44ff8be6aea80498bbe2c6c7e3d6ba40
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

Must pass 1 mandatory parameter `filenames` and 1 optional parameter `checksum` if you want it to also return the (MD5) checksum.


#### Request With JSON

```
POST /files/check HTTP/1.1
Host: localhost:1080
Content-Type: application/json

{ "filenames" : [ "img_5451.jpg" ,"unknown.jpg" ], "checksum" : true }
```

#### Request With x-www-form-urlencoded

```
POST /files/check HTTP/1.1
Host: localhost:1080
Content-Type: application/x-www-form-urlencoded

filenames%5B%5D=img_5451.jpg&filenames%5B%5D=unknown.jpg&checksum=true
```

#### Response (in both cases) NO CHECKSUM

```
HTTP/1.1 200 OK
Content-Length: 219
Content-Type: application/json

{"results":[{"name":"img_5451.jpg","friendly_name":"img_5451.jpg","status":"found","size":901264},{"name":"unknown.jpg","friendly_name":"unknown.jpg","status":"not_found"}]}
```

#### Response (in both cases) WITH CHECKSUM

```
HTTP/1.1 200 OK
Content-Length: 219
Content-Type: application/json

{"results":[{"name":"img_5451.jpg","friendly_name":"img_5451.jpg","status":"found","size":901264,"checksum":"da37a80437d9d27ae87e00c70e4744b4"},{"name":"unknown.jpg","friendly_name":"unknown.jpg","status":"not_found"}]}
```


The results will be like the following

```json
{
  "results": [
    {
      "name": "img_5451.jpg",
      "status": "found",
      "size": 901264,
      "checksum": "da37a80437d9d27ae87e00c70e4744b4"
    },
    {
      "name": "unknown.jpg",
      "status": "not_found"
    }
  ]
}
```

### POST /{temp_file_name}/move

Must pass 1 mandatory parameter `path` and 1 optional parameter `checksum` if you want it to also return the (MD5) checksum.


#### Request With JSON

Request:
```
POST /files/218fbf7e66ebc8a4eba684ef51d716c5/move HTTP/1.1
Host: localhost:1080
Content-Type: application/json

{ "path" : "test.img", "checksum" : true}
```

#### Request With x-www-form-urlencoded

Request:
```
POST /files/44ff8be6aea80498bbe2c6c7e3d6ba40/move HTTP/1.1
Host: localhost:1080
Content-Type: application/x-www-form-urlencoded

path=test.img&checksum=true
```

#### Response (in both cases) NO CHECKSUM

```
HTTP/1.1 201 Created
Content-Length: 0
Location: http://localhost:1080/files/final/test.img
```


#### Response (in both cases) WITH CHECKSUM

```
HTTP/1.1 201 Created
Content-Length: 0
Checksum: d41d8cd98f00b204e9800998ecf8427e
Location: http://localhost:1080/files/final/test.img
```
