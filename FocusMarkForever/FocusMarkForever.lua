local addonName, addonTable = ...

-- Global access
addonTable.Main = CreateFrame("Frame")
addonTable.Events = addonTable.Main

-- ============================================================================
-- 1. DEFAULTS & LOGGING
-- ============================================================================

local defaults = {
    -- Marker Defaults
    preferredIcon = 8,
    position = { "CENTER", "UIParent", "CENTER", 0, 0 },
    isLocked = true,
    iconSize = 32,
    orientation = "HORIZONTAL",
    barVisible = true,
    
    -- Debug
    debugLog = {}
}

-- Logging Engine
function addonTable.Log(msg, level)
    if not FocusMarkForeverDB or not FocusMarkForeverDB.debugLog then return end
    level = level or "INFO"
    local timestamp = date("%H:%M:%S")
    local entry = string.format("[%s] [%s]: %s", timestamp, level, tostring(msg))
    
    table.insert(FocusMarkForeverDB.debugLog, 1, entry) -- Newest at top
    
    -- Cap at 50 entries
    if #FocusMarkForeverDB.debugLog > 50 then
        table.remove(FocusMarkForeverDB.debugLog)
    end
end

-- Icon Names
local iconNames = {
    [1]="Star", [2]="Circle", [3]="Diamond", [4]="Triangle",
    [5]="Moon", [6]="Square", [7]="Cross", [8]="Skull"
}

local MACRO_NAME = "FocusMark"
local barFrame

-- HELPER: Safe Number
function addonTable.SafeToNumber(val)
    if val == nil then return 0 end
    local success, num = pcall(function() return val + 0 end)
    if success and type(num) == "number" then return num end
    return 0
end

-- ============================================================================
-- 2. MACRO & CHAT LOGIC
-- ============================================================================

local function UpdateMacro(iconIndex)
    if InCombatLockdown() then
        addonTable.Log("Attempted macro update during combat.", "WARN")
        return
    end

    local macroIndex = GetMacroIndexByName(MACRO_NAME)
    if macroIndex == 0 then 
        addonTable.Log("Macro 'FocusMark' not found.", "ERROR")
        return 
    end

    -- PATCH 12.0.7 UPDATE: Added the '~' prefix before iconIndex to enable native overwrite protection
    local body = "#showtooltip\n/focus [@mouseover,exists,nodead][]\n/stopmacro [@focus,noexists]\n/tm [@focus] ~" .. iconIndex
    -- Forever diagnostics: pass the macro's existing icon (nil may be ignored on this client),
    -- catch errors, and verify the body actually changed.
    local _, existingIcon = GetMacroInfo(macroIndex)
    local ok, err = pcall(EditMacro, macroIndex, MACRO_NAME, existingIcon, body)
    local after = GetMacroBody and GetMacroBody(macroIndex)
    local changed = (after == body)
    addonTable.Log(string.format("EditMacro idx=%s ok=%s err=%s verified=%s", tostring(macroIndex), tostring(ok), tostring(err), tostring(changed)), changed and "INFO" or "ERROR")
    print("|cFF00FFFFFocusMark Forever|r: macro update " .. (changed and "OK" or ("FAILED (ok=" .. tostring(ok) .. ", err=" .. tostring(err) .. ", idx=" .. tostring(macroIndex) .. ")")))
end

local function AnnounceIcon(iconIndex, prefix)
    C_Timer.After(0.1, function()
        local msg = (prefix or "") .. "My Focus Icon is {rt" .. iconIndex .. "}"
        -- Smart Chat Routing
        if IsInRaid() then
            -- Silent in ALL raids (print to self only), takes highest priority
            local name = iconNames[iconIndex] or "Unknown"
            print("|cFF00FFFFFocusMark Forever|r: Icon set to " .. name .. " (Silent in Raid)")
        elseif IsInGroup(2) then -- 2 = LE_PARTY_CATEGORY_INSTANCE (constant may be nil on Forever)
            -- Matchmaking instances (LFD)
            C_ChatInfo.SendChatMessage(msg, "INSTANCE_CHAT")
        elseif IsInGroup() then
            -- Standard 5-man Party
            C_ChatInfo.SendChatMessage(msg, "PARTY")
        else
            -- Solo
            local name = iconNames[iconIndex] or "Unknown"
            print("|cFF00FFFFFocusMark Forever|r: Icon set to " .. name)
        end
    end)
end

-- ============================================================================
-- 3. BAR LOGIC
-- ============================================================================

function addonTable.ApplyPosition()
    if not barFrame then return end
    barFrame:ClearAllPoints()
    local p, r, rp, x, y = unpack(FocusMarkForeverDB.position)
    if not p then 
        FocusMarkForeverDB.position = { "CENTER", "UIParent", "CENTER", 0, 0 }
        p, r, rp, x, y = unpack(FocusMarkForeverDB.position)
    end
    if type(r) ~= "string" then r = "UIParent" end
    
    local success = pcall(function() barFrame:SetPoint(p, r, rp, x, y) end)
    if not success then
        barFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
end

function addonTable.UpdateLayout()
    if not barFrame then return end
    local size = FocusMarkForeverDB.iconSize
    local orientation = FocusMarkForeverDB.orientation
    local spacing = 4
    
    for i, btn in ipairs(barFrame.buttons) do
        btn:SetSize(size, size)
        btn:ClearAllPoints()
        if i == 1 then
            if orientation == "HORIZONTAL" then 
                btn:SetPoint("LEFT", barFrame, "LEFT", 0, 0)
            else 
                btn:SetPoint("TOP", barFrame, "TOP", 0, 0) 
            end
        else
            local prev = barFrame.buttons[i-1]
            if orientation == "HORIZONTAL" then 
                btn:SetPoint("LEFT", prev, "RIGHT", spacing, 0)
            else 
                btn:SetPoint("TOP", prev, "BOTTOM", 0, -spacing) 
            end
        end
    end
    
    local num = #barFrame.buttons
    if orientation == "HORIZONTAL" then
        barFrame:SetSize((num * size) + ((num - 1) * spacing), size)
    else
        barFrame:SetSize(size, (num * size) + ((num - 1) * spacing))
    end
    
    local isEditMode = addonTable.IsEditModeActive and addonTable.IsEditModeActive()
    
    if FocusMarkForeverDB.barVisible or isEditMode then 
        barFrame:Show() 
    else 
        barFrame:Hide() 
    end
    
    if isEditMode then
        barFrame:SetMovable(true)
        barFrame:EnableMouse(true)
        barFrame.texture:Hide()
    else
        if FocusMarkForeverDB.isLocked then
            barFrame:SetMovable(false)
            barFrame.texture:Hide()
            barFrame:EnableMouse(false)
        else
            barFrame:SetMovable(true)
            barFrame.texture:Show()
            barFrame:EnableMouse(true)
        end
    end
    
    if addonTable.UpdateEditModeOverlay then addonTable.UpdateEditModeOverlay() end
end

local function OnDragStopHandler(frame)
    frame:StopMovingOrSizing()
    local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint()
    local relName = "UIParent"
    if relativeTo and type(relativeTo) ~= "string" and relativeTo.GetName then
        relName = relativeTo:GetName()
    elseif type(relativeTo) == "string" then
        relName = relativeTo
    end
    FocusMarkForeverDB.position = { point, relName, relativePoint, xOfs, yOfs }
end

function addonTable.InitBar()
    barFrame = CreateFrame("Frame", "FocusMarkForeverButtonFrame", UIParent)
    barFrame:SetClampedToScreen(false) 
    barFrame:SetMovable(true)
    barFrame:RegisterForDrag("LeftButton")
    
    barFrame.texture = barFrame:CreateTexture(nil, "BACKGROUND")
    barFrame.texture:SetAllPoints()
    barFrame.texture:SetColorTexture(0, 0, 0, 0.4)

    barFrame:SetScript("OnDragStart", function(self) 
        if not FocusMarkForeverDB.isLocked or (addonTable.IsEditModeActive and addonTable.IsEditModeActive()) then 
            self:StartMoving() 
        end 
    end)
    barFrame:SetScript("OnDragStop", OnDragStopHandler)

    addonTable.ApplyPosition()

    barFrame.buttons = {}
    local iconCoords = {
        {0.0,0.25,0.0,0.25},{0.25,0.5,0.0,0.25},{0.5,0.75,0.0,0.25},{0.75,1.0,0.0,0.25},
        {0.0,0.25,0.25,0.5},{0.25,0.5,0.25,0.5},{0.5,0.75,0.25,0.5},{0.75,1.0,0.25,0.5},
    }
    
    for i=1, 8 do
        local btn = CreateFrame("Button", nil, barFrame)
        btn:SetID(i)
        local tex = btn:CreateTexture(nil, "ARTWORK")
        tex:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
        tex:SetTexCoord(unpack(iconCoords[i]))
        tex:SetAllPoints()
        
        btn:SetScript("OnClick", function()
             if addonTable.IsEditModeActive and addonTable.IsEditModeActive() then
                 if addonTable.ToggleEditModeConfig then addonTable.ToggleEditModeConfig(barFrame) end
                 return
             end
             if not FocusMarkForeverDB.isLocked then return end
             FocusMarkForeverDB.preferredIcon = i
             UpdateMacro(i)
             AnnounceIcon(i)
        end)
        
        btn:SetScript("OnDragStart", function() 
            if not FocusMarkForeverDB.isLocked or (addonTable.IsEditModeActive and addonTable.IsEditModeActive()) then 
                barFrame:StartMoving() 
            end 
        end)
        btn:SetScript("OnDragStop", function() OnDragStopHandler(barFrame) end)
        table.insert(barFrame.buttons, btn)
    end
    
    addonTable.BarFrame = barFrame
    addonTable.UpdateLayout()
    UpdateMacro(FocusMarkForeverDB.preferredIcon)
end

-- ============================================================================
-- 4. INITIALIZATION
-- ============================================================================

addonTable.Events:RegisterEvent("ADDON_LOADED")
addonTable.Events:RegisterEvent("READY_CHECK")
addonTable.Events:RegisterEvent("PLAYER_LOGIN")

addonTable.Events:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        -- Forever: the macro list is not loaded yet at ADDON_LOADED (GetMacroIndexByName
        -- returned 0 for a macro that existed), so apply the saved icon once it is.
        if FocusMarkForeverDB and FocusMarkForeverDB.preferredIcon then
            UpdateMacro(FocusMarkForeverDB.preferredIcon)
            C_Timer.After(2, function()
                if GetMacroIndexByName(MACRO_NAME) ~= 0 then UpdateMacro(FocusMarkForeverDB.preferredIcon) end
            end)
        end
    elseif event == "ADDON_LOADED" then
        local arg1 = ...
        if arg1 == addonName then
            if not FocusMarkForeverDB then FocusMarkForeverDB = {} end
            for k,v in pairs(defaults) do
                if FocusMarkForeverDB[k] == nil then FocusMarkForeverDB[k] = v end
            end
            
            addonTable.InitBar()
            if addonTable.InitEditMode then addonTable.InitEditMode() end
            if addonTable.InitConfig then addonTable.InitConfig() end
            
            -- VERSION LOG UPDATE: Bumped to v2.0.18
            addonTable.Log("FocusMark Forever 2.0.18-forever.1 (forked from FocusMarker 2.0.18) initialized.")
            self:UnregisterEvent("ADDON_LOADED")
        end
    elseif event == "READY_CHECK" then
        if FocusMarkForeverDB and FocusMarkForeverDB.preferredIcon then
             AnnounceIcon(FocusMarkForeverDB.preferredIcon, "Ready Check! ")
        end
    end
end)
