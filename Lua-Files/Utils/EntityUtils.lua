-- *****************************************************************
--        ####     ##  #####  ##   ##
--        ## ##    ## ##   ##  ## ##	Crysis Wars nCX
--        ##  ##   ## ##        ###
--        ##   ##  ## ##        ###      Author:   Arcziy
--        ##    ## ## ##   ##  ## ##     Version:  2.0 Public
--        ##     ####  #####  ##   ##    LastEdit: 2012-04-09
-- *****************************************************************

EntityCommon = {
	TempPhysParams = { mass=0,density=0 },
	TempPhysicsFlags = { flags_mask=0, flags=0 };
};

function MakeDerivedEntity( _DerivedClass,_Parent )
	local derivedProperties = _DerivedClass.Properties;
	_DerivedClass.Properties = {};
	mergef(_DerivedClass,_Parent,1);
	mergef(_DerivedClass.Properties,derivedProperties,1);
	_DerivedClass.__super = BasicEntity;
	return _DerivedClass;
end

function BroadcastEvent( sender,Event  )
	sender:ProcessBroadcastEvent( Event );
	if (sender.Events) then
		local eventTargets = sender.Events[Event];
		if (eventTargets) then
			for i, target in pairs(eventTargets) do
				local TargetId = target[1];
				local TargetEvent = target[2];				
				if (TargetId == 0) then
					if Mission then
						local func = Mission["Event_"..TargetEvent];
						if (func ~= nil) then
							func( sender )
						end
					end
				else
					local entity = System.GetEntity(TargetId);
					if (entity ~= nil) then
						local TargetName = entity:GetName();
						local func = entity["Event_"..TargetEvent];
						if (func ~= nil) then
							func(entity, sender);
						end
					end
				end
 			end
 		end
 	end
end

function MakeUsable(entity)
	if not entity.Properties then entity.Properties = {} end
	entity.Properties.UseText = "";
	entity.Properties.bUsable = 0;
	function entity:IsUsable()
		if not self.__usable then self.__usable = self.Properties.bUsable end;
		return self.__usable;
	end
	function entity:ResetOnUsed()
		self.__usable = nil;
	end
	function entity:GetUsableMessage()
		return self.Properties.UseText;
	end
	function entity:OnUsed(user, idx)
		BroadcastEvent(self, "Used");
	end
	function entity:Event_Used()
		BroadcastEvent(self, "Used");
	end
	function entity:Event_EnableUsable()
		self.__usable = 1;
		BroadcastEvent(self, "EnableUsable");
	end
	function entity:Event_DisableUsable()
		self.__usable = 0;
		BroadcastEvent(self, "DisableUsable");
	end
end

function MakePickable(entity)
	if not entity.Properties then entity.Properties = {} end;
	entity.Properties.bPickable = 0;
end

function MakeSpawnable(entity)
	entity.spawnedEntity = nil
	if not entity.Properties then entity.Properties = {} end
	local p = entity.Properties;
	p.bSpawner = false;
	p.SpawnedEntityName = "";
	local _OnDestroy = entity.OnDestroy;
	function entity:OnDestroy()
		if self.whoSpawnedMe then
			self.whoSpawnedMe:NotifyRemoval(self.id);
		end
		if _OnDestroy then
			_OnDestroy(self);
 		end
	end

	function entity:NotifyRemoval(spawnedEntityId)
		if (self.spawnedEntity and self.spawnedEntity == spawnedEntityId) then
			self.spawnedEntity = nil;
		end
	end		

	local _OnReset = entity.OnReset;
	function entity:OnReset()
		if self.spawnedEntity then
			System.RemoveEntity(self.spawnedEntity);
			self.spawnedEntity = nil;
		end
		if self.whoSpawnedMe then
			System.RemoveEntity( self.id );
			return
		end
		_OnReset(self);
	end
	
  function entity:GetFlowgraphForwardingEntity()
		return self.spawnedEntity
	end

	function entity:Event_Spawned()
		BroadcastEvent(self, "Spawned")
	end

	if not entity.FlowEvents then entity.FlowEvents = {} end
	local fe = entity.FlowEvents
	fe.Inputs = fe.Inputs or {}
	fe.Outputs = fe.Outputs or {}
	local allEvents = {}
	local name, data
	for name, data in pairs(fe.Outputs) do
		allEvents[name] = data
	end
	for name, data in pairs(fe.Inputs) do
		allEvents[name] = data
	end

	for name, data in pairs(allEvents) do
		local isInput = fe.Inputs[name]
		local isOutput = fe.Outputs[name]
		local isDeath = (name=="Dead")
		local _event = data
		if type(_event) == "table" then
			_event = _event[1]
		else
			_event = nil
		end
		entity["Event_"..name] = function(self, sender, param)
			if isOutput and (sender and sender.id == self.spawnedEntity or sender==self) then
				BroadcastEvent(self, name)
			end
			if isInput and (self.spawnedEntity and ((not sender) or (self.spawnedEntity ~= sender.id))) then
				local ent = System.GetEntity(self.spawnedEntity)
				if _event and ent and ent ~= sender then
					_event(ent, sender, param)
				end
			elseif _event and not self.spawnedEntity then
				_event(self, sender, param)
			end
			if isDeath and (sender and sender.id == self.spawnedEntity) then
				self.spawnedEntity = nil
			end
		end
	end

	function entity:Event_Spawn()
		if self.whoSpawnedMe then
			self.whoSpawnedMe:Event_Spawn()
		else
			if self.spawnedEntity then
				return
			end
			local params = {
				class = self.class;
				position = self:GetPos(),
				orientation = self:GetDirectionVector(1),
				scale = self:GetScale(),
				archetype = self:GetArchetype(),
				properties = self.Properties,
				propertiesInstance = self.PropertiesInstance,
			};
			if self.Properties.SpawnedEntityName ~= "" then
				params.name = self.Properties.SpawnedEntityName
			else
				params.name = self:GetName().."_s"
			end
			local ent = System.SpawnEntity(params, self.id)
			if ent then
				self.spawnedEntity = ent.id
				if not ent.Events then ent.Events = {} end
				local evts = ent.Events
				for name, data in pairs(self.FlowEvents.Outputs) do
					if not evts[name] then evts[name] = {} end
					table.insert(evts[name], {self.id, name})
				end
				ent.whoSpawnedMe = self;
				self:ActivateOutput("Spawned", ent.id);
			end
		end
	end

	function entity:Event_SpawnKeep()
		local params = {
			class = self.class;
			position = self:GetPos(),
			orientation = self:GetDirectionVector(1),
			scale = self:GetScale(),
			archetype = self:GetArchetype(),
			properties = self.Properties,
			propertiesInstance = self.PropertiesInstance,
		};
		local rndOffset = 1;
		params.position.x = params.position.x + random(0,rndOffset*2)-rndOffset;
		params.position.y = params.position.y + random(0,rndOffset*2)-rndOffset;
		params.name = self:GetName()
		local ent = System.SpawnEntity(params, self.id)
		if ent then
			self.spawnedEntity = ent.id
			if not ent.Events then ent.Events = {} end
			local evts = ent.Events
			for name, data in pairs(self.FlowEvents.Outputs) do
				if not evts[name] then evts[name] = {} end
				table.insert(evts[name], {self.id, name})
			end
			self:ActivateOutput("Spawned", ent.id);
		end
	end
	fe.Inputs["Spawn"] = {entity.Event_Spawn, "bool"}
	fe.Outputs["Spawned"] = "entity";
end

EntityCommon.PhysicalizeRigid = function( entity,nSlot,Properties,bActive )
  local Mass = Properties.Mass; 
  local Density = Properties.Density;
  local physType;
  if (Properties.bArticulated == 1) then
		physType = PE_ARTICULATED;
	else
		if (Properties.bRigidBody == 1) then
			physType = PE_RIGID;
		else
			physType = PE_STATIC;
		end
	end
	local TempPhysParams = EntityCommon.TempPhysParams;
	TempPhysParams.density = Density;
	TempPhysParams.mass = Mass;
	TempPhysParams.flags = 0;
	entity:Physicalize( nSlot, physType, TempPhysParams );	
	local Simulation = Properties.Simulation;
	if (Simulation) then
		entity:SetPhysicParams(PHYSICPARAM_SIMULATION, Simulation);
	end
	local Buoyancy = Properties.Buoyancy;
	if (Buoyancy) then
		entity:SetPhysicParams(PHYSICPARAM_BUOYANCY, Buoyancy);
	end
	local PhysFlags = EntityCommon.TempPhysicsFlags;
	PhysFlags.flags =  0;
	if (Properties.bPushableByPlayers == 1) then
	  PhysFlags.flags = pef_pushable_by_players;
	end
	if (Simulation and Simulation.bFixedDamping and Simulation.bFixedDamping==1) then
		PhysFlags.flags = PhysFlags.flags+pef_fixed_damping;
	end
	if (Simulation and Simulation.bUseSimpleSolver and Simulation.bUseSimpleSolver==1) then
		PhysFlags.flags = PhysFlags.flags+ref_use_simple_solver;
	end
	if (Properties.bCanBreakOthers==nil or Properties.bCanBreakOthers==0) then
		PhysFlags.flags = PhysFlags.flags+pef_never_break;
	end
	PhysFlags.flags_mask = pef_fixed_damping + ref_use_simple_solver + pef_pushable_by_players + pef_never_break;
	entity:SetPhysicParams( PHYSICPARAM_FLAGS,PhysFlags );
	if (Properties.bResting == 0) then
		entity:AwakePhysics(1);
	else
		entity:AwakePhysics(0);
	end
end

function MakeCompareEntitiesByDistanceFromPoint( point )
	function CompareEntitiesByDistanceFromPoint( ent1, ent2 )
		distance1 = DistanceSqVectors( ent1:GetWorldPos(), point )
		distance2 = DistanceSqVectors( ent2:GetWorldPos(), point )
		return distance1 > distance2
	end
	return CompareEntitiesByDistanceFromPoint
end

XVar = {};
function XFormat(fmt,...)
	local status, result = pcall(string.format,fmt,...);
	if (not status) then
		System.LogAlways("[AEGIS] XFormat Error: "..(debug.traceback(tostring(result) or "NIL",2) or "FAILED TRACEBACK"));
		error(tostring(result) or "UNKNOWN ERROR");
	end
	return result;
end
function XTableComp(k1,v1,k2,v2)
	if (tonumber(k1)) then
		if (tonumber(k2)) then
			return tonumber(k1)<tonumber(k2);
		else
			return true; -- numbers before strings
		end
	else
		if (tonumber(k2)) then
			return false; -- numbers before strings
		else
			return tostring(k1)<tostring(k2);
		end
	end
end
function XDumpObjectToFile(file, prefix, obj, depth, short, omitFunctions)
	if (obj and ((obj == XVar.dumpCache) or (obj == XVar.tableXref) or (obj == XVar.functionXref))) then
		return;
	end
	if (depth==nil) then
		depth = 5;
	end
	if (depth<=0) then
		file:write(XFormat("%s=%s ...?\n", prefix, tostring(obj)));
		return
	end
	local clearCache = false;
	if (not XVar.dumpCache) then
		XVar.dumpCache = {};
		XVar.stringMeta = getmetatable("abc");
		XVar.tableXref = {};
		XVar.functionXref = {};
		clearCache = true;
		file:write(XFormat("===== Global Environment Reference\n"));
	end
	local t = type(obj);
	if (t=="table") then
		XDumpTableToFile(file,prefix..".", obj, depth, short, omitFunctions);
	else
		local s = tostring(obj);
		if ((t=="function") and not omitFunctions) then
			if (not XVar.functionXref[obj]) then
				XVar.functionXref[obj] = {};
			end
			XVar.functionXref[obj][#XVar.functionXref[obj] + 1] = prefix;
			file:write(XFormat("%s=%s\n", prefix, s));
		elseif (t~="function") then
			file:write(XFormat("%s=%s\n", prefix, s));
		end
	end
	local m = getmetatable(obj);
	if (m and m~=XVar.stringMeta) then
		XDumpTableToFile(file,prefix.."::", m, depth, short, omitFunctions);
	end
	if (clearCache) then
		if (not short) then
			file:write(XFormat("===== Table Cross Reference\n"));
			for t,pp in pairs(XVar.tableXref) do
				if (#pp > 1) then
					file:write(XFormat("%s:\n",t));
					for i,p in ipairs(pp) do
						file:write(XFormat("  %4d=%s\n",i,p));
					end
				end
			end
			if (not omitFunctions) then
				local fnref = XVar.functionXref;
				XVar.functionXref = {};
				file:write(XFormat("===== Function Cross Reference\n"));
				for fn,pp in pairs(fnref) do
					local info = debug.getinfo(fn,"S");
					file:write(XFormat("%s: %s:%d\n",tostring(fn),info.source,info.linedefined));
					for i,p in pairs(pp) do
						file:write(XFormat("    %4d=%s\n",i,p));
					end
				end
			end
		end
		XVar.functionXref = nil;
		XVar.dumpCache = nil;
		XVar.stringMeta = nil;
		XVar.tableXref = nil;
	end
end

function XDumpTableToFile(file, prefix, obj, depth, short, omitFunctions)
	local s = tostring(obj);
	if (not XVar.tableXref[s]) then
		XVar.tableXref[s] = {};
	end
	XVar.tableXref[s][#XVar.tableXref[s] + 1] = prefix.."*";
	if (XVar.dumpCache[s]) then
		file:write(XFormat("%s*=%s  <<< see above\n", prefix, s));
	else
		file:write(XFormat("%s*=%s\n", prefix, s));
		XVar.dumpCache[s] = true;
		local keys = {};
		for k,v in pairs(obj) do
			keys[#keys + 1] = k;
		end
		table.sort(keys, function (a,b) return XTableComp(a,keys[a],b,keys[b]); end);
		for idx,k in ipairs(keys) do
			local v = obj[k];
			XDumpObjectToFile(file,prefix..tostring(k), v, depth-1, short, omitFunctions);
			if ((k=="id") and (type(v)=="userdata")) then
				local e = System.GetEntity(v);
				if (e and e~=obj) then
					XDumpObjectToFile(file,"<"..prefix..".id>", e, depth-1, short, omitFunctions);
				end
			end
		end
	end
end  
