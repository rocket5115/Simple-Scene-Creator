local files = {}
local allow = {}
local resource = GetCurrentResourceName()

RegisterCommand('allowscene', function(source)
    allow[source] = Admin(source)
    TriggerClientEvent('Scene_creator:allow',source,allow[source])
end)

RegisterNetEvent('Scene_creator:requestAdmin', function()
    local src = source
    if Config.ScenesOnlyByAdmin then
        allow[src] = Admin(src)
    else
        allow[src]=not allow[src]
    end
    print(Admin(src))
    TriggerClientEvent('Scene_creator:allow',src,allow[src])
end)

RegisterNetEvent('Scene_creator:create_session', function(arg)
    local src = source
    if files[src]or not allow[src] then
        return
    else
        local file = ('UNSC'..(arg or math.random(99999))..'.txt')
        SaveResourceFile(resource, './projects/'..file,'[]',-1)
        files[src] = file
        TriggerClientEvent('Scene_creator:createdscene', src, file)
    end
end)

RegisterNetEvent('Scene_creator:save_session', function(data,compressed)
    local src = source
    if not files[src]or not allow[src] then
        return
    else
        SaveResourceFile(resource,'./projects/'..files[src],data,-1)
    end
end)

RegisterNetEvent('Scene_creator:load_session', function(id)
    local src = source
    if not allow[src] then
        return
    end
    local proj = LoadResourceFile(resource,'./projects/UNSC'..id..'.txt')
    if proj then
        files[src]='UNSC'..id..'.txt'
        TriggerClientEvent('Scene_creator:load_session', src, proj)
    else
        TriggerClientEvent('Scene_creator:load_session', src, false)
    end
end)

RegisterNetEvent('Scene_creator:unload', function()
    local src = source
    if not allow[src] then
        return
    end
    if files[src] then
        files[src]=nil
    end
end)

RegisterNetEvent('Scene_creator:save_template', function(data)
    local src = source
    if not allow[src] then
        return
    end
    if files[src] then
        local f = files[src]:gsub('UNSC','UNSCTEMP')
        SaveResourceFile(resource,'./projects/'..f,data,-1)
    end
end)

RegisterNetEvent('Scene_creator:load_template', function(id)
    local src = source
    if not allow[src] then
        return
    end
    local proj = LoadResourceFile(resource,'./projects/UNSCTEMP'..id..'.txt')
    if proj then
        TriggerClientEvent('Scene_creator:load_template', src, proj)
    end
end)

local function CreateBucketPed(x,y,z,h,model)
    model = (type(model)=='number'and model or GetHashKey(model))
    local ent = CreatePed(1,model,x,y,z,h,true,false)
    return ent
end

local function CreateBucketVehicle(x,y,z,h,model)
    model = (type(model)=='number'and model or GetHashKey(model))
    local ent = Citizen.InvokeNative(`CREATE_AUTOMOBILE`, `blista`, x,y,z,h)
    return ent
end

local function CreateBucketObject(x,y,z,model)
    model = (type(model)=='number'and model or GetHashKey(model))
    local ent = CreateObjectNoOffset(model, x,y,z, true, false, false)
    return ent
end

Citizen.CreatePed = CreateBucketPed
Citizen.CreateVehicle = CreateBucketVehicle
Citizen.CreateObject = CreateBucketObject

local loadedScenes = {}
local scenebuckets = {}

function LoadSceneBucket(id)
    if id then
        if loadedScenes[id] then
            return
        end
        local res = LoadResourceFile(resource,'./projects/UNSC'..id..'.txt')
        if not res then
            print('^1Scene: '..id..' does not exist^7')
            return
        end
        local data = json.decode(res)
        if not data then
            print('^1Scene File Cannot Be Compressed!^7')
            return
        end
        local id = id
        loadedScenes[id]={}
        scenebuckets[id]=0
        local objs,vehs,peds = GetAllObjects(),GetAllVehicles(),GetAllPeds()
        for k,v in pairs(data)do
            if tonumber(k)then
                if v.type=='Ped'then
                    local vec = vector3(v.pos.x,v.pos.y,v.pos.z)
                    for i=1,#peds do
                        if v.model==GetEntityModel(peds[i]) and #(vec-GetEntityCoords(peds[i]))<10.0 then
                            DeleteEntity(peds[i])
                        end
                    end
                elseif v.type=='Veh' then
                    local vec = vector3(v.pos.x,v.pos.y,v.pos.z)
                    for i=1,#vehs do
                        if v.model==GetEntityModel(vehs[i]) and #(vec-GetEntityCoords(vehs[i]))<10.0 then
                            DeleteEntity(vehs[i])
                        end
                    end
                elseif v.type=='Obj' then
                    local vec = vector3(v.pos.x,v.pos.y,v.pos.z)
                    for i=1,#objs do
                        if v.model==GetEntityModel(objs[i]) and #(vec-GetEntityCoords(objs[i]))<10.0 then
                            DeleteEntity(objs[i])
                        end
                    end
                end
            end
        end
        for k,v in pairs(data)do
            if tonumber(k)then
                if v.type=='Ped'then
                    local ped = Citizen.CreatePed(v.pos.x, v.pos.y, v.pos.z-1.0, v.heading, v.model)
                    SetEntityCoords(ped,v.pos.x, v.pos.y, v.pos.z-1.0, false, false, false)
                    FreezeEntityPosition(ped,true)
                    loadedScenes[id][ped]=ped
                elseif v.type=='Veh'then
                    local veh = Citizen.CreateVehicle(v.pos.x, v.pos.y, v.pos.z, v.heading, v.model)
                    SetEntityCoords(veh,v.pos.x, v.pos.y, v.pos.z, false, false, false)
                    FreezeEntityPosition(veh,true)
                    loadedScenes[id][veh]=veh
                elseif v.type=='Obj'then
                    local obj = Citizen.CreateObject(v.pos.x, v.pos.y, v.pos.z, v.model)
                    SetEntityRotation(obj,v.rot.x,v.rot.y,v.rot.z,false,true)
                    FreezeEntityPosition(obj,true)
                    loadedScenes[id][obj]=obj
                end
            end
        end
        print('^2Loaded Scene: ^7'..id)
    end
end

function DeleteScene(id)
    if loadedScenes[id] then
        for k,v in pairs(loadedScenes[id]) do
            DeleteEntity(v)
        end
    else
        local res = LoadResourceFile(resource,'./projects/UNSC'..id..'.txt')
        if not res then
            print('^1Scene: '..id..' does not exist^7')
            return
        end
        local data = json.decode(res)
        if not data then
            print('^1Scene File Cannot Be Compressed!^7')
            return
        end
        local objs,vehs,peds = GetAllObjects(),GetAllVehicles(),GetAllPeds()
        for k,v in pairs(data)do
            if tonumber(k)then
                if v.type=='Ped'then
                    local vec = vector3(v.pos.x,v.pos.y,v.pos.z)
                    for i=1,#peds do
                        if v.model==GetEntityModel(peds[i]) and #(vec-GetEntityCoords(peds[i]))<10.0 then
                            DeleteEntity(peds[i])
                        end
                    end
                elseif v.type=='Veh' then
                    local vec = vector3(v.pos.x,v.pos.y,v.pos.z)
                    for i=1,#vehs do
                        if v.model==GetEntityModel(vehs[i]) and #(vec-GetEntityCoords(vehs[i]))<10.0 then
                            DeleteEntity(vehs[i])
                        end
                    end
                elseif v.type=='Obj' then
                    local vec = vector3(v.pos.x,v.pos.y,v.pos.z)
                    for i=1,#objs do
                        if v.model==GetEntityModel(objs[i]) and #(vec-GetEntityCoords(objs[i]))<10.0 then
                            DeleteEntity(objs[i])
                        end
                    end
                end
            end
        end
        print('^2Removed Scene: ^7'..id)
    end
end

RegisterCommand('removescenebucket', function(source,args)
    if source == 0 then
        DeleteScene(args[1])
    end
end)

RegisterCommand('setscenebucket', function(source,args)
    if source==0 then
        SetSceneBucket(args[1],args[2])
    end
end)

RegisterCommand('loadscenebucket', function(source,args)
    if source==0 then
        LoadSceneBucket(args[1])
    end
end)

function SetSceneBucket(scene,id)
    if scene and id and loadedScenes[scene] and tonumber(id) then
        id = tonumber(id)
        scenebuckets[id]=id
        for k,v in pairs(loadedScenes[scene])do
            SetEntityRoutingBucket(v,id)
        end
    end
end

CreateThread(function()
    for i=1,#PermanentScenes do
        PermanentScenes[i].bucket=PermanentScenes[i].bucket or 0
        LoadSceneBucket(PermanentScenes[i].name)
        SetSceneBucket(PermanentScenes[i].name,PermanentScenes[i].bucket)
    end
end)