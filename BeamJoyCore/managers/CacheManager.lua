SetLogType("Cache", CONSOLE_COLORS.FOREGROUNDS.GREEN)
Log("Cache Manager Loaded...", "Cache")

local M = {
    CACHES = {
        -- player
        LANG = "lang",
        USER = "user",
        GROUPS = "groups",
        PLAYERS = "players",
        MAP = "map",
        ENVIRONMENT = "environment",
        PERMISSIONS = "permissions",
        BJC = "bjc",
        VOTE = "vote",
        RACES = "races",
        RACE = "race",
        DELIVERIES = "deliveries",
        DELIVERY_MULTI = "deliverymulti",
        STATIONS = "stations",
        BUS_LINES = "buslines",
        SPEED = "speed",
        HUNTER_DATA = "hunterdata",
        HUNTER = "hunter",
        DERBY_DATA = "derbydata",
        DERBY = "derby",
        -- admin
        DATABASE_PLAYERS = "databasePlayers",
        DATABASE_VEHICLES = "databaseVehicles",
        -- owner
        CORE = "core",
        MAPS = "maps",
    }
}

local function getTargetMap()
    return {
        [M.CACHES.LANG] = { permission = nil, fn = BJCLang.getCache },
        [M.CACHES.USER] = { permission = nil, fn = BJCPlayers.getCacheUser },
        [M.CACHES.GROUPS] = { permission = nil, fn = BJCGroups.getCache },
        [M.CACHES.PERMISSIONS] = { permission = nil, fn = BJCPerm.getCache },
        [M.CACHES.ENVIRONMENT] = { permission = nil, fn = BJCEnvironment.getCache },
        [M.CACHES.BJC] = { permission = nil, fn = BJCConfig.getCache },
        [M.CACHES.PLAYERS] = { permission = nil, fn = BJCPlayers.getCachePlayers },
        [M.CACHES.MAP] = { permission = nil, fn = BJCMaps.getCacheMap },
        [M.CACHES.VOTE] = { permission = nil, fn = BJCVote.getCache },
        [M.CACHES.RACES] = { permission = nil, fn = BJCScenario.getCacheRaces },
        [M.CACHES.RACE] = { permission = nil, fn = BJCScenario.RaceManager.getCache },
        [M.CACHES.DELIVERIES] = { permission = BJCPerm.PERMISSIONS.START_PLAYER_SCENARIO, fn = BJCScenario.getCacheDeliveries },
        [M.CACHES.DELIVERY_MULTI] = { permission = BJCPerm.PERMISSIONS.START_PLAYER_SCENARIO, fn = BJCScenario.DeliveryMultiManager.getCache },
        [M.CACHES.STATIONS] = { permission = BJCPerm.PERMISSIONS.START_PLAYER_SCENARIO, fn = BJCScenario.getCacheStations },
        [M.CACHES.BUS_LINES] = { permission = BJCPerm.PERMISSIONS.START_PLAYER_SCENARIO, fn = BJCScenario.getCacheBusLines },
        [M.CACHES.SPEED] = { permission = nil, fn = BJCScenario.SpeedManager.getCache },
        [M.CACHES.DATABASE_PLAYERS] = { permission = BJCPerm.PERMISSIONS.DATABASE_PLAYERS, fn = BJCPlayers.getCacheDatabasePlayers },
        [M.CACHES.DATABASE_VEHICLES] = { permission = nil, fn = BJCVehicles.getCache },
        [M.CACHES.CORE] = { permission = BJCPerm.PERMISSIONS.SET_CORE, fn = BJCCore.getCache },
        [M.CACHES.MAPS] = { permission = BJCPerm.PERMISSIONS.VOTE_MAP, fn = BJCMaps.getCacheMaps },
        [M.CACHES.HUNTER_DATA] = { permission = nil, fn = BJCScenario.getCacheHunter },
        [M.CACHES.HUNTER] = { permission = nil, fn = BJCScenario.HunterManager.getCache },
        [M.CACHES.DERBY_DATA] = { permission = nil, fn = BJCScenario.getCacheDerby },
        [M.CACHES.DERBY] = { permission = nil, fn = BJCScenario.DerbyManager.getCache },
    }
end

local function getCache(ctxt, cacheType)
    local target = getTargetMap()[cacheType]
    if not target or (target.permission and not BJCPerm.hasPermission(ctxt.senderID, target.permission)) then
        return
    end

    local cache, hash = {}, tostring(GetCurrentTime())
    if target.fn then
        cache, hash = target.fn(ctxt.senderID)
    end

    BJCTx.cache.send(ctxt.senderID, cacheType, cache, hash)
end

M.getCache = getCache

RegisterBJCManager(M)
return M
