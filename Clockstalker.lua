-----------------------------------------------------------------------------------------------
-- Client Lua Script for Clockstalker
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "GameLib"

string.lpad = function(str, len, char)
    if char == nil then char = ' ' end
    return string.rep(char, len - #str) .. str
end

-----------------------------------------------------------------------------------------------
-- Clockstalker Module Definition
-----------------------------------------------------------------------------------------------
local Clockstalker = {} 
local TS = ":"
local knVersion = 1

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function Clockstalker:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
	self.settings = self.settings or {}
	self.settings.bIsOpen = true
	self.settings.debug = false
	self.settings.format = 12
	self.settings.locked = true
    -- initialize variables here

    return o
end

function Clockstalker:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
	self.ktLockSprites = 
		{
			locked = 'CRB_ActionBarSprites:ActionBar_LockBarButton',
			unlocked = 'CRB_ActionBarSprites:ActionBar_LockBarButtonPressed'
		}
end

function Clockstalker:d(msg)
	if self.settings.debug then self:d(msg) end
	return
end

-----------------------------------------------------------------------------------------------
-- Clockstalker OnLoad
-----------------------------------------------------------------------------------------------
function Clockstalker:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("Clockstalker.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
	
end
-----------------------------------------------------------------------------------------------
-- Clockstalker OnDocLoaded
-----------------------------------------------------------------------------------------------
function Clockstalker:OnDocLoaded()
	self:d("In OnDocLoaded")
	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
		

	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "TimeForm", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
	
		
		if self.locSavedWindowLoc then
			self:d("attempting to move window")
			self.wndMain:MoveToLocation(self.locSavedWindowLoc)
		end
		
		if self.settings.bIsOpen then 
			self:d("attempting to show window")
			self.wndMain:Show(true, true)
		else
			self.wndMain:Show(false, true)
		end
		
		if self.settings.format == 12 then
			self:OnSet12h()
		else
			self:OnSet24h()
		end
		
		if self.settings.locked then
			self:OnLockMove(self.wndMain)
		else 
			self:OnUnlockMove(self.wndMain)
		end
		
		-- if the xmlDoc is no longer needed, you should set it to nil
		self.xmlDoc = nil;
					
									
		-- Register handlers for events, slash commands and timer, etc.
		-- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)

		Apollo.RegisterSlashCommand("clock", "OnClockToggle", self)

		self.timer = ApolloTimer.Create(1.0, true, "OnTimer", self)

		-- Do additional Addon initialization here
	end
end

-----------------------------------------------------------------------------------------------
-- Clockstalker Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

-- on SlashCommand "/clock"
function Clockstalker:OnClockToggle(cmd, time)
	
	if time and time == 'debug' then
		self.settings.debug = not self.settings.debug
		return
	end
	
	self:d(tostring(time))
	if time then time = tonumber(time) end
	if time then
		if time == 24 then self:OnSet24h() end
		if time == 12 then self:OnSet12h() end		
	end	
	self:d("Toggling clock")
	self:d("Plain self:d")
	if not self.settings.bIsOpen then
		self.wndMain:Show(true,true) -- show the window
	else
		self.wndMain:Close()
	end
	self.settings.bIsOpen = not self.settings.bIsOpen 
end

-- on timer
function Clockstalker:OnTimer()
	-- Do your timer-related stuff here.
	if self.settings.bIsOpen then
		local t = GameLib:GetLocalTime()
		local mer = ''
		if self.settings.format == 12 then		
			if t.nHour > 12 then
				t.nHour = t.nHour % 12
				mer = ' PM'
			else
				mer = ' AM'
			end
			if t.nHour == 0 then t.nHour = 12 end
		end
		
		local out = tostring(t.nHour) .. TS .. string.lpad(tostring(t.nMinute),2,'0') .. TS .. string.lpad(tostring(t.nSecond),2,'0') .. mer
		self.wndMain:FindChild("Time"):SetText(out)
	
	end
end


-----------------------------------------------------------------------------------------------
-- ClockstalkerForm Functions
-----------------------------------------------------------------------------------------------
-- when the OK button is clicked
function Clockstalker:OnOK()
	self.wndMain:Close() -- hide the window
end

-- when the Cancel button is clicked
function Clockstalker:OnCancel()
	self.wndMain:Close() -- hide the window
end

function Clockstalker:OnSave(eType)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then
		return
	end
	
	local locWindowLocation = self.wndMain and self.wndMain:GetLocation() or self.locSavedWindowLoc
	
	local tSave = 
	{
		tLocation = locWindowLocation and locWindowLocation:ToTable() or nil,
		nVersion = knVersion,
		bIsOpen = self.settings.bIsOpen,
		format = self.settings.format
		
	}
	return tSave
end

function Clockstalker:OnRestore(eType, tSavedData)
	self:d("In OnRestore")
	if tSavedData and tSavedData.nVersion  == knVersion then
		if tSavedData.tLocation then
			self.locSavedWindowLoc = WindowLocation.new(tSavedData.tLocation)
			self.settings.bIsOpen = tSavedData.bIsOpen
			self.settings.format = tSavedData.format			
		end
	end
end

---------------------------------------------------------------------------------------------------
-- TimeForm Functions
---------------------------------------------------------------------------------------------------
function Clockstalker:OnSet12h( wndHandler, wndControl, eMouseButton )
		wndControl = wndControl or self.wndMain:FindChild('12h')
		wndControl:SetText("12h")
		self.settings.format = 12
end

function Clockstalker:OnSet24h( wndHandler, wndControl, eMouseButton )
		wndControl = wndControl or self.wndMain:FindChild('12h')
		wndControl:SetText("24h")
		self.settings.format = 24
end

function Clockstalker:OnLockMove( wndHandler, wndControl, eMouseButton )
	self:d("locking with "..tostring(wndControl))
	self.wndMain:FindChild("moveLock"):SetCheck(false)
	self.settings.locked = true
	self.wndMain:SetStyle("Moveable", false)
end

function Clockstalker:OnUnlockMove( wndHandler, wndControl, eMouseButton )
	self:d("unlocking")
	self.wndMain:FindChild("moveLock"):SetCheck(true)
	self.settings.locked = false
	self.wndMain:SetStyle("Moveable", true)
end

function Clockstalker:OnMouseUp( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY )
	if wndHandler == wndControl then
		self:d("not the controls")
		if (not self.settings.locked) and (eMouseButton and eMouseButton == 0) then
			self:d("MouseUp with "..tostring(eMouseButton))
			self:OnLockMove(self.wndMain)
		end
	end
end

function Clockstalker:OnShowControls( wndHandler, wndControl, x, y )
	self.wndMain:FindChild("controls"):Show(true,true)
end

function Clockstalker:OnHideControls( wndHandler, wndControl, x, y )
	self:d(tostring(wndControl == self.wndMain))
	if wndControl == self.wndMain
		and not (self.wndMain:FindChild("controls"):IsParentOfMouseTarget() or self.wndMain:FindChild("controls"):IsMouseTarget())
	then
		self:OnLockMove(self.wndMain)
		self.wndMain:FindChild("controls"):Show(false,true)
	end
end

-----------------------------------------------------------------------------------------------
-- Clockstalker Instance
-----------------------------------------------------------------------------------------------
local ClockstalkerInst = Clockstalker:new()
ClockstalkerInst:Init()
