local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local FatalityUI = {
    Elements = {}, 
    Connections = {},
    HiddenGUI = nil,
    Theme = {
        Background    = Color3.fromRGB(10, 10, 12),
        TabSection    = Color3.fromRGB(16, 16, 20),
        Outline       = Color3.fromRGB(242, 143, 173), -- Pastel Light Pink
        GroupOutline  = Color3.fromRGB(242, 143, 173), 
        Accent        = Color3.fromRGB(242, 143, 173),
        BrightRed     = Color3.fromRGB(255, 65, 65), 
        Text          = Color3.fromRGB(255, 255, 255),
        TextMuted     = Color3.fromRGB(175, 155, 160),
        TabHover      = Color3.fromRGB(28, 22, 25)
    }
}

-- // UI Configuration State Storage
local CheatState = {
    YawHallucination = false,
    YawSpeed = 1,
    NoLegs = false,
    NoLimbs = false,
    Bury = false,
    LayDown = false,
    Flip = false,
    CartelLimbSep = {
        Vertical = 0,
        Horizontal = 0
    },
    Rage = {
        BulletManip = false,
        SkyKill = false,
        UndergroundKill = false,
        TeleportKill = false,
        WhileFly = false,
        WhileNoclipped = false,
        WhileFreecammed = false,
        Underground = false,
        WhileResynced = false,
        WhileAntiAimed = false
    },
    Movement = {
        JumpFly = false,
        BHop = false,
        Noclip = false,
        NoFallDamage = false
    },
    Atmosphere = {
        TimeChanger = 12,
        FullBright = false
    },
    Colors = {
        Saturation = 1
    },
    Exploits = {
        SkinChanger = false,
        HandTeleport = false,
        HatID = ""
    },
    Camera = {
        AspectRatio = 1,
        FOV = false,
        FOVVal = 90
    },
    FPS = {
        PotatoMode = false,
        PerformanceMode = false
    }
}

-- Track references to UI elements globally to allow the loader to update them
local UIElements = {}

local function SafeCreateDrawing(type)
    -- Robust drawing check fallback
    local success, obj = pcall(function() 
        if Drawing and Drawing.new then
            return Drawing.new(type) 
        end
        return nil
    end)
    if success and obj then return obj end
    
    -- Silent dummy fallback to prevent execution halts
    local dummy = {}
    local mt = {
        __index = function() return function() end end,
        __newindex = function() end
    }
    setmetatable(dummy, mt)
    return dummy
end

-- Track elements that should pulse with RGB color effects
local RGBCallbacks = {}

function FatalityUI:CreateWindow(position, size)
    local Window = {
        Position = position,
        MiniPosition = Vector2.new(100, 200), 
        Size = size,
        Tabs = {},
        CurrentTab = nil,
        Minimized = false,
        AllDrawings = {},
        AllUI = {}
    }

    local uiContainer = Instance.new("ScreenGui")
    uiContainer.Name = "ProtogenMobileOverlay_" .. tostring(math.random(1000, 9999))
    uiContainer.IgnoreGuiInset = true 
    uiContainer.ResetOnSpawn = false
    
    -- Safe UI Parent execution tree
    local parentSuccess = pcall(function() uiContainer.Parent = CoreGui end)
    if not parentSuccess then 
        local localPlayer = Players.LocalPlayer
        if not localPlayer then
            pcall(function() localPlayer = Players:GetPropertyChangedSignal("LocalPlayer"):Wait() end)
        end
        
        if localPlayer then
            local playerGui = localPlayer:FindFirstChild("PlayerGui") or localPlayer:WaitForChild("PlayerGui", 5)
            if playerGui then 
                uiContainer.Parent = playerGui 
            else
                uiContainer.Parent = workspace
            end
        else
            uiContainer.Parent = workspace
        end
    end
    self.HiddenGUI = uiContainer

    local function RegisterDrawing(obj, objType, offset1, offset2, isMini, parentTab, isScrollable, groupRef)
        table.insert(self.Elements, obj)
        local entry = {
            Instance = obj, Type = objType, IsMini = isMini or false, ParentTab = parentTab,
            Offset1 = offset1, Offset2 = offset2, VisibleCondition = nil, IsScrollable = isScrollable or false,
            GroupRef = groupRef
        }
        table.insert(Window.AllDrawings, entry)
        return obj, entry
    end

    local function RegisterUI(obj, offset, sizeOffset, isMini, parentTab, isScrollable, groupRef)
        local entry = { 
            Instance = obj, Offset = offset, SizeOffset = sizeOffset, IsMini = isMini or false, 
            ParentTab = parentTab, VisibleCondition = nil, IsScrollable = isScrollable or false,
            GroupRef = groupRef
        }
        table.insert(Window.AllUI, entry)
        return obj, entry
    end

    local bg = RegisterDrawing(SafeCreateDrawing("Square"), "Square", Vector2.new(0,0), size)
    bg.Color = self.Theme.Background; bg.Filled = true

    local title = RegisterDrawing(SafeCreateDrawing("Text"), "Text", Vector2.new((size.X / 2) - 30, 11))
    title.Text = "protogen.xyz"
    title.Color = Color3.fromRGB(255, 255, 255); title.Size = 18; title.Outline = true; title.Font = 2; title.Center = true

    local privateTitle = RegisterDrawing(SafeCreateDrawing("Text"), "Text", Vector2.new((size.X / 2) + 65, 15))
    privateTitle.Text = "(private)"
    privateTitle.Color = self.Theme.TextMuted; privateTitle.Size = 12; privateTitle.Outline = true; privateTitle.Font = 2; privateTitle.Center = true

    local headerLine = RegisterDrawing(SafeCreateDrawing("Square"), "Square", Vector2.new(0, 40), Vector2.new(size.X, 1))
    headerLine.Color = self.Theme.Accent; headerLine.Filled = true

    local tabWidth = math.floor(size.X * 0.3)
    local tabBg = RegisterDrawing(SafeCreateDrawing("Square"), "Square", Vector2.new(0, 41), Vector2.new(tabWidth, size.Y - 41))
    tabBg.Color = self.Theme.TabSection; tabBg.Filled = true

    local tabOutline = RegisterDrawing(SafeCreateDrawing("Square"), "Square", Vector2.new(0, 41), Vector2.new(tabWidth, size.Y - 41))
    tabOutline.Color = self.Theme.Outline; tabOutline.Filled = false; tabOutline.Thickness = 1

    local minBtnText = RegisterDrawing(SafeCreateDrawing("Text"), "Text", Vector2.new(size.X - 25, 10))
    minBtnText.Text = "-"; minBtnText.Color = self.Theme.TextMuted; minBtnText.Size = 22; minBtnText.Outline = true; minBtnText.Font = 2

    local minTouch = RegisterUI(Instance.new("TextButton"), Vector2.new(size.X - 35, 5), Vector2.new(30, 30))
    minTouch.BackgroundTransparency = 1; minTouch.TextTransparency = 1; minTouch.ZIndex = 12; minTouch.Parent = uiContainer

    local mainDragTouch = RegisterUI(Instance.new("TextButton"), Vector2.new(0, 0), Vector2.new(size.X - 40, 40))
    mainDragTouch.BackgroundTransparency = 1; mainDragTouch.TextTransparency = 1; mainDragTouch.ZIndex = 10; mainDragTouch.Parent = uiContainer

    local scrollTouch = RegisterUI(Instance.new("TextButton"), Vector2.new(tabWidth, 41), Vector2.new(size.X - tabWidth, size.Y - 41))
    scrollTouch.BackgroundTransparency = 1; scrollTouch.TextTransparency = 1; scrollTouch.ZIndex = 9; scrollTouch.Parent = uiContainer

    local fCircle = RegisterDrawing(SafeCreateDrawing("Circle"), "Circle", Vector2.new(22, 22), nil, true)
    fCircle.Radius = 22; fCircle.Color = self.Theme.TabSection; fCircle.Filled = true

    local fCircleBorder = RegisterDrawing(SafeCreateDrawing("Circle"), "Circle", Vector2.new(22, 22), nil, true)
    fCircleBorder.Radius = 22; fCircleBorder.Filled = false; fCircleBorder.Thickness = 1; fCircleBorder.Color = self.Theme.Accent

    local fText = RegisterDrawing(SafeCreateDrawing("Text"), "Text", Vector2.new(22, 11), nil, true)
    fText.Text = "P"; fText.Color = Color3.fromRGB(255, 255, 255); fText.Size = 22; fText.Outline = true; fText.Font = 2; fText.Center = true

    local miniTouch = RegisterUI(Instance.new("TextButton"), Vector2.new(0, 0), Vector2.new(44, 44), true)
    miniTouch.BackgroundTransparency = 1; miniTouch.TextTransparency = 1; miniTouch.ZIndex = 15; miniTouch.Parent = uiContainer

    function Window:Refresh()
        local scrollOffset = self.CurrentTab and Vector2.new(0, self.CurrentTab.ScrollY) or Vector2.new(0, 0)
        local canvasTop = self.Position.Y + 41
        local canvasBottom = self.Position.Y + self.Size.Y

        if self.CurrentTab then
            local padding = 12
            local textHeightOffset = 18
            local currentColumnY = { [1] = 12, [2] = 12 }

            for _, group in ipairs(self.CurrentTab.Groupboxes) do
                local col = group.ColumnIndex
                local boxY = 41 + currentColumnY[col] + textHeightOffset
                group.ComputedBoxY = boxY
                
                local activeHeight = 15
                for _, elem in ipairs(group.Elements) do
                    if elem.VisibleCondition == nil or elem.VisibleCondition() then
                        activeHeight = activeHeight + elem.HeightCost
                    end
                end
                group.ComputedHeight = math.max(activeHeight, 40)
                currentColumnY[col] = currentColumnY[col] + group.ComputedHeight + padding + textHeightOffset
            end
            local maxContentHeight = math.max(currentColumnY[1], currentColumnY[2])
            self.CurrentTab.MaxScroll = maxContentHeight > (size.Y - 41) and (maxContentHeight - (size.Y - 41) + 20) or 0
            self.CurrentTab.ScrollY = math.clamp(self.CurrentTab.ScrollY, -self.CurrentTab.MaxScroll, 0)
        end

        for _, d in ipairs(self.AllDrawings) do
            pcall(function()
                if self.Minimized then
                    d.Instance.Visible = d.IsMini
                    if d.IsMini then d.Instance.Position = self.MiniPosition + d.Offset1 end
                else
                    if d.IsMini then d.Instance.Visible = false
                    elseif d.ParentTab == nil or d.ParentTab == self.CurrentTab then
                        if d.VisibleCondition and not d.VisibleCondition() then d.Instance.Visible = false
                        else
                            local baseOffset = d.Offset1
                            local calculatedSize = d.Offset2
                            if d.GroupRef then
                                local group = d.GroupRef
                                if d.IsGroupHeader then baseOffset = Vector2.new(baseOffset.X, group.ComputedBoxY - 18)
                                elseif d.IsGroupBorder then
                                    baseOffset = Vector2.new(baseOffset.X, group.ComputedBoxY)
                                    calculatedSize = Vector2.new(calculatedSize.X, group.ComputedHeight)
                                else
                                    local currentInnerY = 10
                                    for _, elem in ipairs(group.Elements) do
                                        local matched = false
                                        for _, entry in ipairs(elem.DrawingEntries) do if entry == d then matched = true break end end
                                        if matched then
                                            baseOffset = Vector2.new(baseOffset.X, group.ComputedBoxY + currentInnerY + d.InnerElementYOffset)
                                            break
                                        end
                                        if elem.VisibleCondition == nil or elem.VisibleCondition() then currentInnerY = currentInnerY + elem.HeightCost end
                                    end
                                end
                            end
                            local finalPos = self.Position + baseOffset
                            if d.IsScrollable then finalPos = finalPos + scrollOffset end
                            local dynamicElementHeight = d.Type == "Square" and calculatedSize.Y or (d.Instance.Size or 14)
                            if d.IsScrollable and (finalPos.Y < canvasTop or (finalPos.Y + dynamicElementHeight) > canvasBottom - 3) then d.Instance.Visible = false
                            else
                                d.Instance.Visible = true; d.Instance.Position = finalPos
                                if d.Type == "Square" then d.Instance.Size = calculatedSize end
                            end
                        end
                    else d.Instance.Visible = false end
                end
            end)
        end

        for _, ui in ipairs(self.AllUI) do
            pcall(function()
                if self.Minimized then
                    ui.Instance.Visible = ui.IsMini
                    if ui.IsMini then
                        ui.Instance.Position = UDim2.new(0, self.MiniPosition.X + ui.Offset.X, 0, self.MiniPosition.Y + ui.Offset.Y)
                        ui.Instance.Size = UDim2.new(0, ui.SizeOffset.X, 0, ui.SizeOffset.Y)
                    end
                else
                    if ui.IsMini then ui.Instance.Visible = false
                    elseif (ui.ParentTab == nil or ui.ParentTab == self.CurrentTab) and (not ui.VisibleCondition or ui.VisibleCondition()) then
                        local finalYOffset = ui.Offset.Y
                        if ui.GroupRef then
                            local group = ui.GroupRef
                            local currentInnerY = 10
                            for _, elem in ipairs(group.Elements) do
                                if elem.UIEntry == ui then finalYOffset = group.ComputedBoxY + currentInnerY + ui.InnerElementYOffset end
                                if elem.VisibleCondition == nil or elem.VisibleCondition() then currentInnerY = currentInnerY + elem.HeightCost end
                            end
                        end
                        local finalY = self.Position.Y + finalYOffset
                        if ui.IsScrollable then finalY = finalY + scrollOffset.Y end
                        if ui.IsScrollable and (finalY < canvasTop or (finalY + ui.SizeOffset.Y) > canvasBottom - 3) then ui.Instance.Visible = false
                        else
                            ui.Instance.Visible = true
                            ui.Instance.Position = UDim2.new(0, self.Position.X + ui.Offset.X, 0, finalY)
                            ui.Instance.Size = UDim2.new(0, ui.SizeOffset.X, 0, ui.SizeOffset.Y)
                        end
                    else ui.Instance.Visible = false end
                end
            end)
        end
    end

    function Window:AddTab(name, iconId)
        local tabIndex = #self.Tabs
        local tabHeight = 45 
        local tabOffset = Vector2.new(0, 41 + (tabIndex * tabHeight))
        local tabBoxSize = Vector2.new(tabWidth, tabHeight)
        local Tab = { Name = name, Groupboxes = {}, ScrollY = 0, MaxScroll = 0 }

        local tBg = RegisterDrawing(SafeCreateDrawing("Square"), "Square", tabOffset, tabBoxSize)
        tBg.Color = FatalityUI.Theme.Background; tBg.Filled = true; tBg.Transparency = 0

        local tAccent = RegisterDrawing(SafeCreateDrawing("Square"), "Square", tabOffset, Vector2.new(3, tabHeight))
        tAccent.Color = FatalityUI.Theme.Accent; tAccent.Filled = true; tAccent.Visible = false
        
        local tText = RegisterDrawing(SafeCreateDrawing("Text"), "Text", tabOffset + Vector2.new(38, 12))
        tText.Text = string.lower(name); tText.Color = FatalityUI.Theme.TextMuted; tText.Size = 18; tText.Outline = true; tText.Font = 2

        local touchButton = RegisterUI(Instance.new("TextButton"), tabOffset, tabBoxSize)
        touchButton.BackgroundTransparency = 1; touchButton.TextTransparency = 1; touchButton.ZIndex = 11; touchButton.Parent = uiContainer

        local iconImage
        if iconId then
            iconImage = Instance.new("ImageLabel")
            iconImage.Position = UDim2.new(0, 12, 0, 12); iconImage.Size = UDim2.new(0, 20, 0, 20); iconImage.BackgroundTransparency = 1
            iconImage.Image = iconId; iconImage.ImageColor3 = FatalityUI.Theme.TextMuted; iconImage.ZIndex = 12; iconImage.Parent = touchButton
        end

        function Tab:AddGroupbox(title, columnIndex)
            local padding = 12
            local boxWidth = math.floor((size.X - tabWidth - (padding * 3)) / 2)
            local boxX = tabWidth + padding
            if columnIndex == 2 then boxX = boxX + boxWidth + padding end
            local Group = { ColumnIndex = columnIndex, Elements = {}, ComputedBoxY = 0, ComputedHeight = 0 }
            table.insert(Tab.Groupboxes, Group)

            local titleDrawing, titleEntry = RegisterDrawing(SafeCreateDrawing("Text"), "Text", Vector2.new(boxX, 0), nil, false, Tab, true, Group)
            titleDrawing.Text = title; titleDrawing.Color = FatalityUI.Theme.Text; titleDrawing.Size = 14; titleDrawing.Outline = true; titleDrawing.Font = 2
            titleEntry.IsGroupHeader = true

            function Group:AddLabel(text)
                local labelOffset = Vector2.new(boxX + 10, 0)
                local label, labelEntry = RegisterDrawing(SafeCreateDrawing("Text"), "Text", labelOffset, nil, false, Tab, true, Group)
                label.Text = text; label.Color = FatalityUI.Theme.Accent; label.Size = 13; label.Font = 2; label.Outline = true; labelEntry.InnerElementYOffset = 0
                
                local isLabelVisible = true
                labelEntry.VisibleCondition = function() return isLabelVisible end

                local labelObj = {}
                local elementRecord = { HeightCost = 18, DrawingEntries = { labelEntry }, UIEntry = nil, VisibleCondition = function() return isLabelVisible end }
                table.insert(Group.Elements, elementRecord)

                function labelObj:SetVisible(visible) isLabelVisible = visible; Window:Refresh() end
                function labelObj:SetText(newText) label.Text = newText end
                return labelObj
            end

            function Group:AddToggle(text, default, callback, useRGB)
                local toggleOffset = Vector2.new(boxX + 10, 0)
                local fillOffset = Vector2.new(boxX + 12, 0)
                local labelOffset = Vector2.new(boxX + 28, 0)

                local box, boxEntry = RegisterDrawing(SafeCreateDrawing("Square"), "Square", toggleOffset, Vector2.new(12, 12), false, Tab, true, Group)
                box.Color = FatalityUI.Theme.Accent; box.Filled = false; box.Thickness = 1; boxEntry.InnerElementYOffset = 0

                local fill, fillEntry = RegisterDrawing(SafeCreateDrawing("Square"), "Square", fillOffset, Vector2.new(8, 8), false, Tab, true, Group)
                fill.Color = FatalityUI.Theme.Accent; fill.Filled = true; fill.Visible = default; fillEntry.InnerElementYOffset = 2

                local label, labelEntry = RegisterDrawing(SafeCreateDrawing("Text"), "Text", labelOffset, nil, false, Tab, true, Group)
                label.Text = text; label.Color = FatalityUI.Theme.Text; label.Size = 13; label.Font = 2; label.Outline = true; labelEntry.InnerElementYOffset = -1

                local hit = Instance.new("TextButton")
                hit.BackgroundTransparency = 1; hit.TextTransparency = 1; hit.ZIndex = 20; hit.Parent = uiContainer
                local _, hitEntry = RegisterUI(hit, toggleOffset, Vector2.new(boxWidth - 20, 14), false, Tab, true, Group)
                hitEntry.InnerElementYOffset = 0

                local state = default
                local isToggleVisible = true

                boxEntry.VisibleCondition = function() return isToggleVisible end
                fillEntry.VisibleCondition = function() return isToggleVisible and state end
                labelEntry.VisibleCondition = function() return isToggleVisible end
                hitEntry.VisibleCondition = function() return isToggleVisible end

                if useRGB then
                    table.insert(RGBCallbacks, function(rainbowColor)
                        box.Color = rainbowColor
                        if state then fill.Color = rainbowColor end
                        label.Color = rainbowColor
                    end)
                end

                local toggleObj = { Value = state }
                local elementRecord = { HeightCost = 22, DrawingEntries = { boxEntry, fillEntry, labelEntry }, UIEntry = hitEntry, VisibleCondition = function() return isToggleVisible end }
                table.insert(Group.Elements, elementRecord)

                hit.Activated:Connect(function()
                    state = not state
                    toggleObj.Value = state
                    fill.Visible = state
                    callback(state)
                    Window:Refresh()
                end)

                function toggleObj:SetVisible(visible) isToggleVisible = visible; Window:Refresh() end
                function toggleObj:SetState(newState) state = newState; fill.Visible = newState; toggleObj.Value = newState; callback(newState); Window:Refresh() end
                
                UIElements[text] = toggleObj
                return toggleObj
            end

            function Group:AddButton(text, callback)
                local btnOffset = Vector2.new(btnOffset or boxX + 10, 0)
                local btnWidth = boxWidth - 20
                local box, boxEntry = RegisterDrawing(SafeCreateDrawing("Square"), "Square", btnOffset, Vector2.new(btnWidth, 26), false, Tab, true, Group)
                box.Color = Color3.fromRGB(24, 20, 22); box.Filled = true; boxEntry.InnerElementYOffset = 0

                local label, labelEntry = RegisterDrawing(SafeCreateDrawing("Text"), "Text", Vector2.new(boxX + 10 + (btnWidth / 2), 0), nil, false, Tab, true, Group)
                label.Text = text; label.Color = FatalityUI.Theme.Accent; label.Size = 13; label.Font = 2; label.Outline = true; label.Center = true; labelEntry.InnerElementYOffset = 6

                local hit = Instance.new("TextButton")
                hit.BackgroundTransparency = 1; hit.TextTransparency = 1; hit.ZIndex = 25; hit.Parent = uiContainer
                local _, hitEntry = RegisterUI(hit, btnOffset, Vector2.new(btnWidth, 26), false, Tab, true, Group)
                hitEntry.InnerElementYOffset = 0

                local isBtnVisible = true
                boxEntry.VisibleCondition = function() return isBtnVisible end
                labelEntry.VisibleCondition = function() return isBtnVisible end
                hitEntry.VisibleCondition = function() return isBtnVisible end

                local btnObj = {}
                local elementRecord = {HeightCost = 34, DrawingEntries = { boxEntry, labelEntry }, UIEntry = hitEntry, VisibleCondition = function() return isBtnVisible end }
                table.insert(Group.Elements, elementRecord)
                hit.Activated:Connect(function() callback() end)

                function btnObj:SetVisible(visible) isBtnVisible = visible; Window:Refresh() end
                function btnObj:SetText(newText) label.Text = newText end
                function btnObj:SetColor(color) box.Color = color end
                function btnObj:SetTextColor(color) label.Color = color end
                return btnObj
            end

            function Group:AddSlider(text, min, max, default, isFloat, callback, step, suffix)
                local suf = suffix or ""
                local labelOffset = Vector2.new(boxX + 10, 0)
                local sliderWidth = boxWidth - 20

                local label, labelEntry = RegisterDrawing(SafeCreateDrawing("Text"), "Text", labelOffset, nil, false, Tab, true, Group)
                label.Text = text; label.Color = FatalityUI.Theme.TextMuted; label.Size = 13; label.Font = 2; label.Outline = true; labelEntry.InnerElementYOffset = 0

                local valLabel, valEntry = RegisterDrawing(SafeCreateDrawing("Text"), "Text", labelOffset, nil, false, Tab, true, Group)
                local initialText = isFloat and string.format("%.2f", default) or tostring(default)
                if step == 0.1 then initialText = string.format("%.1f", default) end
                valLabel.Text = initialText .. suf; valLabel.Color = FatalityUI.Theme.Text; valLabel.Size = 13; valLabel.Font = 2; valLabel.Outline = true
                valEntry.InnerElementYOffset = 0; valEntry.Offset1 = Vector2.new(boxX + 10 + sliderWidth - 30, 0)

                local track, trackEntry = RegisterDrawing(SafeCreateDrawing("Square"), "Square", labelOffset, Vector2.new(sliderWidth, 6), false, Tab, true, Group)
                track.Color = Color3.fromRGB(35, 30, 32); track.Filled = true; trackEntry.InnerElementYOffset = 16

                local percent = (default - min) / (max - min)
                local fill, fillEntry = RegisterDrawing(SafeCreateDrawing("Square"), "Square", labelOffset, Vector2.new(math.floor(sliderWidth * percent), 6), false, Tab, true, Group)
                fill.Color = FatalityUI.Theme.Accent; fill.Filled = true; fillEntry.InnerElementYOffset = 16

                local hit = Instance.new("TextButton")
                hit.BackgroundTransparency = 1; hit.TextTransparency = 1; hit.ZIndex = 21; hit.Parent = uiContainer
                local _, hitEntry = RegisterUI(hit, labelOffset, Vector2.new(sliderWidth, 14), false, Tab, true, Group)
                hitEntry.InnerElementYOffset = 12

                local value = default
                local isSliderVisible = true

                labelEntry.VisibleCondition = function() return isSliderVisible end
                valEntry.VisibleCondition = function() return isSliderVisible end
                trackEntry.VisibleCondition = function() return isSliderVisible end
                fillEntry.VisibleCondition = function() return isSliderVisible end
                hitEntry.VisibleCondition = function() return isSliderVisible end

                local sliderObj = { Value = value }
                local elementRecord = { HeightCost = 34, DrawingEntries = { labelEntry, valEntry, trackEntry, fillEntry }, UIEntry = hitEntry, VisibleCondition = function() return isSliderVisible end }
                table.insert(Group.Elements, elementRecord)

                local dragging = false
                local function update(inputPositionX)
                    local absoluteBarX = Window.Position.X + boxX + 10
                    local relativeX = math.clamp(inputPositionX - absoluteBarX, 0, sliderWidth)
                    percent = relativeX / sliderWidth
                    value = min + (max - min) * percent
                    if step then value = math.round(value / step) * step elseif not isFloat then value = math.round(value) end
                    value = math.clamp(value, min, max)
                    sliderObj.Value = value
                    
                    local displayText = isFloat and string.format("%.2f", value) or tostring(value)
                    if step == 0.1 then displayText = string.format("%.1f", value) end
                    valLabel.Text = displayText .. suf
                    fillEntry.Offset2 = Vector2.new(math.floor(sliderWidth * ((value - min) / (max - min))), 6)
                    callback(value)
                    Window:Refresh()
                end
 hit.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true; update(input.Position.X) end end)
                UserInputService.InputChanged:Connect(function(input) if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then update(input.Position.X) end end)
                UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end end)

                function sliderObj:SetVisible(visible) isSliderVisible = visible; Window:Refresh() end
                function sliderObj:SetState(val)
                    value = math.clamp(val, min, max)
                    sliderObj.Value = value
                    local displayText = isFloat and string.format("%.2f", value) or tostring(value)
                    valLabel.Text = displayText .. suf
                    fillEntry.Offset2 = Vector2.new(math.floor(sliderWidth * ((value - min) / (max - min))), 6)
                    callback(value)
                    Window:Refresh()
                end

                UIElements[text] = sliderObj
                return sliderObj
            end

            function Group:AddTextBox(labelText, defaultText, callback)
                local labelOffset = Vector2.new(boxX + 10, 0)
                local boxWidth = boxWidth - 20
                
                local label, labelEntry = RegisterDrawing(SafeCreateDrawing("Text"), "Text", labelOffset, nil, false, Tab, true, Group)
                label.Text = labelText; label.Color = FatalityUI.Theme.TextMuted; label.Size = 13; label.Font = 2; label.Outline = true; labelEntry.InnerElementYOffset = 0

                local bgFrame = Instance.new("Frame")
                bgFrame.BorderSizePixel = 0; bgFrame.BackgroundColor3 = Color3.fromRGB(24, 20, 22); bgFrame.ZIndex = 14; bgFrame.Parent = uiContainer
                local _, bgFrameEntry = RegisterUI(bgFrame, labelOffset, Vector2.new(boxWidth, 22), false, Tab, true, Group)
                bgFrameEntry.InnerElementYOffset = 15

                local boxStroke = Instance.new("UIStroke")
                boxStroke.Color = FatalityUI.Theme.Accent; boxStroke.Thickness = 1; boxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; boxStroke.Parent = bgFrame

                local tBox = Instance.new("TextBox")
                tBox.BackgroundTransparency = 1; tBox.Size = UDim2.new(1, -10, 1, 0); tBox.Position = UDim2.new(0, 5, 0, 0)
                tBox.Text = defaultText; tBox.TextColor3 = FatalityUI.Theme.Text; tBox.TextSize = 12; tBox.Font = Enum.Font.Code
                tBox.TextXAlignment = Enum.TextXAlignment.Left; tBox.ZIndex = 15; tBox.Parent = bgFrame

                local isBoxVisible = true
                labelEntry.VisibleCondition = function() return isBoxVisible end
                bgFrameEntry.VisibleCondition = function() return isBoxVisible end

                tBox.FocusLost:Connect(function()
                    callback(tBox.Text)
                end)

                local boxObj = { Frame = tBox }
                local elementRecord = { HeightCost = 42, DrawingEntries = { labelEntry }, UIEntry = bgFrameEntry, VisibleCondition = function() return isBoxVisible end }
                table.insert(Group.Elements, elementRecord)

                function boxObj:SetVisible(visible) isBoxVisible = visible; Window:Refresh() end
                function boxObj:SetText(newText) tBox.Text = newText end
                return boxObj
            end

            function Group:AddOptionCycle(labelText, options, defaultIndex, callback)
                local labelOffset = Vector2.new(boxX + 10, 0)
                local cycleWidth = boxWidth - 20

                local label, labelEntry = RegisterDrawing(SafeCreateDrawing("Text"), "Text", labelOffset, nil, false, Tab, true, Group)
                label.Text = labelText; label.Color = FatalityUI.Theme.TextMuted; label.Size = 13; label.Font = 2; label.Outline = true; labelEntry.InnerElementYOffset = 0

                local displayBox, displayEntry = RegisterDrawing(SafeCreateDrawing("Square"), "Square", labelOffset, Vector2.new(cycleWidth, 20), false, Tab, true, Group)
                displayBox.Color = Color3.fromRGB(24, 20, 22); displayBox.Filled = true; displayEntry.InnerElementYOffset = 15

                local borderBox, borderEntry = RegisterDrawing(SafeCreateDrawing("Square"), "Square", labelOffset, Vector2.new(cycleWidth, 20), false, Tab, true, Group)
                borderBox.Color = FatalityUI.Theme.Accent; borderBox.Filled = false; borderBox.Thickness = 1; borderEntry.InnerElementYOffset = 15

                local displayText, displayTextEntry = RegisterDrawing(SafeCreateDrawing("Text"), "Text", labelOffset, nil, false, Tab, true, Group)
                displayText.Text = options[defaultIndex] or "None"; displayText.Color = FatalityUI.Theme.Text; displayText.Size = 12; displayText.Font = 2; displayText.Outline = true; displayText.Center = true
                displayTextEntry.InnerElementYOffset = 18; displayTextEntry.Offset1 = Vector2.new(boxX + 10 + (cycleWidth / 2), 0)

                local hit = Instance.new("TextButton")
                hit.BackgroundTransparency = 1; hit.TextTransparency = 1; hit.ZIndex = 22; hit.Parent = uiContainer
                local _, hitEntry = RegisterUI(hit, labelOffset, Vector2.new(cycleWidth, 20), false, Tab, true, Group)
                hitEntry.InnerElementYOffset = 15

                local currentIndex = defaultIndex
                local isCycleVisible = true

                labelEntry.VisibleCondition = function() return isCycleVisible end
                displayEntry.VisibleCondition = function() return isCycleVisible end
                borderEntry.VisibleCondition = function() return isCycleVisible end
                displayTextEntry.VisibleCondition = function() return isCycleVisible end
                hitEntry.VisibleCondition = function() return isCycleVisible end

                local cycleObj = { Value = options[defaultIndex] or "None" }
                local elementRecord = { HeightCost = 40, DrawingEntries = { labelEntry, displayEntry, borderEntry, displayTextEntry }, UIEntry = hitEntry, VisibleCondition = function() return isCycleVisible end }
                table.insert(Group.Elements, elementRecord)

                hit.Activated:Connect(function()
                    if #options == 0 then return end
                    currentIndex = currentIndex + 1
                    if currentIndex > #options then currentIndex = 1 end
                    cycleObj.Value = options[currentIndex]
                    displayText.Text = options[currentIndex]
                    callback(options[currentIndex])
                end)

                function cycleObj:SetVisible(visible) isCycleVisible = visible; Window:Refresh() end
                
                function cycleObj:UpdateOptions(newOptions)
                    options = newOptions
                    currentIndex = 1
                    cycleObj.Value = options[1] or "None"
                    displayText.Text = cycleObj.Value
                    Window:Refresh()
                end
                
                return cycleObj
            end

            return Group
        end

        function Tab:Select()
            for _, otherTab in ipairs(Window.Tabs) do
                otherTab.Visuals.Bg.Transparency = 0; otherTab.Visuals.Accent.Visible = false; otherTab.Visuals.Text.Color = FatalityUI.Theme.TextMuted
                if otherTab.Visuals.Icon then otherTab.Visuals.Icon.ImageColor3 = FatalityUI.Theme.TextMuted end
            end
            tBg.Transparency = 1; tBg.Color = FatalityUI.Theme.TabHover; tAccent.Visible = true; tText.Color = FatalityUI.Theme.Text
            if iconImage then iconImage.ImageColor3 = FatalityUI.Theme.Text end
            Window.CurrentTab = Tab; Window:Refresh()
        end

        touchButton.Activated:Connect(function() Tab:Select() end)
        Tab.Visuals = { Bg = tBg, Accent = tAccent, Text = tText, Icon = iconImage }
        table.insert(Window.Tabs, Tab)
        return Tab
    end

    minTouch.Activated:Connect(function() Window.Minimized = true; Window:Refresh() end)
    miniTouch.Activated:Connect(function() Window.Minimized = false; Window:Refresh() end)

    local dragStart, startScroll
    scrollTouch.InputBegan:Connect(function(input) if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and Window.CurrentTab then dragStart = input.Position; startScroll = Window.CurrentTab.ScrollY end end)
    UserInputService.InputChanged:Connect(function(input) if dragStart and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and Window.CurrentTab then local delta = input.Position - dragStart; Window.CurrentTab.ScrollY = math.clamp(startScroll + delta.Y, -Window.CurrentTab.MaxScroll, 0); Window:Refresh() end end)
    UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragStart = nil end end)

    local function SetupDrag(handle, getTargetPos, setTargetPos)
        local wDragStart, startPos
        handle.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then wDragStart = input.Position; startPos = getTargetPos() end end)
        UserInputService.InputChanged:Connect(function(input) if wDragStart and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then local delta = input.Position - wDragStart; setTargetPos(startPos + Vector2.new(delta.X, delta.Y)); Window:Refresh() end end)
        UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then wDragStart = nil end end)
    end
    SetupDrag(mainDragTouch, function() return Window.Position end, function(v) Window.Position = v end)
    SetupDrag(miniTouch, function() return Window.MiniPosition end, function(v) Window.MiniPosition = v end)

    return Window
end

function FatalityUI:Unload()
    if self.HiddenGUI then pcall(function() self.HiddenGUI:Destroy() end) end
    for _, element in ipairs(self.Elements) do if element and element.Remove then pcall(function() element:Remove() end) end end
    self.Elements = {}
    for _, conn in ipairs(self.Connections) do if conn and conn.Disconnect then pcall(function() conn:Disconnect() end) end end
    self.Connections = {}
end
--------------------------------------------------------------------------------
-- RUNTIME UI LAYOUT BUILD
--------------------------------------------------------------------------------
local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(800, 600)
local menuSize = Vector2.new(550, 350) 
local menuPosition = (viewport / 2) - (menuSize / 2)

if getgenv().FatalityUI_Instance then 
    pcall(function() 
        getgenv().FatalityUI_Instance:Unload() 
    end) 
end

local UI = FatalityUI:CreateWindow(menuPosition, menuSize)
getgenv().FatalityUI_Instance = FatalityUI 

local ICONS = {
    Scope  = "rbxassetid://7733919105", Eye = "rbxassetid://7733770806", 
    Shield = "rbxassetid://7733749702", Bolt = "rbxassetid://7733715400"
}

local CombatTab   = UI:AddTab("Combat", ICONS.Scope)
local VisualTab   = UI:AddTab("Visual", ICONS.Eye)
local AntiAimTab  = UI:AddTab("anti aim", "rbxassetid://7733920644")
local MiscTab     = UI:AddTab("misc", ICONS.Bolt)

-- Combat Sector Layout
local LegitBox = CombatTab:AddGroupbox("legit", 1)
local AimbotSettingsBox = CombatTab:AddGroupbox("aimbot settings", 1)
local RageMainBox = CombatTab:AddGroupbox("rage", 2)       
local RageBox = CombatTab:AddGroupbox("allow shoot", 2)    

local fovSlider, fovTracer, indicator, naturalJerk, smartPickBtn
local smartPickState, smartPickClicks = false, 0
local bulletManipToggle, skyKillToggle, undergroundKillToggle, teleportKillToggle

local function updateSmartPickingVisibility()
    local c = 0
    if bulletManipToggle and bulletManipToggle.Value then c = c + 1 end
    if skyKillToggle and skyKillToggle.Value then c = c + 1 end
    if undergroundKillToggle and undergroundKillToggle.Value then c = c + 1 end
    if teleportKillToggle and teleportKillToggle.Value then c = c + 1 end
    smartPickBtn:SetVisible(c >= 3)
end

local aimbotToggle = LegitBox:AddToggle("Aimbot", false, function(enabled)
    fovSlider:SetVisible(enabled); fovTracer:SetVisible(enabled); indicator:SetVisible(enabled); naturalJerk:SetVisible(enabled)
end)
fovSlider   = LegitBox:AddSlider("FOV", 0, 1000, 100, false, function(val) end)
fovTracer   = LegitBox:AddToggle("FOV tracer", false, function(state) end)
indicator   = LegitBox:AddToggle("indicator", false, function(state) end)
naturalJerk = LegitBox:AddToggle("natural jerk", false, function(state) end)
fovSlider:SetVisible(false); fovTracer:SetVisible(false); indicator:SetVisible(false); naturalJerk:SetVisible(false)

AimbotSettingsBox:AddSlider("smoothness", 0, 1, 0.25, true, function(val) end)

-- Spray Control layout updated (no mode switchers or sensitivity settings)
local sprayToggle = AimbotSettingsBox:AddToggle("spray control", false, function(state) end)

bulletManipToggle     = RageMainBox:AddToggle("Bullet manip", false, function(state) CheatState.Rage.BulletManip = state; updateSmartPickingVisibility() end)

skyKillToggle         = RageMainBox:AddToggle("SKY KILL", false, function(state) CheatState.Rage.SkyKill = state; updateSmartPickingVisibility() end, true)
undergroundKillToggle = RageMainBox:AddToggle("UNDERGROUND KILL", false, function(state) CheatState.Rage.UndergroundKill = state; updateSmartPickingVisibility() end, true)
teleportKillToggle    = RageMainBox:AddToggle("TELEPORT KILL", false, function(state) CheatState.Rage.UnderportKill = state; updateSmartPickingVisibility() end, true)

smartPickBtn = RageMainBox:AddButton("smart picking? no", function()
    smartPickClicks = smartPickClicks + 1
    if smartPickClicks == 6 then
        local blackoutGui = Instance.new("ScreenGui")
        blackoutGui.IgnoreGuiInset = true; blackoutGui.DisplayOrder = 999999
        blackoutGui.Parent = game:GetService("CoreGui")
        local bf = Instance.new("Frame")
        bf.Size = UDim2.new(1,0,1,0); bf.BackgroundColor3 = Color3.fromRGB(0,0,0); bf.Parent = blackoutGui
        local tl = Instance.new("TextLabel")
        tl.Size = UDim2.new(1,0,1,0); tl.BackgroundTransparency = 1; tl.Text = "RETARDD!!!!"; tl.TextColor3 = Color3.fromRGB(255,255,255); tl.TextSize = 75; tl.Font = Enum.Font.Code; tl.Parent = bf
        task.delay(5, function() blackoutGui:Destroy() end)
    elseif smartPickClicks >= 15 then
        game:GetService("Players").LocalPlayer:Kick("go fuck your self")
        return
    end
    smartPickState = not smartPickState
    smartPickBtn:SetText(smartPickState and "smart picking? yes" or "smart picking? no")
end)
smartPickBtn:SetVisible(false) 

RageBox:AddToggle("while fly", false, function(state) CheatState.Rage.WhileFly = state end)
RageBox:AddToggle("while noclipped", false, function(state) CheatState.Rage.WhileNoclipped = state end)
RageBox:AddToggle("while freecammed", false, function(state) CheatState.Rage.WhileFreecammed = state end)
RageBox:AddToggle("underground", false, function(state) CheatState.Rage.Underground = state end)
RageBox:AddToggle("while resynced", false, function(state) CheatState.Rage.WhileResynced = state end)
RageBox:AddToggle("while anti aimed", false, function(state) CheatState.Rage.WhileAntiAimed = state end)

-- Visual Sector Layout
local MainVisualsBox = VisualTab:AddGroupbox("Main", 1)
local SecondaryVisualsBox = VisualTab:AddGroupbox("Secondary", 2)

MainVisualsBox:AddToggle("AI check", false, function(state) end)

local fullBtn, corneredBtn
local boxStyle = "Full"

local function updateBoxButtons()
    if not fullBtn or not corneredBtn then return end
    if boxStyle == "Full" then
        fullBtn:SetColor(FatalityUI.Theme.Accent); fullBtn:SetTextColor(FatalityUI.Theme.Background)
        corneredBtn:SetColor(Color3.fromRGB(24, 20, 22)); corneredBtn:SetTextColor(FatalityUI.Theme.Accent)
    else
        fullBtn:SetColor(Color3.fromRGB(24, 20, 22)); fullBtn:SetTextColor(FatalityUI.Theme.Accent)
        corneredBtn:SetColor(FatalityUI.Theme.Accent); corneredBtn:SetTextColor(FatalityUI.Theme.Background)
    end
end

local boxesToggle = MainVisualsBox:AddToggle("Boxes", false, function(state) fullBtn:SetVisible(state); corneredBtn:SetVisible(state) end)
fullBtn = MainVisualsBox:AddButton("Full", function() if boxStyle ~= "Full" then boxStyle = "Full"; updateBoxButtons() end end)
corneredBtn = MainVisualsBox:AddButton("Cornered", function() if boxStyle ~= "Cornered" then boxStyle = "Cornered"; updateBoxButtons() end end)
fullBtn:SetVisible(false); corneredBtn:SetVisible(false); updateBoxButtons()

MainVisualsBox:AddToggle("Name", false, function(state) end)
MainVisualsBox:AddToggle("distance", false, function(state) end)
MainVisualsBox:AddToggle("weapon", false, function(state) end)
MainVisualsBox:AddToggle("healthbar", false, function(state) end)
MainVisualsBox:AddToggle("health number", false, function(state) end)
MainVisualsBox:AddToggle("skeleton", false, function(state) end)
MainVisualsBox:AddToggle("look tracer", false, function(state) end)
MainVisualsBox:AddToggle("glow chams", false, function(state) end)
MainVisualsBox:AddSlider("visible check", 0, 5000, 1000, false, function(val) end, 1, "m")
MainVisualsBox:AddToggle("extraction", false, function(state) end)

local currentMode = "None"
local modeButtons = {}
local extraSettings = {}
local secondaryActive = false

local secondaryMasterToggle = SecondaryVisualsBox:AddToggle("Enable Secondary ESP", false, function(state)
    secondaryActive = state
    for _, btn in pairs(modeButtons) do btn:SetVisible(state) end
    for _, setting in pairs(extraSettings) do setting:SetVisible(state) end
end)

local function updateModeSelection(selectedMode)
    currentMode = selectedMode
    for modeName, btn in pairs(modeButtons) do
        if modeName == selectedMode then btn:SetColor(FatalityUI.Theme.Accent); btn:SetTextColor(FatalityUI.Theme.Background)
        else btn:SetColor(Color3.fromRGB(20, 16, 18)); btn:SetTextColor(FatalityUI.Theme.TextMuted) end
    end
end

local modes = {"Furry", "Folk", "Kirk", "Jew"}
for _, modeName in ipairs(modes) do
    local btn = SecondaryVisualsBox:AddButton(modeName, function()
        if not secondaryActive then return end
        if currentMode == modeName then updateModeSelection("None") else updateModeSelection(modeName) end
    end)
    btn:SetVisible(false)
    modeButtons[modeName] = btn
end

extraSettings.TeamCheck = SecondaryVisualsBox:AddToggle("Team check", false, function(state) end)
extraSettings.FriendCheck = SecondaryVisualsBox:AddToggle("Friend check", false, function(state) end)
extraSettings.GradientSize = SecondaryVisualsBox:AddSlider("gradient size", 0, 100, 50, false, function(val) end, 1, "%")
extraSettings.TeamCheck:SetVisible(false); extraSettings.FriendCheck:SetVisible(false); extraSettings.GradientSize:SetVisible(false)

-- Anti Aim Sector Layout
local CharacterBox = AntiAimTab:AddGroupbox("Character", 1)
local CharacterDesyncBox = AntiAimTab:AddGroupbox("character desync", 2)
local PitchesBox = AntiAimTab:AddGroupbox("Pitches", 1) 

local jitterBar
local lookUpToggle, lookDownToggle
local yawSpeedSlider

local jitterToggle = CharacterBox:AddToggle("Furry crack jitter", false, function(state) jitterBar:SetVisible(state) end)
jitterBar = CharacterBox:AddSlider("Jitter intensity", 1, 1000, 500, false, function(val) end)
jitterBar:SetVisible(false)
CharacterBox:AddToggle("Moonwalk AA", false, function(state) end)

local yawToggle = PitchesBox:AddToggle("yaw hallucination", false, function(state)
    CheatState.YawHallucination = state
    yawSpeedSlider:SetVisible(state)
end)
yawSpeedSlider = PitchesBox:AddSlider("hallucination speed", 1, 10, 1, false, function(val) CheatState.YawSpeed = val end, 1, "x")
yawSpeedSlider:SetVisible(false)

lookUpToggle = PitchesBox:AddToggle("look up vector", false, function(state) if state and lookDownToggle.Value then lookDownToggle:SetState(false) end end)
lookDownToggle = PitchesBox:AddToggle("look down vector", false, function(state) if state and lookUpToggle.Value then lookUpToggle:SetState(false) end end)

CharacterDesyncBox:AddToggle("no legs", false, function(state) CheatState.NoLegs = state end)
CharacterDesyncBox:AddToggle("no limbs", false, function(state) CheatState.NoLimbs = state end)
CharacterDesyncBox:AddToggle("bury", false, function(state) CheatState.Bury = state end)
CharacterDesyncBox:AddToggle("lay down", false, function(state) CheatState.LayDown = state end)
CharacterDesyncBox:AddToggle("flip", false, function(state) CheatState.Flip = state end)

CharacterDesyncBox:AddLabel("cartel limb separation")
CharacterDesyncBox:AddSlider("separation horizontal", -10, 10, 0, false, function(val) CheatState.CartelLimbSep.Horizontal = val end, 1)
CharacterDesyncBox:AddSlider("separation vertical", -10, 10, 0, false, function(val) CheatState.CartelLimbSep.Vertical = val end, 1)
-- ============================================================================
-- MISCELLANEOUS / MOVEMENT SECTOR
-- ============================================================================
local MovementBox   = MiscTab:AddGroupbox("Movement", 1)
local AtmosphereBox = MiscTab:AddGroupbox("atmosphere", 1)
local ColorsBox     = MiscTab:AddGroupbox("colors", 1)

local ExploitsBox   = MiscTab:AddGroupbox("Exploits", 2)
local CameraBox     = MiscTab:AddGroupbox("camera", 2)
local FPSBox        = MiscTab:AddGroupbox("FPS", 2)

-- 1. Movement Groupbox
MovementBox:AddToggle("Jump fly (buggy)", false, function(state) CheatState.Movement.JumpFly = state end)
MovementBox:AddToggle("B-Hop", false, function(state) CheatState.Movement.BHop = state end)
MovementBox:AddToggle("Noclip", false, function(state) CheatState.Movement.Noclip = state end)
MovementBox:AddToggle("NO FALL DAMAGE", false, function(state) CheatState.Movement.NoFallDamage = state end, true)

-- 2. Atmosphere Groupbox
local timeSlider
local timeToggle = AtmosphereBox:AddToggle("Time changer", false, function(state)
    timeSlider:SetVisible(state)
end)
timeSlider = AtmosphereBox:AddSlider("Time selection", 0, 24, 12, false, function(val) CheatState.Atmosphere.TimeChanger = val end, 1, "h")
timeSlider:SetVisible(false)

AtmosphereBox:AddToggle("Full bright", false, function(state) CheatState.Atmosphere.FullBright = state end)

-- 3. Colors Groupbox
ColorsBox:AddSlider("Saturation", 0, 1, 1, true, function(val) CheatState.Colors.Saturation = val end, 0.1, "x")

-- 4. Exploits Groupbox
ExploitsBox:AddToggle("Skin changer", false, function(state) CheatState.Exploits.SkinChanger = state end)
ExploitsBox:AddToggle("Hand teleport", false, function(state) CheatState.Exploits.HandTeleport = state end)
ExploitsBox:AddTextBox("Equip Hats (Enter ID)", "12345678", function(txt) CheatState.Exploits.HatID = txt end)

-- 5. Camera Groupbox
-- Replaced dual sliders with single Aspect Ratio slider ranging from 0 to 1 with 0.1 increments
CameraBox:AddSlider("Aspect Ratio", 0, 1, 1, true, function(val) CheatState.Camera.AspectRatio = val end, 0.1)

local fovValSlider
local fovToggle = CameraBox:AddToggle("FOV", false, function(state) 
    CheatState.Camera.FOV = state
    fovValSlider:SetVisible(state)
end)
fovValSlider = CameraBox:AddSlider("FOV Value", 60, 120, 90, false, function(val) CheatState.Camera.FOVVal = val end, 1)
fovValSlider:SetVisible(false)

-- 6. FPS Groupbox
FPSBox:AddToggle("Potato mode", false, function(state) CheatState.FPS.PotatoMode = state end)
FPSBox:AddToggle("Performance mode", false, function(state) CheatState.FPS.PerformanceMode = state end)
--------------------------------------------------------------------------------
-- RUNTIME UI RGB GLOW TASK
--------------------------------------------------------------------------------
local function StartGlowLoop()
    local rgbConnection = RunService.Heartbeat:Connect(function()
        local hue = (tick() % 4) / 4 -- Speed of the RGB transition (4 seconds full cycle)
        local color = Color3.fromHSV(hue, 1, 1)
        
        for _, callback in ipairs(RGBCallbacks) do
            pcall(callback, color)
        end
    end)
    table.insert(FatalityUI.Connections, rgbConnection)
end

StartGlowLoop()

VisualTab:Select()
UI:Refresh()


-- ============================================================================
-- [[ YOUR BACKEND CODE GOES HERE ]]
-- ============================================================================
-- ============================================================================
-- Place all of your feature loops, combat/movement logic, hookmetatables, 
-- and game environment manipulations right below this comment block.
--
-- You can read real-time values changed by the UI using the 'CheatState' table.
--
-- Example of reading states:
--   if CheatState.Movement.BHop then ... end
--   if CheatState.Rage.BulletManip then ... end
--
-- Example loop hook:
--   local BackendConnection = RunService.Heartbeat:Connect(function()
--       if CheatState.Movement.BHop then
--           -- Insert Bunnyhop Code
--       end
--   end)
--   table.insert(FatalityUI.Connections, BackendConnection) -- Tracks connection so it disconnects on UI Unload
-- ============================================================================

-- UNIFIED BACKEND ARCHITECTURE
-- Features: Modular ESP, Air Platform, Bullet Manipulators, Character Mods, ARCS

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera or Workspace:WaitForChild("Camera")

-- ============================================================================
-- INITIAL CONFIGURATION
-- ============================================================================
local Config = {
    -- Toggle passive character modifications (True = On, False = Off)
    EnableBackwardLook = false, -- 180-degree backward facing when not shooting
    EnableBackwardLean = false, -- Tilts waist backward (-45 degrees)
    EnableLayingSunk   = false, -- Lays flat and sinks 1 stud underground
    EnableOnlyArms     = false, -- Teleports head and legs to the void
}

-- ============================================================================
-- MODULE 1: DECOUPLED ESP & VISUALS
-- ============================================================================
local SharedVisuals = {
    ManipActive = false,
    ManipTarget = nil,
    ManipColor = Color3.fromRGB(255, 255, 255),
    ManipThickness = 1.5,
    ARCSActive = false,
    ARCSTargetPos = nil
}

local TracerLine, targetBeam, targetDot
local fallbackGui, fallbackLine
local successDraw, DrawingLib = pcall(function() return Drawing end)

if successDraw and DrawingLib then
    pcall(function()
        TracerLine = DrawingLib.new("Line")
        TracerLine.Visible = false
        TracerLine.Transparency = 1
        
        targetBeam = DrawingLib.new("Line")
        targetBeam.Color = Color3.fromRGB(255, 255, 255)
        targetBeam.Thickness = 1.5
        targetBeam.Transparency = 0.8
        targetBeam.Visible = false
        
        targetDot = DrawingLib.new("Circle")
        targetDot.Color = Color3.fromRGB(255, 75, 75)
        targetDot.Radius = 5
        targetDot.Filled = true
        targetDot.Thickness = 1
        targetDot.NumSides = 16
        targetDot.Transparency = 1
        targetDot.Visible = false
    end)
end

-- Fallback UI for Manipulator Lines
if not TracerLine then
    local uiParent = pcall(gethui) and gethui() or CoreGui:FindFirstChild("RobloxGui") or player:WaitForChild("PlayerGui")
    fallbackGui = Instance.new("ScreenGui")
    fallbackGui.Name = "TracerFallbackUI"
    fallbackGui.ResetOnSpawn = false
    fallbackGui.Parent = uiParent
    
    fallbackLine = Instance.new("Frame")
    fallbackLine.AnchorPoint = Vector2.new(0.5, 0.5)
    fallbackLine.BorderSizePixel = 0
    fallbackLine.Visible = false
    fallbackLine.Parent = fallbackGui
end

RunService.RenderStepped:Connect(function()
    local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    
    -- 1. Manipulator Visuals
    if SharedVisuals.ManipActive and SharedVisuals.ManipTarget and SharedVisuals.ManipTarget.Character then
        local targetHead = SharedVisuals.ManipTarget.Character:FindFirstChild("Head")
        if targetHead then
            local screenPos, onScreen = camera:WorldToViewportPoint(targetHead.Position)
            if onScreen then
                if TracerLine then
                    TracerLine.Color = SharedVisuals.ManipColor
                    TracerLine.Thickness = SharedVisuals.ManipThickness
                    TracerLine.From = screenCenter
                    TracerLine.To = Vector2.new(screenPos.X, screenPos.Y)
                    TracerLine.Visible = true
                elseif fallbackLine then
                    fallbackLine.BackgroundColor3 = SharedVisuals.ManipColor
                    local dx, dy = screenPos.X - screenCenter.X, screenPos.Y - screenCenter.Y
                    local dist = math.sqrt(dx * dx + dy * dy)
                    fallbackLine.Size = UDim2.new(0, dist, 0, SharedVisuals.ManipThickness)
                    fallbackLine.Position = UDim2.new(0, (screenCenter.X + screenPos.X) / 2, 0, (screenCenter.Y + screenPos.Y) / 2)
                    fallbackLine.Rotation = math.deg(math.atan2(dy, dx))
                    fallbackLine.Visible = true
                end
            else
                if TracerLine then TracerLine.Visible = false end
                if fallbackLine then fallbackLine.Visible = false end
            end
        end
    else
        if TracerLine then TracerLine.Visible = false end
        if fallbackLine then fallbackLine.Visible = false end
    end
    
    -- 2. ARCS Visuals
    if SharedVisuals.ARCSActive and SharedVisuals.ARCSTargetPos then
        local screenPos, onScreen = camera:WorldToViewportPoint(SharedVisuals.ARCSTargetPos)
        if onScreen then
            local tVec = Vector2.new(screenPos.X, screenPos.Y)
            if targetBeam then
                targetBeam.From = screenCenter
                targetBeam.To = tVec
                targetBeam.Visible = true
            end
            if targetDot then
                targetDot.Position = tVec
                targetDot.Visible = true
            end
        else
            if targetBeam then targetBeam.Visible = false end
            if targetDot then targetDot.Visible = false end
        end
    else
        if targetBeam then targetBeam.Visible = false end
        if targetDot then targetDot.Visible = false end
    end
end)

-- ============================================================================
-- MODULE 2: SHARED UTILITIES & GUI SETUP
-- ============================================================================
local uiParent = pcall(gethui) and gethui() or CoreGui:FindFirstChild("RobloxGui") or player:WaitForChild("PlayerGui")
local MainScreenGui = Instance.new("ScreenGui")
MainScreenGui.Name = "Volatile_Unified_UI"
MainScreenGui.ResetOnSpawn = false
MainScreenGui.Parent = uiParent

local function MakeDraggable(guiObj)
    local dragging, dragInput, dragStart, startPos
    guiObj.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = guiObj.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    guiObj.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch         if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then setDir(true) end 
    end)
    btn.InputEnded:Connect(function(i) 
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then setDir(false) end 
    end)
end

styleFlyBtn("▲ UP", Color3.fromRGB(0, 255, 255), UDim2.new(0, 0, 0, 0))
styleFlyBtn("▼ DN", Color3.fromRGB(255, 100, 100), UDim2.new(0, 0, 1, -60))

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    local r = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if h and r and h.Health > 0 and input.KeyCode == Enum.KeyCode.Space then
        FlyState.Landed = false
        FlyState.ManualJump = true
        r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, FlyState.JumpPower, r.AssemblyLinearVelocity.Z)
        h:ChangeState(Enum.HumanoidStateType.Jumping)
        lockPlatformToCharacter(r, h)
    end
end)

task.spawn(function()
    while true do
        task.wait(0.01)
        local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        local r = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if h and r and h.Health > 0 then
            local state = h:GetState()
            if (state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Jumping) and not _G.AirPlatformActive then
                lockPlatformToCharacter(r, h)
            end
            if not FlyState.Up and not FlyState.Down and _G.AirPlatformActive and h.FloorMaterial ~= Enum.Material.Air and h.FloorMaterial ~= nil then
                local ray = RaycastParams.new()
                ray.FilterType = Enum.RaycastFilterType.Exclude
                ray.FilterDescendantsInstances = {player.Character, _G.AirPlatformActive}
                if Workspace:Raycast(r.Position, Vector3.new(0, -4, 0), ray) then
                    if FlyState.SteppedConn then FlyState.SteppedConn:Disconnect() end
                    if _G.AirPlatformActive then 
                        _G.AirPlatformActive:Destroy()
_G.AirPlatformActive = nil 
            end
        end
    end
end)

-- ============================================================================
-- MODULE 4: BULLET MANIPULATORS
-- ============================================================================
local Manip = {
    Active = false,
    CurrentBtn = nil,
    SavedCFrame = nil,
    SavedCamCFrame = nil,
    HoldConn = nil,
    IsTraveling = false
}

local function hasLineOfSight(startPos, endPos, char, targetChar)
    local params = RaycastParams.new()
    local filters = {char}
    if targetChar then table.insert(filters, targetChar) end
    params.FilterDescendantsInstances = filters
    params.IgnoreWater = true
    return Workspace:Raycast(startPos, endPos - startPos, params) == nil
end

local function findVisibleHeight(baseCF, tRoot, myChar, tChar)
    local basePos = baseCF.Position + Vector3.new(0, 20, 0)
    if hasLineOfSight(basePos, tRoot.Position, myChar, tChar) then return 20 end
    for step = 1, 60 do
        local offset = step * 5.0
        if hasLineOfSight(basePos - Vector3.new(0, offset, 0), tRoot.Position, myChar, tChar) then return 20 - offset end
        if hasLineOfSight(basePos + Vector3.new(0, offset, 0), tRoot.Position, myChar, tChar) then return 20 + offset end
    end
    return 20
end

local function lockPositionWithJitter(rootPart, targetRoot, height, dist, isDynamic, originCF)
    if Manip.HoldConn then Manip.HoldConn:Disconnect() end
    local lastJitter = 0
    local jitterOff = Vector3.new(0, 0, 0)
    Manip.HoldConn = RunService.Heartbeat:Connect(function()
        if rootPart and rootPart.Parent and targetRoot and targetRoot.Parent then
            local now = os.clock()
            if now - lastJitter >= 0.005 then
                lastJitter = now
                jitterOff = Vector3.new((math.random() - 0.5) * 0.8, (math.random() - 0.5) * 0.8, (math.random() - 0.5) * 0.8)
            end
            local baseCF = isDynamic and (originCF + Vector3.new(0, height, 0)) or (targetRoot.CFrame * CFrame.new(0, height, dist))
            rootPart.CFrame = baseCF + jitterOff
            rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            rootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        else
            if Manip.HoldConn then Manip.HoldConn:Disconnect(); Manip.HoldConn = nil end
        end
    end)
end

local function triggerManipulator(mode, button, color, defaultTxt, activeColor)
    if Manip.IsTraveling then return end
    local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    Manip.IsTraveling = true
    
    if Manip.Active then
        if Manip.SavedCFrame then
            Manip.CurrentBtn.Text = "RESETTING..."
            if Manip.HoldConn then Manip.HoldConn:Disconnect(); Manip.HoldConn = nil end
            rootPart.AssemblyLinearVelocity, rootPart.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
            bypassTravel(rootPart, Manip.SavedCFrame)
            if Manip.SavedCamCFrame then camera.CFrame = Manip.SavedCamCFrame end
        end
        Manip.CurrentBtn.Text = defaultTxt
        Manip.CurrentBtn.BackgroundColor3 = activeColor
        Manip.Active = false
        Manip.SavedCFrame, Manip.SavedCamCFrame = nil, nil
        SharedVisuals.ManipActive = false
        Manip.IsTraveling = false
        return
    end
    
    local targetPlayer = getClosestPlayerToCrosshair()
    local targetRoot = targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not targetRoot then Manip.IsTraveling = false return end
    
    Manip.SavedCFrame = rootPart.CFrame
    Manip.SavedCamCFrame = camera.CFrame
    button.Text = (mode == "DYNAMIC") and "SCANNING..." or "MANIPULATING..."
    rootPart.AssemblyLinearVelocity, rootPart.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
    
    local height, dist, destCF = 0, 0, nil
    if mode == "SKY" then
        height, dist = 15.0, -5.0
        destCF = targetRoot.CFrame * CFrame.new(0, height, dist)
    elseif mode == "BEHIND" then
        height, dist = 0.0, 5.0
        destCF = targetRoot.CFrame * CFrame.new(0, height, dist)
    elseif mode == "DYNAMIC" then
        height = findVisibleHeight(Manip.SavedCFrame, targetRoot, player.Character, targetPlayer.Character)
        destCF = Manip.SavedCFrame + Vector3.new(0, height, 0)
    end
    
    Manip.Active = true
    Manip.CurrentBtn = button
    bypassTravel(rootPart, destCF)
    
    if mode == "BEHIND" then 
        camera.CFrame = CFrame.lookAt(destCF.Position + Vector3.new(0, 2, 0), targetRoot.Position)
    else 
        camera.CFrame = CFrame.lookAt(destCF.Position, targetRoot.Position) 
    end
    
    lockPositionWithJitter(rootPart, targetRoot, height, dist, mode == "DYNAMIC", Manip.SavedCFrame)
    button.Text = "RESET MANIP"
    button.BackgroundColor3 = Color3.fromRGB(220, 245, 220)
    SharedVisuals.ManipActive = true
    SharedVisuals.ManipTarget = targetPlayer
    SharedVisuals.ManipColor = color
    Manip.IsTraveling = false
end

-- Building Unified Manipulator UI
local btnSky = CreateMenuButton("BtnSky", "MANIP SKY", Color3.fromRGB(200, 255, 255), Color3.fromRGB(45, 45, 45), UDim2.new(0.8, -35, 0.30, -35))
local btnBehind = CreateMenuButton("BtnBehind", "MANIP BEHIND", Color3.fromRGB(210, 225, 255), Color3.fromRGB(45, 45, 45), UDim2.new(0.8, -35, 0.45, -35))
local btnDyn = CreateMenuButton("BtnDyn", "DYNAMIC SKY", Color3.fromRGB(120, 220, 180), Color3.fromRGB(45, 45, 45), UDim2.new(0.8, -35, 0.60, -35))

btnSky.MouseButton1Click:Connect(function() 
    triggerManipulator("SKY", btnSky, Color3.fromRGB(0, 255, 255), "MANIP SKY", Color3.fromRGB(200, 255, 255)) 
end)
btnBehind.MouseButton1Click:Connect(function() 
    triggerManipulator("BEHIND", btnBehind, Color3.fromRGB(255, 105, 180), "MANIP BEHIND", Color3.fromRGB(210, 225, 255)) 
end)
btnDyn.MouseButton1Click:Connect(function() 
    triggerManipulator("DYNAMIC", btnDyn, Color3.fromRGB(0, 255, 127), "DYNAMIC SKY", Color3.fromRGB(120, 220, 180)) 
end)

UserInputService.JumpRequest:Connect(function()
    if Manip.Active and not Manip.IsTraveling then
        if Manip.CurrentBtn == btnSky then 
            triggerManipulator("SKY", btnSky, Color3.fromRGB(0, 255, 255), "MANIP SKY", Color3.fromRGB(200, 255, 255))
        elseif Manip.CurrentBtn == btnBehind then 
            triggerManipulator("BEHIND", btnBehind, Color3.fromRGB(255, 105, 180), "MANIP BEHIND", Color3.fromRGB(210, 225, 255))
        elseif Manip.CurrentBtn == btnDyn then 
            triggerManipulator("DYNAMIC", btnDyn, Color3.fromRGB(0, 255, 127), "DYNAMIC SKY", Color3.fromRGB(120, 220, 180)) 
        end
    end
end)

-- ============================================================================
-- MODULE 5: PASSIVE CHARACTER MODS
-- ============================================================================
local function SetupCharacterMods(character)
    local humanoid = character:WaitForChild("Humanoid", 10)
    local rootPart = character:WaitForChild("Humanoid RootPart", 10)
    local upperTorso = character:WaitForChild("UpperTorso", 3)
    local lowerTorso = character:WaitForChild("LowerTorso", 3)
    if not humanoid or not rootPart then return end
    
    local rootJoint = (lowerTorso and (lowerTorso:FindFirstChild("Root") or lowerTorso:FindFirstChild("RootJoint"))) or rootPart:FindFirstChild("RootJoint")
    local waist = upperTorso and upperTorso:FindFirstChild("Waist")
    local rjBaseC0 = rootJoint and rootJoint.C0
    local waistBaseC0 = waist and waist.C0
    
    -- Only Arms Mod
    if Config.EnableOnlyArms then
        local voidOffset = CFrame.new(0, -99999, 0)
        local hide = {["Neck"] = true, ["Left Hip"] = true, ["LeftHip"] = true, ["Right Hip"] = true, ["RightHip"] = true}
        for _, j in ipairs(character:GetDescendants()) do
            if j:IsA("Motor6D") and hide[j.Name] then j.C0 = voidOffset end
        end
    end
    
    RunService.Stepped:Connect(function()
        if not character or not character:IsDescendantOf(Workspace) or humanoid.Health <= 0 then return end
        
        -- Laying Sunk overrides Backward Look on the RootJoint
        if Config.EnableLayingSunk and rootJoint then
            rootJoint.C0 = rjBaseC0 * CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(90), 0, 0)
            for _, p in ipairs(character:GetChildren()) do
                if p:IsA("BasePart") and p.Name ~= "Humanoid RootPart" then 
                    p.CanCollide = false 
                end
            end
        elseif Config.EnableBackwardLook and rootJoint then
            if FireState.IsFiring then
                rootJoint.C0 = rjBaseC0
            else
                rootJoint.C0 = rjBaseC0 * CFrame.Angles(0, math.rad(180), 0)
            end
        end
        
        -- Backward Lean applies purely to the Waist
        if Config.EnableBackwardLean and waist then
            waist.C0 = waistBaseC0 * CFrame.Angles(math.rad(-45), 0, 0)
        end
    end)
end

if player.Character then task.spawn(SetupCharacterMods, player.Character) end
player.CharacterAdded:Connect(SetupCharacterMods)

-- ============================================================================
-- MODULE 6: ARCS (AIMBOT & RECOIL SYSTEM)
-- ============================================================================
local ARCS = {
    Enabled = false,
    ActivePart = nil,
    RecoilActive = 0,
    SprayTime = 0,
    BaseOffset = -0.22,
    MaxOffset = -0.75,
    SprayRamp = 3.5,
    StiffBase = 0.94,
    StiffShoot = 0.99,
    RecoilBaseForce = 0.0035,
    RecoilMax = 0.016,
    RecoilRamp = 0.015,
    RecoilRecov = 18.0,
    BulletVel = 10000
}

local arcsBtn = Instance.new("TextButton")
arcsBtn.Size = UDim2.new(0, 90, 0, 45)
arcsBtn.Position = UDim2.new(0, 20, 0, 70)
arcsBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
arcsBtn.TextColor3 = Color3.fromRGB(255, 75, 75)
arcsBtn.Text = "ARCS"
arcsBtn.Font = Enum.Font.SourceSansBold
arcsBtn.TextSize = 18
Instance.new("UICorner", arcsBtn).CornerRadius = UDim.new(0, 8)
arcsBtn.Parent = MainScreenGui
MakeDraggable(arcsBtn)

arcsBtn.MouseButton1Click:Connect(function()
    ARCS.Enabled = not ARCS.Enabled
    arcsBtn.TextColor3 = ARCS.Enabled and Color3.fromRGB(75, 255, 75) or Color3.fromRGB(255, 75, 75)
    if not ARCS.Enabled then
        ARCS.ActivePart = nil
        ARCS.RecoilActive = 0
        ARCS.SprayTime = 0
        SharedVisuals.ARCSActive = false
    end
end)

local function getARCSTarget()
    local closest, shortest = nil, math.huge
    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= player and other.Character and other.Character:FindFirstChild("Head") then
            local p = other.Character.Head
            local pos, onS = camera:WorldToViewportPoint(p.Position)
            if onS then
                local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)).Magnitude
                if dist < shortest then 
                    shortest = dist
                    closest = p 
                end
            end
        end
    end
    return closest
end

RunService:BindToRenderStep("ARCS_Stabilizer", Enum.RenderPriority.Camera.Value + 100, function(dt)
    if not camera then return end
    local isShooting = FireState.IsFiring or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
    local fovScale = math.clamp(camera.FieldOfView / 70, 0.15, 1.0)
    
    if ARCS.Enabled and isShooting then
        ARCS.SprayTime = math.min(ARCS.SprayTime + (dt * ARCS.SprayRamp), 1.0)
        ARCS.RecoilActive = math.clamp(ARCS.RecoilActive + ((ARCS.RecoilBaseForce * fovScale) + (ARCS.RecoilActive * ARCS.RecoilRamp)), 0, (ARCS.RecoilMax * fovScale))
    else
        ARCS.SprayTime = math.max(ARCS.SprayTime - (dt * 4), 0)
        ARCS.RecoilActive = ARCS.RecoilActive - (ARCS.RecoilActive * math.min(1, dt * ARCS.RecoilRecov))
    end
    
    local trackPart = nil
    local finalTargetPos = nil
    
    if ARCS.Enabled then
        if not ARCS.ActivePart or not ARCS.ActivePart.Parent or ARCS.ActivePart.Parent:FindFirstChildOfClass("Humanoid").Health <= 0 then
            ARCS.ActivePart = getARCSTarget()
        end
        
        if ARCS.ActivePart then
            trackPart = ARCS.ActivePart
            local tPos = trackPart.Position
            local dist = (camera.CFrame.Position - tPos).Magnitude
            local tFly = dist / ARCS.BulletVel
            local gravDrop = 0.5 * Workspace.Gravity * (tFly ^ 2)
            local dynRecoil = ARCS.BaseOffset + (ARCS.MaxOffset - ARCS.BaseOffset) * ARCS.SprayTime
            local tVel = Vector3.zero
            local rt = trackPart.Parent:FindFirstChild("HumanoidRootPart")
            if rt then tVel = rt.Velocity end
            local lead = tVel * tFly
            
            finalTargetPos = tPos + Vector3.new(0, dynRecoil + gravDrop, 0) + lead
            local tLook = CFrame.new(camera.CFrame.Position, finalTargetPos) * CFrame.Angles(isShooting and -ARCS.RecoilActive or 0, 0, 0)
            camera.CFrame = camera.CFrame:Lerp(tLook, isShooting and ARCS.StiffShoot or ARCS.StiffBase)
        elseif isShooting and ARCS.RecoilActive > 0 then
            camera.CFrame = camera.CFrame * CFrame.Angles(-ARCS.RecoilActive, 0, 0)
        end
    else
        trackPart = getARCSTarget()
        if trackPart then 
            finalTargetPos = trackPart.Position + Vector3.new(0, ARCS.BaseOffset, 0) 
        end
    end
    
    -- Update Visual Tracker state
    if ARCS.Enabled and trackPart and finalTargetPos then
        SharedVisuals.ARCSActive = true
        SharedVisuals.ARCSTargetPos = finalTargetPos
    else
        SharedVisuals.ARCSActive = false
    end
end)
   ============================================================================

      
      
