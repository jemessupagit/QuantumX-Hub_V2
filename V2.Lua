-- Script Name: Semi-potato graphic V2.5
-- Created by: JamesZZS222
-- Version: 2.5.0
-- Target: Roblox Luau Engine (Advanced Mobile & PC Performance Core)

-- =============================================================================
-- [SECTION 1: CORE SERVICES & VARIABLES]
-- =============================================================================
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local workspace = game:GetService("Workspace")
local Terrain = workspace:FindFirstChildOfClass("Terrain")

setfpscap(999)

-- =============================================================================
-- [SECTION 2: CONFIGURATION & DATA STORAGE]
-- =============================================================================
local config = {
	ui = {
		size = UDim2.new(0, 160, 0, 155), -- ปรับขนาดกรอบรองรับปุ่ม 3 โหมด + ปุ่มปิด
		startPos = UDim2.new(0.45, 0, 0.3, 0),
		bgColor = Color3.fromRGB(20, 20, 20),
		bgTrans = 0.15,
		strokeColor = Color3.fromRGB(70, 70, 70),
		strokeThickness = 1.2,
		cornerRadius = 6
	},
	colors = {
		default = Color3.fromRGB(45, 45, 45),
		low = Color3.fromRGB(80, 130, 80),
		medium = Color3.fromRGB(140, 110, 50),
		super = Color3.fromRGB(160, 50, 50),
		text = Color3.fromRGB(255, 255, 255)
	}
}

local state = {
	currentMode = "Default", -- โหมดปัจจุบัน: "Default", "Low", "Medium", "Super"
	currentFps = 0,
	isDragging = false
}

-- คลังเก็บข้อมูลจำลองสถานะเดิมเพื่อฟื้นฟู (Prevent Memory Leaks)
local cache = {
	materials = {},
	shadows = {},
	transparencies = {},
	particleRates = {},
	particleEnabled = {},
	lighting = {},
	skybox = nil,
	connections = {}, -- สำหรับเก็บ Event Listeners เพื่อ Disconnect เคลียร์แรม
	streamingObjects = {} -- สำหรับระบบเก็บพาร์ทขยะคำนวณระยะห่าง
}

-- =============================================================================
-- [SECTION 3: INSTANCE GENERATOR FACTORY]
-- =============================================================================
local UIComponentFactory = {}
UIComponentFactory.__index = UIComponentFactory

function UIComponentFactory.new()
	return setmetatable({}, UIComponentFactory)
end

function UIComponentFactory:CreateScreenGui(name)
	local gui = Instance.new("ScreenGui")
	gui.Name = name
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	return gui
end

function UIComponentFactory:CreateMainFrame(parent)
	local frame = Instance.new("Frame")
	frame.Name = "MainFrame"
	frame.Size = config.ui.size
	frame.Position = config.ui.startPos
	frame.BackgroundColor3 = config.ui.bgColor
	frame.BackgroundTransparency = config.ui.bgTrans
	frame.BorderSizePixel = 0
	frame.Active = true
	frame.Parent = parent
	return frame
end

function UIComponentFactory:CreateCorner(radius, parent)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

function UIComponentFactory:CreateStroke(color, thickness, parent)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.Parent = parent
	return stroke
end

function UIComponentFactory:CreateStatsLabel(parent)
	local label = Instance.new("TextLabel")
	label.Name = "StatsLabel"
	label.Size = UDim2.new(1, 0, 0, 25)
	label.Position = UDim2.new(0, 0, 0, 5)
	label.BackgroundTransparency = 1
	label.Text = "FPS: -- | MODE: Default"
	label.TextColor3 = Color3.fromRGB(240, 240, 240)
	label.TextSize = 12
	label.Font = Enum.Font.Code
	label.Parent = parent
	return label
end

function UIComponentFactory:CreateMenuButton(name, text, color, positionY, parent)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.new(0.9, 0, 0, 25)
	button.Position = UDim2.new(0.05, 0, 0, positionY)
	button.BackgroundColor3 = color
	button.Text = text
	button.TextColor3 = config.colors.text
	button.TextSize = 11
	button.Font = Enum.Font.SourceSansBold
	button.Parent = parent
	return button
end

-- =============================================================================
-- [SECTION 4: INTERACTION & DRAG CONTROLLER]
-- =============================================================================
local UIDragController = {}
UIDragController.__index = UIDragController

function UIDragController.init(targetFrame)
	local self = setmetatable({}, UIDragController)
	self.targetFrame = targetFrame
	self.dragInput = nil
	self.dragStart = nil
	self.startPos = nil
	self:ConnectSignals()
	return self
end

function UIDragController:ConnectSignals()
	self.targetFrame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			state.isDragging = true
			self.dragStart = input.Position
			self.startPos = self.targetFrame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then state.isDragging = false end
			end)
		end
	end)
	self.targetFrame.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			self.dragInput = input
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if input == self.dragInput and state.isDragging then
			local delta = input.Position - self.dragStart
			self.targetFrame.Position = UDim2.new(self.startPos.X.Scale, self.startPos.X.Offset + delta.X, self.startPos.Y.Scale, self.startPos.Y.Offset + delta.Y)
		end
	end)
end

-- =============================================================================
-- [SECTION 5: INTENSIVE PERFORMANCE ENGINES]
-- =============================================================================
local PotatoEngine = {}
PotatoEngine.__index = PotatoEngine

function PotatoEngine.new()
	return setmetatable({}, PotatoEngine)
end

-- 5.1 ระบบล้างความจำและตัดการเชื่อมต่อสัญญาณ (Memory & Connection Cleanup)
function PotatoEngine:CleanupConnections()
	for _, connection in pairs(cache.connections) do
		if connection then
			connection:Disconnect()
		end
	end
	table.clear(cache.connections)
	table.clear(cache.streamingObjects)
end

-- 5.2 ระบบบันทึกค่าพื้นฐานของแสงและเอฟเฟกต์ (Lighting Backup Engine)
function PotatoEngine:BackupEnvironment()
	if next(cache.lighting) == nil then
		cache.lighting.GlobalShadows = Lighting.GlobalShadows
		cache.lighting.EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale
		cache.lighting.EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale
		cache.lighting.FogEnd = Lighting.FogEnd
		cache.lighting.FogColor = Lighting.FogColor
		if Terrain then
			cache.lighting.TerrainDecoration = Terrain.Decoration
		end
		local sky = Lighting:FindFirstChildOfClass("Sky")
		if sky then cache.skybox = sky:Clone() end
	end
end

-- 5.3 ระบบตัดเอฟเฟกต์ระดับสูงและหมอกหนา (Post-Effect & Atmosphere Purge)
function PotatoEngine:PurgeEffects(mode)
	for _, v in pairs(Lighting:GetDescendants()) do
		if v:IsA("PostEffect") or v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") then
			v.Enabled = false
		elseif (mode == "Medium" or mode == "Super") and (v:IsA("Atmosphere") or v:IsA("Clouds")) then
			v:Destroy()
		end
	end
end

-- 5.4 ฟังก์ชันหลักในการคัดแยกวัตถุเพื่อปรับแต่ง (Multi-Tier Object Transformer)
function PotatoEngine:ProcessObject(v, mode)
	if not v or not v.Parent then return end

	-- ⚙️ PHYSICS OPTIMIZATION: วัตถุแต่งฉากตกแต่ง ล็อกตำแหน่ง ลดการชนภาระการ์ดจอ
	if v:IsA("BasePart") and not v:IsA("Terrain") and not v:IsAncestorOf(player.Character or workspace) then
		if mode == "Super" then
			v.Anchored = true
			v.CanCollide = false
		end
	end

	-- 🎨 MATERIAL & SHADOW MANAGEMENT
	if v:IsA("BasePart") and not v:IsA("Terrain") then
		if not cache.materials[v] then cache.materials[v] = v.Material end
		if cache.shadows[v] == nil then cache.shadows[v] = v.CastShadow end
		
		if mode == "Low" or mode == "Medium" or mode == "Super" then
			v.Material = Enum.Material.SmoothPlastic
			v.CastShadow = false
		end
		
		-- โหมดสเปกต่ำขีดสุด (Super Potato): บังคับวัตถุเป็นสีเทาล้วน ดับแสงเงา
		if mode == "Super" then
			v.Color = Color3.fromRGB(100, 100, 100)
		end
		
	-- 🖼️ DECAL & TEXTURE PURGE
	elseif v:IsA("Decal") or v:IsA("Texture") then
		if not cache.transparencies[v] then cache.transparencies[v] = v.Transparency end
		if mode == "Medium" or mode == "Super" then
			v.Transparency = 1
		end
		
	-- 🎇 PARTICLE LIMITATION & BEAM RATE
	elseif v:IsA("ParticleEmitter") or v:IsA("Beam") then
		if not cache.particleRates[v] then cache.particleRates[v] = v.Rate end
		if mode == "Low" then
			v.Rate = 3
		elseif mode == "Medium" or mode == "Super" then
			v.Rate = 0
		end
		
	-- 💨 SMOKE, FIRE, TRAIL EXTRACTION
	elseif v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") then
		if cache.particleEnabled[v] == nil then cache.particleEnabled[v] = v.Enabled end
		if mode == "Medium" or mode == "Super" then
			v.Enabled = false
		end
	end
end

-- 5.5 ระบบซ่อนผู้เล่นอื่นและถอดเสื้อผ้าแบบเรียลไทม์ (Character Optimizer)
function PotatoEngine:OptimizeCharacters(mode)
	if mode ~= "Super" then return end
	
	for _, otherPlayer in pairs(Players:GetPlayers()) do
		if otherPlayer ~= player and otherPlayer.Character then
			-- ซ่อน Accessories และเสื้อผ้า ขจัดโมเดลซับซ้อนบนมือถือ
			for _, item in pairs(otherPlayer.Character:GetDescendants()) do
				if item:IsA("Clothing") or item:IsA("ShirtGraphic") or item:IsA("Pants") or item:IsA("Accessory") then
					item:Destroy()
				elseif item:IsA("BasePart") then
					item.Transparency = 1
					item.CastShadow = false
				end
			end
		end
	end
end

-- 5.6 ระบบคำนวณสตรีมมิ่งระยะห่างจำกัดการมองเห็น (Local Distance Streaming Engine)
function PotatoEngine:InitiateStreaming(mode)
	local maxDistance = (mode == "Super" and 75) or (mode == "Medium" and 250) or 99999
	
	if mode == "Medium" or mode == "Super" then
		local streamConnection = RunService.Heartbeat:Connect(function()
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if not root then return end
			
			for _, part in pairs(workspace:GetDescendants()) do
				if part:IsA("BasePart") and not part:IsA("Terrain") and not part:IsAncestorOf(char) then
					local distance = (part.Position - root.Position).Magnitude
					if distance > maxDistance then
						part.LocalTransparencyModifier = 1 -- ซ่อนวัตถุไกลเกินพิกัดสายตา
					else
						part.LocalTransparencyModifier = 0
					end
				end
			end
		end)
		table.insert(cache.connections, streamConnection)
	end
end

-- 5.7 ฟังก์ชันประมวลผลคำสั่งเปลี่ยนสไตล์กะทันหัน (Master Style Switcher)
function PotatoEngine:ApplyPerformanceTier(mode)
	self:CleanupConnections()
	self:BackupEnvironment()
	
	state.currentMode = mode
	
	-- จัดการแสงสว่างและโมเดลสิ่งแวดล้อมฉาก
	Lighting.GlobalShadows = (mode == "Default")
	Lighting.EnvironmentDiffuseScale = (mode == "Default" and cache.lighting.EnvironmentDiffuseScale) or 0
	Lighting.EnvironmentSpecularScale = (mode == "Default" and cache.lighting.EnvironmentSpecularScale) or 0
	
	if mode == "Medium" or mode == "Super" then
		Lighting.FogEnd = 150
		Lighting.FogColor = Color3.fromRGB(30, 30, 30)
		-- Potato Skybox: เปลี่ยนท้องฟ้าเป็นสีพื้นคลาสสิค
		local currentSky = Lighting:FindFirstChildOfClass("Sky")
		if currentSky then currentSky:Destroy() end
		local customSky = Instance.new("Sky")
		customSky.SkyboxBk, customSky.SkyboxDn, customSky.SkyboxFt = "rbxassetid://0", "rbxassetid://0", "rbxassetid://0"
		customSky.SkyboxLf, customSky.SkyboxRt, customSky.SkyboxUp = "rbxassetid://0", "rbxassetid://0", "rbxassetid://0"
		customSky.Parent = Lighting
	else
		Lighting.FogEnd = cache.lighting.FogEnd or 100000
	end
	
	if Terrain then
		Terrain.Decoration = (mode == "Default" and cache.lighting.TerrainDecoration) or false
	end
	
	self:PurgeEffects(mode)
	
	-- สแกนวัตถุประมวลผลโครงสร้างทั่วทั้งพื้นที่เซิร์ฟเวอร์
	local allDescendants = workspace:GetDescendants()
	for i = 1, #allDescendants do
		self:ProcessObject(allDescendants[i], mode)
	end
	
	self:OptimizeCharacters(mode)
	self:InitiateStreaming(mode)
	
	-- เพิ่มสัญญารับฟังก์ชันดักจับไอเทมเสกใหม่ระหว่างเล่นเกม (DescendantAdded Connection)
	local dynamicListener = workspace.DescendantAdded:Connect(function(v)
		task.defer(function()
			self:ProcessObject(v, state.currentMode)
		end)
	end)
	table.insert(cache.connections, dynamicListener)
	
	-- ขัดเกลาการประมวลผลสูงสุดระดับโครงข่าย Roblox
	settings().Rendering.QualityLevel = (mode == "Default" and Enum.QualityLevel.Automatic) or Enum.QualityLevel.Level1
end

-- 5.8 ฟังก์ชันการล้างค่าย้อนกลับสู่จุดเริ่มต้นสากล (Universal Rollback Factory)
function PotatoEngine:RestoreToFactoryDefaults()
	self:CleanupConnections()
	
	-- คืนค่าวัสดุผิววัตถุ
	for part, material in pairs(cache.materials) do
		if part and part.Parent then part.Material = material end
	end
	-- คืนค่าเงาวัตถุ
	for part, shadow in pairs(cache.shadows) do
		if part and part.Parent then part.CastShadow = shadow end
	end
	-- คืนค่าความโปร่งแสงลวดลายรูปภาพ
	for part, trans in pairs(cache.transparencies) do
		if part and part.Parent then part.Transparency = trans end
	end
	-- คืนค่าพาร์ทิเคิลเอฟเฟกต์ตามอัตราเดิม
	for emitter, rate in pairs(cache.particleRates) do
		if emitter and emitter.Parent then emitter.Rate = rate end
	end
	for effect, enabled in pairs(cache.particleEnabled) do
		if effect and effect.Parent then effect.Enabled = enabled end
	end
	
	-- สลัดค่าตัวแปรในคลังจัดเก็บข้อมูลล้าง Memory รั่วไหล
	table.clear(cache.materials)
	table.clear(cache.shadows)
	table.clear(cache.transparencies)
	table.clear(cache.particleRates)
	table.clear(cache.particleEnabled)
	
	-- คืนค่าบรรยากาศสิ่งแวดล้อมดั้งเดิมของ Map
	local currentSky = Lighting:FindFirstChildOfClass("Sky")
	if currentSky then currentSky:Destroy() end
	if cache.skybox then cache.skybox:Clone().Parent = Lighting end
	
	self:RestoreLightingDefaults()
	state.currentMode = "Default"
	settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
end

-- =============================================================================
-- [SECTION 6: TELEMETRY & RUNTIME INITIALIZATION]
-- =============================================================================
local factory = UIComponentFactory.new()
local screenGui = factory:CreateScreenGui("MiniFPSBoosterGUI")
local mainFrame = factory:CreateMainFrame(screenGui)
factory:CreateCorner(config.ui.cornerRadius, mainFrame)
factory:CreateStroke(config.ui.strokeColor, config.ui.strokeThickness, mainFrame)

local statsLabel = factory:CreateStatsLabel(mainFrame)
local btnLow = factory:CreateMenuButton("BtnLow", "LOW PERFORMANCE", config.colors.default, 35, mainFrame)
local btnMed = factory:CreateMenuButton("BtnMed", "MEDIUM POTATO", config.colors.default, 65, mainFrame)
local btnSuper = factory:CreateMenuButton("BtnSuper", "SUPER POTATO", config.colors.default, 95, mainFrame)
local btnReset = factory:CreateMenuButton("BtnReset", "RESET TO DEFAULT", config.booster.disabledColor, 125, mainFrame)

factory:CreateCorner(4, btnLow)
factory:CreateCorner(4, btnMed)
factory:CreateCorner(4, btnSuper)
factory:CreateCorner(4, btnReset)

UIDragController.init(mainFrame)
local engine = PotatoEngine.new()

-- ลูปรันตรวจสอบค่าสถิติเฟรมเรตคอมพิวเตอร์และมือถือแบบต่อเนื่อง
RunService.Heartbeat:Connect(function(deltaTime)
	state.currentFps = math.round(1 / deltaTime)
end)

task.spawn(function()
	while true do
		statsLabel.Text = string.format("FPS: %d | MODE: %s", state.currentFps, state.currentMode)
		task.wait(1)
	end
end)

-- ฟังก์ชันปรับแต่งอนิเมชั่นไฮไลท์สีของปุ่มกดสวิตช์โหมด
local function UpdateButtonVisuals(activeButton)
	btnLow.BackgroundColor3 = config.colors.default
	btnMed.BackgroundColor3 = config.colors.default
	btnSuper.BackgroundColor3 = config.colors.default
	
	if activeButton == btnLow then
		btnLow.BackgroundColor3 = config.colors.low
	elseif activeButton == btnMed then
		btnMed.BackgroundColor3 = config.colors.medium
	elseif activeButton == btnSuper then
		btnSuper.BackgroundColor3 = config.colors.super
	end
end

-- ประกอบพอร์ตการเชื่อมต่อสิทธิเข้าควบคุมปุ่มกดอินเตอร์เฟซใช้งาน
btnLow.MouseButton1Click:Connect(function()
	UpdateButtonVisuals(btnLow)
	engine:ApplyPerformanceTier("Low")
end)

btnMed.MouseButton1Click:Connect(function()
	UpdateButtonVisuals(btnMed)
	engine:ApplyPerformanceTier("Medium")
end)

btnSuper.MouseButton1Click:Connect(function()
	UpdateButtonVisuals(btnSuper)
	engine:ApplyPerformanceTier("Super")
end)

btnReset.MouseButton1Click:Connect(function()
	UpdateButtonVisuals(nil)
	engine:RestoreToFactoryDefaults()
end)

-- ส่งหน้าต่าง GUI แสดงผลลัพธ์สู่สายตาผู้ใช้งานหลัก
screenGui.Parent = playerGui

-- =============================================================================
-- [SECTION 5: INTENSIVE PERFORMANCE ENGINES]
-- =============================================================================
local PotatoEngine = {}
PotatoEngine.__index = PotatoEngine

function PotatoEngine.new()
	return setmetatable({}, PotatoEngine)
end

-- 5.1 ระบบล้างความจำและตัดการเชื่อมต่อสัญญาณ (Memory & Connection Cleanup)
function PotatoEngine:CleanupConnections()
	for _, connection in pairs(cache.connections) do
		if connection then
			connection:Disconnect()
		end
	end
	table.clear(cache.connections)
	table.clear(cache.streamingObjects)
end

-- 5.2 ระบบบันทึกค่าพื้นฐานของแสงและเอฟเฟกต์ (Lighting Backup Engine)
function PotatoEngine:BackupEnvironment()
	if next(cache.lighting) == nil then
		cache.lighting.GlobalShadows = Lighting.GlobalShadows
		cache.lighting.EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale
		cache.lighting.EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale
		cache.lighting.FogEnd = Lighting.FogEnd
		cache.lighting.FogColor = Lighting.FogColor
		if Terrain then
			cache.lighting.TerrainDecoration = Terrain.Decoration
		end
		local sky = Lighting:FindFirstChildOfClass("Sky")
		if sky then cache.skybox = sky:Clone() end
	end
end

-- 5.3 ระบบตัดเอฟเฟกต์ระดับสูงและหมอกหนา (Post-Effect & Atmosphere Purge)
function PotatoEngine:PurgeEffects(mode)
	for _, v in pairs(Lighting:GetDescendants()) do
		if v:IsA("PostEffect") or v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") then
			v.Enabled = false
		elseif (mode == "Medium" or mode == "Super") and (v:IsA("Atmosphere") or v:IsA("Clouds")) then
			v:Destroy()
		end
	end
end

-- 5.4 ฟังก์ชันหลักในการคัดแยกวัตถุเพื่อปรับแต่ง (Multi-Tier Object Transformer)
function PotatoEngine:ProcessObject(v, mode)
	if not v or not v.Parent then return end

	-- ⚙️ PHYSICS OPTIMIZATION: วัตถุแต่งฉากตกแต่ง ล็อกตำแหน่ง ลดการชนภาระการ์ดจอ
	if v:IsA("BasePart") and not v:IsA("Terrain") and not v:IsAncestorOf(player.Character or workspace) then
		if mode == "Super" then
			v.Anchored = true
			v.CanCollide = false
		end
	end

	-- 🎨 MATERIAL & SHADOW MANAGEMENT
	if v:IsA("BasePart") and not v:IsA("Terrain") then
		if not cache.materials[v] then cache.materials[v] = v.Material end
		if cache.shadows[v] == nil then cache.shadows[v] = v.CastShadow end
		
		if mode == "Low" or mode == "Medium" or mode == "Super" then
			v.Material = Enum.Material.SmoothPlastic
			v.CastShadow = false
		end
		
		-- โหมดสเปกต่ำขีดสุด (Super Potato): บังคับวัตถุเป็นสีเทาล้วน ดับแสงเงา
		if mode == "Super" then
			v.Color = Color3.fromRGB(100, 100, 100)
		end
		
	-- 🖼️ DECAL & TEXTURE PURGE
	elseif v:IsA("Decal") or v:IsA("Texture") then
		if not cache.transparencies[v] then cache.transparencies[v] = v.Transparency end
		if mode == "Medium" or mode == "Super" then
			v.Transparency = 1
		end
		
	-- 🎇 PARTICLE LIMITATION & BEAM RATE
	elseif v:IsA("ParticleEmitter") or v:IsA("Beam") then
		if not cache.particleRates[v] then cache.particleRates[v] = v.Rate end
		if mode == "Low" then
			v.Rate = 3
		elseif mode == "Medium" or mode == "Super" then
			v.Rate = 0
		end
		
	-- 💨 SMOKE, FIRE, TRAIL EXTRACTION
	elseif v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") then
		if cache.particleEnabled[v] == nil then cache.particleEnabled[v] = v.Enabled end
		if mode == "Medium" or mode == "Super" then
			v.Enabled = false
		end
	end
end

-- 5.5 ระบบซ่อนผู้เล่นอื่นและถอดเสื้อผ้าแบบเรียลไทม์ (Character Optimizer)
function PotatoEngine:OptimizeCharacters(mode)
	if mode ~= "Super" then return end
	
	for _, otherPlayer in pairs(Players:GetPlayers()) do
		if otherPlayer ~= player and otherPlayer.Character then
			-- ซ่อน Accessories และเสื้อผ้า ขจัดโมเดลซับซ้อนบนมือถือ
			for _, item in pairs(otherPlayer.Character:GetDescendants()) do
				if item:IsA("Clothing") or item:IsA("ShirtGraphic") or item:IsA("Pants") or item:IsA("Accessory") then
					item:Destroy()
				elseif item:IsA("BasePart") then
					item.Transparency = 1
					item.CastShadow = false
				end
			end
		end
	end
end

-- 5.6 ระบบคำนวณสตรีมมิ่งระยะห่างจำกัดการมองเห็น (Local Distance Streaming Engine)
function PotatoEngine:InitiateStreaming(mode)
	local maxDistance = (mode == "Super" and 75) or (mode == "Medium" and 250) or 99999
	
	if mode == "Medium" or mode == "Super" then
		local streamConnection = RunService.Heartbeat:Connect(function()
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if not root then return end
			
			for _, part in pairs(workspace:GetDescendants()) do
				if part:IsA("BasePart") and not part:IsA("Terrain") and not part:IsAncestorOf(char) then
					local distance = (part.Position - root.Position).Magnitude
					if distance > maxDistance then
						part.LocalTransparencyModifier = 1 -- ซ่อนวัตถุไกลเกินพิกัดสายตา
					else
						part.LocalTransparencyModifier = 0
					end
				end
			end
		end)
		table.insert(cache.connections, streamConnection)
	end
end

-- 5.7 ฟังก์ชันประมวลผลคำสั่งเปลี่ยนสไตล์กะทันหัน (Master Style Switcher)
function PotatoEngine:ApplyPerformanceTier(mode)
	self:CleanupConnections()
	self:BackupEnvironment()
	
	state.currentMode = mode
	
	-- จัดการแสงสว่างและโมเดลสิ่งแวดล้อมฉาก
	Lighting.GlobalShadows = (mode == "Default")
	Lighting.EnvironmentDiffuseScale = (mode == "Default" and cache.lighting.EnvironmentDiffuseScale) or 0
	Lighting.EnvironmentSpecularScale = (mode == "Default" and cache.lighting.EnvironmentSpecularScale) or 0
	
	if mode == "Medium" or mode == "Super" then
		Lighting.FogEnd = 150
		Lighting.FogColor = Color3.fromRGB(30, 30, 30)
		-- Potato Skybox: เปลี่ยนท้องฟ้าเป็นสีพื้นคลาสสิค
		local currentSky = Lighting:FindFirstChildOfClass("Sky")
		if currentSky then currentSky:Destroy() end
		local customSky = Instance.new("Sky")
		customSky.SkyboxBk, customSky.SkyboxDn, customSky.SkyboxFt = "rbxassetid://0", "rbxassetid://0", "rbxassetid://0"
		customSky.SkyboxLf, customSky.SkyboxRt, customSky.SkyboxUp = "rbxassetid://0", "rbxassetid://0", "rbxassetid://0"
		customSky.Parent = Lighting
	else
		Lighting.FogEnd = cache.lighting.FogEnd or 100000
	end
	
	if Terrain then
		Terrain.Decoration = (mode == "Default" and cache.lighting.TerrainDecoration) or false
	end
	
	self:PurgeEffects(mode)
	
	-- สแกนวัตถุประมวลผลโครงสร้างทั่วทั้งพื้นที่เซิร์ฟเวอร์
	local allDescendants = workspace:GetDescendants()
	for i = 1, #allDescendants do
		self:ProcessObject(allDescendants[i], mode)
	end
	
	self:OptimizeCharacters(mode)
	self:InitiateStreaming(mode)
	
	-- เพิ่มสัญญารับฟังก์ชันดักจับไอเทมเสกใหม่ระหว่างเล่นเกม (DescendantAdded Connection)
	local dynamicListener = workspace.DescendantAdded:Connect(function(v)
		task.defer(function()
			self:ProcessObject(v, state.currentMode)
		end)
	end)
	table.insert(cache.connections, dynamicListener)
	
	-- ขัดเกลาการประมวลผลสูงสุดระดับโครงข่าย Roblox
	settings().Rendering.QualityLevel = (mode == "Default" and Enum.QualityLevel.Automatic) or Enum.QualityLevel.Level1
end

-- 5.8 ฟังก์ชันการล้างค่าย้อนกลับสู่จุดเริ่มต้นสากล (Universal Rollback Factory)
function PotatoEngine:RestoreToFactoryDefaults()
	self:CleanupConnections()
	
	-- คืนค่าวัสดุผิววัตถุ
	for part, material in pairs(cache.materials) do
		if part and part.Parent then part.Material = material end
	end
	-- คืนค่าเงาวัตถุ
	for part, shadow in pairs(cache.shadows) do
		if part and part.Parent then part.CastShadow = shadow end
	end
	-- คืนค่าความโปร่งแสงลวดลายรูปภาพ
	for part, trans in pairs(cache.transparencies) do
		if part and part.Parent then part.Transparency = trans end
	end
	-- คืนค่าพาร์ทิเคิลเอฟเฟกต์ตามอัตราเดิม
	for emitter, rate in pairs(cache.particleRates) do
		if emitter and emitter.Parent then emitter.Rate = rate end
	end
	for effect, enabled in pairs(cache.particleEnabled) do
		if effect and effect.Parent then effect.Enabled = enabled end
	end
	
	-- สลัดค่าตัวแปรในคลังจัดเก็บข้อมูลล้าง Memory รั่วไหล
	table.clear(cache.materials)
	table.clear(cache.shadows)
	table.clear(cache.transparencies)
	table.clear(cache.particleRates)
	table.clear(cache.particleEnabled)
	
	-- คืนค่าบรรยากาศสิ่งแวดล้อมดั้งเดิมของ Map
	local currentSky = Lighting:FindFirstChildOfClass("Sky")
	if currentSky then currentSky:Destroy() end
	if cache.skybox then cache.skybox:Clone().Parent = Lighting end
	
	self:RestoreLightingDefaults()
	state.currentMode = "Default"
	settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
end

-- =============================================================================
-- [SECTION 6: TELEMETRY & RUNTIME INITIALIZATION]
-- =============================================================================
local factory = UIComponentFactory.new()
local screenGui = factory:CreateScreenGui("MiniFPSBoosterGUI")
local mainFrame = factory:CreateMainFrame(screenGui)
factory:CreateCorner(config.ui.cornerRadius, mainFrame)
factory:CreateStroke(config.ui.strokeColor, config.ui.strokeThickness, mainFrame)

local statsLabel = factory:CreateStatsLabel(mainFrame)
local btnLow = factory:CreateMenuButton("BtnLow", "LOW PERFORMANCE", config.colors.default, 35, mainFrame)
local btnMed = factory:CreateMenuButton("BtnMed", "MEDIUM POTATO", config.colors.default, 65, mainFrame)
local btnSuper = factory:CreateMenuButton("BtnSuper", "SUPER POTATO", config.colors.default, 95, mainFrame)
local btnReset = factory:CreateMenuButton("BtnReset", "RESET TO DEFAULT", config.booster.disabledColor, 125, mainFrame)

factory:CreateCorner(4, btnLow)
factory:CreateCorner(4, btnMed)
factory:CreateCorner(4, btnSuper)
factory:CreateCorner(4, btnReset)

UIDragController.init(mainFrame)
local engine = PotatoEngine.new()

-- ลูปรันตรวจสอบค่าสถิติเฟรมเรตคอมพิวเตอร์และมือถือแบบต่อเนื่อง
RunService.Heartbeat:Connect(function(deltaTime)
	state.currentFps = math.round(1 / deltaTime)
end)

task.spawn(function()
	while true do
		statsLabel.Text = string.format("FPS: %d | MODE: %s", state.currentFps, state.currentMode)
		task.wait(1)
	end
end)

-- ฟังก์ชันปรับแต่งอนิเมชั่นไฮไลท์สีของปุ่มกดสวิตช์โหมด
local function UpdateButtonVisuals(activeButton)
	btnLow.BackgroundColor3 = config.colors.default
	btnMed.BackgroundColor3 = config.colors.default
	btnSuper.BackgroundColor3 = config.colors.default
	
	if activeButton == btnLow then
		btnLow.BackgroundColor3 = config.colors.low
	elseif activeButton == btnMed then
		btnMed.BackgroundColor3 = config.colors.medium
	elseif activeButton == btnSuper then
		btnSuper.BackgroundColor3 = config.colors.super
	end
end

-- ประกอบพอร์ตการเชื่อมต่อสิทธิเข้าควบคุมปุ่มกดอินเตอร์เฟซใช้งาน
btnLow.MouseButton1Click:Connect(function()
	UpdateButtonVisuals(btnLow)
	engine:ApplyPerformanceTier("Low")
end)

btnMed.MouseButton1Click:Connect(function()
	UpdateButtonVisuals(btnMed)
	engine:ApplyPerformanceTier("Medium")
end)

btnSuper.MouseButton1Click:Connect(function()
	UpdateButtonVisuals(btnSuper)
	engine:ApplyPerformanceTier("Super")
end)

btnReset.MouseButton1Click:Connect(function()
	UpdateButtonVisuals(nil)
	engine:RestoreToFactoryDefaults()
end)

-- ส่งหน้าต่าง GUI แสดงผลลัพธ์สู่สายตาผู้ใช้งานหลัก
screenGui.Parent = playerGui

-- =============================================================================
-- [SECTION 9: LIGHTWEIGHT 3D RAYCASTING OPTIMIZATION]
-- =============================================================================
local OcclusionCullingEngine = {}
OcclusionCullingEngine.__index = OcclusionCullingEngine

function OcclusionCullingEngine.new()
	local self = setmetatable({}, OcclusionCullingEngine)
	self.camera = workspace.CurrentCamera
	self.raycastParams = RaycastParams.new()
	self.raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	return self
end

-- 9.1 ฟังก์ชันยิงลำแสงตรวจสอบว่าวัตถุโดนบล็อกบดบังสายตาอยู่หรือไม่
function OcclusionCullingEngine:IsObjectVisible(part)
	local char = player.Character
	if not char or not part then return true end
	
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return true end
	
	-- ตั้งค่าไม่ให้ลำแสงชนตัวเองและตัวละครของผู้เล่น
	self.raycastParams.FilterDescendantsInstances = {char}
	
	local origin = self.camera.CFrame.Position
	local destination = part.Position
	local direction = destination - origin
	
	local raycastResult = workspace:Raycast(origin, direction, self.raycastParams)
	
	-- ถ้าลำแสงชนวัตถุอื่นก่อน แสดงว่าพาร์ทชิ้นนี้โดนบังอยู่ (สามารถซ่อนเพื่อลดโหลดได้)
	if raycastResult and raycastResult.Instance ~= part and not raycastResult.Instance:IsDescendantOf(char) then
		if raycastResult.Instance.Transparency < 0.5 and raycastResult.Instance.CanCollide then
			return false
		end
	end
	return true
end

-- 9.2 ระบบควบคุมการทำงานลูป Raycasting เพื่อสลับปิดเปิดตามสเปกเครื่อง
function OcclusionCullingEngine:StartOcclusionLoop()
	local occlusionConnection = RunService.Heartbeat:Connect(function()
		if state.currentMode == "Super" then
			local char = player.Character
			if not char then return end
			
			for _, v in pairs(workspace:GetDescendants()) do
				if v:IsA("BasePart") and not v:IsA("Terrain") and not v:IsAncestorOf(char) and v.LocalTransparencyModifier == 0 then
					if not self:IsObjectVisible(v) then
						v.LocalTransparencyModifier = 1 -- ซ่อนวัตถุที่ผู้เล่นมองไม่เห็นแน่ๆ
					end
				end
			end
		end
	end)
	table.insert(cache.connections, occlusionConnection)
end

-- =============================================================================
-- [SECTION 10: USER CONFIGURATION PROFILES & THEME SWITCHER]
-- =============================================================================
local UIThemeManager = {}
UIThemeManager.__index = UIThemeManager

function UIThemeManager.new(mainFrame, stroke, label)
	local self = setmetatable({}, UIThemeManager)
	self.mainFrame = mainFrame
	self.stroke = stroke
	self.label = label
	return self
end

-- 10.1 ฟังก์ชันเปลี่ยนสีอินเตอร์เฟสแบบ Smooth ตามโหมดที่เลือก (Visual Feedback)
function UIThemeManager:ApplyThemeForMode(mode)
	local targetColor = config.ui.bgColor
	local strokeColor = config.ui.strokeColor
	
	if mode == "Low" then
		targetColor = Color3.fromRGB(20, 35, 20)
		strokeColor = config.colors.low
	elseif mode == "Medium" then
		targetColor = Color3.fromRGB(35, 30, 15)
		strokeColor = config.colors.medium
	elseif mode == "Super" then
		targetColor = Color3.fromRGB(40, 15, 15)
		strokeColor = config.colors.super
	end
	
	-- ใช้ TweenService ในการเกลี่ยสีให้ค่อยๆ เปลี่ยนอย่างนุ่มนวล
	TweenService:Create(self.mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = targetColor}):Play()
	TweenService:Create(self.stroke, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Color = strokeColor}):Play()
end

-- =============================================================================
-- [SECTION 11: GRAPHICAL BACKUP REGISTRY]
-- =============================================================================
local BackupRegistry = {}
BackupRegistry.__index = BackupRegistry

-- 11.1 ระบบตรวจสอบความถูกต้องขั้นสูง เพื่อป้องกันปัญหาสคริปต์หลุดเมื่อมีคนลบพาร์ททิ้งระหว่างเกม
function BackupRegistry.VerifyCacheIntegrity()
	for part, _ in pairs(cache.materials) do
		if not part or not part.Parent then
			cache.materials[part] = nil
		end
	end
	for part, _ in pairs(cache.shadows) do
		if not part or not part.Parent then
			cache.shadows[part] = nil
		end
	end
	for part, _ in pairs(cache.transparencies) do
		if not part or not part.Parent then
			cache.transparencies[part] = nil
		end
	end
end

-- =============================================================================
-- [SECTION 12: SECURITY & SYSTEM KEEPALIVE]
-- =============================================================================
-- สร้างเซอร์วิสเสริมและเปิดใช้งานลูป Raycast คัดกรองสายตา
local cullingEngine = OcclusionCullingEngine.new()
cullingEngine:StartOcclusionLoop()

local themeManager = UIThemeManager.new(mainFrame, mainStroke, statsLabel)

-- เชื่อมโยงระบบธีมเข้ากับปุ่มกดเดิมในสคริปต์
btnLow.MouseButton1Click:Connect(function()
	themeManager:ApplyThemeForMode("Low")
end)

btnMed.MouseButton1Click:Connect(function()
	themeManager:ApplyThemeForMode("Medium")
end)

btnSuper.MouseButton1Click:Connect(function()
	themeManager:ApplyThemeForMode("Super")
end)

btnReset.MouseButton1Click:Connect(function()
	themeManager:ApplyThemeForMode("Default")
	BackupRegistry.VerifyCacheIntegrity()
end)

-- ลูปตรวจสอบความปลอดภัยของความจำเบื้องหลัง (Run ทุกๆ 30 วินาที)
task.spawn(function()
	while true do
		task.wait(30)
		BackupRegistry.VerifyCacheIntegrity()
	end
end)
