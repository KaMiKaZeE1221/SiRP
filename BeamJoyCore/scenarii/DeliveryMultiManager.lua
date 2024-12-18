local M = {
    participants = {},
    target = nil,
}

local function initTarget(pos)
    local targets = {}
    for _, delivery in pairs(BJCScenario.Deliveries) do
        table.insert(targets, {
            target = tdeepcopy(delivery),
            distance = GetHorizontalDistance(pos, delivery.pos),
        })
    end

    table.sort(targets, function(a, b)
        return a.distance > b.distance
    end)
    if #targets > 1 then
        local threhsholdPos = math.ceil(#targets * .99) + 1 -- 66% furthest
        while targets[threhsholdPos] do
            table.remove(targets, threhsholdPos)
        end
    end
    M.target = trandom(targets).target
end

local function join(playerID, gameVehID, pos)
    if #BJCScenario.Deliveries == 0 then
        return
    elseif M.participants[playerID] then
        return
    elseif BJCScenario.isServerScenarioInProgress() then
        return
    end

    local isStarting = false
    if tlength(M.participants) == 0 then
        initTarget(pos)
        isStarting = true
    end

    M.participants[playerID] = {
        gameVehID = gameVehID,
        streak = 0,
        nextTargetReward = isStarting,
        reached = false,
    }
    BJCTx.cache.invalidate(BJCTx.ALL_PLAYERS, BJCCache.CACHES.DELIVERY_MULTI)
end

local function resetted(playerID)
    local playerData = M.participants[playerID]
    if not playerData then
        return
    end

    playerData.nextTargetReward = false
    playerData.streak = 0
	BJCChat.onServerChat(playerID, "📦 You reset your vehicle and lost your streak! ☹️")
    BJCTx.cache.invalidate(BJCTx.ALL_PLAYERS, BJCCache.CACHES.DELIVERY_MULTI)
end

local function checkNextTarget()
    if tlength(M.participants) == 0 then
        return
    end
    for _, playerData in pairs(M.participants) do
        if not playerData.reached then
            return
        end
    end

    -- all participants reached target
    initTarget(M.target.pos)
    for playerID, playerData in pairs(M.participants) do
        playerData.reached = false
        if playerData.nextTargetReward then
            local reward = BJCConfig.Data.Reputation.DeliveryPackageReward +
                playerData.streak * BJCConfig.Data.Reputation.DeliveryPackageStreakReward
            local player = BJCPlayers.Players[playerID]
            player.stats.delivery = player.stats.delivery + 1
            BJCPlayers.reward(playerID, reward)
            playerData.streak = playerData.streak + 1
			local milestones = {
			[100] = "🌟 100 packages delivered without resetting, You’re a delivery legend! 👑",
			[95]  = "🌟 95 packages delivered without resetting, Almost at 100, keep going! 🚀",
			[90]  = "🌟 90 packages delivered without resetting, Almost there! You’re on fire! 🔥",
			[85]  = "🌟 85 packages delivered without resetting, You’re cruising now! 🚗💨",
			[80]  = "🌟 80 packages delivered without resetting, Look at you go! 😎",
			[75]  = "🌟 75 packages delivered without resetting, Keep it up, you’re unstoppable! 💪",
			[70]  = "🌟 70 packages delivered without resetting, Just 30 more until you hit the big 100! 🎯",
			[65]  = "🌟 65 packages delivered without resetting, Can we get a ‘woot woot’?! 🎉",
			[60]  = "🌟 60 packages delivered without resetting, You’ve got this in the bag! 🛍️",
			[55]  = "🌟 55 packages delivered without resetting, Still going strong! 💥",
			[50]  = "🌟 50 packages delivered without resetting, You are just better 🤷",
			[45]  = "🌟 45 packages delivered without resetting, Wow, are you a delivery robot? 🤖",
			[40]  = "🌟 40 packages delivered without resetting, You’re basically a professional now 🏆",
			[35]  = "🌟 35 packages delivered without resetting, Almost halfway to legendary status! 👑",
			[30]  = "🌟 30 packages delivered without resetting, Congrats! Can we call you the Delivery King? 👑",
			[25]  = "🌟 25 packages delivered without resetting, Getting closer to that 30 club! 😎",
			[20]  = "🌟 20 packages delivered without resetting, You’re on fire! 🔥",
			[15]  = "🌟 15 packages delivered without resetting, Look at you go! 🏃‍♂️",
			[10]  = "🌟 10 packages delivered without resetting, Double digits! You’re in the big leagues now! 💪",
			[5]   = "🌟 5 packages delivered without resetting, Not bad for a rookie! Welcome to the club! 🥳",
			}
			
			local message = milestones[playerData.streak]
			
			if message then
			BJCChat.onServerChat(playerID, message)
			end
        end
        playerData.nextTargetReward = true
    end
end

local function reached(playerID)
    BJCChat.onServerChat(playerID, "📦 You have successfully delivered the package!")
    if not M.participants[playerID] then
        return
    end

    M.participants[playerID].reached = true
    checkNextTarget()
    BJCTx.cache.invalidate(BJCTx.ALL_PLAYERS, BJCCache.CACHES.DELIVERY_MULTI)
end

local function checkEnd()
    if tlength(M.participants) == 0 then
        M.target = nil
    end
end

local function leave(playerID)
    if not M.participants[playerID] then
        return
    end

    M.participants[playerID] = nil
    checkEnd()
    BJCTx.cache.invalidate(BJCTx.ALL_PLAYERS, BJCCache.CACHES.DELIVERY_MULTI)
end

local function onPlayerDisconnect(playerID)
    if M.participants[playerID] then
        M.participants[playerID] = nil
        checkEnd()
        if tlength(M.participants) > 0 then
            checkNextTarget()
        end
        BJCTx.cache.invalidate(BJCTx.ALL_PLAYERS, BJCCache.CACHES.DELIVERY_MULTI)
    end
end

local function stop()
    if tlength(M.participants) > 0 then
        M.participants = {}
        M.target = nil
        BJCTx.cache.invalidate(BJCTx.ALL_PLAYERS, BJCCache.CACHES.DELIVERY_MULTI)
    end
end

local function getCache()
    return {
        participants = M.participants,
        target = M.target,
    }, M.getCacheHash()
end

local function getCacheHash()
    return Hash({
        M.participants,
        M.target,
    })
end

M.join = join
M.resetted = resetted
M.reached = reached
M.leave = leave

M.onPlayerDisconnect = onPlayerDisconnect

M.stop = stop

M.getCache = getCache
M.getCacheHash = getCacheHash

RegisterBJCManager(M)
return M
