print('Help Messages Loaded!')

function onChatMessage(playerID, message)
if message[0] == '/help' then
    onPlayerChat(playerID, helpMessage, {0.8, 0.8, 0.8, 1}) -- Light grey color
    local helpMessage = [[
    Anything you do with your vehicle will cost 10 reputation points. 
	You can see how many reputation points you have on the beamjoy interface. 
	You can earn reputation by doing races, delivery missions and bus missions. 
	To start a race as a solo player, click on Scenario and select Start Solo Race. 
	To start with other players, click on vote and select the event you want.
    ]]
  end
end