
--[[
    Synthesizer V Studio Pro Script Group
    Tetris Game. MIT License.
    The complete package includes W.lua, A.lua, S.lua and D.lua, all under the
    same license.

    Copyright 2022 RigoLigo

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to
    deal in the Software without restriction, including without limitation the
    rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
    sell copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
    IN THE SOFTWARE.
]]

--[[

    You're about to see some true magic that even I don't fully understand.
    Don't try to comprehend the code.

]]


function getClientInfo()
    return {
        name = SV:T("Main"),
        category = "Tetris",
        author = "RigoLigo",
        versionNumber = 2
    }
end

function getNote(idx)
    return assert(scope:getNote(idx))
end

Unit = 0.25
NextX = 15
Bottom = 30
Height = 20
Width = 10
MapX = 5

blockKinds = {
    { 3, {1,0,0,0}, {1,1,1,0}, {0,0,0,0}, {0,0,0,0} }, -- L
    { 3, {0,1,0,0}, {1,1,1,0}, {0,0,0,0}, {0,0,0,0} }, -- T
    { 3, {0,1,1,0}, {1,1,0,0}, {0,0,0,0}, {0,0,0,0} }, -- S
    { 3, {1,1,0,0}, {0,1,1,0}, {0,0,0,0}, {0,0,0,0} }, -- Z
    { 2, {1,1,0,0}, {1,1,0,0}, {0,0,0,0}, {0,0,0,0} }, -- O
    { 4, {0,0,0,0}, {1,1,1,1}, {0,0,0,0}, {0,0,0,0} } -- I
}

function displayNext()
    if #nextBlock ~= 0 then -- clear
        for _, v in pairs(nextBlock) do
            scope:removeNote(v:getIndexInParent())
        end
        nextBlock = {}
    end
    local kind = blockKinds[nextKind] -- generate new
    for i = 2, 5 do -- row
        for j = 1, 4 do -- col
            if kind[i][j] == 1 then
                local px = SV:create("Note")
                px:setOnset(SV:quarter2Blick((25 + j - 1) * Unit))
                px:setPitch(Bottom + Height - i)
                px:setDuration(SV:quarter2Blick(Unit))

                local idx = scope:addNote(px)
                table.insert(nextBlock, scope:getNote(idx))
            end
        end
    end
end

function moveNoteTo(note, row, col)
    if col >= 0 then note:setOnset(SV:quarter2Blick((col + MapX) * Unit)) end
    if row >= 0 then note:setPitch(Bottom + row) end
    note:setDuration(SV:quarter2Blick(Unit))
end

function getRandomNote()
    if false then return 5
    else return math.random(6) end
end

function init()
    math.randomseed(os.time())

    local total = scope:getNumNotes()
    for i = 1, total do
        scope:removeNote(1)
    end

    map = {}  -- map contains rows and rows idx 1 is bottom line. cols are individual notes
    currentBlock = {} -- contains 1st element as [originRow,originCol,size] and other elements like [ row, col, note ]
    nextKind = getRandomNote()
    nextBlock = {}
    displayNext();

    -- bottom bar
    local bar = SV:create("Note")
    moveNoteTo(bar, 0, 1)
    bar:setDuration(SV:quarter2Blick(Width * Unit))
    local barIdx = scope:addNote(bar)
    barNote = scope:getNote(barIdx)

    local i
    for i = 1, 24 do
        map[i] = {}
    end

    lastTick = os.time()
end

function shiftDown()
    for i = 2, #currentBlock do
        local a = currentBlock[i]
        a[1] = a[1] - 1
        moveNoteTo(a[3], a[1], a[2])
    end

    currentBlock[1][1] = currentBlock[1][1] - 1
end

function tickShiftBlockDown()
    if downPressed == true then
        downPressed = false
        return
    end
    shiftDown()
end

function rotate()
    --prepare work buffer bitmap
    local buf = {}
    local buf2= {}
    local size = currentBlock[1][3]
    for i = 1, size do
        buf[i] = {}
        buf2[i]= {}
    end

    -- fill current block into buf
    local orgRow = currentBlock[1][1]
    local orgCol = currentBlock[1][2]
    for i = 2, #currentBlock do
        local a = currentBlock[i]
--         assert(a[2] >= orgCol)
--         assert(a[1] <= orgRow)
--         print("size:", size, "orgRow: ", orgRow, " orgCol:", orgCol, " a[1]:", a[1], " a[2]:", a[2])
        buf[orgRow - a[1] + 1][a[2] - orgCol + 1] = a[3]
    end

    --rotate
    local count = 2
    for i = 1, size do
        for j = 1, size do
            buf2[i][j] = buf[size - j + 1][i]
            if buf2[i][j] ~= nil then
                moveNoteTo(buf2[i][j], orgRow + 1 - i, orgCol + j - 1)
                --write back
                currentBlock[count] = {orgRow + 1 - i, orgCol + j - 1, buf2[i][j]}
                count = count + 1
            end
        end
    end
end

function left()
    for i = 2, #currentBlock do
        local a = currentBlock[i]
        if a[2] == 1 then return end
        if map[a[1]][a[2] - 1] ~= nil then return end
    end

    -- move left
    for i = 2, #currentBlock do
        local a = currentBlock[i]
        a[2] = a[2] - 1
        moveNoteTo(a[3], a[1], a[2])
    end
    currentBlock[1][2] = currentBlock[1][2] - 1 -- move reference origin
end

function right()
    for i = 2, #currentBlock do
        local a = currentBlock[i]
        if a[2] == Width then return end
        if map[a[1]][a[2] + 1] ~= nil then return end
    end

    -- move right
    for i = 2, #currentBlock do
        local a = currentBlock[i]
        a[2] = a[2] + 1
        moveNoteTo(a[3], a[1], a[2])
    end
    currentBlock[1][2] = currentBlock[1][2] + 1
end

function down()
    downPressed = true
    if doesSettle() then
        settle()
        newBlock()
    else
        shiftDown()
    end
end

function doesSettle()
    if #currentBlock == 0 then -- No current block, game has just started
        return true
    else
        -- bottom touching check
--         print("CHECK")
        for i = 2, #currentBlock do
            local a = currentBlock[i]
            print(a)
            if a[1] == Bottom + 1 then return true end
            if map[a[1] - 1] == nil then return true end -- safety measure lol
            if map[a[1] - 1][a[2]] ~= nil then return true end
        end
    end
    return false
end

function tickCheckControls()
    local n = getNote(controlNoteIdx)
    local s = n:getLyrics()
        if s == 'w' then rotate()
    elseif s == 'a' then left()
    elseif s == 's' then down()
    elseif s == 'd' then right()
    end
    n:setLyrics("")

end

function newBlock()
    -- get a new block
    local kind = blockKinds[nextKind]
    local size = kind[1]
    local begin = math.floor((Width - size) / 2)
    currentBlock[1] = { Height + size - 1 , begin, size }
    for i = 2, size + 1 do -- row
        for j = 1, size do -- col
            if kind[i][j] == 1 then
                local x = SV:create("Note")
                moveNoteTo(x, Height + size - i - 1, begin + j - 1)
                local xIdx = scope:addNote(x)
                x = scope:getNote(xIdx)
                table.insert(currentBlock, { Height + size - i, begin + j - 1, x })
            end
        end
    end

    -- generate next
    nextKind = getRandomNote()
    displayNext()
end

function settle()
    if #currentBlock == 0 then
        return
    else
        -- transfer currentBlock to map
        for i = 2, #currentBlock do
            local block = currentBlock[i]
            if map[block[1]][block[2]] ~= nil then
                SV:showMessageBox("Tetris", "Game Over!")
                SV:finish()
                return false
            end
            map[block[1]][block[2]] = block[3]
        end
        currentBlock = {}

        -- Try to clear lines
        for i = 1, Height do
            ::RedoLine::
            local hits = 0
            for _, b in pairs(map[i]) do
                if b ~= nil then hits = hits + 1 end
            end
            if hits >= 10 then
                -- clear this line
                for _, j in pairs(map[i]) do
                    scope:removeNote(j:getIndexInParent()) -- delete in view
                end
                for j = i, Height - 1 do
                    map[j] = map[j + 1] -- shift in data and delete in data
                    for _, k in pairs(map[j]) do
                        moveNoteTo(k, j, -1) -- shift in view
                    end
                end
                map[Height] = {} -- fill in the last row with empty line
                goto RedoLine -- redo the current line (because it's filled with the line above)
            end
        end
    end
    return true
end

function tick()
        if doesSettle() then
            settle()
            newBlock()
        else
            tickShiftBlockDown()
        end
    barNote:setLyrics("("..tostring(currentBlock[1][1])..","..tostring(currentBlock[1][2])..")")
end

function controlTick()
    tickCheckControls()

    barNote:setLyrics("("..tostring(currentBlock[1][1])..","..tostring(currentBlock[1][2])..")")
end

function FallTicker()
    tick()
    SV:setTimeout(500, FallTicker)
end

function ControlTicker()
    controlTick()
    SV:setTimeout(100, ControlTicker)
end

function main()
    scope = SV:getMainEditor():getCurrentGroup():getTarget()
    init()

    local communicateNote = SV:create("Note")
    communicateNote:setOnset(0)
    communicateNote:setDuration(SV:quarter2Blick(Unit))
    communicateNote:setPitch(Bottom)

    controlNoteIdx = scope:addNote(communicateNote)

    for i = 1, Height do
        local mark = SV:create("Note")
        mark:setDuration(SV:quarter2Blick(Unit))
        moveNoteTo(mark, i, 0)
        mark:setLyrics(tostring(i))
        scope:addNote(mark)
    end


    FallTicker()
    ControlTicker()
end
