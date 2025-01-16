local SCRIPT_TITLE = "Put Phonemes into Lyric"

function getClientInfo()
    return {
        name = SV:T(SCRIPT_TITLE),
        author = "UtaUtaUtau",
        category = "Uta's Shenanigans",
        versionNumber = 1,
        minEditorVersion = 65537
    }
end

function getTranslations(langCode)
    if langCode == "ja-jp" then
        return {
            {"Please select a note.", "ノートを選択してください。"}
        }
    elseif langCode == "zh-cn" then
        return {
            {"Please select a note.", "请选择注释。"}
        }
    elseif langCode == "es-la" then
        return {
            {"Please select a note.", "Por favor seleccione una nota."}
        }
    end
end

function main()
    local selection = SV:getMainEditor():getSelection() -- get selection    
    if selection:hasSelectedNotes() then -- check for selections
        local notes = selection:getSelectedNotes() -- get selected notes

        local group = SV:getMainEditor():getCurrentGroup() -- get current group to get default phonemes
        local phonemes = SV:getPhonemesForGroup(group)
        local groupNotes = group:getTarget()

        for i = 1, #notes do -- set the phoneme property to "phoneme" for selected notes without phoneme override
            if notes[i]:getPhonemes() == "" then
                notes[i]:setPhonemes("phoneme")
            end
        end

        for i = 1, groupNotes:getNumNotes() do -- put phonemes into lyrics
            local note = groupNotes:getNote(i)
            if note:getPhonemes() == "phoneme" then
                note:setLyrics("."..phonemes[i])
            elseif note:getPhonemes() ~= "" then
                note:setLyrics("."..note:getPhonemes())
            end
            note:setPhonemes("")
        end
    else -- complain
        SV:showMessageBox(SV:T(SCRIPT_TITLE), SV:T("Please select a note."))
    end
    SV:finish() -- finish execution
end

