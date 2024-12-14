local M = {
    Data = {},
}

local function init()
    M.Data = BJCDao.vehicles.findAll()
end

--VEHICLE SPAWNING
function _BJCOnVehicleSpawn(playerID, vehID, vehData)
    local s, e = vehData:find('%{')
    vehData = vehData:sub(s)
    vehData = JSON.parse(vehData)

    local player = BJCPlayers.Players[playerID]
    if not player then
        LogError(svar(BJCLang.getConsoleMessage("players.invalidPlayer"), { playerID = playerID }))
        return 1
    end

    local group = BJCGroups.Data[player.group]
    if not group then
        LogError(svar(BJCLang.getConsoleMessage("players.invalidGroup"), { group = player.group }))
        return 1
    end

    if not vehData then
        LogError(svar(BJCLang.getConsoleMessage("players.invalidVehicleData"), { playerID = playerID }))
        return 1
    end

    if vehData.jbm == "unicycle" then
        -- Special case for unicycle (walking)
        if group.vehicleCap == 0 then
            --BJCTx.player.toast(playerID, BJC_TOAST_TYPES.ERROR, "players.cannotSpawnVehicle")
           BJCChat.onServerChat(playerID, "players.cannotSpawnVehicle")
            return 1
        elseif not BJCConfig.Data.Freeroam.AllowUnicycle or not BJCScenario.canWalk(playerID) then
            --BJCTx.player.toast(playerID, BJC_TOAST_TYPES.ERROR, "players.walkNotAllowed")
           BJCChat.onServerChat(playerID, "players.walkNotAllowed")
            return 1
        end
    else
        -- General vehicle spawning
        if group.vehicleCap > -1 and group.vehicleCap <= tlength(player.vehicles) then
            --BJCTx.player.toast(playerID, BJC_TOAST_TYPES.ERROR, "players.cannotSpawnVehicle")
            BJCChat.onServerChat(playerID, "players.cannotSpawnVehicle")
            return 1
        end

        if tincludes(BJCVehicles.Data.ModelBlacklist, model, true) then
            if BJCPerm.isStaff(playerID) then
                --BJCTx.player.toast(playerID, BJC_TOAST_TYPES.WARNING, "players.blacklistedVehicle")
               BJCChat.onServerChat(playerID, "players.blacklistedVehicle")
            else
                --BJCTx.player.toast(playerID, BJC_TOAST_TYPES.ERROR, "players.blacklistedVehicle")
                BJCChat.onServerChat(playerID, "players.blacklistedVehicle")
                return 1
            end
        end

        -- Add the vehicle to the player's list of vehicles
        player.vehicles[vehID] = {
            vehicleID = vehID,
            vid = vehData.vid,
            pid = vehData.pid,
            name = model,
            freeze = false,
            engine = true,
        }
    end

    BJCTx.cache.invalidate(playerID, BJCCache.CACHES.USER)
    BJCTx.cache.invalidate(BJCTx.ALL_PLAYERS, BJCCache.CACHES.PLAYERS)
end

--VEHICLE RESET
function _BJCOnVehicleReset(playerID, vehID, posRot)
    --posRot = JSON.parse(posRot)

    local player = BJCPlayers.Players[playerID]
    local vehicle = player.vehicles[vehID]
    if not vehicle then return end
   
    local vehiclePrice = 10

    if player.reputation < vehiclePrice then
		--BJCTx.player.toast(playerID, BJC_TOAST_TYPES.ERROR, " Not enough reputation to reset the vehicle. You need ".. vehiclePrice .. " reputation points.")
		BJCChat.onServerChat(playerID, "❌ Not enough reputation to reset the vehicle. You need ".. vehiclePrice .. " reputation points. 🎭")
		MP.RemoveVehicle(playerID, vehID, vehData)
		_BJCOnVehicleDeleted(playerID, vehID)
        return 1		
    end

    player.reputation = player.reputation - vehiclePrice
	--BJCTx.player.toast(playerID, BJC_TOAST_TYPES.INFO, " Vehicle reset at the cost of " .. vehiclePrice .. " reputation points.")
	BJCChat.onServerChat(playerID, "🚗 Vehicle reset at the cost of " .. vehiclePrice .. " reputation points. 🎭")
    -- Save the updated player data
    BJCDao.players.save(player)
end

function _BJCOnVehicleDeleted(playerID, vehID)
    local player = BJCPlayers.Players[playerID]
    if not player then
        LogError(svar(BJCLang.getConsoleMessage("players.invalidPlayer"), { playerID = playerID }))
        return
    end

    local isCurrent = player.vehicles[vehID] and player.vehicles[vehID].vid == player.currentVehicle
    player.vehicles[vehID] = nil
    if isCurrent then
        player.currentVehicle = nil
    end
    BJCTx.cache.invalidate(playerID, BJCCache.CACHES.USER)
    BJCTx.cache.invalidate(BJCTx.ALL_PLAYERS, BJCCache.CACHES.PLAYERS)

    BJCScenario.onVehicleDeleted(playerID, vehID)
end

local function initHooks()
    MP.RegisterEvent("onPlayerJoin", "onPlayerJoin")
    MP.RegisterEvent("onVehicleSpawn", "_BJCOnVehicleSpawn")
    MP.RegisterEvent("onVehicleEdited", "_BJCOnVehicleEdited")
    MP.RegisterEvent("onVehicleDeleted", "_BJCOnVehicleDeleted")
    MP.RegisterEvent("onVehicleReset", "_BJCOnVehicleReset")
end

local function setModelBlacklist(model, state)
    if state and not tincludes(M.Data.ModelBlacklist, model, true) then
        table.insert(M.Data.ModelBlacklist, model)
    elseif not state then
        local pos = tpos(M.Data.ModelBlacklist, model)
        if pos then
            table.remove(M.Data.ModelBlacklist, pos)
        end
    end
    BJCDao.vehicles.save(M.Data)
end

local function getCache()
    return tdeepcopy(M.Data), M.getCacheHash()
end

local function getCacheHash()
    return Hash(M.Data)
end

local function onDriftEnded(playerID, driftScore)
    if driftScore >= BJCConfig.Data.Freeroam.DriftGood then
        local isBig = driftScore >= BJCConfig.Data.Freeroam.DriftBig
        BJCPlayers.reward(playerID, isBig and
            BJCConfig.Data.Reputation.DriftBigReward or
            BJCConfig.Data.Reputation.DriftGoodReward)

        if BJCConfig.Data.Server.DriftBigBroadcast and isBig then
            local player = BJCPlayers.Players[playerID]
            for targetID, target in pairs(BJCPlayers.Players) do
                BJCChat.onServerChat(targetID, svar(BJCLang.getServerMessage(target.lang, "broadcast.bigDrift"),
                    { playerName = player.playerName, score = driftScore }))
            end
        end
    end
end

M.setModelBlacklist = setModelBlacklist

M.getCache = getCache
M.getCacheHash = getCacheHash
M.onDriftEnded = onDriftEnded
M.onServerChat = onServerChat
M.deleteVehicle = deleteVehicle

init()
initHooks()

return M
