// we make it simple as possible
function jqGridInclude()
{
    var pathtojsfiles = "/js/jqGrid/"; // need to be ajusted
    // if you do not want some module to be included
    // set include to false.
    // by default all modules are included.
    var minver = true;
    var modules = [
        { include: true, incfile:'grid.base.js',minfile: 'grid.base-min.js'}, // jqGrid base
        { include: true, incfile:'grid.formedit.js',minfile: 'grid.formedit-min.js' }, // jqGrid Form editing
        { include: true, incfile:'grid.inlinedit.js',minfile: 'grid.inlinedit-min.js' }, // jqGrid inline editing
        { include: true, incfile:'grid.subgrid.js',minfile: 'grid.subgrid-min.js'}, //jqGrid subgrid
        { include: true, incfile:'grid.custom.js',minfile: 'grid.custom-min.js'}, //jqGrid custom 
        { include: true, incfile:'grid.postext.js',minfile: 'grid.postext-min.js'} //jqGrid postext
    ];
    for(var i=0;i<modules.length; i++)
    {
        if(modules[i].include === true) {
        	if (minver !== true) IncludeJavaScript(pathtojsfiles+modules[i].incfile,CallMe);
        	else IncludeJavaScript(pathtojsfiles+modules[i].minfile,CallMe);
        }
    }
    function CallMe() {
        return true;
    }
    function IncludeJavaScript(jsFile,oCallback)
    {
        var oHead = document.getElementsByTagName('head')[0];
        var oScript = document.createElement('script');
        oScript.type = 'text/javascript';
        oScript.src = jsFile;
        oHead.appendChild(oScript);
        // most browsers
        oScript.onload = oCallback;
        // IE
        oScript.onreadystatechange = function() {
            if (this.readyState == 'loaded' || this.readyState == 'complete') {
                oCallback();
            }
        };
        return false;
    }
}

jqGridInclude();
