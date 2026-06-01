-- Script Name: QuantumX Hub - Semi-potato V2.6.1 (Fixed & Power Saver)
-- Created by: JamesZZS222 (Optimized for Mobile)
-- Version: 2.6.1 Bug Fixes & Battery Saver
-- Target: Roblox Luau Engine (Arceus X Neo Fully Compatible)

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

-- สถานะการทำงานของ Booster (เปิดใช้งานตั้งแต่เริ่มต้น)
local boosterActive = true

-- =============================================================================
-- [SECTION 2: CONFIGURATION]
-- =============================================================================
local config = {
	ui = {
		size = UDim2.new(0, 160, 0, 26), -- ขยายขนาดเล็กน้อยเพื่อรองรับข้อความปุ่ม
		startPos = UDim2.new(0, 15, 0, 15),
		bgColor = Color3.fromRGB(10, 10, 10),
		bgTrans = 0.4,
		strokeColor = Color3.fromRGB(255, 255, 255),
		strokeTrans = 0.7
	},
	booster = {
		targetMaterial = Enum.Material.SmoothPlastic,
		maxDistance = 75, -- ปรับสมดุลลดลงเล็กน้อยเพื่อประหยัดแบตเตอรี่บนมือถือ
		garbageInterval = 20
	}
}

-- เก็บค่าวัสดุดั้งเดิมของวัตถุไว้ (เผื่อใช้ตอนปิด Booster)
local originalMaterials = {}

-- =============================================================================
-- [SECTION 3: OPTIMIZED COUNTER & TOGGLE UI]
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
uiCorner.CornerRadius = UDim.new(0, 6)
uiCorner.Parent = mainFrame

local uiStroke = Instance.new("UIStroke")
uiStroke.Color = config.ui.strokeColor
uiStroke.Thickness = 1
uiStroke.Transparency = config.ui.strokeTrans
uiStroke.Parent = mainFrame

-- ตัวนับ FPS (แก้ไขบัคแสดงผลค้าง)
local statsLabel = Instance.new("TextLabel")
statsLabel.Name = "StatsLabel"
statsLabel.Size = UDim2.new(0, 65, 1, 0)
statsLabel.Position = UDim2.new(0, 5, 0, 0)
statsLabel.BackgroundTransparency = 1
statsLabel.Text = "FPS: รอข้อมูล"
statsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statsLabel.TextSize = 11
statsLabel.Font = Enum.Font.Code
statsLabel.TextXAlignment = Enum.TextXAlignment.Left
statsLabel.Parent = mainFrame

-- ปุ่มกดสลับโหมด BOOSTER (ON / OFF)
local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.Size = UDim2.new(0, 85, 0, 18)
toggleButton.Position = UDim2.new(1, -90, 0.5, -9)
toggleButton.BackgroundColor3 = Color3.fromRGB(0, 180, 90) -- เริ่มต้นสีเขียว (ON)
toggleButton.Text = "BOOSTER: ON"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.TextSize = 10
toggleButton.Font = Enum.Font.CodeBold
toggleButton.Parent = mainFrame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 4)
btnCorner.Parent = toggleButton

screenGui.Parent = playerGui

-- =============================================================================
-- [SECTION 4: PERFORMANCE ENGINES (BATTERY & ARCEUS NEO OPTIMIZED)]
-- =============================================================================

-- 4.1 ลบสเปกสภาพแวดล้อมเพื่อลดความร้อนชิปเซ็ต
local function PurgeEnvironment()
	Lighting.GlobalShadows = false
	Lighting.EnvironmentDiffuseScale = 0
	Lighting.EnvironmentSpecularScale = 0
	Lighting.FogEnd = 250
	
	if Terrain then
		Terrain.Decoration = false
	end

	-- ใช้ task.defer เพื่อไม่ให้ Arceus X ค้างเวลาวนลูปหนักๆ
	task.defer(function()
		for _, v in pairs(Lighting:GetDescendants()) do
			if v:IsA("PostEffect") or v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("Atmosphere") or v:IsA("Clouds") then
				v:Destroy()
			end
		end
	end)
end

-- 4.2 เอนจิ้นปรับแต่งโครงสร้างโมเดลวัตถุ (รองรับการเปิด-ปิด)
local function OptimizeObject(v)
	if not v or not v.Parent then return end

	if boosterActive then
		-- บันทึกค่าวัสดุดั้งเดิมเก็บไว้ก่อนเปลี่ยนเพื่อใช้ตอนปิดสวิตช์
		if v:IsA("BasePart") and not originalMaterials[v] then
			originalMaterials[v] = {Material = v.Material, CastShadow = v.CastShadow}
		end

		-- บังคับเปลี่ยนวัสดุและลบเงา
		if v:IsA("BasePart") and not v:IsA("Terrain") then
			v.Material = config.booster.targetMaterial
			v.CastShadow = false
			
			-- ลดภาระการคำนวณแสงที่ทำให้เครื่องร้อน
			for _, light in pairs(v:GetChildren()) do
				if light:IsA("Light") then 
					light.Shadows = false
				end
			end
		elseif v:IsA("Decal") or v:IsA("Texture") then
			v.Transparency = 1
		elseif v:IsA("ParticleEmitter") or v:IsA("Beam") then
			v.Rate = 0
		elseif v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") then
			v.Enabled = false
		end
	end
end

-- ฟังก์ชันคืนค่ากราฟิกเดิมเมื่อปิด Booster (ช่วยเซฟ RAM และแก้บัควัตถุกระพริบ)
local function RestoreObjects()
	for part, orig in pairs(originalMaterials) do
		if part and part.Parent then
			part.Material = orig.Material
			part.CastShadow = orig.CastShadow
		end
	end
	table.clear(originalMaterials) -- ล้างข้อมูลที่เก็บไว้เพื่อคืน Memory ให้มือถือ
end

-- 4.3 ถอดชุดคอสตูมตัวละครอื่น (เซฟ RAM ได้มหาศาล ป้องกันเกมเด้ง)
local function CleanOtherPlayers()
	if not boosterActive then return end
	task.defer(function()
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
	end)
end

-- 4.4 ระบบสตรีมมิ่งระยะไกลแบบถนอมพลังงาน (สแกนอย่างมีระเบียบ ไม่หน่วง CPU)
local function StartDistanceStreaming()
	task.spawn(function()
		while true do
			task.wait(0.25) -- ขยับขึ้นเป็น 0.25 วินาที เพื่อช่วยลดความร้อนและการกินแบตเตอรี่เพิ่มขึ้น
			if boosterActive then
				local char = player.Character
				local root = char and char:FindFirstChild("HumanoidRootPart")
				
				if root then
					local rootPosition = root.Position
					local descendants = workspace:GetDescendants()
					
					-- แบ่งประมวลผลเป็นรอบ (Batch) ป้องกัน Arceus X เกิด Syntax/Runtime Crash
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
						if i % 100 == 0 then task.wait() end -- พักลูปทุกๆ 100 ชิ้น ป้องกัน CPU ทำงานพีคจนเครื่องร้อน
					end
				end
			end
		end
	end)
end

-- 4.5 ลูปเคลียร์ขยะอัตโนมัติ (Anti-Memory Leak เคลียร์ลื่นๆ ไม่ทำให้ค้าง)
local function StartGarbageCollector()
	task.spawn(function()
		while true do
			task.wait(config.booster.garbageInterval)
			if boosterActive then
				for _, v in pairs(workspace:GetDescendants()) do
					if v and (v:IsA("Debris") or v.Name == "BulletHole" or v.Name == "BloodSpatter" or v.Name == "EffectPart") then
						v:Destroy()
					end
				end
			end
		end
	end)
end

-- =============================================================================
-- [SECTION 5: HIGH-EFFICIENCY EXECUTION & REAL-TIME FPS COUNTER]
-- =============================================================================

-- บังคับระบบเรนเดอร์ระดับต่ำสุดเพื่อประหยัดแบตเตอรี่
settings().Rendering.QualityLevel = Enum.QualityLevel.Level1

PurgeEnvironment()

-- โหลดกราฟิกเริ่มต้นแบบปลอดภัยต่อตัวรันมือถือ
task.defer(function()
	local initialDescendants = workspace:GetDescendants()
	for i = 1, #initialDescendants do
		OptimizeObject(initialDescendants[i])
		if i % 150 == 0 then task.wait() end
	end
end)

CleanOtherPlayers()
StartDistanceStreaming()
StartGarbageCollector()

-- ตัวดักจับวัตถุใหม่ที่ถูกสร้างขึ้น (ใช้ task.defer ป้องกันปัญหา Thread ซ้อนใน Arceus)
workspace.DescendantAdded:Connect(function(v)
	if boosterActive then
		task.defer(function()
			OptimizeObject(v)
		end)
	end
end)

-- 🛠️ FIXED: ระบบนับ FPS ลูปความเร็วสูง การันตีค่าไม่ขึ้นเป็น CALC แน่นอน
local fpsCount = 0

RunService.RenderStepped:Connect(function()
	fpsCount = fpsCount + 1
end)

task.spawn(function()
	while true do
		task.wait(1)
		-- แสดงผลตัวเลขจริงในทุกๆ วินาที และมีระบบดักจับค่าว่าง (Nil Check)
		if fpsCount == 0 or not fpsCount then
			statsLabel.Text = "FPS: คำนวณค่า"
		else
			statsLabel.Text = string.format("FPS: %d", fpsCount)
		end
		fpsCount = 0 -- รีเซ็ตลูปนับใหม่
	end
end)

-- =============================================================================
-- [SECTION 6: BUTTON INTERACTION (BOOSTER SWITCH)]
-- =============================================================================
toggleButton.MouseButton1Click:Connect(function()
	boosterActive = not boosterActive
	
	if boosterActive then
		-- เปิดใช้งานโหมดบูสท์
		toggleButton.Text = "BOOSTER: ON"
		toggleButton.BackgroundColor3 = Color3.fromRGB(0, 180, 90)
		
		-- สั่งปรับกราฟิกใหม่ทันที
		local currentDescendants = workspace:GetDescendants()
		for i = 1, #currentDescendants do
			OptimizeObject(currentDescendants[i])
		end
		CleanOtherPlayers()
	else
		-- ปิดใช้งานโหมดบูสท์ (เข้าสู่โหมดประหยัดพลังงาน คืนค่าเดิม)
		toggleButton.Text = "BOOSTER: OFF"
		toggleButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50) -- เปลี่ยนเป็นสีแดง
		
		RestoreObjects() -- คืนค่าวัตถุฉากเดิมทั้งหมด
	end
end)

print("[QuantumX Hub V2.6.1] Fixed & Battery Optimizations Loaded.")
