Translation = {}
function Locale(name,...)
    return (Translation[Config.Language or"en"][name]or""):format(...)
end
Translate = Locale