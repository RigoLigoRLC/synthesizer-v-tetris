
function getClientInfo()
    return {
        name = SV:T("D"),
        category = "Tetris",
        author = "RigoLigo",
        versionNumber = 2
    }
end

function main()
    SV:getMainEditor():getCurrentGroup():getTarget():getNote(1):setLyrics("d")
end
