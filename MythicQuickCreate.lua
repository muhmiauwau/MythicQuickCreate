local _, MythicQuickCreate = ...

local mplusObj = {}

local mapMap = {}
mapMap[1284] = 503
mapMap[1287] = 501
mapMap[1285] = 505
mapMap[713] = 376
mapMap[1290] = 507
mapMap[703] = 375
mapMap[1288] = 502

local englishFaction = UnitFactionGroup("player")
if englishFaction == "Alliance" then
	mapMap[534] = 353
else
	mapMap[659] = 353
end

local initialized = false

LFGListFrame.CategorySelection.StartGroupButton:HookScript("OnClick", function(self)
	if not initialized then
		MythicQuickCreate:Init()
		initialized = true
	end

	local panel = self:GetParent();
	if ( not panel.selectedCategory ) then
		return;
	end

	local baseFilters = panel:GetParent().baseFilters;
	if baseFilters == 4 and panel.selectedCategory == 2 and panel.selectedFilters == 0 then
		MythicQuickCreate:Show(panel)
	else
		MythicQuickCreate:Hide()
	end
end)



function MythicQuickCreate:Init()
	for key, id in pairs(mapMap) do
		local info = C_LFGList.GetActivityInfoTable(key)
		local texture = select(4, C_ChallengeMode.GetMapUIInfo(id))
		tinsert(mplusObj, {
			id = key,
			name = info.fullName,
			info = info,
			texture = texture
		})
	end

	table.sort(mplusObj, function(a, b) return a.name < b.name end)

	local f = CreateFrame("Frame", "MythicQuickCreateContent", LFGListFrame.EntryCreation)
	f:SetPoint("TOPLEFT", LFGListFrame.EntryCreation.Name, "BOTTOMLEFT", -5, -10)
	f:SetPoint("TOPRIGHT", LFGListFrame.EntryCreation.Name, "BOTTOMRIGHT", 0, -10 )
	f:SetHeight(32)

	MythicQuickCreate.DescriptionLabelPoint = { LFGListFrame.EntryCreation.DescriptionLabel:GetPoint() }
	MythicQuickCreate.DescriptionHeight = LFGListFrame.EntryCreation.Description:GetHeight()
	MythicQuickCreate.PlayStyleLabelPoint = { LFGListFrame.EntryCreation.PlayStyleLabel:GetPoint() }
	MythicQuickCreate:createDungeonsButtons()
end

function MythicQuickCreate:Show(panel)
	local children = MythicQuickCreateContent:GetChildren()
	if not children then
		MythicQuickCreate:Hide();
		return 
	 end
	-- reset frames
	table.foreach({children}, function(k,v)
		v.Glowborder:Hide()
		v.Text:SetText("")
	end)

	local activityID = C_LFGList.GetOwnedKeystoneActivityAndGroupAndLevel()
	if activityID then 
		LFGListEntryCreation_Select(LFGListFrame.EntryCreation, panel.selectedFilters, panel.selectedCategory, nil, activityID)
	end

	LFGListFrame.EntryCreation.DescriptionLabel:SetPoint("TOPLEFT",LFGListFrame.EntryCreation.NameLabel, "TOPLEFT",  0,-90)
	LFGListFrame.EntryCreation.Description:SetHeight(13)
	LFGListFrame.EntryCreation.PlayStyleLabel:SetPoint("TOPLEFT",LFGListFrame.EntryCreation.DescriptionLabel, "TOPLEFT", 0,-55)

	MythicQuickCreateContent:Show() 
end

function MythicQuickCreate:Hide()
	LFGListFrame.EntryCreation.DescriptionLabel:SetPoint("TOPLEFT",LFGListFrame.EntryCreation.NameLabel, "TOPLEFT",  MythicQuickCreate.DescriptionLabelPoint[4], MythicQuickCreate.DescriptionLabelPoint[5])
	LFGListFrame.EntryCreation.Description:SetHeight(MythicQuickCreate.DescriptionHeight)
	LFGListFrame.EntryCreation.PlayStyleLabel:SetPoint("TOPLEFT",LFGListFrame.EntryCreation.DescriptionLabel, "TOPLEFT", MythicQuickCreate.PlayStyleLabelPoint[4], MythicQuickCreate.PlayStyleLabelPoint[5])
	MythicQuickCreateContent:Hide() 
end

function MythicQuickCreate:createDungeonsButtons()
	local spacer = 4
	local amount = 8
	local width = MythicQuickCreateContent:GetWidth()
	local size = (width - ((amount - 1) * spacer)) / amount

	for index, dungeon in pairs(mplusObj) do
		local x = (index - 1) * (size + spacer)
		local f = CreateFrame("Button", "MythicQuickCreate" .. dungeon.id, MythicQuickCreateContent , "MythicQuickCreateButton")
		f:SetSize(size,size)
		f:SetPoint("TOPLEFT", x ,0)
		f.Texture:SetTexture(dungeon.texture)
		f.Text:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
		f:Show()

		f.name = dungeon.name
		f.id = dungeon.id
		f:CheckKeystone()
	end
end


MythicQuickCreateButtonMixin = {}

function MythicQuickCreateButtonMixin:OnShow()
	self:CheckKeystone()
end

function MythicQuickCreateButtonMixin:CheckKeystone()
	if not self.id then return end

	local activityID, _, keystoneLevel  = C_LFGList.GetOwnedKeystoneActivityAndGroupAndLevel()
	if not activityID then return nil end 
	
	local check = activityID == self.id
	self.Text:SetText(keystoneLevel)
	self.Glowborder:SetShown(check)
	self.Text:SetShown(check)
end

function MythicQuickCreateButtonMixin:OnClick(buttonName, down)
	if LFGListFrame.EntryCreation.Name:GetText():match( "^%s*(.-)%s*$" ) == "" then
		UIErrorsFrame:AddMessage("Name missing", RED_FONT_COLOR:GetRGBA());
		LFGListFrame.EntryCreation.Name:SetFocus()
	else
		LFGListFrame.EntryCreation.selectedActivity = self.id
		LFGListEntryCreation_Select(LFGListFrame.EntryCreation, nil, nil, nil, self.id)
		MythicQuickCreate.id = self.id
		LFGListEntryCreation_ListGroup(LFGListFrame.EntryCreation);
	end
end

function MythicQuickCreateButtonMixin:OnEnter()
	GameTooltip:SetOwner(MythicQuickCreateContent, "ANCHOR_BOTTOM");
	GameTooltip:ClearLines();
	GameTooltip:SetText(self.name, 1, 1, 1, 1, 1)
	GameTooltip:Show() 
end

function MythicQuickCreateButtonMixin:OnLeave()
	GameTooltip:Hide() 
end


function LFGListEntryCreation_SetTitleFromActivityInfo(self)
	-- keep this here to avoid error :(
end



--@do-not-package@
-- local dObj = {}
-- local mapChallengeModeIDs = C_ChallengeMode.GetMapTable()
-- table.foreach(mapChallengeModeIDs, function(index, mapID)
-- 	local mapInfo = table.pack(C_ChallengeMode.GetMapUIInfo(mapID))
-- 	tinsert(dObj, {
-- 		id =  mapInfo[2],
-- 		name = mapInfo[1],
-- 		mapInfo = mapInfo
-- 	})
-- end)

-- DevTool:AddData(dObj, "dObj")
--@end-do-not-package@
