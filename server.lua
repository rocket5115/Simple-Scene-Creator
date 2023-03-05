files = {}
allow = {}
resource = GetCurrentResourceName()
function scandir(directory)
    local i, t = 0, {}
    local pfile = io.popen('dir "'..directory..'" /b')
    for filename in pfile:lines() do
        i = i + 1
        t[i] = filename
    end
    pfile:close()
    return t
end

local function scdir(dir)
    for dir in io.popen('ls -pa '..dir..' | grep -v /'):lines() do print(dir) end
end

RegisterNetEvent('Scene_creator:requestAdmin', function()
    local src = source
    if Config.ScenesOnlyByAdmin then
        allow[src] = Admin(src)
    else
        allow[src]=not allow[src]
    end
    TriggerClientEvent('Scene_creator:allow',src,allow[src])
end)

RegisterNetEvent('Scene_creator:create_session', function(arg)
    local src = source
    if not Admin(src)then
        SendChatError(src,'~r~You Do Not have Proper Permissions!')
        return
    end
    if files[src]or not allow[src] then
        return
    else
        local file = ('UNSC'..(arg or math.random(99999))..'.txt')
        SaveResourceFile(resource, './projects/'..file,'[]',-1)
        files[src] = file
        TriggerClientEvent('Scene_creator:createdscene', src, file)
    end
end)

RegisterNetEvent('Scene_creator:save_session', function(data)
    local src = source
    if not Admin(src)then
        SendChatError(src,'~r~You Do Not have Proper Permissions!')
        return
    end
    if not files[src]or not allow[src] then
        return
    else
        SaveResourceFile(resource,'./projects/'..files[src],data,-1)
    end
end)

RegisterNetEvent('Scene_creator:load_session', function(id)
    local src = source
    if not Admin(src)then
        SendChatError(src,'~r~You Do Not have Proper Permissions!')
        return
    end
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
    if not Admin(src)then
        SendChatError(src,'~r~You Do Not have Proper Permissions!')
        return
    end
    if not allow[src] then
        return
    end
    if files[src] then
        files[src]=nil
    end
end)

RegisterNetEvent('Scene_creator:save_template', function(data)
    local src = source
    if not Admin(src)then
        SendChatError(src,'~r~You Do Not have Proper Permissions!')
        return
    end
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
    if not Admin(src)then
        SendChatError(src,'~r~You Do Not have Proper Permissions!')
        return
    end
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
        local ents = 0
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
                ents=ents+1
            end
        end
        print('^2Loaded Scene: ^7'..id..' ^2With '..ents..' Entities!^7')
    end
end

function DeleteScene(id)
    if loadedScenes[id] then
        for k,v in pairs(loadedScenes[id]) do
            if DoesEntityExist(v) then
                DeleteEntity(v)
            end
        end
        loadedScenes[id]=nil
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

function SetSceneBucket(scene,id)
    if scene and id and loadedScenes[scene] and tonumber(id) then
        id = tonumber(id)
        scenebuckets[id]=id
        for k,v in pairs(loadedScenes[scene])do
            if DoesEntityExist(v) then
                SetEntityRoutingBucket(v,id)
            else
                loadedScenes[scene][k]=nil
            end
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

RegisterNetEvent('Scene_creator:loadFiles', function(is)
    local src = source
    if not Admin(src) then
        SendChatError(src,'~r~You Do Not have Proper Permissions!')
        return
    end
    if is then
        TriggerClientEvent('Scene_creator:loadFiles', src, scandir(GetResourcePath(resource)..'/projects'), is)
    else
        local files = scandir(GetResourcePath(resource)..'/projects')
        local retval = {}
        for i=1,#files do
            if files[i]:find('UNSC')then
                local n = files[i]:gsub('UNSC','')
                n=n:gsub('.txt','')
                retval[#retval+1]={name=n,temp=files[i]:find('TEMP')}
            end
        end
        TriggerClientEvent('Scene_creator:loadFiles', src, retval, is)
    end
end)

local function SendChatError(src,msg,color)
    TriggerClientEvent('chat:addMessage', src, {
        color = (color or{255,0,0}),
        multiline = true,
        args = {'Scenes Creator', msg}
    })
end

RegisterNetEvent('Scene_creator:manageFile', function(cmd,file)
    local src = source
    if not Admin(src)then
        SendChatError(src,'~r~You Do Not have Proper Permissions!')
        return
    end
    if cmd == 'remove_file' then
        if not HasFullPerms(src) then
            SendChatError(src,'~r~You Do Not have Proper Permissions!')
            return
        end
        local name = file:gsub('UNSC','')
        name=name:gsub('.txt','')
        if loadedScenes[name] then
            SendChatError(src,'Scene from file: ~r~'..file..' ~w~Is Currently Loaded!')
        end
        for k,v in pairs(files)do
            if v==file then
                SendChatError(src,'Scene from file: ~r~'..file..' ~w~Is Currently Loaded!')
                CancelEvent()
                return
            end
        end
        os.remove(GetResourcePath(resource)..'/projects/'..file)
        TriggerClientEvent('Scene_creator:loadFiles', src, scandir(GetResourcePath(resource)..'/projects'), true)
        SendChatError(src,'Removed File: ~g~'..file,{0,255,0})
    elseif cmd == 'see_content' then
        local file = LoadResourceFile(resource,'./projects/'..file)
        if file then
            local data = json.decode(file)
            if not data then
                SendChatError(src,'~r~File Compressed')
            else
                local summary = {
                    Ped = 0,
                    Veh = 0,
                    Obj = 0,
                    Ent = 0
                }
                for k,v in pairs(data)do
                    if tonumber(k)then
                        summary[v.type]=summary[v.type]+1
                        summary.Ent = summary.Ent+1
                    end
                end
                TriggerClientEvent('Scene_creator:manageFile', src, summary)
            end
        else
            SendChatError(src,'~r~File Not Found')
        end
    end
end)

local function SearchScenes(id)
    for _,v in pairs(files)do
        if v:find(id)then
            return true
        end
    end
    for k in pairs(loadedScenes)do
        if k:find(id)then
            return true
        end
    end
    return false
end

RegisterNetEvent('Scene_creator:manageScene', function(cmd,file)
    local src = source
    if not Admin(src)then
        SendChatError(src,'~r~You Do Not have Proper Permissions!')
        return
    end
    if cmd=='load_scene' then
        local is = SearchScenes(file)
        if is then
            SendChatError(src,'~r~Scene Is Already Loaded!')
            return
        else
            LoadSceneBucket(file)
        end
    elseif cmd=='go_to' then
        local exists = false
        for k,v in ipairs(scandir(GetResourcePath(resource)..'/projects'))do
            if v:find(file)then
                exists = v
                break
            end
        end
        if not exists then
            SendChatError(src,'~r~File Does Not Exist!')
            return
        end
        local file = LoadResourceFile(resource,'./projects/'..exists)
        local data = json.decode(file)
        if not data then
            SendChatError(src,'~r~File Compressed')
            return
        end
        local first_place = (data[1]or data["1"])
        if not first_place then
            SendChatError(src,'~r~Scene Is Empty!')
            return
        end
        SetEntityCoords(GetPlayerPed(src),first_place.pos.x, first_place.pos.y, first_place.pos.z+2.0,false,false)
    elseif cmd=='unload_scene' then
        DeleteScene(file)
    end
end)

RegisterNetEvent('Scene_creator:setSceneData', function(file,data)
    local src = source
    if not Admin(src)then
        SendChatError(src,'~r~You Do Not have Proper Permissions!')
        return
    end
    local is = not SearchScenes(file)
    if is then
        SendChatError(src,'~r~Scene Is Not Loaded!')
        return
    end
    for name,value in pairs(data) do
        if name=='bucket'then
            SetSceneBucket(file,tonumber(value)or 0)
        end
    end
end)