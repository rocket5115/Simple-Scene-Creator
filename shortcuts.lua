Shortcuts = {}

function RegisterShortcut(command,keys) --All Shortcuts are NUI oriented by default
    keys = (type(keys)~='table'and{keys})or keys
    local res = {
        command = command
    }
    for i=1,#keys do
        res[#res+1]={
            key = keys[i],
            debug = print(keys[i])
        }
    end
    Shortcuts[#Shortcuts+1]=res
    SendWhenNUIActive({
        type="update_shortcuts",
        data=Shortcuts
    })
end