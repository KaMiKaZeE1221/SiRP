SetLogType("PPML", CONSOLE_COLORS.FOREGROUNDS.GREEN)
Log("Poor Player Manager Loaded...", "PPML")

function onPlayerJoin(playerID)
    local player = BJCPlayers.Players[playerID]
    if player.reputation < 10 then
	    player.reputation = 0
		BJCDao.players.save(player)  -- Save the updated player data
        player.reputation = player.reputation + 100
        BJCTx.player.toast(playerID, BJC_TOAST_TYPES.SUCCESS, " Welcome! You have been given 100 reputation points for having less than 10 reputation points.")
        BJCDao.players.save(player)  -- Save the updated player data
    end
end