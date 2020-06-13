IntegrityService = {

	Properties = {
	
	},
	Editor={
		
	},
	Server = {
		SvOnReceiveMessage = function(self, id, msgType, msg)
			System.LogAlways("SvOnReceiveMessage");
		end,
		
		SvCheckSignature = function(self, id, signature, a1, a2, length)
			System.LogAlways("SvCheckSignature");
		end,
	},
	Client = {
		ClOnReceiveMessage = function(self, id,msgType,msg)
			System.LogAlways("ClOnReceiveMessage");
		end,
		
		ClRequestSignature = function(self, id, nonce, a1, a2, length)
			System.LogAlways("ClRequestSignature");
			
			self.server:SvCheckSignature(id, "nooooob", a1, a2, length)
		end,
	},
	---------------------------
	--		OnInit
	---------------------------		
	OnInit = function(self)
		System.LogAlways(self:GetName().." OnInit");
	end,
	---------------------------
	--	OnPostInitClient
	---------------------------
	OnPostInitClient = function(self, channelId)
		System.LogAlways(self:GetName().." OnPostInitClient "..channelId);
		
		self.onClient:ClRequestSignature(channelId, "yes", "nob", "hey", "yo", "lol");
	end,
	
};

Net.Expose {
	Class = IntegrityService,
	ClientMethods = {
		ClOnReceiveMessage					= { RELIABLE_UNORDERED, NO_ATTACH, STRING, STRING, STRING },
		ClRequestSignature					= { RELIABLE_UNORDERED, NO_ATTACH, STRING, STRING, STRING, STRING, STRING},
	},
	
	ServerMethods = {
		SvOnReceiveMessage		 			= { RELIABLE_UNORDERED, NO_ATTACH, STRING, STRING, STRING },
		SvCheckSignature					= { RELIABLE_UNORDERED, NO_ATTACH, STRING, STRING, STRING, STRING, STRING},
	},
	ServerProperties = {
	}
};