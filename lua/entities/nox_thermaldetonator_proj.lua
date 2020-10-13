-- common grenade projectile code

AddCSLuaFile()

ENT.Type = "anim"
ENT.Model = Model("models/nox/thermaldet/thermaldet.mdl")


AccessorFunc( ENT, "thrower", "Thrower")

function ENT:SetupDataTables()
   self:NetworkVar("Float", 0, "ExplodeTime")
end

function ENT:Initialize()
   self:SetModel(self.Model)


	
	
   self:PhysicsInit(SOLID_VPHYSICS)
   self:SetMoveType(MOVETYPE_VPHYSICS)
   self:SetSolid(SOLID_BBOX)
   self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)

   if SERVER then
      self:SetExplodeTime(0)
   end
end


function ENT:SetDetonateTimer(length)
   self:SetDetonateExact( CurTime() + length )
end

function ENT:SetDetonateExact(t)
   self:SetExplodeTime(t or CurTime())
end

-- override to describe what happens when the nade explodes
function ENT:Explode(tr)
   	if SERVER then
      self:SetNoDraw(true)
      self:SetSolid(SOLID_NONE)

      -- pull out of the surface
      if tr.Fraction != 1.0 then
         self:SetPos(tr.HitPos + tr.HitNormal * 0.6)
      end

      local pos = self:GetPos()

      if util.PointContents(pos) == CONTENTS_WATER then
         self:Remove()
         return
      end

      local effect = EffectData()
      effect:SetStart(pos)
      effect:SetOrigin(pos)
      effect:SetScale(256 * 0.3)
      effect:SetRadius(256)
      effect:SetMagnitude(400)
	  
	  local effect2 = EffectData()
	  effect2:SetStart(pos)
      effect2:SetOrigin(pos)
      effect2:SetScale(2)
      effect2:SetRadius(2)
      effect2:SetMagnitude(10)
	  
      if tr.Fraction != 1.0 then
         effect:SetNormal(tr.HitNormal)
      end
	  
	--  sound.Add( {
	--name = "Detonation",
	--channel = CHAN_WEAPON,
	--volume = 1.0,
	--level = 150,
	--pitch = { 100, 100 },
	--sound = "weapons/thermaldet/Detonation.wav"
--} )
	  local detonation = "weapons/thermaldet/Detonation.wav"
	  self:EmitSound(detonation)
	  
      util.Effect("cball_explode", effect, true, true)
	  util.Effect("Sparks", effect2, true, true)
      util.BlastDamage(self, self:GetThrower(), pos, 256, 400)
	  util.Effect("Explosion", effect, true, true)

      self:SetDetonateExact(0)
	  
      self:Remove()
   else
      local spos = self:GetPos()
      local trs = util.TraceLine({start=spos + Vector(0,0,64), endpos=spos + Vector(0,0,-128), filter=self})
          

      self:SetDetonateExact(0)
   end
end

function ENT:Think()
   local etime = self:GetExplodeTime() or 0
   if etime != 0 and etime < CurTime() then
      -- if thrower disconnects before grenade explodes, just don't explode
      if SERVER and (not IsValid(self:GetThrower())) then
         self:Remove()
         etime = 0
         return
      end

      -- find the ground if it's near and pass it to the explosion
      local spos = self:GetPos()
      local tr = util.TraceLine({start=spos, endpos=spos + Vector(0,0,-32), mask=MASK_SHOT_HULL, filter=self.thrower})

      local success, err = pcall(self.Explode, self, tr)
      if not success then
         -- prevent effect spam on Lua error
         self:Remove()
         ErrorNoHalt("ERROR CAUGHT: nox_thermaldetonator_proj: " .. err .. "\n")
      end
   end
end
