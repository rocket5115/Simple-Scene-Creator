CreateThread(function()
	local allow = false
	local SceneId = nil
	local defaultScope = false
	RegisterNetEvent('Scene_creator:allow', function(p)
		allow = p
	end)
	CreateThread(function()
		Wait(500)
		if Config.AutoEnable then
			TriggerServerEvent('Scene_creator:requestAdmin')
		end
	end)
	local sin,cos,abs,pi = math.sin,math.cos,math.abs,math.pi
	local hp = (pi/180)

	local function RaycastGameplayCamera(distance)
		local rotation = GetGameplayCamRot()
		local cameraCoord = GetGameplayCamCoord()
		local x,z = hp * rotation.x, hp * rotation.z
		local a, b, c, d, e = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, (cameraCoord.x + (-sin(z) * abs(cos(x))) * distance), (cameraCoord.y + (cos(z) * abs(cos(x))) * distance), (cameraCoord.z + sin(x) * distance), -1, -1, 1))
		return b, c, e
	end

	local Peds = {}
	local Vehicles = {}
	local Objects = {}

	local EntitySetAs = {}

	local function PrepareModel(model,err)
		return(((type(model)=='string'and model~='')and GetHashKey(model)or type(model)=='number'and model)or err)
	end

	local function RequestModelSync(model)
		RequestModel(model)
		while not HasModelLoaded(model) do
			Wait(10)
		end
		return true
	end

	local function CreateLocalPed(x,y,z,h,model,network)
		if network then network = true else network = false end
		model = PrepareModel(model,`a_m_m_mexlabor_01`)
		RequestModelSync(model)
		return CreatePed(1,model,x,y,z,h,network,false)
	end

	local function CreateLocalVehicle(x,y,z,h,model,network)
		if network then network = true else network = false end
		model = PrepareModel(model,`blista`)
		RequestModelSync(model)
		return CreateVehicle(model,x,y,z,h,network,false)
	end

	local function CreateLocalObject(x,y,z,model,network)
		if network then network = true else network = false end
		model = PrepareModel(model,`prop_weed_block_01`)
		RequestModelSync(model)
		return CreateObject(model,x,y,z,network,false,false)
	end

	Citizen.CreatePed = CreateLocalPed
	Citizen.CreateVehicle = CreateLocalVehicle
	Citizen.CreateObject = CreateLocalObject

	local function SetEntityFocus(entity,focus,player)
		local ped = PlayerPedId()
		if focus then
			if player then
				SetEntityVisible(ped,false,0)
				SetEntityLocallyInvisible(ped,true)
			end
			SetEntityNoCollisionEntity(ped,entity,false)
		else
			if player then
				SetEntityVisible(ped,true,0)
				SetEntityLocallyVisible(ped)
			end
			SetEntityNoCollisionEntity(ped,entity,true)
		end
	end

	local function RequestNetworkControl(ent)
		if DoesEntityExist(ent) then
			local request = 0
			NetworkRequestControlOfEntity(ent)
			while not NetworkHasControlOfEntity(ent)and request<50 do
				Wait(10)
				NetworkRequestControlOfEntity(ent)
				request=request+1
			end
		end
	end

	local function DeleteNetworkedEntity(entity)
		if NetworkGetEntityIsNetworked(entity) then
			while not NetworkHasControlOfEntity(entity) and DoesEntityExist(entity) do
				NetworkRequestControlOfEntity(entity)
				Wait(1)
			end
			if DoesEntityExist(entity) and NetworkHasControlOfEntity(entity) then
				SetEntityAsMissionEntity(entity, false, true)
				DeleteEntity(entity)
			end
		else
			SetEntityAsMissionEntity(entity,false,false)
			DeleteEntity(entity)
			DeleteObject(entity)
		end
	end

	local function DrawXYZGraphFromEntity(entity)
		local start = GetEntityCoords(entity)
		local x,y,z = start-GetOffsetFromEntityInWorldCoords(entity,2.0,0.0,0.0),start-GetOffsetFromEntityInWorldCoords(entity,0.0,2.0,0.0),start-GetOffsetFromEntityInWorldCoords(entity,0.0,0.0,2.0)
		local x1,x2,y1,y2,z1,z2 = start-x,start+x,start-y,start+y,start-z,start+z
		DrawLine(x1.x,x1.y,x1.z,x2.x,x2.y,x2.z,255,0,0,255)
		DrawLine(y1.x,y1.y,y1.z,y2.x,y2.y,y2.z,0,0,255,255)
		DrawLine(z1.x,z1.y,z1.z,z2.x,z2.y,z2.z,0,255,0,255)
	end

	SendWhenNUIActive({
		lang = Config.Language or 'en',
		data = Translation[Config.Language or 'en'],
		type = 'translations'
	})

	local nuienabled = false
	local lnui = false
	local isOn = false
	RegisterNUIListener('nuioff', function()
		lnui = false
		nuienabled = false
		isOn = false
	end)

	local template = {}

	CreateThread(function()
		while true do
			if not allow then
				Wait(200)
			else
				local pPed = PlayerPedId()
				if (lnui or nuienabled) then
					DisableControlAction(1,24,true)
					TaskStandStill(pPed,200)
				end
				Wait(5)
				DisableControlAction(1,37,true)
				if not lnui and IsDisabledControlJustPressed(1,37) then
					display(true,true)
					lnui = true
					isOn=true
				elseif not nuienabled and lnui and not IsDisabledControlPressed(1,37) and isOn then
					nuienabled=false
					lnui = false
					isOn=false
					display(false,false)
				elseif lnui and IsDisabledControlJustReleased(1,24) then
					nuienabled = true
					lnui = true
					isOn=true
					display(true,false)
				end
			end
		end
	end)

	local curEnt = nil
	local mMode_default = false
	local spd = 0.05

	CreateThread(function()
		local rotation = 0.0
		local pitch = 0.0
		local roll = 0.0
		local set = false
		local entType = 0
		local mMode = false
		while true do
			Wait(5)
			if not curEnt or not allow then
				rotation=0.0
				pitch=0.0
				roll=0.0
				set=false
				mMode=mMode_default
				if spd > 100 then
					spd=1
				elseif spd < 0 then
					spd=0.05
				end
				Wait(200)
			else
				DisableControlAction(1,44,true)
				DisableControlAction(1,46,true)
				DisableControlAction(1,178,true)
				DisableControlAction(1,243,true)
				if not set then
					SendDebugData('speed',spd)
					local is = NetworkGetEntityIsNetworked(curEnt)
					SendDebugData('networked','<span '..(is and 'class="green">Yes'or'class="red">No')..'</span>')
					SendDebugData('network', '<span '..(EntitySetAs[curEnt] and 'class="green">Yes'or'class="red">No')..'</span>')
					FreezeEntityPosition(curEnt,true)
					entType = GetEntityType(curEnt)
					if entType ~= 1 then
						SetEntityDrawOutline(curEnt, true)
						SetEntityDrawOutlineColor(255,0,0,100)
					else
						SetEntityAlpha(curEnt, 200)
					end
					if entType ~= 3 then
						rotation = GetEntityHeading(curEnt)
						SendDebugData('rot',rotation)
					else
						local rot = GetEntityRotation(curEnt)
						roll = rot.y
						pitch = rot.x
						rotation = rot.z
						SendDebugData('rot',rotation)
					end
					SendDebugData('model',GetEntityModel(curEnt))

					set=true
				end
				if IsDisabledControlPressed(1,44) then
					rotation=rotation+spd
					if rotation>360.0 then
						rotation=0.0
					end
					if entType == 3 then
						SetEntityRotation(curEnt, pitch, roll, rotation, false, true)
						SendDebugData('rot',GetEntityRotation(curEnt))
					else
						SetEntityHeading(curEnt, rotation)
						SendDebugData('rot',GetEntityHeading(curEnt))
					end
				elseif IsDisabledControlPressed(1,46) then
					rotation=rotation-spd
					if rotation<0.0 then
						rotation=360.0
					end
					if entType == 3 then
						SetEntityRotation(curEnt, pitch, roll, rotation, false, true)
						SendDebugData('rot',GetEntityRotation(curEnt))
					else
						SetEntityHeading(curEnt, rotation)
						SendDebugData('rot',GetEntityHeading(curEnt))
					end
				end
				if IsDisabledControlJustPressed(1,178) then
					if entType == 1 then
						Peds[curEnt]=nil
					elseif entType == 2 then
						Vehicles[curEnt]=nil
					elseif entType == 3 then
						Objects[curEnt]=nil
					end
					SetEntityDrawOutline(curEnt, false)
					ResetEntityAlpha(curEnt)
					DeleteNetworkedEntity(curEnt)
					TriggerEvent('Scene_creator:saveScene')
					curEnt=nil
				end
				if IsDisabledControlJustPressed(1,243) then
					mMode=not mMode
				end
				if entType==3 then
					DisableControlAction(1,34,true)
					DisableControlAction(1,30,true)
					DisableControlAction(1,20,true)
					DisableControlAction(1,73,true)
					if IsDisabledControlPressed(1,20) then
						pitch=pitch+spd
						if pitch>180.0 then
							pitch=-180.0
						end
						SetEntityRotation(curEnt,pitch,roll,rotation,false,true)
					elseif IsDisabledControlPressed(1,73) then
						pitch=pitch-spd
						if pitch<-180.0 then
							pitch=180.0
						end
						SetEntityRotation(curEnt,pitch,roll,rotation,false,true)
					end
					if IsDisabledControlPressed(1,30) then
						roll=roll+spd
						if roll>180.0 then
							roll=-180.0
						end
						SetEntityRotation(curEnt,pitch,roll,rotation,false,true)
					elseif IsDisabledControlPressed(1,34) then
						roll=roll-spd
						if roll<-180.0 then
							roll=180.0
						end
						SetEntityRotation(curEnt,pitch,roll,rotation,false,true)
					end
				end
				if IsControlPressed(1, 96) then
					spd=spd+0.05
					SendDebugData('speed',spd)
				elseif IsControlPressed(1, 97) then
					if spd-0.05>0 then
						spd=spd-0.05
					end
					SendDebugData('speed',spd)
				end
				if mMode then
					DisableControlAction(1,172,true)
					DisableControlAction(1,173,true)
					DisableControlAction(1,174,true)
					DisableControlAction(1,175,true)
					DisableControlAction(1,32,true)
					DisableControlAction(1,33,true)
					DrawXYZGraphFromEntity(curEnt)
					TaskStandStill(PlayerPedId(),100)
					if IsDisabledControlPressed(1,172) then
						local offset = GetOffsetFromEntityInWorldCoords(curEnt, 0.0, spd, 0.0)
						SetEntityCoordsNoOffset(curEnt, offset.x, offset.y, offset.z, false, false, false)
						SendDebugData('pos',offset)
					elseif IsDisabledControlPressed(1,173) then
						local offset = GetOffsetFromEntityInWorldCoords(curEnt, 0.0, -spd, 0.0)
						SetEntityCoordsNoOffset(curEnt, offset.x, offset.y, offset.z, false, false, false)
						SendDebugData('pos',offset)
					end
					if IsDisabledControlPressed(1,174) then
						local offset = GetOffsetFromEntityInWorldCoords(curEnt, spd, 0.0, 0.0)
						SetEntityCoordsNoOffset(curEnt, offset.x, offset.y, offset.z, false, false, false)
						SendDebugData('pos',offset)
					elseif IsDisabledControlPressed(1,175) then
						local offset = GetOffsetFromEntityInWorldCoords(curEnt, -spd, 0.0, 0.0)
						SetEntityCoordsNoOffset(curEnt, offset.x, offset.y, offset.z, false, false, false)
						SendDebugData('pos',offset)
					end
					if IsDisabledControlPressed(1,32) then
						local offset = GetOffsetFromEntityInWorldCoords(curEnt, 0.0, 0.0, spd)
						SetEntityCoordsNoOffset(curEnt, offset.x, offset.y, offset.z, false, false, false)
						SendDebugData('pos',offset)
					elseif IsDisabledControlPressed(1,33) then
						local offset = GetOffsetFromEntityInWorldCoords(curEnt, 0.0, 0.0, -spd)
						SetEntityCoordsNoOffset(curEnt, offset.x, offset.y, offset.z, false, false, false)
						SendDebugData('pos',offset)
					end
				else
					local hit, coords, entity = RaycastGameplayCamera(1000.0)
					if hit then
						if entity ~= curEnt and not IsPedAPlayer(entity) then
							SetEntityCoords(curEnt, coords.x, coords.y, coords.z, false, false, false, true)
							if entType == 3 then
								SetEntityRotation(curEnt, pitch, roll, rotation, false, true)
								SendDebugData('rot',GetEntityRotation(curEnt))
							else
								SetEntityHeading(curEnt, rotation)
								SendDebugData('rot',GetEntityHeading(curEnt))
							end
						end
					end
				end
				if IsControlJustPressed(1,191)then
					SetEntityDrawOutline(curEnt, false)
					ResetEntityAlpha(curEnt)
					curEnt = nil
					TriggerEvent('Scene_creator:saveScene')
				end
			end
		end
	end)

	local lastentity = nil

	function RegisterEntityAsMoveable(entity, ray)
		if lastentity then
			--FreezeEntityPosition(lastentity,false)
			SetEntityDrawOutline(lastentity, false)
			ResetEntityAlpha(lastentity)
		end
		if not entity then
			return
		end
		lastentity = entity
		FreezeEntityPosition(entity,true)
		if ray then curEnt = entity end
	end

	function SaveMoveableEntity(entity)
		if IsEntityAPed(entity) then
			Peds[entity]=entity
		elseif IsEntityAVehicle(entity) then
			Vehicles[entity]=entity
		elseif IsEntityAnObject(entity) then
			Objects[entity]=entity
		end
	end

	local curMan = nil

	RegisterNUICallback('spawn', function(data)
		curMan = nil
		if data.data == 'S_Ped' then
			local coords = GetEntityCoords(PlayerPedId())
			local ped = Citizen.CreatePed(coords.x, coords.y, coords.z+5.0, 0.0, IsModelAPed(GetHashKey(data.model))and data.model, data.network)
			SetEntityScope(defaultScope,ped)
			SaveMoveableEntity(ped)
			RegisterEntityAsMoveable(ped, true)
		elseif data.data == 'S_Veh' then
			local coords = GetEntityCoords(PlayerPedId())
			local veh = Citizen.CreateVehicle(coords.x, coords.y, coords.z+5.0, 0.0, IsModelInCdimage(GetHashKey(data.model))and data.model, data.network)
			SetEntityScope(defaultScope,veh)
			SaveMoveableEntity(veh)
			RegisterEntityAsMoveable(veh, true)
		elseif data.data == 'S_Obj' then
			local coords = GetEntityCoords(PlayerPedId())
			local obj = Citizen.CreateObject(coords.x, coords.y, coords.z+5.0, IsModelValid(GetHashKey(data.model))and data.model, data.network)
			SetEntityScope(defaultScope,obj)
			SaveMoveableEntity(obj)
			RegisterEntityAsMoveable(obj, true)
		end
		TriggerEvent('Scene_creator:saveScene')
	end)

	RegisterNUICallback('manage', function(data)
		curMan = true
	end)

	CreateThread(function()
		local lastEnt = nil
		local lastType = nil
		while true do
			Wait(10)
			if not curMan or not allow then
				lastEnt = nil
				lastType = nil
				Wait(200)
			else
				local hit, coords, entity = RaycastGameplayCamera(1000.0)
				if hit then
					local ent = (Peds[entity]or Vehicles[entity]or Objects[entity])
					if ent and not lastEnt and DoesEntityExist(entity) then
						if not lastEnt then
							lastType=GetEntityType(ent)
							SetEntityFocus(ent,true,true)
							if lastType==1 then
								SetEntityAlpha(ent,200)
							else
								SetEntityDrawOutline(ent, true)
							end
						end
						lastEnt = ent
					elseif lastEnt and not lastEnt == ent then
						if lastEnt then
							SetEntityFocus(lastEnt,false,true)
							if lastType==1 then
								ResetEntityAlpha(lastEnt)
							else
								SetEntityDrawOutline(lastEnt, false)
							end
							lastEnt=nil
						end
					else
						if lastEnt ~= ent then
							SetEntityFocus(lastEnt,false,true)
							if lastType==1 then
								ResetEntityAlpha(lastEnt)
							else
								SetEntityDrawOutline(lastEnt, false)
							end
							lastEnt=nil
						end
					end
				end
				if IsControlJustPressed(1,191)then
					if lastEnt then
						SetEntityFocus(lastEnt,false,true)
						if lastType==1 then
							ResetEntityAlpha(lastEnt)
						else
							SetEntityDrawOutline(ent, false)
						end
						curEnt=lastEnt
						lastEnt=nil
					end
					curMan = nil
				end
			end
		end
	end)

	local isSearching = false

	RegisterNUICallback('addent', function()
		isSearching = true
	end)

	CreateThread(function()
		local lastEnt = nil
		local entType = nil
		while true do
			Wait(10)
			if not isSearching or not allow then
				Wait(200)
			else
				local hit, coords, entity = RaycastGameplayCamera(1000.0)
				if hit then
					if entity~=lastEnt and not (Peds[entity]or Vehicles[entity]or Objects[entity]) and not IsPedAPlayer(entity) and DoesEntityExist(entity) and GetEntityType(entity)~=0 then
						if lastEnt then
							SetEntityFocus(lastEnt,false,true)
							ResetEntityAlpha(lastEnt)
							SetEntityDrawOutline(lastEnt, false)
						end
						lastEnt = entity
						entType = GetEntityType(entity)
						SetEntityFocus(entity,true,true)
						if entType ~= 1 then
							SetEntityDrawOutline(entity, true)
							SetEntityDrawOutlineColor(255,0,0,100)
						else
							SetEntityAlpha(entity, 200)
						end
					elseif lastEnt and entity~=lastEnt then
						SetEntityFocus(lastEnt,false,true)
						if entType==1 then
							ResetEntityAlpha(lastEnt)
						else
							SetEntityDrawOutline(lastEnt, false)
						end
						lastEnt = nil
					end
					if IsControlJustPressed(1,191)then
						if lastEnt then
							SetEntityScope(defaultScope,lastEnt)
							TriggerEvent('Scene_creator:saveScene')
							if NetworkGetEntityIsNetworked(lastEnt) then
								RequestNetworkControl(lastEnt)
							end
							SetEntityFocus(lastEnt,false,true)
							if entType==1 then
								ResetEntityAlpha(lastEnt)
								Peds[lastEnt] = lastEnt
							else
								SetEntityDrawOutline(lastEnt, false)
								if entType==2 then
									Vehicles[lastEnt] = lastEnt
								else
									Objects[lastEnt] = lastEnt
								end
							end
						end
						isSearching = false
						lastEnt = nil
						entType = nil
					end
				end
			end
		end
	end)

	RegisterNUICallback('UpdateSettings', function(data)
		mMode_default = data.select
		Config.SaveDefault = data.change
		Config.SaveSpace = data.save
	end)

	local function DataFunc()
		local retval = {}
		for k,v in pairs(Peds)do
			local net = false
			if EntitySetAs[v]~=nil then
				net = EntitySetAs[v]
			else
				net = NetworkGetEntityIsNetworked(v)
			end
			retval[#retval+1] = {
				type = 'Ped',
				pos = GetEntityCoords(v),
				model = GetEntityModel(v),
				heading = GetEntityHeading(v),
				network = net
			}
		end
		for k,v in pairs(Vehicles)do
			local net = false
			if EntitySetAs[v]~=nil then
				net = EntitySetAs[v]
			else
				net = NetworkGetEntityIsNetworked(v)
			end
			retval[#retval+1] = {
				type = 'Veh',
				pos = GetEntityCoords(v),
				model = GetEntityModel(v),
				heading = GetEntityHeading(v),
				network = net
			}
		end
		for k,v in pairs(Objects)do
			local net = false
			if EntitySetAs[v]~=nil then
				net = EntitySetAs[v]
			else
				net = NetworkGetEntityIsNetworked(v)
			end
			retval[#retval+1] = {
				type = 'Obj',
				pos = GetEntityCoords(v),
				model = GetEntityModel(v),
				rot = GetEntityRotation(v),
				network = net
			}
		end
		return retval
	end

	local await = {}

	RegisterNUICallback('compress', function(data)
		if await[1] then
			await[2]=data.data
			await[1]:resolve(true)
		end
	end)

	local function GetCurrentData(compress)
		if compress then
			local prm = promise:new()
			SendNUIMessage({
				type='compress',
				data=DataFunc()
			})
			await[1]=prm
			Citizen.Await(prm)
			await[1]=nil
			local data = await[2]
			await[2]=nil
			return data
		else
			local data = DataFunc()
			data.lang = 'lua'
			return json.encode(data)
		end
	end

	local crt = false

	RegisterNUICallback('SaveProject', function()
		if crt then
			TriggerServerEvent('Scene_creator:save_session',GetCurrentData(Config.SaveSpace),Config.SaveSpace)
		end
	end)

	RegisterCommand('createscene', function(_,args)
		crt=true
		TriggerServerEvent('Scene_creator:create_session',args[1])
	end)

	RegisterCommand('loadscene', function(_,args)
		SceneId=args[1]
		TriggerServerEvent('Scene_creator:load_session',args[1])
	end)

	RegisterCommand('savetemplate', function()
		if crt then
			local data = DataFunc()
			print(data,#data)
			if #data==0 then
				return
			else
				local first = data[1]
				first.pos = nil
				local offsets = {{offset=vector3(0,0,0),data=first,ent=0}}
				for i=2,#data do
					local offset = data[i].pos-first.pos
					data[i].pos=nil
					offsets[i]={offset=offset,data=data[i],ent=0}
				end
				TriggerServerEvent('Scene_creator:save_template',json.encode(offsets))
			end
		end
	end)

	RegisterCommand('loadtemplate', function(_,args)
		if args[1] then
			SceneId=args[1]
			TriggerServerEvent('Scene_creator:load_template',args[1])
		end
	end)

	local mtemp = false

	RegisterNetEvent('Scene_creator:load_template', function(data)
		crt=true
		SendDebugData('id',SceneId)
		local data = json.decode(data)
		local first = GetOffsetFromEntityInWorldCoords(curEnt, 0.0, 0.0, 5.0)
		for i=1,#data do
			data[i].data.offset = vector3(data[i].offset.x,data[i].offset.y,data[i].offset.z)
			if i~=1 then
				data[i].data.pos=first+data[i].data.offset
			end
			if data[i].data.type=='Ped'then
				local ped = Citizen.CreatePed(data[i].data.pos.x, data[i].data.pos.y, data[i].data.pos.z, data[i].data.heading, data[i].data.model, (data[i].data.network~=nil and data[i].data.network~=false))
				SetEntityCoordsNoOffset(ped,data[i].data.pos.x, data[i].data.pos.y, data[i].data.pos.z, false, false, false)
				Peds[ped]=ped
				data[i].ent = ped
				FreezeEntityPosition(ped,true)
			elseif data[i].data.type=='Veh'then
				local veh = Citizen.CreateVehicle(data[i].data.pos.x, data[i].data.pos.y, data[i].data.pos.z, data[i].data.heading, data[i].data.model, (data[i].data.network~=nil and data[i].data.network~=false))
				SetEntityCoordsNoOffset(veh,data[i].data.pos.x, data[i].data.pos.y, data[i].data.pos.z, false, false, false)
				Vehicles[veh]=veh
				data[i].ent = veh
				FreezeEntityPosition(veh,true)
			elseif data[i].data.type=='Obj'then
				local obj = Citizen.CreateObject(data[i].data.pos.x, data[i].data.pos.y, data[i].data.pos.z, data[i].data.model, (data[i].data.network~=nil and data[i].data.network~=false))
				SetEntityCoordsNoOffset(obj,data[i].data.pos.x, data[i].data.pos.y, data[i].data.pos.z, false, false, false)
				Objects[obj]=obj
				data[i].ent = obj
				SetEntityRotation(obj,data[i].data.rot.x,data[i].data.rot.y,data[i].data.rot.z,false,true)
				FreezeEntityPosition(obj,true)
			end
		end
		template=data
		mtemp=true
	end)

	local function MoveTemplate(coords)
		local offset = template[1]
		if offset then
			SetEntityCoordsNoOffset(offset.ent,coords.x,coords.y,coords.z,false,false,false)
			for i=2,#template do
				local c = coords+vector3(template[i].offset.x,template[i].offset.y,template[i].offset.z)
				SetEntityCoordsNoOffset(template[i].ent,c.x,c.y,c.z,false,false,false)
			end
		end
		mtemp=true
	end

	RegisterCommand('movetemplate', function()
		mtemp=true
	end)

	local mModeTemp = false

	CreateThread(function()
		while true do
			Wait(10)
			if not mtemp or not template[1] or not allow then
				Wait(200)
			else
				DisableControlAction(1,243,true)
				if IsDisabledControlJustPressed(1,243) then
					mModeTemp=not mModeTemp
				end
				if mModeTemp then
					DisableControlAction(1,172,true)
					DisableControlAction(1,173,true)
					DisableControlAction(1,174,true)
					DisableControlAction(1,175,true)
					DisableControlAction(1,32,true)
					DisableControlAction(1,33,true)
					DisableControlAction(1,44,true)
					DisableControlAction(1,46,true)
					local curEnt = template[1].ent
					DrawXYZGraphFromEntity(curEnt)
					TaskStandStill(PlayerPedId(),100)
					if IsDisabledControlPressed(1,172) then
						local offset = GetOffsetFromEntityInWorldCoords(curEnt, 0.0, spd, 0.0)
						MoveTemplate(offset)
					elseif IsDisabledControlPressed(1,173) then
						local offset = GetOffsetFromEntityInWorldCoords(curEnt, 0.0, -spd, 0.0)
						MoveTemplate(offset)
					end
					if IsDisabledControlPressed(1,174) then
						local offset = GetOffsetFromEntityInWorldCoords(curEnt, spd, 0.0, 0.0)
						MoveTemplate(offset)
					elseif IsDisabledControlPressed(1,175) then
						local offset = GetOffsetFromEntityInWorldCoords(curEnt, -spd, 0.0, 0.0)
						MoveTemplate(offset)
					end
					if IsDisabledControlPressed(1,32) then
						local offset = GetOffsetFromEntityInWorldCoords(curEnt, 0.0, 0.0, spd)
						MoveTemplate(offset)
					elseif IsDisabledControlPressed(1,33) then
						local offset = GetOffsetFromEntityInWorldCoords(curEnt, 0.0, 0.0, -spd)
						MoveTemplate(offset)
					end
				else
					local hit, coords, entity = RaycastGameplayCamera(1000.0)
					if hit then
						if not (Peds[entity]or Vehicles[entity]or Objects[entity]) then
							MoveTemplate(coords)
						end
					end
				end
				if IsControlJustPressed(1,191)then
					mtemp = false
				end
			end
		end
	end)

	function SetEntityScope(scope,ent,p)
		if ent then
			EntitySetAs[ent]=scope
		elseif not p then
			for k,v in pairs(Peds)do
				EntitySetAs[v] = scope
			end
			for k,v in pairs(Vehicles)do
				EntitySetAs[v] = scope
			end
			for k,v in pairs(Objects)do
				EntitySetAs[v] = scope
			end
		end
	end

	RegisterNUICallback('TempSelected', function(data)
		if data.id == 'set_network' then
			SetEntityScope(true)
			defaultScope=true
		elseif data.id == 'set_local' then
			SetEntityScope(false)
			defaultScope=false
		elseif data.id == 'set_network_c' then
			SetEntityScope(true,curEnt,true)
		elseif data.id == 'set_local_c' then
			SetEntityScope(false,curEnt,true)
		end
		SendDebugData('network', '<span '..(EntitySetAs[curEnt] and 'class="green">Yes'or'class="red">No')..'</span>')
	end)

	local awt = {}

	RegisterNUICallback('decompress', function(data)
		if awt[1] then
			awt[2]=data.data
			awt[1]:resolve(true)
		end
	end)

	local function Decompress(data)
		local prm = promise:new()
		awt[1]=prm
		SendNUIMessage({
			type='decompress',
			data=data
		})
		Citizen.Await(prm)
		awt[1]=nil
		local data=awt[2]
		awt[2]=nil
		return data
	end

	local function LoadScene(data)
		if data.lang then
			for k,v in pairs(data)do
				if tonumber(k)then
					if v.type=='Ped'then
						local ped = Citizen.CreatePed(v.pos.x, v.pos.y, v.pos.z, v.heading, v.model, (v.network~=nil and v.network~=false))
						SetEntityCoordsNoOffset(ped,v.pos.x, v.pos.y, v.pos.z, false, false, false)
						Peds[ped]=ped
						FreezeEntityPosition(ped,true)
					elseif v.type=='Veh'then
						local veh = Citizen.CreateVehicle(v.pos.x, v.pos.y, v.pos.z, v.heading, v.model, (v.network~=nil and v.network~=false))
						SetEntityCoordsNoOffset(veh,v.pos.x, v.pos.y, v.pos.z, false, false, false)
						Vehicles[veh]=veh
						FreezeEntityPosition(veh,true)
					elseif v.type=='Obj'then
						local obj = Citizen.CreateObject(v.pos.x, v.pos.y, v.pos.z, v.model, (v.network~=nil and v.network~=false))
						SetEntityCoordsNoOffset(obj,v.pos.x, v.pos.y, v.pos.z, false, false, false)
						Objects[obj]=obj
						SetEntityRotation(obj,v.rot.x,v.rot.y,v.rot.z,false,true)
						FreezeEntityPosition(obj,true)
					end
				end
			end
		else
			for i=1,#data do
				if data[i].type=='Ped'then
					local ped = Citizen.CreatePed(data[i].pos.x, data[i].pos.y, data[i].pos.z, data[i].heading, data[i].model, (data[i].network~=nil and data[i].network~=false))
					SetEntityCoordsNoOffset(ped,data[i].pos.x, data[i].pos.y, data[i].pos.z, false, false, false)
					Peds[ped]=ped
					FreezeEntityPosition(ped,true)
				elseif data[i].type=='Veh'then
					local veh = Citizen.CreateVehicle(data[i].pos.x, data[i].pos.y, data[i].pos.z, data[i].heading, data[i].model, (data[i].network~=nil and data[i].network~=false))
					SetEntityCoordsNoOffset(veh,data[i].pos.x, data[i].pos.y, data[i].pos.z, false, false, false)
					Vehicles[veh]=veh
					FreezeEntityPosition(veh,true)
				elseif data[i].type=='Obj'then
					local obj = Citizen.CreateObject(data[i].pos.x, data[i].pos.y, data[i].pos.z, data[i].model, (data[i].network~=nil and data[i].network~=false))
					SetEntityCoordsNoOffset(obj,data[i].pos.x, data[i].pos.y, data[i].pos.z, false, false, false)
					Objects[obj]=obj
					SetEntityRotation(obj,data[i].rot.x,data[i].rot.y,data[i].rot.z,false,true)
					FreezeEntityPosition(obj,true)
				end
			end
		end
	end

	RegisterNetEvent('Scene_creator:load_session', function(data)
		if data then
			SendDebugData('id',SceneId)
			crt=true
			if json.decode(data)then
				LoadScene(json.decode(data))
			else
				LoadScene(json.decode(Decompress(data)))
			end
		end
	end)

	RegisterNetEvent('Scene_creator:saveScene', function()
		if crt and Config.SaveDefault then
			TriggerServerEvent('Scene_creator:save_session',GetCurrentData(Config.SaveSpace),Config.SaveSpace)
			Wait(10)
			SendNotification('Saved Scene With '..#DataFunc()..' Entities')
		end
	end)

	RegisterNetEvent('Scene_creator:createdscene', function(name)
		name=name:gsub('.txt',''):gsub('UNSC','')
		print("Scene ID:",name)
		SceneId=name
		SendDebugData('id',SceneId)
	end)

	RegisterCommand('scenedeleteall', function()
		if crt then
			DebugDeleteAll()
			for k,v in pairs(Peds)do
				Peds[k] = nil
				DeleteNetworkedEntity(v)
			end
			for k,v in pairs(Vehicles)do
				Vehicles[k] = nil
				DeleteNetworkedEntity(v)
			end
			for k,v in pairs(Objects)do
				Objects[k] = nil
				DeleteNetworkedEntity(v)
			end
			crt=false
			template={}
			TriggerServerEvent('Scene_creator:unload')
		else
			DebugDeleteAll()
			for k,v in pairs(Peds)do
				Peds[k] = nil
				DeleteNetworkedEntity(v)
			end
			for k,v in pairs(Vehicles)do
				Vehicles[k] = nil
				DeleteNetworkedEntity(v)
			end
			for k,v in pairs(Objects)do
				Objects[k] = nil
				DeleteNetworkedEntity(v)
			end
			template={}
		end
		EntitySetAs={}
	end)
	RegisterNUICallback('admin', function(data)
		if data.data then
			if data.data == 'AD_VS' then
				TriggerServerEvent('Scene_creator:loadFiles', false)
			elseif data.data == 'AD_MF' then
				TriggerServerEvent('Scene_creator:loadFiles', true)
			end
		end
	end)
	RegisterNetEvent('Scene_creator:loadFiles', function(data,is)
		SendNUIMessage({
			type="admin",
			data=data,
			is=is
		})
	end)
	RegisterNUICallback('adminselected', function(data)
		if data.command == 'remove_file'or data.command == 'see_content'then
			TriggerServerEvent('Scene_creator:manageFile', data.command, data.file)
		else
			TriggerServerEvent('Scene_creator:manageScene', data.command, data.file)
		end
	end)
	RegisterNUICallback('setscenedata', function(data)
		TriggerServerEvent('Scene_creator:setSceneData', data.file, data.data)
	end)
	RegisterNetEvent('Scene_creator:manageFile', function(data)
		SendNotification('Peds: '..data.Ped..'; Vehs: '..data.Veh..'; Objs: '..data.Obj..'; All: '..data.Ent)
	end)
	local admin = false
	RegisterNetEvent('Scene_creator:openAdmin', function()
		admin=not admin
		SendNUIMessage({
			type='showadmin',
			show=admin
		})
		SetNuiFocus(admin,admin)
	end)
	RegisterNUIListener('nuioff', function()
		admin=false
	end)
end)