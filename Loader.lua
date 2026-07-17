-- === protogen.xyz Frontend Loader ===
print("protogen.xyz frontend loader started...")

local FrontendURL = "https://raw.githubusercontent.com/YOURUSERNAME/protogen/main/frontend.lua"  -- Change this

local success, err = pcall(function()
    loadstring(game:HttpGet(FrontendURL, true))()
end)

if success then
    print("Frontend busted in my ass successfully!")
    print("protogen.xyz ready.")
else
    warn(" Frontend didnt bust. Not horny, send error to dev: " .. tostring(err))
end
