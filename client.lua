local sBuffer = {}
local vBuffer = {}
local CintoSeguranca = false
local ExNoCarro = false


local hour
local minute

function CalculateTimeToDisplay()
	hour = GetClockHours()
	minute = GetClockMinutes()
	if hour <= 9 then
		hour = '0' .. hour
	end
	if minute <= 9 then
		minute = '0' .. minute
	end
	SendNUIMessage(
		{
			date = hour .. ':' .. minute
		}
	)
end


inCar = false
Citizen.CreateThread(function()
	while true do
		local likizao = 500
		local ped = PlayerPedId()
		inCar = IsPedInAnyVehicle(ped, false)

		if inCar then 
			vehicle = GetVehiclePedIsIn(ped, false)
			local x,y,z = table.unpack(GetEntityCoords(ped))
			local vida = math.ceil((100 * ((GetEntityHealth(ped) - 100) / (GetEntityMaxHealth(ped) - 100))))
			local armour = GetPedArmour(ped)
			CalculateTimeToDisplay()

			local city = GetLabelText(GetNameOfZone(x,y,z))
			local streetName = GetStreetNameFromHashKey(GetStreetNameAtCoord(x, y, z))

			local rua = streetName..', '..city
			
			SendNUIMessage({
				action = "inCar",
				cinto = CintoSeguranca,
				health = vida,
				rua = rua,
				armour = armour
			})	
		end

		Citizen.Wait(likizao)	
	end
end)

Citizen.CreateThread(function()
	while true do
		local likizao = 200
		if inCar then 
			likizao = 50
			local ped = PlayerPedId()
			local car = GetVehiclePedIsIn(ped)
			local speed = math.ceil(GetEntitySpeed(vehicle) * 3.605936)
			local _,lights,highlights = GetVehicleLightsState(vehicle)
			local marcha = GetVehicleCurrentGear(vehicle)
			local fuel = GetVehicleFuelLevel(vehicle)
			local engine = GetVehicleEngineHealth(vehicle)
			CalculateTimeToDisplay()
			local farol = "off"
			if lights == 1 and highlights == 0 then farol = "normal"
			elseif (lights == 1 and highlights == 1) or (lights == 0 and highlights == 1) then 
				farol = "alto"
			end
			if marcha == 0 and speed > 0 then marcha = "R" elseif marcha == 0 and speed < 2 then marcha = "N" end
			rpm = GetVehicleCurrentRpm(vehicle)
            rpm = math.ceil(rpm * 10000, 2)
            vehicleNailRpm = 280 - math.ceil( math.ceil((rpm-2000) * 140) / 10000)
			SendNUIMessage({
				action = "updateSpeed",
				speed = speed,
				marcha = marcha,
				fuel = parseInt(fuel),
				engine = parseInt(engine/10),
				farol = farol,
				rpmnail = vehicleNailRpm,
                rpm = rpm/100,
				cinto = CintoSeguranca,
			})			
		end
		Citizen.Wait(likizao)	
	end
	end)

Citizen.CreateThread(function()
	while true do
		local likizao = 250
		if not inCar then 
			DisplayRadar(false)

			local ped = PlayerPedId()
			local vida = math.ceil((100 * ((GetEntityHealth(ped) - 100) / (GetEntityMaxHealth(ped) - 100))))
			local armour = GetPedArmour(ped)
	
			local x,y,z = table.unpack(GetEntityCoords(ped))
			CalculateTimeToDisplay()
			local city = GetLabelText(GetNameOfZone(x,y,z))
			local streetName = GetStreetNameFromHashKey(GetStreetNameAtCoord(x, y, z))

			local rua = streetName..', '..city
			SendNUIMessage({
				action = "update",
				health = vida,
				rua = rua,
				armour = armour,
			})			

		else
			DisplayRadar(true)
		end
		Citizen.Wait(likizao)	
	end
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- SEATBELT
-----------------------------------------------------------------------------------------------------------------------------------------
IsCar = function(veh)
	local vc = GetVehicleClass(veh)
	return (vc >= 0 and vc <= 7) or (vc >= 9 and vc <= 12) or (vc >= 17 and vc <= 20)
end

Citizen.CreateThread(function()
	while true do
		local timeDistance = 500
		local ped = PlayerPedId()
		local car = GetVehiclePedIsIn(ped)

		if car ~= 0 and (ExNoCarro or IsCar(car)) then
			ExNoCarro = true
			if CintoSeguranca then
				DisableControlAction(0,75)
			end

			timeDistance = 4
			sBuffer[2] = sBuffer[1]
			sBuffer[1] = GetEntitySpeed(car)

			if sBuffer[2] ~= nil and not CintoSeguranca and GetEntitySpeedVector(car,true).y > 1.0 and sBuffer[1] > 10.25 and (sBuffer[2] - sBuffer[1]) > (sBuffer[1] * 0.255) then
				SetEntityHealth(ped,GetEntityHealth(ped)-10)
				TaskLeaveVehicle(ped,GetVehiclePedIsIn(ped),4160)
			end

			if IsControlJustReleased(1,47) then
				if CintoSeguranca then
					TriggerEvent("vrp_sound:source","unbelt",0.5)
					CintoSeguranca = false
				else
					TriggerEvent("vrp_sound:source","belt",0.5)
					CintoSeguranca = true
				end
			end
		elseif ExNoCarro then
			ExNoCarro = false
			CintoSeguranca = false
			sBuffer[1],sBuffer[2] = 0.0,0.0
		end
		Citizen.Wait(timeDistance)
	end
end)

RegisterCommand('p', function(source, args, rawCmd)
	local ped = PlayerPedId()
	if IsPedInAnyVehicle(ped, false) then	
		local carrinhu = GetVehiclePedIsIn(ped, false)
		if not seatbeltIsOn then
			if args[1] then
				local acento = parseInt(args[1])
				
				if acento == 1 then
					if IsVehicleSeatFree(carrinhu, -1) then 
						if GetPedInVehicleSeat(carrinhu, 0) == ped then
							SetPedIntoVehicle(ped, carrinhu, -1)
						else
							TriggerEvent('Notify', 'negado','Você só pode passar para o P1 a partir do P2.')
						end
					else
						TriggerEvent('Notify','negado','O acento deve estar livre.')
					end
				elseif acento == 2 then
					if IsVehicleSeatFree(carrinhu, 0) then 
						if GetPedInVehicleSeat(carrinhu, -1) == ped then
							SetPedIntoVehicle(ped, carrinhu, 0)
						else
							TriggerEvent('Notify', 'negado','Você só pode passar para o P2 a partir do P1.')
						end
					else
						TriggerEvent('Notify', 'negado','O acento deve estar livre.')
					end
				elseif acento == 3 then
					if IsVehicleSeatFree(carrinhu, 1) then 
						if GetPedInVehicleSeat(carrinhu, 2) == ped then
							SetPedIntoVehicle(ped, carrinhu, 1)
						else
							TriggerEvent('Notify', 'negado','Você só pode passar para o P3 a partir do P4.')
						end
					else
						TriggerEvent('Notify', 'negado','O acento deve estar livre.')
					end
				elseif acento == 4 then
					if IsVehicleSeatFree(carrinhu, 2) then 
						if GetPedInVehicleSeat(carrinhu, 1) == ped then
							SetPedIntoVehicle(ped, carrinhu, 2)
						else
							TriggerEvent('Notify', 'negado','Você só pode passar para o P4 a partir do P3.')
						end
					else
						TriggerEvent('Notify', 'negado','O acento deve estar livre.')
					end
				end
			else
				TriggerEvent('Notify', 'negado','Especifique o acento que quer ir!')
			end
		else
			TriggerEvent('Notify', 'negado','Você não pode utilizar esse comando com o cinto de segurança!')
		end
	end
end)
	
RegisterCommand("cr",function(source,args)
	local veh = GetVehiclePedIsIn(PlayerPedId(),false)
	local maxspeed = GetVehicleMaxSpeed(GetEntityModel(veh))
	local vehspeed = GetEntitySpeed(veh)*3.605936
	if GetPedInVehicleSeat(veh,-1) == PlayerPedId() and math.ceil(vehspeed) >= 0 and GetEntityModel(veh) ~= -2076478498 and not IsEntityInAir(veh) then
		if args[1] == nil then
			SetEntityMaxSpeed(veh,maxspeed)
			TriggerEvent("Notify","sucesso","Limitador de Velocidade desligado com sucesso.")
		else
			SetEntityMaxSpeed(veh,0.45*args[1]-0.45)
			TriggerEvent("Notify","sucesso","Velocidade máxima travada em <b>"..args[1].." KM/H</b>.")
		end
	end
end)
RegisterNetEvent("hud:channel")
RegisterNetEvent("pma-voice:setTalkingMode")

AddEventHandler("hud:channel", function(_channel) SendNUIMessage({action = 'hudChannel',channel = _channel}) end)
AddEventHandler("pma-voice:setTalkingMode", function(_mode) SendNUIMessage({action = 'hudMode',mode = _mode}) end)