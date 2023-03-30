var SCRIPT_TITLE = "Expressive Vibrato 2.0";

// Header
function getClientInfo() {
	return {
		"name" : SV.T(SCRIPT_TITLE),
		"author" : "UtaUtaUtau",
		"versionNumber" : 1.4,
		"minEditorVersion" : 65537
	};
}

function getTranslations(langCode) {
	if (langCode == "ja-jp") { //This is DeepL Translation for names that are not officially translated terms.
		return [
			["Expressive Vibrato 2.0", "表現豊かなビブラート 2.0"],
			["Please select a note.", "ノートを選択してください。"],
			["Loudness", "ラウドネス"],
			["Tension", "テンション"],
			["Breathiness", "ブレス"],
			["Voicing", "有声/無声音"],
			["Gender", "ジェンダー"],
			["Tone Shift", "トーンシフト"],
			["Adds vibrato to the parameters listed.", "リストアップされたパラメーターにビブラートをかけます。"]
		];
	} else if (langCode == "zh-cn") { //This is DeepL Translation for names that are not officially translated terms.
		return [
			["Expressive Vibrato 2.0", "富有表现力的颤音 2.0"],
			["Please select a note.", "请选择注释。"],
			["Loudness", "响度"],
			["Tension", "张力"],
			["Breathiness", "气声"],
			["Voicing", "发声"],
			["Gender", "性别"],
			["Tone Shift", "音区偏移"],
			["Adds vibrato to the parameters listed.", "将颤音添加到所列参数中。"]
		];
	} else if (langCode == "es-la") { //Thanks to haraao for this translation! I still used official translations for parameter names.
		return [
			["Expressive Vibrato 2.0", "Vibrato Expresivo 2.0"],
			["Please select a note.", "Por favor seleccione una nota."],
			["Loudness", "Volúmen"],
			["Tension", "Tensión"],
			["Breathiness", "Aire"],
			["Voicing", "Apertura"],
			["Gender", "Género"],
			["Tone Shift", "Cambio de Tono"],
			["Adds vibrato to the parameters listed.", "Le añade vibrato a los parámetros enumerados."]
		];
	}
	return [];
}

function envelopeFunc(fin, fout, len, t) { // Envelope function
	if (t < fin) return t / fin;
	if (t > len - fout) return 1 - (t - len + fout) / fout;
	return 1;
}

function contains(arr, x) { // Checks an array "arr" if it contains x. I'm not sure if SynthV JavaScript has it natively so.
	for (var i in arr) {
		if (x == arr[i]) return true;
	}
	return false;
}

function getAttributes(voice, note) { // Gets attributes needed cuz SynthV doesn't give me the stupid defaults.
	var res = {
		"tF0VbrStart": 0.250,
		"tF0VbrLeft": 0.2,
		"tF0VbrRight": 0.2,
		"fF0Vbr": 5.5,
		"pF0Vbr": 0,
		"dF0Vbr": 1
	}
	var keys = Object.keys(res);
	var voiceKeys = Object.keys(voice);
	var noteKeys = Object.keys(note);
	for (var i in keys) {
		var key = keys[i];
		if (contains(voiceKeys, key)) res[key] = voice[key];
		if (contains(noteKeys, key)) res[key] = note[key];
	}
	return res;
}

function makeVibrato(automation, timing, voice, note, envelope, depth) { // Draws vibrato
	var range = [note.getOnset(), note.getEnd()];
	var secRange = [timing.getSecondsFromBlick(range[0]), timing.getSecondsFromBlick(range[1])];
	var dur = secRange[1] - secRange[0];
	var attributes = getAttributes(voice, note.getAttributes());
	
	if (attributes.tF0VbrStart > dur || attributes.dF0Vbr == 0) return;	
	
	var vbrRange = [secRange[0] + attributes.tF0VbrStart, secRange[1]];
	var vbrLength = vbrRange[1] - vbrRange[0];
	range[0] = timing.getBlickFromSeconds(vbrRange[0]);
	var amCopy = automation.clone();
	
	automation.remove(range[0], range[1]);
	automation.add(range[0], amCopy.get(range[0]));
	automation.add(range[1], amCopy.get(range[1]));
	
	for (var i = vbrRange[0]; i < vbrRange[1]; i += 0.01) {
		var iBlick = timing.getBlickFromSeconds(i);
		var off = i - vbrRange[0];
		var vbr = Math.sin(attributes.fF0Vbr * 2 * Math.PI * off + attributes.pF0Vbr)
				  * depth 
				  * envelope.get(iBlick) 
				  * envelopeFunc(attributes.tF0VbrLeft, attributes.tF0VbrRight, vbrLength, off);
		var param = amCopy.get(iBlick) + vbr
		automation.add(iBlick, param);
	}
	
	automation.simplify(range[0], range[1]);
}

function expressiveVibrato(selection, options) { // Expressive Vibrato
	var scope = SV.getMainEditor().getCurrentGroup();
	var voice = scope.getVoice();
	var group = scope.getTarget();
	var notes = selection.getSelectedNotes();
	var timing = SV.getProject().getTimeAxis();
	
	notes.sort(function (a, b) {
		if (a.getOnset() < b.getOnset()) return -1;
		if (a.getOnset() > b.getOnset()) return 1;
		return 0;
	});
	
	var ld = group.getParameter("loudness");
	var tn = group.getParameter("tension");
	var br = group.getParameter("breathiness");
	var vc = group.getParameter("voicing");
	var gn = group.getParameter("gender");
	var ts = group.getParameter("toneShift");
	var envelope = group.getParameter("vibratoEnv");
	
	for (var i in notes) {
		var note = notes[i];
		if (options.loudness != 0) makeVibrato(ld, timing, voice, note, envelope, options.loudness);
		if (options.tension != 0) makeVibrato(tn, timing, voice, note, envelope, options.tension);
		if (options.breathiness != 0) makeVibrato(br, timing, voice, note, envelope, options.breathiness);
		if (options.voicing != 0) makeVibrato(vc, timing, voice, note, envelope, options.voicing);
		if (options.gender != 0) makeVibrato(gn, timing, voice, note, envelope, options.gender);
		if (options.toneShift != 0) makeVibrato(ts, timing, voice, note, envelope, options.toneShift);
	}
}

function main() { //Main function
	try {
		var selection = SV.getMainEditor().getSelection();
		var selectedNotes = selection.getSelectedNotes();
		
		if (selectedNotes.length < 1) {
			SV.showMessageBox(SV.T(SCRIPT_TITLE), SV.T("Please select a note."))
			SV.finish()
			return;
		}
		
		var form = {
			"title" : SV.T(SCRIPT_TITLE),
			"message" : SV.T("Adds vibrato to the parameters listed."),
			"buttons" : "OkCancel",
			"widgets" : [
				{
					"name" : "loudness", "type" : "Slider",
					"label" : SV.T("Loudness"),
					"format" : "%.3f Db",
					"minValue" : -12,
					"maxValue" : 12,
					"interval" : 0.005,
					"default" : -2
				},
				{
					"name" : "tension", "type" : "Slider",
					"label" : SV.T("Tension"),
					"format" : "%1.3f",
					"minValue" : -1,
					"maxValue" : 1,
					"interval" : 0.005,
					"default" : 0
				},
				{
					"name" : "breathiness", "type" : "Slider",
					"label" : SV.T("Breathiness"),
					"format" : "%1.3f",
					"minValue" : -1,
					"maxValue" : 1,
					"interval" : 0.005,
					"default" : 0
				},
				{
					"name" : "voicing", "type" : "Slider",
					"label" : SV.T("Voicing"),
					"format" : "%1.3f",
					"minValue" : -1,
					"maxValue" : 1,
					"interval" : 0.005,
					"default" : 0
				},
				{
					"name" : "gender", "type" : "Slider",
					"label" : SV.T("Gender"),
					"format" : "%1.3f",
					"minValue" : -1,
					"maxValue" : 1,
					"interval" : 0.005,
					"default" : 0
				},
				{
					"name" : "toneShift", "type" : "Slider",
					"label" : SV.T("Tone Shift"),
					"format" : "%.3f cents",
					"minValue" : -400,
					"maxValue" : 400,
					"interval" : 0.005,
					"default" : 0
				},
			]
		};
		var results = SV.showCustomDialog(form);
		if (results.status == 1) {
			expressiveVibrato(selection, results.answers);
		}
	} catch (error) {
		SV.showMessageBox(SV.T(SCRIPT_TITLE), error.message);
	} finally {
		SV.finish();
	}
}

// Debugging aka I just want a print function.
function debugPrint(text) {
	SV.showMessageBox(SV.T(SCRIPT_TITLE), text);
}

function printObject(obj) {
	var keys = Object.keys(obj);
	var text = "";
	for (var i in keys) {
		var value = obj[keys[i]];
		text += keys[i] + " : " + value + "\n";
	}
	debugPrint(text);
}
