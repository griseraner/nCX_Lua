-- *****************************************************************
--        ####     ##  #####  ##   ##
--        ## ##    ## ##   ##  ## ##	Crysis Wars nCX
--        ##  ##   ## ##        ###
--        ##   ##  ## ##        ###      Author:   ctaoistrach
--        ##    ## ## ##   ##  ## ##     Version:  2.0 Public
--        ##     ####  #####  ##   ##    LastEdit: 2013-04-17
-- *****************************************************************
local NewString = {
	---------------------------
	--    lspace
	---------------------------
	lspace = function(self, space, text, char)
		text = tostring(text);
		local length = #self.gsub(text, "%$%d", "");
		if (length > space) then
			if (length ~= #text) then
				return text;
			end
			return self.sub(text, 1, space);
		end
		return self.rep(char or " ", space - length)..text;
	end,
	---------------------------
	--    rspace
	---------------------------
	rspace = function(self, space, text, char)
		text = tostring(text);
		local length = #self.gsub(text, "%$%d", "");
		if (length > space) then
			if (length ~= #text) then
				return text;
			end
			return self.sub(text, 1, space);
		end
		return text..string.rep(char or " ", space - length);
	end,
	---------------------------
	--    mspace
	---------------------------
	mspace = function(self, max, text, char)
		text = tostring(text);
		local length = #self.gsub(text, "%$%d", "");
		local check = (max - length) * 0.5;
		if (check == 0) then
			return text;
		elseif (check < 0) then
			if (length ~= #text) then
				return text;
			end
			return self.sub(text, 1, max);
		end
		local char = char or " ";
		return self.rep(char, math.ceil(check))..text..self.rep(char, math.floor(check));
	end,
	sub = new(string.sub);
	upper = new(string.upper);
	len = new(string.len);
	gfind = new(string.gfind);
	rep = new(string.rep);
	find = new(string.find);
	match = new(string.match);
	--char = new(string.char);
	dump = new(string.dump);
	gmatch = new(string.gmatch);
	reverse = new(string.reverse);
	format = new(string.format);
	gsub = new(string.gsub);
	lower = new(string.lower);
};

string = new(NewString);


