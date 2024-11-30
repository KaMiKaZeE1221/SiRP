local function drawIndicator(ctxt)
    if not ctxt.vehData or not ctxt.vehData.tanks or
        not BJIContext.Scenario.Data.EnergyStations then
        return
    end

    local energyStationCounts = {}
    for _, station in ipairs(BJIContext.Scenario.Data.EnergyStations) do
        for _, energyType in ipairs(station.types) do
            if not energyStationCounts[energyType] then
                energyStationCounts[energyType] = 0
            end
            energyStationCounts[energyType] = energyStationCounts[energyType] + 1
        end
    end
    local garageCount = #BJIContext.Scenario.Data.Garages

    -- group energy types
    local tanks = {}
    for _, tank in pairs(ctxt.vehData.tanks) do
        local t = tanks[tank.energyType]
        if not t then
            tanks[tank.energyType] = {
                current = 0,
                max = 0,
            }
            t = tanks[tank.energyType]
        end
        t.current = t.current + tank.currentEnergy
        t.max = t.max + tank.maxEnergy
    end

    local i = 1
    for energyType, tank in pairs(tanks) do
        local indicatorColor = TEXT_COLORS.DEFAULT
        if tank.current / tank.max <= .05 then
            indicatorColor = TEXT_COLORS.ERROR
        elseif tank.current / tank.max <= .15 then
            indicatorColor = TEXT_COLORS.HIGHLIGHT
        end
        local line = LineBuilder()
            :text(svar("{1}:", { BJILang.get(svar("energy.tankNames.{1}", { energyType })) }))
            :text(svar("{1}{2}", {
                Round(BJIVeh.jouleToReadableUnit(tank.current, energyType), 1),
                BJILang.get(svar("energy.energyUnits.{1}", { energyType }))
            }), indicatorColor)
        if BJIScenario.canRefuelAtStation() then
            local isEnergyStation = tincludes(BJI_ENERGY_STATION_TYPES, energyType, true)
            local stationCount = isEnergyStation and
                (energyStationCounts[energyType] and energyStationCounts[energyType]) or
                garageCount
            if stationCount > 0 then
                line:btnIcon({
                    id = svar("setRouteStation{1}", { i }),
                    icon = ICONS.add_location,
                    background = BTN_PRESETS.SUCCESS,
                    disabled = BJIGPS.getByKey("BJIEnergyStation"),
                    onClick = function()
                        if isEnergyStation then
                            -- Gas station energy types
                            local stations = {}
                            for _, station in ipairs(BJIContext.Scenario.Data.EnergyStations) do
                                if tincludes(station.types, energyType, true) then
                                    local distance = BJIGPS.getRouteLength({ ctxt.vehPosRot.pos, station
                                        .pos })
                                    table.insert(stations, { station = station, distance = distance })
                                end
                            end
                            table.sort(stations, function(a, b)
                                return a.distance < b.distance
                            end)
                            BJIGPS.prependWaypoint(BJIGPS.KEYS.STATION, stations[1].station.pos,
                                stations[1].station.radius)
                        else
                            -- Garage energy types
                            local garages = {}
                            for _, garage in ipairs(BJIContext.Scenario.Data.Garages) do
                                local distance = BJIGPS.getRouteLength({ ctxt.vehPosRot.pos, garage.pos })
                                table.insert(garages, { garage = garage, distance = distance })
                            end
                            table.sort(garages, function(a, b)
                                return a.distance < b.distance
                            end)
                            BJIGPS.prependWaypoint(BJIGPS.KEYS.STATION, garages[1].garage.pos,
                                garages[1].garage.radius)
                        end
                    end
                })
            else
                local stationName = BJILang.get(svar("energy.stationNames.{1}", { energyType }))
                Line = line:text(svar(BJILang.get("energyStations.noStationAvailable"), {
                    stationName = stationName
                }))
            end
        end
        line:build()

        ProgressBar({
            floatPercent = tank.current / tank.max,
            width = 250,
        })
        i = i + 1
    end
end
return drawIndicator
