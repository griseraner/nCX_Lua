ZoneOut = {

	Server = {
			
		OnNewMap = function(self, map, reboot, reload)
			if (map:lower() ~= "multiplayer/ps/mesa") then
				self:ShutDown(true);
				return;
			elseif (reload) then
				--return;
			end
			local params = {
				--BARRIERS
				["Flag"] = {
					{orientation = { x=0.829038, y=0.559193, z=0 }, position = { x=2884.33, y=2644.82, z=333.107 }, },
					{orientation = { x=-0.829038, y=-0.559193, z=0 }, position = { x=2887.29, y=2640.37, z=333.11 }, },
					{orientation = { x=0.5, y=-0.866026, z=0 }, position = { x=1452.41, y=3093.49, z=365.781 }, },
					{orientation = { x=-0.5, y=0.866025, z=0 }, position = { x=1447.77, y=3090.84, z=365.778 }, },
					{orientation = { x=0.190809, y=-0.981627, z=0 }, position = { x=2136.78, y=1411.48, z=420.923 }, },
					{orientation = { x=-0.190809, y=0.981627, z=0 }, position = { x=2131.53, y=1410.49, z=420.926 }, },
				},
				-- RIFLES
				["Rifles"] = {
					{orientation = { x=-0.559193, y=0.829038, z=-1.86695e-007 }, position = { x=2886.62, y=2641.59, z=333.304 }, },
					{orientation = { x=0.559193, y=-0.829038, z=-1.767e-007 }, position = { x=2885.17, y=2643.73, z=333.303 }, },
					{orientation = { x=-0.866026, y=-0.5, z=-3.25009e-007 }, position = { x=1451.15, y=3092.91, z=365.975 }, },
					{orientation = { x=0.866025, y=0.5, z=-6.66471e-007 }, position = { x=1448.91, y=3091.61, z=365.974 }, },
					{orientation = { x=-0.981627, y=-0.190809, z=-6.33666e-007 }, position = { x=2135.45, y=1411.13, z=421.118 }, },
					{orientation = { x=0.981627, y=0.190809, z=-1.29475e-007 }, position = { x=2132.91, y=1410.63, z=421.12 }, },
				},
				-- RPGS
				["LAW"] = {
					{orientation = { x=-0.840169, y=-0.540044, z=0.0496875 }, position = { x=2886.14, y=2642.66, z=333.318 }, },
					{orientation = { x=-0.840169, y=-0.540044, z=0.0496875 }, position = { x=2886, y=2642.88, z=333.318 }, },
					{orientation = { x=0.480121, y=-0.875794, z=0.0496875 }, position = { x=1449.82, y=3092.37, z=365.989 }, },
					{orientation = { x=0.480121, y=-0.875794, z=0.0496875 }, position = { x=1450.05, y=3092.5, z=365.989 }, },
					{orientation = { x=-0.168833, y=0.984391, z=0.0496875 }, position = { x=2134.34, y=1410.7, z=421.133 }, },
					{orientation = { x=-0.168833, y=0.984391, z=0.0496875 }, position = { x=2134.08, y=1410.66, z=421.133 }, },
				},
				-- SCOPES
				["Scopes"] = {
					{orientation = { x=-0.838671, y=-0.544639, z=0 }, position = { x=2887.18, y=2640.89, z=333.309 }, },
					{orientation = { x=-0.838671, y=-0.544639, z=0 }, position = { x=2887.08, y=2641.04, z=333.309 }, },
					{orientation = { x=-0.838671, y=-0.544639, z=0 }, position = { x=2887.13, y=2640.96, z=333.309 }, },
					{orientation = { x=-0.838671, y=-0.544639, z=0 }, position = { x=2884.74, y=2644.48, z=333.309 }, },
					{orientation = { x=-0.838671, y=-0.544639, z=0 }, position = { x=2884.79, y=2644.4, z=333.309 }, },
					{orientation = { x=-0.838671, y=-0.544639, z=0 }, position = { x=2884.84, y=2644.32, z=333.309 }, },
					{orientation = { x=0.48481, y=-0.87462, z=0 }, position = { x=1451.72, y=3093.32, z=365.98 }, },
					{orientation = { x=0.48481, y=-0.87462, z=0 }, position = { x=1448.21, y=3091.27, z=365.98 }, },
					{orientation = { x=0.48481, y=-0.87462, z=0 }, position = { x=1448.13, y=3091.23, z=365.98 }, },
					{orientation = { x=0.48481, y=-0.87462, z=0 }, position = { x=1448.05, y=3091.18, z=365.98 }, },
					{orientation = { x=0.48481, y=-0.87462, z=0 }, position = { x=1451.88, y=3093.41, z=365.98 }, },
					{orientation = { x=0.48481, y=-0.87462, z=0 }, position = { x=1451.8, y=3093.37, z=365.98 }, },
					{orientation = { x=-0.173648, y=0.984808, z=0 }, position = { x=2136.31, y=1411.24, z=421.125 }, },
					{orientation = { x=-0.173648, y=0.984808, z=0 }, position = { x=2136.22, y=1411.22, z=421.125 }, },
					{orientation = { x=-0.173648, y=0.984808, z=0 }, position = { x=2136.12, y=1411.21, z=421.125 }, },
					{orientation = { x=-0.173648, y=0.984808, z=0 }, position = { x=2131.96, y=1410.37, z=421.125 }, },
					{orientation = { x=-0.173648, y=0.984808, z=0 }, position = { x=2132.05, y=1410.39, z=421.125 }, },
					{orientation = { x=-0.173648, y=0.984808, z=0 }, position = { x=2132.14, y=1410.41, z=421.125 }, },
				},
			};
			for cl, tbl in pairs(params) do
				local c = 1;
				local class = cl;
				for i, p in pairs(tbl) do
					if (cl == "Rifles") then
						local tbl = {"DSG1", "GaussRifle",};
						c = c > #tbl and 1 or c;
						class = tbl[c];
					elseif (cl == "Scopes") then
						local tbl = {"SniperScope", "Silencer", "AssaultScope", "LAMRifle"};
						c = c > #tbl and 1 or c;
						class = tbl[c];
					end
					c = c + 1;
					local name = class.."_SZ"..i;
					if (System.GetEntityByName(name)) then
						return;
					end
					local param = {
						class = class,
						name = name,
						orientation = p.orientation,
						position = p.position,
						properties = {
							Paint = p.paint,
							Respawn = {
								bAbandon = 1,
								bRespawn = 1,
								bUnique = 1,
								nAbandonTimer = 45,
								nTimer = 45,
							},
						};
					};
					if (class == "Flag") then
						param.properties.Respawn.bAbandon = 0;
						param.properties.Respawn.bRespawn = 0;
					elseif (cl == "Scopes") then
						param.properties.Respawn.nTimer = 10;
					end
					System.SpawnEntity(param);
				end
			end
		end,
		
		OnConnect = function(self, channelId, actor, profileId, restart)
			local flags = {
				{orientation = { x=0.829038, y=0.559193, z=0 }, position = { x=2884.33, y=2644.82, z=333.107 }, },
				{orientation = { x=-0.829038, y=-0.559193, z=0 }, position = { x=2887.29, y=2640.37, z=333.11 }, },
				{orientation = { x=0.5, y=-0.866026, z=0 }, position = { x=1452.41, y=3093.49, z=365.781 }, },
				{orientation = { x=-0.5, y=0.866025, z=0 }, position = { x=1447.77, y=3090.84, z=365.778 }, },
				{orientation = { x=0.190809, y=-0.981627, z=0 }, position = { x=2136.78, y=1411.48, z=420.923 }, },
				{orientation = { x=-0.190809, y=0.981627, z=0 }, position = { x=2131.53, y=1410.49, z=420.926 }, },
			};
			for i, tbl in pairs(flags) do
				tbl.position.z = tbl.position.z - 1;
				--tbl.position.z = tbl.position.z + 10;
				nCX.ParticleManager("Alien_Environment.Scanner.red", 1, tbl.position, g_Vectors.up, channelId);
			end
		end,
	
	},
	
	Lights = function(self)
		local SZ1 = {x=2886.14, y=2642.66, z=333.318}; 
		local SZ2 = {x=1449.82, y=3092.37, z=365.989}; 
		local SZ3 = {x=2134.34, y=1410.7, z=421.133}; 
		nCX.ParticleManager("explosions.flare.night_time_selfillum", 1, SZ1, g_Vectors.up, 0);
		nCX.ParticleManager("explosions.flare.night_time_selfillum", 1, SZ2, g_Vectors.up, 0);
		nCX.ParticleManager("explosions.flare.night_time_selfillum", 1, SZ3, g_Vectors.up, 0);
	end,
	
};
