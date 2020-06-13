Dialog = {
	type = "Sound",

	Properties = {
		soundName="",
		bPlay=0,	-- Immidiatly start playing on spawn.
		bOnce=0,
		bEnabled=1,
		bAllowRadioOverDistance=0,
		bIgnoreCulling=0,
		bIgnoreObstruction=0,
	},
	
	started=0,
	Editor={
		Model="Editor/Objects/Sound.cgf",
		Icon="Dialog.bmp",
	},
	bEnabled=1,
}

function Dialog:OnSpawn()
	--self:SetFlags(ENTITY_FLAG_CLIENT_ONLY, 0);
	Sound.Precache(self.Properties.soundName, 0);
end

function Dialog:OnSave(save)
	--WriteToStream(stm,self.Properties);
	save.started = self.started
	save.bEnabled = self.bEnabled
	save.bIgnoreCulling = self.Properties.bIgnoreCulling;
	save.bIgnoreObstruction = self.Properties.bIgnoreObstruction;
end

function Dialog:OnLoad(load)
	--self.Properties=ReadFromStream(stm);
	--self:OnReset();
	self.started = load.started
	self.bEnabled = load.bEnabled
	self.Properties.bIgnoreCulling = load.bIgnoreCulling;
	self.Properties.bIgnoreObstruction = load.bIgnoreObstruction;
	
	if ((self.started==1) and (self.Properties.bOnce~=1)) then
    self:Play();
	end	
end

----------------------------------------------------------------------------------------
function Dialog:OnPropertyChange()
	-- all changes need a complete reset
	self:OnReset();
		
end
----------------------------------------------------------------------------------------
function Dialog:OnReset()
	
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
Dialog["Server"] = {
	OnInit= function (self)
		self.started = 0;
		self:NetPresent(0);
	end,
	OnShutDown= function (self)
	end,
}

----------------------------------------------------------------------------------------
Dialog["Client"] = {
	----------------------------------------------------------------------------------------
	OnInit = function(self)
		--System.LogToConsole("OnInit");
		self.started = 0;
		--self.loop = self.Properties.bLoop;
		self.soundName = "";
		self.soundid = nil;
		self:NetPresent(0);

		if (self.Properties.bPlay==1) then
			self:Play();
			--System.LogToConsole("Play sound"..self.Properties.soundName);
		end
		--self.Client.OnMove(self);
	end,
	----------------------------------------------------------------------------------------
	OnShutDown = function(self)
		self:Stop();
	end,
	OnSoundDone = function(self)
	  self:ActivateOutput( "Done",true );
	  --System.LogToConsole("Done sound "..self.Properties.soundName);
	end,
}

----------------------------------------------------------------------------------------
function Dialog:Play()

	if (self.bEnabled == 0 ) then 
		do return end;
	end

  if (self.soundid ~= nil) then
		self:Stop(); -- entity proxy
	end

	local sndFlags = bor(SOUND_EVENT, SOUND_VOICE);
	--if (self.Properties.bLoop ~=0 ) then
		--sndFlags = bor(sndFlags, SOUND_LOOP);
	--end;  
  
  if (self.Properties.bIgnoreCulling == 0) then
	  sndFlags = bor(sndFlags, SOUND_CULLING);
	end;  

	if (self.Properties.bIgnoreObstruction == 0) then
	  sndFlags = bor(sndFlags, SOUND_OBSTRUCTION);
	end;  
	
  
	self.soundid = self:PlaySoundEvent(self.Properties.soundName, g_Vectors.v000, g_Vectors.v010, sndFlags, SOUND_SEMANTIC_DIALOG);
	self.soundName = self.Properties.soundName;

	--System.LogToConsole( "Play Sound" );
	if (not self.soundid) then
	  self.started = 1;
	end;
	
end

----------------------------------------------------------------------------------------
function Dialog:Stop()

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
function Dialog:Event_Play( sender )
	
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

------------------------------------------------------------------------------------------------------
-- Event Handlers
------------------------------------------------------------------------------------------------------

function Dialog:Event_SoundName( sender, sSoundName )
  self.Properties.soundName = sSoundname;
  --BroadcastEvent( self,"SoundName" );
  self:OnPropertyChange();
end

function Dialog:Event_Enable( sender, bEnable )
  self.Properties.bEnabled = bEnable;
  --BroadcastEvent( self,"Enable" );
  self:OnPropertyChange();
end


function Dialog:Event_Stop( sender, bStop )
	if (bStop == true) then
		self:Stop();
	end
	--BroadcastEvent( self,"Stop" );
end

function Dialog:Event_Once( sender, bOnce )
	if (bOnce == true) then
		self.Properties.bOnce = 1;
	else
	  self.Properties.bOnce = 0;
	end
	--BroadcastEvent( self,"Once" );
end


Dialog.FlowEvents =
{
	Inputs =
	{
	  SoundName = { Dialog.Event_SoundName, "string" },
		Enable = { Dialog.Event_Enable, "bool" },
		Play = { Dialog.Event_Play, "bool" },
		Stop = { Dialog.Event_Stop, "bool" },
		Once = { Dialog.Event_Once, "bool" },
	},
	Outputs =
	{
	  Done = "bool",
	},
}


