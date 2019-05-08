

RegisterNetEvent("plesConf:confiscateVeh")
AddEventHandler("plesConf:confiscateVeh", function()
  local ped = GetPlayerPed(-1)
  if IsPedInAnyVehicle(ped) then
    local car = GetVehiclePedIsIn(ped, false)
    local model = GetEntityModel(car)
	local plate = tostring(GetVehicleNumberPlateText(car))
    TriggerServerEvent("plesConf:pasul2", model, plate)
  else
    TriggerEvent("chatMessage", "^1Error^7: You have to drive the car that you want to confiscate.")
  end
end)
