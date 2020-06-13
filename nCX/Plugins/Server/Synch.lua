Synch = {

	---------------------------
	--		Config
	---------------------------
	Required 	= true,
	Tick 		= 10,
	Check		= {
		{"Data_Users", "Users"},
		{"BanList", "BanSystem"},
		{"Data_Attach", "Attach"},
		{"Data_Reports", "Reports"},
	},
	Comparison = {},
	
	
	Server = {},
	
	OnInit = function(self)
		local n = 0;
		for i, info in pairs(self.Check) do
			local filename = info[1];
			local file = io.open(CryMP.Paths.GlobalData..filename..".lua", "r");
			if (file) then
				local size = file:seek("end");
				self.Comparison[filename] = size;
				file:close();
				n = n+1;
			end
		end
		local n = math:zero(n);
		self:Log("Added $1#$5"..n.."$9 files to synch");
		nCX.Log("Core", "Added "..n.." files to synch", true);
	end,
	
	OnChange = function(self, filename, newsize)--update database immediately to avoid updating file on local
		local file = io.open(CryMP.Paths.GlobalData..filename..".lua", "r");
		if (file) then
			System.LogAlways(file:seek("end")..", "..newsize);
			file:close();
		end		
		local ok = self.Comparison[filename];
		if (ok) then
			self.Comparison[filename] = newsize;
		end
	end,
	
	OnTick = function(self, players)--check for filechange from other server (global)
		for i, info in pairs(self.Check) do
			local filename, plugin = info[1], info[2];
			local file = io.open(CryMP.Paths.GlobalData..filename..".lua", "r");
			if (file) then
				local size = file:seek("end");
				file:close();
				local oldsize = self.Comparison[filename];
				if (size ~= oldsize) then
					CryMP[plugin]:OnInit(true);
					self.Comparison[filename] = size;
					local done = false;
					if (fileName == "BanList") then	
						local banlist = nCX.GetBanlist();
						local new = banlist and banlist[#banlist];
						if (new) then
							local bannedBy = new[7] or "nCX";
							local color = bannedBy == "nCX" and "$4" or "";
							self:Log("Loaded ban on "..new[1].." ("..new[2]..", "..new[4]..") by "..(color or "")..bannedBy, true);
							done = true;
						end
					end
					if (not done) then
						self:Log("Updated "..filename);
					end
					nCX.Log("Core", "Updated "..filename, true);
				end
			end
		end
	end,
	
};