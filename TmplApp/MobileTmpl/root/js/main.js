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

/*
    var dumper = new JKL.Dumper();
    document.write(dumper.dump(data))
*/
if ( typeof(JKL) == 'undefined' ) JKL = function() {};
JKL.Dumper = function () {
    return this;
};
JKL.Dumper.prototype.dump = function ( data, offset ) {
    if ( typeof(offset) == "undefined" ) offset = "";
    var nextoff = offset + "  ";
    switch ( typeof(data) ) {
    case "string":
        return '"'+this.escapeString(data)+'"';
        break;
    case "number":
        return data;
        break;
    case "boolean":
        return data ? "true" : "false";
        break;
    case "undefined":
        return "null";
        break;
    case "object":
        if ( data == null ) {
            return "null";
        } else if ( data.constructor == Array ) {
            var array = [];
            for ( var i=0; i<data.length; i++ ) {
                array[i] = this.dump( data[i], nextoff );
            }
            return "[\n"+nextoff+array.join( ",\n"+nextoff )+"\n"+offset+"]";
        } else {
            var array = [];
            for ( var key in data ) {
                var val = this.dump( data[key], nextoff );
                    key = '"'+this.escapeString( key )+'"';
                array[array.length] = key+": "+val;
            }
            if ( array.length == 1 && ! array[0].match( /[\n\{\[]/ ) ) {
                return "{ "+array[0]+" }";
            }
            return "{\n"+nextoff+array.join( ",\n"+nextoff )+"\n"+offset+"}";
        }
        break;
    default:
        return data;
        break;
    }
};

JKL.Dumper.prototype.escapeString = function ( str ) {
    return str.replace( /\\/g, "\\\\" ).replace( /\"/g, "\\\"" );
};

