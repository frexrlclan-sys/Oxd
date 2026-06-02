
repeat task.wait() until game:IsLoaded()

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local SoundService      = game:GetService("SoundService")
local Lighting          = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService       = game:GetService("HttpService")
local Player            = Players.LocalPlayer

local function waitForCharacter()
    local char = Player.Character
    if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChildOfClass("Humanoid") then return char end
    return Player.CharacterAdded:Wait()
end
task.spawn(waitForCharacter)

if not getgenv then getgenv = function() return _G end end

local ConfigFileName = "OXDHUB_Config.json"

local Enabled = {
    AntiRagdoll        = false,
    SpinBot            = false,
    AutoSteal          = false,
    Unwalk             = false,
    Optimizer          = false,
    Galaxy             = false,
    SpamBat            = false,
    AutoDisableSpeed   = true,
    AutoWalkEnabled    = false,
    AutoRightEnabled   = false,
    ScriptUserESP      = true,
    InfiniteJump       = false,
    NoDie              = false,
    Aimbot             = false,
    Float              = false,
    FullAutoDuel       = false,
    DropEnabled        = false,
    TpEnabled          = false,
    InfJump            = false,
    InstaGrab          = false,
    AutoSpeedEnabled   = false,
    SkeletonESP        = false,
    BoxESP             = false,
    HighlightESP       = false,
}

local Values = {
    SpinSpeed            = 30,
    STEAL_RADIUS         = 20,
    STEAL_DURATION       = 1.3,
    DEFAULT_GRAVITY      = 196.2,
    GalaxyGravityPercent = 70,
    HOP_POWER            = 35,
    HOP_COOLDOWN         = 0.08,
    FOV                  = 70,
    FloatHeight          = 8,
    SpeedNoSteal         = 56,
    SpeedStealing        = 29,
    AimbotSpeed          = 80,
    MV_Normal_carry      = 56,
    MV_Normal_steal      = 29,
    MV_Desync_carry      = 200,
    MV_Desync_steal      = 29,
    MV_Lagger_carry      = 100,
    MV_Lagger_steal      = 29,
    -- SCALE değerleri
    Scale_SidebarW       = 148,
    Scale_SidebarH       = 42,
    Scale_FloatPanelW    = 148,
    Scale_FloatPanelH    = 42,
    Scale_DropPanelW     = 148,
    Scale_DropPanelH     = 42,
    Scale_TpDownPanelW   = 148,
    Scale_TpDownPanelH   = 42,
    Scale_AutoPlayPanelW = 148,
    Scale_AutoPlayPanelH = 42,
    Scale_MainW          = 370,
    Scale_MainH          = 460,
}

local KEYBINDS = {
    SPIN           = Enum.KeyCode.N,
    GALAXY         = Enum.KeyCode.M,
    AUTOLEFT       = Enum.KeyCode.Z,
    AUTORIGHT      = Enum.KeyCode.C,
    ANTIRAGDOLL    = Enum.KeyCode.Unknown,
    AIMBOT         = Enum.KeyCode.Unknown,
    FLOAT          = Enum.KeyCode.Unknown,
    FULLAUTODUEL   = Enum.KeyCode.Unknown,
    DROP           = Enum.KeyCode.Unknown,
    TPDOWN         = Enum.KeyCode.Unknown,
    AUTOPLAY       = Enum.KeyCode.Unknown,
}

local VisualSetters   = {}
local SliderSetters   = {}
local KeyBindBtns     = {}

local Connections        = {}
local AutoWalkEnabled    = false
local AutoRightEnabled   = false
local onAutoRightDone    = nil
local onAutoLeftDone     = nil
local galaxyEnabled      = false
local hopsEnabled        = false
local infJumpEnabled     = false
local auto1              = false
local auto2              = false
local instaGrab          = false
local abActive           = false
local abVisualSetter     = nil

-- AUTO PLAY state
local apSelectedRoute    = nil  -- "left" | "right" | nil
local apIsRunning        = false

-- ============================================================
-- BLOCK 1: CONFIG
-- ============================================================
do
    local function SaveConfig()
        local data = {}
        for k,v in pairs(Enabled)  do data[k]         = v end
        for k,v in pairs(Values)   do data[k]         = v end
        for k,v in pairs(KEYBINDS) do data["KEY_"..k] = v.Name end
        local ok = false
        if writefile then
            pcall(function() writefile(ConfigFileName, HttpService:JSONEncode(data)); ok=true end)
        end
        return ok
    end

    local function LoadConfig()
        pcall(function()
            if readfile and isfile and isfile(ConfigFileName) then
                local data = HttpService:JSONDecode(readfile(ConfigFileName))
                if data then
                    for k,v in pairs(data) do
                        if Enabled[k] ~= nil then Enabled[k] = v end
                        if Values[k]  ~= nil then Values[k]  = v end
                    end
                    for k in pairs(KEYBINDS) do
                        local key = "KEY_"..k
                        if data[key] then
                            local ok2,kc = pcall(function() return Enum.KeyCode[data[key]] end)
                            if ok2 and kc then KEYBINDS[k] = kc end
                        end
                    end
                end
            end
        end)
    end
    LoadConfig()

    getgenv().HUBDUEL_SaveConfig  = SaveConfig
    getgenv().HUBDUEL_LoadConfig  = LoadConfig
end

-- ============================================================
-- BLOCK 2: BACKEND
-- ============================================================
do
    local lastBatSwing       = 0
    local BAT_SWING_COOLDOWN = 0.12

    local SlapList = {
        {1,"Bat"},{2,"Slap"},{3,"Iron Slap"},{4,"Gold Slap"},
        {5,"Diamond Slap"},{6,"Emerald Slap"},{7,"Ruby Slap"},
        {8,"Dark Matter Slap"},{9,"Flame Slap"},{10,"Nuclear Slap"},
        {11,"Galaxy Slap"},{12,"Glitched Slap"},
    }

    local function findBat()
        local c = Player.Character if not c then return nil end
        local bp = Player:FindFirstChildOfClass("Backpack")
        for _,ch in ipairs(c:GetChildren()) do
            if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end
        end
        if bp then
            for _,ch in ipairs(bp:GetChildren()) do
                if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end
            end
        end
        for _,i in ipairs(SlapList) do
            local t = c:FindFirstChild(i[2]) or (bp and bp:FindFirstChild(i[2]))
            if t then return t end
        end
        return nil
    end

    local spamBatCircle, spamBatCircleConn

    local function createSpamBatCircle()
        if spamBatCircle then spamBatCircle:Destroy(); spamBatCircle=nil end
        local c = Player.Character if not c then return end
        local hrp = c:FindFirstChild("HumanoidRootPart") if not hrp then return end
        local circle = Instance.new("Part")
        circle.Name="ZAY_SpamBatCircle"; circle.Anchored=true; circle.CanCollide=false
        circle.CastShadow=false; circle.Material=Enum.Material.Neon
        circle.Color=Color3.fromRGB(160,0,255); circle.Shape=Enum.PartType.Cylinder
        circle.Size=Vector3.new(0.08,20,20); circle.Transparency=0.22; circle.Parent=workspace
        spamBatCircle = circle
    end

    local function removeSpamBatCircle()
        if spamBatCircle then spamBatCircle:Destroy(); spamBatCircle=nil end
        if spamBatCircleConn then spamBatCircleConn:Disconnect(); spamBatCircleConn=nil end
    end

    local function startSpamBatCircle()
        removeSpamBatCircle(); createSpamBatCircle()
        spamBatCircleConn = RunService.Heartbeat:Connect(function()
            if not Enabled.SpamBat then removeSpamBatCircle(); return end
            local c = Player.Character if not c then return end
            local hrp = c:FindFirstChild("HumanoidRootPart") if not hrp then return end
            if not spamBatCircle or not spamBatCircle.Parent then createSpamBatCircle(); return end
            spamBatCircle.CFrame = CFrame.new(hrp.Position.X,hrp.Position.Y-3.2,hrp.Position.Z)*CFrame.Angles(0,0,math.rad(90))
        end)
    end

    local function startSpamBat()
        if Connections.spamBat then return end
        Connections.spamBat = RunService.Heartbeat:Connect(function()
            if not Enabled.SpamBat then return end
            local c = Player.Character if not c then return end
            local bat = findBat() if not bat then return end
            if bat.Parent ~= c then bat.Parent = c end
            local now = tick()
            if now - lastBatSwing < BAT_SWING_COOLDOWN then return end
            lastBatSwing = now
            pcall(function() bat:Activate() end)
        end)
    end

    local function stopSpamBat()
        if Connections.spamBat then Connections.spamBat:Disconnect(); Connections.spamBat=nil end
    end

    getgenv().HUBDUEL_startSpamBat      = startSpamBat
    getgenv().HUBDUEL_stopSpamBat       = stopSpamBat
    getgenv().HUBDUEL_startSpamBatCircle= startSpamBatCircle
    getgenv().HUBDUEL_removeSpamBatCircle=removeSpamBatCircle

    -- SpinBot
    local spinBAV
    local function startSpinBot()
        local c = Player.Character if not c then return end
        local hrp = c:FindFirstChild("HumanoidRootPart") if not hrp then return end
        if spinBAV then spinBAV:Destroy(); spinBAV=nil end
        for _,v in pairs(hrp:GetChildren()) do if v.Name=="SpinBAV" then v:Destroy() end end
        spinBAV = Instance.new("BodyAngularVelocity")
        spinBAV.Name="SpinBAV"; spinBAV.MaxTorque=Vector3.new(0,math.huge,0)
        spinBAV.AngularVelocity=Vector3.new(0,Values.SpinSpeed,0); spinBAV.Parent=hrp
    end
    local function stopSpinBot()
        if spinBAV then spinBAV:Destroy(); spinBAV=nil end
        local c = Player.Character
        if c then local hrp=c:FindFirstChild("HumanoidRootPart") if hrp then for _,v in pairs(hrp:GetChildren()) do if v.Name=="SpinBAV" then v:Destroy() end end end end
    end

    RunService.Heartbeat:Connect(function()
        if Enabled.SpinBot and spinBAV then
            spinBAV.AngularVelocity = Player:GetAttribute("Stealing") and Vector3.new(0,0,0) or Vector3.new(0,Values.SpinSpeed,0)
        end
    end)

    getgenv().HUBDUEL_startSpinBot = startSpinBot
    getgenv().HUBDUEL_stopSpinBot  = stopSpinBot

    -- Galaxy
    local galaxyVectorForce, galaxyAttachment
    local lastHopTime    = 0
    local spaceHeld      = false
    local originalJumpPower = 50

    local function captureJumpPower()
        local c = Player.Character if not c then return end
        local hum = c:FindFirstChildOfClass("Humanoid")
        if hum and hum.JumpPower > 0 then originalJumpPower = hum.JumpPower end
    end
    task.spawn(function() task.wait(1); captureJumpPower() end)
    Player.CharacterAdded:Connect(function() task.wait(1); captureJumpPower() end)

    local function setupGalaxyForce()
        pcall(function()
            local c = Player.Character if not c then return end
            local h = c:FindFirstChild("HumanoidRootPart") if not h then return end
            if galaxyVectorForce then galaxyVectorForce:Destroy() end
            if galaxyAttachment  then galaxyAttachment:Destroy()  end
            galaxyAttachment = Instance.new("Attachment"); galaxyAttachment.Parent = h
            galaxyVectorForce = Instance.new("VectorForce")
            galaxyVectorForce.Attachment0 = galaxyAttachment
            galaxyVectorForce.ApplyAtCenterOfMass = true
            galaxyVectorForce.RelativeTo = Enum.ActuatorRelativeTo.World
            galaxyVectorForce.Force = Vector3.new(0,0,0); galaxyVectorForce.Parent = h
        end)
    end

    local function adjustGalaxyJump()
        pcall(function()
            local c = Player.Character if not c then return end
            local hum = c:FindFirstChildOfClass("Humanoid") if not hum then return end
            if not galaxyEnabled then hum.JumpPower=originalJumpPower; return end
            local ratio = math.sqrt((Values.DEFAULT_GRAVITY*(Values.GalaxyGravityPercent/100))/Values.DEFAULT_GRAVITY)
            hum.JumpPower = originalJumpPower*ratio
        end)
    end

    local function updateGalaxyForce()
        if not galaxyEnabled or not galaxyVectorForce then return end
        local c = Player.Character if not c then return end
        local mass = 0
        for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then mass+=p:GetMass() end end
        local tg = Values.DEFAULT_GRAVITY*(Values.GalaxyGravityPercent/100)
        galaxyVectorForce.Force = Vector3.new(0,mass*(Values.DEFAULT_GRAVITY-tg)*0.95,0)
    end

    local function doMiniHop()
        if not hopsEnabled then return end
        pcall(function()
            local c = Player.Character if not c then return end
            local h = c:FindFirstChild("HumanoidRootPart")
            local hum = c:FindFirstChildOfClass("Humanoid")
            if not h or not hum then return end
            if tick()-lastHopTime < Values.HOP_COOLDOWN then return end
            lastHopTime = tick()
            if hum.FloorMaterial == Enum.Material.Air then
                h.AssemblyLinearVelocity = Vector3.new(h.AssemblyLinearVelocity.X,Values.HOP_POWER,h.AssemblyLinearVelocity.Z)
            end
        end)
    end

    local function startGalaxy() galaxyEnabled=true; hopsEnabled=true; setupGalaxyForce(); adjustGalaxyJump() end
    local function stopGalaxy()
        galaxyEnabled=false; hopsEnabled=false
        if galaxyVectorForce then galaxyVectorForce:Destroy(); galaxyVectorForce=nil end
        if galaxyAttachment  then galaxyAttachment:Destroy();  galaxyAttachment=nil  end
        adjustGalaxyJump()
    end

    RunService.Heartbeat:Connect(function()
        if hopsEnabled and spaceHeld then doMiniHop() end
        if galaxyEnabled then updateGalaxyForce() end
    end)

    getgenv().HUBDUEL_startGalaxy     = startGalaxy
    getgenv().HUBDUEL_stopGalaxy      = stopGalaxy
    getgenv().HUBDUEL_setupGalaxyForce= setupGalaxyForce
    getgenv().HUBDUEL_adjustGalaxyJump= adjustGalaxyJump
    getgenv().HUBDUEL_spaceHeldSet    = function(v) spaceHeld = v end

    local function getMovementDirection()
        local c = Player.Character if not c then return Vector3.zero end
        local hum = c:FindFirstChildOfClass("Humanoid")
        return hum and hum.MoveDirection or Vector3.zero
    end

    local function startSpeedBoost()
        if Connections.speed then return end
        Connections.speed = RunService.Heartbeat:Connect(function()
            if not Enabled.SpeedBoost then return end
            if Player:GetAttribute("Stealing") then return end
            pcall(function()
                local c = Player.Character if not c then return end
                local h = c:FindFirstChild("HumanoidRootPart") if not h then return end
                local md = getMovementDirection()
                if md.Magnitude > 0.1 then
                    h.AssemblyLinearVelocity = Vector3.new(md.X*Values.BoostSpeed,h.AssemblyLinearVelocity.Y,md.Z*Values.BoostSpeed)
                end
            end)
        end)
    end
    local function stopSpeedBoost()
        if Connections.speed then Connections.speed:Disconnect(); Connections.speed=nil end
    end

    getgenv().HUBDUEL_startSpeedBoost = startSpeedBoost
    getgenv().HUBDUEL_stopSpeedBoost  = stopSpeedBoost
    getgenv().HUBDUEL_getMovDir       = getMovementDirection

    local function startSpeedWhileStealing()
        if Connections.speedWhileStealing then return end
        Connections.speedWhileStealing = RunService.Heartbeat:Connect(function()
            if not Enabled.SpeedWhileStealing or not Player:GetAttribute("Stealing") then return end
            local c=Player.Character if not c then return end
            local h=c:FindFirstChild("HumanoidRootPart") if not h then return end
            local md=getMovementDirection()
            if md.Magnitude > 0.1 then
                h.AssemblyLinearVelocity=Vector3.new(md.X*Values.StealingSpeedValue,h.AssemblyLinearVelocity.Y,md.Z*Values.StealingSpeedValue)
            end
        end)
    end
    local function stopSpeedWhileStealing()
        if Connections.speedWhileStealing then Connections.speedWhileStealing:Disconnect(); Connections.speedWhileStealing=nil end
    end

    getgenv().HUBDUEL_startSpeedWhileStealing = startSpeedWhileStealing
    getgenv().HUBDUEL_stopSpeedWhileStealing  = stopSpeedWhileStealing

    -- AntiRagdoll
    local function startAntiRagdoll()
        if Connections.antiRagdoll then return end
        Connections.antiRagdoll = RunService.Heartbeat:Connect(function()
            if not Enabled.AntiRagdoll then return end
            local char=Player.Character if not char then return end
            local root=char:FindFirstChild("HumanoidRootPart")
            local hum=char:FindFirstChildOfClass("Humanoid")
            if hum then
                local s=hum:GetState()
                if s==Enum.HumanoidStateType.Physics or s==Enum.HumanoidStateType.Ragdoll or s==Enum.HumanoidStateType.FallingDown then
                    hum:ChangeState(Enum.HumanoidStateType.Running)
                    workspace.CurrentCamera.CameraSubject=hum
                    pcall(function()
                        local pm=Player.PlayerScripts:FindFirstChild("PlayerModule")
                        if pm then require(pm:FindFirstChild("ControlModule")):Enable() end
                    end)
                    if root then root.Velocity=Vector3.zero; root.RotVelocity=Vector3.zero end
                end
            end
            for _,obj in ipairs(char:GetDescendants()) do
                if obj:IsA("Motor6D") and not obj.Enabled then obj.Enabled=true end
            end
        end)
    end
    local function stopAntiRagdoll()
        if Connections.antiRagdoll then Connections.antiRagdoll:Disconnect(); Connections.antiRagdoll=nil end
    end

    getgenv().HUBDUEL_startAntiRagdoll = startAntiRagdoll
    getgenv().HUBDUEL_stopAntiRagdoll  = stopAntiRagdoll

    -- Float
    local floatAttachment, floatVectorForce, floatInfJumpConn
    local floatMassCache = 0
    local floatLastMassTime = 0
    local FLOAT_MASS_INTERVAL = 2
    local FLOAT_KP = 160; local FLOAT_KD = 24; local FLOAT_DEADZONE = 0.10
    local floatJumping = false

    local function getCharacterMassFloat(char)
        local mass = 0
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then mass = mass + part:GetMass() end
        end
        return mass
    end

    local function setupFloatObjects(char)
        if floatVectorForce then floatVectorForce:Destroy(); floatVectorForce = nil end
        if floatAttachment  then floatAttachment:Destroy();  floatAttachment  = nil end
        local hrp = char and char:FindFirstChild("HumanoidRootPart") if not hrp then return end
        floatAttachment = Instance.new("Attachment"); floatAttachment.Name="ZAY_FloatAttachment"; floatAttachment.Parent=hrp
        floatVectorForce = Instance.new("VectorForce"); floatVectorForce.Name="ZAY_FloatForce"
        floatVectorForce.Attachment0=floatAttachment; floatVectorForce.ApplyAtCenterOfMass=true
        floatVectorForce.RelativeTo=Enum.ActuatorRelativeTo.World; floatVectorForce.Force=Vector3.new(0,0,0); floatVectorForce.Parent=hrp
    end

    local function startFloat()
        if Connections.float then return end
        local char = Player.Character if not char then return end
        setupFloatObjects(char); floatMassCache=getCharacterMassFloat(char); floatLastMassTime=tick(); floatJumping=false
        if floatInfJumpConn then floatInfJumpConn:Disconnect() end
        floatInfJumpConn = UserInputService.JumpRequest:Connect(function() if Enabled.Float then floatJumping=true end end)
        Connections.float = RunService.Heartbeat:Connect(function()
            if not Enabled.Float then return end
            pcall(function()
                local c=Player.Character if not c then return end
                local hrp=c:FindFirstChild("HumanoidRootPart") if not hrp then return end
                if not floatVectorForce or not floatVectorForce.Parent then setupFloatObjects(c) end
                local now=tick()
                if now-floatLastMassTime>FLOAT_MASS_INTERVAL then floatMassCache=getCharacterMassFloat(c); floatLastMassTime=now end
                local velY=hrp.AssemblyLinearVelocity.Y
                local rp=RaycastParams.new(); rp.FilterDescendantsInstances={c}; rp.FilterType=Enum.RaycastFilterType.Exclude
                local ray=workspace:Raycast(hrp.Position,Vector3.new(0,-500,0),rp)
                local groundY=ray and ray.Position.Y or (hrp.Position.Y-Values.FloatHeight)
                local targetY=groundY+Values.FloatHeight; local diff=targetY-hrp.Position.Y
                if floatJumping then
                    if velY>0 then floatVectorForce.Force=Vector3.new(0,0,0); return
                    else
                        if hrp.Position.Y>targetY+0.3 then floatVectorForce.Force=Vector3.new(0,0,0); return
                        else floatJumping=false; hrp.AssemblyLinearVelocity=Vector3.new(hrp.AssemblyLinearVelocity.X,0,hrp.AssemblyLinearVelocity.Z) end
                    end
                end
                local gravComp=floatMassCache*workspace.Gravity
                if math.abs(diff)<FLOAT_DEADZONE and math.abs(velY)<0.3 then floatVectorForce.Force=Vector3.new(0,gravComp,0); return end
                local pdForce=floatMassCache*(FLOAT_KP*diff-FLOAT_KD*velY)
                floatVectorForce.Force=Vector3.new(0,gravComp+pdForce,0)
                if hrp.Position.Y<targetY and velY<0 then hrp.AssemblyLinearVelocity=Vector3.new(hrp.AssemblyLinearVelocity.X,0,hrp.AssemblyLinearVelocity.Z) end
            end)
        end)
    end

    local function stopFloat()
        if Connections.float then Connections.float:Disconnect(); Connections.float=nil end
        if floatInfJumpConn then floatInfJumpConn:Disconnect(); floatInfJumpConn=nil end
        if floatVectorForce then floatVectorForce:Destroy(); floatVectorForce=nil end
        if floatAttachment  then floatAttachment:Destroy();  floatAttachment=nil  end
        pcall(function() local c=Player.Character; local hum=c and c:FindFirstChildOfClass("Humanoid"); if hum then if galaxyEnabled then getgenv().HUBDUEL_adjustGalaxyJump() else hum.JumpPower=50 end end end)
    end

    getgenv().HUBDUEL_startFloat = startFloat
    getgenv().HUBDUEL_stopFloat  = stopFloat

    -- Unwalk
    local savedAnimations={}
    local function startUnwalk()
        local c=Player.Character if not c then return end
        local hum=c:FindFirstChildOfClass("Humanoid")
        if hum then for _,t in ipairs(hum:GetPlayingAnimationTracks()) do t:Stop() end end
        local anim=c:FindFirstChild("Animate")
        if anim then savedAnimations.Animate=anim:Clone(); anim:Destroy() end
    end
    local function stopUnwalk()
        local c=Player.Character
        if c and savedAnimations.Animate then savedAnimations.Animate:Clone().Parent=c; savedAnimations.Animate=nil end
    end

    getgenv().HUBDUEL_startUnwalk = startUnwalk
    getgenv().HUBDUEL_stopUnwalk  = stopUnwalk

    -- Optimizer
    local originalTransparency={}; local xrayEnabled=false
    local function enableOptimizer()
        if getgenv and getgenv().OPTIMIZER_ACTIVE then return end
        if getgenv then getgenv().OPTIMIZER_ACTIVE=true end
        pcall(function() settings().Rendering.QualityLevel=Enum.QualityLevel.Level01; Lighting.GlobalShadows=false; Lighting.Brightness=3; Lighting.FogEnd=9e9 end)
        pcall(function()
            for _,obj in ipairs(workspace:GetDescendants()) do
                pcall(function()
                    if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then obj:Destroy()
                    elseif obj:IsA("BasePart") then obj.CastShadow=false; obj.Material=Enum.Material.Plastic end
                end)
            end
        end)
        xrayEnabled=true
        pcall(function()
            for _,obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") and obj.Anchored and (obj.Name:lower():find("base") or (obj.Parent and obj.Parent.Name:lower():find("base"))) then
                    originalTransparency[obj]=obj.LocalTransparencyModifier; obj.LocalTransparencyModifier=0.85
                end
            end
        end)
    end
    local function disableOptimizer()
        if getgenv then getgenv().OPTIMIZER_ACTIVE=false end
        if xrayEnabled then
            for part,v in pairs(originalTransparency) do if part then part.LocalTransparencyModifier=v end end
            originalTransparency={}; xrayEnabled=false
        end
    end

    getgenv().HUBDUEL_enableOptimizer  = enableOptimizer
    getgenv().HUBDUEL_disableOptimizer = disableOptimizer

    -- ESP Systems
    local espObjects = {}
    local espConnections = {}

    local function clearESP()
        for _, obj in pairs(espObjects) do pcall(function() obj:Destroy() end) end
        espObjects = {}
        for _, conn in pairs(espConnections) do pcall(function() conn:Disconnect() end) end
        espConnections = {}
    end

    local function updateESP()
        clearESP()
        if not Enabled.HighlightESP and not Enabled.BoxESP and not Enabled.SkeletonESP then return end
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= Player and pl.Character then
                if Enabled.HighlightESP then
                    pcall(function()
                        local hl = Instance.new("Highlight")
                        hl.FillColor = Color3.fromRGB(255,50,100)
                        hl.OutlineColor = Color3.fromRGB(255,255,255)
                        hl.FillTransparency = 0.5
                        hl.OutlineTransparency = 0
                        hl.Adornee = pl.Character
                        hl.Parent = Player.PlayerGui
                        table.insert(espObjects, hl)
                    end)
                end
                if Enabled.BoxESP then
                    pcall(function()
                        local hrp = pl.Character:FindFirstChild("HumanoidRootPart")
                        if not hrp then return end
                        local bb = Instance.new("SelectionBox")
                        bb.Color3 = Color3.fromRGB(255,50,100)
                        bb.LineThickness = 0.04
                        bb.SurfaceTransparency = 0.8
                        bb.Adornee = pl.Character
                        bb.Parent = workspace
                        table.insert(espObjects, bb)
                    end)
                end
            end
        end
        espConnections.playerAdded = Players.PlayerAdded:Connect(function(pl)
            task.wait(1)
            if Enabled.HighlightESP or Enabled.BoxESP or Enabled.SkeletonESP then updateESP() end
        end)
        espConnections.playerRemoved = Players.PlayerRemoving:Connect(function()
            task.wait(0.1)
            if Enabled.HighlightESP or Enabled.BoxESP or Enabled.SkeletonESP then updateESP() end
        end)
        espConnections.charAdded = Players.PlayerAdded:Connect(function(pl)
            pl.CharacterAdded:Connect(function() task.wait(0.5); if Enabled.HighlightESP or Enabled.BoxESP or Enabled.SkeletonESP then updateESP() end end)
        end)
    end

    getgenv().HUBDUEL_updateESP = updateESP
    getgenv().HUBDUEL_clearESP  = clearESP

    -- Speed labels
    local speedBillboard, speedTextLabel
    local function createSpeedLabel(char)
        if speedBillboard then speedBillboard:Destroy(); speedBillboard=nil; speedTextLabel=nil end
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart") if not hrp then return end
        local bb = Instance.new("BillboardGui"); bb.Name="ZAY_SpeedLabel"; bb.AlwaysOnTop=false
        bb.Size=UDim2.new(0,120,0,30); bb.StudsOffset=Vector3.new(0,3.2,0); bb.MaxDistance=60; bb.Parent=hrp
        local lbl = Instance.new("TextLabel",bb); lbl.Size=UDim2.new(1,0,1,0); lbl.BackgroundTransparency=1
        lbl.Text="Speed: 0.0"; lbl.TextColor3=Color3.fromRGB(200,150,255); lbl.TextStrokeColor3=Color3.fromRGB(0,0,0)
        lbl.TextStrokeTransparency=0; lbl.Font=Enum.Font.GothamBlack; lbl.TextSize=16; lbl.TextXAlignment=Enum.TextXAlignment.Center
        speedBillboard=bb; speedTextLabel=lbl
    end
    task.spawn(function() task.wait(1); createSpeedLabel(Player.Character) end)
    Player.CharacterAdded:Connect(function(char) task.wait(0.5); createSpeedLabel(char) end)
    RunService.Heartbeat:Connect(function()
        if not speedTextLabel then return end
        pcall(function()
            local char=Player.Character if not char then return end
            local hrp=char:FindFirstChild("HumanoidRootPart") if not hrp then return end
            local vel=hrp.AssemblyLinearVelocity
            speedTextLabel.Text="Speed: "..string.format("%.1f",Vector3.new(vel.X,0,vel.Z).Magnitude)
        end)
    end)

    local enemySpeedLabels = {}
    local function createEnemySpeedLabel(targetPlayer)
        pcall(function()
            local char=targetPlayer.Character if not char then return end
            local hrp=char:FindFirstChild("HumanoidRootPart") if not hrp then return end
            if enemySpeedLabels[targetPlayer] then enemySpeedLabels[targetPlayer]:Destroy(); enemySpeedLabels[targetPlayer]=nil end
            local bb=Instance.new("BillboardGui"); bb.Name="ZAY_EnemySpeedLabel"; bb.AlwaysOnTop=false
            bb.Size=UDim2.new(0,120,0,30); bb.StudsOffset=Vector3.new(0,3.2,0); bb.MaxDistance=120; bb.Parent=hrp
            local lbl=Instance.new("TextLabel",bb); lbl.Size=UDim2.new(1,0,1,0); lbl.BackgroundTransparency=1
            lbl.Text="Speed: 0.0"; lbl.TextColor3=Color3.fromRGB(255,180,100); lbl.TextStrokeColor3=Color3.fromRGB(0,0,0)
            lbl.TextStrokeTransparency=0; lbl.Font=Enum.Font.GothamBlack; lbl.TextSize=14; lbl.TextXAlignment=Enum.TextXAlignment.Center
            enemySpeedLabels[targetPlayer]=bb
        end)
    end
    local function removeEnemySpeedLabel(tp) if enemySpeedLabels[tp] then enemySpeedLabels[tp]:Destroy(); enemySpeedLabels[tp]=nil end end
    local function setupAllEnemyLabels()
        for _,pl in ipairs(Players:GetPlayers()) do
            if pl~=Player then
                createEnemySpeedLabel(pl)
                pl.CharacterAdded:Connect(function() task.wait(0.5); createEnemySpeedLabel(pl) end)
                pl.CharacterRemoving:Connect(function() removeEnemySpeedLabel(pl) end)
            end
        end
    end
    Players.PlayerAdded:Connect(function(pl)
        pl.CharacterAdded:Connect(function() task.wait(0.5); createEnemySpeedLabel(pl) end)
        pl.CharacterRemoving:Connect(function() removeEnemySpeedLabel(pl) end)
    end)
    Players.PlayerRemoving:Connect(function(pl) removeEnemySpeedLabel(pl) end)
    task.spawn(function() task.wait(1.5); setupAllEnemyLabels() end)
    RunService.Heartbeat:Connect(function()
        for pl,bb in pairs(enemySpeedLabels) do
            pcall(function()
                if not bb or not bb.Parent then enemySpeedLabels[pl]=nil; return end
                local char=pl.Character if not char then return end
                local hrp=char:FindFirstChild("HumanoidRootPart") if not hrp then return end
                local vel=hrp.AssemblyLinearVelocity
                local lbl=bb:FindFirstChildOfClass("TextLabel")
                if lbl then lbl.Text="Speed: "..string.format("%.1f",Vector3.new(vel.X,0,vel.Z).Magnitude) end
            end)
        end
    end)

    getgenv().HUBDUEL_getSpeedLabel       = function() return speedTextLabel end
    getgenv().HUBDUEL_getEnemySpeedLabels = function() return enemySpeedLabels end
end -- END BLOCK 2

-- ============================================================
-- BLOCK 3: AUTO WALK / RIGHT / DUEL BACKEND
-- ============================================================
do
    local POSITION_1  = Vector3.new(-476.48,-6.28, 92.73)
    local POSITION_2  = Vector3.new(-483.12,-4.95, 94.80)
    local POSITION_R1 = Vector3.new(-476.16,-6.52, 25.62)
    local POSITION_R2 = Vector3.new(-483.04,-5.09, 23.14)
    local autoWalkPhase=1; local autoRightPhase=1
    local autoWalkConnection, autoRightConnection

    local coordESPFolder = Instance.new("Folder",workspace); coordESPFolder.Name="HUBDUEL_CoordESP"
    local function createCoordMarker(pos,lbl,col)
        local dot=Instance.new("Part",coordESPFolder); dot.Anchored=true; dot.CanCollide=false; dot.CastShadow=false
        dot.Material=Enum.Material.Neon; dot.Color=col; dot.Shape=Enum.PartType.Ball; dot.Size=Vector3.new(1,1,1); dot.Position=pos; dot.Transparency=0.2
        local bb=Instance.new("BillboardGui",dot); bb.AlwaysOnTop=true; bb.Size=UDim2.new(0,100,0,20); bb.StudsOffset=Vector3.new(0,2,0); bb.MaxDistance=300
        local tx=Instance.new("TextLabel",bb); tx.Size=UDim2.new(1,0,1,0); tx.BackgroundTransparency=1; tx.Text=lbl; tx.TextColor3=col
        tx.TextStrokeColor3=Color3.fromRGB(0,0,0); tx.TextStrokeTransparency=0; tx.Font=Enum.Font.GothamBold; tx.TextSize=12
    end
    createCoordMarker(POSITION_1,"L1",Color3.fromRGB(180,100,255))
    createCoordMarker(POSITION_2,"L END",Color3.fromRGB(140,60,220))
    createCoordMarker(POSITION_R1,"R1",Color3.fromRGB(200,120,255))
    createCoordMarker(POSITION_R2,"R END",Color3.fromRGB(160,80,240))

    local function faceSouth()
        local c=Player.Character if not c then return end
        local h=c:FindFirstChild("HumanoidRootPart") if not h then return end
        h.CFrame=CFrame.new(h.Position)*CFrame.Angles(0,0,0)
        local cam=workspace.CurrentCamera
        if cam then cam.CFrame=CFrame.new(h.Position.X,h.Position.Y+5,h.Position.Z-12)*CFrame.Angles(math.rad(-15),0,0) end
    end
    local function faceNorth()
        local c=Player.Character if not c then return end
        local h=c:FindFirstChild("HumanoidRootPart") if not h then return end
        h.CFrame=CFrame.new(h.Position)*CFrame.Angles(0,math.rad(180),0)
        local cam=workspace.CurrentCamera
        if cam then cam.CFrame=CFrame.new(h.Position.X,h.Position.Y+2,h.Position.Z+12)*CFrame.Angles(0,math.rad(180),0) end
    end

    local function startAutoWalk()
        if autoWalkConnection then autoWalkConnection:Disconnect() end
        autoWalkPhase=1
        autoWalkConnection=RunService.Heartbeat:Connect(function()
            if not AutoWalkEnabled then return end
            local c=Player.Character if not c then return end
            local h=c:FindFirstChild("HumanoidRootPart"); local hum=c:FindFirstChildOfClass("Humanoid")
            if not h or not hum then return end
            local target=autoWalkPhase==1 and POSITION_1 or POSITION_2
            local dist=(Vector3.new(target.X,h.Position.Y,target.Z)-h.Position).Magnitude
            if dist<1 then
                if autoWalkPhase==1 then autoWalkPhase=2; return end
                hum:Move(Vector3.zero,false); h.AssemblyLinearVelocity=Vector3.new(0,0,0)
                AutoWalkEnabled=false; Enabled.AutoWalkEnabled=false
                if VisualSetters and VisualSetters.AutoWalkEnabled then VisualSetters.AutoWalkEnabled(false,true) end
                if autoWalkConnection then autoWalkConnection:Disconnect(); autoWalkConnection=nil end
                if onAutoLeftDone then onAutoLeftDone() end
                faceSouth(); return
            end
            local dir=(target-h.Position); local md=Vector3.new(dir.X,0,dir.Z).Unit
            hum:Move(md,false); h.AssemblyLinearVelocity=Vector3.new(md.X*Values.BoostSpeed,h.AssemblyLinearVelocity.Y,md.Z*Values.BoostSpeed)
        end)
    end
    local function stopAutoWalk()
        if autoWalkConnection then autoWalkConnection:Disconnect(); autoWalkConnection=nil end
        autoWalkPhase=1
        local c=Player.Character if c then local hum=c:FindFirstChildOfClass("Humanoid") if hum then hum:Move(Vector3.zero,false) end end
    end

    local function startAutoRight()
        if autoRightConnection then autoRightConnection:Disconnect() end
        autoRightPhase=1
        autoRightConnection=RunService.Heartbeat:Connect(function()
            if not AutoRightEnabled then return end
            local c=Player.Character if not c then return end
            local h=c:FindFirstChild("HumanoidRootPart"); local hum=c:FindFirstChildOfClass("Humanoid")
            if not h or not hum then return end
            local target=autoRightPhase==1 and POSITION_R1 or POSITION_R2
            local dist=(Vector3.new(target.X,h.Position.Y,target.Z)-h.Position).Magnitude
            if dist<1 then
                if autoRightPhase==1 then autoRightPhase=2; return end
                hum:Move(Vector3.zero,false); h.AssemblyLinearVelocity=Vector3.new(0,0,0)
                AutoRightEnabled=false; Enabled.AutoRightEnabled=false
                if VisualSetters and VisualSetters.AutoRightEnabled then VisualSetters.AutoRightEnabled(false,true) end
                if autoRightConnection then autoRightConnection:Disconnect(); autoRightConnection=nil end
                if onAutoRightDone then onAutoRightDone() end
                faceNorth(); return
            end
            local dir=(target-h.Position); local md=Vector3.new(dir.X,0,dir.Z).Unit
            hum:Move(md,false); h.AssemblyLinearVelocity=Vector3.new(md.X*Values.BoostSpeed,h.AssemblyLinearVelocity.Y,md.Z*Values.BoostSpeed)
        end)
    end
    local function stopAutoRight()
        if autoRightConnection then autoRightConnection:Disconnect(); autoRightConnection=nil end
        autoRightPhase=1
        local c=Player.Character if c then local hum=c:FindFirstChildOfClass("Humanoid") if hum then hum:Move(Vector3.zero,false) end end
    end

    getgenv().HUBDUEL_startAutoWalk  = startAutoWalk
    getgenv().HUBDUEL_stopAutoWalk   = stopAutoWalk
    getgenv().HUBDUEL_startAutoRight = startAutoRight
    getgenv().HUBDUEL_stopAutoRight  = stopAutoRight

    -- Full Auto Duel
    local fadWaypoints={}; local fadCurrent=1; local fadMoving=false; local fadWaiting=false; local fadGrabDone=false
    local fadMoveConn=nil; local fadSpeedConn=nil

    local function fadStop()
        if fadMoveConn then fadMoveConn:Disconnect(); fadMoveConn=nil end
        if fadSpeedConn then fadSpeedConn:Disconnect(); fadSpeedConn=nil end
        fadMoving=false; fadWaiting=false; fadGrabDone=false
        Enabled.FullAutoDuel=false
        if VisualSetters and VisualSetters.FullAutoDuel then VisualSetters.FullAutoDuel(false,true) end
    end

    local function fadMoveLoop()
        if fadMoveConn then fadMoveConn:Disconnect() end
        fadMoveConn=RunService.Stepped:Connect(function()
            if not fadMoving or fadWaiting then return end
            local c=Player.Character if not c then return end
            local root=c:FindFirstChild("HumanoidRootPart") if not root then return end
            local wp=fadWaypoints[fadCurrent]
            local targetXZ=Vector3.new(wp.position.X,0,wp.position.Z)
            local currentXZ=Vector3.new(root.Position.X,0,root.Position.Z)
            local distXZ=(targetXZ-currentXZ).Magnitude
            if distXZ<3 then
                if fadCurrent==3 and not fadGrabDone then fadWaiting=true; root.AssemblyLinearVelocity=Vector3.new(0,root.AssemblyLinearVelocity.Y,0); return end
                if fadCurrent==#fadWaypoints then fadStop(); return end
                fadCurrent+=1
            else
                local moveDir=(targetXZ-currentXZ).Unit
                root.AssemblyLinearVelocity=Vector3.new(moveDir.X*wp.speed,root.AssemblyLinearVelocity.Y,moveDir.Z*wp.speed)
            end
        end)
    end

    local function startFullAutoDuel()
        local root=Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        fadMoving=true; fadGrabDone=false; fadCurrent=1
        if root.Position.Z>57 then
            fadWaypoints={{position=Vector3.new(-476.48,-6.28,92.73),speed=59},{position=Vector3.new(-483.12,-4.95,94.80),speed=29},{position=Vector3.new(-476.48,-6.28,92.73),speed=29},{position=Vector3.new(-474.22,-6.96,16.18),speed=29}}
        else
            fadWaypoints={{position=Vector3.new(-476.16,-6.52,25.62),speed=59},{position=Vector3.new(-483.04,-5.09,23.14),speed=29},{position=Vector3.new(-476.16,-6.52,25.62),speed=29},{position=Vector3.new(-474.22,-6.96,105.48),speed=29}}
        end
        if fadSpeedConn then fadSpeedConn:Disconnect() end
        fadSpeedConn=RunService.Heartbeat:Connect(function()
            if not fadWaiting or fadGrabDone then return end
            local c=Player.Character if not c then return end
            local hum=c:FindFirstChildOfClass("Humanoid") if not hum then return end
            if hum.WalkSpeed<23 then task.wait(0.3); fadWaiting=false; fadGrabDone=true; if fadCurrent<#fadWaypoints then fadCurrent+=1 end end
        end)
        fadMoveLoop()
    end

    getgenv().HUBDUEL_startFullAutoDuel = startFullAutoDuel
    getgenv().HUBDUEL_stopFullAutoDuel  = fadStop

    -- Drop / TP / InfJump
    local dropRunning=false
    local detectA=Vector3.new(-466.51,-7.81,113.79); local detectB=Vector3.new(-466.43,-7.89,6.55)
    local routeA={Vector3.new(-432.87,-7.98,54.04),Vector3.new(-461.95,-7.98,97.28),Vector3.new(-483.72,-6.08,94.77)}
    local routeB={Vector3.new(-447.12,-7.98,61.52),Vector3.new(-463.56,-7.98,25.78),Vector3.new(-486.73,-5.51,23.99)}
    local chosenRoute=nil

    task.spawn(function()
        while not chosenRoute do
            task.wait(.1)
            local char=Player.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local pos=char.HumanoidRootPart.Position
                if (pos-detectA).Magnitude<5 then chosenRoute=routeB
                elseif (pos-detectB).Magnitude<5 then chosenRoute=routeA end
            end
        end
    end)

    local function hrp2()
        local c=Player.Character; return c and c:FindFirstChild("HumanoidRootPart")
    end

    local wfConns={}; local wfActive=false
    local function startWf()
        wfActive=true
        table.insert(wfConns,RunService.Stepped:Connect(function()
            if not wfActive then return end
            for _,pl in ipairs(Players:GetPlayers()) do
                if pl~=Player and pl.Character then
                    for _,part in ipairs(pl.Character:GetChildren()) do if part:IsA("BasePart") then part.CanCollide=false end end
                end
            end
        end))
        local co=coroutine.create(function()
            while wfActive do
                RunService.Heartbeat:Wait()
                local root=Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                if not root then RunService.Heartbeat:Wait() end
                local vel=root.Velocity; root.Velocity=vel*10000+Vector3.new(0,10000,0)
                RunService.RenderStepped:Wait()
                if root and root.Parent then root.Velocity=vel end
                RunService.Stepped:Wait()
                if root and root.Parent then root.Velocity=vel+Vector3.new(0,0.1,0) end
            end
        end)
        coroutine.resume(co); table.insert(wfConns,co)
    end
    local function stopWf()
        wfActive=false
        for _,c in ipairs(wfConns) do
            if typeof(c)=="RBXScriptConnection" then c:Disconnect() elseif typeof(c)=="thread" then pcall(task.cancel,c) end
        end
        wfConns={}
    end

    local function doDrop()
        if dropRunning then return end
        dropRunning=true; startWf()
        task.delay(0.4,function() stopWf(); dropRunning=false end)
    end

    local function doTP()
        local char=Player.Character if not char then return end
        local root=char:FindFirstChild("HumanoidRootPart") if not root then return end
        if not chosenRoute then repeat task.wait() until chosenRoute end
        for _,pos in ipairs(chosenRoute) do root.CFrame=CFrame.new(pos); task.wait(.2) end
    end

    getgenv().HUBDUEL_doDrop = doDrop
    getgenv().HUBDUEL_doTP   = doTP
    getgenv().HUBDUEL_hrp2   = hrp2

    local function doTpDown()
        local r=Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if not r then return end
        local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances={Player.Character}
        local res=workspace:Raycast(r.Position,Vector3.new(0,-500,0),params)
        if res then r.CFrame=CFrame.new(Vector3.new(r.Position.X,res.Position.Y+3,r.Position.Z))
        else r.CFrame=r.CFrame*CFrame.new(0,-20,0) end
        r.AssemblyLinearVelocity=Vector3.zero
    end
    getgenv().HUBDUEL_doTpDown = doTpDown

    -- Infinite Jump
    local jumpForce=50; local clampFallSpeed=80
    RunService.Heartbeat:Connect(function()
        if not infJumpEnabled then return end
        local char=Player.Character if not char then return end
        local root=char:FindFirstChild("HumanoidRootPart")
        if root and root.Velocity.Y<-clampFallSpeed then root.Velocity=Vector3.new(root.Velocity.X,-clampFallSpeed,root.Velocity.Z) end
    end)
    UserInputService.JumpRequest:Connect(function()
        if not infJumpEnabled then return end
        local char=Player.Character if not char then return end
        local root=char:FindFirstChild("HumanoidRootPart")
        if root then root.Velocity=Vector3.new(root.Velocity.X,jumpForce,root.Velocity.Z) end
    end)

    -- Auto Grab / AutoSteal
    local ProgressBarFill, ProgressPercentLabel
    local isStealing=false; local stealStartTime=nil; local progressConn=nil; local StealData={}

    local function isMyPlotByName(pn)
        local plots=workspace:FindFirstChild("Plots") if not plots then return false end
        local plot=plots:FindFirstChild(pn) if not plot then return false end
        local sign=plot:FindFirstChild("PlotSign")
        if sign then local yb=sign:FindFirstChild("YourBase"); if yb and yb:IsA("BillboardGui") then return yb.Enabled==true end end
        return false
    end

    local function findNearestPrompt()
        local h=Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") if not h then return nil end
        local plots=workspace:FindFirstChild("Plots") if not plots then return nil end
        local np,nd,nn=nil,math.huge,nil
        for _,plot in ipairs(plots:GetChildren()) do
            if isMyPlotByName(plot.Name) then continue end
            local podiums=plot:FindFirstChild("AnimalPodiums") if not podiums then continue end
            for _,pod in ipairs(podiums:GetChildren()) do
                pcall(function()
                    local base=pod:FindFirstChild("Base"); local spawn=base and base:FindFirstChild("Spawn")
                    if spawn then
                        local dist=(spawn.Position-h.Position).Magnitude
                        if dist<nd and dist<=Values.STEAL_RADIUS then
                            local att=spawn:FindFirstChild("PromptAttachment")
                            if att then
                                for _,ch in ipairs(att:GetChildren()) do
                                    if ch:IsA("ProximityPrompt") then np,nd,nn=ch,dist,pod.Name; break end
                                end
                            end
                        end
                    end
                end)
            end
        end
        return np,nd,nn
    end

    local function ResetProgressBar()
        if ProgressPercentLabel then ProgressPercentLabel.Text="0%" end
        if ProgressBarFill then ProgressBarFill.Size=UDim2.new(0,0,1,0) end
    end

    local function executeSteal(prompt,name)
        if isStealing then return end
        if not StealData[prompt] then
            StealData[prompt]={hold={},trigger={},ready=true}
            pcall(function()
                if getconnections then
                    for _,c in ipairs(getconnections(prompt.PromptButtonHoldBegan)) do if c.Function then table.insert(StealData[prompt].hold,c.Function) end end
                    for _,c in ipairs(getconnections(prompt.Triggered)) do if c.Function then table.insert(StealData[prompt].trigger,c.Function) end end
                end
            end)
        end
        local data=StealData[prompt]
        if not data.ready then return end
        data.ready=false; isStealing=true; stealStartTime=tick()
        if progressConn then progressConn:Disconnect() end
        progressConn=RunService.Heartbeat:Connect(function()
            if not isStealing then progressConn:Disconnect(); return end
            local prog=math.clamp((tick()-stealStartTime)/Values.STEAL_DURATION,0,1)
            if ProgressBarFill then ProgressBarFill.Size=UDim2.new(prog,0,1,0) end
            if ProgressPercentLabel then ProgressPercentLabel.Text=math.floor(prog*100).."%" end
        end)
        task.spawn(function()
            for _,f in ipairs(data.hold) do task.spawn(f) end
            task.wait(Values.STEAL_DURATION)
            for _,f in ipairs(data.trigger) do task.spawn(f) end
            if progressConn then progressConn:Disconnect() end
            ResetProgressBar(); data.ready=true; task.wait(0.3); isStealing=false
        end)
    end

    local function startAutoSteal()
        if Connections.autoSteal then return end
        Connections.autoSteal=RunService.Heartbeat:Connect(function()
            if not Enabled.AutoSteal or isStealing then return end
            local p,_,n=findNearestPrompt(); if p then executeSteal(p,n) end
        end)
    end
    local function stopAutoSteal()
        if Connections.autoSteal then Connections.autoSteal:Disconnect(); Connections.autoSteal=nil end
        isStealing=false; ResetProgressBar()
    end

    getgenv().HUBDUEL_startAutoSteal     = startAutoSteal
    getgenv().HUBDUEL_stopAutoSteal      = stopAutoSteal
    getgenv().HUBDUEL_setProgressBarFill = function(f) ProgressBarFill=f end
    getgenv().HUBDUEL_setProgressLabel   = function(l) ProgressPercentLabel=l end

    -- InstaGrab
    local InternalStealCache={}
    local function buildCallbacks3(prompt)
        if InternalStealCache[prompt] then return end
        local data={hold={},trigger={},ready=true}
        local ok1,conns1=pcall(getconnections,prompt.PromptButtonHoldBegan)
        if ok1 then for _,c in pairs(conns1) do if c.Function then table.insert(data.hold,c.Function) end end end
        local ok2,conns2=pcall(getconnections,prompt.Triggered)
        if ok2 then for _,c in pairs(conns2) do if c.Function then table.insert(data.trigger,c.Function) end end end
        InternalStealCache[prompt]=data
    end
    local function runSteal3(prompt)
        local data=InternalStealCache[prompt]; if not data or not data.ready then return end
        data.ready=false
        task.spawn(function()
            for _,fn in pairs(data.hold) do task.spawn(fn) end
            task.wait(.15)
            for _,fn in pairs(data.trigger) do task.spawn(fn) end
            task.wait(.05); data.ready=true
        end)
    end
    RunService.Heartbeat:Connect(function()
        if not instaGrab then return end
        local r=hrp2() if not r then return end
        for _,v in pairs(workspace:GetDescendants()) do
            if v:IsA("ProximityPrompt") then
                local p=v.Parent; local pos2=p:IsA("Attachment") and p.WorldPosition or p.Position
                if pos2 and (pos2-r.Position).Magnitude<7 then buildCallbacks3(v); runSteal3(v) end
            end
        end
    end)

    -- AIMBOT
    local _abAimConn,_abHighlight,_abLockedTarget=nil,nil,nil

    local function _abIsValidTarget(tc)
        if not tc then return false end
        local hum=tc:FindFirstChildOfClass("Humanoid"); local hrp=tc:FindFirstChild("HumanoidRootPart"); local ff=tc:FindFirstChildOfClass("ForceField")
        return hum and hrp and hum.Health>0 and not ff
    end

    local function _abGetBestTarget(myHrp)
        if _abLockedTarget and _abIsValidTarget(_abLockedTarget) then return _abLockedTarget:FindFirstChild("HumanoidRootPart"),_abLockedTarget end
        local shortest,newTarget,newHrp=math.huge,nil,nil
        for _,pl in ipairs(Players:GetPlayers()) do
            if pl~=Player and _abIsValidTarget(pl.Character) then
                local h=pl.Character:FindFirstChild("HumanoidRootPart")
                if h then local dist=(h.Position-myHrp.Position).Magnitude; if dist<shortest then shortest=dist; newHrp=h; newTarget=pl.Character end end
            end
        end
        _abLockedTarget=newTarget; return newHrp,newTarget
    end

    local function _abFindBat()
        local c=Player.Character if not c then return nil end
        for _,tool in ipairs(c:GetChildren()) do if tool:IsA("Tool") and (tool.Name:lower():find("bat") or tool.Name:lower():find("slap")) then return tool end end
        local bp=Player:FindFirstChildOfClass("Backpack")
        if bp then for _,tool in ipairs(bp:GetChildren()) do if tool:IsA("Tool") and (tool.Name:lower():find("bat") or tool.Name:lower():find("slap")) then return tool end end end
        return nil
    end

    local function _abStop()
        abActive=false
        if _abAimConn then _abAimConn:Disconnect(); _abAimConn=nil end
        if _abHighlight then _abHighlight:Destroy(); _abHighlight=nil end
        _abLockedTarget=nil
        pcall(function()
            local c=Player.Character; local hrp=c and c:FindFirstChild("HumanoidRootPart"); local hum=c and c:FindFirstChildOfClass("Humanoid")
            if hrp then local al=hrp:FindFirstChild("HUBDUEL_AimbotAlign"); local at=hrp:FindFirstChild("HUBDUEL_AimbotAttach"); if al then al:Destroy() end; if at then at:Destroy() end end
            if hum then hum.AutoRotate=true end
        end)
    end

    local function _abStart()
        _abStop(); abActive=true
        _abHighlight=Instance.new("Highlight"); _abHighlight.Name="HUBDUEL_BatAimbot"
        _abHighlight.FillColor=Color3.fromRGB(255,50,100); _abHighlight.OutlineColor=Color3.fromRGB(255,255,255)
        _abHighlight.FillTransparency=0.4; _abHighlight.OutlineTransparency=0.2
        pcall(function() _abHighlight.Parent=Player:WaitForChild("PlayerGui") end)
        local c=Player.Character if not c then return end
        local hrp=c:FindFirstChild("HumanoidRootPart"); local hum=c:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end
        hum.AutoRotate=false
        local align=Instance.new("AlignOrientation",hrp); align.Name="HUBDUEL_AimbotAlign"
        align.Mode=Enum.OrientationAlignmentMode.OneAttachment; align.MaxTorque=math.huge; align.Responsiveness=250
        local attachment=Instance.new("Attachment",hrp); attachment.Name="HUBDUEL_AimbotAttach"; align.Attachment0=attachment
        _abAimConn=RunService.Heartbeat:Connect(function()
            if not abActive then return end
            pcall(function()
                local myC=Player.Character if not myC then return end
                local myHRP=myC:FindFirstChild("HumanoidRootPart"); local myHum=myC:FindFirstChildOfClass("Humanoid")
                if not myHRP or not myHum then return end
                local bat=_abFindBat(); if bat and bat.Parent~=myC then pcall(function() myHum:EquipTool(bat) end) end
                local targetHrp,targetChar=_abGetBestTarget(myHRP)
                if targetHrp and targetChar then
                    _abHighlight.Adornee=targetChar
                    local targetVel=targetHrp.AssemblyLinearVelocity
                    local predictTime=math.clamp(targetVel.Magnitude/160,0.05,0.25)
                    local predictedPos=targetHrp.Position+(targetVel*predictTime)
                    local dirToTarget=predictedPos-myHRP.Position; local distance=dirToTarget.Magnitude
                    local curAlign=myHRP:FindFirstChild("HUBDUEL_AimbotAlign"); if curAlign then curAlign.CFrame=CFrame.lookAt(myHRP.Position,predictedPos) end
                    local targetPos=(distance>0) and predictedPos-(dirToTarget.Unit*3.5) or predictedPos
                    local moveDir=targetPos-myHRP.Position; local moveDist=moveDir.Magnitude
                    if moveDist>1.5 then myHRP.AssemblyLinearVelocity=moveDir.Unit*Values.AimbotSpeed
                    else myHRP.AssemblyLinearVelocity=targetHrp.AssemblyLinearVelocity end
                    if distance<=5 and bat and bat.Parent==myC then pcall(function() bat:Activate() end) end
                else
                    _abHighlight.Adornee=nil; _abLockedTarget=nil
                    local md=myHum.MoveDirection; if md.Magnitude>0.1 then myHRP.AssemblyLinearVelocity=md.Unit*Values.AimbotSpeed end
                end
            end)
        end)
    end

    local function abToggle() if abActive then _abStop() else _abStart() end; if abVisualSetter then abVisualSetter(abActive) end end
    Player.CharacterAdded:Connect(function() if not abActive then return end; task.wait(0.5); _abStart() end)
    getgenv().HUBDUEL_abToggle=abToggle
end -- END BLOCK 3

-- ============================================================
-- BLOCK 4: GUI
-- ============================================================
do
    local isMobile=UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    local GS=isMobile and 0.85 or 1

    local function onTap(btn,cb)
        if isMobile then btn.Activated:Connect(cb) else btn.MouseButton1Click:Connect(cb) end
    end

    local C={
        bg=Color3.fromRGB(8,6,16), bgRow=Color3.fromRGB(18,14,30), purple=Color3.fromRGB(138,43,226),
        purpleLight=Color3.fromRGB(180,100,255), purpleDark=Color3.fromRGB(80,20,140), purpleDim=Color3.fromRGB(100,60,160),
        white=Color3.fromRGB(255,255,255), dim=Color3.fromRGB(160,130,200), muted=Color3.fromRGB(100,80,140),
        off=Color3.fromRGB(35,28,55), border=Color3.fromRGB(80,50,120), danger=Color3.fromRGB(220,50,80),
        dangerDark=Color3.fromRGB(100,20,40), badge=Color3.fromRGB(40,28,65), badgeActive=Color3.fromRGB(100,60,180),
        accent=Color3.fromRGB(200,100,255), tabActive=Color3.fromRGB(120,40,200), tabInactive=Color3.fromRGB(22,16,40),
    }

    local WIN_W=math.floor(370*GS); local WIN_H=math.floor(460*GS); local CR=math.floor(10*GS)
    local TITLE_H=math.floor(54*GS); local TAB_H=math.floor(34*GS); local ROW_H=math.floor(38*GS); local SL_H=math.floor(56*GS)

    local sg=Instance.new("ScreenGui"); sg.Name="OXDHUB_GUI"; sg.ResetOnSpawn=false
    sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; sg.Parent=Player.PlayerGui

    local function playSound(id,vol,spd)
        pcall(function()
            local s=Instance.new("Sound",SoundService); s.SoundId=id; s.Volume=vol or 0.3; s.PlaybackSpeed=spd or 1
            s:Play(); game:GetService("Debris"):AddItem(s,1)
        end)
    end

    local function rc(inst,r) local c=Instance.new("UICorner",inst); c.CornerRadius=UDim.new(0,r or CR) end
    local function st(inst,thick,col,trans)
        local s=Instance.new("UIStroke",inst); s.Thickness=thick or 2; s.Color=col or C.purple
        s.Transparency=trans or 0; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
    end
    local function grad(inst,rot,c0,c1)
        local g=Instance.new("UIGradient",inst); g.Rotation=rot
        g.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,c0),ColorSequenceKeypoint.new(1,c1)}; return g
    end

    local mainWrap=Instance.new("Frame",sg); mainWrap.Name="OXDHUB_MainWrap"
    mainWrap.Size=UDim2.new(0,WIN_W+4,0,WIN_H+4); mainWrap.Position=UDim2.new(0.5,-(WIN_W+4)/2,0.5,-(WIN_H+4)/2)
    mainWrap.BackgroundColor3=Color3.fromRGB(100,15,160); mainWrap.BackgroundTransparency=0.5
    mainWrap.BorderSizePixel=0; mainWrap.Active=false; mainWrap.ZIndex=8
    local mwCorner=Instance.new("UICorner",mainWrap); mwCorner.CornerRadius=UDim.new(0,CR+2)
    local mainWrapGrad=Instance.new("UIGradient",mainWrap)
    mainWrapGrad.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.fromRGB(220,100,255)),ColorSequenceKeypoint.new(0.18,Color3.fromRGB(140,30,210)),ColorSequenceKeypoint.new(0.45,Color3.fromRGB(35,5,75)),ColorSequenceKeypoint.new(0.72,Color3.fromRGB(100,15,160)),ColorSequenceKeypoint.new(1,Color3.fromRGB(220,100,255))}
    local mwAngle=0; local function mwShimmer() mwAngle=(mwAngle+1.2)%360; mainWrapGrad.Rotation=mwAngle; task.delay(1/40,mwShimmer) end; task.delay(0.1,mwShimmer)

    local main=Instance.new("Frame",mainWrap); main.Name="OXDHUB_Main"
    main.Size=UDim2.new(0,WIN_W,0,WIN_H); main.Position=UDim2.new(0,2,0,2)
    main.BackgroundColor3=C.bg; main.BackgroundTransparency=0.15; main.BorderSizePixel=0; main.Active=true; rc(main,CR)
    main:GetPropertyChangedSignal("Visible"):Connect(function() mainWrap.Visible=main.Visible end)
    mainWrap.Visible=false; main.Visible=false

    local titleBar=Instance.new("Frame",main); titleBar.Size=UDim2.new(1,0,0,TITLE_H); titleBar.BackgroundTransparency=1; titleBar.BorderSizePixel=0; titleBar.ZIndex=2
    local accentLine=Instance.new("Frame",main); accentLine.Size=UDim2.new(1,0,0,2); accentLine.Position=UDim2.new(0,0,0,TITLE_H)
    accentLine.BackgroundColor3=C.purple; accentLine.BorderSizePixel=0; accentLine.ZIndex=3; grad(accentLine,0,C.purpleLight,C.purpleDark)
    local iconDot=Instance.new("Frame",main); iconDot.Size=UDim2.new(0,8,0,8); iconDot.Position=UDim2.new(0,math.floor(16*GS),0,math.floor((TITLE_H-8)/2))
    iconDot.BackgroundColor3=C.accent; iconDot.BorderSizePixel=0; iconDot.ZIndex=4; rc(iconDot,4)
    local titleTxt=Instance.new("TextLabel",main); titleTxt.Size=UDim2.new(1,-math.floor(80*GS),0,TITLE_H); titleTxt.Position=UDim2.new(0,math.floor(30*GS),0,0)
    titleTxt.BackgroundTransparency=1; titleTxt.Text="Oxd Hub"; titleTxt.TextColor3=C.white; titleTxt.Font=Enum.Font.GothamBlack
    titleTxt.TextSize=math.floor(22*GS); titleTxt.TextXAlignment=Enum.TextXAlignment.Left; titleTxt.TextYAlignment=Enum.TextYAlignment.Center; titleTxt.ZIndex=4
    local CBW=math.floor(24*GS)
    local closeBtn=Instance.new("TextButton",main); closeBtn.Size=UDim2.new(0,CBW,0,CBW); closeBtn.Position=UDim2.new(1,-math.floor(CBW+12*GS),0,math.floor((TITLE_H-CBW)/2))
    closeBtn.BackgroundColor3=C.dangerDark; closeBtn.Text="✕"; closeBtn.TextColor3=C.white; closeBtn.Font=Enum.Font.GothamBold; closeBtn.TextSize=math.floor(13*GS); closeBtn.BorderSizePixel=0; closeBtn.ZIndex=5; rc(closeBtn,math.floor(CBW/2)); st(closeBtn,1.5,C.danger,0.3)

    local tabBar=Instance.new("Frame",main); tabBar.Size=UDim2.new(1,0,0,TAB_H); tabBar.Position=UDim2.new(0,0,0,TITLE_H+2)
    tabBar.BackgroundColor3=C.bg; tabBar.BorderSizePixel=0; tabBar.ZIndex=3
    local tabLayout=Instance.new("UIListLayout",tabBar); tabLayout.FillDirection=Enum.FillDirection.Horizontal; tabLayout.SortOrder=Enum.SortOrder.LayoutOrder; tabLayout.Padding=UDim.new(0,2)
    local tabPad=Instance.new("UIPadding",tabBar); tabPad.PaddingLeft=UDim.new(0,math.floor(4*GS)); tabPad.PaddingRight=UDim.new(0,math.floor(4*GS)); tabPad.PaddingTop=UDim.new(0,math.floor(4*GS)); tabPad.PaddingBottom=UDim.new(0,math.floor(4*GS))
    local tabSep=Instance.new("Frame",main); tabSep.Size=UDim2.new(1,0,0,1); tabSep.Position=UDim2.new(0,0,0,TITLE_H+2+TAB_H); tabSep.BackgroundColor3=C.border; tabSep.BorderSizePixel=0; tabSep.ZIndex=3

    local SCROLL_Y=TITLE_H+2+TAB_H+2
    local scroll=Instance.new("ScrollingFrame",main); scroll.Size=UDim2.new(1,0,0,WIN_H-SCROLL_Y); scroll.Position=UDim2.new(0,0,0,SCROLL_Y)
    scroll.BackgroundTransparency=1; scroll.BorderSizePixel=0; scroll.ScrollBarThickness=math.floor(3*GS); scroll.ScrollBarImageColor3=C.purpleDim
    scroll.CanvasSize=UDim2.new(0,0,0,0); scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y; scroll.ScrollingDirection=Enum.ScrollingDirection.Y; scroll.ZIndex=2
    local layout=Instance.new("UIListLayout",scroll); layout.SortOrder=Enum.SortOrder.LayoutOrder; layout.Padding=UDim.new(0,math.floor(3*GS))
    local pad=Instance.new("UIPadding",scroll); pad.PaddingTop=UDim.new(0,math.floor(6*GS)); pad.PaddingBottom=UDim.new(0,math.floor(12*GS)); pad.PaddingLeft=UDim.new(0,math.floor(8*GS)); pad.PaddingRight=UDim.new(0,math.floor(8*GS))

    local tabs={}; local tabContents={}; local activeTab=nil; local waitingForKeybind=nil

    -- 8 sekme: DUEL, MOVE, STEAL, ESP, PROTECTION, THEMES, CONFIG, SCALE
    local TAB_DEFS={
        {name="DUEL",label="DUEL"},{name="MOVE",label="MOVE"},{name="STEAL",label="STEAL"},
        {name="ESP",label="ESP"},{name="PROTECTION",label="PROT"},{name="THEMES",label="THEMES"},
        {name="CONFIG",label="CFG"},{name="SCALE",label="SCALE"},
    }

    local function createTab(def,order)
        local tabCount=#TAB_DEFS
        local btn=Instance.new("TextButton",tabBar)
        btn.Size=UDim2.new(0,math.floor((WIN_W-8-2*(tabCount-1))/tabCount*GS),0,TAB_H-8)
        btn.BackgroundColor3=C.tabInactive; btn.Text=def.label; btn.TextColor3=C.muted
        btn.Font=Enum.Font.GothamBold; btn.TextSize=math.floor(8*GS); btn.BorderSizePixel=0
        btn.LayoutOrder=order; btn.ZIndex=4; btn.TextScaled=false; rc(btn,math.floor(5*GS)); st(btn,1,C.border,0.5)
        local holder=Instance.new("Frame",scroll); holder.Size=UDim2.new(1,0,0,0); holder.AutomaticSize=Enum.AutomaticSize.Y
        holder.BackgroundTransparency=1; holder.BorderSizePixel=0; holder.LayoutOrder=1; holder.Visible=false
        local innerLayout=Instance.new("UIListLayout",holder); innerLayout.SortOrder=Enum.SortOrder.LayoutOrder; innerLayout.Padding=UDim.new(0,math.floor(3*GS))
        tabs[def.name]=btn; tabContents[def.name]=holder; return btn,holder
    end

    for i,def in ipairs(TAB_DEFS) do createTab(def,i) end

    local function switchTab(name)
        if activeTab==name then return end; activeTab=name
        for k,btn in pairs(tabs) do
            local isActive=(k==name)
            TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=isActive and C.tabActive or C.tabInactive,TextColor3=isActive and C.white or C.muted}):Play()
            tabContents[k].Visible=isActive
        end
        playSound("rbxassetid://6895079813",0.2,1.2)
    end

    for k,btn in pairs(tabs) do local tn=k; btn.MouseButton1Click:Connect(function() switchTab(tn) end) end

    local function getTabHolder(n) return tabContents[n] end
    local orderCounters={}; for _,def in ipairs(TAB_DEFS) do orderCounters[def.name]=0 end
    local function nextOrder(n) orderCounters[n]=orderCounters[n]+1; return orderCounters[n] end

    local function createSectionHeader(tabName,txt)
        local holder=getTabHolder(tabName); local w=Instance.new("Frame",holder)
        w.Size=UDim2.new(1,0,0,math.floor(22*GS)); w.BackgroundTransparency=1; w.LayoutOrder=nextOrder(tabName)
        local lbl=Instance.new("TextLabel",w); lbl.Size=UDim2.new(1,-8,1,0); lbl.Position=UDim2.new(0,4,0,0); lbl.BackgroundTransparency=1
        lbl.Text="◆  "..txt; lbl.TextColor3=C.purpleLight; lbl.Font=Enum.Font.GothamBold; lbl.TextSize=math.floor(9*GS); lbl.TextXAlignment=Enum.TextXAlignment.Left
    end

    local KB_W=math.floor(50*GS); local KB_H=math.floor(20*GS)

    local function createKeybindBadge(parent,keybindKey)
        if not keybindKey then return nil end
        local kc0=KEYBINDS[keybindKey]; local btn=Instance.new("TextButton",parent)
        btn.Size=UDim2.new(0,KB_W,0,KB_H)
        local pillRight=math.floor(42*GS)+math.floor(8*GS)
        btn.Position=UDim2.new(1,-(pillRight+KB_W+math.floor(6*GS)),0.5,-math.floor(KB_H/2))
        btn.BackgroundColor3=C.badge; btn.Text=(kc0==Enum.KeyCode.Unknown) and "—" or kc0.Name
        btn.TextColor3=C.purpleLight; btn.Font=Enum.Font.GothamBold; btn.TextSize=math.floor(8*GS)
        btn.TextScaled=false; btn.TextTruncate=Enum.TextTruncate.AtEnd; btn.BorderSizePixel=0; btn.ZIndex=15
        rc(btn,math.floor(5*GS)); st(btn,1.5,C.purpleDim,0.3); KeyBindBtns[keybindKey]=btn
        btn.MouseButton1Click:Connect(function()
            if waitingForKeybind==keybindKey then
                waitingForKeybind=nil; local kc2=KEYBINDS[keybindKey]; btn.Text=(kc2==Enum.KeyCode.Unknown) and "—" or kc2.Name
                TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=C.badge}):Play(); return
            end
            if waitingForKeybind then
                local prev=KeyBindBtns[waitingForKeybind]
                if prev then local pkc=KEYBINDS[waitingForKeybind]; prev.Text=(pkc==Enum.KeyCode.Unknown) and "—" or pkc.Name; TweenService:Create(prev,TweenInfo.new(0.15),{BackgroundColor3=C.badge}):Play() end
            end
            waitingForKeybind=keybindKey; btn.Text="?"; TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=C.badgeActive}):Play(); playSound("rbxassetid://6895079813",0.3,1.5)
        end)
        btn.MouseButton2Click:Connect(function()
            KEYBINDS[keybindKey]=Enum.KeyCode.Unknown; btn.Text="—"; waitingForKeybind=nil
            TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=C.badge}):Play()
        end)
        return btn
    end

    local function createToggle(tabName,labelTxt,enabledKey,callback,keybindKey)
        local holder=getTabHolder(tabName); local row=Instance.new("Frame",holder)
        row.Size=UDim2.new(1,0,0,ROW_H); row.BackgroundColor3=C.bgRow; row.BorderSizePixel=0; row.LayoutOrder=nextOrder(tabName)
        rc(row,math.floor(8*GS)); st(row,1.5,C.border,0.6)
        local PW=math.floor(42*GS); local PH=math.floor(22*GS)
        local rightReserve=PW+math.floor(8*GS)+(keybindKey and (KB_W+math.floor(6*GS)) or 0)+math.floor(8*GS)
        local lbl=Instance.new("TextLabel",row); lbl.Size=UDim2.new(1,-(math.floor(12*GS)+rightReserve),1,0); lbl.Position=UDim2.new(0,math.floor(12*GS),0,0)
        lbl.BackgroundTransparency=1; lbl.Text=labelTxt; lbl.TextColor3=C.white; lbl.Font=Enum.Font.GothamSemibold; lbl.TextSize=math.floor(11*GS)
        lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.TextTruncate=Enum.TextTruncate.AtEnd; lbl.ZIndex=2
        local isOn=Enabled[enabledKey] or false
        local pill=Instance.new("Frame",row); pill.Size=UDim2.new(0,PW,0,PH); pill.Position=UDim2.new(1,-(PW+math.floor(8*GS)),0.5,-PH/2)
        pill.BackgroundColor3=isOn and C.purple or C.off; pill.BorderSizePixel=0; pill.ZIndex=5; rc(pill,PH/2); st(pill,1.5,C.purpleDim,0.4)
        local KW=math.floor(16*GS); local knob=Instance.new("Frame",pill); knob.Size=UDim2.new(0,KW,0,KW)
        knob.Position=isOn and UDim2.new(1,-(KW+3),0.5,-KW/2) or UDim2.new(0,3,0.5,-KW/2)
        knob.BackgroundColor3=isOn and C.white or C.purpleDim; knob.BorderSizePixel=0; knob.ZIndex=6; rc(knob,KW/2)
        createKeybindBadge(row,keybindKey)
        local clk=Instance.new("TextButton",row); clk.Size=UDim2.new(1,0,1,0); clk.BackgroundTransparency=1; clk.Text=""; clk.ZIndex=10
        local function setVisual(state,skipCB)
            isOn=state; TweenService:Create(pill,TweenInfo.new(0.18),{BackgroundColor3=isOn and C.purple or C.off}):Play()
            TweenService:Create(knob,TweenInfo.new(0.18,Enum.EasingStyle.Back),{BackgroundColor3=isOn and C.white or C.purpleDim,Position=isOn and UDim2.new(1,-(KW+3),0.5,-KW/2) or UDim2.new(0,3,0.5,-KW/2)}):Play()
            if not skipCB then callback(isOn) end
        end
        VisualSetters[enabledKey]=setVisual
        local function doToggle()
            if waitingForKeybind then return end
            isOn=not isOn; Enabled[enabledKey]=isOn; setVisual(isOn); playSound("rbxassetid://6895079813",0.3,isOn and 1.1 or 0.9)
        end
        if isMobile then clk.Activated:Connect(doToggle) else clk.MouseButton1Click:Connect(doToggle) end
        return row,setVisual
    end

    local function createSlider(tabName,labelTxt,minV,maxV,valueKey,callback)
        local holder=getTabHolder(tabName); local f=Instance.new("Frame",holder)
        f.Size=UDim2.new(1,0,0,SL_H); f.BackgroundColor3=C.bgRow; f.BorderSizePixel=0; f.LayoutOrder=nextOrder(tabName)
        rc(f,math.floor(8*GS)); st(f,1.5,C.border,0.6)
        local lbl=Instance.new("TextLabel",f); lbl.Size=UDim2.new(0.65,0,0,math.floor(18*GS)); lbl.Position=UDim2.new(0,math.floor(12*GS),0,math.floor(5*GS))
        lbl.BackgroundTransparency=1; lbl.Text=labelTxt; lbl.TextColor3=C.dim; lbl.Font=Enum.Font.GothamMedium; lbl.TextSize=math.floor(10*GS); lbl.TextXAlignment=Enum.TextXAlignment.Left
        local function r1(n) return math.floor(n*10+0.5)/10 end
        local function fmt(n) return string.format("%.1f",n) end
        local defVal=r1(Values[valueKey] or minV)
        local valBox=Instance.new("TextBox",f); valBox.Size=UDim2.new(0,math.floor(50*GS),0,math.floor(20*GS)); valBox.Position=UDim2.new(1,-math.floor(58*GS),0,math.floor(3*GS))
        valBox.BackgroundColor3=C.off; valBox.Text=fmt(defVal); valBox.TextColor3=C.purpleLight; valBox.Font=Enum.Font.GothamBold; valBox.TextSize=math.floor(10*GS)
        valBox.ClearTextOnFocus=false; valBox.BorderSizePixel=0; rc(valBox,6); st(valBox,1.5,C.border,0.4)
        local track=Instance.new("Frame",f); track.Size=UDim2.new(1,-math.floor(16*GS),0,math.floor(6*GS)); track.Position=UDim2.new(0,math.floor(8*GS),1,-math.floor(14*GS))
        track.BackgroundColor3=C.off; track.BorderSizePixel=0; rc(track,4); st(track,1.5,C.border,0.5)
        local pct=math.clamp((defVal-minV)/(maxV-minV),0,1)
        local fill=Instance.new("Frame",track); fill.Size=UDim2.new(pct,0,1,0); fill.BackgroundColor3=C.purple; fill.BorderSizePixel=0; rc(fill,4); grad(fill,0,C.purpleLight,C.purple)
        local thumb=Instance.new("Frame",track); thumb.Size=UDim2.new(0,math.floor(12*GS),0,math.floor(12*GS)); thumb.Position=UDim2.new(pct,-math.floor(6*GS),0.5,-math.floor(6*GS))
        thumb.BackgroundColor3=C.purpleLight; thumb.BorderSizePixel=0; rc(thumb,math.floor(6*GS)); st(thumb,1.5,C.white,0.4)
        local hitbox=Instance.new("TextButton",track); hitbox.Size=UDim2.new(1,0,5,0); hitbox.Position=UDim2.new(0,0,-2,0); hitbox.BackgroundTransparency=1; hitbox.Text=""
        local dragging=false
        local function setVal(rel)
            rel=math.clamp(rel,0,1); fill.Size=UDim2.new(rel,0,1,0); thumb.Position=UDim2.new(rel,-math.floor(6*GS),0.5,-math.floor(6*GS))
            local v=r1(math.clamp(r1(minV+(maxV-minV)*rel),minV,maxV)); valBox.Text=fmt(v); Values[valueKey]=v; callback(v)
        end
        local function setSlider(v)
            v=r1(math.clamp(v,minV,maxV)); local r=(v-minV)/(maxV-minV)
            fill.Size=UDim2.new(r,0,1,0); thumb.Position=UDim2.new(r,-math.floor(6*GS),0.5,-math.floor(6*GS)); valBox.Text=fmt(v); Values[valueKey]=v
        end
        SliderSetters[valueKey]=setSlider
        hitbox.MouseButton1Down:Connect(function() dragging=true end)
        hitbox.InputBegan:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.Touch then dragging=true end end)
        UserInputService.InputEnded:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then dragging=false end end)
        UserInputService.InputChanged:Connect(function(inp)
            if dragging and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then
                setVal((inp.Position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X)
            end
        end)
        valBox.FocusLost:Connect(function()
            local n=tonumber(valBox.Text)
            if n then setSlider(r1(math.clamp(n,minV,maxV))); callback(Values[valueKey]) else valBox.Text=fmt(Values[valueKey] or minV) end
        end)
        return f,setSlider
    end

    local function createActionBtn(tabName,txt,bgCol,strokeCol,callback)
        local holder=getTabHolder(tabName); local f=Instance.new("Frame",holder)
        f.Size=UDim2.new(1,0,0,math.floor(36*GS)); f.BackgroundTransparency=1; f.LayoutOrder=nextOrder(tabName)
        local btn=Instance.new("TextButton",f); btn.Size=UDim2.new(1,0,1,0); btn.BackgroundColor3=bgCol; btn.Text=txt; btn.TextColor3=C.white
        btn.Font=Enum.Font.GothamBold; btn.TextSize=math.floor(11*GS); btn.BorderSizePixel=0; rc(btn,math.floor(8*GS)); st(btn,2,strokeCol,0.2)
        onTap(btn,function() callback(btn) end); return f,btn
    end

    -- ============================================================
    -- BUILD TABS
    -- ============================================================

    -- DUEL TAB
    createSectionHeader("DUEL","AUTO DUEL")
    createSectionHeader("DUEL","AUTO PLAY SPEEDS")
    createSlider("DUEL","Speed (No Steal)",10,80,"SpeedNoSteal",function(v) Values.SpeedNoSteal=v end)
    createSlider("DUEL","Speed (Stealing)",10,60,"SpeedStealing",function(v) Values.SpeedStealing=v end)
    createSectionHeader("DUEL","QUICK ACTIONS")
    createToggle("DUEL","Insta Grab","InstaGrab",function(s) Enabled.InstaGrab=s; instaGrab=s end,nil)

    -- MOVE TAB
    createSectionHeader("MOVE","PHYSICS")
    createToggle("MOVE","Galaxy (Low Gravity)","Galaxy",function(s) Enabled.Galaxy=s; if s then getgenv().HUBDUEL_startGalaxy() else getgenv().HUBDUEL_stopGalaxy() end end,"GALAXY")
    createSlider("MOVE","Gravity %",25,130,"GalaxyGravityPercent",function(v) Values.GalaxyGravityPercent=v; if galaxyEnabled then getgenv().HUBDUEL_adjustGalaxyJump() end end)
    createSlider("MOVE","Jump Boost",10,80,"HOP_POWER",function(v) Values.HOP_POWER=v end)
    createToggle("MOVE","Float","Float",function(s) Enabled.Float=s; if s then getgenv().HUBDUEL_startFloat() else getgenv().HUBDUEL_stopFloat() end end,"FLOAT")
    createSlider("MOVE","Float Height",1,50,"FloatHeight",function(v) Values.FloatHeight=v end)
    createToggle("MOVE","Infinite Jump","InfJump",function(s) Enabled.InfJump=s; infJumpEnabled=s end,nil)
    createSectionHeader("MOVE","COMBAT")
    createSlider("MOVE","Aimbot Speed",10,300,"AimbotSpeed",function(v) Values.AimbotSpeed=v end)
    createToggle("MOVE","Spin Bot","SpinBot",function(s) Enabled.SpinBot=s; if s then getgenv().HUBDUEL_startSpinBot() else getgenv().HUBDUEL_stopSpinBot() end end,"SPIN")
    createSlider("MOVE","Spin Speed",5,50,"SpinSpeed",function(v) Values.SpinSpeed=v end)
    local isMobileCheck=UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    if not isMobileCheck then
        createToggle("MOVE","Aimbot","Aimbot",function(s) if s==abActive then return end; getgenv().HUBDUEL_abToggle() end,"AIMBOT")
        abVisualSetter=function(on) if VisualSetters.Aimbot then VisualSetters.Aimbot(on,true) end end
    end

    -- STEAL TAB
    createSectionHeader("STEAL","AUTO GRAB")
    createToggle("STEAL","Auto Grab","AutoSteal",function(s) Enabled.AutoSteal=s; if s then getgenv().HUBDUEL_startAutoSteal() else getgenv().HUBDUEL_stopAutoSteal() end end,nil)
    createSlider("STEAL","Steal Radius",5,100,"STEAL_RADIUS",function(v) Values.STEAL_RADIUS=v end)
    createSlider("STEAL","Steal Duration",0.1,5,"STEAL_DURATION",function(v) Values.STEAL_DURATION=v end)

    -- ESP TAB (yeni)
    createSectionHeader("ESP","VISUAL")
    createToggle("ESP","Highlight ESP","HighlightESP",function(s) Enabled.HighlightESP=s; if s then getgenv().HUBDUEL_updateESP() else getgenv().HUBDUEL_clearESP() end end,nil)
    createToggle("ESP","Box ESP","BoxESP",function(s) Enabled.BoxESP=s; if s then getgenv().HUBDUEL_updateESP() else getgenv().HUBDUEL_clearESP() end end,nil)
    createSectionHeader("ESP","PERFORMANCE")
    createToggle("ESP","Optimizer + XRay","Optimizer",function(s) Enabled.Optimizer=s; if s then getgenv().HUBDUEL_enableOptimizer() else getgenv().HUBDUEL_disableOptimizer() end end,nil)
    createSectionHeader("ESP","CAMERA")
    createSlider("ESP","FOV",30,120,"FOV",function(v) Values.FOV=v; pcall(function() local cam=workspace.CurrentCamera; if cam then cam.FieldOfView=v end end) end)

    -- PROTECTION TAB (yeni)
    createSectionHeader("PROTECTION","RAGDOLL")
    createToggle("PROTECTION","Anti Ragdoll","AntiRagdoll",function(s) Enabled.AntiRagdoll=s; if s then getgenv().HUBDUEL_startAntiRagdoll() else getgenv().HUBDUEL_stopAntiRagdoll() end end,"ANTIRAGDOLL")

    createSectionHeader("PROTECTION","DROP")
    do
        local holder=getTabHolder("PROTECTION")
        local dkRow=Instance.new("Frame",holder); dkRow.Size=UDim2.new(1,0,0,ROW_H); dkRow.BackgroundColor3=C.bgRow; dkRow.BorderSizePixel=0; dkRow.LayoutOrder=nextOrder("PROTECTION")
        rc(dkRow,math.floor(8*GS)); st(dkRow,1.5,C.border,0.6)
        local dkLbl=Instance.new("TextLabel",dkRow); dkLbl.Size=UDim2.new(0.55,0,1,0); dkLbl.Position=UDim2.new(0,math.floor(12*GS),0,0)
        dkLbl.BackgroundTransparency=1; dkLbl.Text="Drop GUI"; dkLbl.TextColor3=C.white; dkLbl.Font=Enum.Font.GothamSemibold; dkLbl.TextSize=math.floor(11*GS); dkLbl.TextXAlignment=Enum.TextXAlignment.Left; dkLbl.ZIndex=2
        local PW2=math.floor(42*GS); local PH2=math.floor(22*GS); local dropGuiVisible=false
        local dropPill=Instance.new("Frame",dkRow); dropPill.Size=UDim2.new(0,PW2,0,PH2); dropPill.Position=UDim2.new(1,-(PW2+math.floor(8*GS)),0.5,-PH2/2)
        dropPill.BackgroundColor3=C.off; dropPill.BorderSizePixel=0; dropPill.ZIndex=5; rc(dropPill,PH2/2); st(dropPill,1.5,C.purpleDim,0.4)
        local KW2=math.floor(16*GS); local dropKnob=Instance.new("Frame",dropPill); dropKnob.Size=UDim2.new(0,KW2,0,KW2); dropKnob.Position=UDim2.new(0,3,0.5,-KW2/2)
        dropKnob.BackgroundColor3=C.purpleDim; dropKnob.BorderSizePixel=0; dropKnob.ZIndex=6; rc(dropKnob,KW2/2)
        local dkBadge=Instance.new("TextButton",dkRow); dkBadge.Size=UDim2.new(0,KB_W,0,KB_H); dkBadge.Position=UDim2.new(1,-(PW2+math.floor(8*GS)+KB_W+math.floor(6*GS)),0.5,-KB_H/2)
        dkBadge.BackgroundColor3=C.badge; dkBadge.Text=(KEYBINDS.DROP==Enum.KeyCode.Unknown) and "—" or KEYBINDS.DROP.Name; dkBadge.TextColor3=C.purpleLight
        dkBadge.Font=Enum.Font.GothamBold; dkBadge.TextSize=math.floor(9*GS); dkBadge.BorderSizePixel=0; dkBadge.ZIndex=8; rc(dkBadge,math.floor(5*GS)); st(dkBadge,1.5,C.border,0.5)
        KeyBindBtns["DROP"]=dkBadge
        local waitDrop=false
        dkBadge.MouseButton1Click:Connect(function()
            if waitDrop then return end; waitDrop=true; dkBadge.Text="?"; TweenService:Create(dkBadge,TweenInfo.new(0.15),{BackgroundColor3=C.badgeActive}):Play()
            local conn; conn=UserInputService.InputBegan:Connect(function(inp)
                if inp.UserInputType~=Enum.UserInputType.Keyboard then return end
                if inp.KeyCode==Enum.KeyCode.Unknown then return end
                KEYBINDS.DROP=inp.KeyCode; dkBadge.Text=inp.KeyCode.Name; TweenService:Create(dkBadge,TweenInfo.new(0.15),{BackgroundColor3=C.badge}):Play(); waitDrop=false; conn:Disconnect()
            end)
        end)
        dkBadge.MouseButton2Click:Connect(function() KEYBINDS.DROP=Enum.KeyCode.Unknown; dkBadge.Text="—"; waitDrop=false; TweenService:Create(dkBadge,TweenInfo.new(0.15),{BackgroundColor3=C.badge}):Play() end)
        local dropClk=Instance.new("TextButton",dkRow); dropClk.Size=UDim2.new(0.55,0,1,0); dropClk.BackgroundTransparency=1; dropClk.Text=""; dropClk.ZIndex=10
        local function toggleDropGui()
            dropGuiVisible=not dropGuiVisible
            TweenService:Create(dropPill,TweenInfo.new(0.18),{BackgroundColor3=dropGuiVisible and C.purple or C.off}):Play()
            TweenService:Create(dropKnob,TweenInfo.new(0.18,Enum.EasingStyle.Back),{BackgroundColor3=dropGuiVisible and C.white or C.purpleDim,Position=dropGuiVisible and UDim2.new(1,-(KW2+3),0.5,-KW2/2) or UDim2.new(0,3,0.5,-KW2/2)}):Play()
            getgenv().HUBDUEL_dropFloatVisible(dropGuiVisible)
        end
        onTap(dropClk,toggleDropGui); getgenv().HUBDUEL_toggleDropGui=toggleDropGui
    end

    createSectionHeader("PROTECTION","TP DOWN")
    do
        local holder=getTabHolder("PROTECTION")
        local tkRow=Instance.new("Frame",holder); tkRow.Size=UDim2.new(1,0,0,ROW_H); tkRow.BackgroundColor3=C.bgRow; tkRow.BorderSizePixel=0; tkRow.LayoutOrder=nextOrder("PROTECTION")
        rc(tkRow,math.floor(8*GS)); st(tkRow,1.5,C.border,0.6)
        local tkLbl=Instance.new("TextLabel",tkRow); tkLbl.Size=UDim2.new(0.6,0,1,0); tkLbl.Position=UDim2.new(0,math.floor(12*GS),0,0)
        tkLbl.BackgroundTransparency=1; tkLbl.Text="TP Down Keybind"; tkLbl.TextColor3=C.white; tkLbl.Font=Enum.Font.GothamSemibold; tkLbl.TextSize=math.floor(11*GS); tkLbl.TextXAlignment=Enum.TextXAlignment.Left; tkLbl.ZIndex=2
        local tkBadge=Instance.new("TextButton",tkRow); tkBadge.Size=UDim2.new(0,KB_W,0,KB_H); tkBadge.Position=UDim2.new(1,-(KB_W+math.floor(12*GS)),0.5,-KB_H/2)
        tkBadge.BackgroundColor3=C.badge; tkBadge.Text=(KEYBINDS.TPDOWN==Enum.KeyCode.Unknown) and "—" or KEYBINDS.TPDOWN.Name; tkBadge.TextColor3=C.purpleLight
        tkBadge.Font=Enum.Font.GothamBold; tkBadge.TextSize=math.floor(9*GS); tkBadge.BorderSizePixel=0; tkBadge.ZIndex=8; rc(tkBadge,math.floor(5*GS)); st(tkBadge,1.5,C.border,0.5)
        KeyBindBtns["TPDOWN"]=tkBadge
        local waitTP=false
        tkBadge.MouseButton1Click:Connect(function()
            if waitTP then return end; waitTP=true; tkBadge.Text="?"; TweenService:Create(tkBadge,TweenInfo.new(0.15),{BackgroundColor3=C.badgeActive}):Play()
            local conn; conn=UserInputService.InputBegan:Connect(function(inp)
                if inp.UserInputType~=Enum.UserInputType.Keyboard then return end
                if inp.KeyCode==Enum.KeyCode.Unknown then return end
                KEYBINDS.TPDOWN=inp.KeyCode; tkBadge.Text=inp.KeyCode.Name; TweenService:Create(tkBadge,TweenInfo.new(0.15),{BackgroundColor3=C.badge}):Play(); waitTP=false; conn:Disconnect()
            end)
        end)
        tkBadge.MouseButton2Click:Connect(function() KEYBINDS.TPDOWN=Enum.KeyCode.Unknown; tkBadge.Text="—"; waitTP=false; TweenService:Create(tkBadge,TweenInfo.new(0.15),{BackgroundColor3=C.badge}):Play() end)
    end

    -- THEMES TAB (eski MISC)
    createSectionHeader("THEMES","UTILITY")
    createToggle("THEMES","Unwalk","Unwalk",function(s) Enabled.Unwalk=s; if s then getgenv().HUBDUEL_startUnwalk() else getgenv().HUBDUEL_stopUnwalk() end end,nil)
    createToggle("THEMES","Spam Bat","SpamBat",function(s) Enabled.SpamBat=s; if s then getgenv().HUBDUEL_startSpamBat(); getgenv().HUBDUEL_startSpamBatCircle() else getgenv().HUBDUEL_stopSpamBat(); getgenv().HUBDUEL_removeSpamBatCircle() end end,nil)
    createActionBtn("THEMES","💬  Taunt in Chat",C.purpleDark,C.purple,function()
        pcall(function() game:GetService("TextChatService").TextChannels.RBXGeneral:SendAsync("/Fire On Top") end)
    end)
    createSectionHeader("THEMES","🎨  TEMALAR")
    do
        local THEMES={
            {name="Purple Black",purpleDim=Color3.fromRGB(100,60,160),bg=Color3.fromRGB(8,6,16),bgRow=Color3.fromRGB(18,14,30),purple=Color3.fromRGB(138,43,226),purpleLight=Color3.fromRGB(180,100,255),purpleDark=Color3.fromRGB(80,20,140),accent=Color3.fromRGB(200,100,255),wrapA=Color3.fromRGB(220,100,255),wrapB=Color3.fromRGB(35,5,75),wrapC=Color3.fromRGB(100,15,160)},
            {name="Ocean",purpleDim=Color3.fromRGB(0,80,140),bg=Color3.fromRGB(4,12,22),bgRow=Color3.fromRGB(8,22,40),purple=Color3.fromRGB(0,120,200),purpleLight=Color3.fromRGB(80,180,255),purpleDark=Color3.fromRGB(0,60,120),accent=Color3.fromRGB(0,200,255),wrapA=Color3.fromRGB(0,200,255),wrapB=Color3.fromRGB(0,40,100),wrapC=Color3.fromRGB(0,100,180)},
            {name="Crimson",purpleDim=Color3.fromRGB(140,20,40),bg=Color3.fromRGB(16,4,8),bgRow=Color3.fromRGB(30,10,16),purple=Color3.fromRGB(200,30,60),purpleLight=Color3.fromRGB(255,80,120),purpleDark=Color3.fromRGB(100,10,30),accent=Color3.fromRGB(255,60,100),wrapA=Color3.fromRGB(255,80,120),wrapB=Color3.fromRGB(80,5,20),wrapC=Color3.fromRGB(160,20,50)},
            {name="Emerald",purpleDim=Color3.fromRGB(20,110,55),bg=Color3.fromRGB(4,14,8),bgRow=Color3.fromRGB(8,24,14),purple=Color3.fromRGB(30,160,80),purpleLight=Color3.fromRGB(80,220,130),purpleDark=Color3.fromRGB(10,80,40),accent=Color3.fromRGB(50,230,120),wrapA=Color3.fromRGB(60,240,130),wrapB=Color3.fromRGB(5,60,25),wrapC=Color3.fromRGB(20,130,60)},
            {name="Sunset",purpleDim=Color3.fromRGB(160,60,10),bg=Color3.fromRGB(18,8,4),bgRow=Color3.fromRGB(32,14,8),purple=Color3.fromRGB(220,90,30),purpleLight=Color3.fromRGB(255,160,80),purpleDark=Color3.fromRGB(120,40,10),accent=Color3.fromRGB(255,120,40),wrapA=Color3.fromRGB(255,140,60),wrapB=Color3.fromRGB(100,20,5),wrapC=Color3.fromRGB(200,70,20)},
            {name="Monochrome",purpleDim=Color3.fromRGB(90,90,90),bg=Color3.fromRGB(8,8,8),bgRow=Color3.fromRGB(22,22,22),purple=Color3.fromRGB(140,140,140),purpleLight=Color3.fromRGB(220,220,220),purpleDark=Color3.fromRGB(60,60,60),accent=Color3.fromRGB(200,200,200),wrapA=Color3.fromRGB(220,220,220),wrapB=Color3.fromRGB(30,30,30),wrapC=Color3.fromRGB(100,100,100)},
        }
        local holder=getTabHolder("THEMES")
        local themeScroll=Instance.new("ScrollingFrame",holder); themeScroll.Size=UDim2.new(1,0,0,math.floor(200*GS))
        themeScroll.BackgroundTransparency=1; themeScroll.BorderSizePixel=0; themeScroll.ScrollBarThickness=3; themeScroll.ScrollBarImageColor3=C.purple
        themeScroll.CanvasSize=UDim2.new(0,0,0,#THEMES*(math.floor(38*GS)+math.floor(6*GS))); themeScroll.LayoutOrder=nextOrder("THEMES")
        local tLayout=Instance.new("UIListLayout",themeScroll); tLayout.SortOrder=Enum.SortOrder.LayoutOrder; tLayout.Padding=UDim.new(0,math.floor(6*GS))
        local themeBtns={}
        for i,theme in ipairs(THEMES) do
            local tBtn=Instance.new("TextButton",themeScroll); tBtn.Size=UDim2.new(1,-8,0,math.floor(38*GS))
            tBtn.BackgroundColor3=(i==1) and C.purple or C.badge; tBtn.Text=((i==1) and "✔  " or "    ")..theme.name
            tBtn.TextColor3=(i==1) and C.white or C.dim; tBtn.Font=Enum.Font.GothamSemibold; tBtn.TextSize=math.floor(11*GS); tBtn.BorderSizePixel=0; tBtn.LayoutOrder=i; rc(tBtn,math.floor(8*GS))
            local strip=Instance.new("Frame",tBtn); strip.Size=UDim2.new(0,math.floor(5*GS),0.7,0); strip.Position=UDim2.new(0,math.floor(8*GS),0.15,0)
            strip.BackgroundColor3=theme.accent; strip.BorderSizePixel=0; rc(strip,2); themeBtns[i]=tBtn
            tBtn.MouseButton1Click:Connect(function()
                C.bg=theme.bg; C.bgRow=theme.bgRow; C.purple=theme.purple; C.purpleLight=theme.purpleLight; C.purpleDark=theme.purpleDark; C.accent=theme.accent
                for j,b in ipairs(themeBtns) do
                    TweenService:Create(b,TweenInfo.new(0.15),{BackgroundColor3=(j==i) and C.purple or C.badge,TextColor3=(j==i) and C.white or C.dim}):Play()
                    b.Text=((j==i) and "✔  " or "    ")..THEMES[j].name
                end
                playSound("rbxassetid://6895079813",0.3,1.05)
            end)
        end
    end

    -- CONFIG TAB
    createSectionHeader("CONFIG","SAVE / LOAD")
    createActionBtn("CONFIG","💾  Save Config",C.purpleDark,C.purple,function(btn)
        local ok=getgenv().HUBDUEL_SaveConfig()
        btn.Text=ok and "✔  Saved!" or "✗  Failed"; btn.BackgroundColor3=ok and C.purple or C.dangerDark
        task.delay(2,function() btn.Text="💾  Save Config"; btn.BackgroundColor3=C.purpleDark end); playSound("rbxassetid://6895079813",0.4,ok and 1.2 or 0.7)
    end)
    createActionBtn("CONFIG","🗑  Reset Config",Color3.fromRGB(50,8,20),C.dangerDark,function(btn)
        for k in pairs(Enabled) do Enabled[k]=false end; Enabled.AutoDisableSpeed=true
        for _,setter in pairs(VisualSetters) do setter(false,true) end
        for k,setter in pairs(SliderSetters) do if Values[k] then setter(Values[k]) end end
        getgenv().HUBDUEL_stopAntiRagdoll(); getgenv().HUBDUEL_stopSpinBot(); getgenv().HUBDUEL_stopSpamBat(); getgenv().HUBDUEL_removeSpamBatCircle()
        getgenv().HUBDUEL_stopAutoSteal(); getgenv().HUBDUEL_stopGalaxy(); getgenv().HUBDUEL_stopSpeedWhileStealing()
        getgenv().HUBDUEL_stopUnwalk(); getgenv().HUBDUEL_disableOptimizer(); getgenv().HUBDUEL_stopFloat(); getgenv().HUBDUEL_clearESP()
        if abActive then getgenv().HUBDUEL_abToggle() end
        auto1=false; auto2=false; instaGrab=false; infJumpEnabled=false; apSelectedRoute=nil; apIsRunning=false
        btn.Text="✔  Reset!"; btn.BackgroundColor3=C.off
        task.delay(1.8,function() btn.Text="🗑  Reset Config"; btn.BackgroundColor3=Color3.fromRGB(50,8,20) end)
        playSound("rbxassetid://6895079813",0.5,0.8)
    end)
    createSectionHeader("CONFIG","INFO")
    do
        local holder=getTabHolder("CONFIG"); local infoRow=Instance.new("Frame",holder)
        infoRow.Size=UDim2.new(1,0,0,math.floor(60*GS)); infoRow.BackgroundColor3=C.bgRow; infoRow.BorderSizePixel=0; infoRow.LayoutOrder=nextOrder("CONFIG"); rc(infoRow,math.floor(8*GS)); st(infoRow,1.5,C.border,0.6)
        local infoTxt=Instance.new("TextLabel",infoRow); infoTxt.Size=UDim2.new(1,-16,1,0); infoTxt.Position=UDim2.new(0,8,0,0); infoTxt.BackgroundTransparency=1
        infoTxt.Text="FIRE HUB — Press [U] to hide/show\nESP + PROTECTION + SCALE tabs added"
        infoTxt.TextColor3=C.muted; infoTxt.Font=Enum.Font.GothamMedium; infoTxt.TextSize=math.floor(10*GS); infoTxt.TextWrapped=true; infoTxt.TextXAlignment=Enum.TextXAlignment.Left; infoTxt.TextYAlignment=Enum.TextYAlignment.Center
    end

    -- SCALE TAB
    createSectionHeader("SCALE","MAIN MENU SIZE")
    do
        local holder=getTabHolder("SCALE")

        -- Referanslar (sidebar paneller sonradan doldurulacak)
        local panelRefs = {}
        getgenv().HUBDUEL_RegisterScaleRef = function(name,wrapRef,panelRef)
            panelRefs[name] = {wrap=wrapRef, panel=panelRef}
        end

        local function makeScaleRow(labelTxt, defaultW, defaultH, refName)
            local row=Instance.new("Frame",holder); row.Size=UDim2.new(1,0,0,math.floor(48*GS)); row.BackgroundColor3=C.bgRow; row.BorderSizePixel=0; row.LayoutOrder=nextOrder("SCALE"); rc(row,math.floor(8*GS)); st(row,1.5,C.border,0.6)
            local lbl=Instance.new("TextLabel",row); lbl.Size=UDim2.new(0.45,0,0.5,0); lbl.Position=UDim2.new(0,math.floor(10*GS),0,2); lbl.BackgroundTransparency=1; lbl.Text=labelTxt; lbl.TextColor3=C.dim; lbl.Font=Enum.Font.GothamBold; lbl.TextSize=math.floor(9*GS); lbl.TextXAlignment=Enum.TextXAlignment.Left
            local wLbl=Instance.new("TextLabel",row); wLbl.Size=UDim2.new(0,30,0.45,0); wLbl.Position=UDim2.new(0.45,0,0.08,0); wLbl.BackgroundTransparency=1; wLbl.Text="W:"; wLbl.TextColor3=C.muted; wLbl.Font=Enum.Font.GothamBold; wLbl.TextSize=math.floor(9*GS)
            local wBox=Instance.new("TextBox",row); wBox.Size=UDim2.new(0,math.floor(46*GS),0.45,0); wBox.Position=UDim2.new(0.45,22,0.08,0); wBox.BackgroundColor3=C.off; wBox.Text=tostring(defaultW); wBox.TextColor3=C.purpleLight; wBox.Font=Enum.Font.GothamBold; wBox.TextSize=math.floor(10*GS); wBox.ClearTextOnFocus=false; wBox.BorderSizePixel=0; rc(wBox,5); st(wBox,1.5,C.border,0.4)
            local hLbl=Instance.new("TextLabel",row); hLbl.Size=UDim2.new(0,30,0.45,0); hLbl.Position=UDim2.new(0.45,0,0.55,0); hLbl.BackgroundTransparency=1; hLbl.Text="H:"; hLbl.TextColor3=C.muted; hLbl.Font=Enum.Font.GothamBold; hLbl.TextSize=math.floor(9*GS)
            local hBox=Instance.new("TextBox",row); hBox.Size=UDim2.new(0,math.floor(46*GS),0.45,0); hBox.Position=UDim2.new(0.45,22,0.55,0); hBox.BackgroundColor3=C.off; hBox.Text=tostring(defaultH); hBox.TextColor3=C.purpleLight; hBox.Font=Enum.Font.GothamBold; hBox.TextSize=math.floor(10*GS); hBox.ClearTextOnFocus=false; hBox.BorderSizePixel=0; rc(hBox,5); st(hBox,1.5,C.border,0.4)
            local applyBtn=Instance.new("TextButton",row); applyBtn.Size=UDim2.new(0,math.floor(44*GS),0.8,0); applyBtn.Position=UDim2.new(1,-math.floor(52*GS),0.1,0); applyBtn.BackgroundColor3=C.purpleDark; applyBtn.Text="Apply"; applyBtn.TextColor3=C.white; applyBtn.Font=Enum.Font.GothamBold; applyBtn.TextSize=math.floor(9*GS); applyBtn.BorderSizePixel=0; rc(applyBtn,5); st(applyBtn,1.5,C.purple,0.3)
            applyBtn.MouseButton1Click:Connect(function()
                local nw=tonumber(wBox.Text); local nh=tonumber(hBox.Text)
                if not nw or not nh then return end
                nw=math.clamp(math.floor(nw),50,800); nh=math.clamp(math.floor(nh),30,600)
                wBox.Text=tostring(nw); hBox.Text=tostring(nh)
                if refName=="MAIN" then
                    mainWrap.Size=UDim2.new(0,nw+4,0,nh+4); main.Size=UDim2.new(0,nw,0,nh)
                    mainWrap.Position=UDim2.new(0.5,-(nw+4)/2,0.5,-(nh+4)/2)
                else
                    task.spawn(function()
                        task.wait(0.1)
                        local refs=panelRefs[refName]
                        if refs then
                            if refs.wrap then refs.wrap.Size=UDim2.new(0,nw+4,0,nh+4) end
                            if refs.panel then refs.panel.Size=UDim2.new(0,nw,0,nh) end
                        end
                    end)
                end
                TweenService:Create(applyBtn,TweenInfo.new(0.1),{BackgroundColor3=C.purple}):Play()
                task.delay(0.4,function() TweenService:Create(applyBtn,TweenInfo.new(0.1),{BackgroundColor3=C.purpleDark}):Play() end)
                playSound("rbxassetid://6895079813",0.2,1.1)
            end)
        end

        makeScaleRow("Main Menu",370,460,"MAIN")
        makeScaleRow("Float Panel",148,42,"FLOAT")
        makeScaleRow("Drop Panel",148,42,"DROP")
        makeScaleRow("Aimbot Panel",148,42,"AIMBOT")
        makeScaleRow("Auto Play Panel",148,42,"AUTOPLAY")
        makeScaleRow("TP Down Panel",148,42,"TPDOWN")
    end

    onTap(closeBtn,function() main.Visible=false; playSound("rbxassetid://6895079813",0.4,0.9) end)

    -- ============================================================
    -- BANNER
    -- ============================================================
    do
        local BW=math.floor(220*GS); local BH=math.floor(52*GS); local BN_CR=math.floor(14*GS); local baseY=math.floor(22*GS)
        local bannerWrap=Instance.new("Frame",sg); bannerWrap.Name="OXDHUB_BannerWrap"
        bannerWrap.Size=UDim2.new(0,BW+4,0,BH+4); bannerWrap.Position=UDim2.new(0.5,-(BW+4)/2,0,baseY-2)
        bannerWrap.BackgroundColor3=Color3.fromRGB(100,15,160); bannerWrap.BorderSizePixel=0; bannerWrap.ZIndex=48
        local bwCorner=Instance.new("UICorner",bannerWrap); bwCorner.CornerRadius=UDim.new(0,BN_CR+2)
        local bwGrad=Instance.new("UIGradient",bannerWrap)
        bwGrad.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.fromRGB(220,100,255)),ColorSequenceKeypoint.new(0.18,Color3.fromRGB(140,30,210)),ColorSequenceKeypoint.new(0.45,Color3.fromRGB(35,5,75)),ColorSequenceKeypoint.new(0.72,Color3.fromRGB(100,15,160)),ColorSequenceKeypoint.new(1,Color3.fromRGB(220,100,255))}
        local bwAngle=90; local function bwShimmer() bwAngle=(bwAngle+1.0)%360; bwGrad.Rotation=bwAngle; task.delay(1/40,bwShimmer) end; task.delay(0.15,bwShimmer)
        local fireBanner=Instance.new("Frame",bannerWrap); fireBanner.Name="OXDHUB_Banner"
        fireBanner.Size=UDim2.new(0,BW,0,BH); fireBanner.Position=UDim2.new(0,2,0,2); fireBanner.BackgroundColor3=Color3.fromRGB(8,4,18); fireBanner.BorderSizePixel=0; fireBanner.ZIndex=50
        local bannerCorner=Instance.new("UICorner",fireBanner); bannerCorner.CornerRadius=UDim.new(0,BN_CR)
        local bannerGrad=Instance.new("UIGradient",fireBanner); bannerGrad.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.fromRGB(55,8,95)),ColorSequenceKeypoint.new(0.55,Color3.fromRGB(20,4,40)),ColorSequenceKeypoint.new(1,Color3.fromRGB(5,2,12))}; bannerGrad.Rotation=130
        local fireLabel=Instance.new("TextLabel",fireBanner); fireLabel.Size=UDim2.new(1,0,1,0); fireLabel.BackgroundTransparency=1; fireLabel.Text="FIRE HUB"
        fireLabel.TextColor3=Color3.fromRGB(225,140,255); fireLabel.Font=Enum.Font.GothamBlack; fireLabel.TextSize=math.floor(24*GS); fireLabel.TextXAlignment=Enum.TextXAlignment.Center; fireLabel.TextYAlignment=Enum.TextYAlignment.Center; fireLabel.ZIndex=52
        local guiVisible=false; local bannerClick=Instance.new("TextButton",fireBanner); bannerClick.Size=UDim2.new(1,0,1,0); bannerClick.BackgroundTransparency=1; bannerClick.Text=""; bannerClick.ZIndex=60
        onTap(bannerClick,function()
            guiVisible=not guiVisible; main.Visible=guiVisible
            TweenService:Create(fireBanner,TweenInfo.new(0.08),{BackgroundTransparency=0.3}):Play()
            task.delay(0.12,function() TweenService:Create(fireBanner,TweenInfo.new(0.14),{BackgroundTransparency=0}):Play() end)
            playSound("rbxassetid://6895079813",0.3,guiVisible and 1.1 or 0.9)
        end)
        local bobUp=true; local function doBob()
            local dy=bobUp and -math.floor(8*GS) or math.floor(8*GS); bobUp=not bobUp
            TweenService:Create(bannerWrap,TweenInfo.new(1.6,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Position=UDim2.new(0.5,-(BW+4)/2,0,baseY-2+dy)}):Play()
            task.delay(1.6,doBob)
        end
        task.delay(0.4,doBob)
        local fpsLabel=Instance.new("TextLabel",sg); fpsLabel.Size=UDim2.new(0,math.floor(90*GS),0,math.floor(24*GS)); fpsLabel.Position=UDim2.new(1,-math.floor(98*GS),1,-math.floor(30*GS))
        fpsLabel.BackgroundColor3=Color3.fromRGB(9,5,18); fpsLabel.BackgroundTransparency=0.25; fpsLabel.Text="FPS: --"; fpsLabel.TextColor3=Color3.fromRGB(200,150,255); fpsLabel.Font=Enum.Font.GothamBold; fpsLabel.TextSize=math.floor(11*GS); fpsLabel.TextXAlignment=Enum.TextXAlignment.Center; fpsLabel.BorderSizePixel=0; fpsLabel.ZIndex=60; rc(fpsLabel,6); st(fpsLabel,1.5,C.border,0.5)
        local msLabel=Instance.new("TextLabel",sg); msLabel.Size=UDim2.new(0,math.floor(90*GS),0,math.floor(24*GS)); msLabel.Position=UDim2.new(0,math.floor(8*GS),1,-math.floor(30*GS))
        msLabel.BackgroundColor3=Color3.fromRGB(9,5,18); msLabel.BackgroundTransparency=0.25; msLabel.Text="MS: --"; msLabel.TextColor3=Color3.fromRGB(200,150,255); msLabel.Font=Enum.Font.GothamBold; msLabel.TextSize=math.floor(11*GS); msLabel.TextXAlignment=Enum.TextXAlignment.Center; msLabel.BorderSizePixel=0; msLabel.ZIndex=60; rc(msLabel,6); st(msLabel,1.5,C.border,0.5)
        local lastFpsTime=tick(); local frameCount=0
        RunService.Heartbeat:Connect(function()
            frameCount+=1; local now=tick()
            if now-lastFpsTime>=0.5 then fpsLabel.Text="FPS: "..math.floor(frameCount/(now-lastFpsTime)+0.5); frameCount=0; lastFpsTime=now end
        end)
        task.spawn(function() while true do task.wait(1); pcall(function() local stats=game:GetService("Stats"); local ms=math.floor(stats.Network.ServerStatsItem["Data Ping"]:GetValue()); msLabel.Text="MS: "..ms end) end end)
    end

    -- AUTO GRAB HUD
    do
        local HUD_W=math.floor(340*GS); local HUD_H=math.floor(70*GS); local HUD_CR=math.floor(10*GS)
        local hudWrap=Instance.new("Frame",sg); hudWrap.Name="OXDHUB_GrabHUDWrap"; hudWrap.Size=UDim2.new(0,HUD_W+4,0,HUD_H+4)
        hudWrap.Position=UDim2.new(0.5,-(HUD_W+4)/2,1,-(HUD_H+4)-math.floor(72*GS)); hudWrap.BackgroundColor3=Color3.fromRGB(100,15,160); hudWrap.BorderSizePixel=0; hudWrap.Active=false; hudWrap.ZIndex=7
        local hudWrapCorner=Instance.new("UICorner",hudWrap); hudWrapCorner.CornerRadius=UDim.new(0,HUD_CR+2)
        local hudWrapGrad=Instance.new("UIGradient",hudWrap)
        hudWrapGrad.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.fromRGB(220,100,255)),ColorSequenceKeypoint.new(0.18,Color3.fromRGB(140,30,210)),ColorSequenceKeypoint.new(0.45,Color3.fromRGB(35,5,75)),ColorSequenceKeypoint.new(0.72,Color3.fromRGB(100,15,160)),ColorSequenceKeypoint.new(1,Color3.fromRGB(220,100,255))}
        local hwAngle=60; local function hwShimmer() hwAngle=(hwAngle+1.5)%360; hudWrapGrad.Rotation=hwAngle; task.delay(1/40,hwShimmer) end; task.delay(0.3,hwShimmer)
        local hudFrame=Instance.new("Frame",hudWrap); hudFrame.Name="OXDHUB_GrabHUD"; hudFrame.Size=UDim2.new(0,HUD_W,0,HUD_H); hudFrame.Position=UDim2.new(0,2,0,2)
        hudFrame.BackgroundColor3=C.bg; hudFrame.BorderSizePixel=0; hudFrame.Active=false; rc(hudFrame,HUD_CR); grad(hudFrame,135,C.purpleDark,C.bg)
        local infoFrame=Instance.new("Frame",hudFrame); infoFrame.Size=UDim2.new(1,-6,0,math.floor(22*GS)); infoFrame.Position=UDim2.new(0,3,0,3); infoFrame.BackgroundTransparency=1
        local rPresets={5,8,10,12,15,18,20,25,30,40,50}; local dPresets={0.5,0.8,1.0,1.2,1.3,1.5,2.0,3.0,5.0}
        local function findPresetIdx(tbl,val) for i,v in ipairs(tbl) do if math.abs(v-val)<0.05 then return i end end return 1 end
        local rIdx=findPresetIdx(rPresets,Values.STEAL_RADIUS); local dIdx=findPresetIdx(dPresets,Values.STEAL_DURATION)
        local rBtn=Instance.new("TextButton",infoFrame); rBtn.Size=UDim2.new(0,math.floor(72*GS),1,0); rBtn.Position=UDim2.new(1,-math.floor(150*GS),0,0)
        rBtn.BackgroundColor3=Color3.fromRGB(30,18,50); rBtn.TextColor3=C.purpleLight; rBtn.Font=Enum.Font.GothamBold; rBtn.TextSize=math.floor(9*GS); rBtn.BorderSizePixel=0; rc(rBtn,4)
        local function updateRText() rBtn.Text="R:"..rPresets[rIdx] end; updateRText()
        rBtn.MouseButton1Click:Connect(function() rIdx=(rIdx%#rPresets)+1; Values.STEAL_RADIUS=rPresets[rIdx]; if SliderSetters.STEAL_RADIUS then SliderSetters.STEAL_RADIUS(rPresets[rIdx]) end; updateRText() end)
        rBtn.MouseButton2Click:Connect(function() rIdx=((rIdx-2)%#rPresets)+1; Values.STEAL_RADIUS=rPresets[rIdx]; if SliderSetters.STEAL_RADIUS then SliderSetters.STEAL_RADIUS(rPresets[rIdx]) end; updateRText() end)
        local dBtn=Instance.new("TextButton",infoFrame); dBtn.Size=UDim2.new(0,math.floor(72*GS),1,0); dBtn.Position=UDim2.new(1,-math.floor(72*GS),0,0)
        dBtn.BackgroundColor3=Color3.fromRGB(30,18,50); dBtn.TextColor3=C.purpleLight; dBtn.Font=Enum.Font.GothamBold; dBtn.TextSize=math.floor(9*GS); dBtn.BorderSizePixel=0; rc(dBtn,4)
        local function updateDText() dBtn.Text="D:"..string.format("%.1f",dPresets[dIdx]) end; updateDText()
        dBtn.MouseButton1Click:Connect(function() dIdx=(dIdx%#dPresets)+1; Values.STEAL_DURATION=dPresets[dIdx]; if SliderSetters.STEAL_DURATION then SliderSetters.STEAL_DURATION(dPresets[dIdx]) end; updateDText() end)
        dBtn.MouseButton2Click:Connect(function() dIdx=((dIdx-2)%#dPresets)+1; Values.STEAL_DURATION=dPresets[dIdx]; if SliderSetters.STEAL_DURATION then SliderSetters.STEAL_DURATION(dPresets[dIdx]) end; updateDText() end)
        local pbTrack2=Instance.new("Frame",hudFrame); pbTrack2.Size=UDim2.new(1,-math.floor(16*GS),0,math.floor(7*GS)); pbTrack2.Position=UDim2.new(0,math.floor(8*GS),1,-math.floor(12*GS))
        pbTrack2.BackgroundColor3=C.off; pbTrack2.BorderSizePixel=0; pbTrack2.ZIndex=2; rc(pbTrack2,4)
        local pbf2=Instance.new("Frame",pbTrack2); pbf2.Size=UDim2.new(0,0,1,0); pbf2.BackgroundColor3=C.purple; pbf2.BorderSizePixel=0; pbf2.ZIndex=3; rc(pbf2,4); grad(pbf2,0,C.purpleLight,C.purple)
        getgenv().HUBDUEL_setProgressBarFill(pbf2); getgenv().HUBDUEL_setProgressLabel(nil)
    end

    -- ============================================================
    -- SIDEBAR PANELS
    -- ============================================================
    do
        local SB_W=math.floor(148*GS); local SB_H=math.floor(42*GS); local SB_X=math.floor(8*GS)
        local SB_GAP=math.floor(8*GS); local SB_Y0=math.floor(160*GS); local CORNER_R=math.floor(10*GS)

        local function makePanel(idx,name)
            local yOff=SB_Y0+(idx-1)*(SB_H+SB_GAP)
            local wrapper=Instance.new("Frame",sg); wrapper.Name="OXDHUB_"..name.."_Wrap"
            wrapper.Size=UDim2.new(0,SB_W+4,0,SB_H+4); wrapper.Position=UDim2.new(0,SB_X-2,0,yOff-2)
            wrapper.BackgroundColor3=Color3.fromRGB(100,15,160); wrapper.BorderSizePixel=0; wrapper.ZIndex=11
            local wrapCorner=Instance.new("UICorner",wrapper); wrapCorner.CornerRadius=UDim.new(0,CORNER_R+2)
            local wrapGrad=Instance.new("UIGradient",wrapper)
            wrapGrad.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.fromRGB(220,100,255)),ColorSequenceKeypoint.new(0.18,Color3.fromRGB(140,30,210)),ColorSequenceKeypoint.new(0.45,Color3.fromRGB(40,5,80)),ColorSequenceKeypoint.new(0.72,Color3.fromRGB(100,15,160)),ColorSequenceKeypoint.new(1,Color3.fromRGB(220,100,255))}
            local shimmerAngle=0; local function shimmerLoop() shimmerAngle=(shimmerAngle+2)%360; wrapGrad.Rotation=shimmerAngle; task.delay(1/40,shimmerLoop) end; task.delay(idx*0.18,shimmerLoop)
            local f=Instance.new("Frame",wrapper); f.Name="OXDHUB_"..name; f.Size=UDim2.new(0,SB_W,0,SB_H); f.Position=UDim2.new(0,2,0,2)
            f.BackgroundColor3=Color3.fromRGB(9,5,18); f.BorderSizePixel=0; f.Active=true; f.ZIndex=12
            local fCorner=Instance.new("UICorner",f); fCorner.CornerRadius=UDim.new(0,CORNER_R)
            local fGrad=Instance.new("UIGradient",f); fGrad.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.fromRGB(38,7,66)),ColorSequenceKeypoint.new(1,Color3.fromRGB(5,2,12))}; fGrad.Rotation=120
            local tapCallbacks={}; local dragging=false; local dragStart=nil; local frameStart=nil; local DRAG_THRESH=8
            local hit=Instance.new("TextButton",f); hit.Size=UDim2.new(1,0,1,0); hit.BackgroundTransparency=1; hit.Text=""; hit.ZIndex=25; hit.Active=true
            hit.InputBegan:Connect(function(inp)
                if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then dragging=true; dragStart=inp.Position; frameStart=wrapper.Position end
            end)
            UserInputService.InputChanged:Connect(function(inp)
                if not dragging then return end
                if inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch then
                    local d=inp.Position-dragStart
                    if d.Magnitude>=DRAG_THRESH then wrapper.Position=UDim2.new(frameStart.X.Scale,frameStart.X.Offset+d.X,frameStart.Y.Scale,frameStart.Y.Offset+d.Y) end
                end
            end)
            UserInputService.InputEnded:Connect(function(inp)
                if not dragging then return end
                if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
                    local moved=dragStart and (inp.Position-dragStart).Magnitude or 999; dragging=false
                    if moved<DRAG_THRESH then for _,cb in ipairs(tapCallbacks) do cb() end end
                end
            end)
            -- Scale tab'a kaydet
            if getgenv().HUBDUEL_RegisterScaleRef then getgenv().HUBDUEL_RegisterScaleRef(name:upper():gsub("PANEL",""),wrapper,f) end
            return f,tapCallbacks,hit,wrapper
        end

        local function makeStatusRow(parent,tapCallbacks,labelTxt,fontSize)
            local dot=Instance.new("Frame",parent); dot.Size=UDim2.new(0,math.floor(10*GS),0,math.floor(10*GS))
            dot.Position=UDim2.new(0,math.floor(12*GS),0.5,-math.floor(5*GS)); dot.BackgroundColor3=Color3.fromRGB(80,80,80); dot.BorderSizePixel=0; dot.ZIndex=14; rc(dot,math.floor(5*GS))
            local lbl=Instance.new("TextLabel",parent); lbl.Size=UDim2.new(1,-math.floor(30*GS),1,0); lbl.Position=UDim2.new(0,math.floor(28*GS),0,0)
            lbl.BackgroundTransparency=1; lbl.Text=labelTxt; lbl.TextColor3=Color3.fromRGB(195,170,215); lbl.Font=Enum.Font.GothamBlack; lbl.TextSize=fontSize or math.floor(13*GS)
            lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.TextYAlignment=Enum.TextYAlignment.Center; lbl.ZIndex=14
            local clickZone=Instance.new("TextButton",parent); clickZone.Size=UDim2.new(1,0,1,0); clickZone.BackgroundTransparency=1; clickZone.Text=""; clickZone.ZIndex=13
            local function setState(on)
                TweenService:Create(dot,TweenInfo.new(0.15),{BackgroundColor3=on and Color3.fromRGB(70,210,70) or Color3.fromRGB(70,70,70)}):Play()
                TweenService:Create(parent,TweenInfo.new(0.15),{BackgroundColor3=on and Color3.fromRGB(10,32,10) or Color3.fromRGB(9,5,18)}):Play()
            end
            return clickZone,setState
        end

        -- 1. FLOAT
        local floatPanel,floatTaps,_,floatWrap=makePanel(1,"FloatPanel")
        local floatClk,floatSetState=makeStatusRow(floatPanel,floatTaps,"FLOAT",math.floor(13*GS))
        floatSetState(Enabled.Float)
        local function doFloatToggle()
            Enabled.Float=not Enabled.Float; floatSetState(Enabled.Float)
            if VisualSetters.Float then VisualSetters.Float(Enabled.Float,true) end
            if Enabled.Float then getgenv().HUBDUEL_startFloat() else getgenv().HUBDUEL_stopFloat() end
            playSound("rbxassetid://6895079813",0.3,Enabled.Float and 1.1 or 0.9)
        end
        floatClk.MouseButton1Click:Connect(doFloatToggle); table.insert(floatTaps,doFloatToggle)
        local origFloatSetter=VisualSetters.Float
        VisualSetters.Float=function(on,skipCB) floatSetState(on); if origFloatSetter then origFloatSetter(on,skipCB) end end

        -- 2. DROP
        local dropPanel,dropTaps,_,dropWrap=makePanel(2,"DropPanel")
        local dropClkBtn,_=makeStatusRow(dropPanel,dropTaps,"DROP",math.floor(13*GS))
        local function doDrop()
            getgenv().HUBDUEL_doDrop(); playSound("rbxassetid://6895079813",0.4,1.1)
            TweenService:Create(dropPanel,TweenInfo.new(0.08),{BackgroundColor3=Color3.fromRGB(50,10,80)}):Play()
            task.delay(0.18,function() TweenService:Create(dropPanel,TweenInfo.new(0.14),{BackgroundColor3=Color3.fromRGB(9,5,18)}):Play() end)
        end
        dropClkBtn.MouseButton1Click:Connect(doDrop); table.insert(dropTaps,doDrop)
        getgenv().HUBDUEL_dropFloatVisible=function(v) end

        -- 3. AIMBOT
        local abPanel,abTaps,_,abWrap=makePanel(3,"AimbotPanel")
        local abClkBtn,abSetState=makeStatusRow(abPanel,abTaps,"AIMBOT",math.floor(13*GS))
        abSetState(abActive)
        local function doAimbotToggle() getgenv().HUBDUEL_abToggle(); abSetState(abActive) end
        abClkBtn.MouseButton1Click:Connect(doAimbotToggle); table.insert(abTaps,doAimbotToggle)
        local oldAbVS=abVisualSetter; abVisualSetter=function(on) if oldAbVS then oldAbVS(on) end; abSetState(on) end

        -- 4. AUTO PLAY (Yeni: önce LEFT/RIGHT seç, sonra başlat + keybind)
        do
            local AP_CLOSED_H=SB_H
            local AP_BTN_H=math.floor(32*GS)
            local AP_GAP=math.floor(6*GS)
            local AP_OPEN_H=AP_CLOSED_H+AP_GAP+AP_BTN_H+math.floor(4*GS)

            local yOff=SB_Y0+(4-1)*(SB_H+SB_GAP)

            local apWrap=Instance.new("Frame",sg); apWrap.Name="OXDHUB_AutoPlayPanel_Wrap"
            apWrap.Size=UDim2.new(0,SB_W+4,0,AP_CLOSED_H+4); apWrap.Position=UDim2.new(0,SB_X-2,0,yOff-2)
            apWrap.BackgroundColor3=Color3.fromRGB(100,15,160); apWrap.BorderSizePixel=0; apWrap.ZIndex=11
            local apWrapCorner=Instance.new("UICorner",apWrap); apWrapCorner.CornerRadius=UDim.new(0,CORNER_R+2)
            local apWrapGrad=Instance.new("UIGradient",apWrap)
            apWrapGrad.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.fromRGB(220,100,255)),ColorSequenceKeypoint.new(0.18,Color3.fromRGB(140,30,210)),ColorSequenceKeypoint.new(0.45,Color3.fromRGB(40,5,80)),ColorSequenceKeypoint.new(0.72,Color3.fromRGB(100,15,160)),ColorSequenceKeypoint.new(1,Color3.fromRGB(220,100,255))}
            local apShimAng=0; local function apShimmer() apShimAng=(apShimAng+2)%360; apWrapGrad.Rotation=apShimAng; task.delay(1/40,apShimmer) end; task.delay(4*0.18,apShimmer)

            local apPanel=Instance.new("Frame",apWrap); apPanel.Name="OXDHUB_AutoPlayPanel"
            apPanel.Size=UDim2.new(0,SB_W,0,AP_CLOSED_H); apPanel.Position=UDim2.new(0,2,0,2)
            apPanel.BackgroundColor3=Color3.fromRGB(9,5,18); apPanel.BorderSizePixel=0; apPanel.Active=true; apPanel.ZIndex=12; apPanel.ClipsDescendants=true
            local apCorner=Instance.new("UICorner",apPanel); apCorner.CornerRadius=UDim.new(0,CORNER_R)
            local apGradF=Instance.new("UIGradient",apPanel); apGradF.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.fromRGB(38,7,66)),ColorSequenceKeypoint.new(1,Color3.fromRGB(5,2,12))}; apGradF.Rotation=120

            -- Durum noktası (sol)
            local apDot=Instance.new("Frame",apPanel); apDot.Size=UDim2.new(0,math.floor(10*GS),0,math.floor(10*GS))
            apDot.Position=UDim2.new(0,math.floor(12*GS),0,math.floor((AP_CLOSED_H-10)/2)); apDot.BackgroundColor3=Color3.fromRGB(70,70,70); apDot.BorderSizePixel=0; apDot.ZIndex=14; rc(apDot,math.floor(5*GS))

            -- "AUTO PLAY" yazısı + seçili rota göstergesi
            local apLbl=Instance.new("TextLabel",apPanel); apLbl.Size=UDim2.new(1,-math.floor(60*GS),0,AP_CLOSED_H); apLbl.Position=UDim2.new(0,math.floor(28*GS),0,0)
            apLbl.BackgroundTransparency=1; apLbl.Text="AUTO PLAY"; apLbl.TextColor3=Color3.fromRGB(195,170,215); apLbl.Font=Enum.Font.GothamBlack; apLbl.TextSize=math.floor(11*GS)
            apLbl.TextXAlignment=Enum.TextXAlignment.Left; apLbl.TextYAlignment=Enum.TextYAlignment.Center; apLbl.ZIndex=14

            -- Route badge (sağ alt küçük yazı)
            local apRouteBadge=Instance.new("TextLabel",apPanel); apRouteBadge.Size=UDim2.new(0,math.floor(36*GS),0,math.floor(14*GS))
            apRouteBadge.Position=UDim2.new(1,-math.floor(38+26*GS),1,-math.floor(16*GS)); apRouteBadge.BackgroundColor3=Color3.fromRGB(40,28,65)
            apRouteBadge.Text="—"; apRouteBadge.TextColor3=Color3.fromRGB(180,100,255); apRouteBadge.Font=Enum.Font.GothamBold; apRouteBadge.TextSize=math.floor(8*GS); apRouteBadge.TextXAlignment=Enum.TextXAlignment.Center; apRouteBadge.BorderSizePixel=0; apRouteBadge.ZIndex=16; rc(apRouteBadge,3)

            -- Ayarlar (⚙) butonu
            local gearSz=math.floor(22*GS)
            local apGear=Instance.new("TextButton",apPanel); apGear.Size=UDim2.new(0,gearSz,0,gearSz); apGear.Position=UDim2.new(1,-math.floor(gearSz+8*GS),0,math.floor((AP_CLOSED_H-gearSz)/2))
            apGear.BackgroundColor3=Color3.fromRGB(40,28,65); apGear.Text="⚙"; apGear.TextColor3=Color3.fromRGB(180,100,255); apGear.Font=Enum.Font.GothamBold; apGear.TextSize=math.floor(13*GS); apGear.BorderSizePixel=0; apGear.ZIndex=18; rc(apGear,math.floor(5*GS))
            local apGearStroke=Instance.new("UIStroke",apGear); apGearStroke.Thickness=1.5; apGearStroke.Color=Color3.fromRGB(100,60,160); apGearStroke.Transparency=0.3; apGearStroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border

            -- Ana tıklama butonu (AUTO PLAY başlatır)
            local apMainBtn=Instance.new("TextButton",apPanel); apMainBtn.Size=UDim2.new(1,-math.floor(gearSz+12*GS),0,AP_CLOSED_H); apMainBtn.Position=UDim2.new(0,0,0,0)
            apMainBtn.BackgroundTransparency=1; apMainBtn.Text=""; apMainBtn.ZIndex=13

            -- Açılır alt kısım: LEFT / RIGHT seçim butonları
            local btnRowY=AP_CLOSED_H+AP_GAP
            local btnW=math.floor((SB_W-3*math.floor(6*GS))/2)

            local leftBtn=Instance.new("TextButton",apPanel); leftBtn.Size=UDim2.new(0,btnW,0,AP_BTN_H); leftBtn.Position=UDim2.new(0,math.floor(6*GS),0,btnRowY)
            leftBtn.BackgroundColor3=Color3.fromRGB(40,28,65); leftBtn.Text="◀  LEFT"; leftBtn.TextColor3=Color3.fromRGB(180,100,255); leftBtn.Font=Enum.Font.GothamBlack; leftBtn.TextSize=math.floor(10*GS); leftBtn.BorderSizePixel=0; leftBtn.ZIndex=16; rc(leftBtn,math.floor(7*GS))
            local lStroke=Instance.new("UIStroke",leftBtn); lStroke.Thickness=1.5; lStroke.Color=Color3.fromRGB(100,60,160); lStroke.Transparency=0.35; lStroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border

            local rightBtn=Instance.new("TextButton",apPanel); rightBtn.Size=UDim2.new(0,btnW,0,AP_BTN_H); rightBtn.Position=UDim2.new(0,math.floor(6*GS)+btnW+math.floor(6*GS),0,btnRowY)
            rightBtn.BackgroundColor3=Color3.fromRGB(40,28,65); rightBtn.Text="RIGHT  ▶"; rightBtn.TextColor3=Color3.fromRGB(180,100,255); rightBtn.Font=Enum.Font.GothamBlack; rightBtn.TextSize=math.floor(10*GS); rightBtn.BorderSizePixel=0; rightBtn.ZIndex=16; rc(rightBtn,math.floor(7*GS))
            local rStroke=Instance.new("UIStroke",rightBtn); rStroke.Thickness=1.5; rStroke.Color=Color3.fromRGB(100,60,160); rStroke.Transparency=0.35; rStroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border

            -- Keybind satırı (⚙ açılınca görünür alt kısımda)
            local kbRowY=btnRowY+AP_BTN_H+math.floor(4*GS)
            local AP_OPEN_H2=AP_OPEN_H+math.floor(28*GS) -- keybind için ekstra yükseklik

            local kbLbl=Instance.new("TextLabel",apPanel); kbLbl.Size=UDim2.new(0.5,0,0,math.floor(22*GS)); kbLbl.Position=UDim2.new(0,math.floor(6*GS),0,kbRowY)
            kbLbl.BackgroundTransparency=1; kbLbl.Text="Keybind:"; kbLbl.TextColor3=Color3.fromRGB(140,110,180); kbLbl.Font=Enum.Font.GothamBold; kbLbl.TextSize=math.floor(9*GS); kbLbl.TextXAlignment=Enum.TextXAlignment.Left; kbLbl.ZIndex=16

            local apKbBadge=Instance.new("TextButton",apPanel); apKbBadge.Size=UDim2.new(0,math.floor(54*GS),0,math.floor(20*GS))
            apKbBadge.Position=UDim2.new(1,-math.floor(60*GS),0,kbRowY+1); apKbBadge.BackgroundColor3=Color3.fromRGB(40,28,65)
            apKbBadge.Text=(KEYBINDS.AUTOPLAY==Enum.KeyCode.Unknown) and "—" or KEYBINDS.AUTOPLAY.Name
            apKbBadge.TextColor3=Color3.fromRGB(180,100,255); apKbBadge.Font=Enum.Font.GothamBold; apKbBadge.TextSize=math.floor(8*GS); apKbBadge.BorderSizePixel=0; apKbBadge.ZIndex=18; rc(apKbBadge,4)
            local kbStroke=Instance.new("UIStroke",apKbBadge); kbStroke.Thickness=1.5; kbStroke.Color=Color3.fromRGB(100,60,160); kbStroke.Transparency=0.3; kbStroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
            KeyBindBtns["AUTOPLAY"]=apKbBadge

            local apKbWaiting=false
            apKbBadge.MouseButton1Click:Connect(function()
                if apKbWaiting then apKbWaiting=false; apKbBadge.Text=(KEYBINDS.AUTOPLAY==Enum.KeyCode.Unknown) and "—" or KEYBINDS.AUTOPLAY.Name; TweenService:Create(apKbBadge,TweenInfo.new(0.12),{BackgroundColor3=Color3.fromRGB(40,28,65)}):Play(); return end
                apKbWaiting=true; apKbBadge.Text="?"; TweenService:Create(apKbBadge,TweenInfo.new(0.12),{BackgroundColor3=Color3.fromRGB(100,60,180)}):Play()
                local conn; conn=UserInputService.InputBegan:Connect(function(inp)
                    if inp.UserInputType~=Enum.UserInputType.Keyboard then return end
                    if inp.KeyCode==Enum.KeyCode.Unknown then return end
                    KEYBINDS.AUTOPLAY=inp.KeyCode; apKbBadge.Text=inp.KeyCode.Name
                    TweenService:Create(apKbBadge,TweenInfo.new(0.12),{BackgroundColor3=Color3.fromRGB(40,28,65)}):Play()
                    apKbWaiting=false; conn:Disconnect()
                end)
            end)
            apKbBadge.MouseButton2Click:Connect(function()
                KEYBINDS.AUTOPLAY=Enum.KeyCode.Unknown; apKbBadge.Text="—"; apKbWaiting=false
                TweenService:Create(apKbBadge,TweenInfo.new(0.12),{BackgroundColor3=Color3.fromRGB(40,28,65)}):Play()
            end)

            -- STATE FUNCTIONS
            local function setApDotState(on)
                TweenService:Create(apDot,TweenInfo.new(0.15),{BackgroundColor3=on and Color3.fromRGB(70,210,70) or Color3.fromRGB(70,70,70)}):Play()
                TweenService:Create(apPanel,TweenInfo.new(0.15),{BackgroundColor3=on and Color3.fromRGB(10,32,10) or Color3.fromRGB(9,5,18)}):Play()
            end

            local function setRouteBtn(route)
                -- LEFT btn
                TweenService:Create(leftBtn,TweenInfo.new(0.15),{
                    BackgroundColor3=route=="left" and Color3.fromRGB(138,43,226) or Color3.fromRGB(40,28,65),
                    TextColor3=route=="left" and Color3.fromRGB(255,255,255) or Color3.fromRGB(180,100,255),
                }):Play()
                -- RIGHT btn
                TweenService:Create(rightBtn,TweenInfo.new(0.15),{
                    BackgroundColor3=route=="right" and Color3.fromRGB(138,43,226) or Color3.fromRGB(40,28,65),
                    TextColor3=route=="right" and Color3.fromRGB(255,255,255) or Color3.fromRGB(180,100,255),
                }):Play()
                -- badge text
                if route=="left" then apRouteBadge.Text="◀ L"
                elseif route=="right" then apRouteBadge.Text="R ▶"
                else apRouteBadge.Text="—" end
            end

            -- Ayarlar açma/kapama
            local apSettingsOpen=false
            apGear.MouseButton1Click:Connect(function()
                apSettingsOpen=not apSettingsOpen
                local targetH=apSettingsOpen and AP_OPEN_H2 or AP_CLOSED_H
                local targetHW=apSettingsOpen and AP_OPEN_H2+4 or AP_CLOSED_H+4
                TweenService:Create(apPanel,TweenInfo.new(0.22,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Size=UDim2.new(0,SB_W,0,targetH)}):Play()
                TweenService:Create(apWrap,TweenInfo.new(0.22,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Size=UDim2.new(0,SB_W+4,0,targetHW)}):Play()
                TweenService:Create(apGear,TweenInfo.new(0.15),{BackgroundColor3=apSettingsOpen and Color3.fromRGB(138,43,226) or Color3.fromRGB(40,28,65),TextColor3=apSettingsOpen and Color3.fromRGB(255,255,255) or Color3.fromRGB(180,100,255)}):Play()
                playSound("rbxassetid://6895079813",0.2,1.1)
            end)

            -- LEFT seç (çalıştırmaz, sadece seçer)
            leftBtn.MouseButton1Click:Connect(function()
                if apSelectedRoute=="left" then
                    apSelectedRoute=nil; setRouteBtn(nil)
                else
                    apSelectedRoute="left"; setRouteBtn("left")
                end
                -- eğer çalışıyorsa durdur
                if apIsRunning then
                    auto1=false; auto2=false; apIsRunning=false; setApDotState(false)
                end
                playSound("rbxassetid://6895079813",0.2,1.1)
            end)

            -- RIGHT seç (çalıştırmaz, sadece seçer)
            rightBtn.MouseButton1Click:Connect(function()
                if apSelectedRoute=="right" then
                    apSelectedRoute=nil; setRouteBtn(nil)
                else
                    apSelectedRoute="right"; setRouteBtn("right")
                end
                if apIsRunning then
                    auto1=false; auto2=false; apIsRunning=false; setApDotState(false)
                end
                playSound("rbxassetid://6895079813",0.2,0.9)
            end)

            -- AUTO PLAY başlat/durdur (ana butona tıklama)
            local function doAutoPlayToggle()
                if not apSelectedRoute then
                    -- Rota seçilmemiş, hafifçe salla
                    TweenService:Create(apPanel,TweenInfo.new(0.06),{Position=UDim2.new(0,2+4,0,2)}):Play()
                    task.delay(0.06,function() TweenService:Create(apPanel,TweenInfo.new(0.06),{Position=UDim2.new(0,2-4,0,2)}):Play() end)
                    task.delay(0.12,function() TweenService:Create(apPanel,TweenInfo.new(0.06),{Position=UDim2.new(0,2,0,2)}):Play() end)
                    return
                end
                if apIsRunning then
                    -- Durdur
                    auto1=false; auto2=false; apIsRunning=false; setApDotState(false)
                    playSound("rbxassetid://6895079813",0.3,0.9)
                else
                    -- Başlat
                    apIsRunning=true; setApDotState(true)
                    playSound("rbxassetid://6895079813",0.3,1.1)
                    task.spawn(function()
                        if apSelectedRoute=="left" then
                            auto1=true
                            local function cond() return auto1 and apIsRunning end
                            local function goTo(pos,spd,c)
                                local r=getgenv().HUBDUEL_hrp2() if not r then return end
                                while c() and (Vector3.new(r.Position.X,0,r.Position.Z)-Vector3.new(pos.X,0,pos.Z)).Magnitude>1 do
                                    local tXZ=Vector3.new(pos.X,0,pos.Z); local cXZ=Vector3.new(r.Position.X,0,r.Position.Z); local dir=(tXZ-cXZ).Unit
                                    r.AssemblyLinearVelocity=Vector3.new(dir.X*spd,r.AssemblyLinearVelocity.Y,dir.Z*spd); task.wait()
                                end
                            end
                            goTo(Vector3.new(-476.48,-6.28,92.73),Values.SpeedNoSteal,cond)
                            goTo(Vector3.new(-483.12,-4.95,94.80),Values.SpeedNoSteal,cond)
                            instaGrab=true; goTo(Vector3.new(-476.48,-6.28,92.73),Values.SpeedStealing,cond); instaGrab=false
                            goTo(Vector3.new(-474.22,-6.96,16.18),Values.SpeedStealing,cond)
                            auto1=false
                        else
                            auto2=true
                            local function cond() return auto2 and apIsRunning end
                            local function goTo(pos,spd,c)
                                local r=getgenv().HUBDUEL_hrp2() if not r then return end
                                while c() and (r.Position-pos).Magnitude>1 do
                                    local dir=(pos-r.Position).Unit; r.AssemblyLinearVelocity=Vector3.new(dir.X*spd,r.AssemblyLinearVelocity.Y,dir.Z*spd); task.wait()
                                end
                            end
                            goTo(Vector3.new(-476.16,-6.52,25.62),Values.SpeedNoSteal,cond)
                            goTo(Vector3.new(-483.04,-5.09,23.14),Values.SpeedNoSteal,cond)
                            instaGrab=true; goTo(Vector3.new(-476.16,-6.52,25.62),Values.SpeedStealing,cond); instaGrab=false
                            goTo(Vector3.new(-474.22,-6.96,105.48),Values.SpeedStealing,cond)
                            auto2=false
                        end
                        apIsRunning=false; setApDotState(false)
                    end)
                end
            end

            apMainBtn.MouseButton1Click:Connect(doAutoPlayToggle)
            getgenv().HUBDUEL_triggerAutoPlay = doAutoPlayToggle

            -- Scale tab kaydı
            if getgenv().HUBDUEL_RegisterScaleRef then getgenv().HUBDUEL_RegisterScaleRef("AUTOPLAY",apWrap,apPanel) end

            -- Sürükleme
            do
                local drag2,ds2,ws2=false,nil,nil
                apMainBtn.InputBegan:Connect(function(inp)
                    if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then drag2=true; ds2=inp.Position; ws2=apWrap.Position end
                end)
                UserInputService.InputChanged:Connect(function(inp)
                    if not drag2 then return end
                    if inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch then
                        local d=inp.Position-ds2
                        if d.Magnitude>=8 then apWrap.Position=UDim2.new(ws2.X.Scale,ws2.X.Offset+d.X,ws2.Y.Scale,ws2.Y.Offset+d.Y) end
                    end
                end)
                UserInputService.InputEnded:Connect(function(inp)
                    if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then drag2=false end
                end)
            end
        end

        -- 5. TP DOWN
        local tpPanel,tpTaps,_,tpWrap=makePanel(5,"TpDownPanel")
        local tpClkBtn,_=makeStatusRow(tpPanel,tpTaps,"TP DOWN",math.floor(13*GS))
        local function doTpDownBtn()
            getgenv().HUBDUEL_doTpDown(); playSound("rbxassetid://6895079813",0.4,0.85)
            TweenService:Create(tpPanel,TweenInfo.new(0.08),{BackgroundColor3=Color3.fromRGB(10,40,80)}):Play()
            task.delay(0.18,function() TweenService:Create(tpPanel,TweenInfo.new(0.14),{BackgroundColor3=Color3.fromRGB(9,5,18)}):Play() end)
        end
        tpClkBtn.MouseButton1Click:Connect(doTpDownBtn); table.insert(tpTaps,doTpDownBtn)
    end

    -- Drag (ana GUI)
    do
        local dragging=false; local dragStart=nil; local wrapStart=nil
        local titleHitbox=Instance.new("TextButton",main); titleHitbox.Size=UDim2.new(1,-math.floor(60*GS),0,TITLE_H)
        titleHitbox.BackgroundTransparency=1; titleHitbox.Text=""; titleHitbox.ZIndex=20; titleHitbox.Active=true
        titleHitbox.InputBegan:Connect(function(inp)
            if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then dragging=true; dragStart=inp.Position; wrapStart=mainWrap.Position end
        end)
        UserInputService.InputChanged:Connect(function(inp)
            if not dragging then return end
            if inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch then
                local d=inp.Position-dragStart; mainWrap.Position=UDim2.new(wrapStart.X.Scale,wrapStart.X.Offset+d.X,wrapStart.Y.Scale,wrapStart.Y.Offset+d.Y)
            end
        end)
        UserInputService.InputEnded:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then dragging=false end end)
    end

    -- Apply loaded config
    task.spawn(function()
        task.wait(2.5)
        local c=Player.Character; if not c or not c:FindFirstChild("HumanoidRootPart") then c=Player.CharacterAdded:Wait(); task.wait(1) end
        switchTab("DUEL")
        for key,setter in pairs(VisualSetters) do setter(Enabled[key] or false,true) end
        for key,setter in pairs(SliderSetters) do if Values[key] then setter(Values[key]) end end
        for k,badgeBtn in pairs(KeyBindBtns) do local kc=KEYBINDS[k]; badgeBtn.Text=(kc==Enum.KeyCode.Unknown) and "—" or kc.Name end
        pcall(function() local cam=workspace.CurrentCamera; if cam and Values.FOV then cam.FieldOfView=Values.FOV end end)
        if Enabled.AntiRagdoll then getgenv().HUBDUEL_startAntiRagdoll() end
        if Enabled.AutoSteal then getgenv().HUBDUEL_startAutoSteal() end
        if Enabled.Optimizer then getgenv().HUBDUEL_enableOptimizer() end
        task.wait(0.3)
        if Enabled.SpeedBoost then getgenv().HUBDUEL_startSpeedBoost() end
        if Enabled.SpinBot then getgenv().HUBDUEL_startSpinBot() end
        if Enabled.SpamBat then getgenv().HUBDUEL_startSpamBat(); getgenv().HUBDUEL_startSpamBatCircle() end
        if Enabled.Galaxy then getgenv().HUBDUEL_startGalaxy() end
        if Enabled.SpeedWhileStealing then getgenv().HUBDUEL_startSpeedWhileStealing() end
        if Enabled.Unwalk then getgenv().HUBDUEL_startUnwalk() end
        if Enabled.Float then getgenv().HUBDUEL_startFloat() end
        if Enabled.FullAutoDuel then getgenv().HUBDUEL_startFullAutoDuel() end
        if Enabled.Aimbot and not abActive then getgenv().HUBDUEL_abToggle() end
        if Enabled.InfJump then infJumpEnabled=true end
        if Enabled.InstaGrab then instaGrab=true end
        if Enabled.HighlightESP or Enabled.BoxESP then getgenv().HUBDUEL_updateESP() end
    end)

    -- Keybind dispatch
    local guiVisible=false
    local function dispatchKey(kc)
        if kc==KEYBINDS.SPIN and KEYBINDS.SPIN~=Enum.KeyCode.Unknown then
            Enabled.SpinBot=not Enabled.SpinBot; if VisualSetters.SpinBot then VisualSetters.SpinBot(Enabled.SpinBot) end
            if Enabled.SpinBot then getgenv().HUBDUEL_startSpinBot() else getgenv().HUBDUEL_stopSpinBot() end
        end
        if kc==KEYBINDS.GALAXY and KEYBINDS.GALAXY~=Enum.KeyCode.Unknown then
            Enabled.Galaxy=not Enabled.Galaxy; if VisualSetters.Galaxy then VisualSetters.Galaxy(Enabled.Galaxy) end
            if Enabled.Galaxy then getgenv().HUBDUEL_startGalaxy() else getgenv().HUBDUEL_stopGalaxy() end
        end
        if kc==KEYBINDS.AUTOLEFT and KEYBINDS.AUTOLEFT~=Enum.KeyCode.Unknown then
            AutoWalkEnabled=not AutoWalkEnabled; Enabled.AutoWalkEnabled=AutoWalkEnabled
            if VisualSetters.AutoWalkEnabled then VisualSetters.AutoWalkEnabled(AutoWalkEnabled) end
            if AutoWalkEnabled then getgenv().HUBDUEL_startAutoWalk() else getgenv().HUBDUEL_stopAutoWalk() end
        end
        if kc==KEYBINDS.AUTORIGHT and KEYBINDS.AUTORIGHT~=Enum.KeyCode.Unknown then
            AutoRightEnabled=not AutoRightEnabled; Enabled.AutoRightEnabled=AutoRightEnabled
            if VisualSetters.AutoRightEnabled then VisualSetters.AutoRightEnabled(AutoRightEnabled) end
            if AutoRightEnabled then getgenv().HUBDUEL_startAutoRight() else getgenv().HUBDUEL_stopAutoRight() end
        end
        if kc==KEYBINDS.ANTIRAGDOLL and KEYBINDS.ANTIRAGDOLL~=Enum.KeyCode.Unknown then
            Enabled.AntiRagdoll=not Enabled.AntiRagdoll; if VisualSetters.AntiRagdoll then VisualSetters.AntiRagdoll(Enabled.AntiRagdoll) end
            if Enabled.AntiRagdoll then getgenv().HUBDUEL_startAntiRagdoll() else getgenv().HUBDUEL_stopAntiRagdoll() end
        end
        if kc==KEYBINDS.AIMBOT and KEYBINDS.AIMBOT~=Enum.KeyCode.Unknown then getgenv().HUBDUEL_abToggle() end
        if kc==KEYBINDS.FLOAT and KEYBINDS.FLOAT~=Enum.KeyCode.Unknown then
            Enabled.Float=not Enabled.Float; if VisualSetters.Float then VisualSetters.Float(Enabled.Float) end
            if Enabled.Float then getgenv().HUBDUEL_startFloat() else getgenv().HUBDUEL_stopFloat() end
        end
        if kc==KEYBINDS.FULLAUTODUEL and KEYBINDS.FULLAUTODUEL~=Enum.KeyCode.Unknown then
            Enabled.FullAutoDuel=not Enabled.FullAutoDuel; if VisualSetters.FullAutoDuel then VisualSetters.FullAutoDuel(Enabled.FullAutoDuel) end
            if Enabled.FullAutoDuel then getgenv().HUBDUEL_startFullAutoDuel() else getgenv().HUBDUEL_stopFullAutoDuel() end
        end
        -- AUTO PLAY keybind: seçili rotayı başlatır/durdurur
        if kc==KEYBINDS.AUTOPLAY and KEYBINDS.AUTOPLAY~=Enum.KeyCode.Unknown then
            if getgenv().HUBDUEL_triggerAutoPlay then getgenv().HUBDUEL_triggerAutoPlay() end
        end
    end

    UserInputService.InputBegan:Connect(function(input,gpe)
        if input.KeyCode==Enum.KeyCode.Space then getgenv().HUBDUEL_spaceHeldSet(true) end
        if waitingForKeybind then
            if input.UserInputType~=Enum.UserInputType.Keyboard then return end
            if input.KeyCode==Enum.KeyCode.Unknown then return end
            local k=input.KeyCode; KEYBINDS[waitingForKeybind]=k
            local badgeBtn=KeyBindBtns[waitingForKeybind]
            if badgeBtn then badgeBtn.Text=k.Name; TweenService:Create(badgeBtn,TweenInfo.new(0.15),{BackgroundColor3=C.badge}):Play() end
            waitingForKeybind=nil; return
        end
        if gpe then return end
        if input.KeyCode==Enum.KeyCode.U then guiVisible=not guiVisible; main.Visible=guiVisible; return end
        if KEYBINDS.DROP~=Enum.KeyCode.Unknown and input.KeyCode==KEYBINDS.DROP then getgenv().HUBDUEL_doDrop() end
        if KEYBINDS.TPDOWN~=Enum.KeyCode.Unknown and input.KeyCode==KEYBINDS.TPDOWN then getgenv().HUBDUEL_doTpDown() end
        dispatchKey(input.KeyCode)
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode==Enum.KeyCode.Space then getgenv().HUBDUEL_spaceHeldSet(false) end
    end)

end -- END BLOCK 4

-- ============================================================
-- CHARACTER RESPAWN
-- ============================================================
Player.CharacterAdded:Connect(function()
    task.wait(1)
    if Enabled.SpinBot then getgenv().HUBDUEL_stopSpinBot(); task.wait(0.1); getgenv().HUBDUEL_startSpinBot() end
    if Enabled.Galaxy  then getgenv().HUBDUEL_setupGalaxyForce(); getgenv().HUBDUEL_adjustGalaxyJump() end
    if Enabled.SpamBat then getgenv().HUBDUEL_stopSpamBat(); task.wait(0.1); getgenv().HUBDUEL_startSpamBat(); getgenv().HUBDUEL_startSpamBatCircle() end
    if Enabled.Unwalk  then getgenv().HUBDUEL_startUnwalk() end
    if Enabled.AutoSteal then getgenv().HUBDUEL_startAutoSteal() end
    if Enabled.Float   then getgenv().HUBDUEL_stopFloat(); task.wait(0.1); getgenv().HUBDUEL_startFloat() end
    task.wait(0.5)
    pcall(function() local cam=workspace.CurrentCamera; if cam and Values.FOV then cam.FieldOfView=Values.FOV end end)
    if Enabled.HighlightESP or Enabled.BoxESP then task.wait(0.5); getgenv().HUBDUEL_updateESP() end
end)

-- FOV GUARD
RunService.RenderStepped:Connect(function()
    local cam=workspace.CurrentCamera
    if cam and cam.FieldOfView~=Values.FOV then cam.FieldOfView=Values.FOV end
end)

print("FIRE HUB Loaded — Press [U] to toggle GUI")

-- ============================================================
-- BLOCK 5: MOVE MODE PANEL
-- ============================================================
do
    local MV={Normal={carry=Values.MV_Normal_carry,steal=Values.MV_Normal_steal},Desync={carry=Values.MV_Desync_carry,steal=Values.MV_Desync_steal},Lagger={carry=Values.MV_Lagger_carry,steal=Values.MV_Lagger_steal}}
    local activeMode=nil; local modeConns={}

    local function stopMode()
        for _,c in pairs(modeConns) do if typeof(c)=="RBXScriptConnection" then c:Disconnect() end end
        modeConns={}; activeMode=nil
    end

    local function startNormal()
        stopMode(); activeMode="Normal"
        modeConns.hb=RunService.Heartbeat:Connect(function()
            local char=Player.Character if not char then return end
            local hrp=char:FindFirstChild("HumanoidRootPart") if not hrp then return end
            local hum=char:FindFirstChildOfClass("Humanoid") if not hum then return end
            local md=hum.MoveDirection; if md.Magnitude>0.1 then
                local spd=Player:GetAttribute("Stealing") and Values.MV_Normal_steal or Values.MV_Normal_carry
                hrp.AssemblyLinearVelocity=Vector3.new(md.X*spd,hrp.AssemblyLinearVelocity.Y,md.Z*spd)
            end
        end)
    end

    local function startDesync()
        stopMode(); activeMode="Desync"
        modeConns.hb=RunService.Heartbeat:Connect(function()
            local char=Player.Character if not char then return end
            local hrp=char:FindFirstChild("HumanoidRootPart") if not hrp then return end
            local hum=char:FindFirstChildOfClass("Humanoid") if not hum then return end
            local md=hum.MoveDirection; if md.Magnitude>0.1 then
                local spd=Player:GetAttribute("Stealing") and Values.MV_Desync_steal or Values.MV_Desync_carry
                hrp.AssemblyLinearVelocity=Vector3.new(md.X*spd,hrp.AssemblyLinearVelocity.Y,md.Z*spd)
            end
        end)
    end

    local function startLagger()
        stopMode(); activeMode="Lagger"
        modeConns.hb=RunService.Heartbeat:Connect(function()
            local char=Player.Character if not char then return end
            local hrp=char:FindFirstChild("HumanoidRootPart") if not hrp then return end
            local hum=char:FindFirstChildOfClass("Humanoid") if not hum then return end
            local md=hum.MoveDirection; if md.Magnitude>0.1 then
                local spd=Player:GetAttribute("Stealing") and Values.MV_Lagger_steal or Values.MV_Lagger_carry
                hrp.AssemblyLinearVelocity=Vector3.new(md.X*spd,hrp.AssemblyLinearVelocity.Y,md.Z*spd)
            end
        end)
        modeConns.lg=RunService.Stepped:Connect(function()
            local char=Player.Character if not char then return end
            local hrp=char:FindFirstChild("HumanoidRootPart") if not hrp then return end
            local v=hrp.AssemblyLinearVelocity
            for _=1,6 do hrp.AssemblyLinearVelocity=Vector3.new(v.X+(math.random()-0.5)*Values.MV_Lagger_carry*0.08,v.Y,v.Z+(math.random()-0.5)*Values.MV_Lagger_carry*0.08) end
            hrp.AssemblyLinearVelocity=v
        end)
    end

    local STARTERS={Normal=startNormal,Desync=startDesync,Lagger=startLagger}
    local isMob5=UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled; local GS5=isMob5 and 0.85 or 1.0

    local D={bg=Color3.fromRGB(8,6,16),row=Color3.fromRGB(18,14,30),purple=Color3.fromRGB(138,43,226),pLight=Color3.fromRGB(180,100,255),pDark=Color3.fromRGB(80,20,140),pDim=Color3.fromRGB(100,60,160),white=Color3.fromRGB(255,255,255),dim=Color3.fromRGB(160,130,200),off=Color3.fromRGB(35,28,55),border=Color3.fromRGB(80,50,120),badge=Color3.fromRGB(40,28,65),grey=Color3.fromRGB(50,45,60),greyTx=Color3.fromRGB(80,70,100)}

    local PW5=math.floor(280*GS5); local TTL5=math.floor(30*GS5); local BTN_H=math.floor(36*GS5); local BOX_H=math.floor(32*GS5); local PAD=math.floor(6*GS5); local CR5=math.floor(9*GS5)
    local CLOSED_H=TTL5+math.floor(2*GS5)+PAD+BTN_H+math.floor(4*GS5); local OPEN_H=CLOSED_H+PAD+BOX_H+PAD+BOX_H+math.floor(6*GS5)

    local function mkC(p,r) local c=Instance.new("UICorner",p); c.CornerRadius=UDim.new(0,r or CR5) end
    local function mkS(p,t,col,tr) local s=Instance.new("UIStroke",p); s.Thickness=t or 2; s.Color=col or D.purple; s.Transparency=tr or 0; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border end
    local function mkG(p,rot,c0,c1) local g=Instance.new("UIGradient",p); g.Rotation=rot; g.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,c0),ColorSequenceKeypoint.new(1,c1)} end

    local sg5=Player.PlayerGui:WaitForChild("OXDHUB_GUI")
    local mWrap=Instance.new("Frame",sg5); mWrap.Name="MOVEMODE_Wrap"; mWrap.Size=UDim2.new(0,PW5+4,0,CLOSED_H+4); mWrap.Position=UDim2.new(1,-(PW5+4+math.floor(8*GS5)),0,math.floor(120*GS5))
    mWrap.BackgroundColor3=Color3.fromRGB(100,15,160); mWrap.BorderSizePixel=0; mWrap.ZIndex=8; mWrap.ClipsDescendants=false; mkC(mWrap,CR5+2)
    local mWG=Instance.new("UIGradient",mWrap); mWG.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.fromRGB(220,100,255)),ColorSequenceKeypoint.new(0.18,Color3.fromRGB(140,30,210)),ColorSequenceKeypoint.new(0.45,Color3.fromRGB(35,5,75)),ColorSequenceKeypoint.new(0.72,Color3.fromRGB(100,15,160)),ColorSequenceKeypoint.new(1,Color3.fromRGB(220,100,255))}
    local mAng=45; local function mShimmer() mAng=(mAng+1.4)%360; mWG.Rotation=mAng; task.delay(1/40,mShimmer) end; task.delay(0.25,mShimmer)

    local mMain=Instance.new("Frame",mWrap); mMain.Size=UDim2.new(0,PW5,0,CLOSED_H); mMain.Position=UDim2.new(0,2,0,2)
    mMain.BackgroundColor3=D.bg; mMain.BackgroundTransparency=0.35; mMain.BorderSizePixel=0; mMain.ClipsDescendants=true; mkC(mMain,CR5)

    local ttl=Instance.new("Frame",mMain); ttl.Size=UDim2.new(1,0,0,TTL5); ttl.BackgroundColor3=D.pDark; ttl.BackgroundTransparency=0.45; ttl.BorderSizePixel=0; mkC(ttl,CR5); mkG(ttl,90,Color3.fromRGB(55,10,95),Color3.fromRGB(12,4,24))
    local gearSz=math.floor(22*GS5)
    local titleGear=Instance.new("TextButton",ttl); titleGear.Size=UDim2.new(0,gearSz,0,gearSz); titleGear.Position=UDim2.new(1,-math.floor(30*GS5),0.5,-gearSz/2)
    titleGear.BackgroundColor3=D.badge; titleGear.Text="⚙"; titleGear.TextColor3=D.pLight; titleGear.Font=Enum.Font.GothamBold; titleGear.TextSize=math.floor(13*GS5); titleGear.BorderSizePixel=0; titleGear.ZIndex=10; mkC(titleGear,math.floor(5*GS5)); mkS(titleGear,1.5,D.pDim,0.3)
    local ttlL=Instance.new("TextLabel",ttl); ttlL.Size=UDim2.new(1,-math.floor(36*GS5),1,0); ttlL.BackgroundTransparency=1; ttlL.Text="⚡  MOVE MODE"; ttlL.TextColor3=D.pLight; ttlL.Font=Enum.Font.GothamBlack; ttlL.TextSize=math.floor(11*GS5); ttlL.TextXAlignment=Enum.TextXAlignment.Center; ttlL.ZIndex=4

    local sep=Instance.new("Frame",mMain); sep.Size=UDim2.new(1,0,0,1); sep.Position=UDim2.new(0,0,0,TTL5); sep.BackgroundColor3=D.purple; sep.BorderSizePixel=0; mkG(sep,0,D.pLight,D.pDark)

    local contentY=TTL5+math.floor(2*GS5)+PAD
    local btnRow=Instance.new("Frame",mMain); btnRow.Size=UDim2.new(1,-PAD*2,0,BTN_H); btnRow.Position=UDim2.new(0,PAD,0,contentY); btnRow.BackgroundTransparency=1; btnRow.BorderSizePixel=0
    local bLayout=Instance.new("UIListLayout",btnRow); bLayout.FillDirection=Enum.FillDirection.Horizontal; bLayout.SortOrder=Enum.SortOrder.LayoutOrder; bLayout.Padding=UDim.new(0,math.floor(4*GS5))

    local MODES_ORDER={"Normal","Desync","Lagger"}; local modeButtons={}; local carryBox,stealBox,carryLbl,stealLbl; local settingsOpen=false

    local function refreshBoxes()
        if not activeMode then carryBox.Text="--"; stealBox.Text="--"; carryBox.TextEditable=false; stealBox.TextEditable=false; carryBox.TextColor3=D.greyTx; stealBox.TextColor3=D.greyTx; carryBox.BackgroundColor3=D.grey; stealBox.BackgroundColor3=D.grey; carryLbl.TextColor3=D.greyTx; stealLbl.TextColor3=D.greyTx; return end
        local carry=Values["MV_"..activeMode.."_carry"]; local steal=Values["MV_"..activeMode.."_steal"]
        MV[activeMode].carry=carry; MV[activeMode].steal=steal; carryBox.Text=tostring(carry); stealBox.Text=tostring(steal)
        carryBox.TextEditable=true; stealBox.TextEditable=true; carryBox.TextColor3=D.pLight; stealBox.TextColor3=D.pLight; carryBox.BackgroundColor3=D.off; stealBox.BackgroundColor3=D.off; carryLbl.TextColor3=D.dim; stealLbl.TextColor3=D.dim
    end

    local function setActiveBtn(name)
        for _,nm in ipairs(MODES_ORDER) do
            local btn=modeButtons[nm]; local isA=(nm==name)
            TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=isA and D.purple or D.badge,TextColor3=isA and D.white or D.pDim}):Play()
        end
    end

    for i,nm in ipairs(MODES_ORDER) do
        local bw=math.floor((PW5-PAD*2-4*2)/3)
        local btn=Instance.new("TextButton",btnRow); btn.Size=UDim2.new(0,bw,1,0); btn.BackgroundColor3=D.badge; btn.Text=nm:upper(); btn.TextColor3=D.pDim
        btn.Font=Enum.Font.GothamBlack; btn.TextSize=math.floor(10*GS5); btn.BorderSizePixel=0; btn.LayoutOrder=i; btn.ZIndex=6; mkC(btn,math.floor(7*GS5)); mkS(btn,1.5,D.pDim,0.35)
        modeButtons[nm]=btn
        btn.MouseButton1Click:Connect(function()
            if activeMode==nm then stopMode(); setActiveBtn(nil); refreshBoxes()
            else STARTERS[nm](); setActiveBtn(nm); refreshBoxes() end
        end)
    end

    contentY=contentY+BTN_H+PAD
    local function makeSpeedRow(yOff,labelTxt,tag)
        local rowF=Instance.new("Frame",mMain); rowF.Size=UDim2.new(1,-PAD*2,0,BOX_H); rowF.Position=UDim2.new(0,PAD,0,yOff); rowF.BackgroundColor3=D.row; rowF.BorderSizePixel=0; mkC(rowF,math.floor(7*GS5)); mkS(rowF,1.5,D.border,0.55)
        local strip=Instance.new("Frame",rowF); strip.Size=UDim2.new(0,3,0,BOX_H-8); strip.Position=UDim2.new(0,0,0.5,-(BOX_H-8)/2); strip.BackgroundColor3=D.pDim; strip.BorderSizePixel=0; mkC(strip,2)
        local lbl=Instance.new("TextLabel",rowF); lbl.Size=UDim2.new(0.52,0,1,0); lbl.Position=UDim2.new(0,math.floor(11*GS5),0,0); lbl.BackgroundTransparency=1; lbl.Text=labelTxt; lbl.TextColor3=D.greyTx; lbl.Font=Enum.Font.GothamMedium; lbl.TextSize=math.floor(10*GS5); lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.ZIndex=2
        local box=Instance.new("TextBox",rowF); box.Size=UDim2.new(0.38,0,1,-8); box.Position=UDim2.new(0.57,0,0,4); box.BackgroundColor3=D.grey; box.Text="--"; box.TextColor3=D.greyTx; box.Font=Enum.Font.GothamBold; box.TextSize=math.floor(11*GS5); box.ClearTextOnFocus=false; box.TextEditable=false; box.BorderSizePixel=0; box.ZIndex=5; mkC(box,5); mkS(box,1.5,D.border,0.4)
        box.FocusLost:Connect(function()
            if not activeMode then box.Text="--"; return end
            local n=tonumber(box.Text)
            if n then n=math.clamp(math.floor(n),1,9999); MV[activeMode][tag]=n; box.Text=tostring(n); local vKey="MV_"..activeMode.."_"..tag; if Values[vKey]~=nil then Values[vKey]=n end
            else box.Text=tostring(MV[activeMode][tag]) end
        end)
        return lbl,box
    end

    carryLbl,carryBox=makeSpeedRow(contentY,"Carry Speed","carry")
    stealLbl,stealBox=makeSpeedRow(contentY+BOX_H+PAD,"Steal Speed","steal")
    refreshBoxes()

    titleGear.MouseButton1Click:Connect(function()
        settingsOpen=not settingsOpen
        local targetH=settingsOpen and OPEN_H or CLOSED_H; local targetHW=settingsOpen and OPEN_H+4 or CLOSED_H+4
        TweenService:Create(mMain,TweenInfo.new(0.22,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Size=UDim2.new(0,PW5,0,targetH)}):Play()
        TweenService:Create(mWrap,TweenInfo.new(0.22,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Size=UDim2.new(0,PW5+4,0,targetHW)}):Play()
        TweenService:Create(titleGear,TweenInfo.new(0.15),{BackgroundColor3=settingsOpen and D.purple or D.badge,TextColor3=settingsOpen and D.white or D.pLight}):Play()
        if settingsOpen then refreshBoxes() end
    end)

    do
        local drag,ds,ws=false,nil,nil
        local dh=Instance.new("TextButton",ttl); dh.Size=UDim2.new(1,-math.floor(40*GS5),1,0); dh.BackgroundTransparency=1; dh.Text=""; dh.ZIndex=20
        dh.InputBegan:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then drag=true; ds=inp.Position; ws=mWrap.Position end end)
        UserInputService.InputChanged:Connect(function(inp)
            if not drag then return end
            if inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch then local d=inp.Position-ds; mWrap.Position=UDim2.new(ws.X.Scale,ws.X.Offset+d.X,ws.Y.Scale,ws.Y.Offset+d.Y) end
        end)
        UserInputService.InputEnded:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then drag=false end end)
    end

    print("MOVE MODE GUI Loaded")
end -- END BLOCK 5