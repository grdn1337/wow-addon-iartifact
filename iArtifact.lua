-----------------------------------
-- Setting up scope, upvalues and libs
-----------------------------------

local AddonName, iArtifact = ...;
LibStub("AceEvent-3.0"):Embed(iArtifact);

--local L = LibStub("AceLocale-3.0"):GetLocale(AddonName);

local _G = _G;
local format = _G.string.format;

local LibCrayon = LibStub("LibCrayon-3.0");

-------------------------------
-- Registering with iLib
-------------------------------

LibStub("iLib"):Register(AddonName, nil, iArtifact);

------------------------------------------
-- Variables, functions and colors
------------------------------------------
--[[
local CharName = _G.GetUnitName("player", false); -- The charname doesn't change during a session. To prevent calling the function more than once, we simply store the name.

local COLOR_GOLD = "|cfffed100%s|r";
local COLOR_RED  = "|cffff0000%s|r";
local COLOR_GREEN= "|cff00ff00%s|r";

local COLOR_ATWAR= "|TInterface\\PVPFrame\\Icon-Combat:14:14|t |cffff0000%s|r";

local BONUSREP_POSSIBLE = "|TInterface\\Common\\ReputationStar:14:14:0:0:32:32:17:32:1:16|t %s";
local BONUSREP_ACTIVE = "|TInterface\\Common\\ReputationStar:14:14:0:0:32:32:1:16:1:16|t %s";
local BONUSREP_ACCOUNT = "|TInterface\\Common\\ReputationStar:14:14:0:0:32:32:17:32:17:32|t %s";

local function get_perc(earned, barMin, barMax, isFriendship)
	local perc;
	if( isFriendship ) then
		perc = _G.math.min(earned / barMax * 100, 100);
	else
		perc = _G.math.min((earned - barMin) / (barMax - barMin) * 100, 100);
	end
	
	if( perc >= 99.01 ) then
		perc = 100;
	end
	return perc;
end

local function get_label(earned, barMin, barMax, isFriendship)
	if( isFriendship ) then
		return ("%s / %s"):format(_G.BreakUpLargeNumbers(earned), _G.BreakUpLargeNumbers(barMax));
	else
		return ("%s / %s"):format(_G.BreakUpLargeNumbers(earned - barMin), _G.BreakUpLargeNumbers(barMax - barMin));
	end
end
--]]

local CurrentPower = 0;
local MaximumPower = 0;

-----------------------------
-- Setting up the LDB
-----------------------------

iArtifact.ldb = LibStub("LibDataBroker-1.1"):NewDataObject(AddonName, {
	type = "data source",
	text = AddonName,
	icon = "Interface\\Addons\\iArtifact\\Images\\iArtifact",
});

iArtifact.ldb.OnEnter = function(anchor)
	if( iArtifact:IsTooltip("Main") ) then
		return;
	end
	iArtifact:HideAllTooltips();
	
	local tip = iArtifact:GetTooltip("Main", "UpdateTooltip");
	tip:SmartAnchorTo(anchor);
	tip:SetAutoHideDelay(0.25, anchor);
	tip:Show();
end

iArtifact.ldb.OnLeave = function() end -- some display addons refuse to display brokers when this is not defined

----------------------
-- Initializing
----------------------

function iArtifact:Boot()
	-- self.db = LibStub("AceDB-3.0"):New("iReputationDB", {realm={today="",chars={}}}, true).realm;
	
	-- if( not self.db.chars[CharName] ) then
	-- 	self.db.chars[CharName] = {};
	-- end
	
	-- local c = self.db.chars[CharName];
	-- local today = date("%y-%m-%d");
	
	-- if( today ~= self.db.today ) then
	-- 	self.db.today = today;
		
	-- 	for k, v in pairs(self.db.chars) do
	-- 		for k2, v2 in pairs(v) do
	-- 			v2.changed = 0;
	-- 		end
	-- 	end
	--end
	
	--self:UpdateFactions();
	--self:RegisterEvent("UPDATE_FACTION", "UpdateFactions");

	self:RegisterEvent("ARTIFACT_XP_UPDATE", "UpdateData");
	self:RegisterEvent("AZERITE_ITEM_EXPERIENCE_CHANGED", "UpdateData");
	--self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", "UpdateData");

	self:UpdateData();
end
iArtifact:RegisterEvent("PLAYER_ENTERING_WORLD", "Boot");

------------------------------------------
-- UpdateArtifact
------------------------------------------

local function get_perc(a, x)
	if( x and x > 0 ) then
		return a / x * 100;
	end

	return 0;
end

local function get_label(noColor)
	local percent = get_perc(CurrentPower, MaximumPower);

	if( noColor ) then
		return ("%s/%s %d%%"):format(_G.BreakUpLargeNumbers(CurrentPower), _G.BreakUpLargeNumbers(MaximumPower), percent);
	end

	return ("%s/%s |cff%s%d%%|r"):format(_G.BreakUpLargeNumbers(CurrentPower), _G.BreakUpLargeNumbers(MaximumPower), LibCrayon:GetThresholdHexColor(percent, 100), percent);
end

function iArtifact:UpdateData()
	-- get current power
	local azeriteItemLocation = _G.C_AzeriteItem.FindActiveAzeriteItem();
	if( azeriteItemLocation ) then
		CurrentPower, MaximumPower = _G.C_AzeriteItem.GetAzeriteItemXPInfo(azeriteItemLocation);
	else
		CurrentPower, MaximumPower = nil, nil;
	end

	-- update text
	if( CurrentPower and MaximumPower ) then
		self.ldb.text = get_label();
	else
		self.ldb.text = AddonName;
	end
end

------------------------------------------
-- Custom Cell Provider - LibQTip
------------------------------------------

local cell_provider, cell_prototype = LibStub("LibQTip-1.0"):CreateCellProvider();

function cell_prototype:InitializeCell()
	local bar = self:CreateTexture(nil, "ARTWORK", self);
	self.bar = bar;
	bar:SetWidth(200);
	bar:SetHeight(14);
	bar:SetPoint("LEFT", self, "LEFT", 1, 0);
	
	local bg = self:CreateTexture(nil, "BACKGROUND");
	self.bg = bg;
	bg:SetWidth(202);
	bg:SetHeight(16);
	bg:SetColorTexture(0, 0, 0, 0.5);
	bg:SetPoint("LEFT", self);
	
	local fs = self:CreateFontString(nil, "OVERLAY");
	self.fs = fs;
	fs:SetFontObject(_G.GameTooltipText);
	local font, size = fs:GetFont();
	fs:SetFont(font, size, "OUTLINE");
	fs:SetAllPoints(self);
	
	self.r, self.g, self.b = 1, 1, 1;
end

function cell_prototype:SetupCell(tip, label, justification, font)
	local bar = self.bar;
	local fs = self.fs;
	local perc = get_perc(CurrentPower, MaximumPower);
	local r, g, b = LibCrayon:GetThresholdColor(perc, 100);
	
	bar:SetVertexColor(r, g, b);
	bar:SetWidth(perc * 2);
	bar:SetTexture("Interface\\TargetingFrame\\UI-StatusBar");
	if( perc == 0 ) then
		bar:Hide();
	else
		bar:Show();
	end
	
	fs:SetText(label);
	fs:SetFontObject(font or tooltip:GetFont());
	fs:SetJustifyH("CENTER");
	fs:SetTextColor(1, 1, 1);
	fs:Show();
	
	return self.bg:GetWidth(), bar:GetHeight() + 2;
end

function cell_prototype:ReleaseCell()
	self.r, self.g, self.b = 1, 1, 1;
end

function cell_prototype:getContentHeight()
	return self.bar:GetHeight() + 2;
end

------------------------------------------
-- UpdateTooltip
------------------------------------------

function iArtifact:UpdateTooltip(tip)
	tip:Clear();
	tip:SetColumnLayout(2, "LEFT", "RIGHT")

	local line;

	-- if Hearth of Azeroth is equipped, show the progress bar
	local hearthLink = _G.GetInventoryItemLink("player", 2);
	if( hearthLink and _G.GetItemInfoInstant(hearthLink) == 158075 ) then -- actually Hearth of Azeroth
		line = tip:AddLine(hearthLink);

		tip:SetCell(line, 2, get_label(true), cell_provider, 1, 0, 0);
	end
end