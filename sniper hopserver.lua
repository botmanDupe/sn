repeat wait() until game:IsLoaded()

local function jumpToServer()
    local sfUrl = "https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=%s&limit=%s&excludeFullGames=true"
    local req = request({ Url = string.format(sfUrl, 15502339080, "Desc", 100) })
    local body = game:GetService("HttpService"):JSONDecode(req.Body)
    local deep = math.random(1, 3)
    if deep > 1 then
        for i = 1, deep, 1 do
            req = request({ Url = string.format(sfUrl .. "&cursor=" .. body.nextPageCursor, 15502339080, "Desc", 100) })
            body = game:GetService("HttpService"):JSONDecode(req.Body)
            task.wait(0.1)
        end
    end
    local servers = {}
    if body and body.data then
        for i, v in next, body.data do
            if type(v) == "table" and tonumber(v.playing) and tonumber(v.maxPlayers) and v.playing < v.maxPlayers and v.id ~= game.JobId then
                -- Prioritize servers with 28 to 38 players
                local priority = (v.playing / v.maxPlayers) * 100
                if priority >= 70 and priority <= 80 then
                    table.insert(servers, priority, v.id)
                end
            end
        end
    end

    local chosenServer = nil
    for i, serverId in ipairs(servers) do
        local success, errorMessage = pcall(function()
            game:GetService("TeleportService"):TeleportToPlaceInstance(15502339080, serverId, game:GetService("Players").LocalPlayer)
        end)
        if success then
            chosenServer = serverId
            break
        else
            print("Failed to join server " .. serverId .. ": " .. errorMessage)
        end
    end

    if not chosenServer then
        print("No suitable servers found.")
    else
        -- Check for snipers in the chosen server
        local hasSniper = false
        local players = game:GetService("Players"):GetPlayers()
        for _, player in ipairs(players) do
            if detectSniper(player) then
                hasSniper = true
                break
            end
        end

        if hasSniper then
            print("Sniper detected in server. Joining a different one.")
            jumpToServer()
        end

        -- Check if the server is still full
        local playersInServer = game:GetService("Players"):GetPlayersInServer(chosenServer)
        if playersInServer.Count < 17 then
            print("Server is below 17 players. Joining a different one.")
            jumpToServer()
        end

        -- Check if the current game is not 15502339080
        if game.PlaceId ~= 15502339080 then
            print("Changing to game 15502339080")
            game:GetService("TeleportService"):TeleportToPlaceInstance(15502339080)
        end
    end
end

while wait(1) do
    jumpToServer()
end
