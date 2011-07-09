(function() { 
    jQuery.fn.hoverToggle = function(mouseOnClass, mouseOffClass) {
        if (mouseOnClass == undefined) { mouseOnClass = "jquery-hover-toggle-on"; }
        if (mouseOffClass == undefined) { mouseOffClass = "jquery-hover-toggle-off"; }
        $(this).addClass(mouseOffClass);
        this.hover(function() {
           $(this).toggleClass(mouseOnClass);
        }, function() {
           $(this).toggleClass(mouseOnClass);
        })
        return this;
    }
})(jQuery);
