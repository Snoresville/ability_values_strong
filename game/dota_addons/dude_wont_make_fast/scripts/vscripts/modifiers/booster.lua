booster = booster or class({})

function booster:GetTexture() return "sven_gods_strength" end -- get the icon from a different ability

function booster:IsPermanent() return true end
function booster:RemoveOnDeath() return false end
function booster:IsHidden() return false end 	-- we can hide the modifier
function booster:IsDebuff() return false end 	-- make it red or green

function booster:OnCreated(event)
	-- for k,v in pairs(event) do print("booster created",k,v,(IsServer() and "on Server" or "on Client")) end
	-- called when the modifier is created
	if IsServer() then
		self.hero_kill_gain = BUTTINGS.HERO_KILL_GAIN or 25
		self.creep_kill_gain = BUTTINGS.CREEP_KILL_GAIN or 25
	end
	self:StartIntervalThink(1)
	
	self.multiplier = 1
end

function booster:OnIntervalThink()
	if not IsServer() then
		return
	end
	for i = 0, 30 do
		local ability = self:GetParent():GetAbilityByIndex(i)
		if ability and not ability:IsNull() and ability:GetLevel() > 0 then
			ability:RefreshIntrinsicModifier()
		end
	end
end

function booster:GetAttributes()
	return 0
		+ MODIFIER_ATTRIBUTE_PERMANENT           -- Modifier passively remains until strictly removed. 
		-- + MODIFIER_ATTRIBUTE_MULTIPLE            -- Allows modifier to stack with itself. 
		-- + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE -- Allows modifier to be assigned to invulnerable entities. 
end

function booster:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_DEATH,
		MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL,
		MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL_VALUE,
		MODIFIER_PROPERTY_TOOLTIP,
	}
	return funcs
end

function booster:OnTooltip(event)
	return self.multiplier * self:GetStackCount()
end

function booster:OnRefresh(event)
	-- for k,v in pairs(event) do print("booster refreshed",k,v,(IsServer() and "on Server" or "on Client")) end
	-- called when the modifier is refreshed
	
	self:OnCreated()
end


function booster:OnDeath(event)
	-- for k,v in pairs(event) do print("OnDeath",k,v) end -- find out what event.__ to use
	if IsClient() then return end
	if event.attacker:GetPlayerOwnerID() ~= self:GetParent():GetPlayerOwnerID() then return end -- only affect the own hero
	if event.unit:IsOther() then return end -- denying wards bad
	--if not event.unit:IsHero() then return end
	
	if event.unit:IsHero() and not event.unit:IsIllusion() then
		self:SetStackCount(self:GetStackCount() + self.hero_kill_gain)
	else
		self:SetStackCount(self:GetStackCount() + self.creep_kill_gain)
	end
end

function booster:GetModifierOverrideAbilitySpecial( params )
	local ability = params.ability
	
	-- Unomment this shit if you don't want items to work
	-- Reverse for working items
	if ability:IsItem() then return 0 end

	return 1
end

-----------------------------------------------------------------------

function booster:GetModifierOverrideAbilitySpecialValue( params )
	local szAbilityName = params.ability:GetAbilityName() 
	local szSpecialValueName = params.ability_special_value
	local nSpecialLevel = params.ability_special_level
	
	local flBaseValue = params.ability:GetLevelSpecialValueNoOverride( szSpecialValueName, nSpecialLevel )
	if szSpecialValueName == "AbilityCooldown" or szSpecialValueName == "AbilityManaCost" or szSpecialValueName == "AbilityChargeRestoreTime" then
		return flBaseValue
	end

	print(szSpecialValueName)

	return flBaseValue + flBaseValue * self.multiplier * self:GetStackCount() / 100
end
