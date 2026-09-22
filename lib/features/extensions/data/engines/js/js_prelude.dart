const String jsPrelude = '''
globalThis.host = {
  fetch: function(url, options) {
    return sendMessage("fetchUrl", JSON.stringify({ url: url, options: options || {} }))
      .then(function(result) {
        var parsed = JSON.parse(result);
        if (parsed && parsed.error) throw new Error(parsed.error);
        return parsed;
      });
  },
  query: function(html, selector) {
    return sendMessage("queryHtml", JSON.stringify({ html: html, selector: selector }))
      .then(function(result) {
        var parsed = JSON.parse(result);
        if (parsed && parsed.error) throw new Error(parsed.error);
        return parsed;
      });
  },
  // Returns a Promise of the hex digest for md5, sha1, sha224, sha256, sha384 or sha512.
  hash: function(algorithm, input) {
    return sendMessage("hash", JSON.stringify({ algorithm: algorithm, input: input }))
      .then(function(result) {
        var parsed = JSON.parse(result);
        if (parsed && parsed.error) throw new Error(parsed.error);
        return parsed.hash;
      });
  },
  // True in the Source Editor test panel and false in real browsing.
  isTesting: false,
  // Persistent key-value storage scoped to this source.
  storage: {
    get: function(key) {
      return sendMessage("storageGet", JSON.stringify({ key: key }))
        .then(function(result) {
          var parsed = JSON.parse(result);
          if (parsed && parsed.error) throw new Error(parsed.error);
          return parsed.value;
        });
    },
    set: function(key, value) {
      return sendMessage("storageSet", JSON.stringify({ key: key, value: value }))
        .then(function(result) {
          var parsed = JSON.parse(result);
          if (parsed && parsed.error) throw new Error(parsed.error);
          return true;
        });
    },
    delete: function(key) {
      return sendMessage("storageDelete", JSON.stringify({ key: key }))
        .then(function(result) {
          var parsed = JSON.parse(result);
          if (parsed && parsed.error) throw new Error(parsed.error);
          return true;
        });
    },
    remove: function(key) {
      return globalThis.host.storage.delete(key);
    },
    clear: function() {
      return sendMessage("storageClear", "{}")
        .then(function(result) {
          var parsed = JSON.parse(result);
          if (parsed && parsed.error) throw new Error(parsed.error);
          return true;
        });
    },
    all: function() {
      return sendMessage("storageAll", "{}")
        .then(function(result) {
          var parsed = JSON.parse(result);
          if (parsed && parsed.error) throw new Error(parsed.error);
          return parsed.values;
        });
    },
  },
  // User-configured settings defined by getSourcePreferences().
  preference: {
    get: function(key) {
      return sendMessage("preferenceGet", JSON.stringify({ key: key }))
        .then(function(result) {
          var parsed = JSON.parse(result);
          if (parsed && parsed.error) throw new Error(parsed.error);
          return parsed.value;
        });
    },
    all: function() {
      return sendMessage("preferenceAll", "{}")
        .then(function(result) {
          var parsed = JSON.parse(result);
          if (parsed && parsed.error) throw new Error(parsed.error);
          return parsed.values;
        });
    },
  },
};

// Mangayomi helpers: getPreferenceValue(key) and getPreferenceValue(sourceId, key).
globalThis.getPreferenceValue = function(a, b) {
  var k = typeof b !== 'undefined' ? b : a;
  return globalThis.host.preference.get(k);
};

globalThis.SharedPreferences = function() {
  return {
    get: function(key) {
      return globalThis.host.preference.get(key);
    },
  };
};

// Standard base64 encode and decode. btoa throws outside Latin-1, so encode to UTF-8 first.
(function() {
  var CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
  globalThis.btoa = function(str) {
    var out = '';
    var i = 0;
    while (i < str.length) {
      var c1 = str.charCodeAt(i++);
      if (c1 > 0xFF) throw new Error('btoa: The string contains characters outside of the Latin1 range');
      var c2 = str.charCodeAt(i++);
      var c3 = str.charCodeAt(i++);
      out += CHARS[c1 >> 2];
      out += CHARS[((c1 & 3) << 4) | ((isNaN(c2) ? 0 : c2) >> 4)];
      out += isNaN(c2) ? '=' : CHARS[((c2 & 0xF) << 2) | ((isNaN(c3) ? 0 : c3) >> 6)];
      out += isNaN(c3) ? '=' : CHARS[c3 & 0x3F];
    }
    return out;
  };
  globalThis.atob = function(str) {
    str = str.replace(/\\s/g, '');
    if (str.length % 4 !== 0) throw new Error('atob: The string to be decoded is not correctly encoded');
    var out = '';
    for (var i = 0; i < str.length; i += 4) {
      var a = CHARS.indexOf(str[i]);
      var b = CHARS.indexOf(str[i + 1]);
      var c = CHARS.indexOf(str[i + 2]);
      var d = CHARS.indexOf(str[i + 3]);
      out += String.fromCharCode((a << 2) | (b >> 4));
      if (str[i + 2] !== '=') out += String.fromCharCode(((b & 0xF) << 4) | (c >> 2));
      if (str[i + 3] !== '=') out += String.fromCharCode(((c & 0x3) << 6) | d);
    }
    return out;
  };
})();

// A fetch() shaped alias for host.fetch on the same guarded bridge.
globalThis.fetch = function(url, options) {
  return host.fetch(url, options).then(function(result) {
    return {
      ok: result.statusCode >= 200 && result.statusCode < 300,
      status: result.statusCode,
      headers: result.headers,
      text: function() { return Promise.resolve(result.body); },
      json: function() { return Promise.resolve(JSON.parse(result.body)); },
    };
  });
};

// A small standard library so sources do not each redo decoding, url and date helpers.
(function () {
  var modules = {
    entities: {
      decode: function (str) {
        if (!str) return '';
        return str
          .replace(/&amp;/g, '&')
          .replace(/&lt;/g, '<')
          .replace(/&gt;/g, '>')
          .replace(/&quot;/g, '"')
          .replace(/&#0?39;/g, "'")
          .replace(/&#8217;/g, "'")
          .replace(/&#8216;/g, "'")
          .replace(/&#8220;/g, '"')
          .replace(/&#8221;/g, '"')
          .replace(/&#8230;/g, '...')
          .trim();
      },
    },
    url: {
      resolve: function (baseUrl, url) {
        if (!url) return '';
        if (url.indexOf('http://') === 0 || url.indexOf('https://') === 0) return url;
        if (url.indexOf('//') === 0) return 'https:' + url;
        if (url.indexOf('/') === 0) return baseUrl + url;
        return baseUrl + '/' + url;
      },
    },
    date: {
      parse: function (str) {
        if (!str) return null;
        var d = new Date(str);
        return isNaN(d.getTime()) ? null : d.toISOString();
      },
    },
  };
  globalThis.require = function (name) {
    var mod = modules[name];
    if (!mod) {
      throw new Error('Unknown module "' + name + '". Available: ' + Object.keys(modules).join(', '));
    }
    return mod;
  };
})();
''';
