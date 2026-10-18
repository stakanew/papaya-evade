local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local Camera = Workspace.CurrentCamera

if setfpscap then
    pcall(function() setfpscap(240) end)
end

local player = Players.LocalPlayer

local settings = {
    espSouls = true,
    espItems = true,
    espMobs = true,
    showSpeed = true,
    showTimer = true,
    showCompass = true,
    skyType = "Sunset",
}

local skies = {
    Default = {bk="", dn="", ft="", lf="", rt="", up=""},
    Sunset = {
        bk="rbxassetid://159454299", dn="rbxassetid://159454296",
        ft="rbxassetid://159454293", lf="rbxassetid://159454286",
        rt="rbxassetid://159454300", up="rbxassetid://159454288"
    },
    Night = {
        bk="rbxassetid://8992230677", dn="rbxassetid://8992230677",
        ft="rbxassetid://8992230677", lf="rbxassetid://8992230677",
        rt="rbxassetid://8992230677", up="rbxassetid://8992230677"
    },
    Space = {
        bk="rbxassetid://12064107", dn="rbxassetid://12064152",
        ft="rbxassetid://12064121", lf="rbxassetid://12063984",
        rt="rbxassetid://12064131", up="rbxassetid://12063990"
    }
}

-- ФИКС СВЕТА: небо теперь не влияет на яркость карты
local function SetupLighting()
    Lighting.EnvironmentDiffuseScale = 0
    Lighting.EnvironmentSpecularScale = 0
    Lighting.Ambient = Color3.fromRGB(150, 150, 150)
    Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 150)
    Lighting.Brightness = 2
    Lighting.GlobalShadows = true
end
SetupLighting()

local currentSkyObj = nil
local function ApplySky(skyName)
    settings.skyType = skyName
    if currentSkyObj then currentSkyObj:Destroy() end
    for _, v in ipairs(Lighting:GetChildren()) do
        if v:IsA("Sky") then v:Destroy() end
    end
    
    local data = skies[skyName]
    if skyName == "Default" or not data then return end
    
    local sky = Instance.new("Sky")
    sky.SkyboxBk = data.bk
    sky.SkyboxDn = data.dn
    sky.SkyboxFt = data.ft
    sky.SkyboxLf = data.lf
    sky.SkyboxRt = data.rt
    sky.SkyboxUp = data.up
    sky.Parent = Lighting
    currentSkyObj = sky
end

ApplySky(settings.skyType)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "EvadeSettings"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 2147483647
screenGui.Parent = game:GetService("CoreGui")

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(0, 200, 0, 30)
speedLabel.Position = UDim2.new(0.5, -100, 0.5, 15)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "0.0"
speedLabel.Font = Enum.Font.GothamBold
speedLabel.TextSize = 22
speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
speedLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
speedLabel.TextStrokeTransparency = 0
speedLabel.Visible = settings.showSpeed
speedLabel.Parent = screenGui

local timerLabel = Instance.new("TextLabel")
timerLabel.Size = UDim2.new(0, 200, 0, 30)
timerLabel.Position = UDim2.new(1, -220, 0, 30)
timerLabel.BackgroundTransparency = 1
timerLabel.Text = "--:--"
timerLabel.Font = Enum.Font.GothamBold
timerLabel.TextSize = 22
timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
timerLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
timerLabel.TextStrokeTransparency = 0
timerLabel.TextXAlignment = Enum.TextXAlignment.Right
timerLabel.Visible = settings.showTimer
timerLabel.Parent = screenGui

local stateLabel = Instance.new("TextLabel")
stateLabel.Size = UDim2.new(0, 200, 0, 16)
stateLabel.Position = UDim2.new(1, -220, 0, 62)
stateLabel.BackgroundTransparency = 1
stateLabel.Text = ""
stateLabel.Font = Enum.Font.GothamBold
stateLabel.TextSize = 11
stateLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
stateLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
stateLabel.TextStrokeTransparency = 0
stateLabel.TextXAlignment = Enum.TextXAlignment.Right
stateLabel.Visible = settings.showTimer
stateLabel.Parent = screenGui

local trackedItems = {}

local function ClearAllESP()
    for obj, data in pairs(trackedItems) do
        pcall(function() data.billboard:Destroy() end)
        pcall(function() data.highlight:Destroy() end)
        trackedItems[obj] = nil
    end
end

local function CreateESP(obj, name, color, type)
    if trackedItems[obj] then return end
    if obj.Parent and trackedItems[obj.Parent] then return end
    
    local targetPart = nil
    if obj:IsA("Model") then 
        targetPart = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
    elseif obj:IsA("BasePart") then 
        targetPart = obj 
    end
    if not targetPart then return end

    local pos = targetPart.Position
    for _, data in pairs(trackedItems) do
        if data.target and data.target.Parent then
            if (data.target.Position - pos).Magnitude < 3 then return end
        end
    end

    local hl = Instance.new("Highlight")
    hl.FillColor = color
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency = 0.5
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee = obj
    hl.Parent = obj

    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 200, 0, 24)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = targetPart

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = " " .. name
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 14
    nameLabel.TextColor3 = color
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextXAlignment = Enum.TextXAlignment.Center
    nameLabel.Parent = billboard

    trackedItems[obj] = { billboard = billboard, highlight = hl, target = targetPart, color = color, type = type }
end

local function UpdateESP()
    for obj, data in pairs(trackedItems) do
        if not obj.Parent or not data.target.Parent then
            pcall(function() data.billboard:Destroy() end)
            pcall(function() data.highlight:Destroy() end)
            trackedItems[obj] = nil
        end
    end

    if settings.espSouls or settings.espItems then
        local effects = Workspace:FindFirstChild("Effects")
        if effects then
            for _, obj in ipairs(effects:GetDescendants()) do
                if obj:IsA("Model") or obj:IsA("BasePart") then
                    local n = obj.Name:lower()
                    local isSoul = n:find("soul")
                    local isSkull = n:find("skull")
                    
                    if isSoul and settings.espSouls then
                        CreateESP(obj, "👻 Soul", Color3.fromRGB(180, 100, 255), "soul")
                    elseif isSkull and settings.espSouls then
                        local siblingSoul = nil
                        if obj.Parent then
                            siblingSoul = obj.Parent:FindFirstChild("Souls0") or obj.Parent:FindFirstChild("Soul")
                        end
                        if not siblingSoul then
                            CreateESP(obj, "💀 Skull", Color3.fromRGB(255, 255, 255), "soul")
                        end
                    elseif settings.espItems then
                        if n:find("token") or n:find("ticket") then 
                            CreateESP(obj, "🎟️ Ticket", Color3.fromRGB(100, 255, 100), "item")
                        elseif n:find("experience") then 
                            CreateESP(obj, "✨ EXP", Color3.fromRGB(0, 255, 255), "item")
                        elseif n:find("loadout") then 
                            CreateESP(obj, "⚔️ Loadout", Color3.fromRGB(255, 100, 200), "item")
                        elseif n:find("point") then 
                            CreateESP(obj, "🎯 Point", Color3.fromRGB(255, 255, 0), "item")
                        elseif n == "usb" then
                            CreateESP(obj, "💾 USB", Color3.fromRGB(0, 255, 255), "item")
                        end
                    end
                end
            end
        end
    end

    if settings.espMobs then
        local plrsFolder = Workspace:FindFirstChild("Players")
        if plrsFolder then
            for _, obj in ipairs(plrsFolder:GetChildren()) do
                if obj.Name:find("Glorp") then 
                    CreateESP(obj, "👾 Glorp Cat", Color3.fromRGB(255, 50, 50), "mob") 
                end
            end
        end
    end
end

task.spawn(function()
    while task.wait(0.5) do
        pcall(UpdateESP)
    end
end)

local compassFrame = Instance.new("Frame")
compassFrame.Size = UDim2.new(0, 0, 0, 0)
compassFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
compassFrame.BackgroundTransparency = 1
compassFrame.Parent = screenGui

local indicators = {}

local function GetOrCreateIndicator(id)
    if indicators[id] then return indicators[id] end
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 80, 0, 24)
    frame.BackgroundTransparency = 1
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Parent = compassFrame
    
    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 100, 0, 20)
    arrow.BackgroundTransparency = 1
    arrow.Text = "▲"
    arrow.Font = Enum.Font.GothamBold
    arrow.TextSize = 18
    arrow.TextStrokeTransparency = 0
    arrow.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 100, 0, 14)
    label.Position = UDim2.new(0, 0, 0, 16)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.TextStrokeTransparency = 0
    label.Parent = frame

    indicators[id] = { frame = frame, arrow = arrow, label = label }
    return indicators[id]
end

local function UpdateCompass()
    if not settings.showCompass then
        for _, ind in pairs(indicators) do ind.frame.Visible = false end
        return
    end
    
    if not Camera or not Camera.Parent then Camera = Workspace.CurrentCamera end
    
    local char = player.Character
    local rootPart = char and char:FindFirstChild("HumanoidRootPart")
    if not rootPart or not Camera then return end
    
    local targets = {}
    for obj, data in pairs(trackedItems) do
        if obj and obj.Parent and data.target and data.target.Parent then
            local enabled = false
            if data.type == "soul" and settings.espSouls then enabled = true end
            if data.type == "item" and settings.espItems then enabled = true end
            if data.type == "mob" and settings.espMobs then enabled = true end
            
            if enabled then
                table.insert(targets, {
                    pos = data.target.Position,
                    color = data.color,
                    dist = (rootPart.Position - data.target.Position).Magnitude
                })
            end
        end
    end
    
    table.sort(targets, function(a, b) return a.dist < b.dist end)
    
    local maxShow = 6
    local shownCount = 0
    
    for id, ind in pairs(indicators) do ind.frame.Visible = false end

    for i, t in ipairs(targets) do
        if shownCount >= maxShow then break end
        shownCount = shownCount + 1
        
        local indicator = GetOrCreateIndicator(i)
        indicator.frame.Visible = true
        
        local direction = (t.pos - rootPart.Position).Unit
        local camLook = Camera.CFrame.LookVector
        local camRight = Camera.CFrame.RightVector
        
        local flatDir = Vector3.new(direction.X, 0, direction.Z).Unit
        local flatLook = Vector3.new(camLook.X, 0, camLook.Z).Unit
        local flatRight = Vector3.new(camRight.X, 0, camRight.Z).Unit
        
        local dotForward = flatDir:Dot(flatLook)
        local dotRight = flatDir:Dot(flatRight)
        
        local angle = math.atan2(dotRight, dotForward)
        local arrowAngle = math.deg(angle)
        
        local radius = 100
        local x = math.sin(angle) * radius
        local y = -math.cos(angle) * radius
        
        indicator.frame.Position = UDim2.new(0.5, x, 0.5, y)
        indicator.arrow.Rotation = arrowAngle
        indicator.arrow.TextColor3 = t.color
        indicator.label.Text = string.format("%.0fm", t.dist)
        indicator.label.TextColor3 = t.color
    end
end

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 280, 0, 450)
mainFrame.Position = UDim2.new(0.5, -140, 0.5, -225)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Visible = false
mainFrame.Parent = screenGui

local pc = Instance.new("UICorner") pc.CornerRadius = UDim.new(0, 10) pc.Parent = mainFrame
local ps = Instance.new("UIStroke") ps.Color = Color3.fromRGB(150, 100, 255) ps.Thickness = 1.5 ps.Parent = mainFrame

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 35)
titleBar.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame
local tbc = Instance.new("UICorner") tbc.CornerRadius = UDim.new(0, 10) tbc.Parent = titleBar

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 1, 0)
title.BackgroundTransparency = 1
title.Text = "⚙️ Настройки (Z)"
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 24, 0, 24)
closeBtn.Position = UDim2.new(1, -30, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Text = "×"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Parent = titleBar
local cbc = Instance.new("UICorner") cbc.CornerRadius = UDim.new(0, 6) cbc.Parent = closeBtn

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -10, 1, -45)
scroll.Position = UDim2.new(0, 5, 0, 40)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.CanvasSize = UDim2.new(0, 0, 0, 550)
scroll.Parent = mainFrame

local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 6)
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Parent = scroll

local function MakeToggle(text, initial, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 30)
    btn.BackgroundColor3 = initial and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(50, 50, 60)
    btn.Text = text .. (initial and " [ВКЛ]" or " [ВЫКЛ]")
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 12
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Parent = scroll
    local bc = Instance.new("UICorner") bc.CornerRadius = UDim.new(0, 6) bc.Parent = btn
    
    local state = initial
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(50, 50, 60)
        btn.Text = text .. (state and " [ВКЛ]" or " [ВЫКЛ]")
        callback(state)
    end)
    return btn
end

local function MakeSkyButton(text, skyName)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 30)
    btn.BackgroundColor3 = (settings.skyType == skyName) and Color3.fromRGB(100, 70, 180) or Color3.fromRGB(40, 40, 55)
    btn.Text = text
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 12
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Parent = scroll
    local bc = Instance.new("UICorner") bc.CornerRadius = UDim.new(0, 6) bc.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        for _, child in ipairs(scroll:GetChildren()) do
            if child:IsA("TextButton") and child.Text:find("Небо") then
                child.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
            end
        end
        btn.BackgroundColor3 = Color3.fromRGB(100, 70, 180)
        ApplySky(skyName)
    end)
    return btn
end

local yOrder = 0

local compassTitle = Instance.new("TextLabel")
compassTitle.Size = UDim2.new(1, 0, 0, 20)
compassTitle.BackgroundTransparency = 1
compassTitle.Text = "--- ПРИЦЕЛ ---"
compassTitle.Font = Enum.Font.GothamBold
compassTitle.TextSize = 12
compassTitle.TextColor3 = Color3.fromRGB(200, 200, 255)
compassTitle.LayoutOrder = yOrder yOrder = yOrder + 1
compassTitle.Parent = scroll

MakeToggle("🎯 Метки у центра", settings.showCompass, function(s)
    settings.showCompass = s
end).LayoutOrder = yOrder yOrder = yOrder + 1

local espTitle = Instance.new("TextLabel")
espTitle.Size = UDim2.new(1, 0, 0, 20)
espTitle.BackgroundTransparency = 1
espTitle.Text = "--- ESP ---"
espTitle.Font = Enum.Font.GothamBold
espTitle.TextSize = 12
espTitle.TextColor3 = Color3.fromRGB(150, 200, 255)
espTitle.LayoutOrder = yOrder yOrder = yOrder + 1
espTitle.Parent = scroll

MakeToggle("👻 Души и Черепа", settings.espSouls, function(s)
    settings.espSouls = s
    if not s then ClearAllESP() end
end).LayoutOrder = yOrder yOrder = yOrder + 1

MakeToggle("📦 Предметы (USB, Тикеты)", settings.espItems, function(s)
    settings.espItems = s
    if not s then ClearAllESP() end
end).LayoutOrder = yOrder yOrder = yOrder + 1

MakeToggle("👾 Глорп Коты", settings.espMobs, function(s)
    settings.espMobs = s
    if not s then ClearAllESP() end
end).LayoutOrder = yOrder yOrder = yOrder + 1

local hudTitle = Instance.new("TextLabel")
hudTitle.Size = UDim2.new(1, 0, 0, 20)
hudTitle.BackgroundTransparency = 1
hudTitle.Text = "--- HUD ---"
hudTitle.Font = Enum.Font.GothamBold
hudTitle.TextSize = 12
hudTitle.TextColor3 = Color3.fromRGB(255, 200, 150)
hudTitle.LayoutOrder = yOrder yOrder = yOrder + 1
hudTitle.Parent = scroll

MakeToggle("📊 Скорость", settings.showSpeed, function(s)
    settings.showSpeed = s
end).LayoutOrder = yOrder yOrder = yOrder + 1

MakeToggle("⏱️ Таймер", settings.showTimer, function(s)
    settings.showTimer = s
end).LayoutOrder = yOrder yOrder = yOrder + 1

local skyTitle = Instance.new("TextLabel")
skyTitle.Size = UDim2.new(1, 0, 0, 20)
skyTitle.BackgroundTransparency = 1
skyTitle.Text = "--- НЕБО ---"
skyTitle.Font = Enum.Font.GothamBold
skyTitle.TextSize = 12
skyTitle.TextColor3 = Color3.fromRGB(255, 150, 255)
skyTitle.LayoutOrder = yOrder yOrder = yOrder + 1
skyTitle.Parent = scroll

MakeSkyButton("Небо: Обычное", "Default").LayoutOrder = yOrder yOrder = yOrder + 1
MakeSkyButton("Небо: Закат", "Sunset").LayoutOrder = yOrder yOrder = yOrder + 1
MakeSkyButton("Небо: Ночь", "Night").LayoutOrder = yOrder yOrder = yOrder + 1
MakeSkyButton("Небо: Космос", "Space").LayoutOrder = yOrder yOrder = yOrder + 1

local cachedIngameFrame = nil
local cachedRoundFrame = nil
local lastCacheUpdate = 0

local function UpdateCache()
    local now = tick()
    if now - lastCacheUpdate < 1 then return end
    lastCacheUpdate = now
    pcall(function()
        local gui = player:FindFirstChild("PlayerGui")
        if not gui then return end
        local roundOverlay = gui.Game.HUD.Overlay.RoundOverlay
        if not roundOverlay then return end
        local roundTimerFrame = roundOverlay:FindFirstChild("RoundTimer")
        if not roundTimerFrame then return end
        cachedIngameFrame = roundTimerFrame:FindFirstChild("IngameRoundTimer")
        cachedRoundFrame = roundTimerFrame:FindFirstChild("RoundTimer")
    end)
end

local function GetTimerData()
    UpdateCache()

    if not cachedIngameFrame or not cachedIngameFrame.Parent then
        lastCacheUpdate = 0
        UpdateCache()
    end
    if not cachedRoundFrame or not cachedRoundFrame.Parent then
        lastCacheUpdate = 0
        UpdateCache()
    end

    local ingameVisible = cachedIngameFrame and cachedIngameFrame.Visible
    local roundVisible = cachedRoundFrame and cachedRoundFrame.Visible

    local ingameText = nil
    local roundText = nil

    if cachedIngameFrame then
        local t = cachedIngameFrame:FindFirstChild("Timer")
        if t and t:IsA("TextLabel") then ingameText = t.Text end
    end
    if cachedRoundFrame then
        local t = cachedRoundFrame:FindFirstChild("Timer")
        if t and t:IsA("TextLabel") then roundText = t.Text end
    end

    if ingameVisible and ingameText and ingameText ~= "" then
        return ingameText, "РАУНД"
    end
    if roundVisible and roundText and roundText ~= "" then
        return roundText, "ПЕРЕРЫВ"
    end

    if ingameText and ingameText ~= "" and ingameText ~= "0:00" then
        return ingameText, "РАУНД"
    end
    if roundText and roundText ~= "" and roundText ~= "0:00" then
        return roundText, "ПЕРЕРЫВ"
    end

    return nil, nil
end

local lastGuiUpdate = 0
RunService.RenderStepped:Connect(function()
    local now = tick()
    
    UpdateCompass()

    speedLabel.Visible = settings.showSpeed
    timerLabel.Visible = settings.showTimer
    stateLabel.Visible = settings.showTimer

    if now - lastGuiUpdate < 0.05 then return end
    lastGuiUpdate = now

    if settings.showSpeed then
        local char = player.Character
        local hum = char and char:FindFirstChild("Humanoid")
        local rp = char and char:FindFirstChild("HumanoidRootPart")
        
        if char and hum and hum.Health > 0 and rp and rp.Parent then
            local vel = rp.AssemblyLinearVelocity
            local flatVel = Vector3.new(vel.X, 0, vel.Z)
            speedLabel.Text = string.format("%.1f", flatVel.Magnitude)
        else
            speedLabel.Text = "0.0"
        end
    end

    if settings.showTimer then
        local timerText, mode = GetTimerData()
        if timerText then
            timerLabel.Text = timerText
            if mode == "ПЕРЕРЫВ" then
                timerLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
                stateLabel.Text = "ПЕРЕРЫВ"
                stateLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
            else
                timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                stateLabel.Text = "РАУНД"
                stateLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            end
        else
            timerLabel.Text = "--:--"
            stateLabel.Text = ""
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.Z then
        mainFrame.Visible = not mainFrame.Visible
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
end)

print("EVADE v70")
print("Нажми Z, чтобы открыть меню")
