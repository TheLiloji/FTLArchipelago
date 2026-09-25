_G.apCoverage = { calls = {}, names = {} }

do
    local wrapped = {}
    for name, value in pairs(_G) do
        if type(name) == "string" and type(value) == "function"
            and name:match("^ap[A-Z]") and not name:match("ForTesting$") then
            wrapped[name] = value
        end
    end

    for name, original in pairs(wrapped) do
        _G.apCoverage.calls[name] = 0
        _G.apCoverage.names[#_G.apCoverage.names + 1] = name
        _G[name] = function(...)
            _G.apCoverage.calls[name] = _G.apCoverage.calls[name] + 1
            return original(...)
        end
    end
    table.sort(_G.apCoverage.names)
end
