function createQuery(params) {
    var ret = new Array();
    for (var key in params) { ret.push(key + "=" + encodeURIComponent(params[key])); }
    return ret.join('&');
}

function lineBreak(content) {
    return content.replace(/\r?\n/g, "<br />");
}

var htmlEscape = (function(){
    var map = {"<":"&lt;", ">":"&gt;", "&":"&amp;", "'":"&#39;", "\"":"&quot;", " ":"&nbsp;"};
    var replaceStr = function(s){ return map[s]; };
    return function(str) { return str.replace(/<|>|&|'|"|\s/g, replaceStr); };
})();

