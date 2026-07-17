
-- protogen.xyz Frontend Loader (safer)
print("Frontend busted in my ass successfully!")

local url = "https://raw.githubusercontent.com/galaxydestroyer29/Protogen.xyz/refs/heads/main/UI.lua"

local success, response = pcall(function()
    return game:HttpGet(url, true)
end)

if success and response then
    local loadSuccess, loadErr = pcall(function()
        loadstring(response)()
    end)
    
    if loadSuccess then
        print("protogen.xyz ready.")
    else
        warn("Frontend didnt bust. Not horny, send error to dev: " .. tostring(loadErr))
    end
else
    warn("Failed to fetch script: " .. tostring(response))
end
