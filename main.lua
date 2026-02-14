local s = getgenv().__SESSION
if not s then return end
if not string.match(s, "^S%-") then return end

-- OPTIONAL: delay phá dump
task.wait(math.random())

-- ============================================
-- MONEY EVENT + ARCADE EVENT + BAT
-- ============================================
-- Money Event: Auto farm (logic gốc)
-- Arcade Event: Auto collect (logic gốc từ script 3)
-- BAT: Size expander
-- ============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ============================================
-- BIẾN
-- ============================================

local AUTO_ENABLED = _G.AutoEventEnabled or false
local isAutoRunning = false

local ARCADE_ENABLED = _G.ArcadeEventEnabled or false
local arcadeRunning = false

local BAT_ENABLED = true
local SIZE_MULTIPLIER = 10
local MIN_SIZE = 1
local MAX_SIZE = 1000
local originalSizes = {}
local currentTool = nil

-- Money Event
local CONFIG = {
    VERIFY_TIME = 15,
    VERIFY_RADIUS = 5,
    OSCILLATION = 0.15,
    OSCILLATION_SPEED = 0.8,
    DETECTION_PATTERNS = {
        "Bonus:",
        "completed",
        "this",
        "Thưởng thêm",
    },
}

local TARGETS = {
    {name = "A", x = 425.7, y = -10.5, z = -340},
    {name = "C", x = 1132.37, y = 3.9, z = 529},
    {name = "B", x = 2571, y = -5.44, z = -337.7}
}

local MONEY_EVENT_ICON = "rbxassetid://109664817855554"

-- Arcade Collect (LOGIC GỐC)
local FLY_SPEED = 300
local A = Vector3.new(153, 4.15, -140)
local B = Vector3.new(4027, -1, -135)
local AB = B - A
local BOX_MIN = Vector3.new(153, -4, -140)
local BOX_MAX = Vector3.new(4055, 10, 135)
local SAFE_RADIUS = 100
local COLLECT_RADIUS = 300
local bodyVelocity = nil

-- ============================================
-- UI
-- ============================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MoneyEventSystem"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 280, 0, 200)
mainFrame.Position = UDim2.new(1, -290, 0, 10)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(60, 60, 60)
mainStroke.Thickness = 2
mainStroke.Parent = mainFrame

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 35)
header.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
header.BorderSizePixel = 0
header.Parent = mainFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 10)
headerCorner.Parent = header

local headerFix = Instance.new("Frame")
headerFix.Size = UDim2.new(1, 0, 0, 18)
headerFix.Position = UDim2.new(0, 0, 1, -18)
headerFix.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
headerFix.BorderSizePixel = 0
headerFix.Parent = header

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -40, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Auto Event"
titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
titleLabel.TextSize = 14
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -33, 0, 2.5)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
closeBtn.Text = "×"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 18
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.Parent = header

local closeBtnCorner = Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(0, 6)
closeBtnCorner.Parent = closeBtn

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -20, 1, -45)
scrollFrame.Position = UDim2.new(0, 10, 0, 40)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 4
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 215, 0)
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.Parent = mainFrame

local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, 0, 0, 0)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = scrollFrame

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 8)
listLayout.Parent = contentFrame

listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    contentFrame.Size = UDim2.new(1, 0, 0, listLayout.AbsoluteContentSize.Y)
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
end)

-- ============================================
-- EVENT MONEY BUTTON
-- ============================================

local eventMoneyBtn = Instance.new("TextButton")
eventMoneyBtn.Name = "EventMoneyBtn"
eventMoneyBtn.Size = UDim2.new(1, 0, 0, 35)
eventMoneyBtn.BackgroundColor3 = Color3.fromRGB(60, 50, 20)
eventMoneyBtn.Text = ""
eventMoneyBtn.BorderSizePixel = 0
eventMoneyBtn.LayoutOrder = 1
eventMoneyBtn.Parent = contentFrame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 8)
btnCorner.Parent = eventMoneyBtn

local btnStroke = Instance.new("UIStroke")
btnStroke.Color = Color3.fromRGB(255, 215, 0)
btnStroke.Thickness = 1.5
btnStroke.Parent = eventMoneyBtn

local btnLabel = Instance.new("TextLabel")
btnLabel.Size = UDim2.new(1, -50, 1, 0)
btnLabel.Position = UDim2.new(0, 10, 0, 0)
btnLabel.BackgroundTransparency = 1
btnLabel.Text = "💰 Event Money"
btnLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
btnLabel.TextSize = 13
btnLabel.Font = Enum.Font.GothamBold
btnLabel.TextXAlignment = Enum.TextXAlignment.Left
btnLabel.Parent = eventMoneyBtn

local statusIndicator = Instance.new("TextLabel")
statusIndicator.Name = "StatusIndicator"
statusIndicator.Size = UDim2.new(0, 40, 0, 20)
statusIndicator.Position = UDim2.new(1, -50, 0.5, -10)
statusIndicator.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
statusIndicator.Text = "OFF"
statusIndicator.TextColor3 = Color3.fromRGB(255, 255, 255)
statusIndicator.TextSize = 10
statusIndicator.Font = Enum.Font.GothamBold
statusIndicator.BorderSizePixel = 0
statusIndicator.Parent = eventMoneyBtn

local indicatorCorner = Instance.new("UICorner")
indicatorCorner.CornerRadius = UDim.new(0, 5)
indicatorCorner.Parent = statusIndicator

local timerDisplay = Instance.new("Frame")
timerDisplay.Size = UDim2.new(1, 0, 0, 30)
timerDisplay.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
timerDisplay.BorderSizePixel = 0
timerDisplay.Visible = false
timerDisplay.LayoutOrder = 2
timerDisplay.Parent = contentFrame

local timerCorner = Instance.new("UICorner")
timerCorner.CornerRadius = UDim.new(0, 6)
timerCorner.Parent = timerDisplay

local timerLabel = Instance.new("TextLabel")
timerLabel.Name = "TimerLabel"
timerLabel.Size = UDim2.new(1, -10, 1, 0)
timerLabel.Position = UDim2.new(0, 5, 0, 0)
timerLabel.BackgroundTransparency = 1
timerLabel.Font = Enum.Font.GothamBold
timerLabel.TextSize = 12
timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
timerLabel.Text = "Waiting..."
timerLabel.TextXAlignment = Enum.TextXAlignment.Center
timerLabel.RichText = true
timerLabel.Parent = timerDisplay

local statusDisplay = Instance.new("Frame")
statusDisplay.Size = UDim2.new(1, 0, 0, 50)
statusDisplay.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
statusDisplay.BorderSizePixel = 0
statusDisplay.Visible = false
statusDisplay.LayoutOrder = 3
statusDisplay.Parent = contentFrame

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 6)
statusCorner.Parent = statusDisplay

local statusText = Instance.new("TextLabel")
statusText.Name = "StatusText"
statusText.Size = UDim2.new(1, -10, 0, 20)
statusText.Position = UDim2.new(0, 5, 0, 5)
statusText.BackgroundTransparency = 1
statusText.Text = "Sẵn sàng..."
statusText.TextColor3 = Color3.fromRGB(200, 200, 200)
statusText.TextSize = 10
statusText.Font = Enum.Font.Gotham
statusText.TextXAlignment = Enum.TextXAlignment.Left
statusText.Parent = statusDisplay

local progressBg = Instance.new("Frame")
progressBg.Size = UDim2.new(1, -10, 0, 18)
progressBg.Position = UDim2.new(0, 5, 0, 27)
progressBg.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
progressBg.BorderSizePixel = 0
progressBg.Parent = statusDisplay

local progCorner = Instance.new("UICorner")
progCorner.CornerRadius = UDim.new(0, 5)
progCorner.Parent = progressBg

local progressFill = Instance.new("Frame")
progressFill.Name = "ProgressFill"
progressFill.Size = UDim2.new(0, 0, 1, 0)
progressFill.BackgroundColor3 = Color3.fromRGB(80, 150, 255)
progressFill.BorderSizePixel = 0
progressFill.Parent = progressBg

local progFillCorner = Instance.new("UICorner")
progFillCorner.CornerRadius = UDim.new(0, 5)
progFillCorner.Parent = progressFill

local progressText = Instance.new("TextLabel")
progressText.Name = "ProgressText"
progressText.Size = UDim2.new(1, 0, 1, 0)
progressText.BackgroundTransparency = 1
progressText.Text = "0%"
progressText.TextColor3 = Color3.fromRGB(255, 255, 255)
progressText.TextSize = 9
progressText.Font = Enum.Font.GothamBold
progressText.ZIndex = 2
progressText.Parent = progressBg

-- ============================================
-- ARCADE EVENT BUTTON (GIỐNG MONEY EVENT)
-- ============================================

local arcadeBtn = Instance.new("TextButton")
arcadeBtn.Name = "ArcadeBtn"
arcadeBtn.Size = UDim2.new(1, 0, 0, 35)
arcadeBtn.BackgroundColor3 = Color3.fromRGB(40, 30, 50)
arcadeBtn.Text = ""
arcadeBtn.BorderSizePixel = 0
arcadeBtn.LayoutOrder = 4
arcadeBtn.Parent = contentFrame

local arcadeBtnCorner = Instance.new("UICorner")
arcadeBtnCorner.CornerRadius = UDim.new(0, 8)
arcadeBtnCorner.Parent = arcadeBtn

local arcadeBtnStroke = Instance.new("UIStroke")
arcadeBtnStroke.Color = Color3.fromRGB(138, 43, 226)
arcadeBtnStroke.Thickness = 1.5
arcadeBtnStroke.Parent = arcadeBtn

local arcadeBtnLabel = Instance.new("TextLabel")
arcadeBtnLabel.Size = UDim2.new(1, -50, 1, 0)
arcadeBtnLabel.Position = UDim2.new(0, 10, 0, 0)
arcadeBtnLabel.BackgroundTransparency = 1
arcadeBtnLabel.Text = "🎮 Arcade Event"
arcadeBtnLabel.TextColor3 = Color3.fromRGB(138, 43, 226)
arcadeBtnLabel.TextSize = 13
arcadeBtnLabel.Font = Enum.Font.GothamBold
arcadeBtnLabel.TextXAlignment = Enum.TextXAlignment.Left
arcadeBtnLabel.Parent = arcadeBtn

local arcadeStatusIndicator = Instance.new("TextLabel")
arcadeStatusIndicator.Name = "ArcadeStatusIndicator"
arcadeStatusIndicator.Size = UDim2.new(0, 40, 0, 20)
arcadeStatusIndicator.Position = UDim2.new(1, -50, 0.5, -10)
arcadeStatusIndicator.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
arcadeStatusIndicator.Text = "OFF"
arcadeStatusIndicator.TextColor3 = Color3.fromRGB(255, 255, 255)
arcadeStatusIndicator.TextSize = 10
arcadeStatusIndicator.Font = Enum.Font.GothamBold
arcadeStatusIndicator.BorderSizePixel = 0
arcadeStatusIndicator.Parent = arcadeBtn

local arcadeIndicatorCorner = Instance.new("UICorner")
arcadeIndicatorCorner.CornerRadius = UDim.new(0, 5)
arcadeIndicatorCorner.Parent = arcadeStatusIndicator

local arcadeTimerDisplay = Instance.new("Frame")
arcadeTimerDisplay.Size = UDim2.new(1, 0, 0, 30)
arcadeTimerDisplay.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
arcadeTimerDisplay.BorderSizePixel = 0
arcadeTimerDisplay.Visible = false
arcadeTimerDisplay.LayoutOrder = 5
arcadeTimerDisplay.Parent = contentFrame

local arcadeTimerCorner = Instance.new("UICorner")
arcadeTimerCorner.CornerRadius = UDim.new(0, 6)
arcadeTimerCorner.Parent = arcadeTimerDisplay

local arcadeTimerLabel = Instance.new("TextLabel")
arcadeTimerLabel.Name = "ArcadeTimerLabel"
arcadeTimerLabel.Size = UDim2.new(1, -10, 1, 0)
arcadeTimerLabel.Position = UDim2.new(0, 5, 0, 0)
arcadeTimerLabel.BackgroundTransparency = 1
arcadeTimerLabel.Font = Enum.Font.GothamBold
arcadeTimerLabel.TextSize = 12
arcadeTimerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
arcadeTimerLabel.Text = "Waiting..."
arcadeTimerLabel.TextXAlignment = Enum.TextXAlignment.Center
arcadeTimerLabel.RichText = true
arcadeTimerLabel.Parent = arcadeTimerDisplay

-- ============================================
-- BAT BUTTON
-- ============================================

local batBtn = Instance.new("TextButton")
batBtn.Name = "BatBtn"
batBtn.Size = UDim2.new(1, 0, 0, 35)
batBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
batBtn.Text = ""
batBtn.BorderSizePixel = 0
batBtn.LayoutOrder = 6
batBtn.Parent = contentFrame

local batBtnCorner = Instance.new("UICorner")
batBtnCorner.CornerRadius = UDim.new(0, 8)
batBtnCorner.Parent = batBtn

local batBtnStroke = Instance.new("UIStroke")
batBtnStroke.Color = Color3.fromRGB(100, 100, 100)
batBtnStroke.Thickness = 1.5
batBtnStroke.Parent = batBtn

local batBtnLabel = Instance.new("TextLabel")
batBtnLabel.Size = UDim2.new(1, -50, 1, 0)
batBtnLabel.Position = UDim2.new(0, 10, 0, 0)
batBtnLabel.BackgroundTransparency = 1
batBtnLabel.Text = "Gậy Khủng Bố"
batBtnLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
batBtnLabel.TextSize = 13
batBtnLabel.Font = Enum.Font.GothamBold
batBtnLabel.TextXAlignment = Enum.TextXAlignment.Left
batBtnLabel.Parent = batBtn

local batStatusIndicator = Instance.new("TextLabel")
batStatusIndicator.Name = "BatStatusIndicator"
batStatusIndicator.Size = UDim2.new(0, 40, 0, 20)
batStatusIndicator.Position = UDim2.new(1, -50, 0.5, -10)
batStatusIndicator.BackgroundColor3 = Color3.fromRGB(60, 200, 60)
batStatusIndicator.Text = "ON"
batStatusIndicator.TextColor3 = Color3.fromRGB(255, 255, 255)
batStatusIndicator.TextSize = 10
batStatusIndicator.Font = Enum.Font.GothamBold
batStatusIndicator.BorderSizePixel = 0
batStatusIndicator.Parent = batBtn

local batIndicatorCorner = Instance.new("UICorner")
batIndicatorCorner.CornerRadius = UDim.new(0, 5)
batIndicatorCorner.Parent = batStatusIndicator

local batSettings = Instance.new("Frame")
batSettings.Size = UDim2.new(1, 0, 0, 55)
batSettings.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
batSettings.BorderSizePixel = 0
batSettings.Visible = true
batSettings.LayoutOrder = 7
batSettings.Parent = contentFrame

local batSettingsCorner = Instance.new("UICorner")
batSettingsCorner.CornerRadius = UDim.new(0, 6)
batSettingsCorner.Parent = batSettings

local sizeLabel = Instance.new("TextLabel")
sizeLabel.Size = UDim2.new(1, -16, 0, 14)
sizeLabel.Position = UDim2.new(0, 8, 0, 8)
sizeLabel.BackgroundTransparency = 1
sizeLabel.Font = Enum.Font.Gotham
sizeLabel.TextSize = 11
sizeLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
sizeLabel.TextXAlignment = Enum.TextXAlignment.Left
sizeLabel.Text = "Size: x" .. SIZE_MULTIPLIER
sizeLabel.Parent = batSettings

local TRACK_W = 244
local track = Instance.new("Frame")
track.Size = UDim2.new(0, TRACK_W, 0, 6)
track.Position = UDim2.new(0, 8, 0, 30)
track.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
track.BorderSizePixel = 0
track.Parent = batSettings

local trackCorner = Instance.new("UICorner")
trackCorner.CornerRadius = UDim.new(0, 3)
trackCorner.Parent = track

local fill = Instance.new("Frame")
fill.Size = UDim2.new(0, 0, 1, 0)
fill.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
fill.BorderSizePixel = 0
fill.Parent = track

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0, 3)
fillCorner.Parent = fill

local thumb = Instance.new("Frame")
thumb.Size = UDim2.new(0, 12, 0, 18)
thumb.AnchorPoint = Vector2.new(0.5, 0.5)
thumb.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
thumb.BorderSizePixel = 0
thumb.Parent = track

local thumbCorner = Instance.new("UICorner")
thumbCorner.CornerRadius = UDim.new(0, 4)
thumbCorner.Parent = thumb

-- ============================================
-- BAT LOGIC
-- ============================================

local function ratioFromSize(s)
    return math.log(s / MIN_SIZE) / math.log(MAX_SIZE / MIN_SIZE)
end

local function sizeFromRatio(r)
    return math.floor(MIN_SIZE * (MAX_SIZE / MIN_SIZE) ^ r + 0.5)
end

local function updateSlider()
    local px = math.clamp(ratioFromSize(SIZE_MULTIPLIER) * TRACK_W, 0, TRACK_W)
    fill.Size = UDim2.new(0, px, 1, 0)
    thumb.Position = UDim2.new(0, px, 0.5, 0)
    sizeLabel.Text = "Size: x" .. SIZE_MULTIPLIER
end

local function expandTool(tool)
    if not BAT_ENABLED then return end
    for _, part in ipairs(tool:GetDescendants()) do
        if part:IsA("BasePart") then
            if not originalSizes[part] then
                originalSizes[part] = part.Size
            end
            part.Size = originalSizes[part] * SIZE_MULTIPLIER
        end
    end
end

local function restoreTool(tool)
    for _, part in ipairs(tool:GetDescendants()) do
        if part:IsA("BasePart") and originalSizes[part] then
            part.Size = originalSizes[part]
            originalSizes[part] = nil
        end
    end
end

local function applyMultiplier()
    if BAT_ENABLED and currentTool then
        restoreTool(currentTool)
        originalSizes = {}
        task.wait(0.05)
        expandTool(currentTool)
    end
end

local sliding = false
local function setFromX(absX)
    local ratio = math.clamp((absX - track.AbsolutePosition.X) / TRACK_W, 0, 1)
    SIZE_MULTIPLIER = math.clamp(sizeFromRatio(ratio), MIN_SIZE, MAX_SIZE)
    updateSlider()
    applyMultiplier()
end

track.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        sliding = true
        setFromX(i.Position.X)
    end
end)

track.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        sliding = false
    end
end)

UIS.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        sliding = false
    end
end)

UIS.InputChanged:Connect(function(i)
    if sliding and i.UserInputType == Enum.UserInputType.MouseMovement then
        setFromX(i.Position.X)
    end
end)

local function setupChar(char)
    char.ChildAdded:Connect(function(tool)
        if tool:IsA("Tool") then
            currentTool = tool
            task.wait(0.1)
            expandTool(tool)
        end
    end)
    char.ChildRemoved:Connect(function(tool)
        if tool:IsA("Tool") then
            restoreTool(tool)
            currentTool = nil
        end
    end)
end

if player.Character then
    setupChar(player.Character)
end

player.CharacterAdded:Connect(function(newChar)
    setupChar(newChar)
end)

batBtn.MouseButton1Click:Connect(function()
    BAT_ENABLED = not BAT_ENABLED
    if BAT_ENABLED then
        batStatusIndicator.Text = "ON"
        batStatusIndicator.BackgroundColor3 = Color3.fromRGB(60, 200, 60)
        batBtnStroke.Color = Color3.fromRGB(60, 200, 60)
        batSettings.Visible = true
        if currentTool then expandTool(currentTool) end
    else
        batStatusIndicator.Text = "OFF"
        batStatusIndicator.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
        batBtnStroke.Color = Color3.fromRGB(100, 100, 100)
        batSettings.Visible = false
        if currentTool then restoreTool(currentTool) end
    end
end)

-- ============================================
-- MONEY EVENT LOGIC (GỐC)
-- ============================================

local function formatTime(totalSeconds)
    if totalSeconds <= 0 then return "00:00" end
    local minutes = math.floor(totalSeconds / 60)
    local seconds = totalSeconds % 60
    return string.format("%02d:%02d", minutes, seconds)
end

local function getMoneyEventTime()
    local success, result = pcall(function()
        local eventTimers = workspace:FindFirstChild("EventTimers")
        if not eventTimers then return nil end
        
        for _, part in pairs(eventTimers:GetChildren()) do
            if part:IsA("BasePart") then
                local surfaceGui = part:FindFirstChild("SurfaceGui")
                if surfaceGui then
                    local frame = surfaceGui:FindFirstChild("Frame")
                    if frame then
                        for _, textLabel in pairs(frame:GetChildren()) do
                            if textLabel:IsA("TextLabel") then
                                local text = textLabel.Text
                                if text:upper():find("MONEY") then
                                    local timePattern = "(%d+):(%d+)"
                                    local time1, time2 = text:match(timePattern)
                                    if time1 and time2 then
                                        local minutes = tonumber(time1)
                                        local seconds = tonumber(time2)
                                        local totalSeconds = minutes * 60 + seconds
                                        return {
                                            minutes = minutes,
                                            seconds = seconds,
                                            totalSeconds = totalSeconds,
                                            rawText = text
                                        }
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        return nil
    end)
    
    if success and result then return result end
    return nil
end

local function getActiveEventTime()
    local success, result = pcall(function()
        local hud = player.PlayerGui:FindFirstChild("HUD")
        if not hud then return nil end
        
        local bottomRight = hud:FindFirstChild("BottomRight")
        if not bottomRight then return nil end
        
        local buffs = bottomRight:FindFirstChild("Buffs")
        if not buffs then return nil end
        
        for _, template in pairs(buffs:GetChildren()) do
            if template:IsA("ImageButton") then
                if template.Image == MONEY_EVENT_ICON then
                    local label = template:FindFirstChild("Label")
                    if label and label:IsA("TextLabel") and label.Visible then
                        local text = label.Text
                        if text:match("%d+:%d+") and text ~= "00:00" then
                            local timePattern = "(%d+):(%d+)"
                            local minutes, seconds = text:match(timePattern)
                            if minutes and seconds then
                                local totalSeconds = tonumber(minutes) * 60 + tonumber(seconds)
                                if totalSeconds > 0 and totalSeconds <= 600 then
                                    return {
                                        minutes = tonumber(minutes),
                                        seconds = tonumber(seconds),
                                        totalSeconds = totalSeconds,
                                        isActive = true,
                                        source = label:GetFullName()
                                    }
                                end
                            end
                        end
                    end
                end
            end
        end
        return nil
    end)
    
    if success and result then return result end
    return nil
end

local function updateTimer()
    if not AUTO_ENABLED then
        timerDisplay.Visible = false
        statusDisplay.Visible = false
        return
    end
    
    local upcomingEvent = getMoneyEventTime()
    local activeEvent = getActiveEventTime()
    
    if activeEvent then
        local displayTime = formatTime(activeEvent.totalSeconds)
        timerLabel.Text = string.format('<font color="#00FF00">ACTIVE</font> <font color="#888">▸</font> <font color="#00FF00">%s</font>', displayTime)
        timerDisplay.BackgroundColor3 = Color3.fromRGB(20, 50, 20)
        timerDisplay.Visible = true
        
        if not isAutoRunning then
            startAutoFarm()
        end
    elseif upcomingEvent then
        local displayTime = formatTime(upcomingEvent.totalSeconds)
        timerLabel.Text = string.format('<font color="#FFD700">MONEY</font> <font color="#888">▸</font> <font color="#FFD700">%s</font>', displayTime)
        
        if upcomingEvent.totalSeconds <= 60 then
            timerDisplay.BackgroundColor3 = Color3.fromRGB(50, 20, 20)
        elseif upcomingEvent.totalSeconds <= 300 then
            timerDisplay.BackgroundColor3 = Color3.fromRGB(40, 30, 20)
        else
            timerDisplay.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        end
        timerDisplay.Visible = true
    else
        timerLabel.Text = '<font color="#888">Waiting...</font>'
        timerDisplay.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        timerDisplay.Visible = true
    end
end

local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")
local noclipConnection = nil
local currentTargetIndex = 1
local completedTargets = {}
local startTime = 0
local isPaused = false
local detectedNotification = false
local skipRequested = false
local previousGUITexts = {}
local detectionCounter = 0
local currentDetectionCounter = 0
local lastActivityTime = tick()
local watchdogConnection = nil
local notificationConnection = nil

local function enableNoclip()
    if noclipConnection then return end
    noclipConnection = RunService.Stepped:Connect(function()
        if not isAutoRunning then return end
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)
end

local function disableNoclip()
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
end

local function updateFarmUI(statusStr)
    if statusStr then statusText.Text = statusStr end
end

local function updateProgress(percent)
    progressText.Text = string.format("%d%%", math.floor(percent))
    progressFill:TweenSize(
        UDim2.new(percent / 100, 0, 1, 0),
        Enum.EasingDirection.Out,
        Enum.EasingStyle.Quad,
        0.2,
        true
    )
end

local function teleportTo(x, y, z)
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
    
    humanoidRootPart.CFrame = CFrame.new(x, y, z)
    humanoidRootPart.Velocity = Vector3.new(0, 0, 0)
    humanoidRootPart.RotVelocity = Vector3.new(0, 0, 0)
    humanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    humanoidRootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
end

local function setFakeWalking(enabled)
    if enabled then
        humanoid.WalkSpeed = 16
    else
        humanoid.WalkSpeed = 16
    end
end

local function checkForNotification()
    for _, gui in pairs(player.PlayerGui:GetDescendants()) do
        if gui:IsA("TextLabel") and gui.Visible and gui.Parent then
            local text = gui.Text
            local fullName = gui:GetFullName()
            
            if text and text ~= "" and #text > 10 then
                local hasPattern = false
                
                for _, pattern in ipairs(CONFIG.DETECTION_PATTERNS) do
                    if string.find(text, pattern) then
                        hasPattern = true
                        break
                    end
                end
                
                if hasPattern then
                    local pos = gui.AbsolutePosition
                    local size = gui.AbsoluteSize
                    local screenCenter = workspace.CurrentCamera.ViewportSize / 2
                    
                    local distFromCenter = math.abs(pos.X + size.X/2 - screenCenter.X) + math.abs(pos.Y + size.Y/2 - screenCenter.Y)
                    
                    if distFromCenter < 400 then
                        local lastCounter = previousGUITexts[fullName]
                        
                        if not lastCounter or lastCounter < currentDetectionCounter then
                            previousGUITexts[fullName] = currentDetectionCounter
                            return true, text
                        end
                    end
                end
            end
        end
    end
    return false, nil
end

local function resetWatchdog()
    lastActivityTime = tick()
end

local function startWatchdog()
    if watchdogConnection then return end
    watchdogConnection = RunService.Heartbeat:Connect(function()
        if not isAutoRunning then return end
        if tick() - lastActivityTime > 30 then
            updateFarmUI("Phát hiện đơ - Khởi động lại")
            lastActivityTime = tick()
            stopNotificationListener()
            disableNoclip()
            task.wait(2)
            if currentTargetIndex > #TARGETS then
                currentTargetIndex = 1
                completedTargets = {}
            end
            executeAutoFarm()
        end
    end)
end

local function stopWatchdog()
    if watchdogConnection then
        watchdogConnection:Disconnect()
        watchdogConnection = nil
    end
end

local function startNotificationListener()
    if notificationConnection then return end
    detectedNotification = false
    
    notificationConnection = RunService.Heartbeat:Connect(function()
        if detectedNotification then return end
        
        local found, text = checkForNotification()
        if found then
            detectedNotification = true
            updateFarmUI(string.format("Phát hiện: %s", text:sub(1, 20)))
        end
    end)
end

local function stopNotificationListener()
    if notificationConnection then
        notificationConnection:Disconnect()
        notificationConnection = nil
    end
end

local function oscillateAtPoint(x, y, z, maxDuration)
    local oscillationTime = 0
    local startTime = tick()
    detectedNotification = false
    
    previousGUITexts = {}
    
    detectionCounter = detectionCounter + 1
    currentDetectionCounter = detectionCounter
    
    task.wait(1.5)
    
    startNotificationListener()
    setFakeWalking(true)
    resetWatchdog()
    
    while not detectedNotification and isAutoRunning do
        resetWatchdog()
        
        if skipRequested then break end
        if tick() - startTime > maxDuration then
            updateFarmUI("Timeout - Chuyển điểm")
            break
        end
        
        if not character or not character.Parent then
            updateFarmUI("Nhân vật mất!")
            stopNotificationListener()
            return false
        end
        
        local humanoidCheck = character:FindFirstChildOfClass("Humanoid")
        if not humanoidCheck or humanoidCheck.Health <= 0 then
            updateFarmUI("Nhân vật chết!")
            stopNotificationListener()
            return false
        end
        
        local currentPos = humanoidRootPart.Position
        local targetPos = Vector3.new(x, y, z)
        local dist = (currentPos - targetPos).Magnitude
        
        if dist > CONFIG.VERIFY_RADIUS then
            updateFarmUI("Bị dật xa, tele lại...")
            teleportTo(x, y + 2, z)
            oscillationTime = 0
        else
            oscillationTime = oscillationTime + 0.1
            local offsetX = math.sin(oscillationTime * CONFIG.OSCILLATION_SPEED) * CONFIG.OSCILLATION
            local offsetZ = math.cos(oscillationTime * CONFIG.OSCILLATION_SPEED) * CONFIG.OSCILLATION
            teleportTo(x + offsetX, y + 2, z + offsetZ)
            local elapsed = tick() - startTime
            updateFarmUI(string.format("Chờ thông báo... %.1fs", elapsed))
        end
        
        task.wait(0.1)
    end
    
    stopNotificationListener()
    setFakeWalking(false)
    teleportTo(x, y + 2, z)
    return detectedNotification
end

function executeAutoFarm()
    if not AUTO_ENABLED or not isAutoRunning then return end
    
    enableNoclip()
    startWatchdog()
    resetWatchdog()
    
    if startTime == 0 then
        startTime = tick()
    end
    
    while currentTargetIndex <= #TARGETS and isAutoRunning and AUTO_ENABLED do
        resetWatchdog()
        local target = TARGETS[currentTargetIndex]
        
        if completedTargets[target.name] then
            currentTargetIndex = currentTargetIndex + 1
            continue
        end
        
        updateProgress(((currentTargetIndex - 1) / #TARGETS) * 100)
        updateFarmUI(string.format("Tele đến %s", target.name))
        
        enableNoclip()
        task.wait(0.1)
        teleportTo(target.x, target.y + 2, target.z)
        task.wait(0.2)
        
        local verified = oscillateAtPoint(target.x, target.y, target.z, CONFIG.VERIFY_TIME)
        
        if skipRequested then
            skipRequested = false
            completedTargets[target.name] = true
            updateFarmUI(string.format("Bỏ qua %s", target.name))
            updateProgress((currentTargetIndex / #TARGETS) * 100)
            task.wait(0.5)
            currentTargetIndex = currentTargetIndex + 1
        elseif verified then
            completedTargets[target.name] = true
            updateFarmUI(string.format("Xong %s!", target.name))
            updateProgress((currentTargetIndex / #TARGETS) * 100)
            
            currentTargetIndex = currentTargetIndex + 1
            
            updateFarmUI("Reset để tránh bug thông báo...")
            task.wait(0.5)
            humanoid.Health = 0
        else
            updateFarmUI(string.format("Timeout %s - Làm lại", target.name))
            task.wait(0.5)
        end
    end
    
    local completedCount = 0
    for _ in pairs(completedTargets) do
        completedCount = completedCount + 1
    end
    
    if completedCount >= #TARGETS then
        updateProgress(100)
        updateFarmUI("HOÀN THÀNH! - Đổi server...")
        task.wait(3)
        currentTargetIndex = 1
        completedTargets = {}
        doServerHop()
    else
        updateFarmUI(string.format("Đã xong %d/%d - Làm nốt", completedCount, #TARGETS))
        task.wait(2)
        currentTargetIndex = 1
        executeAutoFarm()
    end
    
    disableNoclip()
    stopWatchdog()
    isAutoRunning = false
end

function startAutoFarm()
    if isAutoRunning then return end
    isAutoRunning = true
    statusDisplay.Visible = true
    timerDisplay.Visible = false
    currentTargetIndex = 1
    completedTargets = {}
    updateFarmUI("Bắt đầu Auto Farm...")
    updateProgress(0)
    task.spawn(executeAutoFarm)
end

function stopAutoFarm()
    isAutoRunning = false
    disableNoclip()
    stopWatchdog()
    stopNotificationListener()
    statusDisplay.Visible = false
    if AUTO_ENABLED then
        timerDisplay.Visible = true
    end
    updateFarmUI("Đã dừng")
end

local PlaceId = game.PlaceId

function doServerHop()
    updateFarmUI("Đang tìm server mới...")
    
    local currentJobId = game.JobId
    local cursor = ""
    local found = nil
    
    repeat
        local url = "https://games.roblox.com/v1/games/"..PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
        if cursor ~= "" then
            url = url .. "&cursor=" .. cursor
        end
        
        local data = HttpService:JSONDecode(game:HttpGet(url))
        
        for _, s in ipairs(data.data) do
            if s.id ~= currentJobId and s.playing < s.maxPlayers then
                found = s.id
                break
            end
        end
        
        cursor = data.nextPageCursor
    until found or not cursor
    
    if found then
        updateFarmUI("Tìm thấy server! Đang teleport...")
        task.wait(1)
        TeleportService:TeleportToPlaceInstance(PlaceId, found)
    end
end

local function refreshEventMoneyBtn()
    if AUTO_ENABLED then
        statusIndicator.Text = "ON"
        statusIndicator.BackgroundColor3 = Color3.fromRGB(60, 200, 60)
        btnStroke.Color = Color3.fromRGB(60, 200, 60)
        eventMoneyBtn.BackgroundColor3 = Color3.fromRGB(20, 50, 20)
        timerDisplay.Visible = true
    else
        statusIndicator.Text = "OFF"
        statusIndicator.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
        btnStroke.Color = Color3.fromRGB(255, 215, 0)
        eventMoneyBtn.BackgroundColor3 = Color3.fromRGB(60, 50, 20)
        timerDisplay.Visible = false
        statusDisplay.Visible = false
    end
end

eventMoneyBtn.MouseButton1Click:Connect(function()
    AUTO_ENABLED = not AUTO_ENABLED
    _G.AutoEventEnabled = AUTO_ENABLED
    refreshEventMoneyBtn()
    
    if not AUTO_ENABLED then
        stopAutoFarm()
    end
end)

-- ============================================
-- ARCADE EVENT LOGIC (COPY GỐC TỪ SCRIPT 3)
-- ============================================

local function getArcadeEventTime()
    local success, result = pcall(function()
        local eventTimers = workspace:FindFirstChild("EventTimers")
        if not eventTimers then return nil end
        
        for _, part in pairs(eventTimers:GetChildren()) do
            if part:IsA("BasePart") then
                local surfaceGui = part:FindFirstChild("SurfaceGui")
                if surfaceGui then
                    local frame = surfaceGui:FindFirstChild("Frame")
                    if frame then
                        for _, textLabel in pairs(frame:GetChildren()) do
                            if textLabel:IsA("TextLabel") then
                                local text = textLabel.Text
                                if text:upper():find("ARCADE") then
                                    local timePattern = "(%d+):(%d+)"
                                    local time1, time2 = text:match(timePattern)
                                    if time1 and time2 then
                                        local minutes = tonumber(time1)
                                        local seconds = tonumber(time2)
                                        local totalSeconds = minutes * 60 + seconds
                                        return {
                                            minutes = minutes,
                                            seconds = seconds,
                                            totalSeconds = totalSeconds,
                                            rawText = text
                                        }
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        return nil
    end)
    
    if success and result then return result end
    return nil
end

local function getActiveArcadeEventTime()
    local success, result = pcall(function()
        local hud = player.PlayerGui:FindFirstChild("HUD")
        if not hud then return nil end
        
        local bottomRight = hud:FindFirstChild("BottomRight")
        if not bottomRight then return nil end
        
        local buffs = bottomRight:FindFirstChild("Buffs")
        if not buffs then return nil end
        
        for _, template in pairs(buffs:GetChildren()) do
            if template:IsA("ImageButton") then
                local label = template:FindFirstChild("Label")
                if label and label:IsA("TextLabel") and label.Visible then
                    local text = label.Text
                    
                    if text:match("%d+:%d+") and text ~= "00:00" then
                        local timePattern = "(%d+):(%d+)"
                        local minutes, seconds = text:match(timePattern)
                        
                        if minutes and seconds then
                            local totalSeconds = tonumber(minutes) * 60 + tonumber(seconds)
                            
                            -- KHÔNG PHẢI Money Event
                            if template.Image ~= MONEY_EVENT_ICON and totalSeconds > 0 and totalSeconds <= 600 then
                                return {
                                    minutes = tonumber(minutes),
                                    seconds = tonumber(seconds),
                                    totalSeconds = totalSeconds,
                                    isActive = true
                                }
                            end
                        end
                    end
                end
            end
        end
        return nil
    end)
    
    if success and result then return result end
    return nil
end

local function updateArcadeTimer()
    if not ARCADE_ENABLED then
        arcadeTimerDisplay.Visible = false
        return
    end
    
    local upcomingEvent = getArcadeEventTime()
    local activeEvent = getActiveArcadeEventTime()
    
    if activeEvent then
        local displayTime = formatTime(activeEvent.totalSeconds)
        arcadeTimerLabel.Text = string.format('<font color="#00FF00">ACTIVE</font> <font color="#888">▸</font> <font color="#00FF00">%s</font>', displayTime)
        arcadeTimerDisplay.BackgroundColor3 = Color3.fromRGB(20, 50, 20)
        arcadeTimerDisplay.Visible = true
        
        -- CHỈ CHẠY KHI ACTIVE
        if not arcadeRunning then
            startArcadeCollect()
        end
    elseif upcomingEvent then
        local displayTime = formatTime(upcomingEvent.totalSeconds)
        arcadeTimerLabel.Text = string.format('<font color="#8A2BE2">ARCADE</font> <font color="#888">▸</font> <font color="#8A2BE2">%s</font>', displayTime)
        
        if upcomingEvent.totalSeconds <= 60 then
            arcadeTimerDisplay.BackgroundColor3 = Color3.fromRGB(50, 20, 40)
        elseif upcomingEvent.totalSeconds <= 300 then
            arcadeTimerDisplay.BackgroundColor3 = Color3.fromRGB(40, 25, 35)
        else
            arcadeTimerDisplay.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        end
        arcadeTimerDisplay.Visible = true
        -- UPCOMING = CHỈ HIỆN, KHÔNG CHẠY
    else
        arcadeTimerLabel.Text = '<font color="#888">Waiting...</font>'
        arcadeTimerDisplay.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        arcadeTimerDisplay.Visible = true
    end
end

-- ============================================
-- ARCADE COLLECT LOGIC (GỐC 100%)
-- ============================================

local function setupNoFall(character)
    local hrp = character:WaitForChild("HumanoidRootPart", 5)
    if not hrp then return end
    
    for _, obj in pairs(hrp:GetChildren()) do
        if obj:IsA("BodyVelocity") then
            obj:Destroy()
        end
    end
    
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(0, math.huge, 0)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.P = 10000
    bodyVelocity.Parent = hrp
    
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end

local function projectOntoLine(P)
    local AP = P - A
    local t = math.clamp(AP:Dot(AB) / AB:Dot(AB), 0, 1)
    return A + AB * t
end

local function distanceToLine(P)
    return (P - projectOntoLine(P)).Magnitude
end

local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Include

local function hasTsunami()
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp or SAFE_RADIUS == 0 then return false end
    
    if distanceToLine(hrp.Position) <= 2 then return false end
    
    local tsunamis = workspace:FindFirstChild("ActiveTsunamis")
    if not tsunamis then return false end
    
    overlapParams.FilterDescendantsInstances = {tsunamis}
    
    local parts = workspace:GetPartBoundsInRadius(hrp.Position, SAFE_RADIUS, overlapParams)
    
    return #parts > 0
end

local function scanItems()
    local items = {}
    
    local region = Region3.new(BOX_MIN, BOX_MAX):ExpandToGrid(4)
    local parts = workspace:FindPartsInRegion3(region, nil, math.huge)
    
    for _, obj in pairs(parts) do
        local name = obj.Name
        local priority = 999
        
        if name == "Rayshield" or name == "Ticket" or (obj.Parent and obj.Parent.Name:find("Ticket")) then
            priority = 1
        elseif name == "Game Console" then
            priority = 2
        else
            continue
        end
        
        table.insert(items, {obj = obj, priority = priority})
    end
    
    table.sort(items, function(a, b)
        if a.priority ~= b.priority then return a.priority < b.priority end
        return (projectOntoLine(a.obj.Position) - A).Magnitude < (projectOntoLine(b.obj.Position) - A).Magnitude
    end)
    
    return items
end

local function findNearby(center, radius)
    local nearby = {}
    
    local regionMin = center - Vector3.new(radius, 50, radius)
    local regionMax = center + Vector3.new(radius, 50, radius)
    local region = Region3.new(regionMin, regionMax):ExpandToGrid(4)
    
    local parts = workspace:FindPartsInRegion3(region, nil, math.huge)
    
    for _, obj in pairs(parts) do
        local dist = (obj.Position - center).Magnitude
        if dist > radius then continue end
        
        local name = obj.Name
        local priority = 999
        
        if name == "Rayshield" or name == "Ticket" or (obj.Parent and obj.Parent.Name:find("Ticket")) then
            priority = 1
        elseif name == "Game Console" then
            priority = 2
        else
            continue
        end
        
        table.insert(nearby, {obj = obj, priority = priority, dist = dist})
    end
    
    table.sort(nearby, function(a, b)
        if a.priority ~= b.priority then return a.priority < b.priority end
        return a.dist < b.dist
    end)
    
    return nearby
end

local function flyTo(pos)
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local start = hrp.Position
    local dist = (pos - start).Magnitude
    if dist < 2 then
        hrp.CFrame = CFrame.new(pos)
        return
    end
    
    local duration = dist / FLY_SPEED
    local t0 = tick()
    
    while tick() - t0 < duration do
        hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then break end
        
        local alpha = (tick() - t0) / duration
        hrp.CFrame = CFrame.new(start:Lerp(pos, alpha))
        
        task.wait()
    end
    
    if hrp then
        hrp.CFrame = CFrame.new(pos)
    end
end

-- HÀM CHÍNH - LOGIC GỐC 100%
local function startCollectLogic()
    arcadeRunning = false
    task.wait(0.5)
    
    if not player.Character then return end
    arcadeRunning = true
    
    -- Xóa tường
    pcall(function()
        workspace:WaitForChild("DefaultMap_SharedInstances", 2):WaitForChild("VIPWalls", 2):ClearAllChildren()
    end)
    
    pcall(function()
        workspace:WaitForChild("ArcadeMap_SharedInstances", 2):WaitForChild("VIPWalls", 2):ClearAllChildren()
    end)
    
    if player.Character then
        setupNoFall(player.Character)
    end
    
    flyTo(A)
    local currentProj = A
    
    while ARCADE_ENABLED and arcadeRunning do
        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then break end
        
        if bodyVelocity and bodyVelocity.Parent then
            bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        end
        
        local all = scanItems()
        if #all == 0 then
            task.wait(2)
            continue
        end
        
        local target = all[1]
        if not target or not target.obj or not target.obj.Parent then
            task.wait(1)
            continue
        end
        
        local targetProj = projectOntoLine(target.obj.Position)
        
        if (targetProj - currentProj).Magnitude > 10 then
            flyTo(targetProj)
            currentProj = targetProj
        end
        
        local collected = 0
        
        while arcadeRunning and collected < 50 do
            hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then break end
            
            if hasTsunami() then
                print("🌊 TSUNAMI - TELEPORT VỀ!")
                local myProj = projectOntoLine(hrp.Position)
                
                hrp.CFrame = CFrame.new(myProj)
                currentProj = myProj
                
                local waitCount = 0
                while hasTsunami() and waitCount < 20 do
                    task.wait(0.5)
                    waitCount = waitCount + 1
                end
                
                print("✅ An toàn - Tiếp tục")
                break
            end
            
            local near = findNearby(hrp.Position, COLLECT_RADIUS)
            
            if #near == 0 then
                local myProj = projectOntoLine(hrp.Position)
                if (myProj - hrp.Position).Magnitude > 5 then
                    flyTo(myProj)
                    currentProj = myProj
                end
                break
            end
            
            local item = near[1]
            if item and item.obj and item.obj.Parent then
                flyTo(item.obj.Position)
                collected = collected + 1
                task.wait(0.2)
            else
                break
            end
            
            task.wait(0.05)
        end
        
        task.wait(0.2)
    end
end

function startArcadeCollect()
    if arcadeRunning then return end
    print("🎮 Starting Arcade Collect...")
    task.spawn(startCollectLogic)
end

function stopArcadeCollect()
    arcadeRunning = false
    print("🎮 Stopped Arcade Collect")
end

-- Heartbeat giữ không rơi
RunService.Heartbeat:Connect(function()
    if arcadeRunning then
        local char = player.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            
            if hrp then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
                
                if bodyVelocity and bodyVelocity.Parent then
                    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
                end
            end
        end
    end
end)

local function refreshArcadeBtn()
    if ARCADE_ENABLED then
        arcadeStatusIndicator.Text = "ON"
        arcadeStatusIndicator.BackgroundColor3 = Color3.fromRGB(60, 200, 60)
        arcadeBtnStroke.Color = Color3.fromRGB(138, 43, 226)
        arcadeBtn.BackgroundColor3 = Color3.fromRGB(30, 20, 40)
        arcadeTimerDisplay.Visible = true
    else
        arcadeStatusIndicator.Text = "OFF"
        arcadeStatusIndicator.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
        arcadeBtnStroke.Color = Color3.fromRGB(138, 43, 226)
        arcadeBtn.BackgroundColor3 = Color3.fromRGB(40, 30, 50)
        arcadeTimerDisplay.Visible = false
        stopArcadeCollect()
    end
end

arcadeBtn.MouseButton1Click:Connect(function()
    ARCADE_ENABLED = not ARCADE_ENABLED
    _G.ArcadeEventEnabled = ARCADE_ENABLED
    refreshArcadeBtn()
end)

-- ============================================
-- CLOSE & SETUP
-- ============================================

closeBtn.MouseButton1Click:Connect(function()
    AUTO_ENABLED = false
    ARCADE_ENABLED = false
    _G.AutoEventEnabled = false
    _G.ArcadeEventEnabled = false
    stopAutoFarm()
    stopArcadeCollect()
    screenGui:Destroy()
end)

local function setupCharacterDeath()
    local humanoidCheck = character:FindFirstChildOfClass("Humanoid")
    if humanoidCheck then
        humanoidCheck.Died:Connect(function()
            if isAutoRunning and currentTargetIndex <= #TARGETS then
                updateFarmUI("Bị chết - Chờ hồi sinh...")
                isPaused = true
                disableNoclip()
                stopNotificationListener()
            end
        end)
    end
end

player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    humanoid = character:WaitForChild("Humanoid")
    task.wait(2)
    setupCharacterDeath()
    
    if isPaused and currentTargetIndex <= #TARGETS then
        isPaused = false
        updateFarmUI("Hồi sinh - Tiếp tục...")
        task.wait(1)
        executeAutoFarm()
    end
    
    if arcadeRunning then
        setupNoFall(newChar)
        task.wait(1)
        startCollectLogic()
    end
end)

setupCharacterDeath()
refreshEventMoneyBtn()
refreshArcadeBtn()
updateSlider()

spawn(function()
    while wait(1) do
        pcall(updateTimer)
        pcall(updateArcadeTimer)
    end
end)



print("MAIN SCRIPT RUNNING")
