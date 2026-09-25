import 'dart:convert';

/// Hosts (and everything under them) that only exist to serve ads, popups
/// and click-through redirects, the usual noise on manga and anime sites.
const _adHosts = <String>{
  'doubleclick.net',
  'googlesyndication.com',
  'googleadservices.com',
  'adservice.google.com',
  'adsafeprotected.com',
  'popads.net',
  'popcash.net',
  'propellerads.com',
  'propu.sh',
  'exoclick.com',
  'exosrv.com',
  'juicyads.com',
  'trafficjunky.net',
  'adsterra.com',
  'hilltopads.net',
  'clickadu.com',
  'adcash.com',
  'admaven.com',
  'a-ads.com',
  'mgid.com',
  'taboola.com',
  'outbrain.com',
  'revcontent.com',
  'onclickads.net',
  'adnxs.com',
  'ad-maven.com',
  'monetag.com',
  'richpartners.com',
  'tsyndicate.com',
  'realsrv.com',
  'syndication.exoclick.com',
  'popunder.net',
  'bidgear.com',
  'yllix.com',
  'dtscout.com',
};

/// Never blocked, even if something above would match: these run the bot
/// checks this browser exists to get through.
const _neverBlock = <String>{
  'challenges.cloudflare.com',
  'cloudflare.com',
  'turnstile.com',
};

bool _hostIn(String host, Set<String> set) {
  final h = host.toLowerCase();
  for (final entry in set) {
    if (h == entry || h.endsWith('.$entry')) return true;
  }
  return false;
}

/// True when [url] points at an ad host and should not be loaded.
bool isAdUrl(String url) {
  final host = Uri.tryParse(url)?.host ?? '';
  if (host.isEmpty || _hostIn(host, _neverBlock)) return false;
  return _hostIn(host, _adHosts);
}

/// A script for the page itself, run as early as the platform allows: it
/// drops popups, stops ad scripts, frames and requests before they load, and
/// hides ad slots that are already on the page. Safe to run more than once.
String adBlockScript() {
  final hosts = jsonEncode(_adHosts.toList());
  final allow = jsonEncode(_neverBlock.toList());
  return '''
(function () {
  if (window.__sumizuriAdBlock) return;
  window.__sumizuriAdBlock = true;
  var hosts = $hosts, allow = $allow;
  function inList(host, list) {
    host = (host || '').toLowerCase();
    for (var i = 0; i < list.length; i++) {
      if (host === list[i] || host.endsWith('.' + list[i])) return true;
    }
    return false;
  }
  function blocked(url) {
    try {
      var host = new URL(url, location.href).hostname;
      return host && !inList(host, allow) && inList(host, hosts);
    } catch (e) { return false; }
  }
  window.open = function () { return null; };
  var realFetch = window.fetch;
  if (realFetch) {
    window.fetch = function (input) {
      var url = typeof input === 'string' ? input : input && input.url;
      if (blocked(url)) return Promise.reject(new TypeError('blocked'));
      return realFetch.apply(this, arguments);
    };
  }
  var realOpen = XMLHttpRequest.prototype.open;
  XMLHttpRequest.prototype.open = function (method, url) {
    if (blocked(url)) { this.abort(); return; }
    return realOpen.apply(this, arguments);
  };
  function dropIfAd(node) {
    if (!node || !node.tagName) return false;
    var tag = node.tagName;
    if ((tag === 'SCRIPT' || tag === 'IFRAME' || tag === 'IMG' || tag === 'LINK') &&
        blocked(node.src || node.href)) {
      return true;
    }
    return false;
  }
  var realAppend = Node.prototype.appendChild;
  Node.prototype.appendChild = function (node) {
    if (dropIfAd(node)) return node;
    return realAppend.call(this, node);
  };
  var realInsert = Node.prototype.insertBefore;
  Node.prototype.insertBefore = function (node, ref) {
    if (dropIfAd(node)) return node;
    return realInsert.call(this, node, ref);
  };
  var css = 'ins.adsbygoogle,.adsbygoogle,iframe[id^="google_ads_iframe"],' +
    'div[id^="div-gpt-ad"],[id^="google_ads"],[id^="ScriptRoot"],' +
    'iframe[src*="doubleclick"],iframe[src*="googlesyndication"],' +
    'a[href*="doubleclick.net"],a[href*="popads"],.ad-slot,.ad-banner,' +
    '.ads-banner,.ad-container,.advertisement { display: none !important; }';
  function addStyle() {
    var style = document.createElement('style');
    style.textContent = css;
    (document.head || document.documentElement).appendChild(style);
  }
  if (document.documentElement) addStyle();
  else document.addEventListener('DOMContentLoaded', addStyle);
  new MutationObserver(function (records) {
    records.forEach(function (r) {
      r.addedNodes.forEach(function (n) {
        if (dropIfAd(n) && n.parentNode) n.parentNode.removeChild(n);
      });
    });
  }).observe(document.documentElement || document, { childList: true, subtree: true });
})();
''';
}
