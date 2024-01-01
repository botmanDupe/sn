repeat wait() until game:IsLoaded()

-- SETTINGS (adjust as needed)
local MINIMUM_PLAYERS = 10
local pingThreshold = 310
local gameId = 15502339080  -- Replace with the desired game ID

-- Services
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local StatsService = game:GetService("Stats")

-- Variables
local serverStats = StatsService.Network.ServerStatsItem
local dataPing = serverStats["Data Ping"]:GetValueString()
local pingValue = tonumber(dataPing:match("(%d+)"))
local PlaceId = game.PlaceId
local fileName = string.format("%s_servers.json", tostring(PlaceId))
local ServerHopData = {
    CheckedServers = {},
    LastTimeHop = nil,
    CreatedAt = os.time()
}

-- Load previous server data
if isfile(fileName) then
    local fileContent = readfile(fileName)
    ServerHopData = HttpService:JSONDecode(fileContent)
end

-- Function to find and join a suitable server
local function jumpToServer()
    local function GetServerList(cursor)
        cursor = cursor and "&cursor=" .. cursor or ""
        local API_URL = string.format('https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Desc&limit=100', tostring(PlaceId))
        return HttpService:JSONDecode(game:HttpGet(API_URL .. cursor))
    end

    local currentPageCursor = nil
    while true do
        local serverList = GetServerList(currentPageCursor)
        currentPageCursor = serverList.nextPageCursor

        for _, server in ipairs(serverList.data) do
            if server.playing and tonumber(server.playing) >= MINIMUM_PLAYERS and tonumber(server.playing) < Players.MaxPlayers and not table.find(ServerHopData.CheckedServers, tostring(server.id)) and server.id ~= game.JobId then
                -- Update server hop data
                ServerHopData.LastTimeHop = os.time()
                table.insert(ServerHopData.CheckedServers, server.id)
                writefile(fileName, HttpService:JSONEncode(ServerHopData))

                -- Teleport to the server
                TeleportService:TeleportToPlaceInstance(PlaceId, server.id, game.Players.LocalPlayer)
                wait(0.5)
                return  -- Exit the loop after successful hop
            end
        end

        if not currentPageCursor then break else wait(0.25) end
    end
end

-- Function to check ping and trigger server hopping if necessary
local function CheckPingAndHop()
    if pingValue >= pingThreshold then
        print("Ping Is Higher Than 310, Server Hopping...")
        jumpToServer()
    else
        print("Ping is sufficient. No Server Hop Needed")
    end
end

-- Main loop
while wait(1) do
    CheckPingAndHop()  -- Check ping frequently
end
