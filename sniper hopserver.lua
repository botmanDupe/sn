repeat task.wait() until game:IsLoaded()
if not game:IsLoaded() then game:IsLoaded():Wait(5) end

--// SETTINGS!!

local MINIMUM_PLAYERS = 15
local pingThreshold = 310

--// Services

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer
local StatsService = game:GetService("Stats")

--// Variables

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local serverStats = StatsService.Network.ServerStatsItem
local dataPing = serverStats["Data Ping"]:GetValueString()
local pingValue = tonumber(dataPing:match("(%d+)"))
local PlaceId = game.PlaceId
local fileName = string.format("%s_servers.json", tostring(PlaceId))
local ServerHopData = { 
    CheckedServers = {},
    LastTimeHop = nil,
    CreatedAt = os.time() -- We can use it later to clear the checked servers
    -- TODO: Save the cursor? Prob this can help on fast-hops
}

-- Load data from disk/workspace
if isfile(fileName) then
    local fileContent = readfile(fileName)
    ServerHopData = HttpService:JSONDecode(fileContent)
end

-- Optional log feature
if ServerHopData.LastTimeHop then
    print("Took", os.time() - ServerHopData.LastTimeHop, "Seconds To Server Hop")
end

local ServerTypes = { ["Normal"] = "desc", ["Low"] = "asc" }

-- Functions

local function checkAlts()
    local alts = getgenv().alts
    local players = game:GetService("Players"):GetPlayers()
    local altCount = 0
    for _, player in ipairs(players) do
        for _, altName in ipairs(alts) do
            if player.Name == altName then
                altCount = altCount + 1
                break
            end
        end
    end
    if altCount >= 2 then
        return true  -- Saltar de servidor
    else
        return false  -- No saltar
    end
end

local function Jump(serverType)
    serverType = serverType or "Normal" -- Default parameter
    if not ServerTypes[serverType] then serverType = "Normal" end

    local function GetServerList(cursor)
        cursor = cursor and "&cursor=" .. cursor or ""
        local API_URL = string.format('https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=%s&limit=100', tostring(PlaceId), ServerTypes[serverType])
        return HttpService:JSONDecode(game:HttpGet(API_URL .. cursor))
    end

    local currentPageCursor = nil
    while true do 
        local serverList = GetServerList(currentPageCursor)
        currentPageCursor = serverList.nextPageCursor

        for , server in ipairs(serverList.data) do
            if server.playing and tonumber(server.playing) >= MINIMUM_PLAYERS and tonumber(server.playing) < Players.MaxPlayers and not table.find(ServerHopData.CheckedServers, tostring(server.id)) then
                -- Save current data to disk/workspace
                if (pingValue < server.ping or game.PlaceId ~= 15502339080) then
                    ServerHopData.LastTimeHop = os.time() -- Last time that tried to hop
                    table.insert(ServerHopData.CheckedServers, server.id) -- Insert on our list
                    writefile(fileName, HttpService:JSONEncode(ServerHopData)) -- Save our data
                    TeleportService:TeleportToPlaceInstance(PlaceId, server.id, LocalPlayer) -- Actually teleport the player
                    -- Change the wait time if you take long times to hop (or it will add more than 1 server in the file)
                    wait(0.5)
                    break
                end
            end
        end

        if not currentPageCursor then break else wait(0.25) end
    end
end

-- Main loop

while wait(1) do
    if checkAlts() then
        Jump("Normal")
    end
end
