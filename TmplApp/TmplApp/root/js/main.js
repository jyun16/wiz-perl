function createQuery(params) {
    var ret = new Array();
    for (var key in params) { ret.push(key + "=" + encodeURIComponent(params[key])); }
    return ret.join('&');
}

function appendUriParams(uri, params) {
    if (uri instanceof Object != true) { uri = parseUri(uri); }
    var p = uri.params;
    for (var key in params) { p[key] = params[key]; }
    for (var key in p) { p[key] = decodeURIComponent(p[key]); }
    var ret = uri.scheme + '://' + uri.host;
    if (uri.port != 80 && uri.port != 443) {
        ret += ':' + uri.port;
    }
    ret += uri.path;
    var q = createQuery(p);
    if (q != '') { ret += '?' + q; }
    return ret;
}

function lineBreak(content) {
    return content.replace(/\r?\n/g, "<br />");
}

var htmlEscape = (function(){
    var map = {"<":"&lt;", ">":"&gt;", "&":"&amp;", "'":"&#39;", "\"":"&quot;", " ":"&nbsp;"};
    var replaceStr = function(s){ return map[s]; };
    return function(str) { return str.replace(/<|>|&|'|"|\s/g, replaceStr); };
})();

// parseUri 1.2.2
// (c) Steven Levithan <stevenlevithan.com>
// MIT License
function parseUri (str) {
    var o   = parseUri.options,
        m   = o.parser[o.strictMode ? "strict" : "loose"].exec(str),
        uri = {},
        i   = 14;
    while (i--) uri[o.key[i]] = m[i] || "";
    uri[o.q.name] = {};
    uri[o.key[12]].replace(o.q.parser, function ($0, $1, $2) {
        if ($1) uri[o.q.name][$1] = $2;
    });
    return uri;
};

parseUri.options = {
    strictMode: false,
    key: ["uri","scheme","authority","userInfo","user","password","host","port","relative","path","directory","file","query","anchor"],
    q:   {
        name:   "params",
        parser: /(?:^|&)([^&=]*)=?([^&]*)/g
    },
    parser: {
        strict: /^(?:([^:\/?#]+):)?(?:\/\/((?:(([^:@]*)(?::([^:@]*))?)?@)?([^:\/?#]*)(?::(\d*))?))?((((?:[^?#\/]*\/)*)([^?#]*))(?:\?([^#]*))?(?:#(.*))?)/,
        loose:  /^(?:(?![^:@]+:[^:@\/]*@)([^:\/?#.]+):)?(?:\/\/)?((?:(([^:@]*)(?::([^:@]*))?)?@)?([^:\/?#]*)(?::(\d*))?)(((\/(?:[^?#](?![^?#\/]*\.[^?#\/.]+(?:[?#]|$)))*\/?)?([^?#\/]*))(?:\?([^#]*))?(?:#(.*))?)/
    }

};
