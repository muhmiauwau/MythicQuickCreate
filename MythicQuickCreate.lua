MythicQuickCreate = LibStub("AceAddon-3.0"):NewAddon("MythicQuickCreate");
local _ = LibStub("LibLodash-1"):Get()

local mplusObj = {}
local firstCall = true

local mapMap = {}
mapMap[1284] = 503
mapMap[1287] = 501
mapMap[659] = 353
mapMap[1284] = 505
mapMap[713] = 376
mapMap[1290] = 507
mapMap[703] = 375
mapMap[1288] = 502

function MythicQuickCreate:OnInitialize()

	table.foreach(C_LFGList.GetAvailableActivities(2), function(k, id)
		local info = C_LFGList.GetActivityInfoTable(id)
		if not info.isMythicPlusActivity then return end
		local mapID =  mapMap[id] or 503
		local texture= select(4, C_ChallengeMode.GetMapUIInfo(mapID)) 
		tinsert(mplusObj, {
			id = id,
			name = info.fullName,
			info = info,
			texture = texture
		})
	end)

	table.sort(mplusObj, function(a, b) return a.name < b.name end)

	local f = CreateFrame("Frame", "MythicQuickCreateContent", LFGListFrame.EntryCreation)
	f:SetPoint("TOPLEFT", LFGListFrame.EntryCreation.Name, "BOTTOMLEFT", -5, -10)
	f:SetPoint("TOPRIGHT", LFGListFrame.EntryCreation.Name, "BOTTOMRIGHT", 0, -10 )
	f:SetHeight(32)

	MythicQuickCreate.DescriptionLabelPoint = table.pack(LFGListFrame.EntryCreation.DescriptionLabel:GetPoint())
	MythicQuickCreate.DescriptionHeight = LFGListFrame.EntryCreation.Description:GetHeight()
	MythicQuickCreate.PlayStyleLabelPoint = table.pack(LFGListFrame.EntryCreation.PlayStyleLabel:GetPoint())

	LFGListFrame.CategorySelection.StartGroupButton:HookScript("OnClick", function(self) 
		if #mplusObj == 0 and firstCall then
			firstCall = false
			MythicQuickCreate:Hide()
			print("Mythic Quick Create: no dungeon configurated on the server")
			return 
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


	MythicQuickCreate:createDungeonsButtons()
end


function MythicQuickCreate:checkOwnedKeystone()
	local activityID, groupID, keystoneLevel  = C_LFGList.GetOwnedKeystoneActivityAndGroupAndLevel()
	if not activityID then return nil end 

	local f = _G["MythicQuickCreate" .. activityID]
	if not f then return end
	
	f.Glowborder:Show()
	f.Text:SetText(keystoneLevel)

	return activityID
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

	local keystoneId = MythicQuickCreate:checkOwnedKeystone()
	if MythicQuickCreate.id then 
		keystoneId = MythicQuickCreate.id
	end

	if keystoneId then 
		LFGListEntryCreation_Select(LFGListFrame.EntryCreation, panel.selectedFilters, panel.selectedCategory, nil, keystoneId)
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
	
	table.foreach(mplusObj, function(index, dungeon)
		local x = (index - 1) * (size + spacer)
		local f = CreateFrame("Button", "MythicQuickCreate" .. dungeon.id, MythicQuickCreateContent , "MythicQuickCreateButton")
		f:SetSize(size,size)
		f:SetPoint("TOPLEFT", x ,0)
		f.Texture:SetTexture(dungeon.texture)
		f.Text:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")

		f.name = dungeon.name
		f.id = dungeon.id
		f:Show()
	end)
end



MythicQuickCreateButtonMixin = {}
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
