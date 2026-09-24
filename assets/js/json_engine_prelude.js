(function () {
  var config = __sourceConfig;
  if (typeof config.baseUrl === 'string') config.baseUrl = config.baseUrl.trim();
  var entities = require('entities');
  var urlModule = require('url');
  var dateModule = require('date');

  function isWordChar(ch) {
    return (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') || (ch >= '0' && ch <= '9') || ch === '_';
  }

  function substitute(template, vars) {
    var result = '';
    var i = 0;
    while (i < template.length) {
      var open = template.indexOf('{', i);
      if (open === -1) {
        result += template.slice(i);
        break;
      }
      result += template.slice(i, open);
      var close = template.indexOf('}', open + 1);
      if (close === -1) {
        result += template.slice(open);
        break;
      }
      var key = template.slice(open + 1, close);
      var isWord = key.length > 0;
      for (var k = 0; isWord && k < key.length; k++) {
        if (!isWordChar(key[k])) isWord = false;
      }
      if (isWord && (key in vars) && vars[key] !== undefined && vars[key] !== null) {
        result += key === 'query' ? encodeURIComponent(vars[key]) : String(vars[key]);
      } else {
        result += template.slice(open, close + 1);
      }
      i = close + 1;
    }
    return result;
  }

  function getPath(obj, path) {
    if (!path) return obj;
    return path.split('.').reduce(function (acc, key) {
      return (acc === null || acc === undefined) ? undefined : acc[key];
    }, obj);
  }

  function lastPathSegment(url) {
    if (typeof url !== 'string' || !url) return '';
    var parts = url.split('?')[0].split('#')[0].split('/').filter(Boolean);
    return parts.length ? parts[parts.length - 1] : '';
  }

  function typeMatches(value, typeName) {
    if (typeName === 'string') return typeof value === 'string';
    if (typeName === 'number') return typeof value === 'number';
    if (typeName === 'boolean') return typeof value === 'boolean';
    if (typeName === 'array') return Array.isArray(value);
    if (typeName === 'object') return value !== null && typeof value === 'object' && !Array.isArray(value);
    if (typeName === 'null') return value === null || value === undefined;
    if (typeName === 'defined') return value !== null && value !== undefined;
    if (typeName === 'truthy') return Boolean(value);
    return false;
  }

  function resolveCondition(cond, value) {
    if (typeof cond === 'string') return typeMatches(value, cond);
    if (cond && typeof cond === 'object') {
      if ('not' in cond) return !resolveCondition(cond.not, value);
      if ('and' in cond) return cond.and.every(function (c) { return resolveCondition(c, value); });
      if ('or' in cond) return cond.or.some(function (c) { return resolveCondition(c, value); });
    }
    return false;
  }

  function resolveIfCondition(ifSpec, element) {
    if (ifSpec && typeof ifSpec === 'object' && typeof ifSpec.path === 'string') {
      return resolveCondition(ifSpec.is, getPath(element, ifSpec.path));
    }
    return resolveCondition(ifSpec, element);
  }

  function applyRegex(value, pattern) {
    if (typeof value !== 'string') return value;
    var compiled;
    try {
      compiled = new RegExp(pattern);
    } catch (e) {
      // A bad pattern makes the field empty and says why, instead of failing the whole list.
      console.error('Invalid regex ' + JSON.stringify(pattern) + ': ' + e.message);
      return null;
    }
    var match = compiled.exec(value);
    if (!match) return null;
    return match.length > 1 ? match[1] : match[0];
  }

  function applyTransform(value, transform) {
    if (value === null || value === undefined) return value;
    if (transform === 'number') {
      var n = parseFloat(String(value).replace(/[^0-9.\-]/g, ''));
      return isNaN(n) ? null : n;
    }
    if (transform === 'trim') {
      return typeof value === 'string' ? value.trim() : value;
    }
    if (transform === 'capitalize') {
      return typeof value === 'string' && value.length
        ? value.charAt(0).toUpperCase() + value.slice(1)
        : value;
    }
    if (transform === 'htmlToText') {
      if (typeof value !== 'string') return value;
      return entities.decode(
        value
          .replace(/<br\s*\/?>/gi, '\n')
          .replace(/<\/(p|div|h[1-6])>/gi, '\n\n')
          .replace(/<[^>]+>/g, '')
      )
        .replace(/[ \t]+\n/g, '\n')
        .replace(/\n{3,}/g, '\n\n')
        .trim();
    }
    if (transform === 'unixTimestamp') {
      var n = typeof value === 'number' ? value : parseFloat(String(value));
      if (isNaN(n)) return null;
      var ms = n < 1e12 ? n * 1000 : n;
      var d = new Date(ms);
      return isNaN(d.getTime()) ? null : d.toISOString();
    }
    if (transform === 'parseDate') {
      if (typeof value !== 'string' || !value) return null;
      var parsed = new Date(value);
      return isNaN(parsed.getTime()) ? null : parsed.toISOString();
    }
    return value;
  }

  function applyResolve(value, baseUrl) {
    if (typeof value !== 'string' || !value) return value;
    return urlModule.resolve(baseUrl, value);
  }

  function applyMap(value, key) {
    if (!Array.isArray(value)) return value;
    return value.map(function (item) {
      var mapped = getPath(item, key);
      return mapped === null || mapped === undefined ? item : mapped;
    });
  }

  function applySplit(value, separator, index) {
    if (typeof value !== 'string') return value;
    var parts = value.split(separator);
    var i = index < 0 ? parts.length + index : index;
    return i >= 0 && i < parts.length ? parts[i] : null;
  }

  function applyDecode(value, decode) {
    if (typeof value !== 'string') return Promise.resolve(value);
    var steps = Array.isArray(decode) ? decode : [decode];
    return steps.reduce(function (p, step) {
      return p.then(function (val) {
        if (typeof val !== 'string') return val;
        if (step === 'base64') {
          try {
            return require('base64').decode(val);
          } catch (e) {
            return null;
          }
        }
        if (step === 'urlDecode') {
          try {
            return decodeURIComponent(val.replace(/\+/g, ' '));
          } catch (e) {
            return null;
          }
        }
        if (step === 'unpack') {
          var unpacked = require('unpacker').unpackAll(val);
          return unpacked.length ? unpacked.join('\n') : null;
        }
        if (step === 'megaplay') {
          return host.crypto.aes.decrypt(val, {
            key: '693f4c4d5441783051362c3a7d35305500000000000000000000000000000000',
            keyEncoding: 'hex',
            iv: "W0;27ToaUpl_P%'c",
            ivEncoding: 'utf8',
            dataEncoding: 'base64',
            mode: 'cbc'
          }).catch(function () {
            return null;
          });
        }
        return val;
      });
    }, Promise.resolve(value));
  }

  function postProcessField(fieldConfig, value, baseUrl) {
    if (!fieldConfig) return Promise.resolve(value);
    var p = fieldConfig.decode !== undefined
      ? applyDecode(value, fieldConfig.decode)
      : Promise.resolve(value);
    return p.then(function (value) {
      if (typeof fieldConfig.regex === 'string') value = applyRegex(value, fieldConfig.regex);
      if (typeof fieldConfig.split === 'string' && typeof fieldConfig.index === 'number') {
        value = applySplit(value, fieldConfig.split, fieldConfig.index);
      }
      if (typeof fieldConfig.transform === 'string') value = applyTransform(value, fieldConfig.transform);
      if (typeof fieldConfig.round === 'number') {
        var factor = Math.pow(10, fieldConfig.round);
        value = typeof value === 'number' ? Math.round(value * factor) / factor : value;
      }
      if (typeof fieldConfig.map === 'string') value = applyMap(value, fieldConfig.map);
      if (fieldConfig.resolve === true) value = applyResolve(value, baseUrl);
      if (fieldConfig.resolveWeb === true) {
        value = applyResolve(value, typeof config.webBaseUrl === 'string' && config.webBaseUrl ? config.webBaseUrl.trim() : baseUrl);
      }
      if ('default' in fieldConfig && (value === null || value === undefined || value === '')) {
        value = fieldConfig.default;
      }
      return value;
    });
  }

  function templateVars(element) {
    // Always a fresh object, never the element itself.
    if (element && typeof element === 'object' && element.attributes) {
      var vars = {};
      Object.keys(element.attributes).forEach(function (key) { vars[key] = element.attributes[key]; });
      vars.text = element.text;
      return vars;
    }
    var copy = {};
    if (element && typeof element === 'object') {
      Object.keys(element).forEach(function (key) { copy[key] = element[key]; });
    }
    return copy;
  }

  function resolveField(fieldConfig, element, baseUrl, vars) {
    return resolveFieldValue(fieldConfig, element, baseUrl, vars).then(function (value) {
      return postProcessField(fieldConfig, value, baseUrl);
    });
  }

  function resolveFieldValue(fieldConfig, element, baseUrl, vars) {
    if (fieldConfig && Array.isArray(fieldConfig.join)) {
      var separator = typeof fieldConfig.separator === 'string' ? fieldConfig.separator : ' ';
      return Promise.all(
        fieldConfig.join.map(function (part) {
          return resolveField(part, element, baseUrl, vars);
        })
      ).then(function (parts) {
        var present = parts.filter(function (part) { return part !== null && part !== undefined && part !== ''; });
        if (fieldConfig.requireAll === true && present.length !== parts.length) return null;
        return present.join(separator);
      });
    }
    if (fieldConfig && Array.isArray(fieldConfig.or)) {
      var alternatives = fieldConfig.or;
      var tryNext = function (index) {
        if (index >= alternatives.length) return Promise.resolve(null);
        return resolveField(alternatives[index], element, baseUrl, vars).then(function (value) {
          if (value !== null && value !== undefined && value !== '') return value;
          return tryNext(index + 1);
        });
      };
      return tryNext(0);
    }
    if (fieldConfig && 'if' in fieldConfig) {
      var branch = resolveIfCondition(fieldConfig.if, element) ? fieldConfig.then : fieldConfig.else;
      return branch === undefined ? Promise.resolve(null) : resolveField(branch, element, baseUrl, vars);
    }
    if (fieldConfig && typeof fieldConfig.path === 'string') {
      return Promise.resolve(getPath(element, fieldConfig.path));
    }
    if (fieldConfig && typeof fieldConfig.template === 'string') {
      var mergedVars = templateVars(element);
      mergedVars.baseUrl = baseUrl;
      mergedVars.page = vars.page;
      mergedVars.query = vars.query;
      mergedVars.entryUrl = vars.entryUrl;
      mergedVars.chapterUrl = vars.chapterUrl;
      mergedVars.entrySlug = lastPathSegment(vars.entryUrl);
      mergedVars.chapterSlug = lastPathSegment(vars.chapterUrl);
      return Promise.resolve(substitute(fieldConfig.template, mergedVars));
    }
    var selector = fieldConfig.selector;
    if (!selector) {
      if (!element) return Promise.resolve(null);
      var attr = fieldConfig.attr || 'text';
      if (attr === 'text') return Promise.resolve(element.text);
      if (attr === 'html') return Promise.resolve(element.html);
      return Promise.resolve(element.attributes ? (element.attributes[attr] || null) : null);
    }
    return host.query(element.html, selector).then(function (matches) {
      var attr = fieldConfig.attr || 'text';
      function readMatch(match) {
        if (attr === 'text') return match.text;
        if (attr === 'html') return match.html;
        return match.attributes ? (match.attributes[attr] || null) : null;
      }
      if (fieldConfig.all === true) return matches.map(readMatch);
      var match = matches[0];
      return match ? readMatch(match) : null;
    });
  }

  function mapFields(fieldsConfig, element, baseUrl, vars) {
    var keys = Object.keys(fieldsConfig);
    return Promise.all(
      keys.map(function (key) {
        return resolveField(fieldsConfig[key], element, baseUrl, vars).then(function (value) {
          return [key, value];
        });
      })
    ).then(function (pairs) {
      var obj = {};
      pairs.forEach(function (pair) { obj[pair[0]] = pair[1]; });
      return obj;
    });
  }

  function buildRequest(sectionConfig, vars) {
    var headers;
    var effectiveVars = {
      baseUrl: config.baseUrl || '',
      entrySlug: lastPathSegment(vars.entryUrl),
      chapterSlug: lastPathSegment(vars.chapterUrl),
    };
    Object.keys(vars).forEach(function (key) { effectiveVars[key] = vars[key]; });
    if ('page' in vars) {
      var pageStart = typeof sectionConfig.pageStart === 'number' ? sectionConfig.pageStart : 1;
      effectiveVars.page = vars.page - 1 + pageStart;
      if (typeof sectionConfig.pageSize === 'number') {
        effectiveVars.pageSize = sectionConfig.pageSize;
        effectiveVars.offset = (vars.page - 1) * sectionConfig.pageSize;
      }
    }

    headers = Object.assign({}, config.headers || null);
    if (sectionConfig.headers) {
      Object.keys(sectionConfig.headers).forEach(function (key) {
        headers[key] = substitute(sectionConfig.headers[key], effectiveVars);
      });
    }
    return {
      url: substitute(sectionConfig.url, effectiveVars),
      method: (sectionConfig.method || 'GET').toUpperCase(),
      headers: Object.keys(headers).length ? headers : null,
      body: typeof sectionConfig.body === 'string' ? substitute(sectionConfig.body, effectiveVars) : undefined,
    };
  }

  function findHtmlString(value) {
    var best = '';
    (function walk(v) {
      if (typeof v === 'string') {
        if (v.indexOf('<') !== -1 && v.length > best.length) best = v;
      } else if (Array.isArray(v)) {
        v.forEach(walk);
      } else if (v && typeof v === 'object') {
        Object.keys(v).forEach(function (key) { walk(v[key]); });
      }
    })(value);
    return best;
  }

  function htmlBody(sectionConfig, response) {
    var path = sectionConfig.htmlPath;
    if (typeof path !== 'string') return response.body;
    var parsed;
    try {
      parsed = JSON.parse(response.body);
    } catch (e) {
      return response.body;
    }
    var html = path === '*'
      ? findHtmlString(parsed)
      : path === '' ? parsed : getPath(parsed, path);
    if (typeof html !== 'string' || html === '') {
      // Say what did come back, so the cause is clear, such as an error answer.
      var shape = parsed && typeof parsed === 'object' && !Array.isArray(parsed)
        ? 'an object with the keys ' + Object.keys(parsed).slice(0, 12).join(', ')
        : Array.isArray(parsed) ? 'a list of ' + parsed.length : typeof parsed;
      var start = String(response.body).replace(/\s+/g, ' ').slice(0, 200);
      throw new Error(
        'htmlPath ' + JSON.stringify(path) + ' found no HTML in the response. It was ' + shape +
        (response.statusCode && response.statusCode >= 400 ? ' (status ' + response.statusCode + ')' : '') +
        ', starting: ' + start
      );
    }
    return html;
  }

  function runOneResolve(spec, currentVars) {
    if (!spec || typeof spec.url !== 'string' || typeof spec.as !== 'string') {
      return Promise.resolve(currentVars);
    }
    var effectiveVars = {
      baseUrl: config.baseUrl || '',
      entrySlug: lastPathSegment(currentVars.entryUrl),
      chapterSlug: lastPathSegment(currentVars.chapterUrl),
    };
    Object.keys(currentVars).forEach(function (key) { effectiveVars[key] = currentVars[key]; });
    var url = substitute(spec.url, effectiveVars);
    if (/\{[a-zA-Z0-9_]+\}/.test(url)) {
      console.warn('Skipping resolve step for "' + spec.as + '": unresolved placeholder in ' + url);
      return Promise.resolve(currentVars);
    }
    var headers = Object.assign({}, config.headers || null);
    if (spec.headers) {
      Object.keys(spec.headers).forEach(function (key) {
        headers[key] = substitute(spec.headers[key], effectiveVars);
      });
    }
    return host.fetch(url, {
      method: (spec.method || 'GET').toUpperCase(),
      headers: Object.keys(headers).length ? headers : null,
      body: typeof spec.body === 'string' ? substitute(spec.body, effectiveVars) : undefined,
    }).then(function (response) {
      var extractedPromise;
      if (typeof spec.path === 'string') {
        var parsed = null;
        try { parsed = JSON.parse(response.body); } catch (_) {}
        extractedPromise = Promise.resolve(parsed ? getPath(parsed, spec.path) : null);
      } else if (typeof spec.selector === 'string') {
        var html = '';
        try { html = htmlBody(spec, response); } catch (_) { html = response.body || ''; }
        extractedPromise = host.query(html, spec.selector).then(function (matches) {
          var match = matches[0];
          if (!match) return null;
          var attr = spec.attr || 'text';
          if (attr === 'text') return match.text;
          if (attr === 'html') return match.html;
          return match.attributes ? (match.attributes[attr] || null) : null;
        });
      } else {
        var raw;
        try {
          raw = htmlBody(spec, response);
        } catch (_) {
          raw = response.body;
        }
        extractedPromise = Promise.resolve(raw);
      }

      return extractedPromise.then(function (extracted) {
        if (typeof spec.regex === 'string') extracted = applyRegex(extracted, spec.regex);
        if (typeof spec.transform === 'string') extracted = applyTransform(extracted, spec.transform);
        var merged = {};
        Object.keys(currentVars).forEach(function (key) { merged[key] = currentVars[key]; });
        merged[spec.as] = extracted;
        return merged;
      });
    }).catch(function (error) {
      console.error('resolve step for "' + spec.as + '" failed: ' + (error && error.message ? error.message : error));
      return currentVars;
    });
  }

  function resolveExtraVars(sectionConfig, vars) {
    var spec = sectionConfig.resolve;
    if (!spec) return Promise.resolve(vars);
    var specs = Array.isArray(spec) ? spec : [spec];
    return specs.reduce(function (promise, s) {
      return promise.then(function (curVars) {
        return runOneResolve(s, curVars);
      });
    }, Promise.resolve(vars));
  }

  function applyDefaultIndex(mapped) {
    mapped.forEach(function (obj, i) {
      if (!('index' in obj)) obj.index = i;
    });
    return mapped;
  }

  // Sorts by a dotted path into each mapped result, for a source with its own odd order.
  function applySort(mapped, sectionConfig) {
    var sort = sectionConfig.sort;
    if (!sort || typeof sort.by !== 'string') return mapped;
    var direction = sort.order === 'desc' ? -1 : 1;
    var withIndex = mapped.map(function (item, i) { return { item: item, i: i }; });
    withIndex.sort(function (a, b) {
      var av = getPath(a.item, sort.by);
      var bv = getPath(b.item, sort.by);
      var aMissing = av === null || av === undefined;
      var bMissing = bv === null || bv === undefined;
      if (aMissing && bMissing) return a.i - b.i;
      if (aMissing) return 1;
      if (bMissing) return -1;
      if (av < bv) return -1 * direction;
      if (av > bv) return 1 * direction;
      return a.i - b.i;
    });
    return withIndex.map(function (w) { return w.item; });
  }

  function singleElement(sectionConfig, response) {
    if (typeof sectionConfig.itemsPath === 'string') {
      return getPath(JSON.parse(response.body), sectionConfig.itemsPath);
    }
    if (typeof response.body === 'string' && response.body.trim().charAt(0) === '{') {
      try {
        return JSON.parse(response.body);
      } catch (_) {}
    }
    return { html: htmlBody(sectionConfig, response), text: '', attributes: {} };
  }

  function extractItems(sectionConfig, response) {
    if (typeof sectionConfig.itemsPath === 'string') {
      var items = getPath(JSON.parse(response.body), sectionConfig.itemsPath);
      return Promise.resolve(Array.isArray(items) ? items : (items && typeof items === 'object' ? [items] : []));
    }
    return host.query(htmlBody(sectionConfig, response), sectionConfig.itemSelector);
  }

  function findNextPageUrl(pagination, response, baseUrl, sectionConfig) {
    if (typeof pagination.nextPath === 'string') {
      var next = getPath(JSON.parse(response.body), pagination.nextPath);
      return Promise.resolve(typeof next === 'string' && next ? urlModule.resolve(baseUrl, next) : null);
    }
    if (typeof pagination.nextSelector === 'string') {
      return host.query(htmlBody(sectionConfig || {}, response), pagination.nextSelector).then(function (matches) {
        var match = matches[0];
        if (!match) return null;
        var attr = pagination.nextAttr || 'href';
        var raw = attr === 'text' ? match.text : (match.attributes ? match.attributes[attr] : null);
        return typeof raw === 'string' && raw ? urlModule.resolve(baseUrl, raw) : null;
      });
    }
    return Promise.resolve(null);
  }

  function escapeAttribute(text) {
    return String(text).replace(/&/g, '&amp;').replace(/"/g, '&quot;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  }

  var renderCache = {};

  function renderSection(sectionConfig, request) {
    var options = sectionConfig.render === true ? {} : sectionConfig.render;
    var key = request.url + JSON.stringify(options);
    var cached = renderCache[key];
    if (cached && Date.now() - cached.at < 20000) return cached.promise;
    var promise = host.render(request.url, options).then(function (rendered) {
      if (rendered.timedOut) {
        console.warn('render: the page never showed what "render" waits for (' + JSON.stringify(options) + '); using it as it was');
      }
      var captured = (rendered.resources || []).map(function (u) {
        return '<a href="' + escapeAttribute(u) + '">' + escapeAttribute(u) + '</a>';
      }).join('');
      return {
        statusCode: 200,
        body: rendered.html + '\n<div id="sumizuri-captured">' + captured + '</div>',
        headers: {},
        url: rendered.url,
      };
    });
    renderCache[key] = { at: Date.now(), promise: promise };
    promise.catch(function () { delete renderCache[key]; });
    return promise;
  }

  function fetchFor(sectionConfig, request) {
    if (sectionConfig && sectionConfig.render) {
      if (request.method && String(request.method).toUpperCase() !== 'GET') {
        return Promise.reject(new Error('"render" only works for GET requests'));
      }
      return renderSection(sectionConfig, request);
    }
    return host.fetch(request.url, {
      method: request.method,
      headers: request.headers,
      body: request.body,
    });
  }

  function fetchSectionPage(request, sectionConfig) {
    return fetchFor(sectionConfig, request);
  }

  function runSectionPaginated(sectionConfig, request, baseUrl, resolvedVars) {
    var maxPages = typeof sectionConfig.pagination.maxPages === 'number'
      ? sectionConfig.pagination.maxPages
      : 20;
    var allMapped = [];

    function loop(currentRequest, pagesFetched) {
      return fetchSectionPage(currentRequest, sectionConfig).then(function (response) {
        return extractItems(sectionConfig, response).then(function (elements) {
          return mapItems(sectionConfig, elements, baseUrl, resolvedVars);
        }).then(function (mapped) {
          allMapped = allMapped.concat(mapped);
          return findNextPageUrl(sectionConfig.pagination, response, baseUrl, sectionConfig);
        }).then(function (nextUrl) {
          if (nextUrl && pagesFetched + 1 < maxPages) {
            return loop(
              { url: nextUrl, method: 'GET', headers: currentRequest.headers, body: undefined },
              pagesFetched + 1
            );
          }
          return allMapped;
        });
      });
    }

    return loop(request, 0);
  }

  function resolvePreferences(vars) {
    if (!host.preference || !host.preference.all) return Promise.resolve(vars);
    return host.preference.all().then(function (prefs) {
      var merged = {};
      Object.keys(vars || {}).forEach(function (k) { merged[k] = vars[k]; });
      merged.preferences = prefs || {};
      if (prefs && typeof prefs === 'object') {
        Object.keys(prefs).forEach(function (k) {
          if (!(k in merged)) merged[k] = prefs[k];
          merged['pref_' + k] = prefs[k];
          merged['preference_' + k] = prefs[k];
        });
      }
      return merged;
    }).catch(function () {
      return vars;
    });
  }

  function traceSection(sectionConfig, mapped) {
    if (!host.isTesting || !sectionConfig) return mapped;
    var declared = sectionConfig.fields || {};
    var empty = {};
    mapped.forEach(function (item) {
      Object.keys(declared).forEach(function (key) {
        var value = item[key];
        if (value === null || value === undefined || value === '') {
          if (!empty[key]) empty[key] = { count: 0, declared: declared[key] };
          empty[key].count++;
        }
      });
    });
    // The same address or title twice usually means the selector matches the list twice.
    var urls = {};
    var titles = {};
    var sameUrl = 0;
    var sameTitle = 0;
    mapped.forEach(function (item) {
      if (typeof item.url === 'string' && item.url) {
        if (urls[item.url]) sameUrl++;
        urls[item.url] = true;
      }
      if (typeof item.title === 'string' && item.title) {
        if (titles[item.title]) sameTitle++;
        titles[item.title] = true;
      }
    });
    host.trace('section', {
      url: sectionConfig.url,
      itemSelector: sectionConfig.itemSelector,
      itemsPath: sectionConfig.itemsPath,
      items: mapped.length,
      empty: empty,
      sameUrl: sameUrl,
      sameTitle: sameTitle,
    });
    return mapped;
  }

  function mapItems(sectionConfig, elements, baseUrl, vars) {
    var firstError = null;
    return Promise.all(
      elements.map(function (element) {
        return mapFields(sectionConfig.fields, element, baseUrl, vars).catch(function (error) {
          if (!firstError) firstError = error;
          console.error('Skipped an item: ' + (error && error.message ? error.message : error));
          return null;
        });
      })
    ).then(function (mapped) {
      var kept = mapped.filter(function (item) { return item !== null; });
      if (elements.length > 0 && kept.length === 0 && firstError) throw firstError;
      return kept;
    });
  }

  function runSectionWithResolvedVars(sectionConfig, resolvedVars) {
    if (!sectionConfig) return Promise.resolve([]);
    var request = buildRequest(sectionConfig, resolvedVars);
    if (/\{[a-zA-Z0-9_]+\}/.test(request.url)) {
      console.warn('Skipping section fetch: unresolved placeholder in ' + request.url);
      return Promise.resolve([]);
    }
    var baseUrl = config.baseUrl || '';
    var itemsPromise = sectionConfig.pagination
      ? runSectionPaginated(sectionConfig, request, baseUrl, resolvedVars)
      : fetchSectionPage(request, sectionConfig).then(function (response) {
          return extractItems(sectionConfig, response);
        }).then(function (elements) {
          return mapItems(sectionConfig, elements, baseUrl, resolvedVars);
        });
    return itemsPromise.then(function (mapped) {
      return traceSection(sectionConfig, mapped);
    }).then(function (mapped) {
      return applySort(mapped, sectionConfig);
    }).then(applyDefaultIndex);
  }

  function runSection(sectionConfig, vars) {
    if (!sectionConfig) return Promise.resolve([]);
    return resolvePreferences(vars).then(function (varsWithPrefs) {
      return resolveExtraVars(sectionConfig, varsWithPrefs).then(function (resolvedVars) {
        return runSectionWithResolvedVars(sectionConfig, resolvedVars);
      });
    });
  }

  function runSingle(sectionConfig, vars) {
    return resolvePreferences(vars).then(function (varsWithPrefs) {
      return resolveExtraVars(sectionConfig, varsWithPrefs).then(function (resolvedVars) {
        var request = buildRequest(sectionConfig, resolvedVars);
        if (/\{[a-zA-Z0-9_]+\}/.test(request.url)) {
          console.warn('Skipping single fetch: unresolved placeholder in ' + request.url);
          return Promise.resolve({});
        }
        return fetchFor(sectionConfig, request).then(function (response) {
          return mapFields(
            sectionConfig.fields,
            singleElement(sectionConfig, response),
            config.baseUrl || '',
            resolvedVars
          );
        }).then(function (single) {
          traceSection(sectionConfig, [single]);
          return single;
        });
      });
    });
  }

  function subList(sectionConfig, key) {
    var sub = sectionConfig[key];
    if (!sub) return null;
    return Object.assign(
      {
        url: sectionConfig.url,
        method: sectionConfig.method,
        headers: sectionConfig.headers,
        body: sectionConfig.body,
        render: sectionConfig.render,
      },
      sub
    );
  }

  function playerHeaders(sectionConfig, vars) {
    if (!sectionConfig.videoHeaders) return null;
    var templateVars = {
      baseUrl: config.baseUrl || '',
      chapterUrl: vars.chapterUrl,
      chapterSlug: lastPathSegment(vars.chapterUrl),
    };
    Object.keys(vars || {}).forEach(function (key) { templateVars[key] = vars[key]; });
    var headers = {};
    Object.keys(sectionConfig.videoHeaders).forEach(function (key) {
      headers[key] = substitute(String(sectionConfig.videoHeaders[key]), templateVars);
    });
    return headers;
  }

  function withoutIndex(item) {
    var copy = {};
    Object.keys(item).forEach(function (key) {
      if (key !== 'index') copy[key] = item[key];
    });
    return copy;
  }

  function markerOf(sectionConfig, key, vars) {
    var sub = subList(sectionConfig, key);
    if (!sub) return Promise.resolve(null);
    return runSingle(sub, vars).then(
      function (range) {
        var start = Number(range && range.start);
        var end = Number(range && range.end);
        return isFinite(start) && isFinite(end) && end > start ? { start: start, end: end } : null;
      },
      function (error) {
        // A missing or odd marker only costs the skip button, never the video.
        console.warn('videos.' + key + ': ' + (error && error.message ? error.message : error));
        return null;
      }
    );
  }

  function runVideos(sectionConfig, vars) {
    if (!sectionConfig) return Promise.resolve([]);
    return resolvePreferences(vars).then(function (varsWithPrefs) {
      return resolveExtraVars(sectionConfig, varsWithPrefs).then(function (resolvedVars) {
        var subSubs = subList(sectionConfig, 'subtitles');
        var subAudio = subList(sectionConfig, 'audioTracks');
        return Promise.all([
          runSectionWithResolvedVars(sectionConfig, resolvedVars),
          subSubs ? runSectionWithResolvedVars(subSubs, resolvedVars) : Promise.resolve([]),
          subAudio ? runSectionWithResolvedVars(subAudio, resolvedVars) : Promise.resolve([]),
          markerOf(sectionConfig, 'intro', resolvedVars),
          markerOf(sectionConfig, 'outro', resolvedVars),
        ]).then(function (parts) {
          var headers = playerHeaders(sectionConfig, resolvedVars);
          var subtitles = parts[1].map(withoutIndex);
          var audioTracks = parts[2].map(withoutIndex);
          var videos = parts[0].map(function (video) {
            var out = withoutIndex(video);
            if (headers && !out.headers) out.headers = headers;
            if (subtitles.length) out.subtitles = subtitles;
            if (audioTracks.length) out.audioTracks = audioTracks;
            if (parts[3] && !out.intro) out.intro = parts[3];
            if (parts[4] && !out.outro) out.outro = parts[4];
            return out;
          });
          if (sectionConfig.expandPlaylists !== true) return videos;
          return Promise.all(
            videos.map(function (video) {
              return /\.m3u8(\?|#|$)/i.test(String(video.url)) ? require('hls').expand(video) : [video];
            })
          ).then(function (groups) {
            return [].concat.apply([], groups);
          });
        });
      });
    });
  }

  extension = {
    name: config.name,
    lang: config.lang,
    iconUrl: config.iconUrl,
    baseUrl: config.baseUrl,
    search: function (query, page, filters) {
      var searchVars = { query: query, page: page, filters: filters || {} };
      if (filters && typeof filters === 'object') {
        for (var k in filters) {
          if (Object.prototype.hasOwnProperty.call(filters, k)) {
            var val = filters[k];
            searchVars[k] = Array.isArray(val) ? val.join(',') : val;
            searchVars['filter_' + k] = searchVars[k];
          }
        }
      }
      return runSection(config.search, searchVars);
    },
    getPopular: function (page) {
      return runSection(config.popular, { page: page });
    },
    getLatest: function (page) {
      return runSection(config.latest, { page: page });
    },
    getChapterList: function (entryUrl) {
      return runSection(config.chapters, { entryUrl: entryUrl });
    },
  };

  if (config.pages) {
    extension.getPageList = function (chapterUrl) {
      return runSection(config.pages, { chapterUrl: chapterUrl });
    };
  }
  if (config.videos) {
    extension.getVideoList = function (chapterUrl) {
      return runVideos(config.videos, { chapterUrl: chapterUrl });
    };
  }

  if (config.details) {
    extension.getDetails = function (entryUrl) {
      return runSingle(config.details, { entryUrl: entryUrl });
    };
  }
  if (config.comments) {
    extension.getComments = function (entryUrl, sort) {
      return runSection(config.comments, { entryUrl: entryUrl, sort: sort });
    };
  }
  if (config.chapterComments) {
    extension.getChapterComments = function (chapterUrl, sort) {
      return runSection(config.chapterComments, { chapterUrl: chapterUrl, sort: sort });
    };
  }
  if (config.filters && Array.isArray(config.filters)) {
    extension.getFilters = function () {
      return Promise.resolve(config.filters);
    };
  }
  if (config.preferences && Array.isArray(config.preferences)) {
    extension.getSourcePreferences = function () {
      return Promise.resolve(config.preferences);
    };
  }
})();
