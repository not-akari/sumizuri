(function () {
  'use strict';
  var g = globalThis;


  function utf8Bytes(str) {
    var out = [];
    for (var i = 0; i < str.length; i++) {
      var c = str.charCodeAt(i);
      if (c >= 0xd800 && c <= 0xdbff && i + 1 < str.length) {
        var next = str.charCodeAt(i + 1);
        if (next >= 0xdc00 && next <= 0xdfff) {
          c = 0x10000 + ((c - 0xd800) << 10) + (next - 0xdc00);
          i++;
        }
      }
      if (c < 0x80) out.push(c);
      else if (c < 0x800) out.push(0xc0 | (c >> 6), 0x80 | (c & 63));
      else if (c < 0x10000) out.push(0xe0 | (c >> 12), 0x80 | ((c >> 6) & 63), 0x80 | (c & 63));
      else out.push(0xf0 | (c >> 18), 0x80 | ((c >> 12) & 63), 0x80 | ((c >> 6) & 63), 0x80 | (c & 63));
    }
    return out;
  }

  function utf8String(bytes) {
    var out = '';
    for (var i = 0; i < bytes.length; ) {
      var b = bytes[i++];
      var cp;
      if (b < 0x80) cp = b;
      else if (b >= 0xc0 && b < 0xe0 && i < bytes.length) cp = ((b & 31) << 6) | (bytes[i++] & 63);
      else if (b >= 0xe0 && b < 0xf0 && i + 1 < bytes.length) {
        cp = ((b & 15) << 12) | ((bytes[i++] & 63) << 6) | (bytes[i++] & 63);
      } else if (b >= 0xf0 && i + 2 < bytes.length) {
        cp = ((b & 7) << 18) | ((bytes[i++] & 63) << 12) | ((bytes[i++] & 63) << 6) | (bytes[i++] & 63);
      } else cp = 0xfffd;
      if (cp > 0xffff) {
        cp -= 0x10000;
        out += String.fromCharCode(0xd800 + (cp >> 10), 0xdc00 + (cp & 1023));
      } else out += String.fromCharCode(cp);
    }
    return out;
  }

  if (typeof g.TextEncoder === 'undefined') {
    g.TextEncoder = function TextEncoder() {
      this.encoding = 'utf-8';
    };
    g.TextEncoder.prototype.encode = function (str) {
      return Uint8Array.from(utf8Bytes(String(str === undefined ? '' : str)));
    };
  }
  if (typeof g.TextDecoder === 'undefined') {
    g.TextDecoder = function TextDecoder() {
      this.encoding = 'utf-8';
    };
    g.TextDecoder.prototype.decode = function (bytes) {
      return utf8String(bytes ? Array.prototype.slice.call(bytes) : []);
    };
  }


  function formEncode(s) {
    return encodeURIComponent(s)
      .replace(/%20/g, '+')
      .replace(/[!'()~]/g, function (c) {
        return '%' + c.charCodeAt(0).toString(16).toUpperCase();
      });
  }
  function formDecode(s) {
    s = s.replace(/\+/g, ' ');
    try {
      return decodeURIComponent(s);
    } catch (e) {
      return s;
    }
  }

  function URLSearchParamsPolyfill(init) {
    var list = [];
    Object.defineProperty(this, '_list', { value: list });
    if (typeof init === 'string') {
      init = init.charAt(0) === '?' ? init.slice(1) : init;
      if (init) {
        init.split('&').forEach(function (pair) {
          if (!pair) return;
          var at = pair.indexOf('=');
          list.push(at < 0 ? [formDecode(pair), ''] : [formDecode(pair.slice(0, at)), formDecode(pair.slice(at + 1))]);
        });
      }
    } else if (init && typeof init === 'object') {
      if (typeof init.forEach === 'function' && !Array.isArray(init) && typeof init.entries === 'function') {
        init.forEach(function (value, key) {
          list.push([String(key), String(value)]);
        });
      } else if (Array.isArray(init)) {
        init.forEach(function (pair) {
          list.push([String(pair[0]), String(pair[1])]);
        });
      } else {
        Object.keys(init).forEach(function (key) {
          list.push([key, String(init[key])]);
        });
      }
    }
  }
  var P = URLSearchParamsPolyfill.prototype;
  P.append = function (k, v) {
    this._list.push([String(k), String(v)]);
  };
  P.delete = function (k) {
    var list = this._list;
    for (var i = list.length - 1; i >= 0; i--) if (list[i][0] === k) list.splice(i, 1);
  };
  P.get = function (k) {
    for (var i = 0; i < this._list.length; i++) if (this._list[i][0] === k) return this._list[i][1];
    return null;
  };
  P.getAll = function (k) {
    return this._list
      .filter(function (p) {
        return p[0] === k;
      })
      .map(function (p) {
        return p[1];
      });
  };
  P.has = function (k) {
    return this.get(k) !== null;
  };
  P.set = function (k, v) {
    var found = false;
    var list = this._list;
    for (var i = 0; i < list.length; i++) {
      if (list[i][0] === k) {
        if (found) {
          list.splice(i--, 1);
        } else {
          list[i][1] = String(v);
          found = true;
        }
      }
    }
    if (!found) list.push([String(k), String(v)]);
  };
  P.sort = function () {
    var indexed = this._list.map(function (p, i) {
      return { p: p, i: i };
    });
    indexed.sort(function (a, b) {
      return a.p[0] < b.p[0] ? -1 : a.p[0] > b.p[0] ? 1 : a.i - b.i;
    });
    this._list.length = 0;
    for (var i = 0; i < indexed.length; i++) this._list.push(indexed[i].p);
  };
  P.forEach = function (fn, thisArg) {
    var self = this;
    this._list.slice().forEach(function (p) {
      fn.call(thisArg, p[1], p[0], self);
    });
  };
  P.keys = function () {
    return this._list
      .map(function (p) {
        return p[0];
      })
      [Symbol.iterator]();
  };
  P.values = function () {
    return this._list
      .map(function (p) {
        return p[1];
      })
      [Symbol.iterator]();
  };
  P.entries = function () {
    return this._list
      .map(function (p) {
        return [p[0], p[1]];
      })
      [Symbol.iterator]();
  };
  P[Symbol.iterator] = P.entries;
  P.toString = function () {
    return this._list
      .map(function (p) {
        return formEncode(p[0]) + '=' + formEncode(p[1]);
      })
      .join('&');
  };
  if (typeof g.URLSearchParams === 'undefined') g.URLSearchParams = URLSearchParamsPolyfill;

  function resolveRef(base, ref) {
    ref = String(ref).trim();
    if (/^[a-z][a-z0-9+.-]*:/i.test(ref)) return ref;
    var m = /^([a-z][a-z0-9+.-]*:)(\/\/[^\/?#]*)?([^?#]*)(\?[^#]*)?(#.*)?$/i.exec(String(base));
    if (!m) throw new Error('Not an absolute URL: "' + base + '"');
    var scheme = m[1];
    var authority = m[2] || '';
    var path = m[3] || '';
    var query = m[4] || '';
    if (ref.indexOf('//') === 0) return scheme + ref;
    if (ref === '') return scheme + authority + path + query;
    if (ref.charAt(0) === '#') return scheme + authority + path + query + ref;
    var refQuery = '';
    var refHash = '';
    var hashAt = ref.indexOf('#');
    if (hashAt >= 0) {
      refHash = ref.slice(hashAt);
      ref = ref.slice(0, hashAt);
    }
    var queryAt = ref.indexOf('?');
    if (queryAt >= 0) {
      refQuery = ref.slice(queryAt);
      ref = ref.slice(0, queryAt);
    }
    if (ref === '') return scheme + authority + path + refQuery + refHash;
    var merged = ref.charAt(0) === '/' ? ref : path.slice(0, path.lastIndexOf('/') + 1) + ref;
    if (!authority && merged.charAt(0) !== '/') merged = '/' + merged;
    var out = [];
    merged.split('/').forEach(function (part, i, all) {
      if (part === '..') {
        if (out.length > 1) out.pop();
        if (i === all.length - 1) out.push('');
      } else if (part === '.') {
        if (i === all.length - 1) out.push('');
      } else out.push(part);
    });
    var joined = out.join('/');
    if (joined.charAt(0) !== '/') joined = '/' + joined;
    return scheme + authority + joined + refQuery + refHash;
  }

  function URLPolyfill(url, base) {
    var full = base === undefined ? String(url) : resolveRef(String(base), String(url));
    var m = /^([a-z][a-z0-9+.-]*:)\/\/(?:([^:@\/?#]*)(?::([^@\/?#]*))?@)?(\[[^\]]*\]|[^:\/?#]*)(?::(\d+))?([^?#]*)(\?[^#]*)?(#.*)?$/i.exec(full);
    if (!m) throw new TypeError('Invalid URL: "' + full + '"');
    this.protocol = m[1].toLowerCase();
    this.username = m[2] || '';
    this.password = m[3] || '';
    this.hostname = m[4].toLowerCase();
    this.port = m[5] || '';
    this.pathname = m[6] || '/';
    this.hash = m[8] && m[8] !== '#' ? m[8] : '';
    Object.defineProperty(this, 'searchParams', { value: new g.URLSearchParams(m[7] || '') });
  }
  var U = URLPolyfill.prototype;
  Object.defineProperty(U, 'search', {
    get: function () {
      var s = this.searchParams.toString();
      return s ? '?' + s : '';
    },
    set: function (v) {
      this.searchParams._list.length = 0;
      var fresh = new g.URLSearchParams(String(v));
      var list = this.searchParams._list;
      fresh._list.forEach(function (p) {
        list.push(p);
      });
    },
  });
  Object.defineProperty(U, 'host', {
    get: function () {
      return this.hostname + (this.port ? ':' + this.port : '');
    },
  });
  Object.defineProperty(U, 'origin', {
    get: function () {
      return this.protocol + '//' + this.host;
    },
  });
  Object.defineProperty(U, 'href', {
    get: function () {
      var auth = this.username ? this.username + (this.password ? ':' + this.password : '') + '@' : '';
      return this.protocol + '//' + auth + this.host + this.pathname + this.search + this.hash;
    },
  });
  U.toString = function () {
    return this.href;
  };
  U.toJSON = U.toString;
  if (typeof g.URL === 'undefined') g.URL = URLPolyfill;


  function ask(name, payload) {
    return sendMessage(name, JSON.stringify(payload)).then(function (result) {
      var parsed = JSON.parse(result);
      if (parsed && parsed.error) throw new Error(parsed.error);
      return parsed;
    });
  }

  function show(value) {
    if (typeof value === 'string') return value;
    if (value instanceof Error) return value.stack || String(value);
    var seen = [];
    try {
      return JSON.stringify(value, function (key, v) {
        if (typeof v === 'object' && v !== null) {
          if (seen.indexOf(v) >= 0) return '[circular]';
          seen.push(v);
        }
        return typeof v === 'undefined' ? '[undefined]' : v;
      });
    } catch (e) {
      return String(value);
    }
  }
  var nativeConsole = g.console;
  var sourceConsole = {};
  ['log', 'info', 'warn', 'error', 'debug'].forEach(function (level) {
    sourceConsole[level] = function () {
      var text = Array.prototype.map.call(arguments, show).join(' ');
      try {
        sendMessage('log', JSON.stringify({ level: level, text: text }));
      } catch (e) {
        // A log line is never worth failing the source over.
      }
      if (nativeConsole && typeof nativeConsole[level] === 'function') {
        try {
          nativeConsole[level].apply(nativeConsole, arguments);
        } catch (e) {
        }
      }
    };
  });
  g.console = sourceConsole;

  g.host.trace = function (kind, data) {
    if (!g.host.isTesting) return;
    try {
      sendMessage('trace', JSON.stringify({ kind: kind, data: data }));
    } catch (e) {
    }
  };

  function cryptoOptions(options) {
    var o = options || {};
    return {
      mode: o.mode,
      key: o.key,
      iv: o.iv,
      passphrase: o.passphrase,
      keyEncoding: o.keyEncoding,
      ivEncoding: o.ivEncoding,
      dataEncoding: o.dataEncoding,
      output: o.output,
      padding: o.padding,
    };
  }

  var cryptoApi = {
    aes: {
      encrypt: function (data, options) {
        var payload = cryptoOptions(options);
        payload.encrypt = true;
        payload.data = String(data);
        return ask('aes', payload).then(function (r) {
          return r.value;
        });
      },
      decrypt: function (data, options) {
        var payload = cryptoOptions(options);
        payload.encrypt = false;
        payload.data = String(data);
        return ask('aes', payload).then(function (r) {
          return r.value;
        });
      },
    },
    hmac: function (algorithm, key, input, options) {
      var o = options || {};
      return ask('hmac', {
        algorithm: algorithm,
        key: key,
        input: input,
        keyEncoding: o.keyEncoding,
        output: o.output,
      }).then(function (r) {
        return r.value;
      });
    },
    hash: function (algorithm, input) {
      return g.host.hash(algorithm, input);
    },
  };
  g.host.crypto = cryptoApi;


  function search(page, from, kind, expr, options) {
    var o = options || {};
    var payload = { page: page, html: o.html !== false };
    if (from !== null) payload.from = from;
    if (o.limit) payload.limit = o.limit;
    payload[kind] = expr;
    return ask('selectHtml', payload).then(function (r) {
      if (r.values) return r.values;
      return r.items.map(function (item) {
        return makeElement(page, item);
      });
    });
  }

  function scope(page, from) {
    var api = {
      select: function (css, options) {
        return search(page, from, 'css', css, options);
      },
      xpath: function (expr, options) {
        return search(page, from, 'xpath', expr, options);
      },
      selectOne: function (css) {
        return search(page, from, 'css', css, { limit: 1 }).then(function (found) {
          return found.length ? found[0] : null;
        });
      },
      xpathOne: function (expr) {
        return search(page, from, 'xpath', expr, { limit: 1 }).then(function (found) {
          return found.length ? found[0] : null;
        });
      },
      text: function (css) {
        return api.selectOne(css).then(function (el) {
          return el ? el.text : null;
        });
      },
      attr: function (css, name) {
        return api.selectOne(css).then(function (el) {
          return el && el.attributes[name] !== undefined ? el.attributes[name] : null;
        });
      },
    };
    return api;
  }

  function makeElement(page, item) {
    var el = scope(page, item.id);
    el.id = item.id;
    el.tag = item.tag;
    el.text = item.text;
    el.html = item.html;
    el.attributes = item.attributes;
    var own = el.attr;
    el.attr = function (nameOrSelector, name) {
      if (name === undefined) {
        return item.attributes[nameOrSelector] !== undefined ? item.attributes[nameOrSelector] : null;
      }
      return own(nameOrSelector, name);
    };
    return el;
  }

  g.host.parse = function (html) {
    return ask('parseHtml', { html: String(html) }).then(function (r) {
      return scope(r.id, null);
    });
  };


  function patternText(value) {
    if (value === undefined || value === null) return undefined;
    return value instanceof RegExp ? value.source : String(value);
  }

  g.host.render = function (url, options) {
    var o = options || {};
    return ask('render', {
      url: String(url),
      waitFor: o.waitFor,
      waitForResource: patternText(o.waitForResource),
      capture: patternText(o.capture),
      script: o.script,
      userAgent: o.userAgent,
      timeout: o.timeout,
    });
  };


  function makeHeaders(raw) {
    var map = {};
    Object.keys(raw || {}).forEach(function (k) {
      map[k.toLowerCase()] = String(raw[k]);
    });
    var headers = {};
    Object.keys(map).forEach(function (k) {
      headers[k] = map[k];
    });
    Object.defineProperty(headers, 'get', {
      value: function (name) {
        var v = map[String(name).toLowerCase()];
        return v === undefined ? null : v;
      },
    });
    Object.defineProperty(headers, 'has', {
      value: function (name) {
        return Object.prototype.hasOwnProperty.call(map, String(name).toLowerCase());
      },
    });
    return headers;
  }

  g.fetch = function (url, options) {
    var o = {};
    if (options) {
      Object.keys(options).forEach(function (k) {
        o[k] = options[k];
      });
    }
    var headers = {};
    Object.keys(o.headers || {}).forEach(function (k) {
      headers[k] = o.headers[k];
    });
    function hasHeader(name) {
      return Object.keys(headers).some(function (k) {
        return k.toLowerCase() === name;
      });
    }
    if (o.json !== undefined) {
      o.body = JSON.stringify(o.json);
      if (!hasHeader('content-type')) headers['Content-Type'] = 'application/json';
      delete o.json;
    } else if (o.form !== undefined) {
      o.body = new g.URLSearchParams(o.form).toString();
      if (!hasHeader('content-type')) headers['Content-Type'] = 'application/x-www-form-urlencoded;charset=UTF-8';
      delete o.form;
    } else if (o.body instanceof g.URLSearchParams) {
      o.body = o.body.toString();
      if (!hasHeader('content-type')) headers['Content-Type'] = 'application/x-www-form-urlencoded;charset=UTF-8';
    }
    if (o.body !== undefined && o.body !== null && !o.method) o.method = 'POST';
    o.headers = headers;
    var requested = String(url);
    return g.host.fetch(requested, o).then(function (result) {
      var body = result.body;
      var finalUrl = result.url || requested;
      return {
        ok: result.statusCode >= 200 && result.statusCode < 300,
        status: result.statusCode,
        url: finalUrl,
        redirected: finalUrl !== requested,
        headers: makeHeaders(result.headers),
        text: function () {
          return Promise.resolve(body);
        },
        json: function () {
          return Promise.resolve(JSON.parse(body));
        },
      };
    });
  };


  var PACKED = /\}\s*\(\s*(['"])((?:\\[\s\S]|(?!\1)[^\\])*)\1\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*(['"])((?:\\[\s\S]|(?!\5)[^\\])*)\5\s*\.split\(\s*(['"])\|\7\s*\)/;
  var PACKED_MARK = /eval\s*\(\s*function\s*\(\s*p\s*,\s*a\s*,\s*c\s*,\s*k\s*,\s*e\s*,\s*[dr]\s*\)/;

  function unescapeJs(s) {
    return s.replace(/\\(u[0-9a-fA-F]{4}|x[0-9a-fA-F]{2}|[\s\S])/g, function (all, e) {
      if (e.charAt(0) === 'u' && e.length === 5) return String.fromCharCode(parseInt(e.slice(1), 16));
      if (e.charAt(0) === 'x' && e.length === 3) return String.fromCharCode(parseInt(e.slice(1), 16));
      if (e === 'n') return '\n';
      if (e === 't') return '\t';
      if (e === 'r') return '\r';
      return e;
    });
  }

  function baseDigit(n, radix) {
    return (n < radix ? '' : baseDigit(Math.floor(n / radix), radix)) + ((n = n % radix) > 35 ? String.fromCharCode(n + 29) : n.toString(36));
  }

  // The text a packed script would evaluate to. Throws when source is not a packed script.
  function unpack(source) {
    var m = PACKED.exec(source);
    if (!m) throw new Error('unpacker: not a p.a.c.k.e.r script');
    var payload = unescapeJs(m[2]);
    var radix = parseInt(m[3], 10);
    var count = parseInt(m[4], 10);
    var words = unescapeJs(m[6]).split('|');
    if (radix < 2 || radix > 62) throw new Error('unpacker: unsupported radix ' + radix);
    var table = {};
    for (var i = count - 1; i >= 0; i--) {
      var key = baseDigit(i, radix);
      table[key] = words[i] || key;
    }
    return payload.replace(/\b\w+\b/g, function (word) {
      return Object.prototype.hasOwnProperty.call(table, word) ? table[word] : word;
    });
  }

  // Every packed script found in html, unpacked. Scripts that cannot be unpacked are left out.
  function unpackAll(html) {
    var found = [];
    var re = /eval\s*\(\s*function\s*\(\s*p\s*,\s*a\s*,\s*c\s*,\s*k\s*,\s*e\s*,\s*[dr]\s*\)[\s\S]*?\.split\(\s*(['"])\|\1\s*\)[^\n<]*/g;
    var m;
    while ((m = re.exec(String(html)))) {
      try {
        found.push(unpack(m[0]));
      } catch (e) {
      }
    }
    return found;
  }


  function attributes(line) {
    var out = {};
    var re = /([A-Z0-9-]+)=("[^"]*"|[^,]*)/g;
    var m;
    while ((m = re.exec(line))) {
      var v = m[2];
      out[m[1]] = v.charAt(0) === '"' ? v.slice(1, -1) : v;
    }
    return out;
  }

  function isMasterPlaylist(text) {
    return /#EXT-X-STREAM-INF/.test(String(text));
  }

  function qualityLabel(height, bandwidth) {
    if (height) return height + 'p';
    if (bandwidth) return Math.round(bandwidth / 1000) + ' kbps';
    return 'Auto';
  }

  function parseMaster(text, baseUrl) {
    var lines = String(text).split(/\r?\n/);
    var variants = [];
    var audio = [];
    var subtitles = [];
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i].trim();
      if (line.indexOf('#EXT-X-STREAM-INF:') === 0) {
        var a = attributes(line.slice(18));
        var next = i + 1;
        while (next < lines.length && (lines[next].trim() === '' || lines[next].trim().charAt(0) === '#')) next++;
        if (next >= lines.length) continue;
        var size = /^(\d+)x(\d+)$/.exec(a.RESOLUTION || '');
        var bandwidth = parseInt(a.BANDWIDTH || a['AVERAGE-BANDWIDTH'] || '0', 10) || 0;
        var height = size ? parseInt(size[2], 10) : 0;
        variants.push({
          url: resolveRef(baseUrl, lines[next].trim()),
          bandwidth: bandwidth,
          width: size ? parseInt(size[1], 10) : 0,
          height: height,
          codecs: a.CODECS || null,
          frameRate: a['FRAME-RATE'] ? parseFloat(a['FRAME-RATE']) : null,
          audioGroup: a.AUDIO || null,
          quality: qualityLabel(height, bandwidth),
        });
        i = next;
      } else if (line.indexOf('#EXT-X-MEDIA:') === 0) {
        var t = attributes(line.slice(13));
        if (!t.URI) continue;
        var track = {
          url: resolveRef(baseUrl, t.URI),
          label: t.NAME || t.LANGUAGE || 'Track',
          language: t.LANGUAGE || null,
        };
        if (t.TYPE === 'AUDIO') audio.push(track);
        else if (t.TYPE === 'SUBTITLES') subtitles.push(track);
      }
    }
    variants.sort(function (x, y) {
      return y.bandwidth - x.bandwidth || y.height - x.height;
    });
    return { variants: variants, audio: audio, subtitles: subtitles };
  }

  function expandPlaylist(video, options) {
    var o = options || {};
    var headers = video.headers || o.headers || {};
    return g
      .fetch(video.url, { headers: headers })
      .then(function (response) {
        if (!response.ok) return [video];
        return response.text().then(function (text) {
          if (!isMasterPlaylist(text)) return [video];
          var master = parseMaster(text, response.url || video.url);
          if (master.variants.length < 2 || master.audio.length) return [video];
          var shared = {};
          if (video.headers) shared.headers = video.headers;
          if (video.subtitles && video.subtitles.length) shared.subtitles = video.subtitles;
          var auto = {};
          Object.keys(video).forEach(function (k) {
            auto[k] = video[k];
          });
          auto.quality = video.quality || 'Auto';
          var out = [auto];
          master.variants.forEach(function (v) {
            var one = { url: v.url, quality: v.quality };
            Object.keys(shared).forEach(function (k) {
              one[k] = shared[k];
            });
            out.push(one);
          });
          return out;
        });
      })
      .catch(function () {
        return [video];
      });
  }


  var b64 = {
    encode: function (str) {
      return g.btoa(
        utf8Bytes(String(str))
          .map(function (b) {
            return String.fromCharCode(b);
          })
          .join('')
      );
    },
    decode: function (str) {
      var bytes = b64.toBytes(str);
      return utf8String(bytes);
    },
    toBytes: function (str) {
      var s = String(str).replace(/-/g, '+').replace(/_/g, '/').replace(/\s/g, '');
      while (s.length % 4) s += '=';
      var raw = g.atob(s);
      var out = [];
      for (var i = 0; i < raw.length; i++) out.push(raw.charCodeAt(i));
      return out;
    },
  };


  var baseRequire = g.require;
  var extra = {
    crypto: cryptoApi,
    base64: b64,
    unpacker: { unpack: unpack, unpackAll: unpackAll },
    hls: { isMaster: isMasterPlaylist, parseMaster: parseMaster, expand: expandPlaylist },
  };
  g.require = function (name) {
    if (Object.prototype.hasOwnProperty.call(extra, name)) return extra[name];
    var mod;
    try {
      mod = baseRequire(name);
    } catch (e) {
      throw new Error('Unknown module "' + name + '". Available: entities, url, date, ' + Object.keys(extra).join(', '));
    }
    if (name === 'url') {
      return {
        resolve: mod.resolve,
        absolute: resolveRef,
      };
    }
    return mod;
  };
})();
