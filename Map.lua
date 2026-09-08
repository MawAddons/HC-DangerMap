local DM=HCDangerMap
DM.PinColors={Death={1,.1,.1},["Near-miss"]={1,.6,.1},Elite={.75,.25,1},Cave={.6,.45,.25},Patrol={1,.75,.2},["Hostile guard"]={1,.3,.15},["Dangerous quest area"]={.9,.55,.15},Other={.7,.7,.7}}

function DM:GetCurrentZonePins()
 local pins={};local zone=GetRealZoneText and GetRealZoneText()or"";local list=self:GetVisibleMarkers();local i
 for i=1,table.getn(list)do local m=list[i];if m.zone==zone and m.x and m.y then table.insert(pins,m)end end
 return pins
end

function DM:RefreshMapPins()
 if not self.Frames or not self.Frames.mapPins then return end;local zone=GetRealZoneText and GetRealZoneText()or"";local pins=self:GetCurrentZonePins();local i
 for i=1,20 do local button=self.Frames.mapPins[i];local marker=pins[i];if marker then local color=self.PinColors[marker.dangerType]or(marker.transient and{.2,.8,1})or self.PinColors.Other;button.marker=marker;button.dot:SetVertexColor(color[1],color[2],color[3]);button:ClearAllPoints();button:SetPoint("CENTER",self.Frames.mapCanvas,"TOPLEFT",marker.x*self.Frames.mapWidth,-marker.y*self.Frames.mapHeight);button:Show()else button.marker=nil;button:Hide()end end
 self.Frames.mapCaption:SetText(zone~=""and(zone.." - "..table.getn(pins).." positioned pin(s); zone-only events remain in the list")or"Current zone unavailable")
end
