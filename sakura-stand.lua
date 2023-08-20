--hooks general
local kickHook 

kickHook = hookfunction(getrawmetatable(game.Players.LocalPlayer).__namecall, function(self, ...)
    local args = {...}

    if self == game.Players.LocalPlayer and tostring(getnamecallmethod()) == "Kick" then 
        return nil
    end 

    return kickHook(self, ...)
end)
--services variables
repeat task.wait() until game:IsLoaded()

local replicatedStorage = game:GetService("ReplicatedStorage")
local tweenService = game:GetService("TweenService")
local pathfindingService = game:GetService("PathfindingService")
--folders variables
local itemsFolder = workspace:WaitForChild("Item")
--window variables
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/ilovesordfactory/LinoriaLib/main/Library.lua"))()

local window = library:CreateWindow({
    Title = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name,
    AutoShow = true,
    Center = true,
    TabPadding = 6,
    MenuFadeTime = 0
})

game.CoreGui.ChildAdded:Connect(function(child)
    if child.Name == "Linoria" then 
        library:Unload()
    end 
end)
--util functions
local function getCharacter()
    return game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()
end

local function getRoot()
    return getCharacter():WaitForChild('HumanoidRootPart')
end

local function getGui()
    return game.Players.LocalPlayer:WaitForChild("PlayerGui")
end

local function getMag(targetPart)
    return (getRoot().Position - targetPart.Position).Magnitude
end

local function getHumanoid()
    return getCharacter():WaitForChild("Humanoid")
end

local function getClosest(name, parent)
    local closest, distance = nil, 9e9 

    for _, v in parent:GetChildren() do 
        if v.Name ~= name then continue end 
        if not v:IsA("BasePart") then continue end 

        if getMag(v) < distance then 
            distance = getMag(v)
            closest = v
        end     
    end     

    return closest
end
--farm variables
local livingFolder = workspace:WaitForChild("Living")
local farmingMob = false
--farm functions
local function farm_getSkillsFolder()
    local standName = game.Players.LocalPlayer.Data.StandName.Value
    
    local firstPart = tostring(standName:match("(%a+)%s"))
    local noSpaces = tostring(standName:gsub('%s', ""))
        
    if replicatedStorage:FindFirstChild(standName.."Remote") then 
        return  replicatedStorage:FindFirstChild(standName.."Remote")
    elseif replicatedStorage:FindFirstChild(firstPart.."Remote") then 
        return replicatedStorage:FindFirstChild(firstPart.."Remote")
    elseif replicatedStorage:FindFirstChild(noSpaces.."Remote") then
        return replicatedStorage:FindFirstChild(noSpaces.."Remote")
    end
end

local function farm_getSkills()
    local skillsFolder = farm_getSkillsFolder()
    local skills = {}

    for _, v in skillsFolder:GetChildren() do 
        table.insert(skills, v.Name)
    end 

    return skills
end

local function farm_getMobs()
    local bossGui = getGui():WaitForChild("BossHP")
    local mobs = {"Bandit", "Thug", "Attacking Dummy"}

    for _, v in bossGui:GetDescendants() do 
        if not v:IsA("TextLabel") then continue end 
        if v.Text == "N/A" then continue end 
        local bossName = v.Text:match("%p%p%p%s(%a+%s%a+)%s")

        if bossName == nil then 
            bossName = v.Text:gsub("%p", ""):gsub("%s", "")
        end 

        table.insert(mobs, tostring(bossName))
    end 

    return mobs
end

local function farm_activateFarm()
    if not Toggles.farm_farmMobs.Value then return end 

    while Toggles.farm_farmMobs.Value do task.wait(0.1)
        local targetMob 
        local skillsFolder = farm_getSkillsFolder()

        for mob, attack in Options.farm_selectedMobs.Value do 
            if not attack then continue end
            if not livingFolder:FindFirstChild(mob) then continue end 
            
            targetMob = livingFolder:FindFirstChild(mob)
        end 

        if not targetMob then farmingMob = false return end 

        farmingMob = true 

        repeat task.wait()
            getRoot().CFrame = targetMob:FindFirstChild("HumanoidRootPart").CFrame * CFrame.new(0, 0, 5)
            getHumanoid():ChangeState(11)

            for skill, use in Options.farm_selectSkills.Value do
                if not use then continue end 
                if not skillsFolder:FindFirstChild(skill) then continue end
                if getHumanoid().Health <= 0 then continue end 

                skillsFolder:FindFirstChild(skill):FireServer()
            end 

            if getGui():WaitForChild("QuickTimeEvent"):FindFirstChildWhichIsA("TextButton") then 
                local key = getGui():WaitForChild("QuickTimeEvent"):FindFirstChildWhichIsA("TextButton").Text

                virutalInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, getGui())
                task.wait()
                virutalInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, getGui())
            end 

            if targetMob:FindFirstChild("Humanoid") == nil or targetMob:FindFirstChild("Humanoid").Health <= 0 then 
                targetMob:Destroy()
            end 

        until getHumanoid().Health <= 0 or not Toggles.farm_farmMobs.Value or targetMob == nil or targetMob:FindFirstChild("Humanoid") == nil or targetMob:FindFirstChild("Humanoid").Health <= 0
    
        task.wait(0.5)

        for _, v in itemsFolder:GetChildren() do 
            if not v.Name:find("BoxDrop") then continue end 
            if not v:IsA("BasePart") then continue end 
            if getMag(v) >= 100 then continue end 

            getRoot().CFrame = v.CFrame 

            repeat task.wait()
                if v:FindFirstChildWhichIsA("ProximityPrompt", true) then
                    fireproximityprompt(v:FindFirstChildWhichIsA("ProximityPrompt", true))
                end
            until getMag(v) == 35 or v:FindFirstChildWhichIsA("ProximityPrompt", true) == nil or v:FindFirstChildWhichIsA("ProximityPrompt", true).Enabled == false 
        end 
    end
end

local function farm_autoUpgradeMas()
    if not Toggles.farm_autoMas.Value then return end 
        
    local levelText = getGui():WaitForChild("EXP"):WaitForChild("BG"):WaitForChild("LevelN").Text:gsub("%D", "")

    while Toggles.farm_autoMas.Value do task.wait(1)
        if tonumber(levelText) == 50 then 
            game:GetService("ReplicatedStorage").GlobalUsedRemotes.UpgradeMas:FireServer()
        end 
    end 
end
--chest variables

--chest functions
local function getKeys()
    local keys = 0
    
    for _ , v in game.Players.LocalPlayer.Backpack:GetChildren() do 
        if v.Name == "Chest Key" then 
            keys += 1 
        end 
    end 

    return keys 
end

local function activateChestFarm()
    if not Toggles.chest_farmChest.Value then return end 

    while Toggles.chest_farmChest.Value do task.wait() 

        local suc, err = pcall(function()
            if farmingMob then return end 
            
            local moveTo = nil 

            for _, v in itemsFolder:GetChildren() do 
                if not Toggles.chest_farmFinger.Value then continue end 
                if not v.Name:find("Finger") then continue end 

                moveTo = v 
                break
            end 

            if moveTo == nil then
                if not itemsFolder:FindFirstChild("Box") then 
                    moveTo = getClosest("Barrel", itemsFolder)
                elseif not itemsFolder:FindFirstChild("Chest") or getKeys() == 0 then 
                    moveTo = getClosest('Box', itemsFolder)
                else 
                    moveTo = getClosest("Chest", itemsFolder)
                end 
            end

            if not moveTo then 
                return 
            end 

            if getMag(moveTo) >= 500 then 
                moveTo:Destroy()
                return 
            end 

            if moveTo:FindFirstChildWhichIsA("ProximityPrompt", true) and moveTo:FindFirstChildWhichIsA("ProximityPrompt", true).Enabled == false then
                moveTo:Destroy()
                return
            end

            local noClip = game:GetService("RunService").RenderStepped:Connect(function()
                pcall(function()
                    getHumanoid().WalkSpeed = Options.chest_walkSpeed.Value

                    for i, v in getCharacter():GetChildren() do
                        if v:IsA("BasePart") then
                            v.CanCollide = false
                        end
                    end
                end)
            end)

            local path = pathfindingService:CreatePath()
            path:ComputeAsync(getRoot().Position, moveTo.Position + Vector3.new(5, 0, 0))

            if path.Status ~= Enum.PathStatus.Success then 
                moveTo:Destroy()
                return 
            end 

            for _, v in path:GetWaypoints() do 
                if farmingMob then break end 
                if getHumanoid().Health == 0 then break end 
                if v.Action == Enum.PathWaypointAction.Jump then 
                    getHumanoid():ChangeState(Enum.HumanoidStateType.Jumping)
                end 

                getHumanoid():MoveTo(v.Position)
                getHumanoid().MoveToFinished:Wait()
                task.delay(1, function()
                    farm_getSkillsFolder().Punch:FireServer()
                end)
            end 

            task.wait(0.5)

            repeat task.wait()
                local prompt = moveTo:FindFirstChildWhichIsA("ProximityPrompt")

                if prompt then 
                    prompt:GetPropertyChangedSignal("Enabled"):Once(function()
                        moveTo:Destroy()
                    end)

                    fireproximityprompt(prompt)
                else 
                    moveTo:Destroy()
                end 

                print(getMag(moveTo))
            until Toggles.chest_farmChest.Value == false or moveTo == nil or moveTo.Parent == nil or getMag(moveTo) >= 10
        end)

        if not suc then print(err) end
    end 
end
--shop variables
local sellGui = getGui():WaitForChild("SellGUI"):WaitForChild("Outer"):WaitForChild("Inner"):WaitForChild("Inner")
local sellRemote = game:GetService("ReplicatedStorage"):WaitForChild("GlobalUsedRemotes"):WaitForChild("SellItem")
--shop functions
local function shop_getSellables()
    local sellables = {}

    for _, v in sellGui:GetChildren() do 
        if not v:FindFirstChild("Text") then continue end 

        table.insert(sellables, v:FindFirstChild("Text").Text)
    end 

    return sellables
end

local function shop_getBuyables()
    local buyables = {}

    for _, v in replicatedStorage:WaitForChild("BuyItemRemote"):GetChildren() do 
        table.insert(buyables, v.Name)
    end 

    return buyables
end

local function shop_activateSell()
    if not Toggles.shop_autoSell.Value then return end 
    
    while Toggles.shop_autoSell.Value do task.wait()
        for item, sell in Options.shop_selectedItems.Value do 
            if not sell then continue end 

            sellRemote:FireServer(item)
        end 
    end 
end

local function shop_activateBuy()
    if not Toggles.shop_autoBuy.Value then return end 

    while Toggles.shop_autoBuy.Value do task.wait()
        pcall(function()
            for item, buy in Options.shop_buySelect.Value do 
                if not buy then continue end 
                getGui():WaitForChild("PurchaseSuccess").Enabled = false
                getGui():WaitForChild("PurchaseFailed").Enabled = false

                replicatedStorage:WaitForChild("BuyItemRemote"):FindFirstChild(item):FireServer()
            end 
        end)
    end
end
--settings variables
local VirtualUser = game:GetService("VirtualUser")

game:GetService("Players").LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
    VirtualUser:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
end)
--settings functions

--farm_ui variables
local farmTab = window:AddTab("Farm")
local toggles = farmTab:AddLeftGroupbox("Toggles")
local options = farmTab:AddRightGroupbox("Options")
--farm_ui general
toggles:AddToggle("farm_farmMobs", {Text = "Farm Mobs", Default = false, Callback = farm_activateFarm})
options:AddDropdown("farm_selectedMobs", {Text = "Select Mobs", Default = nil, AllowNull = true, Values = farm_getMobs(), Multi = true})
options:AddDivider()
options:AddDropdown("farm_selectSkills", {Text = "Select Skills", Default = nil, AllowNull = true, Values = farm_getSkills(), Multi = true})
options:AddButton({Text = "Refresh Skills", Func = function()
    Options.farm_selectSkills.Values = farm_getSkills()
    Options.farm_selectSkills:SetValues()
end})
toggles:AddDivider()
toggles:AddToggle('farm_autoMas', {Text = "Auto Upgrade Mastery", Default = false, Callback = farm_autoUpgradeMas})
--chest_ui variables
local chestTab = window:AddTab("Chest")
local toggles = chestTab:AddLeftGroupbox("Toggles")
local options = chestTab:AddRightGroupbox("Options")
--chest_ui general
toggles:AddToggle("chest_farmChest", {Text = "Farm Chests", Default = false, Callback = activateChestFarm})
toggles:AddToggle('chest_farmFinger', {Text = "Farm Sukuna Finger", Default = false})
options:AddSlider("chest_walkSpeed", {Text = "Walk Speed While Farm", Default = 80, Min = 16, Max = 120, Rounding = 0})
--shop_ui variables
local shopTab = window:AddTab("Shop")
local toggles = shopTab:AddLeftGroupbox("Toggles")
local options = shopTab:AddRightGroupbox("Options")
--shop_ui general
options:AddDropdown('shop_selectedItems', {Text = "Select Items (Sell)", Default = nil, AllowNull = true, Values = shop_getSellables(), Multi = true})
toggles:AddToggle('shop_autoSell', {Text = "Auto Sell", Default = false, Callback = shop_activateSell})
options:AddDivider()
toggles:AddDivider()
toggles:AddToggle('shop_autoBuy', {Text = "Auto Buy", Default = false, Callback = shop_activateBuy})
options:AddDropdown('shop_buySelect', {Text = "Select Items (Buy)", Default = nil, AllowNull = true, Values = shop_getBuyables(), Multi = true})
--settings_ui variables
local settingsTab = window:AddTab("Settings")
local toggles = settingsTab:AddLeftGroupbox("Toggles")
local options = settingsTab:AddRightGroupbox('Options')
--settings_ui general
options:AddLabel("Keybind"):AddKeyPicker('settings_menuKeybind', {
    Default = "LeftBracket",
    NoUI = true
})

library.ToggleKeybind = Options.settings_menuKeybind
