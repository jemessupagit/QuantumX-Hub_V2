-- Script Name: QuantumX Hub - Semi-potato V2.6.2 (Total Rewrite)
-- Created by: JamesZZS222
-- Version: 2.6.2 Arceus Neo Certified
-- Target: Roblox Luau Engine (Ultra-Streamlined Mobile Core)

-- =============================================================================
-- [SECTION 1: CORE SERVICES]
-- =============================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local workspace = game:GetService("Workspace")

setfpscap(999)

-- สถานะสวิตช์ (True = เปิดบูสท์กราฟิกกาก / False = ปิดโหมดบูสท์)
local _G.QuantumX_Booster = true

-- =============================================================================
-- [SECTION 2: ULTRA-LIGHT UI (NO COMPLEX STROKES)]
-- =============================================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "QuantumX_Counter"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 150, 0, 26)
mainFrame.Position = UDim2.new(0, 15, 0, 15)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
mainFrame.BackgroundTransparency = 0.4
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 5)
uiCorner.Parent = mainFrame

local statsLabel = Instance.new("TextLabel")
statsLabel.Size = UDim2.new(0, 60, 1, 0)
statsLabel.Position = UDim2.new(0, 8, 0, 0)
statsLabel.BackgroundTransparency = 1
statsLabel.Text = "FPS: ---"
statsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statsLabel.TextSize = 11
statsLabel.Font = Enum.Font.Code
statsLabel.TextXAlignment = Enum.TextXAlignment.Left
statsLabel.Parent = mainFrame

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 75, 0, 18)
toggleButton.Position = UDim2.new(1, -80, 0.5, -9)
toggleButton.BackgroundColor3 = Color3.fromRGB(0, 180, 90) -- สีเขียว ON
toggleButton.Text = "BOOSTER: ON"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.TextSize = 10
toggleButton.Font = Enum.Font.CodeBold
toggleButton.Parent = mainFrame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 4)
btnCorner.Parent = toggleButton

-- =============================================================================
-- [SECTION 3: THE POTATO ENGINE (REWRITTEN FOR STABILITY)]
-- =============================================================================

-- 3.1 เอนจิ้นปรับแต่งวัตถุแบบเรียบง่าย (ไม่เก็บค่าดั้งเดิมลง Table เพื่อป้องกัน RAM บวมและ Executor เอ๋อ)
local function OptimizeObject(v)
	if not v or not v.Parent then return end
	
	if _G.QuantumX_Booster then
		-- ถ้าเปิดโหมดบูสท์: ปรับเป็น Smooth Plastic ทั้งหมดเพื่อความลื่น
		if v:IsA("BasePart") and not v:IsA("Terrain") then
			v.Material = Enum.Material.SmoothPlastic
			v.CastShadow = false
			for _, light in pairs(v:GetChildren()) do
				if light:IsA("Light") then light.Shadows = false end
			end
		elseif v:IsA("Decal") or v:IsA("Texture") then
			v.Transparency = 1
		elseif v:IsA("ParticleEmitter") or v:IsA("Beam") then
			v.Rate = 0
		elseif v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") then
			v.Enabled = false
		end
	else
		-- ถ้าปิดโหมดบูสท์: คืนค่าเป็นวัสดุ Plastic มาตรฐานของเกม (ปลอดภัย ไม่ทำลายเอนจิ้น)
		if v:IsA("BasePart") and not v:IsA("Terrain") then
			v.Material = Enum.Material.Plastic
			v.CastShadow = true
		elseif v:IsA("Decal") or v:IsA("Texture") then
			v.Transparency = 0
		elseif v:IsA("ParticleEmitter") or v:IsA("Beam") then
			v.Rate = 20
		elseif v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") then
			v.Enabled = true
		end
	end
end

-- 3.2 เคลียร์สภาพแวดล้อม
local function PurgeEnvironment()
	Lighting.GlobalShadows = false
	Lighting.EnvironmentDiffuseScale = 0
	Lighting.EnvironmentSpecularScale = 0
	Lighting.FogEnd = 300
	
	local Terrain = workspace:FindFirstChildOfClass("Terrain")
	if Terrain then Terrain.Decoration = false end

	for _, v in pairs(Lighting:GetDescendants()) do
		if v:IsA("PostEffect") or v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") then
			v:Destroy()
		end
	end
end

-- 3.3 ถอดชุดคอสตูมคนอื่น (รันแยกเธรดแบบเรียบง่าย)
local function CleanOtherPlayers()
	if not _G.QuantumX_Booster then return end
	for _, otherPlayer in pairs(Players:GetPlayers()) do
		if otherPlayer ~= player and otherPlayer.Character then
			for _, item in pairs(otherPlayer.Character:GetDescendants()) do
				if item:IsA("Clothing") or item:IsA("ShirtGraphic") or item:IsA("Pants") or item:IsA("Accessory") then
					item:Destroy()
				end
			end
		end
	end
end

-- 3.4 ระบบซ่อนพาร์ทระยะไกล + พักลูปเพื่อประหยัดแบตเตอรี่ (ลื้อใหม่ ใช้ลูปมาตรฐาน)
task.spawn(function()
	while true do
		task.wait(0.3) -- ปรับเป็น 0.3 วินาที เพื่อเซฟ CPU มือถือสูงสุด เครื่องไม่ร้อนแน่นอน
		if _G.QuantumX_Booster then
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			
			if root then
				local rootPos = root.Position
				local allParts = workspace:GetDescendants()
				
				for i = 1, #allParts do
					local part = allParts[i]
					if part and part:IsA("BasePart") and not part:IsA("Terrain") and not part:IsAncestorOf(char) then
						if (part.Position - rootPos).Magnitude > 75 then
							part.LocalTransparencyModifier = 1
						else
							part.LocalTransparencyModifier = 0
						end
					end
					-- พักลูปทุกๆ 100 ชิ้น ป้องกันอาการค้างรันไม่ไปบน Arceus
					if i % 100 == 0 then task.wait() end
				end
			end
		end
	end
end)

-- 3.5 ลูปเคลียร์ขยะอัตโนมัติ (Anti-Memory Leak แบบเสถียร)
task.spawn(function()
	while true do
		task.wait(20)
		if _G.QuantumX_Booster then
			for _, v in pairs(workspace:GetDescendants()) do
				if v and (v:IsA("Debris") or v.Name == "BulletHole" or v.Name == "BloodSpatter" or v.Name == "EffectPart") then
					v:Destroy()
				end
			end
		end
	end
end)

-- =============================================================================
-- [SECTION 4: EXECUTION & SAFE FPS COUNTER]
-- =============================================================================
settings().Rendering.QualityLevel = Enum.QualityLevel.Level1
PurgeEnvironment()

-- สั่งบูสท์รอบแรกแบบปลอดภัย ค่อยๆ ทำทีละ 100 ชิ้น
task.spawn(function()
	local currentDescendants = workspace:GetDescendants()
	for i = 1, #currentDescendants do
		OptimizeObject(currentDescendants[i])
		if i % 100 == 0 then task.wait() end
	end
end)

CleanOtherPlayers()

-- ตัวดักจับวัตถุเกิดใหม่
workspace.DescendantAdded:Connect(function(v)
	if _G.QuantumX_Booster then
		OptimizeObject(v)
	end
end)

-- 🛠️ FIXED REAL-TIME FPS: ใช้ระบบนับแบบดิบ (Raw Counter) ที่ Arceus ไม่มีวันเอ๋อ
local fpsCounter = 0

RunService.RenderStepped:Connect(function()
	fpsCounter = fpsCounter + 1
end)

task.spawn(function()
	while true do
		task.wait(1)
		if fpsCounter > 0 then
			statsLabel.Text = "FPS: " .. tostring(fpsCounter)
		else
			statsLabel.Text = "FPS: คำนวณ"
		end
		fpsCounter = 0
	end
end)

-- =============================================================================
-- [SECTION 5: BUTTON INTERACTION]
-- =============================================================================
toggleButton.MouseButton1Click:Connect(function()
	_G.QuantumX_Booster = not _G.QuantumX_Booster
	
	if _G.QuantumX_Booster then
		toggleButton.Text = "BOOSTER: ON"
		toggleButton.BackgroundColor3 = Color3.fromRGB(0, 180, 90)
	else
		toggleButton.Text = "BOOSTER: OFF"
		toggleButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
	end
	
	-- สั่งปรับสถานะวัตถุทั้งหมดในแมพตามสวิตช์ทันที
	task.spawn(function()
		local currentDescendants = workspace:GetDescendants()
		for i = 1, #currentDescendants do
			OptimizeObject(currentDescendants[i])
			if i % 100 == 0 then task.wait() end
		end
	end)
end)

print("[QuantumX Hub V2.6.2] Totally Rewritten for Arceus X Neo.")
