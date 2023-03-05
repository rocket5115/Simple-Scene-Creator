local actives = {}
local args = {}
local NUILoaded = false
local registeredcbs = {}
Citizen.RegisterNUICallback = RegisterNUICallback
local function RCN(name,cb)
    registeredcbs[name]={}
    Citizen.RegisterNUICallback(name, function(data,ret)
        cb(data,ret)
        for i=1,#registeredcbs[name] do
            registeredcbs[name][i](data)
        end
    end)
end

RegisterNUICallback = RCN

function SendWhenNUIActive(data,...)
    if(type(data)~='function')then
        if NUILoaded then
            SendNUIMessage(data)
        else
            actives[#actives+1]=data
        end
    else
        if NUILoaded then
            data(...)
        else
            actives[#actives+1]=data
            args[#actives]={...}
        end
    end
end

RegisterNUICallback('loaded', function()
    NUILoaded = true
end)

CreateThread(function()
    local requested = 0
    while not NUILoaded and requested<50 do
        Wait(10)
        requested=requested+1
    end
    NUILoaded=true
    for i=1,#actives do
        if(type(actives[i])~='function')then
            SendNUIMessage(actives[i])
        else
            actives[i](table.unpack(args[i]))
        end
    end
    actives = nil
    args = nil
end)

local nuion = false

function display(p1,p2)
    nuion=p1
    if p2 then
        SetNuiFocus(false,false)
        SetNuiFocusKeepInput(true)
    else
        SetNuiFocusKeepInput(false)
        SetNuiFocus(p1,p1)
    end
    SendNUIMessage({
        type='show',
        status=nuion
    })
end



function RegisterNUIListener(name,cb)
    registeredcbs[name]=registeredcbs[name]or{}
    registeredcbs[name][#registeredcbs[name]+1]=cb
end

function IsNUIActive()
    return nuion
end

RegisterNUICallback('nuioff', function()
    display(false,false)
end)

function ShowNotification(data)
    SendNUIMessage({
        type='addnotif',
        data="<div>"..data.."</div>"
    })
end

function SendDebugData(name,data)
    data=data or''
    data=tostring(data)
    if data~=''then
        data=(data:find('span')and data or'<span>'..data..'</span>')
    end
    SendNUIMessage({
        type='debug',
        name=name,
        data=data,
        show=data~=''
    })
end

function DebugDeleteAll()
    SendNUIMessage({
        type='debugdelete'
    })
end

function SendNotification(data)
    SendNUIMessage({
        type='addnotif',
        data=data
    })
end

local commands = {}

function RegisterKeybind(command,keys)
    commands[command] = {}
    for i=1,#keys do
        commands[command][keys[i]]=false
        RegisterCommand('KeyPressed'..keys[i],function()
            print(keys[i])
            for k,v in pairs(commands)do
                if not v[keys[i]]then
                    v[keys[i]]=true
                    local ret = true
                    for k,v in pairs(v)do
                        if not v then
                            ret=false
                            break
                        end
                    end
                    if ret then
                        ExecuteCommand(k)
                    end
                    Citizen.SetTimeout(200,function()
                        v[keys[i]]=false
                    end)
                end
            end
        end)
        RegisterKeyMapping('KeyPressed'..keys[i],'Key: '..keys[i],'keyboard',keys[i])
    end
end