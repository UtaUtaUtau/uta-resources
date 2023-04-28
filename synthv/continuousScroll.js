var SCRIPT_TITLE = "Continuous Scroll";

function getClientInfo() {
    return {
        "name" : SV.T(SCRIPT_TITLE),
        "author" : "UtaUtaUtau",
        "category" : "Uta's Shenanigans",
        "versionNumber" : 1.1,
        "minEditorVersion" : 65537
    }
}

var inputForm = {
    "title" : SV.T(SCRIPT_TITLE),
    "message" : SV.T("Follows the playhead while playing. Set where the playhead will be relative to the screen."),
    "buttons" : "OkCancel",
    "widgets" : [
        {
            "name" : "center", "type" : "Slider",
            "label" : SV.T("Playhead Position"),
            "format" : "%.2f%%",
            "minValue" : 0,
            "maxValue" : 100,
            "interval" : 0.01,
            "default" : 50
        }
    ]
};

function setInterval(t, callback) {
    callback();
    SV.setTimeout(t, setInterval.bind(null, t, callback));
}

function makeScroller(coordSystem, center) {
    var playback = SV.getPlayback();
    var timeAxis = SV.getProject().getTimeAxis();
    
    return function() {
        var position = timeAxis.getBlickFromSeconds(playback.getPlayhead());
        var range = coordSystem.getTimeViewRange();
        var leftOffset = (range[1] - range[0]) * center;
        
        var timeLeft = Math.max(position - leftOffset, 0);
        coordSystem.setTimeLeft(timeLeft);
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
    var result = SV.showCustomDialog(inputForm);
    if (result.status) {
        var playback = SV.getPlayback();
        
        playback.seek(0);
        playback.play();
        
        mainEditorScroller = makeScroller(SV.getMainEditor().getNavigation(), result.answers.center / 100);
        arrangementScroller = makeScroller(SV.getArrangement().getNavigation(), result.answers.center / 100);
        
        setInterval(20, checkPlayhead);
    } else {
        SV.finish();
    }
}