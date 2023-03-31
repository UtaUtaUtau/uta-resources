SCRIPT_TITLE = "Scale Finder"

function getClientInfo()
    return {
        name = SV:T(SCRIPT_TITLE),
        author = "UtaUtaUtau",
        category = "Uta's Shenanigans",
        versionNumber = 1,
        minEditorVersion = 65537
    }
end

local majorWeight = {.748, .06, .488, .082, .67, .46, .096, .715, .104, .366, .057, .4}
local minorWeight = {.712, .084, .474, .618, .049, .46, .105, .747, .404, .067, .133, .330}
local keyNames = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "B"}

local trackSelector = {
    title = SV:T(SCRIPT_TITLE),
    message = SV:T("No selected notes or groups detected. Select a track to find the key of."),
    buttons = "OkCancel",
    widgets = {
        {
            name = "track", type = "ComboBox",
            label = SV:T("Tracks:"),
            choices = {},
            default = 0
        }
    }
}

function normalize(t)
    local mag = 0
    for _, v in pairs(t) do
        mag = mag + v * v
    end
    mag = math.sqrt(mag)
    
    res = {}
    for _, v in pairs(t) do
        table.insert(res, v / mag)
    end
    
    return res
end

function dot(a, b)
    if #a ~= #b then return nil end
    
    res = 0
    for i = 1, #a do
        res = res + a[i] * b[i]
    end
    
    return res
end

function argmax(t)
    local res = 1
    local maxValue = -math.huge
    for i, v in pairs(t) do
        if v > maxValue then
            maxValue = v
            res = i
        end
    end
    return res
end

function zeros(length)
    local res = {}
    for i = 1, length do
        res[i] = 0
    end
    return res
end

function tablemax(t)
    return math.max(table.unpack(t))
end

function appendNotesFromGroup(notes, groupReference)
    -- Exit if group is an audio file
    if groupReference:isInstrumental() then return nil end
    
    -- Get note group target and pitch offset
    local groupTarget = groupReference:getTarget()
    local pitchOffset = groupReference:getPitchOffset()
    
    -- Get notes from target and append to notes table
    local numNotes = groupTarget:getNumNotes()
    for i = 1, numNotes do
        table.insert(notes, {note=groupTarget:getNote(i), offset=pitchOffset})
    end
end

function main()
    -- Check selection state
    local selection = SV:getMainEditor():getSelection()
    local hasSelection = selection:hasSelectedContent()
    local notes = {}
    
    if hasSelection then -- If there's a selection, get notes from selected content
        if selection:hasSelectedNotes() then -- replace notes array if notes are selected
            notes = selection:getSelectedNotes()
        end
        
        if selection:hasSelectedGroups() then -- add notes from group if groups are selected
            local groups = selection:getSelectedGroups()
            for _, group in pairs(groups) do
                appendNotesFromGroup(notes, group)
            end
        end
    else -- Else, select a track
        -- Get current projects to get tracks
        local project = SV:getProject()
        local numTracks = project:getNumTracks()
        
        -- Loop through tracks to get names
        local trackNames = {}
        for i = 1, numTracks do
            table.insert(trackNames, project:getTrack(i):getName())
        end
        
        -- Set choices for dialog box
        trackSelector.widgets[1].choices = trackNames
        local result = SV:showCustomDialog(trackSelector)
        if result.status then -- Get notes in track
            -- Get track
            local trackIdx = result.answers.track + 1
            local track = project:getTrack(trackIdx)
            
            -- Loop through groups in track
            local numGroups = track:getNumGroups()
            local noteCounts = {}
            for i = 1, numGroups do
                -- Add notes from groups
                appendNotesFromGroup(notes, track:getGroupReference(i))
            end
        end
    end
    
    if #notes > 0 then
        -- Setup pitch vectors
        local flatRes, weightedRes
        local flatInput, weightedInput = zeros(12), zeros(12)
        local majorResFlat, minorResFlat = {}, {}
        local majorResWeighted, minorResWeighted = {}, {}
        
        for _, note in pairs(notes) do -- Fill up input array
            local pitch
            if note.offset then -- If from group with pitch offsets
                pitch = (note.note:getPitch() + note.offset) % 12 + 1
            else -- If from selection
                pitch = note:getPitch() % 12 + 1
            end
            flatInput[pitch] = 1
            weightedInput[pitch] = weightedInput[pitch] + 1
        end
        
        -- Normalize inputs cuz... idk it's fancy
        flatInput = normalize(flatInput)
        weightedInput = normalize(weightedInput)
        
        -- Calculate "probability" of each key
        for i = 1, 12 do
            -- Dot with weighting vectors
            majorResFlat[i] = dot(flatInput, majorWeight)
            minorResFlat[i] = dot(flatInput, minorWeight)
            
            majorResWeighted[i] = dot(weightedInput, majorWeight)
            minorResWeighted[i] = dot(weightedInput, minorWeight)
            
            -- Shift weighting vector for keys
            table.insert(majorWeight, 1, table.remove(majorWeight))
            table.insert(minorWeight, 1, table.remove(minorWeight))
        end
        
        -- Max value is the most probable key
        if tablemax(majorResFlat) > tablemax(minorResFlat) then
            flatRes = keyNames[argmax(majorResFlat)].."maj"
        else
            flatRes = keyNames[argmax(minorResFlat)].."min"
        end
        
        if tablemax(majorResWeighted) > tablemax(minorResWeighted) then
            weightedRes = keyNames[argmax(majorResWeighted)].."maj"
        else
            weightedRes = keyNames[argmax(minorResWeighted)].."min"
        end
        
        -- Show message box
        local res = string.format("%s: %s\n%s: %s", SV:T("Flat-input (based on presence of notes only)"), flatRes, SV:T("Weighted-input (based on frequency of notes)"), weightedRes)
        SV:showMessageBox(SV:T(SCRIPT_TITLE), res)
    else
        SV:showMessageBox(SV:T(SCRIPT_TITLE), SV:T("Please select notes, groups, or a track with content."))
    end
    SV:finish()
end