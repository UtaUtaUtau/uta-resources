SCRIPT_TITLE = "Randomize Note Offsets"

function getClientInfo()
	return {
		name = SV:T(SCRIPT_TITLE),
		author = "UtaUtaUtau",
		category = "Uta's Shenanigans",
		versionNumber = 1,
		minEditorVersion = 65537
	}
end

local inputForm = {
	title = SV:T(SCRIPT_TITLE),
	message = SV:T("Randomize note offsets for selected notes by a range in seconds."),
	buttons = "OkCancel",
	widgets = {
		{
			name = "range", type = "Slider",
			label = SV:T("Range"),
			format = "%1.3f sec",
			minValue = 0,
			maxValue = 0.1,
			interval = 0.001,
			default = 0.005
		},
		{
			name = "seed", type = "TextBox",
			label = SV:T("Seed (for reproducible randomness)"),
			default = "0"
		},
		{
			name = "gaussian", type = "CheckBox",
			text = SV:T("Use Gaussian/Normal distribution"),
			default = true
		}
	}
}

function generateGaussian(mean, stddev) -- Marsaglia polar form algorithm
	local u, v, s;
	
	repeat
		u = math.random() * 2 - 1
		v = math.random() * 2 - 1
		s = u * u + v * v
	until (s <= 1 and s ~= 0)
	
	s = math.sqrt(-2 * math.log(s) / s)
	return mean + stddev * u * s
end

function main()
	-- Get selected notes
	local selection = SV:getMainEditor():getSelection()
	local notes = selection:getSelectedNotes()
	
	if #notes == 0 then -- Exit when no notes selected
		SV:showMessageBox(SV:T("No notes selected"), SV:T("Please select at least one note."))
	else
		local result = SV:showCustomDialog(inputForm)
		if result.status then -- If pressed OK
			local range = result.answers.range
			local seed = tonumber(result.answers.seed)
			local gauss = result.answers.gaussian
			
			math.randomseed(seed) -- set seed
			for i, note in pairs(notes) do -- for each note
				local noteAttr = note:getAttributes() -- Get note attribute
				local noteOff = noteAttr.tNoteOffset
				if not noteOff then noteOff = 0 end
				
				local rand; -- generate random number
				if gauss then
					rand = generateGaussian(0, range/2)
				else
					rand = 2 * range * math.random() - range
				end
				
				note:setAttributes({tNoteOffset=rand}) -- set random number to note offset
			end
		end
	end
	SV:finish()
end