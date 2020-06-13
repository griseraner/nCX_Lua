TagPoint = {
  type = "TagPoint",

	Editor={
		--Model="Editor/Objects/T.cgf",
		Icon="TagPoint.bmp",
	},
}

-------------------------------------------------------
function TagPoint:OnInit()
	AI.RegisterWithAI(self.id, AIOBJECT_WAYPOINT);
end