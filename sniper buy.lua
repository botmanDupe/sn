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
local playerID, snipeNormal

if not snipeNormalPets then
    snipeNormalPets = false
end

local vu = game:GetService("VirtualUser")
Players.LocalPlayer.Idled:connect(function()
   vu:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
   task.wait(1)
   vu:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
end)

for i = 1, PlayerInServer do
   for ii = 1,#alts do
        if getPlayers[i].Name == alts[ii] and alts[ii] ~= Players.LocalPlayer.Name then
            jumpToServer()
        end
    end
end

local function processListingInfo(uid, gems, item, version, shiny, amount, boughtFrom, boughtStatus, mention)
    local gemamount = Players.LocalPlayer.leaderstats["💎 Diamonds"].Value
    local snipeMessage ="||".. Players.LocalPlayer.Name .. "||"
    local weburl, webContent, webcolor
    if version then
        if version == 2 then
            version = "Rainbow "
        elseif version == 1 then
            version = "Golden "
        end
    else
       version = ""
    end

    if boughtStatus then
	webcolor = tonumber(0x00ff00)
	weburl = webhook
        snipeMessage = snipeMessage .. " Snipeastes un "
	if mention then 
            webContent = "<@".. userid ..">"
        else
	    webContent = ""
	end
	if snipeNormal == true then
	    weburl = normalwebhook
	    snipeNormal = false
	end
    else
	webcolor = tonumber(0xff0000)
	weburl = webhookFail
	snipeMessage = snipeMessage .. " No logró Snipear un "
	if snipeNormal == true then
	    weburl = normalwebhook
	    snipeNormal = false
	end
    end
    
    snipeMessage = snipeMessage .. "**" .. version
    
    if shiny then
        snipeMessage = snipeMessage .. " Shiny "
    end
    
    snipeMessage = snipeMessage .. item .. "**"
    
    local message1 = {
        ['content'] = webContent,
        ['embeds'] = {
            {
		["author"] = {
			["name"] = "Sniper 🌚",
			["icon_url"] = "https://cdn.discordapp.com/attachments/1190066556122701885/1190851706045616218/tanjiro.png?ex=65a34e13&is=6590d913&hm=8fc73b79b25ec5bb70c0800b54b8cc1d73dfc2d9f8aa116004f852ea8f27831c&",
		},
                ['title'] = snipeMessage,
                ["color"] = webcolor,
                ["timestamp"] = DateTime.now():ToIsoDate(),
                ['fields'] = {
                    {
                        name = "INFO DE COMPRA:",
                        value = "\n\n",
                    },
                    {
                        name = "Precio:",
                        value = tostring(gems) .. " Gema´s💎",
                    },
                    {
                        name = "Cantidad Comprados:",
                        value = tostring(amount),
                    },
                    {
                        name = "Vendido Por:",
                        value = "🤡 ||" .. tostring(boughtFrom) .. "|| 🤡",
                    },
                    {
                        name = "PetID:",
                        value = "||" .. tostring(uid) .. "|| \n\n", 
                    },
                    {
                        name = "Gemas Restantes💎:",
                        value = tostring(gemamount),
                    },
                },
		["footer"] = {
                        ["icon_url"] = "https://media.discordapp.net/attachments/886649528244129792/1189625887163953213/Screenshot_20231202_152047_Instagram.jpg?ex=659ed871&is=658c6371&hm=32004e71a6f154d31ca0e100a5a83d4577339548e7716b577de9ff95d8d19806&", -- optional
                        ["text"] = "Base Hecha por Root y modificado por Craz"
		}
            },
        }
    }
	
    local jsonMessage = http:JSONEncode(message1)
    local success, webMessage = pcall(function()
	http:PostAsync(weburl, jsonMessage)
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

Booths_Broadcast.OnClientEvent:Connect(function(username, message)
        if type(message) == "table" then
            local highestTimestamp = -math.huge -- Initialize with the smallest possible number
            local key = nil
            local listing = nil
            for v, value in pairs(message["Listings"] or {}) do
                if type(value) == "table" and value["ItemData"] and value["ItemData"]["data"] then
                    local timestamp = value["Timestamp"]
                    if timestamp > highestTimestamp then
                        highestTimestamp = timestamp
                        key = v
                        listing = value
                    end
                end
            end
            if listing then
                local buytimestamp = listing["ReadyTimestamp"]
                local listTimestamp = listing["Timestamp"]
                local data = listing["ItemData"]["data"]
                local gems = tonumber(listing["DiamondCost"])
                local uid = key
                local item = data["id"]
                local version = data["pt"]
                local shiny = data["sh"]
                local amount = tonumber(data["_am"]) or 1
                local playerid = message['PlayerID']
                local class = tostring(listing["ItemData"]["class"])
                local unitGems = gems/amount
		local ping = false
                    
                print(string.format("%s listed %s %s - %s gems, %s gems/unit", tostring(username), tostring(amount), tostring(item), tostring(gems), tostring(unitGems)))
                if string.find(item, "Huge") and unitGems <= 100000 then
                    coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp, ping)
                    return
                elseif class == "Pet" then
                    local type = Library.Directory.Pets[item]
                    if type.exclusiveLevel and unitGems <= 15000 and item ~= "Banana" and item ~= "Coin" then
                        coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp, ping)
                        return
                    elseif type.titanic and unitGems <= 10000000 then
                        ping = true
			coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp, ping)
                        return
                    elseif type.huge and unitGems <= 1000000 then
                        ping = true
			coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp, ping)
                        return
                    end
                elseif (item == "Titanic Christmas Present" or string.find(item, "2024 New Year")) and unitGems <= 30000 then
                    coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp, ping)
                    return
                elseif class == "Egg" and unitGems <= 30000 then
                    coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp, ping)
                    return
                elseif ((string.find(item, "Key") and not string.find(item, "Lower")) or string.find(item, "Ticket") or string.find(item, "Charm") or class == "Charm") and unitGems <= 2500 then 
                    coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp, ping)
                    return
                elseif class == "Enchant" and unitGems <= 30000 then
                    if item == "Fortune" then 
                        coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp, ping)
                        return
                    elseif string.find(item, "Chest Mimic") then
                        coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp, ping)
                        return
                    elseif item == "Lucky Block" then
                        coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp, ping)
                        return
                    elseif item == "Massive Comet" then
                        coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp, ping)
                        return
                    end
                end
            end
        end
    end)

  local function tryPurchase(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp, ping)
    print("PURCHASING ATTEMPT START") --for testings
    --while (buytimestamp - os.time()) > 1 then
    if buytimestamp > listTimestamp then
      task.wait(3.05) --could try deductiong the ping ? : game.Players.LocalPlayer:GetNetworkPing()
    end
    print("PURCHASING ATTEMPT END - os " .. os.time() .. " - buy " .. buytimestamp .. " - offset " .. listTimestamp) --for testings
    local boughtPet, boughtMessage = game:GetService("ReplicatedStorage").Network.Booths_RequestPurchase:InvokeServer(playerid, uid)
    processListingInfo(uid, gems, item, version, shiny, amount, username, boughtPet, class, ping, boughtMessage)
  end

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

Players.PlayerRemoving:Connect(function(player)
    PlayerInServer = #getPlayers
    if PlayerInServer < 25 then
        while task.wait(1) do
	    jumpToServer()
	end
    end
end) 

Players.PlayerAdded:Connect(function(player)
    for i = 1,#alts do
        if player.Name == alts[i] and alts[i] ~= Players.LocalPlayer.Name then
            while task.wait(1) do
	        jumpToServer()
	    end
        end
    end
end) 

while task.wait(1) do
    if math.floor(os.clock() - osclock) >= math.random(900, 1200) then
        while task.wait(1) do
	    jumpToServer()		
	end	
    end
end
