local M = {}

-- Function to check and refill fuel tanks
local function checkAndRefillFuel(ctxt)
    local player = ctxt.vehData and BJCPlayers.Players[ctxt.vehData.ownerID]
    if not player then
        print("Error: Invalid player ID - " .. tostring(ctxt.vehData.ownerID))
        LogError(svar(BJCLang.getConsoleMessage("players.invalidPlayer"), { playerID = ctxt.vehData.ownerID }))
        return
    end

    local vehData = ctxt.vehData
    if not vehData or not vehData.tanks then
        print("Error: Vehicle has no tanks - " .. tostring(vehData.vehID))
        LogError(svar(BJCLang.getConsoleMessage("vehicles.noTanks"), { vehID = vehData.vehID }))
        return
    end

    for tankName, tank in pairs(vehData.tanks) do
        local minFuelThreshold = tank.maxEnergy * 10.0 -- 0.01% of max energy
        if tank.currentEnergy < minFuelThreshold then
            local newFuelLevel = minFuelThreshold * 50.0 -- Ensure a small amount above the threshold
            print("Refilling fuel for tank: " .. tankName .. ", new fuel level: " .. newFuelLevel)
            core_vehicleBridge.executeAction(ctxt.veh, 'setEnergyStorageEnergy', tankName, newFuelLevel)
            
            -- Notify player of the fuel refill
            BJCTx.player.toast(ctxt.vehData.ownerID, BJC_TOAST_TYPES.INFO, "Your fuel was running low. We have refilled it to keep you going!")
        end
    end
end

-- Function to process periodic updates
local function slowTick(ctxt)
    if not ctxt.vehData then
        print("Error: Vehicle data is nil")
        return
    end

    local vehID = ctxt.vehData and ctxt.vehData.vehID or nil
    print("Processing slow tick for vehicle ID: " .. tostring(vehID))

    -- Update fuel information
    if core_vehicleBridge then
        print("Requesting fuel information update")
        core_vehicleBridge.requestValue(ctxt.veh, function(data)
            print("Fuel data received")
            updateVehFuelState(ctxt, data)
        end, 'energyStorage')
    end

    -- Check and refill fuel
    checkAndRefillFuel(ctxt)

    -- Remove corrupted vehicles
    for _, vehData in pairs(BJIContext.User.vehicles) do
        local v = M.getVehicleObject(vehData.gameVehID)
        if not v then
            print("Deleting corrupted vehicle ID: " .. tostring(vehData.gameVehID))
            BJITx.moderation.deleteVehicle(BJIContext.User.playerID, vehData.gameVehID)
        end
    end
end

-- Register initialization and shutdown handlers
M.onInit = onInit
M.onShutdown = onShutdown

-- Register initialization and shutdown handlers
M.onInit = function()
    print("Initialization started")
    onInit()
    print("Initialization completed")
end

return M
