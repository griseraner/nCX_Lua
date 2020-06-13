-- ===============================================
-- Mathematical Utilities
-- ===============================================

CryMP.Math = {
	
	GetGroundLevel = function(self, pos)
		local z = System.GetTerrainElevation(pos);
		pos.z = pos.z - z;
		return pos;
	end,
	
	--[[SideSpace = function(self, space, text, right, char)
		if (space and text) then
			local space = tonumber(space);
			local text = tostring(text);
			local length = #string.gsub(text, "%$%d", "");
			if (length > space) then
				if (length ~= #text) then
					return text;
				end
				return string.sub(text, 1, space);
			end
			if (right) then
				return text..string.rep(char or " ", space - length);
			else
				return string.rep(char or " ", space - length)..text;
			end
		end
	end,
	
	MaxSpace = function(self, max, text, char)
		if (max and text) then
			local max = tonumber(max);
			local text = tostring(text);
			local char = char or " ";
			local length = #string.gsub(text, "%$%d", "");
			local check = (max - length) * 0.5;
			if (check == 0) then
				return text;
			elseif (check < 0) then
				if (length ~= #text) then
					return text;
				end
				return string.sub(text, 1, max);
			end
			return string.rep(char, math.ceil(check))..text..string.rep(char, math.floor(check));
		end
	end,]]

	GetServerUptime = function(self, tbl)
		local secsRaw = CryAction.GetServerTime();
		local seconds = math.floor(secsRaw);
		local minutes, secsRem = self:ConvertTime(seconds, 60);
		local hours, minsRem = self:ConvertTime(minutes, 60);
		local days, hoursRem = self:ConvertTime(hours, 24);
		if (days and hoursRem and minsRem and secsRem) then
			if (tbl) then
				return {days = days, hours = math:zero(hoursRem), minutes = math:zero(minsRem), seconds = math:zero(secsRem)};
			end
			return days, math:zero(hoursRem), math:zero(minsRem), math:zero(secsRem);
		end
	end,

	ConvertTime = function(self, units, total, tbl)
		units = math.floor(units);
		total = math.floor(total);
		if (units < total) then
			return 0, units;
		end
		if (units == 0) then
			return 0, 0;
		end
		local x = units % total;
		if (tbl) then
			return {((units-x)/total), x}
		end
		return ((units-x)/total), x;
	end,

	AddTimes = function(self, unit, add, cap, largerUnit)
		unit = unit + add;
		if (unit > cap) then
			unit = unit - cap;
			largerUnit = largerUnit + 1;
		end
		return unit, largerUnit
	end,

	MonthToDays = function(self, month, year)
		month = tonumber(month)
		if (not month or month == 1) then
			return 0;
		end
		local total = 0
		local function isleapyear()
			local y1 = tonumber(year or os.date("%Y"));
			if (y1 % 400 == 0) then
				return 29;
			elseif (y1 % 100 == 0) then
				return 28;
			elseif (y1 % 4 == 0) then
				return 29;
			else 
				return 28;
			end
		end
		local days = {31, isleapyear(), 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
		for i=1, (month-1) do
			total = total + (days[i] or 0);
		end
		return total;
	end,

	DaysAgo = function(self, date1, extended, console)
		local y1,m1,d1 = string.match(date1, "(%d%d%d%d)(%d%d)(%d%d)");
		if (not d1) then
			return extended and "Never" or 0;
		end
		local ago;
		local d2 = os.date("%j");
		local y2 = os.date("%Y");
		if (y2 > y1) then
			local tmp = tonumber(y2-y1);
			for i = 0, (tmp-1) do
				if (i == 0) then
					d1 = self:MonthToDays(13, y1) - self:MonthToDays(m1, y1) - d1;
				else
					d1 = d1 + self:MonthToDays(13, y1+i);
				end
			end
			ago = d1 + d2;
		else
			ago = d2 - (d1 + self:MonthToDays(m1, y1));
		end
		if (extended) then
			if (ago == 0) then
				return "Today";
			elseif (ago == 1) then
				return "Yesterday";
			end
			if (console) then
				return ago.." $9days ago";
			end
			return ago.." days ago";
		end
		return ago;
	end,
	
	Round = function(self, number, precision)
		if not (number and precision and tonumber(number) and tonumber(precision)) then
			return 0;
		end
		return math.floor(number*math.pow(10,precision)+0.5) / math.pow(10,precision)
	end,

	RemoveChar = function(self, msg, char)
        local char = char or "$";
        return string.gsub(msg, "%"..char.."%d", "")
    end,
	
	VectorToRadians = function(self, vector)
		if (vector.x and vector.y and vector.z) then
			-- format {x=424, y=24, z=243} 
			vector.x=math.rad(vector.x);
			vector.y=math.rad(vector.y);
			vector.z=math.rad(vector.z);
		else
			-- format {424, 24, 243} 
			for i=1, 3 do
				vector[i]=math.rad(vector[i]);
			end
		end
		return vector;
	end,
};
