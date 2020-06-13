-- *****************************************************************
--        ####     ##  #####  ##   ##
--        ## ##    ## ##   ##  ## ##	Crysis Wars nCX
--        ##  ##   ## ##        ###
--        ##   ##  ## ##        ###      Author:   Arcziy
--        ##    ## ## ##   ##  ## ##     Version:  2.0 Public
--        ##     ####  #####  ##   ##    LastEdit: 2012-04-08
-- *****************************************************************

	if (not _G["avexplosive"]) then
		local explosive = {};
		function explosive:CanDisarm()
			return true;
		end
		_G["avexplosive"] = explosive;
	end
  
  if (not _G["c4explosive"]) then
		local explosive = {};
		function explosive:CanDisarm()
			return true;
		end
		_G["c4explosive"] = explosive;
	end
  
  if (not _G["claymoreexplosive"]) then
		local explosive = {};
		function explosive:CanDisarm()
			return true;
		end
		_G["claymoreexplosive"] = explosive;
	end