
local rawUrl = "https://raw.githubusercontent.com/galaxydestroyer29/Protogen.xyz/refs/heads/main/67UIsupercool.lua"

local cacheBypassUrl = rawUrl .. "?t=" .. tostring(tick())

local success, result = pcall(function()
    return loadstring(game:HttpGet(cacheBypassUrl))()
end)

if not success then
    warn("Failed to load script: " .. tostring(result))
end
