-- *****************************************************************
--        ####     ##  #####  ##   ##
--        ## ##    ## ##   ##  ## ##	Crysis Wars nCX
--        ##  ##   ## ##        ###
--        ##   ##  ## ##        ###      Author:   KrawallMann & ctaoistrach
--        ##    ## ## ##   ##  ## ##     Version:  2.0 Public
--        ##     ####  #####  ##   ##    LastEdit: 2012-09-15
-- *****************************************************************
ActionTrigger = {
	
	type = "Trigger",
	Properties = {
		DimX = 5,
		DimY = 5,
		DimZ = 5,
		Effect = "expansion_misc.Lights.Towersignallight", -- misc.runway_light.flash_red
		Scale = 0.4, 
	},
	trigger = true,
	
	Server = {
		---------------------------
		--		OnInit
		---------------------------		
		OnInit = function(self)
			self.debug = self.Properties.Debug;
			self.entity = self.Properties.Vehicle;
			self.PopulationTable = {}; -- [Warning] must be OnInit or triggers will share 1 table
			self.InArea = {};
		end,
		---------------------------
		--		OnInit
		---------------------------	
		OnUpdate = function(self, frameTime)
			self:CheckThePopulation();
		end,
		---------------------------
		--		OnEnterArea
		---------------------------
		OnEnterArea = function(self, entity, areaId)
			if (entity.actor or entity.vehicle) then
				if (self.entity == entity.id) then -- triggers linked to vehicle should ignore enter events for that vehicle
					return;
				elseif (self.CanEnter and not self:CanEnter(entity)) then 
					return;
				end
				self.PopulationTable[entity.id] = entity;
				if (self.entity or self:GetWorldAngles().z == 0) then
					CryMP:HandleEvent("OnEnterArea", {self, entity}); -- default behavior
				elseif (nCX.Count(self.PopulationTable) == 1) then
					self:Activate(1);  -- first entity entered, activate the Population check now!
					if (self.debug) then
						nCX.SendTextMessage(0, "Enabling population check for "..self:GetName().."...", 0);
					end					
				end
			end
		end,
		---------------------------
		--		OnLeaveArea
		---------------------------
		OnLeaveArea = function(self, entity, areaId)
			if (entity.actor or entity.vehicle) then
				if (self.entity == entity.id) then -- triggers linked to vehicle should ignore enter events for that vehicle
					return;
				elseif (self.CanEnter and not self:CanEnter(entity)) then 
					return;
				end
				if (self.entity or self:GetWorldAngles().z == 0) then -- default behavior
					self.PopulationTable[entity.id] = nil;
					CryMP:HandleEvent("OnLeaveArea", {self, entity}); 
				elseif (areaId == -1) then -- left the area
					CryMP:HandleEvent("OnLeaveArea", {self, entity}); 
					self.InArea[entity.id] = nil;
					if (self.debug) then
						CryMP.Msg.Chat:ToAll(entity:GetName().." leaving the area...  #"..tostring(nCX.Count(self.InArea)), 1);
					end						
				elseif (not self.InArea[entity.id]) then
					self.PopulationTable[entity.id] = nil;
					if (nCX.Count(self.PopulationTable) == 0) then
						self:Activate(0);  
						if (self.debug) then
							nCX.SendTextMessage(0, "Disabled population check for "..self:GetName().."...", 0);
						end
					end
				end	
			end
		end,
		
	},
	---------------------------
	--		OnSpawn
	---------------------------
	OnSpawn = function(self)	
	end,
	---------------------------
	--		OnSpawn
	---------------------------
	OnTimer = function(self)	
		self:SpawnLights();
	end,
	---------------------------
	--		OnReset
	---------------------------
	OnReset = function(self)
		--self:DebugLights(self.debug);
		local rotation = self:GetWorldAngles();
		if (self.debug) then
			--[[
			if (rotation.x ~=0 or rotation.y ~=0) then
				System.LogAlways("[$9Warning$9] Spawned Trigger '"..self:GetName().."' probably has an illegal rotation (x or y rotation is not zero) - this is NOT supported!");
			end
			if (math.abs(rotation.z)==math.abs(math.rad(90)) or math.abs(rotation.z)==math.abs(math.rad(270)) or math.abs(rotation.z)==math.abs(math.rad(180))) then
				System.LogAlways("[$9Warning$9] Spawned Trigger "..self:GetName().."'s rotation is a multiple of 90deg - set it to zero and adapt the trigger's dimensions!");
			elseif (rotation.z==0) then
				System.LogAlways("[$9Warning$9] Spawned Trigger "..self:GetName().." has no rotation and will be more performant!");
			end
			if (rotation.z ~= 0) then
				System.LogAlways("[$9Warning$9] Spawned Trigger "..self:GetName().." has been rotated! (z:"..rotation.z..")");
			end
			]]
		end
		local DimX, DimY, DimZ = self.Properties.DimX / 2, self.Properties.DimY / 2, self.Properties.DimZ / 2;
		local corners	= {}; -- MUST BE ORDERED CLOCKWISE - OTHERWISE, THE CROSS PRODUCT METHOD WILL NOT WORK!
		corners[1] = {x=-DimX, y=-DimY,z=0};
		corners[2] = {x=-DimX, y=DimY,z=0};
		corners[3] = {x=DimX, y=DimY,z=0};
		corners[4] = {x=DimX, y=-DimY,z=0};
		if (rotation.z ~= 0) then
			--rotation required!
			local minX, minY, maxX, maxY = 0, 0, 0, 0;
			local cornersRotated = {};
			local center = self:GetWorldPos();
			-- calculate the coordinates for our bounding box!
			for i = 1, 4 do
				cornersRotated[i] = self:Rotate(corners[i], rotation.z);
				minX = math.min(minX, cornersRotated[i].x);
				minY = math.min(minY, cornersRotated[i].y);
				
				maxX = math.max(maxX, cornersRotated[i].x);
				maxY = math.max(maxY, cornersRotated[i].y);
			end
			self.Corners = cornersRotated;
			self:SetTriggerBBox( {minX, minY, -DimZ} , {maxX, maxY, DimZ} ); -- Set the minimum boundingbox
		else
			-- no rotation required - use the default behavior!
			local Min = { x=-DimX, y=-DimY, z=-DimZ, };
			local Max = { x=DimX, y=DimY, z=DimZ, };
			self:SetTriggerBBox( Min, Max );
			self.Corners = corners;
		end
	end,
	---------------------------
	--	CheckThePopulation
	---------------------------
	CheckThePopulation = function(self)
		for entityId, entity in pairs(self.PopulationTable) do
			local speed = entity:GetSpeed();
			if (speed) then
				if (speed > 0) then -- dont check if entity is not moving
					local inside = self:IsInside(entity);
					if (inside) then
						if (not self.InArea[entityId]) then
							self.InArea[entityId] = true;
							CryMP:HandleEvent("OnEnterArea", {self, entity});
							if (self.debug) then
								CryMP.Msg.Chat:ToAll(entity:GetName().." entering the area... #"..tostring(nCX.Count(self.InArea)), 1);  -- Tables without index cannot be counted with #, use nCX.Count
							end
						end
					elseif (self.InArea[entityId]) then
						self.Server.OnLeaveArea(self, entity, -1);
					end
				end
			else
				self.PopulationTable[entityId] = nil;
			end
		end
	end,
	---------------------------
	--	IsInside
	---------------------------
	IsInside = function(self, entity)
		local pos, spos = entity:GetWorldPos(), self:GetWorldPos();
		if (math.abs(pos.z - spos.z) > self.Properties.DimZ) then
			return false; -- fix for rotated niggas ignoring height
		end
		for index = 1, 4 do
			local nextCorner = index + 1;
			if (nextCorner > 4) then
				nextCorner = 1;
			end
			-- get the vector from this edge to the next one!
			local vcorner = math:DifferenceVectors(self.Corners[nextCorner], self.Corners[index]); -- vector pointing towards the next edge 
			-- get the vector from this edge to the player's position
			local ppos = math:DifferenceVectors(pos, math:SumVectors(spos, self.Corners[index])); -- vector pointing towards the player's position
			-- cross product(ppos, vcorner) is positive if the point is inside!
			local result = g_Vectors.v000;
			math:crossproduct3d( result, ppos, vcorner );
			if (result.z < 0) then
				return false;
			end
		end
		return true;
	end,
	---------------------------
	--	EnableLights
	---------------------------
	DebugLights = function(self, enable)
		if (enable) then
			nCX.UpdateObjectTimer(self.id, true);
		else
			nCX.UpdateObjectTimer(self.id, false);
		end
	end,
	---------------------------
	--	SpawnLights
	---------------------------
	SpawnLights = function(self, channelId, effect, scale)
		local spos = self:GetWorldPos();
		local scale = scale or self.Properties.Scale;
		effect = effect or self.Properties.Effect;
		for index, pos in pairs(self.Corners) do
			local e = {
				math:SumVectors(spos, pos),
				math:SumVectors(spos, math:SumVectors(pos, {x=0, y=0, z=self.Properties.DimZ/2})),
				math:SumVectors(spos, math:SumVectors(pos, {x=0, y=0, z=-self.Properties.DimZ/2})),					
			};
			for i, v in pairs(e) do
				nCX.ParticleManager(effect, scale, v, g_Vectors.up, channelId or 0);
			end
		end
	end,
	---------------------------
	--	Rotate
	---------------------------
	Rotate = function(self, pos, angle)
		return {
			x = math.cos(angle) * pos.x - math.sin(angle) * pos.y,
			y = math.sin(angle) * pos.x + math.cos(angle) * pos.y,
			z = pos.z,
		};
	end,
	
};