HCDangerMap = {}
local DM=HCDangerMap

DM.VERSION="0.1.2"
DM.NAME="HC Danger Map"
DM.COLORED_NAME="|cffb8c0ccHC|r |cffa335eeDanger Map|r"
DM.MODULE="MAP"
DM.MAX_MARKERS=400
DM.MarkerTypes={"Death","Near-miss","Elite","Cave","Patrol","Hostile guard","Dangerous quest area","Other"}
DM.State={selectedId=nil,typeIndex=3,offset=0,currentOnly=1}

function DM:Trim(v,limit)
 v=tostring(v or"");v=string.gsub(v,"|c%x%x%x%x%x%x%x%x","");v=string.gsub(v,"|r","");v=string.gsub(v,"[\r\n]"," ");v=string.gsub(v,"%s+"," ");v=string.gsub(v,"^%s+","");v=string.gsub(v,"%s+$","");if limit and string.len(v)>limit then v=string.sub(v,1,limit)end;return v
end
function DM:Now()if type(time)=="function"then local n=tonumber(time());if n then return n end end;return math.floor(GetTime())end
function DM:GetLocation()return self:Trim(GetRealZoneText and GetRealZoneText()or GetZoneText and GetZoneText()or"Unknown",64),self:Trim(GetSubZoneText and GetSubZoneText()or"",64)end
function DM:GetCoordinates()
 if not GetPlayerMapPosition then return nil,nil end;if WorldMapFrame and WorldMapFrame:IsShown()then return nil,nil end;if SetMapToCurrentZone then SetMapToCurrentZone()end
 local x,y=GetPlayerMapPosition("player");x=tonumber(x);y=tonumber(y);if not x or not y or x<=0 or y<=0 or x>1 or y>1 then return nil,nil end;return math.floor(x*1000)/1000,math.floor(y*1000)/1000
end
function DM:InitializeDB()
 if type(HCDangerMapDB)~="table"then HCDangerMapDB={}end;if type(HCDangerMapDB.settings)~="table"then HCDangerMapDB.settings={}end;if type(HCDangerMapDB.markers)~="table"then HCDangerMapDB.markers={}end;if type(HCDangerMapDB.imports)~="table"then HCDangerMapDB.imports={}end
 local s=HCDangerMapDB.settings;if s.communitySync==nil then s.communitySync=nil end;if s.minimap==nil then s.minimap=1 end;if s.minimapAngle==nil then s.minimapAngle=-.6 end;if type(s.position)~="table"then s.position={point="CENTER",relPoint="CENTER",x=0,y=10}end
 HCDangerMapDB.schema=1;self.DB=HCDangerMapDB;self:PruneMarkers();self:ImportJournal()
end
function DM:ValidateType(value)local i;for i=1,table.getn(self.MarkerTypes)do if self.MarkerTypes[i]==value then return value end end;return nil end
function DM:MarkerKey(marker)
 local zone=string.lower(self:Trim(marker.zone,64));local kind=string.lower(self:Trim(marker.dangerType,32));local pos="zone"
 if marker.x and marker.y then pos=tostring(math.floor(marker.x*20))..":"..tostring(math.floor(marker.y*20))end
 return zone.."~"..kind.."~"..pos
end
function DM:FindMarkerByKey(key)local i;for i=1,table.getn(self.DB.markers)do if self.DB.markers[i].key==key then return self.DB.markers[i]end end;return nil end
function DM:AggregateMarker(data,source)
 if not self.DB or type(data)~="table"then return nil end;local kind=self:ValidateType(data.dangerType)or"Other";local zone=self:Trim(data.zone,64);if zone==""then return nil end
 local x=tonumber(data.x);local y=tonumber(data.y);if not x or not y or x<=0 or y<=0 or x>1 or y>1 then x=nil;y=nil end
 local low=tonumber(data.levelLow or data.level)or 0;local high=tonumber(data.levelHigh or data.level)or low;if low<0 then low=0 end;if high<low then high=low end;if high>255 then high=255 end
 local temp={zone=zone,dangerType=kind,x=x,y=y};local key=self:MarkerKey(temp);local marker=self:FindMarkerByKey(key);local now=tonumber(data.timestamp)or self:Now();if now>self:Now()+300 then now=self:Now()end;if now<self:Now()-7776000 then now=self:Now()-7776000 end
 if marker then marker.sources=marker.sources or{};marker.observations=(tonumber(marker.observations)or 1)+1;if now>(marker.lastSeen or 0)then marker.lastSeen=now end;if low>0 and(marker.levelLow==0 or low<marker.levelLow)then marker.levelLow=low end;if high>(marker.levelHigh or 0)then marker.levelHigh=high end;if data.note and data.note~=""then marker.note=self:Trim(data.note,100)end;marker.sources[source or"local"]=(marker.sources[source or"local"]or 0)+1
 else marker={id=tostring(self:Now()).."-"..tostring(math.floor(GetTime()*100)).."-"..tostring(table.getn(self.DB.markers)+1),key=key,zone=zone,subzone=self:Trim(data.subzone,64),x=x,y=y,dangerType=kind,levelLow=low,levelHigh=high,note=self:Trim(data.note,100),observations=1,firstSeen=now,lastSeen=now,sources={}};marker.sources[source or"local"]=1;table.insert(self.DB.markers,1,marker)end
 self:PruneMarkers();if self.RefreshUI then self:RefreshUI()end;return marker
end
function DM:GetConfidence(marker)
 local age=(self:Now()-(marker.lastSeen or self:Now()))/86400;if age<0 then age=0 end;local score=20+((marker.observations or 1)*12)-(age*2);if marker.x then score=score+8 end;if score<5 then score=5 end;if score>100 then score=100 end;return math.floor(score)
end
function DM:PruneMarkers()
 if not self.DB then return end;local now=self:Now();local i
 for i=table.getn(self.DB.markers),1,-1 do local m=self.DB.markers[i];local maxAge=7776000;if m.sources and m.sources.community and not m.sources.manual and not m.sources.journal then maxAge=2592000 end;if now-(m.lastSeen or now)>maxAge then table.remove(self.DB.markers,i)end end
 while table.getn(self.DB.markers)>self.MAX_MARKERS do local oldest=1;for i=2,table.getn(self.DB.markers)do if(self.DB.markers[i].lastSeen or 0)<(self.DB.markers[oldest].lastSeen or 0)then oldest=i end end;table.remove(self.DB.markers,oldest)end
end
function DM:ImportJournal()
 if type(HCDangerJournalAPI)~="table"or type(HCDangerJournalAPI.GetEntries)~="function"then return end;local entries=HCDangerJournalAPI.GetEntries()or{};local i;local imported=0
 for i=1,table.getn(entries)do local e=entries[i];if e.id and not self.DB.imports[e.id]and imported<100 then local kind=e.kind=="near-miss"and"Near-miss"or self:MapJournalType(e.kind);self:AggregateMarker({zone=e.zone,subzone=e.subzone,x=e.x,y=e.y,dangerType=kind,level=e.level,note=e.note~=""and e.note or e.enemies,timestamp=e.timestamp},"journal");self.DB.imports[e.id]=self:Now();imported=imported+1 end end
 local id,at;for id,at in pairs(self.DB.imports)do if self:Now()-(at or 0)>15552000 then self.DB.imports[id]=nil end end
end
function DM:MapJournalType(kind)
 if kind=="dangerous cave"then return"Cave"elseif kind=="elite encounter"then return"Elite"elseif kind=="hostile guard"then return"Hostile guard"elseif kind=="near-miss"then return"Near-miss"end;return"Other"
end
function DM:AddManual(kind,note,share)
 local zone,sub=self:GetLocation();local x,y=self:GetCoordinates();local level=tonumber(UnitLevel("player"))or 0;local marker=self:AggregateMarker({zone=zone,subzone=sub,x=x,y=y,dangerType=kind,level=level,note=note,timestamp=self:Now()},"manual");self.State.selectedId=marker and marker.id or nil;if share and marker then self:BroadcastMarker(marker)end;self:Print("local "..tostring(kind).." marker added"..(x and" with coordinates."or" as zone-only fallback."));return marker
end
function DM:ParseHardcoreDeath(message,eventName,sender)
 if eventName=="CHAT_MSG_HARDCORE"and sender and sender~=""and string.lower(sender)~="system"then return nil end;local text=self:Trim(message,220);if not string.find(string.lower(text),"a tragedy has occurred",1,1)then return nil end
 local _,_,name,level=string.find(text,"Hardcore character%s+(%S+)%s+%(level%s+(%d+)%)");local _,_,killer,killerLevel,zone=string.find(text,"has fallen to%s+(.-)%s+%(level%s+([^%)]+)%)%s+in%s+(.-)%.");if not killer then _,_,killer,zone=string.find(text,"has fallen to%s+(.-)%s+in%s+(.-)%.")end;if not name or not zone then return nil end
 return self:AggregateMarker({zone=zone,dangerType="Death",level=tonumber(level),note="Fatal encounter: "..self:Trim(killer or"Unknown",55),timestamp=self:Now()},"death-announcement")
end
function DM:GetBeaconMarkers()
 local result={};if type(HCRescueBeaconAPI)~="table"or type(HCRescueBeaconAPI.GetActiveBeacons)~="function"then return result end;local list=HCRescueBeaconAPI.GetActiveBeacons()or{};local i
 for i=1,table.getn(list)do local b=list[i];table.insert(result,{id="beacon:"..b.id,zone=b.zone,subzone=b.subzone,x=b.x,y=b.y,dangerType="Beacon: "..(b.dangerType or"SOS"),levelLow=b.level,levelHigh=b.level,note=(b.owner or"Unknown")..": "..(b.message or""),observations=1,lastSeen=b.createdAt,expiresAt=b.expiresAt,confidence=100,transient=1})end;return result
end
function DM:GetVisibleMarkers()
 local list={};local current=GetRealZoneText and GetRealZoneText()or"";local i
 for i=1,table.getn(self.DB.markers)do local m=self.DB.markers[i];if not self.State.currentOnly or m.zone==current then table.insert(list,m)end end
 local beacons=self:GetBeaconMarkers();for i=1,table.getn(beacons)do if not self.State.currentOnly or beacons[i].zone==current then table.insert(list,beacons[i])end end
 table.sort(list,function(a,b)local ac=a.confidence or DM:GetConfidence(a);local bc=b.confidence or DM:GetConfidence(b);if ac~=bc then return ac>bc end;return(a.lastSeen or 0)>(b.lastSeen or 0)end);return list
end
function DM:SubmitLocalEvent(eventData,share)
 local mapped=eventData.dangerType=="near-miss"and"Near-miss"or self:MapJournalType(eventData.dangerType);local marker=self:AggregateMarker({zone=eventData.zone,subzone=eventData.subzone,x=eventData.x,y=eventData.y,dangerType=mapped,level=eventData.level,note=eventData.note,timestamp=eventData.timestamp},eventData.source or"journal");if share and marker then self:BroadcastMarker(marker)end;return marker
end
function DM:ShareSelected()local list=self:GetVisibleMarkers();local marker=nil;local i;for i=1,table.getn(list)do if list[i].id==self.State.selectedId then marker=list[i]end end;if not marker or marker.transient then self:Print("select a persistent marker first.");return end;self:BroadcastMarker(marker)end
function DM:SavePosition(f)local p,rel,rp,x,y=f:GetPoint();self.DB.settings.position={point=p or"CENTER",relPoint=rp or"CENTER",x=x or 0,y=y or 0}end
function DM:Print(v)if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(self.COLORED_NAME..": "..tostring(v))end end
function DM:OnEvent(eventName,one,two,nine)
 if eventName=="VARIABLES_LOADED"then self:InitializeDB();self:InitializeNetwork();self:RestoreUISettings()
 elseif eventName=="PLAYER_ENTERING_WORLD"then if not self.loaded then self.loaded=1;self:Print("loaded. Community sync is OFF by default; type |cffffffff/hcdm|r.")end;self:ImportJournal();if self.DB.settings.communitySync then self:JoinNetwork()end;self:RefreshUI()
 elseif eventName=="ZONE_CHANGED_NEW_AREA"or eventName=="ZONE_CHANGED"then self:RefreshUI()
 elseif eventName=="CHAT_MSG_SYSTEM"or eventName=="CHAT_MSG_HARDCORE"then self:ParseHardcoreDeath(one,eventName,two)
 elseif eventName=="CHAT_MSG_CHANNEL"then self:NetworkChat(one,two,nine)
 elseif eventName=="CHAT_MSG_CHANNEL_NOTICE"then self:NetworkNotice(one,nine)end
end
HCDangerMapAPI={}
function HCDangerMapAPI.SubmitLocalEvent(eventData,share)return DM:SubmitLocalEvent(eventData,share)end
