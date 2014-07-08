class ResumableUpload
  ResumableUpload.SUPPORT = ->
    ((typeof(File) != 'undefined') && (typeof(Blob) != 'undefined') &&
      (typeof(FileList)!= 'undefined') &&
      (!!Blob.prototype.webkitSlice || !!Blob.prototype.mozSlice || !!Blob.prototype.slice || false)
    )

  constructor: (file, options) ->
    @file = file
    @options =
      endpoint:     options.endpoint
      fingerprint:  options.fingerprint
      resumable:    (if options.resumable isnt undefined then options.resetBefore else true)
      resetBefore:  options.resetBefore
      resetAfter:   options.resetAfter
      headers:      (if options.headers isnt undefined then options.headers else {})
      chunkSize:    options.chunkSize
      minChunkSize: (if options.minChunkSize isnt undefined then options.minChunkSize else 51200)
      maxChunkSize: (if options.minChunkSize isnt undefined then options.minChunkSize else 2097152*8)

    # The url of the uploaded file, assigned by the tus upload endpoint
    @fileUrl = null

    # Bytes sent to the server so far
    @bytesWritten = null

    # @TODO Add @bytesTotal again

    # the jqXHR object
    @_jqXHR = null

    # Create a deferred and make our upload a promise object
    @_deferred = $.Deferred();
    @_deferred.promise(this);

  _start : ->
    # Optionally resetBefore
    @_urlCache false  if not @options.resumable or @options.resetBefore is true
    unless @fileUrl = @_urlCache()
      @_post()
    else
      @_head()

  _post : ->
    headers = $.extend({
      'Final-Length': @file.size
    }, @options.headers)

    options =
      type:    'POST'
      url:     @options.endpoint
      headers: headers

    $.ajax(options)
      .fail(
        (jqXHR, textStatus, errorThrown) =>
          # @todo: Implement retry support
          @_emitFail("Could not post to file resource #{@options.endpoint}. #{textStatus}")
      )
      .done(
        (data, textStatus, jqXHR) =>
          location = jqXHR.getResponseHeader('Location')
          return _emitFail('Could not get url for file resource. ' + textStatus) unless location
          @fileUrl = location
          @_uploadFile(0)
      )

  _head : ->
    options =
      type:    'HEAD',
      url:     @fileUrl,
      cache:   false,
      headers: @options.headers

    console.log("Resuming known url #{@fileUrl}");
    $.ajax(options)
    .fail(
      (jqXHR, textStatus, errorThrown) =>
        if(jqXHR.status == 404)
          @_post()
        else
          @_emitFail("Could not head at file resource: #{textStatus}");
    )
    .done(
      (data, textStatus, jqXHR) =>
        offset = jqXHR.getResponseHeader('Offset');
        bytesWritten = if parseInt(offset, 10) then offset else 0
        @_uploadFile(bytesWritten);
    )

  _uploadFile : (range_from) ->
    @bytesWritten = range_from
    if (@bytesWritten == @file.size)
      # Cool, we already completely uploaded this.
      # Update progress to 100%.
      @_emitProgress();
      return @_emitDone();

    @_urlCache(@fileUrl);
    @_emitProgress();

    bytesWrittenAtStart = @bytesWritten;

    range_to = @file.size;

    if(@options.chunkSize)
      range_to = Math.min(range_to, range_from + @options.chunkSize);


    slice = @file.slice || @file.webkitSlice || @file.mozSlice
    blob  = slice.call(@file, range_from, range_to, @file.type)
    xhr   = $.ajaxSettings.xhr()

    headers = $.extend({
      'Offset': range_from
      'Content-Type': 'application/offset+octet-stream'
    }, @options.headers)

    options =
      type:         'PATCH'
      url:          @fileUrl
      data:         blob
      processData:  false
      contentType:  @file.type
      cache:        false
      headers:      headers
      xhr: ->       return xhr

    $(xhr.upload).bind('progress',
      (e) =>
        @bytesWritten = bytesWrittenAtStart + e.originalEvent.loaded
        @_emitProgress(e)
    )

    @_jqXHR = $.ajax(options)
      .fail(
        (jqXHR, textStatus, errorThrown) =>
          # @TODO: Compile somewhat meaningful error
          # Needs to be cleaned up
          # Needs to have retry
          msg = jqXHR.responseText || textStatus || errorThrown
          @_emitFail(msg)
      )
      .done(
        =>
          if(range_to == @file.size)
            console.log('done', arguments, this, @fileUrl)
            @_urlCache(false) if @options.resetAfter
            @_emitDone()
          else
            # still have more to upload
            @_uploadFile(range_to)
      )

  stop : ->
    @_jqXHR.abort() if @_jqXHR?

  _emitProgress : (e = null) ->
    @_deferred.notifyWith(this, [e, @bytesWritten, @file.size])

  _emitDone : ->
    @_deferred.resolveWith(this, [@fileUrl, @file])

  _emitFail : (err) ->
    @_deferred.rejectWith(this, [err])

  _urlCache : (url)->
    fingerPrint = @options.fingerprint;
    fingerPrint ?= @fingerprint(@file);

    if (url == false)
      console.log('Resetting any known cached url for ' + this.file.name)
      return localStorage.removeItem(fingerPrint)

    if (url)
      result = false;
      try
        result = localStorage.setItem(fingerPrint, url);
      catch e
        # most likely quota exceeded error

      return result;

    return localStorage.getItem(fingerPrint);

  fingerprint: (file) ->
    'tus-' + file.name + '-' + file.type + '-' + file.size;

class PolyResumableUpload extends ResumableUpload
  constructor: (file, options) ->
    super(file, options)
    @_chunkTimer = -1

  _getChunkSize : ->
    if (@_chunkTimer < 0)
      chunkSize = @options.chunkSize = @options.minChunkSize
    else
      diff = (new Date().getTime()) - @_chunkTimer
      chunkSize = @options.chunkSize = Math.round(@options.chunkSize / diff * 1000)

    @_chunkTimer = new Date().getTime()

    return Math.min(Math.max(@options.minChunkSize, chunkSize), @options.maxChunkSize)

  _uploadFile : (range_from) ->
    if (@options.chunkSize)
      @options.chunkSize = @_getChunkSize()

    super(range_from)