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

function Jump(serverType)
    serverType = serverType or "Normal" -- Default parameter
    if not ServerTypes[serverType] then serverType = "Normal" end

    local function GetServerList(cursor)
        cursor = cursor and "&cursor=" .. cursor or ""
        local API_URL = string.format('https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=%s&limit=100', tostring(PlaceId), ServerTypes[serverType])
        return HttpService:JSONDecode(game:HttpGet(APIURL .. cursor))
    end

    local currentPageCursor = nil
    while true do 
        local serverList = GetServerList(currentPageCursor)
        currentPageCursor = serverList.nextPageCursor

        for , server in ipairs(serverList.data) do
            if server.playing and tonumber(server.playing) >= MINIMUM_PLAYERS and tonumber(server.playing) < Players.MaxPlayers and not table.find(ServerHopData.CheckedServers, tostring(server.id)) then
                -- Save current data to disk/workspace
                ServerHopData.LastTimeHop = os.time() -- Last time that tried to hop
                table.insert(ServerHopData.CheckedServers, server.id) -- Insert on our list
                writefile(fileName, HttpService:JSONEncode(ServerHopData)) -- Save our data
                TeleportService:TeleportToPlaceInstance(PlaceId, server.id, LocalPlayer) -- Actually teleport the player
                -- Change the wait time if you take long times to hop (or it will add more than 1 server in the file)
                wait(0.5)
            end
        end

        if not currentPageCursor then break else wait(0.25) end
    end
end

-- check current server ping
function CheckPingStat()
    if pingValue >= pingThreshold then
        print("Ping Is Higher Than 310, Sevrer Hopping...")
        Jump("Normal")
    else
        print("Ping is sufficent. No Server Hop Needed")
    end
end

while task.wait(60) do
    CheckPingStat()
end
