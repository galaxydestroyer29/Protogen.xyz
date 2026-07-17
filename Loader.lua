
-- === protogen.xyz Frontend Loader ===
print("Frontend busted in my ass successfully!")

local success, err = pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/galaxydestroyer29/Protogen.xyz/refs/heads/main/UI.lua", true))()
end)

if success then
    print("protogen.xyz ready.")
else
    warn("Frontend didnt bust. Not horny, send error to dev: " .. tostring(err))
end
