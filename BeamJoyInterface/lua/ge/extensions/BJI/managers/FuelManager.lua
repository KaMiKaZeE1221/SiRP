local M = {}

local function checkAndRefillFuel(ctxt)
    local player = ctxt.vehData and BJCPlayers.Players[ctxt.vehData.ownerID]
    if not player then
        LogError(svar(BJCLang.getConsoleMessage("players.invalidPlayer"), { playerID = ctxt.vehData.ownerID }))
        return
    end

    local vehData = ctxt.vehData
    if not vehData or not vehData.tanks then
        LogError(svar(BJCLang.getConsoleMessage("vehicles.noTanks"), { vehID = vehData.vehID }))
        return
    end

    for tankName, tank in pairs(vehData.tanks) do
        local minFuelThreshold = tank.maxEnergy * 0.0001 -- 0.01% of max energy
        if tank.currentEnergy < minFuelThreshold then
            -- Set the fuel level to a small amount to avoid running out
            local newFuelLevel = minFuelThreshold * 2 -- or any other small amount above threshold
            core_vehicleBridge.executeAction(ctxt.veh, 'setEnergyStorageEnergy', tankName, newFuelLevel)
            
            -- Send a toast message to the player
            BJCTx.player.toast(ctxt.vehData.ownerID, BJC_TOAST_TYPES.INFO, "Your fuel was running low. We have refilled it to keep you going!")
        end
    end
end

local function slowTick(ctxt)
    if not ctxt.vehData then
        return
    end

    local vehID = ctxt.vehData and ctxt.vehData.vehID or nil

    -- get current fuel
    if core_vehicleBridge then
        -- update fuel
        core_vehicleBridge.requestValue(ctxt.veh, function(data)
            updateVehFuelState(ctxt, data)
        end, 'energyStorage')
    end

    -- get current damages
    if ctxt.veh then
        ctxt.veh:queueLuaCommand(svar([[
                obj:queueGameEngineLua(
                    "BJIVeh.updateVehDamages({1}, " ..
                        serialize(beamstate.damage) ..
                    ")"
                )
        ]], { vehID }))
    end

    -- check and refill fuel
    checkAndRefillFuel(ctxt)

    -- delete corrupted vehs
    for _, vehData in pairs(BJIContext.User.vehicles) do
        local v = M.getVehicleObject(vehData.gameVehID)
        if not v then
            BJITx.moderation.deleteVehicle(BJIContext.User.playerID, vehData.gameVehID)
        end
    end
end

M.onInit = onInit
M.onShutdown = onShutdown

RegisterBJIManager(M)
return M
