'use strict';

var ResumableUpload;

var tus = window.tus = {
    upload: function(file, options) {
        var upload = new ResumableUpload(file, options);
        if (file) {
            upload._start();
        }
        return upload;
    },
    fingerprint: function(file) {
        return 'tus-' + file.name + '-' + file.type + '-' + file.size;
    }
};

ResumableUpload = (function() {
    ResumableUpload.SUPPORT = function() {
        return (typeof File !== 'undefined') && (typeof Blob !== 'undefined') && (typeof FileList !== 'undefined') && (!!Blob.prototype.webkitSlice || !!Blob.prototype.mozSlice || !!Blob.prototype.slice || false);
    };

    function ResumableUpload(file, options) {
        this.file = file;
        this.options = {
            endpoint: options.endpoint,
            fingerprint: options.fingerprint,
            resumable: (options.resumable !== undefined ? options.resetBefore : true),
            resetBefore: options.resetBefore,
            resetAfter: options.resetAfter,
            headers: (options.headers !== undefined ? options.headers : {}),
            chunkSize: options.chunkSize,
            minChunkSize: (options.minChunkSize !== undefined ? options.minChunkSize : 51200),
            maxChunkSize: (options.maxChunkSize !== undefined ? options.maxChunkSize : 2097152*10)
        };
        this._chunkTimer = -1;
        this.fileUrl = null;
        this.bytesWritten = null;
        this._jqXHR = null;
        this._deferred = $.Deferred();
        this._deferred.promise(this);
    }

    ResumableUpload.prototype._start = function() {
        if (!this.options.resumable || this.options.resetBefore === true) {
            this._urlCache(false);
        }
        if (!(this.fileUrl = this._urlCache())) {
            return this._post();
        } else {
            return this._head();
        }
    };

    ResumableUpload.prototype._post = function() {
        var headers, options;
        headers = $.extend({
            'Final-Length': this.file.size,
            'File-Type': this.file.type,
            'File-Name': this.file.name
        }, this.options.headers);
        options = {
            type: 'POST',
            url: this.options.endpoint,
            headers: headers
        };

        return $.ajax(options).fail((function(_this) {
            return function(jqXHR, textStatus, errorThrown) {
                return _this._emitFail("Could not post to file resource " + _this.options.endpoint + ". " + textStatus);
            };
        })(this)).done((function(_this) {
            return function(data, textStatus, jqXHR) {
                var location;
                location = jqXHR.getResponseHeader('Location');
                if (!location) {
                    return _emitFail('Could not get url for file resource. ' + textStatus);
                }
                _this.fileUrl = location;
                return _this._uploadFile(0);
            };
        })(this));
    };

    ResumableUpload.prototype._head = function() {
        var options;
        options = {
            type: 'HEAD',
            url: this.fileUrl,
            cache: false,
            headers: this.options.headers
        };
        console.log("Resuming known url " + this.fileUrl);
        return $.ajax(options).fail((function(_this) {
            return function(jqXHR, textStatus, errorThrown) {
                if (jqXHR.status === 404) {
                    return _this._post();
                } else {
                    return _this._emitFail("Could not head at file resource: " + textStatus);
                }
            };
        })(this)).done((function(_this) {
            return function(data, textStatus, jqXHR) {
                var bytesWritten, offset;
                offset = jqXHR.getResponseHeader('Offset');
                bytesWritten = parseInt(offset, 10) ? offset : 0;
                return _this._uploadFile(bytesWritten);
            };
        })(this));
    };

    ResumableUpload.prototype._getChunkSize = function() {
        var chunkSize, diff;
        if (this._chunkTimer < 0) {
            chunkSize = this.options.chunkSize = this.options.minChunkSize;
        } else {
            diff = (new Date().getTime()) - this._chunkTimer;
            chunkSize = this.options.chunkSize = Math.round(this.options.chunkSize / diff * 1000);
        }
        this._chunkTimer = new Date().getTime();
        return Math.min(Math.max(this.options.minChunkSize, chunkSize), this.options.maxChunkSize);
    };

    ResumableUpload.prototype._uploadFile = function(range_from) {
        var blob, bytesWrittenAtStart, headers, options, range_to, slice, xhr;
        this.bytesWritten = range_from;
        if (this.bytesWritten === this.file.size) {
            this._emitProgress();
            return this._emitDone();
        }
        this._urlCache(this.fileUrl);
        this._emitProgress();
        bytesWrittenAtStart = this.bytesWritten;
        range_to = this.file.size;
        var chunkSize = this._getChunkSize()
        if (this.options.chunkSize) {
            range_to = Math.min(range_to, range_from + chunkSize);
        }
        console.log(chunkSize);

        slice = this.file.slice || this.file.webkitSlice || this.file.mozSlice;
        blob = slice.call(this.file, range_from, range_to, this.file.type);
        xhr = $.ajaxSettings.xhr();
        headers = $.extend({
            'Offset': range_from,
            'Content-Type': 'application/offset+octet-stream'
        }, this.options.headers);
        options = {
            type: 'PATCH',
            url: this.fileUrl,
            data: blob,
            processData: false,
            contentType: this.file.type,
            cache: false,
            headers: headers,
            xhr: function() {
                return xhr;
            }
        };
        $(xhr.upload).bind('progress', (function(_this) {
            return function(e) {
                _this.bytesWritten = bytesWrittenAtStart + e.originalEvent.loaded;
                return _this._emitProgress(e);
            };
        })(this));
        return this._jqXHR = $.ajax(options).fail((function(_this) {
            return function(jqXHR, textStatus, errorThrown) {
                var msg;
                msg = jqXHR.responseText || textStatus || errorThrown;
                return _this._emitFail(msg);
            };
        })(this)).done((function(_this) {
            return function() {
                if (range_to === _this.file.size) {
                    console.log('done', arguments, _this, _this.fileUrl);
                    if (_this.options.resetAfter) {
                        _this._urlCache(false);
                    }
                    return _this._emitDone();
                } else {
                    return _this._uploadFile(range_to);
                }
            };
        })(this));
    };

    ResumableUpload.prototype.stop = function() {
        if (this._jqXHR != null) {
            return this._jqXHR.abort();
        }
    };

    ResumableUpload.prototype._emitProgress = function(e) {
        if (e == null) {
            e = null;
        }
        return this._deferred.notifyWith(this, [e, this.bytesWritten, this.file.size]);
    };

    ResumableUpload.prototype._emitDone = function() {
        return this._deferred.resolveWith(this, [this.fileUrl, this.file]);
    };

    ResumableUpload.prototype._emitFail = function(err) {
        return this._deferred.rejectWith(this, [err]);
    };

    ResumableUpload.prototype._urlCache = function(url) {
        var e, fingerPrint, result;
        fingerPrint = this.options.fingerprint;
        if (fingerPrint == null) {
            fingerPrint = tus.fingerprint(this.file);
        }
        if (url === false) {
            console.log('Resetting any known cached url for ' + this.file.name);
            return localStorage.removeItem(fingerPrint);
        }
        if (url) {
            result = false;
            try {
                result = localStorage.setItem(fingerPrint, url);
            } catch (_error) {
                e = _error;
            }
            return result;
        }
        return localStorage.getItem(fingerPrint);
    };

    ResumableUpload.prototype.fingerprint = function(file) {
        return 'tus-' + file.name + '-' + file.type + '-' + file.size;
    };

    return ResumableUpload;

})();