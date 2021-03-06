local Tunnel = module("vrp", "lib/Tunnel")
local Proxy = module("vrp", "lib/Proxy")
MySQL = module("vrp_mysql", "MySQL")

vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP","vRP_confisca")


local pret = 3000 -- fine price to recover a seized car
local tdCords = {434.05514526367, -1014.9097290039, 28.775266647339} -- where cops can seize vehs / players can recover seized vehs
local cop_permission = "police.easy_cuff" -- permission for a cop to seize an vehicle



MySQL.createCommand("vRP/ples_confiscate", [[
ALTER TABLE vrp_user_vehicles ADD veh_confiscate TINYINT NOT NULL DEFAULT 0;
CREATE TABLE `vrp_confiscate`(
    `id` INT AUTO_INCREMENT,
    `user_id` INT(30) NOT NULL,
    `vehicle` VARCHAR(255) NOT NULL,
    `cop` VARCHAR(255) DEFAULT 'Unknown',
    PRIMARY KEY (id)
);
]])

-- get user_id by plate function
MySQL.createCommand("vRP/get_userbyplate","SELECT `user_id` FROM `vrp_user_vehicles` WHERE `vehicle_plate` = @plate")

-- if you will want to add it to vrp/modules/identity.lua
-- function vRP.getUserByPlate(plate, cbr)
function getUserByPlate(plate, cbr)
  local task = Task(cbr)
  if plate ~= nil then
	  MySQL.query("vRP/get_userbyplate", {plate = plate}, function(rows, affected)
		if #rows > 0 then
		  task({rows[1].user_id})
		else
		  task()
		end
	  end)
  end
end


MySQL.createCommand("vRP/ples_getVehs", "SELECT `vehicle` FROM `vrp_user_vehicles` WHERE `user_id`=@u_id")
MySQL.createCommand("vRP/ples_confVeh", [[
  UPDATE vrp_user_vehicles SET veh_confiscate = 1 WHERE `user_id`=@u_id AND `vehicle`=@modelX;
  INSERT IGNORE INTO `vrp_confiscate` (`user_id`, `vehicle`, `cop`) VALUES (@u_id, @modelX, @cop);
]])


MySQL.createCommand("vRP/ples_getConfiscate", "SELECT vehicle, cop FROM vrp_confiscate WHERE user_id = @user_id")
MySQL.createCommand("vRP/ples_stergConf", [[
UPDATE vrp_user_vehicles SET veh_confiscate = 0 WHERE `user_id`=@user_id AND `vehicle`=@model;
DELETE FROM vrp_confiscate WHERE user_id = @user_id AND vehicle = @model
]])
-- init

--MySQL.query("vRP/ples_confiscate")
print("[PLES] Am verificat tabelu ! (Bun scripter a facut asta adevarat!)")

local menu_confisca = {
	name = "Seize Cars",
	css={top = "75px", header_color="rgba(226, 87, 36, 0.75)"}
}

menu_confisca["Confiscate a car"] = {function(player, choice)
	local user_id = vRP.getUserId({player})
	if user_id ~= nil then
		if vRP.hasPermission({user_id, cop_permission}) then
			vRP.closeMenu({player})
			TriggerClientEvent("plesConf:confiscateVeh", player)
		else
			vRP.closeMenu({player})
			vRPclient.notify(player, {"~r~Only a cop can confiscate a personal vehicle."})
		end
	end
end, "Seize the car you are driving at the moment."}

RegisterServerEvent("plesConf:pasul2")
AddEventHandler("plesConf:pasul2", function(model, plate)
	local user_id = vRP.getUserId({source})
	local player = vRP.getUserSource({user_id})
	if vRP.hasPermission({user_id, cop_permission}) then
		getUserByPlate(plate, function(u_id)
			u_id = parseInt(u_id)
			if u_id ~= nil then
				tsource = vRP.getUserSource({u_id})
				if tsource ~= nil then
					MySQL.query("vRP/ples_getVehs", {u_id = u_id}, function(rows, affected)
						if #rows > 0 then
							local gasit = false
							for i, v in pairs(rows) do
								if GetHashKey(v.vehicle) == model then
									local modelX = v.vehicle
									gasit = true
									--TriggerClientEvent("chatMessage", source, "Model gasit: "..v.vehicle) -- Debug
									local cop = GetPlayerName(player)
									MySQL.execute("vRP/ples_confVeh", {u_id = u_id, modelX = modelX, cop = cop })
									TriggerClientEvent("wk:deleteVehicle", player)

									TriggerClientEvent("chatMessage", tsource, "^1Info^7: Your car was seized by the police. Go to the police station as soon as possible to recover it !")
									TriggerClientEvent("chatMessage", player, "^1Info^7: You seized "..GetPlayerName(tsource).."'s car [ID "..u_id.."]")
								end
							end
							if not gasit then
								vRPclient.notify(player, {"~r~The player does not own a car of this model."})
							end
						else
							vRPclient.notify(player, {"~r~The player does not own a car of this model."})
						end
					end)
				else
					vRPclient.notify(player, {"~r~The player is offline."})
				end
			else
				vRPclient.notify(player, {"~r~This car is not an personal vehicle"})
			end
		end)
	end
end)

menu_confisca["My cars"] = {function(player, choice)
	local user_id = vRP.getUserId({player})
	if user_id ~= nil then
		local menu_sub = {
		name = "Seized cars",
		css={top = "75px", header_color="rgba(226, 87, 36, 0.75)"}
		}

		MySQL.query("vRP/ples_getConfiscate", {user_id = user_id}, function(pvehicles, affected)

			for k,v in pairs(pvehicles) do
				menu_sub[ "Car #"..k ] = {function(playerx, choicex)
					if vRP.tryFullPayment({user_id, pret}) then
						local model = v.vehicle
						MySQL.execute("vRP/ples_stergConf", {user_id = user_id, model = model})
						vRPclient.notify(playerx, {"You paid the fines to recover the car.\nGo to a garage to use it."})
						vRP.closeMenu({playerx})
					else
						vRPclient.notify(playerx, {"~r~Not enought money."})
					end
				end,"The cop that seized your car: "..v.cop.."<br/>Fine price: $"..pret}
			end

			vRP.openMenu({player, menu_sub})
		end)
	end
end, "Seize the car you are driving at the moment."}

local function build_confisca(source)
	local user_id = vRP.getUserId({source})
	if user_id ~= nil then
		local x, y, z = table.unpack(tdCords)

		local conf_enter = function(player, area)
			local user_id = vRP.getUserId({player})
			if user_id ~= nil then
				if menu_confisca then vRP.openMenu({player, menu_confisca}) end
			end
		end

		local conf_leave = function(player, area)
			vRP.closeMenu({player})
		end

		vRPclient.addBlip(source, {x, y, z, 380, 47, "Seized Vehicles"})
		vRPclient.addMarker(source,{x,y,z-0.95,1.5,1.5,0.9,0, 66, 134, 244,150})

		vRP.setArea({source, "vRP:confisatdePles", x, y, z, 3, 2, conf_enter, conf_leave})
	end
end

AddEventHandler("vRP:playerSpawn",function(user_id,source,first_spawn)
  if first_spawn then
    build_confisca(source)
  end
end)
