--pin mixin
WorldQuestTrackerPathPinMixin = CreateFromMixins(MapCanvasPinMixin)
function WorldQuestTrackerPathPinMixin:OnLoad()
	self:UseFrameLevelType("PIN_FRAME_LEVEL_AREA_POI")
end
