local osclock = os.clock()
repeat task.wait() until game:IsLoaded()

setfpscap(10)
game:GetService("RunService"):Set3dRenderingEnabled(false)
local Booths_Broadcast = game:GetService("ReplicatedStorage").Network:WaitForChild("Booths_Broadcast")
local Players = game:GetService('Players')
local getPlayers = Players:GetPlayers()
local PlayerInServer = #getPlayers
local http = game:GetService("HttpService")
local ts = game:GetService("TeleportService")
local rs = game:GetService("ReplicatedStorage")

local vu = game:GetService("VirtualUser")
Players.LocalPlayer.Idled:connect(function()
   vu:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
   task.wait(1)
   vu:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
end)

for i = 1, PlayerInServer do
   if getPlayers[i] ~= Players.LocalPlayer and getPlayers[i].Character then
      getPlayers[i].Character:ClearAllChildren()
   end
   for ii = 1,#alts do
        if getPlayers[i].Name == alts[ii] and alts[ii] ~= Players.LocalPlayer.Name then
            jumpToServer()
        end
    end
end

local function processListingInfo(uid, gems, item, version, shiny, amount, boughtFrom, boughtStatus)
    local gemamount = Players.LocalPlayer.leaderstats["💎 Diamonds"].Value
    local snipeMessage = Players.LocalPlayer.Name .. " just sniped a "
    if version then
        if version == 2 then
            version = "Rainbow"
        elseif version == 1 then
            version = "Golden"
        end
    else
       version = "Normal"
    end
    
    snipeMessage = snipeMessage .. version
    
    if shiny then
        snipeMessage = snipeMessage .. " Shiny"
    end
    
    snipeMessage = snipeMessage .. " " .. (item)
    
    if amount == nil then
        amount = 1
    end

    if petimg then
        Image = string.split(petimg, "rbxassetid://")[2]
        Image = game:HttpGet("https://thumbnails.roblox.com/v1/assets?assetIds=" ..
        Image ..
        "&returnPolicy=PlaceHolder&size=420x420&format=Png&isCircular=false")
        Image = game:GetService("HttpService"):JSONDecode(Image).data[1].imageUrl
    end

    if boughtPet == true then
	local color = tonumber(0x33dd99)
	local weburl = webhook
    else
	local color = tonumber(0xff00000)
	local weburl = webhookFail
    end
    
    local message1 = {
        ['content'] = "Goofyahh Sniper",
        ['embeds'] = {
            {
                ['title'] = snipeMessage,
                ["color"] = color,
                ["timestamp"] = DateTime.now():ToIsoDate(),
                ['fields'] = {
                    {
                        name = "PURCHASE INFO:",
                        value = "\n\n",
                    },
                    {
                        name = "PRICE:",
                        value = tostring(gems) .. " GEMS",
                    },
                    {
                        name = "AMOUNT:",
                        value = tostring(amount),
                    },
                    {
                        name = "BOUGHT FROM:",
                        value = "||" .. tostring(boughtFrom) .. "||",
                    },
                    {
                        name = "PETID:",
                        value = "||" .. tostring(uid) .. "|| \n\n", 
                    },
                    {
                        name = "USER INFO:",
                        value = "||\n\n||", 
                    },
                    {
                        name = "USER:",
                        value = "||" .. game.Players.LocalPlayer.Name .. "||",
                    },
                    {
                        name = "GEMS:",
                        value = tostring(gemamount),
                    },
                    {
                        name = "IMAGE URL:",
                        value = Image,
                    },
                },
            },
        }
    }

    local jsonMessage = http:JSONEncode(message1)
    local success, response = pcall(function()
            http:PostAsync(getgenv().webhook, jsonMessage)
    end)
    if success == false then
            local response = request({
            Url = weburl,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = jsonMessage
        })
    end
end

local function checklisting(uid, gems, item, version, shiny, amount, username, playerid)
    local Library = require(rs:WaitForChild('Library'))
    local purchase = rs.Network.Booths_RequestPurchase
    gems = tonumber(gems)
    local type = {}
    pcall(function()
        type = Library.Directory.Pets[item]
    end)

    if type.exclusiveLevel and gems <= 10000 and item ~= "Banana" and item ~= "Coin" then
        local boughtPet, boughtMessage = purchase:InvokeServer(playerid, uid)
        if boughtPet == true then
            processListingInfo(uid, gems, item, version, shiny, amount, username, boughtPet)
        end
    elseif item == "Titanic Christmas Present" and gems <= 25000 then
        local boughtPet, boughtMessage = purchase:InvokeServer(playerid, uid)
        if boughtPet == true then
            processListingInfo(uid, gems, item, version, shiny, amount, username, boughtPet)
        end
    elseif string.find(item, "Exclusive") and gems <= 25000 then
        local boughtPet, boughtMessage = purchase:InvokeServer(playerid, uid)
        if boughtPet == true then
            processListingInfo(uid, gems, item, version, shiny, amount, username, boughtPet)
        end
    elseif type.huge and gems <= 1000000 then
        local boughtPet, boughtMessage = purchase:InvokeServer(playerid, uid)
        if boughtPet == true then
            processListingInfo(uid, gems, item, version, shiny, amount, username, boughtPet)
        end     
    elseif type.titanic and gems <= 10000000 then
        local boughtPet, boughtMessage = purchase:InvokeServer(playerid, uid)
        if boughtPet == true then
            processListingInfo(uid, gems, item, version, shiny, amount, username, boughtPet)
        end
    end
end

Booths_Broadcast.OnClientEvent:Connect(function(username, message)
    local playerID = message['PlayerID']
    if type(message) == "table" then
        local listing = message["Listings"]
        for key, value in pairs(listing) do
            if type(value) == "table" then
                local uid = key
                local gems = value["DiamondCost"]
                local itemdata = value["ItemData"]

                if itemdata then
                    local data = itemdata["data"]

                    if data then
                        local item = data["id"]
                        local version = data["pt"]
                        local shiny = data["sh"]
                        local amount = data["_am"]
                        checklisting(uid, gems, item, version, shiny, amount, username , playerID)
                    end
                end
            end
        end
    end
end)

local function jumpToServer() 
    local sfUrl = "https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=%s&limit=%s&excludeFullGames=true" 
    local req = request({ Url = string.format(sfUrl, 15502339080, "Desc", 100) }) 
    local body = http:JSONDecode(req.Body) 
    local deep = math.random(1, 3)
    if deep > 1 then 
        for i = 1, deep, 1 do 
             req = request({ Url = string.format(sfUrl .. "&cursor=" .. body.nextPageCursor, 15502339080, "Desc", 100) }) 
             body = http:JSONDecode(req.Body) 
             task.wait(0.1)
        end 
    end 
    local servers = {} 
    if body and body.data then 
        for i, v in next, body.data do 
            if type(v) == "table" and tonumber(v.playing) and tonumber(v.maxPlayers) and v.playing < v.maxPlayers and v.id ~= game.JobId then
                table.insert(servers, v.id)
            end
        end
    end
    local randomCount = #servers
    if not randomCount then
       randomCount = 2
    end
    ts:TeleportToPlaceInstance(15502339080, servers[math.random(1, randomCount)], game:GetService("Players").LocalPlayer) 
end

Players.PlayerAdded:Connect(function(player)
    for i = 1,#alts do
        if  player.Name == alts[i] and alts[i] ~= Players.LocalPlayer.Name then
            jumpToServer()
        end
    end
end) 

game:GetService("RunService").Stepped:Connect(function()
    PlayerInServer = #getPlayers
    if PlayerInServer < 25 or math.floor(os.clock() - osclock) >= math.random(900, 1200) then
        jumpToServer()
    end
end)
