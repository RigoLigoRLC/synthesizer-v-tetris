
function getClientInfo()
    return {
        name = SV:T("Tetris-S"),
        category = "Tetris",
        author = "RigoLigo",
        versionNumber = 2
    }
end

function main()
    SV:getMainEditor():getCurrentGroup():getTarget():getNote(1):setLyrics("s")
end
