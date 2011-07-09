function dateDiff(date1, date2) {
    var before = false;
    var diff = 0;
    if (date1 > date2) { before = true; diff = date1 - date2; }
    else { diff = date2 - date1; }
    var secDiff = Math.floor(diff / 1000);
    var minDiff = Math.floor(secDiff / 60);
    var hourDiff = Math.floor(minDiff / 60);
    var dayDiff = Math.floor(hourDiff / 24);
    var monthDiff = Math.floor(dayDiff / 30);
    var ret = monthDiff != 0 ? [ monthDiff, "month" ] :
        dayDiff != 0 ? [ dayDiff, "day" ] :
        hourDiff != 0 ? [ hourDiff, "hour" ] :
        minDiff != 0 ? [ minDiff, "min" ] : [ secDiff, "sec" ];
    return before ? [ -ret[0], ret[1] ] : [ ret[0], ret[1] ];
}

function dateDiffStr(diffArray) {
    var diff = diffArray[0];
    var term = diffArray[1];
    var ret = Math.abs(diff);
    if (term == "month") { ret += "ヶ月"; }
    else if (term == "day") { ret += "日"; }
    else if (term == "hour") { ret += "時間"; }
    else if (term == "min") { ret += "分"; }
    else if (term == "sec") { ret += "秒"; }
    if (diff < 0) { ret += "前"; }
    else { ret += "後"; }
    return ret;
}

function datetime2str(d) {
    var y = d.getYear();
    if (y < 2000) { y += 1900; }
    return sprintf("%d-%02d-%02d %02d:%02d:%02d",
        y, d.getMonth() + 1, d.getDate(), d.getHours(), d.getMinutes(), d.getSeconds());
}

function datetime2strYYYYMMDD(d) {
    var y = d.getYear();
    if (y < 2000) { y += 1900; }
    return sprintf("%d-%02d-%02d", y, d.getMonth() + 1, d.getDate());
}

function datetime2strHHmm(d) {
    return sprintf("%02d:%02d", d.getHours(), d.getMinutes());
}

function dateStringSimple(date, format) {
    if (isEmpty(format)) { format = 'yyyy-MM-dd HH:mm:ss'; }
    var dateFormat = new DateFormat(format);
    var writtenDate = dateFormat.parse(date);
    var ret = '';
    if (writtenDate) {
        var diff = dateDiff(new Date(), writtenDate);
        ret += (diff[1] == "month" || diff[1] == "day") ?
            datetime2str(writtenDate) : datetime2strHHmm(writtenDate);
        ret += "(" + dateDiffStr(diff) + ")";
    }
    return ret;
}
