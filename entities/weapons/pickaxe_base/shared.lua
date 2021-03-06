if (SERVER) then AddCSLuaFile("shared.lua") end

if (CLIENT) then

	SWEP.DrawAmmo			= false

	SWEP.DrawCrosshair		= true

	SWEP.ViewModelFOV		= 55

	SWEP.ViewModelFlip		= false

	SWEP.CSMuzzleFlashes	= false

	SWEP.Slot               = 0

	SWEP.SlotPos		    = 2

end

SWEP.Author		= "Jackool"

SWEP.Contact		= ""

SWEP.Purpose		= "Used for mining"

SWEP.Instructions	= "Primary fire: Attempt to mine from a rock."

SWEP.Category = "Rebellion (Utility)"


SWEP.Spawnable			= true

SWEP.AdminSpawnable		= true

SWEP.ViewModel			= "models/weapons/v_stone_pickaxe.mdl"

SWEP.WorldModel			= "models/weapons/w_stone_pickaxe.mdl"

SWEP.Primary.ClipSize		= -1

SWEP.Primary.DefaultClip	= -1

SWEP.Primary.Automatic		= true

SWEP.Primary.Ammo			= "none"

SWEP.HoldType               = "melee2"

SWEP.Secondary.ClipSize		= -1

SWEP.Secondary.DefaultClip	= -1

SWEP.Secondary.Automatic	= false

SWEP.Secondary.Ammo			= "none"

SWEP.ChanceMultiplier = 1

SWEP.OresMultiplier = 1

function SWEP:Initialize()

	self:SetHoldType(self.HoldType)

end

function SWEP:Reload() end

/*---------------------------------------------------------
	PrimaryAttack
	Line 553: 			 self.Owner:EmitSound(Sound("physics/glass/glass_bottle_impact_hard"..tostring(math.random(1,3))..".wav"))
	Line 553: 			 self.Owner:EmitSound(Sound("physics/glass/glass_bottle_impact_hard"..tostring(math.random(1,3))..".wav"))
---------------------------------------------------------*/
function SWEP:PrimaryAttack()

	self.Weapon:SendWeaponAnim(ACT_VM_HITCENTER)

	self.Weapon:SetNextPrimaryFire(CurTime() + 1)

	if CLIENT then RunConsoleCommand("-attack") return end

	local ply = self.Owner

	if ply:Team() != TEAM_MINER then ply:LiquidChat("Mining", Color(100,100,100), "You need to be the miner job to use this. (remember to holster the pick first)") return end
	
	if ply.Picking then return end
	
	local ent = ply:GetEyeTrace().Entity
	
	ply:EmitSound("weapons/iceaxe/iceaxe_swing1.wav")
	
	if ent:GetClass() != "rock_base" or ply:GetEyeTrace().HitPos:Distance(ply:GetPos()) > 100 then return end

	ply:EmitSound("physics/glass/glass_bottle_impact_hard" .. math.random(1,3) .. ".wav")
	
	local RockType = ent.RockType

	local Tbl = LDRP_SH.Rocks[RockType]

	local Lvl = ply.Character.Skills["Mining"].lvl
	
	if Tbl.lvl > Lvl then ply:LiquidChat("Mining", Color(100,100,100), "You need a higher level mining to mine this.") return

	elseif !ply:CanCarry(Tbl.picked,Tbl.pickedam*self.OreMultipler) then ply:LiquidChat("Mining", Color(100,100,100), "You need to free up inventory space before mining this.") return
	
	elseif Tbl.required then ply:LiquidChat("Mining", Color(100,100,100), "This rock requires a better pickaxe.") end

	local plyid = ply:UniqueID()

	local Picked = 0

	ply.Picking = true

	local Picktime

	if self.MiningTimeReducer then

		Picktime = tonumber(LDRP_SH.PickTime - self.MiningTimeReducer)

	else

		Picktime = LDRP_SH.PickTime

	end

	umsg.Start("SendMeter",ply)

		umsg.String("Mining...")

		umsg.Float(Picktime)

	umsg.End()

	timer.Create("Mining_" .. plyid, 1, Picktime, function()

		if !ent:IsValid() or !ply:IsValid() or ply:GetActiveWeapon() != self.Weapon or ply:GetEyeTrace().Entity != ent or ply:GetEyeTrace().HitPos:Distance(ply:GetPos()) > 100 then
			
			umsg.Start("CancelMeter",ply)
			
			umsg.End()
			
			if ply:IsValid() then ply.Picking = nil end
			
			timer.Remove("Mining_" .. plyid)
			
			return
		end

		ply:EmitSound(Sound("physics/glass/glass_bottle_impact_hard"..tostring(math.random(1,3))..".wav"))
		
		self.Weapon:SendWeaponAnim(ACT_VM_HITCENTER)
		
		Picked = Picked+1
		
		if SERVER and Picked == Picktime then

			ply.Picking = false

			if (self.ChanceMultiplier == 0) || math.random(1,Tbl.minechance*self.ChanceMultiplier) == 1 then

				ply:LiquidChat("Mining", Color(100,100,100), "You have mined " .. RockType .. "!")

				ply:AddItem(Tbl.picked,Tbl.pickedam*self.OreMultipler)

				ply:GiveEXP("Mining",Tbl.exp,true)

				ent.Picks = ent.Picks+1

				if ent.Picks >= Tbl.picks then

					ent:Remove()

					ply:LiquidChat("Mining", Color(100,100,100), "The rock has broken!")

				end

			else

				ply:LiquidChat("Mining", Color(100,100,100), "Failed to mine rock.")

			end

			self:PrimaryAttack()

		end
		
	end)

end

/*---------------------------------------------------------
	SecondaryAttack
---------------------------------------------------------*/
function SWEP:SecondaryAttack()
end

function SWEP:Deploy()
	if self.CustomClr then

		if SERVER then

			timer.Simple(0.1, function() if IsValid(self) then self:CallOnClient("Deploy", "") end end)

			self:SetMaterial(self.CustomMat)

			self:SetColor(self.CustomClr)

		else

			self.Owner:GetViewModel():SetMaterial(self.CustomMat)

			self.Owner:GetViewModel():SetColor(self.CustomClr)

		end

	end

end

function SWEP:Holster()

	if self.CustomClr then

		if SERVER then

			self:SetColor(Color(255, 255, 255, 255))

			self:SetMaterial("")

		elseif CLIENT && IsValid(self.Owner) && IsValid(self.Owner:GetViewModel()) then

			self.Owner:GetViewModel():SetColor(Color(255, 255, 255, 255))

			self.Owner:GetViewModel():SetMaterial("")

		end

	end

	return true

end

function SWEP:OnRemove()

	if self.CustomClr then

		if SERVER then

			self:SetMaterial("")

			self:SetColor(Color(255, 255, 255, 255))

		elseif CLIENT && IsValid(self.Owner) && IsValid(self.Owner:GetViewModel()) then

			self.Owner:GetViewModel():SetColor(Color(255, 255, 255, 255))

			self.Owner:GetViewModel():SetMaterial("")

		end

	end

end