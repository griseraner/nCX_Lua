SoundSpot = {
	type = "Sound",

	Properties = {
		sndSource="",
		fVolume=1.0,
		InnerRadius=2,
		OuterRadius=10,
		bLoop=1,	-- Loop sound.
		bPlay=0,	-- Immidiatly start playing on spawn.
		bOnce=0,
		bEnabled=1,
		--bOcclusion=1,
		--bDirectional=0,
	},
	 
	started=0,
	Editor={
		Model="Editor/Objects/Sound.cgf",
		Icon="Sound.bmp",
	},
	bEnabled=1,
}

function SoundSpot:OnSpawn()
	self:SetFlags(ENTITY_FLAG_CLIENT_ONLY, 0);
end

----------------------------------------------------------------------------------------
function SoundSpot:OnSoundDone()
  self:ActivateOutput( "Done",true );
	--System.LogToConsole("Done sound "..self.Properties.sndSource);
end

----------------------------------------------------------------------------------------
function SoundSpot:OnSave(props)
	--WriteToStream(stm,self.Properties);
	props.started = self.started
	props.bEnabled = self.bEnabled
end

----------------------------------------------------------------------------------------
function SoundSpot:OnLoad(props)
	--self.Properties=ReadFromStream(stm);
	--self:OnReset();
	self.started = props.started
	self.bEnabled = props.bEnabled
	if ((self.started==1) and (self.Properties.bOnce~=1)) then
    self:Play();
	end	
end

----------------------------------------------------------------------------------------
function SoundSpot:OnPropertyChange()
	if (self.soundName ~= self.Properties.sndSource or 
	    self.Properties.bLoop ~= self.loop or
	    self.Properties.bPlay ~= self.started or
	    self.Properties.bEnable ~= self.bEnable) then
		--System.LogToConsole("Reset sound"..self.Properties.sndSource);
	  self:OnReset();		
	end
	
	if (self.volume ~= self.Properties.fVolume) then
	  Sound.SetSoundVolume(self.soundid, self.Properties.fVolume);
	  self.volume = self.Properties.fVolume;
	end
	
	if (self.InnerRadius ~= self.Properties.InnerRadius or
	    self.OuterRadius ~= self.Properties.OuterRadius) then
	  Sound.SetMinMaxDistance(self.soundid, self.Properties.InnerRadius, self.Properties.OuterRadius);
	  self.InnerRadius = self.Properties.InnerRadius;
	  self.OuterRadius = self.Properties.OuterRadius;
	end
	


end
----------------------------------------------------------------------------------------
function SoundSpot:OnReset()
	
	-- Set basic sound params.
	--System.LogToConsole("Reset SP");
	--System.LogToConsole("self.Properties.bPlay:"..self.Properties.bPlay..", self.started:"..self.started);
  	
  self.started = 0; -- [marco] fix playonce on reset for switch editor/game mode
	self.bEnabled = self.Properties.bEnabled;

	--if (self.Properties.bPlay == 0 and self.soundid ~= nil) then
		self:Stop();
	--end

	if (self.Properties.bPlay ~= 0) then -- and self.started == 0) then
		self:Play();
	end
	--self.Client:OnMove();


	--self.started = 0; -- [marco] fix playonce on reset for switch editor/game mode
end

----------------------------------------------------------------------------------------
SoundSpot["Server"] = {
	OnInit= function (self)
		self.started = 0;
		self:NetPresent(0);
	end,
	OnShutDown= function (self)
	end,
}

----------------------------------------------------------------------------------------
SoundSpot["Client"] = {
	----------------------------------------------------------------------------------------
	OnInit = function(self)
		--System.LogToConsole("OnInit");
		self.started = 0;
		self.loop = self.Properties.bLoop;
		self.soundName = "";
		self.soundid = nil;
		self:NetPresent(0);

		if (self.Properties.bPlay==1) then
			self:Play();
			--System.LogToConsole("Play sound"..self.Properties.sndSource);
		end
		--self.Client.OnMove(self);
	end,
	----------------------------------------------------------------------------------------
	OnShutDown = function(self)
		self:Stop();
	end,
	OnSoundDone = function(self)
	end,
	  --self:ActivateOutput( "Done",true );
	  --System.LogToConsole("Done sound"..self.Properties.soundName);
	--end,

}

----------------------------------------------------------------------------------------
function SoundSpot:Play()

	if (self.bEnabled == 0 ) then 
		do return end;
	end

  if (self.soundid ~= nil) then
		self:Stop(); -- entity proxy
	end

  local sndFlags = bor(SOUND_DEFAULT_3D,SOUND_RADIUS);

	if (self.Properties.bLoop ~=0 ) then
		sndFlags = bor(sndFlags, SOUND_LOOP);
	end;  
	self.loop = self.Properties.bLoop;
  
	self.soundid = self:PlaySoundEventEx(self.Properties.sndSource, sndFlags, self.Properties.fVolume, g_Vectors.v000, self.Properties.InnerRadius, self.Properties.OuterRadius, SOUND_SEMANTIC_SOUNDSPOT );
	self.soundName = self.Properties.sndSource;
	self.volume = self.Properties.fVolume;
	self.InnerRadius = self.Properties.InnerRadius;
	self.OuterRadius = self.Properties.OuterRadius;

	--System.LogToConsole( "Play Sound" );
	if (not self.soundid) then
	  self.started = 1;
	end;
	
end

----------------------------------------------------------------------------------------
function SoundSpot:Stop()

	--if (self.bEnabled == 0 ) then 
		--do return end;
	--end

	if (self.soundid ~= nil) then
		self:StopSound(self.soundid); -- stopping through entity proxy
		--System.LogToConsole( "Stop Sound" );
		self.soundid = nil;
	end
	self.started = 0;
end

----------------------------------------------------------------------------------------
function SoundSpot:Event_Play( sender )
	
	if (self.soundid ~= nil) then
		self:Stop();
	end
	--Log("Event_Play %d %d",self.Properties.bOnce, self.started)
	if(self.Properties.bOnce~=0 and self.started~=0) then
		return
	end
	self:Play();
	--BroadcastEvent( self,"Play" );
end

-------------------------------------------------------------------------------
-- Stop Event
-------------------------------------------------------------------------------
function SoundSpot:Event_Stop( sender, bStop )
	if (bStop == true) then
		self:Stop();
	end
	--BroadcastEvent( self,"Stop" );
end

function SoundSpot:Event_Enable( sender, bEnable )
	self.bEnabled = 1;
	--BroadcastEvent( self,"Stop" );
end

SoundSpot.FlowEvents =
{
	Inputs =
	{
		Play = { SoundSpot.Event_Play, "bool" },
		Stop = { SoundSpot.Event_Stop, "bool" },
		Enable = { SoundSpot.Event_Enable, "bool" },
	},
	Outputs =
	{
	  Done = "bool",
	},
}

