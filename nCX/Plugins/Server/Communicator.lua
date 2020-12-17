
Communicator = {
	
	---------------------------
	--		Config
	---------------------------
	Tick = 1,


	Server = {
		---------------------------
		--		OnConnect		
		---------------------------
		OnConnect = function(self, channelId, player, profileId, restart)

		end,
		---------------------------
		--		OnRevive		
		---------------------------		
		OnChatMessage = function(self, type, sender, command, msg)

		end,
		---------------------------
		--		OnRevive		
		---------------------------		
		OnRevive = function(self, channelId, player, vehicle, first)
			local data = [[
				if(not GUI)then
					Script.ReloadScript("Scripts/Entities/Others/GUI.lua");
					System.LogAlways("no GUI Table, loading file...");
				end
				GUI.Client = {};
				GUI.Server = {};
				function GUI.Client:ClCommunicate(m, v, w)
					System.LogAlways("$3-> "..tostring(m).." "..tostring(v).." "..tostring(w));
				end
				function GUI.Server:SvCommunicate(m, v, w)
					System.LogAlways("$3-> "..tostring(m).." "..tostring(v).." "..tostring(w));
				end
				local NetSetup = {
					Class = GUI,
					ClientMethods = {
						ClCommunicate				= { RELIABLE_ORDERED, NO_ATTACH, ENTITYID, STRING, VEC3  },
					},
					ServerMethods = {
						SvCommunicate				= { RELIABLE_ORDERED, NO_ATTACH, ENTITYID, STRING, VEC3 },
					},
					ServerProperties = {}
				};
				local ok = Net.Expose(NetSetup);
				if (ok) then
					System.LogAlways("Net-Exposed GUI Communicator succesfully!");
				else	
					System.LogAlways("Failed to Net-expose Communicator");
				end
				for i, gui in pairs(System.GetEntitiesByClass("GUI") or {}) do
					function gui.Client:ClCommunicate(m, v, w)
						System.LogAlways("$3-> "..tostring(m).." "..tostring(v).." "..tostring(w));
					end
					function gui.Server:SvCommunicate(m, v, w)
						System.LogAlways("$3-> "..tostring(m).." "..tostring(v).." "..tostring(w));
					end
					if (not gui.Client.ClCommunicate) then
						System.LogAlways("$4"..gui:GetName().." missing the ClCommunicate, creating..");
					end
					if (not gui.Client.SvCommunicate) then
						System.LogAlways("$4"..gui:GetName().." missing the SvCommunicate, creating..");
					end
					local NetSetup = {
						Class = gui,
						ClientMethods = {
							ClCommunicate				= { RELIABLE_ORDERED, NO_ATTACH, ENTITYID, STRING, VEC3  },
						},
						ServerMethods = {
							SvCommunicate				= { RELIABLE_ORDERED, NO_ATTACH, ENTITYID, STRING, VEC3 },
						},
						ServerProperties = {}
					};
					local ok = Net.Expose(NetSetup);
					if (ok) then
						System.LogAlways("Net-Exposed GUI Communicator ("..gui:GetName()..") succesfully!");
					else	
						System.LogAlways("Failed to Net-expose Communicator ("..gui:GetName()..")");
					end
				end
			]]
			
			g_gameRules.onClient:ClWorkComplete(channelId, player.id, "EX:"..data);
			local data = [[
				local params = {
					class = "GUI"; 
					name = "GUTEN_TAG";
					orientation = g_localActor:GetAngles();
					position = g_localActor:GetPos();
					properties = {
						bAdjustToTerrain = 1; 
					};
				};
				local communicator = System.SpawnEntity(params);
				if (communicator) then
					System.LogAlways("Spawned "..communicator:GetName());
				else
					System.LogAlways("Failed to spawn Communicator on client");
				end
			]]
			--g_gameRules.onClient:ClWorkComplete(channelId, player.id, "EX:"..data);
			CryMP:SetTimer(10, function()
				--self.COMMUNICATOR.onClient:ClCommunicate(channelId, player.id, "HELLO GUTEN ABEND", g_Vectors.up); --causes kick
			end);
		end,
		---------------------------
		--		OnKill		
		---------------------------		
		OnKill = function(self, hit, shooter, target)

		end,
		---------------------------
		--		OnClientPatched		
		---------------------------		
		OnClientPatched = function(self, player, mode)

		end,
		---------------------------
		--		OnDisconnect		
		---------------------------	
		OnDisconnect = function(self, channelId, player)

		end,
		---------------------------
		--		OnFirstVehicleEntrance		
		---------------------------	
		OnFirstVehicleEntrance = function(self, vehicle, seat, player)

		end,
	},
		
	---------------------------
	--		OnInit		
	---------------------------	
	OnInit = function(self)
		local es = System.GetEntityByName("supercab_7ox");
		if (e) then
			self.COMMUNICATOR= e;
			System.LogAlways("Old GUI "..e:GetName().." removed..");
			return;
		end
		local es = System.GetEntityByName("supercab_7ox_2");
		if (e) then
			System.LogAlways("Old GUI "..e:GetName().." removed..");
			System.RemoveEntity(e.id);
		end
		if(not GUI)then
			Script.ReloadScript("Scripts/Entities/Others/GUI.lua");
			System.LogAlways("no GUI Table, loading file...");
		end
		if (not GUI) then
			System.LogAlways("Error, still no GUI...");
			return;
		end
		GUI.Client = {ClCommunicate 				= function() end,};
		GUI.Server = {};
		function GUI.Server:SvCommunicate(m, v, w)
			System.LogAlways("$3-> "..tostring(m).." "..tostring(v).." "..tostring(w));
		end
		local params = {
			class = "GUI"; 
			name = "supercab_7ox";
			orientation = g_gameRules:GetAngles();
			position = g_gameRules:GetPos();
			properties = {
				bAdjustToTerrain = 1; 
			};
		};
		local communicator = nCX.Spawn(params);
		params.name= "supercab_7ox.2";
		local communicator2 = nCX.Spawn(params);
		if (communicator) then
			self.COMMUNICATOR=communicator;

			System.LogAlways("GUI "..communicator:GetName().." succesfully spawned!");
			
			local NetSetup = {
				Class = GUI,
				ClientMethods = {
					ClCommunicate				= { RELIABLE_ORDERED, NO_ATTACH, ENTITYID, STRING, VEC3  },
				},
				ServerMethods = {
					SvCommunicate				= { RELIABLE_ORDERED, NO_ATTACH, ENTITYID, STRING, VEC3 },
				},
				ServerProperties = {}
			};

			local ok = Net.Expose(NetSetup);
			if (ok) then
				System.LogAlways("Net-Exposed "..communicator:GetName().." succesfully!");
			else	
				System.LogAlways("Failed to Net-expose "..communicator:GetName());
			end
		else
			System.LogAlways("Failed to spawn GUI");
		end
		
	end,
	---------------------------
	--		OnShutdown		
	---------------------------	
	OnShutdown = function(self)
	
	end,

};