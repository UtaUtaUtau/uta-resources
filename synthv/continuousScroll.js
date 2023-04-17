function getClientInfo() {
    return {
        "name" : SV.T("Continuous Scroll"),
        "author" : "UtaUtaUtau",
        "category" : "Uta's Shenanigans",
        "versionNumber" : 1,
        "minEditorVersion" : 65537
    }
}

function setInterval(t, callback) {
    callback();
    SV.setTimeout(t, setInterval.bind(null, t, callback));
}

function makeScroller(coordSystem) {
    var playback = SV.getPlayback();
    var timeAxis = SV.getProject().getTimeAxis();
    
    return function() {
        var position = timeAxis.getBlickFromSeconds(playback.getPlayhead());
        var range = coordSystem.getTimeViewRange();
        var middle = (range[0] + range[1]) / 2;
        
        if (position > middle) {
            coordSystem.setTimeLeft(range[0] + position - middle);
        }
    };
}

var mainEditorScroller;
var arrangementScroller;

function checkPlayhead() {
    var playback = SV.getPlayback();
    if (playback.getStatus() == "stopped") {
        SV.finish();
        return;
    }
    
    mainEditorScroller();
    arrangementScroller();
}

function main() {
    SV.getPlayback().play();
    
    mainEditorScroller = makeScroller(SV.getMainEditor().getNavigation());
    arrangementScroller = makeScroller(SV.getArrangement().getNavigation());
    
    setInterval(20, checkPlayhead);
}