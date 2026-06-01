-- Script Name: QuantumX Hub - Semi-potato V3 (Ultimate Auto-Run)
-- Created by: JamesZZS222
-- Version: 3.0.0
-- Target: Roblox Luau Engine (Ultimate Performance Core)

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

-- ปดล็อกขีดจำกัดเฟรมเรตสูงสุด
setfpscap(999)

-- =============================================================================
-- [SECTION 2: CONFIGURATION & MEMORY CACHE]
-- =============================================================================
local config = {
	ui = {
		size = UDim2.new(0, 100, 0, 25),
		startPos = UDim2.new(0, 10, 0, 10), -- ตำแหน่งมุมบนซ้ายตามต้องการ
		bgColor = Color3.fromRGB(15, 15, 15),
		bgTrans = 0.5, -- กรอบจางๆ โปร่งแสง 50%
		strokeColor = Color3.fromRGB(255, 255, 255),
		strokeTrans = 0.7,
		cornerRadius = 4
	},
	booster = {
		targetMaterial = Enum.Material.SmoothPlastic,
		maxDistance = 75, -- ระยะการมองเห็นโหมด Super Potato (ไกลกว่านี้ซ่อน)
		garbageInterval = 15 -- ลูปเคลียร์ขยะทุกๆ 15 วินาที
	}
}

local state = {
	currentFps = 0
}

local cache = {
	connections = {} -- เก็บ Event ป้องกัน Memory Leak
}

-- =============================================================================
-- [SECTION 3: LIGHTWEIGHT COUNTER UI GENERATOR]
-- =============================================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "QuantumX_FPS_Counter"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local mainFrame = Instance.new("Frame")
mainFrame.Name = "CounterFrame"
mainFrame.Size = config.ui.size
mainFrame.Position = config.ui.startPos
mainFrame.BackgroundColor3 = config.ui.bgColor
mainFrame.BackgroundTransparency = config.ui.bgTrans
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, config.ui.cornerRadius)
uiCorner.Parent = mainFrame

local uiStroke = Instance.new("UIStroke")
uiStroke.Color = config.ui.strokeColor
uiStroke.Thickness = 1
uiStroke.Transparency = config.ui.strokeTrans
uiStroke.Parent = mainFrame

local statsLabel = Instance.new("TextLabel")
statsLabel.Name = "StatsLabel"
statsLabel.Size = UDim2.new(1, 0, 1, 0)
statsLabel.BackgroundTransparency = 1
statsLabel.Text = "FPS: --"
statsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statsLabel.TextSize = 11
statsLabel.Font = Enum.Font.Code
statsLabel.Parent = mainFrame

screenGui.Parent = playerGui

-- =============================================================================
-- [SECTION 4: INTENSIVE PERFORMANCE ENGINES (ALL-IN-ONE PURGE)]
-- =============================================================================

-- 4.1 ลบเอฟเฟกต์แสง, บรรยากาศ, หมอก และหญ้า (No Grass / Leaves / Anti-Fog / Potato Skybox)
local function PurgeEnvironment()
	Lighting.GlobalShadows = false
	Lighting.EnvironmentDiffuseScale = 0
	Lighting.EnvironmentSpecularScale = 0
	Lighting.FogEnd = 150 -- บีบระยะหมอกให้แคบลงเพื่อลดการเรนเดอร์ฉากหลัง
	Lighting.FogColor = Color3.fromRGB(30, 30, 30)
	
	if Terrain then
		Terrain.Decoration = false -- ปิดหญ้า 3D (No Grass)
	end

	-- ลบเอฟเฟกต์หน้าจอทั้งหมด (Bloom, Blur, DoF, SunRays, ColorCorrection)
	-- และลบชั้นบรรยากาศ (Atmosphere / Clouds)
	for _, v in pairs(Lighting:GetDescendants()) do
		if v:IsA("PostEffect") or v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("Atmosphere") or v:IsA("Clouds") then
			v:Destroy()
		end
	end

	-- เปลี่ยนท้องฟ้าเป็น Potato Skybox (สีพื้นเรียบจางๆ ไม่โหลดภาพท้องฟ้าให้หนักการ์ดจอ)
	local currentSky = Lighting:FindFirstChildOfClass("Sky")
	if currentSky then currentSky:Destroy() end
	local customSky = Instance.new("Sky")
	customSky.SkyboxBk, customSky.SkyboxDn, customSky.SkyboxFt = "rbxassetid://0", "rbxassetid://0", "rbxassetid://0"
	customSky.SkyboxLf, customSky.SkyboxRt, customSky.SkyboxUp = "rbxassetid://0", "rbxassetid://0", "rbxassetid://0"
	customSky.Parent = Lighting
end

-- 4.2 เอนจิ้นปรับแต่งวัตถุขั้นสูงสุด (Super Potato: พาร์ทเรียบสีเทา, ไร้เงา, ไร้ Decal, ไร้ Particle)
local function OptimizeObject(v)
	if not v or not v.Parent then return end

	-- ⚙️ PHYSICS OPTIMIZATION: วัตถุแต่งฉากที่อยู่ไกลตัว จะสั่งล็อกตำแหน่งและปิดระบบชน เพื่อลดภาระการคำนวณฟิสิกส์
	if v:IsA("BasePart") and not v:IsA("Terrain") and not v:IsAncestorOf(player.Character or workspace) then
		v.Anchored = true
		v.CanCollide = false
	end

	-- 🎨 บังคับเปลี่ยนวัสดุพาร์ทเป็น SmoothPlastic + ลบเงา + บังคับพาร์ททุกชิ้นเป็นสีเทาล้วน ดับแสงเงา
	if v:IsA("BasePart") and not v:IsA("Terrain") then
		v.Material = config.booster.targetMaterial
		v.CastShadow = false
		v.Color = Color3.fromRGB(100, 100, 100)
		
		-- Disable Shadows V2: ปิดเงาจากแหล่งกำเนิดแสงย่อยรอบๆ พาร์ทชิ้นนั้นๆ
		for _, light in pairs(v:GetChildren()) do
			if light:IsA("SurfaceLight") or light:IsA("SpotLight") or light:IsA("PointLight") then
				light.Shadows = false
			end
		end
		
	-- 🖼️ ลบรูปภาพ, โลโก้, ลวดลายกำแพง, รอยเลือด (Decals & Textures) ให้หายไปทั้งหมด
	elseif v:IsA("Decal") or v:IsA("Texture") then
		v.Transparency = 1
		
	-- 🎇 ดับอัตราการเกิดของ Particle, ควัน, ไฟ, เส้นสกิลทั้งหมด (Rate = 0 / Enabled = false)
	elseif v:IsA("ParticleEmitter") or v:IsA("Beam") then
		v.Rate = 0
	elseif v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") then
		v.Enabled = false
	end
end

-- 4.3 ระบบถอดเสื้อผ้าและซ่อนตัวละครคนอื่นชั่วคราวเพื่อลดโหลดการประมวลผล (Character Dress Purge)
local function CleanOtherPlayers()
	for _, otherPlayer in pairs(Players:GetPlayers()) do
		if otherPlayer ~= player and otherPlayer.Character then
			for _, item in pairs(otherPlayer.Character:GetDescendants()) do
				-- ลบเสื้อผ้า กางเกง และชุดแต่งกาย Accessory ที่ทำให้อืดเครื่อง
				if item:IsA("Clothing") or item:IsA("ShirtGraphic") or item:IsA("Pants") or item:IsA("Accessory") then
					item:Destroy()
				-- ซ่อนตัวละครคนอื่นให้โปร่งใสทั้งหมด ลบการเรนเดอร์โมเดลผู้เล่นคนอื่น
				elseif item:IsA("BasePart") then
					item.Transparency = 1
					item.CastShadow = false
				end
			end
		end
	end
end

-- 4.4 ระบบสตรีมมิ่งระยะห่างสายตา (Local Distance Streaming Engine)
local function StartDistanceStreaming()
	local streamConnection = RunService.Heartbeat:Connect(function()
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not root then return end
		
		for _, part in pairs(workspace:GetDescendants()) do
			if part:IsA("BasePart") and not part:IsA("Terrain") and not part:IsAncestorOf(char) then
				local distance = (part.Position - root.Position).Magnitude
				-- ถ้าวัตถุอยู่ห่างเกินระยะที่กำหนดใน config ให้ซ่อนทันที
				if distance > config.booster.maxDistance then
					part.LocalTransparencyModifier = 1
				else
					part.LocalTransparencyModifier = 0
				end
			end
		end
	end)
	table.insert(cache.connections, streamConnection)
end

-- 4.5 ลูปเบื้องหลังสแกนล้างเศษชิ้นส่วนขยะ, รอยกระสุน, ขยะตกค้างจากสกิล (Automated Debris Clean Loop)
local function StartGarbageCollector()
	task.spawn(function()
		while true do
			task.wait(config.booster.garbageInterval)
			for _, v in pairs(workspace:GetDescendants()) do
				if v:IsA("Debris") or v.Name == "BulletHole" or v.Name == "BloodSpatter" or v.Name == "EffectPart" then
					v:Destroy()
				end
			end
		end
	end)
end

-- =============================================================================
-- [SECTION 5: SYSTEM EXECUTION & TELEMETRY]
-- =============================================================================

-- สั่งให้เอนจิ้นลดกราฟิกทำงานทันทีที่รันสคริปต์ (Instant Auto-Run)
PurgeEnvironment()

local descendants = workspace:GetDescendants()
for i = 1, #descendants do
	OptimizeObject(descendants[i])
end

CleanOtherPlayers()
StartDistanceStreaming()
StartGarbageCollector()

-- Listener สำหรับดักจับและทำลายกราฟิกของวัตถุใหม่ๆ ที่เสกขึ้นมาระหว่างเล่นเกม (เช่น พาร์ทสกิล)
workspace.DescendantAdded:Connect(function(v)
	task.defer(function()
		OptimizeObject(v)
	end)
end)

-- บังคับกราฟิกตัวเกมให้อยู่ในระดับต่ำสุด (Level 1)
settings().Rendering.QualityLevel = Enum.QualityLevel.Level1

-- เชื่อมต่อตัวนับ FPS สดๆ บนหน้าจอ
RunService.Heartbeat:Connect(function(deltaTime)
	state.currentFps = math.round(1 / deltaTime)
end)

task.spawn(function()
	while true do
		statsLabel.Text = string.format("FPS: %d", state.currentFps)
		task.wait(1)
	end
end)

print("[QuantumX Hub V3] All Graphics Purged Successfully. Running Ultra-Smooth Mode!")
