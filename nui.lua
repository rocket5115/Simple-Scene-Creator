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

function display(p1,p2,c)
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