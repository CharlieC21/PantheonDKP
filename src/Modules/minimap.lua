local _, core = ...;
local _G = _G;
local L = core.L;

local Minimap = core.Minimap;
local Settings = core.Settings;
local PDKP = core.PDKP;
local Util = core.Util;
local GUI = core.GUI;

local success = '22bb33'
local warning = 'E71D36'
local info = 'F4A460'
local system = '1E90FF'

local clickText = Util:FormatFontTextColor(info, 'Click') .. ' to open PDKP. '
local shiftClickText = Util:FormatFontTextColor(info, 'Shift-Click') ..  ' to request a push.'
local altShiftText = Util:FormatFontTextColor(info, 'Alt-Shift-Click') .. ' to wipe your tables.'
local shiftRightClickText = Util:FormatFontTextColor(info, 'Right-Shift-Click') .. ' to open Officer push'
local rightClickText = Util:FormatFontTextColor(info, 'Right-Click') .. ' to open settings'
local disableSyncInRaidText = Util:FormatFontTextColor(warning, 'Push requests disabled')

local AceConfig = LibStub('AceConfigRegistry-3.0')


function Minimap:Init()
    local miniDB = Settings.db['minimap'];
    if miniDB == nil then
        Settings.db['minimap'] = {};
        miniDB = Settings.db['minimap']
    end


    Minimap.LDB = LibStub("LibDataBroker-1.1"):NewDataObject("PantheonDKP", {
        type="launcher",
        text='PantheonDKP',
        icon = "Interface\\AddOns\\PantheonDKP\\icons\\icon.tga",
        OnTooltipShow = function(tooltip)
            tooltip:SetText("PantheonDKP " .. "v" .. Settings:GetAddonVersion()) -- First line
            --tooltip:AddLine('Sync Status: '.. ' Out of date', 1, 1, 1, 1) -- text, r,g,b flag to wrap text.
            tooltip:AddLine(" ", 1,1,1,1)
            tooltip:AddLine(clickText, 1,1,1)
            tooltip:AddLine(rightClickText, 1, 1, 1)

            --
            --Raid:GetLockedInfo()
            --
            --local canRequestSync, _, nextSyncAvailable  = DKP:CanRequestSync()
            --
            --if Defaults:AllowSync() == false then
            --    tooltip:AddLine(disableSyncInRaidText, 1, 1, 1)
            --elseif canRequestSync then
            --    tooltip:AddLine(shiftClickText, 1, 1, 1)
            --else
            --    local nextSyncText = 'Next ' .. Util:FormatFontTextColor(info, 'Sync') ..
            --            ' available in: ' .. tostring(nextSyncAvailable) .. ' min(s).'
            --    tooltip:AddLine(nextSyncText, 1, 1, 1)
            --end
            ----            tooltip:AddLine(altShiftText, 1, 1, 1, 1)
            --
            --if core.canEdit then
            --    tooltip:AddLine(shiftRightClickText, 1, 1, 1)
            --end
            --
            --if #Raid.lockedInstances > 0 then
            --    tooltip:AddLine(' ', 1, 1, 1, 1)
            --    for _, raid in pairs(Raid.lockedInstances) do
            --        tooltip:AddLine(raid.desc, 1, 1, 1)
            --    end
            --end
            --
            --if #Raid.lockedRaids > 0 then
            --    tooltip:AddLine(' ', 1, 1, 1, 1)
            --    for _, raid in pairs(Raid.lockedRaids) do
            --        tooltip:AddLine(raid.desc, 1, 1, 1)
            --    end
            --end

            tooltip:Show()
        end,
        OnClick = function(_, button)
            Minimap:HandleIconClicks(button)
        end
    })
    local icon = LibStub("LibDBIcon-1.0")
    icon:Register('PantheonDKP', Minimap.LDB, miniDB)
end

function Minimap:HandleIconClicks(buttonType)

    local hasCtrl, hasShift, hasAlt = IsControlKeyDown(), IsShiftKeyDown(), IsAltKeyDown()
    if buttonType == 'LeftButton' then
        if hasShift and hasAlt then -- Table wipe. -- TODO: Hook this up.
            -- TODO: Hookup Wipe Request.
        elseif hasShift then -- Sync request.
            -- TODO: Hookup Sync Request.
        else
            GUI:TogglePDKP()
        end
    elseif buttonType == 'RightButton' then
        if hasShift and Settings:CanEdit() then -- Can Edit.
            StaticPopup_Show('PDKP_OFFICER_PUSH_CONFIRM') -- Officer Confirm Push.
        else
            --Open Interface Options.
            InterfaceOptionsFrame_OpenToCategory("PantheonDKP");
        end
    end



    --local hasCtrl, hasShift, hasAlt = IsAltKeyDown(), IsShiftKeyDown(), IsAltKeyDown()
    --local canRequestSync, minsSinceSync = DKP:CanRequestSync()
    --
    --if buttonType == 'LeftButton' then -- Left button capabilities.
    --    if hasShift and hasAlt then -- Table wipe
    --        -- Popup notifying them that this cannot be reversed.
    --        -- Letting them know that they will have to reload their UI after this is finished.
    --        Util:Debug('ShiftAlt click')
    --    elseif hasShift then
    --        local canRequestSync, minsSinceSync, nextSyncAvailable = DKP:CanRequestSync()
    --        if canRequestSync and Defaults:AllowSync() then
    --            local _, _, server_time, _ = Util:GetDateTimes()
    --            DKP.lastSync = server_time -- Will prevent people from sending multiple requests accidentally.
    --            Comms:SendCommsMessage('pdkpSyncReq', server_time, 'GUILD', nil, 'BULK', nil)
    --        elseif Defaults:AllowSync() == false then
    --            PDKP:Print('Syncing in raids is currently disabled. You can change this in the PDKP settings.')
    --        else
    --            PDKP:Print('Next sync available in: ' .. tostring(nextSyncAvailable) .. ' mins')
    --        end
    --    else
    --        if GUI.pdkp_frame and GUI.pdkp_frame:IsVisible() then
    --            GUI:Hide()
    --        else
    --            PDKP:Show()
    --        end
    --    end
    --elseif buttonType == 'RightButton' then
    --    if hasShift and core.canEdit then
    --        StaticPopup_Show('PDKP_OFFICER_PUSH_CONFIRM')
    --    else -- No modifiers
    --        -- This has to be called twice in order to properly work. Bug with Blizzard's code.
    --        InterfaceOptionsFrame_OpenToCategory("PantheonDKP");
    --        InterfaceOptionsFrame_OpenToCategory("PantheonDKP");
    --    end
    --end
end