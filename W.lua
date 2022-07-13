
function getClientInfo()
    return {
        name = SV:T("W"),
        category = "Tetris",
        author = "RigoLigo",
        versionNumber = 2
    }
end

function main()
    SV:getMainEditor():getCurrentGroup():getTarget():getNote(1):setLyrics("w")
end
