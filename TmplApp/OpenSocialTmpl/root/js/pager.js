var Pager = function() {
    this.prevLabel  = '前へ';
    this.nextLabel  = '次へ';
    this.total      = 0;
    this.limit      = 10;
    this.totalPages = 0;
    this.nowPage    = 1;
    this.firstPage  = 0;
    this.lastPage   = 0;
    this.offset     = 0;
    this.pagerFunction = 'pagerFunction';
    this.infoFormat = '%total件中%nowPageページ目 (%start～%end件)';
    this.setNowPage = function(nowPage) {
        this.nowPage = nowPage;
        this.offset = nowPage > 1 ? (nowPage - 1) * this.limit : 0;
    };
    this.calcPage = function() {
        if (this.total > this.limit) {
            this.totalPages = Math.ceil(this.total / this.limit);
        }
        this.firstPage = this.nowPage < 7 ? 1 : this.nowPage - 5;
        if (this.totalPages > 9 && this.firstPage + 9 > this.totalPages) {
            this.firstPage -= this.firstPage + 9 - this.totalPages;
        }
        this.lastPage = this.nowPage < 7 ? 10 : this.firstPage + 9;
        if (this.lastPage > this.totalPages) {
            this.lastPage = this.totalPages;
        }
    };
    this.toInfoString = function() {
        this.calcPage();
        var ret = this.infoFormat;
        ret = ret.replace('%total', this.total);
        ret = ret.replace('%start', this.offset + 1);
        ret = ret.replace('%end', this.nowPage == this.lastPage ? this.total : this.offset + this.limit);
        ret = ret.replace('%nowPage', this.nowPage);
        ret = ret.replace('%limit', this.limit);
        return ret;
    };
    this.toString = function() {
        this.calcPage();
        var tag = '';
        if (this.nowPage > 1) {
            tag += '<a href="javascript:' + this.pagerFunction + '(' + (this.nowPage - 1) + ')">'
                + this.prevLabel
                + '</a>&lt;&nbsp;';
        }
        for (var i = this.firstPage; i <= this.lastPage; i++) {
            if ((this.nowPage == 0 && i == 1) || this.nowPage == i) {
                tag += i;
            }
            else {
                tag += '<a href="javascript:' + this.pagerFunction + '(' + i + ')">'
                    + i
                    + '</a>';
            }
            tag += '&nbsp;';
        }
        if (this.nowPage < this.totalPages) {
            tag += '&gt;<a href="javascript:' + this.pagerFunction + '(' + (this.nowPage + 1) + ')">'
                + this.nextLabel
                + '</a>';
        }
        return tag;
    };
}
