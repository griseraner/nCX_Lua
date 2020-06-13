-- *****************************************************************
--        ####     ##  #####  ##   ##
--        ## ##    ## ##   ##  ## ##	Crysis Wars nCX
--        ##  ##   ## ##        ###
--        ##   ##  ## ##        ###      Author:   Arcziy
--        ##    ## ## ##   ##  ## ##     Version:  2.0 Public
--        ##     ####  #####  ##   ##    LastEdit: 2012-04-09
-- *****************************************************************
--Script.ReloadScript("Server/nCX/Variables.lua");
g_SignalData_point = {x=0,y=0,z=0};
g_SignalData_point2 = {x=0,y=0,z=0};
g_SignalData = {
	point = g_SignalData_point,
	point2 = g_SignalData_point2,
	ObjectName = "",
	id = NULL_ENTITY,
	fValue = 0,
	iValue = 0,
	iValue2 = 0,
};

g_StringTemp1 = "                                            ";
g_HitTable = {{},{},{},{},{},{},{},{},{},{},}

function new(_obj, norecurse)
	if (type(_obj) == "table") then
		local _newobj = {};
		if (norecurse) then
			for i,f in pairs(_obj) do
				_newobj[i] = f;
			end
		else
			for i,f in pairs(_obj) do
				if ((type(f) == "table") and (_obj~=f)) then
					_newobj[i] = new(f);
				else
					_newobj[i] = f;
				end
			end
		end
		return _newobj;
	else
		return _obj;
	end
end

function merge(dst, src, recurse)
	for i,v in pairs(src) do
		if (type(v) ~= "function") then
			if(recurse) then
				if((type(v) == "table") and (v ~= src))then
					if (not dst[i]) then
						dst[i] = {};
					end
					merge(dst[i], v, recurse);
				elseif (not dst[i]) then
					dst[i] = v;
				end
			elseif (not dst[i]) then
				dst[i] = v;
			end
		end
	end
	return dst;
end

function mergef(dst, src, recursive)
	for i,v in pairs(src) do
		if (recursive) then
			if((type(v) == "table") and (v ~= src))then
				if (not dst[i]) then
					dst[i] = {};
				end
				mergef(dst[i], v, recursive);
			elseif (not dst[i]) then
				dst[i] = v;
			end
		elseif (not dst[i]) then
			dst[i] = v;
		end
	end
	return dst;
end

Script.ReloadScript("Server/Lua-Files/Utils/Math.lua");
Script.ReloadScript("Server/Lua-Files/Utils/String.lua");
Script.ReloadScript("Server/Lua-Files/Utils/EntityUtils.lua");

Script.ReloadScript("scripts/physics.lua");
--Script.ReloadScript("scripts/Tweaks.lua");

--Script.ReloadScript("Server/Lua-Files/Utils/ZeroG.lua");
Script.ReloadScript("Server/Lua-Files/Items/ItemSystemMath.lua");

--Sound.Precache("Sounds/physics:bullet_impact:mat_grass", SOUND_PRECACHE_LOAD_SOUND);
--Sound.Precache("Sounds/physics:footstep_walk:mat_grass", SOUND_PRECACHE_LOAD_SOUND);
--Sound.Precache("Sounds/physics:mat_metal_sheet:mat_dirt", SOUND_PRECACHE_LOAD_SOUND);

function myUnpack(tbl)
    if (type(tbl) ~= "table") then
        return ""
    end
    local ret = ""
    for k, v in pairs(tbl) do
        if (tostring(v) ~= "") then
            ret = ret.. tostring(k).. "=".. tostring(v).. ", ";
        end
    end
    return string.gsub(ret, ", $", "");
end

function hook()
    local info = debug.getinfo(2)
    if (info ~= nil and info.what == "Lua") then
		local name = (info.name and info.name.." ") or "";
		System.LogAlways(name..tostring(debug.traceback()));
		local i, variables = 1, {""};
        while true do
            local name, value = debug.getlocal(2, i);
            if (name == nil) then
                break;
            end
            if (name ~= "(*temporary)") then
                variables[tostring(name)] = value
            end
            i = i + 1
        end
        System.LogAlways("  "..info.short_src..":"..info.currentline..": "..(info.name or "unknown").."("..myUnpack(variables)..")");
    end
end

--debug.sethook(hook, "c");