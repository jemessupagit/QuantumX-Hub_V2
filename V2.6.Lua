-- Script Name: QuantumX Hub - Semi-potato V2.6 (Ultra-Lightweight Auto-Run)
-- Created by: JamesZZS222
-- Version: 2.6.0 Bug fixes
-- Target: Roblox Luau Engine (High-Performance & Low-Budget Mobile Core)

-- =============================================================================
-- [SECTION 1: CORE SERVICES & VARIABLES]
-- =============================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local workspace = game:GetService("Workspace")
local Terrain = workspace:FindFirstChildOfClass("Terrain")

setfpscap(999)

-- =============================================================================
-- [SECTION 2: CONFIGURATION]
-- =============================================================================
local config = {
	ui = {
		size = UDim2.new(0, 85, 0, 22),
		startPos = UDim2.new(0, 15, 0, 15), -- มุมบนซ้าย
		bgColor = Color3.fromRGB(10, 10, 10),
		bgTrans = 0.5, -- กรอบจางโปร่งแสง
		strokeColor = Color3.fromRGB(255, 255, 255),
		strokeTrans = 0.75
	},
	booster = {
		targetMaterial = Enum.Material.SmoothPlastic,
		maxDistance = 80, -- ระยะตรวจสอบการมองเห็นวัตถุ
		garbageInterval = 20 -- ขยายเวลาลูปเคลียร์ขยะเป็น 20 วินาทีเพื่อลดโหลด CPU
	}
}

-- =============================================================================
-- [SECTION 3: OPTIMIZED COUNTER UI (ULTRA-LIGHT)]
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
uiCorner.CornerRadius = UDim.new(0, 4)
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
statsLabel.Text = "FPS: CALC"
statsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statsLabel.TextSize = 11
statsLabel.Font = Enum.Font.Code
statsLabel.Parent = mainFrame

screenGui.Parent = playerGui

-- =============================================================================
-- [SECTION 4: PERFORMANCE ENGINES (BUILT FOR LOW-END PHONES)]
-- =============================================================================

-- 4.1 ลบสเปกสภาพแวดล้อม (No Grass / Leaves / Fog Purge)
local function PurgeEnvironment()
	Lighting.GlobalShadows = false
	Lighting.EnvironmentDiffuseScale = 0
	Lighting.EnvironmentSpecularScale = 0
	Lighting.FogEnd = 200
	Lighting.FogColor = Color3.fromRGB(25, 25, 25)
	
	if Terrain then
		Terrain.Decoration = false
	end

	for _, v in pairs(Lighting:GetDescendants()) do
		if v:IsA("PostEffect") or v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("Atmosphere") or v:IsA("Clouds") then
			v:Destroy()
		end
	end

	local currentSky = Lighting:FindFirstChildOfClass("Sky")
	if currentSky then currentSky:Destroy() end
	local customSky = Instance.new("Sky")
	customSky.SkyboxBk, customSky.SkyboxDn, customSky.SkyboxFt = "rbxassetid://0", "rbxassetid://0", "rbxassetid://0"
	customSky.SkyboxLf, customSky.SkyboxRt, customSky.SkyboxUp = "rbxassetid://0", "rbxassetid://0", "rbxassetid://0"
	customSky.Parent = Lighting
end

-- 4.2 เอนจิ้นปรับแต่งโครงสร้างโมเดลวัตถุ (Super Potato Transformer)
local function OptimizeObject(v)
	if not v or not v.Parent then return end

	-- Physics Optimization: ล็อกชิ้นส่วนฉากลดการชน
	if v:IsA("BasePart") and not v:IsA("Terrain") and not v:IsAncestorOf(player.Character or workspace) then
		v.Anchored = true
		v.CanCollide = false
	end

	-- บังคับเปลี่ยนวัสดุพาร์ทผิวเรียบสีเทา + ปิดเงาสะท้อนทุกระดับ
	if v:IsA("BasePart") and not v:IsA("Terrain") then
		v.Material = config.booster.targetMaterial
		v.CastShadow = false
		v.Color = Color3.fromRGB(110, 110, 110)
		
		for _, light in pairs(v:GetChildren()) do
			if light:IsA("Light") then -- คลุมคลุมทั้ง Surface, Spot, Point Light
				light.Shadows = false
			end
		end
		
	-- ลบรูปภาพพื้นผิวฉากทั้งหมด
	elseif v:IsA("Decal") or v:IsA("Texture") then
		v.Transparency = 1
		
	-- สั่งปิดพาร์ทิเคิลเอฟเฟกต์ เส้นสกิล และควันไฟ
	elseif v:IsA("ParticleEmitter") or v:IsA("Beam") then
		v.Rate = 0
	elseif v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") then
		v.Enabled = false
	end
end

-- 4.3 ถอดชุดคอสตูมตัวละครผู้เล่นอื่นเพื่อลดภาระการ์ดจอมือถือ
local function CleanOtherPlayers()
	for _, otherPlayer in pairs(Players:GetPlayers()) do
		if otherPlayer ~= player and otherPlayer.Character then
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

-- 4.4 ระบบสตรีมมิ่งซ่อนพาร์ทระยะไกล (สแกนแบบแบ่งเวลาทำเพื่อไม่ให้ CPU ทำงานหนักเกินไป)
local function StartDistanceStreaming()
	task.spawn(function()
		while true do
			task.wait(0.2) -- เปลี่ยนจากการรันทุกเฟรม (Heartbeat) เป็นการตรวจจับทุกๆ 0.2 วินาที ประหยัดการคำนวณลง 10 เท่า!
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			
			if root then
				local rootPosition = root.Position
				local descendants = workspace:GetDescendants()
				
				-- ใช้ลูปความเร็วสูงจำกัดงานประมวลผลต่อรอบ
				for i = 1, #descendants do
					local part = descendants[i]
					if part and part:IsA("BasePart") and not part:IsA("Terrain") and not part:IsAncestorOf(char) then
						local distance = (part.Position - rootPosition).Magnitude
						if distance > config.booster.maxDistance then
							part.LocalTransparencyModifier = 1
						else
							part.LocalTransparencyModifier = 0
						end
					end
				end
			end
		end
	end)
end

-- 4.5 ลูปเก็บกวาดเคลียร์เศษชิ้นส่วนสกิลตกค้างในพื้นที่แมพ
local function StartGarbageCollector()
	task.spawn(function()
		while true do
			task.wait(config.booster.garbageInterval)
			for _, v in pairs(workspace:GetDescendants()) do
				if v and (v:IsA("Debris") or v.Name == "BulletHole" or v.Name == "BloodSpatter" or v.Name == "EffectPart") then
					v:Destroy()
				end
			end
		end
	end)
end

-- =============================================================================
-- [SECTION 5: HIGH-EFFICIENCY EXECUTION & FIX FPS BUG]
-- =============================================================================

-- บังคับระบบเรนเดอร์ระดับต่ำสุด
settings().Rendering.QualityLevel = Enum.QualityLevel.Level1

-- สั่งเริ่มงานทันที
PurgeEnvironment()

local initialDescendants = workspace:GetDescendants()
for i = 1, #initialDescendants do
	OptimizeObject(initialDescendants[i])
end

CleanOtherPlayers()
StartDistanceStreaming()
StartGarbageCollector()

-- ตัวดักจับวัตถุใหม่ที่ถูกสร้างขึ้นในเซิร์ฟเวอร์
workspace.DescendantAdded:Connect(function(v)
	task.defer(function()
		OptimizeObject(v)
	end)
end)

-- 🛠️ FIXED FPS NIL BUG: ระบบนับตัวเลข FPS น้ำหนักเบา ไร้บัค ไร้อาการเครื่องอืด
local fpsBuffer = 0

RunService.RenderStepped:Connect(function()
	fpsBuffer = fpsBuffer + 1
end)

task.spawn(function()
	while true do
		task.wait(1)
		-- ป้องกันบัคค่าว่าง และล็อกการแสดงผลให้เที่ยงตรง
		local displayFps = fpsBuffer
		if displayFps == 0 or not displayFps then
			statsLabel.Text = "FPS: รอข้อมูล"
		else
			statsLabel.Text = string.format("FPS: %d", displayFps)
		end
		fpsBuffer = 0 -- รีเซ็ตค่าเพื่อเริ่มนับวินาทีถัดไป
	end
end)

print("[QuantumX Hub V2.6] Optimization Engine Engaged (Ultra-Light Build).")
